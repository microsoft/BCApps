// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Agents;

codeunit 7104 "EA Agent Archiving" implements IAgentArchiving
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure IsArchivingSupported(): Boolean
    begin
        exit(false);
    end;
}
