package pl.mg.amp.printer;

import com.amazonaws.auth.DefaultAWSCredentialsProviderChain;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class MessageS3Printer implements MessagePrinter {

    @Override
    public void printMessage(String message) {
        System.out.println("Printing message to S3: " + message);

        AmazonS3 s3 = AmazonS3ClientBuilder.standard()
                .withRegion(Regions.EU_CENTRAL_1)
                .withCredentials(new DefaultAWSCredentialsProviderChain())
                .build();
        System.out.println("S3 client created...");
        s3.putObject("aws-ms-saver-bucket", "ms-object-" + Instant.now().toString(), message);
        System.out.println("Message saved to S3...");
    }
}
