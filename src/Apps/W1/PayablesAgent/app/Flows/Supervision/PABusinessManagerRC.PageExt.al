namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.RoleCenters;

// Embeds task-status monitoring in the human business manager's role center, not in the agent user's workspace.
pageextension 3312 PABusinessManagerRC extends "Business Manager Role Center"
{
    layout
    {
        addafter(ApprovalsActivities)
        {
            part(PayablesAgentActivities; "Payables Agent Activities")
            {
                ApplicationArea = Basic, Suite;
                AccessByPermission = tabledata "Payables Agent Setup" = R;
                Visible = false;
            }
        }
    }
}
