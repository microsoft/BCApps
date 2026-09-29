// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Environment.Configuration;
using System.Media;

codeunit 10030 "IRS Forms Install"
{
    Subtype = Install;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AssistedSetupTxt: Label 'Set up IRS 1099 forms';
        AssistedSetupDescriptionTxt: Label 'Set up 1099 forms to transmit the tax data to the IRS in the United States.';
        AssistedSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?LinkId=2374605', Locked = true;

    trigger OnInstallAppPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if (AppInfo.DataVersion() <> Version.Create('0.0.0.0')) then
            exit;

        SetupFeature();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
        SetupFeature();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', true, true)]
    local procedure InsertIntoAssistedSetup()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        GuidedExperience.InsertAssistedSetup(
            AssistedSetupTxt, CopyStr(AssistedSetupTxt, 1, 50), AssistedSetupDescriptionTxt, 5,
            ObjectType::Page, Page::"IRS Forms Guide", AssistedSetupGroup::FinancialReporting,
            '', VideoCategory::FinancialReporting, AssistedSetupHelpTxt);

        if not IRSReportingPeriod.ReadPermission() then
            exit;
        if not IRSReportingPeriod.IsEmpty() then
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"IRS Forms Guide");
    end;

    local procedure SetupFeature()
    var
        IRSFormsSetup: Record "IRS Forms Setup";
    begin
        IRSFormsSetup.InitSetup();
        IRSFormsSetup.Validate("Collect Details For Line", true);
        IRSFormsSetup.Modify(true);
    end;
}
