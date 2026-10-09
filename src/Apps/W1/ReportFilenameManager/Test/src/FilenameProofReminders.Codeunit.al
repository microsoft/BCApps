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

    trigger OnRun()
    begin
        ProveSourceTableFilter();
    end;

    procedure ProveSourceTableFilter()
    var
        Level3Reminder: Record "Issued Reminder Header";
        Level1Reminder: Record "Issued Reminder Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        NameForLevel3: Text;
        NameForLevel1: Text;
        NameWithoutFallback: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        // A company that has never issued a reminder has nothing for this proof to build on.
        // Isolated, so a company where even the stand-in cannot be made still reports the reason
        // below rather than taking the whole run down.
        if not Codeunit.Run(Codeunit::"Filename Proof Seed Rmdr") then
            ProofSupport.LogLine('10 Level 1 reminder could not be seeded', GetLastErrorText());

        if not FindReminderAtLevel(1, Level1Reminder) then begin
            ProofSupport.LogLine('Setup', NoLevel1Msg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        ProofSupport.LogLine('10 Level 1 reminder', Level1Reminder."No.");

        if not EnsureLevel3Reminder(Level1Reminder, Level3Reminder) then begin
            ProofSupport.LogLine('Setup', NoLevel3Msg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
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

        // The fabricated document goes away again. Left in place it is found first next time,
        // the real Reminder-Issue route is never attempted again, and a regression there would
        // go unnoticed for good.
        RemoveFabricatedReminder();

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

    local procedure ExpectedLevel3Name(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(Level3PrefixTok + IssuedReminderHeader."No.");
    end;

    local procedure ExpectedPlainName(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(PlainPrefixTok + IssuedReminderHeader."No.");
    end;

    /// <summary>
    /// Deletes the level 3 document this proof constructed, recognisable by the suffix it was
    /// given. A reminder that was genuinely issued does not carry it and is left alone.
    /// </summary>
    local procedure RemoveFabricatedReminder()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.SetFilter("No.", '*' + Level3SuffixTok);
        IssuedReminderHeader.SetRange("Reminder Level", 3);
        IssuedReminderHeader.DeleteAll(false);
    end;

    local procedure FindReminderAtLevel(Level: Integer; var IssuedReminderHeader: Record "Issued Reminder Header"): Boolean
    begin
        IssuedReminderHeader.Reset();
        IssuedReminderHeader.SetRange("Reminder Level", Level);
        exit(IssuedReminderHeader.FindFirst());
    end;

    /// <summary>
    /// Produces a level 3 issued reminder. The real routine is tried first - a reminder built
    /// and put through Reminder-Issue, exactly as a user would - because a document that went
    /// through the real path cannot be accused of having been shaped to suit the test. Issuing
    /// posts fees to the general ledger and depends on a good deal of company setup, so if it
    /// will not run here the document is constructed from the level 1 reminder instead. Which
    /// of the two happened is written to the log, because it changes what the proof is worth.
    ///
    /// Both routes are separate codeunits run through Codeunit.Run: they write, so they cannot
    /// be TryFunctions, and Codeunit.Run gives the same isolation - a failure rolls back only
    /// what that codeunit did.
    /// </summary>
    /// <param name="Level1Reminder">An existing reminder, used as the model.</param>
    /// <param name="Level3Reminder">Receives the level 3 reminder.</param>
    /// <returns>True when a level 3 reminder is available.</returns>
    local procedure EnsureLevel3Reminder(var Level1Reminder: Record "Issued Reminder Header"; var Level3Reminder: Record "Issued Reminder Header"): Boolean
    var
        Model: Record "Issued Reminder Header";
    begin
        if FindReminderAtLevel(3, Level3Reminder) then begin
            ProofSupport.LogLine('10 Level 3 reminder source', AlreadyPresentMsg);
            exit(true);
        end;

        // Nothing of this proof's own is written yet, and the log so far is committed, so the
        // isolated runs below cannot take anything else down with them.
        Commit();

        Model := Level1Reminder;
        if Codeunit.Run(Codeunit::"Filename Proof Issue Rmdr", Model) then
            if FindReminderAtLevel(3, Level3Reminder) then begin
                ProofSupport.LogLine('10 Level 3 reminder source', IssuedForRealMsg);
                exit(true);
            end;

        if GetLastErrorText() <> '' then
            ProofSupport.LogLine('10 Reminder-Issue did not run here', GetLastErrorText())
        else
            ProofSupport.LogLine('10 Reminder-Issue ran but produced no level 3 document', IssuedNoLevel3Msg);

        Model := Level1Reminder;
        if not Codeunit.Run(Codeunit::"Filename Proof Build Rmdr", Model) then begin
            ProofSupport.LogLine('10 Level 3 reminder source', StrSubstNo(CouldNotBuildMsg, GetLastErrorText()));
            exit(false);
        end;

        ProofSupport.LogLine('10 Level 3 reminder source', ConstructedMsg);
        exit(FindReminderAtLevel(3, Level3Reminder));
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        Level3SuffixTok: Label '-L3', Locked = true;
        PlainPatternTok: Label 'Reminder-[No.]', Locked = true;
        PlainPrefixTok: Label 'Reminder-', Locked = true;
        Level3PatternTok: Label 'Reminder-L3-[No.]', Locked = true;
        Level3PrefixTok: Label 'Reminder-L3-', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        ShouldNotHaveResolvedMsg: Label 'FAIL - the filtered pattern named a document that does not meet its condition: %1', Comment = '%1 the name it produced';
        NoLevel1Msg: Label 'This company has no issued reminder to compare against.';
        NoLevel3Msg: Label 'No level 3 reminder could be produced, so the condition cannot be proven here.';
        AlreadyPresentMsg: Label 'One was already in the company.';
        IssuedForRealMsg: Label 'Built as a reminder and put through Reminder-Issue, the way a user would.';
        ConstructedMsg: Label 'Constructed from the level 1 reminder, because Reminder-Issue would not run in this company.';
        IssuedNoLevel3Msg: Label 'The issue routine completed without leaving a level 3 issued reminder behind.';
        CouldNotBuildMsg: Label 'Neither issuing nor constructing one worked: %1', Comment = '%1 the error';
}
