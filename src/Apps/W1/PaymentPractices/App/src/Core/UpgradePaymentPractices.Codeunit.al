// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Upgrade;

codeunit 683 "Upgrade Payment Practices"
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";

    trigger OnUpgradePerCompany()
    begin
        BackfillReportingScheme();
    end;

    local procedure BackfillReportingScheme()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
    begin
        if UpgradeTag.HasUpgradeTag(GetReportingSchemeUpgradeTag()) then
            exit;

        ReportingScheme := PaymentPeriodMgt.DetectReportingScheme();

        PaymentPracticeHeader.SetRange("Reporting Scheme", 0);
        PaymentPracticeHeader.ModifyAll("Reporting Scheme", ReportingScheme);

        UpgradeTag.SetUpgradeTag(GetReportingSchemeUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetReportingSchemeUpgradeTag());
    end;

    procedure GetReportingSchemeUpgradeTag(): Code[250]
    begin
        exit('MS-597313-PaymPracReportingScheme-20260513');
    end;
}
