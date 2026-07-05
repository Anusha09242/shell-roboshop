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
if [ $ACTION != "create" ] && [ $ACTION != "delete" ]; then
    echo -e "$R ERROR: First argument must be either create or delete $N"
    echo "USAGE: $0 [create/delete] [instance1] [instance2...]"
    exit 1
fi

get_instance_id(){
    name=$1
    aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=roboshop-$name" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text
}

for instance in $@
do
    INSTANCE_ID=$(get_instance_id $instance)
    echo "INSTANCE: $instance"
    echo "INSTANCE_ID: $INSTANCE_ID
    fi
done

