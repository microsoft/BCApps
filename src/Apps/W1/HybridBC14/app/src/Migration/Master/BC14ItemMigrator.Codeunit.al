// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Inventory.Item;

codeunit 50170 "BC14 Item Migrator" implements "IMasterMigrator"
{
    var
        MigratorNameLbl: Label 'Item Migrator';

    procedure GetName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
    begin
        BC14CompanyAdditionalSettings.GetSingleInstance();
        exit(BC14CompanyAdditionalSettings.GetInventoryModuleEnabled());
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    var
        BC14Item: Record "BC14 Item";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;
        if not IsEnabled() then
            exit(true);

        if BC14Item.FindSet() then
            repeat
                if not TryMigrateItem(BC14Item) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Item", 'BC14 Item', BC14Item."No.", Database::Item, GetLastErrorText(), BC14Item.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14Item.Next() = 0;

        exit(Success);
    end;

    [TryFunction]
    local procedure TryMigrateItem(BC14Item: Record "BC14 Item")
    begin
        MigrateItem(BC14Item);
    end;

    internal procedure MigrateItem(BC14Item: Record "BC14 Item")
    var
        Item: Record Item;
    begin
        if not Item.Get(BC14Item."No.") then begin
            Item.Init();
            Item."No." := BC14Item."No.";
            Item.Insert(true);
        end;

        Item.Description := BC14Item.Description;
        Item.Type := Enum::"Item Type".FromInteger(BC14Item.Type);
        Item."Base Unit of Measure" := BC14Item."Base Unit of Measure";
        Item."Unit Price" := BC14Item."Unit Price";
        Item."Standard Cost" := BC14Item."Standard Cost";
        Item."Unit Cost" := BC14Item."Unit Cost";
        Item.Blocked := BC14Item.Blocked;
        Item."Inventory Posting Group" := BC14Item."Inventory Posting Group";
        Item."Costing Method" := Enum::"Costing Method".FromInteger(BC14Item."Costing Method");
        Item."Net Weight" := BC14Item."Net Weight";
        Item."Unit Volume" := BC14Item."Unit Volume";

        OnTransferItemCustomFields(BC14Item, Item);

        Item.Modify(true);
    end;

    /// <summary>
    /// Integration event raised during item migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Item to Item.
    /// </summary>
    /// <param name="BC14Item">The source BC14 Item record.</param>
    /// <param name="Item">The target Item record (modifiable).</param>
    [IntegrationEvent(false, false)]
    local procedure OnTransferItemCustomFields(BC14Item: Record "BC14 Item"; var Item: Record Item)
    begin
    end;

    procedure RetryFailedRecords(StopOnFirstError: Boolean): Boolean
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14Item: Record "BC14 Item";
        Success: Boolean;
    begin
        Success := true;
        BC14MigrationErrors.SetRange("Source Table ID", Database::"BC14 Item");
        BC14MigrationErrors.SetRange("Company Name", CompanyName());
        BC14MigrationErrors.SetRange("Scheduled For Retry", true);
        BC14MigrationErrors.SetRange("Resolved", false);

        if BC14MigrationErrors.FindSet() then
            repeat
                if BC14Item.Get(BC14MigrationErrors."Source Record Key") then
                    if TryMigrateItem(BC14Item) then
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
        BC14Item: Record "BC14 Item";
    begin
        exit(BC14Item.Count());
    end;
}
