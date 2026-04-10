// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.IO;

/// <summary>
/// Manages payment export operations for customer ledger entries.
/// This codeunit handles the export of customer refund payments to external payment files.
/// </summary>
codeunit 1208 "Pmt Export Mgt Cust Ledg Entry"
{
    Permissions = TableData "Cust. Ledger Entry" = rm;

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
    /// Exports customer payment file with user confirmation if entries were previously exported.
    /// This procedure prompts the user if re-exporting already exported entries.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entries to export for payment processing.</param>
    [Scope('OnPrem')]
    procedure ExportCustPaymentFileYN(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if IsCustLedgerEntryExported(CustLedgerEntry) or IsAppliedToCustPaymentExported(CustLedgerEntry) then
            if not Confirm(ExportAgainQst) then
                exit;
        ExportCustPaymentFile(CustLedgerEntry);
    end;

    local procedure IsCustLedgerEntryExported(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // In case of selecting more than one line on the page.
        if CustLedgerEntry.MarkedOnly() then begin
            CustLedgerEntry2.MarkedOnly(true);
            CustLedgerEntry2.SetRange(CustLedgerEntry2."Exported to Payment File", true);
            exit(not CustLedgerEntry2.IsEmpty());
        end;

        // In case of selecting one line on the page or passing a variable directly.
        if CustLedgerEntry.HasFilter() then begin
            CustLedgerEntry2.CopyFilters(CustLedgerEntry);
            CustLedgerEntry2.SetRange(CustLedgerEntry2."Exported to Payment File", true);
            exit(not CustLedgerEntry2.IsEmpty());
        end;

        // The case of a record not being passed via the user interface is not supported.
        exit(false);
    end;

    local procedure IsAppliedToCustPaymentExported(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        AppliedToCustLedgerEntry: Record "Cust. Ledger Entry";
        ExportCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        case true of
            CustLedgerEntry.MarkedOnly:
                ExportCustLedgerEntry.MarkedOnly(true);
            CustLedgerEntry.HasFilter:
                begin
                    ExportCustLedgerEntry.CopyFilters(CustLedgerEntry);
                    ExportCustLedgerEntry.FindSet();
                end;
            else
                ExportCustLedgerEntry.Copy(CustLedgerEntry);
        end;

        AppliedToCustLedgerEntry.SetRange("Exported to Payment File", true);
        repeat
            AppliedToCustLedgerEntry.SetRange("Closed by Entry No.", ExportCustLedgerEntry."Entry No.");
            if not AppliedToCustLedgerEntry.IsEmpty() then
                exit(true);
        until ExportCustLedgerEntry.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Exports customer payment file after validation without user prompts.
    /// This procedure validates and exports customer ledger entries for payment processing.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entries to export for payment processing.</param>
    [Scope('OnPrem')]
    procedure ExportCustPaymentFile(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CODEUNIT.Run(CODEUNIT::"Pmt. Export Cust. Ledger Check", CustLedgerEntry);
        ExportCustLedgerEntry(CustLedgerEntry);
        SetExportFlagOnCustLedgerEntries(CustLedgerEntry);
    end;

    /// <summary>
    /// Processes customer ledger entries for export to payment file format.
    /// This procedure creates the data exchange entries and export file for customer payments.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entries to process for export.</param>
    [Scope('OnPrem')]
    procedure ExportCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        DataExch: Record "Data Exch.";
        Window: Dialog;
        LineNo: Integer;
        LineAmount: Decimal;
        TransferDate: Date;
        TotalAmount: Decimal;
        HandledGenJnlDataExchLine: Boolean;
        HandledPaymentExportVendLedgerEntry: Boolean;
    begin
        CustLedgerEntry2.Copy(CustLedgerEntry);
        PaymentExportMgt.CreateDataExch(DataExch, CustLedgerEntry2."Bal. Account No.");
        Window.Open(ProgressMsg);
        repeat
            LineNo += 1;
            Window.Update(1, LineNo);
            OnBeforeCreateCustLedgerDataExchLine(DataExch, CustLedgerEntry2, LineNo, LineAmount,
              TotalAmount, TransferDate, HandledGenJnlDataExchLine);
            if not HandledGenJnlDataExchLine then
                CreateCustLedgerDataExchLine(DataExch."Entry No.", CustLedgerEntry2, LineNo);
        until CustLedgerEntry2.Next() = 0;
        Window.Close();
        OnBeforePaymentExportCustLedgerEntry(CustLedgerEntry."Bal. Account No.", DataExch."Entry No.",
          LineNo, TotalAmount, TransferDate, HandledPaymentExportVendLedgerEntry);
        if not HandledPaymentExportVendLedgerEntry then
            PaymentExportMgt.ExportToFile(DataExch."Entry No.")
    end;

    local procedure CreateCustLedgerDataExchLine(DataExchEntryNo: Integer; CustLedgerEntry: Record "Cust. Ledger Entry"; LineNo: Integer)
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        PreparePaymentExportDataCLE(PaymentExportData, CustLedgerEntry, DataExchEntryNo, LineNo);
        PaymentExportMgt.CreatePaymentLines(PaymentExportData);
    end;

    /// <summary>
    /// Prepares payment export data from customer ledger entry information.
    /// This procedure converts customer ledger entry data into payment export format for refund file generation.
    /// </summary>
    /// <param name="TempPaymentExportData">Temporary payment export data record to populate.</param>
    /// <param name="CustLedgerEntry">Source customer ledger entry containing payment information.</param>
    /// <param name="DataExchEntryNo">Data exchange entry number for linking.</param>
    /// <param name="LineNo">Line number for the payment export data entry.</param>
    procedure PreparePaymentExportDataCLE(var TempPaymentExportData: Record "Payment Export Data" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        GeneralLedgerSetup.Get();
        Customer.Get(CustLedgerEntry."Customer No.");
        CustomerBankAccount.Get(CustLedgerEntry."Customer No.", CustLedgerEntry."Recipient Bank Account");

        BankAccount.Get(CustLedgerEntry."Bal. Account No.");
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        TempPaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

        CompanyInformation.Get();
        TempPaymentExportData.Init();
        TempPaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        TempPaymentExportData."Sender Bank Account Code" := CustLedgerEntry."Bal. Account No.";
        if CompanyInformation."Registration No." <> '' then
            TempPaymentExportData."Sender Reg. No." := CopyStr(CompanyInformation."Registration No.", 1, MaxStrLen(TempPaymentExportData."Sender Reg. No."));

        if BankAccount."Country/Region Code" = CustomerBankAccount."Country/Region Code" then begin
            CustLedgerEntry.CalcFields("Amount (LCY)");
            TempPaymentExportData.Amount := CustLedgerEntry."Amount (LCY)";
            TempPaymentExportData."Currency Code" := GeneralLedgerSetup."LCY Code";
        end else begin
            CustLedgerEntry.CalcFields(Amount);
            TempPaymentExportData.Amount := CustLedgerEntry.Amount;
            TempPaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(CustLedgerEntry."Currency Code");
        end;

        TempPaymentExportData."Recipient Bank Acc. No." :=
          CopyStr(CustomerBankAccount.GetBankAccountNo(), 1, MaxStrLen(TempPaymentExportData."Recipient Bank Acc. No."));
        TempPaymentExportData."Recipient Reg. No." := CustomerBankAccount."Bank Branch No.";
        TempPaymentExportData."Recipient Acc. No." := CustomerBankAccount."Bank Account No.";
        TempPaymentExportData."Recipient Bank Country/Region" := CustomerBankAccount."Country/Region Code";
        TempPaymentExportData."Recipient Bank Name" := CopyStr(CustomerBankAccount.Name, 1, 35);
        TempPaymentExportData."Recipient Bank Address" := CopyStr(CustomerBankAccount.Address, 1, 35);
        TempPaymentExportData."Recipient Bank City" := CopyStr(CustomerBankAccount."Post Code" + CustomerBankAccount.City, 1, 35);
        TempPaymentExportData."Recipient Bank BIC" := CustomerBankAccount."SWIFT Code";

        TempPaymentExportData."Recipient Name" := CopyStr(Customer.Name, 1, 35);
        TempPaymentExportData."Recipient Address" := CopyStr(Customer.Address, 1, 35);
        TempPaymentExportData."Recipient City" := CopyStr(Customer."Post Code" + ' ' + Customer.City, 1, 35);
        TempPaymentExportData."Transfer Date" := CustLedgerEntry."Posting Date";
        TempPaymentExportData."Message to Recipient 1" := CopyStr(CustLedgerEntry."Message to Recipient", 1, 35);
        TempPaymentExportData."Message to Recipient 2" := CopyStr(CustLedgerEntry."Message to Recipient", 36, 70);
        TempPaymentExportData."Document No." := CustLedgerEntry."Document No.";
        TempPaymentExportData."Applies-to Ext. Doc. No." := CustLedgerEntry."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Short Advice" := CustLedgerEntry."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Line No." := LineNo;
        if PaymentMethod.Get(CustLedgerEntry."Payment Method Code") then
            TempPaymentExportData."Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
        OnPreparePaymentExportDataCLEOnBeforeTempPaymentExportDataInsert(TempPaymentExportData, CustLedgerEntry, GeneralLedgerSetup);
        TempPaymentExportData.Insert(true);
    end;

    /// <summary>
    /// Enables export of payment files to server temporary location.
    /// This procedure configures customer payment export to use server-side temporary files.
    /// </summary>
    /// <param name="SilentServerMode">True to enable silent server mode without user interaction.</param>
    /// <param name="ServerFileExtension">File extension to use for the temporary server file.</param>
    procedure EnableExportToServerTempFile(SilentServerMode: Boolean; ServerFileExtension: Text[3])
    begin
        PaymentExportMgt.EnableExportToServerTempFile(SilentServerMode, ServerFileExtension);
    end;

    /// <summary>
    /// Gets the file name of the server temporary file used for customer payment export.
    /// This procedure returns the path to the temporary file created during customer payment export.
    /// </summary>
    /// <returns>The full path and file name of the server temporary file.</returns>
    procedure GetServerTempFileName(): Text[1024]
    begin
        exit(PaymentExportMgt.GetServerTempFileName());
    end;

    local procedure SetExportFlagOnCustLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.Copy(CustLedgerEntry);
        repeat
            CustLedgerEntry2.Validate(CustLedgerEntry2."Exported to Payment File", true);
            CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry2);
        until CustLedgerEntry2.Next() = 0;
    end;

    /// <summary>
    /// Integration event that allows customization of customer ledger entry payment export processing.
    /// This event enables custom handling of the payment export process for customer entries.
    /// </summary>
    /// <param name="BalAccountNo">Balance account number used for the payment export.</param>
    /// <param name="DataExchEntryNo">Data exchange entry number for the export operation.</param>
    /// <param name="LineCount">Number of lines being processed in the export.</param>
    /// <param name="TotalAmount">Total amount of all payments being exported.</param>
    /// <param name="TransferDate">Date for the payment transfer.</param>
    /// <param name="Handled">Set to true if the export processing has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforePaymentExportCustLedgerEntry(BalAccountNo: Code[20]; DataExchEntryNo: Integer; LineCount: Integer; TotalAmount: Decimal; TransferDate: Date; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of customer ledger data exchange line creation.
    /// This event enables custom processing before creating data exchange lines for customer payments.
    /// </summary>
    /// <param name="DataExch">Data exchange record being processed.</param>
    /// <param name="CustLedgerEntry">Customer ledger entry being processed for export.</param>
    /// <param name="LineNo">Line number for the data exchange entry.</param>
    /// <param name="LineAmount">Amount for the specific line being processed.</param>
    /// <param name="TotalAmount">Running total amount for all processed lines.</param>
    /// <param name="TransferDate">Date for the payment transfer.</param>
    /// <param name="Handled">Set to true if the line creation has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeCreateCustLedgerDataExchLine(DataExch: Record "Data Exch."; CustLedgerEntry: Record "Cust. Ledger Entry"; LineNo: Integer; var LineAmount: Decimal; var TotalAmount: Decimal; var TransferDate: Date; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of payment export data before insertion from customer ledger entries.
    /// This event enables modifications to payment export data during customer payment file generation.
    /// </summary>
    /// <param name="TempPaymentExportData">Payment export data record that can be modified.</param>
    /// <param name="CustLedgerEntry">Source customer ledger entry containing the payment information.</param>
    /// <param name="GeneralLedgerSetup">General ledger setup record for accessing configuration.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPreparePaymentExportDataCLEOnBeforeTempPaymentExportDataInsert(var TempPaymentExportData: Record "Payment Export Data" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;
}

