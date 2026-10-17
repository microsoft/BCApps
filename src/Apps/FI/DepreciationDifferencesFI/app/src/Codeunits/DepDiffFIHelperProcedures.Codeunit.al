#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;

codeunit 13481 "Dep Diff FI Helper Procedures"
{
    Access = Internal;

    procedure MigrateFields()
    begin
        MigrateFAPostingGroupFields();
        MigrateFALedgerEntryField();
        MigrateSourceCodeSetupField();
    end;

    local procedure MigrateFAPostingGroupFields()
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        if FAPostingGroup.FindSet(true) then
            repeat
#pragma warning disable AL0432
                FAPostingGroup."Deprec. Difference Account" := FAPostingGroup."Depr. Difference Acc.";
                FAPostingGroup."Deprec. Difference Bal Acct" := FAPostingGroup."Depr. Difference Bal. Acc.";
#pragma warning restore AL0432
                FAPostingGroup.Modify(false);
            until FAPostingGroup.Next() = 0;
    end;

    local procedure MigrateFALedgerEntryField()
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("Depreciation Difference Posted", true);
        FALedgerEntry.ModifyAll("Depreciation Difference Posted", false, false);
        FALedgerEntry.Reset();
#pragma warning disable AL0432
        FALedgerEntry.SetRange("Depr. Difference Posted", true);
#pragma warning restore AL0432
        FALedgerEntry.ModifyAll("Depreciation Difference Posted", true, false);
    end;

    local procedure MigrateSourceCodeSetupField()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if not SourceCodeSetup.Get() then
            exit;
#pragma warning disable AL0432
        SourceCodeSetup."Depreciation Difference Code" := SourceCodeSetup."Depr. Difference";
#pragma warning restore AL0432
        SourceCodeSetup.Modify(false);
    end;
}
#endif
