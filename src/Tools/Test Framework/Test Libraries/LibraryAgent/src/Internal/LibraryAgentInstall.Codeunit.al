// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.AI;
using System.TestLibraries.AI;

codeunit 130562 "Library - Agent Install"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        LibraryCopilotCapability: Codeunit "Library - Copilot Capability";
        LibraryAgentUtilities: Codeunit "Library - Agent Utilities";
        AppInfo: ModuleInfo;
    begin
        LibraryAgentUtilities.VerifyCanRunOnCurrentEnvironment();
        NavApp.GetCurrentModuleInfo(AppInfo);
        LibraryCopilotCapability.ActivateCopilotCapability(Enum::"Copilot Capability"::"Agent Test LLM Judge", AppInfo.Id);
    end;
}