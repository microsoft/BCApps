// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Reporting;
#if not CLEAN30
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;
#endif

codeunit 10836 "Substitute Report FR"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    var
        FinancialScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
#if not CLEAN30
#pragma warning disable AL0432
        FRTrialBalanceReports: Codeunit "Reports FR";
#pragma warning restore AL0432
#endif
    begin
        if FinancialScheduleMgt.IsEnabled() then
            case ReportId of
                10811:
                    begin
                        NewReportId := Report::"FR Financial Schedule";
                        exit;
                    end;
                10842:
                    begin
                        NewReportId := Report::"G/L Account Statement FR";
                        exit;
                    end;
            end;
#if not CLEAN30
        if not FRTrialBalanceReports.IsEnabled() then
            exit;

#pragma warning disable AL0432
        case ReportId of
            Report::"Customer Detail Trial Balance":
                NewReportId := Report::"Cust. Detail Trial Balance";
            Report::"Vendor Trial Balance FR":
                NewReportId := Report::"Vendor Trial Balance";
            Report::"Customer Trial Balance FR":
                NewReportId := Report::"Customer Trial Balance";
            Report::"Vendor Detail Trial Balance FR":
                NewReportId := Report::"Vendor Detail Trial Balance";
            Report::"G/L Trial Balance":
                NewReportId := Report::"G/L Trial Balance FR";
            Report::"G/L Detail Trial Balance":
                NewReportId := Report::"G/L Detail Trial Balance FR";
            Report::"Bank Account Trial Balance":
                NewReportId := Report::"Bank Acc. Trial Balance";
            Report::"Bank Account Journal":
                NewReportId := Report::"Bank Account Journal FR";
            Report::"Customer Journal":
                NewReportId := Report::"Customer Journal FR";
            Report::"G/L Journal":
                NewReportId := Report::"G/L Journal FR";
            Report::"Vendor Journal":
                NewReportId := Report::"Vendor Journal FR";
            Report::Journals:
                NewReportId := Report::"Journals FR";
            Report::"Bank Acc. Detail Trial Balance":
                NewReportId := Report::"Bank Acc. Det. Trial Balance";
        end;
#pragma warning restore AL0432
#endif
    end;
}