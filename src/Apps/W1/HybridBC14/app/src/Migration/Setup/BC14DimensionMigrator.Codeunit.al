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

    procedure GetSourceTableId(): Integer
    begin
        exit(Database::"BC14 Dimension");
    end;

    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef)
    begin
        // No special filters needed for Dimension migration
    end;

    procedure IsRecordMigrated(var SourceRecordRef: RecordRef): Boolean
    var
        Dimension: Record Dimension;
        RecordKey: Text[250];
    begin
        RecordKey := GetSourceRecordKey(SourceRecordRef);
        exit(Dimension.Get(RecordKey));
    end;

    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean
    var
        BC14Dimension: Record "BC14 Dimension";
    begin
        SourceRecordRef.SetTable(BC14Dimension);
        exit(TryMigrateDimension(BC14Dimension));
    end;

    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250]
    var
        CodeFieldRef: FieldRef;
    begin
        CodeFieldRef := SourceRecordRef.Field(1); // Code field
        exit(Format(CodeFieldRef.Value()));
    end;

    procedure GetRecordCount(): Integer
    var
        BC14Dimension: Record "BC14 Dimension";
    begin
        exit(BC14Dimension.Count());
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
            TransferFields(BC14Dimension, Dimension);
            Dimension.Modify(true);
        end else begin
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

        OnTransferDimensionCustomFields(BC14Dimension, Dimension);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferDimensionCustomFields(BC14Dimension: Record "BC14 Dimension"; var Dimension: Record Dimension)
    begin
    end;
}
