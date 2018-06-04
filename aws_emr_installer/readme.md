# GeoMesa on EMR, S3, Spark & Python
A simplified way to get GeoMesa running using AWS Elastic Map Reduce.

Contains install scripts and a Python script for loading, converting & querying [GDELT](https://www.gdeltproject.org/) data in S3 using GeoMesa on Spark.

## The Platform

This guide & code will deploy the following stack:

- EMRFS using AWS S3
- Hadoop with YARN & Hive
- Spark with Pyspark
- GeoMesa FileSystem Datastore
- GeoMesa Spark & PySpark

#### Why EMR & S3?
EMR makes launching a cluster with Hadoop, Hive & Spark straightforward. It also makes it simple to use S3 as a data store.

S3 removes the need for an additional data store like Accumulo or HBase. S3 is also less costly and more persistent than HDFS, although HDFS can be faster.

#### Why Spark?
Spark enables big data analytics through the simplicity of SQL; as well as programmatic access using Python, R and Scala.

#### Why Python instead of Scala?
Python is easier to code & deploy and has a massive variety of modules to help you build your data & analytics platform. 

## Install Process

### Step 1 - Create an EMR cluster
Log into the AWS Console to setup security and create a EMR cluster with Hadoop, Hive & Spark:
1. Go to the EC2 Console and [create a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair) if you don't have one.
1. Go to the EMR Console an click **Create Cluster**
1. Click **Go to advanced options**
1. Wait a few seconds and choose the *emr-5.12.1* release
1. Select *Hadoop*, *Hive* and *Spark* to install, click **next**
1. Leave the number of Core servers at 2 (unless you want to run it a bit faster), click **next**
1. Give your cluster a meaningful name like *Geomesa Test*, click **next**
1. Select your EC2 key pair & click **Create cluster**
1. *Wait several minutes for the cluster to start*
1. Get the public IP address of the master server (click **Hardware** and the master server's ID)
1. In the EC2 Console - edit the security group of the master server to [allow SSH access](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html) from your machine
1. Refresh the EMR Console to confirm the master and Core servers are running

### Important
If you created a key pair - download it and...
- On MacOS or Linux: change the file's permissions using `chmod og-rwx mykeypair.pem`
- On Windows: import it using PuTTYgen. See the [PuTTY instructions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html) for adding a key.

Creating an EMR cluster requires 2-3 AWS roles:
- If you have the right to create the roles: they will be created automatically
- If not: get your AWS admins to create the *EMR_DefaultRole* and *EMR_EC2_DefaultRole* roles for you
- If you want the cluster to autoscale, you'll need the third role: *EMR_AutoScaling_DefaultRole*

The GeoMesa install script is for AWS Linux (EMR's default)
- The script won't work if you choose non-Fedora AMIs for your cluster.

### Step 2 - Install GeoMesa

On MacOS or Linux: 
1. Edit *copy_files_and_login.sh* to set the IP address of your EMR master server and the full path to your key pair's pem file
1. Open your preferred command line tool and run *copy_files_and_login.sh*
1. Run `. ~/install-geomesa.sh`
1. Wait 8-10 mins and check the on-screen log for success

On Windows:
1. Use PuTTy Secure Copy (PSCP) to copy the 3 *master_server_files* files to the home directory on the EMR master server. Connect using the *hadoop* user, not *ec2-user*
1. Use PuTTY to connect to the EMR master server using SSH
1. Run `. ~/install-geomesa.sh`
1. Wait 8-10 mins and check the on-screen log for success

### Step 3 - Do something with GeoMesa

1. Edit this command to add the S3 bucket you want to output the GeoMesa data to: `spark-submit --jars $GEOMESA_FS_HOME/dist/spark/geomesa-fs-spark-runtime_2.11-$GEOMESA_VERSION.jar geomesa_convert.py --target-s3-bucket <your_output_s3_bucket_name>`
1. Whilst still logged into the EMR master server - run the command!

If all goes well - the script will:
1. Load the GDELT data from S3
1. Filter it to Australia
1. Output it as GeoMesa Parquet formatted data to S3
1. Run a spatial query on the GeoMesa dataset and show the results on screen
