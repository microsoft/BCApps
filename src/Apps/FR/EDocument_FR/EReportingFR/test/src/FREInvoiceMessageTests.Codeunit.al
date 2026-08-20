// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 148152 "FR E-Invoice Message Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Cust. Ledger Entry" = rimd,
                  tabledata "Detailed Cust. Ledg. Entry" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "E-Document Service Status" = rimd,
                  tabledata "FR E-Invoice Message" = rimd,
                  tabledata "Sales Invoice Header" = rimd;

    var
        Assert: Codeunit Assert;
        MessageSenderMock: Codeunit "FR E-Doc. Msg. Sender Mock";

    [Test]
    procedure PaymentApplicationSendsCollected()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry);

        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One Collected message must be sent.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>212</ram:ProcessConditionCode>'), 'The payload must contain status 212.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ValueAmount currencyID="EUR">100'), 'The payload must contain the collected amount.');
    end;

    [Test]
    procedure PaymentUnapplicationSendsLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        CollectedMessage: Record "FR E-Invoice Message";
        NegativeMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        CreateDetailedLedgerEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry."Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.", -100);

        FREInvoiceMessageMgt.ProcessUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        NegativeMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeMessage.SetRange(Type, NegativeMessage.Type::"Negative Collected");
        NegativeMessage.FindFirst();
        Assert.AreEqual(CollectedMessage."Entry No.", NegativeMessage."Original Entry No.", 'The reversal must link to the original occurrence.');
        Assert.AreEqual(-CollectedMessage.Amount, NegativeMessage.Amount, 'The reversal amount must negate the original amount.');
        Assert.AreEqual(2, MessageSenderMock.GetSendCount(), 'Collected and Negative Collected messages must be sent.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ValueAmount currencyID="EUR">-100'), 'The reversal payload must contain a negative amount.');
    end;

    [Test]
    procedure RefusalSendsStatusAndReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'PRICE', 'The amount is incorrect.');

        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One refusal message must be sent.');
        Assert.AreEqual("E-Doc. Response Type"::Refused, MessageSenderMock.GetLastResponseType(), 'The child message must be Refused.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>210</ram:ProcessConditionCode>'), 'The payload must contain status 210.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ReasonCode>PRICE</ram:ReasonCode>'), 'The payload must contain the reason code.');
    end;

    [Test]
    procedure RefusalRequiresReasonAndCannotBeRepeated()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, '', 'Not accepted.');
        Assert.ExpectedError('A refusal reason code is required.');
        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');
        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Again.');
        Assert.ExpectedError('has already been refused');
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'A duplicate refusal must not be sent.');
    end;

    local procedure Initialize()
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        FREInvoiceMessage.DeleteAll();
        MessageSenderMock.Reset();
        EnsureService();
    end;

    local procedure EnsureService()
    var
        EDocumentService: Record "E-Document Service";
    begin
        if EDocumentService.Get('FR-MESSAGE-MOCK') then
            exit;
        EDocumentService.Init();
        EDocumentService.Code := 'FR-MESSAGE-MOCK';
        EDocumentService."Document Format" := EDocumentService."Document Format"::"Peppol BIS 3.0 FR";
        EDocumentService."Service Integration V2" := EDocumentService."Service Integration V2"::"FR Message Mock";
        EDocumentService.Insert();
    end;

    local procedure CreateIncomingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice";
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
    end;

    local procedure CreatePaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        DocumentNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(DocumentNo));
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := DocumentNo;
        SalesInvoiceHeader.Insert();

        EDocument.Init();
        EDocument."Document No." := DocumentNo;
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
        CreateServiceStatus(EDocument);

        InvoiceCustLedgerEntry.Init();
        InvoiceCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        InvoiceCustLedgerEntry."Document Type" := InvoiceCustLedgerEntry."Document Type"::Invoice;
        InvoiceCustLedgerEntry."Document No." := DocumentNo;
        InvoiceCustLedgerEntry.Insert();
        PaymentCustLedgerEntry.Init();
        PaymentCustLedgerEntry."Entry No." := InvoiceCustLedgerEntry."Entry No." + 1;
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry.Insert();
        CreateDetailedLedgerEntry(DetailedCustLedgEntry, InvoiceCustLedgerEntry."Entry No.", PaymentCustLedgerEntry."Entry No.", -100);
    end;

    local procedure CreateServiceStatus(EDocument: Record "E-Document")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.Init();
        EDocumentServiceStatus."E-Document Entry No" := EDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := EDocument.Service;
        EDocumentServiceStatus.Status := EDocumentServiceStatus.Status::Approved;
        EDocumentServiceStatus.Insert();
    end;

    local procedure CreateDetailedLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; InvoiceEntryNo: Integer; PaymentEntryNo: Integer; Amount: Decimal)
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := GetNextDetailedLedgerEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := InvoiceEntryNo;
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := PaymentEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Currency Code" := 'EUR';
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert();
    end;

    local procedure GetNextCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetNextDetailedLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;
}