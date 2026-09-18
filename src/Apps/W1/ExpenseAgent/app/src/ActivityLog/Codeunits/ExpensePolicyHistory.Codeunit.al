// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.Encryption;

codeunit 6927 "Expense Policy History"
{
    Access = Internal;
    Permissions = tabledata "Expense Activity Log Entry" = rim;

    internal procedure CaptureSubmission(ExpenseReportHeader: Record "Expense Report Header"; var SubmissionEntry: Record "Expense Activity Log Entry")
    begin
        ExpenseReportHeader.ReadIsolation := IsolationLevel::UpdLock;
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        if not IsEnabled() then
            exit;

        SubmissionEntry."Policy Context Hash" := ContextHash(ExpenseReportHeader);
        SubmissionEntry.Modify(false);
        Capture(ExpenseReportHeader, SubmissionEntry, false);
    end;

    internal procedure Complete(var ExpenseReportHeader: Record "Expense Report Header"; SubmissionActivityID: Guid)
    var
        SubmissionEntry: Record "Expense Activity Log Entry";
        LaterEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseReportHeader.ReadIsolation := IsolationLevel::UpdLock;
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        if not IsEnabled() then
            exit;

        SubmissionEntry.LockTable();
        if not SubmissionEntry.GetBySystemId(SubmissionActivityID) then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);
        if (SubmissionEntry."Subject System ID" <> ExpenseReportHeader.SystemId) or
           (SubmissionEntry."Subject Table ID" <> Database::"Expense Report Header") or
           (SubmissionEntry."Source Table ID" <> Database::"Expense Report Header") or
           (SubmissionEntry."Source Record System ID" <> ExpenseReportHeader.SystemId) or
           not (SubmissionEntry."Event Type" in [SubmissionEntry."Event Type"::Submitted, SubmissionEntry."Event Type"::Resubmitted])
        then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);

        LaterEntry.SetRange("Subject Table ID", Database::"Expense Report Header");
        LaterEntry.SetRange("Subject System ID", ExpenseReportHeader.SystemId);
        LaterEntry.SetFilter("Entry No.", '>%1', SubmissionEntry."Entry No.");
        LaterEntry.SetFilter("Event Type", '%1|%2|%3|%4',
            LaterEntry."Event Type"::Submitted, LaterEntry."Event Type"::Resubmitted,
            LaterEntry."Event Type"::Recalled, LaterEntry."Event Type"::ReopenedByApprover);
        if not LaterEntry.IsEmpty() then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);
        if ExpenseReportHeader.Status in [ExpenseReportHeader.Status::Open, ExpenseReportHeader.Status::Released] then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);

        Capture(ExpenseReportHeader, SubmissionEntry, true);
    end;

    local procedure Capture(ExpenseReportHeader: Record "Expense Report Header"; SubmissionEntry: Record "Expense Activity Log Entry"; RequireComplete: Boolean)
    var
        Snapshot: Record "Expense Activity Log Entry";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
        EntryNo: BigInteger;
    begin
        Snapshot.LockTable();
        Snapshot.SetRange("Submission Activity ID", SubmissionEntry.SystemId);
        Snapshot.SetRange("Event Type", Snapshot."Event Type"::PolicyEvaluated);
        // A retry must never reinterpret an already captured verdict using changed live data.
        if not Snapshot.IsEmpty() then
            exit;
        Snapshot.Reset();
        if (SubmissionEntry."Policy Context Hash" = '') or
           (SubmissionEntry."Policy Context Hash" <> ContextHash(ExpenseReportHeader))
        then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);
        if not Aggregate(ExpenseReportHeader, Snapshot) then begin
            if RequireComplete then
                Error(IncompleteErr + IncompleteCodeTok);
            exit;
        end;
        // Stabilize observed rows and reject membership changes during aggregation.
        // The snapshot describes the validation interval, not future live policy state.
        if SubmissionEntry."Policy Context Hash" <> ContextHash(ExpenseReportHeader) then
            Error(ObsoleteSubmissionErr + ConflictCodeTok);

        EntryNo := ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader, Enum::"Expense Activity Event Type"::PolicyEvaluated,
            Enum::"Expense Activity Initiator"::Agent, Enum::"Expense Activity Actor Role"::" ", '',
            StrSubstNo(SummaryLbl, Format(Snapshot."Policy Status"), Snapshot."Failed Policy Count", Snapshot."Passed Policy Count"));
        SetSnapshot(EntryNo, SubmissionEntry.SystemId, Snapshot);
    end;

    local procedure SetSnapshot(EntryNo: BigInteger; SubmissionActivityID: Guid; Snapshot: Record "Expense Activity Log Entry")
    var
        Entry: Record "Expense Activity Log Entry";
    begin
        Entry.Get(EntryNo);
        Entry."Policy Snapshot Present" := true;
        Entry."Submission Activity ID" := SubmissionActivityID;
        Entry."Policy Status" := Snapshot."Policy Status";
        Entry."Failed Policy Count" := Snapshot."Failed Policy Count";
        Entry."Passed Policy Count" := Snapshot."Passed Policy Count";
        Entry."Flagged Categories" := Snapshot."Flagged Categories";
        Entry."Flagged Category Count" := Snapshot."Flagged Category Count";
        Entry."Latest Policies Evaluated At" := Snapshot."Latest Policies Evaluated At";
        Entry.Modify(false);
    end;

    local procedure Aggregate(ExpenseReportHeader: Record "Expense Report Header"; var Snapshot: Record "Expense Activity Log Entry"): Boolean
    var
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        Evaluation: Record "Expense Policy Evaluation";
        CategoryCodes: List of [Code[20]];
        Categories: JsonArray;
        CategoriesText: Text;
    begin
        Line.ReadIsolation := IsolationLevel::RepeatableRead;
        Policy.ReadIsolation := IsolationLevel::RepeatableRead;
        Evaluation.ReadIsolation := IsolationLevel::RepeatableRead;
        Line.SetRange("Document No.", ExpenseReportHeader."No.");
        if Line.FindSet() then
            repeat
                Policy.SetApplicableToLineFilter(Line);
                if Policy.FindSet() then begin
                    if (Line."Policies Evaluated At" = 0DT) or (Line."Evaluated Policy Version" <> Line."Policy Eval Version") then
                        exit(false);
                    repeat
                        if not Evaluation.Get(Policy."Subject Type", Line.SystemId, Policy.SystemId, Line."Policy Eval Version", Policy.Version) then
                            exit(false);
                        if (Evaluation."Evaluated At" = 0DT) or (Evaluation."Evaluated At" > Line."Policies Evaluated At") then
                            exit(false);
                        if Evaluation."Evaluated At" > Snapshot."Latest Policies Evaluated At" then
                            Snapshot."Latest Policies Evaluated At" := Evaluation."Evaluated At";
                        if Evaluation.Compliant then
                            Snapshot."Passed Policy Count" += 1
                        else begin
                            Snapshot."Failed Policy Count" += 1;
                            if (Line."Expense Category" <> '') and not CategoryCodes.Contains(Line."Expense Category") then begin
                                CategoryCodes.Add(Line."Expense Category");
                                Categories.Add(Line."Expense Category");
                                Categories.WriteTo(CategoriesText);
                                if StrLen(CategoriesText) > MaxStrLen(Snapshot."Flagged Categories") then
                                    Categories.RemoveAt(Categories.Count() - 1);
                            end;
                        end;
                    until Policy.Next() = 0;
                end else
                    if (Line."Policies Evaluated At" <> 0DT) and (Line."Evaluated Policy Version" <> Line."Policy Eval Version") then
                        exit(false);
            until Line.Next() = 0;

        Snapshot."Flagged Category Count" := CategoryCodes.Count();
        Categories.WriteTo(CategoriesText);
        Snapshot."Flagged Categories" := CopyStr(CategoriesText, 1, MaxStrLen(Snapshot."Flagged Categories"));
        Snapshot."Policy Status" := Snapshot."Policy Status"::"No Policies";
        if Snapshot."Passed Policy Count" > 0 then
            Snapshot."Policy Status" := Snapshot."Policy Status"::Cleared;
        if Snapshot."Failed Policy Count" > 0 then
            Snapshot."Policy Status" := Snapshot."Policy Status"::Flagged;
        exit(true);
    end;

    local procedure ContextHash(ExpenseReportHeader: Record "Expense Report Header"): Text[100]
    var
        Line: Record "Expense Report Line";
        Policy: Record "Expense Policy";
        CryptographyManagement: Codeunit "Cryptography Management";
        Context: TextBuilder;
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        Line.ReadIsolation := IsolationLevel::RepeatableRead;
        Policy.ReadIsolation := IsolationLevel::RepeatableRead;
        Context.AppendLine(ExpenseReportHeader."No.");
        Context.AppendLine(ExpenseReportHeader.Description);
        Context.AppendLine(ExpenseReportHeader."Expense User No.");
        Context.AppendLine(ExpenseReportHeader."Expense User Name");
        Line.SetRange("Document No.", ExpenseReportHeader."No.");
        if Line.FindSet() then
            repeat
                Context.AppendLine(StrSubstNo('%1:%2:%3',
                    Format(Line.SystemId, 0, 9), Format(Line."Policy Eval Version", 0, 9), Line."Expense Category"));
                Policy.SetApplicableToLineFilter(Line);
                if Policy.FindSet() then
                    repeat
                        Context.AppendLine(StrSubstNo('%1:%2', Format(Policy.SystemId, 0, 9), Format(Policy.Version, 0, 9)));
                    until Policy.Next() = 0;
            until Line.Next() = 0;
        exit(CopyStr(CryptographyManagement.GenerateHash(Context.ToText(), HashAlgorithm::SHA256), 1, 100));
    end;

    local procedure IsEnabled(): Boolean
    var
        Setup: Record "Expense Agent Setup";
    begin
        Setup.ReadIsolation := IsolationLevel::RepeatableRead;
        if not Setup.Get() then
            exit(false);
        exit(Setup."Evaluate Policies");
    end;

    local procedure InvalidateChangedReportContext(ExpenseReportHeader: Record "Expense Report Header")
    var
        StoredHeader: Record "Expense Report Header";
        Line: Record "Expense Report Line";
    begin
        if ExpenseReportHeader.IsTemporary() then
            exit;
        // Read the stored image: xRec can already contain the new values. Include the
        // submitter name and report-number fallback used by the evaluator, not workflow fields.
        StoredHeader.ReadIsolation := IsolationLevel::UpdLock;
        if not StoredHeader.GetBySystemId(ExpenseReportHeader.SystemId) then
            exit;
        if (StoredHeader."No." = ExpenseReportHeader."No.") and
           (StoredHeader.Description = ExpenseReportHeader.Description) and
           (StoredHeader."Expense User No." = ExpenseReportHeader."Expense User No.") and
           (StoredHeader."Expense User Name" = ExpenseReportHeader."Expense User Name")
        then
            exit;

        Line.SetRange("Document No.", StoredHeader."No.");
        if Line.FindSet(true) then
            repeat
                Line.InvalidatePolicyEvaluation();
            until Line.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Report Header", OnBeforeModifyEvent, '', false, false)]
    local procedure BeforeHeaderModify(var Rec: Record "Expense Report Header"; var xRec: Record "Expense Report Header"; RunTrigger: Boolean)
    begin
        InvalidateChangedReportContext(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Report Header", OnBeforeRenameEvent, '', false, false)]
    local procedure BeforeHeaderRename(var Rec: Record "Expense Report Header"; var xRec: Record "Expense Report Header"; RunTrigger: Boolean)
    begin
        InvalidateChangedReportContext(Rec);
    end;

    var
        ObsoleteSubmissionErr: Label 'The submission or its policy evaluation context is obsolete.';
        ConflictCodeTok: Label ' [PolicyHistoryConflict]', Locked = true;
        IncompleteErr: Label 'Policy evaluation is incomplete for this submission.';
        IncompleteCodeTok: Label ' [PolicyHistoryIncomplete]', Locked = true;
        SummaryLbl: Label '%1. Failed policy checks: %2. Passed policy checks: %3.', Comment = '%1 = policy status, %2 = failed line-policy pairs, %3 = passed line-policy pairs';
}
