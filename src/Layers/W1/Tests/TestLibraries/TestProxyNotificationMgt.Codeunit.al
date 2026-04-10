codeunit 130231 "Test Proxy Notification Mgt."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempNotificationContext: Record "Notification Context" temporary;
        NotificationErr: Label 'Notification has not been recalled for %1.';

    local procedure DeleteNotificationContextEntries()
    begin
        TempNotificationContext.DeleteAll();
    end;

    local procedure GetFirstRecordIDText(): Text
    begin
        TempNotificationContext.FindFirst();
        exit(Format(TempNotificationContext."Record ID"));
    end;

    local procedure HasNotificationContextEntries(): Boolean
    begin
        exit(not TempNotificationContext.IsEmpty);
    end;

    local procedure RemoveIgnoringNotifications()
    var
        Ignore: Boolean;
    begin
        if TempNotificationContext.IsEmpty() then
            exit;

        TempNotificationContext.FindSet(true);
        repeat
            Ignore := false;
            OnCheckIgnoringNotification(TempNotificationContext."Notification ID", Ignore);
            if Ignore then
                TempNotificationContext.Delete();
        until TempNotificationContext.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Lifecycle Mgt.", 'OnAfterInsertNotificationContext', '', false, false)]
    local procedure InsertEntryOnAfterInsertNotificationContext(NotificationContext: Record "Notification Context")
    begin
        TempNotificationContext.TransferFields(NotificationContext);
        TempNotificationContext.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Lifecycle Mgt.", 'OnAfterDeleteNotificationContext', '', false, false)]
    local procedure DeleteEntryOnAfterDeleteNotificationContext(NotificationContext: Record "Notification Context")
    begin
        if TempNotificationContext.Get(NotificationContext."Notification ID") then
            TempNotificationContext.Delete();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Proxy", 'OnBeforeTestFunctionRun', '', false, false)]
    local procedure PrepareOnBeforeTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    begin
        DeleteNotificationContextEntries();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Proxy", 'OnAfterTestFunctionRun', '', false, false)]
    local procedure VerifyOnAfterTestFunctionRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var IsSuccess: Boolean)
    begin
        if IsSuccess then begin
            RemoveIgnoringNotifications();
            IsSuccess := not HasNotificationContextEntries();
            if not IsSuccess then
                asserterror Error(NotificationErr, GetFirstRecordIDText());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIgnoringNotification(NotificationID: Guid; var Ignore: Boolean)
    begin
    end;
}

