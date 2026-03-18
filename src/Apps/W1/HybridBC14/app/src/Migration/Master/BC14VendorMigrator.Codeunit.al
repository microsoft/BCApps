// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;

codeunit 50167 "BC14 Vendor Migrator" implements "IMasterMigrator"
{
    var
        MigratorNameLbl: Label 'Vendor Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record "BC14CompanyMigrationSettings";
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetPayablesModuleEnabled());
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Vendor");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Vendor migration
    end;

    procedure IsRecordMigrated(var SourceRecordRef: RecordRef): Boolean
    var
        Vendor: Record Vendor;
        RecordKey: Text[250];
    begin
        RecordKey := GetSourceRecordKey(SourceRecordRef);
        // Only skip if target record already exists - failed records will be retried
        exit(Vendor.Get(RecordKey));
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14Vendor: Record "BC14 Vendor";
    begin
        SourceRecordRef.SetTable(BC14Vendor);
        exit(TryMigrateVendor(BC14Vendor));
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
        BC14Vendor: Record "BC14 Vendor";
    begin
        exit(BC14Vendor.Count());
    end;

    [TryFunction]
    local procedure TryMigrateVendor(BC14Vendor: Record "BC14 Vendor")
    begin
        MigrateVendor(BC14Vendor);
    end;

    internal procedure MigrateVendor(BC14Vendor: Record "BC14 Vendor")
    var
        Vendor: Record Vendor;
        GeneralLedgerSetup: Record "General Ledger Setup";
        IsNew: Boolean;
        CurrencyCode: Code[10];
    begin
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

        // LCY (Local Currency) is not stored in the Currency table.
        // If source Currency Code = LCY Code, set to blank to avoid validation error.
        CurrencyCode := BC14Vendor."Currency Code";
        if (CurrencyCode <> '') and GeneralLedgerSetup.Get() then
            if CurrencyCode = GeneralLedgerSetup."LCY Code" then
                CurrencyCode := '';
        Vendor."Currency Code" := CurrencyCode;

        Vendor."Language Code" := BC14Vendor."Language Code";
        Vendor.Blocked := BC14Vendor.Blocked;

        OnTransferVendorCustomFields(BC14Vendor, Vendor);

        if IsNew then
            Vendor.Insert(true)
        else
            Vendor.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorCustomFields(BC14Vendor: Record "BC14 Vendor"; var Vendor: Record Vendor)
    begin
    end;
}
