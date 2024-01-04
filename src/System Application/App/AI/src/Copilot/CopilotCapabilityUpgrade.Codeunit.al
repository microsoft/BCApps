// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

codeunit 7776 "Copilot Capability Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        CopilotCapabilityInstall: Codeunit "Copilot Capability Install";
    begin
        CopilotCapabilityInstall.RegisterCapabilities();
    end;
}