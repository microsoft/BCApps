// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.ExpenseAgent;

using System.Agents;

enumextension 6998 "EA Agent Metadata" extends "Agent Metadata Provider"
{
    value(6998; "Expense Agent")
    {
        Caption = 'Expense Agent', Locked = true;
        Implementation = IAgentFactory = "EA Metadata Provider", IAgentMetadata = "EA Metadata Provider", IAgentTaskExecution = "EA Agent Task Execution";
    }
}
