



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
