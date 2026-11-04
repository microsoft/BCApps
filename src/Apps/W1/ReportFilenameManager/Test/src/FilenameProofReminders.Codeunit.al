// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.Reminder;

codeunit 149503 "Filename Proof Reminders"
{
    // Proves the Table Filter (applied in filter group 10, so it narrows the document's own
    // filter): a level 3 pattern wins for a level 3 reminder, loses for level 1, and is never
    // selected outside its condition. The reminder terms are the proof's own, with no attachment
    // texts: a reminder Base Application names from one is left to it on every route.

    trigger OnRun()
    begin
        ProveSourceTableFilter();
    end;

    procedure ProveSourceTableFilter()
    var
        Level3Reminder: Record "Issued Reminder Header";
        Level1Reminder: Record "Issued Reminder Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        TestData: Codeunit "Filename Test Data";
        NameForLevel3: Text;
        NameForLevel1: Text;
        NameWithoutFallback: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        TestData.CreateIssuedReminder(TestData.CreateCustomer(), TestData.CreateReminderTerms(3), 1, '', Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder', Level1Reminder."No.");

        ProduceLevel3Reminder(Level1Reminder, Level3Reminder);
        ProofSupport.LogLine('10 Level 3 reminder', Level3Reminder."No.");

        ClearPatterns();
        CreateUnfilteredPattern();
        CreateLevel3Pattern();

        NameForLevel3 := NameReminder(Level3Reminder);
        ProofSupport.LogLine('10 Level 3 reminder named', NameForLevel3);
        if NameForLevel3 = ExpectedLevel3Name(Level3Reminder) then
            ProofSupport.LogLine('RESULT filtered pattern wins for a level 3 reminder', PassMsg)
        else
            ProofSupport.LogLine('RESULT filtered pattern wins for a level 3 reminder', StrSubstNo(ExpectedButGotMsg, ExpectedLevel3Name(Level3Reminder), NameForLevel3));

        NameForLevel1 := NameReminder(Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder named', NameForLevel1);
        if NameForLevel1 = ExpectedPlainName(Level1Reminder) then
            ProofSupport.LogLine('RESULT unfiltered pattern wins for a level 1 reminder', PassMsg)
        else
            ProofSupport.LogLine('RESULT unfiltered pattern wins for a level 1 reminder', StrSubstNo(ExpectedButGotMsg, ExpectedPlainName(Level1Reminder), NameForLevel1));

        // With no fallback, level 1 must come out unnamed; the first two checks cannot tell a
        // filtered pattern selected regardless of its condition.
        DeleteUnfilteredPattern();
        NameWithoutFallback := NameReminder(Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder with only the filtered pattern left', NameWithoutFallback);
        if NameWithoutFallback = DidNotResolveMsg then
            ProofSupport.LogLine('RESULT filtered pattern is never selected outside its condition', PassMsg)
        else
            ProofSupport.LogLine('RESULT filtered pattern is never selected outside its condition', StrSubstNo(ShouldNotHaveResolvedMsg, NameWithoutFallback));

        FilenameProofLogMgt.Flush();
    end;

    // Both inputs OnGetFilename gives the manager: the record and the filterviews payload.
    local procedure NameReminder(var IssuedReminderHeader: Record "Issued Reminder Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        IssuedReminderHeader.SetRecFilter();
        SourceRecRef.GetTable(IssuedReminderHeader);

        if not ReportFilenameMgt.TryResolve(Report::Reminder, Channel::Download,
             SourceRecRef, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;


    local procedure CreateUnfilteredPattern()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("File Name Pattern", PlainPatternTok);
        // A pattern is created as a draft.
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ProofSupport.LogLine('10 Unfiltered pattern', PlainPatternTok);
    end;

    // Differs from the plain pattern only by the condition, built from a filtered record's view.
    local procedure CreateLevel3Pattern()
    var
        Pattern: Record "Report Filename Pattern";
        ConditionSource: Record "Issued Reminder Header";
    begin
        ConditionSource.SetRange("Reminder Level", 3);

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("File Name Pattern", Level3PatternTok);
        Pattern.WriteTableFilter(ConditionSource.GetView(false));
        Pattern.Enabled := true;
        Pattern.Insert(true);

        ProofSupport.LogLine('10 Filtered pattern', Level3PatternTok);
        ProofSupport.LogLine('10 Its condition, read back', Pattern.GetTableFilterDisplayText());
    end;

    local procedure DeleteUnfilteredPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        Pattern.SetRange("File Name Pattern", PlainPatternTok);
        Pattern.DeleteAll(false);
    end;

    local procedure ClearPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
    end;

    // Issued for real (Filename Proof Issue Rmdr) where it can be, constructed where it cannot;
    // the log says which, as it changes what the proof is worth.
    local procedure ProduceLevel3Reminder(var Level1Reminder: Record "Issued Reminder Header"; var Level3Reminder: Record "Issued Reminder Header")
    var
        Model: Record "Issued Reminder Header";
        FilenameProofIssueRmdr: Codeunit "Filename Proof Issue Rmdr";
        TestData: Codeunit "Filename Test Data";
    begin
        // Codeunit.Run with its result used must not start inside a write transaction.
        Commit();

        Model := Level1Reminder;
        if FilenameProofIssueRmdr.Run(Model) then
            if Level3Reminder.Get(FilenameProofIssueRmdr.IssuedReminderNo()) then begin
                Level3Reminder.SetRecFilter();
                ProofSupport.LogLine('10 Level 3 reminder source', IssuedForRealMsg);
                exit;
            end;

        if GetLastErrorText() <> '' then
            ProofSupport.LogLine('10 Reminder-Issue did not run here', GetLastErrorText())
        else
            ProofSupport.LogLine('10 Reminder-Issue ran but produced no level 3 document', IssuedNoLevel3Msg);

        TestData.CreateIssuedReminder(Level1Reminder."Customer No.", Level1Reminder."Reminder Terms Code", 3, '', Level3Reminder);
        ProofSupport.LogLine('10 Level 3 reminder source', ConstructedMsg);
    end;

    local procedure ExpectedLevel3Name(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(Level3PrefixTok + IssuedReminderHeader."No.");
    end;

    local procedure ExpectedPlainName(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(PlainPrefixTok + IssuedReminderHeader."No.");
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        PlainPatternTok: Label 'Reminder-[No.]', Locked = true;
        PlainPrefixTok: Label 'Reminder-', Locked = true;
        Level3PatternTok: Label 'Reminder-L3-[No.]', Locked = true;
        Level3PrefixTok: Label 'Reminder-L3-', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        ShouldNotHaveResolvedMsg: Label 'FAIL - the filtered pattern named a document that does not meet its condition: %1', Comment = '%1 the name it produced';
        IssuedForRealMsg: Label 'Issued for real: an overdue invoice, and reminders made by Reminder-Make and issued by Reminder-Issue up to level 3, the way a company issues them.';
        IssuedNoLevel3Msg: Label 'The issue routine completed without handing back a level 3 issued reminder.';
        ConstructedMsg: Label 'Constructed by the proof (Filename Test Data), because Reminder-Issue would not run here.';
}
