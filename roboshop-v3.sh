#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z10440783CSR1J1BG02N4"
DOMAIN_NAME="anu90.shop"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

### Validation ###
if [ $# -lt 2 ]; then
    echo -e "$R ERROR: Atleast 2 arguments are required $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

### take this as assignment, create another version of roboshop.sh
##If create, If instance is stopped, start and update R53 record
###If delete, If instance is stopped, delete that too and delete R53 records too

ACTION=$1
shift

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
    echo -e "$R ERROR: First argument must be either create or delete $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

### Get Instance ID ###
get_instance_id(){
    name=$1
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=roboshop-$name" \
            "Name=instance-state-name,Values=running,stopped" \
	--query 'Reservations[0].Instances[0].InstanceId' \
	--output text
}

for instance in $@
do
    INSTANCE_ID=$(get_instance_id $instance)
    echo "INSTANCE: $instance"
    echo "INSTANCE_ID: $INSTANCE_ID"
    if [ "$ACTION" == "create" ]; then
        if [ "$INSTANCE_ID" == "None" ]; then
            echo "Launching Instance: roboshop-$instance"
            INSTANCE_ID=$(aws ec2 run-instances \
            --image-id $AMI_ID \
            --instance-type t3.micro \
            --security-groups "roboshop-common" "roboshop-$instance" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
            --query 'Instances[0].InstanceId' \
            --output text
            )
            echo "Launched Instance: $INSTANCE_ID"
        else
            STATE=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].State.Name" \
            --output text)
            if [ "$STATE" == "stopped" ]; then
                echo "roboshop-$instance is stopped: $INSTANCE_ID"
                echo "Starting the instance"
                aws ec2 start-instances \
                    --instance-ids "$INSTANCE_ID"
                aws ec2 wait instance-running \
                    --instance-ids "$INSTANCE_ID"
                echo "Instance is now running"
            else
                echo "roboshop-$instance already running: $INSTANCE_ID"
            fi
        fi

        ### update R53 record ###
        if [ $instance == "frontend" ]; then
            IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query "Reservations[*].Instances[*].PublicIpAddress" \
            --output text
            )
            R53_RECORD="$DOMAIN_NAME"
        else
            IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID  \
                --query "Reservations[*].Instances[*].PrivateIpAddress" \
                --output text
            )
            R53_RECORD="$instance.$DOMAIN_NAME"
        fi

        aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
            {
                "Comment": "Update A record to add new IP",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": "'$R53_RECORD'",
                            "Type": "A",
                            "TTL": 1,
                            "ResourceRecords": [
                                {
                                    "Value": "'$IP'"
                                }
                            ]
                        }
                    }
                ]
            }

        '
        echo "updated R53 record for: $instance"
    else
        if [ $INSTANCE_ID == "None" ]; then
            echo "$instance already destroyed, nothing to do..."
        else
            STATE=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --query "Reservations[0].Instances[0].State.Name" \
                --output text)

            echo "Current state: $STATE"
            if [ "$STATE" == "stopped" ] || [ "$STATE" == "running" ]; then
                echo "Terminating Instance: roboshop-$instance"
                aws ec2 terminate-instances \
                --instance-ids $INSTANCE_ID

                ### DELETE Route53 record ###
                if [ "$instance" == "frontend" ]; then
                R53_RECORD="$DOMAIN_NAME"
                else
                    R53_RECORD="$instance.$DOMAIN_NAME"
                fi
                aws route53 change-resource-record-sets \
                    --hosted-zone-id $ZONE_ID \
                    --change-batch '
                        {
                            "Comment": "Delete record",
                            "Changes": [
                                {
                                    "Action": "DELETE",
                                    "ResourceRecordSet": {
                                        "Name": "'$R53_RECORD'",
                                        "Type": "A",
                                        "TTL": 1,
                                        "ResourceRecords": [
                                            {
                                                "Value": "'$IP'"
                                            }
                                        ]
                                    }
                                }
                            ]
                        }
                    '
                echo "Deleted R53 record for $instance"
            fi   
        fi
    fi
done

