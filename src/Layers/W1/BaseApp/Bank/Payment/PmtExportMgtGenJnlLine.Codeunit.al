// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.IO;

/// <summary>
/// Manages payment export operations for general journal lines.
/// This codeunit handles the export of payments from journal lines to external payment files.
/// </summary>
codeunit 1206 "Pmt Export Mgt Gen. Jnl Line"
{
    Permissions = TableData "Vendor Ledger Entry" = rm,
                  TableData "Gen. Journal Line" = rm,
                  TableData "Payment Export Data" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        ExportJournalPaymentFile(Rec);
    end;

    var
        ExportAgainQst: Label 'One or more of the selected lines has already been exported. Do you want to export it again?';
        ProgressMsg: Label 'Processing line no. #1######.', Comment = '#1 - Line no.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        EmployeeMustHaveBankAccountNoErr: Label 'You must specify either Bank Account No. or IBAN for employee %1.', Comment = '%1 - Employee name';

    /// <summary>
    /// Exports journal payment file with user confirmation if lines were previously exported.
    /// This procedure prompts the user if re-exporting already exported journal lines.
    /// </summary>
    /// <param name="GenJnlLine">General journal lines to export for payment processing.</param>
    [Scope('OnPrem')]
    procedure ExportJournalPaymentFileYN(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        if GenJnlLine.IsExportedToPaymentFile() then
            if not Confirm(ExportAgainQst) then
                exit;
        ExportJournalPaymentFile(GenJnlLine);
    end;

    /// <summary>
    /// Exports journal payment file without user prompts.
    /// This procedure validates and exports general journal lines for payment processing.
    /// </summary>
    /// <param name="GenJnlLine">General journal lines to export for payment processing.</param>
    [Scope('OnPrem')]
    procedure ExportJournalPaymentFile(var GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        DataExchDef: Record "Data Exch. Def";
    begin
        BankAccount.Get(GenJnlLine."Bal. Account No.");
        BankAccount.GetDataExchDefPaymentExport(DataExchDef);
        CreditTransferRegister.CreateNew(DataExchDef.Code, GenJnlLine."Bal. Account No.");
        Commit();

        CheckGenJnlLine(GenJnlLine);
        ExportGenJnlLine(GenJnlLine, CreditTransferRegister);
    end;

    local procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine.DeletePaymentFileBatchErrors();
        GenJnlLine2.CopyFilters(GenJnlLine);
        if GenJnlLine2.FindSet() then
            repeat
                CODEUNIT.Run(CODEUNIT::"Payment Export Gen. Jnl Check", GenJnlLine2);
                OnCheckGenJnlLine(GenJnlLine2);
            until GenJnlLine2.Next() = 0;

        if GenJnlLine2.HasPaymentFileErrorsInBatch() then begin
            Commit();
            Error(HasErrorsErr);
        end;
    end;

    /// <summary>
    /// Processes general journal lines for export to payment file format.
    /// This procedure creates data exchange entries and credit transfer entries for payment export.
    /// </summary>
    /// <param name="GenJnlLine">General journal lines to process for export.</param>
    /// <param name="CreditTransferRegister">Credit transfer register for tracking the export operation.</param>
    [Scope('OnPrem')]
    procedure ExportGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var CreditTransferRegister: Record "Credit Transfer Register")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        DataExch: Record "Data Exch.";
        CreditTransferEntry: Record "Credit Transfer Entry";
        Window: Dialog;
        LineNo: Integer;
        LineAmount: Decimal;
        TransferDate: Date;
        TotalAmount: Decimal;
        HandledGenJnlDataExchLine: Boolean;
        HandledPaymentExport: Boolean;
    begin
        GenJnlLine2.CopyFilters(GenJnlLine);
        GenJnlLine2.FindSet();

        PaymentExportMgt.CreateDataExch(DataExch, GenJnlLine2."Bal. Account No.");
        GenJnlLine2.ModifyAll("Data Exch. Entry No.", DataExch."Entry No.");

        Window.Open(ProgressMsg);
        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            OnBeforeCreateGenJnlDataExchLine(DataExch, GenJnlLine2, LineNo, LineAmount, TotalAmount, TransferDate, HandledGenJnlDataExchLine);
            if not HandledGenJnlDataExchLine then
                CreateGenJnlDataExchLine(DataExch."Entry No.", GenJnlLine2, LineNo);

            CreditTransferEntry.CreateNew(CreditTransferRegister."No.", LineNo,
              GenJnlLine2."Account Type", GenJnlLine2."Account No.", GenJnlLine2.GetAppliesToDocEntryNo(),
              GenJnlLine2."Posting Date", GenJnlLine2."Currency Code", GenJnlLine2.Amount, '',
              GenJnlLine2."Recipient Bank Account", GenJnlLine2."Message to Recipient");
        until GenJnlLine2.Next() = 0;
        Window.Close();

        OnBeforePaymentExport(GenJnlLine."Bal. Account No.", DataExch."Entry No.", LineNo, TotalAmount, TransferDate, HandledPaymentExport);
        if not HandledPaymentExport then
            PaymentExportMgt.ExportToFile(DataExch."Entry No.");

        CODEUNIT.Run(CODEUNIT::"Exp. User Feedback Gen. Jnl.", DataExch);
    end;

    local procedure CreateGenJnlDataExchLine(DataExchEntryNo: Integer; GenJnlLine: Record "Gen. Journal Line"; LineNo: Integer)
    var
        TempPaymentExportData: Record "Payment Export Data" temporary;
    begin
        PreparePaymentExportDataJnl(TempPaymentExportData, GenJnlLine, DataExchEntryNo, LineNo);
        PaymentExportMgt.CreatePaymentLines(TempPaymentExportData);
    end;

    /// <summary>
    /// Prepares payment export data from general journal line information.
    /// This procedure populates payment export data with vendor, employee, and bank account details for payment processing.
    /// </summary>
    /// <param name="TempPaymentExportData">Temporary payment export data record to populate.</param>
    /// <param name="GenJnlLine">General journal line containing payment information.</param>
    /// <param name="DataExchEntryNo">Data exchange entry number for tracking.</param>
    /// <param name="LineNo">Line number for the payment export data.</param>
    procedure PreparePaymentExportDataJnl(var TempPaymentExportData: Record "Payment Export Data" temporary; GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Employee: Record Employee;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        CompanyInformation: Record "Company Information";
        IsEmployee: Boolean;
    begin
        GeneralLedgerSetup.Get();
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee then begin
            Employee.Get(GenJnlLine."Account No.");
            IsEmployee := true;
        end else begin
            GenJnlLine.TestField("Account Type", GenJnlLine."Account Type"::Vendor);
            Vendor.Get(GenJnlLine."Account No.");
        end;

        BankAccount.Get(GenJnlLine."Bal. Account No.");
        BankAccount.GetBankExportImportSetup(BankExportImportSetup);
        TempPaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

        CompanyInformation.Get();
        TempPaymentExportData.Init();
        TempPaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        TempPaymentExportData."Sender Bank Account Code" := GenJnlLine."Bal. Account No.";
        TempPaymentExportData."Sender Bank Name" := BankAccount.Name;
        if CompanyInformation."Registration No." <> '' then
            TempPaymentExportData."Sender Reg. No." := CopyStr(CompanyInformation."Registration No.", 1, MaxStrLen(TempPaymentExportData."Sender Reg. No."));

        if IsEmployee then begin
            TempPaymentExportData.Amount := GenJnlLine.Amount;
            TempPaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
            FillPaymentExportDataFromEmployee(TempPaymentExportData, Employee);
        end else begin
            if VendorBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account") then begin
                TempPaymentExportData.Amount := GenJnlLine.Amount;
                TempPaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
                TempPaymentExportData."Recipient Bank Acc. No." :=
                  CopyStr(VendorBankAccount.GetBankAccountNo(), 1, MaxStrLen(TempPaymentExportData."Recipient Bank Acc. No."));
                TempPaymentExportData."Recipient Reg. No." := VendorBankAccount."Bank Branch No.";
                TempPaymentExportData."Recipient Acc. No." := VendorBankAccount."Bank Account No.";
                TempPaymentExportData."Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
                TempPaymentExportData."Recipient Bank Name" := CopyStr(VendorBankAccount.Name, 1, 35);
                TempPaymentExportData."Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 35);
                TempPaymentExportData."Recipient Bank City" := CopyStr(VendorBankAccount."Post Code" + VendorBankAccount.City, 1, 35);
                TempPaymentExportData."Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
                TempPaymentExportData."Recipient Bank County" := VendorBankAccount.County;
                TempPaymentExportData."Recipient Bank Post Code" := VendorBankAccount."Post Code";
            end else
                if GenJnlLine."Creditor No." <> '' then begin
                    TempPaymentExportData.Amount := GenJnlLine."Amount (LCY)";
                    TempPaymentExportData."Currency Code" := GeneralLedgerSetup."LCY Code";
                end;

            TempPaymentExportData."Recipient Name" := CopyStr(Vendor.Name, 1, 35);
            TempPaymentExportData."Recipient Address" := CopyStr(Vendor.Address, 1, 35);
            TempPaymentExportData."Recipient City" := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
            TempPaymentExportData."Recipient Email Address" := Vendor."E-Mail";
        end;

        TempPaymentExportData."Transfer Date" := GenJnlLine."Posting Date";
        TempPaymentExportData."Message to Recipient 1" := CopyStr(GenJnlLine."Message to Recipient", 1, 35);
        TempPaymentExportData."Message to Recipient 2" := CopyStr(GenJnlLine."Message to Recipient", 36, 70);
        TempPaymentExportData."Document No." := GenJnlLine."Document No.";
        TempPaymentExportData."Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Short Advice" := GenJnlLine."Applies-to Ext. Doc. No.";
        TempPaymentExportData."Line No." := LineNo;
        TempPaymentExportData."Payment Reference" := GenJnlLine."Payment Reference";
        if PaymentMethod.Get(GenJnlLine."Payment Method Code") then
            TempPaymentExportData."Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
        TempPaymentExportData."Recipient Creditor No." := GenJnlLine."Creditor No.";
        OnBeforeInsertPmtExportDataJnlFromGenJnlLine(TempPaymentExportData, GenJnlLine, GeneralLedgerSetup);
        TempPaymentExportData.Insert(true);
    end;

    /// <summary>
    /// Enables export to server temporary file with specified settings.
    /// This procedure configures payment export to save files on the server instead of client download.
    /// </summary>
    /// <param name="SilentServerMode">Whether to run in silent mode without user interaction.</param>
    /// <param name="ServerFileExtension">File extension for the server temporary file.</param>
    procedure EnableExportToServerTempFile(SilentServerMode: Boolean; ServerFileExtension: Text[3])
    begin
        PaymentExportMgt.EnableExportToServerTempFile(SilentServerMode, ServerFileExtension);
    end;

    /// <summary>
    /// Retrieves the server temporary file name for payment export.
    /// This procedure returns the path of the temporary file created on the server during payment export.
    /// </summary>
    /// <returns>Server temporary file name with full path.</returns>
    procedure GetServerTempFileName(): Text[1024]
    begin
        exit(PaymentExportMgt.GetServerTempFileName());
    end;

    local procedure FillPaymentExportDataFromEmployee(var TempPaymentExportData: Record "Payment Export Data" temporary; Employee: Record Employee)
    var
        EmployeeBankAccNo: Text;
    begin
        EmployeeBankAccNo := Employee.GetBankAccountNo();
        if EmployeeBankAccNo = '' then
            Error(EmployeeMustHaveBankAccountNoErr, Employee.FullName());

        TempPaymentExportData."Recipient Name" := Employee.FullName();
        TempPaymentExportData."Recipient Address" := Employee.Address;
        TempPaymentExportData."Recipient City" := Employee.City;
        TempPaymentExportData."Recipient County" := Employee.County;
        TempPaymentExportData."Recipient Post Code" := Employee."Post Code";
        TempPaymentExportData."Recipient Country/Region Code" := Employee."Country/Region Code";
        TempPaymentExportData."Recipient Email Address" := Employee."E-Mail";
        TempPaymentExportData."Recipient Bank Acc. No." := CopyStr(EmployeeBankAccNo, 1, MaxStrLen(TempPaymentExportData."Recipient Bank Acc. No."));
        TempPaymentExportData."Recipient Reg. No." := Employee."Bank Branch No.";
        TempPaymentExportData."Recipient Acc. No." := Employee."Bank Account No.";
    end;

    /// <summary>
    /// Integration event raised before inserting payment export data from general journal line.
    /// This event allows customization of payment export data before it is processed.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data record being prepared for insert.</param>
    /// <param name="GenJournalLine">Source general journal line containing payment information.</param>
    /// <param name="GeneralLedgerSetup">General ledger setup for currency and company information.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeInsertPmtExportDataJnlFromGenJnlLine(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating general journal data exchange line.
    /// This event allows customization of data exchange line creation for payment export.
    /// </summary>
    /// <param name="DataExch">Data exchange record for the payment export.</param>
    /// <param name="GenJournalLine">General journal line being processed for export.</param>
    /// <param name="LineNo">Line number for the data exchange entry.</param>
    /// <param name="LineAmount">Amount for the specific line being processed.</param>
    /// <param name="TotalAmount">Total amount for the entire payment export operation.</param>
    /// <param name="TransferDate">Date when the payment transfer should occur.</param>
    /// <param name="Handled">Set to true if the data exchange line creation has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeCreateGenJnlDataExchLine(DataExch: Record "Data Exch."; GenJournalLine: Record "Gen. Journal Line"; LineNo: Integer; var LineAmount: Decimal; var TotalAmount: Decimal; var TransferDate: Date; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before payment export operation starts.
    /// This event allows customization of the payment export process before file generation.
    /// </summary>
    /// <param name="BalAccountNo">Balance account number for the payment export.</param>
    /// <param name="DataExchEntryNo">Data exchange entry number for the export operation.</param>
    /// <param name="LineCount">Number of lines being exported in this operation.</param>
    /// <param name="TotalAmount">Total amount for all lines in the payment export.</param>
    /// <param name="TransferDate">Date when the payment transfer should occur.</param>
    /// <param name="Handled">Set to true if the payment export has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforePaymentExport(BalAccountNo: Code[20]; DataExchEntryNo: Integer; LineCount: Integer; TotalAmount: Decimal; TransferDate: Date; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised during general journal line validation for payment export.
    /// This event allows external extensions to perform additional validation on journal lines.
    /// </summary>
    /// <param name="GenJournalLine">General journal line being validated for payment export.</param>
    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnCheckGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

