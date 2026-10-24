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
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Threading;
using System.Upgrade;
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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
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
        EDocImplState.EnableMessageTelemetry();
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
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000LC8'), 'Emit exactly one polling failure.');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000LC7'), 'A polling failure is not a send failure.');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000W3L'), 'A connector failure is not a scheduling failure.');
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
        EDocImplState.EnableMessageTelemetry();
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
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000LC7'), 'Emit exactly one send failure.');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000LC8'), 'A send failure is not a polling failure.');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000W3L'), 'A connector failure is not a scheduling failure.');
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
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EnsurePaymentOccurrenceDispatcherSchedulesSingleJob()
    var
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentBackgroundJobs: Codeunit "E-Document Background Jobs";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Payment occurrence dispatcher setup is idempotent
        Initialize(Customer);

        // [WHEN] Dispatcher setup runs more than once
        EDocumentBackgroundJobs.EnsurePaymentOccurrenceDispatcher();
        EDocumentBackgroundJobs.EnsurePaymentOccurrenceDispatcher();

        // [THEN] A single dispatcher job is scheduled
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Payment Occ. Dispatcher");
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PaymentOccurrenceDispatcherUpgradeRunsOnlyOnce()
    var
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentUpgrade: Codeunit "E-Document Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Dispatcher provisioning runs once and does not recreate a removed job on later upgrades
        Initialize(Customer);
        UpgradeTagLibrary.DeleteUpgradeTag(EDocumentUpgrade.GetPaymentOccurrenceDispatcherUpgradeTag(), CopyStr(CompanyName(), 1, 30));

        // [WHEN] The dispatcher provisioning upgrade runs
        EDocumentUpgrade.UpgradePaymentOccurrenceDispatcher();

        // [THEN] A single dispatcher job is scheduled and the upgrade tag is set
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Payment Occ. Dispatcher");
        Assert.RecordCount(JobQueueEntry, 1);
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(EDocumentUpgrade.GetPaymentOccurrenceDispatcherUpgradeTag()), 'Dispatcher provisioning must set its upgrade tag.');

        // [GIVEN] The dispatcher job is removed after provisioning
        JobQueueEntry.DeleteAll();

        // [WHEN] The dispatcher provisioning upgrade runs again
        EDocumentUpgrade.UpgradePaymentOccurrenceDispatcher();

        // [THEN] The completed upgrade does not recreate the removed job
        Assert.RecordCount(JobQueueEntry, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
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
    [TransactionModel(TransactionModel::AutoCommit)]
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

        // [GIVEN] A payment occurrence that failed during localization processing
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocImplState.SetThrowPaymentOccurrenceProcessingError();
        BindSubscription(EDocImplState);
        EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);
        UnbindSubscription(EDocImplState);
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::"Retry Pending", EDocPaymentOccurrence.Status, 'Failed processing must schedule the occurrence for retry.');
        Assert.AreEqual(1, EDocPaymentOccurrence."Retry Count", 'Failed processing must increment the retry count.');
        Assert.IsTrue(EDocPaymentOccurrence."Next Attempt At" > EDocPaymentOccurrence."Last Attempt At", 'Failed processing must schedule a future retry.');
        Assert.AreNotEqual('', EDocPaymentOccurrence."Last Error", 'Failed processing must retain the processing error.');
        EDocPaymentOccurrence."Next Attempt At" := 0DT;
        EDocPaymentOccurrence.Modify();

        // [WHEN] The recurrent dispatcher retries the occurrence
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] The occurrence is marked processed and its error is cleared
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'A successful retry must mark the occurrence Processed.');
        Assert.AreEqual('', EDocPaymentOccurrence."Last Error", 'A successful retry must clear the previous error.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PaymentOccurrenceStopsAutomaticRetriesAfterFiveFailures()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceDispatcher: Codeunit "E-Doc. Payment Occ. Dispatcher";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A payment occurrence requiring action stops retrying automatically after five failures
        Initialize(Customer);

        // [GIVEN] A payment occurrence that has failed four times
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocPaymentOccurrence."Retry Count" := 4;
        EDocPaymentOccurrence.Modify();
        EDocImplState.SetThrowPaymentOccurrenceProcessingError();
        BindSubscription(EDocImplState);

        // [WHEN] Processing the occurrence fails for the fifth time
        EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);

        UnbindSubscription(EDocImplState);

        // [THEN] The occurrence requires user action and has no automatic retry
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status, 'The fifth failure must require user action.');
        Assert.AreEqual(5, EDocPaymentOccurrence."Retry Count", 'The fifth failure must be retained.');
        Assert.AreEqual(0DT, EDocPaymentOccurrence."Next Attempt At", 'An action-required occurrence must not have an automatic retry time.');
        Assert.AreNotEqual('', EDocPaymentOccurrence."Last Error", 'The fifth failure must retain the processing error.');

        // [WHEN] The recurrent dispatcher runs
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] The action-required occurrence is not processed again
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status, 'The dispatcher must not process action-required occurrences.');
        Assert.AreEqual(5, EDocPaymentOccurrence."Retry Count", 'The dispatcher must not increment the retry count of an action-required occurrence.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ManualPaymentOccurrenceRetrySucceedsWithoutResettingHistory()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A corrected action-required occurrence can be retried manually
        Initialize(Customer);

        // [GIVEN] An action-required payment occurrence with five failed attempts
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Error;
        EDocPaymentOccurrence."Retry Count" := 5;
        EDocPaymentOccurrence."Last Error" := 'Previous error';
        EDocPaymentOccurrence.Modify();

        // [WHEN] The occurrence is retried manually after the processing issue is corrected
        EDocPaymentOccurrenceMgt.RetryPaymentOccurrence(EDocPaymentOccurrence."Entry No.");

        // [THEN] The occurrence is processed without resetting its failure history
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'The corrected occurrence must be processed.');
        Assert.AreEqual(5, EDocPaymentOccurrence."Retry Count", 'Successful processing must retain the failure history.');
        Assert.AreEqual('', EDocPaymentOccurrence."Last Error", 'Successful processing must clear the previous error.');
        Assert.AreEqual(0DT, EDocPaymentOccurrence."Next Attempt At", 'Successful processing must clear the next attempt time.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedManualPaymentOccurrenceRetryPreservesAutomaticRetryBudget()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A failed manual retry preserves the remaining automatic retry budget
        Initialize(Customer);

        // [GIVEN] A retry-pending payment occurrence with automatic attempts remaining
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::"Retry Pending";
        EDocPaymentOccurrence."Retry Count" := 1;
        EDocPaymentOccurrence."Next Attempt At" := CurrentDateTime() + 1800000;
        EDocPaymentOccurrence.Modify();
        EDocImplState.SetThrowPaymentOccurrenceProcessingError();
        BindSubscription(EDocImplState);

        // [WHEN] The occurrence is retried manually before its scheduled attempt
        EDocPaymentOccurrenceMgt.RetryPaymentOccurrence(EDocPaymentOccurrence."Entry No.");

        UnbindSubscription(EDocImplState);

        // [THEN] The failed attempt remains pending for the next automatic retry
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::"Retry Pending", EDocPaymentOccurrence.Status, 'A failed manual retry must preserve remaining automatic retries.');
        Assert.AreEqual(2, EDocPaymentOccurrence."Retry Count", 'A failed manual retry must be included in failure history.');
        Assert.IsTrue(EDocPaymentOccurrence."Next Attempt At" > EDocPaymentOccurrence."Last Attempt At", 'A failed manual retry must schedule the next automatic attempt.');
        Assert.AreNotEqual('', EDocPaymentOccurrence."Last Error", 'A failed manual retry must retain the processing error.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedManualPaymentOccurrenceRetryRemainsActionRequired()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A failed manual retry does not restart automatic retries
        Initialize(Customer);

        // [GIVEN] An action-required payment occurrence whose processing issue persists
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Error;
        EDocPaymentOccurrence."Retry Count" := 5;
        EDocPaymentOccurrence.Modify();
        EDocImplState.SetThrowPaymentOccurrenceProcessingError();
        BindSubscription(EDocImplState);

        // [WHEN] The occurrence is retried manually
        EDocPaymentOccurrenceMgt.RetryPaymentOccurrence(EDocPaymentOccurrence."Entry No.");

        UnbindSubscription(EDocImplState);

        // [THEN] The occurrence still requires user action and has no automatic retry
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Error, EDocPaymentOccurrence.Status, 'A failed manual retry must still require user action.');
        Assert.AreEqual(6, EDocPaymentOccurrence."Retry Count", 'A failed manual retry must be included in failure history.');
        Assert.AreEqual(0DT, EDocPaymentOccurrence."Next Attempt At", 'A failed manual retry must not schedule automatic processing.');
        Assert.AreNotEqual('', EDocPaymentOccurrence."Last Error", 'A failed manual retry must retain the processing error.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PaymentOccurrenceDispatcherHonorsBatchLimit()
    var
        Customer: Record Customer;
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceDispatcher: Codeunit "E-Doc. Payment Occ. Dispatcher";
        Index: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] One dispatcher invocation processes at most one hundred payment occurrences
        Initialize(Customer);

        // [GIVEN] One hundred and one pending payment occurrences for an outgoing E-Document
        CreateOutgoingEDocument(EDocument);
        for Index := 1 to 101 do begin
            EDocPaymentOccurrence.Init();
            EDocPaymentOccurrence."Entry No." := 0;
            EDocPaymentOccurrence."E-Document Entry No." := EDocument."Entry No";
            EDocPaymentOccurrence."Source Occurrence ID" := CreateGuid();
            EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Pending;
            EDocPaymentOccurrence.Insert();
        end;

        // [WHEN] The recurrent dispatcher runs once
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] One hundred occurrences are processed and one remains pending
        EDocPaymentOccurrence.SetRange(Status, EDocPaymentOccurrence.Status::Processed);
        Assert.RecordCount(EDocPaymentOccurrence, 100);
        EDocPaymentOccurrence.SetRange(Status, EDocPaymentOccurrence.Status::Pending);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PaymentOccurrenceDispatcherProcessesEveryDueStatusUnderLoad()
    var
        Customer: Record Customer;
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceDispatcher: Codeunit "E-Doc. Payment Occ. Dispatcher";
        ExpiredProcessingEntryNo: Integer;
        RetryPendingEntryNo: Integer;
        Index: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Due retries and expired processing leases progress when the pending backlog exceeds the batch limit
        Initialize(Customer);

        // [GIVEN] One hundred and one pending occurrences, one due retry, and one expired processing lease
        CreateOutgoingEDocument(EDocument);
        for Index := 1 to 101 do
            CreatePaymentOccurrence(EDocument."Entry No", EDocPaymentOccurrence.Status::Pending, 0DT);
        RetryPendingEntryNo :=
            CreatePaymentOccurrence(EDocument."Entry No", EDocPaymentOccurrence.Status::"Retry Pending", CurrentDateTime() - 1);
        ExpiredProcessingEntryNo :=
            CreatePaymentOccurrence(EDocument."Entry No", EDocPaymentOccurrence.Status::Processing, CurrentDateTime() - 1);

        // [WHEN] The recurrent dispatcher runs once
        EDocPaymentOccurrenceDispatcher.Run();

        // [THEN] Both recovery classes make progress without exceeding the one-hundred occurrence limit
        EDocPaymentOccurrence.Get(RetryPendingEntryNo);
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'The due retry must be processed.');
        EDocPaymentOccurrence.Get(ExpiredProcessingEntryNo);
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processed, EDocPaymentOccurrence.Status, 'The expired processing lease must be recovered.');
        EDocPaymentOccurrence.Reset();
        EDocPaymentOccurrence.SetRange(Status, EDocPaymentOccurrence.Status::Processed);
        Assert.RecordCount(EDocPaymentOccurrence, 100);
        EDocPaymentOccurrence.SetRange(Status, EDocPaymentOccurrence.Status::Pending);
        Assert.RecordCount(EDocPaymentOccurrence, 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ActivePaymentOccurrenceLeasePreventsConcurrentProcessing()
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocument: Record "E-Document";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
        LeaseExpiresAt: DateTime;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An active processing lease prevents duplicate payment occurrence processing
        Initialize(Customer);

        // [GIVEN] A payment occurrence with an active processing lease
        CreatePaymentOccurrenceScenario(EDocument, DetailedCustLedgEntry);
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.FindFirst();
        LeaseExpiresAt := CurrentDateTime() + 1800000;
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Processing;
        EDocPaymentOccurrence."Next Attempt At" := LeaseExpiresAt;
        EDocPaymentOccurrence.Modify();

        // [WHEN] The occurrence is selected for processing again
        EDocPaymentOccurrenceMgt.ProcessPaymentOccurrence(EDocPaymentOccurrence);

        // [THEN] The active processing lease is preserved
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        Assert.AreEqual(EDocPaymentOccurrence.Status::Processing, EDocPaymentOccurrence.Status, 'An active lease must retain the processing state.');
        Assert.AreEqual(LeaseExpiresAt, EDocPaymentOccurrence."Next Attempt At", 'An active lease must not be changed.');
        Assert.AreEqual(0, EDocPaymentOccurrence."Retry Count", 'An active lease must prevent another processing attempt.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure QueueMessagePreparationFailureIsRetryable()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Preparation failure persists a retryable error on the original message.
        Initialize(Customer);

        // [GIVEN] Message "M" and a scheduler that fails before enqueueing.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Created);
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Send Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);

        // [WHEN] Message "M" is queued.
        EDocumentMessageAPI.QueueMessage(EDocMessage."Entry No.");

        // [THEN] The same message remains recoverable and telemetry does not claim success.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::Error, 'SendScheduling', 'TEST SCHEDULING FAILURE');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure QueueMessageEnqueueFailureIsRetryable()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Enqueue failure has durable diagnostics without a scheduling-success event.
        Initialize(Customer);

        // [GIVEN] Message "M" whose job cannot be inserted.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Created);
        EDocImplState.SetEnqueueFailure(Codeunit::"E-Doc. Message Send Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);

        // [WHEN] Message "M" is queued.
        EDocumentMessageAPI.QueueMessage(EDocMessage."Entry No.");

        // [THEN] The same message retains the enqueue failure.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::Error, 'SendScheduling', 'TEST ENQUEUE FAILURE');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SendRetryPreparationFailureKeepsMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A failed manual send retry does not duplicate the child or payload.
        Initialize(Customer);

        // [GIVEN] Failed message "M" and a failing scheduler.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Send Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);

        // [WHEN] Sending is retried.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");

        // [THEN] Message "M" retains its payload and remains retryable.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::Error, 'SendScheduling', 'TEST SCHEDULING FAILURE');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ResponseRetryPreparationFailureKeepsResponseError()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A failed response retry never queues another send.
        Initialize(Customer);

        // [GIVEN] Response-error message "M" and a failing poll scheduler.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::"Response Error");
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Response Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);

        // [WHEN] Polling is retried.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");

        // [THEN] Message "M" remains a response error, with no send job.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::"Response Error", 'ResponseScheduling', 'TEST SCHEDULING FAILURE');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AcceptedSendWithPollingScheduleFailureKeepsResponseError()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Scheduling failure after an accepted send must not become a send error.
        Initialize(Customer);

        // [GIVEN] Queued message "M", an asynchronous connector, and a failing poll scheduler.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Queued);
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        EDocImplState.SetIsAsync();
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Response Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);
        Commit();

        // [WHEN] The send worker accepts the message and attempts to schedule its response.
        Assert.IsTrue(Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry), 'An accepted send must not be reported as a send failure.');

        // [THEN] Only response scheduling failed.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::"Response Error", 'ResponseScheduling', 'TEST SCHEDULING FAILURE');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000LC7'), 'Do not emit a send-failure event after an accepted send.');
        EDocImplState.SetSchedulingFailure(0);
        EDocImplState.SetOnGetResponseSuccess();
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        JobQueueEntry.FindFirst();
        Assert.AreEqual(Codeunit::"E-Doc. Message Response Job", JobQueueEntry."Object ID to Run", 'Retry must poll an already accepted send.');
        Commit();
        Assert.IsTrue(Codeunit.Run(Codeunit::"E-Doc. Message Response Job", JobQueueEntry), 'The repaired response worker must succeed.');
        Assert.AreEqual(1, EDocImplState.GetMessageSendCount(), 'Response recovery must never resend the accepted message.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PendingPollSchedulingFailureKeepsResponseError()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A pending poll whose next job cannot be scheduled remains recoverable.
        Initialize(Customer);

        // [GIVEN] Pending message "M" and a scheduler that cannot enqueue another poll.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::"Pending Response");
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Response Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);

        // [WHEN] The connector still has no response.
        EDocumentMessageAPI.PollMessageResponse(EDocMessage."Entry No.");

        // [THEN] The original message is a response error, never a new send.
        VerifySchedulingFailure(EDocument, EDocMessage, EDocMessage.Status::"Response Error", 'ResponseScheduling', 'TEST SCHEDULING FAILURE');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RepairedSchedulerRetriesOriginalMessage()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        OriginalDataStorageEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Repairing setup permits retry with truthful scheduling telemetry and the original payload.
        Initialize(Customer);

        // [GIVEN] Message "M" failed once during scheduling.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Created);
        OriginalDataStorageEntryNo := EDocMessage."Data Storage Entry No.";
        EDocImplState.SetSchedulingFailure(Codeunit::"E-Doc. Message Send Job");
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);
        EDocumentMessageAPI.QueueMessage(EDocMessage."Entry No.");
        EDocImplState.SetSchedulingFailure(0);

        // [WHEN] The user retries after setup is repaired.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");

        // [THEN] One actual job is scheduled for the same payload.
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.FindFirst();
        Assert.AreEqual(Format(JobQueueEntry.ID), EDocImplState.GetScheduledJobId(), 'Success telemetry must contain the persisted queue ID.');
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000LC6'), 'Only successful enqueue emits scheduling success.');
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual('TEST SCHEDULING FAILURE', EDocMessage."Last Error", 'Retry alone must retain the last diagnostic.');
        Commit();

        // [WHEN] The repaired send worker succeeds.
        Assert.IsTrue(Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry), 'The retry must send successfully.');

        // [THEN] Success clears the error without replacing the child or resetting its failure history.
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'The original message must be sent.');
        Assert.AreEqual('', EDocMessage."Last Error", 'Successful delivery must clear the last error.');
        Assert.AreEqual(1, EDocMessage."Retry Count", 'Successful delivery must retain failure history.');
        Assert.AreEqual(OriginalDataStorageEntryNo, EDocMessage."Data Storage Entry No.", 'Retry must retain the original payload.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure MessageErrorInfoRetainsServiceNavigation()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        MessageErrorInfo: ErrorInfo;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Raw connector errors retain safe classification and actionable service context.
        Initialize(Customer);

        // [GIVEN] Message "M" belongs to a configured service.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);

        // [WHEN] A connector error is wrapped for the user.
        MessageErrorInfo := EDocMessageMgt.CreateMessageErrorInfo(EDocMessage, 'Customer-specific diagnostic');

        // [THEN] The error retains its text and service navigation without classifying it as metadata.
        Assert.AreEqual(Format(DataClassification::CustomerContent), Format(MessageErrorInfo.DataClassification), 'Connector text is customer content.');
        Assert.IsTrue(EDocumentService.RecordId() = MessageErrorInfo.RecordId, 'The error must navigate to the message service.');
        Assert.AreEqual(Page::"E-Document Service", MessageErrorInfo.PageNo, 'The error must open the service setup.');
        Assert.AreEqual('Customer-specific diagnostic', MessageErrorInfo.Message, 'The connector diagnostic must be retained.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure MessageUserCanRetryAndRunResponseWorker()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        WorkerSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A basic user with message and job-queue roles can retry polling without SUPER or an extra response-runner grant.
        Initialize(Customer);

        // [GIVEN] Response-error message "M" and a connector with a completed response.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::"Response Error");
        EDocImplState.SetOnGetResponseSuccess();
        BindSubscription(EDocImplState);
        Commit();
        SetMessageUserPermissions();

        // [WHEN] The user retries polling and the scheduled response worker runs.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::"Pending Response", EDocMessage.Status, EDocMessage."Last Error");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        JobQueueEntry.FindFirst();
        Commit();
        WorkerSucceeded := Codeunit.Run(Codeunit::"E-Doc. Message Response Job", JobQueueEntry);
        LibraryLowerPermission.StopLoggingNAVPermissions();

        // [THEN] The original child is sent by a response job, not a new send job.
        Assert.IsTrue(WorkerSucceeded, 'The response worker must run with the normal message and job-queue roles.');
        Assert.AreEqual(Codeunit::"E-Doc. Message Response Job", JobQueueEntry."Object ID to Run", 'A response retry must not queue a send.');
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'Polling must complete the original child.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure MessageUserCanRetryAndRunSendWorker()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        WorkerSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A basic user with message and job-queue roles can retry sending without SUPER.
        Initialize(Customer);

        // [GIVEN] Failed message "M" and a functioning connector.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        BindSubscription(EDocImplState);
        Commit();
        SetMessageUserPermissions();

        // [WHEN] The user retries sending and the scheduled send worker runs.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Queued, EDocMessage.Status, EDocMessage."Last Error");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        JobQueueEntry.FindFirst();
        Commit();
        WorkerSucceeded := Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry);
        LibraryLowerPermission.StopLoggingNAVPermissions();

        // [THEN] The original child is sent using the normal roles.
        Assert.IsTrue(WorkerSucceeded, 'The send worker must run with the normal message and job-queue roles.');
        Assert.AreEqual(Codeunit::"E-Doc. Message Send Job", JobQueueEntry."Object ID to Run", 'A send retry must queue a send job.');
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Sent, EDocMessage.Status, 'Sending must complete the original child.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [HandlerFunctions('MessageServicePageHandler')]
    procedure MessageFactBoxOpensSelectedService()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocumentPage: TestPage "E-Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A failed message opens its own service configuration.
        Initialize(Customer);

        // [GIVEN] Failed message "M" is selected in the Messages FactBox.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.EDocMessages.GoToRecord(EDocMessage);

        // [WHEN] The user opens the message's service.
        EDocumentPage.EDocMessages.OpenService.Invoke();
        EDocumentPage.Close();

        // [THEN] The service page shows the selected message's service.
        Assert.AreEqual(EDocMessage.Service, LibraryVariableStorage.DequeueText(), 'Navigation must open the selected message service.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageIntegrationLogsPageHandler')]
    procedure MessageFactBoxFiltersIntegrationLogs()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        OtherEDocument: Record "E-Document";
        OtherService: Record "E-Document Service";
        EDocMessage: Record "E-Document Message";
        EDocumentIntegrationLog: Record "E-Document Integration Log";
        EDocumentPage: TestPage "E-Document";
        ExpectedLogEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Message diagnostics exclude logs for other parent documents and services.
        Initialize(Customer);

        // [GIVEN] Message "M" and communication logs for two different parent documents.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        CreateOutgoingEDocument(OtherEDocument);
        EDocumentIntegrationLog.Init();
        EDocumentIntegrationLog."E-Doc. Entry No" := EDocument."Entry No";
        EDocumentIntegrationLog."Service Code" := EDocumentService.Code;
        EDocumentIntegrationLog.Insert();
        ExpectedLogEntryNo := EDocumentIntegrationLog."Entry No.";
        EDocumentIntegrationLog.Init();
        EDocumentIntegrationLog."Entry No." := 0;
        EDocumentIntegrationLog."E-Doc. Entry No" := OtherEDocument."Entry No";
        EDocumentIntegrationLog."Service Code" := EDocumentService.Code;
        EDocumentIntegrationLog.Insert();
        OtherService.Init();
        OtherService.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(OtherService.Code));
        OtherService.Insert();
        EDocumentIntegrationLog.Init();
        EDocumentIntegrationLog."Entry No." := 0;
        EDocumentIntegrationLog."E-Doc. Entry No" := EDocument."Entry No";
        EDocumentIntegrationLog."Service Code" := OtherService.Code;
        EDocumentIntegrationLog.Insert();
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.EDocMessages.GoToRecord(EDocMessage);

        // [WHEN] The user opens communication logs for message "M".
        EDocumentPage.EDocMessages.OpenIntegrationLogs.Invoke();
        EDocumentPage.Close();

        // [THEN] Only its parent document's matching service log is shown.
        Assert.AreEqual(ExpectedLogEntryNo, LibraryVariableStorage.DequeueInteger(), 'Only logs for the selected message parent must be shown.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LongConnectorErrorIsTruncatedAndExcludedFromTelemetry()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        ConnectorError: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Long customer-bearing diagnostics stay local and are truncated only for storage.
        Initialize(Customer);

        // [GIVEN] Queued message "M" and a connector returning a long private diagnostic.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Queued);
        ConnectorError := 'PRIVATE-DIAGNOSTIC-' + PadStr('', MaxStrLen(EDocMessage."Last Error") + 50, 'X');
        EDocImplState.SetMessageConnectorError(ConnectorError);
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        Commit();

        // [WHEN] The send worker fails.
        Assert.IsFalse(Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry), 'The connector error must not become a successful send.');

        // [THEN] The local error is bounded and no custom telemetry contains the private diagnostic.
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(CopyStr(ConnectorError, 1, MaxStrLen(EDocMessage."Last Error")), EDocMessage."Last Error", 'Persist the diagnostic up to the field capacity.');
        Assert.IsFalse(EDocImplState.GetMessageTelemetryText().Contains('PRIVATE-DIAGNOSTIC-'), 'Customer content must not enter custom telemetry.');
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000LC7'), 'Emit exactly one worker failure.');
        UnbindSubscription(EDocImplState);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CompletedResponseWithPendingStatusIsRejected()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A true response result cannot carry Pending Response status.
        Initialize(Customer);

        // [GIVEN] Pending message "M" and an inconsistent completed response.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::"Pending Response");
        EDocImplState.SetOnGetResponseSuccess();
        EDocImplState.SetMessageResponseStatus("E-Document Service Status"::"Pending Response");
        Commit();

        // [WHEN] The response worker polls message "M".
        // [THEN] The invalid contract becomes a recoverable response error.
        VerifyInvalidResponseRejected(EDocMessage);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PendingResponseWithSentStatusIsRejected()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A false response result cannot carry Sent status.
        Initialize(Customer);

        // [GIVEN] Pending message "M" and an inconsistent incomplete response.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::"Pending Response");
        EDocImplState.SetMessageResponseStatus("E-Document Service Status"::Sent);
        Commit();

        // [WHEN] The response worker polls message "M".
        // [THEN] The invalid contract becomes a recoverable response error.
        VerifyInvalidResponseRejected(EDocMessage);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure RetryWithoutErrorLogPermissionsRetainsActionableFailure()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Denied scheduling leaves an actionable failure and does not enqueue a retry.
        Initialize(Customer);

        // [GIVEN] Failed message "M" and a user without the base error-log write permissions.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        Commit();
        LibraryLowerPermission.StartLoggingNAVPermissions();
        LibraryLowerPermission.SetExactPermissionSet('E-Doc. Core - User');
        LibraryLowerPermission.AddPermissionSet('D365 Basic - Read');
        LibraryLowerPermission.AddPermissionSet('Job Queue - Admin');

        // [WHEN] The user retries without the error-log permissions required for scheduling.
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");
        LibraryLowerPermission.StopLoggingNAVPermissions();

        // [THEN] The child retains the permission diagnostic and remains retryable without a queued job.
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Error, EDocMessage.Status, 'Denied scheduling must remain retryable.');
        Assert.IsTrue(EDocMessage."Last Error".Contains('Error Message Register'), EDocMessage."Last Error");
        Assert.IsTrue(EDocMessage."Last Error".Contains('Permissions'), 'Retain the missing error-log permissions diagnostic.');
        Assert.AreEqual(1, EDocMessage."Retry Count", 'Count the denied scheduling attempt exactly once.');
        Assert.AreNotEqual(0DT, EDocMessage."Last Attempt At", 'Record the denied scheduling attempt.');
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UnsupportedConnectorRetainsActionableFailure()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A service without message support must report a retryable failure, never success.
        Initialize(Customer);

        // [GIVEN] Queued message "M" belongs to a service with no message connector.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Queued);
        Clear(EDocumentService."Service Integration V2");
        EDocumentService.Modify();
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        Commit();

        // [WHEN] The send worker tries the unsupported connector.
        Assert.IsFalse(Codeunit.Run(Codeunit::"E-Doc. Message Send Job", JobQueueEntry), 'An unsupported connector must fail explicitly.');

        // [THEN] The child has an actionable service-specific error.
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::Error, EDocMessage.Status, 'Unsupported transport must not report Sent.');
        Assert.AreEqual(StrSubstNo('E-Document service %1 does not support sending E-Document messages.', EDocumentService.Code), EDocMessage."Last Error", 'The failure must identify the service and unsupported operation.');
    end;

    [Test]
    procedure RetryActionOnlyEnablesForFailedOutgoingMessages()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] Retry is enabled only for failed outgoing sends and polls.
        Initialize(Customer);

        // [GIVEN] Message "M" is shown in the Messages FactBox.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Created);

        // [WHEN] The message direction and transport state vary.
        // [THEN] Only the two recoverable outgoing states allow retry.
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::Created, EDocMessage.Direction::Outgoing, false);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::Queued, EDocMessage.Direction::Outgoing, false);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::"Pending Response", EDocMessage.Direction::Outgoing, false);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::Sent, EDocMessage.Direction::Outgoing, false);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::Error, EDocMessage.Direction::Outgoing, true);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::"Response Error", EDocMessage.Direction::Outgoing, true);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::Error, EDocMessage.Direction::Incoming, false);
        VerifyRetryEnabled(EDocMessage, EDocMessage.Status::"Response Error", EDocMessage.Direction::Incoming, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RepeatedRetryDoesNotDuplicateScheduledSend()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647423] A second retry cannot enqueue another job for an already queued message.
        Initialize(Customer);

        // [GIVEN] Failed message "M" has already been retried.
        CreateMessageWithStatus(EDocument, EDocMessage, EDocMessage.Status::Error);
        EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");
        Commit();

        // [WHEN] The retry request is repeated.
        asserterror EDocumentMessageAPI.RetryMessage(EDocMessage."Entry No.");

        // [THEN] The repeated request is rejected and only the original retry job exists.
        Assert.ExpectedError('Status must be equal to ''Error''');
        Assert.ExpectedErrorCode('TestField');
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
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
        LibraryVariableStorage.Clear();
        LibraryLowerPermission.StopLoggingNAVPermissions();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter(
            "Object ID to Run", '%1|%2|%3', Codeunit::"E-Doc. Message Send Job",
            Codeunit::"E-Doc. Message Response Job", Codeunit::"E-Doc. Payment Occ. Dispatcher");
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

    local procedure VerifyRetryEnabled(var EDocMessage: Record "E-Document Message"; MessageStatus: Enum "E-Doc. Message Status"; Direction: Enum "E-Document Direction"; ExpectedEnabled: Boolean)
    var
        EDocument: Record "E-Document";
        EDocumentPage: TestPage "E-Document";
    begin
        EDocMessage.Status := MessageStatus;
        EDocMessage.Direction := Direction;
        EDocMessage.Modify();
        EDocument.Get(EDocMessage."E-Document Entry No.");
        EDocumentPage.OpenView();
        EDocumentPage.GoToRecord(EDocument);
        EDocumentPage.EDocMessages.GoToRecord(EDocMessage);
        Assert.AreEqual(ExpectedEnabled, EDocumentPage.EDocMessages.Retry.Enabled(), 'Retry eligibility must match the message state and direction.');
        EDocumentPage.Close();
    end;

    local procedure VerifyInvalidResponseRejected(EDocMessage: Record "E-Document Message")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        EDocImplState.EnableMessageTelemetry();
        BindSubscription(EDocImplState);
        JobQueueEntry."Record ID to Process" := EDocMessage.RecordId();
        Assert.IsFalse(Codeunit.Run(Codeunit::"E-Doc. Message Response Job", JobQueueEntry), 'An inconsistent response must fail.');
        EDocMessage.Get(EDocMessage."Entry No.");
        Assert.AreEqual(EDocMessage.Status::"Response Error", EDocMessage.Status, 'The invalid response must remain recoverable.');
        Assert.AreEqual(1, EDocMessage."Retry Count", 'Count the invalid response exactly once.');
        Assert.AreNotEqual('', EDocMessage."Last Error", 'Retain the invalid-contract diagnostic.');
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000LC8'), 'Emit one response failure.');
        UnbindSubscription(EDocImplState);
    end;

    local procedure SetMessageUserPermissions()
    begin
        LibraryLowerPermission.StartLoggingNAVPermissions();
        LibraryLowerPermission.SetExactPermissionSet('E-Doc. Core - User');
        LibraryLowerPermission.AddPermissionSet('D365 BASIC');
        LibraryLowerPermission.AddPermissionSet('Job Queue - Admin');
        LibraryLowerPermission.AddPermissionSet('E-Doc. Message Test');
    end;

    local procedure CreateMessageWithStatus(var EDocument: Record "E-Document"; var EDocMessage: Record "E-Document Message"; MessageStatus: Enum "E-Doc. Message Status")
    begin
        CreateOutgoingEDocument(EDocument);
        EDocMessage.Get(CreatePendingMessage(EDocument));
        EDocMessage.Status := MessageStatus;
        EDocMessage.Modify();
    end;

    local procedure VerifySchedulingFailure(OriginalEDocument: Record "E-Document"; OriginalMessage: Record "E-Document Message"; ExpectedStatus: Enum "E-Doc. Message Status"; ExpectedStage: Text; ExpectedError: Text)
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        Dimensions: Dictionary of [Text, Text];
    begin
        EDocMessage.Get(OriginalMessage."Entry No.");
        Assert.AreEqual(ExpectedStatus, EDocMessage.Status, 'The message must retain the correct retryable status.');
        Assert.AreEqual(OriginalMessage."Data Storage Entry No.", EDocMessage."Data Storage Entry No.", 'Scheduling must not replace the payload.');
        Assert.AreEqual(OriginalMessage."Retry Count" + 1, EDocMessage."Retry Count", 'Count the failed attempt exactly once.');
        Assert.AreEqual(ExpectedError, EDocMessage."Last Error", 'Retain the original scheduler diagnostic.');
        Assert.AreNotEqual(0DT, EDocMessage."Last Attempt At", 'Record the failed attempt time.');
        EDocMessage.SetRange("E-Document Entry No.", OriginalEDocument."Entry No");
        Assert.RecordCount(EDocMessage, 1);
        JobQueueEntry.SetRange("Record ID to Process", OriginalMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 0);
        EDocument.Get(OriginalEDocument."Entry No");
        Assert.AreEqual(OriginalEDocument.Status, EDocument.Status, 'Child-message failure must not change invoice status.');
        Assert.AreEqual(1, EDocImplState.GetMessageTelemetryCount('0000W3L'), 'Emit one scheduling-failure event.');
        Assert.AreEqual(0, EDocImplState.GetMessageTelemetryCount('0000LC6'), 'Failed enqueue must not emit success.');
        Assert.IsFalse(EDocImplState.GetMessageTelemetryText().Contains(ExpectedError), 'Raw diagnostics must not be sent to telemetry.');
        Dimensions := EDocImplState.GetSchedulingTelemetryDimensions();
        Assert.AreEqual(ExpectedStage, Dimensions.Get('Stage'), 'Identify the failed scheduling stage.');
        Assert.AreEqual(Format(OriginalMessage."Entry No.", 0, 9), Dimensions.Get('MessageEntryNo'), 'Correlate telemetry to the existing child.');
        Assert.AreEqual(Format(DataClassification::SystemMetadata), Dimensions.Get('TestClassification'), 'New telemetry contains metadata only.');
        Assert.AreEqual(Format(TelemetryScope::All), Dimensions.Get('TestScope'), 'Actionable scheduling failures belong in environment telemetry.');
        Assert.AreEqual(Format(Verbosity::Error), Dimensions.Get('TestVerbosity'), 'Scheduling failure must be an error event.');
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

    local procedure CreatePaymentOccurrence(EDocumentEntryNo: Integer; Status: Enum "E-Doc. Payment Occ. Status"; NextAttemptAt: DateTime): Integer
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        EDocPaymentOccurrence.Init();
        EDocPaymentOccurrence."E-Document Entry No." := EDocumentEntryNo;
        EDocPaymentOccurrence."Source Occurrence ID" := CreateGuid();
        EDocPaymentOccurrence.Status := Status;
        EDocPaymentOccurrence."Next Attempt At" := NextAttemptAt;
        EDocPaymentOccurrence.Insert();
        exit(EDocPaymentOccurrence."Entry No.");
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

    [PageHandler]
    procedure MessageServicePageHandler(var EDocumentServicePage: TestPage "E-Document Service")
    begin
        LibraryVariableStorage.Enqueue(EDocumentServicePage.Code.Value);
        EDocumentServicePage.Close();
    end;

    [PageHandler]
    procedure MessageIntegrationLogsPageHandler(var EDocumentIntegrationLogs: TestPage "E-Document Integration Logs")
    begin
        if EDocumentIntegrationLogs.First() then
            repeat
                LibraryVariableStorage.Enqueue(EDocumentIntegrationLogs."Entry No.".AsInteger());
            until not EDocumentIntegrationLogs.Next();
        EDocumentIntegrationLogs.Close();
    end;
}
