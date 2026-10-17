// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50164 "Filename Proof Gate"
{
    // Turns the proof log into something that can fail.
    //
    // Every proof writes its conclusion as a line beginning RESULT, and until now that was all
    // it did: a regression produced a green run and a log line nobody was obliged to read.
    // This reads the lines a run produced and errors if any of them is not a pass, so the run
    // itself carries the verdict - whether it was started by the test runner or by hand.

    Access = Internal;

    /// <summary>
    /// The last log entry before a run starts, so the verdicts of that run can be told apart
    /// from every earlier one in the same company.
    /// </summary>
    /// <returns>The entry number to check from.</returns>
    internal procedure Baseline(): Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        if FilenameProofLog.FindLast() then
            exit(FilenameProofLog."Entry No.");
        exit(0);
    end;

    /// <summary>
    /// Errors unless every verdict written since the baseline is a pass, naming the ones that
    /// are not.
    /// </summary>
    /// <param name="FromEntryNo">The entry number returned by Baseline before the run.</param>
    internal procedure AssertAllVerdictsPassed(FromEntryNo: Integer)
    var
        Failures: Text;
        Checked: Integer;
    begin
        Checked := CollectFailures(FromEntryNo, Failures);

        if Failures <> '' then
            Error(VerdictsFailedErr, Failures);

        // A run that produced no verdict at all is not a pass either: it means the proofs did
        // not reach their conclusions, which is the failure mode a green light hides best.
        if Checked = 0 then
            Error(NoVerdictsErr);
    end;

    /// <summary>
    /// Reads the verdicts a run wrote.
    /// </summary>
    /// <param name="FromEntryNo">The entry number to read after.</param>
    /// <param name="Failures">Receives one line per verdict that is not a pass.</param>
    /// <returns>How many verdicts were found.</returns>
    internal procedure CollectFailures(FromEntryNo: Integer; var Failures: Text) Checked: Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        Failures := '';

        FilenameProofLog.SetFilter("Entry No.", '>%1', FromEntryNo);
        FilenameProofLog.SetFilter(Item, VerdictFilterTok);
        if not FilenameProofLog.FindSet() then
            exit(0);

        repeat
            // A long verdict is written across several rows, and only the first carries the
            // conclusion; the continuations are the rest of the sentence.
            if StrPos(FilenameProofLog.Item, ContinuationTok) = 0 then begin
                Checked += 1;
                if not IsPass(FilenameProofLog.Value) then
                    Failures += StrSubstNo(FailureLineLbl, FilenameProofLog.Item, FilenameProofLog.Value);
            end;
        until FilenameProofLog.Next() = 0;
    end;

    /// <summary>
    /// Whether a verdict reads as a pass. The proofs write either PASS or, where the point is
    /// that several routes agree, IDENTICAL followed by the name they agreed on.
    /// </summary>
    local procedure IsPass(Verdict: Text): Boolean
    begin
        if CopyStr(Verdict, 1, StrLen(PassPrefixTok)) = PassPrefixTok then
            exit(true);
        exit(CopyStr(Verdict, 1, StrLen(IdenticalPrefixTok)) = IdenticalPrefixTok);
    end;

    var
        VerdictFilterTok: Label 'RESULT*', Locked = true;
        ContinuationTok: Label '(cont.', Locked = true;
        PassPrefixTok: Label 'PASS', Locked = true;
        IdenticalPrefixTok: Label 'IDENTICAL', Locked = true;
        FailureLineLbl: Label '%1: %2\', Comment = '%1 what was being proven, %2 what happened', Locked = true;
        VerdictsFailedErr: Label 'The filename proofs did not all pass:\%1', Comment = '%1 one line per failed verdict';
        NoVerdictsErr: Label 'The filename proofs produced no verdict at all, so nothing was proven.';
}
