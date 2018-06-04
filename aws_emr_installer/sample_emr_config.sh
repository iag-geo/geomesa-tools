#!/usr/bin/env bash

aws emr create-cluster \
--termination-protected \
--applications Name=Hadoop Name=Hive Name=Spark \
--ec2-attributes '{
                    "KeyName": "<myKeyPairName>",
                    "InstanceProfile": "EMR_EC2_DefaultRole",
                    "SubnetId": "<mySubnetId>",
                    "EmrManagedSlaveSecurityGroup": "<mySlaveSecurityGroup>",
                    "EmrManagedMasterSecurityGroup": "<myMasterSecurityGroup>"
                  }' \
--release-label emr-5.12.1 \
--log-uri 's3n://<myS3BucketName>/elasticmapreduce/' \
--instance-groups '[{
                      "InstanceCount": 1,
                      "EbsConfiguration": {
                        "EbsBlockDeviceConfigs": [{
                          "VolumeSpecification": {
                            "SizeInGB": 32,
                            "VolumeType": "gp2"
                          },
                          "VolumesPerInstance": 1
                        }]
                      },
                      "InstanceGroupType": "MASTER",
                      "InstanceType": "m4.large",
                      "Name": "Master - 1"
                    }, {
                      "InstanceCount": 2,
                      "EbsConfiguration": {
                        "EbsBlockDeviceConfigs": [{
                          "VolumeSpecification": {
                            "SizeInGB": 32,
                            "VolumeType": "gp2"
                          },
                          "VolumesPerInstance": 1
                        }]
                      },
                      "InstanceGroupType": "CORE",
                      "InstanceType": "m4.large",
                      "Name": "Core - 2"
                    }]' \
--auto-scaling-role EMR_AutoScaling_DefaultRole \
--no-visible-to-all-users \
--ebs-root-volume-size 10 \
--service-role EMR_DefaultRole \
--enable-debugging \
--name 'GeoMesa Test' \
--scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
--region us-east-1
