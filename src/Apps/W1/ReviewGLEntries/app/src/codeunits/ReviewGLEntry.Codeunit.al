namespace Microsoft.Finance.GeneralLedger.Review;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;
using System.Telemetry;

codeunit 22200 "Review G/L Entry" implements "G/L Entry Reviewer"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "G/L Entry Review Setup" = ri,
#if not CLEAN27
#pragma warning disable AL0432
                  TableData "G/L Entry Review Entry" = rid,
#pragma warning restore AL0432
#endif
                  TableData "G/L Entry Review Log" = rid;

    var
        NoEntriesSelectedLbl: Label 'No entries were selected';
        GLAccountLbl: Label 'G/L Entries for G/L Account %1 %2 were not marked as reviewed since the G/L Account has Review Policy None', Locked = false, MaxLength = 999, Comment = '%1 is G/L Account No. and %2 is G/L Account Name';
        BalanceNotMatchingMsg: Label 'Selected G/L Entries for G/L Account %1 %2 were not marked as reviewed because credit and debit do not match and the review policy on the account enforces that', Locked = false, MaxLength = 999, Comment = '%1 is G/L Account No. and %2 is G/L Account Name';


    procedure ReviewEntries(var GLEntry: Record "G/L Entry");
    var
        GLEntryToProcess: Record "G/L Entry";
        GLEntrySnapshot: Record "G/L Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        GLEntryReviewLog: Record "G/L Entry Review Log";
#if not CLEAN27
#pragma warning disable AL0432
        GLEntryReviewEntry: Record "G/L Entry Review Entry";
#pragma warning restore AL0432
#endif
        FeatureTelemetry: Codeunit "Feature Telemetry";
        UserName: Code[50];
        Identifier: Integer;
    begin
        VerifyThatAllEntriesHaveSamePolicy(GLEntry);
        ValidateEntries(GLEntry);
        Identifier := GetNextIdentifier();
        UserName := CopyStr(Database.UserId(), 1, MaxStrLen(UserName));
        // Snapshot the selected rows into a temporary buffer in a single pass.
        // Iterating with Modify directly on the page-supplied recordset is
        // unreliable when the selection is large enough that
        // CurrPage.SetSelectionFilter falls back to marks (e.g. Ctrl+A on
        // thousands of rows): Modify(true) reloads the record and can drop the
        // marked cursor mid-iteration, causing only the first few entries to be
        // processed. The in-memory temp record is immune to that.
        // Use a local Copy + SetLoadFields so we only fetch the columns the
        // processing loop actually needs (G/L Entry has 70+ columns) and so
        // SetLoadFields does not bleed onto the caller's recordset.
        GLEntrySnapshot.Copy(GLEntry);
        GLEntrySnapshot.SetLoadFields("Entry No.", "Amount to Review", Amount, "G/L Account No.");
        GLEntrySnapshot.FindSet();
        repeat
            TempGLEntry := GLEntrySnapshot;
            TempGLEntry.Insert();
        until GLEntrySnapshot.Next() = 0;

        TempGLEntry.FindSet();
        repeat
            GLEntryReviewLog.Init();
            GLEntryReviewLog."G/L Entry No." := TempGLEntry."Entry No.";
            GLEntryReviewLog."Reviewed Identifier" := Identifier;
            GLEntryReviewLog."Reviewed By" := UserName;
            if TempGLEntry."Amount to Review" = 0 then
                GLEntryReviewLog."Reviewed Amount" := TempGLEntry.Amount
            else
                GLEntryReviewLog."Reviewed Amount" := TempGLEntry."Amount to Review";
            GLEntryReviewLog."G/L Account No." := TempGLEntry."G/L Account No.";
            GLEntryReviewLog."Reviewed At" := CurrentDateTime();
            GLEntryReviewLog.Insert(true);

            // Only touch the persistent G/L Entry when there is something to
            // clear. In the typical flow "Amount to Review" is 0 for every
            // selected row, so this avoids a per-row Get + Modify roundtrip.
            if TempGLEntry."Amount to Review" <> 0 then begin
                GLEntryToProcess.Get(TempGLEntry."Entry No.");
                GLEntryToProcess."Amount to Review" := 0;
                GLEntryToProcess.Modify(true);
            end;
        until TempGLEntry.Next() = 0;
#if not CLEAN27
#pragma warning disable AL0432
        OnAfterReviewEntries(GLEntry, GLEntryReviewEntry);
#pragma warning restore AL0432
#endif

        OnAfterReviewEntriesLog(GLEntry, GLEntryReviewLog);

        FeatureTelemetry.LogUptake('0000J2W', 'Review G/L Entries', "Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000KQJ', 'Review G/L Entries', 'Review G/L Entries');
    end;

    procedure UnreviewEntries(var GLEntry: Record "G/L Entry");
    var
        GLEntrySnapshot: Record "G/L Entry";
        GLEntryReviewLog: Record "G/L Entry Review Log";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        ValidateEntries(GLEntry);
        // Snapshot the selected entry numbers into a List to avoid losing the
        // marked cursor when CurrPage.SetSelectionFilter falls back to marks
        // (large multi-selection via Ctrl+A) and the per-entry DeleteAll
        // disrupts iteration. Only "Entry No." is needed for the unreview
        // loop, so a List<Integer> is dramatically lighter than a temp record
        // (which would allocate the full G/L Entry row structure per entry).
        // Use a local Copy + SetLoadFields so SetLoadFields does not bleed
        // onto the caller's recordset.
        GLEntrySnapshot.Copy(GLEntry);
        GLEntrySnapshot.SetLoadFields("Entry No.");
        GLEntrySnapshot.FindSet();
        repeat
            EntryNos.Add(GLEntrySnapshot."Entry No.");
        until GLEntrySnapshot.Next() = 0;

        foreach EntryNo in EntryNos do begin
            GLEntryReviewLog.SetRange("G/L Entry No.", EntryNo);
            GLEntryReviewLog.DeleteAll(true);
        end;
    end;

    procedure ValidateEntries(var GLEntry: Record "G/L Entry")
    var
        GLAccount: Record "G/L Account";
        ErrorMsg: Text;
    begin
        if GLEntry.IsEmpty() then
            Error(NoEntriesSelectedLbl);
        GLEntry.FindSet();
        GLAccount.Get(GLEntry."G/L Account No.");
        if GLAccount."Review Policy" = "G/L Account Review Policy"::None then begin
            ErrorMsg := StrSubstNo(GLAccountLbl, GLAccount."No.", GLAccount.Name);
            Error(ErrorMsg);
        end;
        if GLAccount."Review Policy" = "G/L Account Review Policy"::"Allow Review and Match Balance" then
            if not CreditDebitSumsToZero(GLEntry) then begin
                ErrorMsg := StrSubstNo(BalanceNotMatchingMsg, GLAccount."No.", GLAccount.Name);
                Error(ErrorMsg);
            end;
    end;

    local procedure VerifyThatAllEntriesHaveSamePolicy(var GLEntry: Record "G/L Entry")
    var
        GLEntryCopy: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        ReviewPolicyType: Enum "Review Policy Type";
        NoMatchingPolicyErr: Label 'All entries must have the same review policy.';
    begin
        // Use a local copy so SetLoadFields does not bleed onto the caller's
        // recordset, where it would interfere with later Modify operations.
        GLEntryCopy.Copy(GLEntry);
        GLEntryCopy.SetLoadFields("G/L Account No.");
        if GLEntryCopy.FindSet() then begin
            GLAccount.Get(GLEntryCopy."G/L Account No.");
            ReviewPolicyType := GLAccount."Review Policy";
            repeat
                GLAccount.Get(GLEntryCopy."G/L Account No.");
                if GLAccount."Review Policy" <> ReviewPolicyType then
                    Error(NoMatchingPolicyErr);
            until GLEntryCopy.Next() = 0;
        end;

    end;

    local procedure CreditDebitSumsToZero(var GLEntry: Record "G/L Entry"): Boolean
    var
        GLEntry2: Record "G/L Entry";
        Balance: Decimal;
    begin
        GLEntry2.Copy(GLEntry);
        GLEntry2.SetLoadFields("Amount to Review", "Debit Amount", "Credit Amount");
        if GLEntry2.IsEmpty() then
            exit(true);

        GLEntry2.SetRange("Amount to Review", 0);
        GLEntry2.CalcSums("Debit Amount", "Credit Amount");
        Balance := GLEntry2."Credit Amount" - GLEntry2."Debit Amount";
        GLEntry2.SetFilter("Amount to Review", '<>0');
        GLEntry2.CalcSums("Amount to Review");
        Balance += GLEntry2."Amount to Review";
        exit(Balance = 0);
    end;

    local procedure GetNextIdentifier(): Integer
    var
        GLEntry: Record "G/L Entry Review Log";
    begin
        GLEntry.SetCurrentKey("Reviewed Identifier");
        GLEntry.SetAscending("Reviewed Identifier", false);
        if GLEntry.FindFirst() then
            exit(GLEntry."Reviewed Identifier" + 1);
        exit(1);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitSetupTables', '', false, false)]
    local procedure OnAfterInitSetupTables()
    var
        GLEntryReviewSetup: Record "G/L Entry Review Setup";
    begin
        if not GLEntryReviewSetup.Get() then begin
            GLEntryReviewSetup.Init();
            GLEntryReviewSetup.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnSkipGLEntryByReviewStatus', '', false, false)]
    local procedure OnSkipGLEntryByReviewStatus(var GLEntry: Record "G/L Entry"; ReviewStatus: Option All,Reviewed,"Not Reviewed"; EvaluationDate: Date; Skip: Boolean)
    begin
        if EvaluationDate <> 0D then
            case ReviewStatus of
                ReviewStatus::Reviewed:
                    if GLEntry."Reviewed Date" = 0DT then
                        Skip := true
                    else
                        Skip := (DT2Date(GLEntry."Reviewed Date") > EvaluationDate);
                ReviewStatus::"Not Reviewed":
                    if GLEntry."Reviewed Date" = 0DT then
                        Skip := false
                    else
                        Skip := (DT2Date(GLEntry."Reviewed Date") <= EvaluationDate);
            end
        else
            case ReviewStatus of
                ReviewStatus::Reviewed:
                    Skip := (GLEntry."Reviewed Date" = 0DT);
                ReviewStatus::"Not Reviewed":
                    Skip := (GLEntry."Reviewed Date" <> 0DT);
            end;
    end;

#if not CLEAN27
#pragma warning disable AL0432
    [Obsolete('Use the event OnAfterReviewEntriesLog instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterReviewEntries(var GLEntry: Record "G/L Entry"; var GLEntryReviewEntry: Record "G/L Entry Review Entry")
    begin
    end;
#pragma warning restore AL0432
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterReviewEntriesLog(var GLEntry: Record "G/L Entry"; var GLEntryReviewLog: Record "G/L Entry Review Log")
    begin
    end;
}

