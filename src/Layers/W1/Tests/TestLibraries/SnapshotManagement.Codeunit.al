codeunit 130013 "Snapshot Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempSnapshot: Record Snapshot temporary;
        BackupManagement: Codeunit "Backup Management";
        BackupStorage: Codeunit "Backup Storage";
        BackupSubscriber: Codeunit "Backup Subscriber";
        IsEnabled: Boolean;
        RestoringSnapshotNo: Integer;
        SnapshotNotEnabled: Label 'Snapshot functionality is not enabled.';
        SnapshotAlreadyExists: Label 'Snapshot %1 already exists.';
        EmptyStringNotAllowed: Label 'Empty string is not a valid snapshot name.';
        TooManySnapshots: Label 'Cannot create more than %1 snapshots.';
        MixingSnapshotTypes: Label 'Cannot mix incremental and non-incremental snapshot types.';

    [Scope('OnPrem')]
    procedure Clear()
    begin
        TempSnapshot.Reset();
        TempSnapshot.SetCurrentKey("Incremental Index");
        if TempSnapshot.FindLast() then
            repeat
                DeleteSnapshot(TempSnapshot."Snapshot No.");
            until TempSnapshot.Next(-1) = 0;

        RestoringSnapshotNo := 0
    end;

    [Scope('OnPrem')]
    procedure DeleteSnapshot(SnapshotNo: Integer)
    begin
        BackupStorage.DeleteBackupNo(SnapshotNo);
        TempSnapshot.Get(SnapshotNo);
        TempSnapshot.Delete();
    end;

    [Scope('OnPrem')]
    procedure RestoreSnapshot(SnapshotNo: Integer)
    var
        TempSnapshot2: Record Snapshot temporary;
    begin
        if not IsEnabled then
            Error(SnapshotNotEnabled);

        TempSnapshot.Get(SnapshotNo);
        if TempSnapshot.Incremental then begin
            TempSnapshot.Reset();
            TempSnapshot.Get(SnapshotNo);
            TempSnapshot.SetCurrentKey("Incremental Index");
            TempSnapshot.SetFilter("Incremental Index", '>=%1', TempSnapshot."Incremental Index");
            TempSnapshot.FindSet();

            // Store relevant snapshots in local buffer, so filters are not overwritten by ChangeLog()
            repeat
                TempSnapshot2.Init();
                TempSnapshot2.Copy(TempSnapshot);
                TempSnapshot2.Insert();
            until TempSnapshot.Next() = 0;

            TempSnapshot2.Reset();
            TempSnapshot2.SetCurrentKey("Incremental Index");
            TempSnapshot2.Find('+');
            repeat
                RestoringSnapshotNo := TempSnapshot2."Snapshot No.";
                BackupStorage.RestoreTaintedTables(TempSnapshot2."Snapshot No.", true);
                RestoringSnapshotNo := 0;
                if TempSnapshot2."Snapshot No." <> SnapshotNo then
                    DeleteSnapshot(TempSnapshot2."Snapshot No.");
            until TempSnapshot2.Next(-1) = 0;
        end else begin
            RestoringSnapshotNo := SnapshotNo;
            BackupStorage.RestoreTaintedTables(SnapshotNo, false);
            RestoringSnapshotNo := 0
        end;
    end;

    [Scope('OnPrem')]
    procedure InitSnapshot(SnapshotName: Text[30]; Incremental: Boolean): Integer
    var
        NextIndex: Integer;
    begin
        if not IsEnabled then
            Error(SnapshotNotEnabled);

        if SnapshotExists(SnapshotName) then
            Error(SnapshotAlreadyExists, SnapshotName);

        if SnapshotName = '' then
            Error(EmptyStringNotAllowed);

        TempSnapshot.Reset();
        TempSnapshot.SetRange(Incremental, not Incremental);
        if TempSnapshot.FindFirst() then
            Error(MixingSnapshotTypes);

        NextIndex := 1;
        TempSnapshot.Reset();
        TempSnapshot.SetCurrentKey("Incremental Index");
        if TempSnapshot.FindLast() then
            NextIndex := TempSnapshot."Incremental Index" + 1;

        TempSnapshot.Reset();
        TempSnapshot.Init();
        TempSnapshot."Snapshot No." := GetAvailableSnapshotNo();
        TempSnapshot."Snapshot Name" := SnapshotName;
        TempSnapshot.Description := '';
        TempSnapshot.Incremental := Incremental;
        TempSnapshot."Incremental Index" := NextIndex;
        TempSnapshot.Insert();
        exit(TempSnapshot."Snapshot No.")
    end;

    [Scope('OnPrem')]
    procedure SnapshotNoExists(SnapshotNo: Integer): Boolean
    begin
        TempSnapshot.Reset();
        TempSnapshot.SetRange("Snapshot No.", SnapshotNo);
        exit(TempSnapshot.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure SnapshotExists(SnapshotName: Text[30]): Boolean
    begin
        TempSnapshot.Reset();
        TempSnapshot.SetRange("Snapshot Name", SnapshotName);
        exit(TempSnapshot.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure HasAvailableSnapshotNo(): Boolean
    var
        i: Integer;
    begin
        for i := 1 to BackupStorage.MaxBackups() do
            if not SnapshotNoExists(i) then
                exit(true);

        exit(false)
    end;

    [Scope('OnPrem')]
    procedure SnapshotOverflowErrorMessage(): Text
    begin
        exit(StrSubstNo(TooManySnapshots, BackupStorage.MaxBackups()))
    end;

    [Scope('OnPrem')]
    procedure GetAvailableSnapshotNo(): Integer
    var
        i: Integer;
    begin
        for i := 1 to BackupStorage.MaxBackups() do
            if not SnapshotNoExists(i) then
                exit(i);

        Error(SnapshotOverflowErrorMessage());
    end;

    [Scope('OnPrem')]
    procedure SnapshotNameToNo(SnapshotName: Text[30]): Integer
    begin
        TempSnapshot.Reset();
        TempSnapshot.SetRange("Snapshot Name", SnapshotName);
        if TempSnapshot.FindFirst() then
            exit(TempSnapshot."Snapshot No.");

        exit(0)
    end;

    [Scope('OnPrem')]
    procedure SetEnabled(Enabled: Boolean)
    begin
        UnbindSubscription(BackupSubscriber);
        if Enabled then begin
            BindSubscription(BackupSubscriber);
            BackupManagement.CheckSubscribtionToCOD1();
        end;

        IsEnabled := Enabled;
    end;

    [Scope('OnPrem')]
    procedure GetEnabledFlag(): Boolean
    begin
        exit(IsEnabled);
    end;

    [Scope('OnPrem')]
    procedure ChangeLog(TableID: Integer)
    begin
        if not IsEnabled then
            exit;

        if not BackupStorage.GetDatabaseTableTriggerSetup(TableID) then
            exit;

        // Incremental snapshots
        TempSnapshot.Reset();
        TempSnapshot.SetCurrentKey("Incremental Index");
        if TempSnapshot.FindLast() then
            if TempSnapshot.Incremental then begin
                if TempSnapshot."Snapshot No." <> RestoringSnapshotNo then
                    if not BackupStorage.BackupTableIsTainted(TempSnapshot."Snapshot No.", TableID) then
                        BackupStorage.TaintTable(TempSnapshot."Snapshot No.", TableID, RestoringSnapshotNo <> 0);

                exit;
            end;

        // Full snapshots
        // Backup in all snapshots (unless one of them is restoring)
        TempSnapshot.Reset();
        TempSnapshot.SetCurrentKey("Snapshot No.");
        if TempSnapshot.FindSet() then
            repeat
                if TempSnapshot."Snapshot No." <> RestoringSnapshotNo then
                    if not BackupStorage.BackupTableIsTainted(TempSnapshot."Snapshot No.", TableID) then
                        BackupStorage.TaintTable(TempSnapshot."Snapshot No.", TableID, RestoringSnapshotNo <> 0)
                    else
                        if RestoringSnapshotNo = 0 then
                            BackupStorage.ClearImplicitTaint(TempSnapshot."Snapshot No.", TableID);
            until TempSnapshot.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure IsEmpty(SnapshotNo: Integer): Boolean
    begin
        exit(BackupStorage.IsEmpty(SnapshotNo));
    end;

    [Scope('OnPrem')]
    procedure IsRestoring(): Boolean
    begin
        exit(RestoringSnapshotNo <> 0)
    end;

    [Scope('OnPrem')]
    procedure BackupTableRowCount(SnapshotNo: Integer; TableNo: Integer): Integer
    begin
        exit(BackupStorage.BackupTableRowCount(SnapshotNo, TableNo))
    end;

    [Scope('OnPrem')]
    procedure ListSnapshots(var TempSnapshot2: Record Snapshot temporary)
    begin
        TempSnapshot.Reset();
        if TempSnapshot.FindSet() then
            repeat
                TempSnapshot2.Init();
                TempSnapshot2.Copy(TempSnapshot);
                TempSnapshot2.Insert();
            until TempSnapshot.Next() = 0
    end;

    [Scope('OnPrem')]
    procedure ListTables(var TempTaintedTable: Record "Tainted Table" temporary)
    begin
        BackupStorage.GetTaintedTables(TempTaintedTable)
    end;

    [Scope('OnPrem')]
    procedure SetDescription(SnapshotNo: Integer; Description: Text[250])
    begin
        TempSnapshot.Get(SnapshotNo);
        TempSnapshot.Description := Description;
        TempSnapshot.Modify();
    end;
}

