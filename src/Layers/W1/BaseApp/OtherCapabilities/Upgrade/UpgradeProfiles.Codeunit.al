// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment.Configuration;
using System.Upgrade;

/// <summary>
/// Upgrade code to insert new profiles or modify existing profiles.
/// </summary>
codeunit 104047 "Upgrade Profiles"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        BaseAppAppId := '437DBF0E-84FF-417A-965D-ED2BB9650972';
        UpgradeEmployeeProfile();
    end;

    local procedure UpgradeEmployeeProfile()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDef: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDef.GetEmployeeProfileUpgradeTag()) then
            exit;

        CreateTenantProfile(BaseAppAppId, EmployeeProfileIDTxt, EmployeeProfileDescriptionTxt, 8999, false); // Blank Role Center ID = 8999

        UpgradeTag.SetUpgradeTag(UpgradeTagDef.GetEmployeeProfileUpgradeTag());
    end;

    local procedure CreateTenantProfile(AppId: Guid; ProfileId: Code[30]; Description: Text[250]; RoleCenterID: Integer; Enabled: Boolean)
    var
        TenantProfile: Record "Tenant Profile";
        InsertSuccessful: Boolean;
    begin
        TenantProfile."App ID" := AppId;
        TenantProfile."Profile ID" := ProfileId;
        TenantProfile.Description := Description;
        TenantProfile."Role Center ID" := RoleCenterID;
        TenantProfile."Disable Personalization" := Enabled;
        InsertSuccessful := TenantProfile.Insert();
        Session.LogMessage('0000A40', StrSubstNo(TelemetryResultTxt, Format(InsertSuccessful)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    var
        TelemetryCategoryTok: Label 'AL Upg Profiles', Locked = true;
        EmployeeProfileIDTxt: Label 'EMPLOYEE', Locked = true;
        EmployeeProfileDescriptionTxt: Label 'Gives people who have a license for Teams read-only access to data in Business Central.';
        TelemetryResultTxt: Label 'Per database upgrade attempt of Employee profile has been completed. Result: %1.', Comment = '%1 = Upgrade result', Locked = true;
        BaseAppAppId: Guid;
}