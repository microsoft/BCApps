// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50153 "Filename Proof Reminders"
{
    // Proves the Source Table Filter, which is the mechanism that removes special cases from
    // the design: "a level 3 reminder is named differently from every other reminder" is a row
    // in a setup table rather than a branch in code. The condition is stored as a view and
    // applied to the document in filter group 10, so it narrows the document rather than
    // replacing the filter that identified it.
    //
    // Three things have to hold, and each gets its own pass line:
    //   the filtered pattern wins for a document that meets its condition;
    //   the unfiltered pattern wins for a document that does not;
    //   the filtered pattern is never selected outside its condition - shown by removing the
    //   unfiltered pattern and confirming the name is not resolved at all, rather than the
    //   filtered one quietly applying.
    //
    // The two reminders are the proof's own, at levels 1 and 3 of reminder terms of their own, for
    // a customer of their own. Those terms carry no attachment texts, so Base Application names
    // neither reminder from one - a reminder it names is left to it on every route (Report
    // Filename Mgt.IsNamedByReminderCommunication) - and the patterns decide. A company's own
    // terms may carry them, and with a File Name the proof would measure that rule instead of the
    // condition.

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

        // The level 1 reminder is constructed (Filename Test Data), for a customer and on reminder
        // terms with levels 1 to 3 of the proof's own; the level 3 reminder is issued for real for
        // the same customer and terms where it can be, and constructed where it cannot.
        TestData.CreateIssuedReminder(TestData.CreateCustomer(), TestData.CreateReminderTerms(3), 1, '', Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder', Level1Reminder."No.");

        ProduceLevel3Reminder(Level1Reminder, Level3Reminder);
        ProofSupport.LogLine('10 Level 3 reminder', Level3Reminder."No.");

        ClearPatterns();
        CreateUnfilteredPattern();
        CreateLevel3Pattern();

        // The filtered pattern has to win here: its condition holds, and a condition on the
        // document is the most specific thing a pattern can say.
        NameForLevel3 := NameReminder(Level3Reminder);
        ProofSupport.LogLine('10 Level 3 reminder named', NameForLevel3);
        if NameForLevel3 = ExpectedLevel3Name(Level3Reminder) then
            ProofSupport.LogLine('RESULT filtered pattern wins for a level 3 reminder', PassMsg)
        else
            ProofSupport.LogLine('RESULT filtered pattern wins for a level 3 reminder', StrSubstNo(ExpectedButGotMsg, ExpectedLevel3Name(Level3Reminder), NameForLevel3));

        // And it has to lose here, to the row that says nothing about the level.
        NameForLevel1 := NameReminder(Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder named', NameForLevel1);
        if NameForLevel1 = ExpectedPlainName(Level1Reminder) then
            ProofSupport.LogLine('RESULT unfiltered pattern wins for a level 1 reminder', PassMsg)
        else
            ProofSupport.LogLine('RESULT unfiltered pattern wins for a level 1 reminder', StrSubstNo(ExpectedButGotMsg, ExpectedPlainName(Level1Reminder), NameForLevel1));

        // With nothing left to fall back to, a level 1 reminder must come out unnamed. If the
        // filtered pattern were being selected regardless of its condition, this would produce
        // its name instead - which is the failure the first two checks cannot distinguish.
        DeleteUnfilteredPattern();
        NameWithoutFallback := NameReminder(Level1Reminder);
        ProofSupport.LogLine('10 Level 1 reminder with only the filtered pattern left', NameWithoutFallback);
        if NameWithoutFallback = DidNotResolveMsg then
            ProofSupport.LogLine('RESULT filtered pattern is never selected outside its condition', PassMsg)
        else
            ProofSupport.LogLine('RESULT filtered pattern is never selected outside its condition', StrSubstNo(ShouldNotHaveResolvedMsg, NameWithoutFallback));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Names a reminder the way the Download route presents it: the platform's data item
    /// filter plus a positioned record.
    /// </summary>
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
        // Said explicitly. A pattern is created as a draft now - Enabled starts off, so an
        // administrator cannot leave an incomplete row switched on - which means code that
        // intends a pattern to be live has to say so, or it would be inert and match nothing.
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ProofSupport.LogLine('10 Unfiltered pattern', PlainPatternTok);
    end;

    /// <summary>
    /// The same table, the same everything, differing only by the condition - which is the
    /// point being proven. The condition is built by filtering a record and taking its view,
    /// so no field number is written down anywhere.
    /// </summary>
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

    /// <summary>
    /// Produces a level 3 issued reminder. The real routine is tried first - an overdue invoice,
    /// and reminders made by Reminder-Make and issued by Reminder-Issue up to level 3, exactly as a
    /// company issues them (Filename Proof Issue Rmdr) - because a document that went through the
    /// real path cannot be accused of having been shaped to suit the test. If it will not run here
    /// the document is constructed instead. Which of the two happened is written to the log,
    /// because it changes what the proof is worth; so is Base Application's error when it fails.
    ///
    /// The real route is a separate codeunit run through Codeunit.Run: it writes, so it cannot be
    /// a TryFunction, and Codeunit.Run gives the same isolation - a failure rolls back what that
    /// codeunit did. The level 3 reminder is found by the number the run hands back.
    /// </summary>
    /// <param name="Level1Reminder">The proof's level 1 reminder, whose customer and terms are used.</param>
    /// <param name="Level3Reminder">Receives the level 3 reminder.</param>
    local procedure ProduceLevel3Reminder(var Level1Reminder: Record "Issued Reminder Header"; var Level3Reminder: Record "Issued Reminder Header")
    var
        Model: Record "Issued Reminder Header";
        FilenameProofIssueRmdr: Codeunit "Filename Proof Issue Rmdr";
        TestData: Codeunit "Filename Test Data";
    begin
        // The proof's data so far and the log are committed, so the isolated run below cannot
        // take anything else down with it.
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
