// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Substitution;

using System.AI;

codeunit 7331 "Create Product Info. Install"
{
    Access = Internal;
    Subtype = Install;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnInstallAppPerDatabase()
    begin
        UnregisterCapability();
    end;

    local procedure UnregisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Create Product Information") then
            CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Create Product Information");
    end;
}