// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.CRM.Opportunity;
using System.Visualization;

/// <summary>
/// Manages the sales pipeline chart data and navigation between sales cycles.
/// </summary>
codeunit 781 "Sales Pipeline Chart Mgt."
{

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Opens the opportunity entries page filtered by the selected sales cycle stage.
    /// </summary>
    /// <param name="BusinessChartBuffer">The business chart buffer containing drill-down context.</param>
    /// <param name="SalesCycleStage">The sales cycle stage records used to determine filtering.</param>
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

    /// <summary>
    /// Returns the count of opportunity entries for the specified sales cycle and stage.
    /// </summary>
    /// <param name="SalesCycleCode">The sales cycle code to filter by.</param>
    /// <param name="SalesCycleStage">The stage number within the sales cycle.</param>
    /// <returns>The count of matching opportunity entries.</returns>
    procedure GetOppEntryCount(SalesCycleCode: Code[10]; SalesCycleStage: Integer): Integer
    var
        OppEntry: Record "Opportunity Entry";
    begin
        OppEntry.SetRange("Sales Cycle Code", SalesCycleCode);
        OppEntry.SetRange("Sales Cycle Stage", SalesCycleStage);
        OnGetOppEntryCountOnBeforeCount(OppEntry);
        exit(OppEntry.Count);
    end;

    /// <summary>
    /// Populates a temporary table with stages from the specified sales cycle.
    /// </summary>
    /// <param name="TempSalesCycleStage">The temporary table to populate with sales cycle stages.</param>
    /// <param name="SalesCycle">The sales cycle to retrieve stages from.</param>
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

    /// <summary>
    /// Sets the default sales cycle and determines navigation availability.
    /// </summary>
    /// <param name="SalesCycle">The sales cycle record to initialize with the first available cycle.</param>
    /// <param name="NextSalesCycleAvailable">Returns whether a next sales cycle is available.</param>
    /// <param name="PrevSalesCycleAvailable">Returns whether a previous sales cycle is available.</param>
    /// <returns>True if a sales cycle was found, otherwise false.</returns>
    procedure SetDefaultSalesCycle(var SalesCycle: Record "Sales Cycle"; var NextSalesCycleAvailable: Boolean; var PrevSalesCycleAvailable: Boolean): Boolean
    begin
        OnBeforeSetDefaultSalesCycle(SalesCycle);
        if not SalesCycle.FindFirst() then
            exit(false);

        NextSalesCycleAvailable := TryNextSalesCycle(SalesCycle);
        PrevSalesCycleAvailable := TryPrevSalesCycle(SalesCycle);
        exit(true);
    end;

    /// <summary>
    /// Navigates to the previous or next sales cycle and updates availability flags.
    /// </summary>
    /// <param name="SalesCycle">The current sales cycle record to navigate from.</param>
    /// <param name="NextSalesCycleAvailable">Returns whether a next sales cycle is available after navigation.</param>
    /// <param name="PrevSalesCycleAvailable">Returns whether a previous sales cycle is available after navigation.</param>
    /// <param name="Step">The navigation direction: positive for next, negative for previous.</param>
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

    /// <summary>
    /// Updates the chart data with opportunity counts for each sales cycle stage.
    /// </summary>
    /// <param name="BusinessChartBuffer">The business chart buffer to populate with data.</param>
    /// <param name="TempSalesCycleStage">The temporary table to populate with sales cycle stages.</param>
    /// <param name="SalesCycle">The sales cycle to display data for.</param>
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

    /// <summary>
    /// Raised before opening the opportunity entries page during drill-down.
    /// </summary>
    /// <param name="OppEntry">The opportunity entry record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(var OppEntry: Record "Opportunity Entry")
    begin
    end;

    /// <summary>
    /// Raised before selecting the default sales cycle.
    /// </summary>
    /// <param name="SalesCycle">The sales cycle record that will be initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesCycle(var SalesCycle: Record "Sales Cycle")
    begin
    end;

    /// <summary>
    /// Raised before counting opportunity entries for a sales cycle stage.
    /// </summary>
    /// <param name="OppEntry">The opportunity entry record with applied filters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetOppEntryCountOnBeforeCount(var OppEntry: Record "Opportunity Entry")
    begin
    end;

    /// <summary>
    /// Raised before checking if a next sales cycle is available.
    /// </summary>
    /// <param name="NextSalesCycle">The sales cycle record to check for next availability.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTryNextSalesCycleOnBeforeNextSalesCycleFind(var NextSalesCycle: Record "Sales Cycle")
    begin
    end;

    /// <summary>
    /// Raised before checking if a previous sales cycle is available.
    /// </summary>
    /// <param name="PrevSalesCycle">The sales cycle record to check for previous availability.</param>
    [IntegrationEvent(false, false)]
    local procedure OnTryPrevSalesCycleOnBeforePrevSalesCycleFind(var PrevSalesCycle: Record "Sales Cycle")
    begin
    end;
}

