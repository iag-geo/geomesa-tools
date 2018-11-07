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







# word count example


# create topics
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --create --topic streams-plaintext-input --replication-factor 1 --partitions 3
$KAFKA_HOME/bin/kafka-topics.sh --zookeeper $ZK_HOSTS --create --topic streams-wordcount-output --replication-factor 1 --partitions 3

# create some data
echo -e "all streams lead to kafka\nhello kafka streams\njoin kafka summit" > ~/tmp/file-input.txt

# add data to input topic
cat ~/tmp/file-input.txt | $KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $KAFKA_BROKERS --topic streams-plaintext-input















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

