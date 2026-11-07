// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;

codeunit 46867 "BC14 Vendor Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Vendor";

    trigger OnRun()
    begin
        MigrateVendor(Rec);
    end;

    var
        MigratorNameLbl: Label 'Vendor Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Vendor", Database::"BC14 Vendor");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetPayablesModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14Vendor: Record "BC14 Vendor";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVendors(IsMigrated);
        if IsMigrated then
            exit(true);

        SourceVariant := BC14Vendor;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Vendor Migrator");

        OnAfterMigrateVendors(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14Vendor: Record "BC14 Vendor";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Vendor", BC14Vendor.Count()));
    end;

    internal procedure MigrateVendor(BC14Vendor: Record "BC14 Vendor")
    var
        Vendor: Record Vendor;
        IsNew: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateVendor(BC14Vendor, IsMigrated);
        if IsMigrated then
            exit;

        IsNew := not Vendor.Get(BC14Vendor."No.");
        if IsNew then begin
            Vendor.Init();
            Vendor."No." := BC14Vendor."No.";
        end;

        // Populate all fields before Insert/Modify to prevent zombie records
        Vendor.Name := BC14Vendor.Name;
        Vendor.Address := BC14Vendor.Address;
        Vendor."Address 2" := BC14Vendor."Address 2";
        Vendor.City := BC14Vendor.City;
        Vendor."Post Code" := BC14Vendor."Post Code";
        Vendor."Country/Region Code" := BC14Vendor."Country/Region Code";
        Vendor."Phone No." := BC14Vendor."Phone No.";
        Vendor."E-Mail" := BC14Vendor."E-Mail";
        Vendor."Home Page" := BC14Vendor."Home Page";
        Vendor."Vendor Posting Group" := BC14Vendor."Vendor Posting Group";
        Vendor."Gen. Bus. Posting Group" := BC14Vendor."Gen. Bus. Posting Group";
        Vendor."Payment Terms Code" := BC14Vendor."Payment Terms Code";
        Vendor."Currency Code" := ResolveCurrencyCode(BC14Vendor."Currency Code");

        Vendor."Language Code" := BC14Vendor."Language Code";
        Vendor.Blocked := BC14Vendor.Blocked;

        OnTransferVendorCustomFields(BC14Vendor, Vendor);

        if IsNew then
            Vendor.Insert(true)
        else
            Vendor.Modify(true);

        OnAfterMigrateVendor(BC14Vendor, Vendor);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVendors(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVendors(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateVendor(BC14Vendor: Record "BC14 Vendor"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateVendor(BC14Vendor: Record "BC14 Vendor"; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorCustomFields(BC14Vendor: Record "BC14 Vendor"; var Vendor: Record Vendor)
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

