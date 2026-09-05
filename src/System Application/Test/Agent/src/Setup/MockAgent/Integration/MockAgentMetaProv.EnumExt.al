// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents;
using System.Agents;

enumextension 133952 "Mock Agent Meta. Prov." extends "Agent Metadata Provider"
{
    value(133952; "SDK Mock Agent")
    {
        Caption = 'SDK Mock Agent';
        Implementation = IAgentFactory = "Mock Agent Meta. Prov.", IAgentMetadata = "Mock Agent Meta. Prov.";
    }

    value(133955; "SDK Mock Agent No Archiving")
    {
        Caption = 'SDK Mock Agent No Archiving';
        Implementation = IAgentFactory = "Mock Agent Meta. Prov.", IAgentMetadata = "Mock Agent Meta. Prov.", IAgentArchiving = "Mock Agent Meta. Prov.";
    }
}
