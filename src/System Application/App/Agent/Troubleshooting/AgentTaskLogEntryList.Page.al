// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;

page 4303 "Agent Task Log Entry List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Agent Task Log Entry";
    Caption = 'Agent Task Log';
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

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Description);
                    end;
                }
                field(Reason; Rec.Reason)
                {
                    Caption = 'Reason';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Reason);
                    end;
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
            fixed(DisclaimerGroup)
            {
                group(Left)
                {
                    ShowCaption = false;
                    label(Empty)
                    {
                        Caption = '', Locked = true;
                    }
                }
                group(Right)
                {
                    ShowCaption = false;
                    field(Disclaimer; AIGeneratedContentDisclaimerLbl)
                    {
                        ShowCaption = false;
                        Style = Subordinate;

                        trigger OnDrillDown()
                        begin
                            Hyperlink('https://go.microsoft.com/fwlink/?linkid=2349003');
                        end;
                    }
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
            part(TaskLogEntryDetails; "Agent Task Log Entry Part")
            {
                ApplicationArea = All;
                Caption = 'Log entry details';
                AboutTitle = 'Details of the selected log entry';
                AboutText = 'Shows details of the selected log entry, including the reason and description provided by the agent.';
                SubPageLink = "Task ID" = field("Task ID"), ID = field(ID);
            }
        }
    }
    actions
    {
        area(Promoted)
        {
            actionref(ViewDetails_Promoted; ViewDetails)
            {
            }
            actionref(Refresh_Promoted; Refresh)
            {
            }
            actionref(Feedback_Promoted; Feedback)
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
            action(Feedback)
            {
                ApplicationArea = All;
                Caption = 'Give feedback';
                ToolTip = 'Tell us what you think about the agent and suggest new features or improvements.';
                Image = Comment;
                Enabled = IsFeedbackActionEnabled;
                Visible = IsFeedbackActionEnabled;

                trigger OnAction()
                var
                    AgentUserFeedback: Codeunit "Agent User Feedback";
                    ContextProperties: Dictionary of [Text, Text];
                begin
                    ContextProperties := AgentUserFeedback.InitializeAgentTaskContext(Rec."Task ID");
                    AgentUserFeedback.RequestFeedback('Agent Task Log Entries', ContextProperties);
                end;
            }
        }
        area(Processing)
        {
            action(ViewDetails)
            {
                ApplicationArea = All;
                Caption = 'View details';
                ToolTip = 'View details of the selected log entry.';
                Image = View;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Page.Run(Page::"Agent Task Log Entry", Rec);
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
        Agent: Record Agent;
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        DetailsTxt := AgentTaskImpl.GetDetailsForAgentTaskLogEntry(Rec);
        case Rec.Level of
            Rec.Level::Error:
                TypeStyle := Format(PageStyle::Unfavorable);
            Rec.Level::Warning:
                TypeStyle := Format(PageStyle::Ambiguous);
            else
                TypeStyle := Format(PageStyle::Standard);
        end;

        if AgentTaskImpl.TryGetAgentRecordFromTaskId(Rec."Task ID", Agent) then
            IsFeedbackActionEnabled := Agent."Publisher Type" <> Agent."Publisher Type"::"Third Party"
        else
            IsFeedbackActionEnabled := false
    end;

    var
        AIGeneratedContentDisclaimerLbl: Label 'AI-generated content may be incorrect.';
        IsFeedbackActionEnabled: Boolean;
        DetailsTxt: Text;
        TypeStyle: Text;
}