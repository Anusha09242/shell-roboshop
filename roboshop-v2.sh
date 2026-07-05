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