// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Upgrade;

codeunit 329 "No. Series Installer"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    begin
        TriggerMovedTableSchemaCheck();
        SetupNoSeriesImplementation();
    end;

    local procedure SetupNoSeriesImplementation()
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

    local procedure TriggerMovedTableSchemaCheck()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesTenant: Record "No. Series Tenant";
#if not CLEAN24
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
#endif
    begin
#pragma warning disable AA0175
        if NoSeries.FindFirst() then;
        if NoSeriesLine.FindFirst() then;
        if NoSeriesRelationship.FindFirst() then;
        if NoSeriesTenant.FindFirst() then;
#if not CLEAN24
        if NoSeriesLineSales.FindFirst() then;
        if NoSeriesLinePurchase.FindFirst() then;
#endif
#pragma warning restore AA0175
    end;
}
