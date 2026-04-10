namespace System.Automation;

report 1511 "Delegate Approval Requests"
{
    Caption = 'Delegate Approval Requests';
    ProcessingOnly = true;
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
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        if ApprovalEntry.FindSet(true) then
            repeat
                if not (Format(ApprovalEntry."Delegation Date Formula") = '') then
                    if CalcDate(ApprovalEntry."Delegation Date Formula", DT2Date(ApprovalEntry."Date-Time Sent for Approval")) <= Today then
                        ApprovalsMgmt.DelegateSelectedApprovalRequest(ApprovalEntry, false);
            until ApprovalEntry.Next() = 0;
    end;
}

