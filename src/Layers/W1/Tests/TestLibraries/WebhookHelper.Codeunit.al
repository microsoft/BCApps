codeunit 132494 "Webhook Helper"
{
    Permissions = TableData "Workflow Webhook Entry" = imd;

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure CreatePendingFlowApproval(RecordId: RecordID)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // Creates an already-open approval request in the Workflow Webhook Entry table.
        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Record ID" := RecordId;
        WorkflowWebhookEntry."Initiated By User ID" := UserId;
        WorkflowWebhookEntry.Response := WorkflowWebhookEntry.Response::Pending;
        WorkflowWebhookEntry.Insert();
    end;
}

