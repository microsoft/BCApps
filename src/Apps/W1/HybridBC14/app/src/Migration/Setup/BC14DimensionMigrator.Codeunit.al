// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.Dimension;

codeunit 50190 "BC14 Dimension Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Dimension Migrator';

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
        BC14Dimension: Record "BC14 Dimension";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        Success: Boolean;
    begin
        Success := true;

        if not HasDataToMigrate() then
            exit(true);

        if BC14Dimension.FindSet() then
            repeat
                if not TryMigrateDimension(BC14Dimension) then begin
                    BC14MigrationErrorHandler.LogError(GetName(), Database::"BC14 Dimension", 'BC14 Dimension', BC14Dimension.Code, Database::Dimension, GetLastErrorText(), BC14Dimension.RecordId);
                    Success := false;
                    if StopOnFirstError then
                        exit(false);
                    ClearLastError();
                end;
            until BC14Dimension.Next() = 0;

        exit(Success);
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14Dimension: Record "BC14 Dimension";
    begin
        exit(not BC14Dimension.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigrateDimension(BC14Dimension: Record "BC14 Dimension")
    var
        Dimension: Record Dimension;
    begin
        if Dimension.Get(BC14Dimension.Code) then begin
            // Update existing record
            TransferFields(BC14Dimension, Dimension);
            Dimension.Modify(true);
        end else begin
            // Insert new record
            Dimension.Init();
            TransferFields(BC14Dimension, Dimension);
            Dimension.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
        Dimension.Code := BC14Dimension.Code;
        Dimension.Name := BC14Dimension.Name;
        Dimension."Code Caption" := BC14Dimension."Code Caption";
        Dimension."Filter Caption" := BC14Dimension."Filter Caption";
        Dimension.Description := BC14Dimension.Description;
        Dimension.Blocked := BC14Dimension.Blocked;
        Dimension."Consolidation Code" := BC14Dimension."Consolidation Code";
        Dimension."Map-to IC Dimension Code" := BC14Dimension."Map-to IC Dimension Code";

        // Allow extensions to map custom fields
        OnTransferDimensionCustomFields(BC14Dimension, Dimension);
    end;

    /// <summary>
    /// Integration event raised during dimension migration to allow mapping of custom fields.
    /// Subscribe to this event to transfer TableExtension fields from BC14 Dimension to Dimension.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferDimensionCustomFields(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
    end;
}
