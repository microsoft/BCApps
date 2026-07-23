#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 10808 "Substitute Report"
{
    ObsoleteReason = 'Feature SalesFR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    var
        SalesFR: Codeunit "Sales FR";
    begin
        if not SalesFR.IsEnabled() then
            exit;

        case ReportId of
            Report::"Standard Sales - Draft Invoice":
                NewReportId := Report::"Stand. Sales-Draft Invoice FR";
            Report::"Standard Sales - Credit Memo":
                NewReportId := Report::"Standard Sales-Credit Memo FR";
            Report::"Standard Sales - Invoice":
                NewReportId := Report::"Standard Sales - Invoice FR";
        end;
    end;
}
#endif
