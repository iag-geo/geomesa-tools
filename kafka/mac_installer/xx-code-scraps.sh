#!/usr/bin/env bash


# stop Zookeeper and Kafka
$KAFKA_HOME/bin/kafka-server-stop.sh
$KAFKA_HOME/bin/zookeeper-server-stop.sh

# start zookeeper and kafka
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties



TOPIC_NAME=fred

# list topics
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --list

# delete topic
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --delete --topic $TOPIC_NAME

# create topic
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --create --topic $TOPIC_NAME --replication-factor 1 --partitions 3

# add file data to topic (producer)
cat "/Users/s57405/Downloads/a full drive.txt" | $KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $KAFKA_BROKERS --topic $TOPIC_NAME

# read data from topic (comsumer)
$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server $KAFKA_BROKERS --topic $TOPIC_NAME --from-beginning --max-messages 10





########################################
#
# word count example
#
########################################

# delete topics
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --delete --topic streams-plaintext-input
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --delete --topic streams-wordcount-output

# stop Zookeeper and Kafka
$KAFKA_HOME/bin/kafka-server-stop.sh
$KAFKA_HOME/bin/zookeeper-server-stop.sh

# start zookeeper and kafka
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties

# create topics
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --create --topic streams-plaintext-input --replication-factor 1 --partitions 1
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --create --topic streams-wordcount-output --replication-factor 1 --partitions 1

# create some data
echo -e "all streams lead to kafka\nhello kafka streams\njoin kafka summit" > ~/tmp/file-input.txt

# add data to input topic
cat ~/tmp/file-input.txt | $KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $KAFKA_BROKERS --topic streams-plaintext-input



# consume output topic
$KAFKA_HOME/bin/kafka-console-consumer.sh --topic streams-wordcount-output --from-beginning \
                                          --bootstrap-server localhost:9092 \
                                          --property print.key=true \
                                          --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer


########################################
#
# Geomesa Kafka Tutorial
#
########################################

# download repo and build
cd /Users/hugh.saalmans/OneDrive/IdeaProjects/Geomesa

git clone https://github.com/geomesa/geomesa-tutorials.git
cd geomesa-tutorials
git checkout tags/geomesa-tutorials-$GEOMESA_KAFKA_VERSION

mvn clean install -pl geomesa-tutorials-kafka/geomesa-tutorials-kafka-quickstart -am

# start zookeeper and kafka
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties
$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties

# run tutorial
cd geomesa-tutorials-kafka


#/Users/hugh.saalmans/OneDrive/IdeaProjects/Geomesa/geomesa-tutorials/geomesa-tutorials-kafka/geomesa-tutorials-kafka-quickstart/target/geomesa-tutorials-kafka-quickstart-2.0.2.jar

java -cp geomesa-tutorials-kafka-quickstart/target/geomesa-tutorials-kafka-quickstart-$GEOMESA_KAFKA_VERSION.jar \
    org.geomesa.example.kafka.KafkaQuickStart \
    --kafka.brokers $KAFKA_BROKERS \
    --kafka.zookeepers $ZK_HOSTS \
    --cleanup




# UNUSED DOCKER KAFKA STUFF

## fire up the kafka shell
#. docker/start-kafka-shell.sh host.docker.internal host.docker.internal:2181

## create a topic and start a producer
#$KAFKA_HOME/bin/kafka-topics.sh --create --topic topic --partitions 4 --zookeeper $ZK --replication-factor 2
#$KAFKA_HOME/bin/kafka-topics.sh --describe --topic topic --zookeeper $ZK
#$KAFKA_HOME/bin/kafka-console-producer.sh --topic=topic --broker-list='host.docker.internal:32775,host.docker.internal:32774'
#
## start a consumer
#$KAFKA_HOME/bin/kafka-console-consumer.sh --topic=topic --zookeeper=$ZK

