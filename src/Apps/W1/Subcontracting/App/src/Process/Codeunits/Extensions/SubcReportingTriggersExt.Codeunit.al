// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Environment;

codeunit 99001512 "Subc. Reporting Triggers Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", SubstituteReport, '', false, false)]
    local procedure SubstituteDetailedCalculation(ReportId: Integer; var NewReportId: Integer)
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if ReportId = Report::"Subc. Detailed Calculation" then
            NewReportId := Report::"Subc. Detailed Calculation";
    end;
}