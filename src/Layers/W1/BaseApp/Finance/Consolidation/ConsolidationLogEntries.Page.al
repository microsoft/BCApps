// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

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
                    ToolTip = 'The unique identifier of the log entry.';
                }
                field("Request URI Preview"; Rec."Request URI Preview")
                {
                    ApplicationArea = All;
                    ToolTip = 'The URI of the request that was sent to the API of the business unit.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'The status code of the response that was received from the API for this request.';
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
