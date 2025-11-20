namespace System.Automation;

using Microsoft.Bank.Check;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Threading;

codeunit 1550 "Record Restriction Mgt."
{
    Permissions = TableData "Restricted Record" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        RecordRestrictedTxt: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
#pragma warning restore AA0470
        RestrictLineUsageDetailsTxt: Label 'The restriction was imposed because the line requires approval.';
        RestrictBatchUsageDetailsTxt: Label 'The restriction was imposed because the journal batch requires approval.';

    procedure RestrictRecordUsage(RecVar: Variant; RestrictionDetails: Text)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        if RecRef.IsTemporary then
            exit;

        OnRestrictRecordUsageOnBeforeSetFilter(RestrictedRecord, RecRef);
        SetRestrictedRecordFiltersForRecRef(RestrictedRecord, RecRef);

        RestrictedRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if RestrictedRecord.FindFirst() then begin
            RestrictedRecord.Details := CopyStr(RestrictionDetails, 1, MaxStrLen(RestrictedRecord.Details));
            RestrictedRecord.Modify(true);
        end else begin
            RestrictedRecord.Init();
            RestrictedRecord."Record ID" := RecRef.RecordId;
            RestrictedRecord.Details := CopyStr(RestrictionDetails, 1, MaxStrLen(RestrictedRecord.Details));
            RestrictedRecord.Insert(true);
        end;
    end;

    procedure AllowGenJournalBatchUsage(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AllowRecordUsage(GenJournalBatch);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindSet() then
            repeat
                AllowRecordUsage(GenJournalLine);
            until GenJournalLine.Next() = 0;
    end;

    procedure AllowItemJournalBatchUsage(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        AllowRecordUsage(ItemJournalBatch);

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        if ItemJournalLine.FindSet() then
            repeat
                AllowRecordUsage(ItemJournalLine);
            until ItemJournalLine.Next() = 0;
    end;

    procedure AllowFAJournalBatchUsage(FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        AllowRecordUsage(FAJournalBatch);

        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
        if FAJournalLine.FindSet() then
            repeat
                AllowRecordUsage(FAJournalLine);
            until FAJournalLine.Next() = 0;
    end;

    procedure AllowRequisitionWkshUsage(RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AllowRecordUsage(RequisitionWkshName);

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        if RequisitionLine.FindSet() then
            repeat
                AllowRecordUsage(RequisitionLine);
            until RequisitionLine.Next() = 0;
    end;

    procedure AllowRecordUsage(RecVar: Variant)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        if RecRef.IsTemporary then
            exit;

        RestrictedRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if RestrictedRecord.IsEmpty() then
            exit;

        OnAllowRecordUsageOnBeforeSetFilter(RestrictedRecord, RecRef);
        SetRestrictedRecordFiltersForRecRef(RestrictedRecord, RecRef);
        RestrictedRecord.LockTable(true);
        RestrictedRecord.DeleteAll(true);
    end;

    procedure UpdateRestriction(RecVar: Variant; xRecVar: Variant)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
        xRecRef: RecordRef;
    begin
        xRecRef.GetTable(xRecVar);
        RecRef.GetTable(RecVar);

        if RecRef.IsTemporary then
            exit;

        RestrictedRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if RestrictedRecord.IsEmpty() then
            exit;

        OnUpdateRestrictionOnBeforeSetFilter(RestrictedRecord, RecRef, xRecRef);
        SetRestrictedRecordFiltersForRecRef(RestrictedRecord, xRecRef);
        RestrictedRecord.ModifyAll("Record ID", RecRef.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterInsertEvent', '', false, false)]
    procedure RestrictGenJournalLineAfterInsert(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        RestrictGenJournalLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterModifyEvent', '', false, false)]
    procedure RestrictGenJournalLineAfterModify(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if Format(Rec) = Format(xRec) then
            exit;
        RestrictGenJournalLine(Rec);
    end;

    local procedure RestrictGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if GenJournalLine."System-Created Entry" or GenJournalLine.IsTemporary then
            exit;

        if ApprovalsMgmt.IsGeneralJournalLineApprovalsWorkflowEnabled(GenJournalLine) then
            RestrictRecordUsage(GenJournalLine, RestrictLineUsageDetailsTxt);

        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if ApprovalsMgmt.IsGeneralJournalBatchApprovalsWorkflowEnabled(GenJournalBatch) then
                RestrictRecordUsage(GenJournalLine, RestrictBatchUsageDetailsTxt);
    end;

    local procedure CheckGenJournalBatchHasUsageRestrictions(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CheckRecordHasUsageRestrictions(GenJournalBatch);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindSet() then
            repeat
                CheckRecordHasUsageRestrictions(GenJournalLine);
            until GenJournalLine.Next() = 0;
    end;

    local procedure CheckGenJournalLineHasUsageRestrictions(GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CheckRecordHasUsageRestrictions(GenJournalBatch);
        CheckRecordHasUsageRestrictions(GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterInsertEvent', '', false, false)]
    procedure RestrictRequisitionLineAfterInsert(var Rec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        RestrictRequisitionWkshLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterModifyEvent', '', false, false)]
    procedure RestrictRequisitionLineAfterModify(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        if Format(Rec) = Format(xRec) then
            exit;

        RestrictRequisitionWkshLine(Rec);
    end;

    local procedure RestrictRequisitionWkshLine(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if RequisitionLine.IsTemporary then
            exit;

        if RequisitionWkshName.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name") then
            if ApprovalsMgmt.IsRequisitionWkshBatchApprovalsWorkflowEnabled(RequisitionWkshName) then
                RestrictRecordUsage(RequisitionLine, RestrictBatchUsageDetailsTxt);
    end;

    [TryFunction]
    procedure CheckRecordHasUsageRestrictions(RecVar: Variant)
    var
        RestrictedRecord: Record "Restricted Record";
        RecRef: RecordRef;
        ErrorMessage: Text;
    begin
        RecRef.GetTable(RecVar);
        if RecRef.IsTemporary then
            exit;

        RestrictedRecord.ReadIsolation := IsolationLevel::ReadCommitted;
        if RestrictedRecord.IsEmpty() then
            exit;

        OnCheckRecordHasUsageRestrictionsOnBeforeSetFilter(RestrictedRecord, RecRef);
        SetRestrictedRecordFiltersForRecRef(RestrictedRecord, RecRef);
        if not RestrictedRecord.FindFirst() then
            exit;

        ErrorMessage :=
          StrSubstNo(
            RecordRestrictedTxt,
            Format(Format(RestrictedRecord."Record ID", 0, 1))) + '\\' + RestrictedRecord.Details;

        Error(ErrorMessage);
    end;

    local procedure SetRestrictedRecordFiltersForRecRef(var RestrictedRecord: Record "Restricted Record"; RecordRef: RecordRef)
    begin
        RestrictedRecord.SetRange("Record ID", RecordRef.RecordId);
        OnAfterSetRestrictedRecordFiltersForRecRef(RestrictedRecord, RecordRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCheckSalesPostRestrictions', '', false, false)]
    procedure CustomerCheckSalesPostRestrictions(var Sender: Record "Sales Header")
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustomerCheckSalesPostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        Customer.Get(Sender."Sell-to Customer No.");
        CheckRecordHasUsageRestrictions(Customer);
        if Sender."Sell-to Customer No." = Sender."Bill-to Customer No." then
            exit;
        Customer.Get(Sender."Bill-to Customer No.");
        CheckRecordHasUsageRestrictions(Customer);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnCheckPurchasePostRestrictions', '', false, false)]
    procedure VendorCheckPurchasePostRestrictions(var Sender: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendorCheckPurchasePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        Vendor.Get(Sender."Buy-from Vendor No.");
        CheckRecordHasUsageRestrictions(Vendor);
        if Sender."Buy-from Vendor No." = Sender."Pay-to Vendor No." then
            exit;
        Vendor.Get(Sender."Pay-to Vendor No.");
        CheckRecordHasUsageRestrictions(Vendor);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLinePostRestrictions', '', false, false)]
    procedure CustomerCheckGenJournalLinePostRestrictions(var Sender: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCustomerCheckGenJournalLinePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        if (Sender."Account Type" = Sender."Account Type"::Customer) and (Sender."Account No." <> '') then begin
            Customer.Get(Sender."Account No.");
            CheckRecordHasUsageRestrictions(Customer);
        end;

        if (Sender."Bal. Account Type" = Sender."Bal. Account Type"::Customer) and (Sender."Bal. Account No." <> '') then begin
            Customer.Get(Sender."Bal. Account No.");
            CheckRecordHasUsageRestrictions(Customer);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLinePostRestrictions', '', false, false)]
    procedure VendorCheckGenJournalLinePostRestrictions(var Sender: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVendorCheckGenJournalLinePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        if (Sender."Account Type" = Sender."Account Type"::Vendor) and (Sender."Account No." <> '') then begin
            Vendor.Get(Sender."Account No.");
            CheckRecordHasUsageRestrictions(Vendor);
        end;

        if (Sender."Bal. Account Type" = Sender."Bal. Account Type"::Vendor) and (Sender."Bal. Account No." <> '') then begin
            Vendor.Get(Sender."Bal. Account No.");
            CheckRecordHasUsageRestrictions(Vendor);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnCheckItemJournalLinePostRestrictions', '', false, false)]
    local procedure ItemJournalLineCheckItemPostRestrictions(var Sender: Record "Item Journal Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemJournalLineCheckItemPostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
        Item.Get(Sender."Item No.");
        CheckRecordHasUsageRestrictions(Item);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLinePostRestrictions', '', false, false)]
    procedure GenJournalLineCheckGenJournalLinePostRestrictions(var Sender: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJournalLineCheckGenJournalLinePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLinePrintCheckRestrictions', '', false, false)]
    procedure GenJournalLineCheckGenJournalLinePrintCheckRestrictions(var Sender: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJournalLineCheckGenJournalLinePrintCheckRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        if Sender."Bank Payment Type" = Sender."Bank Payment Type"::"Computer Check" then
            CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCheckRequisitionWkshLinePostRestrictions', '', false, false)]
    procedure RequisitionWkshBatchCheckRequisitionWkshLinePostRestrictions(var Sender: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not RequisitionWkshName.Get(Sender."Worksheet Template Name", Sender."Journal Batch Name") then
            exit;

        CheckRecordHasUsageRestrictions(RequisitionWkshName);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCheckRequisitionWkshLinePostRestrictions', '', false, false)]
    procedure RequisitionWkshLineCheckRequisitionWkshLinePostRestrictions(var Sender: Record "Requisition Line")
    begin
        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Check Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    procedure CheckPrintRestrictionsBeforeInsertCheckLedgerEntry(var Rec: Record "Check Ledger Entry"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        if Rec.IsTemporary() then
            exit;

        if IsNullGuid(Rec."Print Gen Jnl Line SystemId") then
            exit;

        RecRef.Open(Database::"Gen. Journal Line");
        if not RecRef.GetBySystemId(Rec."Print Gen Jnl Line SystemId") then
            exit;

        CheckRecordHasUsageRestrictions(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Check Ledger Entry", 'OnBeforeModifyEvent', '', false, false)]
    procedure CheckPrintRestrictionsBeforeModifyCheckLedgerEntry(var Rec: Record "Check Ledger Entry"; var xRec: Record "Check Ledger Entry"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
    begin
        if Rec.IsTemporary() then
            exit;

        if GetExecutionContext() = ExecutionContext::Upgrade then
            exit;

        if IsNullGuid(Rec."Print Gen Jnl Line SystemId") then
            exit;

        RecRef.Open(Database::"Gen. Journal Line");
        if not RecRef.GetBySystemId(Rec."Print Gen Jnl Line SystemId") then
            exit;

        CheckRecordHasUsageRestrictions(RecRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLinePostRestrictions', '', false, false)]
    procedure GenJournalBatchCheckGenJournalLinePostRestrictions(var Sender: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJournalBatchCheckGenJournalLinePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        if not GenJournalBatch.Get(Sender."Journal Template Name", Sender."Journal Batch Name") then
            exit;

        CheckRecordHasUsageRestrictions(GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnCheckGenJournalLineExportRestrictions', '', false, false)]
    procedure GenJournalBatchCheckGenJournalLineExportRestrictions(var Sender: Record "Gen. Journal Batch")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJournalBatchCheckGenJournalLineExportRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        if not Sender."Allow Payment Export" then
            exit;

        CheckGenJournalBatchHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCheckGenJournalLineExportRestrictions', '', false, false)]
    local procedure GenJournalLineCheckLineExportRestrictions(var Sender: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJournalLineCheckLineExportRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        GenJournalBatch.SetLoadFields("Allow Payment Export");
        if GenJournalBatch.Get(Sender."Journal Template Name", Sender."Journal Batch Name") then
            if not GenJournalBatch."Allow Payment Export" then
                exit;

        CheckGenJournalLineHasUsageRestrictions(Sender, GenJournalBatch);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCheckSalesPostRestrictions', '', false, false)]
    procedure SalesHeaderCheckSalesPostRestrictions(var Sender: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderCheckSalesPostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCheckSalesReleaseRestrictions', '', false, false)]
    procedure SalesHeaderCheckSalesReleaseRestrictions(var Sender: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderCheckSalesReleaseRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnCheckPurchasePostRestrictions', '', false, false)]
    procedure PurchaseHeaderCheckPurchasePostRestrictions(var Sender: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseHeaderCheckPurchasePostRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnCheckPurchaseReleaseRestrictions', '', false, false)]
    procedure PurchaseHeaderCheckPurchaseReleaseRestrictions(var Sender: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchaseHeaderCheckPurchaseReleaseRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveCustomerRestrictionsBeforeDelete(var Rec: Record Customer; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveVendorRestrictionsBeforeDelete(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveItemRestrictionsBeforeDelete(var Rec: Record Item; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveGenJournalLineRestrictionsBeforeDelete(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveGenJournalBatchRestrictionsBeforeDelete(var Rec: Record "Gen. Journal Batch"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveRequisitionWkshLineRestrictionsBeforeDelete(var Rec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Wksh. Name", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveRequisitionWkshBatchRestrictionsBeforeDelete(var Rec: Record "Requisition Wksh. Name"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemoveSalesHeaderRestrictionsBeforeDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnBeforeDeleteEvent', '', false, false)]
    procedure RemovePurchaseHeaderRestrictionsBeforeDelete(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        AllowRecordUsage(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateGenJournalLineRestrictionsAfterRename(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateRequisitionWkshLineRestrictionsAfterRename(var Rec: Record "Requisition Line"; var xRec: Record "Requisition Line"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnCheckIncomingDocSetForOCRRestrictions', '', false, false)]
    procedure IncomingDocCheckSetForOCRRestrictions(var Sender: Record "Incoming Document")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncomingDocCheckSetForOCRRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnCheckIncomingDocReleaseRestrictions', '', false, false)]
    procedure IncomingDocCheckReleaseRestrictions(var Sender: Record "Incoming Document")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncomingDocCheckReleaseRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateGenJournalBatchRestrictionsAfterRename(var Rec: Record "Gen. Journal Batch"; var xRec: Record "Gen. Journal Batch"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Wksh. Name", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateRequisitionWkshBatchRestrictionsAfterRename(var Rec: Record "Requisition Wksh. Name"; var xRec: Record "Requisition Wksh. Name"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdateSalesHeaderRestrictionsAfterRename(var Rec: Record "Sales Header"; var xRec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterRenameEvent', '', false, false)]
    procedure UpdatePurchaseHeaderRestrictionsAfterRename(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        UpdateRestriction(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnCheckIncomingDocCreateDocRestrictions', '', false, false)]
    procedure IncomingDocCheckCreateDocRestrictions(var Sender: Record "Incoming Document")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIncomingDocCheckCreateDocRestrictions(Sender, IsHandled);
        if IsHandled then
            exit;

        CheckRecordHasUsageRestrictions(Sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeModifyEvent', '', true, true)]
    local procedure CheckRecordRestrictionOnBeforeModifyJobQueueEntry(var Rec: Record "Job Queue Entry")
    begin
        CheckRecordHasUsageRestrictions(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure CheckRecordRestrictionOnBeforeDeleteJobQueueEntry(var Rec: Record "Job Queue Entry")
    begin
        CheckRecordHasUsageRestrictions(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRestrictedRecordFiltersForRecRef(var RestrictedRecord: Record "Restricted Record"; RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomerCheckSalesPostRestrictions(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorCheckPurchasePostRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomerCheckGenJournalLinePostRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorCheckGenJournalLinePostRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJournalLineCheckItemPostRestrictions(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineCheckGenJournalLinePostRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineCheckGenJournalLinePrintCheckRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalBatchCheckGenJournalLinePostRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalBatchCheckGenJournalLineExportRestrictions(var GenJournalBatch: Record "Gen. Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJournalLineCheckLineExportRestrictions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderCheckSalesPostRestrictions(var Sender: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderCheckSalesReleaseRestrictions(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderCheckPurchasePostRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseHeaderCheckPurchaseReleaseRestrictions(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncomingDocCheckSetForOCRRestrictions(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncomingDocCheckReleaseRestrictions(var Sender: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncomingDocCheckCreateDocRestrictions(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRestrictRecordUsageOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAllowRecordUsageOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRestrictionOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef; xRecordReference: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRecordHasUsageRestrictionsOnBeforeSetFilter(var RestrictedRecord: Record "Restricted Record"; RecordReference: RecordRef)
    begin
    end;
}

