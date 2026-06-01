#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Upgrade;

codeunit 328 "No. Series Upgrade"
{
    Access = Internal;
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

        NoSeriesLine.SetRange(Implementation, 0); // Only update the No. Series Lines that are still referencing the default implementation (0)
        NoSeriesLine.SetRange("Allow Gaps in Nos.", true);
        NoSeriesLine.ModifyAll(Implementation, "No. Series Implementation"::Sequence, false);

        UpgradeTag.SetUpgradeTag(NoSeriesUpgradeTags.GetImplementationUpgradeTag());
    end;
}
#endif