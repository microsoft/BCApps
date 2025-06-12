// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Upgrade;
// start of <todo>
// TODO: Uncomment this once the semantic search is implemented in production.
// using System.Environment;
// end of <todo>

codeunit 327 "No. Series Copilot Register"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure HandleOnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        // start of <todo>
        // TODO: Uncomment this once the semantic search is implemented in production.
        // EnvironmentInformation: Codeunit "Environment Information";
        // end of <todo>
        UpgradeTag: Codeunit "Upgrade Tag";
        NoSeriesCopilotUpgradeTags: Codeunit "No. Series Copilot Upgr. Tags";
    begin
        // start of <todo>
        // TODO: Uncomment this once the semantic search is implemented in production.
        // if not EnvironmentInformation.IsSaaSInfrastructure() then
        //     exit;
        // end of <todo>

        if UpgradeTag.HasUpgradeTag(NoSeriesCopilotUpgradeTags.GetImplementationUpgradeTag()) then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"No. Series Copilot") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"No. Series Copilot", LearnMoreUrlTxt);

        UpgradeTag.SetUpgradeTag(NoSeriesCopilotUpgradeTags.GetImplementationUpgradeTag());
    end;

    var
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2294514', Locked = true;

}