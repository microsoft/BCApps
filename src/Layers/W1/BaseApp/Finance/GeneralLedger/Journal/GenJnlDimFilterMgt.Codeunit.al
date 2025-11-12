// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using System.Environment.Configuration;

codeunit 486 "Gen. Jnl. Dim. Filter Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        NotificationNameTxt: Label 'Set dimension filters.';
        NotificationDescTxt: Label 'Show a suggestion to set dimension filters for recurring journal line.';

    procedure SetGenJnlDimFilters(SetDimFiltersNotification: Notification)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlDimFilters: Page "Gen. Jnl. Dim. Filters";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        JournalLineNo: Integer;
    begin
        JournalTemplateName := CopyStr(SetDimFiltersNotification.GetData('JournalTemplateName'), 1, MaxStrLen(JournalTemplateName));
        JournalBatchName := CopyStr(SetDimFiltersNotification.GetData('JournalBatchName'), 1, MaxStrLen(JournalBatchName));
        Evaluate(JournalLineNo, SetDimFiltersNotification.GetData('JournalLineNo'));

        GenJournalLine.Get(JournalTemplateName, JournalBatchName, JournalLineNo);
        GenJnlDimFilters.SetGenJnlLine(GenJournalLine);
        GenJnlDimFilters.RunModal();
    end;

    procedure HideNotification(SetDimFiltersNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationId()) then
            MyNotifications.InsertDefault(GetNotificationId(), NotificationNameTxt, NotificationDescTxt, false);
    end;

    procedure IsNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationId()));
    end;

    local procedure GetNotificationId(): Guid
    begin
        exit('e0f9167c-f9bd-4ab1-952b-874c8036cf93');
    end;
}
