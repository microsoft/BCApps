namespace System.Environment.Configuration;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Automation;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

codeunit 1510 "Notification Management"
{
    Permissions = TableData "Overdue Approval Entry" = ri,
                  TableData "Notification Entry" = rimd,
                  TableData "Sent Notification Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        OverdueEntriesMsg: Label 'Overdue approval entries have been created.';
        SalesInvoiceTxt: Label 'Sales Invoice';
        PurchaseInvoiceTxt: Label 'Purchase Invoice';
        SalesCreditMemoTxt: Label 'Sales Credit Memo';
        PurchaseCreditMemoTxt: Label 'Purchase Credit Memo';
        ActionNewRecordTxt: Label 'has been created.', Comment = 'E.g. Sales Invoice 10000 has been created.';
        ActionApproveTxt: Label 'requires your approval.', Comment = 'E.g. Sales Invoice 10000 requires your approval.';
        ActionApprovedTxt: Label 'has been approved.', Comment = 'E.g. Sales Invoice 10000 has been approved.';
        ActionApprovalCreatedTxt: Label 'approval request has been created.', Comment = 'E.g. Sales Invoice 10000 approval request has been created.';
        ActionApprovalCanceledTxt: Label 'approval request has been canceled.', Comment = 'E.g. Sales Invoice 10000 approval request has been canceled.';
        ActionApprovalRejectedTxt: Label 'approval has been rejected.', Comment = 'E.g. Sales Invoice 10000 approval request has been rejected.';
        ActionOverdueTxt: Label 'has a pending approval.', Comment = 'E.g. Sales Invoice 10000 has a pending approval.';

    procedure CreateOverdueNotifications(WorkflowStepArgument: Record "Workflow Step Argument")
    var
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        OverdueApprovalEntry: Record "Overdue Approval Entry";
        NotificationEntry: Record "Notification Entry";
        IsHandled: Boolean;
    begin
        if UserSetup.FindSet() then
            repeat
                ApprovalEntry.Reset();
                ApprovalEntry.SetRange("Approver ID", UserSetup."User ID");
                ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
                ApprovalEntry.SetFilter("Due Date", '<=%1', Today);
                if ApprovalEntry.FindSet() then
                    repeat
                        InsertOverdueEntry(ApprovalEntry, OverdueApprovalEntry);
                        IsHandled := false;
                        OnCreateOverdueNotificationsOnBeforeCreateNotificationEntry(UserSetup, ApprovalEntry, OverdueApprovalEntry, WorkflowStepArgument, IsHandled);
                        if not IsHandled then
                            NotificationEntry.CreateNotificationEntry(NotificationEntry.Type::Overdue,
                              UserSetup."User ID", OverdueApprovalEntry, WorkflowStepArgument."Link Target Page",
                              WorkflowStepArgument."Custom Link", CopyStr(UserId(), 1, 50));
                    until ApprovalEntry.Next() = 0;
            until UserSetup.Next() = 0;

        Message(OverdueEntriesMsg);
    end;

    local procedure InsertOverdueEntry(ApprovalEntry: Record "Approval Entry"; var OverdueApprovalEntry: Record "Overdue Approval Entry")
    var
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        OnBeforeInsertOverdueEntry(ApprovalEntry, OverdueApprovalEntry);

        OverdueApprovalEntry.Init();
        OverdueApprovalEntry."Approver ID" := ApprovalEntry."Approver ID";
        User.SetRange("User Name", ApprovalEntry."Approver ID");
        if User.FindFirst() then begin
            OverdueApprovalEntry."Sent to Name" := CopyStr(User."Full Name", 1, MaxStrLen(OverdueApprovalEntry."Sent to Name"));
            UserSetup.Get(User."User Name");
        end;

        OverdueApprovalEntry."Table ID" := ApprovalEntry."Table ID";
        OverdueApprovalEntry."Document Type" := ApprovalEntry."Document Type";
        OverdueApprovalEntry."Document No." := ApprovalEntry."Document No.";
        OverdueApprovalEntry."Sent to ID" := ApprovalEntry."Approver ID";
        OverdueApprovalEntry."Sent Date" := Today;
        Sleep(1);
        // to make sure Time() is different 
        OverdueApprovalEntry."Sent Time" := Time;
        OverdueApprovalEntry."E-Mail" := UserSetup."E-Mail";
        OverdueApprovalEntry."Sequence No." := ApprovalEntry."Sequence No.";
        OverdueApprovalEntry."Due Date" := ApprovalEntry."Due Date";
        OverdueApprovalEntry."Approval Code" := ApprovalEntry."Approval Code";
        OverdueApprovalEntry."Approval Type" := ApprovalEntry."Approval Type";
        OverdueApprovalEntry."Limit Type" := ApprovalEntry."Limit Type";
        OverdueApprovalEntry."Record ID to Approve" := ApprovalEntry."Record ID to Approve";
        OverdueApprovalEntry.Insert();
    end;

    procedure CreateDefaultNotificationTypeSetup(NotificationType: Enum "Notification Entry Type")
    var
        NotificationSetup: Record "Notification Setup";
    begin
        if DefaultNotificationEntryExists(NotificationType) then
            exit;

        NotificationSetup.Init();
        NotificationSetup.Validate("Notification Type", NotificationType);
        NotificationSetup.Validate("Notification Method", NotificationSetup."Notification Method"::Email);
        OnBeforeInsertNotificationSetup(NotificationSetup, NotificationType);
        NotificationSetup.Insert(true);
    end;

    local procedure DefaultNotificationEntryExists(NotificationType: Enum "Notification Entry Type"): Boolean
    var
        NotificationSetup: Record "Notification Setup";
    begin
        NotificationSetup.SetRange("User ID", '');
        NotificationSetup.SetRange("Notification Type", NotificationType);
        exit(not NotificationSetup.IsEmpty)
    end;

    procedure MoveNotificationEntryToSentNotificationEntries(var NotificationEntry: Record "Notification Entry"; NotificationBody: Text; AggregatedNotifications: Boolean; NotificationMethod: Option)
    var
        SentNotificationEntry: Record "Sent Notification Entry";
        InitialSentNotificationEntry: Record "Sent Notification Entry";
    begin
        if AggregatedNotifications then begin
            if NotificationEntry.FindSet() then begin
                InitialSentNotificationEntry.NewRecord(NotificationEntry, NotificationBody, NotificationMethod);
                while NotificationEntry.Next() <> 0 do begin
                    SentNotificationEntry.NewRecord(NotificationEntry, NotificationBody, NotificationMethod);
                    SentNotificationEntry.Validate("Aggregated with Entry", InitialSentNotificationEntry.ID);
                    SentNotificationEntry.Modify(true);
                end;
            end;
            NotificationEntry.DeleteAll(true);
        end else begin
            SentNotificationEntry.NewRecord(NotificationEntry, NotificationBody, NotificationMethod);
            NotificationEntry.Delete(true);
        end;
    end;

    procedure GetDocumentTypeAndNumber(var RecRef: RecordRef; var DocumentType: Text; var DocumentNo: Text)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        FieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        case RecRef.Number of
            DATABASE::"Incoming Document":
                begin
                    DocumentType := RecRef.Caption;
                    FieldRef := RecRef.Field(2);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    DocumentType := SalesHeader.GetFullDocTypeTxt();

                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    DocumentType := PurchaseHeader.GetFullDocTypeTxt();

                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentType := SalesInvoiceTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Purch. Inv. Header":
                begin
                    DocumentType := PurchaseInvoiceTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentType := SalesCreditMemoTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    DocumentType := PurchaseCreditMemoTxt;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            DATABASE::"Gen. Journal Line":
                begin
                    DocumentType := RecRef.Caption;
                    FieldRef := RecRef.Field(1);
                    DocumentNo := Format(FieldRef.Value);
                    FieldRef := RecRef.Field(51);
                    DocumentNo += ',' + Format(FieldRef.Value);
                    FieldRef := RecRef.Field(2);
                    DocumentNo += ',' + Format(FieldRef.Value);
                end;
            DATABASE::"Gen. Journal Batch":
                begin
                    DocumentType := RecRef.Caption;
                    FieldRef := RecRef.Field(1);
                    DocumentNo := Format(FieldRef.Value);
                    FieldRef := RecRef.Field(2);
                    DocumentNo += ',' + Format(FieldRef.Value);
                end;
            DATABASE::Customer,
            DATABASE::Vendor,
            DATABASE::Item:
                begin
                    DocumentType := RecRef.Caption;
                    FieldRef := RecRef.Field(1);
                    DocumentNo := Format(FieldRef.Value);
                end;
            else begin
                IsHandled := false;
                OnGetDocumentTypeAndNumber(RecRef, DocumentType, DocumentNo, IsHandled);
                if not IsHandled then begin
                    DocumentType := RecRef.Caption;
                    FieldRef := RecRef.Field(3);
                    DocumentNo := Format(FieldRef.Value);
                end;
            end;
        end;
    end;

    procedure GetActionTextFor(var NotificationEntry: Record "Notification Entry"): Text
    var
        ApprovalEntry: Record "Approval Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        CustomText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetActionTextFor(NotificationEntry, CustomText, IsHandled);
        if IsHandled then
            exit(CustomText);

        case NotificationEntry.Type of
            NotificationEntry.Type::"New Record":
                exit(ActionNewRecordTxt);
            NotificationEntry.Type::Approval:
                begin
                    DataTypeManagement.GetRecordRef(NotificationEntry."Triggered By Record", RecRef);
                    RecRef.SetTable(ApprovalEntry);
                    case ApprovalEntry.Status of
                        ApprovalEntry.Status::Open:
                            exit(ActionApproveTxt);
                        ApprovalEntry.Status::Canceled:
                            exit(ActionApprovalCanceledTxt);
                        ApprovalEntry.Status::Rejected:
                            exit(ActionApprovalRejectedTxt);
                        ApprovalEntry.Status::Created:
                            exit(ActionApprovalCreatedTxt);
                        ApprovalEntry.Status::Approved:
                            exit(ActionApprovedTxt);
                    end;
                end;
            NotificationEntry.Type::Overdue:
                exit(ActionOverdueTxt);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetActionTextFor(var NotificationEntry: Record "Notification Entry"; var CustomText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOverdueEntry(ApprovalEntry: Record "Approval Entry"; var OverdueApprovalEntry: Record "Overdue Approval Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentTypeAndNumber(var RecRef: RecordRef; var DocumentType: Text; var DocumentNo: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOverdueNotificationsOnBeforeCreateNotificationEntry(UserSetup: Record "User Setup"; ApprovalEntry: Record "Approval Entry"; var OverdueApprovalEntry: Record "Overdue Approval Entry"; WorkflowStepArgument: Record "Workflow Step Argument"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNotificationSetup(var NotificationSetup: Record "Notification Setup"; NotificationType: Enum "Notification Entry Type")
    begin
    end;
}

