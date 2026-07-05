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

ACTION=$1
shift #first argument will be removed, $@ does not have action/destroy

if [ "$ACTION" != "create" ] && [ "$ACTION" != "delete" ]; then
    echo -e "$R ERROR:: First argument must be either create or delete $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

get_instance_id(){
    name=$1
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=roboshop-$name" \
            "Name=instance-state-name,Values=running" \
	--query 'Reservations[0].Instances[0].InstanceId' \
	--output text
}

for instance in $@
do
    INSTANCE_ID=$(get_instance_id $instance)
    if [ $ACTION == 'create' ]; then
        if [ $INSTANCE_ID == "None" ]; then
            echo "Launching Instance: roboshop-$instance"
            INSTANCE_ID=$(aws ec2 run-instances \
            --image-id $AMI_ID \
            --instance-type t3.micro \
            --security-groups roboshop-common \
            --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' \
            --query 'Instances[0].InstanceId' \
            --output text
            )
            echo "Launched Instance: $INSTANCE_ID"
        else
            echo "roboshop-$instance already running: $INSTANCE_ID"
        fi
    fi
done