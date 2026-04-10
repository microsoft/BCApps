namespace System.IO;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;

codeunit 1273 "Exp. Pre-Mapping Gen. Jnl."
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Window: Dialog;
        LineNo: Integer;
    begin
        GenJnlLine.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        GenJnlLine.FindSet();

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            PreparePaymentExportDataJnl(GenJnlLine, GenJnlLine."Data Exch. Entry No.", LineNo);
        until GenJnlLine.Next() = 0;

        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Pre-processing line no. #1######.', Comment = 'Line no.';
#pragma warning restore AA0470
        EmployeeMustHaveBankAccountNoErr: Label 'You must specify either Bank Account No. or IBAN for employee %1.', Comment = '%1 - Employee name';

    local procedure PreparePaymentExportDataJnl(GenJnlLine: Record "Gen. Journal Line"; DataExchEntryNo: Integer; LineNo: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentExportData: Record "Payment Export Data";
        Employee: Record Employee;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
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
        PaymentExportData.SetPreserveNonLatinCharacters(BankExportImportSetup."Preserve Non-Latin Characters");

        PaymentExportData.Init();
        PaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        PaymentExportData."Sender Bank Account Code" := GenJnlLine."Bal. Account No.";
        BankAccount.Get(PaymentExportData."Sender Bank Account Code");
        PaymentExportData."Sender Bank Account No." := CopyStr(BankAccount.GetBankAccountNo(), 1, MaxStrLen(PaymentExportData."Sender Bank Account No."));
        PaymentExportData."Sender Reg. No." := CopyStr(BankAccount.GetBankAccountNo(), 1, MaxStrLen(PaymentExportData."Sender Reg. No."));

        if IsEmployee then begin
            PaymentExportData."Recipient Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(PaymentExportData."Recipient Name"));
            PaymentExportData."Recipient Address" := Employee.Address;
            PaymentExportData."Recipient City" := CopyStr(Employee.City, 1, 35);
            PaymentExportData."Recipient County" := Employee.County;
            PaymentExportData."Recipient Post Code" := Employee."Post Code";
            PaymentExportData."Recipient Country/Region Code" := Employee."Country/Region Code";
            PaymentExportData."Recipient Email Address" := Employee."E-Mail";
            if Employee.GetBankAccountNo() = '' then
                Error(EmployeeMustHaveBankAccountNoErr, Employee.FullName());
            PaymentExportData."Recipient Bank Acc. No." := CopyStr(Employee.GetBankAccountNo(), 1, MaxStrLen(PaymentExportData."Recipient Bank Acc. No."));
            PaymentExportData."Recipient Reg. No." := Employee."Bank Branch No.";
            PaymentExportData."Recipient Acc. No." := Employee."Bank Account No.";
            PaymentExportData.Amount := GenJnlLine.Amount;
            PaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
        end else begin
            if VendorBankAccount.Get(GenJnlLine."Account No.", GenJnlLine."Recipient Bank Account") then begin
                PaymentExportData.Amount := GenJnlLine.Amount;
                PaymentExportData."Currency Code" := GeneralLedgerSetup.GetCurrencyCode(GenJnlLine."Currency Code");
                PaymentExportData."Recipient Bank Acc. No." :=
                  CopyStr(VendorBankAccount.GetBankAccountNo(), 1, MaxStrLen(PaymentExportData."Recipient Bank Acc. No."));
                PaymentExportData."Recipient Reg. No." := VendorBankAccount."Bank Branch No.";
                PaymentExportData."Recipient Acc. No." := VendorBankAccount."Bank Account No.";
                PaymentExportData."Recipient Bank Country/Region" := VendorBankAccount."Country/Region Code";
                PaymentExportData."Recipient Bank Name" := CopyStr(VendorBankAccount.Name, 1, 35);
                PaymentExportData."Recipient Bank Address" := CopyStr(VendorBankAccount.Address, 1, 35);
                PaymentExportData."Recipient Bank City" := CopyStr(VendorBankAccount."Post Code" + VendorBankAccount.City, 1, 35);
                PaymentExportData."Recipient Bank BIC" := VendorBankAccount."SWIFT Code";
            end else
                if GenJnlLine."Creditor No." <> '' then begin
                    PaymentExportData.Amount := GenJnlLine."Amount (LCY)";
                    PaymentExportData."Currency Code" := GeneralLedgerSetup."LCY Code";
                end;

            PaymentExportData."Recipient Name" := CopyStr(Vendor.Name, 1, 35);
            PaymentExportData."Recipient Address" := CopyStr(Vendor.Address, 1, 35);
            PaymentExportData."Recipient City" := CopyStr(Vendor."Post Code" + ' ' + Vendor.City, 1, 35);
        end;

        PaymentExportData."Transfer Date" := GenJnlLine."Posting Date";
        PaymentExportData."Message to Recipient 1" := CopyStr(GenJnlLine."Message to Recipient", 1, 35);
        PaymentExportData."Message to Recipient 2" := CopyStr(GenJnlLine."Message to Recipient", 36, 70);
        PaymentExportData."Document No." := GenJnlLine."Document No.";
        PaymentExportData."Applies-to Ext. Doc. No." := GenJnlLine."Applies-to Ext. Doc. No.";
        PaymentExportData."Short Advice" := GenJnlLine."Applies-to Ext. Doc. No.";
        PaymentExportData."Line No." := LineNo;
        PaymentExportData."Payment Reference" := GenJnlLine."Payment Reference";
        if PaymentMethod.Get(GenJnlLine."Payment Method Code") then
            PaymentExportData."Data Exch. Line Def Code" := PaymentMethod."Pmt. Export Line Definition";
        PaymentExportData."Recipient Creditor No." := GenJnlLine."Creditor No.";

        OnBeforeInsertPaymentExoprtData(PaymentExportData, GenJnlLine, GeneralLedgerSetup);

        PaymentExportData.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPaymentExoprtData(var PaymentExportData: Record "Payment Export Data"; GenJournalLine: Record "Gen. Journal Line"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;
}

