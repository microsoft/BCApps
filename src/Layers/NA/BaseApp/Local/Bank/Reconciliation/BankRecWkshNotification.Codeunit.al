// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Foundation.Company;
using System.Environment.Configuration;

codeunit 10127 "Bank Rec. Wksh. Notification"
{
    Access = Internal;

    trigger OnRun()
    begin

    end;

    procedure ShowBankRecWorksheetUIImprovementNotification()
    begin
        if IsNotificationDisabled() then
            exit;

        if IsDemoCompany() then
            exit;

        FireUIImprovementNotification();
    end;

    [Scope('OnPrem')]
    procedure DisableNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(Notification.Id) then
            MyNotifications.InsertDefault(Notification.Id, BankRecWorksheetUIImprovementTxt,
                          BankRecWorksheetUIImprovementDescTxt, false);
    end;

    [Scope('OnPrem')]
    procedure LearnMoreNotification(Notification: Notification)
    begin
        Hyperlink(LearnMoreUrlTxt);
    end;

    local procedure FireUIImprovementNotification()
    var
        Notification: Notification;
    begin
        CreateNotification(Notification, BankRecWorksheetUIImprovementIdTxt, BankRecWorksheetUIImprovementMsg);
        Notification.Send();
    end;

    local procedure CreateNotification(var Notification: Notification; ID: Text; Message: Text)
    begin
        Notification.Id(ID);
        Notification.Message(Message);
        Notification.AddAction(DontShowAgainMsg, CODEUNIT::"Bank Rec. Wksh. Notification", 'DisableNotification');
        Notification.AddAction(LearnMoreMsg, CODEUNIT::"Bank Rec. Wksh. Notification", 'LearnMoreNotification');
    end;

    local procedure IsDemoCompany(): Boolean
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        exit(CompanyInformationMgt.IsDemoCompany());
    end;

    local procedure IsNotificationDisabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(not MyNotifications.IsEnabled(BankRecWorksheetUIImprovementIdTxt));
    end;

    var
        DontShowAgainMsg: Label 'Don''t show again';
        LearnMoreMsg: Label 'Learn more';
        BankRecWorksheetUIImprovementMsg: Label 'Notice something different? We’ve added space to this page so there''s more room to work. Also, Focus Mode lets you open FastTabs in separate pages.';
        BankRecWorksheetUIImprovementTxt: Label 'Bank Acc. Reconciliation change';
        BankRecWorksheetUIImprovementDescTxt: Label 'The functions and features are the same, it just looks a bit different. In addition we’ve given you a pop-out option on each of the fasttabs so you can have a full page when you work with these.';
        BankRecWorksheetUIImprovementIdTxt: Label '33e3f532-13ea-4248-b96f-48128140aab4', Locked = true;
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2155800';

}
