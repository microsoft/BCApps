// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;
using System.Security.AccessControl;

codeunit 6926 "Expense Activity Log Mgt."
{
    Access = Internal;
    Permissions = tabledata "Expense Activity Log Entry" = rimd,
                  tabledata "Expense Agent Setup" = r,
                  tabledata User = r;

    /// <summary>
    /// Appends an activity entry for an in-flight expense report.
    /// </summary>
    internal procedure LogExpenseReportEvent(
        ExpenseReportHeader: Record "Expense Report Header";
        EventType: Enum "Expense Activity Event Type";
        InitiatedBy: Enum "Expense Activity Initiator";
        ActorRole: Enum "Expense Activity Actor Role";
        ActorExpenseUserNo: Code[20];
        EventComment: Text
    ): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        InitializeExpenseReportEntry(
            ExpenseActivityLogEntry, ExpenseReportHeader, EventType, InitiatedBy, ActorRole, EventComment, CurrentDateTime());
        SetExpenseUserActor(ExpenseActivityLogEntry, ActorExpenseUserNo);
        exit(InsertExpenseReportEntry(ExpenseActivityLogEntry, ExpenseReportHeader));
    end;

    /// <summary>
    /// Appends an activity entry performed directly by a Business Central user.
    /// </summary>
    internal procedure LogExpenseReportEventByBCUser(
        ExpenseReportHeader: Record "Expense Report Header";
        EventType: Enum "Expense Activity Event Type";
        ActorRole: Enum "Expense Activity Actor Role";
        EventComment: Text
    ): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        InitializeExpenseReportEntry(
            ExpenseActivityLogEntry, ExpenseReportHeader, EventType,
            Enum::"Expense Activity Initiator"::User, ActorRole, EventComment, CurrentDateTime());
        SetBCUserActor(ExpenseActivityLogEntry, UserSecurityId());
        exit(InsertExpenseReportEntry(ExpenseActivityLogEntry, ExpenseReportHeader));
    end;

    /// <summary>
    /// Appends the retrospective creation entry when activity tracking starts at first submission.
    /// </summary>
    internal procedure LogExpenseReportCreatedEvent(ExpenseReportHeader: Record "Expense Report Header"): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        OccurredAt: DateTime;
    begin
        OccurredAt := ExpenseReportHeader.SystemCreatedAt;
        if OccurredAt = 0DT then
            OccurredAt := CurrentDateTime();

        InitializeExpenseReportEntry(
            ExpenseActivityLogEntry, ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            '', OccurredAt);

        // Expense Agent API creation stores the report's Expense User; direct BC creation is identified by SystemCreatedBy.
        if not IsNullGuid(ExpenseReportHeader."Created By Exp. User Id") then
            SetExpenseUserActorBySystemID(ExpenseActivityLogEntry, ExpenseReportHeader."Created By Exp. User Id")
        else
            SetBCUserActor(ExpenseActivityLogEntry, ExpenseReportHeader.SystemCreatedBy);

        exit(InsertExpenseReportEntry(ExpenseActivityLogEntry, ExpenseReportHeader));
    end;

    /// <summary>
    /// Appends an activity entry for a travel request.
    /// The actor is the given expense user or, when no expense user is given, the current Business Central user.
    /// </summary>
    internal procedure LogTravelRequestEvent(
        SpendRequest: Record "Spend Request";
        EventType: Enum "Expense Activity Event Type";
        ActorRole: Enum "Expense Activity Actor Role";
        ActorExpenseUserNo: Code[20];
        EventComment: Text
    ): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        InitializeTravelRequestEntry(
            ExpenseActivityLogEntry, SpendRequest, EventType, ActorRole, EventComment, CurrentDateTime());
        if ActorExpenseUserNo <> '' then
            SetExpenseUserActor(ExpenseActivityLogEntry, ActorExpenseUserNo)
        else
            SetBCUserActor(ExpenseActivityLogEntry, UserSecurityId());
        exit(InsertTravelRequestEntry(ExpenseActivityLogEntry, SpendRequest));
    end;

    /// <summary>
    /// Appends the retrospective creation entry when travel request activity tracking starts at first submission.
    /// </summary>
    internal procedure LogTravelRequestCreatedEvent(SpendRequest: Record "Spend Request"): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        Requester: Record "Expense User";
        OccurredAt: DateTime;
    begin
        OccurredAt := SpendRequest.SystemCreatedAt;
        if OccurredAt = 0DT then
            OccurredAt := CurrentDateTime();

        InitializeTravelRequestEntry(
            ExpenseActivityLogEntry, SpendRequest,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Actor Role"::Submitter,
            '', OccurredAt);

        // Travel requests are owned by the requesting expense user; fall back to the BC user who created the record.
        Requester.SetLoadFields(SystemId);
        Requester.SetRange("Employee No.", SpendRequest."Requested By");
        if (SpendRequest."Requested By" <> '') and Requester.FindFirst() then
            SetExpenseUserActorBySystemID(ExpenseActivityLogEntry, Requester.SystemId)
        else
            SetBCUserActor(ExpenseActivityLogEntry, SpendRequest.SystemCreatedBy);

        exit(InsertTravelRequestEntry(ExpenseActivityLogEntry, SpendRequest));
    end;

    /// <summary>
    /// Logs the creation of an expense report created automatically by the Expense Agent from an approved travel request.
    /// </summary>
    internal procedure LogExpenseReportCreatedFromTravelRequest(ExpenseReportHeader: Record "Expense Report Header"): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // This Created entry also prevents the retrospective Created entry at first submission.
        InitializeExpenseReportEntry(
            ExpenseActivityLogEntry, ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Created,
            Enum::"Expense Activity Initiator"::Agent,
            Enum::"Expense Activity Actor Role"::" ",
            '', CurrentDateTime());
        SetExpenseAgentActor(ExpenseActivityLogEntry);
        exit(InsertExpenseReportEntry(ExpenseActivityLogEntry, ExpenseReportHeader));
    end;

    /// <summary>
    /// Logs once on an approved travel request that the Expense Agent created its expense reports automatically.
    /// </summary>
    internal procedure LogTravelRequestExpenseReportsCreated(SpendRequest: Record "Spend Request"): BigInteger
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        InitializeTravelRequestEntry(
            ExpenseActivityLogEntry, SpendRequest,
            Enum::"Expense Activity Event Type"::ExpenseReportCreated,
            Enum::"Expense Activity Actor Role"::" ",
            '', CurrentDateTime());
        ExpenseActivityLogEntry."Initiated By" := Enum::"Expense Activity Initiator"::Agent;
        SetExpenseAgentActor(ExpenseActivityLogEntry);
        exit(InsertTravelRequestEntry(ExpenseActivityLogEntry, SpendRequest));
    end;

    /// <summary>
    /// Reassigns a report's entries to the posted report while preserving event and subject identity.
    /// </summary>
    internal procedure ReassignExpenseReportEntriesToPosted(
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header"
    )
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        EntryNumbers: List of [BigInteger];
        EntryNumber: BigInteger;
    begin
        // Capture the primary keys before changing fields used by the source filter.
        ExpenseActivityLogEntry.SetLoadFields("Entry No.");
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        if ExpenseActivityLogEntry.FindSet() then
            repeat
                EntryNumbers.Add(ExpenseActivityLogEntry."Entry No.");
            until ExpenseActivityLogEntry.Next() = 0;

        // Update both source fields together so an entry cannot be left with an intermediate source identity.
        foreach EntryNumber in EntryNumbers do begin
            ExpenseActivityLogEntry.Get(EntryNumber);
            ExpenseActivityLogEntry."Source Table ID" := Database::"Posted Expense Report Header";
            ExpenseActivityLogEntry."Source Record System ID" := PostedExpenseReportHeader.SystemId;
            ExpenseActivityLogEntry.Modify(false);
        end;
    end;

    /// <summary>
    /// Deletes activity entries sourced from the specified record.
    /// </summary>
    internal procedure DeleteEntriesForSource(SourceTableID: Integer; SourceRecordSystemID: Guid)
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", SourceTableID);
        ExpenseActivityLogEntry.SetRange("Source Record System ID", SourceRecordSystemID);
        ExpenseActivityLogEntry.DeleteAll();
    end;

    internal procedure HasEntriesForSource(SourceTableID: Integer; SourceRecordSystemID: Guid): Boolean
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", SourceTableID);
        ExpenseActivityLogEntry.SetRange("Source Record System ID", SourceRecordSystemID);
        exit(not ExpenseActivityLogEntry.IsEmpty());
    end;

    internal procedure HasSubmissionForSource(SourceTableID: Integer; SourceRecordSystemID: Guid): Boolean
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", SourceTableID);
        ExpenseActivityLogEntry.SetRange("Source Record System ID", SourceRecordSystemID);
        ExpenseActivityLogEntry.SetFilter(
            "Event Type", '%1|%2',
            ExpenseActivityLogEntry."Event Type"::Submitted,
            ExpenseActivityLogEntry."Event Type"::Resubmitted);
        exit(not ExpenseActivityLogEntry.IsEmpty());
    end;

    internal procedure LogPolicyEvaluationIfReady(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SubmissionEntry: Record "Expense Activity Log Entry";
        Snapshot: Record "Expense Activity Log Entry";
        FlaggedCategories: List of [Code[20]];
        CategoryCode: Code[20];
        Categories: JsonArray;
        CategoriesText: Text;
        CategoriesTruncated: Boolean;
        SummaryLbl: Label '%1. Failed policy checks: %2. Passed policy checks: %3.', Comment = '%1 = policy status, %2 = failed line-policy pairs, %3 = passed line-policy pairs';
    begin
        // Policy history is opt-in; absent setup also leaves it disabled.
        if not ExpenseAgentSetup.Get() then
            exit;
        if not ExpenseAgentSetup."Evaluate Policies" then
            exit;

        // Both submission and line confirmation lock the header before reading the report's lines.
        ExpenseReportHeader.ReadIsolation := IsolationLevel::UpdLock;
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        // Ignore draft checks and results arriving after the report leaves approval.
        if not ExpenseReportHeader.IsApprovalPending() then
            exit;

        SubmissionEntry.SetRange("Source Table ID", Database::"Expense Report Header");
        SubmissionEntry.SetRange("Source Record System ID", ExpenseReportHeader.SystemId);
        SubmissionEntry.SetRange("Subject Table ID", Database::"Expense Report Header");
        SubmissionEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        SubmissionEntry.SetFilter("Event Type", '%1|%2', SubmissionEntry."Event Type"::Submitted, SubmissionEntry."Event Type"::Resubmitted);
        // Do not create policy history for an untracked submission.
        // Keep primary-key order so FindLast returns the latest submission across both event types; the SourceEvent key serves the filters.
        SubmissionEntry.SetLoadFields("Entry No.");
        if not SubmissionEntry.FindLast() then
            exit;

        Snapshot.CopyFilters(SubmissionEntry);
        Snapshot.SetRange("Event Type", Snapshot."Event Type"::PolicyEvaluated);
        Snapshot.SetFilter("Entry No.", '>%1', SubmissionEntry."Entry No.");
        // Read the latest committed entries; a cached empty result could otherwise hide an existing snapshot and log a duplicate.
        SelectLatestVersion(Database::"Expense Activity Log Entry");
        // Log at most one PolicyEvaluated entry after the latest Submitted/Resubmitted entry.
        // Example (Entry No.): Submitted 100, PolicyEvaluated 101 => skip duplicate.
        // Resubmitted 105 starts a new round; entry 101 remains in history.
        // Only PolicyEvaluated entries after 105 prevent another snapshot in that round.
        if not Snapshot.IsEmpty() then
            exit;
        Snapshot.Reset();

        InitializeExpenseReportEntry(
            Snapshot, ExpenseReportHeader, Enum::"Expense Activity Event Type"::PolicyEvaluated,
            Enum::"Expense Activity Initiator"::Agent, Enum::"Expense Activity Actor Role"::" ", '', 0DT);
        SetBCUserActor(Snapshot, ExpenseAgentSetup."User Security ID");
        // Wait for complete, current results across all lines; a later confirmation retries.
        if not ExpenseReportHeader.IsPolicyEvaluationComplete(
            Snapshot."Policy Status", Snapshot."Failed Policy Count", Snapshot."Passed Policy Count", FlaggedCategories)
        then
            exit;

        foreach CategoryCode in FlaggedCategories do
            AddBoundedCategory(Categories, CategoryCode, MaxStrLen(Snapshot."Flagged Categories"), CategoriesText, CategoriesTruncated);
        Categories.WriteTo(CategoriesText);
        Snapshot."Flagged Categories" := CopyStr(CategoriesText, 1, MaxStrLen(Snapshot."Flagged Categories"));
        Snapshot."Occurred At" := CurrentDateTime();
        Snapshot.Comment := CopyStr(
            StrSubstNo(SummaryLbl, Format(Snapshot."Policy Status"), Snapshot."Failed Policy Count", Snapshot."Passed Policy Count"),
            1, MaxStrLen(Snapshot.Comment));
        InsertExpenseReportEntry(Snapshot, ExpenseReportHeader);
    end;

    local procedure InitializeExpenseReportEntry(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportHeader: Record "Expense Report Header";
        EventType: Enum "Expense Activity Event Type";
        InitiatedBy: Enum "Expense Activity Initiator";
        ActorRole: Enum "Expense Activity Actor Role";
        EventComment: Text;
        OccurredAt: DateTime
    )
    begin
        ExpenseActivityLogEntry.Init();
        ExpenseActivityLogEntry."Source Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Source Record System ID" := ExpenseReportHeader.SystemId;
        ExpenseActivityLogEntry."Subject Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Subject System ID" := ExpenseReportHeader.SystemId;
        ExpenseActivityLogEntry."Document No." := ExpenseReportHeader."No.";
        ExpenseActivityLogEntry."Document Description" := ExpenseReportHeader.Description;
        ExpenseActivityLogEntry."Event Type" := EventType;
        ExpenseActivityLogEntry."Occurred At" := OccurredAt;
        ExpenseActivityLogEntry."Initiated By" := InitiatedBy;
        ExpenseActivityLogEntry."Actor Role" := ActorRole;
        SetEntryComment(ExpenseActivityLogEntry, EventComment);
    end;

    local procedure InitializeTravelRequestEntry(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        SpendRequest: Record "Spend Request";
        EventType: Enum "Expense Activity Event Type";
        ActorRole: Enum "Expense Activity Actor Role";
        EventComment: Text;
        OccurredAt: DateTime
    )
    begin
        ExpenseActivityLogEntry.Init();
        ExpenseActivityLogEntry."Source Table ID" := Database::"Spend Request";
        ExpenseActivityLogEntry."Source Record System ID" := SpendRequest.SystemId;
        ExpenseActivityLogEntry."Subject Table ID" := Database::"Spend Request";
        ExpenseActivityLogEntry."Subject System ID" := SpendRequest.SystemId;
        ExpenseActivityLogEntry."Document No." := SpendRequest."No.";
        ExpenseActivityLogEntry."Document Description" :=
            CopyStr(SpendRequest.Purpose, 1, MaxStrLen(ExpenseActivityLogEntry."Document Description"));
        ExpenseActivityLogEntry."Event Type" := EventType;
        ExpenseActivityLogEntry."Occurred At" := OccurredAt;
        ExpenseActivityLogEntry."Initiated By" := Enum::"Expense Activity Initiator"::User;
        ExpenseActivityLogEntry."Actor Role" := ActorRole;
        SetEntryComment(ExpenseActivityLogEntry, EventComment);
    end;

    local procedure SetEntryComment(var ExpenseActivityLogEntry: Record "Expense Activity Log Entry"; EventComment: Text)
    begin
        if StrLen(EventComment) > MaxStrLen(ExpenseActivityLogEntry.Comment) then
            ExpenseActivityLogEntry.Comment :=
                CopyStr(EventComment, 1, MaxStrLen(ExpenseActivityLogEntry.Comment) - 3) + '...'
        else
            ExpenseActivityLogEntry.Comment := CopyStr(EventComment, 1, MaxStrLen(ExpenseActivityLogEntry.Comment));
    end;

    local procedure InsertTravelRequestEntry(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        SpendRequest: Record "Spend Request"
    ): BigInteger
    begin
        if ExpenseActivityLogEntry."Event Type" in [
            ExpenseActivityLogEntry."Event Type"::Submitted,
            ExpenseActivityLogEntry."Event Type"::Resubmitted]
        then begin
            ExpenseActivityLogEntry."Total Expected Amount" := SpendRequest."Total Expected Amount";
            ExpenseActivityLogEntry."Currency Code" := SpendRequest."Currency Code";
            ExpenseActivityLogEntry."Amount (LCY)" := SpendRequest."Total Expected Amount (LCY)";
        end;

        ExpenseActivityLogEntry.Insert();
        exit(ExpenseActivityLogEntry."Entry No.");
    end;

    local procedure InsertExpenseReportEntry(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportHeader: Record "Expense Report Header"
    ): BigInteger
    begin
        if ExpenseActivityLogEntry."Event Type" in [
            ExpenseActivityLogEntry."Event Type"::Submitted,
            ExpenseActivityLogEntry."Event Type"::Resubmitted,
            ExpenseActivityLogEntry."Event Type"::Posted]
        then begin
            SetAmountSnapshot(ExpenseActivityLogEntry, ExpenseReportHeader);
            SetContentsSnapshot(ExpenseActivityLogEntry, ExpenseReportHeader."No.");
        end;

        ExpenseActivityLogEntry.Insert();
        exit(ExpenseActivityLogEntry."Entry No.");
    end;

    local procedure SetExpenseUserActor(var ExpenseActivityLogEntry: Record "Expense Activity Log Entry"; ActorExpenseUserNo: Code[20])
    var
        ExpenseUser: Record "Expense User";
    begin
        if ActorExpenseUserNo = '' then
            exit;

        ExpenseUser.SetLoadFields(SystemId, Name);
        if ExpenseUser.Get(ActorExpenseUserNo) then begin
            ExpenseActivityLogEntry."Actor Table ID" := Database::"Expense User";
            ExpenseActivityLogEntry."Actor Record System ID" := ExpenseUser.SystemId;
            ExpenseActivityLogEntry."Actor Display Name" := ExpenseUser.Name;
        end;
    end;

    local procedure SetExpenseUserActorBySystemID(var ExpenseActivityLogEntry: Record "Expense Activity Log Entry"; ActorExpenseUserSystemID: Guid)
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseActivityLogEntry."Actor Table ID" := Database::"Expense User";
        ExpenseActivityLogEntry."Actor Record System ID" := ActorExpenseUserSystemID;

        ExpenseUser.SetLoadFields(Name);
        if ExpenseUser.GetBySystemId(ActorExpenseUserSystemID) then
            ExpenseActivityLogEntry."Actor Display Name" := ExpenseUser.Name;
    end;

    local procedure SetBCUserActor(var ExpenseActivityLogEntry: Record "Expense Activity Log Entry"; ActorUserSecurityID: Guid)
    var
        User: Record User;
    begin
        if IsNullGuid(ActorUserSecurityID) then
            exit;

        User.SetLoadFields(SystemId, "Full Name", "User Name");
        if not User.Get(ActorUserSecurityID) then
            exit;

        ExpenseActivityLogEntry."Actor Table ID" := Database::User;
        ExpenseActivityLogEntry."Actor Record System ID" := User.SystemId;
        if User."Full Name" <> '' then
            ExpenseActivityLogEntry."Actor Display Name" :=
                CopyStr(User."Full Name", 1, MaxStrLen(ExpenseActivityLogEntry."Actor Display Name"))
        else
            ExpenseActivityLogEntry."Actor Display Name" :=
                CopyStr(User."User Name", 1, MaxStrLen(ExpenseActivityLogEntry."Actor Display Name"));
    end;

    local procedure SetExpenseAgentActor(var ExpenseActivityLogEntry: Record "Expense Activity Log Entry")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAgentNameTxt: Label 'Expense Agent';
    begin
        ExpenseAgentSetup.GetRecordOnce();
        SetBCUserActor(ExpenseActivityLogEntry, ExpenseAgentSetup."User Security ID");
        // Without a configured agent user, the entry is still shown as performed by the Expense Agent.
        if ExpenseActivityLogEntry."Actor Display Name" = '' then
            ExpenseActivityLogEntry."Actor Display Name" := ExpenseAgentNameTxt;
    end;

    local procedure SetAmountSnapshot(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportHeader: Record "Expense Report Header"
    )
    begin
        ExpenseReportHeader.CalcFields(
            "Amount (LCY)", "Non-Refundable Amount (LCY)",
            "Reimbursable Amount", "Reimbursable Amount (LCY)",
            "Refundable Amount", "Refundable Amount (LCY)");
        ExpenseActivityLogEntry."Amount (LCY)" := ExpenseReportHeader."Amount (LCY)";
        ExpenseActivityLogEntry."Non-Refundable Amount (LCY)" := ExpenseReportHeader."Non-Refundable Amount (LCY)";
        ExpenseActivityLogEntry."Reimbursable Amount" := ExpenseReportHeader."Reimbursable Amount";
        ExpenseActivityLogEntry."Reimbursable Amount (LCY)" := ExpenseReportHeader."Reimbursable Amount (LCY)";
        ExpenseActivityLogEntry."Refundable Amount" := ExpenseReportHeader."Refundable Amount";
        ExpenseActivityLogEntry."Refundable Amount (LCY)" := ExpenseReportHeader."Refundable Amount (LCY)";
        ExpenseActivityLogEntry."Reimbursement Currency Code" := ExpenseReportHeader."Reimbursement Currency Code";
        ExpenseActivityLogEntry."Reimbursement Currency Factor" := ExpenseReportHeader."Reimbursement Currency Factor";
    end;

    local procedure SetContentsSnapshot(
        var ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        ExpenseReportNo: Code[20]
    )
    var
        ExpenseReportLine: Record "Expense Report Line";
        Categories: JsonArray;
        CategoryCodes: List of [Code[20]];
        CategoriesText: Text;
        CategoriesTruncated: Boolean;
    begin
        ExpenseReportLine.SetLoadFields("Expense Category", "Receipt Attached");
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        if ExpenseReportLine.FindSet() then
            repeat
                ExpenseActivityLogEntry."Expense Count" += 1;
                if ExpenseReportLine."Receipt Attached" then
                    ExpenseActivityLogEntry."Attached Receipt Count" += 1;

                // Add the category to the list if it is not already present and if it fits within the maximum length of the Categories field.
                if (not CategoriesTruncated) and
                   (ExpenseReportLine."Expense Category" <> '') and
                   (not CategoryCodes.Contains(ExpenseReportLine."Expense Category"))
                then begin
                    CategoryCodes.Add(ExpenseReportLine."Expense Category");
                    AddBoundedCategory(
                        Categories, ExpenseReportLine."Expense Category", MaxStrLen(ExpenseActivityLogEntry.Categories), CategoriesText, CategoriesTruncated);
                end;
            until ExpenseReportLine.Next() = 0;

        ExpenseActivityLogEntry.Categories :=
            CopyStr(CategoriesText, 1, MaxStrLen(ExpenseActivityLogEntry.Categories));
    end;

    local procedure AddBoundedCategory(var Categories: JsonArray; CategoryValueText: Text; MaxLength: Integer; var CategoriesText: Text; var CategoriesTruncated: Boolean)
    begin
        if CategoriesTruncated then
            exit;

        Categories.Add(CategoryValueText);
        Categories.WriteTo(CategoriesText);
        if StrLen(CategoriesText) <= MaxLength then
            exit;

        Categories.RemoveAt(Categories.Count() - 1);
        Categories.Add('...');
        Categories.WriteTo(CategoriesText);
        while StrLen(CategoriesText) > MaxLength do begin
            Categories.RemoveAt(Categories.Count() - 2);
            Categories.WriteTo(CategoriesText);
        end;
        CategoriesTruncated := true;
    end;
}
