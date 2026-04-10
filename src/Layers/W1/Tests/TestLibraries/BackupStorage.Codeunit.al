codeunit 130012 "Backup Storage"
{
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempTaintedTable: Record "Tainted Table" temporary;
        RecordRefBackups: array[20, 1000] of RecordRef;
        TableBackupsCurrentIndices: array[20] of Integer;
        BackupNotFoundError: Label 'Could not find backup no %1.';

    [Scope('OnPrem')]
    procedure DeleteAll()
    var
        i: Integer;
    begin
        for i := 1 to MaxBackups() do
            DeleteBackupNo(i);
    end;

    [Scope('OnPrem')]
    procedure DeleteBackupNo(BackupNo: Integer)
    begin
        // Delete backup <BackupNo>.
        // If backup <BackupNo> does not exist, nothing happens.

        if BackupNoExists(BackupNo) then begin
            Clear(RecordRefBackups[BackupNo]);
            TableBackupsCurrentIndices[BackupNo] := 0;
            TempTaintedTable.SetRange("Snapshot No.", BackupNo);
            TempTaintedTable.DeleteAll();
        end
    end;

    [Scope('OnPrem')]
    procedure BackupTableIsTainted(BackupNo: Integer; TableID: Integer): Boolean
    begin
        exit(TempTaintedTable.Get(BackupNo, TableID))
    end;

    [Scope('OnPrem')]
    procedure TaintTable(BackupNo: Integer; TableID: Integer; Implicit: Boolean)
    begin
        BackupTableInBackupNo(BackupNo, CompanyName, TableID);

        TempTaintedTable.Init();
        TempTaintedTable."Snapshot No." := BackupNo;
        TempTaintedTable."Table No." := TableID;
        TempTaintedTable."Implicit Taint" := Implicit;
        TempTaintedTable.Insert();
    end;

    [Scope('OnPrem')]
    procedure ClearImplicitTaint(BackupNo: Integer; TableID: Integer)
    begin
        TempTaintedTable.Get(BackupNo, TableID);
        TempTaintedTable."Implicit Taint" := false;
        TempTaintedTable.Modify();
    end;

    [Scope('OnPrem')]
    procedure RestoreTaintedTables(BackupNo: Integer; Clear: Boolean)
    var
        TempTaintedTable2: Record "Tainted Table" temporary;
    begin
        if not BackupNoExists(BackupNo) then
            Error(BackupNotFoundError, BackupNo);

        // Copy list of tables to restore to local variable, as TempTaintedTable may be changed from the global
        // trigger when restoring a table.
        TempTaintedTable.Reset();
        TempTaintedTable.SetRange("Snapshot No.", BackupNo);
        if TempTaintedTable.FindSet() then
            repeat
                TempTaintedTable2.Init();
                TempTaintedTable2.Copy(TempTaintedTable);
                TempTaintedTable2.Insert();
            until TempTaintedTable.Next() = 0;

        if TempTaintedTable2.FindSet() then
            repeat
                RestoreTableFromBackupNo(BackupNo, CompanyName, TempTaintedTable2."Table No.");
            until TempTaintedTable2.Next() = 0;

        SetWorkDate();

        if Clear then begin
            TempTaintedTable.SetRange("Snapshot No.", BackupNo);
            TempTaintedTable.DeleteAll();
            TableBackupsCurrentIndices[BackupNo] := 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTaintedTables(var TempTaintedTable2: Record "Tainted Table" temporary)
    begin
        TempTaintedTable.Reset();
        if TempTaintedTable.FindSet() then
            repeat
                TempTaintedTable2.Init();
                TempTaintedTable2.Copy(TempTaintedTable);
                TempTaintedTable2.Insert();
            until TempTaintedTable.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure BackupTableInBackupNo(BackupNo: Integer; CompanyName: Text[1024]; TableNo: Integer)
    var
        RecordRef: RecordRef;
        BackupRecordRef: RecordRef;
    begin
        // Backup table <TableNo> in company <ComanyName> to backup <BackupNo>.
        // If a non-empty backup of table <TableNo> already exists in backup <BackupNo>,
        // nothing happens.
        // if table <TableNo> is external, nothing happens
        if not IsSupportedTableType(TableNo) then
            exit;

        // If table <TableNo> is empty, nothing happens.
        RecordRef.Open(TableNo, false, CompanyName);
        // we only backup non-empty tables
        if not RecordRef.FindSet() then
            exit;

        if GetTableBackup(BackupNo, TableNo, BackupRecordRef) then begin
            // Table has been backed up before: only continue if it is empty.
            // This implies that the table backup was deleted and we don't need to use a new index
            if BackupRecordRef.FindFirst() then
                // ... do nothing when backup is not empty
                exit
        end else
            BackupRecordRef.Open(TableNo, true);

        repeat
            CopyFields(RecordRef, BackupRecordRef);
            BackupRecordRef.Insert();
        until RecordRef.Next() = 0;
        InsertTableBackup(BackupNo, BackupRecordRef)
    end;

    [Scope('OnPrem')]
    procedure RestoreTableFromBackupNo(BackupNo: Integer; CompanyName: Text[1024]; TableNo: Integer)
    var
        RecordRef: RecordRef;
        BackupRecordRef: RecordRef;
        RecordsRemoved: Boolean;
        BackupRecordCount: Integer;
    begin
        // Restore table <TableNo> in company <CompanyName> from backup <BackupNo>.
        // If table <TableNo> is not supported it is ignored.
        if not IsSupportedTableType(TableNo) then
            exit;

        // If a backup of table <TableNo> does not exists in backup <BackupNo>
        // table <TableNo> is emptied.
        RecordRef.Open(TableNo, false, CompanyName);
        // if the table has not been backed up: empty table, exit
        if not GetTableBackup(BackupNo, TableNo, BackupRecordRef) then begin
            RecordRef.DeleteAll();
            exit
        end;

        // if the table in the backup is empty: empty table, exit
        if not BackupRecordRef.FindSet() then begin
            RecordRef.DeleteAll();
            exit
        end;

        // if the current table is empty: copy all backed up records, exit
        if not RecordRef.FindFirst() then begin
            repeat
                CopyFields(BackupRecordRef, RecordRef);
                RecordRef.Insert();
            until BackupRecordRef.Next() = 0;

            // It is necessary to explicitly comit changes between tables because these
            // can have auto_incrementing fields. If two tables are modified by the same
            // codeunit this will cause an exception during restore when trying to insert
            // into the second table.
            Commit();
            exit
        end;

        // restore records removed from or modified in the current table since backup-time
        repeat
            if RecordRef.Get(BackupRecordRef.RecordId) then begin
                if not AreEqualRecords(RecordRef, BackupRecordRef) then begin
                    CopyFields(BackupRecordRef, RecordRef);
                    RecordRef.Modify();
                end
            end else begin
                RecordsRemoved := true;
                // restore removed records
                CopyFields(BackupRecordRef, RecordRef);
                RecordRef.Insert();
            end;
            BackupRecordCount += 1
        until BackupRecordRef.Next() = 0;

        // It is necessary to explicitly comit changes between tables because these
        // can have auto_incrementing fields. If two tables are modified by the same
        // codeunit this will cause an exception during restore when trying to insert
        // into the second table.
        Commit();

        // if no records have been removed and the record count has not changed, no records were inserted either
        if not RecordsRemoved then
            if RecordRef.Count = BackupRecordCount then
                exit;

        // delete records inserted in the current table since backup-time
        RecordRef.FindSet();
        repeat
            if not BackupRecordRef.Get(RecordRef.RecordId) then
                RecordRef.Delete();
        until RecordRef.Next() = 0;

        // It is necessary to explicitly comit changes between tables because these
        // can have auto_incrementing fields. If two tables are modified by the same
        // codeunit this will cause an exception during restore when trying to insert
        // into the second table.
        Commit();
    end;

    local procedure AreEqualRecords(var RecordRefLeft: RecordRef; var RecordRefRight: RecordRef): Boolean
    var
        LeftFieldRef: FieldRef;
        RightFieldRef: FieldRef;
        i: Integer;
    begin
        // Records <Left> and <Right> are considered equal when each (Normal) <Left> field has the same value
        // as the <Right> field with the same index.
        // Note that for performance reasons this function does not take into account,
        // whether the two records have the same number of fields.

        for i := 1 to RecordRefLeft.FieldCount do begin
            LeftFieldRef := RecordRefLeft.FieldIndex(i);
            if LeftFieldRef.Class = FieldClass::Normal then begin
                RightFieldRef := RecordRefRight.FieldIndex(i);
                if LeftFieldRef.Value <> RightFieldRef.Value then
                    exit(false)
            end
        end;

        exit(true)
    end;

    [Scope('OnPrem')]
    procedure GetTableBackup(BackupNo: Integer; TableNo: Integer; var RecordRef: RecordRef): Boolean
    var
        i: Integer;
    begin
        // Return the backup of table <TableNo> in backup <BackupNo> in <RecordRef>
        // Return FALSE if no backup of table <TableNo> exists in backup <BackupNo>.

        if TableBackupsCurrentIndices[BackupNo] = 0 then
            exit(false);

        for i := 1 to TableBackupsCurrentIndices[BackupNo] do
            if RecordRefBackups[BackupNo] [i].Number = TableNo then begin
                RecordRef := RecordRefBackups[BackupNo] [i];
                exit(true)
            end;

        exit(false)
    end;

    [Scope('OnPrem')]
    procedure InsertTableBackup(BackupNo: Integer; RecordRef: RecordRef)
    begin
        TableBackupsCurrentIndices[BackupNo] += 1;
        RecordRefBackups[BackupNo] [TableBackupsCurrentIndices[BackupNo]] := RecordRef
    end;

    local procedure CopyFields(RecordRefSource: RecordRef; var RecordRefDestination: RecordRef)
    var
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecordRefSource.FieldCount do begin
            SourceFieldRef := RecordRefSource.FieldIndex(i);
            if SourceFieldRef.Class = FieldClass::Normal then begin
                DestinationFieldRef := RecordRefDestination.FieldIndex(i);
                if SourceFieldRef.Type = FieldType::BLOB then
                    SourceFieldRef.CalcField();
                DestinationFieldRef.Value(SourceFieldRef.Value)
            end;
        end
    end;

    [Scope('OnPrem')]
    procedure BackupNoExists(BackupNo: Integer): Boolean
    begin
        exit(BackupNo in [1 .. MaxBackups()])
    end;

    [Scope('OnPrem')]
    procedure MaxBackups(): Integer
    begin
        exit(ArrayLen(RecordRefBackups, 1))
    end;

    [Scope('OnPrem')]
    procedure IsEmpty(BackupNo: Integer): Boolean
    begin
        TempTaintedTable.Reset();
        TempTaintedTable.SetRange("Snapshot No.", BackupNo);
        exit(not TempTaintedTable.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure BackupTableRowCount(BackupNo: Integer; TableNo: Integer): Integer
    var
        BackupRecordRef: RecordRef;
    begin
        if not GetTableBackup(BackupNo, TableNo, BackupRecordRef) then
            exit(-1);
        exit(BackupRecordRef.Count)
    end;

    [Scope('OnPrem')]
    procedure SetWorkDate()
    var
        GLEntry: Record "G/L Entry";
        OK: Boolean;
    begin
        // Set workdate to date of last transaction or today
        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        OK := true;
        repeat
            GLEntry.SetFilter("G/L Account No.", '>%1', GLEntry."G/L Account No.");
            GLEntry.SetFilter("Posting Date", '>%1', GLEntry."Posting Date");
            if GLEntry.FindFirst() then begin
                GLEntry.SetRange("G/L Account No.", GLEntry."G/L Account No.");
                GLEntry.SetRange("Posting Date");
                GLEntry.FindLast();
            end else
                OK := false
        until not OK;

        if GLEntry."Posting Date" = 0D then
            WorkDate := Today
        else
            WorkDate := NormalDate(GLEntry."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure GetDatabaseTableTriggerSetup(TableID: Integer): Boolean
    begin
        if CompanyName = '' then
            exit(false);

        exit(TableID in [1 .. 99999, 150000 .. 1999999999, 2000000080, 2000000165, 2000000166, 2000000253, 2000000053]);
    end;

    local procedure IsSupportedTableType(TableNo: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if not TableMetadata.Get(TableNo) then
            exit(false);

        if TableMetadata.TableType in [TableMetadata.TableType::CRM, TableMetadata.TableType::ExternalSQL,
                                       TableMetadata.TableType::Exchange, TableMetadata.TableType::MicrosoftGraph]
        then
            exit(false);

        exit(true);
    end;
}

