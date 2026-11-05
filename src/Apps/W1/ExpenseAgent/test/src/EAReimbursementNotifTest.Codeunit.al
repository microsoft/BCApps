// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148336 "EA Reimbursement Notif. Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        AgentNotEnabledErr: Label 'Please make sure the Expense Agent is active.';
        CommunicationDisabledErr: Label 'Sending emails to users is turned off. Turn on Communication for the Expense Agent before sending reimbursement notifications.';
        NoNoreplyAccountErr: Label 'No account is set for sending emails. Set the send mail account for the Expense Agent before sending reimbursement notifications.';
        ReimbursementCannotBeSentErr: Label 'Reimbursement notification cannot be sent as the reimbursable amount is 0.';

    [Test]
    procedure ReimbursementNotificationFailEarlyGuards()
    var
        Setup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        PostedExpReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 636970] The manual "send reimbursement notification" action fails early with a
        // clear error for every unmet precondition, instead of silently doing nothing.
        // Each guard is isolated by satisfying the previous one and asserting the next error. The
        // success path is not covered here as it performs a live HTTP call.

        // [GIVEN] An expense user without an e-mail, and a posted report that references it.
        InitReimbursementScenario(Setup, ExpenseUser, PostedExpReportHeader);

        // [GIVEN] The agent is disabled.
        Setup."Enable Agent" := false;
        Setup.Modify();
        Commit();

        // [THEN] Sending errors because the agent is not active.
        Clear(ExpenseReportPost);
        asserterror ExpenseReportPost.CheckAndSendReimbursementNotification(PostedExpReportHeader);
        Assert.ExpectedError(AgentNotEnabledErr);

        // [GIVEN] The agent is enabled but communication is off.
        Setup."Enable Agent" := true;
        Setup."Enable Communication" := false;
        Setup.Modify();
        Commit();

        // [THEN] Sending errors because outgoing communication is turned off.
        Clear(ExpenseReportPost);
        asserterror ExpenseReportPost.CheckAndSendReimbursementNotification(PostedExpReportHeader);
        Assert.ExpectedError(CommunicationDisabledErr);

        // [GIVEN] Communication is on but no no-reply account is set.
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");
        Setup.Modify();
        Commit();

        // [THEN] Sending errors because there is no no-reply sender account.
        Clear(ExpenseReportPost);
        asserterror ExpenseReportPost.CheckAndSendReimbursementNotification(PostedExpReportHeader);
        Assert.ExpectedError(NoNoreplyAccountErr);

        // [GIVEN] A no-reply account is set, but the expense user has no e-mail.
        Setup."Noreply Email Account ID" := CreateGuid();
        Setup.Modify();
        Commit();

        // [THEN] Sending errors because the recipient has no e-mail address (platform TestField error).
        Clear(ExpenseReportPost);
        asserterror ExpenseReportPost.CheckAndSendReimbursementNotification(PostedExpReportHeader);

        // [GIVEN] The expense user now has an e-mail, but the report has a zero reimbursable amount.
        ExpenseUser."E-mail" := 'employee@contoso.com';
        ExpenseUser.Modify();
        Commit();

        // [THEN] Sending errors because there is nothing to reimburse.
        Clear(ExpenseReportPost);
        asserterror ExpenseReportPost.CheckAndSendReimbursementNotification(PostedExpReportHeader);
        Assert.ExpectedError(ReimbursementCannotBeSentErr);
    end;

    local procedure InitReimbursementScenario(var Setup: Record "Expense Agent Setup"; var ExpenseUser: Record "Expense User"; var PostedExpReportHeader: Record "Posted Expense Report Header")
    begin
        Setup.DeleteAll();
        Setup.Init();
        Setup."Primary Key" := '';
        Setup.Insert();

        ExpenseUser.Init();
        ExpenseUser."No." := LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User");
        ExpenseUser."E-mail" := '';
        ExpenseUser.Insert();

        PostedExpReportHeader.Init();
        PostedExpReportHeader."No." := LibraryUtility.GenerateRandomCode(PostedExpReportHeader.FieldNo("No."), Database::"Posted Expense Report Header");
        PostedExpReportHeader."Expense User No." := ExpenseUser."No.";
        PostedExpReportHeader.Insert();
        Commit();
    end;
}
