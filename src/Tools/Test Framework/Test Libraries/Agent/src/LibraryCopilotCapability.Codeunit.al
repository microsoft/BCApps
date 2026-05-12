// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.AI;

using System.AI;

/// <summary>
/// Provides utility functions for managing copilot capabilities beyond the scope of the Copilot Capability codeunit.
/// </summary>
codeunit 130564 "Library - Copilot Capability"
{
    Permissions = tabledata "Copilot Settings" = rm;

    /// <summary>
    /// Activates a copilot capability defined by the specified extension.
    /// </summary>
    /// <param name="Capability">The copilot capability to activate.</param>
    /// <param name="AppId">The application ID of the extension defining the copilot capability.</param>
    procedure ActivateCopilotCapability(Capability: Enum "Copilot Capability"; AppId: Guid)
    var
        CopilotSettings: Record "Copilot Settings";
    begin
        if CopilotSettings.Get(Capability, AppId) then
            if CopilotSettings.Status = CopilotSettings.Status::Active then
                exit
            else begin
                CopilotSettings.Status := CopilotSettings.Status::Active;
                CopilotSettings.Modify();
                exit;
            end;

        RegisterCopilotCapabilityWithAppId(Capability, AppId);
    end;

    local procedure RegisterCopilotCapabilityWithAppId(Capability: Enum "Copilot Capability"; AppId: Guid)
    var
        CopilotSettings: Record "Copilot Settings";
        CopilotCapability: Codeunit "Copilot Capability";
        ModuleInfo: ModuleInfo;
    begin
        CopilotCapability.RegisterCapability(Capability, '');

        NavApp.GetCurrentModuleInfo(ModuleInfo);
        if CopilotSettings.Get(Capability, ModuleInfo.Id) then begin
            CopilotSettings.Rename(Capability, AppId);
            CopilotSettings.Status := CopilotSettings.Status::Active;
            CopilotSettings.Modify();
            Commit();
        end;
    end;
}