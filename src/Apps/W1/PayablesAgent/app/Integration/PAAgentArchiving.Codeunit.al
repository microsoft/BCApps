// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

codeunit 3319 "PA Agent Archiving" implements IAgentArchiving
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure IsArchivingSupported(): Boolean
    begin
        exit(false);
    end;
}
