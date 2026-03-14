// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Setup;

codeunit 50195 "BC14 Acct. Period Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Accounting Period Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(HasDataToMigrate());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14AccountingPeriod.FindSet() then
            repeat
                if not TryMigrateAccountingPeriod(BC14AccountingPeriod) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Accounting Period", 'BC14 Accounting Period', Format(BC14AccountingPeriod."Starting Date"), Database::"Accounting Period", GetLastErrorText(), BC14AccountingPeriod.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14AccountingPeriod.Next() = 0;

        exit(Success);
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
    begin
        exit(not BC14AccountingPeriod.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigrateAccountingPeriod(BC14AccountingPeriod: Record "BC14 Accounting Period")
    var
        AccountingPeriod: Record "Accounting Period";
        InventorySetup: Record "Inventory Setup";
    begin
        if AccountingPeriod.Get(BC14AccountingPeriod."Starting Date") then begin
            TransferFields(BC14AccountingPeriod, AccountingPeriod);
            AccountingPeriod.Modify(true);
        end else begin
            AccountingPeriod.Init();
            AccountingPeriod.Validate("Starting Date", BC14AccountingPeriod."Starting Date");
            TransferFields(BC14AccountingPeriod, AccountingPeriod);

            // For new fiscal year, get average cost settings from Inventory Setup
            if BC14AccountingPeriod."New Fiscal Year" then
                if InventorySetup.Get() then begin
                    AccountingPeriod."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type";
                    AccountingPeriod."Average Cost Period" := InventorySetup."Average Cost Period";
                end;

            AccountingPeriod.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
        AccountingPeriod."Starting Date" := BC14AccountingPeriod."Starting Date";
        AccountingPeriod.Name := BC14AccountingPeriod.Name;
        AccountingPeriod."New Fiscal Year" := BC14AccountingPeriod."New Fiscal Year";
        AccountingPeriod.Closed := BC14AccountingPeriod.Closed;
        AccountingPeriod."Date Locked" := BC14AccountingPeriod."Date Locked";
        // Note: Average Cost Calc. Type and Average Cost Period are handled in TryMigrateAccountingPeriod

        // Allow extensions to map custom fields
        OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod, AccountingPeriod);
    end;

    /// <summary>
    /// Integration event raised during accounting period migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
    end;
}
