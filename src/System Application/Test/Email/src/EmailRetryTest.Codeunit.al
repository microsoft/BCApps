// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Email;

using System.Email;
using System.TestLibraries.Email;
using System.Environment;
using System.TestLibraries.Reflection;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134703 "Email Retry Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Message" = rd,
                  tabledata "Email Message Attachment" = rd,
                  tabledata "Email Recipient" = rd,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email Retry" = rimd,
                  tabledata "Email Inbox" = rimd,
                  tabledata "Scheduled Task" = rd,
                  tabledata "Sent Email" = rid,
                  tabledata "Email Rate Limit" = rimd;

    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Library Assert";
        Email: Codeunit Email;
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResendEmailFromEmailOutboxTest1()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRetry: Record "Email Retry";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] User can resend an email from the Email Outbox page when the email is failed and the retry process has completed.
        // When Status Failed and no retry records -> Re-sendable and not showing retry details
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Create the first email message without retry records
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        EmailOutbox := SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject1', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Processing, 10, true);

        // [When] Open the Email Outbox page and check the first email outbox record
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();

        // [Then] The Send Email and Show Retry Details actions are disabled
        Assert.IsFalse(EmailOutboxTestPage.SendEmail.Enabled(), 'Send Email action should be enabled for the first email outbox record because it is in Processing status');
        Assert.IsFalse(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should not be enabled for the first email outbox record because it doesn''t have any retry records');
        Assert.IsFalse(EmailOutboxTestPage.ShowError.Enabled(), 'Show Error action should not be enabled for the first email outbox record because it doesn''t have any retry records');
        Assert.IsFalse(EmailOutboxTestPage.ShowErrorCallStack.Enabled(), 'Show Error Call Stack action should not be enabled for the first email outbox record because it doesn''t have any retry records');
        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResendEmailFromEmailOutboxTest2()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRetry: Record "Email Retry";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] User can resend an email from the Email Outbox page when the email is failed and the retry process has completed
        // When Status Failed and Retry No. = 3 -> Not re-sendable and showing retry details
        // There are four email outbox records with different statuses and retry records are created:
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Create the second email message and retry record
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        EmailOutbox := SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject2', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Failed, 3, true);
        CreateMultipleEmailRetryRecords(3, EmailOutbox);
        // [When] Open the Email Outbox page and check the first email outbox record
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();
        // [Then] The Send Email is disabled, and Show Retry Details actions is enabled
        Assert.IsTrue(EmailOutboxTestPage.SendEmail.Enabled(), 'Send Email action should not be enabled for the second email outbox record because it only has 3 retries');
        Assert.IsTrue(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should be enabled for the second email outbox record');
        Assert.IsTrue(EmailOutboxTestPage.ShowError.Enabled(), 'Show Error action should not be enabled for the first email outbox record because it has retry records');
        Assert.IsTrue(EmailOutboxTestPage.ShowErrorCallStack.Enabled(), 'Show Error Call Stack action should not be enabled for the first email outbox record because it has retry records');
        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResendEmailFromEmailOutboxTest3()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRetry: Record "Email Retry";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] User can resend an email from the Email Outbox page when the email is failed and the retry process has completed
        // When Status Queued and Retry No. = 5 -> Not re-sendable and showing retry details
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Create the third email message and retry record
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        EmailOutbox := SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject3', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Processing, 5, true);
        CreateMultipleEmailRetryRecords(5, EmailOutbox);
        // [When] Open the Email Outbox page and check the first email outbox record
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();
        // [Then] The Send Email is disabled, and Show Retry Details actions is enabled
        Assert.IsFalse(EmailOutboxTestPage.SendEmail.Enabled(), 'Send Email action should not be enabled for the third email outbox record because it is in Processing status');
        Assert.IsTrue(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should be enabled for the third email outbox record');
        Assert.IsTrue(EmailOutboxTestPage.ShowError.Enabled(), 'Show Error action should not be enabled for the first email outbox record because it has retry records');
        Assert.IsTrue(EmailOutboxTestPage.ShowErrorCallStack.Enabled(), 'Show Error Call Stack action should not be enabled for the first email outbox record because it has retry records');
        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResendEmailFromEmailOutboxTest4()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRetry: Record "Email Retry";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] User can resend an email from the Email Outbox page when the email is failed and the retry process has completed
        // When Status Failed and Retry No. = 10 -> Re-sendable and showing retry details
        // When the user clicks on the Send Email action, the retry records should be deleted, and the "Retry No." should be set with 0.
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Create the forth email message and retry record
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        EmailOutbox := SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject4', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Failed, 10, true);
        CreateMultipleEmailRetryRecords(10, EmailOutbox);
        // [When] Open the Email Outbox page and check the first email outbox record
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();
        // [Then] The Send Email and Show Retry Details actions are enabled
        Assert.IsTrue(EmailOutboxTestPage.SendEmail.Enabled(), 'Send Email action should be enabled for the forth email outbox record with 10 retries');
        Assert.IsTrue(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should be enabled for the forth email outbox record');
        Assert.IsTrue(EmailOutboxTestPage.ShowError.Enabled(), 'Show Error action should not be enabled for the first email outbox record because it has retry records');
        Assert.IsTrue(EmailOutboxTestPage.ShowErrorCallStack.Enabled(), 'Show Error Call Stack action should not be enabled for the first email outbox record because it has retry records');

        // [When] The Send Email action is clicked
        EmailOutboxTestPage.SendEmail.Invoke();

        // [Then] The retry records are deleted, the Retry No. is reset to 0, and the status is set to Queued
        Assert.AreEqual(1, EmailOutboxTestPage."Retry No.".AsInteger(), 'The Retry No. should be reset to 1');
        Assert.AreEqual(Enum::"Email Status"::Queued, EmailOutboxTestPage.Status.AsInteger(), 'The Status should be reset to Queued');
        // Assert.AreEqual('Test Subject4', EmailOutboxTestPage.Desc.Value(), 'The Description should be the same as the email subject');
        Assert.IsFalse(EmailOutboxTestPage.SendEmail.Enabled(), 'Send Email action should be disabled after sending the email');
        Assert.IsFalse(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should be disabled after sending the email');
        Assert.IsFalse(EmailOutboxTestPage.ShowError.Enabled(), 'Show Error action should not be enabled for the first email outbox record because it doesn''t have any retry records');
        Assert.IsFalse(EmailOutboxTestPage.ShowErrorCallStack.Enabled(), 'Show Error Call Stack action should not be enabled for the first email outbox record because it doesn''t have any retry records');

        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CancelSendEmailFailedTest()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRetry: Record "Email Retry";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] User cannot cancel the email sending if it has completed.
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Create the email message and retry record
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        EmailOutbox := SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject4', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Failed, 10, true);
        CreateMultipleEmailRetryRecords(10, EmailOutbox);

        // [When] Open the Email Outbox page and check the first email outbox record
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();

        // [When] Cancel Retry action is clicked
        Assert.IsTrue(EmailOutboxTestPage.CancelRetry.Enabled(), 'Cancel Retry action should be enabled');
        asserterror EmailOutboxTestPage.CancelRetry.Invoke();

        // [Then] The error message is shown
        Assert.ExpectedError('We cannot cancel the retry of this email because the background task has completed');
        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EmailRetryDetailPageHandler')]
    procedure EnqueueEmailMessageFailedAndRetryTest()
    var
        EmailRetry: Record "Email Retry";
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
    begin
        // [Scenario] When call the email enqueue to send an email on the background and then fails, the email should be scheduled for retry
        // [Given] An email message and an email account are created
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.FailOnSend(true);
        // [Given] The email is enqueued in the outbox
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), true);

        // [WHEN] The sending task is run from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [THEN] The email outbox entry is updated with the error message and status
        EmailRetry.SetRange("Account Id", TempAccount."Account Id");
        EmailRetry.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailRetry.FindFirst(), 'The email retry entry should exist');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector".AsInteger(), EmailRetry.Connector.AsInteger(), 'Wrong connector');
        Assert.AreEqual(Enum::"Email Status"::Failed.AsInteger(), EmailRetry.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailRetry."Error Message", 'Wrong error message');
        Assert.AreEqual(1, EmailRetry."Retry No.", 'The retry number should be 1');
        Assert.AreEqual(2, EmailRetry.Count(), 'There are two entries in the Email Retry table');

        // [When] The Email Outbox page is opened and the retry detail is shown
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();
        Assert.IsTrue(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'Show Retry Details action should be enabled for the email outbox record');
        EmailOutboxTestPage.ShowRetryDetail.Invoke();
        // [Then] The Email Retry Detail page is opened with the correct entries in EmailRetryDetailPageHandler. All the button in the Email Retry Detail page are shown correctly.

        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendEmailMessageFromBackgroundFailedTest()
    var
        EmailRetry: Record "Email Retry";
        EmailOutbox: Record "Email Outbox";
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
        Connector: Enum "Email Connector";
        EmailStatus: Enum "Email Status";
        AccountId: Guid;
        ScheduledDateTime: DateTime;
    begin
        // [Scenario] When sending an email on the background and the process fails, an error is shown and the email is not rescheduled for retry
        //            This is because they are calling Email.Send() from the background, which does not support retry. Only Email.Enqueue() supports retry.
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(ClientType::Background);

        PermissionsMock.Set('Email Edit');
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] An email message and an email account
        CreateEmail(EmailMessage);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(AccountId);
        UpdateEmailMaxAttemptNo(AccountId, 10);

        // [When] Sending the email fails
        ConnectorMock.FailOnSend(true);
        ScheduledDateTime := CurrentDateTime();
        Assert.IsFalse(Email.Send(EmailMessage, AccountId, Connector::"Test Email Connector"), 'Sending an email should have failed');

        // [Then] The error is as expected
        EmailOutbox.SetRange("Account Id", AccountId);
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailOutbox.FindFirst(), 'The email outbox entry should exist');
        Assert.AreEqual(Connector::"Test Email Connector".AsInteger(), EmailOutbox.Connector.AsInteger(), 'Wrong connector');
        Assert.AreEqual(EmailStatus::Failed.AsInteger(), EmailOutbox.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailOutbox."Error Message", 'Wrong error message');
        Assert.IsTrue(EmailOutbox."Date Queued" > ScheduledDateTime, 'The Date Queued should be later than now');

        // [Then] There is no entry in the Email Retry table
        EmailRetry.SetRange("Account Id", AccountId);
        EmailRetry.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailRetry.IsEmpty(), 'There should be no entries in the Email Retry table for this message');

        // [When] The Email Outbox page is opened
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();

        // [Then] The show retry detail action is not enabled
        Assert.IsFalse(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'The Show Retry Detail action should not be visible when there is no retry entry');
        EmailOutboxPage.Close();
        UnBindSubscription(TestClientTypeSubscriber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendEmailMessageFromForegroundFailedTest()
    var
        EmailRetry: Record "Email Retry";
        EmailOutbox: Record "Email Outbox";
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        EmailOutboxPage: Page "Email Outbox";
        EmailOutboxTestPage: TestPage "Email Outbox";
        Connector: Enum "Email Connector";
        EmailStatus: Enum "Email Status";
        AccountId: Guid;
        ScheduledDateTime: DateTime;
    begin
        // [Scenario] When sending an email on the foreground and the process fails, an error is shown and the email is not rescheduled for retry
        PermissionsMock.Set('Email Edit');
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();

        // [Given] An email message and an email account
        CreateEmail(EmailMessage);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(AccountId);

        // [Given] The Email Rate Limit is set to 10 for the account
        UpdateEmailMaxAttemptNo(AccountId, 10);

        // [When] Sending the email fails
        ConnectorMock.FailOnSend(true);
        ScheduledDateTime := CurrentDateTime();
        Assert.IsFalse(Email.Send(EmailMessage, AccountId, Connector::"Test Email Connector"), 'Sending an email should have failed');

        // [Then] The error is as expected
        EmailOutbox.SetRange("Account Id", AccountId);
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailOutbox.FindFirst(), 'The email outbox entry should exist');
        Assert.AreEqual(Connector::"Test Email Connector".AsInteger(), EmailOutbox.Connector.AsInteger(), 'Wrong connector');
        Assert.AreEqual(EmailStatus::Failed.AsInteger(), EmailOutbox.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailOutbox."Error Message", 'Wrong error message');
        Assert.IsTrue(EmailOutbox."Date Queued" > ScheduledDateTime, 'The Date Queued should be later than now');

        // [Then] There is no entry in the Email Retry table
        EmailRetry.SetRange("Account Id", AccountId);
        EmailRetry.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailRetry.IsEmpty(), 'There should be no entries in the Email Retry table for this message');

        // [When] The Email Outbox page is opened
        EmailOutboxTestPage.Trap();
        EmailOutboxPage.SetRecord(EmailOutbox);
        EmailOutboxPage.Run();

        // [Then] The show retry detail action is not enabled
        Assert.IsFalse(EmailOutboxTestPage.ShowRetryDetail.Enabled(), 'The Show Retry Detail action should not be visible when there is no retry entry');
        EmailOutboxPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendEmailMessageForegroundExceedingMaxConcurrencyTest()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        OriginalScheduledDateTime: DateTime;
        OriginalTaskId: Guid;
    begin
        // [Scenario] When there are already too many emails being sent in the background, sending an email from the foreground should be rescheduled
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] Ten email messages and an email account are created
        CreateEmailMessageAndEmailOutboxRecord(10, TempAccount, false);

        // [Given] The 11st email is created and sent from the foreground
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Queued, 0, false);

        // [When] The 11st email is sent from the foreground
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        OriginalScheduledDateTime := EmailOutbox."Date Sending";
        OriginalTaskId := EmailOutbox."Task Scheduler Id";
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [Then] The sending task is rescheduled, and the email outbox entry is updated with the error message and status
        Assert.AreNotEqual(OriginalScheduledDateTime, EmailOutbox."Date Sending", 'The Date Sending should be updated');
        Assert.AreNotEqual(OriginalTaskId, EmailOutbox."Task Scheduler Id", 'The Task Scheduler Id should be updated');
        Assert.AreEqual(EmailOutbox.Status, EmailOutbox.Status::Queued, 'The status should not be Processing');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendEmailMessageBackgroundExceedingMaxConcurrencyTest()
    var
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRateLimit: Record "Email Rate Limit";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        OriginalScheduledDateTime: DateTime;
        OriginalTaskId: Guid;
    begin
        // [Scenario] When user is created, the default concurrency limit is 3. Then when user try to send 6 emails at the same time, part of them should be rescheduled.
        // Then user changes the concurrency limit to 10, and the 7th email should be sent immediately.
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 10);

        // [Given] 5 email messages and an email account are created
        CreateEmailMessageAndEmailOutboxRecord(5, TempAccount, true);

        // [Given] The 6st email is created
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Queued, 0, true);

        // [When] The 6st email is sent from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        OriginalScheduledDateTime := EmailOutbox."Date Sending";
        OriginalTaskId := EmailOutbox."Task Scheduler Id";
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [Then] The sending task is rescheduled, and the email outbox entry is updated with the error message and status
        Assert.AreNotEqual(OriginalScheduledDateTime, EmailOutbox."Date Sending", 'The Date Sending should be updated');
        Assert.AreNotEqual(OriginalTaskId, EmailOutbox."Task Scheduler Id", 'The Task Scheduler Id should be updated');
        Assert.AreEqual(EmailOutbox.Status, EmailOutbox.Status::Queued, 'The status should not be Processing');

        // [Given] The Email Rate Limit is set to 10 for the account
        EmailRateLimit.SetRange("Account Id", TempAccount."Account Id");
        Assert.IsTrue(EmailRateLimit.FindFirst(), 'The Email Rate Limit entry should exist');
        EmailRateLimit.Validate("Concurrency Limit", 10);
        EmailRateLimit.Modify();

        // [Given] The 7st email is created
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Queued, 0, true);

        // [When] The 7st email is sent from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailOutbox.FindFirst(), 'The Email Rate Limit entry should exist');
        OriginalScheduledDateTime := EmailOutbox."Date Sending";
        OriginalTaskId := EmailOutbox."Task Scheduler Id";
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [Then] The sending task is rescheduled, and the email outbox entry is updated with the error message and status
        Assert.AreEqual(EmailOutbox.Status::Processing, EmailOutbox.Status, 'The status should be Processing');
        Assert.AreEqual(OriginalScheduledDateTime, EmailOutbox."Date Sending", 'The Date Sending should not be updated');
        Assert.AreEqual(OriginalTaskId, EmailOutbox."Task Scheduler Id", 'The Task Scheduler Id should not be updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendEmailMessageBackgroundExceedingMaxConcurrencyForDifferentAccountsTest()
    var
        TempAccount1: Record "Email Account" temporary;
        TempAccount2: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        EmailRateLimit: Record "Email Rate Limit";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
        OriginalScheduledDateTime: DateTime;
        OriginalTaskId: Guid;
    begin
        // [Scenario] When two users are created, the account1's concurrency limit is changed to 10, and the account2's is 3.
        // Then when the account1 tries to send 11 emails at the same time, the 11th email should be rescheduled.
        // Then when the account2 tries to send 1 email, it should be sent immediately because the concurrency limit is 3.
        // Account1 and account2 are different accounts, so the concurrency limit is not shared between them.
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount1);
        ConnectorMock.AddAccount(TempAccount2);
        UpdateEmailMaxAttemptNo(TempAccount1."Account Id", 5);
        UpdateEmailMaxAttemptNo(TempAccount2."Account Id", 5);

        // [Given] The Email Rate Limit is set to 10 for the account1
        EmailRateLimit.SetRange("Account Id", TempAccount1."Account Id");
        Assert.IsTrue(EmailRateLimit.FindFirst(), 'The Email Rate Limit entry should exist');
        EmailRateLimit.Validate("Concurrency Limit", 10);
        EmailRateLimit.Modify();

        // [Given] 10 email messages and an email account are created
        CreateEmailMessageAndEmailOutboxRecord(10, TempAccount1, true);

        // [Given] The 11th email is created
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount1."Account Id", 'Test Subject', TempAccount1."Email Address", UserSecurityId(), Enum::"Email Status"::Queued, 0, true);

        // [When] The 11st email is sent from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        OriginalScheduledDateTime := EmailOutbox."Date Sending";
        OriginalTaskId := EmailOutbox."Task Scheduler Id";
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [Then] The sending task is rescheduled because of exceeding max concurrency limit, and the email outbox entry is updated with the error message and status
        Assert.AreNotEqual(OriginalScheduledDateTime, EmailOutbox."Date Sending", 'The Date Sending should be updated');
        Assert.AreNotEqual(OriginalTaskId, EmailOutbox."Task Scheduler Id", 'The Task Scheduler Id should be updated');
        Assert.AreEqual(EmailOutbox.Status::Queued, EmailOutbox.Status, 'The status should not be Processing');

        // [Given] A new email message is created for the account2
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount2."Account Id", 'Test Subject', TempAccount2."Email Address", UserSecurityId(), Enum::"Email Status"::Queued, 0, true);

        // [When] This email is sent from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailOutbox.FindFirst(), 'The Email Rate Limit entry should exist');
        OriginalScheduledDateTime := EmailOutbox."Date Sending";
        OriginalTaskId := EmailOutbox."Task Scheduler Id";
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [Then] The sending task is processing correctly, and the email outbox entry is updated with the error message and status
        Assert.AreEqual(EmailOutbox.Status::Processing, EmailOutbox.Status, 'The status should be Processing');
        Assert.AreEqual(OriginalScheduledDateTime, EmailOutbox."Date Sending", 'The Date Sending should not be updated');
        Assert.AreEqual(OriginalTaskId, EmailOutbox."Task Scheduler Id", 'The Task Scheduler Id should not be updated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMaxAttemptAmountUpdateTest()
    var
        EmailRetry: Record "Email Retry";
        TempAccount: Record "Email Account" temporary;
        EmailOutbox: Record "Email Outbox";
        Any: Codeunit Any;
        EmailMessage: Codeunit "Email Message";
        ConnectorMock: Codeunit "Connector Mock";
    begin
        // [Scenario] The default Email Max Attempt Amount is 1 which means it will not retry sending the email. When we change it to 2, it will retry sending the email 2 times.
        // [Given] An email message and an email account are created
        EmailRetry.DeleteAll();
        EmailOutbox.DeleteAll();
        PermissionsMock.Set('Email Edit');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);

        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.FailOnSend(true);
        // [Given] The email is enqueued in the outbox
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), true);

        // [WHEN] The sending task is run from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [THEN] The email outbox entry is updated with the error message and status
        EmailRetry.SetRange("Account Id", TempAccount."Account Id");
        EmailRetry.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailRetry.FindFirst(), 'The email retry entry should exist');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector".AsInteger(), EmailRetry.Connector.AsInteger(), 'Wrong connector');
        Assert.AreEqual(Enum::"Email Status"::Failed.AsInteger(), EmailRetry.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailRetry."Error Message", 'Wrong error message');
        Assert.AreEqual(1, EmailRetry."Retry No.", 'The retry number should be 1');
        Assert.AreEqual(1, EmailRetry.Count(), 'There are two entries in the Email Retry table');

        // [Given] The Email Rate Limit is set to 2 for the account
        UpdateEmailMaxAttemptNo(TempAccount."Account Id", 2);

        // [Given] The second email message is created
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
        Assert.IsTrue(EmailMessage.Get(EmailMessage.GetId()), 'The email should exist');
        ConnectorMock.FailOnSend(true);

        // [Given] The second email is enqueued in the outbox
        SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), true);

        // [WHEN] The sending task is run from the background
        EmailOutbox.SetRange("Message Id", EmailMessage.GetId());
        EmailOutbox.FindFirst();
        Codeunit.Run(Codeunit::"Email Dispatcher", EmailOutbox);

        // [THEN] The email outbox entry is updated with the error message and status
        EmailRetry.SetRange("Account Id", TempAccount."Account Id");
        EmailRetry.SetRange("Message Id", EmailMessage.GetId());
        Assert.IsTrue(EmailRetry.FindFirst(), 'The email retry entry should exist');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector".AsInteger(), EmailRetry.Connector.AsInteger(), 'Wrong connector');
        Assert.AreEqual(Enum::"Email Status"::Failed.AsInteger(), EmailRetry.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailRetry."Error Message", 'Wrong error message');
        Assert.AreEqual(1, EmailRetry."Retry No.", 'The retry number should be 1');
        Assert.AreEqual(2, EmailRetry.Count(), 'There are two entries in the Email Retry table');
    end;

    local procedure SetupEmailOutbox(EmailMessageId: Guid; Connector: Enum "Email Connector"; EmailAccountId: Guid; EmailDescription: Text; EmailAddress: Text[250]; UserSecurityId: Code[50]; IsBackground: Boolean)
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.Validate("Message Id", EmailMessageId);
        EmailOutbox.Insert();
        EmailOutbox.Validate(Connector, Connector);
        EmailOutbox.Validate("Account Id", EmailAccountId);
        EmailOutbox.Validate(Description, EmailDescription);
        EmailOutbox.Validate("User Security Id", UserSecurityId);
        EmailOutbox.Validate("Send From", EmailAddress);
        EmailOutbox.Validate("Is Background Task", IsBackground);
        EmailOutbox.Modify();
    end;

    local procedure CreateEmailMessageAndEmailOutboxRecord(NumberOfRecords: Integer; TempAccount: Record "Email Account"; IsBackground: Boolean)
    var
        EmailMessage: Codeunit "Email Message";
        Any: Codeunit Any;
        i: Integer;
    begin
        for i := 0 to NumberOfRecords do begin
            EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
            // [Given] The email is enqueued in the outbox
            SetupEmailOutbox(EmailMessage.GetId(), Enum::"Email Connector"::"Test Email Connector", TempAccount."Account Id", 'Test Subject', TempAccount."Email Address", UserSecurityId(), Enum::"Email Status"::Processing, i, IsBackground);
        end;
    end;

    local procedure SetupEmailOutbox(EmailMessageId: Guid; Connector: Enum "Email Connector"; EmailAccountId: Guid; EmailDescription: Text; EmailAddress: Text[250]; UserSecurityId: Code[50]; Status: Enum "Email Status"; RetryCount: Integer; IsBackground: Boolean): Record "Email Outbox"
    var
        EmailOutbox: Record "Email Outbox";
    begin
        EmailOutbox.Validate("Message Id", EmailMessageId);
        EmailOutbox.Insert();
        EmailOutbox.Validate(Connector, Connector);
        EmailOutbox.Validate("Account Id", EmailAccountId);
        EmailOutbox.Validate(Description, EmailDescription);
        EmailOutbox.Validate("User Security Id", UserSecurityId);
        EmailOutbox.Validate("Send From", EmailAddress);
        EmailOutbox.Validate(Status, Status);
        EmailOutbox.Validate("Retry No.", RetryCount);
        EmailOutbox.Validate("Is Background Task", IsBackground);
        EmailOutbox.Modify();
        exit(EmailOutbox);
    end;

    local procedure CreateMultipleEmailRetryRecords(NumberOfRecords: Integer; EmailOutbox: Record "Email Outbox")
    var
        i: Integer;
    begin
        for i := 1 to NumberOfRecords do
            CreateEmailRetryRecord(EmailOutbox."Message Id", EmailOutbox.Connector, EmailOutbox."Account Id", EmailOutbox.Description, EmailOutbox."Send From", EmailOutbox."User Security Id");
    end;

    local procedure CreateEmailRetryRecord(EmailMessageId: Guid; Connector: Enum "Email Connector"; EmailAccountId: Guid; EmailDescription: Text; EmailAddress: Text[250]; UserSecurityId: Code[50])
    var
        EmailRetry: Record "Email Retry";
    begin
        EmailRetry.Validate("Message Id", EmailMessageId);
        EmailRetry.Insert();
        EmailRetry.Validate(Connector, Connector);
        EmailRetry.Validate("Account Id", EmailAccountId);
        EmailRetry.Validate(Description, EmailDescription);
        EmailRetry.Validate("User Security Id", UserSecurityId);
        EmailRetry.Validate("Send From", EmailAddress);
        EmailRetry.Modify();
    end;

    local procedure UpdateEmailMaxAttemptNo(AccountId: Guid; ConcurrencyLimit: Integer)
    var
        EmailRateLimit: Record "Email Rate Limit";
    begin
        EmailRateLimit.SetRange("Account Id", AccountId);
        Assert.IsTrue(EmailRateLimit.FindFirst(), 'The Email Rate Limit entry should exist');
        EmailRateLimit.Validate("Max. Retry Limit", ConcurrencyLimit);
        EmailRateLimit.Modify();
    end;

    local procedure CreateEmail(var EmailMessage: Codeunit "Email Message")
    var
        Any: Codeunit Any;
    begin
        EmailMessage.Create(Any.Email(), Any.UnicodeText(50), Any.UnicodeText(250), true);
    end;

    [ModalPageHandler]
    procedure EmailRetryDetailPageHandler(var EmailRetryDetailPage: TestPage "Email Retry Detail")
    begin
        Assert.IsTrue(EmailRetryDetailPage.First(), 'The first Email Retry Detail should be shown');
        Assert.AreEqual(Enum::"Email Status"::Failed.AsInteger(), EmailRetryDetailPage.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('Failed to send email', EmailRetryDetailPage."Error Message".Value(), 'Wrong error message');
        Assert.AreEqual(1, EmailRetryDetailPage."Retry No.".AsInteger(), 'The retry number should be 1');
        Assert.IsTrue(EmailRetryDetailPage.ShowError.Enabled(), 'The Show Error action should be enabled');
        Assert.IsTrue(EmailRetryDetailPage.ShowErrorCallStack.Enabled(), 'The Show Error Call Stack action should be enabled');

        Assert.IsTrue(EmailRetryDetailPage.Next(), 'The second Email Retry Detail should be shown');
        Assert.AreEqual(Enum::"Email Status"::Queued.AsInteger(), EmailRetryDetailPage.Status.AsInteger(), 'Wrong status');
        Assert.AreEqual('', EmailRetryDetailPage."Error Message".Value(), 'Wrong error message');
        Assert.AreEqual(2, EmailRetryDetailPage."Retry No.".AsInteger(), 'The retry number should be 1');
        Assert.AreEqual('', EmailRetryDetailPage."Date Failed".Value(), 'The Date Failed should be empty');
        Assert.IsFalse(EmailRetryDetailPage.ShowError.Enabled(), 'The Show Error action should be enabled');
        Assert.IsFalse(EmailRetryDetailPage.ShowErrorCallStack.Enabled(), 'The Show Error Call Stack action should be enabled');

        Assert.IsFalse(EmailRetryDetailPage.Next(), 'There should be no more Email Retry Details');
    end;
}