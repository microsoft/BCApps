namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.RoleCenters;

// Embeds task-status monitoring in the human payables administrator's role center, not in the agent user's workspace.
pageextension 3311 PAAccPayablesAdministratorRC extends "Acc. Payable Administrator RC"
{
    layout
    {
        addafter(ApprovalsActivities)
        {
            part(PayablesAgentActivities; "Payables Agent Activities")
            {
                ApplicationArea = Basic, Suite;
                AccessByPermission = tabledata "Payables Agent Setup" = R;
            }
        }
    }
}
