// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

codeunit 6926 "Expense Activity Log Mgt."
{
    Access = Internal;
    Permissions = tabledata "Expense Activity Log Entry" = rimd,
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
        if ExpenseActivityLogEntry.FindSet(true) then
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

    internal procedure LogPolicyEvaluationIfReady(ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SubmissionEntry: Record "Expense Activity Log Entry";
        Snapshot: Record "Expense Activity Log Entry";
        FlaggedCategoryNames: List of [Text];
        CategoryName: Text;
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
        if not SubmissionEntry.FindLast() then
            exit;

        Snapshot.CopyFilters(SubmissionEntry);
        Snapshot.SetRange("Event Type", Snapshot."Event Type"::PolicyEvaluated);
        Snapshot.SetFilter("Entry No.", '>%1', SubmissionEntry."Entry No.");
        // Log at most one PolicyEvaluated entry after the latest Submitted/Resubmitted entry.
        // Repeated line confirmations leave that snapshot unchanged; a resubmission permits a new one.
        // Example: Submitted 100, PolicyEvaluated 101 => skip; Resubmitted 105 => 101 no longer matches.
        if not Snapshot.IsEmpty() then
            exit;
        Snapshot.Reset();

        InitializeExpenseReportEntry(
            Snapshot, ExpenseReportHeader, Enum::"Expense Activity Event Type"::PolicyEvaluated,
            Enum::"Expense Activity Initiator"::Agent, Enum::"Expense Activity Actor Role"::" ", '', 0DT);
        // Wait for complete, current results across all lines; a later confirmation retries.
        if not ExpenseReportHeader.IsPolicyEvaluationComplete(
            Snapshot."Policy Status", Snapshot."Failed Policy Count", Snapshot."Passed Policy Count", FlaggedCategoryNames)
        then
            exit;

        foreach CategoryName in FlaggedCategoryNames do
            AddBoundedCategory(Categories, CategoryName, MaxStrLen(Snapshot."Flagged Categories"), CategoriesText, CategoriesTruncated);
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
        if StrLen(EventComment) > MaxStrLen(ExpenseActivityLogEntry.Comment) then
            ExpenseActivityLogEntry.Comment :=
                CopyStr(EventComment, 1, MaxStrLen(ExpenseActivityLogEntry.Comment) - 3) + '...'
        else
            ExpenseActivityLogEntry.Comment := CopyStr(EventComment, 1, MaxStrLen(ExpenseActivityLogEntry.Comment));
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

    local procedure AddBoundedCategory(var Categories: JsonArray; CategoryName: Text; MaxLength: Integer; var CategoriesText: Text; var CategoriesTruncated: Boolean)
    begin
        if CategoriesTruncated then
            exit;

        Categories.Add(CategoryName);
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
