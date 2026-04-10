// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using System.Environment.Configuration;

/// <summary>
/// Manages dimension filtering functionality for general journal lines including filter setup and notification handling.
/// Provides centralized management of dimension-based filtering capabilities for journal line analysis and reporting.
/// </summary>
/// <remarks>
/// Core management functionality for journal dimension filtering. Handles filter configuration, notification processing,
/// and integration with dimension filtering user interfaces for enhanced journal line analysis capabilities.
/// Key features: Dimension filter setup, notification management, recurring journal filter suggestions, filter validation.
/// Integration: Works with dimension filtering pages and journal line processing for comprehensive dimension-based analysis.
/// </remarks>
codeunit 486 "Gen. Jnl. Dim. Filter Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        NotificationNameTxt: Label 'Set dimension filters.';
        NotificationDescTxt: Label 'Show a suggestion to set dimension filters for recurring journal line.';

    /// <summary>
    /// Opens dimension filter setup page for journal line based on notification data.
    /// Processes notification to launch dimension filter configuration interface.
    /// </summary>
    /// <param name="SetDimFiltersNotification">Notification containing journal line context data for filter setup.</param>
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

    /// <summary>
    /// Disables the dimension filter notification for the current user.
    /// Processes user request to hide dimension filter setup suggestions.
    /// </summary>
    /// <param name="SetDimFiltersNotification">Notification to disable for current user preferences.</param>
    procedure HideNotification(SetDimFiltersNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationId()) then
            MyNotifications.InsertDefault(GetNotificationId(), NotificationNameTxt, NotificationDescTxt, false);
    end;

    /// <summary>
    /// Checks if dimension filter notifications are enabled for the current user.
    /// Returns user preference setting for showing dimension filter suggestions.
    /// </summary>
    /// <returns>True if notification is enabled, false if user has disabled dimension filter suggestions.</returns>
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
