// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;

/// <summary>
/// Registers the Shopify Tax Matching Agent with the BC Agent Framework.
/// </summary>
enumextension 30470 "Shpfy Tax Agent Metadata" extends "Agent Metadata Provider"
{
    value(30470; "Shpfy Tax Agent")
    {
        Caption = 'Shopify Tax Matching Agent';
        Implementation =
            IAgentFactory = "Shpfy Tax Agent",
            IAgentMetadata = "Shpfy Tax Agent",
            IAgentTaskExecution = "Shpfy Tax Agent Task Exec.";
    }
}
