codeunit 132800 "Upgrade Test Data Setup Mgt."
{
    [IntegrationEvent(false, false)]
    procedure OnSetupDataPerCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSetupDataPerDatabase()
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetTablesToBackupPerCompany(TableMapping: Dictionary of [Integer, Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetTablesToBackupPerDatabase(TableMapping: Dictionary of [Integer, Integer])
    begin
    end;

    procedure BackupTablesPerDatabase()
    var
        TableMapping: Dictionary of [Integer, Integer];
        SourceTableId: Integer;
    begin
        OnGetTablesToBackupPerDatabase(TableMapping);
        foreach SourceTableId in TableMapping.Keys() do
            BackupTable(SourceTableId, TableMapping.Get(SourceTableId));
    end;

    procedure BackupTablesPerCompany()
    var
        TableMapping: Dictionary of [Integer, Integer];
        SourceTableId: Integer;
    begin
        OnGetTablesToBackupPerCompany(TableMapping);
        foreach SourceTableId in TableMapping.Keys() do
            BackupTable(SourceTableId, TableMapping.Get(SourceTableId));
    end;

    local procedure BackupTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        I: Integer;
    begin
        SourceRecordRef.Open(SourceTableId);
        if not SourceRecordRef.FindFirst() then
            exit;

        repeat
            CLEAR(TargetRecordRef);
            TargetRecordRef.Open(TargetTableId);
            for I := 1 to TargetRecordRef.FieldCount() do begin
                TargetFieldRef := TargetRecordRef.FieldIndex(I);
                if Format(TargetFieldRef.Class()) <> 'Normal' then
                    Error(OnlyNormalFieldsAreSupportedErr);
                SourceFieldRef := SourceRecordRef.Field(TargetFieldRef.Number);
                TargetFieldRef.Value := SourceFieldRef.Value();
            end;

            TargetRecordRef.Insert();
        until SourceRecordRef.Next() = 0;
    end;

    var
        OnlyNormalFieldsAreSupportedErr: Label 'Only normal fields are supported for Backup table.';
}