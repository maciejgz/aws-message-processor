package pl.mg.amp;

import com.amazonaws.auth.ContainerCredentialsProvider;
import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.auth.EC2ContainerCredentialsProviderWrapper;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

@SpringBootApplication
@EnableScheduling
public class MessageSaverApplication {


    @Value("${secret.variable:default_secret_value}")
    private String secretVariable;

    @Value("${env.variable:default_env_value}")
    private String envVariable;

    public static void main(String[] args) {
        SpringApplication.run(MessageSaverApplication.class, args);
    }

    @PostConstruct
    public void init() {
        System.out.println("Secret variable: " + secretVariable);
        System.out.println("Env variable: " + envVariable);

        try {
            System.out.println("Trying to build SQS client...");
            AmazonSQS sqs = AmazonSQSClientBuilder.standard()
//                    .withCredentials((new EC2ContainerCredentialsProviderWrapper().))
                    .withRegion(Regions.EU_CENTRAL_1)
                    .build();

            System.out.println("Getting queue URL...");
            String queueUrl = sqs.getQueueUrl("ms-queue").getQueueUrl();
            System.out.println("Reading message...");
            sqs.receiveMessage(queueUrl).getMessages().forEach(message
                    -> System.out.println("Message received: " + message.getBody()));
        } catch (Exception e) {
            System.out.println("Error reading message: " + e.getMessage());
        }
//        this.getSecretCached();
    }

    @Scheduled(fixedRate = 5000)
    public void performTask() {
        System.out.println("Performing a task...");
    }

    /*AWSSecretsManagerClientBuilder secretsManager = AWSSecretsManagerClientBuilder.standard()
            .withRegion("eu-central-1");

    private final SecretCache cache = new SecretCache(secretsManager);

    public void getSecretCached() {
        final String secret = cache.getSecretString("secret.variable");
        System.out.println("Secret cached: " + secret);
    }*/

}
