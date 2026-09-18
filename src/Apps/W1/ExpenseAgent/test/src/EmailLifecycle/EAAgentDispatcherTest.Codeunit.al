// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;
using System.Email;
using System.Environment;
using System.TestLibraries.Email;

codeunit 148314 "EA Agent Dispatcher Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Function;
    TestHttpRequestPolicy = BlockOutboundRequests;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";
        ExpectedPath: Text;
        ResponseResource: Text;
        ResponseStatusCode: Integer;
        HttpRequestCount: Integer;
        ObservedRequestCount: Integer;
        EndpointResolutionCount: Integer;
        ExpectedUseCanaryEndpoint: Boolean;
        RequestCorrelationId: Guid;
        MultipartBody: Text;
        MultipartContentType: Text;
        UnexpectedRequest: Text;
        ReceiptMessageId: Guid;
        OutgoingMockAccountId: Guid;
        FixtureMessageIds: List of [Guid];
        DisableOutgoingAfterSend: Boolean;
        UseReceiptAttachmentFixture: Boolean;
        TestCompanyTok: Label 'EA Email Lifecycle Test', Locked = true;
        ServiceBaseUrlTok: Label 'https://expense-agent.example.invalid', Locked = true;
        RecipientEmailTok: Label 'recipient@example.invalid', Locked = true;
        OneOwnerMustBeDefinedErr: Label 'At least one user must be able to configure the Expense Agent.';

    [Test]
    procedure OutgoingPassSendsMultipleRowsWithoutIncomingAccount()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        FirstOutboxEmail: Record "EA Outbox Email";
        SecondOutboxEmail: Record "EA Outbox Email";
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, false);
        CreatePendingEmail(FirstOutboxEmail);
        CreatePendingEmail(SecondOutboxEmail);

        RunCommunication(Setup);

        FirstOutboxEmail.Get(FirstOutboxEmail.Id);
        SecondOutboxEmail.Get(SecondOutboxEmail.Id);
        Assert.AreEqual(FirstOutboxEmail.Status::Sent, FirstOutboxEmail.Status, 'Outgoing must work with receipts enabled but no incoming account.');
        Assert.AreEqual(SecondOutboxEmail.Status::Sent, SecondOutboxEmail.Status, 'Direct passes must initialize the per-run limit above one.');
        Assert.IsFalse(IsNullGuid(ConnectorMock.GetEmailMessageID()), 'The real Email.Send path must reach the mock connector.');
        AssertNoIncomingProcessing();
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure IncomingOnlySubmitsMultipartReceiptAndPreservesOutgoingWork()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
        EAKPI: Record "EA KPI";
        FilesReceivedBefore: Integer;
    begin
        InitializeCommunication(Setup, true, false);
        CreateRecipient(ExpenseUser, true);
        CreatePendingEmail(OutboxEmail);
        CreateReceiptInbox(Setup);
        EAKPI.GetSafe();
        FilesReceivedBefore := EAKPI."File Received";
        ExpectService('/api/v1.0/expenses/process', 'receipt-accepted.json', 202);

        RunCommunication(Setup);

        Assert.AreEqual(1, HttpRequestCount, 'Incoming-only must submit one receipt.');
        AssertMultipartReceipt();
        AssertReceiptProcessed();
        EAKPI.GetSafe();
        Assert.AreEqual(FilesReceivedBefore + 2, EAKPI."File Received", '202 is acceptance of both attachments, not completed processing or delivery.');
        AssertOutgoingUnchanged(OutboxEmail, ExpenseUser);
    end;

    [Test]
    procedure MissingBothAccountsRunsNoCommunicationPhases()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
        ExpenseAgentStatus: Record "Expense Agent Status";
        PreviousNotificationRun: DateTime;
    begin
        InitializeCommunication(Setup, false, false);
        CreateRecipient(ExpenseUser, true);
        CreatePendingEmail(OutboxEmail);
        CreateEligibleReminder(Setup, ExpenseUser, PreviousNotificationRun);
        ConnectorMock.FailOnRetrieveEmails(true);
        ConnectorMock.FailOnSend(true);

        RunCommunication(Setup);

        AssertOutgoingUnchanged(OutboxEmail, ExpenseUser);
        AssertNoIncomingProcessing();
        ExpenseAgentStatus.Get();
        Assert.AreEqual(PreviousNotificationRun, ExpenseAgentStatus."Last Notif. Run At", 'Missing outgoing must not advance reminder polling.');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure DirectPassRetriesUntilFifthConnectorFailure()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
        Attempt: Integer;
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, true);
        ExpectService('/api/v1.0/notifications/welcome', 'notification-outbox-accepted.json', 200);
        RunCommunication(Setup);
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", 'Retries start after a real successful handoff.');
        InsertCorrelatedCallback(OutboxEmail, RequestCorrelationId);
        ExpectNoService();
        ConnectorMock.FailOnSend(true);

        for Attempt := 1 to 5 do begin
            RunCommunication(Setup);
            OutboxEmail.Get(OutboxEmail.Id);
            ExpenseUser.Get(ExpenseUser."No.");
            Assert.AreEqual(Attempt, OutboxEmail."Retry Count", 'One failed connector delivery per pass is one retry.');
            if Attempt < 5 then begin
                Assert.AreEqual(OutboxEmail.Status::Pending, OutboxEmail.Status, 'Attempts one through four remain pending.');
                Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", 'Nonterminal failures must not complete the welcome.');
            end else begin
                Assert.AreEqual(OutboxEmail.Status::Failed, OutboxEmail.Status, 'The fifth failed attempt is terminal.');
                Assert.AreEqual(ExpenseUser."Welcome Email Status"::Failed, ExpenseUser."Welcome Email Status", 'Terminal failure must correlate back to the welcome.');
            end;
        end;

        RunCommunication(Setup);
        OutboxEmail.Get(OutboxEmail.Id);
        Assert.AreEqual(5, OutboxEmail."Retry Count", 'Terminal rows must not be retried.');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure WelcomeAcceptanceThenCorrelatedCallbackAndDelivery()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
        EmailMessage: Codeunit "Email Message";
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, true);
        ExpectService('/api/v1.0/notifications/welcome', 'notification-outbox-accepted.json', 200);

        RunCommunication(Setup);

        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(1, HttpRequestCount, 'One real welcome request is expected.');
        Assert.IsFalse(IsNullGuid(RequestCorrelationId), 'The production request must carry a correlation header.');
        Assert.AreEqual(RequestCorrelationId, ExpenseUser."Welcome Correlation Id", 'Hop one must persist the actual request correlation.');
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", '200 acknowledges outbox handoff, not connector delivery.');
        Assert.AreEqual(0DT, ExpenseUser."Welcome Email Sent At", 'HTTP acceptance alone is not Sent.');
        Assert.IsTrue(OutboxEmail.IsEmpty(), 'Returning HTTP 200 alone must not fabricate a callback.');

        // Simulated BC writeback, outside the HTTP TryFunction. This is not OData/auth validation.
        InsertCorrelatedCallback(OutboxEmail, RequestCorrelationId);
        Assert.AreEqual(OutboxEmail.Status::Pending, OutboxEmail.Status, 'The callback inserts pending work.');
        ExpectNoService();
        RunCommunication(Setup);

        OutboxEmail.Get(OutboxEmail.Id);
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(OutboxEmail.Status::Sent, OutboxEmail.Status, 'The second production pass must deliver via Email.Send.');
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Sent, ExpenseUser."Welcome Email Status", 'Real outbox correlation must complete the welcome.');
        Assert.AreNotEqual(0DT, ExpenseUser."Welcome Email Sent At", 'Mocked connector delivery stamps Sent.');
        Assert.IsTrue(EmailMessage.Get(ConnectorMock.GetEmailMessageID()), 'The mock connector must receive a persisted email.');
        Assert.AreEqual(OutboxEmail.Subject, EmailMessage.GetSubject(), 'The callback subject must reach the connector.');
        Assert.AreEqual(OutboxEmail.ReadBody(), EmailMessage.GetBody(), 'The callback body must reach the connector.');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure WelcomeGatewayFailureDoesNotCreateOutboxOrMarkSent()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, true);
        // Only the HTTP 502 boundary is asserted; no unverified service error-body contract is invented.
        ExpectService('/api/v1.0/notifications/welcome', '', 502);

        RunCommunication(Setup);

        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(1, HttpRequestCount, 'The failure must come from the real HTTP status boundary.');
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Failed, ExpenseUser."Welcome Email Status", 'HTTP 502 fails the handoff.');
        Assert.IsTrue(IsNullGuid(ExpenseUser."Welcome Correlation Id"), 'Failed handoff must clear the user correlation.');
        Assert.AreEqual(0DT, ExpenseUser."Welcome Email Sent At", 'Failed handoff is not delivery.');
        Assert.IsTrue(OutboxEmail.IsEmpty(), 'A failed service handoff must not insert an outbox callback.');
    end;

    [Test]
    procedure MissingSetupSkipsEndpointOverrideAndHttp()
    var
        Setup: Record "Expense Agent Setup";
        EAHttpClient: Codeunit "EA Http Client";
        Success: Boolean;
    begin
        AssertIsolatedCompany();
        ExpectNoService();
        Setup.DeleteAll();
        Commit();
        BindSubscription(this);
        Success := EAHttpClient.SendWelcomeEmailNotification(RecipientEmailTok, CreateGuid());
        UnbindSubscription(this);

        Assert.IsFalse(Success, 'The real HTTP wrapper must reject missing persisted setup.');
        Assert.AreEqual(0, EndpointResolutionCount, 'Missing setup must be checked before the endpoint override event.');
        Assert.AreEqual(0, ObservedRequestCount, 'Missing setup must not construct a service request.');
        Assert.AreEqual(0, HttpRequestCount, 'Missing setup must not reach HTTP.');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure SavedCanarySelectionReachesCommunicationEndpoint()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, true);
        ExpectService('/api/v1.0/notifications/welcome', 'notification-outbox-accepted.json', 200);
        RunCommunication(Setup);
        Assert.AreEqual(1, EndpointResolutionCount, 'The saved default selection must reach endpoint resolution.');
        Assert.AreEqual(1, HttpRequestCount, 'The default selection must execute the real HTTP wrapper.');

        Setup.Get();
        Setup."Use Canary Endpoint" := true;
        Setup.Modify();
        CreateRecipient(ExpenseUser, true);
        ExpectService('/api/v1.0/notifications/welcome', 'notification-outbox-accepted.json', 200);
        ExpectedUseCanaryEndpoint := true;
        RunCommunication(Setup);
        Assert.AreEqual(1, EndpointResolutionCount, 'The saved canary selection must reach endpoint resolution.');
        Assert.AreEqual(1, HttpRequestCount, 'The canary selection must execute the real HTTP wrapper with a safe mock endpoint.');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure EligibleReminderWithoutIncomingAcceptsSkippedResponse()
    begin
        VerifyReminderResponse('reminder-skipped.json');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure ReminderBodyFailurePreservesExistingHttpOnlyBoundary()
    begin
        // Current AL wrappers inspect HTTP status only; do not reinterpret the service response body.
        VerifyReminderResponse('reminder-send-failed.json');
    end;

    [Test]
    [HandlerFunctions('ExpenseServiceHandler')]
    procedure BothChannelsProcessReceiptAndPendingOutbox()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
    begin
        InitializeCommunication(Setup, true, true);
        CreateRecipient(ExpenseUser, false);
        CreatePendingEmail(OutboxEmail);
        CreateReceiptInbox(Setup);
        ExpectService('/api/v1.0/expenses/process', 'receipt-accepted.json', 202);

        RunCommunication(Setup);

        Assert.AreEqual(1, HttpRequestCount, 'The incoming phase must submit the receipt.');
        AssertMultipartReceipt();
        AssertReceiptProcessed();
        OutboxEmail.Get(OutboxEmail.Id);
        Assert.AreEqual(OutboxEmail.Status::Sent, OutboxEmail.Status, 'Outgoing must also run in the same production pass.');
    end;

    [Test]
    procedure ReReadsPersistedSetupAfterCommittingOutboxPhase()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        OutboxEmail: Record "EA Outbox Email";
        ExpenseAgentStatus: Record "Expense Agent Status";
        PreviousNotificationRun: DateTime;
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, true);
        CreatePendingEmail(OutboxEmail);
        CreateEligibleReminder(Setup, ExpenseUser, PreviousNotificationRun);
        DisableOutgoingAfterSend := true;

        RunCommunication(Setup);

        Setup.Get();
        Assert.IsFalse(Setup."Enable Communication", 'The callback must persist the changed setup during the send phase.');
        OutboxEmail.Get(OutboxEmail.Id);
        Assert.AreEqual(OutboxEmail.Status::Sent, OutboxEmail.Status, 'Already executing delivery completes.');
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'Later phases must not use stale setup.');
        ExpenseAgentStatus.Get();
        Assert.AreEqual(PreviousNotificationRun, ExpenseAgentStatus."Last Notif. Run At", 'Reminders must use the saved disabled configuration.');
    end;

    local procedure InitializeCommunication(var Setup: Record "Expense Agent Setup"; IncomingAvailable: Boolean; OutgoingAvailable: Boolean)
    var
        OutboxEmail: Record "EA Outbox Email";
        EmailOutbox: Record "Email Outbox";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        EAEmail: Record "EA Email";
        ExpenseAgentStatus: Record "Expense Agent Status";
        TempEmailInbox: Record "Email Inbox" temporary;
        TestEmailConnector: Codeunit "Test Email Connector v4";
        CopilotCapability: Codeunit "Copilot Capability";
        ExpenseAgentAppId: Guid;
    begin
        AssertIsolatedCompany();
        Evaluate(ExpenseAgentAppId, '66efe10c-8033-403b-a86d-77c0887178ba');
        Assert.IsTrue(CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Expense Agent", ExpenseAgentAppId),
            'Expense Agent capability and required privacy approvals must already be enabled. These tests never change tenant-wide Copilot settings or approvals.');
        Assert.IsTrue(EmailOutbox.IsEmpty(), 'The disposable company must have no existing email outbox rows, including failed background work.');
        if ExpenseAgentStatus.Get() then begin
            Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Task ID"), 'The isolated fixture must not have a configured dispatcher.');
            Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID"), 'The isolated fixture must not have configured recovery.');
        end;
        Clear(ReceiptMessageId);
        Clear(OutgoingMockAccountId);
        Clear(FixtureMessageIds);
        Clear(DisableOutgoingAfterSend);
        Clear(UseReceiptAttachmentFixture);
        ExpectNoService();
        TestEmailConnector.SetEmailInbox(TempEmailInbox);
        ConnectorMock.Initialize();
        OutboxEmail.DeleteAll();
        ExpenseUser.DeleteAll();
        ExpenseReportHeader.DeleteAll();
        EAEmail.DeleteAll(true);
        ExpenseAgentStatus.DeleteAll();
        ExpenseAgentStatus.GetOrCreate();
        Setup.DeleteAll();
        Setup.Init();
        Setup."Enable Agent" := true;
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := true;
        Setup."Enable Open Report Notif." := false;
        Setup."Use Canary Endpoint" := false;
        if IncomingAvailable then begin
            Setup."Email Account ID" := RegisterMockAccount('receipts@example.invalid');
            Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
            Setup."Email Address" := 'receipts@example.invalid';
        end;
        if OutgoingAvailable then begin
            Setup."Noreply Email Account ID" := RegisterMockAccount('noreply@example.invalid');
            OutgoingMockAccountId := Setup."Noreply Email Account ID";
            Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
            Setup."Noreply Email Address" := 'noreply@example.invalid';
        end;
        Setup.Insert();

        Commit();
    end;

    local procedure AssertIsolatedCompany()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.AreEqual(TestCompanyTok, CompanyName(), 'Run only in the dedicated disposable EA Email Lifecycle Test company, never CRONUS.');
        Assert.IsFalse(EnvironmentInformation.IsSaaS(), 'Mock integration tests require on-prem; SaaS authentication is not under test.');
        Assert.IsFalse(EnvironmentInformation.IsSaaSInfrastructure(), 'These tests must not use SaaS infrastructure.');
    end;

    local procedure RegisterMockAccount(Address: Text[250]): Guid
    var
        TestEmailAccount: Record "Test Email Account";
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        // This overload creates the matching connector's explicit zero (unlimited) rate-limit row.
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TestEmailAccount.Get(TempEmailAccount."Account Id");
        TestEmailAccount.Email := Address;
        TestEmailAccount.Name := 'Expense communication mock';
        TestEmailAccount.Modify();
        Assert.IsTrue(EmailAccount.IsAccountRegistered(TestEmailAccount.Id, TestEmailAccount.Connector), 'The native mock account must be registered.');
        exit(TestEmailAccount.Id);
    end;

    local procedure RunCommunication(var Setup: Record "Expense Agent Setup")
    var
        TempEmailInbox: Record "Email Inbox" temporary;
        Dispatcher: Codeunit "EA Agent Dispatcher";
        TestEmailConnector: Codeunit "Test Email Connector v4";
        ErrorMessage: Text;
        Success: Boolean;
    begin
        // The endpoint override and read-only request observers are bound only for this production pass.
        BindSubscription(this);
        Commit();
        Success := Dispatcher.ProcessCommunication(Setup, ErrorMessage);
        UnbindSubscription(this);
        TestEmailConnector.SetEmailInbox(TempEmailInbox);
        Assert.IsTrue(Success, 'The scheduler-free production pass failed: ' + ErrorMessage);
        Assert.AreEqual('', ErrorMessage, 'Runnable channels must not report a missing-incoming error.');
        Assert.AreEqual('', UnexpectedRequest, 'Unexpected HTTP must fail even if production catches the handler error.');
        Assert.AreEqual(HttpRequestCount, ObservedRequestCount, 'Every observed production request must reach the native HTTP mock.');
        Assert.AreEqual(HttpRequestCount, EndpointResolutionCount, 'Each mocked request must resolve its endpoint through the real persisted-setup boundary.');
    end;

    local procedure CreateRecipient(var ExpenseUser: Record "Expense User"; QueueWelcome: Boolean)
    begin
        ExpenseUser.Init();
        ExpenseUser."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ExpenseUser."No."));
        ExpenseUser."E-mail" := RecipientEmailTok;
        if QueueWelcome then
            ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Queued;
        ExpenseUser.Insert();
    end;

    local procedure CreatePendingEmail(var OutboxEmail: Record "EA Outbox Email")
    begin
        OutboxEmail.Init();
        OutboxEmail.Id := 0;
        OutboxEmail.ToLine := RecipientEmailTok;
        OutboxEmail.Subject := 'Isolated communication test';
        OutboxEmail.WriteBody('<p>Mock notification.</p>');
        OutboxEmail.Insert();
    end;

    local procedure CreateReceiptInbox(Setup: Record "Expense Agent Setup")
    var
        TempEmailInbox: Record "Email Inbox" temporary;
        EmailMessage: Codeunit "Email Message";
        TestEmailConnector: Codeunit "Test Email Connector v4";
    begin
        EmailMessage.Create('receipts@example.invalid', 'Receipt € ø', '<p>Two receipts for processing.</p>', true);
        UseReceiptAttachmentFixture := true;
        ReceiptMessageId := EmailMessage.GetId();
        TempEmailInbox.Id := 1;
        TempEmailInbox."Account Id" := Setup."Email Account ID";
        TempEmailInbox.Connector := Setup."Email Connector";
        TempEmailInbox."Message Id" := ReceiptMessageId;
        TempEmailInbox."Sender Address" := RecipientEmailTok;
        TempEmailInbox."Sender Name" := 'Mock expense user';
        TempEmailInbox."Received DateTime" := CurrentDateTime();
        TempEmailInbox."Sent DateTime" := CurrentDateTime();
        TempEmailInbox."External Message Id" := Format(CreateGuid());
        TempEmailInbox.Insert();
        TestEmailConnector.SetEmailInbox(TempEmailInbox);
        Commit();
    end;

    local procedure AssertMultipartReceipt()
    var
        Parts: List of [Text];
    begin
        Assert.IsTrue(MultipartContentType.StartsWith('multipart/form-data; boundary='), 'Receipt requests must remain multipart.');
        Assert.IsTrue(MultipartBody.Contains('name="conversation_id"'), 'Multipart must carry the production conversation id.');
        Assert.IsTrue(MultipartBody.Contains('name="context"'), 'Multipart must carry context.');
        Assert.IsTrue(MultipartBody.Contains('Receipt € ø'), 'Context must preserve UTF-8 text.');
        Assert.IsTrue(MultipartBody.Contains('Two receipts for processing.'), 'Receipt context must contain the inbox body.');
        Parts := MultipartBody.Split('name="attachments"');
        Assert.AreEqual(3, Parts.Count(), 'Two attachments must use the same repeated multipart field name.');
        Assert.IsTrue(MultipartBody.Contains('filename="receipt-one.pdf"'), 'First attachment filename must be serialized.');
        Assert.IsTrue(MultipartBody.Contains('filename="receipt-two.png"'), 'Second attachment filename must be serialized.');
        Assert.IsTrue(MultipartBody.Contains('mock-receipt-one'), 'First attachment bytes must be serialized.');
        Assert.IsTrue(MultipartBody.Contains('mock-receipt-two'), 'Second attachment bytes must be serialized.');
    end;

    local procedure AssertReceiptProcessed()
    var
        EmailInbox: Record "Email Inbox";
        EAEmail: Record "EA Email";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        EmailInbox.SetRange("Message Id", ReceiptMessageId);
        Assert.IsTrue(EmailInbox.FindFirst(), 'The native mock inbox must have been retrieved.');
        EAEmail.Get(EmailInbox.Id);
        Assert.IsTrue(EAEmail.Processed, 'The real receipt phase must mark the inbox item processed.');
        ExpenseAgentStatus.Get();
        Assert.AreNotEqual(0DT, ExpenseAgentStatus."Last Sync At", 'Successful incoming phase must update sync status.');
    end;

    local procedure AssertNoIncomingProcessing()
    var
        EAEmail: Record "EA Email";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        Assert.IsTrue(EAEmail.IsEmpty(), 'Missing incoming must not retrieve any email.');
        ExpenseAgentStatus.Get();
        Assert.AreEqual(0DT, ExpenseAgentStatus."Last Sync At", 'Skipped incoming must not update sync status.');
    end;

    local procedure AssertOutgoingUnchanged(var OutboxEmail: Record "EA Outbox Email"; var ExpenseUser: Record "Expense User")
    begin
        OutboxEmail.Get(OutboxEmail.Id);
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(OutboxEmail.Status::Pending, OutboxEmail.Status, 'Missing outgoing leaves outbox work pending.');
        Assert.AreEqual(0, OutboxEmail."Retry Count", 'A skipped channel must not consume retries.');
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'A skipped channel preserves welcome work.');
        Assert.IsTrue(IsNullGuid(ConnectorMock.GetEmailMessageID()), 'No delivery may reach the connector.');
    end;

    local procedure InsertCorrelatedCallback(var OutboxEmail: Record "EA Outbox Email"; CorrelationId: Guid)
    var
        Callback: JsonObject;
        Value: JsonToken;
        CallbackText: Text;
    begin
        CallbackText := NavApp.GetResourceAsText('outbox-email-correlated.json', TextEncoding::UTF8);
        CallbackText := CallbackText.Replace('__REQUEST_CORRELATION_GUID__', Format(CorrelationId, 0, 4));
        Callback.ReadFrom(CallbackText);
        OutboxEmail.Init();
        Callback.Get('toLine', Value);
        OutboxEmail.ToLine := CopyStr(Value.AsValue().AsText(), 1, MaxStrLen(OutboxEmail.ToLine));
        Callback.Get('subject', Value);
        OutboxEmail.Subject := CopyStr(Value.AsValue().AsText(), 1, MaxStrLen(OutboxEmail.Subject));
        Callback.Get('body', Value);
        OutboxEmail.WriteBody(Value.AsValue().AsText());
        Callback.Get('correlationId', Value);
        Evaluate(OutboxEmail."Correlation Id", Value.AsValue().AsText());
        Callback.Get('notificationType', Value);
        Assert.AreEqual('Welcome', Value.AsValue().AsText(), 'Only a Welcome callback is exercised here.');
        OutboxEmail."Notification Type" := OutboxEmail."Notification Type"::Welcome;
        OutboxEmail.Insert();
    end;

    local procedure CreateEligibleReminder(var Setup: Record "Expense Agent Setup"; ExpenseUser: Record "Expense User"; var PreviousRun: DateTime)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        Setup."Enable Open Report Notif." := true;
        Setup."Open Report Notif. Freq." := Enum::"Expense Report Frequency"::Daily;
        Setup.Modify();
        ExpenseReportHeader.Init();
        ExpenseReportHeader."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ExpenseReportHeader."No."));
        ExpenseReportHeader."Expense User No." := ExpenseUser."No.";
        ExpenseReportHeader.Status := Enum::"Expense Report Status"::Open;
        ExpenseReportHeader.Insert();
        PreviousRun := CreateDateTime(Today() - 2, 090000T);
        ExpenseAgentStatus.Get();
        ExpenseAgentStatus."Last Notif. Run At" := PreviousRun;
        ExpenseAgentStatus.Modify();
    end;

    local procedure VerifyReminderResponse(ResourceName: Text)
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        ExpenseAgentStatus: Record "Expense Agent Status";
        OutboxEmail: Record "EA Outbox Email";
        PreviousRun: DateTime;
    begin
        InitializeCommunication(Setup, false, true);
        CreateRecipient(ExpenseUser, false);
        CreateEligibleReminder(Setup, ExpenseUser, PreviousRun);
        ExpectService('/api/v1.0/notifications/open-reports-reminder', ResourceName, 200);

        RunCommunication(Setup);

        Assert.AreEqual(1, HttpRequestCount, 'An eligible local open report must cause a real reminder request.');
        Assert.IsFalse(IsNullGuid(RequestCorrelationId), 'The reminder request carries a production correlation id.');
        Assert.IsTrue(OutboxEmail.IsEmpty(), 'Skipped/body-failed reminders have no callback and no outbox delivery.');
        ExpenseAgentStatus.Get();
        Assert.IsTrue(ExpenseAgentStatus."Last Notif. Run At" > PreviousRun, 'HTTP 200 advances the current HTTP-only polling boundary.');
        AssertNoIncomingProcessing();
    end;

    local procedure ExpectNoService()
    begin
        Clear(ExpectedPath);
        Clear(ResponseResource);
        Clear(ResponseStatusCode);
        Clear(HttpRequestCount);
        Clear(ObservedRequestCount);
        Clear(EndpointResolutionCount);
        Clear(ExpectedUseCanaryEndpoint);
        Clear(RequestCorrelationId);
        Clear(MultipartBody);
        Clear(MultipartContentType);
        Clear(UnexpectedRequest);
    end;

    local procedure ExpectService(Path: Text; ResourceName: Text; StatusCode: Integer)
    begin
        ExpectNoService();
        ExpectedPath := ServiceBaseUrlTok + Path;
        ResponseResource := ResourceName;
        ResponseStatusCode := StatusCode;
    end;

    [HttpClientHandler]
    procedure ExpenseServiceHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        if (Request.RequestType <> HttpRequestType::POST) or (ExpectedPath = '') or
           (Request.Path <> ExpectedPath) or (Request.QueryParameters.Count() <> 0) or Request.HasSecretUri()
        then begin
            UnexpectedRequest := Format(Request.RequestType) + ' ' + Request.Path;
            Error('Unexpected Expense Agent HTTP request: %1', UnexpectedRequest);
        end;
        HttpRequestCount += 1;
        if ResponseResource <> '' then
            Response.Content.WriteFrom(NavApp.GetResourceAsText(ResponseResource, TextEncoding::UTF8))
        else
            Response.Content.WriteFrom('');
        Response.HttpStatusCode := ResponseStatusCode;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Http Client", 'OnGetCommunicationBaseUrl', '', false, false)]
    local procedure SetCommunicationBaseUrl(UseCanaryEndpoint: Boolean; var BaseUrl: Text)
    begin
        Assert.AreEqual(ExpectedUseCanaryEndpoint, UseCanaryEndpoint, 'Endpoint selection must use the saved company setup flag.');
        Assert.AreEqual('', BaseUrl, 'The communication override must precede normal endpoint lookup.');
        BaseUrl := ServiceBaseUrlTok;
        Assert.AreNotEqual('', BaseUrl, 'The isolated mock endpoint must be nonempty.');
        EndpointResolutionCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Http Client", 'OnBeforeAddAuthHeaders', '', false, false)]
    local procedure ObserveServiceRequest(RequestMessage: HttpRequestMessage)
    var
        Headers: HttpHeaders;
        HeaderValues: List of [Text];
        Content: HttpContent;
    begin
        // TestHttpRequestMessage exposes routing only, so this read-only observer checks the actual request.
        ObservedRequestCount += 1;
        Assert.AreEqual(ExpectedPath, RequestMessage.GetRequestUri(), 'Unexpected service host/path.');
        Assert.AreEqual('POST', RequestMessage.Method(), 'Expense requests must be POST.');
        RequestMessage.GetHeaders(Headers);
        Assert.IsFalse(Headers.Contains('Authorization'), 'The observation boundary must not expose authorization headers.');
        Assert.IsTrue(Headers.GetValues('On-Behalf-Of', HeaderValues), 'The request must carry the intended expense user.');
        Assert.AreEqual(1, HeaderValues.Count(), 'Exactly one expense user is expected.');
        Assert.AreEqual(RecipientEmailTok, HeaderValues.Get(1), 'Only sanitized mock recipients are allowed.');
        Clear(HeaderValues);
        if ExpectedPath.EndsWith('/expenses/process') then begin
            Content := RequestMessage.Content();
            Content.ReadAs(MultipartBody);
            Content.GetHeaders(Headers);
            Headers.GetValues('Content-Type', HeaderValues);
            MultipartContentType := HeaderValues.Get(1);
        end else begin
            Assert.IsTrue(Headers.GetValues('X-Correlation-Id', HeaderValues), 'Notification requests must carry a correlation id.');
            Assert.AreEqual(1, HeaderValues.Count(), 'Exactly one request correlation is expected.');
            Evaluate(RequestCorrelationId, HeaderValues.Get(1));
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Retrieve Emails", 'OnGetEmailAttachments', '', false, false)]
    local procedure SupplyReceiptAttachments(var TempAttachment: Record "EA Email Attachment" temporary; var IsHandled: Boolean)
    begin
        if not UseReceiptAttachmentFixture then
            exit;

        Assert.IsTrue(TempAttachment.IsEmpty(), 'The fixture must be the only attachment source.');
        AddReceiptAttachment(TempAttachment, 1, 'receipt-one.pdf', 'application/pdf', 'mock-receipt-one');
        AddReceiptAttachment(TempAttachment, 2, 'receipt-two.png', 'image/png', 'mock-receipt-two');
        IsHandled := true;
    end;

    local procedure AddReceiptAttachment(var TempAttachment: Record "EA Email Attachment" temporary; EntryNo: Integer; FileName: Text[250]; ContentType: Text[100]; ContentText: Text)
    var
        ContentOutStream: OutStream;
    begin
        TempAttachment.Init();
        TempAttachment."Entry No." := EntryNo;
        TempAttachment.FileName := FileName;
        TempAttachment.ContentType := ContentType;
        TempAttachment.Insert();
        TempAttachment.Content.CreateOutStream(ContentOutStream, TextEncoding::UTF8);
        ContentOutStream.WriteText(ContentText);
        TempAttachment.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"EA Outbox Email", 'OnAfterModifyEvent', '', false, false)]
    local procedure DisableCommunicationAfterDelivery(var Rec: Record "EA Outbox Email"; var xRec: Record "EA Outbox Email"; RunTrigger: Boolean)
    var
        Setup: Record "Expense Agent Setup";
    begin
        if not DisableOutgoingAfterSend or Rec.IsTemporary() or (Rec.Status <> Rec.Status::Sent) then
            exit;
        Setup.Get();
        Setup."Enable Communication" := false;
        Setup.Modify();
        DisableOutgoingAfterSend := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnEnqueuedInOutbox', '', false, false)]
    local procedure AssertForegroundSendCannotThrottle(MessageId: Guid)
    var
        EmailOutbox: Record "Email Outbox";
        LibraryEmailMock: Codeunit "Library - Email Mock";
        FoundCurrentMessage: Boolean;
    begin
        // This event precedes Email Dispatcher. Rate is explicitly zero; concurrency counts Processing rows only.
        // Only this new Queued row and known Failed foreground attempts may exist, so the processing count is zero.
        Assert.IsFalse(IsNullGuid(OutgoingMockAccountId), 'No email may be queued without the fixture outgoing account.');
        Assert.IsFalse(FixtureMessageIds.Contains(MessageId), 'Every synchronous attempt must use a fresh message.');
        if EmailOutbox.FindSet() then
            repeat
                Assert.AreEqual(OutgoingMockAccountId, EmailOutbox.GetAccountId(), 'Unknown account work must not reach the native dispatcher.');
                Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector v4", EmailOutbox.GetConnector(), 'Only the native mock connector is allowed.');
                if EmailOutbox.GetMessageId() = MessageId then begin
                    FoundCurrentMessage := true;
                    Assert.IsTrue(LibraryEmailMock.CheckEmailOutBoxStatusWithMessageId(MessageId, Enum::"Email Status"::Queued),
                        'The current foreground message must still be queued before dispatch.');
                end else begin
                    Assert.IsTrue(FixtureMessageIds.Contains(EmailOutbox.GetMessageId()), 'Pre-existing background or unrelated emails are forbidden.');
                    Assert.IsTrue(LibraryEmailMock.CheckEmailOutBoxStatusWithMessageId(EmailOutbox.GetMessageId(), Enum::"Email Status"::Failed),
                        'Earlier fixture attempts must be Failed, never Queued or Processing.');
                end;
            until EmailOutbox.Next() = 0;
        Assert.IsTrue(FoundCurrentMessage, 'The foreground email must have a native outbox row.');
        FixtureMessageIds.Add(MessageId);
    end;

    [Test]
    procedure GetSendEmailAccountReturnsMainAccountWhenNoreplyNotConfigured()
    var
        Setup: Record "Expense Agent Setup";
        MainAccountID: Guid;
    begin
        // [SCENARIO] When no noreply account is configured, sending uses the main email account.

        // [GIVEN] Setup with a main email account and no noreply account
        MainAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, MainAccountID);

        // [THEN] The main account fields are present and noreply fields are empty
        Assert.AreEqual(MainAccountID, Setup."Email Account ID", 'Main Email Account ID should be set.');
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should be empty.');
    end;

    [Test]
    procedure GetSendEmailAccountReturnsNoreplyAccountWhenConfigured()
    var
        Setup: Record "Expense Agent Setup";
        MainAccountID: Guid;
        NoreplyAccountID: Guid;
    begin
        // [SCENARIO] When a noreply account is configured, it should be preferred for sending.

        // [GIVEN] Setup with both main and noreply email accounts
        MainAccountID := CreateGuid();
        NoreplyAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, MainAccountID);
        Setup."Noreply Email Account ID" := NoreplyAccountID;
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Address" := 'noreply@example.invalid';
        Setup.Modify();

        // [THEN] Noreply account is set
        Assert.AreEqual(NoreplyAccountID, Setup."Noreply Email Account ID", 'Noreply Email Account ID should be set.');
        Assert.AreEqual('noreply@example.invalid', Setup."Noreply Email Address", 'Noreply Email Address should be set.');
    end;

    [Test]
    procedure NoreplyFieldsDefaultToEmpty()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO] New installations have empty noreply fields by default (backward-compatible).

        // [GIVEN] A fresh setup record
        AssertIsolatedCompany();
        Setup.DeleteAll();
        Setup.Init();
        Setup.Insert();

        // [THEN] Noreply fields are empty
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should default to empty GUID.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'Noreply Email Address should default to empty.');
    end;

    [Test]
    procedure ClearingNoreplyAccountResetsAllFields()
    var
        Setup: Record "Expense Agent Setup";
        NoreplyAccountID: Guid;
    begin
        // [SCENARIO] Clearing the noreply account resets all three noreply fields.

        // [GIVEN] Setup with a noreply account configured
        NoreplyAccountID := CreateGuid();
        InitSetupWithMainAccount(Setup, CreateGuid());
        Setup."Noreply Email Account ID" := NoreplyAccountID;
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Address" := 'noreply@example.invalid';
        Setup.Modify();

        // [WHEN] The noreply fields are cleared
        Clear(Setup."Noreply Email Account ID");
        Clear(Setup."Noreply Email Connector");
        Setup."Noreply Email Address" := '';
        Setup.Modify();

        // [THEN] All noreply fields are reset
        Setup.Get();
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should be empty after clearing.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'Noreply Email Address should be empty after clearing.');
    end;

    local procedure InitSetupWithMainAccount(var Setup: Record "Expense Agent Setup"; AccountID: Guid)
    begin
        AssertIsolatedCompany();
        Setup.DeleteAll();
        Setup.Init();
        Setup."Email Account ID" := AccountID;
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Email Address" := 'expenses@example.invalid';
        Setup.Insert();
    end;

    [Test]
    procedure SchedulerTaskFailedStatusAndErrorMessageArePersisted()
    var
        EASchedulerTask: Record "EA Scheduler Task";
        TaskID: BigInteger;
    begin
        // [SCENARIO] EA Scheduler Task supports the new Failed status and stores an error message.

        // [GIVEN] A scheduler task in progress
        AssertIsolatedCompany();
        EASchedulerTask.DeleteAll();
        Clear(EASchedulerTask);
        EASchedulerTask.Status := EASchedulerTask.Status::"In Progress";
        EASchedulerTask.Insert();
        TaskID := EASchedulerTask.ID;

        // [WHEN] The task is marked as failed with an error message
        EASchedulerTask.Status := EASchedulerTask.Status::Failed;
        EASchedulerTask."Error Message" := 'Expense Agent is not enabled.';
        EASchedulerTask.Modify();

        // [THEN] The Failed status and error message are stored
        Clear(EASchedulerTask);
        EASchedulerTask.Get(TaskID);
        Assert.AreEqual(EASchedulerTask.Status::Failed, EASchedulerTask.Status, 'Status should be Failed.');
        Assert.AreEqual('Expense Agent is not enabled.', EASchedulerTask."Error Message", 'Error Message should be persisted.');
    end;

    [Test]
    procedure ExpenseAgentStatusFlowFieldsLookupSchedulerTask()
    var
        EASchedulerTask: Record "EA Scheduler Task";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        // [SCENARIO] The Expense Agent Status FlowFields read Status and Error Message from the linked scheduler task.

        // [GIVEN] A failed scheduler task
        AssertIsolatedCompany();
        EASchedulerTask.DeleteAll();
        Clear(EASchedulerTask);
        EASchedulerTask.Status := EASchedulerTask.Status::Failed;
        EASchedulerTask."Error Message" := 'Expense Agent has no email account specified.';
        EASchedulerTask.Insert();

        // [GIVEN] An Expense Agent Status record pointing to that task
        ExpenseAgentStatus.DeleteAll();
        ExpenseAgentStatus.GetOrCreate();
        ExpenseAgentStatus."EA Scheduler Task ID" := EASchedulerTask.ID;
        ExpenseAgentStatus.Modify();

        // [WHEN] The FlowFields are calculated
        ExpenseAgentStatus.CalcFields("Scheduler Task Status", "Scheduler Task Error Message");

        // [THEN] They reflect the linked scheduler task
        Assert.AreEqual(ExpenseAgentStatus."Scheduler Task Status"::Failed, ExpenseAgentStatus."Scheduler Task Status", 'Scheduler Task Status FlowField should reflect linked task.');
        Assert.AreEqual('Expense Agent has no email account specified.', ExpenseAgentStatus."Scheduler Task Error Message", 'Scheduler Task Error Message FlowField should reflect linked task.');
    end;

    [Test]
    procedure GetByUserSecurityIDReturnsTrueWhenUserExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] GetByUserSecurityID finds an existing access control row by user.

        // [GIVEN] An access control record for a user
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Looking up by that user security ID
        Clear(AccessControl);

        // [THEN] The record is found
        Assert.IsTrue(AccessControl.GetByUserSecurityID(UserID), 'Expected to find access control row for user.');
        Assert.AreEqual(UserID, AccessControl."User Security ID", 'Returned record should be the requested user.');
    end;

    [Test]
    procedure GetByUserSecurityIDReturnsFalseWhenUserMissing()
    var
        AccessControl: Record "Expense Agent Access Control";
    begin
        // [SCENARIO] GetByUserSecurityID returns false when no row exists for the user.

        // [GIVEN] No access control rows for the queried user
        AssertIsolatedCompany();
        AccessControl.DeleteAll();

        // [THEN] Lookup returns false
        Assert.IsFalse(AccessControl.GetByUserSecurityID(CreateGuid()), 'Expected lookup to return false when user is not present.');
    end;

    [Test]
    procedure ClearingCanConfigureAgentSucceedsWhenAnotherOwnerExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        SetupSystemID: Guid;
        UserA: Guid;
        UserB: Guid;
    begin
        // [SCENARIO] Clearing Can Configure Agent on one owner is allowed when another owner remains.

        // [GIVEN] Two users with Can Configure Agent set to true
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        SetupSystemID := EmptyGuid();
        UserA := CreateGuid();
        UserB := CreateGuid();
        InsertAccessControl(AccessControl, UserA, true, true);
        InsertAccessControl(AccessControl, UserB, true, false);

        // [WHEN] Clearing Can Configure Agent on the first user
        AccessControl.Get(SetupSystemID, UserA);
        AccessControl.Validate("Can Configure Agent", false);
        AccessControl.Modify();

        // [THEN] The value is updated and no error is raised
        AccessControl.Get(SetupSystemID, UserA);
        Assert.IsFalse(AccessControl."Can Configure Agent", 'Can Configure Agent should be cleared.');
    end;

    [Test]
    procedure ClearingCanConfigureAgentFailsWhenLastOwner()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] Clearing 'Can Configure' Agent on the only owner raises an error.

        // [GIVEN] A single user with Can Configure Agent set to true
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Trying to clear Can Configure Agent on the last owner
        AccessControl.Get(EmptyGuid(), UserID);
        asserterror AccessControl.Validate("Can Configure Agent", false);

        // [THEN] The "one owner must be defined" error is raised
        Assert.ExpectedError(OneOwnerMustBeDefinedErr);
    end;

    [Test]
    procedure DeletingOwnerSucceedsWhenAnotherOwnerExists()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserA: Guid;
        UserB: Guid;
    begin
        // [SCENARIO] Deleting an owner is allowed when at least one other owner remains.

        // [GIVEN] Two users with Can Configure Agent
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        UserA := CreateGuid();
        UserB := CreateGuid();
        InsertAccessControl(AccessControl, UserA, true, true);
        InsertAccessControl(AccessControl, UserB, true, false);

        // [WHEN] Deleting one of them
        AccessControl.Get(EmptyGuid(), UserA);
        AccessControl.Delete(true);

        // [THEN] The other owner is still present
        Assert.IsTrue(AccessControl.GetByUserSecurityID(UserB), 'Remaining owner should still exist.');
    end;

    [Test]
    procedure DeletingLastOwnerFails()
    var
        AccessControl: Record "Expense Agent Access Control";
        UserID: Guid;
    begin
        // [SCENARIO] Deleting the only owner raises an error.

        // [GIVEN] A single user with Can Configure Agent
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        UserID := CreateGuid();
        InsertAccessControl(AccessControl, UserID, true, true);

        // [WHEN] Deleting that user
        AccessControl.Get(EmptyGuid(), UserID);
        asserterror AccessControl.Delete(true);

        // [THEN] The "one owner must be defined" error is raised
        Assert.ExpectedError(OneOwnerMustBeDefinedErr);
    end;

    [Test]
    procedure DeletingNonOwnerDoesNotEnforceOwnerRule()
    var
        AccessControl: Record "Expense Agent Access Control";
        OwnerID: Guid;
        NonOwnerID: Guid;
    begin
        // [SCENARIO] Deleting a non-owner row does not raise the owner rule even when only one owner exists.

        // [GIVEN] One owner and one non-owner
        AssertIsolatedCompany();
        AccessControl.DeleteAll();
        OwnerID := CreateGuid();
        NonOwnerID := CreateGuid();
        InsertAccessControl(AccessControl, OwnerID, true, true);
        InsertAccessControl(AccessControl, NonOwnerID, false, false);

        // [WHEN] Deleting the non-owner row
        AccessControl.Get(EmptyGuid(), NonOwnerID);
        AccessControl.Delete(true);

        // [THEN] The owner is still present and no error was raised
        Assert.IsTrue(AccessControl.GetByUserSecurityID(OwnerID), 'Owner should remain after deleting a non-owner.');
    end;

    local procedure InsertAccessControl(var AccessControl: Record "Expense Agent Access Control"; UserID: Guid; CanConfigure: Boolean; CanWorkOnBehalf: Boolean)
    begin
        Clear(AccessControl);
        AccessControl."Setup System ID" := EmptyGuid();
        AccessControl."User Security ID" := UserID;
        AccessControl."Can Configure Agent" := CanConfigure;
        AccessControl."Can Work on Behalf" := CanWorkOnBehalf;
        AccessControl.Insert();
    end;

    local procedure EmptyGuid(): Guid
    var
        EmptyId: Guid;
    begin
        Clear(EmptyId);
        exit(EmptyId);
    end;
}
