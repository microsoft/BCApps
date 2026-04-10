namespace System.IO;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 1278 "Exp. User Feedback Gen. Jnl."
{
    Permissions = TableData "Payment Export Data" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentExportData: Record "Payment Export Data";
    begin
        GenJnlLine.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        GenJnlLine.FindFirst();

        CreditTransferRegister.SetRange("From Bank Account No.", GenJnlLine."Bal. Account No.");
        CreditTransferRegister.FindLast();
        SetFileOnCreditTransferRegister(Rec, CreditTransferRegister);
        SetExportFlagOnGenJnlLine(GenJnlLine);

        PaymentExportData.SetRange("Data Exch Entry No.", Rec."Entry No.");
        PaymentExportData.DeleteAll(true);
    end;

    local procedure SetFileOnCreditTransferRegister(DataExch: Record "Data Exch."; var CreditTransferRegister: Record "Credit Transfer Register")
    begin
        CreditTransferRegister.SetStatus(CreditTransferRegister.Status::"File Created");
        CreditTransferRegister.SetFileContent(DataExch);
    end;

    procedure SetExportFlagOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        SetGivenExportFlagOnGenJnlLine(GenJnlLine, true)
    end;

    procedure SetGivenExportFlagOnGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        GenJnlLine2.CopyFilters(GenJnlLine);
        if GenJnlLine2.FindSet() then
            repeat
                SetExportFlagOnAppliedCustVendLedgerEntry(GenJnlLine2, Flag);
                GenJnlLine2.Validate("Check Exported", Flag);
                GenJnlLine2.Validate("Exported to Payment File", Flag);
                OnSetGivenExportFlagOnGenJnlLineOnBeforeGenJnlLineModify(GenJnlLine2, Flag);
                GenJnlLine2.Modify(true);
            until GenJnlLine2.Next() = 0;
    end;

    procedure SetExportFlagOnAppliedCustVendLedgerEntry(var GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    begin
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Vendor:
                SetExportFlagOnAppliedVendorLedgerEntry(GenJnlLine, Flag);
            GenJnlLine."Account Type"::Customer:
                SetExportFlagOnAppliedCustLedgerEntry(GenJnlLine, Flag);
        end;

        OnAfterSetExportFlagOnAppliedCustVendLedgerEntry(GenJnlLine, Flag);
    end;

    local procedure SetExportFlagOnAppliedVendorLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if GenJnlLine.IsApplied() then begin
            VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");

            if GenJnlLine."Applies-to Doc. No." <> '' then begin
                VendLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                VendLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            end;

            if GenJnlLine."Applies-to ID" <> '' then
                VendLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

            if VendLedgerEntry.FindSet() then
                repeat
                    VendLedgerEntry.Validate("Exported to Payment File", Flag);
                    CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgerEntry);
                until VendLedgerEntry.Next() = 0;
        end;

        VendLedgerEntry.Reset();
        VendLedgerEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
        VendLedgerEntry.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
        VendLedgerEntry.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");
        if VendLedgerEntry.FindSet() then
            repeat
                VendLedgerEntry.Validate("Exported to Payment File", Flag);
                CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgerEntry);
            until VendLedgerEntry.Next() = 0;
    end;

    local procedure SetExportFlagOnAppliedCustLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if GenJnlLine.IsApplied() then begin
            CustLedgerEntry.SetRange("Customer No.", GenJnlLine."Account No.");

            if GenJnlLine."Applies-to Doc. No." <> '' then begin
                CustLedgerEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
                CustLedgerEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
            end;

            if GenJnlLine."Applies-to ID" <> '' then
                CustLedgerEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");

            if CustLedgerEntry.FindSet() then
                repeat
                    CustLedgerEntry.Validate("Exported to Payment File", Flag);
                    CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
                until CustLedgerEntry.Next() = 0;
        end;

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", GenJnlLine."Account No.");
        CustLedgerEntry.SetRange("Applies-to Doc. Type", GenJnlLine."Document Type");
        CustLedgerEntry.SetRange("Applies-to Doc. No.", GenJnlLine."Document No.");

        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.Validate("Exported to Payment File", Flag);
                CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);
            until CustLedgerEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetExportFlagOnAppliedCustVendLedgerEntry(var GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetGivenExportFlagOnGenJnlLineOnBeforeGenJnlLineModify(var GenJnlLine: Record "Gen. Journal Line"; Flag: Boolean)
    begin
    end;
}

