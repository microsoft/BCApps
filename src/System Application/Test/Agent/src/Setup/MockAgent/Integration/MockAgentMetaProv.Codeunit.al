// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

codeunit 133952 "Mock Agent Meta. Prov." implements IAgentMetadata, IAgentFactory
{
    InherentEntitlements = X;
    InherentPermissions = X;

    Access = Internal;

    var
        MockAgentSetup: Codeunit "Mock Agent Setup";
        MockAgentInitialLbl: Label 'MA', MaxLength = 4;

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(MockAgentInitialLbl);
    end;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit('MOCK');
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(0); // No setup page for mock agent
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(0); // No setup page for mock agent
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(0);
    end;

    procedure ShowCanCreateAgent(): Boolean
    begin
        exit(true);
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Mock Agent");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations);
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(Page::"Agent Task Message Card");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    begin
        MockAgentSetup.GetDefaultProfile(TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        MockAgentSetup.GetDefaultAccessControls(TempAccessControlBuffer);
    end;
}
