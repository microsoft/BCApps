// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6756 "Reminder Action History"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Reminder Action Group Log";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    CardPageId = "Reminder Act. History Detailed";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(ActionGroupLog)
            {
                field(EntryNo; Rec."Run Id")
                {
                    ApplicationArea = All;
                    Caption = 'Run Id';
                    ToolTip = 'Specifies the unique identifier of the reminder action group log entry. Each job will get an unique identifier.';
                }
                field("Reminder Action Group ID"; Rec."Reminder Action Group ID")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Action Group';
                    ToolTip = 'Specifies the reminder action group that was run.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    StyleExpr = Rec.Status = Rec.Status::Failed;
                    Style = Unfavorable;
                    ToolTip = 'Specifies the status of the reminder action group log entry.';
                }
                field(StartedOn; Rec."Started On")
                {
                    ApplicationArea = All;
                    Caption = 'Started on';
                    ToolTip = 'Specifies the date and time when the reminder action group log entry was started.';
                }
                field(CompletedOn; Rec."Completed On")
                {
                    ApplicationArea = All;
                    Caption = 'Completed on';
                    ToolTip = 'Specifies the date and time when the reminder action group log entry was completed.';
                }
                field(NumberOfErrors; NumberOfActiveErrors)
                {
                    ApplicationArea = All;
                    Caption = 'Number of errors';
                    ToolTip = 'Specifies the number of errors that occurred during the run.';
                    StyleExpr = NumberOfActiveErrors > 0;
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        ReminderAutomationError: Record "Reminder Automation Error";
                    begin
                        Rec.GetActiveErrors(ReminderAutomationError);
                        Page.Run(Page::"Reminder Aut. Error Overview", ReminderAutomationError);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NumberOfActiveErrors := Rec.GetNumberOfActiveErrors();
        if not UpdatedInProgressRecords then
            if Rec.Status = Rec.Status::Running then begin
                Rec.UpdateInProgressRecords();
                UpdatedInProgressRecords := true;
            end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        NumberOfActiveErrors := Rec.GetNumberOfActiveErrors();
    end;

    var
        NumberOfActiveErrors: Integer;
        UpdatedInProgressRecords: Boolean;
}