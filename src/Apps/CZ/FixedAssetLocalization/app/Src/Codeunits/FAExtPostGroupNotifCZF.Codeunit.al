// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Environment.Configuration;

codeunit 11768 "FA Ext. Post. Group Notif. CZF"
{
    Access = Internal;

    procedure DontShowAgainNotification(Notification: Notification)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.DisableFAExtPostGroupNotification();
    end;

    procedure OpenFAExtPostingGroups(Notification: Notification)
    var
        FAExtendedPostingGroupCZF: Record "FA Extended Posting Group CZF";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FAExtendedPostingGroupCZF.SetRange("FA Posting Group Code", Notification.GetData(GenJournalLine.FieldName("Posting Group")));
        Page.Run(Page::"FA Extended Posting Groups CZF", FAExtendedPostingGroupCZF);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure InsertDefaultNotificationOnInitializingNotificationWithDefaultState()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFAExtPostGroupNotificationDefaultState(true);
    end;
}
