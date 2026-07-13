// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 46857 "BC14 Balance Warning" implements "Cloud Migration Warning", "BC14 Migration Validation"
{
    procedure GetDisplayName(): Text[250]
    begin
        exit(BalanceWarningDisplayNameLbl);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure Execute()
    begin
        CreateBalanceWarnings();
    end;

    procedure CheckWarning(): Boolean
    begin
        exit(GetWarningCount() > 0);
    end;

    procedure FixWarning()
    begin
        Page.Run(Page::"BC14 Balance Validation");
    end;

    procedure ShowWarning(var CloudMigrationWarning: Record "Cloud Migration Warning"): Text
    var
        SearchCloudMigrationWarning: Record "Cloud Migration Warning";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
        FilterTxt: Text;
    begin
        SearchCloudMigrationWarning.SetRange("Warning Type", SearchCloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        SearchCloudMigrationWarning.SetRange(Ignored, false);
        HybridReplicationSummary.SetCurrentKey("Start Time");
        if HybridReplicationSummary.FindLast() then
            SearchCloudMigrationWarning.SetFilter(SystemCreatedAt, '>%1', HybridReplicationSummary."Start Time");

        if not SearchCloudMigrationWarning.FindSet() then
            exit;

        repeat
            FilterTxt := FilterTxt + Format(SearchCloudMigrationWarning."Entry No.") + '|'
        until SearchCloudMigrationWarning.Next() = 0;
        FilterTxt := FilterTxt.TrimEnd('|');

        exit(FilterTxt);
    end;

    procedure GetWarningMessage(): Text[1024]
    begin
        exit(BalanceMismatchWarningMsg);
    end;

    procedure GetWarningCount(): Integer
    var
        CloudMigrationWarning: Record "Cloud Migration Warning";
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        CloudMigrationWarning.SetRange(Ignored, false);
        HybridReplicationSummary.SetCurrentKey("Start Time");
        if HybridReplicationSummary.FindLast() then
            CloudMigrationWarning.SetFilter(SystemCreatedAt, '>%1', HybridReplicationSummary."Start Time");

        exit(CloudMigrationWarning.Count());
    end;

    procedure CreateBalanceWarnings()
    var
        GLAccount: Record "G/L Account";
        BC14GLEntry: Record "BC14 G/L Entry";
        CloudMigrationWarning: Record "Cloud Migration Warning";
        BC14Balance: Decimal;
        BCOnlineBalance: Decimal;
        MismatchCount: Integer;
    begin
        ClearExistingWarnings();

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetLoadFields("No.");
        if not GLAccount.FindSet() then
            exit;

        repeat
            BC14GLEntry.SetRange("G/L Account No.", GLAccount."No.");
            BC14GLEntry.CalcSums("Debit Amount", "Credit Amount");
            BC14Balance := BC14GLEntry."Debit Amount" - BC14GLEntry."Credit Amount";

            GLAccount.CalcFields("Net Change");
            BCOnlineBalance := GLAccount."Net Change";

            if Abs(BC14Balance - BCOnlineBalance) > 0.01 then
                MismatchCount += 1;
        until GLAccount.Next() = 0;

        if MismatchCount = 0 then
            exit;

        CloudMigrationWarning.Init();
        CloudMigrationWarning."Entry No." := 0;
        CloudMigrationWarning."Warning Type" := CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch";
        CloudMigrationWarning.Message := CopyStr(StrSubstNo(BalanceMismatchDetailMsg, MismatchCount), 1, MaxStrLen(CloudMigrationWarning.Message));
        CloudMigrationWarning.Insert();
    end;

    local procedure ClearExistingWarnings()
    var
        CloudMigrationWarning: Record "Cloud Migration Warning";
    begin
        CloudMigrationWarning.SetRange("Warning Type", CloudMigrationWarning."Warning Type"::"BC14 Balance Mismatch");
        if not CloudMigrationWarning.IsEmpty() then
            CloudMigrationWarning.DeleteAll();
    end;

    var
        BalanceWarningDisplayNameLbl: Label 'Balance Warning', Locked = true;
        BalanceMismatchWarningMsg: Label 'G/L account balances from the source system do not match the current balances in Business Central Online.';
        BalanceMismatchDetailMsg: Label '%1 G/L account(s) have balance differences between source and Business Central Online. Open the Balance Validation page to review details.', Comment = '%1 = number of mismatched accounts';
}
