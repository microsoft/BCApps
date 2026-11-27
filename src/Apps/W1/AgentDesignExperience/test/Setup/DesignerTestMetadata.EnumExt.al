// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.Designer;

using System.Agents;
using System.Agents.Designer.CustomAgent;

enumextension 133750 "Designer Test Metadata" extends "Agent Metadata Provider"
{
    value(133750; "Designer Test Agent")
    {
        Caption = 'Designer test agent';
        Implementation = IAgentFactory = "Designer Test Agent Factory", IAgentMetadata = "Custom Agent Metadata Provider";
    }
}
