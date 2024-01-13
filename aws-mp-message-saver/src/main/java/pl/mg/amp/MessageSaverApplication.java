package pl.mg.amp;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class MessageSaverApplication {


    @Value("${secret.variable:default_value}")
    private String secretVariable;

    public static void main(String[] args) {
        SpringApplication.run(MessageSaverApplication.class, args);
    }

    @PostConstruct
    public void init() {
        System.out.println("Secret variable: " + secretVariable);
    }

}
