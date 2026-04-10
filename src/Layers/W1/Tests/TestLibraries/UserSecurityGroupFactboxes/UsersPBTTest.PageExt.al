pageextension 135106 "Users PBT Test" extends Users
{
    actions
    {
        addlast(processing)
        {
            // TestPage.RunPageBackgroundTask starts a new session (despite its description) - bug 495670.
            // This is a workaround that allows to mock page background task completion in tests.
            action(TriggerPageBackgroundTask)
            {
                ApplicationArea = All;
                ToolTip = 'Trigger page background task in tests';

                trigger OnAction()
                var
                    UserSecurityGroupsPBT: Codeunit "User Security Groups PBT";
                    Parameters: Dictionary of [Text, Text];
                begin
                    Parameters.Add(UserSecurityGroupsPBT.GetUserSecurityIdParameterKey(), Rec."User Security ID");
                    RefreshFactboxes(UserSecurityGroupsPBT.GetBackgroundTaskResult(Parameters));
                end;
            }
        }
    }
}