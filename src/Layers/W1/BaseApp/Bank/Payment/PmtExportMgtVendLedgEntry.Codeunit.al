// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.IO;

/// <summary>
/// Manages payment export operations for vendor ledger entries.
/// This codeunit handles the export of vendor payments to external payment files.
/// </summary>
codeunit 1207 "Pmt Export Mgt Vend Ledg Entry"
{
    Permissions = TableData "Vendor Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines has already been exported. Do you want to export it again?';
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
#pragma warning restore AA0470
        PaymentExportMgt: Codeunit "Payment Export Mgt";

    /// <summary>
    /// Exports vendor payment file with user confirmation if entries were previously exported.
    /// This procedure prompts the user if re-exporting already exported vendor entries.
    /// </summary>
    /// <param name="VendorLedgerEntry">Vendor ledger entries to export for payment processing.</param>
    [Scope('OnPrem')]
    procedure ExportVendorPaymentFileYN(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if IsVendorLedgerEntryExported(VendorLedgerEntry) or IsAppliedToVendorPaymentExported(VendorLedgerEntry) then
            if not Confirm(ExportAgainQst) then
                exit;
        ExportVendorPaymentFile(VendorLedgerEntry);
    end;

    local procedure IsVendorLedgerEntryExported(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        // In case of selecting more than one line on the page.
        if VendorLedgerEntry.MarkedOnly() then begin
            VendorLedgerEntry2.MarkedOnly(true);
            VendorLedgerEntry2.SetRange("Exported to Payment File", true);
            exit(not VendorLedgerEntry2.IsEmpty());
        end;

        // In case of selecting one line on the page or passing a variable directly.
        if VendorLedgerEntry.HasFilter() then begin
            VendorLedgerEntry2.CopyFilters(VendorLedgerEntry);
            VendorLedgerEntry2.SetRange("Exported to Payment File", true);
            exit(not VendorLedgerEntry2.IsEmpty());
        end;

        // The case of a record not being passed via the user interface is not supported.
        exit(false);
    end;

    local procedure IsAppliedToVendorPaymentExported(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        AppliedToVendLedgerEntry: Record "Vendor Ledger Entry";
        ExportVendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        case true of
            VendorLedgerEntry.MarkedOnly:
                ExportVendLedgerEntry.MarkedOnly(true);
            VendorLedgerEntry.HasFilter:
                begin
                    ExportVendLedgerEntry.CopyFilters(VendorLedgerEntry);
                    ExportVendLedgerEntry.FindSet();
                end;
            else
                ExportVendLedgerEntry.Copy(VendorLedgerEntry);
        end;

        AppliedToVendLedgerEntry.SetRange("Exported to Payment File", true);
        repeat
            AppliedToVendLedgerEntry.SetRange("Closed by Entry No.", ExportVendLedgerEntry."Entry No.");
            if not AppliedToVendLedgerEntry.IsEmpty() then
                exit(true);
        until ExportVendLedgerEntry.Next() = 0;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ExportVendorPaymentFile(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CODEUNIT.Run(CODEUNIT::"Pmt. Export Vend. Ledger Check", VendorLedgerEntry);
        ExportVendLedgerEntry(VendorLedgerEntry);
        SetExportFlagOnVendorLedgerEntries(VendorLedgerEntry);
    end;

    [Scope('OnPrem')]
    procedure ExportVendLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        DataExch: Record "Data Exch.";
        Window: Dialog;
        LineNo: Integer;
        LineAmount: Decimal;
        TransferDate: Date;
        TotalAmount: Decimal;
        HandledGenJnlDataExchLine: Boolean;
        HandledPaymentExportVendLedgerEntry: Boolean;
    begin
        VendorLedgerEntry2.Copy(VendorLedgerEntry);
        PaymentExportMgt.CreateDataExch(DataExch, VendorLedgerEntry2."Bal. Account No.");
        Window.Open(ProgressMsg);
        repeat
            LineNo += 1;
            Window.Update(1, LineNo);
            OnBeforeCreateVendLedgerDataExchLine(DataExch, VendorLedgerEntry2, LineNo, LineAmount,
              TotalAmount, TransferDate, HandledGenJnlDataExchLine);
            if not HandledGenJnlDataExchLine then
                CreateVendLedgerDataExchLine(DataExch."Entry No.", VendorLedgerEntry2, LineNo);
        until VendorLedgerEntry2.Next() = 0;
        Window.Close();

        OnBeforePaymentExportVendorLedgerEntry(VendorLedgerEntry."Bal. Account No.", DataExch."Entry No.",
          LineNo, TotalAmount, TransferDate, HandledPaymentExportVendLedgerEntry);
        if not HandledPaymentExportVendLedgerEntry then
            PaymentExportMgt.ExportToFile(DataExch."Entry No.")
    end;

    local procedure CreateVendLedgerDataExchLine(DataExchEntryNo: Integer; VendorLedgerEntry: Record "Vendor Ledger Entry"; LineNo: Integer)
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PreparePaymentExportDataVLE(PaymentExportData, VendorLedgerEntry, DataExchEntryNo, LineNo);
        PaymentExportMgt.CreatePaymentLines(PaymentExportData);
    end;

    procedure PreparePaymentExportDataVLE(var TempPaymentExportData: Record "Payment Export Data" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CompanyInformation: Record "Company Information";
    begin
        GeneralLedgerSetup.Get();
        Vendor.Get(VendorLedgerEntry."Vendor No.");

        BankAccount.Get(VendorLedgerEntry."Bal. Account No.");
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        TempPaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

        CompanyInformation.Get();
        TempPaymentExportData.Init();
        TempPaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        TempPaymentExportData."Sender Bank Account Code" := VendorLedgerEntry."Bal. Account No.";
        if CompanyInformation."Registration No." <> '' then
            TempPaymentExportData."Sender Reg. No." := CopyStr(CompanyInformation."Registration No.", 1, MaxStrLen(TempPaymentExportData."Sender Reg. No."));

        if VendorBankAccount.Get(VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Recipient Bank Account") then begin
            VendorLedgerEntry.CalcFields(Amount);
            TempPaymentExportData.Amount := VendorLedgerEntry.Amount;
            TempPaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(VendorLedgerEntry."Currency Code");
            TempPaymentExportData."Recipient Bank Acc. No." :=
              CopyStr(VendorBankAccount.GetBankAccountNo(), 1, MaxStrLen(TempPaymentExportData."Recipient Bank Acc. No."));
            TempPaymentExportData."Recipient Reg. No." := VendorBankAccount."Bank Branch No.";
            TempPaymentExportData."Recipient Acc. No." := VendorBankAccount."Bank Account No.";
            TempPaymentExportData."Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
            TempPaymentExportData."Recipient Bank Name" := CopyStr(VendorBankAccount.Name, 1, 35);
            TempPaymentExportData."Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 35);
            TempPaymentExportData."Recipient Bank City" := CopyStr(VendorBankAccount."Post Code" + VendorBankAccount.City, 1, 35);
            TempPaymentExportData."Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
        end else
            if VendorLedgerEntry."Creditor No." <> '' then begin
                VendorLedgerEntry.CalcFields("Amount (LCY)");
                TempPaymentExportData.Amount := VendorLedgerEntry."Amount (LCY)";
                TempPaymentExportData."Currency Code" := GeneralLedgerSetup."LCY Code";
            end;

        TempPaymentExportData."Recipient Name" := CopyStr(Vendor.Name, 1, 35);
        TempPaymentExportData."Recipient Address" := CopyStr(Vendor.Address, 1, 35);
        TempPaymentExportData."Recipient City" := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
        TempPaymentExportData."Transfer Date" := VendorLedgerEntry."Posting Date";
        TempPaymentExportData."Message to Recipient 1" := CopyStr(VendorLedgerEntry."Message to Recipient", 1, 35);
        TempPaymentExportData."Message to Recipient 2" := CopyStr(VendorLedgerEntry."Message to Recipient", 36, 70);
        TempPaymentExportData."Document No." := VendorLedgerEntry."Document No.";
        TempPaymentExportData."Applies-to Ext. Doc. No." := VendorLedgerEntry."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Short Advice" := VendorLedgerEntry."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Line No." := LineNo;
        TempPaymentExportData."Payment Reference" := VendorLedgerEntry."Payment Reference";
        if PaymentMethod.Get(VendorLedgerEntry."Payment Method Code") then
            TempPaymentExportData."Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
        TempPaymentExportData."Recipient Creditor No." := VendorLedgerEntry."Creditor No.";
        OnBeforeInsertPmtExportDataJnlFromVendorLedgerEntry(TempPaymentExportData, VendorLedgerEntry, GeneralLedgerSetup);
        TempPaymentExportData.Insert(true);
    end;

    procedure EnableExportToServerTempFile(SilentServerMode: Boolean; ServerFileExtension: Text[3])
    begin
        PaymentExportMgt.EnableExportToServerTempFile(SilentServerMode, ServerFileExtension);
    end;

    procedure GetServerTempFileName(): Text[1024]
    begin
        exit(PaymentExportMgt.GetServerTempFileName());
    end;

    local procedure SetExportFlagOnVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.Copy(VendorLedgerEntry);
        repeat
            VendorLedgerEntry2.Validate(VendorLedgerEntry2."Exported to Payment File", true);
            CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendorLedgerEntry2);
        until VendorLedgerEntry2.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeInsertPmtExportDataJnlFromVendorLedgerEntry(var PaymentExportData: Record "Payment Export Data"; VendorLedgerEntry: Record "Vendor Ledger Entry"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforePaymentExportVendorLedgerEntry(BalAccountNo: Code[20]; DataExchEntryNo: Integer; LineCount: Integer; TotalAmount: Decimal; TransferDate: Date; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeCreateVendLedgerDataExchLine(DataExch: Record "Data Exch."; VendorLedgerEntry: Record "Vendor Ledger Entry"; LineNo: Integer; var LineAmount: Decimal; var TotalAmount: Decimal; var TransferDate: Date; var Handled: Boolean)
    begin
    end;
}

