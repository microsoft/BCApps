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

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Accounting Period");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Accounting Period migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
    begin
        SourceRecordRef.SetTable(BC14AccountingPeriod);
        exit(TryMigrateAccountingPeriod(BC14AccountingPeriod));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        StartDateFieldRef: FieldRef;
    begin
        StartDateFieldRef := SourceRecordRef.Field(1); // Starting Date field
        exit(Format(StartDateFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14AccountingPeriod: Record "BC14 Accounting Period";
    begin
        exit(BC14AccountingPeriod.Count());
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

        OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod, AccountingPeriod);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferAccountingPeriodCustomFields(BC14AccountingPeriod: Record "BC14 Accounting Period"; var AccountingPeriod: Record "Accounting Period")
    begin
    end;
}
