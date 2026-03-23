// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Upgrade;

codeunit 149031 "AIT Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    begin
        SetupDefaultCreditLimit();
    end;

    procedure SetupDefaultCreditLimit()
    var
        AITEvalMonthlyCopilotCreditsLimit: Record "AIT Eval Monthly Copilot Cred.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(GetDefaultCreditLimitUpgradeTag()) then
            exit;

        // If the table already has data, just set the upgrade tag.
        if not AITEvalMonthlyCopilotCreditsLimit.IsEmpty() then begin
            UpgradeTag.SetDatabaseUpgradeTag(GetDefaultCreditLimitUpgradeTag());
            exit;
        end;

        // Insert default credit limit setup.
        AITEvalMonthlyCopilotCreditsLimit.Init();
        AITEvalMonthlyCopilotCreditsLimit."Primary Key" := '';
        AITEvalMonthlyCopilotCreditsLimit."Monthly Credit Limit" := 200;
        AITEvalMonthlyCopilotCreditsLimit."Enforcement Enabled" := true;
        AITEvalMonthlyCopilotCreditsLimit.Insert();

        UpgradeTag.SetDatabaseUpgradeTag(GetDefaultCreditLimitUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure OnGetPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetDefaultCreditLimitUpgradeTag());
    end;

    local procedure GetDefaultCreditLimitUpgradeTag(): Code[250]
    begin
        exit('MS-AITestToolkit-InsertDefaultCreditLimit-20260318');
    end;
}
