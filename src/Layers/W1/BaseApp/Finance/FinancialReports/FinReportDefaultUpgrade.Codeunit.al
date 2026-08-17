#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Foundation.Enums;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 1081 "Fin. Report Default Upgrade"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    ObsoleteReason = 'This upgrade code will be removed in a future release.';

    var
        HybridDeployment: Codeunit System.Environment."Hybrid Deployment";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";

    trigger OnUpgradePerCompany()
    var
        FinancialReport: Record "Financial Report";
        FinancialReportUserFilters: Record "Financial Report User Filters";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        FinancialReport.SetFilter(PeriodTypeDefault, '<>%1', FinancialReport.PeriodTypeDefault::Default);
        if not FinancialReport.IsEmpty() then
            exit;
        FinancialReport.SetRange(PeriodTypeDefault);
        FinancialReport.SetFilter(NegativeAmountFormatDefault, '<>%1', FinancialReport.NegativeAmountFormatDefault::Default);
        if not FinancialReport.IsEmpty() then
            exit;

        FinancialReportUserFilters.SetFilter(PeriodTypeDefault, '<>%1', FinancialReportUserFilters.PeriodTypeDefault::Default);
        if not FinancialReportUserFilters.IsEmpty() then
            exit;
        FinancialReportUserFilters.SetRange(PeriodTypeDefault);
        FinancialReportUserFilters.SetFilter(NegativeAmountFormatDefault, '<>%1', FinancialReportUserFilters.NegativeAmountFormatDefault::Default);
        if not FinancialReportUserFilters.IsEmpty() then
            exit;

        UpdateData();
    end;

    procedure UpdateData()
    var
        FinancialReport: Record "Financial Report";
        FinancialReportUserFilters: Record "Financial Report User Filters";
        DataUpgradeExecuted: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetFinancialReportDefaultsUpgradeTag()) then
            exit;

        if FinancialReport.FindSet(true) then begin
            repeat
                FinancialReport.PeriodTypeDefault := "Financial Report Period Type".FromInteger(FinancialReport.PeriodType.AsInteger());
                FinancialReport.NegativeAmountFormatDefault := "Fin. Report Negative Format".FromInteger(FinancialReport.NegativeAmountFormat.AsInteger());
                FinancialReport.Modify();
            until FinancialReport.Next() = 0;
            DataUpgradeExecuted := true;
        end;

        if FinancialReportUserFilters.FindSet(true) then begin
            repeat
                FinancialReportUserFilters.PeriodTypeDefault := "Financial Report Period Type".FromInteger(FinancialReportUserFilters.PeriodType.AsInteger());
                FinancialReportUserFilters.NegativeAmountFormatDefault := "Fin. Report Negative Format".FromInteger(FinancialReportUserFilters.NegativeAmountFormat.AsInteger());
                FinancialReportUserFilters.Modify();
            until FinancialReportUserFilters.Next() = 0;
            DataUpgradeExecuted := true;
        end;

        SetUpgradeTag(DataUpgradeExecuted);
    end;

    procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    begin
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetFinancialReportDefaultsUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgradeTagDefinitions.GetFinancialReportDefaultsUpgradeTag(), true);
    end;
}
#endif