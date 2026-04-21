// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Shows every LLM call the Performance Center has made, most recent first, with the
/// system prompt, user payload, raw response, and error so developers can troubleshoot.
/// </summary>
page 8428 "Perf. Analysis LLM Logs"
{
    Caption = 'Performance Analysis LLM Logs';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Perf. Analysis LLM Log";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    CardPageId = "Perf. Analysis LLM Log Card";
    Permissions = tabledata "Perf. Analysis LLM Log" = RD;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number.';
                }
                field("Logged At"; Rec."Logged At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the LLM call was made.';
                }
                field("Purpose"; Rec."Purpose")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which Performance Center AI entry point produced this call.';
                }
                field("Success"; Rec."Success")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the call succeeded.';
                    StyleExpr = SuccessStyle;
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the HTTP status code returned by the AOAI endpoint.';
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the round-trip duration of the LLM call in milliseconds.';
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message returned by the AOAI endpoint, if any.';
                }
                field("Analysis Id"; Rec."Analysis Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Performance Analysis that triggered this call.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearLog)
            {
                Caption = 'Clear log';
                ToolTip = 'Delete all entries from the LLM log.';
                Image = ClearLog;
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Record "Perf. Analysis LLM Log";
                    ConfirmLbl: Label 'Delete all %1 LLM log entries?', Comment = '%1 = number of entries';
                begin
                    if Log.IsEmpty() then
                        exit;
                    if not Confirm(StrSubstNo(ConfirmLbl, Log.Count())) then
                        exit;
                    Log.DeleteAll();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ClearLog_Promoted; ClearLog) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Success" then
            SuccessStyle := 'Favorable'
        else
            SuccessStyle := 'Unfavorable';
    end;

    var
        SuccessStyle: Text;
}

