// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Security.AccessControl;
using System.Security.User;

codeunit 148342 "Expense Activity Log Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    procedure OnlySnapshotEventsCaptureFinancialValues()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EventType: Enum "Expense Activity Event Type";
        EntryNo: BigInteger;
        EventTypeIndex: Integer;
        SnapshotEventCount: Integer;
        EventTypeOrdinals: List of [Integer];
        SnapshotExpected: Boolean;
    begin
        // [SCENARIO] Financial and content snapshots are stored only for snapshot event types.
        // [GIVEN] A report with financial values, two categories, and one receipt-bearing line.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        ExpenseReportHeader."Reimbursement Currency Code" := 'USD';
        ExpenseReportHeader."Reimbursement Currency Factor" := 1.25;
        ExpenseReportLine."Document No." := ExpenseReportHeader."No.";
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Amount (LCY)" := 120;
        ExpenseReportLine."Non-Refundable Amount (LCY)" := 20;
        ExpenseReportLine."Reimbursable Amount" := 80;
        ExpenseReportLine."Reimbursable Amount (LCY)" := 75;
        ExpenseReportLine."Refundable Amount" := 25;
        ExpenseReportLine."Refundable Amount (LCY)" := 25;
        ExpenseReportLine."Expense Category" := 'MEALS';
        ExpenseReportLine."Receipt Attached" := true;
        ExpenseReportLine.Insert();
        Clear(ExpenseReportLine);
        ExpenseReportLine."Document No." := ExpenseReportHeader."No.";
        ExpenseReportLine."Line No." := 20000;
        ExpenseReportLine."Expense Category" := 'TRAVEL';
        ExpenseReportLine.Insert();

        // [WHEN] Every concrete activity event type is logged.
        EventTypeOrdinals := EventType.Ordinals();
        for EventTypeIndex := 1 to EventTypeOrdinals.Count() do begin
            EventType := Enum::"Expense Activity Event Type".FromInteger(EventTypeOrdinals.Get(EventTypeIndex));
            if EventType.AsInteger() <> 0 then begin
                EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
                    ExpenseReportHeader,
                    EventType,
                    Enum::"Expense Activity Initiator"::User,
                    Enum::"Expense Activity Actor Role"::Submitter,
                    ExpenseUser."No.",
                    '');

                ExpenseActivityLogEntry.Get(EntryNo);
                SnapshotExpected := EventType in [EventType::Submitted, EventType::Resubmitted, EventType::Posted];

                // [THEN] Common identity, actor, and event metadata are always persisted.
                Assert.AreEqual(Database::"Expense Report Header", ExpenseActivityLogEntry."Source Table ID", 'Source table ID must identify the expense report.');
                Assert.AreEqual(ExpenseReportHeader.SystemId, ExpenseActivityLogEntry."Source Record System ID", 'Source SystemId must identify the expense report.');
                Assert.AreEqual(ExpenseReportHeader.SystemId, ExpenseActivityLogEntry."Subject System ID", 'Subject SystemId must remain the stable report identity.');
                Assert.AreEqual(Database::"Expense User", ExpenseActivityLogEntry."Actor Table ID", 'Actor table ID must identify the Expense User table.');
                Assert.AreEqual(ExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'Actor SystemId must identify the expense user.');
                Assert.AreEqual(ExpenseUser.Name, ExpenseActivityLogEntry."Actor Display Name", 'Actor display name must be captured as a snapshot.');
                Assert.AreEqual(EventType, ExpenseActivityLogEntry."Event Type", 'Event type must be persisted.');
                Assert.AreEqual(Enum::"Expense Activity Initiator"::User, ExpenseActivityLogEntry."Initiated By", 'Initiator must be persisted.');
                Assert.AreEqual(Enum::"Expense Activity Actor Role"::Submitter, ExpenseActivityLogEntry."Actor Role", 'Actor role must be persisted.');

                // [THEN] Only Submitted, Resubmitted, and Posted contain financial and content snapshots.
                if SnapshotExpected then begin
                    SnapshotEventCount += 1;
                    Assert.AreEqual(120, ExpenseActivityLogEntry."Amount (LCY)", 'Total amount in LCY must be persisted.');
                    Assert.AreEqual(20, ExpenseActivityLogEntry."Non-Refundable Amount (LCY)", 'Non-refundable amount in LCY must be persisted.');
                    Assert.AreEqual(80, ExpenseActivityLogEntry."Reimbursable Amount", 'Reimbursable amount must be persisted.');
                    Assert.AreEqual(75, ExpenseActivityLogEntry."Reimbursable Amount (LCY)", 'Reimbursable amount in LCY must be persisted.');
                    Assert.AreEqual(25, ExpenseActivityLogEntry."Refundable Amount", 'Refundable amount must be persisted.');
                    Assert.AreEqual(25, ExpenseActivityLogEntry."Refundable Amount (LCY)", 'Refundable amount in LCY must be persisted.');
                    Assert.AreEqual(2, ExpenseActivityLogEntry."Expense Count", 'Expense count must include every report line.');
                    Assert.AreEqual(1, ExpenseActivityLogEntry."Attached Receipt Count", 'Attached receipt count must include only report lines with an attached receipt.');
                    Assert.AreEqual('USD', ExpenseActivityLogEntry."Reimbursement Currency Code", 'Reimbursement currency code must be persisted.');
                    Assert.AreEqual(1.25, ExpenseActivityLogEntry."Reimbursement Currency Factor", 'Reimbursement currency factor must be persisted.');
                    Assert.AreNotEqual('', ExpenseActivityLogEntry.Categories, 'Snapshot events must persist categories.');
                end else begin
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Amount (LCY)", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Non-Refundable Amount (LCY)", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Reimbursable Amount", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Reimbursable Amount (LCY)", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Refundable Amount", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Refundable Amount (LCY)", 'Non-snapshot events must not duplicate financial values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Expense Count", 'Non-snapshot events must not duplicate expense counts.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Attached Receipt Count", 'Non-snapshot events must not duplicate attached receipt counts.');
                    Assert.AreEqual('', ExpenseActivityLogEntry."Reimbursement Currency Code", 'Non-snapshot events must not duplicate currency values.');
                    Assert.AreEqual(0, ExpenseActivityLogEntry."Reimbursement Currency Factor", 'Non-snapshot events must not duplicate currency values.');
                    Assert.AreEqual('', ExpenseActivityLogEntry.Categories, 'Non-snapshot events must not duplicate categories.');
                end;
            end;
        end;

        Assert.AreEqual(3, SnapshotEventCount, 'Exactly three activity event types must capture snapshots.');
    end;

    [Test]
    procedure CreatedEventFallsBackToBCUserActor()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        User: Record User;
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EmptyGuid: Guid;
        EntryNo: BigInteger;
    begin
        // [SCENARIO] Retrospective creation identifies the direct BC user when no Expense User creator was stored.
        // [GIVEN] A report with a platform creator but no Created By Expense User Id.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        ExpenseReportHeader."Created By Exp. User Id" := EmptyGuid;
        ExpenseReportHeader.Modify(false);
        User.Get(ExpenseReportHeader.SystemCreatedBy);

        // [WHEN] The retrospective Created entry is logged.
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportCreatedEvent(ExpenseReportHeader);

        // [THEN] The actor points to the BC User record identified by SystemCreatedBy.
        ExpenseActivityLogEntry.Get(EntryNo);
        Assert.AreEqual(Database::User, ExpenseActivityLogEntry."Actor Table ID", 'Created activity must identify the BC User table.');
        Assert.AreEqual(User.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'Created activity must identify the BC User record.');
        Assert.AreEqual(ExpenseReportHeader.SystemCreatedAt, ExpenseActivityLogEntry."Occurred At", 'Created activity must use the source record creation timestamp.');
    end;

    [Test]
    procedure ApprovalLifecycleLogsImportantEvents()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] The approval lifecycle records creation, submission, rejection, resubmission, and approval.
        // [GIVEN] A released expense report with a submitter and approver.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);

        // [WHEN] The report is submitted, rejected, resubmitted, and approved.
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        ExpenseReportApprovalMgt.Reject(ExpenseReportHeader, ApproverExpenseUser."No.", 'Please explain the change.');
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.", 'Updated the justification.');
        ExpenseReportApprovalMgt.Approve(ExpenseReportHeader, ApproverExpenseUser."No.");

        // [THEN] The report has the expected ordered activity entries.
        ExpenseActivityLogEntry.SetRange("Subject Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetCurrentKey("Entry No.");
        ExpenseActivityLogEntry.FindSet();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Created, ExpenseActivityLogEntry."Event Type", 'The first entry must record report creation.');
        Assert.AreEqual(ExpenseReportHeader.SystemCreatedAt, ExpenseActivityLogEntry."Occurred At", 'The creation entry must use the report creation timestamp.');
        ExpenseActivityLogEntry.Next();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Submitted, ExpenseActivityLogEntry."Event Type", 'The second entry must record first submission.');
        ExpenseActivityLogEntry.Next();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Rejected, ExpenseActivityLogEntry."Event Type", 'The third entry must record rejection.');
        Assert.AreEqual('Please explain the change.', ExpenseActivityLogEntry.Comment, 'The rejection entry must preserve the approver comment.');
        ExpenseActivityLogEntry.Next();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Resubmitted, ExpenseActivityLogEntry."Event Type", 'The fourth entry must record resubmission.');
        Assert.AreEqual('Updated the justification.', ExpenseActivityLogEntry.Comment, 'The resubmission entry must preserve the submitter comment.');
        ExpenseActivityLogEntry.Next();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Approved, ExpenseActivityLogEntry."Event Type", 'The fifth entry must record approval.');
        Assert.AreEqual(0, ExpenseActivityLogEntry.Next(), 'No additional approval lifecycle entries are expected.');
    end;

    [Test]
    procedure ApprovalConversationKeepsLatestHeaderValuesAndCompleteHistory()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
        RejectedCount: Integer;
        ResubmittedCount: Integer;
    begin
        // [SCENARIO] Header comments keep the latest exchange while activity entries preserve every cycle.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);

        // [WHEN] The report is rejected and resubmitted twice.
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        ExpenseReportApprovalMgt.Reject(ExpenseReportHeader, ApproverExpenseUser."No.", 'First approver comment.');
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.", 'First submitter response.');
        ExpenseReportApprovalMgt.Reject(ExpenseReportHeader, ApproverExpenseUser."No.", 'Second approver comment.');
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.", 'Second submitter response.');

        // [THEN] The header exposes only the latest value from each participant.
        Assert.AreEqual('Second approver comment.', ExpenseReportHeader.GetApproverComment(), 'The header must keep the latest approver comment.');
        Assert.AreEqual('Second submitter response.', ExpenseReportHeader.GetSubmitterComment(), 'The header must keep the latest submitter comment.');

        // [THEN] Every comment remains in its state-change activity entry.
        ExpenseActivityLogEntry.SetRange("Subject Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetCurrentKey("Entry No.");
        ExpenseActivityLogEntry.FindSet();
        repeat
            case ExpenseActivityLogEntry."Event Type" of
                ExpenseActivityLogEntry."Event Type"::Rejected:
                    begin
                        RejectedCount += 1;
                        case RejectedCount of
                            1:
                                Assert.AreEqual('First approver comment.', ExpenseActivityLogEntry.Comment, 'The first rejection comment must remain unchanged.');
                            2:
                                Assert.AreEqual('Second approver comment.', ExpenseActivityLogEntry.Comment, 'The second rejection comment must be appended.');
                        end;
                    end;
                ExpenseActivityLogEntry."Event Type"::Resubmitted:
                    begin
                        ResubmittedCount += 1;
                        case ResubmittedCount of
                            1:
                                Assert.AreEqual('First submitter response.', ExpenseActivityLogEntry.Comment, 'The first submitter response must remain unchanged.');
                            2:
                                Assert.AreEqual('Second submitter response.', ExpenseActivityLogEntry.Comment, 'The second submitter response must be appended.');
                        end;
                    end;
            end;
        until ExpenseActivityLogEntry.Next() = 0;
        Assert.AreEqual(2, RejectedCount, 'Exactly two rejection comments are expected.');
        Assert.AreEqual(2, ResubmittedCount, 'Exactly two submitter responses are expected.');
    end;

    [Test]
    procedure ResubmissionAllowsBlankComment()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] The conversation-specific submit operation accepts a blank comment.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        ExpenseReportApprovalMgt.Reject(ExpenseReportHeader, ApproverExpenseUser."No.", 'Please explain the change.');
        Commit();

        // [WHEN] The submitter does not provide a response.
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.", '');

        // [THEN] The report is resubmitted with an empty latest comment.
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'A blank response must not block resubmission.');
        Assert.AreEqual('', ExpenseReportHeader.GetSubmitterComment(), 'The latest submitter comment must be empty.');
    end;

    [Test]
    procedure ActivityCommentTruncationIncludesEllipsis()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
    begin
        // [SCENARIO] An activity comment that exceeds storage capacity is truncated with an ellipsis.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [WHEN] An event is logged with more than 2048 characters.
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Rejected,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Approver,
            ExpenseUser."No.",
            PadStr('', 2049, 'X'));

        // [THEN] The stored comment fills the field and signals truncation.
        ExpenseActivityLogEntry.Get(EntryNo);
        Assert.AreEqual(MaxStrLen(ExpenseActivityLogEntry.Comment), StrLen(ExpenseActivityLogEntry.Comment), 'The truncated comment must fill the storage field.');
        Assert.AreEqual('...', CopyStr(ExpenseActivityLogEntry.Comment, StrLen(ExpenseActivityLogEntry.Comment) - 2), 'The truncated comment must end with an ellipsis.');
    end;

    [Test]
    procedure ReopeningPendingApprovalLogsRecall()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
        EntryCountBeforeRejectedReopen: Integer;
    begin
        // [SCENARIO] Returning a pending report to Open is a recall, while reopening a rejected report is not logged.
        // [GIVEN] A submitted expense report whose submitter is the current BC user without Unlimited Expense Approval.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        SetCurrentUserUnlimitedExpenseApproval(false);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");

        // [WHEN] The pending report is reopened.
        ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] A Recalled entry is appended.
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Recalled, ExpenseActivityLogEntry."Event Type", 'Pending approval to Open must be recorded as recalled.');
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Submitter, ExpenseActivityLogEntry."Actor Role", 'The original submitter must be recorded with the Submitter role.');
        Assert.AreEqual(Database::"Expense User", ExpenseActivityLogEntry."Actor Table ID", 'A submitter recall must identify an Expense User.');
        Assert.AreEqual(SubmitterExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'A submitter recall must identify the captured submitter.');

        // [WHEN] The same operation reopens a rejected report.
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Rejected;
        ExpenseReportHeader.Modify(true);
        EntryCountBeforeRejectedReopen := ExpenseActivityLogEntry.Count();
        ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] No additional activity entry is appended.
        ExpenseActivityLogEntry.Reset();
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        Assert.AreEqual(EntryCountBeforeRejectedReopen, ExpenseActivityLogEntry.Count(), 'Reopening a rejected report must not create an activity entry.');
    end;

    [Test]
    procedure SubmitterWithUnlimitedApprovalRecallStillLogsSubmitter()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] A submitter with Unlimited Expense Approval is still classified as the submitter.
        // [GIVEN] A submitted expense report whose submitter is the current unlimited BC user.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        SetCurrentUserUnlimitedExpenseApproval(true);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");

        // [WHEN] The submitter recalls the pending report.
        ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] Submitter identity takes precedence over the administrator capability.
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Submitter, ExpenseActivityLogEntry."Actor Role", 'A submitter with unlimited approval must retain the Submitter role.');
        Assert.AreEqual(SubmitterExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'The recall must identify the captured submitter.');
    end;

    [Test]
    procedure UnmappedAdministratorRecallLogsBCUser()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        User: Record User;
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] An unlimited user without an Expense User mapping can administratively recall a submitted report.
        // [GIVEN] A report submitted by another user and the current user has Unlimited Expense Approval.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        SetSubmitterToDifferentUser(SubmitterExpenseUser);
        RemoveCurrentExpenseUserMappings();
        SetCurrentUserUnlimitedExpenseApproval(true);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        User.Get(UserSecurityId());

        // [WHEN] The current user recalls the pending report.
        ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] The recall is attributed to the actual BC User acting as Administrator.
        Assert.AreEqual(ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status, 'Administrative recall must reopen the report.');
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Recalled, ExpenseActivityLogEntry."Event Type", 'Administrative recall must be recorded.');
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Administrator, ExpenseActivityLogEntry."Actor Role", 'An administrative recall must use the Administrator role.');
        Assert.AreEqual(Database::User, ExpenseActivityLogEntry."Actor Table ID", 'An administrative recall must identify a BC User.');
        Assert.AreEqual(User.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'An administrative recall must identify the current BC User.');
        Assert.AreNotEqual('', ExpenseActivityLogEntry."Actor Display Name", 'An administrative recall must retain the BC User display name.');

        // [THEN] The administrative event does not make the administrator a submitter or approver participant.
        ExpenseActivityLogEntry.SetRange("History Actor Table ID Filter", Database::User);
        ExpenseActivityLogEntry.SetRange("History Actor System ID Filter", User.SystemId);
        ExpenseActivityLogEntry.SetRange("History Actor Role Filter", Enum::"Expense Activity Actor Role"::Submitter);
        ExpenseActivityLogEntry.CalcFields("History Subject Match");
        Assert.IsFalse(ExpenseActivityLogEntry."History Subject Match", 'An administrator must not gain submitter history participation.');
        ExpenseActivityLogEntry.SetRange("History Actor Role Filter", Enum::"Expense Activity Actor Role"::Approver);
        ExpenseActivityLogEntry.CalcFields("History Subject Match");
        Assert.IsFalse(ExpenseActivityLogEntry."History Subject Match", 'An administrator must not gain approver history participation.');
    end;

    [Test]
    procedure MappedAdministratorRecallStillLogsAdministrator()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        AdministratorExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] An unlimited user mapped to an Expense User still acts as Administrator when recalling another submitter's report.
        // [GIVEN] A report submitted by another user and the current unlimited user has an unrelated Expense User mapping.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        SetSubmitterToDifferentUser(SubmitterExpenseUser);
        RemoveCurrentExpenseUserMappings();
        LibraryExpense.CreateExpenseUser(AdministratorExpenseUser);
        AdministratorExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(AdministratorExpenseUser."User Id For Approvals"));
        AdministratorExpenseUser.Modify();
        SetCurrentUserUnlimitedExpenseApproval(true);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");

        // [WHEN] The mapped current user recalls the pending report.
        ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] Mapping presence does not misclassify the action as a submitter recall.
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Administrator, ExpenseActivityLogEntry."Actor Role", 'Recalling another submitter''s report must use the Administrator role.');
        Assert.AreEqual(Database::User, ExpenseActivityLogEntry."Actor Table ID", 'The administrator must be represented by the BC User, not an unrelated Expense User mapping.');
    end;

    [Test]
    procedure UnauthorizedUserCannotRecallSubmittedReport()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        UserSetup: Record "User Setup";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
        EntryCountBeforeRecall: Integer;
    begin
        // [SCENARIO] A user who is neither the captured submitter nor unlimited cannot recall a submitted report.
        // [GIVEN] A report submitted by another user and the current user has limited approval rights.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        SetSubmitterToDifferentUser(SubmitterExpenseUser);
        SetCurrentUserUnlimitedExpenseApproval(false);
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        EntryCountBeforeRecall := ExpenseActivityLogEntry.Count();
        Commit();

        // [WHEN] The current user attempts to recall the pending report.
        asserterror ExpenseReportApprovalMgt.ReopenSubmitted(ExpenseReportHeader);

        // [THEN] The operation is denied before status or history changes.
        Assert.ExpectedError(UserSetup.FieldCaption("Unlimited Expense Approval"));
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.Status, 'An unauthorized recall must not change the report status.');
        Assert.AreEqual(EntryCountBeforeRecall, ExpenseActivityLogEntry.Count(), 'An unauthorized recall must not append activity.');
    end;

    [Test]
    procedure CategoriesSnapshotRemovesTrailingCategoryToFitEllipsis()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        Categories: JsonArray;
        LastCategory: JsonToken;
        EntryNo: BigInteger;
        CategoryIndex: Integer;
    begin
        // [SCENARIO] An overflowing category snapshot remains valid and signals omitted categories.
        // [GIVEN] A report with more maximum-length unique categories than the snapshot field can store.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        for CategoryIndex := 1 to 90 do begin
            Clear(ExpenseReportLine);
            ExpenseReportLine."Document No." := ExpenseReportHeader."No.";
            ExpenseReportLine."Line No." := CategoryIndex * 10000;
            ExpenseReportLine."Expense Category" := CopyStr(PadStr(Format(CategoryIndex), 20, 'X'), 1, MaxStrLen(ExpenseReportLine."Expense Category"));
            ExpenseReportLine."Receipt Attached" := CategoryIndex = 90;
            ExpenseReportLine.Insert();
        end;

        // [WHEN] A Submitted entry captures the report contents.
        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');

        // [THEN] The category JSON fits, remains valid, and ends with an ellipsis.
        ExpenseActivityLogEntry.Get(EntryNo);
        Assert.IsTrue(StrLen(ExpenseActivityLogEntry.Categories) <= MaxStrLen(ExpenseActivityLogEntry.Categories), 'Categories must not exceed the field length.');
        Assert.IsTrue(Categories.ReadFrom(ExpenseActivityLogEntry.Categories), 'Categories must remain valid JSON.');
        Categories.Get(Categories.Count() - 1, LastCategory);
        Assert.AreEqual('...', LastCategory.AsValue().AsText(), 'An overflowing category snapshot must end with an ellipsis.');
        Assert.AreEqual(1, ExpenseActivityLogEntry."Attached Receipt Count", 'Attached receipt counting must continue after the category snapshot overflows.');
    end;

    [Test]
    procedure ExistingReportStartsTimelineWhenResubmitted()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] A report submitted before activity tracking starts gets a complete timeline when resubmitted.
        // [GIVEN] A released report with an earlier submission timestamp but no activity entries.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        ExpenseReportHeader."Submission DateTime" := CurrentDateTime() - 1000;
        ExpenseReportHeader.Modify(true);

        // [WHEN] The existing report is resubmitted.
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");

        // [THEN] The timeline starts with Created and records the action as Resubmitted.
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.SetCurrentKey("Entry No.");
        ExpenseActivityLogEntry.FindSet();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Created, ExpenseActivityLogEntry."Event Type", 'The timeline must start with report creation.');
        ExpenseActivityLogEntry.Next();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::Resubmitted, ExpenseActivityLogEntry."Event Type", 'An earlier submission timestamp must produce Resubmitted.');
        Assert.AreEqual(0, ExpenseActivityLogEntry.Next(), 'Only creation and resubmission entries are expected.');
    end;

    [Test]
    procedure ReopeningApprovedReportIsLogged()
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        CurrentUserExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        // [SCENARIO] Reopening an approved report records the approver lifecycle action.
        // [GIVEN] An approved report whose approver is the only Expense User mapped to the current BC user.
        Initialize();
        CreateApprovalScenario(SubmitterExpenseUser, ApproverExpenseUser, ExpenseReportHeader);
        CurrentUserExpenseUser.SetRange("User Id For Approvals", UserId());
        CurrentUserExpenseUser.ModifyAll("User Id For Approvals", '');
        ApproverExpenseUser."User Id For Approvals" :=
            CopyStr(UserId(), 1, MaxStrLen(ApproverExpenseUser."User Id For Approvals"));
        ApproverExpenseUser.Modify();
        ExpenseReportApprovalMgt.Submit(ExpenseReportHeader, SubmitterExpenseUser."No.");
        ExpenseReportApprovalMgt.Approve(ExpenseReportHeader, ApproverExpenseUser."No.");

        // [WHEN] The approver reopens the approved report.
        ExpenseReportApprovalMgt.ReopenApproved(ExpenseReportHeader);

        // [THEN] ReopenedByApprover is the latest activity.
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindLast();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::ReopenedByApprover, ExpenseActivityLogEntry."Event Type", 'Reopening an approved report must be logged.');
        Assert.AreEqual(ApproverExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'The reopen entry must identify the approver.');
    end;

    [Test]
    procedure ReassigningToPostedChangesOwnerButKeepsSubject()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        DecoyEntryNo: BigInteger;
        OriginalEntryNo: BigInteger;
        OriginalEntrySystemID: Guid;
        OriginalSubjectSystemID: Guid;
    begin
        // [SCENARIO] Posting reassigns only the exact entries owned by the source report.
        // [GIVEN] Two source-report entries and an unowned decoy sharing the posted header SystemId.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        OriginalEntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        ExpenseActivityLogEntry.Get(OriginalEntryNo);
        OriginalEntrySystemID := ExpenseActivityLogEntry.SystemId;
        OriginalSubjectSystemID := ExpenseReportHeader.SystemId;

        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportHeader.Insert();

        Clear(ExpenseActivityLogEntry);
        ExpenseActivityLogEntry.Init();
        ExpenseActivityLogEntry."Source Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Source Record System ID" := PostedExpenseReportHeader.SystemId;
        ExpenseActivityLogEntry."Subject Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Subject System ID" := CreateGuid();
        ExpenseActivityLogEntry."Event Type" := Enum::"Expense Activity Event Type"::Created;
        ExpenseActivityLogEntry."Occurred At" := CurrentDateTime();
        ExpenseActivityLogEntry.Insert();
        DecoyEntryNo := ExpenseActivityLogEntry."Entry No.";

        // [WHEN] The source report entries are reassigned to the posted report.
        ExpenseActivityLogMgt.ReassignExpenseReportEntriesToPosted(ExpenseReportHeader, PostedExpenseReportHeader);

        // [THEN] The source entries have the posted owner while their event and subject identities remain stable.
        ExpenseActivityLogEntry.Reset();
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
        ExpenseActivityLogEntry.Reset();
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        ExpenseActivityLogEntry.FindFirst();
        Assert.RecordCount(ExpenseActivityLogEntry, 2);
        Assert.AreEqual(Database::"Posted Expense Report Header", ExpenseActivityLogEntry."Source Table ID", 'Posted entries must be sourced from the posted report.');
        Assert.AreEqual(OriginalSubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'Posting must not change the contract subject identity.');
        ExpenseActivityLogEntry.SetRange(SystemId, OriginalEntrySystemID);
        Assert.RecordIsNotEmpty(ExpenseActivityLogEntry);

        // [THEN] The unmarked decoy remains owned by an active report.
        ExpenseActivityLogEntry.Get(DecoyEntryNo);
        Assert.AreEqual(Database::"Expense Report Header", ExpenseActivityLogEntry."Source Table ID", 'An unmarked active entry with the posted source GUID must not be reassigned.');
    end;

    [Test]
    procedure SourceDeletionRemovesActivityEntries()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        // [SCENARIO] Activity entries are deleted with the active or posted source document.
        // [GIVEN] An activity entry reassigned from an active report to a posted report.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseUser."No.",
            '');
        PostedExpenseReportHeader.Init();
        PostedExpenseReportHeader."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PostedExpenseReportHeader."No."));
        PostedExpenseReportHeader.Insert();
        ExpenseActivityLogMgt.ReassignExpenseReportEntriesToPosted(ExpenseReportHeader, PostedExpenseReportHeader);

        // [WHEN] The active report is deleted after reassignment.
        ExpenseReportHeader.Delete(true);

        // [THEN] The entry remains with the posted source.
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        Assert.RecordIsNotEmpty(ExpenseActivityLogEntry);

        // [WHEN] The posted source document is deleted.
        PostedExpenseReportHeader.Delete(true);

        // [THEN] Its activity entries are deleted.
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
    end;

    [Test]
    procedure SubmissionAggregatesGlobalPolicyPairsAndLineCategories()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        SecondLine: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PassedPolicy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Global policies count line-policy pairs and use line categories, not blank policy scope.
        Initialize();

        // [GIVEN] Two lines with distinct categories and two applicable global policies.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryLine(Header, SecondLine);
        LibraryExpense.CreateExpensePolicy(PassedPolicy, '', 'Passing global policy');
        AddHistoryEvaluation(Line, Policy, false);
        AddHistoryEvaluation(Line, PassedPolicy, false);
        AddHistoryEvaluation(SecondLine, Policy, false);
        AddHistoryEvaluation(SecondLine, PassedPolicy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");

        // [WHEN] The report is submitted with already-current manual results.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] Exactly one agent snapshot contains three failed pairs, one pass and two flagged line categories.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 3, 1, 2);
        VerifyFlaggedCategory(SubmissionID, Line."Expense Category");
        VerifyFlaggedCategory(SubmissionID, SecondLine."Expense Category");
    end;

    [Test]
    procedure ManualEvaluationDoesNotWriteHistory()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Manual results and marks alone never create an activity entry.
        Initialize();

        // [GIVEN] An unsubmitted report with a policy.
        CreatePolicyHistoryScenario(Header, Line, Policy);

        // [WHEN] A complete passing evaluation is recorded and confirmed.
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No activity was written.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure SubmissionDoesNotSnapshotUnconfirmedResults()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Persisted passing evaluations are insufficient without the exact-version line confirmation.
        Initialize();

        // [GIVEN] A passing but unconfirmed result.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);

        // [WHEN] The report is submitted.
        SubmitHistoryReport(Header);

        // [THEN] Pending evaluation is not misrepresented as a successful snapshot.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure CompletionAfterApprovalCapturesFlaggedResults()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Approval between mark and callback does not lose or clear a flagged result.
        Initialize();

        // [GIVEN] A submitted report subsequently evaluated and approved via override.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        AddHistoryEvaluation(Line, Policy, false);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        Header.Status := Header.Status::Approved;
        Header.Modify(false);

        // [WHEN] The original automatic run completes.
        PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] A flagged snapshot is captured without imposing new approval restrictions.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 1, 0, 1);
    end;

    [Test]
    procedure CompletionRetryKeepsOriginalSnapshot()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Retrying completion after a policy change returns the immutable original snapshot.
        Initialize();

        // [GIVEN] A flagged snapshot and a later disabled policy.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, false);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);
        Policy.Enabled := false;
        Policy.Modify(true);

        // [WHEN] Completion is retried twice.
        PolicyHistory.Complete(Header, SubmissionID);
        PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] The one stored failure is not re-derived as cleared or no policies.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 1, 0, 1);
    end;

    [Test]
    procedure CompletionRejectsChangedPolicy()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A changed policy invalidates a pending submission context.
        Initialize();

        // [GIVEN] A policy changes after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Policy."Policy Text" := 'Changed';
        Policy.Modify(true);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] An explicit context conflict is returned.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsDeletedPolicy()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Deleting the last policy cannot turn a pending failed check into no policies.
        Initialize();

        // [GIVEN] A policy is removed after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Policy.Delete(true);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] No new success snapshot can be derived.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsNewPolicy()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        NewPolicy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] New applicable policies invalidate the original submission context.
        Initialize();

        // [GIVEN] A new global policy is added after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        LibraryExpense.CreateExpensePolicy(NewPolicy, '', 'New policy');

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] The new pair is not silently omitted.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsChangedLine()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A changed line version invalidates the original submission context.
        Initialize();

        // [GIVEN] The subject version advances after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Line.InvalidatePolicyEvaluation();

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] Results for a different version cannot be captured.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsDeletedLine()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Deleted lines cannot silently disappear from a pending snapshot.
        Initialize();

        // [GIVEN] A line is deleted after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Line.Delete(false);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] A context conflict is returned.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsNewLine()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        NewLine: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] New lines cannot silently be counted as clean.
        Initialize();

        // [GIVEN] A line is added after submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        AddHistoryLine(Header, NewLine);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] A context conflict is returned.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsEarlierSubmissionRound()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A callback cannot attach to a later resubmission.
        Initialize();

        // [GIVEN] An original submission and a later round.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Header.Status := Header.Status::Released;
        Header.Modify(false);
        SubmitHistoryReport(Header);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] The original identity is rejected rather than replaced with the latest one.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsForeignReportIdentity()
    var
        Header: Record "Expense Report Header";
        OtherHeader: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A submission identity must belong to the scoped report.
        Initialize();

        // [GIVEN] Two reports and a submission on the first.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        LibraryExpense.CreateExpenseReport(OtherHeader, Header."Expense User No.", '', '');

        // [WHEN] A foreign submission identity is supplied.
        asserterror PolicyHistory.Complete(OtherHeader, SubmissionID);

        // [THEN] The identity is rejected.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure NoApplicablePoliciesSnapshotIsNotCleared()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A report with no applicable policies has its own explicit outcome.
        Initialize();

        // [GIVEN] A report line without any applicable policies.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        Policy.Delete(true);

        // [WHEN] The report is submitted.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] No policies is recorded, not a fabricated clean evaluation.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::"No Policies", 0, 0, 0);
    end;

    [Test]
    procedure ZeroLinePolicySnapshotIsNoPolicies()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The aggregation's empty report case contains zero pairs.
        Initialize();

        // [GIVEN] A zero-line report at the approval-management entry point.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        Line.Delete(false);

        // [WHEN] A submission is logged through approval management.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] No policies is distinct from successful evaluated checks.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::"No Policies", 0, 0, 0);
    end;

    [Test]
    procedure DisabledPolicyEvaluationWritesNoHistory()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Setup: Record "Expense Agent Setup";
        Entry: Record "Expense Activity Log Entry";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] BC enforces the feature switch at submission and callback.
        Initialize();

        // [GIVEN] Complete results with policy evaluation disabled.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        Setup.Get();
        Setup."Evaluate Policies" := false;
        Setup.Modify(false);

        // [WHEN] Submission and callback are requested despite the disabled capability.
        SubmissionID := SubmitHistoryReport(Header);
        PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] No policy activity is created.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure PostingRetainsPolicySnapshotAndSubmissionIdentity()
    var
        Header: Record "Expense Report Header";
        PostedHeader: Record "Posted Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
        ActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Source reassignment preserves policy snapshot contents and correlation.
        Initialize();

        // [GIVEN] A completed snapshot and a posted report.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);
        PostedHeader."No." := Header."No.";
        PostedHeader.Insert(false);

        // [WHEN] Posting reassigns the report's history.
        ActivityLogMgt.ReassignExpenseReportEntriesToPosted(Header, PostedHeader);

        // [THEN] The policy snapshot is unchanged and attached to the posted source.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
        Entry.SetRange("Submission Activity ID", SubmissionID);
        Entry.FindFirst();
        Assert.AreEqual(PostedHeader.SystemId, Entry."Source Record System ID", 'The posted source must own the snapshot.');
    end;

    [Test]
    procedure SubmissionCountsOnlyCurrentPolicyVersions()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Superseded failed evaluations do not pollute a complete current passing snapshot.
        Initialize();

        // [GIVEN] A failed old policy version and a confirmed passing current version.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, false);
        Policy."Policy Text" := 'Revised policy';
        Policy.Modify(true);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [WHEN] Current results are reused during submission.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] Only the applicable current policy pair is counted.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure CompletionRejectsMissingPairs()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Completion never records a success when evaluations are missing.
        Initialize();

        // [GIVEN] A pending submission with missing evaluations.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);

        // [WHEN] Completion is called prematurely.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] An explicit incomplete result is returned.
        Assert.ExpectedError('[PolicyHistoryIncomplete]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure CompletionRejectsChangedReportContext()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Editing report context after submission cannot yield a snapshot for the original context.
        Initialize();

        // [GIVEN] The report title changes while evaluation is in flight.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Header.Description := 'Changed report context';
        Header.Modify(false);

        // [WHEN] The original callback arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] A context conflict is returned.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure DescriptionChangedAfterManualEvaluationDoesNotSnapshot()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
        EvaluatedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Changing report context before submission cannot reuse old manual evidence.
        Initialize();

        // [GIVEN] Report H has a confirmed passing evaluation.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        EvaluatedVersion := Line."Policy Eval Version";

        // [WHEN] H's description changes and H is submitted.
        Header.Description := 'Changed purpose after manual check';
        Header.Modify(true);
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] H requires fresh evidence and has no success snapshot.
        VerifyInvalidatedLine(Line, EvaluatedVersion);
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure DescriptionChangedDuringEvaluationRejectsOldInsert()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Results from an in-flight evaluation cannot be inserted after a header edit.
        Initialize();

        // [GIVEN] L's version is captured before H's description changes.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        Header.Description := 'Changed while evaluating';
        Header.Modify(true);

        // [WHEN] An evaluator inserts a result using L's captured version.
        asserterror AddHistoryEvaluation(Line, Policy, true);

        // [THEN] BC rejects the old-context result.
        Assert.ExpectedError('The expense report line changed after policy evaluation started.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure DescriptionChangedDuringEvaluationRejectsOldConfirmation()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A header edit between persistence and confirmation invalidates the captured version.
        Initialize();

        // [GIVEN] H changes after a passing result is persisted for L.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Header.Description := 'Changed before confirmation';
        Header.Modify(false);

        // [WHEN] L is confirmed using the version captured before H changed.
        asserterror Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] Confirmation rejects the old context, including writes without table triggers.
        Assert.ExpectedError('The expense report line changed after policy evaluation started.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure UnchangedDescriptionAndSubmissionCommentReuseManualEvidence()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        ApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
        SubmissionID: Guid;
        EvaluatedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Unchanged report context, comments and submission status preserve current evidence.
        Initialize();

        // [GIVEN] H has confirmed passing evidence.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        EvaluatedVersion := Line."Policy Eval Version";

        // [WHEN] H is saved unchanged and submitted with a new comment.
        Header.Modify(true);
        SubmissionID := CreateGuid();
        ApprovalMgmt.Submit(Header, Header."Expense User No.", 'Please review this report', SubmissionID);

        // [THEN] L's version is preserved and the existing evidence is captured.
        Line.Get(Line."Document No.", Line."Line No.");
        Assert.AreEqual(EvaluatedVersion, Line."Policy Eval Version", 'Workflow changes must not invalidate evidence.');
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure SubmitterNameChangeBeforeSubmissionRequiresRecheck()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
        EvaluatedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The stored submitter name is part of the LLM context, not just the owner number.
        Initialize();

        // [GIVEN] H has confirmed evidence for its original submitter name.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        EvaluatedVersion := Line."Policy Eval Version";

        // [WHEN] H's stored submitter name changes before submission.
        Header."Expense User Name" := 'Changed submitter name';
        Header.Modify(false);
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] The old-context evidence is not captured as a current success.
        VerifyInvalidatedLine(Line, EvaluatedVersion);
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure OwnerChangeInvalidatesOnlyOwnedReportLines()
    var
        Header: Record "Expense Report Header";
        OtherHeader: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        SecondLine: Record "Expense Report Line";
        OtherLine: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        ExpenseUser: Record "Expense User";
        CapturedVersion: Integer;
        OtherVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An owner change invalidates every line on H but never another report.
        Initialize();

        // [GIVEN] H has two lines and H2 belongs to the same owner.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryLine(Header, SecondLine);
        LibraryExpense.CreateExpenseReport(OtherHeader, Header."Expense User No.", '', '');
        AddHistoryLine(OtherHeader, OtherLine);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CapturedVersion := Line."Policy Eval Version";
        OtherVersion := OtherLine."Policy Eval Version";

        // [WHEN] H's owner is changed by a backend writer without validation triggers.
        Header."Expense User No." := ExpenseUser."No.";
        Header.Modify(false);

        // [THEN] Only H's line versions change.
        VerifyInvalidatedLine(Line, CapturedVersion);
        VerifyInvalidatedLine(SecondLine, CapturedVersion);
        OtherLine.Get(OtherLine."Document No.", OtherLine."Line No.");
        Assert.AreEqual(OtherVersion, OtherLine."Policy Eval Version", 'Another report must not be invalidated.');
    end;

    [Test]
    procedure RepeatedDescriptionEditsAdvanceUnevaluatedVersion()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        CapturedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Every context edit invalidates in-flight work even before the first confirmation.
        Initialize();

        // [GIVEN] L has not yet been evaluated.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        CapturedVersion := Line."Policy Eval Version";

        // [WHEN] H's description is edited twice.
        Header.Description := 'First purpose';
        Header.Modify(true);
        Header.Description := 'Second purpose';
        Header.Modify(true);

        // [THEN] Both edits advance the captured version.
        Line.Get(Line."Document No.", Line."Line No.");
        Assert.AreEqual(CapturedVersion + 2, Line."Policy Eval Version", 'Every context edit requires a distinct version.');
    end;

    [Test]
    procedure TemporaryReportContextDoesNotInvalidateStoredLines()
    var
        Header: Record "Expense Report Header";
        TempHeader: Record "Expense Report Header" temporary;
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        CapturedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Editing a temporary header must not change persisted evaluation versions.
        Initialize();

        // [GIVEN] A temporary copy of H with the same identity.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        CapturedVersion := Line."Policy Eval Version";
        TempHeader := Header;
        TempHeader.Insert(false, true);

        // [WHEN] Only the temporary description changes.
        TempHeader.Description := 'Temporary purpose';
        TempHeader.Modify(false);

        // [THEN] L remains unchanged.
        Line.Get(Line."Document No.", Line."Line No.");
        Assert.AreEqual(CapturedVersion, Line."Policy Eval Version", 'Temporary changes must not invalidate stored evidence.');
    end;

    [Test]
    procedure CompletionRecoversPersistedUnconfirmedResults()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A worker confirms existing pairs even when live policy status already reads Cleared.
        Initialize();

        // [GIVEN] L has a passing persisted result but no confirmation and H is submitted.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Assert.AreEqual(Enum::"Expense Policy Status"::Cleared, Line.GetPolicyStatus(), 'The legacy status can precede confirmation.');
        SubmissionID := SubmitHistoryReport(Header);
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] The worker confirms the captured version and completes the same submission twice.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        PolicyHistory.Complete(Header, SubmissionID);
        PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] Exactly one completed snapshot contains the persisted passing evidence.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure AutomaticCompletionDoesNotDuplicateImmediateSnapshot()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Always scheduling completion preserves a snapshot already captured during submission.
        Initialize();

        // [GIVEN] Current evidence was already captured when H was submitted.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);

        // [WHEN] An empty-delta worker confirms and completes the submission.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] No duplicate snapshot is created.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure CompletionRejectsChangedSubmitterNameContext()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PolicyHistory: Codeunit "Expense Policy History";
        SubmissionID: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Changing the stored submitter name invalidates a pending submission's context hash.
        Initialize();

        // [GIVEN] H is submitted and its stored submitter name changes during evaluation.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Header."Expense User Name" := 'Changed submitter context';
        Header.Modify(false);

        // [WHEN] The callback for the original submission arrives.
        asserterror PolicyHistory.Complete(Header, SubmissionID);

        // [THEN] A context conflict is returned rather than an incomplete or clean snapshot.
        Assert.ExpectedError('[PolicyHistoryConflict]');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReportNumberChangeInvalidatesFallbackContext()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        CapturedVersion: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The report number is evaluator context when the description is empty.
        Initialize();

        // [GIVEN] H has no description and L has confirmed passing evidence.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        Header.Description := '';
        Header.Modify(false);
        Line.Get(Line."Document No.", Line."Line No.");
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        CapturedVersion := Line."Policy Eval Version";

        // [WHEN] H is renamed.
        Header.Rename(CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Header."No.")));

        // [THEN] L's stable identity has a new evaluation version.
        Line.GetBySystemId(Line.SystemId);
        Assert.AreEqual(CapturedVersion + 1, Line."Policy Eval Version", 'Renaming the report must invalidate fallback context.');
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Activity Log Test");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Evaluate Policies" := false;
        ExpenseAgentSetup.Modify(false);
        LibrarySetupStorage.Save(Database::"Expense Agent Setup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Activity Log Test");
    end;

    local procedure VerifyInvalidatedLine(var Line: Record "Expense Report Line"; CapturedVersion: Integer)
    begin
        Line.Get(Line."Document No.", Line."Line No.");
        Assert.AreEqual(CapturedVersion + 1, Line."Policy Eval Version", 'Header context changes must invalidate the captured line version.');
    end;

    local procedure VerifyNoPolicySnapshot(SubmissionID: Guid)
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        Entry.SetRange("Submission Activity ID", SubmissionID);
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Assert.RecordIsEmpty(Entry);
    end;

    local procedure CreatePolicyHistoryScenario(var Header: Record "Expense Report Header"; var Line: Record "Expense Report Line"; var Policy: Record "Expense Policy")
    var
        Submitter: Record "Expense User";
        Approver: Record "Expense User";
        Setup: Record "Expense Agent Setup";
    begin
        Policy.DeleteAll(false);
        CreateApprovalScenario(Submitter, Approver, Header);
        Setup.Get();
        Setup."Evaluate Policies" := true;
        Setup.Modify(false);
        AddHistoryLine(Header, Line);
        LibraryExpense.CreateExpensePolicy(Policy, '', 'Global policy');
    end;

    local procedure AddHistoryLine(Header: Record "Expense Report Header"; var Line: Record "Expense Report Line")
    var
        Category: Record "Expense Category";
        LastLine: Record "Expense Report Line";
    begin
        Category.Code := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Category.Code));
        Category.Insert(false);
        LastLine.SetRange("Document No.", Header."No.");
        if not LastLine.FindLast() then
            LastLine."Line No." := 0;
        Line.Init();
        Line."Document No." := Header."No.";
        Line."Line No." := LastLine."Line No." + 10000;
        Line."Expense Category" := Category.Code;
        Line.Insert(false);
    end;

    local procedure AddHistoryEvaluation(Line: Record "Expense Report Line"; Policy: Record "Expense Policy"; Compliant: Boolean)
    var
        Evaluation: Record "Expense Policy Evaluation";
    begin
        LibraryExpense.CreateExpensePolicyEvaluation(Evaluation, Line, Policy, 'Evaluated', Compliant);
    end;

    local procedure SubmitHistoryReport(var Header: Record "Expense Report Header") SubmissionID: Guid
    var
        ApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        SubmissionID := CreateGuid();
        ApprovalMgmt.Submit(Header, Header."Expense User No.", '', SubmissionID);
    end;

    local procedure VerifyPolicySnapshot(SubmissionID: Guid; Status: Enum "Expense Policy Status"; FailedCount: Integer; PassedCount: Integer; CategoryCount: Integer)
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        Entry.SetRange("Submission Activity ID", SubmissionID);
        Assert.RecordCount(Entry, 1);
        Entry.FindFirst();
        Assert.IsTrue(Entry."Policy Snapshot Present", 'A captured snapshot must be explicit.');
        Assert.AreEqual(Status, Entry."Policy Status", 'Snapshot status must reflect all applicable pairs.');
        Assert.AreEqual(FailedCount, Entry."Failed Policy Count", 'Failed count counts line-policy pairs.');
        Assert.AreEqual(PassedCount, Entry."Passed Policy Count", 'Passed count counts line-policy pairs.');
        Assert.AreEqual(CategoryCount, Entry."Flagged Category Count", 'Categories are distinct flagged line categories.');
        Assert.AreEqual(Enum::"Expense Activity Initiator"::Agent, Entry."Initiated By", 'The snapshot is agent initiated.');
        Assert.AreEqual(0, Entry."Actor Role".AsInteger(), 'No actor role may grant history access.');
        Assert.AreEqual(0, Entry."Actor Table ID", 'No human identity may be attached.');
        Assert.IsTrue(IsNullGuid(Entry."Actor Record System ID"), 'No human identity may be attached.');
        Assert.IsTrue(Entry."Latest Policies Evaluated At" <= Entry."Occurred At", 'Capture time cannot predate included evaluation.');
    end;

    local procedure VerifyFlaggedCategory(SubmissionID: Guid; CategoryCode: Code[20])
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        Entry.SetRange("Submission Activity ID", SubmissionID);
        Entry.FindFirst();
        Assert.IsTrue(Entry."Flagged Categories".Contains(CategoryCode), 'The failed line category must appear in the snapshot.');
    end;

    local procedure CreateApprovalScenario(
        var
            SubmitterExpenseUser: Record "Expense User";
        var
            ApproverExpenseUser: Record "Expense User";
        var
            ExpenseReportHeader: Record "Expense Report Header"
    )
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        LibraryExpense.CreateExpenseUser(SubmitterExpenseUser);
        SubmitterExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(SubmitterExpenseUser."User Id For Approvals"));
        SubmitterExpenseUser.Modify();

        LibraryExpense.CreateExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser."Can Approve" := true;
        ApproverExpenseUser."User Id For Approvals" := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ApproverExpenseUser."User Id For Approvals"));
        ApproverExpenseUser.Modify();
        if ExpenseApprovalSetup.Get(SubmitterExpenseUser."No.") then begin
            ExpenseApprovalSetup.Validate("Approver No.", ApproverExpenseUser."No.");
            ExpenseApprovalSetup.Modify();
        end else
            LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, SubmitterExpenseUser."No.", ApproverExpenseUser."No.");

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, SubmitterExpenseUser."No.", '', '');
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify(true);
    end;

    local procedure SetSubmitterToDifferentUser(var SubmitterExpenseUser: Record "Expense User")
    begin
        SubmitterExpenseUser."User Id For Approvals" :=
            CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SubmitterExpenseUser."User Id For Approvals"));
        SubmitterExpenseUser.Modify();
    end;

    local procedure RemoveCurrentExpenseUserMappings()
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.SetRange("User Id For Approvals", UserId());
        ExpenseUser.ModifyAll("User Id For Approvals", '');
    end;

    local procedure SetCurrentUserUnlimitedExpenseApproval(UnlimitedExpenseApproval: Boolean)
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId()) then begin
            UserSetup.Init();
            UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
            UserSetup.Insert();
        end;

        UserSetup."Unlimited Expense Approval" := UnlimitedExpenseApproval;
        UserSetup.Modify();
    end;

}
