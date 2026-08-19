// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 148151 "FR Lifecycle Response Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure ImportSubmittedResponse()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Submitted response is stored for the matching outgoing invoice
        Initialize();

        VerifyImportedResponse('SUBMITTED', "E-Doc. Response Type"::Submitted);
    end;

    [Test]
    procedure ImportAcceptedResponse()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An Accepted response is stored for the matching outgoing invoice
        Initialize();

        VerifyImportedResponse('ACCEPTED', "E-Doc. Response Type"::Accepted);
    end;

    [Test]
    procedure ImportRejectedResponseWithReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
        ResponseEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A technical Rejected response stores its reason code and description
        Initialize();

        // [GIVEN] Outgoing invoice "I" and a Rejected lifecycle response with a reason
        CreateEDocument(EDocument, 'INV-REJECTED', EDocument.Direction::Outgoing);

        // [WHEN] The response is imported
        ResponseEntryNo := ImportResponse('RESP-REJECTED', EDocument."Document No.", 'REJECTED', 'TECH', 'Invalid invoice syntax');

        // [THEN] The rejection and reason are retained
        FREInvoiceLifecycleResponse.Get(ResponseEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Rejected, FREInvoiceLifecycleResponse."Response Type", 'The response must be Rejected.');
        Assert.AreEqual('TECH', FREInvoiceLifecycleResponse."Reason Code", 'The reason code must be retained.');
        Assert.AreEqual('Invalid invoice syntax', FREInvoiceLifecycleResponse."Reason Description", 'The reason description must be retained.');
    end;

    [Test]
    procedure ImportResponsePreservesPayload()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        StoredPayload: Codeunit "Temp Blob";
        PayloadText: Text;
        ResponseEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Import stores the original response payload in the child message
        Initialize();

        // [GIVEN] Outgoing invoice "I" and lifecycle response payload "P"
        CreateEDocument(EDocument, 'INV-PAYLOAD', EDocument.Direction::Outgoing);
        PayloadText := CreateResponseXml('RESP-PAYLOAD', EDocument."Document No.", 'ACCEPTED', '', '');

        // [WHEN] Payload "P" is imported
        ResponseEntryNo := ImportXml(PayloadText);

        // [THEN] The child message contains unchanged payload "P"
        FREInvoiceLifecycleResponse.Get(ResponseEntryNo);
        EDocumentMessageAPI.GetMessageBlob(FREInvoiceLifecycleResponse."E-Document Message Entry No.", StoredPayload);
        Assert.AreEqual(PayloadText, ReadPayload(StoredPayload), 'The original response payload must be preserved.');
    end;

    [Test]
    procedure ImportResponseFailsForUnknownInvoice()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A response cannot be imported when InvoiceID is unknown
        Initialize();

        asserterror ImportResponse('RESP-UNKNOWN', 'UNKNOWN-INVOICE', 'ACCEPTED', '', '');
        Assert.ExpectedError('No outgoing E-Document was found for InvoiceID UNKNOWN-INVOICE.');
    end;

    [Test]
    procedure ImportResponseFailsForInvalidXml()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Invalid lifecycle XML is rejected
        Initialize();

        asserterror ImportXml('<invalid>');
        Assert.ExpectedError('not valid XML');
    end;

    [Test]
    procedure ImportResponseFailsForUnsupportedStatus()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An unsupported lifecycle status is rejected
        Initialize();

        CreateEDocument(EDocument, 'INV-STATUS', EDocument.Direction::Outgoing);
        asserterror ImportResponse('RESP-STATUS', EDocument."Document No.", 'REFUSED', '', '');
        Assert.ExpectedError('status REFUSED is not supported');
    end;

    [Test]
    procedure ImportResponseFailsForDuplicateResponseId()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The same lifecycle response cannot be imported twice
        Initialize();

        CreateEDocument(EDocument, 'INV-DUPLICATE', EDocument.Direction::Outgoing);
        ImportResponse('RESP-DUPLICATE', EDocument."Document No.", 'SUBMITTED', '', '');

        asserterror ImportResponse('RESP-DUPLICATE', EDocument."Document No.", 'SUBMITTED', '', '');
        Assert.ExpectedError('has already been imported');
    end;

    [Test]
    procedure ImportResponseFailsWithoutInvoiceId()
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A lifecycle response must contain InvoiceID
        Initialize();

        asserterror ImportXml('<CrossDomainAcknowledgementAndResponse><ExchangedDocument><ID>RESP-NO-INVOICE</ID></ExchangedDocument><Status>ACCEPTED</Status></CrossDomainAcknowledgementAndResponse>');
        Assert.ExpectedError('does not contain an InvoiceID');
    end;

    [Test]
    procedure ImportResponseFailsForAmbiguousInvoiceId()
    var
        FirstEDocument: Record "E-Document";
        SecondEDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A lifecycle response cannot be linked when InvoiceID is ambiguous
        Initialize();

        CreateEDocument(FirstEDocument, 'INV-AMBIGUOUS', FirstEDocument.Direction::Outgoing);
        CreateEDocument(SecondEDocument, 'INV-AMBIGUOUS', SecondEDocument.Direction::Outgoing);

        asserterror ImportResponse('RESP-AMBIGUOUS', FirstEDocument."Document No.", 'ACCEPTED', '', '');
        Assert.ExpectedError('More than one outgoing E-Document was found');
    end;

    [Test]
    procedure ImportResponseDoesNotCreatePaymentLifecycle()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Incoming status responses do not create payment lifecycle occurrences
        Initialize();

        CreateEDocument(EDocument, 'INV-NO-PAYMENT', EDocument.Direction::Outgoing);
        ImportResponse('RESP-NO-PAYMENT', EDocument."Document No.", 'ACCEPTED', '', '');

        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.IsTrue(FREInvoiceLifecycle.IsEmpty(), 'Incoming lifecycle responses must not create payment occurrences.');
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
    begin
        FREInvoiceLifecycleResponse.DeleteAll();
        FREInvoiceLifecycle.DeleteAll();
        EDocument.DeleteAll();
    end;

    local procedure VerifyImportedResponse(StatusText: Text; ExpectedResponseType: Enum "E-Doc. Response Type")
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleResponse: Record "FR E-Invoice Lifecycle Resp.";
        ResponseEntryNo: Integer;
    begin
        CreateEDocument(EDocument, CopyStr('INV-' + StatusText, 1, MaxStrLen(EDocument."Document No.")), EDocument.Direction::Outgoing);
        ResponseEntryNo := ImportResponse('RESP-' + StatusText, EDocument."Document No.", StatusText, '', '');

        FREInvoiceLifecycleResponse.Get(ResponseEntryNo);
        Assert.AreEqual(ExpectedResponseType, FREInvoiceLifecycleResponse."Response Type", 'The lifecycle response type is incorrect.');
        Assert.AreEqual(EDocument."Entry No", FREInvoiceLifecycleResponse."E-Document Entry No.", 'The response must be linked to the matching invoice.');
        Assert.IsTrue(FREInvoiceLifecycleResponse."E-Document Message Entry No." > 0, 'An incoming child message must be created.');
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document"; DocumentNo: Code[20]; Direction: Enum "E-Document Direction")
    begin
        EDocument.Init();
        EDocument."Document No." := DocumentNo;
        EDocument.Direction := Direction;
        EDocument.Insert();
    end;

    local procedure ImportResponse(ResponseID: Text; InvoiceID: Text; StatusText: Text; ReasonCode: Text; ReasonDescription: Text): Integer
    begin
        exit(ImportXml(CreateResponseXml(ResponseID, InvoiceID, StatusText, ReasonCode, ReasonDescription)));
    end;

    local procedure ImportXml(XmlText: Text): Integer
    var
        FREInvoiceLifecycleImport: Codeunit "FR E-Invoice Lifecycle Import";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XmlText);
        exit(FREInvoiceLifecycleImport.ImportResponse(TempBlob));
    end;

    local procedure CreateResponseXml(ResponseID: Text; InvoiceID: Text; StatusText: Text; ReasonCode: Text; ReasonDescription: Text): Text
    begin
        exit(
            '<rsm:CrossDomainAcknowledgementAndResponse xmlns:rsm="urn:fr:lifecycle" xmlns:ram="urn:fr:ram">' +
            '<rsm:ExchangedDocument><ram:ID>' + ResponseID + '</ram:ID></rsm:ExchangedDocument>' +
            '<rsm:AcknowledgementDocument><ram:InvoiceID>' + InvoiceID + '</ram:InvoiceID>' +
            '<ram:Status>' + StatusText + '</ram:Status>' +
            '<ram:ReasonCode>' + ReasonCode + '</ram:ReasonCode>' +
            '<ram:ReasonDescription>' + ReasonDescription + '</ram:ReasonDescription>' +
            '</rsm:AcknowledgementDocument></rsm:CrossDomainAcknowledgementAndResponse>');
    end;

    local procedure ReadPayload(TempBlob: Codeunit "Temp Blob"): Text
    var
        InStream: InStream;
        PayloadText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(PayloadText);
        exit(PayloadText);
    end;
}