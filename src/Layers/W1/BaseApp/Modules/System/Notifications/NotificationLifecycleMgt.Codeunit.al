namespace System.Environment.Configuration;

codeunit 1511 "Notification Lifecycle Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationSentCategoryTxt: Label 'AL Notification Sent', Locked = true;
        NotificationSentTelemetryMsg: Label 'A notification with ID %1 was sent for a record of table %2.', Locked = true;
        SubscribersDisabled: Boolean;

    procedure SendNotification(NotificationToSend: Notification; RecId: RecordID)
    begin
        if IsNullGuid(NotificationToSend.Id) then
            NotificationToSend.Id := CreateGuid();

        NotificationToSend.Send();
        OnAfterNotificationSent(NotificationToSend, RecId.TableNo);
        CreateNotificationContext(NotificationToSend.Id, RecId);
    end;

    procedure SendNotificationWithAdditionalContext(NotificationToSend: Notification; RecId: RecordID; AdditionalContextId: Guid)
    begin
        if IsNullGuid(NotificationToSend.Id) then
            NotificationToSend.Id := CreateGuid();

        OnBeforeSendNotification(NotificationToSend, RecId, AdditionalContextId);
        NotificationToSend.Send();
        OnAfterNotificationSent(NotificationToSend, RecId.TableNo);
        CreateNotificationContextWithAdditionalContext(NotificationToSend.Id, RecId, AdditionalContextId);
    end;

    procedure RecallNotificationsForRecord(RecId: RecordID; HandleDelayedInsert: Boolean)
    var
        TempNotificationContextToRecall: Record "Notification Context" temporary;
    begin
        if GetNotificationsForRecord(RecId, TempNotificationContextToRecall, HandleDelayedInsert) then
            RecallNotifications(TempNotificationContextToRecall);
    end;

    procedure RecallNotificationsForRecordWithAdditionalContext(RecId: RecordID; AdditionalContextId: Guid; HandleDelayedInsert: Boolean)
    var
        TempNotificationContextToRecall: Record "Notification Context" temporary;
    begin
        if GetNotificationsForRecordWithAdditionalContext(RecId, AdditionalContextId, TempNotificationContextToRecall, HandleDelayedInsert) then
            RecallNotifications(TempNotificationContextToRecall);
    end;

    procedure RecallAllNotifications()
    begin
        TempNotificationContext.Reset();
        if TempNotificationContext.FindSet() then
            RecallNotifications(TempNotificationContext);
    end;

    procedure GetTmpNotificationContext(var TempNotificationContextOut: Record "Notification Context" temporary)
    begin
        TempNotificationContext.Reset();
        TempNotificationContextOut.Copy(TempNotificationContext, true);
    end;

    procedure SetRecordID(RecId: RecordID)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(RecId.TableNo);
        UpdateRecordIDHandleDelayedInsert(RecRef.RecordId, RecId, false);
    end;

    [TryFunction]
    local procedure TryFctThrowsErrorIfRecordExists(RecId: RecordID; var Exists: Boolean)
    var
        RecRef: RecordRef;
    begin
        // If record exists, in some cases RecRef.GET(RecId) throws an error
        Exists := RecRef.Get(RecId);
    end;

    local procedure UpdateRecordIDHandleDelayedInsert(CurrentRecId: RecordID; NewRecId: RecordID; HandleDelayedInsert: Boolean)
    var
        TempNotificationContextToUpdate: Record "Notification Context" temporary;
        Exists: Boolean;
    begin
        if HandleDelayedInsert then begin
            if not TryFctThrowsErrorIfRecordExists(NewRecId, Exists) then
                Exists := true;

            if not Exists then
                exit;
        end;

        if GetNotificationsForRecord(CurrentRecId, TempNotificationContextToUpdate, HandleDelayedInsert) then
            repeat
                TempNotificationContextToUpdate."Record ID" := NewRecId;
                TempNotificationContextToUpdate.Modify(true);
            until TempNotificationContextToUpdate.Next() = 0
    end;

    procedure UpdateRecordID(CurrentRecId: RecordID; NewRecId: RecordID)
    begin
        UpdateRecordIDHandleDelayedInsert(CurrentRecId, NewRecId, true);
    end;

    procedure GetNotificationsForRecord(RecId: RecordID; var TempNotificationContextOut: Record "Notification Context" temporary; HandleDelayedInsert: Boolean): Boolean
    begin
        TempNotificationContext.Reset();
        GetUsableRecordId(RecId, HandleDelayedInsert);
        TempNotificationContext.SetRange("Record ID", RecId);
        TempNotificationContextOut.Copy(TempNotificationContext, true);
        exit(TempNotificationContextOut.FindSet());
    end;

    procedure GetNotificationsForRecordWithAdditionalContext(RecId: RecordID; AdditionalContextId: Guid; var TempNotificationContextOut: Record "Notification Context" temporary; HandleDelayedInsert: Boolean): Boolean
    begin
        TempNotificationContext.Reset();
        GetUsableRecordId(RecId, HandleDelayedInsert);
        TempNotificationContext.SetRange("Record ID", RecId);
        TempNotificationContext.SetRange("Additional Context ID", AdditionalContextId);
        TempNotificationContextOut.Copy(TempNotificationContext, true);
        exit(TempNotificationContextOut.FindSet());
    end;

    local procedure CreateNotificationContext(NotificationId: Guid; RecId: RecordID)
    begin
        DeleteAlreadyRegisteredNotificationBeforeInsert(NotificationId);
        TempNotificationContext.Init();
        TempNotificationContext."Notification ID" := NotificationId;
        if GetUsableRecordId(RecId, true) then
            TempNotificationContext."Record ID" := RecId;
        TempNotificationContext.Insert(true);

        OnAfterInsertNotificationContext(TempNotificationContext);
    end;

    local procedure CreateNotificationContextWithAdditionalContext(NotificationId: Guid; RecId: RecordID; AdditionalContextId: Guid)
    begin
        DeleteAlreadyRegisteredNotificationBeforeInsert(NotificationId);
        TempNotificationContext.Init();
        TempNotificationContext."Notification ID" := NotificationId;
        if GetUsableRecordId(RecId, true) then
            TempNotificationContext."Record ID" := RecId;
        TempNotificationContext."Additional Context ID" := AdditionalContextId;
        TempNotificationContext.Insert(true);

        OnAfterInsertNotificationContext(TempNotificationContext);
    end;

    local procedure DeleteAlreadyRegisteredNotificationBeforeInsert(NotificationId: Guid)
    begin
        TempNotificationContext.Reset();
        TempNotificationContext.SetRange("Notification ID", NotificationId);
        if TempNotificationContext.FindFirst() then begin
            TempNotificationContext.Delete(true);
            OnAfterDeleteNotificationContext(TempNotificationContext);
        end;
    end;

    local procedure RecallNotifications(var TempNotificationContextToRecall: Record "Notification Context" temporary)
    var
        NotificationToRecall: Notification;
    begin
        repeat
            NotificationToRecall.Id := TempNotificationContextToRecall."Notification ID";
            // Notification.Recall does not fail if the notification was never sent, is no longer there, is dismissed or already recalled
            NotificationToRecall.Recall();

            TempNotificationContextToRecall.Delete(true);
            OnAfterDeleteNotificationContext(TempNotificationContextToRecall);
        until TempNotificationContextToRecall.Next() = 0
    end;

    local procedure GetUsableRecordId(var RecId: RecordID; HandleDelayedInsert: Boolean): Boolean
    var
        RecRef: RecordRef;
    begin
        if RecId.TableNo = 0 then
            exit(false);
        if not HandleDelayedInsert then
            exit(true);
        RecRef.Open(RecId.TableNo);
        RecRef.ReadIsolation := IsolationLevel::ReadUncommitted;
        RecRef.SetLoadFields(RecRef.SystemIdNo);
        // Handle delayed insert
        if not RecRef.Get(RecId) then
            RecId := RecRef.RecordId;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNotificationSent(CurrentNotification: Notification; TableNo: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Lifecycle Mgt.", 'OnAfterNotificationSent', '', true, true)]
    local procedure LogNotificationSentSubscriber(CurrentNotification: Notification; TableNo: Integer)
    begin
        Session.LogMessage('00001KO', StrSubstNo(NotificationSentTelemetryMsg, CurrentNotification.Id, TableNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', NotificationSentCategoryTxt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertNotificationContext(NotificationContext: Record "Notification Context")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteNotificationContext(NotificationContext: Record "Notification Context")
    begin
    end;

    procedure EnableSubscribers()
    begin
        SubscribersDisabled := false;
    end;

    procedure DisableSubscribers()
    begin
        SubscribersDisabled := true;
    end;

    procedure AreSubscribersDisabled(): Boolean
    begin
        exit(SubscribersDisabled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendNotification(var NotificationToSend: Notification; RecId: RecordID; AdditionalContextId: Guid)
    begin
    end;
}

