// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Agents.TaskPane;

page 4343 "Agent Task Context Part"
{
    ApplicationArea = All;
    Caption = 'Context';
    Editable = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    PageType = CardPart;
    SourceTable = "Agent Task";

    layout
    {
        area(Content)
        {
            field(AgentName; Rec."Agent Display Name")
            {
                Caption = 'Agent name';
                ToolTip = 'Specifies the name of the agent that performed the tasks.';

                trigger OnDrillDown()
                var
                    TaskPane: Codeunit "Task Pane";
                begin
                    TaskPane.ShowAgent(Rec."Agent User Security ID");
                end;
            }
            field(TaskID; Rec.ID)
            {
                Caption = 'Task ID';
                ToolTip = 'Specifies the ID of the task that was executed.';
                Editable = false;
                ExtendedDatatype = Task;

                trigger OnDrillDown()
                var
                    TaskPane: Codeunit "Task Pane";
                begin
                    TaskPane.ShowTask(Rec);
                end;
            }
            field(TaskTitle; Rec.Title)
            {
                Caption = 'Task title';
                ToolTip = 'Specifies the title of the task that was executed.';
                Visible = Rec.Title <> '';
            }
            field(CompanyName; Rec."Company Name")
            {
                Caption = 'Company name';
                ToolTip = 'Specifies the name of the company in which the task was executed.';
            }
        }
    }
}