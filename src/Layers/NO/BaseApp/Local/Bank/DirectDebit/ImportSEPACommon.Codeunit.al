// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

codeunit 10635 "Import SEPA Common"
{

    trigger OnRun()
    begin
    end;

    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        RemittanceTools: Codeunit "Remittance Tools";
        MustBeSpecifiedErr: Label 'must be specified';
        CannotBeWhenSettlingErr: Label 'cannot be %1 when settling', Comment = '%1 is the value of the remittance status';
        ReceiptReturnNeededErr: Label 'cannot be %1. Receipt return must be imported before settling', Comment = '%1 is the value of the remittance status';
        RemittanceVendorsTxt: Label 'Remittance: Vendors %1', Comment = '%1 is the value of the date';
        RemittanceDateTxt: Label 'Remittance: Vendors %1', Comment = '%1 is the value of the date';
        DateChangedTxt: Label 'Due date changed from %1 to %2.', Comment = '%1 is the value of the initial due date. %2 is the value of the new due date.';
        XpathNotFoundErr: Label '%1 not found in the XML file.', Comment = '%1 is the Xpath that was not found in the XML file.';
        TransactionRejectedMsg: Label 'The transaction was rejected.';
        RemittanceRoundOffDivergenceTxt: Label 'Remittance: Round off/Divergence';
        TooLargeRoundOffDivergenceErr: Label 'Round off/Divergence is too large.\Max. round off/divergence is %1 (LCY).', Comment = '%1 is the maximum round off divergence.';
        ConfirmImportQst: Label 'Return data for the file "%1" are imported correctly:\Approved: %2.\Rejected: %3.\Settled: %4.\\%4 settled payments are transferred to payment journal.', Comment = 'Parameter 1 - file name, 2, 3, 4 - integer numbers.';
        ConfirmImportExchRateQst: Label 'Return data in the file to be imported has a different currency exchange rate than one in a waiting journal. This may lead to gain/loss detailed ledger entries during application.\\Do you want to continue?';
        ImportCancelledErr: Label 'Import is cancelled.';
        TransactionStatusOption: Option Approved,Settled,Rejected,Pending;

    [Scope('OnPrem')]
    procedure FindFirstNode(RootNode: DotNet XmlNode; XmlNamespaceManager: DotNet XmlNamespaceManager; var XmlNode: DotNet XmlNode; XPathToSearch: Text; ThrowError: Boolean): Boolean
    var
        XmlNodeList: DotNet XmlNodeList;
    begin
        if not XMLDOMManagement.FindNodesWithNamespaceManager(RootNode, XPathToSearch, XmlNamespaceManager, XmlNodeList) then begin
            if ThrowError then
                Error(XpathNotFoundErr, XPathToSearch);
            exit(false);
        end;

        XmlNode := XmlNodeList.Item(0);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FindFirstNodeTxt(RootNode: DotNet XmlNode; XmlNamespaceManager: DotNet XmlNamespaceManager; XPathToSearch: Text[250]; ThrowError: Boolean): Text
    var
        XmlNode: DotNet XmlNode;
    begin
        if not FindFirstNode(RootNode, XmlNamespaceManager, XmlNode, XPathToSearch, ThrowError) then
            exit('');
        exit(XmlNode.InnerText);
    end;

    [Scope('OnPrem')]
    procedure FindFirstNodeDecimal(var DecimalValue: Decimal; RootNode: DotNet XmlNode; XmlNamespaceManager: DotNet XmlNamespaceManager; XPathToSearch: Text[250]; ThrowError: Boolean): Boolean
    begin
        DecimalValue := 0;
        exit(Evaluate(DecimalValue, FindFirstNodeTxt(RootNode, XmlNamespaceManager, XPathToSearch, ThrowError), 9));
    end;

    [Scope('OnPrem')]
    procedure UpdateWaitingJournal(var WaitingJournal: Record "Waiting Journal"; MappedTransactionStatus: Option Approved,Settled,Rejected,Pending; TransactionCauseCode: Text[20]; TransactionCauseInfo: Text[150]; RemittancePaymentOrder: Record "Remittance Payment Order"; ValueDate: Date; CurrentGenJournalLine: Record "Gen. Journal Line"; var AccountCurrency: Code[10]; var NumberApproved: Integer; var NumberSettled: Integer; var NumberRejected: Integer; var TransDocumentNo: Code[20]; var BalanceEntryAmountLCY: Decimal; var MoreReturnJournals: Boolean; var First: Boolean; var LatestDate: Date; var LatestVend: Code[20]; var LatestRemittanceAccount: Record "Remittance Account"; var LatestRemittanceAgreement: Record "Remittance Agreement"; var LatestCurrencyCode: Code[10]; var CreateNewDocumentNo: Boolean; IsPain002Format: Boolean; var BalanceEntryAmount: Decimal)
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        repeat
            case MappedTransactionStatus of
                TransactionStatusOption::Approved:
                    begin
                        NumberApproved += 1;
                        CheckBeforeApprove(WaitingJournal);
                        WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Approved);
                        WaitingJournal."Payment Order ID - Approved" := RemittancePaymentOrder.ID;
                    end;
                TransactionStatusOption::Settled:
                    begin
                        RemittanceAccount.Get(WaitingJournal."Remittance Account Code");
                        RemittanceAgreement.Get(RemittanceAccount."Remittance Agreement Code");
                        AccountCurrency := RemittanceAccount."Currency Code";

                        // Check whether a balance entry should be created now:
                        CreateBalanceEntry(
                          ValueDate, AccountCurrency, WaitingJournal."Account No.", RemittanceAccount, RemittanceAgreement, LatestDate,
                          LatestVend, LatestRemittanceAccount, LatestRemittanceAgreement, LatestCurrencyCode, CurrentGenJournalLine,
                          TransDocumentNo, MoreReturnJournals,
                          First,
                          BalanceEntryAmountLCY, CreateNewDocumentNo, BalanceEntryAmount);

                        NumberSettled += 1;

                        FindDocumentNo(ValueDate, RemittanceAccount, CreateNewDocumentNo, TransDocumentNo);

                        CheckBeforeSettle(WaitingJournal, RemittanceAgreement, IsPain002Format);

                        // Prepare and insert the journal:
                        GenJournalLine.Init();
                        GenJournalLine.TransferFields(WaitingJournal);
                        InitJournalLine(GenJournalLine, RemittanceAccount, CurrentGenJournalLine, MoreReturnJournals);

                        if GenJournalLine."Posting Date" <> ValueDate then
                            RemittanceTools.InsertWarning(
                              GenJournalLine, StrSubstNo(DateChangedTxt,
                                GenJournalLine."Posting Date", ValueDate));

                        GenJournalLine.Validate("Posting Date", ValueDate);
                        GenJournalLine.Validate("Document No.", TransDocumentNo);
                        // GenJournalLine.VALIDATE("Currency Factor",-); // we do not have the real exchange rate in the file from the bank, do not update the currency factor

                        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
                        GenJournalLine.Validate("Bal. Account No.", '');
                        GenJournalLine.Validate("Currency Code", WaitingJournal."Currency Code");
                        GenJournalLine.Validate("Currency Factor", WaitingJournal."Currency Factor");
                        GenJournalLine.Insert(true);

                        WaitingJournal.RecreateLineDimensions(GenJournalLine);

                        // Update balance entry amount
                        BalanceEntryAmountLCY := BalanceEntryAmountLCY + GenJournalLine."Amount (LCY)";
                        BalanceEntryAmount += GenJournalLine.Amount;

                        WaitingJournal.Validate("Journal, Settlement Template", GenJournalLine."Journal Template Name");
                        WaitingJournal.Validate("Journal - Settlement", GenJournalLine."Journal Batch Name");
                        WaitingJournal.Validate("Payment Order ID - Settled", RemittancePaymentOrder.ID);
                        WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Settled);
                    end;
                TransactionStatusOption::Rejected:
                    begin
                        NumberRejected += 1;
                        WaitingJournal."Payment Order ID - Rejected" := RemittancePaymentOrder.ID;
                        SaveErrorInfo(WaitingJournal, TransactionCauseCode, TransactionCauseInfo, RemittancePaymentOrder);
                        WaitingJournal.Validate("Remittance Status", WaitingJournal."Remittance Status"::Rejected);
                    end;
                TransactionStatusOption::Pending:
                    ; // do nothing
            end;
            WaitingJournal.Modify();
        until WaitingJournal.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreatePaymOrder(Note: Text[50]; var RemittancePaymentOrder: Record "Remittance Payment Order")
    var
        NextPaymOrderId: Integer;
    begin
        // Create import PaymOrder.
        // Select ID. Find the next one:
        RemittancePaymentOrder.LockTable();
        if RemittancePaymentOrder.FindLast() then
            NextPaymOrderId := RemittancePaymentOrder.ID + 1
        else
            NextPaymOrderId := 1;

        // Insert new PaymOrder. Remaining data are set later:
        RemittancePaymentOrder.Init();
        RemittancePaymentOrder.Validate(ID, NextPaymOrderId);
        RemittancePaymentOrder.Validate(Date, Today);
        RemittancePaymentOrder.Validate(Time, Time);
        RemittancePaymentOrder.Validate(Comment, Note);
        RemittancePaymentOrder.Validate(Type, RemittancePaymentOrder.Type::Return);
        RemittancePaymentOrder.Insert(true);
    end;

    local procedure SaveErrorInfo(WaitingJournal: Record "Waiting Journal"; CauseCode: Text[20]; AdditionalInfo: Text[150]; RemittancePaymentOrder: Record "Remittance Payment Order")
    var
        ReturnError: Record "Return Error";
        MessageText: Text;
    begin
        ReturnError.Validate("Transaction Name", 'SEPA');
        ReturnError.Validate(Date, Today);
        ReturnError.Validate(Time, Time);
        ReturnError.Validate("Waiting Journal Reference", WaitingJournal.Reference);
        ReturnError.Validate("Payment Order ID", RemittancePaymentOrder.ID);
        ReturnError.Validate("Serial Number", 0); // Finally specified in 'OnInsert'
        AddToMessageText(MessageText, 'Code', CauseCode);
        if AdditionalInfo <> '' then
            AddToMessageText(MessageText, 'Message', StrSubstNo('"%1"', AdditionalInfo));
        if MessageText = '' then
            AddToMessageText(MessageText, '', TransactionRejectedMsg)
        else
            MessageText += '.';
        ReturnError.Validate("Message Text", CopyStr(MessageText, 1, MaxStrLen(ReturnError."Message Text")));
        ReturnError.Insert(true);
    end;

    local procedure AddToMessageText(var MessageText: Text; Prefix: Text; TextToAdd: Text)
    begin
        if TextToAdd = '' then
            exit;
        if MessageText <> '' then
            MessageText += ' ';
        if Prefix = '' then
            MessageText += TextToAdd
        else
            MessageText += StrSubstNo('%1: %2', Prefix, TextToAdd);
    end;

    [Scope('OnPrem')]
    procedure InitJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RemittanceAccount: Record "Remittance Account"; CurrentGenJournalLine: Record "Gen. Journal Line"; var MoreReturnJournals: Boolean)
    var
        RegisterGenJournalBatch: Record "Gen. Journal Batch";
        CheckGenJournalLine: Record "Gen. Journal Line";
        JournalNextLineNo: Integer;
    begin
        // Initialize JournalLine
        if RemittanceAccount."Return Journal Name" = '' then begin
            // Def journal name is used (the journal user reads from)
            // Make sure the user imports in a journal.
            // Read from main menu if the journal is specified for the account:
            if CurrentGenJournalLine."Journal Batch Name" = '' then
                RemittanceAccount.FieldError("Return Journal Name", MustBeSpecifiedErr);
            GenJournalLine.Validate("Journal Template Name", CurrentGenJournalLine."Journal Template Name");
            GenJournalLine.Validate("Journal Batch Name", CurrentGenJournalLine."Journal Batch Name");
        end else begin
            // The journal specified for the account is used:
            RemittanceAccount.TestField("Return Journal Name");
            GenJournalLine.Validate("Journal Template Name", RemittanceAccount."Return Journal Template Name");
            GenJournalLine.Validate("Journal Batch Name", RemittanceAccount."Return Journal Name");
            MoreReturnJournals := true; // If TRUE, settlement status is last shown.
        end;

        // Find the next line no. for the journal in use
        CheckGenJournalLine := GenJournalLine;
        CheckGenJournalLine.SetRange("Journal Template Name", CheckGenJournalLine."Journal Template Name");
        CheckGenJournalLine.SetRange("Journal Batch Name", CheckGenJournalLine."Journal Batch Name");
        if CheckGenJournalLine.FindLast() then
            JournalNextLineNo := CheckGenJournalLine."Line No." + 10000
        else
            JournalNextLineNo := 10000;

        GenJournalLine.Validate("Line No.", JournalNextLineNo);
        RegisterGenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalLine."Posting No. Series" := RegisterGenJournalBatch."Posting No. Series";
    end;

    local procedure CheckBeforeSettle(WaitingJournal: Record "Waiting Journal"; RemittanceAgreement: Record "Remittance Agreement"; IsPain002Format: Boolean)
    begin
        // If the status is not sent or approved, it will not be changed to settled.
        if (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Sent) and
           (WaitingJournal."Remittance Status" <> WaitingJournal."Remittance Status"::Approved)
        then
            WaitingJournal.FieldError(
              "Remittance Status", StrSubstNo(CannotBeWhenSettlingErr, WaitingJournal."Remittance Status"));
        // If "Receipt return required"=Yes, the status has to be Approved first, to be changed to Settled.
        if RemittanceAgreement."Receipt Return Required" and (IsPain002Format and
                                                              (WaitingJournal."Remittance Status" <>
                                                               WaitingJournal."Remittance Status"::Approved))
        then begin
            if WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Sent then
                WaitingJournal.FieldError(
                  "Remittance Status", StrSubstNo(ReceiptReturnNeededErr,
                    WaitingJournal."Remittance Status"));

            WaitingJournal.FieldError(
              "Remittance Status", StrSubstNo(CannotBeWhenSettlingErr, WaitingJournal."Remittance Status"));
        end;
    end;

    local procedure CheckBeforeApprove(WaitingJournal: Record "Waiting Journal")
    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemittanceAccount: Record "Remittance Account";
    begin
        RemittanceAccount.Get(WaitingJournal."Remittance Account Code");
        RemittanceAgreement.Get(RemittanceAccount."Remittance Agreement Code");
        if RemittanceAgreement."Receipt Return Required" or
           (WaitingJournal."Remittance Status" = WaitingJournal."Remittance Status"::Sent)
        then
            exit;
        WaitingJournal.FieldError("Remittance Status");
    end;

    [Scope('OnPrem')]
    procedure CreateBalanceEntry(CurrentDate: Date; CurrentCurrencyCode: Code[10]; CurrentVend: Code[20]; CurrentRemittanceAccount: Record "Remittance Account"; CurrentRemittanceAgreement: Record "Remittance Agreement"; var LatestDate: Date; var LatestVend: Code[20]; var LatestRemittanceAccount: Record "Remittance Account"; var LatestRemittanceAgreement: Record "Remittance Agreement"; var LatestCurrencyCode: Code[10]; CurrentGenJournalLine: Record "Gen. Journal Line"; TransDocumentNo: Code[20]; MoreReturnJournals: Boolean; var First: Boolean; var BalanceEntryAmountLCY: Decimal; var CreateNewDocumentNo: Boolean; var BalanceEntryAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        RemittanceTools: Codeunit "Remittance Tools";
        NewBalanceEntry: Boolean;
        DivergenceLCY: Decimal;
    begin
        // Create balance entries for each vendor transaction.
        // General rules:
        // - variables Current... used for the payment processed at the moment
        // - variables Latest... used for payments that were just created.
        // - check if Current... and Latest... are different. If so, the new balance entry must be created.
        // - The balance entry is created with data from the payments that were just created (variables Latest...).

        // First chance to create balance entry. Don't create the entry yet, instead store date and vendor for later...
        if First then begin
            First := false;
            LatestDate := CurrentDate;
            LatestVend := CurrentVend;
            LatestRemittanceAgreement := CurrentRemittanceAgreement;
            LatestRemittanceAccount := CurrentRemittanceAccount;
            LatestCurrencyCode := CurrentCurrencyCode;
        end;

        if BalanceEntryAmountLCY = 0 then // The balance entry will not be created after all:
            exit;

        // Create balance entry? If the user setup is defined with balance entry per vendor
        // then a balance entry is created each time the vendor is changed. A balance entry is created each
        // time a date is changed, regardless of setup.
        if LatestRemittanceAgreement."New Document Per." =
           LatestRemittanceAgreement."New Document Per."::"Specified for account"
        then begin
            if CurrentRemittanceAccount."New Document Per." = CurrentRemittanceAccount."New Document Per."::Vendor then
                NewBalanceEntry := (CurrentVend <> LatestVend);
        end else
            if LatestRemittanceAgreement."New Document Per." = LatestRemittanceAgreement."New Document Per."::Vendor then
                NewBalanceEntry := (CurrentVend <> LatestVend);
        if CurrentDate <> LatestDate then // A change in date allways means creating new balance entry:
            NewBalanceEntry := true;
        if LatestCurrencyCode <> CurrentCurrencyCode then
            NewBalanceEntry := true;
        if LatestRemittanceAccount.Code <> CurrentRemittanceAccount.Code then
            NewBalanceEntry := true;
        if not NewBalanceEntry then // If not 'create new balance entry' - then exit
            exit;

        // Create balance entry:
        GenJournalLine.Init();
        InitJournalLine(GenJournalLine, LatestRemittanceAccount, CurrentGenJournalLine, MoreReturnJournals);
        GenJournalLine.Validate("Posting Date", LatestDate);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Account Type", LatestRemittanceAccount."Account Type");
        GenJournalLine.Validate("Account No.", LatestRemittanceAccount."Account No.");
        GenJournalLine.Validate("Currency Code", LatestCurrencyCode);
        GenJournalLine.VALIDATE(Amount, -BalanceEntryAmount);
        GenJournalLine.VALIDATE("Amount (LCY)", -BalanceEntryAmountLCY);
        GenJournalLine.Validate("Document No.", TransDocumentNo);
        case LatestRemittanceAgreement."New Document Per." of
            LatestRemittanceAgreement."New Document Per."::Date:
                GenJournalLine.Validate(
                  Description, StrSubstNo(RemittanceDateTxt, LatestDate));
            LatestRemittanceAgreement."New Document Per."::Vendor:
                GenJournalLine.Validate(
                  Description, StrSubstNo(RemittanceVendorsTxt, LatestVend));
        end;
        GenJournalLine.Insert(true);

        // Post round off/divergence:
        // Divergence is calculated as a differance betweens "Amount (NOK)" in the balance entry line and the sum of
        // "Amount (LCY)" in the current transaction lines
        DivergenceLCY := -(GenJournalLine."Amount (LCY)" + BalanceEntryAmountLCY);
        if DivergenceLCY <> 0 then begin
            LatestRemittanceAccount.TestField("Round off/Divergence Acc. No.");
            GenJournalLine.Init();
            InitJournalLine(GenJournalLine, LatestRemittanceAccount, CurrentGenJournalLine, MoreReturnJournals);
            GenJournalLine.Validate("Posting Date", LatestDate);
            GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
            GenJournalLine.Validate("Account No.", LatestRemittanceAccount."Round off/Divergence Acc. No.");
            GenJournalLine.Validate(Amount, DivergenceLCY);
            GenJournalLine.Validate("Document No.", TransDocumentNo);
            GenJournalLine.Validate(Description, RemittanceRoundOffDivergenceTxt);
            if Abs(DivergenceLCY) > LatestRemittanceAccount."Max. Round off/Diverg. (LCY)" then
                RemittanceTools.InsertWarning(
                  GenJournalLine,
                  StrSubstNo(TooLargeRoundOffDivergenceErr,
                    LatestRemittanceAccount."Max. Round off/Diverg. (LCY)"));
            GenJournalLine.Insert(true);
        end;

        // prepare for the next balance entry:
        CreateNewDocumentNo := true;
        BalanceEntryAmount := 0;  // From the begining, with the balance entry amount
        BalanceEntryAmountLCY := 0;
        LatestDate := CurrentDate; // Store current date, vend. etc.
        LatestVend := CurrentVend;
        LatestRemittanceAccount := CurrentRemittanceAccount;
        LatestRemittanceAgreement := CurrentRemittanceAgreement;
        LatestCurrencyCode := CurrentCurrencyCode;
    end;

    local procedure FindDocumentNo(PostDate: Date; RemittanceAccount: Record "Remittance Account"; CreateNewDocumentNo: Boolean; var TransDocumentNo: Code[20])
    var
        NoSeries: Codeunit "No. Series";
    begin
        if CreateNewDocumentNo then begin
            TransDocumentNo := '';
                TransDocumentNo := NoSeries.GetNextNo(RemittanceAccount."Document No. Series", PostDate);
            CreateNewDocumentNo := false;
        end;
        // Trans. document no. is now the current document no.
    end;

    [Scope('OnPrem')]
    procedure ConfirmImportDialog(FileName: Text[250]; NumberApproved: Integer; NumberRejected: Integer; NumberSettled: Integer)
    var
        FileManagement: Codeunit "File Management";
    begin
        if not Confirm(StrSubstNo(
               ConfirmImportQst,
               FileManagement.GetFileName(FileName), NumberApproved, NumberRejected, NumberSettled),
             true)
        then
            Error(ImportCancelledErr);
    end;

    [Scope('OnPrem')]
    procedure ConfirmImportExchRateDialog(): Boolean
    var
        ConfirmMgt: Codeunit "Confirm Management";
    begin
        if not ConfirmMgt.GetResponseOrDefault(ConfirmImportExchRateQst, true) then
            Error(ImportCancelledErr);

        exit(true);
    end;
}
