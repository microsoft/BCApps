// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Environment.Configuration;

tableextension 31078 "Gen. Journal Line CZF" extends "Gen. Journal Line"
{
    fields
    {
        modify("Reason Code")
        {
            trigger OnAfterValidate()
            begin
                CheckFAExtPostGroup();
            end;
        }
        modify("FA Posting Type")
        {
            trigger OnAfterValidate()
            begin
                CheckFAExtPostGroup();
            end;
        }
    }

    var
        FAExtPostGroupNotExistMsg: Label 'FA Extended Posting Group is not set up for Reason Code %1. The disposal will be posted based on the FA Posting Group %2 setup.', Comment = '%1 = Reason Code, %2 = FA Posting Group Code';
        FAExtPostGroupNotificationNameTxt: Label 'Warn about missing FA Extended Posting Group for disposal.';
        FAExtPostGroupNotificationDescTxt: Label 'Show a warning when no FA Extended Posting Group exists for the combination of FA Posting Group, Reason Code, and FA Posting Type Disposal on the journal line.';
        DontShowAgainLbl: Label 'Don''t show again';
        OpenFAExtPostingGroupsLbl: Label 'Open FA Extended Posting Groups';
        IsFAExtendedPostingGroupSent: Boolean;

    local procedure CheckFAExtPostGroup()
    begin
        if ("Account Type" <> "Account Type"::"Fixed Asset") or
           ("FA Posting Type" <> "FA Posting Type"::Disposal) or
           ("Posting Group" = '') or
           ("Reason Code" = '')
        then begin
            if (xRec."Account Type" = "Account Type"::"Fixed Asset") and
               (xRec."FA Posting Type" = "FA Posting Type"::Disposal) and
               (xRec."Posting Group" <> '') and
               (xRec."Reason Code" <> '')
            then
                RecallFAExtPostGroupNotification();
            exit;
        end;

        if not IsFAExtPostingGroupExist() then
            ShowFAExtPostGroupNotification()
        else
            RecallFAExtPostGroupNotification();
    end;

    local procedure IsFAExtPostingGroupExist(): Boolean
    var
        FAExtendedPostingGroupCZF: Record "FA Extended Posting Group CZF";
    begin
        FAExtendedPostingGroupCZF.SetRange("FA Posting Group Code", "Posting Group");
        FAExtendedPostingGroupCZF.SetRange("FA Posting Type", Enum::"FA Extended Posting Type CZF"::Disposal);
        FAExtendedPostingGroupCZF.SetRange(Code, "Reason Code");
        exit(not FAExtendedPostingGroupCZF.IsEmpty());
    end;

    local procedure ShowFAExtPostGroupNotification()
    var
        MyNotifications: Record "My Notifications";
        FAExtPostGroupNotification: Notification;
    begin
        if not MyNotifications.Get(UserId, GetFAExtPostGroupNotificationId()) then
            InitFAExtPostGroupNotification();

        if not MyNotifications.IsEnabled(GetFAExtPostGroupNotificationId()) then
            exit;

        FAExtPostGroupNotification.Id(GetFAExtPostGroupNotificationId());
        FAExtPostGroupNotification.Message(StrSubstNo(FAExtPostGroupNotExistMsg, "Reason Code", "Posting Group"));
        FAExtPostGroupNotification.Scope(NotificationScope::LocalScope);
        FAExtPostGroupNotification.AddAction(OpenFAExtPostingGroupsLbl, Codeunit::"FA Ext. Post. Group Notif. CZF", 'OpenFAExtPostingGroups');
        FAExtPostGroupNotification.AddAction(DontShowAgainLbl, Codeunit::"FA Ext. Post. Group Notif. CZF", 'DontShowAgainNotification');
        FAExtPostGroupNotification.SetData(FieldName("Posting Group"), "Posting Group");
        FAExtPostGroupNotification.SetData(FieldName("Reason Code"), "Reason Code");
        IsFAExtendedPostingGroupSent := FAExtPostGroupNotification.Send();
    end;

    local procedure RecallFAExtPostGroupNotification()
    var
        MyNotifications: Record "My Notifications";
        FAExtPostGroupNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetFAExtPostGroupNotificationId()) then
            exit;
        if not IsFAExtendedPostingGroupSent then
            exit;

        FAExtPostGroupNotification.Id(GetFAExtPostGroupNotificationId());
        FAExtPostGroupNotification.Recall();
    end;

    local procedure InitFAExtPostGroupNotification()
    var
        MyNotifications: Page "My Notifications";
    begin
        MyNotifications.InitializeNotificationsWithDefaultState();
    end;

    internal procedure SetFAExtPostGroupNotificationDefaultState(DefaultState: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetFAExtPostGroupNotificationId(),
            FAExtPostGroupNotificationNameTxt, FAExtPostGroupNotificationDescTxt, DefaultState);
    end;

    internal procedure DisableFAExtPostGroupNotification()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetFAExtPostGroupNotificationId()) then
            SetFAExtPostGroupNotificationDefaultState(false);
    end;

    internal procedure GetFAExtPostGroupNotificationId(): Guid
    begin
        exit('4cdd87d0-490a-4a4d-ba31-0a4c106bdaef');
    end;
}