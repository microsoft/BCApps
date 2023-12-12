// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Upgrade;

codeunit 331 "No. Series Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerCompany()
    begin
        SetupNoSeriesImplementation();
    end;

    internal procedure SetupNoSeriesImplementation()
    var
        NoSeriesLine: Record "No. Series Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        NoSeriesUpgradeTags: Codeunit "No. Series Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(NoSeriesUpgradeTags.GetImplementationUpgradeTag()) then
            exit;

        NoSeriesLine.SetRange("Allow Gaps in Nos.", true);
        NoSeriesLine.ModifyAll(Implementation, "No. Series Implementation"::Sequence, false);
        NoSeriesLine.SetRange("Allow Gaps in Nos.", false);
        NoSeriesLine.ModifyAll(Implementation, "No. Series Implementation"::Normal, false);

        UpgradeTag.SetUpgradeTag(NoSeriesUpgradeTags.GetImplementationUpgradeTag());
    end;
}
