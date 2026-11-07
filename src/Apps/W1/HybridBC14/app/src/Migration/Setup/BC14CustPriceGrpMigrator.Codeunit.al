// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Pricing;

codeunit 46921 "BC14 Cust. Price Grp. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Cust. Price Group";

    trigger OnRun()
    begin
        MigrateCustomerPriceGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Price Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Customer Price Group", Database::"BC14 Cust. Price Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
    begin
        exit(not BC14CustomerPriceGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14CustomerPriceGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Cust. Price Grp. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustomerPriceGroup: Record "BC14 Cust. Price Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Cust. Price Group", BC14CustomerPriceGroup.Count()));
    end;

    internal procedure MigrateCustomerPriceGroup(BC14CustomerPriceGroup: Record "BC14 Cust. Price Group")
    var
        CustomerPriceGroup: Record "Customer Price Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomerPriceGroup(BC14CustomerPriceGroup, IsMigrated);
        if IsMigrated then
            exit;

        if CustomerPriceGroup.Get(BC14CustomerPriceGroup.Code) then begin
            TransferFields(BC14CustomerPriceGroup, CustomerPriceGroup);
            CustomerPriceGroup.Modify();
        end else begin
            CustomerPriceGroup.Init();
            TransferFields(BC14CustomerPriceGroup, CustomerPriceGroup);
            CustomerPriceGroup.Insert();
        end;

        OnAfterMigrateCustomerPriceGroup(BC14CustomerPriceGroup, CustomerPriceGroup);
    end;

    local procedure TransferFields(BC14CustomerPriceGroup: Record "BC14 Cust. Price Group"; var CustomerPriceGroup: Record "Customer Price Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CustomerPriceGroup.Code := BC14CustomerPriceGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        CustomerPriceGroup.Validate(Description, BC14CustomerPriceGroup.Description);
        CustomerPriceGroup.Validate("Allow Invoice Disc.", BC14CustomerPriceGroup."Allow Invoice Disc.");
        CustomerPriceGroup.Validate("Price Includes VAT", BC14CustomerPriceGroup."Price Includes VAT");
        CustomerPriceGroup.Validate("VAT Bus. Posting Gr. (Price)", BC14CustomerPriceGroup."VAT Bus. Posting Gr. (Price)");
        CustomerPriceGroup.Validate("Allow Line Disc.", BC14CustomerPriceGroup."Allow Line Disc.");

        OnTransferCustomerPriceGroupCustomFields(BC14CustomerPriceGroup, CustomerPriceGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomerPriceGroup(BC14CustomerPriceGroup: Record "BC14 Cust. Price Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomerPriceGroup(BC14CustomerPriceGroup: Record "BC14 Cust. Price Group"; var CustomerPriceGroup: Record "Customer Price Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerPriceGroupCustomFields(BC14CustomerPriceGroup: Record "BC14 Cust. Price Group"; var CustomerPriceGroup: Record "Customer Price Group")
    begin
    end;
}

