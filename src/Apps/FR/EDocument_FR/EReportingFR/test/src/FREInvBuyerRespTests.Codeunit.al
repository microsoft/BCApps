// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;

codeunit 148152 "FR E-Inv. Buyer Resp. Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        MessageSenderMock: Codeunit "FR E-Doc. Msg. Sender Mock";

    [Test]
    procedure AcceptIncomingPurchaseInvoice()
    var
        EDocument: Record "E-Document";
        FREInvoiceBuyerResponse: Record "FR E-Invoice Buyer Response";
    begin
        // [SCENARIO] Accepting an incoming purchase invoice creates and sends an Accepted child message
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        AcceptInvoice(EDocument);

        FREInvoiceBuyerResponse.Get(EDocument."Entry No");
        Assert.AreEqual("E-Doc. Response Type"::Accepted, FREInvoiceBuyerResponse."Response Type", 'The buyer response must be Accepted.');
        Assert.AreEqual(FREInvoiceBuyerResponse.Status::Sent, FREInvoiceBuyerResponse.Status, 'The acceptance must be sent.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, MessageSenderMock.GetLastResponseType(), 'The child message must be identified as Accepted.');
    end;

    [Test]
    procedure AcceptancePayloadContainsStatusWithoutRefusalReason()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] The acceptance payload contains status 212 and no refusal reason
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        AcceptInvoice(EDocument);

        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>212</ram:ProcessConditionCode>'), 'The payload must contain status code 212.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessCondition>Acceptée</ram:ProcessCondition>'), 'The payload must contain the Accepted status name.');
        Assert.IsFalse(MessageSenderMock.GetLastPayload().Contains('<ram:ReasonCode>'), 'An acceptance must not contain a refusal reason.');
    end;

    [Test]
    procedure RefuseIncomingPurchaseInvoice()
    var
        EDocument: Record "E-Document";
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
    begin
        // [SCENARIO] Refusing an incoming purchase invoice creates and sends a child message
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        RefuseInvoice(EDocument, 'PRICE', 'The invoice amount is incorrect.');

        FREInvoiceRefusal.Get(EDocument."Entry No");
        Assert.IsTrue(FREInvoiceRefusal."E-Document Message Entry No." > 0, 'A child message must be created.');
        Assert.AreEqual(FREInvoiceRefusal.Status::Sent, FREInvoiceRefusal.Status, 'The refusal must be sent.');
        Assert.AreEqual(1, MessageSenderMock.GetMessageSendCount(), 'The connector must send one message.');
        Assert.AreEqual("E-Doc. Response Type"::Refused, MessageSenderMock.GetLastResponseType(), 'The child message must be identified as Refused.');
    end;

    [Test]
    procedure RefusalPayloadContainsStatus()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] The refusal payload contains the French Refused lifecycle status
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');

        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessConditionCode>210</ram:ProcessConditionCode>'), 'The payload must contain status code 210.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ProcessCondition>Refusée</ram:ProcessCondition>'), 'The payload must contain the Refused status name.');
    end;

    [Test]
    procedure RefusalStoresReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
    begin
        // [SCENARIO] The refusal retains the buyer reason code and description
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        RefuseInvoice(EDocument, 'DUPLICATE', 'This invoice was already received.');

        FREInvoiceRefusal.Get(EDocument."Entry No");
        Assert.AreEqual('DUPLICATE', FREInvoiceRefusal."Reason Code", 'The reason code must be retained.');
        Assert.AreEqual('This invoice was already received.', FREInvoiceRefusal."Reason Description", 'The reason description must be retained.');
        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('<ram:ReasonCode>DUPLICATE</ram:ReasonCode>'), 'The payload must contain the reason code.');
    end;

    [Test]
    procedure RefusalEscapesXmlReason()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] XML-sensitive characters in a refusal reason are escaped
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        RefuseInvoice(EDocument, 'OTHER', 'Wrong <amount> & "currency".');

        Assert.IsTrue(MessageSenderMock.GetLastPayload().Contains('Wrong &lt;amount&gt; &amp; "currency".'), 'The XML reason must be escaped.');
    end;

    [Test]
    procedure RefusalAcceptsMaximumReasonLength()
    var
        EDocument: Record "E-Document";
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
        MaximumReason: Text[500];
    begin
        // [SCENARIO] A 500-character refusal description is retained without truncation
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");
        MaximumReason := PadStr('', MaxStrLen(MaximumReason), 'X');

        RefuseInvoice(EDocument, 'OTHER', MaximumReason);

        FREInvoiceRefusal.Get(EDocument."Entry No");
        Assert.AreEqual(MaximumReason, FREInvoiceRefusal."Reason Description", 'The maximum-length reason must be retained.');
    end;

    [Test]
    procedure RefusalFailsForInvalidDocument()
    var
        OutgoingEDocument: Record "E-Document";
        CreditMemoEDocument: Record "E-Document";
    begin
        // [SCENARIO] The buyer Refused action applies only to incoming purchase invoices
        Initialize();
        CreateEDocument(OutgoingEDocument, OutgoingEDocument.Direction::Outgoing, OutgoingEDocument."Document Type"::"Purchase Invoice");
        CreateEDocument(CreditMemoEDocument, CreditMemoEDocument.Direction::Incoming, CreditMemoEDocument."Document Type"::"Purchase Credit Memo");

        asserterror RefuseInvoice(OutgoingEDocument, 'OTHER', 'Not accepted.');
        Assert.ExpectedError('Direction must be equal to');
        asserterror RefuseInvoice(CreditMemoEDocument, 'OTHER', 'Not accepted.');
        Assert.ExpectedError('Document Type must be equal to Purchase Invoice');
    end;

    [Test]
    procedure RefusalFailsWithoutReason()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] A refusal requires a reason code and description
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        asserterror RefuseInvoice(EDocument, '', 'Not accepted.');
        Assert.ExpectedError('A refusal reason code is required.');
        asserterror RefuseInvoice(EDocument, 'OTHER', '');
        Assert.ExpectedError('A refusal reason description is required.');
    end;

    [Test]
    procedure RefusalUsesInvoiceService()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] The refusal is routed through the service assigned to the incoming invoice
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');

        Assert.AreEqual(EDocument.Service, MessageSenderMock.GetLastServiceCode(), 'The invoice service must send the refusal.');
    end;

    [Test]
    procedure RefusalRollsBackWhenSendFails()
    var
        EDocument: Record "E-Document";
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
    begin
        // [SCENARIO] A connector failure does not leave a refusal marked as created
        Initialize();
        MessageSenderMock.SetShouldFail(true);
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");

        asserterror RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');

        Assert.ExpectedError('French lifecycle message sending failed.');
        Assert.IsFalse(FREInvoiceRefusal.Get(EDocument."Entry No"), 'A failed send must roll back the refusal.');
    end;

    [Test]
    procedure RefusalFailsWhenAlreadyRefused()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] An incoming invoice cannot be refused twice
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");
        RefuseInvoice(EDocument, 'OTHER', 'First refusal.');

        asserterror RefuseInvoice(EDocument, 'OTHER', 'Second refusal.');
        Assert.ExpectedError('already has a buyer response');
        Assert.AreEqual(1, MessageSenderMock.GetMessageSendCount(), 'A duplicate message must not be sent.');
    end;

    [Test]
    procedure AcceptedInvoiceCannotBeRefused()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] An invoice can have only one buyer decision
        Initialize();
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");
        AcceptInvoice(EDocument);

        asserterror RefuseInvoice(EDocument, 'OTHER', 'Changed decision.');

        Assert.ExpectedError('already has a buyer response');
        Assert.AreEqual(1, MessageSenderMock.GetMessageSendCount(), 'A second buyer response must not be sent.');
    end;

    [Test]
    procedure RefusalCompletesPendingResponse()
    var
        EDocument: Record "E-Document";
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
        FREInvoiceRefusalMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
    begin
        // [SCENARIO] An asynchronously accepted refusal moves from Pending Response to Sent
        Initialize();
        MessageSenderMock.SetMessageResultStatus("E-Document Service Status"::"Pending Response");
        CreateEDocument(EDocument, EDocument.Direction::Incoming, EDocument."Document Type"::"Purchase Invoice");
        RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');
        FREInvoiceRefusal.Get(EDocument."Entry No");
        Assert.AreEqual(FREInvoiceRefusal.Status::"Pending Response", FREInvoiceRefusal.Status, 'The refusal must wait for a response.');

        FREInvoiceRefusalMgt.GetResponse(EDocument);

        FREInvoiceRefusal.Get(EDocument."Entry No");
        Assert.AreEqual(FREInvoiceRefusal.Status::Sent, FREInvoiceRefusal.Status, 'The refusal must complete after the connector response.');
        Assert.AreEqual(1, MessageSenderMock.GetMessageResponseCount(), 'The connector response must be requested once.');
    end;

    local procedure Initialize()
    var
        FREInvoiceRefusal: Record "FR E-Invoice Buyer Response";
    begin
        FREInvoiceRefusal.DeleteAll();
        MessageSenderMock.Reset();
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document"; Direction: Enum "E-Document Direction"; DocumentType: Enum "E-Document Type")
    var
        EDocumentService: Record "E-Document Service";
    begin
        if not EDocumentService.Get('FR-MESSAGE-MOCK') then begin
            EDocumentService.Init();
            EDocumentService.Code := 'FR-MESSAGE-MOCK';
            EDocumentService."Service Integration V2" := EDocumentService."Service Integration V2"::"FR Message Mock";
            EDocumentService.Insert();
        end;

        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := Direction;
        EDocument."Document Type" := DocumentType;
        EDocument.Service := EDocumentService.Code;
        EDocument.Insert();
    end;

    local procedure RefuseInvoice(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceRefusalMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
    begin
        FREInvoiceRefusalMgt.RefuseInvoice(EDocument, ReasonCode, ReasonDescription);
    end;

    local procedure AcceptInvoice(EDocument: Record "E-Document")
    var
        FREInvoiceBuyerResponseMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
    begin
        FREInvoiceBuyerResponseMgt.AcceptInvoice(EDocument);
    end;
}