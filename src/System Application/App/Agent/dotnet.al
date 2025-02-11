// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

dotnet
{
    assembly("Microsoft.Dynamics.Nav.Ncl")
    {
        type("Microsoft.Dynamics.Nav.Runtime.Agents.AgentALFunctions"; "AgentALFunctions")
        {
        }
    }

    assembly("Microsoft.Dynamics.Nav.Types")
    {
        type("Microsoft.Dynamics.Nav.Types.AgentTaskUserInterventionDetails"; "AgentTaskUserIntervention")
        {
        }

        type("Microsoft.Dynamics.Nav.Types.AgentTaskUserInterventionRequestDetails"; "AgentTaskUserInterventionRequest")
        {
        }
    }
}
