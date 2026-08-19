// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Sales.Pricing;

codeunit 46922 "BC14 Cust. Disc. Grp. Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Customer Discount Group";

    trigger OnRun()
    begin
        MigrateCustomerDiscountGroup(Rec);
    end;

    var
        MigratorNameLbl: Label 'Customer Discount Group Migrator';

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Customer Discount Group", Database::"BC14 Customer Discount Group");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
    begin
        exit(not BC14CustomerDiscountGroup.IsEmpty());
    end;

    procedure Migrate(): Boolean
    var
        BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
    begin
        SourceVariant := BC14CustomerDiscountGroup;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Cust. Disc. Grp. Migrator");

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group";
        BC14RecordTracker: Codeunit "BC14 Migration Record Tracker";
    begin
        exit(BC14RecordTracker.GetRemainingPercentage(Database::"BC14 Customer Discount Group", BC14CustomerDiscountGroup.Count()));
    end;

    internal procedure MigrateCustomerDiscountGroup(BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group")
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateCustomerDiscountGroup(BC14CustomerDiscountGroup, IsMigrated);
        if IsMigrated then
            exit;

        if CustomerDiscountGroup.Get(BC14CustomerDiscountGroup.Code) then begin
            TransferFields(BC14CustomerDiscountGroup, CustomerDiscountGroup);
            CustomerDiscountGroup.Modify();
        end else begin
            CustomerDiscountGroup.Init();
            TransferFields(BC14CustomerDiscountGroup, CustomerDiscountGroup);
            CustomerDiscountGroup.Insert();
        end;

        OnAfterMigrateCustomerDiscountGroup(BC14CustomerDiscountGroup, CustomerDiscountGroup);
    end;

    local procedure TransferFields(BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group"; var CustomerDiscountGroup: Record "Customer Discount Group")
    begin
        // Primary key fields are assigned directly (required before Insert; no OnValidate logic).
        CustomerDiscountGroup.Code := BC14CustomerDiscountGroup.Code;

        // Use Validate so any OnValidate business logic runs.
        CustomerDiscountGroup.Validate(Description, BC14CustomerDiscountGroup.Description);

        OnTransferCustomerDiscountGroupCustomFields(BC14CustomerDiscountGroup, CustomerDiscountGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateCustomerDiscountGroup(BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateCustomerDiscountGroup(BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group"; var CustomerDiscountGroup: Record "Customer Discount Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferCustomerDiscountGroupCustomFields(BC14CustomerDiscountGroup: Record "BC14 Customer Discount Group"; var CustomerDiscountGroup: Record "Customer Discount Group")
    begin
    end;
}

