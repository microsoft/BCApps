// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays the individual action log entries for a reminder automation run as a subpage part.
/// </summary>
page 6757 "Reminder Act. History Log"
{
    Caption = 'Action log';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Reminder Action Log";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(ActionGroupLog)
            {
                Editable = false;
                field(Id; Rec."Reminder Action ID")
                {
                    ApplicationArea = All;
                    Caption = 'Action';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    StyleExpr = Rec.Status = Rec.Status::Failed;
                    Style = Unfavorable;
                }
                field(Details; Rec."Status summary")
                {
                    ApplicationArea = All;
                    Caption = 'Details';
                }
                field("Last Record Processed"; LastRecordProcessed)
                {
                    ApplicationArea = All;
                    Caption = 'Last record processed';
                    ToolTip = 'Specifies the last record processed by the action job. In case of an error this was the last record processed before the error occurred. If the job was successful, this was the last record processed by the job.';
                }
#if not CLEAN27
                field(TotalErrors; Rec."Total Errors")
                {
                    ApplicationArea = All;
                    Caption = 'Total errors';
                    Visible = false;
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This field is obsolete and should not be used.';
#pragma warning disable AS0074
                    ObsoleteTag = '27.0';
#pragma warning restore AS0074
                }
#endif
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LastRecordProcessed := Format(Rec."Last Record Processed");
    end;

    var
        LastRecordProcessed: Text;
}