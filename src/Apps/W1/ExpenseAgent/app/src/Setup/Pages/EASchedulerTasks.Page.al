// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

page 7077 "EA Scheduler Tasks"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EA Scheduler Task";
    Editable = false;
    SourceTableView = sorting(ID) order(descending);

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field(ID; Rec.ID)
                {
                    Visible = false;
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the time of creation of the log entry, which is also when the task ran.';
                }
                field(Status; Rec.Status)
                {
                }
                field("Access Token Retrieved"; Rec."Access Token Retrieved")
                {
                }
                field("Send Replies Successful"; Rec."Send Replies Successful")
                {
                }
                field("Error Message"; Rec."Error Message")
                {
                    ToolTip = 'Specifies what error occurred if Status=Failed. Drill down to view the full error call stack.';

                    trigger OnDrillDown()
                    var
                        CallStack: Text;
                        DisplayText: Text;
                    begin
                        CallStack := Rec.GetErrorCallStack();

                        if Rec."Error Message" <> '' then
                            DisplayText := StrSubstNo(ErrorMsg, Rec."Error Message");

                        if CallStack <> '' then begin
                            if DisplayText <> '' then
                                DisplayText += '\';
                            DisplayText += StrSubstNo(ErrorCallStackMsg, CallStack);
                        end;

                        if DisplayText <> '' then
                            Message(DisplayText);
                    end;
                }
                field(RunByUser; Rec."Run by user")
                {
                }
            }
        }
    }

    var
        ErrorMsg: Label 'Error: %1', Comment = '%1 = the error message';
        ErrorCallStackMsg: Label 'Error call stack:\%1', Comment = '%1 = the error call stack. The backslash renders as a line break in the dialog.';
}