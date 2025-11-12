namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Security.User;
using System.Security.AccessControl;

codeunit 1543 "Workflow Webhook Management"
{
    Permissions = TableData "Workflow Webhook Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ResponseAlreadyReceivedErr: Label 'A response has already been received.';
        ResponseNotExpectedErr: Label 'A response is not expected.';
#pragma warning disable AA0470
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported.', Comment = 'Record type Customer is not supported by this workflow response.';
#pragma warning restore AA0470
        UserUnableToCancelErr: Label 'User %1 does not have the permission necessary to cancel the item.', Comment = '%1 = a NAV user ID, for example "MEGANB"';
        EmailNotAssociatedWithUserErr: Label 'Email %1 is not associated with any user.', Comment = '%1 = an email, for example "test@microsoft.com"';
        EmailNotProvidedErr: Label 'You must specify an email address for the requestor.';
        UserNotFoundErr: Label 'User %1 has not been configured in the "Approval User Setup".', Comment = '%1 = a NAV user ID, for example "MEGANB"';
        ApproverNotFoundErr: Label 'Approver for user %1 could not be found.', Comment = '%1 = a NAV user ID, for example "MEGANB"';
        EntryIsNotPendingErr: Label 'The %1 you are trying to act on is not in a pending state.', Comment = '%1 = the table caption for "Workflow Webhook Entry"';
        UserUnableToDeleteErr: Label 'User %1 does not have the permission necessary to delete the item.', Comment = '%1 = a NAV user ID, for example "MEGANB"';
        DifferentUserExpectedErr: Label 'User %1 cannot act on this step. Make sure the user who created the webhook (%2) is the same who is trying to act.', Comment = '%1, %2 = two distinct NAV user IDs, for example "MEGANB" and "WILLIAMC"';
        WorkflowStepInstanceIdNotFoundErr: Label 'The workflow step instance id %1 was not found.', Comment = '%1 = Id value of a record.';
        WorkflowNotWaitingForUserErr: Label 'The requested action cannot be completed because the %1 is not waiting for a user.', Comment = '%1 = the table caption for "Workflow Step Argument"';
        TelemetryCategoryTxt: Label 'AL Workflow Webhook', Locked = true;
        CheckingUserActionsTelemetryMsg: Label 'Checking if the user can act on the webhook. Response type: %1. Response argument null: %2.', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnCancelWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry"; OnDeletion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnContinueWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectWorkflow(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
    end;

    procedure CanCancel(WorkflowWebhookEntry: Record "Workflow Webhook Entry"): Boolean
    var
        UserSetup: Record "User Setup";
    begin
        if WorkflowWebhookEntry.Response <> WorkflowWebhookEntry.Response::Pending then
            exit(false);

        if UserSetup.Get(UserId) then
            if UserSetup."Approval Administrator" then
                exit(true);

        exit(WorkflowWebhookEntry."Initiated By User ID" = UserId);
    end;

    procedure CanRequestApproval(RecordId: RecordID): Boolean
    begin
        // Checks if the given record can have an approval request made, based on whether or not there's already a pending approval for it.
        exit(not HasPendingWorkflowWebhookEntryByRecordId(RecordId));
    end;

    procedure GetCanRequestAndCanCancel(RecordId: RecordID; var CanRequestApprovalForFlow: Boolean; var CanCancelApprovalForFlow: Boolean)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        if FindWorkflowWebhookEntryByRecordIdAndResponse(WorkflowWebhookEntry, RecordId, WorkflowWebhookEntry.Response::Pending) then begin
            CanCancelApprovalForFlow := CanCancel(WorkflowWebhookEntry);
            CanRequestApprovalForFlow := false;
        end else begin
            CanCancelApprovalForFlow := false;
            CanRequestApprovalForFlow := true;
        end;
    end;

    procedure GetCanRequestAndCanCancelJournalBatch(GenJournalBatch: Record "Gen. Journal Batch"; var CanRequestBatchApproval: Boolean; var CanCancelBatchApproval: Boolean; var CanRequestLineApprovals: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // Helper method to check the General Journal Batch and all its lines for ability to request/cancel approval.
        // Journal pages' ribbon buttons only let users request approval for the batch or its individual lines, but not both.

        GetCanRequestAndCanCancel(GenJournalBatch.RecordId, CanRequestBatchApproval, CanCancelBatchApproval);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.IsEmpty() then begin
            CanRequestLineApprovals := true;
            exit;
        end;

        WorkflowWebhookEntry.SetRange(Response, WorkflowWebhookEntry.Response::Pending);
        if WorkflowWebhookEntry.FindSet() then
            repeat
                if GenJournalLine.Get(WorkflowWebhookEntry."Record ID") then
                    if (GenJournalLine."Journal Batch Name" = GenJournalBatch.Name) and (GenJournalLine."Journal Template Name" = GenJournalBatch."Journal Template Name") then begin
                        CanRequestLineApprovals := false;
                        exit;
                    end;
            until WorkflowWebhookEntry.Next() = 0;

        CanRequestLineApprovals := true;
    end;

    procedure Cancel(var WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        Cancel(WorkflowWebhookEntry, false);
    end;

    procedure Cancel(var WorkflowWebhookEntry: Record "Workflow Webhook Entry"; OnDeletion: Boolean)
    begin
        VerifyResponseExpected(WorkflowWebhookEntry);

        if not CanCancel(WorkflowWebhookEntry) then
            Error(UserUnableToCancelErr, UserId);

        WorkflowWebhookEntry.Validate(Response, WorkflowWebhookEntry.Response::Cancel);
        WorkflowWebhookEntry.Modify(true);

        OnCancelWorkflow(WorkflowWebhookEntry, OnDeletion);
    end;

    procedure CancelByStepInstanceId(Id: Guid)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        if not FindWorkflowWebhookEntryByStepInstance(WorkflowWebhookEntry, Id) then
            Error(WorkflowStepInstanceIdNotFoundErr, Id);

        Cancel(WorkflowWebhookEntry);
    end;

    procedure CanContinue(WorkflowWebhookEntry: Record "Workflow Webhook Entry"): Boolean
    begin
        exit(TryCheckCanContinue(WorkflowWebhookEntry));
    end;

    [TryFunction]
    local procedure TryCheckCanContinue(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        VerifyCanAct(WorkflowWebhookEntry);
    end;

    procedure CanReject(WorkflowWebhookEntry: Record "Workflow Webhook Entry"): Boolean
    begin
        exit(TryCheckCanReject(WorkflowWebhookEntry));
    end;

    [TryFunction]
    local procedure TryCheckCanReject(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        VerifyCanAct(WorkflowWebhookEntry);
    end;

    procedure Continue(var WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        VerifyResponseExpected(WorkflowWebhookEntry);
        TryCheckCanContinue(WorkflowWebhookEntry);

        WorkflowWebhookEntry.Validate(Response, WorkflowWebhookEntry.Response::Continue);
        WorkflowWebhookEntry.Modify(true);

        OnContinueWorkflow(WorkflowWebhookEntry);
    end;

    procedure ContinueByStepInstanceId(Id: Guid)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        if not FindWorkflowWebhookEntryByStepInstance(WorkflowWebhookEntry, Id) then
            Error(WorkflowStepInstanceIdNotFoundErr, Id);

        Continue(WorkflowWebhookEntry);
    end;

    procedure GenerateRequest(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        CreateWorkflowWebhookEntry(RecRef, WorkflowStepInstance, WorkflowWebhookEntry);

        SendWebhookNotificaton(WorkflowStepInstance);
    end;

    procedure Reject(var WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        VerifyResponseExpected(WorkflowWebhookEntry);

        TryCheckCanReject(WorkflowWebhookEntry);

        WorkflowWebhookEntry.Validate(Response, WorkflowWebhookEntry.Response::Reject);
        WorkflowWebhookEntry.Modify(true);

        OnRejectWorkflow(WorkflowWebhookEntry);
    end;

    procedure RejectByStepInstanceId(Id: Guid)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        if not FindWorkflowWebhookEntryByStepInstance(WorkflowWebhookEntry, Id) then
            Error(WorkflowStepInstanceIdNotFoundErr, Id);

        Reject(WorkflowWebhookEntry);
    end;

    procedure SendWebhookNotificaton(WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowWebhookNotification: Codeunit "Workflow Webhook Notification";
        IsTaskSchedulerAllowed: Boolean;
    begin
        WorkflowWebhookNotification.StartNotification(WorkflowStepInstance.ID);

        IsTaskSchedulerAllowed := true;
        OnFindTaskSchedulerAllowed(IsTaskSchedulerAllowed);

        if IsTaskSchedulerAllowed then
            TASKSCHEDULER.CreateTask(CODEUNIT::"Workflow Webhook Notify Task", 0, true,
              CompanyName, 0DT, WorkflowStepInstance.RecordId)
        else
            CODEUNIT.Run(CODEUNIT::"Workflow Webhook Notify Task", WorkflowStepInstance);
    end;

    local procedure VerifyCanAct(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        Session.LogMessage('0000G8Y', StrSubstNo(CheckingUserActionsTelemetryMsg, WorkflowWebhookEntry.Response, IsNullGuid(WorkflowWebhookEntry."Response Argument")), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        if WorkflowWebhookEntry.Response <> WorkflowWebhookEntry.Response::Pending then
            Error(EntryIsNotPendingErr, WorkflowWebhookEntry.TableCaption());

        WorkflowStepArgument.Get(WorkflowWebhookEntry."Response Argument");

        case WorkflowStepArgument."Response Type" of
            WorkflowStepArgument."Response Type"::"User ID":
                if WorkflowStepArgument."Response User ID" <> UserId then
                    Error(DifferentUserExpectedErr, UserId, WorkflowStepArgument."Response User ID");
            else
                Error(WorkflowNotWaitingForUserErr, WorkflowStepArgument.TableCaption());
        end;
    end;

    local procedure CreateWorkflowWebhookEntry(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; var WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        if IsNullGuid(WorkflowStepInstance.Argument) or not WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            Clear(WorkflowStepArgument);

        WorkflowWebhookEntry.Init();
        WorkflowWebhookEntry."Workflow Step Instance ID" := WorkflowStepInstance.ID;
        WorkflowWebhookEntry."Initiated By User ID" := UserId;
        WorkflowWebhookEntry.Response := GetInitialResponseValue(WorkflowStepInstance.ID, WorkflowStepInstance."Workflow Code",
            WorkflowStepArgument);
        WorkflowWebhookEntry."Response Argument" := WorkflowStepArgument.ID;
        WorkflowWebhookEntry."Date-Time Initiated" := CurrentDateTime;
        WorkflowWebhookEntry."Last Date-Time Modified" := WorkflowWebhookEntry."Date-Time Initiated";
        WorkflowWebhookEntry."Record ID" := RecRef.RecordId;

        case RecRef.Number of
            DATABASE::Customer:
                begin
                    RecRef.SetTable(Customer);
                    WorkflowWebhookEntry."Data ID" := Customer.SystemId;
                end;
            DATABASE::"Gen. Journal Batch":
                begin
                    RecRef.SetTable(GenJournalBatch);
                    WorkflowWebhookEntry."Data ID" := GenJournalBatch.SystemId;
                end;
            DATABASE::"Gen. Journal Line":
                begin
                    RecRef.SetTable(GenJournalLine);
                    WorkflowWebhookEntry."Data ID" := GenJournalLine.SystemId;
                end;
            Database::"Requisition Wksh. Name":
                begin
                    RecRef.SetTable(RequisitionWkshName);
                    WorkflowWebhookEntry."Data ID" := RequisitionWkshName.SystemId;
                end;
            DATABASE::Item:
                begin
                    RecRef.SetTable(Item);
                    WorkflowWebhookEntry."Data ID" := Item.SystemId;
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    WorkflowWebhookEntry."Data ID" := PurchaseHeader.SystemId;
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    WorkflowWebhookEntry."Data ID" := SalesHeader.SystemId;
                end;
            DATABASE::Vendor:
                begin
                    RecRef.SetTable(Vendor);
                    WorkflowWebhookEntry."Data ID" := Vendor.SystemId;
                end;
            else
                Error(UnsupportedRecordTypeErr, RecRef.Caption);
        end;

        WorkflowWebhookEntry.Insert(true);
    end;

    local procedure GetInitialResponseValue(WorkflowStepInstanceID: Guid; WorkflowCode: Code[20]; WorkflowStepArgument: Record "Workflow Step Argument"): Integer
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStep: Record "Workflow Step";
        WorkflowWebhookEvents: Codeunit "Workflow Webhook Events";
        ResponseTypeNotExpected: Option;
    begin
        ResponseTypeNotExpected := WorkflowStepArgument."Response Type"::"Not Expected";

        if WorkflowStepArgument.IsEmpty() or (WorkflowStepArgument."Response Type" <> ResponseTypeNotExpected) then begin
            WorkflowStepInstance.SetLoadFields("Workflow Step ID");
            WorkflowStepInstance.Init();
            WorkflowStepInstance.SetRange(ID, WorkflowStepInstanceID);
            WorkflowStepInstance.SetRange("Workflow Code", WorkflowCode);

            if WorkflowStepInstance.FindSet() then
                repeat
                    if WorkflowStep.Get(WorkflowStepInstance."Workflow Code", WorkflowStepInstance."Workflow Step ID") then
                        if WorkflowStep."Function Name" = WorkflowWebhookEvents.WorkflowWebhookResponseReceivedEventCode() then
                            exit(DummyWorkflowWebhookEntry.Response::Pending);
                until WorkflowStepInstance.Next() = 0;
        end;

        exit(DummyWorkflowWebhookEntry.Response::NotExpected);
    end;

    local procedure FindWorkflowWebhookEntryByStepInstance(var WorkflowWebhookEntry: Record "Workflow Webhook Entry"; Id: Guid): Boolean
    begin
        WorkflowWebhookEntry.SetCurrentKey("Workflow Step Instance ID");
        WorkflowWebhookEntry.SetRange("Workflow Step Instance ID", Id);

        exit(WorkflowWebhookEntry.FindFirst());
    end;

    procedure FindWorkflowWebhookEntryByRecordIdAndResponse(var WorkflowWebhookEntry: Record "Workflow Webhook Entry"; RecordId: RecordID; ResponseStatus: Option): Boolean
    begin
        WorkflowWebhookEntry.SetRange("Record ID", RecordId);
        WorkflowWebhookEntry.SetRange(Response, ResponseStatus);

        exit(WorkflowWebhookEntry.FindFirst())
    end;

    procedure HasPendingWorkflowWebhookEntryByRecordId(RecordId: RecordID): Boolean
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.SetRange("Record ID", RecordId);
        WorkflowWebhookEntry.SetRange(Response, WorkflowWebhookEntry.Response::Pending);
        exit(not WorkflowWebhookEntry.IsEmpty());
    end;

    procedure GetDirectApproverForRequestor(RequestorEmailAddress: Text): Text
    var
        UserSetup: Record "User Setup";
        User: Record User;
        UserName: Code[50];
    begin
        if RequestorEmailAddress = '' then
            Error(EmailNotProvidedErr);

        // Get user name based on the requestor email address
        UserName := GetUserBasedOnEmail(RequestorEmailAddress);

        UserSetup.Reset();
        // Find a user's approval setup
        if not UserSetup.Get(UserName) then
            Error(UserNotFoundErr, UserName);

        User.Reset();
        // Find a user based on the approver id
        User.SetFilter("User Name", '%1', UserSetup."Approver ID");

        if not User.FindFirst() then
            Error(ApproverNotFoundErr, UserSetup."User ID");

        // Return the approver email address
        exit(User."Authentication Email");

    end;

    procedure FindAndCancel(RecordId: RecordID)
    begin
        FindAndCancel(RecordId, false);
    end;

    procedure FindAndCancel(RecordId: RecordID; OnDeletion: Boolean)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        // Searches for and then cancels the webhook entry with the given ID, if possible.
        // (Used by the various Cancel ribbon buttons.)
        if FindWorkflowWebhookEntryByRecordIdAndResponse(WorkflowWebhookEntry, RecordId, WorkflowWebhookEntry.Response::Pending) and
           CanCancel(WorkflowWebhookEntry)
        then
            Cancel(WorkflowWebhookEntry, OnDeletion);
    end;

    procedure DeleteWorkflowWebhookEntries(RecordId: RecordID)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        if FindWorkflowWebhookEntryByRecordIdAndResponse(WorkflowWebhookEntry, RecordId, WorkflowWebhookEntry.Response::Pending) then begin
            VerifyResponseExpected(WorkflowWebhookEntry);

            if not CanCancel(WorkflowWebhookEntry) then
                Error(UserUnableToDeleteErr, UserId);

            WorkflowWebhookEntry.SetRange("Record ID", RecordId);
            if WorkflowWebhookEntry.FindFirst() then
                WorkflowWebhookEntry.DeleteAll();
        end;
    end;

    procedure RenameRecord(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
    begin
        WorkflowWebhookEntry.SetRange("Record ID", OldRecordId);
        if WorkflowWebhookEntry.FindFirst() then
            WorkflowWebhookEntry.ModifyAll("Record ID", NewRecordId, true);
    end;

    local procedure GetUserBasedOnEmail(Email: Text): Code[50]
    var
        User: Record User;
    begin
        // Find a user based on the authentication email address
        User.SetFilter("Authentication Email", '%1', Email);

        if not User.FindFirst() then
            Error(EmailNotAssociatedWithUserErr, Email);

        exit(User."User Name");
    end;

    local procedure VerifyResponseExpected(WorkflowWebhookEntry: Record "Workflow Webhook Entry")
    begin
        if WorkflowWebhookEntry.Response = WorkflowWebhookEntry.Response::NotExpected then
            Error(ResponseNotExpectedErr);

        if WorkflowWebhookEntry.Response <> WorkflowWebhookEntry.Response::Pending then
            Error(ResponseAlreadyReceivedErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTaskSchedulerAllowed(var IsTaskSchedulingAllowed: Boolean)
    begin
    end;
}
