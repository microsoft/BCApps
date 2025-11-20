namespace System.Automation;

codeunit 1542 "Workflow Webhook Responses"
{

    trigger OnRun()
    begin
    end;

    var
        SendNotificationToWebhookTxt: Label 'Send a record notification to a webhook.';

    procedure SendNotificationToWebhookCode(): Code[128]
    begin
        exit('SENDNOTIFICATIONTOWEBHOOK');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsePredecessorsToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookEventResponseCombinationsToLibrary(ResponseFunctionName: Code[128])
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        case ResponseFunctionName of
            SendNotificationToWebhookCode():
                begin
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
                    WorkflowResponseHandling.AddResponsePredecessor(SendNotificationToWebhookCode(),
                      WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnAddWorkflowResponsesToLibrary', '', false, false)]
    local procedure AddWorkflowWebhookResponsesToLibrary()
    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        WorkflowResponseHandling.AddResponseToLibrary(SendNotificationToWebhookCode(), 0, SendNotificationToWebhookTxt, 'GROUP 8');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnExecuteWorkflowResponse', '', false, false)]
    local procedure ExecuteWorkflowWebhookResponses(var ResponseExecuted: Boolean; Variant: Variant; xVariant: Variant; ResponseWorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowResponse: Record "Workflow Response";
    begin
        if WorkflowResponse.Get(ResponseWorkflowStepInstance."Function Name") then
            case WorkflowResponse."Function Name" of
                SendNotificationToWebhookCode():
                    begin
                        SendNotificationToWebhook(Variant, ResponseWorkflowStepInstance);
                        ResponseExecuted := true;
                    end;
            end;
    end;

    local procedure SendNotificationToWebhook(var Variant: Variant; var WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        WorkflowWebhookManagement.GenerateRequest(RecRef, WorkflowStepInstance);
    end;
}

