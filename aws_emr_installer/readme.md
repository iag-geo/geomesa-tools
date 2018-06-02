# AWS Elastic Map Reduce Installer
A quickstart to get GeoMesa running on AWS EMR

Contains install scripts as well as a Python script for loading & querying [GDELT](https://www.gdeltproject.org/) data in S3 using Spark

### Why EMR?
EMR takes all the work out of of launching a cluster with Hadoop, Hive and Spark.
 
All the software is installed and configured to work with your S3 buckets, including encrypted data.

### Why S3 and Spark?

Whilst using HDFS can be faster, it's more costly and less resilient than S3. S3 also removes the need for an additional data store such as Accumulo and HBase

Spark enables access to your data through SQL, and is generally faster than Hive. It also gives you programmatic access using Python and Scala.

### The Stack

This quickstart will deploy GeoMesa using the following stack

- EMRFS using AWS S3
- Hadoop with YARN & Hive
- Spark with Pyspark
- GeoMesa FileStore
- GeoMesa Spark & PySpark

## Quickstart

### 1. 


You'll need to have already setup an EC2 key pair as well as the EMR_Default and EMR_EC2_Default roles

Using the AWS Console - create an EMR instance
 - Click on Go to advanced options
 - Choose the emr-5.12.1 release
 - Select Hadoop, Hive and Spark to install
 - Click next
 - Leave the number of core servers at 2 (unless you want to run it a bit faster)
 - Click next
 - Give your cluster a meaningful name like "Geomesa Test"
 - Click next
 - Select your key pair
 - Create the cluster

Wait a few minutes for the cluster to start, while you're waiting get the public IP address of the Master server.

You'll also need to allow SSH access (port 22) from your machine to the Master server. You can set this by editing the the EC2 security group

When the master and core servers are running

run run.sh
