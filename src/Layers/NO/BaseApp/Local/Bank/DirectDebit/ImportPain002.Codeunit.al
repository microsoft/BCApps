// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using System;
using System.IO;
using System.Xml;

codeunit 10636 "Import Pain002"
{

    trigger OnRun()
    begin
    end;

    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        CurrentGenJournalLine: Record "Gen. Journal Line";
        LatestRemittanceAccount: Record "Remittance Account";
        LatestRemittanceAgreement: Record "Remittance Agreement";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ImportSEPACommon: Codeunit "Import SEPA Common";
        XmlDocumentPain002: DotNet XmlDocument;
        XmlNamespaceManagerPain002: DotNet XmlNamespaceManager;
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
        UnknownStatusErr: Label 'Unknown status.';
        Pain002NamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.002.001.03';
        AccountCurrency: Code[3];
        LatestCurrencyCode: Code[3];
        ChooseFileTitleMsg: Label 'Choose the file to upload.';

    [Scope('OnPrem')]
    procedure ImportAndHandlePain002File(GenJournalLine: Record "Gen. Journal Line"; FileName: Text[250]; Note: Text[50])
    var
        WaitingJournal: Record "Waiting Journal";
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
        XmlNodeListPayments: DotNet XmlNodeList;
        NodeListEnumPayments: DotNet IEnumerator;
        XmlNodeGroupHeader: DotNet XmlNode;
        XmlNodePayment: DotNet XmlNode;
        OriginalMsgId: Text;
        TransactionStatus: Text;
        TransactionCauseCode: Text[20];
        TransactionCauseInfo: Text[150];
    begin
        NumberApproved := 0;
        NumberRejected := 0;
        NumberSettled := 0;
        CurrentGenJournalLine := GenJournalLine;
        MoreReturnJournals := false;
        First := true;
        CreateNewDocumentNo := true;
        LatestDate := 20030201D; // dummy init for precal
        LatestVend := '';

        OpenPain002Document();

        // used as a reference in waiting journals
        ImportSEPACommon.CreatePaymOrder(Note, RemittancePaymentOrder);

        ImportSEPACommon.FindFirstNode(
          XmlDocumentPain002, XmlNamespaceManagerPain002, XmlNodeGroupHeader, '//n:CstmrPmtStsRpt/n:OrgnlGrpInfAndSts', true);

        OriginalMsgId :=
          ImportSEPACommon.FindFirstNodeTxt(
            XmlNodeGroupHeader, XmlNamespaceManagerPain002, './n:OrgnlMsgId', true);

        // prepare to loop on payments
        if XMLDOMManagement.FindNodesWithNamespaceManager(
             XmlDocumentPain002, '//n:OrgnlPmtInfAndSts', XmlNamespaceManagerPain002, XmlNodeListPayments)
        then begin
            NodeListEnumPayments := XmlNodeListPayments.GetEnumerator();
            NodeListEnumPayments.MoveNext();
            repeat
                XmlNodePayment := NodeListEnumPayments.Current;
                HandlePayment(XmlNodePayment, OriginalMsgId);
            until not NodeListEnumPayments.MoveNext();
        end else begin
            // No payment info, search for the info at message level (higher level) and propagate to all linked payments and transactions
            TransactionStatus := ImportSEPACommon.FindFirstNodeTxt(XmlNodeGroupHeader, XmlNamespaceManagerPain002, './n:GrpSts', true);
            GetStatusInfo(XmlNodeGroupHeader, TransactionCauseCode, TransactionCauseInfo);
            // update all transactions that match the filter
            WaitingJournal.Reset();
            WaitingJournal.SetFilter("SEPA Msg. ID", OriginalMsgId);
            if not WaitingJournal.FindFirst() then
                Error(WaitingJournal.GetWaitingJournalNotFoundForRemittanceImport());
            ImportSEPACommon.UpdateWaitingJournal(
              WaitingJournal, MapReceivedStatusToFinalStatus(TransactionStatus), TransactionCauseCode, TransactionCauseInfo,
              RemittancePaymentOrder, GetMsgCreationDate(), CurrentGenJournalLine, AccountCurrency, NumberApproved, NumberSettled, NumberRejected,
              TransDocumentNo, BalanceEntryAmountLCY, MoreReturnJournals, First, LatestDate, LatestVend, LatestRemittanceAccount,
              LatestRemittanceAgreement,
              LatestCurrencyCode,
              CreateNewDocumentNo, true, BalanceEntryAmount);
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
    procedure HandlePayment(XmlNodePayment: DotNet XmlNode; OriginalMsgId: Text)
    var
        WaitingJournal: Record "Waiting Journal";
        XmlNodeListTransactions: DotNet XmlNodeList;
        NodeListEnumTransactions: DotNet IEnumerator;
        XmlNodeTransaction: DotNet XmlNode;
        OriginalPmtInfId: Text;
        TransactionStatus: Text;
        TransactionCauseCode: Text[20];
        TransactionCauseInfo: Text[150];
    begin
        OriginalPmtInfId := ImportSEPACommon.FindFirstNodeTxt(XmlNodePayment, XmlNamespaceManagerPain002, './n:OrgnlPmtInfId', true);
        WaitingJournal.Reset();
        WaitingJournal.SetFilter("SEPA Msg. ID", OriginalMsgId);
        WaitingJournal.SetFilter("SEPA Payment Inf ID", OriginalPmtInfId);

        // prepare to loop on transactions
        if XMLDOMManagement.FindNodesWithNamespaceManager(
             XmlNodePayment, './n:TxInfAndSts', XmlNamespaceManagerPain002, XmlNodeListTransactions)
        then begin
            NodeListEnumTransactions := XmlNodeListTransactions.GetEnumerator();
            NodeListEnumTransactions.MoveNext();
            repeat
                XmlNodeTransaction := NodeListEnumTransactions.Current;
                HandleTransaction(XmlNodeTransaction, WaitingJournal);
            until not NodeListEnumTransactions.MoveNext();
        end else begin
            // No transaction info, search for the info at payment level (higher level) and propagate to all linked transactions
            TransactionStatus := ImportSEPACommon.FindFirstNodeTxt(XmlNodePayment, XmlNamespaceManagerPain002, './n:PmtInfSts', true);
            GetStatusInfo(XmlNodePayment, TransactionCauseCode, TransactionCauseInfo);
            // update all transactions that match the filter
            if not WaitingJournal.FindFirst() then
                Error(WaitingJournal.GetWaitingJournalNotFoundForRemittanceImport());
            ImportSEPACommon.UpdateWaitingJournal(
              WaitingJournal, MapReceivedStatusToFinalStatus(TransactionStatus), TransactionCauseCode, TransactionCauseInfo,
              RemittancePaymentOrder, GetMsgCreationDate(), CurrentGenJournalLine, AccountCurrency, NumberApproved, NumberSettled, NumberRejected,
              TransDocumentNo, BalanceEntryAmountLCY, MoreReturnJournals, First, LatestDate, LatestVend, LatestRemittanceAccount,
              LatestRemittanceAgreement,
              LatestCurrencyCode,
              CreateNewDocumentNo, true, BalanceEntryAmount);
        end;
    end;

    [Scope('OnPrem')]
    procedure HandleTransaction(XmlNodeTransaction: DotNet XmlNode; var WaitingJournal: Record "Waiting Journal")
    var
        OriginalEndToEndId: Text;
        TransactionStatus: Text;
        TransactionCauseCode: Text[20];
        TransactionCauseInfo: Text[150];
    begin
        GetTransactionInfo(
          XmlNodeTransaction, OriginalEndToEndId, TransactionStatus, TransactionCauseCode, TransactionCauseInfo);

        WaitingJournal.SetFilter("SEPA End To End ID", OriginalEndToEndId);
        if not WaitingJournal.FindFirst() then
            Error(WaitingJournal.GetWaitingJournalNotFoundForRemittanceImport());
        ImportSEPACommon.UpdateWaitingJournal(
          WaitingJournal, MapReceivedStatusToFinalStatus(TransactionStatus), TransactionCauseCode, TransactionCauseInfo,
          RemittancePaymentOrder, GetMsgCreationDate(), CurrentGenJournalLine, AccountCurrency, NumberApproved, NumberSettled, NumberRejected,
          TransDocumentNo, BalanceEntryAmountLCY, MoreReturnJournals, First, LatestDate, LatestVend, LatestRemittanceAccount,
          LatestRemittanceAgreement,
          LatestCurrencyCode,
          CreateNewDocumentNo, true, BalanceEntryAmount);
    end;


    local procedure OpenPain002Document()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        FileManagement: Codeunit "File Management";
        ServerFile: Text;
    begin
        ServerFile := FileManagement.UploadFile(ChooseFileTitleMsg, '');

        XMLDOMManagement.LoadXMLDocumentFromFile(ServerFile, XmlDocumentPain002);
        XMLDOMManagement.AddNamespaces(XmlNamespaceManagerPain002, XmlDocumentPain002);
        XmlNamespaceManagerPain002.AddNamespace('n', Pain002NamespaceTxt);
    end;

    local procedure GetStatusInfo(XmlNode: DotNet XmlNode; var CauseCode: Text; var CauseInfo: Text)
    begin
        CauseCode := ImportSEPACommon.FindFirstNodeTxt(XmlNode, XmlNamespaceManagerPain002, './n:StsRsnInf/n:Rsn/n:Cd', false);
        CauseInfo := ImportSEPACommon.FindFirstNodeTxt(XmlNode, XmlNamespaceManagerPain002, './n:StsRsnInf/n:AddtlInf', false);
    end;

    local procedure GetTransactionInfo(XmlNode: DotNet XmlNode; var OriginalEndToEndId: Text; var TransactionStatus: Text; var TransactionCauseCode: Text; var TransactionCauseInfo: Text)
    begin
        OriginalEndToEndId := ImportSEPACommon.FindFirstNodeTxt(XmlNode, XmlNamespaceManagerPain002, './n:OrgnlEndToEndId', true);
        TransactionStatus := ImportSEPACommon.FindFirstNodeTxt(XmlNode, XmlNamespaceManagerPain002, './n:TxSts', true);
        GetStatusInfo(XmlNode, TransactionCauseCode, TransactionCauseInfo);
    end;

    local procedure MapReceivedStatusToFinalStatus(ReceivedStatus: Text): Integer
    var
        ResultStatus: Option Approved,Settled,Rejected,Pending;
    begin
        case ReceivedStatus of
            'ACCP':
                exit(ResultStatus::Approved);
            'ACSC':
                exit(ResultStatus::Settled);
            'ACSP':
                exit(ResultStatus::Approved);
            'ACWC':
                exit(ResultStatus::Approved);
            'PDNG':
                exit(ResultStatus::Pending);
            'RJCT':
                exit(ResultStatus::Rejected);
            else
                Error(UnknownStatusErr);
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

    local procedure GetMsgCreationDate(): Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        ISODate: Text;
    begin
        ISODate :=
          ImportSEPACommon.FindFirstNodeTxt(XmlDocumentPain002, XmlNamespaceManagerPain002, '//n:CstmrPmtStsRpt/n:GrpHdr/n:CreDtTm', true);
        Evaluate(Day, CopyStr(ISODate, 9, 2));
        Evaluate(Month, CopyStr(ISODate, 6, 2));
        Evaluate(Year, CopyStr(ISODate, 1, 4));
        exit(DMY2Date(Day, Month, Year));
    end;

    [Scope('OnPrem')]
    procedure GetNamespace(): Text[250]
    begin
        exit(Pain002NamespaceTxt);
    end;
}

