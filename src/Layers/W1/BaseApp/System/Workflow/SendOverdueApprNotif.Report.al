namespace System.Automation;

report 1509 "Send Overdue Appr. Notif."
{
    ApplicationArea = Suite;
    Caption = 'Send Overdue Approval Notifications';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if not ApprovalsMgmt.IsOverdueNotificationsWorkflowEnabled() then
            Error(NoWorkflowEnabledErr);

        OnSendOverdueNotifications();
    end;

    var
        NoWorkflowEnabledErr: Label 'There is no workflow enabled for sending overdue approval notifications.';

    [IntegrationEvent(false, false)]
    local procedure OnSendOverdueNotifications()
    begin
    end;
}

