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

#if not CLEAN26
    internal procedure ShowDisableSoapWebServiceNotification()
    var
        MyNotifications: Record "My Notifications";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        DisableSoapWebServiceNotification: Notification;
    begin
        if FeatureManagementFacade.IsEnabled(DisableSoapWebServicesOnMicrosoftUIPagesTok) then
            exit;

        if not MyNotifications.IsEnabled(GetDisableSoapWebServicesFeatureNotificationId()) then
            exit;

        DisableSoapWebServiceNotification.Id := GetDisableSoapWebServicesFeatureNotificationId();
        DisableSoapWebServiceNotification.Recall();
        DisableSoapWebServiceNotification.Message := DisableSoapWebServicesNotificationMsgTxt;
        DisableSoapWebServiceNotification.AddAction(DontShowAgainTok, Codeunit::"Webservice Notification Mgt.", 'DisableSoapNotification');
        DisableSoapWebServiceNotification.AddAction(LearnMoreTok, CODEUNIT::"Webservice Notification Mgt.", 'OpenFeatureManagement');
        DisableSoapWebServiceNotification.Send();
    end;

    internal procedure DisableSoapNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetDisableSoapWebServicesFeatureNotificationId()) then
            MyNotifications.InsertDefault(GetDisableSoapWebServicesFeatureNotificationId(), DisableSoapWebServicesNotificationNameTxt, DisableSoapWebServicesNotificationDescriptionTxt, false);
    end;

    internal procedure OpenFeatureManagement(Notification: Notification)
    var
        FeatureKey: Record "Feature Key";
    begin
        Page.Run(Page::"Feature Management", FeatureKey);
    end;

    local procedure GetDisableSoapWebServicesFeatureNotificationId(): Guid
    begin
        exit('65737d8f-3f37-4e75-9d7d-91151e3cbac8');
    end;
#endif

    var
#if not CLEAN26
        LearnMoreTok: Label 'Feature Management';
        DisableSoapWebServicesOnMicrosoftUIPagesTok: Label 'DisableSOAPwebservicesonMicrosoftUIpages', Locked = true;
        DisableSoapWebServicesNotificationMsgTxt: Label 'The ability to expose a Microsoft UI page as a SOAP endpoint is being removed. Learn more on the Feature Management page.';
        DisableSoapWebServicesNotificationNameTxt: Label 'Disable SOAP Web Services';
        DisableSoapWebServicesNotificationDescriptionTxt: Label 'This notification is used to let users know that the ability to expose a Microsoft UI page as a SOAP endpoint is being removed.';
#endif
        WEBServiceAPIDescriptionTok: Label 'If you want to set up an OData connection, for performance and stability reasons consider using an API page instead.';
        WEBServiceAPINameTok: Label 'Use API instead if OData Notification.';
        DontShowAgainTok: Label 'Don''t show again';
        ShowMoreLinkTok: Label 'API documentation';
}