// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Upgrade;

codeunit 7776 "Copilot Capability Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        CopilotCapabilityInstall: Codeunit "Copilot Capability Install";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        CopilotCapabilityInstall.RegisterCapabilities();

        if not UpgradeTag.HasUpgradeTag(GetAddBillingTypeToCapabilityTag()) then begin
            CopilotCapabilityInstall.ModifyCapabilities();
            UpgradeTag.SetUpgradeTag(GetAddBillingTypeToCapabilityTag());
        end;
    end;

    internal procedure GetAddBillingTypeToCapabilityTag(): Text[250]
    begin
        exit('MS-581366-AddBillingTypeToCapabilityTag-20250731');
    end;
}