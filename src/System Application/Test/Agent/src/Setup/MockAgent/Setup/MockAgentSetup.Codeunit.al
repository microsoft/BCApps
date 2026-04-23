// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

codeunit 133951 "Mock Agent Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        Agent: Codeunit Agent;
        CurrentModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);
        Agent.PopulateDefaultProfile(DefaultProfileTok, CurrentModule.Id, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := ModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := DefaultRoleIdTok;
        TempAccessControlBuffer.Insert();
    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Mock Agent") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Mock Agent", '');
    end;

    var
        DefaultProfileTok: Label 'Agent SDK Test', Locked = true;
        DefaultRoleIdTok: Label 'Agent SDK Test', Locked = true;
}
