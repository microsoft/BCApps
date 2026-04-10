codeunit 130015 "Backup Subscriber"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        BackupManagement: Codeunit "Backup Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure OnDatabaseInsertHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure OnDatabaseModifyHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseDelete', '', false, false)]
    local procedure OnDatabaseDeleteHandler(RecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseRename', '', false, false)]
    local procedure OnDatabaseRenameHandler(RecRef: RecordRef; xRecRef: RecordRef)
    begin
        BackupManagement.ChangeLog(RecRef.Number);
    end;
}

