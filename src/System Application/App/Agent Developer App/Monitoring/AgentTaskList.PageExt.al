pageextension 4399 AgentTaskList extends "Agent Task List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addlast(Process)
        {
            action(CreateTask)
            {
                ApplicationArea = All;
                Caption = 'Create task';
                ToolTip = 'Create a new task.';
                Image = New;

                trigger OnAction()
                var
                    Agent: Record Agent;
                    NewAgentTask: Record "Agent Task";
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                    AgentNewTask: Page "Agent New Task Message";
                begin
                    if Rec.GetFilter("Agent User Security ID") <> '' then begin
                        Agent.SetRange("User Security ID", Rec.GetFilter("Agent User Security ID"));
                        Agent.FindFirst();
                    end else
                        AgentTaskImpl.SelectAgent(Agent);

                    NewAgentTask."Agent User Security ID" := Agent."User Security ID";
                    AgentNewTask.SetAgentTask(NewAgentTask);
                    AgentNewTask.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(Stop)
            {
                ApplicationArea = All;
                Caption = 'Stop';
                ToolTip = 'Stop the selected task.';
                Image = Stop;

                trigger OnAction()
                var
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTaskImpl.StopTask(Rec, Rec."Status"::"Stopped by User", true);
                    CurrPage.Update(false);
                end;
            }
            action(Restart)
            {
                ApplicationArea = All;
                Caption = 'Restart';
                ToolTip = 'Restart the selected task.';
                Image = Restore;

                trigger OnAction()
                var
                    AgentTaskImpl: Codeunit "Agent Task Impl.";
                begin
                    AgentTaskImpl.RestartTask(Rec, true);
                    CurrPage.Update(false);
                end;
            }
            action(UserIntervention)
            {
                ApplicationArea = All;
                Caption = 'User Intervention';
                ToolTip = 'Provide the required user intervention.';
                Image = Restore;
                Enabled = UserInterventionEnabled;

                trigger OnAction()
                var
                    UserInterventionRequestStep: Record "Agent Task Step";
                    AgentUserIntervention: Page "Agent User Intervention";
                begin
                    UserInterventionRequestStep.Get(Rec.ID, Rec."Last Step Number");
                    AgentUserIntervention.SetUserInterventionRequestStep(UserInterventionRequestStep);
                    AgentUserIntervention.RunModal();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(CreateTask_Promoted; CreateTask)
                {
                }
                actionref(UserIntervention_Promoted; UserIntervention)
                {
                }
            }
        }
    }
}