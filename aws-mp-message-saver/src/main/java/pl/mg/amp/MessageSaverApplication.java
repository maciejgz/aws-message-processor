package pl.mg.amp;

import com.amazonaws.services.secretsmanager.AWSSecretsManager;
import com.amazonaws.services.secretsmanager.AWSSecretsManagerClient;
import com.amazonaws.services.secretsmanager.model.GetSecretValueRequest;
import com.amazonaws.services.secretsmanager.model.GetSecretValueResult;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.aws.messaging.config.annotation.EnableSqs;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import software.amazon.awssdk.regions.Region;

@SpringBootApplication
@EnableScheduling
@EnableSqs
public class MessageSaverApplication {

    @Value("${mp.secret.variable:default_secret_value}")
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
        getSecret();
    }

    private void getSecret() {
        try {
            String secretName = "mp.secret.variable";
            Region region = Region.EU_CENTRAL_1;
            AWSSecretsManager secretsClient = AWSSecretsManagerClient.builder()
                    .withRegion(region.toString())
                    .build();

            getValue(secretsClient, secretName);
        } catch (Exception e) {
            System.out.println("Error getting secret");
            e.printStackTrace();
        }

    }

    public static void getValue(AWSSecretsManager secretsClient, String secretName) {
        try {
            GetSecretValueRequest valueRequest = new GetSecretValueRequest()
                    .withSecretId(secretName);
            GetSecretValueResult valueResponse = secretsClient.getSecretValue(valueRequest);
            String secret = valueResponse.getSecretString();
            System.out.println("secret found: " + secret);
        } catch (Exception e) {
            System.out.println("Error getting secret value");
            e.printStackTrace();
        }
    }

    @Scheduled(fixedRate = 5000)
    public void performTask() {
        System.out.println("Performing a task...");
    }


}
