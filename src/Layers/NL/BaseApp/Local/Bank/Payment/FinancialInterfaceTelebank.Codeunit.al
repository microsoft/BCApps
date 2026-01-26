// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 11000001 "Financial Interface Telebank"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Employee Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text1000000: Label 'Payment history entries may only be corrected if %1 is "New","Transmitted" or "Request for cancellation".';
        Text1000001: Label 'A Payment in process with status %1 may not be posted';
        TrMode: Record "Transaction Mode";
        BankAcc: Record "Bank Account";
        BankAccPostingGrp: Record "Bank Account Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        NewSeriesCode: Code[20];
        "New Document No.": Code[20];
        NewPostingDate: Date;
        "Detail line": Record "Detail Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        "Journal template": Record "Gen. Journal Template";
        DocumentIsNotOpenMsg: Label 'Document No. %1 of %2 %3 is not open.', Comment = '%1 Document No.; %2 Vendor or Customer or Employee caption; %3 - Source No.';
        DifferentCurrencyQst: Label 'One of the applied document currency codes is different from the bank account''s currency code. This will lead to different currencies in the detailed ledger entries between the document and the applied payment. Document details:\Account Type: %1-%2\Ledger Entry No.: %3\Document Currency: %4\Bank Currency: %5\\Do you want to continue?', Comment = '%1 - account type (vendor\customer), %2 - account number, %3 - ledger entry no., %4 - document currency code, %5 -  bank currency code';

    procedure PostPaymReceived(var GenJnlLine: Record "Gen. Journal Line"; var PaymentHistLine: Record "Payment History Line"; var PaymentHist: Record "Payment History")
    var
        NoSeries: Codeunit "No. Series";
    begin
        PaymentHistLine.TestField(Status, PaymentHistLine.Status::New);
        BankAcc.Get(PaymentHistLine."Our Bank");
        BankAccPostingGrp.Get(BankAcc."Bank Acc. Posting Group");
        BankAccPostingGrp.TestField("Acc.No. Pmt./Rcpt. in Process");
        TrMode.Get(PaymentHistLine."Account Type", PaymentHistLine."Transaction Mode");

        TrMode.TestField("Acc. No. Pmt./Rcpt. in Process");
        TrMode.TestField("Posting No. Series");
        TrMode.TestField("Source Code");

        "New Document No." := '';
        NewPostingDate := Today;
            NewSeriesCode := TrMode."Posting No. Series";
            "New Document No." := NoSeries.GetNextNo(NewSeriesCode);

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine.Validate("Document No.", "New Document No.");
        GenJnlLine.Validate("Posting Date", NewPostingDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", TrMode."Acc. No. Pmt./Rcpt. in Process");
        PaymentHistLine."Amount Paymt. in Process (LCY)" := Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(
              NewPostingDate,
              PaymentHistLine."Currency Code",
              '',
              PaymentHistLine.Amount));
        GenJnlLine.Validate(Amount, PaymentHistLine."Amount Paymt. in Process (LCY)");
        if PaymentHistLine."Description 1" <> '' then
            GenJnlLine.Validate(Description, PaymentHistLine."Description 1");
        GenJnlLine.Validate("Source Code", TrMode."Source Code");

        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PaymentHistLine."Dimension Set ID";
        ProcessGLJL(GenJnlLine);

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine.Validate("Document No.", "New Document No.");
        GenJnlLine.Validate("Posting Date", NewPostingDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", BankAccPostingGrp."Acc.No. Pmt./Rcpt. in Process");
        GenJnlLine.Validate(Amount, -PaymentHistLine."Amount Paymt. in Process (LCY)");
        if PaymentHistLine."Description 1" <> '' then
            GenJnlLine.Validate(Description, PaymentHistLine."Description 1");
        GenJnlLine.Validate("Source Code", TrMode."Source Code");
        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PaymentHist."Dimension Set ID";
        OnPostPaymReceivedOnBeforeProcessGLJL(GenJnlLine, PaymentHistLine);
        ProcessGLJL(GenJnlLine);

        PaymentHistLine."Document No." := "New Document No.";
        PaymentHistLine."Posting Date" := NewPostingDate;
        PaymentHistLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure ReversePaymReceived(var GenJnlLine: Record "Gen. Journal Line"; var PaymentHistLine: Record "Payment History Line"; NewStatus: Option New,Transmitted,"Request for Cancellation",Rejected,Cancelled,Posted; var PaymentHist: Record "Payment History")
    var
        NoSeries: Codeunit "No. Series";
    begin
        if not (PaymentHistLine.Status in
                [PaymentHistLine.Status::New,
                 PaymentHistLine.Status::Transmitted,
                 PaymentHistLine.Status::"Request for Cancellation"])
        then
            Error(Text1000000, PaymentHistLine.FieldCaption(Status));

        BankAcc.Get(PaymentHistLine."Our Bank");
        BankAccPostingGrp.Get(BankAcc."Bank Acc. Posting Group");
        BankAccPostingGrp.TestField("Acc.No. Pmt./Rcpt. in Process");
        TrMode.Get(PaymentHistLine."Account Type", PaymentHistLine."Transaction Mode");

        TrMode.TestField("Acc. No. Pmt./Rcpt. in Process");
        TrMode.TestField("Correction Posting No. Series");
        TrMode.TestField("Correction Source Code");

        "New Document No." := '';
        NewPostingDate := Today;
            NewSeriesCode := TrMode."Correction Posting No. Series";
            "New Document No." := NoSeries.GetNextNo(NewSeriesCode);

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine.Validate("Document No.", "New Document No.");
        GenJnlLine.Validate("Posting Date", NewPostingDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", TrMode."Acc. No. Pmt./Rcpt. in Process");
        GenJnlLine.Validate(Correction, true);
        GenJnlLine.Validate(Amount, -PaymentHistLine."Amount Paymt. in Process (LCY)");
        if PaymentHistLine."Description 1" <> '' then
            GenJnlLine.Validate(Description, PaymentHistLine."Description 1");
        GenJnlLine.Validate("Source Code", TrMode."Correction Source Code");
        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PaymentHistLine."Dimension Set ID";
        ProcessGLJL(GenJnlLine);

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine.Validate("Document No.", "New Document No.");
        GenJnlLine.Validate("Posting Date", NewPostingDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", BankAccPostingGrp."Acc.No. Pmt./Rcpt. in Process");
        GenJnlLine.Validate(Correction, true);
        GenJnlLine.Validate(Amount, PaymentHistLine."Amount Paymt. in Process (LCY)");
        if PaymentHistLine."Description 1" <> '' then
            GenJnlLine.Validate(Description, PaymentHistLine."Description 1");
        GenJnlLine.Validate("Source Code", TrMode."Correction Source Code");
        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PaymentHist."Dimension Set ID";
        OnReversePaymReceivedOnBeforeProcessGLJL(GenJnlLine, PaymentHistLine);
        ProcessGLJL(GenJnlLine);

        PaymentHistLine.Status := NewStatus;
        PaymentHistLine."Document No." := "New Document No.";
        PaymentHistLine."Posting Date" := NewPostingDate;
        PaymentHistLine.Modify();

        "Detail line".SetCurrentKey("Our Bank", Status, "Connect Batches");
        "Detail line".SetRange("Our Bank", PaymentHistLine."Our Bank");
        "Detail line".SetRange(Status, "Detail line".Status::"In process");
        "Detail line".SetRange("Connect Batches", PaymentHistLine."Run No.");
        "Detail line".SetRange("Connect Lines", PaymentHistLine."Line No.");
        "Detail line".ModifyAll(Status, "Detail line".Status::Correction);
    end;

    procedure ProcessPaymReceived(var GenJnlLine: Record "Gen. Journal Line"; var PaymentHistLine: Record "Payment History Line"; CBGStatementline: Record "CBG Statement Line")
    var
        CBGStatement: Record "CBG Statement";
        PaymentHist: Record "Payment History";
        "Use Document No.": Code[20];
        UsePostingDate: Date;
        UseDocumentDate: Date;
    begin
        if not (PaymentHistLine.Status in
                [PaymentHistLine.Status::Transmitted,
                 PaymentHistLine.Status::"Request for Cancellation"])
        then
            Error(Text1000001, PaymentHistLine.Status);

        BankAcc.Get(PaymentHistLine."Our Bank");
        BankAccPostingGrp.Get(BankAcc."Bank Acc. Posting Group");
        BankAccPostingGrp.TestField("Acc.No. Pmt./Rcpt. in Process");

        TrMode.Get(PaymentHistLine."Account Type", PaymentHistLine."Transaction Mode");
        TrMode.TestField("Acc. No. Pmt./Rcpt. in Process");

        CBGStatement.Get(CBGStatementline."Journal Template Name", CBGStatementline."No.");
        case CBGStatement.Type of
            CBGStatement.Type::Cash:
                begin
                    "Use Document No." := CBGStatementline."Document No.";
                    UsePostingDate := CBGStatementline.Date;
                    UseDocumentDate := CBGStatementline.Date;
                end;
            CBGStatement.Type::"Bank/Giro":
                begin
                    "Use Document No." := CBGStatement."Document No.";
                    UsePostingDate := CBGStatementline.Date;
                    UseDocumentDate := CBGStatement.Date;
                end;
        end;
        "Journal template".Get(CBGStatement."Journal Template Name");

        // //////////////////////////////
        // Correct payment in pipeline

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine."Journal Template Name" := CBGStatement."Journal Template Name";
        GenJnlLine."Source Code" := "Journal template"."Source Code";
        GenJnlLine."Reason Code" := "Journal template"."Reason Code";
        GenJnlLine.Validate("Document No.", "Use Document No.");
        GenJnlLine.Validate("Posting Date", UsePostingDate);
        GenJnlLine.Validate("Document Date", UseDocumentDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", TrMode."Acc. No. Pmt./Rcpt. in Process");
        GenJnlLine.Validate(Amount, -PaymentHistLine."Amount Paymt. in Process (LCY)");
        GenJnlLine.Description := CBGStatementline.Description;
        GenJnlLine."Shortcut Dimension 1 Code" := CBGStatementline."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CBGStatementline."Shortcut Dimension 2 Code";
        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PaymentHistLine."Dimension Set ID";
        OnProcessPaymReceivedOnBeforeProcessGLJLTrMode(GenJnlLine, CBGStatementline);
        ProcessGLJL(GenJnlLine);

        "Initialize GJLine"(GenJnlLine);
        GenJnlLine.Validate("System-Created Entry", true);
        GenJnlLine."Journal Template Name" := CBGStatement."Journal Template Name";
        GenJnlLine."Source Code" := "Journal template"."Source Code";
        GenJnlLine."Reason Code" := "Journal template"."Reason Code";
        GenJnlLine.Validate("Document No.", "Use Document No.");
        GenJnlLine.Validate("Posting Date", UsePostingDate);
        GenJnlLine.Validate("Document Date", UseDocumentDate);
        GenJnlLine.Validate("Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", BankAccPostingGrp."Acc.No. Pmt./Rcpt. in Process");
        GenJnlLine.Validate(Amount, PaymentHistLine."Amount Paymt. in Process (LCY)");
        GenJnlLine.Description := CBGStatementline.Description;
        GenJnlLine."Shortcut Dimension 1 Code" := CBGStatementline."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CBGStatementline."Shortcut Dimension 2 Code";
        GenJnlLine."Shortcut Dimension 1 Code" := PaymentHistLine."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PaymentHistLine."Global Dimension 2 Code";
        if PaymentHist.Get(PaymentHistLine."Our Bank", PaymentHistLine."Run No.") then
            GenJnlLine."Dimension Set ID" := PaymentHist."Dimension Set ID";
        OnProcessPaymReceivedOnBeforeProcessGLJL(GenJnlLine, PaymentHistLine);
        ProcessGLJL(GenJnlLine);
        OnProcessPaymReceivedOnAfterProcessGLJL(GenJnlLine, PaymentHistLine, CBGStatementline, UsePostingDate, UseDocumentDate, "Use Document No.");

        PaymentHistLine.Status := PaymentHistLine.Status::Posted;
        PaymentHistLine."Document No." := "Use Document No.";
        PaymentHistLine."Posting Date" := UsePostingDate;
        PaymentHistLine.Modify();

        SetApplyCVLedgerEntries(PaymentHistLine, CBGStatementline."Applies-to ID", true, false);
    end;

    procedure "Initialize GJLine"(var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeInitializeGJLine(GenJnlLine, "Journal template");
        if GenJnlLine.Find('+') then
            GenJnlLine."Line No." := GenJnlLine."Line No." + 1
        else
            GenJnlLine."Line No." := 1;
        GenJnlLine.Init();
    end;

    procedure ProcessGLJL(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessGLJL(GenJnlPostLine, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Insert();
    end;

    procedure PostFDBR(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine.FindSet() then
            repeat
                GenJnlPostLine.RunWithCheck(GenJournalLine);
            until GenJournalLine.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure SetApplyCVLedgerEntries(PaymentHistoryLine: Record "Payment History Line"; AppliesToID: Code[50]; Post: Boolean; Check: Boolean)
    var
        DetailLine: Record "Detail Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        OnBeforeSetApplyCVLedgerEntries(PaymentHistoryLine, AppliesToID, Post, Check);

        // Use detail lines to apply
        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches");
        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");

        if DetailLine.FindSet() then
            repeat
                case DetailLine."Account Type" of
                    DetailLine."Account Type"::Customer:
                        begin
                            CustLedgerEntry.Get(DetailLine."Serial No. (Entry)");
                            if Check then begin
                                if not CustLedgerEntry.Open then
                                    TempErrorMessage.LogMessage(
                                      CustLedgerEntry, CustLedgerEntry.FieldNo(Open), TempErrorMessage."Message Type"::Warning,
                                      StrSubstNo(
                                        DocumentIsNotOpenMsg, CustLedgerEntry."Document No.",
                                        CustLedgerEntry.FieldCaption("Customer No."), CustLedgerEntry."Customer No."));
                            end else
                                if CustLedgerEntry.Open or Post then begin
                                    CustLedgerEntry."Applies-to ID" := AppliesToID;
                                    if CustLedgerEntry."Amount to Apply" = 0 then begin
                                        CustLedgerEntry.SetRange("Connect Batches Filter", DetailLine."Connect Batches");
                                        CustLedgerEntry.SetRange("Connect Lines Filter", DetailLine."Connect Lines");
                                        CustLedgerEntry.SetRange("Our Bank Filter", DetailLine."Our Bank");
                                        CustLedgerEntry.CalcFields("Payments in Process");
                                        CustLedgerEntry.Validate("Amount to Apply", -CustLedgerEntry."Payments in Process");
                                    end;
                                    OnSetApplyCVLedgerEntriesOnBeforeCustLedgerEntryModify(CustLedgerEntry, DetailLine);
                                    CustLedgerEntry.Modify();
                                end;
                        end;
                    DetailLine."Account Type"::Vendor:
                        begin
                            VendorLedgerEntry.Get(DetailLine."Serial No. (Entry)");
                            if Check then begin
                                if not VendorLedgerEntry.Open then
                                    TempErrorMessage.LogMessage(
                                      VendorLedgerEntry, VendorLedgerEntry.FieldNo(Open), TempErrorMessage."Message Type"::Warning,
                                      StrSubstNo(
                                        DocumentIsNotOpenMsg, VendorLedgerEntry."Document No.",
                                        VendorLedgerEntry.FieldCaption("Vendor No."), VendorLedgerEntry."Vendor No."));
                            end else
                                if VendorLedgerEntry.Open or Post then begin
                                    VendorLedgerEntry."Applies-to ID" := AppliesToID;
                                    if VendorLedgerEntry."Amount to Apply" = 0 then begin
                                        VendorLedgerEntry.SetRange("Connect Batches Filter", DetailLine."Connect Batches");
                                        VendorLedgerEntry.SetRange("Connect Lines Filter", DetailLine."Connect Lines");
                                        VendorLedgerEntry.SetRange("Our Bank Filter", DetailLine."Our Bank");
                                        VendorLedgerEntry.CalcFields("Payments in Process");
                                        VendorLedgerEntry.Validate("Amount to Apply", -VendorLedgerEntry."Payments in Process")
                                    end;
                                    OnSetApplyCVLedgerEntriesOnBeforeVendorLedgerEntryModify(VendorLedgerEntry, DetailLine);
                                    VendorLedgerEntry.Modify();
                                end;
                        end;
                    DetailLine."Account Type"::Employee:
                        begin
                            EmployeeLedgerEntry.Get(DetailLine."Serial No. (Entry)");
                            if Check then begin
                                if not EmployeeLedgerEntry.Open then
                                    TempErrorMessage.LogMessage(
                                      EmployeeLedgerEntry, EmployeeLedgerEntry.FieldNo(Open), TempErrorMessage."Message Type"::Warning,
                                      StrSubstNo(
                                        DocumentIsNotOpenMsg, EmployeeLedgerEntry."Document No.",
                                        EmployeeLedgerEntry.FieldCaption("Employee No."), EmployeeLedgerEntry."Employee No."));
                            end else
                                if EmployeeLedgerEntry.Open or Post then begin
                                    EmployeeLedgerEntry."Applies-to ID" := AppliesToID;
                                    if EmployeeLedgerEntry."Amount to Apply" = 0 then begin
                                        EmployeeLedgerEntry.SetRange("Connect Batches Filter", DetailLine."Connect Batches");
                                        EmployeeLedgerEntry.SetRange("Connect Lines Filter", DetailLine."Connect Lines");
                                        EmployeeLedgerEntry.SetRange("Our Bank Filter", DetailLine."Our Bank");
                                        EmployeeLedgerEntry.CalcFields("Payments in Process");
                                        if EmployeeLedgerEntry.Open or Post then
                                            EmployeeLedgerEntry.Validate("Amount to Apply", -EmployeeLedgerEntry."Payments in Process");
                                    end;
                                    EmployeeLedgerEntry.Modify();
                                end;
                        end;
                end;
            until DetailLine.Next() = 0;

        // Modify the detail line to pass checks of codeunit 12
        if Post then
            DetailLine.ModifyAll(Status, DetailLine.Status::Posted);
    end;

    [Scope('OnPrem')]
    procedure CheckPaymReceived(CBGStatement: Record "CBG Statement")
    var
        CBGStatementLine: Record "CBG Statement Line";
        PaymentHistLine: Record "Payment History Line";
        ErrorMessages: Page "Error Messages";
    begin
        TempErrorMessage.DeleteAll();
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        PaymentHistLine.SetRange("Our Bank", CBGStatement."Account No.");
        if CBGStatementLine.FindSet() then
            repeat
                PaymentHistLine.SetRange(Identification, CBGStatementLine.Identification);
                if PaymentHistLine.FindFirst() then
                    SetApplyCVLedgerEntries(PaymentHistLine, '', false, true);
            until CBGStatementLine.Next() = 0;

        if not TempErrorMessage.IsEmpty() then begin
            ErrorMessages.SetRecords(TempErrorMessage);
            ErrorMessages.Run();
            Error('');
        end;
    end;

    procedure CheckCBGStatementCurrencyBeforePost(CBGStatement: Record "CBG Statement")
    var
        CBGStatementLine: Record "CBG Statement Line";
        PaymentHistoryLine: Record "Payment History Line";
        DetailLine: Record "Detail Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if CBGStatement."Account Type" = CBGStatement."Account Type"::"G/L Account" then
            exit;

        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        PaymentHistoryLine.SetRange("Our Bank", CBGStatement."Account No.");
        if CBGStatementLine.FindSet() then
            repeat
                PaymentHistoryLine.SetRange(Identification, CBGStatementLine.Identification);
                if PaymentHistoryLine.FindSet() then
                    repeat
                        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
                        DetailLine.SetRange(Status, DetailLine.Status::"In process");
                        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
                        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
                        DetailLine.SetFilter("Serial No. (Entry)", '<>%1', 0);
                        DetailLine.SetFilter("Currency Code (Entry)", '<>%1', CBGStatement.Currency);
                        if DetailLine.FindFirst() then begin
                            if ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(
                                    DifferentCurrencyQst,
                                    Format(PaymentHistoryLine."Account Type"), PaymentHistoryLine."Account No.", DetailLine."Serial No. (Entry)",
                                    GetCurrencyCode(PaymentHistoryLine."Foreign Currency"), GetCurrencyCode(CBGStatement.Currency)),
                                false)
                            then
                                exit;
                            Error('');
                        end;
                    until PaymentHistoryLine.Next() = 0;
            until CBGStatementLine.Next() = 0;
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode = '' then begin
            GLSetup.Get();
            exit(GLSetup."LCY Code");
        end;

        exit(CurrencyCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplyCVLedgerEntries(var PaymentHistoryLine: Record "Payment History Line"; var AppliesToID: Code[50]; var Post: Boolean; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeGJLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplate: Record "Gen. Journal Template")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessGLJL(var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPaymReceivedOnBeforeProcessGLJL(var GenJournalLine: Record "Gen. Journal Line"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReversePaymReceivedOnBeforeProcessGLJL(var GenJournalLine: Record "Gen. Journal Line"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnProcessPaymReceivedOnAfterProcessGLJL(var GenJournalLine: Record "Gen. Journal Line"; PaymentHistoryLine: Record "Payment History Line"; CBGStatementline: Record "CBG Statement Line"; UsePostingDate: Date; UseDocumentDate: Date; UseDocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPaymReceivedOnBeforeProcessGLJLTrMode(var GenJnlLine: Record "Gen. Journal Line"; CBGStatementline: Record "CBG Statement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPaymReceivedOnBeforeProcessGLJL(var GenJournalLine: Record "Gen. Journal Line"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyCVLedgerEntriesOnBeforeCustLedgerEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; DetailLine: Record "Detail Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplyCVLedgerEntriesOnBeforeVendorLedgerEntryModify(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailLine: Record "Detail Line")
    begin
    end;
}
