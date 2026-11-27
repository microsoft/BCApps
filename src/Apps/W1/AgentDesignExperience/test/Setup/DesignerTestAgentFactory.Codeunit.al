// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.Designer;

using System.Agents;
using System.Agents.Designer.CustomAgent;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

codeunit 133755 "Designer Test Agent Factory" implements IAgentFactory
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        CustomAgentMetadataProvider: Codeunit "Custom Agent Metadata Provider";

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(CustomAgentMetadataProvider.GetDefaultInitials());
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(CustomAgentMetadataProvider.GetFirstTimeSetupPageId());
    end;

    procedure ShowCanCreateAgent(): Boolean
    begin
        exit(CustomAgentMetadataProvider.ShowCanCreateAgent());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Designer Test Agent");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        CustomAgentMetadataProvider.GetDefaultProfile(TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        CustomAgentMetadataProvider.GetDefaultAccessControls(TempAccessControlBuffer);
    end;
}
