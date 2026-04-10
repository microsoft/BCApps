codeunit 132495 MockOnFetchInitParams
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Notify Task", 'OnFetchWorkflowWebhookNotificationInitParams', '', false, false)]
    local procedure MockOnFetchWorkflowWebhookNotificationInitParams(var RetryCount: Integer; var WaitTime: Integer; var InitHandled: Boolean)
    begin
        RetryCount := 0;
        WaitTime := 0;
        InitHandled := true;
    end;
}

