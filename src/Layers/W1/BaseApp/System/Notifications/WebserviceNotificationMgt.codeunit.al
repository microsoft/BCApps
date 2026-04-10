namespace System.Environment.Configuration;

using System.Environment;

codeunit 810 "Webservice Notification Mgt."
{
    [Scope('OnPrem')]
    procedure DisableNotifications(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(Notification.Id);
    end;

    [Scope('OnPrem')]
    procedure WebServiceAPINotifictionhowMore(Notification: Notification)
    begin
        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2185928');
    end;

    [Scope('OnPrem')]
    procedure WebServiceAPINotificationDefault(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        MyNotifications.InsertDefault(
                  WebServiceAPINotificationId(), WEBServiceAPINameTok, WEBServiceAPIDescriptionTok, EnvironmentInfo.IsSaaS());
    end;

    [Scope('OnPrem')]
    procedure WebServiceAPINotificationId(): Guid
    begin
        exit('2d61a428-4bf0-4b05-ab22-1050fad472df');
    end;

    [Scope('OnPrem')]
    procedure WebServiceAPINotificationShow(WebServiceAPINotification: Notification)
    begin
        WebServiceAPINotification.Id := WebServiceAPINotificationId();
        WebServiceAPINotification.Recall();
        WebServiceAPINotification.Message(WEBServiceAPIDescriptionTok);
        WebServiceAPINotification.AddAction(DontShowAgainTok, CODEUNIT::"Webservice Notification Mgt.", 'DisableNotifications');
        WebServiceAPINotification.AddAction(ShowMoreLinkTok, CODEUNIT::"Webservice Notification Mgt.", 'BasicAuthDepricationNotificationShowMore');
        WebServiceAPINotification.Scope(NotificationScope::LocalScope);
        WebServiceAPINotification.Send();
    end;

    [Scope('OnPrem')]
    procedure BasicAuthDepricationNotificationShowMore(Notification: Notification)
    begin
        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2185928');
    end;

    var
        WEBServiceAPIDescriptionTok: Label 'If you want to set up an OData connection, for performance and stability reasons consider using an API page instead.';
        WEBServiceAPINameTok: Label 'Use API instead if OData Notification.';
        DontShowAgainTok: Label 'Don''t show again';
        ShowMoreLinkTok: Label 'API documentation';
}