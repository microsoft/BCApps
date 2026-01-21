// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

#pragma warning disable AS0125
page 4303 "Agent Task Log Entry List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Agent Task Log Entry";
    Caption = 'Agent Task Log (Preview)';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    SourceTableView = sorting("ID") order(descending);
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field(ID; Rec."ID")
                {
                    Caption = 'ID';
                    ToolTip = 'Specifies the unique identifier of the log entry.';
                }
                field(Timestamp; Rec.SystemCreatedAt)
                {
                    Caption = 'Timestamp';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
                }
                field(TaskID; Rec."Task ID")
                {
                    Visible = false;
                    Caption = 'Task ID';
                }
                field(Level; Rec.Level)
                {
                    Caption = 'Level';
                    StyleExpr = TypeStyle;
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    StyleExpr = TypeStyle;
                }
                field(PageCaption; Rec."Page Caption")
                {
                    Caption = 'Page Caption';
                }
                field("User Full Name"; Rec."User Full Name")
                {
                    Caption = 'User Full Name';
                    Tooltip = 'Specifies the full name of the user that was involved in performing the step.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(Details; DetailsTxt)
                {
                    Caption = 'Details';
                    ToolTip = 'Specifies the step details.';

                    trigger OnDrillDown()
                    begin
                        Message(DetailsTxt);
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(TaskContext; "Agent Task Context Part")
            {
                ApplicationArea = All;
                Caption = 'Task context';
                AboutTitle = 'Context information about the task and agent';
                AboutText = 'Shows context information such as the agent name, task ID, and company name.';
                SubPageLink = ID = field("Task ID");
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh)
            {
            }
        }
        area(Creation)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the page.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        DetailsTxt := AgentTaskImpl.GetDetailsForAgentTaskLogEntry(Rec);
        case Rec.Level of
            Rec.Level::Error:
                TypeStyle := 'Unfavorable';
            Rec.Level::Warning:
                TypeStyle := 'Ambiguous';
            else
                TypeStyle := 'Standard';
        end;
    end;

    var
        DetailsTxt: Text;
        TypeStyle: Text;
}
#pragma warning restore AS0125