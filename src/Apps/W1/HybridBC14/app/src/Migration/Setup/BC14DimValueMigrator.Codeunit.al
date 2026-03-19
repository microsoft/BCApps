// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.Dimension;

codeunit 50187 "BC14 Dim. Value Migrator" implements "ISetupMigrator"
{
    var
        MigratorNameLbl: Label 'Dimension Value Migrator';
        DimensionDoesNotExistErr: Label 'Dimension %1 does not exist. Please ensure Dimension table is migrated first.', Comment = '%1 = Dimension Code';

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
        exit(Database::"BC14 Dimension Value");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Dimension Value migration
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
    begin
        SourceRecordRef.SetTable(BC14DimensionValue);
        exit(TryMigrateDimensionValue(BC14DimensionValue));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        DimCodeFieldRef: FieldRef;
        CodeFieldRef: FieldRef;
    begin
        DimCodeFieldRef := SourceRecordRef.Field(1); // Dimension Code field
        CodeFieldRef := SourceRecordRef.Field(2); // Code field
        exit(Format(DimCodeFieldRef.Value()) + '_' + Format(CodeFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
    begin
        exit(BC14DimensionValue.Count());
    end;

    local procedure HasDataToMigrate(): Boolean
    var
        BC14DimensionValue: Record "BC14 Dimension Value";
    begin
        exit(not BC14DimensionValue.IsEmpty());
    end;

    [TryFunction]
    local procedure TryMigrateDimensionValue(BC14DimensionValue: Record "BC14 Dimension Value")
    var
        DimensionValue: Record "Dimension Value";
        Dimension: Record Dimension;
    begin
        if not Dimension.Get(BC14DimensionValue."Dimension Code") then
            Error(DimensionDoesNotExistErr, BC14DimensionValue."Dimension Code");

        if DimensionValue.Get(BC14DimensionValue."Dimension Code", BC14DimensionValue.Code) then begin
            TransferFields(BC14DimensionValue, DimensionValue);
            DimensionValue.Modify(true);
        end else begin
            DimensionValue.Init();
            DimensionValue."Dimension Code" := BC14DimensionValue."Dimension Code";
            DimensionValue.Code := BC14DimensionValue.Code;
            TransferFields(BC14DimensionValue, DimensionValue);
            DimensionValue.Insert(true);
        end;
    end;

    local procedure TransferFields(BC14DimensionValue: Record "BC14 Dimension Value"; var DimensionValue: Record "Dimension Value")
    begin
        DimensionValue.Name := BC14DimensionValue.Name;
        DimensionValue."Dimension Value Type" := BC14DimensionValue."Value Type";
        DimensionValue.Totaling := BC14DimensionValue.Totaling;
        DimensionValue.Blocked := BC14DimensionValue.Blocked;
        DimensionValue."Consolidation Code" := BC14DimensionValue."Consolidation Code";
        DimensionValue.Indentation := BC14DimensionValue.Indentation;
        DimensionValue."Global Dimension No." := BC14DimensionValue."Global Dimension No.";
        DimensionValue."Map-to IC Dimension Code" := BC14DimensionValue."Map-to IC Dimension Code";
        DimensionValue."Map-to IC Dimension Value Code" := BC14DimensionValue."Map-to IC Dimension Value Code";

        OnTransferDimensionValueCustomFields(BC14DimensionValue, DimensionValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDimensionValueCustomFields(BC14DimensionValue: Record "BC14 Dimension Value"; var DimensionValue: Record "Dimension Value")
    begin
    end;
}
