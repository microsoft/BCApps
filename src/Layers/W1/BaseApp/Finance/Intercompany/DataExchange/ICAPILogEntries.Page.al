// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

page 621 "IC API Log Entries"
{
    ApplicationArea = Intercompany;
    Caption = 'IC API Log Entries';
    CardPageId = "IC API Log Entry";
    Editable = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "IC API Log";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the unique identifier of the log entry.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether this was an outgoing or incoming API call.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code related to this API call.';
                }
                field(Method; Rec.Method)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the HTTP method used for the API call.';
                }
                field("Request URI Preview"; Rec."Request URI Preview")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the URI of the API request.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the HTTP status code returned by the API call.';
                }
                field("Created at"; Rec.SystemCreatedAt)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
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
                ApplicationArea = Intercompany;
                Caption = 'Delete';
                ToolTip = 'Delete the selected log entries.';
                Image = Delete;

                trigger OnAction()
                var
                    ICAPILog: Record "IC API Log";
                begin
                    CurrPage.SetSelectionFilter(ICAPILog);
                    if ICAPILog.IsEmpty() then
                        exit;
                    if not Confirm(ConfirmDeletionMsg) then
                        exit;
                    ICAPILog.DeleteAll();
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
