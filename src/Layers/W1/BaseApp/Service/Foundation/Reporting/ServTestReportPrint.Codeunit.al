// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Sales.Setup;
using Microsoft.Service.Document;

codeunit 6462 "Serv. Test Report Print"
{
    procedure PrintServiceHeader(NewServiceHeader: Record "Service Header")
    var
        ReportSelections: Record "Report Selections";
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader := NewServiceHeader;
        ServiceHeader.SetRecFilter();
        CalcServDisc(ServiceHeader);
        ReportSelections.PrintWithCheckForCust(
            ReportSelections.Usage::"SM.Test", ServiceHeader, ServiceHeader.FieldNo("Bill-to Customer No."));
    end;

    local procedure CalcServDisc(var ServHeader: Record "Service Header")
    var
        ServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            ServLine.Reset();
            ServLine.SetRange("Document Type", ServHeader."Document Type");
            ServLine.SetRange("Document No.", ServHeader."No.");
            ServLine.FindFirst();
            OnCalcServDiscOnBeforeRun(ServHeader, ServLine);
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServLine);
            ServHeader.Get(ServHeader."Document Type", ServHeader."No.");
            Commit();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcServDiscOnBeforeRun(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;
}