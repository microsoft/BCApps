// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Posting;
using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Security.User;
using System.Telemetry;
using System.Threading;
using System.Utilities;

codeunit 1535 "Approvals Mgmt."
{
    Permissions = TableData "Approval Entry" = Rimd,
                  TableData "Approval Comment Line" = rimd,
                  TableData "Posted Approval Entry" = rimd,
                  TableData "Posted Approval Comment Line" = rimd,
                  TableData "Overdue Approval Entry" = rimd,
                  TableData "Notification Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";

#pragma warning disable AA0470
        UserIdNotInSetupErr: Label 'User ID %1 does not exist in the Approval User Setup window.', Comment = 'User ID NAVUser does not exist in the Approval User Setup window.';
        ApproverUserIdNotInSetupErr: Label 'You must set up an approver for user ID %1 in the Approval User Setup window.', Comment = 'You must set up an approver for user ID NAVUser in the Approval User Setup window.';
        WFUserGroupNotInSetupErr: Label 'The workflow user group member with user ID %1 does not exist in the Approval User Setup window.', Comment = 'The workflow user group member with user ID NAVUser does not exist in the Approval User Setup window.';
        SubstituteNotFoundErr: Label 'There is no substitute, direct approver, or approval administrator for user ID %1 in the Approval User Setup window.', Comment = 'There is no substitute for user ID NAVUser in the Approval User Setup window.';
#pragma warning restore AA0470
        NoSuitableApproverFoundErr: Label 'No qualified approver was found.';
        DelegateOnlyOpenRequestsErr: Label 'You can only delegate open approval requests.';
        ApproveOnlyOpenRequestsErr: Label 'You can only approve open approval requests.';
        RejectOnlyOpenRequestsErr: Label 'You can only reject open approval entries.';
        ApprovalsDelegatedMsg: Label 'The selected approval requests have been delegated.';
        NoReqToApproveErr: Label 'There is no approval request to approve.';
        NoReqToRejectErr: Label 'There is no approval request to reject.';
        NoReqToDelegateErr: Label 'There is no approval request to delegate.';
        PendingApprovalMsg: Label 'An approval request has been sent.';
#pragma warning disable AA0470
        PurchaserUserNotFoundErr: Label 'The salesperson/purchaser user ID %1 does not exist in the Approval User Setup window for %2 %3.', Comment = 'Example: The salesperson/purchaser user ID NAVUser does not exist in the Approval User Setup window for Salesperson/Purchaser code AB.';
#pragma warning restore AA0470
        NoApprovalRequestsFoundErr: Label 'No approval requests exist.';
        NoWFUserGroupMembersErr: Label 'A workflow user group with at least one member must be set up.';
#pragma warning disable AA0470
        DocStatusChangedMsg: Label '%1 %2 has been automatically approved. The status has been changed to %3.', Comment = 'Order 1001 has been automatically approved. The status has been changed to Released.';
        UnsupportedRecordTypeErr: Label 'Record type %1 is not supported by this workflow response.', Comment = 'Record type Customer is not supported by this workflow response.';
#pragma warning restore AA0470
        SalesPrePostCheckErr: Label 'Sales %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Sales Order 321 must be approved...';
        PurchPrePostCheckErr: Label 'Purchase %1 %2 must be approved and released before you can perform this action.', Comment = '%1=document type, %2=document no., e.g. Purchase Order 321 must be approved...';
        NoWorkflowEnabledErr: Label 'No approval workflow for this record type is enabled.';
        ApprovalReqCanceledForSelectedLinesMsg: Label 'The approval request for the selected record has been canceled.';
        PendingJournalBatchApprovalExistsErr: Label 'An approval request already exists.', Comment = '%1 is the Document No. of the journal line';
        ApprovedJournalBatchApprovalExistsMsg: Label 'An approval request for this batch has already been sent and approved. Do you want to send another approval request?';
#pragma warning disable AA0470
        ApporvalChainIsUnsupportedMsg: Label 'Only Direct Approver is supported as Approver Limit Type option for %1. The approval request will be approved automatically.', Comment = 'Only Direct Approver is supported as Approver Limit Type option for Gen. Journal Batch DEFAULT, CASH. The approval request will be approved automatically.';
#pragma warning restore AA0470
        RecHasBeenApprovedMsg: Label '%1 has been approved.', Comment = '%1 = Record Id';
        NoPermissionToDelegateErr: Label 'You do not have permission to delegate one or more of the selected approval requests.';
        NothingToApproveErr: Label 'There is nothing to approve.';
        ApproverChainErr: Label 'No sufficient approver was found in the approver chain.';
        PreventModifyRecordWithOpenApprovalEntryMsg: Label 'You can''t modify a record pending approval. Add a comment or reject the approval to modify the record.';
        PreventInsertRecordWithOpenApprovalEntryForCurrUserMsg: Label 'You can''t insert a record for active batch approval request. To insert a record, you can Reject approval and document requested changes in approval comment lines.';
        PreventInsertRecordWithOpenApprovalEntryMsg: Label 'You can''t insert a record that has active approval request. Do you want to cancel the batch approval request first?';
        PreventDeleteRecordWithOpenApprovalEntryMsg: Label 'You can''t delete a record that has open approval entries. Do you want to cancel the approval request first?';
        PreventDeleteRecordWithOpenApprovalEntryForCurrUserMsg: Label 'You can''t delete a record that has open approval entries. To delete a record, you can Reject approval and document requested changes in approval comment lines.';
        PreventDeleteRecordWithOpenApprovalEntryForSenderMsg: Label 'You can''t delete a record that has open approval entries. To delete a record, you need to Cancel approval request first.';
        JobQueueDelegatedAdminCategoryTxt: Label 'AL JobQueueEntries Delegated Admin', Locked = true;
        JobQueueWorkflowSetupErr: Label 'The Job Queue approval workflow has not been setup.';
        DelegatedAdminSendingApprovalLbl: Label 'Delegated admin sending approval', Locked = true;
        ImposedRestrictionLbl: Label 'Imposed restriction';
        PendingApprovalLbl: Label 'Pending Approval';
        RestrictBatchUsageDetailsLbl: Label 'The restriction was imposed because the journal batch requires approval.';

    [IntegrationEvent(false, false)]
    procedure OnSendPurchaseDocForApproval(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendSalesDocForApproval(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendIncomingDocForApproval(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelPurchaseApprovalRequest(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelSalesApprovalRequest(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelIncomingDocApprovalRequest(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendCustomerForApproval(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendVendorForApproval(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendItemForApproval(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelCustomerApprovalRequest(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelVendorApprovalRequest(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelItemApprovalRequest(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendGeneralJournalBatchForApproval(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelGeneralJournalBatchApprovalRequest(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendGeneralJournalLineForApproval(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelGeneralJournalLineApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendRequisitionWkshBatchForApproval(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelRequisitionWkshBatchApprovalRequest(var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApproveApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelegateApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRenameRecordInApprovalRequest(OldRecordId: RecordID; NewRecordId: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDeleteRecordInApprovalRequest(RecordIDToApprove: RecordID)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSendJobQueueEntryForApproval(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCancelJobQueueEntryApprovalRequest(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
    end;

    procedure ApproveRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToApproveErr);

        ApprovalEntry.SetRecFilter();
        ApproveApprovalRequests(ApprovalEntry);
    end;

    procedure ApproveGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            ApproveRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            ApproveRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure ApproveRequisitionWkshLineRequest(RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalEntry: Record "Approval Entry";
    begin
        RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, RequisitionWkshName.RecordId()) then
            ApproveRecordApprovalRequest(RequisitionWkshName.RecordId());
    end;

    procedure RejectRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToRejectErr);

        ApprovalEntry.SetRecFilter();
        RejectApprovalRequests(ApprovalEntry);
    end;

    procedure RejectGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            RejectRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            RejectRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure RejectRequisitionWkshLineRequest(RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalEntry: Record "Approval Entry";
    begin
        RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, RequisitionWkshName.RecordId()) then
            RejectRecordApprovalRequest(RequisitionWkshName.RecordId());
    end;

    procedure DelegateRecordApprovalRequest(RecordID: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        if not FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecordID) then
            Error(NoReqToDelegateErr);

        ApprovalEntry.SetRecFilter();
        DelegateApprovalRequests(ApprovalEntry);
    end;

    procedure DelegateGenJournalLineRequest(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            DelegateRecordApprovalRequest(GenJournalBatch.RecordId);
        Clear(ApprovalEntry);
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            DelegateRecordApprovalRequest(GenJournalLine.RecordId);
    end;

    procedure DelegateRequisitionWkshLineRequest(RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalEntry: Record "Approval Entry";
    begin
        RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        if FindOpenApprovalEntryForCurrUser(ApprovalEntry, RequisitionWkshName.RecordId()) then
            DelegateRecordApprovalRequest(RequisitionWkshName.RecordId());
    end;

    procedure ApproveApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApproveApprovalRequests(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                ApproveSelectedApprovalRequest(ApprovalEntryToUpdate);
            until ApprovalEntry.Next() = 0;
    end;

    procedure RejectApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectApprovalRequests(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                RejectSelectedApprovalRequest(ApprovalEntryToUpdate);
            until ApprovalEntry.Next() = 0;
    end;

    procedure DelegateApprovalRequests(var ApprovalEntry: Record "Approval Entry")
    var
        ApprovalEntryToUpdate: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelegateApprovalRequests(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        if ApprovalEntry.FindSet() then begin
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                DelegateSelectedApprovalRequest(ApprovalEntryToUpdate, true);
            until ApprovalEntry.Next() = 0;
            Message(ApprovalsDelegatedMsg);
        end;

        OnAfterDelegateApprovalRequest(ApprovalEntry);
    end;

    local procedure ApproveSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApproveSelectedApprovalRequest(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;
        CheckOpenStatus(ApprovalEntry, "Approval Action"::Approve, ApproveOnlyOpenRequestsErr);

        if ApprovalEntry."Approver ID" <> UserId then
            CheckUserAsApprovalAdministrator(ApprovalEntry);

        ApprovalEntry.Validate(Status, ApprovalEntry.Status::Approved);
        ApprovalEntry.Modify(true);
        OnApproveApprovalRequest(ApprovalEntry);
    end;

    local procedure RejectSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectSelectedApprovalRequest(ApprovalEntry, IsHandled);
        if not IsHandled then begin
            CheckOpenStatus(ApprovalEntry, "Approval Action"::Reject, RejectOnlyOpenRequestsErr);

            if ApprovalEntry."Approver ID" <> UserId then
                CheckUserAsApprovalAdministrator(ApprovalEntry);

            OnRejectApprovalRequest(ApprovalEntry);
            ApprovalEntry.Get(ApprovalEntry."Entry No.");
            ApprovalEntry.Validate(Status, ApprovalEntry.Status::Rejected);
            ApprovalEntry.Modify(true);
        end;

        OnAfterRejectSelectedApprovalRequest(ApprovalEntry);
    end;

    procedure DelegateSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry"; CheckCurrentUser: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelegateSelectedApprovalRequest(ApprovalEntry, CheckCurrentUser, IsHandled);
        if not IsHandled then begin
            CheckOpenStatus(ApprovalEntry, "Approval Action"::Delegate, DelegateOnlyOpenRequestsErr);

            if CheckCurrentUser and (not ApprovalEntry.CanCurrentUserEdit()) then
                Error(NoPermissionToDelegateErr);

            IsHandled := false;
            OnDelegateSelectedApprovalRequestOnBeforeSubstituteUserIdForApprovalEntry(ApprovalEntry, IsHandled);
            if IsHandled then
                exit;

            SubstituteUserIdForApprovalEntry(ApprovalEntry);
        end;

        OnAfterDelegateSelectedApprovalRequest(ApprovalEntry);
    end;

    local procedure CheckOpenStatus(ApprovalEntry: Record "Approval Entry"; ApprovalAction: Enum "Approval Action"; ErrorMessage: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckStatus(ApprovalEntry, ApprovalAction, IsHandled);
        if IsHandled then
            exit;

        if ApprovalEntry.Status <> ApprovalEntry.Status::Open then
            Error(ErrorMessage);
    end;

    local procedure SubstituteUserIdForApprovalEntry(ApprovalEntry: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        ApprovalAdminUserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubstituteUserIdForApprovalEntry(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        if not UserSetup.Get(ApprovalEntry."Approver ID") then
            Error(ApproverUserIdNotInSetupErr, ApprovalEntry."Sender ID");
        OnSubstituteUserIdForApprovalEntryOnAfterCheckUserSetupApprovalEntryApproverID(UserSetup, ApprovalEntry);

        if UserSetup.Substitute = '' then
            if UserSetup."Approver ID" = '' then begin
                ApprovalAdminUserSetup.SetRange("Approval Administrator", true);
                if ApprovalAdminUserSetup.FindFirst() then
                    UserSetup.Get(ApprovalAdminUserSetup."User ID")
                else
                    Error(SubstituteNotFoundErr, UserSetup."User ID");
            end else
                UserSetup.Get(UserSetup."Approver ID")
        else
            UserSetup.Get(UserSetup.Substitute);

        OnSubstituteUserIdForApprovalEntryOnBeforeAssignApproverID(ApprovalEntry, UserSetup);
        ApprovalEntry."Approver ID" := UserSetup."User ID";
        ApprovalEntry.Modify(true);
        OnDelegateApprovalRequest(ApprovalEntry);
    end;

    procedure FindOpenApprovalEntryForCurrUser(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Approver ID", UserId);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if not ApprovalEntry.IsEmpty() then
            ApprovalEntry.SetRange("Related to Change", false);

        OnFindOpenApprovalEntryForCurrUserOnAfterApprovalEntrySetFilters(ApprovalEntry);
        exit(ApprovalEntry.FindFirst());
    end;

    procedure FindApprovalEntryForCurrUser(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange("Approver ID", UserId);
        OnFindApprovalEntryForCurrUserOnAfterApprovalEntrySetFilters(ApprovalEntry);

        exit(ApprovalEntry.FindFirst());
    end;

    procedure FindLastApprovalEntryForCurrUser(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange("Approver ID", UserId);
        exit(ApprovalEntry.FindLast());
    end;

    procedure FindApprovalEntryByRecordId(var ApprovalEntry: Record "Approval Entry"; RecordID: RecordID): Boolean
    begin
        ApprovalEntry.Reset();
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        exit(ApprovalEntry.FindLast());
    end;

    local procedure ShowPurchApprovalStatus(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowPurchApprovalStatus(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader.Find();

        case PurchaseHeader.Status of
            PurchaseHeader.Status::Released:
                Message(DocStatusChangedMsg, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader.Status);
            PurchaseHeader.Status::"Pending Approval":
                if HasOpenOrPendingApprovalEntries(PurchaseHeader.RecordId) then
                    Message(PendingApprovalMsg);
            PurchaseHeader.Status::"Pending Prepayment":
                Message(DocStatusChangedMsg, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader.Status);
        end;
    end;

    local procedure ShowSalesApprovalStatus(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSalesApprovalStatus(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Find();

        case SalesHeader.Status of
            SalesHeader.Status::Released:
                Message(DocStatusChangedMsg, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.Status);
            SalesHeader.Status::"Pending Approval":
                if HasOpenOrPendingApprovalEntries(SalesHeader.RecordId) then
                    Message(PendingApprovalMsg);
            SalesHeader.Status::"Pending Prepayment":
                Message(DocStatusChangedMsg, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.Status);
        end;
    end;

    local procedure ShowApprovalStatus(RecId: RecordID; WorkflowInstanceId: Guid)
    begin
        if HasPendingApprovalEntriesForWorkflow(RecId, WorkflowInstanceId) then
            Message(PendingApprovalMsg)
        else
            Message(RecHasBeenApprovedMsg, Format(RecId, 0, 1));
    end;

    procedure ApproveApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        OnApproveApprovalRequestsForRecordOnAfterApprovalEntrySetFilters(ApprovalEntry, WorkflowStepInstance, RecRef);
        if ApprovalEntry.FindSet() then
            repeat
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntry.Status::Approved);
                OnApproveApprovalRequestsForRecordOnBeforeApprovalEntryToUpdateModify(ApprovalEntryToUpdate);
                ApprovalEntryToUpdate.Modify(true);
                CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
            until ApprovalEntry.Next() = 0;
    end;

    procedure CancelApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        OldStatus: Enum "Approval Status";
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        OnCancelApprovalRequestsForRecordOnAfterSetApprovalEntryFilters(ApprovalEntry, RecRef);
        if ApprovalEntry.FindSet() then
            repeat
                OldStatus := ApprovalEntry.Status;
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntryToUpdate.Status::Canceled);
                ApprovalEntryToUpdate.Modify(true);
                if OldStatus in [ApprovalEntry.Status::Open, ApprovalEntry.Status::Approved] then
                    CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
                OnCancelApprovalRequestsForRecordOnAfterCreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance, OldStatus);
            until ApprovalEntry.Next() = 0;
    end;

    procedure RejectApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        OldStatus: Enum "Approval Status";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRejectApprovalRequestsForRecord(RecRef, WorkflowStepInstance, IsHandled);
        if IsHandled then
            exit;

        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetFilter(Status, '<>%1&<>%2', ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        OnRejectApprovalRequestsForRecordOnAfterSetApprovalEntryFilters(ApprovalEntry, WorkflowStepInstance, RecRef);
        if ApprovalEntry.FindSet() then
            repeat
                OldStatus := ApprovalEntry.Status;
                ApprovalEntryToUpdate := ApprovalEntry;
                ApprovalEntryToUpdate.Validate(Status, ApprovalEntry.Status::Rejected);
                OnRejectApprovalRequestsForRecordOnBeforeApprovalEntryToUpdateModify(ApprovalEntryToUpdate);
                ApprovalEntryToUpdate.Modify(true);
                if OldStatus in [ApprovalEntry.Status::Open] then
                    CreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance);
                OnRejectApprovalRequestsForRecordOnAfterCreateApprovalEntryNotification(ApprovalEntryToUpdate, WorkflowStepInstance, OldStatus);
            until ApprovalEntry.Next() = 0;
    end;

    procedure SendApprovalRequestFromRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntry2: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Record ID to Approve", Status, "Workflow Step Instance ID", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Created);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        IsHandled := false;
        OnSendApprovalRequestFromRecordOnAfterSetApprovalEntryFilters(ApprovalEntry, RecRef, IsHandled, WorkflowStepInstance);
        if IsHandled then
            exit;

        if ApprovalEntry.FindFirst() then begin
            ApprovalEntry2.CopyFilters(ApprovalEntry);
            ApprovalEntry2.SetRange("Sequence No.", ApprovalEntry."Sequence No.");
            if ApprovalEntry2.FindSet(true) then
                repeat
                    ApprovalEntry2.Validate(Status, ApprovalEntry2.Status::Open);
                    ApprovalEntry2.Modify(true);
                    CreateApprovalEntryNotification(ApprovalEntry2, WorkflowStepInstance);
                until ApprovalEntry2.Next() = 0;
            IsHandled := false;
            OnSendApprovalRequestFromRecordOnBeforeFindApprovedApprovalEntryForWorkflowUserGroup(ApprovalEntry, IsHandled);
            if not IsHandled then
                if FindApprovedApprovalEntryForWorkflowUserGroup(ApprovalEntry, WorkflowStepInstance) then
                    if (ApprovalEntry."Sender ID" <> ApprovalEntry."Approver ID") or
                    FindOpenApprovalEntryForSequenceNo(RecRef, WorkflowStepInstance, ApprovalEntry."Sequence No.")
                    then
                        OnApproveApprovalRequest(ApprovalEntry);
            exit;
        end;

        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        if ApprovalEntry.FindLast() then
            OnApproveApprovalRequest(ApprovalEntry)
        else
            Error(NoApprovalRequestsFoundErr);
    end;

    procedure SendApprovalRequestFromApprovalEntry(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntry2: Record "Approval Entry";
        ApprovalEntry3: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendApprovalRequestFromApprovalEntry(ApprovalEntry, WorkflowStepInstance, IsHandled);
        if IsHandled then
            exit;

        if ApprovalEntry.Status = ApprovalEntry.Status::Open then begin
            CreateApprovalEntryNotification(ApprovalEntry, WorkflowStepInstance);
            exit;
        end;

        if FindOpenApprovalEntriesForWorkflowStepInstance(ApprovalEntry, WorkflowStepInstance."Record ID") then
            exit;

        ApprovalEntry2.SetCurrentKey("Table ID", "Document Type", "Document No.", "Sequence No.");
        ApprovalEntry2.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        ApprovalEntry2.SetRange(Status, ApprovalEntry2.Status::Created);
        OnSendApprovalRequestFromApprovalEntryOnAfterSetApprovalEntry2Filters(ApprovalEntry2, ApprovalEntry);

        if ApprovalEntry2.FindFirst() then begin
            ApprovalEntry3.CopyFilters(ApprovalEntry2);
            ApprovalEntry3.SetRange("Sequence No.", ApprovalEntry2."Sequence No.");
            if ApprovalEntry3.FindSet() then
                repeat
                    ApprovalEntry3.Validate(Status, ApprovalEntry3.Status::Open);
                    ApprovalEntry3.Modify(true);
                    CreateApprovalEntryNotification(ApprovalEntry3, WorkflowStepInstance);
                until ApprovalEntry3.Next() = 0;
        end;
    end;

    procedure CreateApprovalRequests(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        ApprovalEntryArgument: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprovalRequests(RecRef, WorkflowStepInstance, IsHandled);
        if IsHandled then
            exit;

        PopulateApprovalEntryArgument(RecRef, WorkflowStepInstance, ApprovalEntryArgument);

        if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            case WorkflowStepArgument."Approver Type" of
                WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser":
                    CreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                WorkflowStepArgument."Approver Type"::Approver:
                    CreateApprReqForApprTypeApprover(WorkflowStepArgument, ApprovalEntryArgument);
                WorkflowStepArgument."Approver Type"::"Workflow User Group":
                    CreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument, ApprovalEntryArgument);
                else
                    OnCreateApprovalRequestsOnElseCase(WorkflowStepArgument, ApprovalEntryArgument);
            end;

        OnCreateApprovalRequestsOnAfterCreateRequests(RecRef, WorkflowStepArgument, ApprovalEntryArgument);

        if WorkflowStepArgument."Show Confirmation Message" then
            InformUserOnStatusChange(RecRef, WorkflowStepInstance.ID);
    end;

    procedure CreateAndAutomaticallyApproveRequest(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        ApprovalEntryArgument: Record "Approval Entry";
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        PopulateApprovalEntryArgument(RecRef, WorkflowStepInstance, ApprovalEntryArgument);
        if not WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
            WorkflowStepArgument.Init();

        CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);

        InformUserOnStatusChange(RecRef, WorkflowStepInstance.ID);
    end;

    local procedure CreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        ApprovalEntryArgument.TestField("Salespers./Purch. Code");

        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
            WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                begin
                    CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForSpecificUser(WorkflowStepArgument, ApprovalEntryArgument);
                end;
        end;

        OnAfterCreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    local procedure CreateApprReqForApprTypeApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain":
                begin
                    CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                CreateApprovalRequestForApprover(WorkflowStepArgument, ApprovalEntryArgument);
            WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                begin
                    CreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument);
                    CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument, ApprovalEntryArgument);
                end;
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                CreateApprovalRequestForSpecificUser(WorkflowStepArgument, ApprovalEntryArgument);
        end;

        OnAfterCreateApprReqForApprTypeApprover(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    local procedure CreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        WorkflowUserGroupMember: Record "Workflow User Group Member";
        ApproverId: Code[50];
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprReqForApprTypeWorkflowUserGroup(WorkflowUserGroupMember, WorkflowStepArgument, ApprovalEntryArgument, SequenceNo, IsHandled);
        if not IsHandled then begin
            if not UserSetup.Get(UserId) then
                Error(UserIdNotInSetupErr, UserId);
            SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

            WorkflowUserGroupMember.SetCurrentKey("Workflow User Group Code", "Sequence No.");
            WorkflowUserGroupMember.SetRange("Workflow User Group Code", WorkflowStepArgument."Workflow User Group Code");

            if not WorkflowUserGroupMember.FindSet() then
                Error(NoWFUserGroupMembersErr);

            repeat
                ApproverId := WorkflowUserGroupMember."User Name";
                if not UserSetup.Get(ApproverId) then
                    Error(WFUserGroupNotInSetupErr, ApproverId);
                IsHandled := false;
                OnCreateApprReqForApprTypeWorkflowUserGroupOnBeforeMakeApprovalEntry(WorkflowUserGroupMember, ApprovalEntryArgument, WorkflowStepArgument, ApproverId, IsHandled);
                if not IsHandled then
                    MakeApprovalEntry(ApprovalEntryArgument, SequenceNo + WorkflowUserGroupMember."Sequence No.", ApproverId, WorkflowStepArgument);
            until WorkflowUserGroupMember.Next() = 0;
        end;
        OnAfterCreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument, ApprovalEntryArgument);
    end;

    procedure CreateApprovalRequestForChainOfApprovers(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        CreateApprovalRequestForApproverChain(WorkflowStepArgument, ApprovalEntryArgument, false);
    end;

    procedure CreateApprovalRequestForApproverWithSufficientLimit(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
        CreateApprovalRequestForApproverChain(WorkflowStepArgument, ApprovalEntryArgument, true);
    end;

    local procedure CreateApprovalRequestForApproverChain(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; SufficientApproverOnly: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        ApproverId: Code[50];
        SequenceNo: Integer;
        MaxCount: Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprovalRequestForApproverChain(WorkflowStepArgument, ApprovalEntryArgument, SufficientApproverOnly, IsHandled);
        if IsHandled then
            exit;

        ApproverId := CopyStr(UserId(), 1, MaxStrLen(ApproverId));

        ApprovalEntry.SetCurrentKey("Record ID to Approve", "Workflow Step Instance ID", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", ApprovalEntryArgument."Table ID");
        ApprovalEntry.SetRange("Record ID to Approve", ApprovalEntryArgument."Record ID to Approve");
        ApprovalEntry.SetRange("Workflow Step Instance ID", ApprovalEntryArgument."Workflow Step Instance ID");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Created);
        OnCreateApprovalRequestForApproverChainOnAfterSetApprovalEntryFilters(ApprovalEntry, ApprovalEntryArgument);
        if ApprovalEntry.FindLast() then
            ApproverId := ApprovalEntry."Approver ID"
        else
            if (WorkflowStepArgument."Approver Type" = WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser") and
                (WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver")
            then begin
                FindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument);
                ApproverId := UserSetup."User ID";
            end;

        UserSetup.Reset();
        MaxCount := UserSetup.Count();

        if not UserSetup.Get(ApproverId) then
            Error(ApproverUserIdNotInSetupErr, ApprovalEntry."Sender ID");

        IsHandled := false;
        OnCreateApprovalRequestForApproverChainOnAfterCheckApprovalEntrySenderID(UserSetup, WorkflowStepArgument, ApprovalEntryArgument, IsHandled);
        if IsHandled then
            exit;

        if not IsSufficientApprover(UserSetup, ApprovalEntryArgument) then
            repeat
                i += 1;
                if i > MaxCount then
                    Error(ApproverChainErr);
                ApproverId := UserSetup."Approver ID";

                IsHandled := false;
                OnCreateApprovalRequestForApproverChainOnBeforeCheckApproverId(UserSetup, WorkflowStepArgument, ApprovalEntryArgument, IsHandled);
                if IsHandled then
                    exit;

                if ApproverId = '' then
                    Error(NoSuitableApproverFoundErr);

                if not UserSetup.Get(ApproverId) then
                    Error(ApproverUserIdNotInSetupErr, UserSetup."User ID");

                OnCreateApprovalRequestForApproverChainOnAfterCheckUserSetupSenderID(UserSetup, WorkflowStepArgument, ApprovalEntryArgument);

                // Approval Entry should not be created only when IsSufficientApprover is false and SufficientApproverOnly is true
                if IsSufficientApprover(UserSetup, ApprovalEntryArgument) or (not SufficientApproverOnly) then begin
                    SequenceNo := GetLastSequenceNo(ApprovalEntryArgument) + 1;
                    MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, ApproverId, WorkflowStepArgument);
                end;

            until IsSufficientApprover(UserSetup, ApprovalEntryArgument);

        OnAfterCreateApprovalRequestForApproverChain(ApprovalEntryArgument, ApproverId, WorkflowStepArgument, UserSetup, SufficientApproverOnly);
    end;

    local procedure CreateApprovalRequestForApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        UsrId: Code[50];
        SequenceNo: Integer;
        IsUserAllowedToApproveIfNoApprovalUserExists: Boolean;
    begin
        UsrId := UserId;

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        if not UserSetup.Get(UserId) then
            Error(UserIdNotInSetupErr, UsrId);

        IsUserAllowedToApproveIfNoApprovalUserExists := UserSetup."Approval Administrator";
        OnCreateApprovalRequestForApproverOnAfterCheckUserSetupUserID(UserSetup, WorkflowStepArgument, ApprovalEntryArgument, IsUserAllowedToApproveIfNoApprovalUserExists);

        UsrId := UserSetup."Approver ID";
        if not UserSetup.Get(UsrId) then begin
            if not IsUserAllowedToApproveIfNoApprovalUserExists then
                Error(ApproverUserIdNotInSetupErr, UserSetup."User ID");
            UsrId := UserId;
        end;

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UsrId, WorkflowStepArgument);
    end;

    local procedure CreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument, ApprovalEntryArgument, IsHandled);
        if IsHandled then
            exit;

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        FindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument);

        SequenceNo += 1;

        if WorkflowStepArgument."Approver Limit Type" = WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver" then begin
            if IsSufficientApprover(UserSetup, ApprovalEntryArgument) then
                MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserSetup."User ID", WorkflowStepArgument);
        end else
            MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserSetup."User ID", WorkflowStepArgument);
    end;

    procedure CreateApprovalRequestForUser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        SequenceNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprovalRequestForUser(WorkflowStepArgument, ApprovalEntryArgument, IsHandled);
        if IsHandled then
            exit;

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UserId, WorkflowStepArgument);
    end;

    procedure CreateApprovalRequestForSpecificUser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        UsrId: Code[50];
        SequenceNo: Integer;
    begin
        UsrId := WorkflowStepArgument."Approver User ID";

        SequenceNo := GetLastSequenceNo(ApprovalEntryArgument);

        if not UserSetup.Get(UsrId) then
            Error(UserIdNotInSetupErr, UsrId);

        SequenceNo += 1;
        MakeApprovalEntry(ApprovalEntryArgument, SequenceNo, UsrId, WorkflowStepArgument);
    end;

    procedure MakeApprovalEntry(ApprovalEntryArgument: Record "Approval Entry"; SequenceNo: Integer; ApproverId: Code[50]; WorkflowStepArgument: Record "Workflow Step Argument")
    var
        ApprovalEntry: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeApprovalEntry(ApprovalEntry, ApprovalEntryArgument, WorkflowStepArgument, ApproverId, IsHandled);
        if IsHandled then
            exit;

        ApprovalEntry."Table ID" := ApprovalEntryArgument."Table ID";
        ApprovalEntry."Document Type" := ApprovalEntryArgument."Document Type";
        ApprovalEntry."Document No." := ApprovalEntryArgument."Document No.";
        ApprovalEntry."Salespers./Purch. Code" := ApprovalEntryArgument."Salespers./Purch. Code";
        ApprovalEntry."Sequence No." := SequenceNo;
        ApprovalEntry."Sender ID" := CopyStr(UserId(), 1, 50);
        ApprovalEntry.Amount := ApprovalEntryArgument.Amount;
        ApprovalEntry."Amount (LCY)" := ApprovalEntryArgument."Amount (LCY)";
        ApprovalEntry."Currency Code" := ApprovalEntryArgument."Currency Code";
        ApprovalEntry."Approver ID" := ApproverId;
        ApprovalEntry."Workflow Step Instance ID" := ApprovalEntryArgument."Workflow Step Instance ID";
        if ApproverId = UserId then
            ApprovalEntry.Status := ApprovalEntry.Status::Approved
        else
            ApprovalEntry.Status := ApprovalEntry.Status::Created;
        ApprovalEntry."Date-Time Sent for Approval" := CreateDateTime(Today, Time);
        ApprovalEntry."Last Date-Time Modified" := CreateDateTime(Today, Time);
        ApprovalEntry."Last Modified By User ID" := CopyStr(UserId(), 1, 50);
        ApprovalEntry."Due Date" := CalcDate(WorkflowStepArgument."Due Date Formula", Today);

        case WorkflowStepArgument."Delegate After" of
            WorkflowStepArgument."Delegate After"::Never:
                Evaluate(ApprovalEntry."Delegation Date Formula", '');
            WorkflowStepArgument."Delegate After"::"1 day":
                Evaluate(ApprovalEntry."Delegation Date Formula", '<1D>');
            WorkflowStepArgument."Delegate After"::"2 days":
                Evaluate(ApprovalEntry."Delegation Date Formula", '<2D>');
            WorkflowStepArgument."Delegate After"::"5 days":
                Evaluate(ApprovalEntry."Delegation Date Formula", '<5D>');
            else
                Evaluate(ApprovalEntry."Delegation Date Formula", '');
        end;
        ApprovalEntry."Available Credit Limit (LCY)" := ApprovalEntryArgument."Available Credit Limit (LCY)";
        SetApproverType(WorkflowStepArgument, ApprovalEntry);
        SetLimitType(WorkflowStepArgument, ApprovalEntry);
        ApprovalEntry."Record ID to Approve" := ApprovalEntryArgument."Record ID to Approve";
        ApprovalEntry."Approval Code" := ApprovalEntryArgument."Approval Code";
        IsHandled := false;
        OnBeforeApprovalEntryInsert(ApprovalEntry, ApprovalEntryArgument, WorkflowStepArgument, ApproverId, IsHandled);
        if IsHandled then
            exit;
        ApprovalEntry.Insert(true);
    end;

    procedure CalcPurchaseDocAmount(PurchaseHeader: Record "Purchase Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        TotalPurchaseLine: Record "Purchase Line";
        TotalPurchaseLineLCY: Record "Purchase Line";
        PurchPost: Codeunit "Purch.-Post";
        TempAmount: Decimal;
        VAtText: Text[30];
    begin
        PurchaseHeader.CalcInvDiscForHeader();
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        OnCalcPurchaseDocAmountOnAfterPurchPostGetPurchLines(TempPurchaseLine);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(
          PurchaseHeader, TempPurchaseLine, 0, TotalPurchaseLine, TotalPurchaseLineLCY,
          TempAmount, VAtText);
        ApprovalAmount := TotalPurchaseLine.Amount;
        ApprovalAmountLCY := TotalPurchaseLineLCY.Amount;

        OnAfterCalcPurchaseDocAmount(PurchaseHeader, TotalPurchaseLine, TotalPurchaseLineLCY, ApprovalAmount, ApprovalAmountLCY);
    end;

    procedure CalcSalesDocAmount(SalesHeader: Record "Sales Header"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    var
        TempSalesLine: Record "Sales Line" temporary;
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        TempAmount: array[5] of Decimal;
        VAtText: Text[30];
    begin
        SalesHeader.CalcInvDiscForHeader();
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, 0);
        Clear(SalesPost);
        SalesPost.SumSalesLinesTemp(
          SalesHeader, TempSalesLine, 0, TotalSalesLine, TotalSalesLineLCY,
          TempAmount[1], VAtText, TempAmount[2], TempAmount[3], TempAmount[4]);
        ApprovalAmount := TotalSalesLine.Amount;
        ApprovalAmountLCY := TotalSalesLineLCY.Amount;
        OnAfterCalcSalesDocAmount(SalesHeader, TotalSalesLine, TotalSalesLineLCY, ApprovalAmount, ApprovalAmountLCY);
    end;

    procedure PopulateApprovalEntryArgument(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; var ApprovalEntryArgument: Record "Approval Entry")
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        IncomingDocument: Record "Incoming Document";
        Vendor: Record Vendor;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        ApprovalAmount: Decimal;
        ApprovalAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePopulateApprovalEntryArgument(WorkflowStepInstance, ApprovalEntryArgument, IsHandled);
        if not IsHandled then begin
            ApprovalEntryArgument.Init();
            ApprovalEntryArgument."Table ID" := RecRef.Number;
            ApprovalEntryArgument."Record ID to Approve" := RecRef.RecordId;
            ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" ";
            ApprovalEntryArgument."Approval Code" := WorkflowStepInstance."Workflow Code";
            ApprovalEntryArgument."Workflow Step Instance ID" := WorkflowStepInstance.ID;

            case RecRef.Number of
                DATABASE::"Purchase Header":
                    begin
                        RecRef.SetTable(PurchaseHeader);
                        CalcPurchaseDocAmount(PurchaseHeader, ApprovalAmount, ApprovalAmountLCY);
                        ApprovalEntryArgument."Document Type" := EnumAssignmentMgt.GetPurchApprovalDocumentType(PurchaseHeader."Document Type");
                        ApprovalEntryArgument."Document No." := PurchaseHeader."No.";
                        ApprovalEntryArgument."Salespers./Purch. Code" := PurchaseHeader."Purchaser Code";
                        ApprovalEntryArgument.Amount := ApprovalAmount;
                        ApprovalEntryArgument."Amount (LCY)" := ApprovalAmountLCY;
                        ApprovalEntryArgument."Currency Code" := PurchaseHeader."Currency Code";
                    end;
                DATABASE::"Sales Header":
                    begin
                        RecRef.SetTable(SalesHeader);
                        CalcSalesDocAmount(SalesHeader, ApprovalAmount, ApprovalAmountLCY);
                        ApprovalEntryArgument."Document Type" := EnumAssignmentMgt.GetSalesApprovalDocumentType(SalesHeader."Document Type");
                        ApprovalEntryArgument."Document No." := SalesHeader."No.";
                        ApprovalEntryArgument."Salespers./Purch. Code" := SalesHeader."Salesperson Code";
                        ApprovalEntryArgument.Amount := ApprovalAmount;
                        ApprovalEntryArgument."Amount (LCY)" := ApprovalAmountLCY;
                        ApprovalEntryArgument."Currency Code" := SalesHeader."Currency Code";
                        ApprovalEntryArgument."Available Credit Limit (LCY)" := GetAvailableCreditLimit(SalesHeader);
                    end;
                DATABASE::Customer:
                    begin
                        RecRef.SetTable(Customer);
                        ApprovalEntryArgument."Salespers./Purch. Code" := Customer."Salesperson Code";
                        ApprovalEntryArgument."Currency Code" := Customer."Currency Code";
                        ApprovalEntryArgument."Available Credit Limit (LCY)" := Customer.CalcAvailableCredit();
                    end;
                DATABASE::"Gen. Journal Batch":
                    RecRef.SetTable(GenJournalBatch);
                DATABASE::"Gen. Journal Line":
                    begin
                        RecRef.SetTable(GenJournalLine);
                        case GenJournalLine."Document Type" of
                            GenJournalLine."Document Type"::Invoice:
                                ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::Invoice;
                            GenJournalLine."Document Type"::"Credit Memo":
                                ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::"Credit Memo";
                            GenJournalLine."Document Type"::" ":
                                ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::" ";
                            GenJournalLine."Document Type"::"Payment":
                                ApprovalEntryArgument."Document Type" := ApprovalEntryArgument."Document Type"::"Payment";
                            else
                                ApprovalEntryArgument."Document Type" := GenJournalLine."Document Type";
                        end;
                        ApprovalEntryArgument."Document No." := GenJournalLine."Document No.";
                        ApprovalEntryArgument."Salespers./Purch. Code" := GenJournalLine."Salespers./Purch. Code";
                        ApprovalEntryArgument.Amount := GenJournalLine.Amount;
                        ApprovalEntryArgument."Amount (LCY)" := GenJournalLine."Amount (LCY)";
                        ApprovalEntryArgument."Currency Code" := GenJournalLine."Currency Code";
                    end;
                DATABASE::"Incoming Document":
                    begin
                        RecRef.SetTable(IncomingDocument);
                        ApprovalEntryArgument."Document No." := Format(IncomingDocument."Entry No.");
                    end;
                DATABASE::Vendor:
                    begin
                        RecRef.SetTable(Vendor);
                        ApprovalEntryArgument."Salespers./Purch. Code" := Vendor."Purchaser Code";
                    end;
                Database::"Requisition Wksh. Name":
                    RecRef.SetTable(RequisitionWkshName);
                else
                    OnPopulateApprovalEntryArgument(RecRef, ApprovalEntryArgument, WorkflowStepInstance);
            end;
        end;

        OnAfterPopulateApprovalEntryArgument(WorkflowStepInstance, ApprovalEntryArgument, IsHandled, RecRef);
    end;

    procedure CreateApprovalEntryNotification(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        NotificationEntry: Record "Notification Entry";
        IsNotificationRequiredForCurrentUser: Boolean;
        IsNotifySenderRequired: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateApprovalEntryNotification(ApprovalEntry, IsHandled, WorkflowStepInstance);
        if not IsHandled then begin
            if not WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
                exit;

            IsNotificationRequiredForCurrentUser := (ApprovalEntry."Approver ID" <> UserId) or IsBackground();
            IsNotifySenderRequired := ((ApprovalEntry."Sender ID" <> UserId) or IsBackground()) and (ApprovalEntry."Sender ID" <> ApprovalEntry."Approver ID");

            ApprovalEntry.Reset();
            if IsNotificationRequiredForCurrentUser and (ApprovalEntry.Status <> ApprovalEntry.Status::Rejected) then
                NotificationEntry.CreateNotificationEntry(
                    NotificationEntry.Type::Approval, ApprovalEntry."Approver ID",
                    ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link", CopyStr(UserId(), 1, 50));
            if WorkflowStepArgument."Notify Sender" and IsNotifySenderRequired then
                NotificationEntry.CreateNotificationEntry(
                    NotificationEntry.Type::Approval, ApprovalEntry."Sender ID",
                    ApprovalEntry, WorkflowStepArgument."Link Target Page", WorkflowStepArgument."Custom Link", CopyStr(UserId(), 1, 50));
        end;

        OnAfterCreateApprovalEntryNotification(ApprovalEntry, WorkflowStepArgument);
    end;

    local procedure SetApproverType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApproverType(WorkflowStepArgument, ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        case WorkflowStepArgument."Approver Type" of
            WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser":
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::"Sales Pers./Purchaser";
            WorkflowStepArgument."Approver Type"::Approver:
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::Approver;
            WorkflowStepArgument."Approver Type"::"Workflow User Group":
                ApprovalEntry."Approval Type" := ApprovalEntry."Approval Type"::"Workflow User Group";
        end;

        OnAfterSetApproverType(WorkflowStepArgument, ApprovalEntry);
    end;

    local procedure SetLimitType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    begin
        case WorkflowStepArgument."Approver Limit Type" of
            WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"Approval Limits";
            WorkflowStepArgument."Approver Limit Type"::"Direct Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";
            WorkflowStepArgument."Approver Limit Type"::"Specific Approver":
                ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";
        end;

        if ApprovalEntry."Approval Type" = ApprovalEntry."Approval Type"::"Workflow User Group" then
            ApprovalEntry."Limit Type" := ApprovalEntry."Limit Type"::"No Limits";

        OnAfterSetLimitType(WorkflowStepArgument, ApprovalEntry);
    end;

    local procedure IsSufficientPurchApprover(UserSetup: Record "User Setup"; DocumentType: Enum "Purchase Document Type"; ApprovalAmountLCY: Decimal): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
        IsSufficient: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsSufficientPurchApprover(UserSetup, DocumentType, ApprovalAmountLCY, IsSufficient, IsHandled);
        if IsHandled then
            exit(IsSufficient);

        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        case DocumentType of
            PurchaseHeader."Document Type"::Quote:
                if UserSetup."Unlimited Request Approval" or
                   ((ApprovalAmountLCY <= UserSetup."Request Amount Approval Limit") and (UserSetup."Request Amount Approval Limit" <> 0))
                then
                    exit(true);
            else
                if UserSetup."Unlimited Purchase Approval" or
                   ((ApprovalAmountLCY <= UserSetup."Purchase Amount Approval Limit") and (UserSetup."Purchase Amount Approval Limit" <> 0))
                then
                    exit(true);
        end;

        exit(false);
    end;

    local procedure IsSufficientSalesApprover(UserSetup: Record "User Setup"; DocumentType: Enum "Sales Document Type"; ApprovalAmountLCY: Decimal): Boolean
    var
        IsHandled: Boolean;
        IsSufficient: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsSufficientSalesApprover(UserSetup, DocumentType, ApprovalAmountLCY, IsSufficient, IsHandled);
        if IsHandled then
            exit(IsSufficient);

        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Sales Approval" or
           ((ApprovalAmountLCY <= UserSetup."Sales Amount Approval Limit") and (UserSetup."Sales Amount Approval Limit" <> 0))
        then
            exit(true);

        exit(false);
    end;

    local procedure IsSufficientGenJournalLineApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry") Result: Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        RecRef.Get(ApprovalEntryArgument."Record ID to Approve");
        RecRef.SetTable(GenJournalLine);

        IsHandled := false;
        OnIsSufficientGenJournalLineApproverOnAfterRecRefSetTable(UserSetup, ApprovalEntryArgument, GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit;

        if GenJournalLine.IsForPurchase() then
            exit(IsSufficientPurchApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)"));

        if GenJournalLine.IsForSales() then
            exit(IsSufficientSalesApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)"));

        if GenJournalLine.IsForGLAccount() then
            exit(IsSufficientGLAccountApprover(UserSetup, ApprovalEntryArgument."Amount (LCY)"));

        exit(true);
    end;

    local procedure IsSufficientGLAccountApprover(UserSetup: Record "User Setup"; ApprovalAmountLCY: Decimal): Boolean
    begin
        if UserSetup."User ID" = UserSetup."Approver ID" then
            exit(true);

        if UserSetup."Unlimited Request Approval" or
            ((ApprovalAmountLCY <= UserSetup."Request Amount Approval Limit") and (UserSetup."Request Amount Approval Limit" <> 0))
        then
            exit(true);

        exit(false);
    end;

    procedure IsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"): Boolean
    var
        IsSufficient: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeIsSufficientApprover(UserSetup, ApprovalEntryArgument);
        IsSufficient := true;
        case ApprovalEntryArgument."Table ID" of
            DATABASE::"Purchase Header":
                IsSufficient := IsSufficientPurchApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)");
            DATABASE::"Sales Header":
                IsSufficient := IsSufficientSalesApprover(UserSetup, ApprovalEntryArgument."Document Type", ApprovalEntryArgument."Amount (LCY)");
            DATABASE::"Gen. Journal Line":
                IsSufficient := IsSufficientGenJournalLineApprover(UserSetup, ApprovalEntryArgument);
            else
                OnSufficientApproverElseCase(UserSetup, ApprovalEntryArgument, IsSufficient);
        end;

        IsHandled := false;
        OnAfterIsSufficientApprover(UserSetup, ApprovalEntryArgument, IsSufficient, IsHandled);
        if not IsHandled then
            if ApprovalEntryArgument."Table ID" in [Database::"Gen. Journal Batch", Database::"Requisition Wksh. Name"] then
                Message(ApporvalChainIsUnsupportedMsg, Format(ApprovalEntryArgument."Record ID to Approve"));

        exit(IsSufficient);
    end;

    local procedure GetAvailableCreditLimit(SalesHeader: Record "Sales Header"): Decimal
    begin
        exit(SalesHeader.CheckAvailableCreditLimit());
    end;

    procedure PrePostApprovalCheckSales(var SalesHeader: Record "Sales Header"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePrePostApprovalCheckSales(SalesHeader, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if IsSalesHeaderPendingApproval(SalesHeader) then
            Error(SalesPrePostCheckErr, SalesHeader."Document Type", SalesHeader."No.");

        exit(true);
    end;

    procedure PrePostApprovalCheckPurch(var PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrePostApprovalCheckPurch(PurchaseHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IsPurchaseHeaderPendingApproval(PurchaseHeader) then
            Error(PurchPrePostCheckErr, PurchaseHeader."Document Type", PurchaseHeader."No.");

        exit(true);
    end;

    procedure IsIncomingDocApprovalsWorkflowEnabled(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(IncomingDocument, WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode()));
    end;

    procedure IsPurchaseApprovalsWorkflowEnabled(var PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsPurchaseApprovalsWorkflowEnabled(PurchaseHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(WorkflowManagement.CanExecuteWorkflow(PurchaseHeader, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode()));
    end;

    procedure IsPurchaseHeaderPendingApproval(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            exit(false);

        exit(IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader));
    end;

    procedure IsSalesApprovalsWorkflowEnabled(var SalesHeader: Record "Sales Header"): Boolean
    begin
        exit(WorkflowManagement.CanExecuteWorkflow(SalesHeader, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode()));
    end;

    procedure IsSalesHeaderPendingApproval(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            exit(false);

        exit(IsSalesApprovalsWorkflowEnabled(SalesHeader));
    end;

    procedure IsOverdueNotificationsWorkflowEnabled(): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetFilter("Due Date", '<%1', Today);
        if not ApprovalEntry.FindSet() then
            ApprovalEntry.Init();

        exit(WorkflowManagement.WorkflowExists(ApprovalEntry, ApprovalEntry,
            WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode()));
    end;

    procedure IsGeneralJournalBatchApprovalsWorkflowEnabled(var GenJournalBatch: Record "Gen. Journal Batch") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(WorkflowManagement.CanExecuteWorkflow(GenJournalBatch,
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode()));
    end;

    procedure IsGeneralJournalLineApprovalsWorkflowEnabled(var GenJournalLine: Record "Gen. Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
            WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode()));
    end;

    procedure IsRequisitionWkshBatchApprovalsWorkflowEnabled(var RequisitionWkshName: Record "Requisition Wksh. Name") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsRequisitionWkshBatchApprovalsWorkflowEnabled(RequisitionWkshName, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(WorkflowManagement.CanExecuteWorkflow(RequisitionWkshName, WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode()));
    end;

    procedure CheckPurchaseApprovalPossible(var PurchaseHeader: Record "Purchase Header") Result: Boolean
    var
        IsHandled: Boolean;
        ShowNothingToApproveError: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchaseApprovalPossible(PurchaseHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader) then
            Error(NoWorkflowEnabledErr);

        ShowNothingToApproveError := not PurchaseHeader.PurchLinesExist();
        OnCheckPurchaseApprovalPossibleOnAfterCalcShowNothingToApproveError(PurchaseHeader, ShowNothingToApproveError);
        if ShowNothingToApproveError then
            Error(NothingToApproveErr);

        OnAfterCheckPurchaseApprovalPossible(PurchaseHeader);

        exit(true);
    end;

    procedure CheckIncomingDocApprovalsWorkflowEnabled(var IncomingDocument: Record "Incoming Document"): Boolean
    begin
        if not IsIncomingDocApprovalsWorkflowEnabled(IncomingDocument) then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckSalesApprovalPossible(var SalesHeader: Record "Sales Header"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesApprovalPossible(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsSalesApprovalsWorkflowEnabled(SalesHeader) then
            Error(NoWorkflowEnabledErr);

        if not SalesHeader.SalesLinesExist() then
            Error(NothingToApproveErr);

        OnAfterCheckSalesApprovalPossible(SalesHeader);

        exit(true);
    end;

    procedure CheckCustomerApprovalsWorkflowEnabled(var Customer: Record Customer) Result: Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Customer, WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode()) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Customer, WorkflowEventHandling.RunWorkflowOnCustomerChangedCode()) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        Result := true;
        OnAfterCheckCustomerApprovalsWorkflowEnabled(Customer, Result);
    end;

    procedure CheckVendorApprovalsWorkflowEnabled(var Vendor: Record Vendor): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Vendor, WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode()) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Vendor, WorkflowEventHandling.RunWorkflowOnVendorChangedCode()) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    procedure CheckItemApprovalsWorkflowEnabled(var Item: Record Item): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(Item, WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode()) then begin
            if WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, WorkflowEventHandling.RunWorkflowOnItemChangedCode()) then
                exit(false);
            Error(NoWorkflowEnabledErr);
        end;
        exit(true);
    end;

    procedure CheckGeneralJournalBatchApprovalsWorkflowEnabled(var GenJournalBatch: Record "Gen. Journal Batch"): Boolean
    begin
        if not
           WorkflowManagement.CanExecuteWorkflow(GenJournalBatch,
             WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode())
        then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckGeneralJournalLineApprovalsWorkflowEnabled(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if not
           WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
             WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode())
        then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckRequisitionWkshBatchApprovalsWorkflowEnabled(var RequisitionWkshName: Record "Requisition Wksh. Name"): Boolean
    begin
        if not WorkflowManagement.CanExecuteWorkflow(RequisitionWkshName, WorkflowEventHandling.RunWorkflowOnSendRequisitionWkshBatchForApprovalCode()) then
            Error(NoWorkflowEnabledErr);

        exit(true);
    end;

    procedure CheckJobQueueEntryApprovalEnabled(): Boolean
    begin
        exit(WorkflowManagement.EnabledWorkflowExist(Database::"Job Queue Entry", WorkflowEventHandling.RunWorkflowOnSendJobQueueEntryForApprovalCode()));
    end;

    procedure DeleteApprovalEntry(Variant: Variant)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        DeleteApprovalEntries(RecRef.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnMoveGenJournalLine', '', false, false)]
    procedure PostApprovalEntriesMoveGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ToRecordID: RecordID)
    begin
        PostApprovalEntries(GenJournalLine.RecordId, ToRecordID, GenJournalLine."Document No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteGenJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnMoveGenJournalBatch', '', false, false)]
    procedure PostApprovalEntriesMoveGenJournalBatch(var Sender: Record "Gen. Journal Batch"; ToRecordID: RecordID)
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        if PostApprovalEntries(Sender.RecordId, ToRecordID, '') then begin
            RecordRestrictionMgt.AllowRecordUsage(Sender);
            DeleteApprovalEntries(Sender.RecordId);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteGenJournalBatch(var Rec: Record "Gen. Journal Batch"; RunTrigger: Boolean)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if Rec.IsTemporary then
            exit;

        if GenJnlTemplate.Get(Rec."Journal Template Name") then
            if not GenJnlTemplate."Increment Batch Name" then
                DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Wksh. Name", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteRequisitionWkshName(var Rec: Record "Requisition Wksh. Name"; RunTrigger: Boolean)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        if Rec.IsTemporary then
            exit;

        if ReqWkshTemplate.Get(Rec."Worksheet Template Name") then
            if not ReqWkshTemplate."Increment Batch Name" then
                DeleteApprovalEntries(Rec.RecordId());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteCustomer(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnAfterDeleteEvent', '', false, false)]
    procedure DeleteApprovalEntriesAfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            DeleteApprovalEntries(Rec.RecordId);
    end;

    procedure PostApprovalEntries(ApprovedRecordID: RecordID; PostedRecordID: RecordID; PostedDocNo: Code[20]): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        PostedApprovalEntry: Record "Posted Approval Entry";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        ApprovalEntry.SetAutoCalcFields("Pending Approvals", "Number of Approved Requests", "Number of Rejected Requests");
        ApprovalEntry.SetRange("Table ID", ApprovedRecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", ApprovedRecordID);
        OnPostApprovalEntriesOnAfterApprovalEntrySetFilters(ApprovalEntry, ApprovedRecordID.TableNo);
        if not ApprovalEntry.FindSet() then
            exit(false);

        repeat
            PostedApprovalEntry.Init();
            PostedApprovalEntry.TransferFields(ApprovalEntry);
            PostedApprovalEntry."Number of Approved Requests" := ApprovalEntry."Number of Approved Requests";
            PostedApprovalEntry."Number of Rejected Requests" := ApprovalEntry."Number of Rejected Requests";
            PostedApprovalEntry."Table ID" := PostedRecordID.TableNo;
            PostedApprovalEntry."Document No." := PostedDocNo;
            PostedApprovalEntry."Posted Record ID" := PostedRecordID;
            PostedApprovalEntry."Entry No." := 0;
            OnPostApprovalEntriesOnBeforePostedApprovalEntryInsert(PostedApprovalEntry, ApprovalEntry);
            PostedApprovalEntry.Insert(true);
            RecordLinkManagement.CopyLinks(ApprovalEntry, PostedApprovalEntry);
        until ApprovalEntry.Next() = 0;

        PostApprovalCommentLines(ApprovedRecordID, PostedRecordID, PostedDocNo);
        exit(true);
    end;

    local procedure PostApprovalCommentLines(ApprovedRecordID: RecordID; PostedRecordID: RecordID; PostedDocNo: Code[20])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", ApprovedRecordID.TableNo);
        ApprovalCommentLine.SetRange("Record ID to Approve", ApprovedRecordID);
        OnPostApprovalCommentLinesOnAfterApprovalCommentLineSetFilters(ApprovalCommentLine, ApprovedRecordID.TableNo);
        if ApprovalCommentLine.FindSet() then
            repeat
                PostedApprovalCommentLine.Init();
                PostedApprovalCommentLine.TransferFields(ApprovalCommentLine);
                PostedApprovalCommentLine."Entry No." := 0;
                PostedApprovalCommentLine."Table ID" := PostedRecordID.TableNo;
                PostedApprovalCommentLine."Document No." := PostedDocNo;
                PostedApprovalCommentLine."Posted Record ID" := PostedRecordID;
                OnPostApprovalCommentLinesOnBeforePostedApprovalCommentLineInsert(PostedApprovalCommentLine, ApprovalCommentLine);
                PostedApprovalCommentLine.Insert(true);
            until ApprovalCommentLine.Next() = 0;
    end;

    procedure ShowPostedApprovalEntries(PostedRecordID: RecordID)
    var
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        PostedApprovalEntry.FilterGroup(2);
        PostedApprovalEntry.SetRange("Posted Record ID", PostedRecordID);
        PostedApprovalEntry.FilterGroup(0);
        PAGE.Run(PAGE::"Posted Approval Entries", PostedApprovalEntry);
    end;

    procedure DeletePostedApprovalEntries(PostedRecordID: RecordID)
    var
        PostedApprovalEntry: Record "Posted Approval Entry";
    begin
        PostedApprovalEntry.SetRange("Table ID", PostedRecordID.TableNo);
        PostedApprovalEntry.SetRange("Posted Record ID", PostedRecordID);
        if not PostedApprovalEntry.IsEmpty() then
            PostedApprovalEntry.DeleteAll();
        DeletePostedApprovalCommentLines(PostedRecordID);
    end;

    local procedure DeletePostedApprovalCommentLines(PostedRecordID: RecordID)
    var
        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
    begin
        PostedApprovalCommentLine.SetRange("Table ID", PostedRecordID.TableNo);
        PostedApprovalCommentLine.SetRange("Posted Record ID", PostedRecordID);
        if not PostedApprovalCommentLine.IsEmpty() then
            PostedApprovalCommentLine.DeleteAll();
    end;

    procedure SetStatusToPendingApproval(var Variant: Variant)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        IncomingDocument: Record "Incoming Document";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeSetStatusToPendingApproval(Variant);
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    PurchaseHeader.Validate(Status, PurchaseHeader.Status::"Pending Approval");
                    PurchaseHeader.Modify(true);
                    Variant := PurchaseHeader;
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SalesHeader.Validate(Status, SalesHeader.Status::"Pending Approval");
                    SalesHeader.Modify(true);
                    Variant := SalesHeader;
                end;
            DATABASE::"Incoming Document":
                begin
                    RecRef.SetTable(IncomingDocument);
                    IncomingDocument.Validate(Status, IncomingDocument.Status::"Pending Approval");
                    IncomingDocument.Modify(true);
                    Variant := IncomingDocument;
                end;
            else begin
                IsHandled := false;
                OnSetStatusToPendingApproval(RecRef, Variant, IsHandled);
                if not IsHandled then
                    Error(UnsupportedRecordTypeErr, RecRef.Caption);
            end;
        end;
    end;

    procedure InformUserOnStatusChange(Variant: Variant; WorkflowInstanceId: Guid)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Purchase Header":
                ShowPurchApprovalStatus(Variant);
            DATABASE::"Sales Header":
                ShowSalesApprovalStatus(Variant);
            else
                ShowCommonApprovalStatus(RecRef, WorkflowInstanceId);
        end;
    end;

    local procedure ShowCommonApprovalStatus(var RecRef: RecordRef; WorkflowInstanceId: Guid)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCommonApprovalStatus(RecRef, IsHandled);
        if IsHandled then
            exit;

        ShowApprovalStatus(RecRef.RecordId, WorkflowInstanceId);
    end;

    procedure GetApprovalComment(Variant: Variant)
    var
        BlankGUID: Guid;
    begin
        ShowApprovalComments(Variant, BlankGUID);
    end;

    procedure GetApprovalCommentForWorkflowStepInstanceID(Variant: Variant; WorkflowStepInstanceID: Guid)
    begin
        ShowApprovalComments(Variant, WorkflowStepInstanceID);
    end;

    local procedure ShowApprovalComments(Variant: Variant; WorkflowStepInstanceID: Guid)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);

        case RecRef.Number of
            DATABASE::"Approval Entry":
                begin
                    ApprovalEntry := Variant;
                    RecRef.Get(ApprovalEntry."Record ID to Approve");
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
                end;
            DATABASE::"Purchase Header":
                begin
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
                    FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
                end;
            DATABASE::"Sales Header":
                begin
                    ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
                    ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
                    FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
                end;
            else
                SetCommonApprovalCommentLineFilters(RecRef, ApprovalEntry, ApprovalCommentLine);
        end;
        OnShowApprovalCommentsOnAfterSetApprovalCommentLineFilters(ApprovalCommentLine, ApprovalEntry, RecRef);

        if IsNullGuid(WorkflowStepInstanceID) and (not IsNullGuid(ApprovalEntry."Workflow Step Instance ID")) then
            WorkflowStepInstanceID := ApprovalEntry."Workflow Step Instance ID";

        RunApprovalCommentsPage(ApprovalCommentLine, WorkflowStepInstanceID);
    end;

    local procedure SetCommonApprovalCommentLineFilters(var RecRef: RecordRef; var ApprovalEntry: Record "Approval Entry"; var ApprovalCommentLine: Record "Approval Comment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCommonApprovalCommentLineFilters(RecRef, ApprovalCommentLine, IsHandled);
        if IsHandled then
            exit;

        ApprovalCommentLine.SetRange("Table ID", RecRef.Number);
        ApprovalCommentLine.SetRange("Record ID to Approve", RecRef.RecordId);
        FindOpenApprovalEntryForCurrUser(ApprovalEntry, RecRef.RecordId);
    end;

    local procedure RunApprovalCommentsPage(var ApprovalCommentLine: Record "Approval Comment Line"; WorkflowStepInstanceID: Guid)
    var
        ApprovalComments: Page "Approval Comments";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunApprovalCommentsPage(ApprovalCommentLine, WorkflowStepInstanceID, IsHandled);
        if IsHandled then
            exit;

        ApprovalComments.SetTableView(ApprovalCommentLine);
        ApprovalComments.SetWorkflowStepInstanceID(WorkflowStepInstanceID);
        ApprovalComments.Run();
    end;

    procedure HasOpenApprovalEntriesForCurrentUser(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Approver ID", UserId);
        OnHasOpenApprovalEntriesForCurrentUserOnAfterSetApprovalEntrySetFilters(ApprovalEntry);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);

        OnHasOpenApprovalEntriesForCurrentUserOnAfterSetApprovalEntryFilters(ApprovalEntry);

        exit(not ApprovalEntry.IsEmpty());
    end;

    procedure HasOpenApprovalEntries(RecordID: RecordID) Result: Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasOpenApprovalEntries(RecordID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);
        OnHasOpenApprovalEntriesOnAfterApprovalEntrySetFilters(ApprovalEntry);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasOpenOrPendingApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasOpenOrPendingApprovalEntriesForCurrentUser(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        ApprovalEntry.SetRange("Approver ID", UserId);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasApprovedApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;


    procedure HasApprovalEntries(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if ApprovalEntry.IsEmpty() then
            exit(false);
        ApprovalEntry.SetRange("Related to Change", false);
        exit(not ApprovalEntry.IsEmpty);
    end;

    local procedure HasPendingApprovalEntriesForWorkflow(RecId: RecordID; WorkflowInstanceId: Guid): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Record ID to Approve", RecId);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        ApprovalEntry.SetFilter("Workflow Step Instance ID", WorkflowInstanceId);
        OnHasPendingApprovalEntriesForWorkflowOnAfterApprovalEntrySetFilters(ApprovalEntry);
        exit(not ApprovalEntry.IsEmpty);
    end;

    procedure HasAnyOpenJournalLineApprovalEntries(JournalTemplateName: Code[20]; JournalBatchName: Code[20]): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApprovalEntry: Record "Approval Entry";
        GenJournalLineRecRef: RecordRef;
        GenJournalLineRecordID: RecordID;
    begin
        ApprovalEntry.SetRange("Table ID", DATABASE::"Gen. Journal Line");
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if not ApprovalEntry.IsEmpty() then
            ApprovalEntry.SetRange("Related to Change", false);
        OnHasAnyOpenJournalLineApprovalEntriesOnAfterApprovalEntrySetFilters(ApprovalEntry);
        if ApprovalEntry.IsEmpty() then
            exit(false);

        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        if GenJournalLine.IsEmpty() then
            exit(false);

        if GenJournalLine.Count < ApprovalEntry.Count then begin
            GenJournalLine.FindSet();
            repeat
                if HasOpenApprovalEntries(GenJournalLine.RecordId) then
                    exit(true);
            until GenJournalLine.Next() = 0;
        end else begin
            ApprovalEntry.FindSet();
            repeat
                GenJournalLineRecordID := ApprovalEntry."Record ID to Approve";
                GenJournalLineRecRef := GenJournalLineRecordID.GetRecord();
                GenJournalLineRecRef.SetTable(GenJournalLine);
                if (GenJournalLine."Journal Template Name" = JournalTemplateName) and
                   (GenJournalLine."Journal Batch Name" = JournalBatchName)
                then
                    exit(true);
            until ApprovalEntry.Next() = 0;
        end;

        exit(false)
    end;

    procedure TrySendJournalBatchApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);
        CheckGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch);
        if HasOpenApprovalEntries(GenJournalBatch.RecordId) or
           HasAnyOpenJournalLineApprovalEntries(GenJournalBatch."Journal Template Name", GenJournalBatch.Name)
        then
            Error(PendingJournalBatchApprovalExistsErr);
        if HasApprovedApprovalEntries(GenJournalBatch.RecordId) then
            if not Confirm(ApprovedJournalBatchApprovalExistsMsg) then
                exit;
        OnSendGeneralJournalBatchForApproval(GenJournalBatch);
    end;

    procedure TrySendJournalLineApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnBeforeTrySendJournalLineApprovalRequests(GenJournalLine);
        if GenJournalLine.Count = 1 then
            CheckGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine);

        repeat
            OnTrySendJournalLineApprovalRequestsOnBeforeLoopIteration(GenJournalLine);
            if WorkflowManagement.CanExecuteWorkflow(GenJournalLine,
                 WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode()) and
               not HasOpenApprovalEntries(GenJournalLine.RecordId)
            then
                OnSendGeneralJournalLineForApproval(GenJournalLine);
        until GenJournalLine.Next() = 0;
    end;

    procedure TryCancelJournalBatchApprovalRequest(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);
        OnCancelGeneralJournalBatchApprovalRequest(GenJournalBatch);
        WorkflowWebhookManagement.FindAndCancel(GenJournalBatch.RecordId);
    end;

    procedure TryCancelJournalLineApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    var
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        repeat
            if HasOpenApprovalEntries(GenJournalLine.RecordId) then
                OnCancelGeneralJournalLineApprovalRequest(GenJournalLine);
            WorkflowWebhookManagement.FindAndCancel(GenJournalLine.RecordId);
        until GenJournalLine.Next() = 0;
        Message(ApprovalReqCanceledForSelectedLinesMsg);
    end;

    procedure ShowJournalApprovalEntries(var GenJournalLine: Record "Gen. Journal Line")
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGeneralJournalBatch(GenJournalBatch, GenJournalLine);

        ApprovalEntry.SetFilter("Table ID", '%1|%2', DATABASE::"Gen. Journal Batch", DATABASE::"Gen. Journal Line");
        ApprovalEntry.SetFilter("Record ID to Approve", '%1|%2', GenJournalBatch.RecordId, GenJournalLine.RecordId);
        ApprovalEntry.SetRange("Related to Change", false);
        PAGE.Run(PAGE::"Approval Entries", ApprovalEntry);
    end;

    local procedure GetGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if not GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            GenJournalBatch.Get(GenJournalLine.GetFilter("Journal Template Name"), GenJournalLine.GetFilter("Journal Batch Name"));
    end;

    procedure TrySendWorksheetBatchApprovalRequest(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        GetRequisitionWkshBatch(RequisitionWkshName, RequisitionLine);
        CheckRequisitionWkshBatchApprovalsWorkflowEnabled(RequisitionWkshName);

        if HasOpenApprovalEntries(RequisitionWkshName.RecordId()) then
            Error(PendingJournalBatchApprovalExistsErr);

        if HasApprovedApprovalEntries(RequisitionWkshName.RecordId()) then
            if not Confirm(ApprovedJournalBatchApprovalExistsMsg) then
                exit;

        OnSendRequisitionWkshBatchForApproval(RequisitionWkshName);
    end;

    procedure TryCancelWorksheetBatchApprovalRequest(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        GetRequisitionWkshBatch(RequisitionWkshName, RequisitionLine);
        OnCancelRequisitionWkshBatchApprovalRequest(RequisitionWkshName);
        WorkflowWebhookManagement.FindAndCancel(RequisitionWkshName.RecordId());
    end;

    procedure ShowWorksheetApprovalEntries(var RequisitionLine: Record "Requisition Line")
    var
        ApprovalEntry: Record "Approval Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        GetRequisitionWkshBatch(RequisitionWkshName, RequisitionLine);

        ApprovalEntry.SetFilter("Table ID", '%1|%2', Database::"Requisition Wksh. Name", Database::"Requisition Line");
        ApprovalEntry.SetFilter("Record ID to Approve", '%1|%2', RequisitionWkshName.RecordId(), RequisitionLine.RecordId());
        ApprovalEntry.SetRange("Related to Change", false);
        Page.Run(Page::"Approval Entries", ApprovalEntry);
    end;

    local procedure GetRequisitionWkshBatch(var RequisitionWkshName: Record "Requisition Wksh. Name"; var RequisitionLine: Record "Requisition Line")
    begin
        if not RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name") then
            RequisitionWkshName.Get(RequisitionLine.GetFilter("Worksheet Template Name"), RequisitionLine.GetFilter("Journal Batch Name"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRenameRecordInApprovalRequest', '', false, false)]
    procedure RenameApprovalEntries(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Record ID to Approve", OldRecordId);
        if not ApprovalEntry.IsEmpty() then
            ApprovalEntry.ModifyAll("Record ID to Approve", NewRecordId, true);
        ChangeApprovalComments(OldRecordId, NewRecordId);
    end;

    local procedure ChangeApprovalComments(OldRecordId: RecordID; NewRecordId: RecordID)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Record ID to Approve", OldRecordId);
        if not ApprovalCommentLine.IsEmpty() then
            ApprovalCommentLine.ModifyAll("Record ID to Approve", NewRecordId, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDeleteRecordInApprovalRequest', '', false, false)]
    procedure DeleteApprovalEntries(RecordIDToApprove: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordIDToApprove.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordIDToApprove);
        OnDeleteApprovalEntriesOnAfterApprovalEntrySetFilters(ApprovalEntry);
        if not ApprovalEntry.IsEmpty() then
            ApprovalEntry.DeleteAll(true);
        DeleteApprovalCommentLines(RecordIDToApprove);
    end;

    procedure DeleteApprovalCommentLines(RecordIDToApprove: RecordID)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
    begin
        ApprovalCommentLine.SetRange("Table ID", RecordIDToApprove.TableNo);
        ApprovalCommentLine.SetRange("Record ID to Approve", RecordIDToApprove);
        OnDeleteApprovalCommentLinesOnAfterApprovalCommentLineSetFilters(ApprovalCommentLine);
        if not ApprovalCommentLine.IsEmpty() then
            ApprovalCommentLine.DeleteAll(true);
    end;

    procedure CopyApprovalEntryQuoteToOrder(FromRecID: RecordID; ToDocNo: Code[20]; ToRecID: RecordID)
    var
        FromApprovalEntry: Record "Approval Entry";
        ToApprovalEntry: Record "Approval Entry";
        FromApprovalCommentLine: Record "Approval Comment Line";
        ToApprovalCommentLine: Record "Approval Comment Line";
        NextEntryNo: Integer;
    begin
        FromApprovalEntry.SetRange("Table ID", FromRecID.TableNo);
        FromApprovalEntry.SetRange("Record ID to Approve", FromRecID);
        if FromApprovalEntry.FindSet() then begin
            repeat
                ToApprovalEntry := FromApprovalEntry;
                ToApprovalEntry."Entry No." := 0; // Auto increment
                ToApprovalEntry."Document Type" := ToApprovalEntry."Document Type"::Order;
                ToApprovalEntry."Document No." := ToDocNo;
                ToApprovalEntry."Record ID to Approve" := ToRecID;
                ToApprovalEntry.Insert();
            until FromApprovalEntry.Next() = 0;

            FromApprovalCommentLine.SetRange("Table ID", FromRecID.TableNo);
            FromApprovalCommentLine.SetRange("Record ID to Approve", FromRecID);
            if FromApprovalCommentLine.FindSet() then begin
                NextEntryNo := ToApprovalCommentLine.GetLastEntryNo() + 1;
                repeat
                    ToApprovalCommentLine := FromApprovalCommentLine;
                    ToApprovalCommentLine."Entry No." := NextEntryNo;
                    ToApprovalCommentLine."Document Type" := ToApprovalCommentLine."Document Type"::Order;
                    ToApprovalCommentLine."Document No." := ToDocNo;
                    ToApprovalCommentLine."Record ID to Approve" := ToRecID;
                    ToApprovalCommentLine.Insert();
                    NextEntryNo += 1;
                until FromApprovalCommentLine.Next() = 0;
            end;
        end;
    end;

    procedure GetLastSequenceNo(ApprovalEntryArgument: Record "Approval Entry"): Integer
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetCurrentKey("Record ID to Approve", "Workflow Step Instance ID", "Sequence No.");
        ApprovalEntry.SetRange("Table ID", ApprovalEntryArgument."Table ID");
        ApprovalEntry.SetRange("Record ID to Approve", ApprovalEntryArgument."Record ID to Approve");
        ApprovalEntry.SetRange("Workflow Step Instance ID", ApprovalEntryArgument."Workflow Step Instance ID");
        OnGetLastSequenceNoOnAfterSetApprovalEntryFilters(ApprovalEntry, ApprovalEntryArgument);
        if ApprovalEntry.FindLast() then
            exit(ApprovalEntry."Sequence No.");
        exit(0);
    end;

    procedure OpenApprovalEntriesPage(RecId: RecordID)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecId.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecId);
        ApprovalEntry.SetRange("Related to Change", false);
        PAGE.RunModal(PAGE::"Approval Entries", ApprovalEntry);
    end;

    procedure OpenApprovalsSales(SalesHeader: Record "Sales Header")
    begin
        RunWorkflowEntriesPage(
            SalesHeader.RecordId(), DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");
    end;

    procedure OpenApprovalsPurchase(PurchHeader: Record "Purchase Header")
    begin
        RunWorkflowEntriesPage(
            PurchHeader.RecordId(), DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");
    end;

    procedure RunWorkflowEntriesPage(RecordIDInput: RecordID; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        Approvals: Page Approvals;
        WorkflowWebhookEntries: Page "Workflow Webhook Entries";
        ApprovalEntries: Page "Approval Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWorkflowEntriesPage(RecordIDInput, TableId, DocumentType, DocumentNo, IsHandled);
        if IsHandled then
            exit;

        // if we are looking at a particular record, we want to see only record related workflow entries
        if DocumentNo <> '' then begin
            ApprovalEntry.SetRange("Record ID to Approve", RecordIDInput);
            WorkflowWebhookEntry.SetRange("Record ID", RecordIDInput);
            // if we have flows created by multiple applications, start generic page filtered for this RecordID
            if not ApprovalEntry.IsEmpty() and not WorkflowWebhookEntry.IsEmpty() then begin
                Approvals.Setfilters(RecordIDInput);
                Approvals.Run();
            end else begin
                // otherwise, open the page filtered for this record that corresponds to the type of the flow
                if not WorkflowWebhookEntry.IsEmpty() then begin
                    WorkflowWebhookEntries.Setfilters(RecordIDInput);
                    WorkflowWebhookEntries.Run();
                    exit;
                end;

                if not ApprovalEntry.IsEmpty() then begin
                    ApprovalEntries.SetRecordFilters(TableId, DocumentType, DocumentNo);
                    ApprovalEntries.Run();
                    exit;
                end;

                // if no workflow exist, show (empty) joint workflows page
                Approvals.Setfilters(RecordIDInput);
                Approvals.Run();
            end
        end else
            // otherwise, open the page with all workflow entries
            Approvals.Run();
    end;

    procedure CanCancelApprovalForRecord(RecID: RecordID) Result: Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit(false);

        ApprovalEntry.SetRange("Table ID", RecID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecID);
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);

        if not UserSetup."Approval Administrator" then
            ApprovalEntry.SetRange("Sender ID", UserId);
        // Initial check before performing an expensive query due to the "Related to Change" flow field.
        if not ApprovalEntry.IsEmpty() then
            ApprovalEntry.SetRange("Related to Change", false);

        Result := ApprovalEntry.FindFirst();
        OnAfterCanCancelApprovalForRecord(RecID, Result, ApprovalEntry, UserSetup);
    end;

    procedure HasApprovalEntriesSentByCurrentUser(RecordId: RecordId): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetFilter(Status, '<>%1', ApprovalEntry.Status::Canceled);
        ApprovalEntry.SetRange("Sender ID", UserId());
        exit(not ApprovalEntry.IsEmpty());
    end;

    local procedure FindUserSetupBySalesPurchCode(var UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument, IsHandled);
        if not IsHandled then
            if ApprovalEntryArgument."Salespers./Purch. Code" <> '' then begin
                UserSetup.SetCurrentKey("Salespers./Purch. Code");
                UserSetup.SetRange("Salespers./Purch. Code", ApprovalEntryArgument."Salespers./Purch. Code");
                if not UserSetup.FindFirst() then
                    Error(
                      PurchaserUserNotFoundErr, UserSetup."User ID", UserSetup.FieldCaption("Salespers./Purch. Code"),
                      UserSetup."Salespers./Purch. Code");
            end;

        OnAfterFindUserSetupBySalesPurchCode(UserSetup, ApprovalEntryArgument);
    end;

    local procedure CheckUserAsApprovalAdministrator(ApprovalEntry: Record "Approval Entry")
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUserAsApprovalAdministrator(ApprovalEntry, IsHandled);
        if IsHandled then
            exit;

        UserSetup.Get(UserId);
        UserSetup.TestField("Approval Administrator");
    end;

    local procedure FindApprovedApprovalEntryForWorkflowUserGroup(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"): Boolean
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        WorkflowInstance: Query "Workflow Instance";
    begin
        WorkflowStepInstance.SetLoadFields(Argument);
        WorkflowStepInstance.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStepInstance.SetRange("Record ID", WorkflowStepInstance."Record ID");
        WorkflowStepInstance.SetRange("Workflow Code", WorkflowStepInstance."Workflow Code");
        WorkflowStepInstance.SetRange(Type, WorkflowInstance.Type::Response);
        WorkflowStepInstance.SetRange(Status, WorkflowInstance.Status::Completed);
        if WorkflowStepInstance.FindSet() then
            repeat
                if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then
                    if WorkflowStepArgument."Approver Type" = WorkflowStepArgument."Approver Type"::"Workflow User Group" then begin
                        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
                        exit(ApprovalEntry.FindLast());
                    end;
            until WorkflowStepInstance.Next() = 0;
        exit(false);
    end;

    local procedure FindOpenApprovalEntriesForWorkflowStepInstance(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstanceRecID: RecordID): Boolean
    var
        ApprovalEntry2: Record "Approval Entry";
    begin
        if ApprovalEntry."Approval Type" = ApprovalEntry."Approval Type"::"Workflow User Group" then
            ApprovalEntry2.SetFilter("Sequence No.", '>%1', ApprovalEntry."Sequence No.");
        ApprovalEntry2.SetFilter("Record ID to Approve", '%1|%2', WorkflowStepInstanceRecID, ApprovalEntry."Record ID to Approve");
        ApprovalEntry2.SetRange(Status, ApprovalEntry2.Status::Open);
        ApprovalEntry2.SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");

        OnFindOpenApprovalEntriesForWorkflowStepInstanceOnAfterSetApprovalEntry2Filters(ApprovalEntry2, ApprovalEntry, WorkflowStepInstanceRecID);

        exit(not ApprovalEntry2.IsEmpty);
    end;

    local procedure IsBackground(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        exit(ClientTypeManagement.GetCurrentClientType() in [ClientType::Background]);
    end;

    procedure PreventDeletingRecordWithOpenApprovalEntry(Variant: Variant)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ConfirmManagement: Codeunit "Confirm Management";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        if HasOpenOrPendingApprovalEntriesForCurrentUser(RecRef.RecordId) and CanCancelApprovalForRecord(RecRef.RecordId) then
            Error(PreventDeleteRecordWithOpenApprovalEntryForCurrUserMsg);

        if (HasOpenApprovalEntries(RecRef.RecordId) and CanCancelApprovalForRecord(RecRef.RecordId))
         or WorkflowWebhookMgt.HasPendingWorkflowWebhookEntryByRecordId(RecRef.RecordId) then
            case RecRef.Number of
                Database::"Gen. Journal Batch":
                    if ConfirmManagement.GetResponseOrDefault(PreventDeleteRecordWithOpenApprovalEntryMsg, true) then begin
                        RecRef.SetTable(GenJournalBatch);
                        OnCancelGeneralJournalBatchApprovalRequest(GenJournalBatch);
                    end else
                        Error('');
                Database::"Gen. Journal Line":
                    Error(PreventDeleteRecordWithOpenApprovalEntryForSenderMsg);
                Database::"Requisition Wksh. Name":
                    if ConfirmManagement.GetResponseOrDefault(PreventDeleteRecordWithOpenApprovalEntryMsg, true) then begin
                        RecRef.SetTable(RequisitionWkshName);
                        OnCancelRequisitionWkshBatchApprovalRequest(RequisitionWkshName);
                    end else
                        Error('');
                else
                    OnPreventDeletingRecordWithOpenApprovalEntryElseCase(RecRef, Variant);
            end;
    end;

    procedure PreventInsertRecIfOpenApprovalEntryExist(Variant: Variant)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
        ConfirmManagement: Codeunit "Confirm Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        case RecRef.Number of
            Database::"Gen. Journal Batch":
                begin
                    if HasOpenOrPendingApprovalEntriesForCurrentUser(RecRef.RecordId) and CanCancelApprovalForRecord(RecRef.RecordId) then
                        Error(PreventInsertRecordWithOpenApprovalEntryForCurrUserMsg);

                    if (HasOpenApprovalEntries(RecRef.RecordId) and CanCancelApprovalForRecord(RecRef.RecordId))
                      or WorkflowWebhookMgt.HasPendingWorkflowWebhookEntryByRecordId(RecRef.RecordId) then
                        if ConfirmManagement.GetResponseOrDefault(PreventInsertRecordWithOpenApprovalEntryMsg, true) then begin
                            RecRef.SetTable(GenJournalBatch);
                            OnCancelGeneralJournalBatchApprovalRequest(GenJournalBatch);
                        end else
                            Error('');
                end;
            Database::"Requisition Wksh. Name":
                begin
                    if HasOpenOrPendingApprovalEntriesForCurrentUser(RecRef.RecordId()) and CanCancelApprovalForRecord(RecRef.RecordId()) then
                        Error(PreventInsertRecordWithOpenApprovalEntryForCurrUserMsg);

                    if (HasOpenApprovalEntries(RecRef.RecordId()) and CanCancelApprovalForRecord(RecRef.RecordId())) or WorkflowWebhookMgt.HasPendingWorkflowWebhookEntryByRecordId(RecRef.RecordId()) then
                        if ConfirmManagement.GetResponseOrDefault(PreventInsertRecordWithOpenApprovalEntryMsg, true) then begin
                            RecRef.SetTable(RequisitionWkshName);
                            OnCancelRequisitionWkshBatchApprovalRequest(RequisitionWkshName);
                        end else
                            Error('');
                end;
            else
                OnPreventInsertRecIfOpenApprovalEntryExistElseCase(RecRef, Variant);
        end;
    end;

    procedure PreventModifyRecIfOpenApprovalEntryExistForCurrentUser(Variant: Variant)
    var
        WorkflowWebhookMgt: Codeunit "Workflow Webhook Management";
        RecRef: RecordRef;
        ErrInfo: ErrorInfo;
        RejectApprovalRequestLbl: Label 'Reject approval';
        ShowCommentsLbl: Label 'Show comments';
        RejectApprovalRequestToolTipLbl: Label 'Reject approval request';
        ShowCommentsToolTipLbl: Label 'Show approval comments';
    begin
        RecRef.GetTable(Variant);
        if HasOpenOrPendingApprovalEntriesForCurrentUser(RecRef.RecordId) or WorkflowWebhookMgt.HasPendingWorkflowWebhookEntryByRecordId(RecRef.RecordId) then begin
            ErrInfo.ErrorType(ErrorType::Client);
            ErrInfo.Verbosity(Verbosity::Error);
            ErrInfo.Message(PreventModifyRecordWithOpenApprovalEntryMsg);
            ErrInfo.TableId(RecRef.Number);
            ErrInfo.RecordId(RecRef.RecordId);
            ErrInfo.AddAction(RejectApprovalRequestLbl, Codeunit::"Approvals Mgmt.", 'RejectApprovalRequest', RejectApprovalRequestToolTipLbl);
            ErrInfo.AddAction(ShowCommentsLbl, Codeunit::"Approvals Mgmt.", 'ShowApprovalCommentLinesForJournal', ShowCommentsToolTipLbl);
            Error(ErrInfo);
        end;
    end;

    procedure ShowApprovalCommentLinesForJournal(ErrInfo: ErrorInfo)
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        ApprovalComments: Page "Approval Comments";
    begin
        ApprovalCommentLine.SetRange("Table ID", ErrInfo.TableId());
        ApprovalCommentLine.SetRange("Record ID to Approve", ErrInfo.RecordId());
        ApprovalComments.SetTableView(ApprovalCommentLine);
        ApprovalComments.RunModal();
    end;

    procedure RejectApprovalRequest(ErrInfo: ErrorInfo)
    begin
        RejectRecordApprovalRequest(ErrInfo.RecordId());
    end;

    procedure SendJournalLinesApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
    begin
        OnBeforeSendJournalLinesApprovalRequests(GenJournalLine);

        NoOfSelected := GenJournalLine.Count();

        if NoOfSelected = 1 then begin
            TrySendJournalLineApprovalRequests(GenJournalLine);
            exit;
        end;

        repeat
            if not HasOpenApprovalEntries(GenJournalLine.RecordId) then
                GenJournalLine.Mark(true);
        until GenJournalLine.Next() = 0;
        GenJournalLine.MarkedOnly(true);
        if GenJournalLine.Find('-') then;
        NoOfSkipped := NoOfSelected - GenJournalLine.Count();
        BatchProcessingMgt.BatchProcess(GenJournalLine, Codeunit::"Approvals Journal Line Request", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
    end;

    procedure GetGenJnlBatchApprovalStatus(GenJournalLine: Record "Gen. Journal Line"; var GenJnlBatchApprovalStatus: Text[20]; EnabledGenJnlBatchWorkflowsExist: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Clear(GenJnlBatchApprovalStatus);
        if not EnabledGenJnlBatchWorkflowsExist then
            exit;
        if not GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            exit;

        if FindLastApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) then
            GenJnlBatchApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, GenJournalBatch)
        else
            if FindApprovalEntryByRecordId(ApprovalEntry, GenJournalBatch.RecordId) then
                GenJnlBatchApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, GenJournalBatch);
    end;

    procedure GetGenJnlLineApprovalStatus(GenJournalLine: Record "Gen. Journal Line"; var GenJnlLineApprovalStatus: Text[20]; EnabledGenJnlLineWorkflowsExist: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        Clear(GenJnlLineApprovalStatus);
        if not EnabledGenJnlLineWorkflowsExist then
            exit;

        if FindLastApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) then
            GenJnlLineApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, GenJournalLine)
        else
            if FindApprovalEntryByRecordId(ApprovalEntry, GenJournalLine.RecordId) then
                GenJnlLineApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, GenJournalLine);
    end;

    procedure GetRequisitionWkshBatchApprovalStatus(RequisitionLine: Record "Requisition Line"; var ReqWkshBatchApprovalStatus: Text[20]; EnabledReqWkshBatchWorkflowsExist: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        Clear(ReqWkshBatchApprovalStatus);
        if not EnabledReqWkshBatchWorkflowsExist then
            exit;

        if not RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name") then
            exit;

        if FindLastApprovalEntryForCurrUser(ApprovalEntry, RequisitionWkshName.RecordId()) then
            ReqWkshBatchApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, RequisitionWkshName)
        else
            if FindApprovalEntryByRecordId(ApprovalEntry, RequisitionWkshName.RecordId()) then
                ReqWkshBatchApprovalStatus := GetApprovalStatusFromApprovalEntry(ApprovalEntry, RequisitionWkshName);
    end;

    internal procedure SendForApproval(var JobQueueEntry: Record "Job Queue Entry")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if ApprovalsMgmt.CheckJobQueueEntryApprovalEnabled() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            Commit();
            ApprovalsMgmt.OnSendJobQueueEntryForApproval(JobQueueEntry);
            FeatureTelemetry.LogUsage('0000JQE', JobQueueDelegatedAdminCategoryTxt, DelegatedAdminSendingApprovalLbl);
        end else begin
            FeatureTelemetry.LogError('0000JQD', JobQueueDelegatedAdminCategoryTxt, DelegatedAdminSendingApprovalLbl, JobQueueWorkflowSetupErr);
            Error(JobQueueWorkflowSetupErr);
        end;
    end;

    local procedure GetApprovalStatusFromApprovalEntry(var ApprovalEntry: Record "Approval Entry"; GenJournalBatch: Record "Gen. Journal Batch"): Text[20]
    var
        RestrictedRecord: Record "Restricted Record";
        GenJournalLine: Record "Gen. Journal Line";
        FieldRef: FieldRef;
        ApprovalStatusName: Text;
    begin
        GetApprovalEntryStatusFieldRef(FieldRef, ApprovalEntry);
        ApprovalStatusName := GetApprovalEntryStatusValueName(FieldRef, ApprovalEntry);
        if ApprovalStatusName = 'Open' then
            exit(CopyStr(PendingApprovalLbl, 1, 20));
        if ApprovalStatusName = 'Approved' then begin
            RestrictedRecord.SetRange(Details, RestrictBatchUsageDetailsLbl);
            if not RestrictedRecord.IsEmpty() then begin
                RestrictedRecord.Reset();
                GenJournalLine.ReadIsolation(IsolationLevel::ReadUncommitted);
                GenJournalLine.SetLoadFields("Journal Template Name", "Journal Batch Name", "Line No.");
                GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
                GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
                if GenJournalLine.FindSet() then
                    repeat
                        RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
                        if not RestrictedRecord.IsEmpty() then
                            exit(CopyStr(ImposedRestrictionLbl, 1, 20));
                    until GenJournalLine.Next() = 0;
            end;
        end;
        exit(CopyStr(GetApprovalEntryStatusValueCaption(FieldRef, ApprovalEntry), 1, 20));
    end;

    local procedure GetApprovalStatusFromApprovalEntry(var ApprovalEntry: Record "Approval Entry"; GenJournalLine: Record "Gen. Journal Line"): Text[20]
    var
        RestrictedRecord: Record "Restricted Record";
        FieldRef: FieldRef;
        ApprovalStatusName: Text;
    begin
        GetApprovalEntryStatusFieldRef(FieldRef, ApprovalEntry);
        ApprovalStatusName := GetApprovalEntryStatusValueName(FieldRef, ApprovalEntry);
        if ApprovalStatusName = 'Open' then
            exit(CopyStr(PendingApprovalLbl, 1, 20));
        if ApprovalStatusName = 'Approved' then begin
            RestrictedRecord.SetRange("Record ID", GenJournalLine.RecordId);
            if not RestrictedRecord.IsEmpty() then
                exit(CopyStr(ImposedRestrictionLbl, 1, 20));
        end;
        exit(CopyStr(GetApprovalEntryStatusValueCaption(FieldRef, ApprovalEntry), 1, 20));
    end;

    local procedure GetApprovalStatusFromApprovalEntry(var ApprovalEntry: Record "Approval Entry"; RequisitionWkshName: Record "Requisition Wksh. Name"): Text[20]
    var
        RestrictedRecord: Record "Restricted Record";
        RequisitionLine: Record "Requisition Line";
        FieldRef: FieldRef;
        ApprovalStatusName: Text;
    begin
        GetApprovalEntryStatusFieldRef(FieldRef, ApprovalEntry);
        ApprovalStatusName := GetApprovalEntryStatusValueName(FieldRef, ApprovalEntry);
        if ApprovalStatusName = 'Open' then
            exit(CopyStr(PendingApprovalLbl, 1, 20));

        if ApprovalStatusName = 'Approved' then begin
            RestrictedRecord.SetRange(Details, RestrictBatchUsageDetailsLbl);
            if not RestrictedRecord.IsEmpty() then begin
                RestrictedRecord.Reset();
                RequisitionLine.ReadIsolation(IsolationLevel::ReadUncommitted);
                RequisitionLine.SetLoadFields("Worksheet Template Name", "Journal Batch Name", "Line No.");
                RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
                RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
                if RequisitionLine.FindSet() then
                    repeat
                        RestrictedRecord.SetRange("Record ID", RequisitionLine.RecordId);
                        if not RestrictedRecord.IsEmpty() then
                            exit(CopyStr(ImposedRestrictionLbl, 1, 20));
                    until RequisitionLine.Next() = 0;
            end;
        end;

        exit(CopyStr(GetApprovalEntryStatusValueCaption(FieldRef, ApprovalEntry), 1, 20));
    end;

    local procedure GetApprovalEntryStatusFieldRef(var FieldRef: FieldRef; var ApprovalEntry: Record "Approval Entry")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(ApprovalEntry);
        FieldRef := RecordRef.Field(ApprovalEntry.FieldNo(Status));
    end;

    local procedure GetApprovalEntryStatusValueName(var FieldRef: FieldRef; ApprovalEntry: Record "Approval Entry"): Text
    begin
        exit(FieldRef.GetEnumValueName(ApprovalEntry.Status.AsInteger() + 1));
    end;

    local procedure GetApprovalEntryStatusValueCaption(var FieldRef: FieldRef; ApprovalEntry: Record "Approval Entry"): Text
    begin
        exit(FieldRef.GetEnumValueCaption(ApprovalEntry.Status.AsInteger() + 1));
    end;

    procedure CleanGenJournalApprovalStatus(GenJournalLine: Record "Gen. Journal Line"; var GenJnlBatchApprovalStatus: Text[20]; var GenJnlLineApprovalStatus: Text[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalEntry: Record "Approval Entry";
    begin
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if IsGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch) then
                if FindLastApprovalEntryForCurrUser(ApprovalEntry, GenJournalBatch.RecordId) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                    GenJnlBatchApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20)
                else
                    if FindApprovalEntryByRecordId(ApprovalEntry, GenJournalBatch.RecordId) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                        GenJnlBatchApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20);

        if IsGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine) then
            if FindLastApprovalEntryForCurrUser(ApprovalEntry, GenJournalLine.RecordId) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                GenJnlLineApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20)
            else
                if FindApprovalEntryByRecordId(ApprovalEntry, GenJournalLine.RecordId) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                    GenJnlLineApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20);
    end;

    internal procedure CleanRequisitionWkshApprovalStatus(RequisitionLine: Record "Requisition Line"; var ReqWkshBatchApprovalStatus: Text[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalEntry: Record "Approval Entry";
    begin
        if RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name") then
            if IsRequisitionWkshBatchApprovalsWorkflowEnabled(RequisitionWkshName) then
                if FindLastApprovalEntryForCurrUser(ApprovalEntry, RequisitionWkshName.RecordId()) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                    ReqWkshBatchApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20)
                else
                    if FindApprovalEntryByRecordId(ApprovalEntry, RequisitionWkshName.RecordId) and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then
                        ReqWkshBatchApprovalStatus := CopyStr(ImposedRestrictionLbl, 1, 20);
    end;

    local procedure FindOpenApprovalEntryForSequenceNo(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; SequenceNo: Integer): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecRef.Number);
        ApprovalEntry.SetRange("Record ID to Approve", RecRef.RecordId());
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.SetRange("Workflow Step Instance ID", WorkflowStepInstance.ID);
        ApprovalEntry.SetRange("Sequence No.", SequenceNo);

        exit(not ApprovalEntry.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', true, true)]
    local procedure SkipScheduleTaskIfWorkflowEnabledOnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean; var TaskGUID: Guid)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if IsHandled then
            exit;

        if not TaskScheduler.CanCreateTask() then
            if ApprovalsMgmt.CheckJobQueueEntryApprovalEnabled() then
                if ApprovalsMgmt.HasApprovalEntries(JobQueueEntry.RecordId()) then begin
                    IsHandled := true;
                    clear(TaskGUID);
                end
    end;


    [IntegrationEvent(false, false)]
    local procedure OnApproveApprovalRequestsForRecordOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCanCancelApprovalForRecord(RecID: RecordID; var Result: Boolean; var ApprovalEntry: Record "Approval Entry"; UserSetup: Record "User Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchaseDocAmount(PurchaseHeader: Record "Purchase Header"; TotalPurchaseLine: Record "Purchase Line"; TotalPurchaseLineLCY: Record "Purchase Line"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCustomerApprovalsWorkflowEnabled(var Customer: Record Customer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesApprovalPossible(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchaseApprovalPossible(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeWorkflowUserGroup(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprReqForApprTypeApprover(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsSufficientApprover(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDelegateApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindUserSetupBySalesPurchCode(var UserSetup: Record "User Setup"; ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPopulateApprovalEntryArgument(WorkflowStepInstance: Record "Workflow Step Instance"; var ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRejectSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApprovalEntryInsert(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepArgument: Record "Workflow Step Argument"; ApproverId: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchaseApprovalPossible(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateApprovalRequests(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateApprovalRequestForUser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateApprovalRequestForApproverChain(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; SufficientApproverOnly: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateApprovalEntryNotification(ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateApprReqForApprTypeWorkflowUserGroup(var WorkflowUserGroupMember: Record "Workflow User Group Member"; WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntry: Record "Approval Entry"; SequenceNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelegateApprovalRequests(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUserAsApprovalAdministrator(ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasOpenApprovalEntries(RecordID: RecordID; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeApprovalEntry(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepArgument: Record "Workflow Step Argument"; ApproverId: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePopulateApprovalEntryArgument(WorkflowStepInstance: Record "Workflow Step Instance"; var ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePostApprovalCheckPurch(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrePostApprovalCheckSales(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWorkflowEntriesPage(RecordIDInput: RecordID; TableId: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetStatusToPendingApproval(var Variant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApproverType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPurchApprovalStatus(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesApprovalStatus(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsGeneralJournalBatchApprovalsWorkflowEnabled(var GenJournalBatch: Record "Gen. Journal Batch"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsGeneralJournalLineApprovalsWorkflowEnabled(var GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsRequisitionWkshBatchApprovalsWorkflowEnabled(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsPurchaseApprovalsWorkflowEnabled(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSufficientApprover(var UserSetup: Record "User Setup"; ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSufficientSalesApprover(UserSetup: Record "User Setup"; DocumentType: Enum "Sales Document Type"; ApprovalAmountLCY: Decimal; var IsSufficient: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsSufficientPurchApprover(UserSetup: Record "User Setup"; DocumentType: Enum "Purchase Document Type"; var ApprovalAmountLCY: Decimal; var IsSufficient: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectApprovalRequestsForRecord(RecRef: RecordRef; WorkflowStepInstance: Record "Workflow Step Instance"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendApprovalRequestFromApprovalEntry(ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCommonApprovalCommentLineFilters(var RecRef: RecordRef; var ApprovalCommentLine: Record "Approval Comment Line"; var IsHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCommonApprovalStatus(var RecRef: RecordRef; var IsHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubstituteUserIdForApprovalEntry(var ApprovalEntry: Record "Approval Entry"; var IsHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunApprovalCommentsPage(var ApprovalCommentLine: Record "Approval Comment Line"; WorkflowStepInstanceID: Guid; var IsHandle: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrySendJournalLineApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelApprovalRequestsForRecordOnAfterCreateApprovalEntryNotification(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"; OldStatus: Enum "Approval Status");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelApprovalRequestsForRecordOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestForApproverOnAfterCheckUserSetupUserID(var UserSetup: Record "User Setup"; WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; var IsUserAllowedToAproveIfNoApprovalUserExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprReqForApprTypeWorkflowUserGroupOnBeforeMakeApprovalEntry(var WorkflowUserGroupMember: Record "Workflow User Group Member"; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepArgument: Record "Workflow Step Argument"; var ApproverId: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestForApproverChainOnAfterCheckApprovalEntrySenderID(var UserSetup: Record "User Setup"; WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestForApproverChainOnAfterCheckUserSetupSenderID(var UserSetup: Record "User Setup"; WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestForApproverChainOnBeforeCheckApproverId(var UserSetup: Record "User Setup"; WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestForApproverChainOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchaseApprovalPossibleOnAfterCalcShowNothingToApproveError(var PurchaseHeader: Record "Purchase Header"; var ShowNothingToApproveError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelegateSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry"; var CheckCurrentUser: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelegateSelectedApprovalRequestOnBeforeSubstituteUserIdForApprovalEntry(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteApprovalEntriesOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsSufficientGenJournalLineApproverOnAfterRecRefSetTable(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; GenJournalLine: Record "Gen. Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindOpenApprovalEntryForCurrUserOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastSequenceNoOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry"; ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasAnyOpenJournalLineApprovalEntriesOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasPendingApprovalEntriesForWorkflowOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasOpenApprovalEntriesOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApprovalEntriesOnBeforePostedApprovalEntryInsert(var PostedApprovalEntry: Record "Posted Approval Entry"; ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApprovalCommentLinesOnBeforePostedApprovalCommentLineInsert(var PostedApprovalCommentLine: Record "Posted Approval Comment Line"; ApprovalCommentLine: Record "Approval Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectApprovalRequestsForRecordOnAfterCreateApprovalEntryNotification(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"; OldStatus: Enum "Approval Status");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectApprovalRequestsForRecordOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRejectApprovalRequestsForRecordOnBeforeApprovalEntryToUpdateModify(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendApprovalRequestFromRecordOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry"; RecRef: RecordRef; var IsHandled: Boolean; WorkflowStepInstance: Record "Workflow Step Instance")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendApprovalRequestFromApprovalEntryOnAfterSetApprovalEntry2Filters(var ApprovalEntry2: Record "Approval Entry"; ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetStatusToPendingApproval(RecRef: RecordRef; var Variant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowApprovalCommentsOnAfterSetApprovalCommentLineFilters(var ApprovalCommentLine: Record "Approval Comment Line"; ApprovalEntry: Record "Approval Entry"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSubstituteUserIdForApprovalEntryOnAfterCheckUserSetupApprovalEntryApproverID(var UserSetup: Record "User Setup"; ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSubstituteUserIdForApprovalEntryOnBeforeAssignApproverID(ApprovalEntry: Record "Approval Entry"; var UserSetup: Record "User Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTrySendJournalLineApprovalRequestsOnBeforeLoopIteration(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLimitType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApproverType(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckStatus(var ApprovalEntry: Record "Approval Entry"; ApprovalAction: Enum "Approval Action"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestsOnElseCase(WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateApprovalRequestsOnAfterCreateRequests(RecRef: RecordRef; WorkflowStepArgument: Record "Workflow Step Argument"; var ApprovalEntryArgument: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApproveApprovalRequestsForRecordOnBeforeApprovalEntryToUpdateModify(var ApprovalEntryToUpdate: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApproveSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectApprovalRequests(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApproveApprovalRequests(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesApprovalPossible(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindUserSetupBySalesPurchCode(var UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateApprovalRequestForSalespersPurchaser(WorkflowStepArgument: Record "Workflow Step Argument"; ApprovalEntryArgument: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasOpenApprovalEntriesForCurrentUserOnAfterSetApprovalEntryFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRejectSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDelegateSelectedApprovalRequest(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApprovalEntriesOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry"; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostApprovalCommentLinesOnAfterApprovalCommentLineSetFilters(var ApprovalCommentLine: Record "Approval Comment Line"; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteApprovalCommentLinesOnAfterApprovalCommentLineSetFilters(var ApprovalCommentLine: Record "Approval Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHasOpenApprovalEntriesForCurrentUserOnAfterSetApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprovalRequestForApproverChain(var ApprovalEntryArgument: Record "Approval Entry"; var ApproverId: Code[50]; var WorkflowStepArgument: Record "Workflow Step Argument"; var UserSetup: Record "User Setup"; var SufficientApproverOnly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendApprovalRequestFromRecordOnBeforeFindApprovedApprovalEntryForWorkflowUserGroup(ApprovalEntry: Record "Approval Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateApprovalEntryNotification(var ApprovalEntryArgument: Record "Approval Entry"; var WorkflowStepArgument: Record "Workflow Step Argument")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindApprovalEntryForCurrUserOnAfterApprovalEntrySetFilters(var ApprovalEntry: Record "Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendJournalLinesApprovalRequests(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPurchaseDocAmountOnAfterPurchPostGetPurchLines(var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcSalesDocAmount(SalesHeader: Record "Sales Header"; TotalSalesLine: Record "Sales Line"; TotalSalesLineLCY: Record "Sales Line"; var ApprovalAmount: Decimal; var ApprovalAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreventDeletingRecordWithOpenApprovalEntryElseCase(RecRef: RecordRef; Variant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreventInsertRecIfOpenApprovalEntryExistElseCase(RecRef: RecordRef; Variant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindOpenApprovalEntriesForWorkflowStepInstanceOnAfterSetApprovalEntry2Filters(var ApprovalEntry2: Record "Approval Entry"; ApprovalEntry: Record "Approval Entry"; WorkflowStepInstanceRecID: RecordId)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSufficientApproverElseCase(UserSetup: Record "User Setup"; ApprovalEntryArgument: Record "Approval Entry"; var IsSufficient: Boolean)
    begin
    end;
}