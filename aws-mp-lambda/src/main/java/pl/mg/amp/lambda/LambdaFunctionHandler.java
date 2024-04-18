package pl.mg.amp.lambda;

import com.amazonaws.regions.Regions;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import com.amazonaws.services.sqs.model.SendMessageRequest;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;


public class LambdaFunctionHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent input, Context context) {
        context.getLogger().log("Processing Lambda request");
        sendSqSMessage("Received event: " + input.getBody(), context);

        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", "application/json");

        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent();
        response.setStatusCode(200);
        response.setHeaders(headers);
        response.setBody("Success");

        return response;
    }

    private void sendSqSMessage(String message, Context context) {
        context.getLogger().log("Reading SQS client...");
        try {
            //debug region
            AmazonSQS sqs = AmazonSQSClientBuilder.standard().withRegion(Regions.EU_CENTRAL_1).build();
            context.getLogger().log("Getting queue URL...");
            String queueUrl = sqs.getQueueUrl("ms-queue").getQueueUrl();
            context.getLogger().log("Sending message...");
            SendMessageRequest send_msg_request = new SendMessageRequest()
                    .withQueueUrl(queueUrl)
                    .withMessageBody(message + "!!!processed by Lambda2!!!")
                    .withDelaySeconds(5);
            sqs.sendMessage(send_msg_request);
            context.getLogger().log("Message sent");
        } catch (Exception e) {
            context.getLogger().log("Error sending message: " + e.getMessage());
            context.getLogger().log("Stack trace: " + Arrays.toString(e.getStackTrace()));
        }

    }

}