// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using System.Utilities;
using System.Visualization;

codeunit 782 "Opportunity Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure DrillDown(var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Record Date; OpportunityStatus: Option)
    var
        Opportunity: Record Opportunity;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesPersonName: Variant;
    begin
        BusinessChartBuffer.GetXValue(BusinessChartBuffer."Drill-Down X Index", SalesPersonName);
        SalespersonPurchaser.SetRange(Name, SalesPersonName);
        SalespersonPurchaser.FindFirst();
        Opportunity.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        Opportunity.Status := "Opportunity Status".FromInteger(OpportunityStatus);
        Opportunity.SetRange(Status, Opportunity.Status);
        case Opportunity.Status of
            Opportunity.Status::"Not Started",
          Opportunity.Status::"In Progress":
                Opportunity.SetRange("Creation Date", 0D, Period."Period End");
            Opportunity.Status::Won,
          Opportunity.Status::Lost:
                Opportunity.SetRange("Date Closed", Period."Period Start", Period."Period End");
        end;
        OnDrillDownOnBeforeRunPage(Opportunity);
        PAGE.Run(PAGE::"Opportunity List", Opportunity);
    end;

    local procedure GetOppCount(Period: Record Date; SalesPersonCode: Code[20]; OpportunityStatus: Option) NumberOfOpp: Integer
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Salesperson Code", SalesPersonCode);
        Opportunity.Status := "Opportunity Status".FromInteger(OpportunityStatus);
        Opportunity.SetRange(Status, Opportunity.Status);
        case Opportunity.Status of
            Opportunity.Status::"Not Started",
          Opportunity.Status::"In Progress":
                Opportunity.SetRange("Creation Date", 0D, Period."Period End");
            Opportunity.Status::Won,
          Opportunity.Status::Lost:
                Opportunity.SetRange("Date Closed", Period."Period Start", Period."Period End");
        end;
        NumberOfOpp := Opportunity.Count;
        OnAfterGetOppCount(Opportunity, NumberOfOpp);
    end;

    procedure SetDefaultOppStatus(var Opportunity: Record Opportunity)
    begin
        Opportunity.Status := Opportunity.Status::"In Progress";
    end;

    procedure SetDefaultPeriod(var Period: Record Date)
    begin
        Period."Period Type" := Period."Period Type"::Month;
        Period."Period Start" := CalcDate('<-CM>', WorkDate());
        Period."Period End" := CalcDate('<CM>', WorkDate());
    end;

    procedure SetNextPeriod(var Period: Record Date)
    begin
        case Period."Period Type" of
            Period."Period Type"::Date:
                Period."Period Start" := CalcDate('<+1D>', Period."Period Start");
            Period."Period Type"::Week:
                Period."Period Start" := CalcDate('<+1W>', Period."Period Start");
            Period."Period Type"::Month:
                Period."Period Start" := CalcDate('<+1M>', Period."Period Start");
            Period."Period Type"::Quarter:
                Period."Period Start" := CalcDate('<+1Q>', Period."Period Start");
            Period."Period Type"::Year:
                Period."Period Start" := CalcDate('<+1Y>', Period."Period Start");
        end;
        SetPeriodRange(Period);
    end;

    procedure SetPrevPeriod(var Period: Record Date)
    begin
        case Period."Period Type" of
            Period."Period Type"::Date:
                Period."Period Start" := CalcDate('<-1D>', Period."Period Start");
            Period."Period Type"::Week:
                Period."Period Start" := CalcDate('<-1W>', Period."Period Start");
            Period."Period Type"::Month:
                Period."Period Start" := CalcDate('<-1M>', Period."Period Start");
            Period."Period Type"::Quarter:
                Period."Period Start" := CalcDate('<-1Q>', Period."Period Start");
            Period."Period Type"::Year:
                Period."Period Start" := CalcDate('<-1Y>', Period."Period Start");
        end;
        SetPeriodRange(Period);
    end;

    procedure SetPeriodRange(var Period: Record Date)
    begin
        case Period."Period Type" of
            Period."Period Type"::Date:
                begin
                    Period."Period Start" := Period."Period Start";
                    Period."Period End" := Period."Period Start";
                end;
            Period."Period Type"::Week:
                begin
                    Period."Period Start" := CalcDate('<-CW>', Period."Period Start");
                    Period."Period End" := CalcDate('<CW>', Period."Period Start");
                end;
            Period."Period Type"::Month:
                begin
                    Period."Period Start" := CalcDate('<-CM>', Period."Period Start");
                    Period."Period End" := CalcDate('<CM>', Period."Period Start");
                end;
            Period."Period Type"::Quarter:
                begin
                    Period."Period Start" := CalcDate('<-CQ>', Period."Period Start");
                    Period."Period End" := CalcDate('<CQ>', Period."Period Start");
                end;
            Period."Period Type"::Year:
                begin
                    Period."Period Start" := CalcDate('<-CY>', Period."Period Start");
                    Period."Period End" := CalcDate('<CY>', Period."Period Start");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateData(var BusinessChartBuffer: Record "Business Chart Buffer"; Period: Record Date; OpportunityStatus: Option)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        I: Integer;
        OppCount: Integer;
    begin
        BusinessChartBuffer.Initialize();
        BusinessChartBuffer.AddIntegerMeasure(SalespersonPurchaser.FieldCaption("No. of Opportunities"), 1, BusinessChartBuffer."Chart Type"::Pie);
        BusinessChartBuffer.SetXAxis(SalespersonPurchaser.TableCaption(), BusinessChartBuffer."Data Type"::String);
        if SalespersonPurchaser.FindSet() then
            repeat
                OppCount := GetOppCount(Period, SalespersonPurchaser.Code, OpportunityStatus);
                if OppCount <> 0 then begin
                    I += 1;
                    BusinessChartBuffer.AddColumn(SalespersonPurchaser.Name);
                    BusinessChartBuffer.SetValueByIndex(0, I - 1, OppCount);
                end;
            until SalespersonPurchaser.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOppCount(var Opportunity: Record "Opportunity"; var NumberOfOpp: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownOnBeforeRunPage(var Opportunity: Record "Opportunity")
    begin
    end;
}

