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
        // [SCENARIO] Global policies count line-policy pairs and use line categories, not blank policy scope.
        Initialize();

        // [GIVEN] L1 and L2 have different category codes sharing one display name and two global policies.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryLine(Header, SecondLine);
        SetHistoryCategoryName(Line, 'Meals "and" travel');
        SetHistoryCategoryName(SecondLine, 'Meals "and" travel');
        LibraryExpense.CreateExpensePolicy(PassedPolicy, '', 'Passing global policy');
        AddHistoryEvaluation(Line, Policy, false);
        AddHistoryEvaluation(Line, PassedPolicy, false);
        AddHistoryEvaluation(SecondLine, Policy, false);
        AddHistoryEvaluation(SecondLine, PassedPolicy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");

        // [WHEN] The report is submitted with already-current manual results.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] Three failed pairs and one pass retain only the distinct displayed line category name.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 3, 1, 1);
        VerifyFlaggedCategory(SubmissionID, 'Meals "and" travel');
    end;

    [Test]
    procedure ManualEvaluationDoesNotWriteHistory()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] Manual results and marks alone never create an activity entry.
        Initialize();

        // [GIVEN] An unsubmitted report with a policy.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        Header.Status := Header.Status::Open;
        Header.Modify(false);

        // [WHEN] A complete passing evaluation is recorded and confirmed.
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No activity was written.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure FinalMarkCapturesSnapshotOnce()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        SecondLine: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Only the final confirmation writes a report snapshot; repeated marks do not duplicate it.
        Initialize();

        // [GIVEN] H is submitted with two unconfirmed lines.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryLine(Header, SecondLine);
        SubmissionID := SubmitHistoryReport(Header);
        AddHistoryEvaluation(Line, Policy, false);
        AddHistoryEvaluation(SecondLine, Policy, true);

        // [WHEN] Only L1 is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] The report still waits for L2 without an error.
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] L2 and both lines are confirmed again.
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");

        // [THEN] Exactly one snapshot records both completed checks, including the failure.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 1, 1, 1);
        VerifyFlaggedCategory(SubmissionID, Line."Expense Category");
    end;

    [Test]
    procedure RepeatedMarksKeepOriginalSnapshot()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        OriginalEntry: Record "Expense Activity Log Entry";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirmation before and after category and policy changes preserves the original snapshot.
        Initialize();

        // [GIVEN] A flagged snapshot with a captured category display name.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SetHistoryCategoryName(Line, 'Original meals');
        AddHistoryEvaluation(Line, Policy, false);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);
        SetPolicySnapshotFilter(SubmissionID, OriginalEntry);
        OriginalEntry.FindFirst();

        // [WHEN] L is confirmed again before any changes.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] The immediate snapshot is not duplicated or modified.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 1, 0, 1);
        VerifyUnchangedPolicySnapshot(OriginalEntry);

        // [GIVEN] The category is renamed and P is disabled.
        SetHistoryCategoryName(Line, 'Renamed meals');
        Policy.Enabled := false;
        Policy.Modify(true);

        // [WHEN] The line is confirmed twice with no policies now applicable.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] The one stored failure is not re-derived as cleared or no policies.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 1, 0, 1);
        VerifyUnchangedPolicySnapshot(OriginalEntry);
        VerifyFlaggedCategory(SubmissionID, 'Original meals');
    end;

    [Test]
    procedure StaleLineWithoutPoliciesWaitsForConfirmation()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Removing policies does not erase the need to reconfirm a changed, previously evaluated line.
        Initialize();

        // [GIVEN] L was evaluated, then changed, and P was removed.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        Line.InvalidatePolicyEvaluation();
        Policy.Delete(true);

        // [WHEN] H is submitted.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] No snapshot is captured before the current version is confirmed.
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] L is confirmed against the empty policy set.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] The snapshot explicitly records no applicable policies.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::"No Policies", 0, 0, 0);
    end;

    [Test]
    procedure ResubmissionCapturesSecondSnapshot()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Every resubmission can capture its own current snapshot.
        Initialize();

        // [GIVEN] H has a snapshot from its first submission.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
        Header.Status := Header.Status::Rejected;
        Header.Modify(false);

        // [WHEN] H is resubmitted with the same current evidence.
        SubmissionID := SubmitHistoryReport(Header);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] There is one snapshot in the new round and two for the report.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Assert.RecordCount(Entry, 2);
    end;

    [Test]
    procedure PendingReportWithoutSubmissionHistoryDoesNotLog()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
        ActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        // [SCENARIO] Pending reports with only older creation history do not manufacture submission snapshots.
        Initialize();

        // [GIVEN] H is pending, but its history contains only Created.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        ActivityLogMgt.LogExpenseReportCreatedEvent(Header);
        Header.Status := Header.Status::"Pending Approval";
        Header.Modify(false);
        AddHistoryEvaluation(Line, Policy, true);

        // [WHEN] L is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] There is no policy snapshot or backfilled submission.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetFilter("Event Type", '<>%1', Entry."Event Type"::Created);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure NoApplicablePoliciesSnapshotIsNotCleared()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
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
    procedure DisabledPolicyEvaluationWritesNoHistory()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Setup: Record "Expense Agent Setup";
        Entry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] BC enforces the feature switch at submission and confirmation.
        Initialize();

        // [GIVEN] Complete results with policy evaluation disabled.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        Setup.Get();
        Setup."Evaluate Policies" := false;
        Setup.Modify(false);

        // [WHEN] H is submitted and L is confirmed with the feature disabled.
        SubmitHistoryReport(Header);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No policy activity is created.
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Assert.RecordIsEmpty(Entry);
    end;

    [Test]
    procedure PostingRetainsPolicySnapshot()
    var
        Header: Record "Expense Report Header";
        PostedHeader: Record "Posted Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
        OriginalEntry: Record "Expense Activity Log Entry";
        ActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Source reassignment preserves policy snapshot contents and subject identity.
        Initialize();

        // [GIVEN] A completed snapshot and a posted report.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SubmissionID := SubmitHistoryReport(Header);
        SetPolicySnapshotFilter(SubmissionID, OriginalEntry);
        OriginalEntry.FindFirst();
        PostedHeader."No." := Header."No.";
        PostedHeader.Insert(false);

        // [WHEN] Posting reassigns the report's history.
        ActivityLogMgt.ReassignExpenseReportEntriesToPosted(Header, PostedHeader);

        // [THEN] The policy snapshot is unchanged and attached to the posted source.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
        VerifyUnchangedPolicySnapshot(OriginalEntry);
        SetPolicySnapshotFilter(SubmissionID, Entry);
        Entry.FindFirst();
        Assert.AreEqual(Database::"Posted Expense Report Header", Entry."Source Table ID", 'The source table must identify the posted report.');
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
    procedure MarkCapturesPersistedUnconfirmedResults()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [SCENARIO] A worker confirms existing pairs even when live policy status already reads Cleared.
        Initialize();

        // [GIVEN] L has a passing persisted result but no confirmation and H is submitted.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryEvaluation(Line, Policy, true);
        Assert.AreEqual(Enum::"Expense Policy Status"::Cleared, Line.GetPolicyStatus(), 'The legacy status can precede confirmation.');
        SubmissionID := SubmitHistoryReport(Header);
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] The worker confirms the captured version.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] Exactly one completed snapshot contains the persisted passing evidence.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure MarkWaitsForStalePolicyOnAnotherLine()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        SecondLine: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirming one line waits without error when another line still has an old policy version.
        Initialize();

        // [GIVEN] Both lines were confirmed before P changed and H was submitted.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        AddHistoryLine(Header, SecondLine);
        AddHistoryEvaluation(Line, Policy, false);
        AddHistoryEvaluation(SecondLine, Policy, false);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");
        Policy."Policy Text" := 'Revised policy';
        Policy.Modify(true);
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] Submission itself cannot capture stale policy evidence.
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] L1 has a current passing result confirmed.
        AddHistoryEvaluation(Line, Policy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] L2's stale evidence does not produce a partial snapshot.
        VerifyNoPolicySnapshot(SubmissionID);

        // [WHEN] L2 has a current passing result confirmed.
        AddHistoryEvaluation(SecondLine, Policy, true);
        SecondLine.MarkPoliciesEvaluated(SecondLine."Policy Eval Version");

        // [THEN] Only the current passing pairs are captured.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 2, 0);
    end;

    [Test]
    procedure InterimApprovedReportCapturesFinalConfirmation()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Interim approval still leaves the report pending for policy history.
        Initialize();

        // [GIVEN] H was submitted and is now interim approved, with a current unconfirmed result.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Header.Status := Header.Status::"Interim Approved";
        Header.Modify(false);
        AddHistoryEvaluation(Line, Policy, true);

        // [WHEN] L is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] The pending report receives its completed snapshot.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Cleared, 0, 1, 0);
    end;

    [Test]
    procedure ApprovedReportDoesNotCaptureLaterMark()
    var
        Line: Record "Expense Report Line";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirmation after final approval does not create policy history.
        Initialize();

        // [GIVEN] H was submitted but approved before evaluation finished.
        SubmissionID := CreateUnconfirmedReportWithStatus(Line, Enum::"Expense Report Status"::Approved);

        // [WHEN] Its line is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No policy snapshot is created.
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure RejectedReportDoesNotCaptureLaterMark()
    var
        Line: Record "Expense Report Line";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirmation after rejection does not create policy history.
        Initialize();

        // [GIVEN] H was submitted but rejected before evaluation finished.
        SubmissionID := CreateUnconfirmedReportWithStatus(Line, Enum::"Expense Report Status"::Rejected);

        // [WHEN] Its line is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No policy snapshot is created.
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure RecalledReportDoesNotCaptureLaterMark()
    var
        Line: Record "Expense Report Line";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirmation on an open recalled report does not create policy history.
        Initialize();

        // [GIVEN] H was submitted but reopened before evaluation finished.
        SubmissionID := CreateUnconfirmedReportWithStatus(Line, Enum::"Expense Report Status"::Open);

        // [WHEN] Its line is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No policy snapshot is created.
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure ReleasedReportDoesNotCaptureLaterMark()
    var
        Line: Record "Expense Report Line";
        SubmissionID: Guid;
    begin
        // [SCENARIO] Confirmation on a released report does not create policy history.
        Initialize();

        // [GIVEN] H was submitted but returned to released before evaluation finished.
        SubmissionID := CreateUnconfirmedReportWithStatus(Line, Enum::"Expense Report Status"::Released);

        // [WHEN] Its line is confirmed.
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [THEN] No policy snapshot is created.
        VerifyNoPolicySnapshot(SubmissionID);
    end;

    [Test]
    procedure FlaggedCategoryNamesOverflowWithEllipsis()
    var
        Header: Record "Expense Report Header";
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        PassedPolicy: Record "Expense Policy";
        Entry: Record "Expense Activity Log Entry";
        ExpectedCategories: JsonArray;
        CategoriesText: Text;
        CategoryName: Text[250];
        SubmissionID: Guid;
        Index: Integer;
    begin
        // [SCENARIO] Escaped display names fill the boundary; overflow replaces the tail with one final marker.
        Initialize();

        // [GIVEN] Four long escaped names and one short name exactly fill the snapshot field.
        CreatePolicyHistoryScenario(Header, Line, Policy);
        LibraryExpense.CreateExpensePolicy(PassedPolicy, '', 'Passing global policy');
        for Index := 1 to 4 do begin
            CategoryName := Format(Index) + PadStr('', 245, '"') + '\end';
            SetHistoryCategoryName(Line, CategoryName);
            ExpectedCategories.Add(CategoryName);
            AddHistoryEvaluation(Line, Policy, false);
            AddHistoryEvaluation(Line, PassedPolicy, true);
            Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
            Clear(Line);
            AddHistoryLine(Header, Line);
        end;
        ExpectedCategories.WriteTo(CategoriesText);
        CategoryName := CopyStr(PadStr('Tail', MaxStrLen(Entry."Flagged Categories") - StrLen(CategoriesText) - 3, 'T'), 1, MaxStrLen(CategoryName));
        SetHistoryCategoryName(Line, CategoryName);
        ExpectedCategories.Add(CategoryName);
        ExpectedCategories.WriteTo(CategoriesText);
        Assert.AreEqual(MaxStrLen(Entry."Flagged Categories"), StrLen(CategoriesText), 'The fixture must exactly fill the serialized boundary.');
        AddHistoryEvaluation(Line, Policy, false);
        AddHistoryEvaluation(Line, PassedPolicy, true);
        Line.MarkPoliciesEvaluated(Line."Policy Eval Version");

        // [GIVEN] Two further names overflow, with both failed and passing checks after the boundary.
        for Index := 5 to 6 do begin
            Clear(Line);
            AddHistoryLine(Header, Line);
            CategoryName := Format(Index) + PadStr('', 245, '"') + '\end';
            SetHistoryCategoryName(Line, CategoryName);
            AddHistoryEvaluation(Line, Policy, false);
            AddHistoryEvaluation(Line, PassedPolicy, true);
            Line.MarkPoliciesEvaluated(Line."Policy Eval Version");
        end;
        ExpectedCategories.RemoveAt(ExpectedCategories.Count() - 1);
        ExpectedCategories.Add('...');

        // [WHEN] H is submitted.
        SubmissionID := SubmitHistoryReport(Header);

        // [THEN] Counts include every pair while the valid preview keeps four distinct names and one marker.
        VerifyPolicySnapshot(SubmissionID, Enum::"Expense Policy Status"::Flagged, 7, 7, 5);
        VerifyFlaggedCategoryPreview(SubmissionID, ExpectedCategories);
    end;

    [Test]
    procedure HeaderPolicySummaryAggregatesWithoutWriting()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        OriginalExpenseReportHeader: Record "Expense Report Header";
        FirstExpenseReportLine: Record "Expense Report Line";
        SecondExpenseReportLine: Record "Expense Report Line";
        ThirdExpenseReportLine: Record "Expense Report Line";
        ClearedExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        PassingExpensePolicy: Record "Expense Policy";
        PolicyStatus: Enum "Expense Policy Status";
        FailedCount: Integer;
        PassedCount: Integer;
        FlaggedCategoryNames: List of [Text];
        IsComplete: Boolean;
    begin
        // [SCENARIO] The header reads all current pairs and distinct category names without changing an unsubmitted report.
        Initialize();

        // [GIVEN] H has three flagged lines and one cleared line, each evaluated against two global policies.
        CreatePolicyHistoryScenario(ExpenseReportHeader, FirstExpenseReportLine, ExpensePolicy);
        AddHistoryLine(ExpenseReportHeader, SecondExpenseReportLine);
        AddHistoryLine(ExpenseReportHeader, ThirdExpenseReportLine);
        AddHistoryLine(ExpenseReportHeader, ClearedExpenseReportLine);
        SetHistoryCategoryName(FirstExpenseReportLine, 'Meals "and" travel');
        SetHistoryCategoryName(SecondExpenseReportLine, 'Meals "and" travel');
        SetHistoryCategoryName(ThirdExpenseReportLine, '');
        LibraryExpense.CreateExpensePolicy(PassingExpensePolicy, '', 'Passing global policy');
        AddHistoryEvaluation(FirstExpenseReportLine, ExpensePolicy, false);
        AddHistoryEvaluation(FirstExpenseReportLine, PassingExpensePolicy, true);
        AddHistoryEvaluation(SecondExpenseReportLine, ExpensePolicy, false);
        AddHistoryEvaluation(SecondExpenseReportLine, PassingExpensePolicy, true);
        AddHistoryEvaluation(ThirdExpenseReportLine, ExpensePolicy, false);
        AddHistoryEvaluation(ThirdExpenseReportLine, PassingExpensePolicy, true);
        AddHistoryEvaluation(ClearedExpenseReportLine, ExpensePolicy, true);
        AddHistoryEvaluation(ClearedExpenseReportLine, PassingExpensePolicy, true);
        FirstExpenseReportLine.MarkPoliciesEvaluated(FirstExpenseReportLine."Policy Eval Version");
        SecondExpenseReportLine.MarkPoliciesEvaluated(SecondExpenseReportLine."Policy Eval Version");
        ThirdExpenseReportLine.MarkPoliciesEvaluated(ThirdExpenseReportLine."Policy Eval Version");
        ClearedExpenseReportLine.MarkPoliciesEvaluated(ClearedExpenseReportLine."Policy Eval Version");
        FirstExpenseReportLine.Get(FirstExpenseReportLine."Document No.", FirstExpenseReportLine."Line No.");
        SecondExpenseReportLine.Get(SecondExpenseReportLine."Document No.", SecondExpenseReportLine."Line No.");
        ThirdExpenseReportLine.Get(ThirdExpenseReportLine."Document No.", ThirdExpenseReportLine."Line No.");
        ClearedExpenseReportLine.Get(ClearedExpenseReportLine."Document No.", ClearedExpenseReportLine."Line No.");
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        OriginalExpenseReportHeader := ExpenseReportHeader;
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Old category');

        // [WHEN] H is read directly through the rich helper.
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] Both overloads agree, count all pairs, and return distinct names in line order with code fallback.
        Assert.IsTrue(IsComplete, 'Confirmed results must be complete even before submission.');
        Assert.AreEqual(IsComplete, ExpenseReportHeader.IsPolicyEvaluationComplete(), 'Both header overloads must agree.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::Flagged, 3, 5, 2);
        Assert.AreEqual('Meals "and" travel', FlaggedCategoryNames.Get(1), 'Shared descriptions must appear only once at their first line position.');
        Assert.AreEqual(ThirdExpenseReportLine."Expense Category", FlaggedCategoryNames.Get(2), 'A blank description must fall back to the category code.');

        // [THEN] H and every line retain their stored versions and status, and no activity is created.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        Assert.AreEqual(OriginalExpenseReportHeader.SystemRowVersion, ExpenseReportHeader.SystemRowVersion, 'Reading the summary must not modify the header.');
        Assert.AreEqual(OriginalExpenseReportHeader.Status, ExpenseReportHeader.Status, 'Reading the summary must not change report status.');
        VerifyUnchangedPolicySummaryLine(FirstExpenseReportLine);
        VerifyUnchangedPolicySummaryLine(SecondExpenseReportLine);
        VerifyUnchangedPolicySummaryLine(ThirdExpenseReportLine);
        VerifyUnchangedPolicySummaryLine(ClearedExpenseReportLine);
        VerifyNoReportActivity(ExpenseReportHeader);
    end;

    [Test]
    procedure HeaderPolicySummaryClearsIncompleteResultsOnEveryRead()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        FreshExpenseReportHeader: Record "Expense Report Header";
        FirstExpenseReportLine: Record "Expense Report Line";
        SecondExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        PolicyStatus: Enum "Expense Policy Status";
        FailedCount: Integer;
        PassedCount: Integer;
        FlaggedCategoryNames: List of [Text];
        IsComplete: Boolean;
    begin
        // [SCENARIO] A later unconfirmed line discards partial results on repeated and freshly loaded header reads.
        Initialize();

        // [GIVEN] H has a confirmed flagged L1 followed by an unconfirmed flagged L2 and seeded outputs.
        CreatePolicyHistoryScenario(ExpenseReportHeader, FirstExpenseReportLine, ExpensePolicy);
        AddHistoryLine(ExpenseReportHeader, SecondExpenseReportLine);
        SetHistoryCategoryName(FirstExpenseReportLine, 'First category');
        SetHistoryCategoryName(SecondExpenseReportLine, 'Second category');
        AddHistoryEvaluation(FirstExpenseReportLine, ExpensePolicy, false);
        AddHistoryEvaluation(SecondExpenseReportLine, ExpensePolicy, false);
        FirstExpenseReportLine.MarkPoliciesEvaluated(FirstExpenseReportLine."Policy Eval Version");
        PolicyStatus := PolicyStatus::Flagged;
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Old category');

        // [WHEN] H is read before L2 is confirmed.
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] No partial flagged result escapes, and both overloads return false.
        Assert.IsFalse(IsComplete, 'An unconfirmed later line must prevent report completion.');
        Assert.AreEqual(IsComplete, ExpenseReportHeader.IsPolicyEvaluationComplete(), 'Both header overloads must agree for an incomplete report.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::"Not Evaluated", 0, 0, 0);

        // [WHEN] The same header and outputs are reused.
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] Reading again cannot expose L1's accumulated counts or names.
        Assert.IsFalse(IsComplete, 'Repeated reads must still wait for L2.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::"Not Evaluated", 0, 0, 0);

        // [WHEN] A fresh H is read with newly seeded outputs.
        FreshExpenseReportHeader.Get(ExpenseReportHeader."No.");
        PolicyStatus := PolicyStatus::Flagged;
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Another old category');
        IsComplete := FreshExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] Fresh reads also discard all partial and caller-provided outputs without logging.
        Assert.IsFalse(IsComplete, 'A fresh header must observe the unconfirmed line.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::"Not Evaluated", 0, 0, 0);
        VerifyNoReportActivity(ExpenseReportHeader);

        // [WHEN] L2 is confirmed and the rich helper is called again with reused, seeded outputs.
        SecondExpenseReportLine.MarkPoliciesEvaluated(SecondExpenseReportLine."Policy Eval Version");
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Obsolete category');
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] The complete summary includes both current names and no stale entries or activity.
        Assert.IsTrue(IsComplete, 'Confirming the remaining line must complete the report.');
        Assert.AreEqual(IsComplete, ExpenseReportHeader.IsPolicyEvaluationComplete(), 'Both overloads must agree after final confirmation.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::Flagged, 2, 0, 2);
        Assert.AreEqual('First category', FlaggedCategoryNames.Get(1), 'The first flagged category must retain line order.');
        Assert.AreEqual('Second category', FlaggedCategoryNames.Get(2), 'The newly confirmed category must replace stale caller entries.');
        VerifyNoReportActivity(ExpenseReportHeader);
    end;

    [Test]
    procedure HeaderPolicySummaryWithoutPoliciesOrLinesClearsOutputs()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        PolicyStatus: Enum "Expense Policy Status";
        FailedCount: Integer;
        PassedCount: Integer;
        FlaggedCategoryNames: List of [Text];
        IsComplete: Boolean;
    begin
        // [SCENARIO] No applicable policies and zero lines are complete helper results with empty overwritten outputs.
        Initialize();

        // [GIVEN] H has an unconfirmed L but no policies, and the caller has nonempty outputs.
        CreatePolicyHistoryScenario(ExpenseReportHeader, ExpenseReportLine, ExpensePolicy);
        ExpensePolicy.Delete(false);
        PolicyStatus := PolicyStatus::Flagged;
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Old category');

        // [WHEN] H is read without applicable policies.
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] No confirmation is required and both overloads report completion without retaining caller data.
        Assert.IsTrue(IsComplete, 'A line with no applicable policies must be complete without confirmation.');
        Assert.AreEqual(IsComplete, ExpenseReportHeader.IsPolicyEvaluationComplete(), 'Both overloads must agree when no policies apply.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::"No Policies", 0, 0, 0);
        VerifyNoReportActivity(ExpenseReportHeader);

        // [GIVEN] H now has zero lines and the outputs contain earlier caller data again.
        ExpenseReportLine.Delete(false);
        PolicyStatus := PolicyStatus::Flagged;
        FailedCount := 99;
        PassedCount := 99;
        FlaggedCategoryNames.Add('Another old category');

        // [WHEN] The helper reads H with zero lines, independently of submission validation.
        IsComplete := ExpenseReportHeader.IsPolicyEvaluationComplete(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames);

        // [THEN] An empty header has the same complete, empty No Policies summary.
        Assert.IsTrue(IsComplete, 'The helper must return complete for a header with zero lines.');
        Assert.AreEqual(IsComplete, ExpenseReportHeader.IsPolicyEvaluationComplete(), 'Both overloads must agree when the header has zero lines.');
        VerifyHeaderPolicySummary(PolicyStatus, FailedCount, PassedCount, FlaggedCategoryNames, PolicyStatus::"No Policies", 0, 0, 0);
        VerifyNoReportActivity(ExpenseReportHeader);
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

    local procedure VerifyHeaderPolicySummary(PolicyStatus: Enum "Expense Policy Status"; FailedCount: Integer; PassedCount: Integer; FlaggedCategoryNames: List of [Text]; ExpectedPolicyStatus: Enum "Expense Policy Status"; ExpectedFailedCount: Integer; ExpectedPassedCount: Integer; ExpectedCategoryCount: Integer)
    begin
        Assert.AreEqual(ExpectedPolicyStatus, PolicyStatus, 'The summary must return the complete status or the offending incomplete line status.');
        Assert.AreEqual(ExpectedFailedCount, FailedCount, 'The failed count must contain only complete current line-policy pairs.');
        Assert.AreEqual(ExpectedPassedCount, PassedCount, 'The passed count must contain only complete current line-policy pairs.');
        Assert.AreEqual(ExpectedCategoryCount, FlaggedCategoryNames.Count(), 'The category list must discard caller entries and incomplete partial results.');
    end;

    local procedure VerifyUnchangedPolicySummaryLine(OriginalExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Get(OriginalExpenseReportLine."Document No.", OriginalExpenseReportLine."Line No.");
        Assert.AreEqual(OriginalExpenseReportLine.SystemRowVersion, ExpenseReportLine.SystemRowVersion, 'Reading the summary must not modify the line.');
        Assert.AreEqual(OriginalExpenseReportLine."Policy Eval Version", ExpenseReportLine."Policy Eval Version", 'Reading the summary must preserve the line policy version.');
        Assert.AreEqual(OriginalExpenseReportLine."Evaluated Policy Version", ExpenseReportLine."Evaluated Policy Version", 'Reading the summary must preserve the confirmed version.');
        Assert.AreEqual(OriginalExpenseReportLine.GetPolicyStatus(), ExpenseReportLine.GetPolicyStatus(), 'Reading the summary must preserve line policy status.');
    end;

    local procedure VerifyNoReportActivity(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Subject Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
    end;

    local procedure VerifyNoPolicySnapshot(SubmissionID: Guid)
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        SetPolicySnapshotFilter(SubmissionID, Entry);
        Assert.RecordIsEmpty(Entry);
    end;

    local procedure CreateUnconfirmedReportWithStatus(var Line: Record "Expense Report Line"; Status: Enum "Expense Report Status") SubmissionID: Guid
    var
        Header: Record "Expense Report Header";
        Policy: Record "Expense Policy";
    begin
        CreatePolicyHistoryScenario(Header, Line, Policy);
        SubmissionID := SubmitHistoryReport(Header);
        Header.Status := Status;
        Header.Modify(false);
        AddHistoryEvaluation(Line, Policy, true);
    end;

    local procedure VerifyFlaggedCategoryPreview(SubmissionID: Guid; ExpectedCategories: JsonArray)
    var
        Entry: Record "Expense Activity Log Entry";
        Categories: JsonArray;
        LastCategory: JsonToken;
        ExpectedText: Text;
    begin
        SetPolicySnapshotFilter(SubmissionID, Entry);
        Entry.FindFirst();
        Assert.IsTrue(StrLen(Entry."Flagged Categories") <= MaxStrLen(Entry."Flagged Categories"), 'The preview must fit the field.');
        Assert.IsTrue(Categories.ReadFrom(Entry."Flagged Categories"), 'The preview must be a valid JSON array.');
        ExpectedCategories.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, Entry."Flagged Categories", 'Distinct escaped names must retain line order with exactly one final marker.');
        Categories.Get(Categories.Count() - 1, LastCategory);
        Assert.AreEqual('...', LastCategory.AsValue().AsText(), 'Overflow must end with a separate ellipsis entry.');
    end;

    local procedure VerifyUnchangedPolicySnapshot(OriginalEntry: Record "Expense Activity Log Entry")
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        Entry.Get(OriginalEntry."Entry No.");
        Assert.AreEqual(OriginalEntry.SystemId, Entry.SystemId, 'The event identity must be preserved.');
        Assert.AreEqual(OriginalEntry."Subject System ID", Entry."Subject System ID", 'The subject identity must be preserved.');
        Assert.AreEqual(OriginalEntry."Occurred At", Entry."Occurred At", 'Capture time must not change.');
        Assert.AreEqual(OriginalEntry."Flagged Categories", Entry."Flagged Categories", 'The category preview must not be recalculated.');
        Assert.AreEqual(OriginalEntry.Comment, Entry.Comment, 'The captured summary must not change.');
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

    local procedure SetHistoryCategoryName(Line: Record "Expense Report Line"; CategoryName: Text[250])
    var
        Category: Record "Expense Category";
    begin
        Category.Get(Line."Expense Category");
        Category.Description := CategoryName;
        Category.Modify(false);
    end;

    local procedure SubmitHistoryReport(var Header: Record "Expense Report Header") SubmissionID: Guid
    var
        Entry: Record "Expense Activity Log Entry";
        ApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ApprovalMgmt.Submit(Header, Header."Expense User No.");
        Entry.SetRange("Subject System ID", Header.SystemId);
        Entry.SetFilter("Event Type", '%1|%2', Entry."Event Type"::Submitted, Entry."Event Type"::Resubmitted);
        Entry.FindLast();
        exit(Entry.SystemId);
    end;

    local procedure VerifyPolicySnapshot(SubmissionID: Guid; Status: Enum "Expense Policy Status"; FailedCount: Integer; PassedCount: Integer; ExpectedCategoryCount: Integer)
    var
        Entry: Record "Expense Activity Log Entry";
        Categories: JsonArray;
    begin
        SetPolicySnapshotFilter(SubmissionID, Entry);
        Assert.RecordCount(Entry, 1);
        Entry.FindFirst();
        Assert.AreEqual(Enum::"Expense Activity Event Type"::PolicyEvaluated, Entry."Event Type", 'The event type must identify the policy snapshot.');
        Assert.AreEqual(Status, Entry."Policy Status", 'Snapshot status must reflect all applicable pairs.');
        Assert.AreEqual(FailedCount, Entry."Failed Policy Count", 'Failed count counts line-policy pairs.');
        Assert.AreEqual(PassedCount, Entry."Passed Policy Count", 'Passed count counts line-policy pairs.');
        Assert.IsTrue(Categories.ReadFrom(Entry."Flagged Categories"), 'Flagged categories must be valid JSON.');
        Assert.AreEqual(ExpectedCategoryCount, Categories.Count(), 'The preview must contain the expected number of entries.');
        Assert.AreEqual(Enum::"Expense Activity Initiator"::Agent, Entry."Initiated By", 'The snapshot is agent initiated.');
        Assert.AreEqual(0, Entry."Actor Role".AsInteger(), 'No actor role may grant history access.');
        Assert.AreEqual(0, Entry."Actor Table ID", 'No human identity may be attached.');
        Assert.IsTrue(IsNullGuid(Entry."Actor Record System ID"), 'No human identity may be attached.');
        Assert.AreNotEqual(0DT, Entry."Occurred At", 'A captured policy event must have a history timestamp.');
    end;

    local procedure VerifyFlaggedCategory(SubmissionID: Guid; CategoryName: Text[250])
    var
        Entry: Record "Expense Activity Log Entry";
        Categories: JsonArray;
        Category: JsonToken;
    begin
        SetPolicySnapshotFilter(SubmissionID, Entry);
        Entry.FindFirst();
        Assert.IsTrue(Categories.ReadFrom(Entry."Flagged Categories"), 'Flagged categories must be valid JSON.');
        Assert.AreEqual(1, Categories.Count(), 'Repeated failures and shared display names must not duplicate categories.');
        Categories.Get(0, Category);
        Assert.AreEqual(CategoryName, Category.AsValue().AsText(), 'Capture the display name, falling back to the code for a blank description.');
    end;

    local procedure SetPolicySnapshotFilter(SubmissionID: Guid; var Entry: Record "Expense Activity Log Entry")
    var
        SubmissionEntry: Record "Expense Activity Log Entry";
    begin
        SubmissionEntry.GetBySystemId(SubmissionID);
        Entry.SetRange("Subject Table ID", Database::"Expense Report Header");
        Entry.SetRange("Subject System ID", SubmissionEntry."Subject System ID");
        Entry.SetRange("Event Type", Entry."Event Type"::PolicyEvaluated);
        Entry.SetFilter("Entry No.", '>%1', SubmissionEntry."Entry No.");
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
