namespace System.Automation;

codeunit 1547 "Workflow Webhook Sub Delete"
{
    // // Intended to be called by Task Scheduler as part of cleaning up when
    // // a subscription is deleted from Table 469 Workflow Webhook Subscription

    TableNo = Workflow;

    trigger OnRun()
    var
        WorkflowWebhookSubBuffer: Record "Workflow Webhook Sub Buffer";
    begin
        // disable corresponding WorkflowWebhookSubBuffer entry
        WorkflowWebhookSubBuffer.SetRange("WF Definition Id", Rec.Code);
        if WorkflowWebhookSubBuffer.FindFirst() then
            WorkflowWebhookSubBuffer.Delete();

        // disable workflow
        if Rec.Enabled then begin
            Rec.Validate(Enabled, false);
            Rec.Modify();
        end;

        // delete workflow
        if Rec.CanDelete(false) then
            Rec.Delete(true);
    end;
}

