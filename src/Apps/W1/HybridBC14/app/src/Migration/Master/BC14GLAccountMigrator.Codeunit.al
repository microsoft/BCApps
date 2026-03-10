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
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        exit(BC14CompanyAdditionalSettings.GetGLModuleEnabled());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14GLAccount: Record "BC14 G/L Account";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;
        if not IsEnabled() then
            exit(true);

        if BC14GLAccount.FindSet() then
            repeat
                if not TryMigrateGLAccount(BC14GLAccount) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 G/L Account", 'BC14 G/L Account', BC14GLAccount."No.", Database::"G/L Account", GetLastErrorText(), BC14GLAccount.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14GLAccount.Next() = 0;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryMigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account")
    begin
        MigrateGLAccount(BC14GLAccount);
    end;

    internal procedure MigrateGLAccount(BC14GLAccount: Record "BC14 G/L Account")
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(BC14GLAccount."No.") then begin
            GLAccount.Init();
            GLAccount."No." := BC14GLAccount."No.";
            GLAccount.Insert(true);
        end;

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

        GLAccount.Modify(true);
    end;

    /// <summary>
    /// Integration event raised during G/L Account migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 G/L Account to G/L Account.
    /// </summary>
    /// <param name="BC14GLAccount">The source BC14 G/L Account record.</param>
    /// <param name="GLAccount">The target G/L Account record (modifiable).</param>
    [IntegrationEvent(false, false)]
    local procedure OnTransferGLAccountCustomFields(BC14GLAccount: Record "BC14 G/L Account"; var GLAccount: Record "G/L Account")
    begin
    end;

    procedure RetryFailedRecords(StopOnFirstError: Boolean): Boolean
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14GLAccount: Record "BC14 G/L Account";
        Success: Boolean;
    begin
        Success := true;
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 G/L Account");
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);

        if BC14MigrationErrors.FindSet() then
            repeat
                if BC14GLAccount.Get(BC14MigrationErrors."Source Record Key") then
                    if TryMigrateGLAccount(BC14GLAccount) then
                        BC14MigrationErrors.MarkAsResolved('Migrated successfully on retry')
                    else begin
                        BC14MigrationErrors."Retry Count" += 1;
                        BC14MigrationErrors."Last Retry On" := CurrentDateTime();
                        BC14MigrationErrors."Error Message" := CopyStr(GetLastErrorText(), 1, 250);
                        BC14MigrationErrors.Modify();
                        Success := false;
                        if StopOnFirstError then
                            exit(false);
                        ClearLastError();
                    end;
            until BC14MigrationErrors.Next() = 0;

        exit(Success);
    end;

    procedure GetRecordCount(): Integer
    var
        BC14GLAccount: Record "BC14 G/L Account";
    begin
        exit(BC14GLAccount.Count());
    end;
}
