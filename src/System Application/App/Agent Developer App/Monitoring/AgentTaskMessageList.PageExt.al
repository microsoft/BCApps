pageextension 4398 AgentTaskMessageList extends "Agent Task Message List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addlast(Process)
        {
            action(AddMessage)
            {
                ApplicationArea = All;
                Caption = 'Create new message';
                ToolTip = 'Create a new message.';
                Image = Task;

                trigger OnAction()
                var
                    CurrentAgentTask: Record "Agent Task";
                    AgentNewTaskMessage: Page "Agent New Task Message";
                begin
                    CurrentAgentTask.Get(Rec."Task ID");
                    AgentNewTaskMessage.SetAgentTask(CurrentAgentTask);
                    AgentNewTaskMessage.RunModal();
                    CurrPage.Update(false);
                end;
            }
        }
    }
            area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AddMessage_Promoted; AddMessage)
                {
                }
            }
        }
}