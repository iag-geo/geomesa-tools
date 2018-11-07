package au.com.iag.geo;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
//import java.util.Properties;

import org.apache.log4j.BasicConfigurator;

//import org.apache.kafka.clients.producer.KafkaProducer;
//import org.apache.kafka.clients.producer.Producer;
//import org.apache.kafka.clients.producer.ProducerConfig;
//import org.apache.kafka.common.serialization.LongSerializer;
//import org.apache.kafka.common.serialization.StringSerializer;


public class Main {

    public static void main(String[] args) {

        BasicConfigurator.configure();

        Map<String, Serializable> parameters = new HashMap<>();
        parameters.put("kafka.zookeepers", "localhost:2181");
        parameters.put("kafka.brokers", "localhost:9092");

        try {

            org.geotools.data.DataStore dataStore = org.geotools.data.DataStoreFinder.getDataStore(parameters);

            System.out.println(dataStore);

        } catch (Exception e) {
            System.out.println("Something screwed up!");
        }
    }
}
