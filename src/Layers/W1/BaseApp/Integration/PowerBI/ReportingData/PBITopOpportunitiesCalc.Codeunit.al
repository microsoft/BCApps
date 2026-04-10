// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.CRM.Opportunity;

codeunit 6310 "PBI Top Opportunities Calc."
{

    trigger OnRun()
    begin
    end;

    procedure GetValues(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        CalcTopFiveOpportunities(TempOpportunity);
        TempOpportunity.SetAutoCalcFields("Estimated Value (LCY)");
        if TempOpportunity.FindSet() then
            repeat
                InsertToBuffer(TempPowerBIChartBuffer, TempOpportunity);
            until TempOpportunity.Next() = 0;
    end;

    local procedure CalcTopFiveOpportunities(var TempOpportunity: Record Opportunity temporary)
    var
        Opportunity: Record Opportunity;
    begin
        TempOpportunity.DeleteAll();
        Opportunity.SetAutoCalcFields("Estimated Value (LCY)");
        Opportunity.SetRange(Closed, false);
        Opportunity.SetCurrentKey("Estimated Value (LCY)");
        Opportunity.Ascending(false);
        if Opportunity.FindSet() then
            repeat
                TempOpportunity := Opportunity;
                TempOpportunity.Insert();
            until Opportunity.Next() = 0;
    end;

    local procedure InsertToBuffer(var TempPowerBIChartBuffer: Record "Power BI Chart Buffer" temporary; TempOpportunity: Record Opportunity temporary)
    begin
        if TempPowerBIChartBuffer.FindLast() then
            TempPowerBIChartBuffer.ID += 1
        else
            TempPowerBIChartBuffer.ID := 1;
        TempPowerBIChartBuffer.Value := TempOpportunity."Estimated Value (LCY)";
        TempPowerBIChartBuffer."Measure Name" := TempOpportunity.Description;
        TempPowerBIChartBuffer."Measure No." := TempOpportunity."No.";
        TempPowerBIChartBuffer.Insert();
    end;
}

