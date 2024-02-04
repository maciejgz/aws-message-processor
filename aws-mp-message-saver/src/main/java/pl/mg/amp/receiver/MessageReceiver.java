package pl.mg.amp.receiver;

import org.springframework.stereotype.Component;

@Component
public class MessageReceiver {
  /*  @JmsListener(destination = "ms-queue")
    public void receiveMessage(String message) {
        System.out.println("Received <" + message + ">");
    }*/
/*    @Sqs("ms-queue")
    public void receiveMessage(String message) {
        // Process the received message
        System.out.println("Received message: " + message);
    }*/
}
