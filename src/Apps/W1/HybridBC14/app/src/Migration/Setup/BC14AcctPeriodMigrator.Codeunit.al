// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Setup;

codeunit 46895 "BC14 Acct. Period Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Accounting Period";

    trigger OnRun()
    begin
        MigrateAccountingPeriod(Rec);
    end;

    var
        MigratorNameLbl: Label 'Accounting Period Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Accounting Period", Database::"BC14 Accounting Period");
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(): Boolean
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateAccountingPeriods(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14AccountingPeriod;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Acct. Period Migrator");

        OnAfterMigrateAccountingPeriods(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Accounting Period", BC14AccountingPeriod.Count()));
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
    begin
        exit(not BC14AccountingPeriod.IsEmpty());
    end;

    internal procedure MigrateAccountingPeriod(BC14AccountingPeriod: Record "BC14 Accounting Period")
    var
        AccountingPeriod: Record "Accounting Period";
        InventorySetup: Record "Inventory Setup";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateAccountingPeriod(BC14AccountingPeriod, IsMigrated);
        if IsMigrated then
            exit;

        if AccountingPeriod.Get(BC14AccountingPeriod."Starting Date") then begin
            AccountingPeriod.Validate(Name, BC14AccountingPeriod.Name);
            AccountingPeriod.Validate(Closed, BC14AccountingPeriod.Closed);
            OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod, AccountingPeriod);
            AccountingPeriod.Modify(true);
        end else begin
            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", BC14AccountingPeriod."Starting Date");
            TransferFields(BC14AccountingPeriod, AccountingPeriod);

            if BC14AccountingPeriod."New Fiscal Year" then
                if InventorySetup.Get() then begin
                    AccountingPeriod."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
                    AccountingPeriod."Average Cost Period" := InventorySetup."Average Cost Period";
                end;

            AccountingPeriod.Insert(true);
        end;

        OnAfterMigrateAccountingPeriod(BC14AccountingPeriod, AccountingPeriod);
    end;

    local procedure TransferFields(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        AccountingPeriod."Starting Date" := BC14AccountingPeriod."Starting Date";

        // Use Validate so any OnValidate business logic runs.
        AccountingPeriod.Validate(Name, BC14AccountingPeriod.Name);
        AccountingPeriod.Validate("New Fiscal Year", BC14AccountingPeriod."New Fiscal Year");
        AccountingPeriod.Validate(Closed, BC14AccountingPeriod.Closed);
        AccountingPeriod.Validate("Date Locked", BC14AccountingPeriod."Date Locked");

        OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod, AccountingPeriod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateAccountingPeriods(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateAccountingPeriods(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateAccountingPeriod(BC14AccountingPeriod: Record "BC14 Accounting Period"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateAccountingPeriod(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
    end;
}

