#if not CLEAN29
namespace Microsoft.Manufacturing.Subcontracting.Migration.Test;

using Microsoft.Manufacturing.Subcontracting.Migration;

codeunit 149957 "IT Subc. Migration Session"
{
    TableNo = "IT Subc. Migration Test Sync";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        SyncEntryNo := Rec."Entry No.";
        ITSubcMigrationSession.SetSyncEntryNo(SyncEntryNo);
        BindSubscription(ITSubcMigrationSession);
        if TryDisableLegacySubcontracting() then
            SetResult(Rec.Status::Succeeded, '')
        else
            SetResult(Rec.Status::Failed, CopyStr(GetLastErrorText(), 1, MaxStrLen(Rec."Error Text")));
    end;

    var
        ITSubcMigrationSession: Codeunit "IT Subc. Migration Session";
        SyncEntryNo: Integer;

    [TryFunction]
    local procedure TryDisableLegacySubcontracting()
    var
#pragma warning disable AL0432
        ITSubcMigration: Codeunit "IT Subc. Migration";
#pragma warning restore AL0432
    begin
        ITSubcMigration.StartDisableLegacySubcontracting(false);
    end;

    internal procedure SetSyncEntryNo(NewSyncEntryNo: Integer)
    begin
        SyncEntryNo := NewSyncEntryNo;
    end;

    local procedure SetResult(NewStatus: Option; ErrorText: Text)
    var
        MigrationTestSync: Record "IT Subc. Migration Test Sync";
    begin
        MigrationTestSync.Get(SyncEntryNo);
        MigrationTestSync.Status := NewStatus;
        MigrationTestSync."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(MigrationTestSync."Error Text"));
        MigrationTestSync.Modify();
        Commit();
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"IT Subc. Migration", OnBeforeLockTables, '', false, false)]
#pragma warning restore AL0432
    local procedure SignalLockBoundary()
    var
        MigrationTestSync: Record "IT Subc. Migration Test Sync";
    begin
        MigrationTestSync.Get(SyncEntryNo);
        MigrationTestSync.Status := MigrationTestSync.Status::"At Lock Boundary";
        MigrationTestSync.Modify();
        Commit();
    end;
}
#endif
