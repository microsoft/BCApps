// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Environment;
using System.Environment.Configuration;

/// <summary>
/// Seeds shipped Composite Layout themes and header/footer parts on company open for new tenants
/// provisioned from a pre-built database image where BaseApp is installed but OnInstallAppPerDatabase
/// may not have run. Gracefully handles missing permissions without blocking company open.
/// </summary>
codeunit 104065 "Composite Report Parts Seeding On Open"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure OnCompanyOpen()
    begin
        SeedDefaultReportPartsIfMissing();
    end;

    local procedure SeedDefaultReportPartsIfMissing()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        // Exit gracefully if no write permissions - OnCompanyOpen should not fail due to permissions
        if not TenantReportLayout.WritePermission() then
            exit;

        // Exit if parts already exist
        if PartAlreadySeeded(CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID(), CompositeReportPartsMgt.GetShippedPartAppId()) then
            exit;

        // Seed the parts using the standard seeding procedure
        UpgradeCompositeReportParts.SeedShippedParts();
    end;

    local procedure PartAlreadySeeded(ReportID: Integer; AppId: Guid): Boolean
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        TenantReportLayout.SetRange("Report ID", ReportID);
        TenantReportLayout.SetRange("App ID", AppId);
        exit(not TenantReportLayout.IsEmpty());
    end;
}
