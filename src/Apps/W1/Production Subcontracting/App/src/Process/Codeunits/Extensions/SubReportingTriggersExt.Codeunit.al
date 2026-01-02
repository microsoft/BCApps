// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Environment;

codeunit 99001512 "Sub. Reporting Triggers Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", SubstituteReport, '', false, false)]
    local procedure SubstituteDetailedCalculation(ReportId: Integer; var NewReportId: Integer)
    begin
        if ReportId = Report::"Sub. Detailed Calculation" then
            NewReportId := Report::"Sub. Detailed Calculation";
    end;
}