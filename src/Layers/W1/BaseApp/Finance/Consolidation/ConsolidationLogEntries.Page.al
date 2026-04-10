// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// List page displaying consolidation process log entries with execution history and status information.
/// Provides comprehensive view of consolidation operation logs for monitoring and troubleshooting.
/// </summary>
/// <remarks>
/// List page showing consolidation log entries in descending order by entry number for recent-first viewing.
/// Read-only interface for reviewing consolidation process execution history and identifying issues.
/// Essential for consolidation audit trails, process monitoring, and troubleshooting consolidation operations.
/// </remarks>
page 1835 "Consolidation Log Entries"
{
    ApplicationArea = All;
    Caption = 'Consolidation Log Entries';
    CardPageId = "Consolidation Log Entry";
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Consolidation Log Entry";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(ConsolidationLogEntryRepeater)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Request URI Preview"; Rec."Request URI Preview")
                {
                    ApplicationArea = All;
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                }
                field("Created at"; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    ToolTip = 'The date and time when the log entry was created.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Delete)
            {
                ApplicationArea = All;
                ToolTip = 'Delete the selected log entries.';
                Image = Delete;
                trigger OnAction()
                var
                    ConsolidationLogEntry: Record "Consolidation Log Entry";
                begin
                    CurrPage.SetSelectionFilter(ConsolidationLogEntry);
                    if ConsolidationLogEntry.IsEmpty() then
                        exit;
                    if not Confirm(ConfirmDeletionMsg) then
                        exit;
                    ConsolidationLogEntry.DeleteAll();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Delete_Promoted; Delete)
            {
            }
        }
    }

    var
        ConfirmDeletionMsg: Label 'Are you sure you want to delete the selected log entries?';
}
