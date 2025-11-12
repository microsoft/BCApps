// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.CRM.Opportunity;
using System.Visualization;

codeunit 781 "Sales Pipeline Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    procedure DrillDown(var BusinessChartBuffer: Record "Business Chart Buffer"; var SalesCycleStage: Record "Sales Cycle Stage")
    var
        OppEntry: Record "Opportunity Entry";
    begin
        if SalesCycleStage.FindSet() then begin
            SalesCycleStage.Next(BusinessChartBuffer."Drill-Down X Index");
            OppEntry.SetRange("Sales Cycle Code", SalesCycleStage."Sales Cycle Code");
            OppEntry.SetRange("Sales Cycle Stage", SalesCycleStage.Stage);
            OnBeforeDrillDown(OppEntry);
            PAGE.Run(PAGE::"Opportunity Entries", OppEntry);
        end;
    end;

    procedure GetOppEntryCount(SalesCycleCode: Code[10]; SalesCycleStage: Integer): Integer
    var
        OppEntry: Record "Opportunity Entry";
    begin
        OppEntry.SetRange("Sales Cycle Code", SalesCycleCode);
        OppEntry.SetRange("Sales Cycle Stage", SalesCycleStage);
        OnGetOppEntryCountOnBeforeCount(OppEntry);
        exit(OppEntry.Count);
    end;

    procedure InsertTempSalesCycleStage(var TempSalesCycleStage: Record "Sales Cycle Stage" temporary; SalesCycle: Record "Sales Cycle")
    var
        SourceSalesCycleStage: Record "Sales Cycle Stage";
    begin
        TempSalesCycleStage.Reset();
        TempSalesCycleStage.DeleteAll();

        SourceSalesCycleStage.SetRange("Sales Cycle Code", SalesCycle.Code);
        if SourceSalesCycleStage.FindSet() then
            repeat
                TempSalesCycleStage := SourceSalesCycleStage;
                TempSalesCycleStage.Insert();
            until SourceSalesCycleStage.Next() = 0;
    end;

    procedure SetDefaultSalesCycle(var SalesCycle: Record "Sales Cycle"; var NextSalesCycleAvailable: Boolean; var PrevSalesCycleAvailable: Boolean): Boolean
    begin
        OnBeforeSetDefaultSalesCycle(SalesCycle);
        if not SalesCycle.FindFirst() then
            exit(false);

        NextSalesCycleAvailable := TryNextSalesCycle(SalesCycle);
        PrevSalesCycleAvailable := TryPrevSalesCycle(SalesCycle);
        exit(true);
    end;

    procedure SetPrevNextSalesCycle(var SalesCycle: Record "Sales Cycle"; var NextSalesCycleAvailable: Boolean; var PrevSalesCycleAvailable: Boolean; Step: Integer)
    begin
        SalesCycle.Next(Step);
        NextSalesCycleAvailable := TryNextSalesCycle(SalesCycle);
        PrevSalesCycleAvailable := TryPrevSalesCycle(SalesCycle);
    end;

    local procedure TryNextSalesCycle(CurrentSalesCycle: Record "Sales Cycle"): Boolean
    var
        NextSalesCycle: Record "Sales Cycle";
    begin
        NextSalesCycle := CurrentSalesCycle;
        OnTryNextSalesCycleOnBeforeNextSalesCycleFind(NextSalesCycle);
        NextSalesCycle.Find('=><');
        exit(NextSalesCycle.Next() <> 0);
    end;

    local procedure TryPrevSalesCycle(CurrentSalesCycle: Record "Sales Cycle"): Boolean
    var
        PrevSalesCycle: Record "Sales Cycle";
    begin
        PrevSalesCycle := CurrentSalesCycle;
        OnTryPrevSalesCycleOnBeforePrevSalesCycleFind(PrevSalesCycle);
        PrevSalesCycle.Find('=><');
        exit(PrevSalesCycle.Next(-1) <> 0);
    end;

    [Scope('OnPrem')]
    procedure UpdateData(var BusinessChartBuffer: Record "Business Chart Buffer"; var TempSalesCycleStage: Record "Sales Cycle Stage" temporary; SalesCycle: Record "Sales Cycle")
    var
        I: Integer;
    begin
        BusinessChartBuffer.Initialize();
        BusinessChartBuffer.AddIntegerMeasure(TempSalesCycleStage.FieldCaption("No. of Opportunities"), 1, BusinessChartBuffer."Chart Type"::Funnel);
        BusinessChartBuffer.SetXAxis(TempSalesCycleStage.TableCaption(), BusinessChartBuffer."Data Type"::String);
        InsertTempSalesCycleStage(TempSalesCycleStage, SalesCycle);
        if TempSalesCycleStage.FindSet() then
            repeat
                I += 1;
                BusinessChartBuffer.AddColumn(TempSalesCycleStage.Description);
                BusinessChartBuffer.SetValueByIndex(0, I - 1, GetOppEntryCount(TempSalesCycleStage."Sales Cycle Code", TempSalesCycleStage.Stage));
            until TempSalesCycleStage.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(var OppEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesCycle(var SalesCycle: Record "Sales Cycle")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOppEntryCountOnBeforeCount(var OppEntry: Record "Opportunity Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryNextSalesCycleOnBeforeNextSalesCycleFind(var NextSalesCycle: Record "Sales Cycle")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTryPrevSalesCycleOnBeforePrevSalesCycleFind(var PrevSalesCycle: Record "Sales Cycle")
    begin
    end;
}

