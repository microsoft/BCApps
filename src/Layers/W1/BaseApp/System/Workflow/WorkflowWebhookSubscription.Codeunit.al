namespace System.Automation;

codeunit 1544 "Workflow Webhook Subscription"
{

    trigger OnRun()
    begin
    end;

    procedure Approve(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.ContinueByStepInstanceId(WorkflowStepInstanceId);
    end;

    procedure Reject(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.RejectByStepInstanceId(WorkflowStepInstanceId);
    end;

    procedure Cancel(WorkflowStepInstanceId: Guid)
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        WorkflowWebhookManagement.CancelByStepInstanceId(WorkflowStepInstanceId);
    end;

    procedure GetDirectApprover(RequestorEmailAddress: Text) ApproverEmailAddress: Text
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        ApproverEmailAddress := WorkflowWebhookManagement.GetDirectApproverForRequestor(RequestorEmailAddress);
    end;
}
