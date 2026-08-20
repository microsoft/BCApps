// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 148151 "FR E-Invoice Message Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Cust. Ledger Entry" = rimd,
                  tabledata "Detailed Cust. Ledg. Entry" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "E-Document Service Status" = rimd,
                  tabledata "E-Doc. Payment Occurrence" = rimd,
                  tabledata "FR E-Invoice Message" = rimd,
                  tabledata "Sales Invoice Header" = rimd;

    var
        Assert: Codeunit Assert;
        MessageSenderMock: Codeunit "FR E-Doc. Msg. Sender Mock";

    [Test]
    procedure PaymentApplicationSendsCollected()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
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
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        EDocPaymentOccurrence.FindFirst();
        Assert.AreEqual(100, EDocPaymentOccurrence.Amount, 'The generic applied occurrence must carry a positive amount.');
        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Payment posting must queue the message without invoking the connector.');
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One Collected message must be sent.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>212</ram:ProcessConditionCode>'), 'The payload must contain status 212.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ValueAmount currencyID="EUR">100'), 'The payload must contain the collected amount.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<udt:DateTimeString format="204">'), 'The payload must contain the AFNOR lifecycle event date.');
    end;

    [Test]
    procedure PaymentUnapplicationSendsLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        CollectedMessage: Record "FR E-Invoice Message";
        AppliedOccurrence: Record "E-Doc. Payment Occurrence";
        NegativeMessage: Record "FR E-Invoice Message";
        ReversedOccurrence: Record "E-Doc. Payment Occurrence";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        SendMessage(CollectedMessage);
        CreateDetailedLedgerEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry."Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.", -100);

        FREInvoiceMessageMgt.ProcessUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        NegativeMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeMessage.SetRange(Type, NegativeMessage.Type::"Negative Collected");
        NegativeMessage.FindFirst();
        Assert.AreEqual(CollectedMessage."Entry No.", NegativeMessage."Original Entry No.", 'The reversal must link to the original occurrence.');
        Assert.AreEqual(-CollectedMessage.Amount, NegativeMessage.Amount, 'The reversal amount must negate the original amount.');
        AppliedOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        AppliedOccurrence.SetRange(Type, AppliedOccurrence.Type::Applied);
        AppliedOccurrence.FindFirst();
        ReversedOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        ReversedOccurrence.SetRange(Type, ReversedOccurrence.Type::Reversed);
        ReversedOccurrence.FindFirst();
        Assert.AreEqual(AppliedOccurrence."Entry No.", ReversedOccurrence."Original Occurrence Entry No.", 'The generic reversal must link to its applied occurrence.');
        Assert.AreEqual(-AppliedOccurrence.Amount, ReversedOccurrence.Amount, 'The generic reversal must negate the applied amount.');
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'Unapplication must queue the reversal without invoking the connector.');
        SendMessage(NegativeMessage);
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

        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Refusal must queue the message without invoking the connector.');
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Refused);
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
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Refused);
        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Again.');
        Assert.ExpectedError('has already been refused');
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'A duplicate refusal must not be sent.');
    end;

    [Test]
    procedure MessageSenderMustReportSuccess()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", "E-Doc. Response Type"::Refused, TempBlob);
        MessageSenderMock.SetReportSuccess(false);

        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        Assert.ExpectedError('could not be sent');
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'The connector must be invoked before its missing success result is rejected.');
    end;

    [Test]
    procedure PaymentApplicationReplayIsIdempotent()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry);

        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure IncomingMessageIsCorrelatedAndDeduplicated()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        FirstMessageEntryNo: Integer;
        DuplicateMessageEntryNo: Integer;
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, 'FR-DOC-001');
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        FirstMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, 'FR-DOC-001', 'FR-MSG-001', "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);
        DuplicateMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, 'FR-DOC-001', 'FR-MSG-001', "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

        Assert.AreNotEqual(0, FirstMessageEntryNo, 'The incoming lifecycle message must be persisted.');
        Assert.AreEqual(FirstMessageEntryNo, DuplicateMessageEntryNo, 'The external message ID must deduplicate repeated delivery.');
    end;

    [Test]
    procedure IncomingMessageRequiresRegisteredDocumentReference()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        asserterror EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, CopyStr(Format(CreateGuid()), 1, 250), CopyStr(Format(CreateGuid()), 1, 250),
            "E-Document Message Type"::"FR Invoice Lifecycle", "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

        Assert.ExpectedError('is not registered');
    end;

    [Test]
    procedure BuyerAcceptanceQueuesAndSendsStatus205()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.AcceptInvoice(EDocument);

        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Accepted);
        Assert.RecordCount(FREInvoiceMessage, 1);
        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Acceptance must queue the message without invoking the connector.');
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Accepted);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One Accepted message must be sent.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, MessageSenderMock.GetLastResponseType(), 'The child message must be Accepted.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>205</ram:ProcessConditionCode>'), 'The payload must contain status 205.');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeated()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.AcceptInvoice(EDocument);
        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Changed my mind.');
        Assert.ExpectedError('already has a buyer response');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeatedAfterRefusal()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');
        asserterror FREInvoiceMessageMgt.AcceptInvoice(EDocument);
        Assert.ExpectedError('already has a buyer response');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveSubmittedPersistsNormalizedMessage()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        ReceivedAt: DateTime;
        FREntryNo: Integer;
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        ReceivedAt := CreateDateTime(20260101D, 120000T);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, ReceivedAt, TempBlob);

        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::Submitted, FREInvoiceMessage.Type, 'FR type must be Submitted.');
        Assert.AreEqual(ExternalMsgID, FREInvoiceMessage."External Message ID", 'External message ID must be stored.');
        Assert.AreEqual(ReceivedAt, FREInvoiceMessage."Received At", 'Received timestamp must be persisted.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocumentMessageAPI.GetMessageDirection(FREInvoiceMessage."E-Document Message Entry No."), 'Generic message must be Incoming.');
        Assert.AreEqual("E-Doc. Message Status"::Received, EDocumentMessageAPI.GetMessageStatus(FREInvoiceMessage."E-Document Message Entry No."), 'Generic message status must be Received.');
        Assert.AreEqual("E-Doc. Response Type"::Submitted, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Submitted.');
    end;

    [Test]
    procedure ReceiveAcceptedPersistsNormalizedMessage()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FREntryNo: Integer;
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", '205', '', ''));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::Accepted, FREInvoiceMessage.Type, 'FR type must be Accepted.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Accepted.');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedPersistsReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FREntryNo: Integer;
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejetée', 'SCHEMA', 'Schema validation failed'));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::"Technical Rejected", FREInvoiceMessage.Type, 'FR type must be Technical Rejected.');
        Assert.AreEqual('SCHEMA', Format(FREInvoiceMessage."Reason Code"), 'Reason code must be persisted.');
        Assert.AreEqual('Schema validation failed', FREInvoiceMessage."Reason Description", 'Reason description must be persisted.');
        Assert.AreEqual("E-Doc. Response Type"::Rejected, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Rejected.');
    end;

    [Test]
    procedure ReceiveMessageIsIdempotent()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        FirstEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));
        SecondEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        Assert.AreEqual(FirstEntryNo, SecondEntryNo, 'Same external message ID must return same FR entry.');
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Submitted);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure ReceiveMessageRejectsInvalidXml()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('not xml at all');

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('not valid XML');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsUnsupportedStatus()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Unknown', '', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('is not supported');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsInvoiceMismatch()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml('WRONG-INVOICE-ID', 'Submitted', '', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('does not match');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonCode()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', '', 'Something went wrong'));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('reason code is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonDescription()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', 'SCHEMA', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('reason description is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BuilderRejectsIncomingOnlyStatus()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := FREInvoiceMessage.Type::Submitted;
        FREInvoiceMessage."Source Occurrence ID" := CreateGuid();
        FREInvoiceMessage."Event Date" := Today();
        FREInvoiceMessage."Created At" := CurrentDateTime();
        FREInvoiceMessage.Insert();

        asserterror FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);

        Assert.ExpectedError('cannot be sent');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure BuildLifecycleXml(InvoiceID: Text; Status: Text; ReasonCode: Text; ReasonDescription: Text): Text
    var
        XmlText: TextBuilder;
    begin
        XmlText.Append('<LifecycleMessage>');
        XmlText.Append('<InvoiceID>');
        XmlText.Append(InvoiceID);
        XmlText.Append('</InvoiceID>');
        XmlText.Append('<Status>');
        XmlText.Append(Status);
        XmlText.Append('</Status>');
        if ReasonCode <> '' then begin
            XmlText.Append('<ReasonCode>');
            XmlText.Append(ReasonCode);
            XmlText.Append('</ReasonCode>');
        end;
        if ReasonDescription <> '' then begin
            XmlText.Append('<ReasonDescription>');
            XmlText.Append(ReasonDescription);
            XmlText.Append('</ReasonDescription>');
        end;
        XmlText.Append('</LifecycleMessage>');
        exit(XmlText.ToText());
    end;

    local procedure SendFirstMessage(EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type")
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, MessageType);
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);
    end;

    local procedure SendMessage(FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        EDocumentMessageAPI.SendMessage(FREInvoiceMessage."E-Document Message Entry No.");
    end;

    local procedure Initialize()
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        EDocPaymentOccurrence.DeleteAll();
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

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
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