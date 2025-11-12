// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Reports;

codeunit 99000797 "Mfg. Document Print"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnAfterInitReportSelectionProd', '', false, false)]
    local procedure OnAfterInitReportSelectionProd()
    begin
        InsertRepSelection("Report Selection Usage"::"Prod.Order", '1', REPORT::"Prod. Order - Job Card");
        InsertRepSelection("Report Selection Usage"::M1, '1', REPORT::"Prod. Order - Job Card");
        InsertRepSelection("Report Selection Usage"::M2, '1', REPORT::"Prod. Order - Mat. Requisition");
        InsertRepSelection("Report Selection Usage"::M3, '1', REPORT::"Prod. Order - Shortage List");
        InsertRepSelection("Report Selection Usage"::"Prod. Output Item Label", '1', REPORT::"Output Item Label");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnInitReportUsage', '', false, false)]
    local procedure OnInitReportUsage(ReportUsage: Integer)
    begin
        case "Report Selection Usage".FromInteger(ReportUsage) of
            "Report Selection Usage"::"Prod.Order":
                InsertRepSelection("Report Selection Usage"::"Prod.Order", '1', REPORT::"Prod. Order - Job Card");
            "Report Selection Usage"::M1:
                InsertRepSelection("Report Selection Usage"::M1, '1', REPORT::"Prod. Order - Job Card");
            "Report Selection Usage"::M2:
                InsertRepSelection("Report Selection Usage"::M2, '1', REPORT::"Prod. Order - Mat. Requisition");
            "Report Selection Usage"::M3:
                InsertRepSelection("Report Selection Usage"::M3, '1', REPORT::"Prod. Order - Shortage List");
            "Report Selection Usage"::"Prod. Output Item Label":
                InsertRepSelection("Report Selection Usage"::"Prod. Output Item Label", '1', REPORT::"Output Item Label");
        end;
    end;

    local procedure InsertRepSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;
    end;
}
