// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Reporting;

codeunit 99000817 "Manu. Print Report"
{

    trigger OnRun()
    begin
    end;

    var
        ReportSelections: Record "Report Selections";
        ProductionOrder: Record "Production Order";

    procedure PrintProductionOrder(NewProductionOrder: Record "Production Order"; Usage: Option)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintProductionOrder(NewProductionOrder, Usage, IsHandled);
        if IsHandled then
            exit;

        ProductionOrder := NewProductionOrder;
        ProductionOrder.SetRecFilter();

        ReportSelections.PrintWithCheckForCust(ConvertUsage(Usage), ProductionOrder, 0);
    end;

    local procedure ConvertUsage(Usage: Option): Enum "Report Selection Usage"
    var
        ResultReportSelectionUsage: Enum "Report Selection Usage";
    begin
        case Usage of
            0:
                exit(ResultReportSelectionUsage::M1);
            1:
                exit(ResultReportSelectionUsage::M2);
            2:
                exit(ResultReportSelectionUsage::M3);
            3:
                exit(ResultReportSelectionUsage::M4);
            else begin
                OnConvertUsageOnUsageCaseElse(Usage, ResultReportSelectionUsage);
                exit(ResultReportSelectionUsage);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintProductionOrder(NewProductionOrder: Record "Production Order"; Usage: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnConvertUsageOnUsageCaseElse(Usage: Option; var ReportSelectionUsage: Enum "Report Selection Usage")
    begin
    end;
}

