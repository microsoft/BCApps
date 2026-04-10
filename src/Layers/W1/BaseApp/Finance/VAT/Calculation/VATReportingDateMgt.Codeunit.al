// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.History;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Security.User;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Manages VAT reporting date functionality including validation, modification controls, and linked entry updates.
/// Provides comprehensive VAT date handling for compliance with VAT reporting requirements and period controls.
/// </summary>
/// <remarks>
/// Key functionality: VAT date validation, linked entry updates, VAT period control integration.
/// Extensibility: Multiple integration events for custom VAT date processing and validation logic.
/// </remarks>
codeunit 799 "VAT Reporting Date Mgt"
{
    SingleInstance = true;
    Permissions = TableData "Issued Reminder Header" = rm,
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Cr.Memo Header" = rm,
                  TableData "G/L Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "VAT Return Period" = r,
                  TableData "General Ledger Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ConfirmManagement: Codeunit "Confirm Management";
        ErrorMessageManagement: Codeunit "Error Message Management";
        ForwardLinkMgt: Codeunit "Forward Link Mgt.";
        VATDateFeatureTok: Label 'VAT Date', Locked = true;
        VATReturnToWarningMsg: Label 'VAT Return for the chosen date is already %1. Are you sure you want to make this change?', Comment = '%1 - The status of the VAT return.';
        VATReturnFromWarningMsg: Label 'VAT Entry is in a %1 VAT Return period. Are you sure you want to make this change?', Comment = '%1 - The status of the VAT return.';
        VATReturnFromClosedErr: Label 'VAT Entry is in a closed VAT Return Period and can not be changed.';
        VATReturnToClosedErr: Label 'VAT Return Period is closed for the selected date. Please select another date.';
        VATDateNotAllowedErr: Label 'The VAT Date is not within the range of allowed VAT dates.';
        VATDateInPeriodNotAllowedErr: Label 'The specified VAT Date is in a %1 VAT Return Period which was not allowed', Comment = '%1 - VAT Return Period status';
        VATDateFromPeriodNotAllowedErr: Label 'The VAT Date is in a %1 VAT Return Period and was not allowed to change', Comment = '%1 - VAT Return Period status';

    /// <summary>
    /// Updates linked entries when VAT entry VAT reporting date is modified.
    /// Synchronizes VAT date changes across related general ledger and document entries.
    /// </summary>
    /// <param name="VATEntry">VAT entry with updated VAT reporting date</param>
    procedure UpdateLinkedEntries(VATEntry: Record "VAT Entry")
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateLinkedEntries(VATEntry, IsHandled);
        if IsHandled then
            exit;

        FeatureTelemetry.LogUsage('0000I9D', VATDateFeatureTok, 'VAT Date field populated');

        UpdateVATEntries(VATEntry);
        UpdateGLEntries(VATEntry);
        UpdatePostedDocuments(VATEntry);

        OnAfterUpdateLinkedEntries(VATEntry);
    end;

    /// <summary>
    /// Determines whether VAT reporting dates can be modified based on system configuration and permissions.
    /// </summary>
    /// <returns>True if VAT dates are modifiable, false otherwise</returns>
    procedure IsVATDateModifiable() IsModifiable: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeIsVATDateModifiable(IsModifiable, IsHandled);
        if IsHandled then
            exit;

        if GLSetup.Get() then
            IsModifiable := GLSetup."VAT Reporting Date Usage" = GLSetup."VAT Reporting Date Usage"::Enabled;
    end;

    /// <summary>
    /// Checks whether VAT reporting date usage is configured to use posting date as default.
    /// </summary>
    /// <returns>True if VAT date usage is set to posting date, false otherwise</returns>
    procedure IsVATDateUsageSetToPostingDate() IsPostingDate: Boolean
    begin
        if GLSetup.Get() then
            IsPostingDate := GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date";
    end;

    /// <summary>
    /// Checks whether VAT reporting date usage is configured to use document date as default.
    /// </summary>
    /// <returns>True if VAT date usage is set to document date, false otherwise</returns>
    procedure IsVATDateUsageSetToDocumentDate() IsDocumentDate: Boolean
    begin
        if GLSetup.Get() then
            IsDocumentDate := GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Document Date";
    end;

    /// <summary>
    /// Determines whether VAT reporting date functionality is enabled in the system.
    /// </summary>
    /// <returns>True if VAT date feature is enabled, false otherwise</returns>
    procedure IsVATDateEnabled() IsEnabled: Boolean
    var
        IsHandled: Boolean;
    begin
        if not IsHandled then
            OnBeforeIsVATDateEnabledForUse(IsEnabled, IsHandled);
        if IsHandled then
            exit;

        if GLSetup.Get() then
            IsEnabled := GLSetup."VAT Reporting Date Usage" <> GLSetup."VAT Reporting Date Usage"::Disabled;
    end;

    internal procedure IsValidDate(Variant: Variant; VATDateFieldNo: Integer) HasErrors: Boolean
    begin
        exit(IsValidDate(Variant, VATDateFieldNo, false));
    end;

    /// <summary>
    /// Validates VAT reporting date against configured VAT periods and date restrictions.
    /// </summary>
    /// <param name="Variant">Record variant containing the VAT date to validate</param>
    /// <param name="VATDateFieldNo">Field number of the VAT date field in the record</param>
    /// <param name="ThrowError">Whether to throw error on validation failure or collect in error messages</param>
    /// <returns>True if validation errors found, false if date is valid</returns>
    procedure IsValidDate(Variant: Variant; VATDateFieldNo: Integer; ThrowError: Boolean) HasErrors: Boolean
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        RecordRef: RecordRef;
        VATDate: Date;
    begin
        ErrorMessageHandler.Activate(ErrorMessageHandler);
        if Variant.IsRecord() then begin
            RecordRef.GetTable(Variant);
            VATDate := RecordRef.Field(VATDateFieldNo).Value();
            ErrorMessageManagement.PushContext(ErrorContextElement, Variant, VATDateFieldNo, ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
        end;
        if Variant.IsDate() then
            VATDate := Variant;

        CheckDateAllowed(VATDate, VATDateFieldNo);
        HasErrors := ErrorMessageHandler.HasErrors();

        if HasErrors and ThrowError then
            if ErrorMessageManagement.GetErrors(TempErrorMessage) then
                Error(TempErrorMessage.Message)
            else
                Error('');

        if Variant.IsRecord() then
            ErrorMessageManagement.PopContext(ErrorContextElement);

        exit(not HasErrors);
    end;

    /// <summary>
    /// Validates VAT reporting date in the specified VAT entry against period restrictions.
    /// </summary>
    /// <param name="VATEntry">VAT entry containing the VAT reporting date to validate</param>
    /// <returns>True if VAT date is valid, false otherwise</returns>
    procedure IsValidVATDate(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(IsValidDate(VATEntry, VATEntry.FieldNo("VAT Reporting Date")));
    end;

    /// <summary>
    /// Validates specified VAT date against configured VAT period restrictions and date ranges.
    /// </summary>
    /// <param name="VATDate">VAT date to validate</param>
    /// <returns>True if VAT date is valid, false otherwise</returns>
    procedure IsValidDate(VATDate: Date): Boolean
    begin
        exit(IsValidDate(VATDate, 0));
    end;

    /// <summary>
    /// Validates and enforces VAT date restrictions, throwing errors for invalid dates.
    /// </summary>
    /// <param name="VATDate">VAT date to check for compliance</param>
    /// <param name="ContextFieldNo">Field number for error context tracking</param>
    procedure CheckDateAllowed(VATDate: Date; ContextFieldNo: Integer)
    begin
        CheckDateAllowed(VATDate, ContextFieldNo, false, true);
    end;

    internal procedure CheckDateAllowed(VATDate: Date; ContextFieldNo: Integer; ExistingEntry: Boolean)
    begin
        CheckDateAllowed(VATDate, ContextFieldNo, ExistingEntry, true)
    end;

    internal procedure CheckDateAllowed(VATDate: Date; ContextFieldNo: Integer; ExistingEntry: Boolean; CheckInAllowPeriod: Boolean)
    var
        UserSetupManagement: Codeunit "User Setup Management";
        SetupRecID: RecordID;
        FieldNo: Integer;
    begin
        if CheckInAllowPeriod then
            if not UserSetupManagement.IsVATDateInAllowedPeriod(VATDate, SetupRecID, FieldNo) then
                ErrorMessageManagement.LogContextFieldError(ContextFieldNo, VATDateNotAllowedErr, SetupRecID, FieldNo, ForwardLinkMgt.GetHelpCodeForAllowedVATDate());

        CheckVATDateValidInVATReturnPeriod(VATDate, ContextFieldNo, ExistingEntry);
    end;

    internal procedure CheckVATDateValidInVATReturnPeriod(VATDate: Date; ContextFieldNo: Integer; ExistingEntry: Boolean)
    var
        VATReturnPeriod: Record "VAT Return Period";
        ClosedError, VATReturnWarning, VATPeriodErr : Text;
    begin
        if ExistingEntry then begin
            ClosedError := VATReturnFromClosedErr;
            VATReturnWarning := VATReturnFromWarningMsg;
            VATPeriodErr := VATDateInPeriodNotAllowedErr
        end else begin
            ClosedError := VATReturnToClosedErr;
            VATReturnWarning := VATReturnToWarningMsg;
            VATPeriodErr := VATDateFromPeriodNotAllowedErr;
        end;
        GLSetup.Get();
        if VATReturnPeriod.FindVATPeriodByDate(VATDate) then
            case GLSetup."Control VAT Period" of
                GLSetup."Control VAT Period"::Disabled:
                    exit;
                GLSetup."Control VAT Period"::"Block posting within closed and warn for released period":
                    begin
                        if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then begin
                            ErrorMessageManagement.LogContextFieldError(ContextFieldNo, ClosedError, VATReturnPeriod, VATReturnPeriod.FieldNo(VATReturnPeriod.Status), ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
                            exit;
                        end;
                        VATReturnPeriod.CalcFields("VAT Return Status");
                        if VATReturnPeriod."VAT Return Status" in [VATReturnPeriod."VAT Return Status"::Released, VATReturnPeriod."VAT Return Status"::Submitted] then
                            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(VATReturnWarning, Format(VATReturnPeriod."VAT Return Status")), true) then
                                ErrorMessageManagement.LogContextFieldError(ContextFieldNo, StrSubstNo(VATPeriodErr, VATReturnPeriod."VAT Return Status"), VATReturnPeriod, VATReturnPeriod.FieldNo(VATReturnPeriod."VAT Return Status"), ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
                    end;
                GLSetup."Control VAT Period"::"Block posting within closed period":
                    if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                        ErrorMessageManagement.LogContextFieldError(ContextFieldNo, ClosedError, VATReturnPeriod, VATReturnPeriod.FieldNo(VATReturnPeriod.Status), ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
                GLSetup."Control VAT Period"::"Warn when posting in closed period":
                    if VATReturnPeriod.Status = VATReturnPeriod.Status::Closed then
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(VATReturnWarning, Format(VATReturnPeriod.Status::Closed)), true) then
                            ErrorMessageManagement.LogContextFieldError(ContextFieldNo, StrSubstNo(VATPeriodErr, VATReturnPeriod.Status), VATReturnPeriod, VATReturnPeriod.FieldNo(VATReturnPeriod.Status), ForwardLinkMgt.GetHelpCodeForAllowedVATDate());
            end;
    end;

    local procedure UpdateGLEntries(VATEntry: Record "VAT Entry")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.LoadFields("Entry No.", "Document No.", "Posting Date", "Transaction No.", "VAT Reporting Date");
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Document No.", VATEntry."Document No.");
        GLEntry.SetRange("Posting Date", VATEntry."Posting Date");
        GLEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLEntry.ModifyAll("VAT Reporting Date", VATEntry."VAT Reporting Date");
    end;

    local procedure UpdateVATEntries(VATEntry: Record "VAT Entry")
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.LoadFields("Entry No.", Type, "Document No.", "Document Type", "Posting Date", "Transaction No.", "VAT Reporting Date");
        VATEntry2.SetFilter("Entry No.", '<>%1', VATEntry."Entry No.");
        VATEntry2.SetRange(Type, VATEntry.Type);
        VATEntry2.SetRange("Document No.", VATEntry."Document No.");
        VATEntry2.SetRange("Document Type", VATEntry."Document Type");
        VATEntry2.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry2.SetRange("Transaction No.", VATEntry."Transaction No.");
        VATEntry2.ModifyAll("VAT Reporting Date", VATEntry."VAT Reporting Date");
    end;

    local procedure UpdatePostedDocuments(VATEntry: Record "VAT Entry")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        RecordRef: RecordRef;
        Updated: Boolean;
    begin
        case VATEntry."Document Type" of
            VATEntry."Document Type"::Invoice:
                begin
                    if VATEntry.Type = VATEntry.Type::Sale then begin
                        FilterSalesInvoiceHeader(VATEntry, SalesInvHeader);
                        RecordRef.GetTable(SalesInvHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, SalesInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        OnUpdatePostedDocumentsOnAfterUpdateSalesInvoice(VATEntry, Updated);
                    end;
                    if VATEntry.Type = VATEntry.Type::Purchase then begin
                        FilterPurchInvoiceHeader(VATEntry, PurchInvHeader);
                        RecordRef.GetTable(PurchInvHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, PurchInvHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                    end;
                end;
            VATEntry."Document Type"::"Credit Memo":
                begin
                    if VATEntry.Type = VATEntry.Type::Sale then begin
                        FilterSalesCrMemoHeader(VATEntry, SalesCrMemoHeader);
                        RecordRef.GetTable(SalesCrMemoHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, SalesCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                        OnUpdatePostedDocumentsOnAfterUpdateSalesCreditMemo(VATEntry, Updated);
                    end;
                    if VATEntry.Type = VATEntry.Type::Purchase then begin
                        FilterPurchCrMemoHeader(VATEntry, PurchCrMemoHeader);
                        RecordRef.GetTable(PurchCrMemoHeader);
                        Updated := UpdateVATDateFromRecordRef(RecordRef, PurchCrMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                    end;
                end;
            VATEntry."Document Type"::"Finance Charge Memo":
                begin
                    FilterIssuedFinChrgMemoHeader(VATEntry, IssuedFinChargeMemoHeader);
                    RecordRef.GetTable(IssuedFinChargeMemoHeader);
                    Updated := UpdateVATDateFromRecordRef(RecordRef, IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                end;
            VATEntry."Document Type"::Reminder:
                begin
                    FilterIssuedReminderHeader(VATEntry, IssuedReminderHeader);
                    RecordRef.GetTable(IssuedReminderHeader);
                    Updated := UpdateVATDateFromRecordRef(RecordRef, IssuedReminderHeader.FieldNo("VAT Reporting Date"), VATEntry."VAT Reporting Date");
                end;
        end;
        if Updated then
            RecordRef.Modify();
    end;

    local procedure FilterSalesInvoiceHeader(VATEntry: Record "VAT Entry"; var SalesInvHeader: Record "Sales Invoice Header")
    begin
        SalesInvHeader.Reset();
        SalesInvHeader.SetRange("No.", VATEntry."Document No.");
        SalesInvHeader.SetRange("Posting Date", VATEntry."Posting Date");
        SalesInvHeader.SetRange("External Document No.", VATEntry."External Document No.");
    end;

    local procedure FilterSalesCrMemoHeader(VATEntry: Record "VAT Entry"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader.Reset();
        SalesCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        SalesCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
        SalesCrMemoHeader.SetRange("External Document No.", VATEntry."External Document No.");
    end;

    local procedure FilterIssuedReminderHeader(VATEntry: Record "VAT Entry"; var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.Reset();
        IssuedReminderHeader.SetRange("No.", VATEntry."Document No.");
        IssuedReminderHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterIssuedFinChrgMemoHeader(VATEntry: Record "VAT Entry"; var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChargeMemoHeader.Reset();
        IssuedFinChargeMemoHeader.SetRange("No.", VATEntry."Document No.");
        IssuedFinChargeMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure FilterPurchInvoiceHeader(VATEntry: Record "VAT Entry"; var PurchInvoiceHeader: Record "Purch. Inv. Header")
    begin
        PurchInvoiceHeader.Reset();
        PurchInvoiceHeader.SetRange("No.", VATEntry."Document No.");
        PurchInvoiceHeader.SetRange("Posting Date", VATEntry."Posting Date");
        PurchInvoiceHeader.SetRange("Vendor Invoice No.", VATEntry."External Document No.");
    end;

    local procedure FilterPurchCrMemoHeader(VATEntry: Record "VAT Entry"; var PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHeader.Reset();
        PurchCrMemoHeader.SetRange("No.", VATEntry."Document No.");
        PurchCrMemoHeader.SetRange("Posting Date", VATEntry."Posting Date");
    end;

    local procedure UpdateVATDateFromRecordRef(var RecordRef: RecordRef; FieldId: Integer; VATDate: Date): Boolean
    var
        FieldRef: FieldRef;
    begin
        if RecordRef.FindFirst() then begin
            FieldRef := RecordRef.Field(FieldId);
            FieldRef.Value := VATDate;
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyEventCheckVATReportingDate(var Rec: Record "General Ledger Setup"; var xRec: Record "General Ledger Setup"; RunTrigger: Boolean)
    var
        UserSetup: Record "User Setup";
        VATSetup: Record "VAT Setup";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."VAT Reporting Date Usage" = xRec."VAT Reporting Date Usage" then
            exit;

        if Rec."VAT Reporting Date Usage" = Enum::"VAT Reporting Date Usage"::Disabled then begin
            // Disable restriction on VAT posting
            UserSetup.ModifyAll("Allow VAT Date From", 0D);
            UserSetup.ModifyAll("Allow VAT Date To", 0D);
            VATSetup.Get();
            VATSetup."Allow VAT Date From" := 0D;
            VATSetup."Allow VAT Date To" := 0D;
            VATSetup.Modify();

            // Disable check of VAT return periods 
            Rec."Control VAT Period" := Enum::"VAT Period Control"::Disabled;
        end else
            Rec."Control VAT Period" := Enum::"VAT Period Control"::"Block posting within closed and warn for released period";
        // Ok. We dont change "VAT Reporting Date Usage" in this procedure.
        Rec.Modify();
    end;

    /// <summary>
    /// Integration event raised before determining if VAT reporting dates are modifiable.
    /// Enables custom logic to control VAT date modification permissions.
    /// </summary>
    /// <param name="IsModifiable">Set to true to allow VAT date modification</param>
    /// <param name="IsHandled">Set to true to skip standard modification check</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateModifiable(var IsModifiable: Boolean; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before determining if VAT reporting date feature is enabled.
    /// Enables custom logic to control VAT date feature availability.
    /// </summary>
    /// <param name="IsEnabled">Set to true to enable VAT date feature</param>
    /// <param name="IsHandled">Set to true to skip standard enablement check</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsVATDateEnabledForUse(var IsEnabled: Boolean; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before updating linked entries for VAT date changes.
    /// Enables custom processing or replacement of standard linked entry updates.
    /// </summary>
    /// <param name="VATEntry">VAT entry with updated VAT reporting date</param>
    /// <param name="IsHandled">Set to true to skip standard linked entry updates</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLinkedEntries(VATEntry: Record "VAT Entry"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after updating linked entries for VAT date changes.
    /// Enables custom post-processing after standard linked entry updates are completed.
    /// </summary>
    /// <param name="VATEntry">VAT entry with updated VAT reporting date</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLinkedEntries(VATEntry: Record "VAT Entry");
    begin
    end;

    /// <summary>
    /// Integration event raised after updating sales invoice header during linked entry processing.
    /// Enables custom actions after VAT date updates in posted sales invoices.
    /// </summary>
    /// <param name="VATEntry">VAT entry triggering the document update</param>
    /// <param name="Updated">Indicates whether the sales invoice was successfully updated</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostedDocumentsOnAfterUpdateSalesInvoice(VATEntry: Record "VAT Entry"; var Updated: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after updating sales credit memo header during linked entry processing.
    /// Enables custom actions after VAT date updates in posted sales credit memos.
    /// </summary>
    /// <param name="VATEntry">VAT entry triggering the document update</param>
    /// <param name="Updated">Indicates whether the sales credit memo was successfully updated</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdatePostedDocumentsOnAfterUpdateSalesCreditMemo(VATEntry: Record "VAT Entry"; var Updated: Boolean)
    begin
    end;
}