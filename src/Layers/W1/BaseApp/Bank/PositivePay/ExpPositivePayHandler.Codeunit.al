// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

/// <summary>
/// Handles positive pay export operations by managing check ledger entry filters and coordinating with export processes.
/// This codeunit provides a bridge between user-specified filters and the positive pay export engine.
/// </summary>
/// <remarks>
/// The Export Positive Pay Handler codeunit manages the flow of filter information during positive pay exports.
/// It stores user-defined check ledger entry filters and provides them to the export pre-mapping processes.
/// This ensures that only the checks meeting the specified criteria are included in the positive pay export file.
/// The codeunit uses event subscription to integrate with the export framework without tight coupling.
/// </remarks>
codeunit 1713 "Exp. Positive Pay Handler"
{
    EventSubscriberInstance = Manual;

    /// <summary>
    /// Sets the check ledger entry filter view to be used during positive pay export processing.
    /// </summary>
    /// <param name="CheckLedgerEntryView">The view string containing filter criteria for check ledger entries.</param>
    /// <remarks>
    /// This procedure stores the filter criteria that will be applied when selecting check ledger entries
    /// for inclusion in the positive pay export. The filter is later retrieved by event subscription.
    /// </remarks>
    procedure SetCheckLedgerEntryView(CheckLedgerEntryView: Text)
    begin
        GlobalCheckLedgerEntryView := CheckLedgerEntryView;
    end;

    /// <summary>
    /// Event subscriber that provides check ledger entry filters to the positive pay detail preparation process.
    /// </summary>
    /// <param name="CheckLedgerEntryView">Returns the stored filter view for check ledger entries.</param>
    /// <remarks>
    /// This event subscriber responds to the OnGetFiltersBeforePreparingPosPayDetails event and provides
    /// the previously stored check ledger entry filter to ensure consistent filtering throughout the export process.
    /// </remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exp. Pre-Mapping Det Pos. Pay", 'OnGetFiltersBeforePreparingPosPayDetails', '', false, false)]
    local procedure GetFiltersBeforePreparingPosPayDetails(var CheckLedgerEntryView: Text)
    begin
        CheckLedgerEntryView := GlobalCheckLedgerEntryView;
    end;

    var
        GlobalCheckLedgerEntryView: Text;
}