// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using System;
using System.IO;
using System.Xml;

codeunit 10637 "Import CAMT054"
{

    trigger OnRun()
    begin
    end;

    var
        UnexpectedStatusErr: Label 'Unexpected status %1.', Comment = '%1 is the status.';
        UnknownStatusErr: Label 'Unknown status %1.', Comment = '%1 is the status.';
        RemittancePaymentOrder: Record "Remittance Payment Order";
        CurrentGenJournalLine: Record "Gen. Journal Line";
        LatestRemittanceAccount: Record "Remittance Account";
        LatestRemittanceAgreement: Record "Remittance Agreement";
        GLSetup: Record "General Ledger Setup";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ImportSEPACommon: Codeunit "Import SEPA Common";
        XmlDocumentCAMT054: DotNet XmlDocument;
        XmlNamespaceManagerCAMT054: DotNet XmlNamespaceManager;
        NumberApproved: Integer;
        NumberRejected: Integer;
        NumberSettled: Integer;
        MoreReturnJournals: Boolean;
        First: Boolean;
        LatestVend: Code[20];
        BalanceEntryAmountLCY: Decimal;
        BalanceEntryAmount: Decimal;
        TransDocumentNo: Code[20];
        CreateNewDocumentNo: Boolean;
        LatestDate: Date;
        CAMT054NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:camt.054.001.02';
        AccountCurrency: Code[3];
        LatestCurrencyCode: Code[3];
        CustomExchRateIsConfirmed: Boolean;
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    [Scope('OnPrem')]
    procedure ImportAndHandleCAMT054File(GenJournalLine: Record "Gen. Journal Line"; FileName: Text[250]; Note: Text[50])
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
        XmlNodeListTransactionEntries: DotNet XmlNodeList;
        NodeListEnumTransactionEntries: DotNet IEnumerator;
        XmlNodeTransactionEntry: DotNet XmlNode;
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        CustomExchRateIsConfirmed := false;
        NumberApproved := 0;
        NumberRejected := 0;
        NumberSettled := 0;
        CurrentGenJournalLine := GenJournalLine;
        MoreReturnJournals := false;
        First := true;
        CreateNewDocumentNo := true;
        LatestDate := 20030201D; // dummy init for precal
        LatestVend := '';

        OpenCAMT054Document();

        // used as a reference in waiting journals
        ImportSEPACommon.CreatePaymOrder(Note, RemittancePaymentOrder);

        // prepare to loop on entries (transactions)
        if XMLDOMManagement.FindNodesWithNamespaceManager(
             XmlDocumentCAMT054, '//n:BkToCstmrDbtCdtNtfctn/n:Ntfctn/n:Ntry', XmlNamespaceManagerCAMT054, XmlNodeListTransactionEntries)
        then begin
            NodeListEnumTransactionEntries := XmlNodeListTransactionEntries.GetEnumerator();
            NodeListEnumTransactionEntries.MoveNext();
            repeat
                XmlNodeTransactionEntry := NodeListEnumTransactionEntries.Current;
                HandleTransaction(XmlNodeTransactionEntry);
            until not NodeListEnumTransactionEntries.MoveNext();
        end;

        // Closing transaction.
        if NumberSettled > 0 then  // Check whether payments are created
                                   // Create balance entry for the last vendor transaction.
                                   // All the parameters are dummies. This is only to make sure that the balance entry is created:
            ImportSEPACommon.CreateBalanceEntry(
            20010101D, AccountCurrency, '', RemittanceAccount, RemittanceAgreement, LatestDate, LatestVend, LatestRemittanceAccount,
            LatestRemittanceAgreement,
            LatestCurrencyCode, CurrentGenJournalLine,
            TransDocumentNo, MoreReturnJournals, First, BalanceEntryAmountLCY, CreateNewDocumentNo, BalanceEntryAmount);

        ImportSEPACommon.ConfirmImportDialog(FileName, NumberApproved, NumberRejected, NumberSettled);
    end;

    [Scope('OnPrem')]
    procedure HandleTransaction(XmlNodeTransactionEntry: DotNet XmlNode)
    var
        WaitingJournal: Record "Waiting Journal";
        AmtDtlsGenJournalLine: Record "Gen. Journal Line";
        OriginalMsgId: Text;
        OriginalPmtInfId: Text;
        OriginalEndToEndId: Text;
        TransactionStatus: Text;
    begin
        GetTransactionInfo(
          XmlNodeTransactionEntry, OriginalMsgId, OriginalPmtInfId, OriginalEndToEndId, TransactionStatus);
        WaitingJournal.Reset();
        WaitingJournal.SetFilter("SEPA Msg. ID", OriginalMsgId);
        WaitingJournal.SetFilter("SEPA Payment Inf ID", OriginalPmtInfId);
        WaitingJournal.SetFilter("SEPA End To End ID", OriginalEndToEndId);
        if not WaitingJournal.FindFirst() then
            Error(WaitingJournal.GetWaitingJournalNotFoundForRemittanceImport());

        if GetAmountDetails(AmtDtlsGenJournalLine, XmlNodeTransactionEntry) then
            if UpdateWaitingJournalWithAmtDtls(WaitingJournal, AmtDtlsGenJournalLine) then
                if not CustomExchRateIsConfirmed then
                    CustomExchRateIsConfirmed := ImportSEPACommon.ConfirmImportExchRateDialog();

        ImportSEPACommon.UpdateWaitingJournal(
          WaitingJournal, MapReceivedStatusToFinalStatus(TransactionStatus), '', '',
          RemittancePaymentOrder, GetMsgCreationDate(XmlNodeTransactionEntry), CurrentGenJournalLine, AccountCurrency, NumberApproved,
          NumberSettled, NumberRejected,
          TransDocumentNo, BalanceEntryAmountLCY, MoreReturnJournals, First, LatestDate, LatestVend, LatestRemittanceAccount,
          LatestRemittanceAgreement,
          LatestCurrencyCode,
          CreateNewDocumentNo, false, BalanceEntryAmount);
    end;

    local procedure OpenCAMT054Document()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        FileManagement: Codeunit "File Management";
        ServerFile: Text;
    begin
        ServerFile := FileManagement.UploadFile(ChooseFileTitleMsg, '');

        XMLDOMManagement.LoadXMLDocumentFromFile(ServerFile, XmlDocumentCAMT054);
        XMLDOMManagement.AddNamespaces(XmlNamespaceManagerCAMT054, XmlDocumentCAMT054);
        XmlNamespaceManagerCAMT054.AddNamespace('n', CAMT054NamespaceTxt);
    end;

    local procedure GetTransactionInfo(TransactionEntryXmlNode: DotNet XmlNode; var OriginalMsgId: Text; var OriginalPmtInfId: Text; var OriginalEndToEndId: Text; var TransactionStatus: Text)
    var
        RefsNode: DotNet XmlNode;
    begin
        ImportSEPACommon.FindFirstNode(TransactionEntryXmlNode, XmlNamespaceManagerCAMT054, RefsNode, './n:NtryDtls/n:TxDtls/n:Refs', true);
        OriginalMsgId := ImportSEPACommon.FindFirstNodeTxt(RefsNode, XmlNamespaceManagerCAMT054, './n:MsgId', true);
        OriginalPmtInfId := ImportSEPACommon.FindFirstNodeTxt(RefsNode, XmlNamespaceManagerCAMT054, './n:PmtInfId', true);
        OriginalEndToEndId := ImportSEPACommon.FindFirstNodeTxt(RefsNode, XmlNamespaceManagerCAMT054, './n:EndToEndId', true);
        TransactionStatus := ImportSEPACommon.FindFirstNodeTxt(TransactionEntryXmlNode, XmlNamespaceManagerCAMT054, './n:Sts', true);
    end;

    local procedure GetAmountDetails(var AmtDtlsGenJournalLine: Record "Gen. Journal Line"; TransactionEntryXmlNode: DotNet XmlNode): Boolean
    var
        AmtDtlsNode: DotNet XmlNode;
        CcyXchgNode: DotNet XmlNode;
    begin
        Clear(AmtDtlsGenJournalLine);

        if not ImportSEPACommon.FindFirstNode(
             TransactionEntryXmlNode, XmlNamespaceManagerCAMT054, AmtDtlsNode, './n:NtryDtls/n:TxDtls/n:AmtDtls', false)
        then
            exit(false);

        if not ImportSEPACommon.FindFirstNode(AmtDtlsNode, XmlNamespaceManagerCAMT054, CcyXchgNode, './n:InstdAmt/n:CcyXchg', false) then
            exit(false);

        if not ImportSEPACommon.FindFirstNodeDecimal(
             AmtDtlsGenJournalLine.Amount, AmtDtlsNode, XmlNamespaceManagerCAMT054, './n:InstdAmt/n:Amt', false)
        then
            exit(false);

        if not ImportSEPACommon.FindFirstNodeDecimal(
             AmtDtlsGenJournalLine."Amount (LCY)", AmtDtlsNode, XmlNamespaceManagerCAMT054, './n:TxAmt/n:Amt', false)
        then
            exit(false);

        AmtDtlsGenJournalLine."Source Currency Code" :=
          CopyStr(
            ImportSEPACommon.FindFirstNodeTxt(CcyXchgNode, XmlNamespaceManagerCAMT054, './n:SrcCcy', false),
            1, MaxStrLen(AmtDtlsGenJournalLine."Source Currency Code"));
        if AmtDtlsGenJournalLine."Source Currency Code" = '' then
            exit(false);

        AmtDtlsGenJournalLine."Currency Code" :=
          CopyStr(
            ImportSEPACommon.FindFirstNodeTxt(CcyXchgNode, XmlNamespaceManagerCAMT054, './n:TrgtCcy', false),
            1, MaxStrLen(AmtDtlsGenJournalLine."Currency Code"));
        if AmtDtlsGenJournalLine."Currency Code" = '' then
            exit(false);

        if not ImportSEPACommon.FindFirstNodeDecimal(
             AmtDtlsGenJournalLine."Currency Factor", CcyXchgNode, XmlNamespaceManagerCAMT054, './n:XchgRate', false)
        then
            exit(false);

        exit(true);
    end;

    local procedure MapReceivedStatusToFinalStatus(ReceivedStatus: Text): Integer
    var
        ResultStatus: Option Approved,Settled,Rejected,Pending;
    begin
        case ReceivedStatus of
            'BOOK':
                exit(ResultStatus::Settled);
            'PDNG':
                Error(UnexpectedStatusErr, ReceivedStatus);
            'INFO':
                Error(UnexpectedStatusErr, ReceivedStatus);
            else
                Error(UnknownStatusErr, ReceivedStatus);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReadStatus(var Approved: Integer; var Rejected: Integer; var Settled: Integer; var ReturnMoreReturnJournals: Boolean; var ReturnRemittancePaymentOrder: Record "Remittance Payment Order")
    begin
        // Returns info on the current (terminated) import.
        // Counts parameters with new values.
        Approved := Approved + NumberApproved;
        Rejected := Rejected + NumberRejected;
        Settled := Settled + NumberSettled;
        ReturnMoreReturnJournals := MoreReturnJournals;
        ReturnRemittancePaymentOrder := RemittancePaymentOrder;
    end;

    local procedure GetMsgCreationDate(XmlNodeTransactionEntry: DotNet XmlNode): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        ISODate: Text;
    begin
        ISODate :=
          ImportSEPACommon.FindFirstNodeTxt(XmlNodeTransactionEntry, XmlNamespaceManagerCAMT054, './n:BookgDt/n:Dt', true);
        Evaluate(Day, CopyStr(ISODate, 9, 2));
        Evaluate(Month, CopyStr(ISODate, 6, 2));
        Evaluate(Year, CopyStr(ISODate, 1, 4));
        exit(DMY2Date(Day, Month, Year));
    end;

    [Scope('OnPrem')]
    procedure GetNamespace(): Text[250]
    begin
        exit(CAMT054NamespaceTxt);
    end;

    local procedure UpdateWaitingJournalWithAmtDtls(var WaitingJournal: Record "Waiting Journal"; AmtDtlsGenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        if (WaitingJournal."Currency Code" = AmtDtlsGenJournalLine."Source Currency Code") and
           (GetCurrencyCode('') = AmtDtlsGenJournalLine."Currency Code")
        then
            if (WaitingJournal.Amount <> AmtDtlsGenJournalLine.Amount) or
               (WaitingJournal."Amount (LCY)" <> AmtDtlsGenJournalLine."Amount (LCY)")
            then begin
                WaitingJournal.Amount := AmtDtlsGenJournalLine.Amount;
                WaitingJournal."Amount (LCY)" := AmtDtlsGenJournalLine."Amount (LCY)";
                WaitingJournal."Currency Factor" := 1 / AmtDtlsGenJournalLine."Currency Factor";
                exit(true);
            end;

        exit(false);
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode = '' then
            exit(GLSetup."LCY Code");

        exit(CurrencyCode);
    end;
}

