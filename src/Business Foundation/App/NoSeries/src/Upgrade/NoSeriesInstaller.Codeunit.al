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
        TriggerMovedTableSchemaSanityCheck();
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

    /// <summary>
    /// This method is used to ensure that the runtime metadata matches the schema for moved tables.
    /// </summary>
    /// <remarks>
    /// The if .. then statements ensure the code does not fail when the tables are empty. The presence of data is not important, the FindFirst will trigger a schema check.
    /// Should this code fail it would indicate a bug in the server code. The code is not expected to fail.
    /// </remarks>
    internal procedure TriggerMovedTableSchemaSanityCheck()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesTenant: Record "No. Series Tenant";
#if not CLEAN24
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
#endif
        UpgradeTag: Codeunit "Upgrade Tag";
        NoSeriesUpgradeTags: Codeunit "No. Series Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(NoSeriesUpgradeTags.GetMovedTableSchemaSanityCheckUpgradeTag()) then
            exit;

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

        UpgradeTag.SetUpgradeTag(NoSeriesUpgradeTags.GetMovedTableSchemaSanityCheckUpgradeTag());
    end;
}
