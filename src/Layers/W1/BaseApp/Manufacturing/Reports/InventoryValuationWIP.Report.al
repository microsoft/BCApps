// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using System.Utilities;

report 5802 "Inventory Valuation - WIP"
{
    ApplicationArea = Manufacturing;
    Caption = 'Production Order - WIP';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = WordLayout;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = where(Status = filter(Released ..));
            PrintOnlyIfDetail = true;
            RequestFilterFields = Status, "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ProdOrderFilter; ProdOrderFilter)
            {
            }
            column(StartDate; StartDateText)
            {
            }
            column(EndDate; EndDate)
            {
            }
            column(AsOfStartDateText; StrSubstNo(Text005, StartDateText))
            {
            }
            column(AsofEndDate; StrSubstNo(Text005, Format(EndDate)))
            {
            }
            column(No_ProductionOrder; "No.")
            {
                IncludeCaption = true;
            }
            column(SourceNo_ProductionOrder; "Source No.")
            {
                IncludeCaption = true;
            }
            column(SrcType_ProductionOrder; "Source Type")
            {
                IncludeCaption = true;
            }
            column(Desc_ProductionOrder; Description)
            {
                IncludeCaption = true;
            }
            column(Status_ProductionOrder; Status)
            {
                IncludeCaption = true;
            }
            column(InventoryValuationWIPCptn; InventoryValuationWIPCptnLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ValueOfCapCaption; ValueOfCapCaptionLbl)
            {
            }
            column(ValueOfOutputCaption; ValueOfOutputCaptionLbl)
            {
            }
            column(ValueEntryCostPostedtoGLCaption; ValueEntryCostPostedtoGLCaptionLbl)
            {
            }
            column(ValueOfMatConsumpCaption; ValueOfMatConsumpCaptionLbl)
            {
            }
            column(ProductionOrderNoCaption; ProductionOrderNoCaptionLbl)
            {
            }
            column(ProdOrderStatusCaption; ProdOrderStatusCaptionLbl)
            {
            }
            column(ProdOrderDescriptionCaption; ProdOrderDescriptionCaptionLbl)
            {
            }
            column(ProdOrderSourceTypeCaptn; ProdOrderSourceTypeCaptnLbl)
            {
            }
            column(ProdOrderSourceNoCaption; ProdOrderSourceNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemTableView = sorting("Order Type", "Order No.");
                column(ValueEntryCostPostedtoGL; TotalValueOfCostPstdToGL)
                {
                    AutoFormatType = 1;
                }
                column(ValueOfOutput; TotalValueOfOutput)
                {
                    AutoFormatType = 1;
                }
                column(ValueOfCap; TotalValueOfCap)
                {
                    AutoFormatType = 1;
                }
                column(ValueOfMatConsump; TotalValueOfMatConsump)
                {
                    AutoFormatType = 1;
                }
                column(ValueOfWIP; TotalValueOfWIP)
                {
                    AutoFormatType = 1;
                }
                column(LastOutput; TotalLastOutput)
                {
                }
                column(AtLastDate; TotalAtLastDate)
                {
                }
                column(LastWIP; TotalLastWIP)
                {
                }
                trigger OnAfterGetRecord()
                var
                    IsHandled: Boolean;
                begin
                    CountRecord := CountRecord + 1;
                    LastOutput := 0;
                    AtLastDate := 0;
                    LastWIP := 0;

                    if (CountRecord = LengthRecord) and IsNotWIP() then begin
                        ValueEntryOnPostDataItem();

                        AtLastDate := NcValueOfWIP + NcValueOfMatConsump + NcValueOfCap + NcValueOfOutput;
                        LastOutput := NcValueOfOutput;
                        LastWIP := NcValueOfWIP;
                        ValueOfCostPstdToGL := NcValueOfCostPstdToGL;

                        NcValueOfWIP := 0;
                        NcValueOfOutput := 0;
                        NcValueOfMatConsump := 0;
                        NcValueOfCap := 0;
                        NcValueOfInvOutput1 := 0;
                        NcValueOfExpOutPut1 := 0;
                        NcValueOfExpOutPut2 := 0;
                        NcValueOfRevalCostAct := 0;
                        NcValueOfRevalCostPstd := 0;
                        NcValueOfCostPstdToGL := 0;
                    end;

                    if not IsNotWIP() then begin
                        ValueOfWIP := 0;
                        ValueOfMatConsump := 0;
                        ValueOfCap := 0;
                        ValueOfOutput := 0;
                        ValueOfInvOutput1 := 0;
                        ValueOfExpOutput1 := 0;
                        ValueOfExpOutput2 := 0;
                        if EntryFound then
                            ValueOfCostPstdToGL := "Cost Posted to G/L";

                        if "Posting Date" < StartDate then begin
                            if "Item Ledger Entry Type" = "Item Ledger Entry Type"::" " then
                                ValueOfWIP := "Cost Amount (Actual)"
                            else
                                ValueOfWIP := -"Cost Amount (Actual)";
                            if "Item Ledger Entry Type" = "Item Ledger Entry Type"::Output then begin
                                ValueOfExpOutput1 := -"Cost Amount (Expected)";
                                ValueOfInvOutput1 := -"Cost Amount (Actual)";
                                ValueOfWIP := ValueOfExpOutput1 + ValueOfInvOutput1;
                            end;

                            if ("Entry Type" = "Entry Type"::Revaluation) and ("Cost Amount (Actual)" <> 0) then
                                ValueOfWIP := 0;
                        end else
                            case "Item Ledger Entry Type" of
                                "Item Ledger Entry Type"::Consumption:
                                    if IsProductionCost("Value Entry") then
                                        ValueOfMatConsump := -"Cost Amount (Actual)";
                                "Item Ledger Entry Type"::" ":
                                    ValueOfCap := "Cost Amount (Actual)";
                                "Item Ledger Entry Type"::Output:
                                    begin
                                        ValueOfExpOutput2 := -"Cost Amount (Expected)";
                                        ValueOfOutput := -("Cost Amount (Actual)" + "Cost Amount (Expected)");
                                        if "Entry Type" = "Entry Type"::Revaluation then
                                            ValueOfRevalCostAct += -"Cost Amount (Actual)";
                                    end;
                            end;

                        if not ("Item Ledger Entry Type" = "Item Ledger Entry Type"::" ") then begin
                            "Cost Amount (Actual)" := -"Cost Amount (Actual)";
                            if IsProductionCost("Value Entry") then begin
                                ValueOfCostPstdToGL := -("Cost Posted to G/L" + "Expected Cost Posted to G/L");
                                if "Entry Type" = "Entry Type"::Revaluation then
                                    ValueOfRevalCostPstd += ValueOfCostPstdToGL;
                            end else
                                ValueOfCostPstdToGL := 0;
                        end else
                            ValueOfCostPstdToGL := "Cost Posted to G/L" + "Expected Cost Posted to G/L";

                        NcValueOfWIP := NcValueOfWIP + ValueOfWIP;
                        NcValueOfOutput := NcValueOfOutput + ValueOfOutput;
                        NcValueOfMatConsump := NcValueOfMatConsump + ValueOfMatConsump;
                        NcValueOfCap := NcValueOfCap + ValueOfCap;
                        NcValueOfInvOutput1 := NcValueOfInvOutput1 + ValueOfInvOutput1;
                        NcValueOfExpOutPut1 := NcValueOfExpOutPut1 + ValueOfExpOutput1;
                        NcValueOfExpOutPut2 := NcValueOfExpOutPut2 + ValueOfExpOutput2;
                        NcValueOfRevalCostAct := ValueOfRevalCostAct;
                        NcValueOfRevalCostPstd := ValueOfRevalCostPstd;
                        NcValueOfCostPstdToGL := NcValueOfCostPstdToGL + ValueOfCostPstdToGL;
                        ValueOfCostPstdToGL := 0;

                        if CountRecord = LengthRecord then begin
                            ValueEntryOnPostDataItem();
                            ValueOfCostPstdToGL := NcValueOfCostPstdToGL;

                            AtLastDate := NcValueOfWIP + NcValueOfMatConsump + NcValueOfCap + NcValueOfOutput;
                            LastOutput := NcValueOfOutput;
                            LastWIP := NcValueOfWIP;

                            NcValueOfWIP := 0;
                            NcValueOfOutput := 0;
                            NcValueOfMatConsump := 0;
                            NcValueOfCap := 0;
                            NcValueOfInvOutput1 := 0;
                            NcValueOfExpOutPut1 := 0;
                            NcValueOfExpOutPut2 := 0;
                            NcValueOfRevalCostAct := 0;
                            NcValueOfRevalCostPstd := 0;
                            NcValueOfCostPstdToGL := 0;
                        end;
                    end;

                    IsHandled := false;
                    OnValueEntryOnAfterGetRecordOnBeforeIncrementTotals(ValueOfCostPstdToGL, AtLastDate, IsHandled);
                    if IsHandled then
                        CurrReport.Skip();

                    TotalValueOfCostPstdToGL := TotalValueOfCostPstdToGL + ValueOfCostPstdToGL;
                    TotalValueOfOutput := TotalValueOfOutput + ValueOfOutput;
                    TotalValueOfCap := TotalValueOfCap + ValueOfCap;
                    TotalValueOfMatConsump := TotalValueOfMatConsump + ValueOfMatConsump;
                    TotalValueOfWIP := TotalValueOfWIP + ValueOfWIP;
                    TotalLastOutput := TotalLastOutput + LastOutput;
                    TotalAtLastDate := TotalAtLastDate + AtLastDate;
                    TotalLastWIP := TotalLastWIP + LastWIP;

                    LastWipSum += ValueOfWIP;
                    ValueOfMatConsumptionSum += ValueOfMatConsump;
                    ValueOfCapSum += ValueOfCap;
                    ValueOfOutputSum += LastOutput;
                    AtLastDateSum += AtLastDate;
                    ValueEntryCostPostedToGLSum += ValueOfCostPstdToGL;

                    if CountRecord <> LengthRecord then
                        CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    ValueEntryOnPostDataItem();
                end;

                trigger OnPreDataItem()
                begin
                    TotalValueOfCostPstdToGL := 0;
                    TotalValueOfOutput := 0;
                    TotalValueOfCap := 0;
                    TotalValueOfMatConsump := 0;
                    TotalValueOfWIP := 0;
                    TotalLastOutput := 0;
                    TotalAtLastDate := 0;
                    TotalLastWIP := 0;

                    SetRange("Order Type", "Order Type"::Production);
                    SetRange("Order No.", "Production Order"."No.");
                    if EndDate <> 0D then
                        SetRange("Posting Date", 0D, EndDate);

                    ValueOfRevalCostAct := 0;
                    ValueOfRevalCostPstd := 0;
                    LengthRecord := 0;
                    CountRecord := 0;

                    if Find('-') then
                        repeat
                            LengthRecord := LengthRecord + 1;
                        until Next() = 0;
                end;
            }
            trigger OnAfterGetRecord()
            begin
                if FinishedProdOrderIsCompletelyInvoiced() then
                    CurrReport.Skip();
                EntryFound := ValueEntryExist("Production Order", StartDate, EndDate);
            end;
        }
        dataitem(Totals; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(LatWipSum; LastWipSum)
            {
            }
            column(ValueOfMatConsumptionSum; ValueOfMatConsumptionSum)
            {
            }
            column(ValueOfCapSum; ValueOfCapSum)
            {
            }
            column(ValueOfOutputSum; ValueOfOutputSum)
            {
            }
            column(AtLastDateSum; AtLastDateSum)
            {
            }
            column(ValueEntryCostPostedToGLSum; ValueEntryCostPostedToGLSum)
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Production Order - WIP';
        AboutText = 'Details Starting WIP, Consumption, Capacity and Output posted during a period and ending WIP for each Production Order. Use it to report in detail your WIP balance and to Reconcile your WIP to the General Ledger WIP Balance Sheet Account at the end of each period.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period covered by the inventory valuation report.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) and (EndDate = 0D) then
                EndDate := WorkDate();
        end;
    }

    rendering
    {
        layout(ExcelLayout)
        {
            Caption = 'Production Order - WIP Excel';
            Type = Excel;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.xlsx';
        }
        layout(WordLayout)
        {
            Caption = 'Production Order - WIP Word';
            Type = Word;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.docx';
        }
        layout(RDLCLayout)
        {
            Caption = 'Production Order - WIP RDLC';
            Type = RDLC;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.rdlc';
        }
    }

    labels
    {
        ProdOrderWIP = 'Prod. Order - WIP';
        CurrReportPageNo = 'Page';
        Capacity = 'Capacity ';
        Output = 'Output ';
        CostPostedToGL = 'Cost Posted to G/L';
        Consumption = 'Consumption ';
        Total = 'Total';
        PeriodCaption = 'Period:';
        UntilCaption = 'Until:';
        StartDateHeader = 'As of Start Date';
        EndDateHeader = 'As of End Date';
        ProdOrderWipPrintLabel = 'Prod. Order - WIP (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderWipAnalysisLabel = 'Prod. Order - WIP (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        ProdOrderFilter := "Production Order".GetFilters();
        if (StartDate = 0D) and (EndDate = 0D) then
            EndDate := WorkDate();

        if StartDate in [0D, 00000101D] then
            StartDateText := ''
        else
            StartDateText := Format(StartDate - 1);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'As of %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StartDate: Date;
        EndDate: Date;
        ProdOrderFilter: Text;
        StartDateText: Text[10];
        ValueOfWIP: Decimal;
        ValueOfMatConsump: Decimal;
        ValueOfCap: Decimal;
        ValueOfOutput: Decimal;
        ValueOfExpOutput1: Decimal;
        ValueOfInvOutput1: Decimal;
        ValueOfExpOutput2: Decimal;
        ValueOfRevalCostAct: Decimal;
        ValueOfRevalCostPstd: Decimal;
        ValueOfCostPstdToGL: Decimal;
        NcValueOfWIP: Decimal;
        NcValueOfOutput: Decimal;
        NcValueOfMatConsump: Decimal;
        NcValueOfCap: Decimal;
        NcValueOfInvOutput1: Decimal;
        NcValueOfExpOutPut1: Decimal;
        NcValueOfExpOutPut2: Decimal;
        NcValueOfRevalCostAct: Decimal;
        NcValueOfRevalCostPstd: Decimal;
        NcValueOfCostPstdToGL: Decimal;
        LastOutput: Decimal;
        LengthRecord: Integer;
        CountRecord: Integer;
        AtLastDate: Decimal;
        LastWIP: Decimal;
        TotalValueOfCostPstdToGL: Decimal;
        TotalValueOfOutput: Decimal;
        TotalValueOfCap: Decimal;
        TotalValueOfMatConsump: Decimal;
        TotalValueOfWIP: Decimal;
        TotalLastOutput: Decimal;
        TotalAtLastDate: Decimal;
        TotalLastWIP: Decimal;
        InventoryValuationWIPCptnLbl: Label 'Inventory Valuation - WIP';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ValueOfCapCaptionLbl: Label 'Capacity ';
        ValueOfOutputCaptionLbl: Label 'Output ';
        ValueEntryCostPostedtoGLCaptionLbl: Label 'Cost Posted to G/L';
        ValueOfMatConsumpCaptionLbl: Label 'Consumption ';
        ProductionOrderNoCaptionLbl: Label 'No.';
        ProdOrderStatusCaptionLbl: Label 'Status';
        ProdOrderDescriptionCaptionLbl: Label 'Description';
        ProdOrderSourceTypeCaptnLbl: Label 'Source Type';
        ProdOrderSourceNoCaptionLbl: Label 'Source No.';
        TotalCaptionLbl: Label 'Total';
        EntryFound: Boolean;
        LastWipSum: Decimal;
        ValueOfMatConsumptionSum: Decimal;
        ValueOfCapSum: Decimal;
        ValueOfOutputSum: Decimal;
        AtLastDateSum: Decimal;
        ValueEntryCostPostedToGLSum: Decimal;


    local procedure ValueEntryOnPostDataItem()
    begin
        if (NcValueOfExpOutPut2 + NcValueOfExpOutPut1) = 0 then begin // if prod. order is invoiced
            NcValueOfOutput := NcValueOfOutput - NcValueOfRevalCostAct; // take out revalued differnce
            NcValueOfCostPstdToGL := NcValueOfCostPstdToGL - NcValueOfRevalCostPstd; // take out Cost posted to G/L
        end;
    end;

    local procedure IsNotWIP(): Boolean
    begin
        if "Value Entry"."Item Ledger Entry Type" = "Value Entry"."Item Ledger Entry Type"::Output then
            exit(not ("Value Entry"."Entry Type" in ["Value Entry"."Entry Type"::"Direct Cost",
                                       "Value Entry"."Entry Type"::Revaluation]));

        exit("Value Entry"."Expected Cost");
    end;

    local procedure IsProductionCost(ValueEntry: Record "Value Entry"): Boolean
    var
        ILE: Record "Item Ledger Entry";
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation) and (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Consumption) then begin
            ILE.Get(ValueEntry."Item Ledger Entry No.");
            if ILE.Positive then
                exit(false)
        end;

        exit(true);
    end;

    local procedure FinishedProdOrderIsCompletelyInvoiced(): Boolean
    var
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        if "Production Order".Status <> "Production Order".Status::Finished then
            exit(false);

        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
        InvtAdjmtEntryOrder.SetRange("Order No.", "Production Order"."No.");
        InvtAdjmtEntryOrder.SetRange("Completely Invoiced", false);
        if not InvtAdjmtEntryOrder.IsEmpty() then
            exit(false);

        exit(not ValueEntryExist("Production Order", StartDate, 99991231D));
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
    end;

    local procedure ValueEntryExist(ProductionOrder: Record "Production Order"; StartDate: Date; EndDate: Date): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.SetRange("Posting Date", StartDate, EndDate);
        exit(not ValueEntry.IsEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValueEntryOnAfterGetRecordOnBeforeIncrementTotals(ValueOfCostPstdToGL: Decimal; AtLastDate: Decimal; var IsHandled: Boolean)
    begin
    end;
}