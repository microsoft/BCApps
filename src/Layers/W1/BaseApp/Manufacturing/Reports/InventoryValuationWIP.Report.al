// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using System.Utilities;

report 5802 "Inventory Valuation - WIP"
{
    ApplicationArea = Manufacturing;
    Caption = 'Production Order - WIP';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            CalcFields = "Inventory Adjmt. Entry Exists";
            DataItemTableView = where(Status = filter(Released ..));
            PrintOnlyIfDetail = true;
            RequestFilterFields = Status, "No.";

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
#if not CLEAN28
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InventoryValuationWIPCptn; InventoryValuationWIPCptnLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ValueOfCapCaption; ValueOfCapCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ValueOfOutputCaption; ValueOfOutputCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ValueEntryCostPostedtoGLCaption; ValueEntryCostPostedtoGLCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ValueOfMatConsumpCaption; ValueOfMatConsumpCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ProductionOrderNoCaption; ProductionOrderNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ProdOrderStatusCaption; ProdOrderStatusCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ProdOrderDescriptionCaption; ProdOrderDescriptionCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ProdOrderSourceTypeCaptn; ProdOrderSourceTypeCaptnLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ProdOrderSourceNoCaption; ProdOrderSourceNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TotalCaption; TotalCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
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

                        if not ReportHasData then
                            ReportHasData := true;
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

                    if (CountRecord <> LengthRecord) or (SkipZeroLines and ((TotalAtLastDate = 0) and (TotalValueOfCostPstdToGL = 0))) then
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

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
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
                    field(SkipZero; SkipZeroLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Zero Lines';
                        ToolTip = 'Specifies whether to skip zero lines.';
                    }
                    // Used to set a report header across multiple languages
                    field(RequestProdOrderFilterHeading; ProdOrderFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Prod. Order Filter';
                        ToolTip = 'Specifies the Prod. Order filters applied to this report.';
                        Visible = false;
                    }
                    field(RequestStartDateHeading; StartDateHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the Start Date applied to this report as a text value for use in the Excel report header.';
                        Visible = false;
                    }
                    field(RequestEndDateHeading; EndDateHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the End Date applied to this report as a text value for use in the Excel report header.';
                        Visible = false;
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

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Production Order - WIP Excel';
            Type = Excel;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.xlsx';
            Summary = 'Built in layout for the Production Order - WIP Excel report.';
        }
        layout(Word)
        {
            Caption = 'Production Order - WIP Word';
            Type = Word;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.docx';
            Summary = 'Built in layout for the Production Order - WIP Word report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Production Order - WIP RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = '.\Manufacturing\Reports\InventoryValuationWIP.rdlc';
ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Production Order - WIP RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        ProdOrderWIPLbl = 'Production Order - WIP';
        ProdOrderWipPrintLbl = 'Prod. Order - WIP (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ProdOrderWipAnalysisLbl = 'Prod. Order - WIP (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        TotalLbl = 'Total';
        PeriodLbl = 'Period:';
        UntilLbl = 'Until:';
        AsOfStartDateLbl = 'As of Start Date';
        ConsumptionLbl = 'Consumption';
        CapacityLbl = 'Capacity';
        OutputLbl = 'Output';
        AsOfEndDateLbl = 'As of End Date';
        CostPostedToGLLbl = 'Cost Posted to G/L';
        // About the report labels
        AboutTheReportLbl = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
    }

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
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
        ProdOrderFilterHeading: Text;
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
        SkipZeroLines: Boolean;
        ReportHasData: Boolean;
        StartDateHeading: Text;
        EndDateHeading: Text;
#if not CLEAN28
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
#endif
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

    local procedure IsNotWIP() Result: Boolean
    begin
        if "Value Entry"."Item Ledger Entry Type" = "Value Entry"."Item Ledger Entry Type"::Output then
            Result := not ("Value Entry"."Entry Type" in ["Value Entry"."Entry Type"::"Direct Cost", "Value Entry"."Entry Type"::Revaluation])
        else
            Result := "Value Entry"."Expected Cost";

        OnAfterIsNotWIP("Value Entry", Result);
        exit(Result);
    end;

    local procedure IsProductionCost(ValueEntry: Record "Value Entry"): Boolean
    begin
        if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation) and (ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Consumption)
            and ("Value Entry"."Item Ledger Entry Quantity" > 0) then
            exit(false);

        exit(true);
    end;

    local procedure FinishedProdOrderIsCompletelyInvoiced(): Boolean
    begin
        if "Production Order".Status <> "Production Order".Status::Finished then
            exit(false);

        if "Production Order"."Inventory Adjmt. Entry Exists" then
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

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ProdOrderFilter := "Production Order".GetFilters();
        if ProdOrderFilter <> '' then
            ProdOrderFilterHeading := "Production Order".TableCaption + ': ' + ProdOrderFilter;

        if (StartDate = 0D) and (EndDate = 0D) then
            EndDate := WorkDate();

        if StartDate in [0D, 00000101D] then
            StartDateText := ''
        else
            StartDateText := Format(StartDate - 1);

        StartDateHeading := Format(StartDate);
        EndDateHeading := Format(EndDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValueEntryOnAfterGetRecordOnBeforeIncrementTotals(ValueOfCostPstdToGL: Decimal; AtLastDate: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNotWIP(var ValueEntry: Record "Value Entry"; var Result: Boolean)
    begin
    end;
}