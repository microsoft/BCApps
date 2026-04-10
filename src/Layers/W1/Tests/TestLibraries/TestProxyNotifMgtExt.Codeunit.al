codeunit 130232 "Test Proxy Notif. Mgt. Ext."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Proxy Notification Mgt.", 'OnCheckIgnoringNotification', '', false, false)]
    local procedure SetIgnoreOnCheckIgnoringNotification(NotificationID: Guid; var Ignore: Boolean)
    begin
        Ignore := true;
    end;
}

