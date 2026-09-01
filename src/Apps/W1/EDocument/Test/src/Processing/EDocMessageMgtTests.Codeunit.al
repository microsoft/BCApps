// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Threading;
using System.Utilities;

codeunit 139898 "E-Doc. Message Mgt. Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure QueueMessageSchedulesBackgroundSend()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Queueing an outgoing E-Document message schedules its background send job
        Initialize(Customer);

        // [GIVEN] A created outgoing E-Document message
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);

        // [WHEN] The message is queued
        EDocMessageMgt.QueueMessage(MessageEntryNo);

        // [THEN] The message is marked Queued and a send job is scheduled for it
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Message Status"::Queued, EDocMessage.Status, 'The message must be queued.');
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Send Job");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RetryMessageRequeuesExistingMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        DataStorageEntryNo: Integer;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647423] Retrying a failed outgoing message requeues the existing message without duplication
        Initialize(Customer);

        // [GIVEN] A failed outgoing E-Document message with a stored payload
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::Error;
        EDocMessage."Last Error" := 'Temporary transport failure';
        EDocMessage.Modify();
        DataStorageEntryNo := EDocMessage."Data Storage Entry No.";

        // [WHEN] The failed message is retried
        EDocumentMessageAPI.RetryMessage(MessageEntryNo);

        // [THEN] The same message and payload are queued with one background send job
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Message Status"::Queued, EDocMessage.Status, 'The existing message must be requeued.');
        Assert.AreEqual(DataStorageEntryNo, EDocMessage."Data Storage Entry No.", 'Retry must reuse the stored message payload.');
        Assert.RecordCount(EDocMessage, 1);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Send Job");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [Test]
    procedure RetryMessageRejectsMessageWithoutError()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647423] Retry rejects an outgoing message that is not in Error status
        Initialize(Customer);

        // [GIVEN] A newly created outgoing E-Document message
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);

        // [WHEN] The message is retried
        asserterror EDocumentMessageAPI.RetryMessage(MessageEntryNo);

        // [THEN] Retry is rejected because the message has not failed
        Assert.ExpectedError('Status must be equal to ''Error''');
    end;

    [Test]
    procedure RetryMessageRejectsIncomingMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647423] Retry rejects a failed incoming message
        Initialize(Customer);

        // [GIVEN] A failed incoming E-Document message
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Incoming,
            "E-Doc. Response Type"::None, TempBlob);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::Error;
        EDocMessage.Modify();

        // [WHEN] The incoming message is retried
        asserterror EDocumentMessageAPI.RetryMessage(MessageEntryNo);

        // [THEN] Retry is rejected because only outgoing messages can be sent
        Assert.ExpectedError('Direction must be equal to ''Outgoing''');
    end;

    [Test]
    procedure PollMessageResponseCompletesPendingMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A completed asynchronous response marks the existing child message as Sent.
        Initialize(Customer);

        // [GIVEN] An outgoing child message waiting for a connector response
        CreateOutgoingEDocument(EDocument);
        MessageEntryNo := CreatePendingMessage(EDocument);
        BindSubscription(EDocImplState);
        EDocImplState.SetOnGetResponseSuccess();

        // [WHEN] The connector reports that the response is complete
        EDocumentMessageAPI.PollMessageResponse(MessageEntryNo);
        UnbindSubscription(EDocImplState);

        // [THEN] The existing child message is marked Sent
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'The completed message must be Sent.');
        Assert.AreNotEqual(0DT, EDocMessage."Last Attempt At", 'The polling attempt time must be stored.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PollMessageResponseReschedulesPendingMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An incomplete asynchronous response remains pending and schedules another poll.
        Initialize(Customer);

        // [GIVEN] An outgoing child message waiting for a connector response
        CreateOutgoingEDocument(EDocument);
        MessageEntryNo := CreatePendingMessage(EDocument);
        BindSubscription(EDocImplState);

        // [WHEN] The connector reports that the response is still pending
        EDocumentMessageAPI.PollMessageResponse(MessageEntryNo);
        UnbindSubscription(EDocImplState);

        // [THEN] The message remains pending and one response job is scheduled
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::"Pending Response", EDocMessage.Status, 'The message must remain pending.');
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Response Job");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PollMessageResponseJobStoresConnectorError()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocumentIntegrationLog: Record "E-Document Integration Log";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A connector polling failure is persisted on the existing child message.
        Initialize(Customer);

        // [GIVEN] A pending child message and a connector that raises a runtime error
        CreateOutgoingEDocument(EDocument);
        MessageEntryNo := CreatePendingMessage(EDocument);
        EDocMessage.Get(MessageEntryNo);
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        BindSubscription(EDocImplState);
        EDocImplState.SetEnableHttpData();
        EDocImplState.SetThrowIntegrationRuntimeError();
        Commit();

        // [WHEN] The response polling background job runs
        Assert.IsFalse(Codeunit.Run(Codeunit::"E-Doc. Message Response Job", JobQueueEntry), 'The polling job must report the connector failure.');
        UnbindSubscription(EDocImplState);

        // [THEN] The existing message contains response-error diagnostics
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::"Response Error", EDocMessage.Status, 'The message must have a response error.');
        Assert.AreEqual(1, EDocMessage."Retry Count", 'The failed polling attempt must increment the retry count.');
        Assert.IsTrue(EDocMessage."Last Error".Contains('TEST'), 'The connector error must be stored.');
        EDocumentIntegrationLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        Assert.RecordCount(EDocumentIntegrationLog, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SendMessageJobStoresConnectorErrorAndIntegrationLog()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocumentIntegrationLog: Record "E-Document Integration Log";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647423] A failed child-message send retains diagnostics and the HTTP exchange
        Initialize(Customer);

        // [GIVEN] Queued message "M" and a connector that records HTTP data before failing
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::Queued;
        EDocMessage.Modify();
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        BindSubscription(EDocImplState);
        EDocImplState.SetEnableHttpData();
        EDocImplState.SetThrowIntegrationRuntimeError();
        Commit();

        // [WHEN] The message send background job runs
        Assert.IsFalse(Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry), 'The send job must report the connector failure.');
        UnbindSubscription(EDocImplState);

        // [THEN] Message "M" contains diagnostics and its HTTP exchange is retained
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::Error, EDocMessage.Status, 'The message must have a send error.');
        Assert.AreEqual(1, EDocMessage."Retry Count", 'The failed send attempt must increment the retry count.');
        Assert.IsTrue(EDocMessage."Last Error".Contains('TEST'), 'The connector error must be stored.');
        EDocumentIntegrationLog.SetRange("E-Doc. Entry No", EDocument."Entry No");
        Assert.RecordCount(EDocumentIntegrationLog, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RetryMessageReschedulesFailedResponsePoll()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Retrying a response error schedules polling instead of resending the child message.
        Initialize(Customer);

        // [GIVEN] An outgoing child message whose response polling failed
        CreateOutgoingEDocument(EDocument);
        MessageEntryNo := CreatePendingMessage(EDocument);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::"Response Error";
        EDocMessage.Modify();

        // [WHEN] The failed message is retried
        EDocumentMessageAPI.RetryMessage(MessageEntryNo);

        // [THEN] The message is pending and only a response polling job is scheduled
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual(EDocMessage.Status::"Pending Response", EDocMessage.Status, 'Retry must restore Pending Response status.');
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Response Job");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Send Job");
        Assert.RecordCount(JobQueueEntry, 0);
    end;

    [Test]
    procedure PaymentOccurrenceDispatcherProcessesPendingCapture()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceDispatcher: Codeunit "E-Doc. Payment Occ. Dispatcher";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The recurrent dispatcher processes a pending payment occurrence
        Initialize(Customer);

        // [GIVEN] An outgoing invoice E-Document and a payment application
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The payment application is captured
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);

        // [THEN] The occurrence remains pending for the dispatcher without retry metadata
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        Assert.AreEqual(EDocPaymentOccurrence.Status::Pending, EDocPaymentOccurrence.Status, 'A captured occurrence must remain pending for the dispatcher.');
        Assert.AreEqual(0, EDocPaymentOccurrence."Retry Count", 'A pending occurrence must not have a retry count.');
        Assert.AreEqual('', EDocPaymentOccurrence."Last Error", 'A pending occurrence must not contain an error.');

        // [WHEN] The recurrent dispatcher runs
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] The occurrence is processed
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'The dispatcher must process a pending occurrence.');
    end;

    [Test]
    procedure PaymentOccurrenceDispatcherRetriesFailedProcessing()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceDispatcher: Codeunit "E-Doc. Payment Occ. Dispatcher";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A failed payment occurrence is retained and processed by the dispatcher retry
        Initialize(Customer);

        // [GIVEN] A persisted payment occurrence whose localization processing fails
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocImplState.SetThrowPaymentOccurrenceProcessingError();
        BindSubscription(EDocImplState);
        EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);
        UnbindSubscription(EDocImplState);
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status, 'Failed processing must leave the occurrence in Error.');
        Assert.AreEqual(1, EDocPaymentOccurrence."Retry Count", 'Failed processing must increment the retry count.');
        EDocPaymentOccurrence."Next Attempt At" := 0DT;
        EDocPaymentOccurrence.Modify();

        // [WHEN] The recurrent dispatcher retries the occurrence
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] The occurrence is marked processed and its error is cleared
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'A successful retry must mark the occurrence Processed.');
        Assert.AreEqual('', EDocPaymentOccurrence."Last Error", 'A successful retry must clear the previous error.');
    end;

    local procedure Initialize(var Customer: Record Customer)
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if UnbindSubscription(EDocImplState) then;
        Clear(EDocImplState);
        LibraryLowerPermission.SetOutsideO365Scope();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2', Codeunit::"E-Doc. Message Send Job", Codeunit::"E-Doc. Message Response Job");
        JobQueueEntry.DeleteAll();
        EDocMessage.DeleteAll();
        EDocPaymentOccurrence.DeleteAll();
        EDocument.DeleteAll();

        if not IsInitialized then begin
            LibraryEDoc.SetupStandardVAT();
            IsInitialized := true;
        end;

        EDocumentService.DeleteAll();
        LibraryEDoc.SetupStandardSalesScenario(
            Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
    end;

    local procedure CreatePaymentOccurrenceScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(SalesInvoiceHeader."No."));
        SalesInvoiceHeader.Insert();
        EDocument.Init();
        EDocument."Document No." := SalesInvoiceHeader."No.";
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Insert();
        InvoiceCustLedgerEntry.Init();
        InvoiceCustLedgerEntry."Entry No." := GetUnusedCustLedgerEntryNo();
        InvoiceCustLedgerEntry."Document Type" := InvoiceCustLedgerEntry."Document Type"::Invoice;
        InvoiceCustLedgerEntry."Document No." := SalesInvoiceHeader."No.";
        InvoiceCustLedgerEntry.Insert();
        PaymentCustLedgerEntry.Init();
        PaymentCustLedgerEntry."Entry No." := GetUnusedCustLedgerEntryNo();
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry.Insert();
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := GetUnusedDetailedCustLedgerEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := InvoiceCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := PaymentCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Amount := -100;
        DetailedCustLedgEntry.SystemId := CreateGuid();
        DetailedCustLedgEntry.Insert();
    end;

    local procedure GetUnusedCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryNo: Integer;
    begin
        EntryNo := -1;
        while CustLedgerEntry.Get(EntryNo) do
            EntryNo -= 1;
        exit(EntryNo);
    end;

    local procedure GetUnusedDetailedCustLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EntryNo: Integer;
    begin
        EntryNo := -1;
        while DetailedCustLedgEntry.Get(EntryNo) do
            EntryNo -= 1;
        exit(EntryNo);
    end;

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument.Insert();
    end;

    local procedure CreatePendingMessage(EDocument: Record "E-Document"): Integer
    var
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::Unknown, "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);
        EDocMessage.Get(MessageEntryNo);
        EDocMessage.Status := EDocMessage.Status::"Pending Response";
        EDocMessage.Modify();
        exit(MessageEntryNo);
    end;
}
