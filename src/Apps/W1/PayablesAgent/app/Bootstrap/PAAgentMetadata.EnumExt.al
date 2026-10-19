// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

enumextension 3304 "PA Agent Metadata" extends "Agent Metadata Provider"
{
    value(3303; "Payables Agent")
    {
        Caption = 'Payables Agent', Locked = true;
        Implementation = IAgentFactory = "Payables Agent Metadata", IAgentMetadata = "Payables Agent Metadata", IAgentTaskExecution = "PA Agent Task Execution", IAgentArchiving = "Payables Agent Metadata";
    }
}
