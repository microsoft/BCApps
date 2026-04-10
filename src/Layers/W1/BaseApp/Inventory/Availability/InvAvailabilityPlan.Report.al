// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 719 "Inv. Availability Plan"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Availability Plan (Excel)';
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = Excel;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where(Type = const(Inventory));
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group", "Vendor No.";
            CalcFields = Inventory, "Planning Receipt (Qty.)", "Planning Release (Qty.)";

            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");

                trigger OnAfterGetRecord()
                begin
                    CalcNeed(Item, "Location Code", "Variant Code");

                    if Print then
                        PopulateBuffer();

                    CurrReport.Skip(); // Item dataitem just for filtering and building the buffer
                end;

                trigger OnPreDataItem()
                begin
                    if not UseStockkeepingUnit then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not UseStockkeepingUnit then begin
                    Print := false;

                    CalcNeed(Item, GetFilter("Location Filter"), GetFilter("Variant Filter"));

                    if Print then
                        PopulateBuffer();

                    CurrReport.Skip();
                end;
            end;
        }
        dataitem(AvailabilityPlanBuffer; "Availability Plan Buffer")
        {
            column(ItemNo; "Item No.")
            {
                IncludeCaption = true;
            }
            column(Description; Description)
            {
                IncludeCaption = true;
            }
            column(LocationCode; "Location Code")
            {
                IncludeCaption = true;
            }
            column(VariantCode; "Variant Code")
            {
                IncludeCaption = true;
            }
            column(CategoryName; "Category Name")
            {
                IncludeCaption = true;
            }
            column(CurrentQuantity; "Current Quantity")
            {
                IncludeCaption = true;
            }
            column(Quantity1; "Quantity 1")
            {
                IncludeCaption = true;
            }
            column(Quantity2; "Quantity 2")
            {
                IncludeCaption = true;
            }
            column(Quantity3; "Quantity 3")
            {
                IncludeCaption = true;
            }
            column(Quantity4; "Quantity 4")
            {
                IncludeCaption = true;
            }
            column(Quantity5; "Quantity 5")
            {
                IncludeCaption = true;
            }
            column(Quantity6; "Quantity 6")
            {
                IncludeCaption = true;
            }
            column(Quantity7; "Quantity 7")
            {
                IncludeCaption = true;
            }
            column(Quantity8; "Quantity 8")
            {
                IncludeCaption = true;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Availability Plan (Excel)';
        AboutText = 'Get an overview of specific items and stock-keeping units, and their availability.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(UseStockkeepUnit; UseStockkeepingUnit)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want the report to list the availability of items by stockkeeping unit.';
                    }
                    // ### Start Report Headers ### Used to set report headers across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item Filters applied to this report.';
                        Visible = false;
                    }
                    field(RequestPeriod1Text; Period1Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 1';
                        ToolTip = 'Specifies Period 1 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod2Text; Period2Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 2';
                        ToolTip = 'Specifies Period 2 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod3Text; Period3Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 3';
                        ToolTip = 'Specifies Period 3 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod4Text; Period4Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 4';
                        ToolTip = 'Specifies Period 4 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod5Text; Period5Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 5';
                        ToolTip = 'Specifies Period 5 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod6Text; Period6Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 6';
                        ToolTip = 'Specifies Period 6 on this report.';
                        Visible = false;
                    }
                    // ### End Report Headers ###
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
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
            Caption = 'Inventory - Availability Plan (Excel)';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InvAvailabilityPlan.xlsx';
            Summary = 'Built in layout for the Inventory - Availability Plan (Excel) report.';
        }
    }

    labels
    {
        InventoryAvailabilityPlanLbl = 'Inventory - Availability Plan';
        InvAvailPlanPrintLbl = 'Inv. Avail. Plan (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvAvailPlanAnalysisLbl = 'Inv. Avail. Plan (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        BeforeLbl = '...Before';
        AfterLbl = 'After...';
        // About the report labels
        AboutTheReportLbl = 'About the report';
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
        AvailToPromise: Codeunit "Available to Promise";
        PeriodLength: DateFormula;
        ItemFilter: Text;
        ItemFilterHeading: Text;
        SchedReceipt: array[8] of Decimal;
        PlanReceipt: array[8] of Decimal;
        PlanRelease: array[8] of Decimal;
        PeriodStartDate: array[9] of Date;
        ProjAvBalance: array[8] of Decimal;
        GrossReq: array[8] of Decimal;
        Print: Boolean;
        EntryNo: Integer;
        UseStockkeepingUnit: Boolean;
        Period1Text: Text;
        Period2Text: Text;
        Period3Text: Text;
        Period4Text: Text;
        Period5Text: Text;
        Period6Text: Text;

    local procedure CalcNeed(Item: Record Item; LocationFilter: Text[250]; VariantFilter: Text[250])
    var
        PlannedOrderReleaseQty: Decimal;
        i: Integer;
    begin
        for i := 1 to 8 do begin
            Item.SetFilter("Location Filter", LocationFilter);
            Item.SetFilter("Variant Filter", VariantFilter);
            if Item.Inventory <> 0 then
                Print := true;

            Item.SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);

            GrossReq[i] := AvailToPromise.CalcGrossRequirement(Item);
            SchedReceipt[i] := AvailToPromise.CalcScheduledReceipt(Item);

            PlannedOrderReleaseQty := Item.CalcPlannedOrderReceiptQty();

            SchedReceipt[i] := SchedReceipt[i] - PlannedOrderReleaseQty;
            PlanReceipt[i] := Item."Planning Receipt (Qty.)" + PlannedOrderReleaseQty;
            PlanRelease[i] := Item."Planning Release (Qty.)" + PlannedOrderReleaseQty;

            if i = 1 then
                ProjAvBalance[1] :=
                  Item.Inventory - GrossReq[1] + SchedReceipt[1] + PlanReceipt[1]
            else
                ProjAvBalance[i] :=
                  ProjAvBalance[i - 1] -
                  GrossReq[i] + SchedReceipt[i] + PlanReceipt[i];

            if (GrossReq[i] <> 0) or
               (PlanReceipt[i] <> 0) or
               (SchedReceipt[i] <> 0) or
               (PlanRelease[i] <> 0)
            then
                Print := true;
        end;
    end;

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: DateFormula; NewUseStockkeepingUnit: Boolean)
    begin
        PeriodStartDate[2] := NewPeriodStartDate;
        PeriodLength := NewPeriodLength;
        UseStockkeepingUnit := NewUseStockkeepingUnit;
    end;

    local procedure PopulateBuffer()
    var
        GrossRequirementLbl: Label 'Gross Requirement';
        ScheduledReceiptLbl: Label 'Scheduled Receipt';
        PlannedReceiptLbl: Label 'Planned Receipt';
        InventoryLbl: Label 'Inventory';
        PlannedReleasesLbl: Label 'Planned Releases';
    begin
        AddBufferEntry(GrossRequirementLbl, 0, GrossReq);
        AddBufferEntry(ScheduledReceiptLbl, 0, SchedReceipt);
        AddBufferEntry(PlannedReceiptLbl, 0, PlanReceipt);
        AddBufferEntry(InventoryLbl, Item.Inventory, ProjAvBalance);
        AddBufferEntry(PlannedReleasesLbl, 0, PlanRelease);
    end;

    local procedure AddBufferEntry(CategoryName: Text[100]; CurrentQuantity: Decimal; Quantities: array[8] of Decimal)
    begin
        AvailabilityPlanBuffer.Init();
        EntryNo += 1;
        AvailabilityPlanBuffer."Entry No." := EntryNo;
        AvailabilityPlanBuffer."Item No." := Item."No.";
        AvailabilityPlanBuffer.Description := Item.Description;
        if UseStockkeepingUnit then begin
            AvailabilityPlanBuffer."Location Code" := "Stockkeeping Unit"."Location Code";
            AvailabilityPlanBuffer."Variant Code" := "Stockkeeping Unit"."Variant Code";
        end;
        AvailabilityPlanBuffer."Category Name" := CategoryName;
        AvailabilityPlanBuffer."Current Quantity" := CurrentQuantity;
        AvailabilityPlanBuffer."Quantity 1" := Quantities[1];
        AvailabilityPlanBuffer."Quantity 2" := Quantities[2];
        AvailabilityPlanBuffer."Quantity 3" := Quantities[3];
        AvailabilityPlanBuffer."Quantity 4" := Quantities[4];
        AvailabilityPlanBuffer."Quantity 5" := Quantities[5];
        AvailabilityPlanBuffer."Quantity 6" := Quantities[6];
        AvailabilityPlanBuffer."Quantity 7" := Quantities[7];
        AvailabilityPlanBuffer."Quantity 8" := Quantities[8];
        AvailabilityPlanBuffer.Insert();
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    var
        i: Integer;
    begin
        ItemFilter := Item.GetFilters();

        ItemFilterHeading := '';
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter;

        for i := 2 to 7 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLength, PeriodStartDate[i]);
        PeriodStartDate[9] := DMY2Date(31, 12, 9999);

        Period1Text := Format(PeriodStartDate[2]) + ' ' + Format(PeriodStartDate[3] - 1);
        Period2Text := Format(PeriodStartDate[3]) + ' ' + Format(PeriodStartDate[4] - 1);
        Period3Text := Format(PeriodStartDate[4]) + ' ' + Format(PeriodStartDate[5] - 1);
        Period4Text := Format(PeriodStartDate[5]) + ' ' + Format(PeriodStartDate[6] - 1);
        Period5Text := Format(PeriodStartDate[6]) + ' ' + Format(PeriodStartDate[7] - 1);
        Period6Text := Format(PeriodStartDate[7]) + ' ' + Format(PeriodStartDate[8] - 1);
    end;
}