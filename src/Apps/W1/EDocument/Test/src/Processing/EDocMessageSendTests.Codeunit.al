// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 139899 "E-Doc. Message Send Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        EDocMessageMock: Codeunit "E-Doc. Message Mock";
        Assert: Codeunit Assert;

    [Test]
    procedure CreateMessagePreservesExplicitServiceAndPayload()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        StoredPayload: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Creating a message preserves its explicit service and payload
        Initialize();

        // [GIVEN] E-Document "ED", message service "S", and payload "P"
        CreateEDocumentAndService(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock");
        CreatePayload(TempBlob, 'PAYLOAD');

        // [WHEN] An outgoing message is created for "S"
        MessageEntryNo := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing, EDocumentService.Code, TempBlob);

        // [THEN] The message retains "S" and payload "P"
        EDocMessage.Get(MessageEntryNo);
        EDocumentMessageAPI.GetMessageBlob(MessageEntryNo, StoredPayload);
        Assert.AreEqual(EDocumentService.Code, EDocMessage.Service, 'The explicit service must be retained.');
        Assert.AreEqual('PAYLOAD', ReadPayload(StoredPayload), 'The message payload must be retained.');
    end;

    [Test]
    procedure SendMessageCompletesSynchronously()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A synchronous message transport completes the child message
        Initialize();

        // [GIVEN] Outgoing message "M" with synchronous message transport
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Outgoing, true);

        // [WHEN] Message "M" is sent
        EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The transport receives the message context and "M" becomes Sent
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'A synchronously completed message must be sent.');
        Assert.AreEqual(EDocument."Entry No", EDocMessageMock.GetLastEDocumentEntryNo(), 'The parent E-Document must be provided to the transport.');
        Assert.AreEqual(EDocumentService.Code, EDocMessageMock.GetLastServiceCode(), 'The selected service must be provided to the transport.');
        Assert.AreEqual(MessageEntryNo, EDocMessageMock.GetLastMessageEntryNo(), 'The message entry must be provided to the transport.');
        Assert.AreEqual('PAYLOAD', EDocMessageMock.GetLastPayload(), 'The message payload must be provided to the transport.');
        Assert.AreEqual(1, EDocMessageMock.GetSendCount(), 'The message must be sent once.');
    end;

    [Test]
    procedure SendMessageStartsAsynchronousProcessing()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An asynchronous message transport leaves the child message pending
        Initialize();

        // [GIVEN] Outgoing message "M" whose transport returns Pending Response
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Outgoing, true);
        EDocMessageMock.SetSendStatus("E-Document Service Status"::"Pending Response");

        // [WHEN] Message "M" is sent
        EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] Message "M" remains pending for an asynchronous response
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::"Pending Response", EDocMessage.Status, 'An asynchronous message must remain pending.');
    end;

    [Test]
    procedure GetMessageResponseRemainsPending()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An incomplete asynchronous response keeps the same message pending
        Initialize();

        // [GIVEN] Message "M" awaiting an asynchronous response
        MessageEntryNo := CreatePendingMessage(EDocument, EDocumentService);

        // [WHEN] The transport reports that the response is still pending
        EDocumentMessageAPI.GetMessageResponse(MessageEntryNo);

        // [THEN] The same message remains pending
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::"Pending Response", EDocMessage.Status, 'An incomplete response must keep the message pending.');
        Assert.AreEqual(MessageEntryNo, EDocMessageMock.GetLastMessageEntryNo(), 'The response must target the original message.');
        Assert.AreEqual(1, EDocMessageMock.GetResponseCount(), 'The response transport must be called once.');
    end;

    [Test]
    procedure GetMessageResponseCompletesSameMessage()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A completed asynchronous response sends the same child message
        Initialize();

        // [GIVEN] Message "M" awaiting an asynchronous response that is now complete
        MessageEntryNo := CreatePendingMessage(EDocument, EDocumentService);
        EDocMessageMock.SetResponseStatus("E-Document Service Status"::Sent);

        // [WHEN] The response for message "M" is retrieved
        EDocumentMessageAPI.GetMessageResponse(MessageEntryNo);

        // [THEN] The same message becomes Sent
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'A completed response must send the message.');
        Assert.AreEqual(MessageEntryNo, EDocMessageMock.GetLastMessageEntryNo(), 'The response must complete the original message.');
    end;

    [Test]
    procedure SendMessageRejectsIncomingMessage()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An incoming message cannot be sent
        Initialize();

        // [GIVEN] Incoming message "M"
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Incoming, true);

        // [WHEN] Message "M" is sent
        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The direction validation fails
        Assert.ExpectedError('Direction must be equal to');
    end;

    [Test]
    procedure SendMessageRejectsAlreadySentMessage()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A sent message cannot be sent again
        Initialize();

        // [GIVEN] Outgoing message "M" that has already been sent
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Outgoing, true);
        EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [WHEN] Message "M" is sent again
        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The status validation fails
        Assert.ExpectedError('Status must be equal to');
    end;

    [Test]
    procedure SendMessageRejectsEmptyPayload()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A message without a payload cannot be sent
        Initialize();

        // [GIVEN] Outgoing message "M" without a payload
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Outgoing, false);

        // [WHEN] Message "M" is sent
        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The missing payload error is raised
        Assert.ExpectedError('does not contain a payload');
    end;

    [Test]
    procedure SendMessageRejectsMissingIntegration()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A service without an integration cannot send a message
        Initialize();

        // [GIVEN] Outgoing message "M" for a service without an integration
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"No Integration", "E-Document Direction"::Outgoing, true);

        // [WHEN] Message "M" is sent
        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The missing integration error is raised
        Assert.ExpectedError('does not have an integration configured');
    end;

    [Test]
    procedure SendMessageRejectsUnsupportedIntegration()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A document-only integration cannot send a message
        Initialize();

        // [GIVEN] Outgoing message "M" for a document-only integration
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Mock Sync", "E-Document Direction"::Outgoing, true);

        // [WHEN] Message "M" is sent
        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        // [THEN] The unsupported message transport error is raised
        Assert.ExpectedError('does not support sending E-Document messages');
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocMessage: Record "E-Document Message";
        EDocDataStorage: Record "E-Doc. Data Storage";
    begin
        EDocMessageMock.Reset();
        EDocMessage.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocument.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();
    end;

    local procedure CreateMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ServiceIntegration: Enum "Service Integration"; Direction: Enum "E-Document Direction"; HasPayload: Boolean): Integer
    var
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
    begin
        CreateEDocumentAndService(EDocument, EDocumentService, ServiceIntegration);
        if HasPayload then
            CreatePayload(TempBlob, 'PAYLOAD');
        exit(EDocumentMessageAPI.CreateMessage(EDocument, "E-Document Message Type"::Unknown, Direction, EDocumentService.Code, TempBlob));
    end;

    local procedure CreatePendingMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"): Integer
    var
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        MessageEntryNo := CreateMessage(EDocument, EDocumentService, Enum::"Service Integration"::"Message Mock", "E-Document Direction"::Outgoing, true);
        EDocMessageMock.SetSendStatus("E-Document Service Status"::"Pending Response");
        EDocumentMessageAPI.SendMessage(MessageEntryNo);
        exit(MessageEntryNo);
    end;

    local procedure CreateEDocumentAndService(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ServiceIntegration: Enum "Service Integration")
    begin
        EDocumentService.Code := CopyStr(CreateGuid(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Service Integration V2" := ServiceIntegration;
        EDocumentService.Insert();

        EDocument.Init();
        EDocument."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument.Insert();
    end;

    local procedure CreatePayload(var TempBlob: Codeunit "Temp Blob"; PayloadText: Text)
    var
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(PayloadText);
    end;

    local procedure ReadPayload(TempBlob: Codeunit "Temp Blob"): Text
    var
        InStream: InStream;
        PayloadText: Text;
    begin
        TempBlob.CreateInStream(InStream);
        InStream.ReadText(PayloadText);
        exit(PayloadText);
    end;
}