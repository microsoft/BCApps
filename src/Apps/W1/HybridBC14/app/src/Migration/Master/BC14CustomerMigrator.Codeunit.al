// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;

codeunit 46865 "BC14 Customer Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Customer";

    trigger OnRun()
    begin
        MigrateCustomer(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Customer", Database::"BC14 Customer");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetReceivablesModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14Customer: Record "BC14 Customer";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomers(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14Customer;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant,
            BC14Customer.FieldNo("No."),
            Codeunit::"BC14 Customer Migrator");

        // OnAfter fires unconditionally (including stop-on-first-error path) so subscribers
        // can perform cleanup that the original early-exit pattern would have skipped.
        OnAfterMigrateCustomers(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Customer: Record "BC14 Customer";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Customer", BC14Customer.Count()));
    end;

    internal procedure MigrateCustomer(BC14Customer: Record "BC14 Customer")
    var
        Customer: Record Customer;
        IsNew: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomer(BC14Customer, IsMigrated);
        if IsMigrated then
            exit;

        IsNew := not Customer.Get(BC14Customer."No.");
        if IsNew then begin
            Customer.Init();
            Customer."No." := BC14Customer."No.";
        end;

        // Populate all fields before Insert/Modify to prevent zombie records
        // (Insert succeeds but subsequent Modify fails leaving incomplete data).
        // Direct field assignment is used (no Validate) because the source data has already
        // been validated in BC14; re-validating triggers business logic that would mutate
        // the data (e.g. clearing fields, recalculating, auto-creating side records) and
        // produce records that no longer match the source.
        Customer.Name := BC14Customer.Name;
        Customer.Address := BC14Customer.Address;
        Customer."Address 2" := BC14Customer."Address 2";
        Customer.City := BC14Customer.City;
        Customer."Post Code" := BC14Customer."Post Code";
        Customer."Country/Region Code" := BC14Customer."Country/Region Code";
        Customer."Phone No." := BC14Customer."Phone No.";
        Customer."E-Mail" := BC14Customer."E-Mail";
        Customer."Home Page" := BC14Customer."Home Page";
        Customer."Customer Posting Group" := BC14Customer."Customer Posting Group";
        Customer."Gen. Bus. Posting Group" := BC14Customer."Gen. Bus. Posting Group";
        Customer."Payment Terms Code" := BC14Customer."Payment Terms Code";
        Customer."Currency Code" := ResolveCurrencyCode(BC14Customer."Currency Code");

        Customer."Language Code" := BC14Customer."Language Code";
        Customer."Credit Limit (LCY)" := BC14Customer."Credit Limit (LCY)";
        Customer.Blocked := BC14Customer.Blocked;

        OnTransferCustomerCustomFields(BC14Customer, Customer);

        if IsNew then
            Customer.Insert(true)
        else
            Customer.Modify(true);

        OnAfterMigrateCustomer(BC14Customer, Customer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomers(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomers(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomer(BC14Customer: Record "BC14 Customer"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomer(BC14Customer: Record "BC14 Customer"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerCustomFields(BC14Customer: Record "BC14 Customer"; var Customer: Record Customer)
    begin
    end;

    local procedure ResolveCurrencyCode(SourceCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if (SourceCurrencyCode <> '') and GeneralLedgerSetup.Get() then
            if SourceCurrencyCode = GeneralLedgerSetup."LCY Code" then
                exit('');
        exit(SourceCurrencyCode);
    end;
}

