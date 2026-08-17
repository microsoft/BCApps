// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Account;

codeunit 46869 "BC14 GL Account Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 G/L Account";

    trigger OnRun()
    begin
        MigrateGLAccount(Rec);
    end;

    var
        MigratorNameLbl: Label 'G/L Account Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"G/L Account", Database::"BC14 G/L Account");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetGLModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14GLAccount: Record "BC14 G/L Account";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGLAccounts(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14GLAccount;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 GL Account Migrator");

        OnAfterMigrateGLAccounts(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GLAccount: Record "BC14 G/L Account";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 G/L Account", BC14GLAccount.Count()));
    end;

    internal procedure MigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account")
    var
        GLAccount: Record "G/L Account";
        IsNew: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateGLAccount(BC14GLAccount, IsMigrated);
        if IsMigrated then
            exit;

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
        GLAccount."Direct Posting" := true;
        GLAccount."Account Category" := BC14GLAccount."Account Category";
        if BC14GLAccount."Account Subcategory Entry No." <> 0 then
            GLAccount."Account Subcategory Entry No." := BC14GLAccount."Account Subcategory Entry No.";

        OnTransferGLAccountCustomFields(BC14GLAccount, GLAccount);

        if IsNew then
            GLAccount.Insert(true)
        else
            GLAccount.Modify(true);

        OnAfterMigrateGLAccount(BC14GLAccount, GLAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGLAccounts(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGLAccounts(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account"; var GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferGLAccountCustomFields(BC14GLAccount: Record "BC14 G/L Account"; var GLAccount: Record "G/L Account")
    begin
    end;
}

