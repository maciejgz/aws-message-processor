package pl.mg.amp;

import com.amazonaws.secretsmanager.caching.SecretCache;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

@SpringBootApplication
@EnableScheduling
public class MessageSaverApplication {


    @Value("${secret.variable:default_value}")
    private String secretVariable;

    public static void main(String[] args) {
        SpringApplication.run(MessageSaverApplication.class, args);
    }

    @PostConstruct
    public void init() {
        System.out.println("Secret variable: " + secretVariable);
        this.getSecret();
    }

    @Scheduled(fixedRate = 5000)
    public void performTask() {
        System.out.println("Performing a task...");
    }

    private final SecretCache cache  = new SecretCache();
    public String getSecret() {
        final String secret  = cache.getSecretString("secret.variable");
        System.out.println("Secret: " + secret);
        return null;
    }

}
