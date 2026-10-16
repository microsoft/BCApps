#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;

codeunit 10836 "Substitute Report FR"
{
    ObsoleteReason = 'Feature Reports FR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    var
        FRTrialBalanceReports: Codeunit "Reports FR";
    begin
        if not FRTrialBalanceReports.IsEnabled() then
            exit;

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
    end;
}
#endif