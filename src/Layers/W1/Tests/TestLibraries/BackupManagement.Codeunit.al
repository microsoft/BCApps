codeunit 130011 "Backup Management"
{
    // This codeunit contains a number of function triggers to create and restore backups in temporary tables.
    // Backups can be made and restored for individual tables, a set of tables, or the all tables in the database.
    // 
    // By default backups only exists for the lifetime of a client session (as long as connected to the same database).
    // On the classic client it is possible to enable persitent backups (in a seperate company) using SetUsePersistentBackup(TRUE).
    // Not anymore, as a result of removal of ISSERVICETIER.

    SingleInstance = true;

    trigger OnRun()
    var
        Bool: Boolean;
    begin
        IsEnabled := true;

        SetEnabled(Confirm(ConfirmEnable));

        if Confirm(Question) then begin
            Bool := IsEnabled;
            SetEnabled(true);
            DefaultFixture();
            SetEnabled(Bool)
        end
    end;

    var
        TempTableMetadata: Record "Table Metadata" temporary;
        BackupStorage: Codeunit "Backup Storage";
        BackupSubscriber: Codeunit "Backup Subscriber";
        BackupRegister: array[7] of Text[30];
        IsNotSubscribedToCOD1Err: Label 'Codeunit 130011 Backup Management is not subscribed to COD1.OnAfterGetDatabaseTableTriggerSetup event.';
        IsNotSubscribedToCOD1OnDatabaseEventsErr: Label 'Codeunit 130015 Backup Subscriber is not subscribed to COD1.OnAfterOnDatabase* events.';
        BackupAlreadyExists: Label 'Backup %1 already exists.';
        EmptyStringNotValid: Label 'Empty string is not a valid backup name.';
        BackupNotFoundError: Label 'Could not find backup %1.';
        Initialized: Boolean;
        SharedFixtureFilter: Text[1024];
        IsEnabled: Boolean;
        TooManyBackups: Label 'Cannot create more than %1 backups.';
        ConfirmEnable: Label 'Enable default fixture restore?';
        DatabaseName: Text[250];
        ExecutionFlag: Boolean;
        IsRestoring: Boolean;
        Question: Label 'Restore default fixture now?';

    [Scope('OnPrem')]
    procedure DefaultFixture()
    begin
        // Restore all tables that have changed since the beginning of the (client) session
        // Use SetEnabled(TRUE) to enable this functionality

        ExecutionFlag := true;

        if not IsEnabled then
            exit;

        Initialize();

        IsRestoring := true;
        BackupStorage.RestoreTaintedTables(BackupNameToNo(DefaultFixtureName()), true);
        IsRestoring := false;
    end;

    [Scope('OnPrem')]
    procedure BackupSharedFixture("Filter": Text[1024])
    begin
        // Backup the tables within the filter as a shared fixture to a reserved backup.

        Initialize();
        BackupRegister[2] := SharedFixtureName();

        // Set shared fixture name and filter
        SharedFixtureFilter := Filter;

        TempTableMetadata.SetFilter(ID, SharedFixtureFilter);
        if TempTableMetadata.FindSet() then
            repeat
                DeleteTableFromBackupNo(2, TempTableMetadata.ID);
                BackupTable(SharedFixtureName(), TempTableMetadata.ID)
            until TempTableMetadata.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure RestoreSharedFixture()
    begin
        // Restore the tables from the shared fixture

        // If no shared fixture backup has been created: exit
        if SharedFixtureName() = '' then
            exit;

        TempTableMetadata.SetFilter(ID, SharedFixtureFilter);
        if TempTableMetadata.FindSet() then
            repeat
                BackupStorage.RestoreTableFromBackupNo(2, CompanyName, TempTableMetadata.ID)
            until TempTableMetadata.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure BackupDatabase(Backup: Text[30])
    var
        BackupNo: Integer;
    begin
        // Create a backup of the current database named <Backup>.
        // An error is thrown if backup <Backup> already exists.

        Initialize();

        BackupNo := InitBackup(Backup);
        TempTableMetadata.Reset();

        if TempTableMetadata.FindSet() then
            repeat
                BackupStorage.BackupTableInBackupNo(BackupNo, CompanyName, TempTableMetadata.ID);
            until TempTableMetadata.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure RestoreDatabase(Backup: Text[30])
    var
        ProgressDialog: Dialog;
        WindowsUpdateTime: Time;
        BackupNo: Integer;
        Increment: Decimal;
        Progress: Decimal;
    begin
        // Restore the backup named <Backup>.
        // An error is thrown if backup <Backup> does not exist.
        // Throw an error if backup <Backup> does not exist.

        BackupNo := GetBackupNo(Backup);

        if BackupNo = 0 then
            Error(BackupNotFoundError, Backup);

        WindowsUpdateTime := Time;
        ProgressDialog.Open('Restoring database from memory@1@@@@\Table#2########');
        TempTableMetadata.Reset();

        Increment := 9998 / (TempTableMetadata.Count - 1);
        if TempTableMetadata.FindSet() then
            repeat
                if Abs(Time - WindowsUpdateTime) > 1000 then begin
                    ProgressDialog.Update(1, Round(Progress, 1));
                    ProgressDialog.Update(2, TempTableMetadata.ID);
                    WindowsUpdateTime := Time;
                end;
                Progress += Increment;
                BackupStorage.RestoreTableFromBackupNo(BackupNo, CompanyName, TempTableMetadata.ID)
            until TempTableMetadata.Next() = 0;
        ProgressDialog.Close();

        BackupStorage.SetWorkDate();
    end;

    [Scope('OnPrem')]
    procedure BackupTable(Backup: Text[30]; TableNo: Integer)
    var
        BackupNo: Integer;
    begin
        // Backup table <TableNo> in backup <Backup>.
        // Initialize a backup named <Backup> if backup <Backup> does not exist.
        // If a backup of table <TableNo> already exists in backup <Backup>
        // nothing happens.

        Initialize();

        BackupNo := GetBackupNo(Backup);
        if BackupNo = 0 then
            BackupNo := InitBackup(Backup);

        BackupStorage.BackupTableInBackupNo(BackupNo, CompanyName, TableNo)
    end;

    [Scope('OnPrem')]
    procedure RestoreTable(Backup: Text[30]; TableNo: Integer)
    var
        BackupNo: Integer;
    begin
        // Restore table <TableNo> from backup <Backup>
        // If no backup of table <TableNo> exists in backup <Backup>,
        // the table is emptied.
        // Throw an error if backup <Backup> does not exist.

        BackupNo := GetBackupNo(Backup);

        if BackupNo = 0 then
            Error(BackupNotFoundError, Backup);

        BackupStorage.RestoreTableFromBackupNo(BackupNo, CompanyName, TableNo)
    end;

    [Scope('OnPrem')]
    procedure DeleteAll()
    var
        i: Integer;
    begin
        // Delete all backups (including persistent backups).
        // never delete the default and shared fixture backups
        for i := 3 to MaxBackups() do
            DeleteBackupNo(i);
    end;

    [Scope('OnPrem')]
    procedure DeleteBackup(Backup: Text[30])
    begin
        // Delete backup <Backup> (including its persisted backup).
        DeleteBackupNo(BackupNameToNo(Backup));
    end;

    [Scope('OnPrem')]
    procedure DeleteTable(Backup: Text[30]; TableNo: Integer)
    begin
        // Delete table <TableNo> from backup <Backup> (both in-memory and persisted backup).

        DeleteTableFromBackupNo(BackupNameToNo(Backup), TableNo)
    end;

    [Scope('OnPrem')]
    procedure BackupExists(Backup: Text[30]): Boolean
    begin
        exit(BackupNoExists(GetBackupNo(Backup)))
    end;

    local procedure DeleteBackupNo(BackupNo: Integer)
    begin
        // Delete backup <BackupNo>.
        // If backup <BackupNo> does not exist, nothing happens.

        if BackupNoExists(BackupNo) then begin
            BackupStorage.DeleteBackupNo(BackupNo);
            BackupRegister[BackupNo] := ''
        end
    end;

    local procedure DeleteTableFromBackupNo(BackupNo: Integer; TableNo: Integer)
    var
        BackupRecordRef: RecordRef;
    begin
        // We delete a table backup by deleting all records in it.
        // Note that for performance reasons we will not rearrange the backup array.

        if BackupNoExists(BackupNo) then
            if BackupStorage.GetTableBackup(BackupNo, TableNo, BackupRecordRef) then
                BackupRecordRef.DeleteAll();
    end;

    local procedure GetBackupNo(Backup: Text[30]) Result: Integer
    begin
        Result := BackupNameToNo(Backup);
    end;

    [Scope('OnPrem')]
    procedure BackupNameToNo(Backup: Text[30]): Integer
    var
        i: Integer;
    begin
        for i := 1 to MaxBackups() do
            if BackupRegister[i] = Backup then
                exit(i);

        exit(0)
    end;

    local procedure InitBackup(Backup: Text[30]) Result: Integer
    begin
        if BackupExists(Backup) then
            Error(BackupAlreadyExists, Backup);

        if Backup = '' then
            Error(EmptyStringNotValid);

        if Backup = DefaultFixtureName() then
            Result := 1
        else
            Result := GetAvailableBackupNo();
        BackupRegister[Result] := Backup;
    end;

    local procedure GetAvailableBackupNo(): Integer
    var
        i: Integer;
    begin
        // First two elements are reserved for the default and shared fixture backups
        for i := 3 to MaxBackups() do
            if BackupRegister[i] = '' then
                exit(i);

        Error(TooManyBackups, MaxBackups() - 2)
    end;

    local procedure BackupNoExists(BackupNo: Integer): Boolean
    begin
        if not (BackupNo in [1 .. MaxBackups()]) then
            exit(false);

        exit(BackupRegister[BackupNo] <> '')
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        TableMetadata: Record "Table Metadata";
    begin
        if Initialized then
            exit;

        TableMetadata.SetFilter(ID, TableFilter());
        TableMetadata.SetRange(DataIsExternal, false);
        TableMetadata.SetFilter(ObsoleteState, '<>%1', TableMetadata.ObsoleteState::Removed);
        TableMetadata.FindSet();
        repeat
            TempTableMetadata.Copy(TableMetadata);
            TempTableMetadata.Insert();
        until TableMetadata.Next() = 0;

        InitBackup(DefaultFixtureName());

        Initialized := true
    end;

    local procedure TableFilter(): Text[1024]
    begin
        exit('1..471|473..99999|150000..1999999999|2000000080')
    end;

    [Scope('OnPrem')]
    procedure DefaultFixtureName(): Text[30]
    begin
        exit('Default Fixture')
    end;

    [Scope('OnPrem')]
    procedure SharedFixtureName(): Text[30]
    begin
        exit('Shared Fixture')
    end;

    local procedure MaxBackups(): Integer
    begin
        exit(ArrayLen(BackupRegister))
    end;

    [Scope('OnPrem')]
    procedure SetEnabled(Enabled: Boolean)
    begin
        UnbindSubscription(BackupSubscriber);
        if Enabled then begin
            BindSubscription(BackupSubscriber);
            CheckSubscribtionToCOD1();
        end;

        IsEnabled := Enabled;
    end;

    [Scope('OnPrem')]
    procedure DeleteAllData()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        TableMetadata: Record "Table Metadata";
        RecRef: RecordRef;
    begin
        // delete retention policy setup first to avoid errors
        RetentionPolicySetup.DeleteAll(true);

        // delete from all objects
        TableMetadata.SetFilter(ID, '1..99999|150000..1999999999|2000000080'); // exclude System tables and test data
        TableMetadata.SetFilter(ObsoleteState, '<>%1', TableMetadata.ObsoleteState::Removed);
        TableMetadata.SetRange(DataIsExternal, false);

        if TableMetadata.FindSet() then
            repeat
                // open a record ref to the table
                RecRef.Open(TableMetadata.ID);
                RecRef.DeleteAll();
                RecRef.Close();
            until TableMetadata.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure GetDatabase(): Text[250]
    var
        ActiveSession: Record "Active Session";
    begin
        if DatabaseName = '' then begin
            ActiveSession.Get(ServiceInstanceId(), SessionId());
            DatabaseName := ActiveSession."Database Name";
        end;

        exit(DatabaseName);
    end;

    [Scope('OnPrem')]
    procedure ClearExecutionFlag()
    begin
        ExecutionFlag := false;
    end;

    [Scope('OnPrem')]
    procedure GetExecutionFlag(): Boolean
    begin
        exit(ExecutionFlag);
    end;

    local procedure GetDatabaseTableTriggerSetup(TableID: Integer): Boolean
    begin
        exit(BackupStorage.GetDatabaseTableTriggerSetup(TableID))
    end;

    [Scope('OnPrem')]
    procedure ChangeLog(TableID: Integer)
    var
        SnapshotMgt: Codeunit "Snapshot Management";
        BackupNo: Integer;
    begin
        SnapshotMgt.ChangeLog(TableID);

        if IsRestoring or not IsEnabled then
            exit;

        if not BackupExists(DefaultFixtureName()) then
            Initialize();

        BackupNo := BackupNameToNo(DefaultFixtureName());

        if BackupStorage.BackupTableIsTainted(BackupNo, TableID) then
            exit;

        BackupTable(DefaultFixtureName(), TableID);

        BackupStorage.TaintTable(BackupNo, TableID, false);
    end;

    [Scope('OnPrem')]
    procedure CheckSubscribtionToCOD1()
    begin
        if not IsSubscribedToCOD1TableTriggerSetup() then
            Error(IsNotSubscribedToCOD1Err);
        if not IsSubscribedToCOD1OnDatabaseEvents() then
            Error(IsNotSubscribedToCOD1OnDatabaseEventsErr);
    end;

    local procedure IsSubscribedToCOD1TableTriggerSetup(): Boolean
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetRange("Subscriber Codeunit ID", CODEUNIT::"Backup Management");
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetRange("Publisher Object ID", CODEUNIT::GlobalTriggerManagement);
        EventSubscription.SetFilter("Published Function", 'OnAfterGetDatabaseTableTriggerSetup');
        exit(not EventSubscription.IsEmpty);
    end;

    local procedure IsSubscribedToCOD1OnDatabaseEvents(): Boolean
    var
        EventSubscription: Record "Event Subscription";
    begin
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetRange("Publisher Object ID", CODEUNIT::GlobalTriggerManagement);
        EventSubscription.SetRange("Subscriber Codeunit ID", CODEUNIT::"Backup Subscriber");
        EventSubscription.SetRange("Subscriber Instance", 'Manual');
        EventSubscription.SetRange("Active Manual Instances", 1);
        EventSubscription.SetFilter("Published Function", 'OnAfterOnDatabase*');
        exit(EventSubscription.Count = 4);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterGetDatabaseTableTriggerSetup', '', true, true)]
    local procedure OnAfterGetDatabaseTableTriggerSetupHandler(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        OnDatabaseInsert := GetDatabaseTableTriggerSetup(TableId);
        OnDatabaseModify := OnDatabaseInsert;
        OnDatabaseDelete := OnDatabaseInsert;
        OnDatabaseRename := OnDatabaseInsert;
    end;
}

