namespace System.Automation;

using System.Security.AccessControl;

codeunit 1546 "Workflow Webhook Notify Task"
{
    // // Intended to be called using TaskScheduler

    EventSubscriberInstance = StaticAutomatic;
    TableNo = "Workflow Step Instance";

    trigger OnRun()
    var
        WorkflowWebhookSubscriptionTable: Record "Workflow Webhook Subscription";
        WorkflowWebhookEntryTable: Record "Workflow Webhook Entry";
        UserTable: Record User;
        WorkflowWebhookNotification: Codeunit "Workflow Webhook Notification";
        ContactEmail: Text;
        RetryCount: Integer;
        WaitTime: Integer;
        InitHandled: Boolean;
    begin
        // Fetch Subscription
        WorkflowWebhookSubscriptionTable.SetFilter("WF Definition Id", Rec."Workflow Code");
        WorkflowWebhookSubscriptionTable.SetFilter(Enabled, '%1', true);
        if not WorkflowWebhookSubscriptionTable.FindFirst() then
            exit;

        // Fetch Entry
        WorkflowWebhookEntryTable.SetRange("Workflow Step Instance ID", Rec.ID);
        if not WorkflowWebhookEntryTable.FindFirst() then
            exit;

        UserTable.SetRange("User Name", WorkflowWebhookEntryTable."Initiated By User ID");
        if UserTable.FindFirst() then
            ContactEmail := UserTable."Authentication Email";

        // Send notification
        OnFetchWorkflowWebhookNotificationInitParams(RetryCount, WaitTime, InitHandled);

        // If parameters not initialized by subscribers (mock subscriber for testing)
        if not InitHandled then begin
            // Set defaults
            BindSubscription(WorkflowWebhookNotification);
            RetryCount := 5;
            WaitTime := 12000;
        end;

        WorkflowWebhookNotification.Initialize(RetryCount, WaitTime);
        WorkflowWebhookNotification.SendNotification(WorkflowWebhookEntryTable."Data ID",
          WorkflowWebhookEntryTable."Workflow Step Instance ID", WorkflowWebhookSubscriptionTable.GetNotificationUrl(), ContactEmail);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFetchWorkflowWebhookNotificationInitParams(var RetryCount: Integer; var WaitTime: Integer; var InitHandled: Boolean)
    begin
    end;
}
