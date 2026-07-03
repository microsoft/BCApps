// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

page 1172 "User Task Recurrence"
{
    Caption = 'Schedule recurring task';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {          
            field(Description; DescriptionLbl)
            {
                ApplicationArea = Basic, Suite;
                ShowCaption = false;
                Editable = false;
                Enabled = false;                
            }
            field(RecurringStartDate; RecurringStartDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurrence Start Date';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the start date for the recurrence.';
            }
            field(Recurrence; Recurrence)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurrence Pattern';
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the recurrence pattern, such as 20D if the task must recur every 20 days.';
            }
            field(Occurrences; Occurrences)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Number of Occurrences';
                MaxValue = 99;
                MinValue = 1;
                NotBlank = true;
                ShowMandatory = true;
                ToolTip = 'Specifies the number of occurrences.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            UserTask.CreateRecurrence(RecurringStartDate, Recurrence, Occurrences);
            Message(TaskScheduledLbl);
        end;
    end;

    procedure SetInitialData(UserTask2: Record "User Task")
    begin
        Clear(UserTask);
        UserTask := UserTask2;
        Occurrences := 1;
    end;

    var
        UserTask: Record "User Task";
        Recurrence: DateFormula;
        RecurringStartDate: Date;
        Occurrences: Integer;
        DescriptionLbl: Label 'Create copies of the task, adjusting each one''s date to match the recurrence pattern.';
        TaskScheduledLbl: Label 'The task occurrences have been created successfully.';
}

