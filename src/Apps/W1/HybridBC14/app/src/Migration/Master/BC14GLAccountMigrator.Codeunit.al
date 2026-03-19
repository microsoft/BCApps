// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.GeneralLedger.Account;

codeunit 50169 "BC14 GL Account Migrator" implements "IMasterMigrator"
{
    var
        MigratorNameLbl: Label 'G/L Account Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetGLModuleEnabled());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 G/L Account");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for G/L Account migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        SourceRecordRef.SetTable(BC14GLAccount);
        exit(TryMigrateGLAccount(BC14GLAccount));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        NoFieldRef: FieldRef;
    begin
        NoFieldRef := SourceRecordRef.Field(1); // No. field
        exit(Format(NoFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        exit(BC14GLAccount.Count());
    end;

    [TryFunction]
    local procedure TryMigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account")
    begin
        MigrateGLAccount(BC14GLAccount);
    end;

    internal procedure MigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account")
    var
        GLAccount: Record "G/L Account";
        IsNew: Boolean;
    begin
        IsNew := not GLAccount.Get(BC14GLAccount."No.");
        if IsNew then begin
            GLAccount.Init();
            GLAccount."No." := BC14GLAccount."No.";
        end;

        // Populate all fields before Insert/Modify to prevent zombie records
        GLAccount.Name := BC14GLAccount.Name;
        GLAccount."Account Type" := BC14GLAccount."Account Type";
        GLAccount."Income/Balance" := BC14GLAccount."Income/Balance";
        GLAccount."Debit/Credit" := BC14GLAccount."Debit/Credit";
        GLAccount.Blocked := BC14GLAccount.Blocked;
        GLAccount."Direct Posting" := BC14GLAccount."Direct Posting";
        GLAccount."Account Category" := BC14GLAccount."Account Category";
        if BC14GLAccount."Account Subcategory Entry No." <> 0 then
            GLAccount."Account Subcategory Entry No." := BC14GLAccount."Account Subcategory Entry No.";

        OnTransferGLAccountCustomFields(BC14GLAccount, GLAccount);

        if IsNew then
            GLAccount.Insert(true)
        else
            GLAccount.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferGLAccountCustomFields(BC14GLAccount: Record "BC14 G/L Account"; var GLAccount: Record "G/L Account")
    begin
    end;
}
