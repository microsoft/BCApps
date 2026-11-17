// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

codeunit 149514 "Filename Proof Gate"
{
    // Makes a run fail when any RESULT line it wrote to the proof log is not a pass.

    Access = Internal;

    /// <summary>
    /// The last log entry before a run starts, so that run's verdicts can be told from earlier ones.
    /// </summary>
    internal procedure Baseline(): Integer
    var
        FilenameProofLog: Record "Filename Proof Log";
    begin
        if FilenameProofLog.FindLast() then
            exit(FilenameProofLog."Entry No.");
        exit(0);
    end;

    internal procedure AssertAllVerdictsPassed(FromEntryNo: Integer)
    var
        Failures: Text;
        Checked: Integer;
    begin
        Checked := CollectFailures(FromEntryNo, Failures);

        if Failures <> '' then
            Error(VerdictsFailedErr, Failures);

        // No verdict at all means the proofs never reached their conclusions.
        if Checked = 0 then
            Error(NoVerdictsErr);
    end;

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
            // A long verdict spans several rows; only the first carries the conclusion.
            if StrPos(FilenameProofLog.Item, ContinuationTok) = 0 then begin
                Checked += 1;
                if not IsPass(FilenameProofLog.Value) then
                    Failures += StrSubstNo(FailureLineLbl, FilenameProofLog.Item, FilenameProofLog.Value);
            end;
        until FilenameProofLog.Next() = 0;
    end;

    // A pass is PASS, or IDENTICAL (several routes gave the same name).
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
