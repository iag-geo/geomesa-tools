# GeoMesa on EMR, S3, Spark & Python
A simplified way to get GeoMesa running on AWS Elastic Map Reduce.

Contains install scripts and a Python script for loading & querying [GDELT](https://www.gdeltproject.org/) data in S3 using Spark.

### Why EMR?
EMR takes a lot of the work out of of launching a cluster with Hadoop, Hive and Spark
 
The platform is setup to use S3 buckets as data stores.

### Why Spark & S3?
Spark enables access to your data through the simplicity of SQL; as well as programmatic access using Python and Scala.

HDFS can be faster than S3, however it's more costly and less resilient. S3 also removes the need for an additional data store like Accumulo and HBase

### Why Python instead of Scala?

Python is easier to code & deploy and has a massive variety of modules to help you build your data & analytics platform. 

### The Stack
This guide will deploy GeoMesa using the following stack

- EMRFS using AWS S3
- Hadoop with YARN & Hive
- Spark with Pyspark
- GeoMesa FileStore
- GeoMesa Spark & PySpark

## Install Process

### Step 1 - Create an EMR cluster
Log into the AWS Console to setup security and create a EMR cluster with Hadoop, Hive & Spark:
1. Go to the EC2 Console and create a key pair if you don't have one.
1. Go to the EMR Console an click on **Create Cluster**
1. Click on **Go to advanced options**
1. Choose the *emr-5.12.1* release
1. Select *Hadoop*, *Hive* and *Spark* to install, click **next**
1. Leave the number of core servers at 2 (unless you want to run it a bit faster), click **next**
1. Give your cluster a meaningful name like "Geomesa Test", click **next**
1. Select your key pair & create the cluster
1. Wait several minutes for the cluster to start
1. While you're waiting - get the public IP address of the Master server
1. Go back to the EC2 Console and edit the security group of the Master server to allow SSH access from your machine

### Important
If you created a key pair, download it and...
- On MacOS: change the file's security using `chmod og-rwx mykeypair.pem`
- On Windows: import it using PuTTYgen. See the [PuTTY instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html) for adding a key.

Creating an EMR cluster requires 2 AWS roles:
- If you have the right to create roles: they should be created for you when you create the cluster
- If not: get your AWS admins to create the EMR_Default and EMR_EC2_Default roles for you

The GeoMesa install scripts are for AWS Linux (EMR's default)
- The script won't work if you choose non-Fedora AMIs for your cluster.

## Step 2 - Install GeoMesa
**Note:** this step is based on a Bash script. If you're running Windows, the simplest workaround is to alter the `copy_files_and_login.sh` to run in PuTTY.

1. Open Terminal (i.e. your Bash/Shell command line tool)


When the master and core servers are running:




## Step 3 - Do something with GeoMesa

`spark-submit \
--jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar \
geomesa_convert.py --target-s3-bucket your_output_s3_bucket`



#### Useful Debugging stuff

Look at the filtered temp file on HDFS

`hadoop fs -cat /tmp/geomesa_ingest/*.csv | head -20`
