# GeoMesa on EMR, S3, Spark & Python
A quickstart to get GeoMesa running on AWS Elastic Map Reduce.

Contains install scripts and a Python script for loading & querying [GDELT](https://www.gdeltproject.org/) data in S3 using Spark.

### Why EMR?
EMR takes a lot of the work out of of launching a cluster with Hadoop, Hive and Spark
 
The platform is setup to use S3 buckets as data stores.

### Why Spark & S3 instead of Hive & HDFS?
Spark enables access to your data through the simplicity of SQL; as well as programmatic access using Python and Scala. It's also generally faster than Hive.

HDFS can be faster, however it's more costly and less resilient than S3. S3 also removes the need for an additional data store such as Accumulo and HBase

### Why Python instead of Scala?

Python is easier to code & deploy and has a massive variety of modules to help you build your data & analytics platform. 

### The Stack
This quickstart will deploy GeoMesa using the following stack

- EMRFS using AWS S3
- Hadoop with YARN & Hive
- Spark with Pyspark
- GeoMesa FileStore
- GeoMesa Spark & PySpark

## Install Process

### Step 1 - Create an EMR Cluster
Log into the AWS Console to setup security and create a EMR cluster with Hadoop, Hive & Spark:
1. Go to the EC2 Console and create a key pair if you don't have one.
1. Go to the EMR Console an click on **Create Cluster**
1. Click on **Go to advanced options**
1. Choose the *emr-5.12.1* release
1. Select *Hadoop*, *Hive* and *Spark* to install, click **next**
1. Leave the number of core servers at 2 (unless you want to run it a bit faster), click **next**
1. Give your cluster a meaningful name like "Geomesa Test", click **next**
1. Select your key pair & create the cluster

Wait a few minutes for the cluster to start. While you're waiting - get the public IP address of the Master server.

You'll also need to allow SSH access (port 22) from your machine to the Master server. You can set this by editing the EC2 security group of the Master server

### Notes
- If you created a key pair -after downloading it, don't forget to change it's security
...Use `chmod og-rwx mykeypair.pem` on MacOS. On Windows - see the PuTTY instructions for adding a key.
- You'll need the right to create roles. If you do - the roles should be created for you when you create your EMR cluster. If not ,get someone to create the EMR_Default and EMR_EC2_Default roles

## Step 2 - Install GeoMesa
When the master and core servers are running

...
