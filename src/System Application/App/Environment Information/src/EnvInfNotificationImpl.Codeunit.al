// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

codeunit 3706 "Env. Inf. Notification Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        LearnMoreMsg: Label 'Learn more...';
        EarlyPreviewNotificationMsg: Label '⚠️ You are running a Dynamics 365 Business Central early access preview version. This version is provided for evaluation purposes only. Features and functionality may change in future releases.';
        EarlyPreviewNotificationIdTxt: Label 'ecd33cae-3e82-426b-9753-fed5addf6aad';
        LearnMoreUrlTxt: Label ' https://go.microsoft.com/fwlink/?linkid=2336818';

    procedure ShowEarlyPreviewNotification()
    var
        EnvironmentInformationImpl: Codeunit "Environment Information Impl.";
    begin
        if not GuiAllowed then
            exit;

        if not EnvironmentInformationImpl.IsEarlyPreview() then
            exit;

        ShowNotification();
    end;

    [Scope('OnPrem')]
    procedure LearnMoreNotification(Notification: Notification)
    begin
        Hyperlink(LearnMoreUrlTxt);
    end;

    local procedure ShowNotification()
    var
        Notification: Notification;
    begin
        CreateNotification(Notification, EarlyPreviewNotificationIdTxt, EarlyPreviewNotificationMsg);
        Notification.Send();
    end;

    local procedure CreateNotification(var Notification: Notification; ID: Text; Message: Text)
    begin
        Notification.Id(ID);
        Notification.Message(Message);
        Notification.AddAction(LearnMoreMsg, CODEUNIT::"Env. Inf. Notification Impl.", 'LearnMoreNotification');
    end;
}