// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148334 "Welcome Email Queue Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler')]
    procedure SendWelcomeEmailQueuesUserInsteadOfSendingSynchronously()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Send Welcome Email queues the user; the actual send is deferred to the agent.
        // [GIVEN] An enabled agent and an expense user with an email and no welcome email sent yet.
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);

        // [WHEN] Send Welcome Email is triggered for the user.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user's welcome email status is Queued (not sent synchronously).
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'Welcome email should be queued.');
    end;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler,ConfirmYesHandler')]
    procedure ResendToAlreadySentUserRequeuesWhenConfirmed()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Resending to an already-sent user is allowed after confirmation.
        // [GIVEN] An expense user whose welcome email was already sent.
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Sent;
        ExpenseUser.Modify();

        // [WHEN] Send Welcome Email is triggered and the resend confirmation is accepted.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user is re-queued.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'Already-sent user should be re-queued after confirmation.');
    end;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler,ConfirmNoHandler')]
    procedure ResendToAlreadySentUserSkippedWhenDeclined()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Declining the resend confirmation keeps already-sent users as Sent.
        // [GIVEN] An expense user whose welcome email was already sent.
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Sent;
        ExpenseUser.Modify();

        // [WHEN] Send Welcome Email is triggered and the resend confirmation is declined.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user remains Sent.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Sent, ExpenseUser."Welcome Email Status", 'Declined resend should keep status Sent.');
    end;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler,ConfirmYesHandler')]
    procedure ResendToInOutboxUserRequeuesWhenConfirmed()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Resending to a user whose welcome email is still In Outbox is allowed after confirmation.
        // [GIVEN] An expense user whose welcome email is In Outbox (handed off, awaiting delivery).
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::"In Outbox";
        ExpenseUser.Modify();

        // [WHEN] Send Welcome Email is triggered and the resend confirmation is accepted.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user is re-queued.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'In Outbox user should be re-queued after confirmation.');
    end;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler,ConfirmNoHandler')]
    procedure ResendToInOutboxUserSkippedWhenDeclined()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Declining the resend keeps an In Outbox user as In Outbox.
        // [GIVEN] An expense user whose welcome email is In Outbox.
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::"In Outbox";
        ExpenseUser.Modify();

        // [WHEN] Send Welcome Email is triggered and the resend confirmation is declined.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user remains In Outbox.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", 'Declined resend should keep status In Outbox.');
    end;

    [Test]
    [HandlerFunctions('WelcomeQueuedMsgHandler')]
    procedure FailedUserIsRequeuedWithoutConfirmation()
    var
        ExpenseUser: Record "Expense User";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] A previously Failed welcome email can be resent without a confirmation prompt.
        // [GIVEN] An expense user whose welcome email failed.
        EnableAgentWithCommunication();
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Failed;
        ExpenseUser.Modify();

        // [WHEN] Send Welcome Email is triggered (no ConfirmHandler needed => no prompt expected).
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] The user is re-queued.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Queued, ExpenseUser."Welcome Email Status", 'Failed user should be re-queued without confirmation.');
    end;

    [Test]
    procedure SendWelcomeEmailBlockedWhenCommunicationOff()
    var
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SelectedExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 636970] Welcome emails cannot be queued when outgoing communication is turned off.
        // [GIVEN] An enabled agent with Enable Communication = false and an expense user.
        EnableAgentWithCommunication();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Communication" := false;
        ExpenseAgentSetup.Modify();
        CreateExpenseUserWithEmail(ExpenseUser);

        // [WHEN] Send Welcome Email is triggered.
        SelectedExpenseUser.SetRange("No.", ExpenseUser."No.");
        asserterror ExpenseUser.SendWelcomeEmail(SelectedExpenseUser);

        // [THEN] It errors because communication is turned off, so nothing is queued.
        Assert.ExpectedError('Sending emails to users is turned off. Turn on communication for the Expense Agent before sending welcome emails.');
    end;

    [Test]
    procedure HandoffSuccessSetsInOutboxAndStoresCorrelationId()
    var
        ExpenseUser: Record "Expense User";
        CorrelationId: Guid;
    begin
        // [SCENARIO 636970] A successful hop-1 handoff sets the status to In Outbox and stores the correlation id.
        // [GIVEN] A queued expense user and a correlation id.
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Queued;
        ExpenseUser.Modify();
        CorrelationId := CreateGuid();

        // [WHEN] The hop-1 handoff result is recorded as successful.
        ExpenseUser.SetWelcomeEmailHandoffResult(true, CorrelationId);

        // [THEN] The user is In Outbox with the correlation id stored.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", 'Successful handoff should set In Outbox.');
        Assert.AreEqual(CorrelationId, ExpenseUser."Welcome Correlation Id", 'Correlation id should be stored on the user.');
    end;

    [Test]
    procedure HandoffFailureSetsFailedAndClearsCorrelationId()
    var
        ExpenseUser: Record "Expense User";
        NullGuid: Guid;
    begin
        // [SCENARIO 636970] A failed hop-1 handoff sets the status to Failed and clears the correlation id.
        // [GIVEN] A queued expense user.
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::Queued;
        ExpenseUser.Modify();

        // [WHEN] The hop-1 handoff result is recorded as failed.
        ExpenseUser.SetWelcomeEmailHandoffResult(false, CreateGuid());

        // [THEN] The user is Failed with no correlation id.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Failed, ExpenseUser."Welcome Email Status", 'Failed handoff should set Failed.');
        Assert.AreEqual(NullGuid, ExpenseUser."Welcome Correlation Id", 'Correlation id should be cleared on failure.');
    end;

    [Test]
    procedure DeliveryByCorrelationSetsSent()
    var
        ExpenseUser: Record "Expense User";
        CorrelationId: Guid;
    begin
        // [SCENARIO 636970] A successful outbox delivery (hop-2) flips the matching In Outbox user to Sent.
        // [GIVEN] An In Outbox expense user with a correlation id.
        CorrelationId := CreateGuid();
        CreateInOutboxUser(ExpenseUser, CorrelationId);

        // [WHEN] The outbox delivery result is applied for that correlation id.
        ExpenseUser.ApplyWelcomeDeliveryResult(CorrelationId, true);

        // [THEN] The user is Sent with a sent timestamp.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Sent, ExpenseUser."Welcome Email Status", 'Delivered welcome should set Sent.');
        Assert.AreNotEqual(0DT, ExpenseUser."Welcome Email Sent At", 'Sent timestamp should be set.');
    end;

    [Test]
    procedure DeliveryFailureByCorrelationSetsFailed()
    var
        ExpenseUser: Record "Expense User";
        CorrelationId: Guid;
    begin
        // [SCENARIO 636970] A failed outbox delivery (hop-2) flips the matching In Outbox user to Failed.
        // [GIVEN] An In Outbox expense user with a correlation id.
        CorrelationId := CreateGuid();
        CreateInOutboxUser(ExpenseUser, CorrelationId);

        // [WHEN] The outbox delivery result is applied as failed.
        ExpenseUser.ApplyWelcomeDeliveryResult(CorrelationId, false);

        // [THEN] The user is Failed.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::Failed, ExpenseUser."Welcome Email Status", 'Failed delivery should set Failed.');
    end;

    [Test]
    procedure DeliveryWithoutCorrelationLeavesUserInOutbox()
    var
        ExpenseUser: Record "Expense User";
        CorrelationId: Guid;
        NullGuid: Guid;
    begin
        // [SCENARIO 636970] Version tolerance: an outbox row with no correlation id (older service) must not flip any user.
        // [GIVEN] An In Outbox expense user with a correlation id.
        CorrelationId := CreateGuid();
        CreateInOutboxUser(ExpenseUser, CorrelationId);

        // [WHEN] A delivery result is applied with a null correlation id.
        ExpenseUser.ApplyWelcomeDeliveryResult(NullGuid, true);

        // [THEN] The user stays In Outbox (no accidental flip).
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(ExpenseUser."Welcome Email Status"::"In Outbox", ExpenseUser."Welcome Email Status", 'A row without a correlation id must not change user status.');
    end;

    [Test]
    procedure OutboxCorrelationFieldsRoundTrip()
    var
        OutboxEmail: Record "EA Outbox Email";
        CorrelationId: Guid;
    begin
        // [SCENARIO 636970] The EA Outbox Email correlation id and notification type persist as written.
        // [GIVEN] A correlation id.
        CorrelationId := CreateGuid();

        // [WHEN] An outbox email is created with the correlation fields.
        OutboxEmail.Init();
        OutboxEmail."Correlation Id" := CorrelationId;
        OutboxEmail."Notification Type" := OutboxEmail."Notification Type"::Welcome;
        OutboxEmail.Insert();

        // [THEN] They are persisted.
        OutboxEmail.Get(OutboxEmail.Id);
        Assert.AreEqual(CorrelationId, OutboxEmail."Correlation Id", 'Correlation id should round-trip.');
        Assert.AreEqual(OutboxEmail."Notification Type"::Welcome, OutboxEmail."Notification Type", 'Notification type should round-trip.');
    end;

    local procedure CreateExpenseUserWithEmail(var ExpenseUser: Record "Expense User")
    begin
        ExpenseUser.Init();
        ExpenseUser."No." := LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User");
        ExpenseUser."E-mail" := 'user@contoso.com';
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::None;
        ExpenseUser.Insert();
    end;

    local procedure EnableAgentWithCommunication()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Communication" := true;
        ExpenseAgentSetup."Noreply Email Account ID" := CreateGuid();
        ExpenseAgentSetup.Modify();
    end;

    local procedure CreateInOutboxUser(var ExpenseUser: Record "Expense User"; CorrelationId: Guid)
    begin
        CreateExpenseUserWithEmail(ExpenseUser);
        ExpenseUser."Welcome Email Status" := ExpenseUser."Welcome Email Status"::"In Outbox";
        ExpenseUser."Welcome Correlation Id" := CorrelationId;
        ExpenseUser.Modify();
    end;

    [MessageHandler]
    procedure WelcomeQueuedMsgHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
