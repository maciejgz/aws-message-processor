package pl.mg.amp.receiver;

import org.springframework.cloud.aws.messaging.listener.annotation.SqsListener;
import org.springframework.stereotype.Component;

@Component
public class MessageReceiver {

    @SqsListener(value = "ms-queue")
    public void receiveMessage(String message) {
        System.out.println("Received ms-queue message: " + message);
    }
}
