package pl.mg.amp.receiver;

import org.springframework.cloud.aws.messaging.listener.annotation.SqsListener;
import org.springframework.stereotype.Component;
import pl.mg.amp.printer.MessagePrinter;

@Component
public class MessageReceiver {

    private final MessagePrinter messagePrinter;

    public MessageReceiver(MessagePrinter messagePrinter) {
        this.messagePrinter = messagePrinter;
    }

    @SqsListener(value = "ms-queue")
    public void receiveMessage(String message) {
        System.out.println("Received ms-queue message: " + message);
        messagePrinter.printMessage(message + " - processed by aws-mp-message-receiver2");
    }
}
