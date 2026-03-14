// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

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
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        exit(BC14CompanyAdditionalSettings.GetPayablesModuleEnabled());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14Vendor: Record "BC14 Vendor";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;
        if not IsEnabled() then
            exit(true);

        if BC14Vendor.FindSet() then
            repeat
                if not TryMigrateVendor(BC14Vendor) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Vendor", 'BC14 Vendor', BC14Vendor."No.", Database::Vendor, GetLastErrorText(), BC14Vendor.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14Vendor.Next() = 0;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryMigrateVendor(BC14Vendor: Record "BC14 Vendor")
    begin
        MigrateVendor(BC14Vendor);
    end;

    internal procedure MigrateVendor(BC14Vendor: Record "BC14 Vendor")
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(BC14Vendor."No.") then begin
            Vendor.Init();
            Vendor."No." := BC14Vendor."No.";
            Vendor.Insert(true);
        end;

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
        Vendor."Currency Code" := BC14Vendor."Currency Code";
        Vendor."Language Code" := BC14Vendor."Language Code";
        Vendor.Blocked := BC14Vendor.Blocked;

        OnTransferVendorCustomFields(BC14Vendor, Vendor);

        Vendor.Modify(true);
    end;

    /// <summary>
    /// Integration event raised during vendor migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Vendor to Vendor.
    /// </summary>
    /// <param name="BC14Vendor">The source BC14 Vendor record.</param>
    /// <param name="Vendor">The target Vendor record (modifiable).</param>
    [IntegrationEvent(false, false)]
    local procedure OnTransferVendorCustomFields(BC14Vendor: Record "BC14 Vendor"; var Vendor: Record Vendor)
    begin
    end;

    procedure RetryFailedRecords(StopOnFirstError: Boolean): Boolean
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14Vendor: Record "BC14 Vendor";
        Success: Boolean;
    begin
        Success := true;
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Vendor");
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);

        if BC14MigrationErrors.FindSet() then
            repeat
                if BC14Vendor.Get(BC14MigrationErrors."Source Record Key") then
                    if TryMigrateVendor(BC14Vendor) then
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
        BC14Vendor: Record "BC14 Vendor";
    begin
        exit(BC14Vendor.Count());
    end;
}
