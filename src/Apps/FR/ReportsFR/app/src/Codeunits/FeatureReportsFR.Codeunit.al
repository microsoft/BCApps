// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using System.Environment.Configuration;
using System.Upgrade;

#if not CLEAN30
codeunit 10825 "Feature - Reports FR" implements "Feature Data Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature Reports FR will be enabled by default in version 33.0.';
    ObsoleteTag = '30.0';

    procedure IsDataUpdateRequired(): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        // No explicit selection still requires migration of the implicit Base Application default.
        exit(not UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()));
    end;

    procedure ReviewData()
    begin
        Message(DescriptionTxt);
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureKey: Record "Feature Key";
        ReportsFR: Codeunit "Reports FR";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        FeatureDataUpdateStatus.TestField("Feature Key", ReportsFR.GetFeatureKeyId());
        FeatureDataUpdateStatus.TestField("Company Name", CompanyName());
        FeatureKey.Get(ReportsFR.GetFeatureKeyId());
        ReportLayoutsFR.VerifyFeatureMetadata(FeatureKey);
        ReportLayoutsFR.MigrateCheckLayout();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        // Migration and its completion tag precede the framework's Complete status, in one transaction.
        // The framework owns status updates; no other company's status is changed here.
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    var
        DescriptionTxt: Label 'Select the Reports FR Check layout for this company when it uses the Base Application default. Existing custom, user-specific, and other extension layouts are preserved.';
}
#endif
