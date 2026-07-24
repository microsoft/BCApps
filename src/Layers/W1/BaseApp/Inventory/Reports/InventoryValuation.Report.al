// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Environment;

report 1001 "Inventory Valuation"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Valuation';
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = ExcelLayout;
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Inventory Posting Group") where(Type = const(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group";
            column(ShowExpected; ShowExpected)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(BoM_Text; BoM_TextLbl)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO___1___2__Item_TABLECAPTION_ItemFilter_; StrSubstNo('%1: %2', TableCaption(), ItemFilter))
            {
            }
            column(STRSUBSTNO_Text005_StartDateText_; StrSubstNo(Text005, StartDateText))
            {
            }
            column(STRSUBSTNO_Text005_FORMAT_EndDate__; StrSubstNo(Text005, Format(EndDate)))
            {
            }
            column(Inventory_ValuationCaption; Inventory_ValuationCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(This_report_includes_entries_that_have_been_posted_with_expected_costs_Caption; This_report_includes_entries_that_have_been_posted_with_expected_costs_CaptionLbl)
            {
            }
            column(ItemNoCaption; ValueEntry.FieldCaption("Item No."))
            {
            }
            column(ItemDescriptionCaption; FieldCaption(Description))
            {
            }
            column(IncreaseInvoicedQtyCaption; IncreaseInvoicedQtyCaptionLbl)
            {
            }
            column(DecreaseInvoicedQtyCaption; DecreaseInvoicedQtyCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(ValueCaption; ValueCaptionLbl)
            {
            }
            column(QuantityCaption_Control31; QuantityCaption_Control31Lbl)
            {
            }
            column(QuantityCaption_Control40; QuantityCaption_Control40Lbl)
            {
            }
            column(InvCostPostedToGL_Control53Caption; InvCostPostedToGL_Control53CaptionLbl)
            {
            }
            column(QuantityCaption_Control58; QuantityCaption_Control58Lbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Expected_Cost_IncludedCaption; Expected_Cost_IncludedCaptionLbl)
            {
            }
            column(Expected_Cost_Included_TotalCaption; Expected_Cost_Included_TotalCaptionLbl)
            {
            }
            column(Expected_Cost_TotalCaption; Expected_Cost_TotalCaptionLbl)
            {
            }
            column(GetUrlForReportDrilldown; GetUrlForReportDrilldown("No."))
            {
            }
            column(ItemNo; "No.")
            {
            }
            column(ItemDescription; Description)
            {
            }
            column(ItemBaseUnitofMeasure; "Base Unit of Measure")
            {
            }
            column(Item_Inventory_Posting_Group; "Inventory Posting Group")
            {
                IncludeCaption = true;
            }
            column(StartingInvoicedValue; StartingInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(StartingInvoicedQty; StartingInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(StartingExpectedValue; StartingExpectedValue)
            {
                AutoFormatType = 1;
            }
            column(StartingExpectedQty; StartingExpectedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(IncreaseInvoicedValue; IncreaseInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(IncreaseInvoicedQty; IncreaseInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(IncreaseExpectedValue; IncreaseExpectedValue)
            {
                AutoFormatType = 1;
            }
            column(IncreaseExpectedQty; IncreaseExpectedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(DecreaseInvoicedValue; DecreaseInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(DecreaseInvoicedQty; DecreaseInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(DecreaseExpectedValue; DecreaseExpectedValue)
            {
                AutoFormatType = 1;
            }
            column(DecreaseExpectedQty; DecreaseExpectedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(EndingInvoicedValue; EndingInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(EndingInvoicedQty; EndingInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(EndingExpectedValue; EndingExpectedValue)
            {
                AutoFormatType = 1;
            }
            column(EndingExpectedQty; EndingExpectedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(StartingExpectedNotInvoicedValue; StartingExpectedNotInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(StartingExpectedNotInvoicedQty; StartingExpectedNotInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(IncreaseExpectedNotInvoicedValue; IncreaseExpectedNotInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(IncreaseExpectedNotInvoicedQty; IncreaseExpectedNotInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(DecreaseExpectedNotInvoicedValue; DecreaseExpectedNotInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(DecreaseExpectedNotInvoicedQty; DecreaseExpectedNotInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(EndingExpectedNotInvoicedValue; EndingExpectedNotInvoicedValue)
            {
                AutoFormatType = 1;
            }
            column(EndingExpectedNotInvoicedQty; EndingExpectedNotInvoicedQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(CostPostedToGL; CostPostedToGL)
            {
                AutoFormatType = 1;
            }
            column(InvCostPostedToGL; InvCostPostedToGL)
            {
                AutoFormatType = 1;
            }
            column(ExpCostPostedToGL; ExpCostPostedToGL)
            {
                AutoFormatType = 1;
            }
            column(CostPostedToGLDifference; CostPostedToGLDifference)
            {
                AutoFormatType = 1;
            }
            column(InvCostPostedToGLDifference; InvCostPostedToGLDifference)
            {
                AutoFormatType = 1;
            }
            column(ExpCostPostedToGLDifference; ExpCostPostedToGLDifference)
            {
                AutoFormatType = 1;
            }

            trigger OnPreDataItem()
            begin
                if StartDate > 0D then
                    SetRange("Opening Bal. Date Filter", 0D, CalcDate('<-1D>', StartDate));
                SetRange("Inv. Val. Period Date Filter", StartDate, EndDate);
                SetRange("Closing Bal. Date Filter", 0D, EndDate);
                SetAutoCalcFields("Assembly BOM", "Opening Bal. ILE Qty.", "Opening Bal. Inv. Qty.", "Opening Bal. Cost Amt. Act.", "Opening Bal. Cost Amt. Exp.", "Increases ILE Qty.",
                    "Increases Inv. Qty.", "Increases Cost Amt. Act.", "Increases Cost Amt. Exp.", "Decreases ILE Qty.", "Decreases Inv. Qty.", "Decreases Cost Amt. Act.",
                    "Decreases Cost Amt. Exp.", "Cost Posted To G/L", "Exp. Cost Posted To G/L");
            end;

            trigger OnAfterGetRecord()
            var
                SkipItem: Boolean;
            begin
                SkipItem := false;
                OnBeforeOnAfterItemGetRecord(Item, SkipItem);
                if SkipItem then
                    CurrReport.Skip();

                CalculateItem(Item);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Valuation';
        AboutText = 'Reconcile your inventory subledger to the inventory account(s) in the general ledger at the end of each period. Include Expected Costs and Apply Location Filters to ensure that the Ending Date Value, Cost Posted to G/L and the Balance in the related Inventory or Inventory (Interim) Account are all in balance.';
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
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(IncludeExpectedCost; ShowExpected)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Expected Cost';
                        ToolTip = 'Specifies if you want the report to also show entries that only have expected costs.';
                    }
                    field(RequestSkipZeroLines; SkipZeroLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Zero Lines';
                        ToolTip = 'Specifies whether to skip lines where ending quantity and value and cost posted to G/L are all zero.';
                    }
                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the item filters applied to this report.';
                        Visible = false;
                    }
                    field(RequestStartDateText; StartDateText)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the Start Date applied to this report as a text value for use in the Excel report header.';
                        Visible = false;
                    }
                    field(RequestEndDateText; EndDateText)
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
        layout(ExcelLayout)
        {
            Caption = 'Inventory Valuation Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/InventoryValuation.xlsx';
            Summary = 'Built in layout for the Inventory Valuation Excel report.';
        }
        layout(RDLCLayout)
        {
            Caption = 'Inventory Valuation RDLC';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/InventoryValuation.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
    }

    labels
    {
        InvValInvoicedLbl = 'Inventory Valuation - Invoiced';
        InvValExpectedLbl = 'Inventory Valuation - Expected';
        InvValTotalLbl = 'Inventory Valuation - Total';
        InvValInvoicedPrintLbl = 'Inv. Val. Invoiced (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvValExpectedPrintLbl = 'Inv. Val. Expected (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvValTotalPrintLbl = 'Inv. Val. Total (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InventoryValuationAnalysisLbl = 'Inventory Valuation (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        Inventory_Posting_Group_NameCaption = 'Inventory Posting Group Name';
        Expected_CostCaption = 'Expected Cost';
        ItemNoLbl = 'Item No.';
        ItemDescLbl = 'Item Description';
        BaseUoMLbl = 'Base UoM';
        AsOfLbl = 'As of';
        IncreasesLbl = 'Increases (LCY)';
        DecreasesLbl = 'Decreases (LCY)';
        TotalCostPostedToGLLbl = 'Total Cost Posted to G/L';
        InvCostPostedToGLLbl = 'Invoiced Cost Posted to G/L';
        ExpCostPostedToGLLbl = 'Expected Cost Posted to G/L';
        TotalDifferenceLbl = 'Total Difference';
        InvDifferenceLbl = 'Invoiced Difference';
        ExpDifferenceLbl = 'Expected Difference';
        ReportIncludesExpectedCostsLbl = 'This report includes entries that have been posted with expected costs.';
        ExpectedCostsNotCalculatedLbl = 'Expected costs have not been calculated.';
        InvoicedLbl = 'Invoiced';
        ExpectedLbl = 'Expected';
        Quantity1Lbl = 'Quantity';
        Quantity2Lbl = 'Quantity';
        Quantity3Lbl = 'Quantity';
        Quantity4Lbl = 'Quantity';
        Quantity5Lbl = 'Quantity';
        Quantity6Lbl = 'Quantity';
        Quantity7Lbl = 'Quantity';
        Quantity8Lbl = 'Quantity';
        Quantity9Lbl = 'Quantity';
        Quantity10Lbl = 'Quantity';
        Quantity11Lbl = 'Quantity';
        Quantity12Lbl = 'Quantity';
        Value1Lbl = 'Value';
        Value2Lbl = 'Value';
        Value3Lbl = 'Value';
        Value4Lbl = 'Value';
        Value5Lbl = 'Value';
        Value6Lbl = 'Value';
        Value7Lbl = 'Value';
        Value8Lbl = 'Value';
        Value9Lbl = 'Value';
        Value10Lbl = 'Value';
        Value11Lbl = 'Value';
        Value12Lbl = 'Value';
        TotalLbl = 'Total';
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
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'As of %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        BoM_TextLbl: Label 'Base UoM';
        Inventory_ValuationCaptionLbl: Label 'Inventory Valuation';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_includes_entries_that_have_been_posted_with_expected_costs_CaptionLbl: Label 'This report includes entries that have been posted with expected costs.';
        IncreaseInvoicedQtyCaptionLbl: Label 'Increases (LCY)';
        DecreaseInvoicedQtyCaptionLbl: Label 'Decreases (LCY)';
        QuantityCaptionLbl: Label 'Quantity';
        ValueCaptionLbl: Label 'Value';
        QuantityCaption_Control31Lbl: Label 'Quantity';
        QuantityCaption_Control40Lbl: Label 'Quantity';
        InvCostPostedToGL_Control53CaptionLbl: Label 'Cost Posted to G/L';
        QuantityCaption_Control58Lbl: Label 'Quantity';
        TotalCaptionLbl: Label 'Total';
        Expected_Cost_Included_TotalCaptionLbl: Label 'Expected Cost Included Total';
        Expected_Cost_TotalCaptionLbl: Label 'Expected Cost Total';
        Expected_Cost_IncludedCaptionLbl: Label 'Expected Cost Included';
        ReportIncludesExpectedCostsTxt: Text;

    protected var
        ValueEntry: Record "Value Entry";
        StartDate: Date;
        EndDate: Date;
        ShowExpected: Boolean;
        SkipZeroLines: Boolean;
        ItemFilter: Text;
        ItemFilterHeading: Text;
        StartDateText: Text[10];
        EndDateText: Text;
        StartingInvoicedValue: Decimal;
        StartingExpectedValue: Decimal;
        StartingInvoicedQty: Decimal;
        StartingExpectedQty: Decimal;
        IncreaseInvoicedValue: Decimal;
        IncreaseExpectedValue: Decimal;
        IncreaseInvoicedQty: Decimal;
        IncreaseExpectedQty: Decimal;
        DecreaseInvoicedValue: Decimal;
        DecreaseExpectedValue: Decimal;
        DecreaseInvoicedQty: Decimal;
        DecreaseExpectedQty: Decimal;
        EndingInvoicedQty: Decimal;
        EndingInvoicedValue: Decimal;
        EndingExpectedQty: Decimal;
        EndingExpectedValue: Decimal;
        InvCostPostedToGL: Decimal;
        CostPostedToGL: Decimal;
        ExpCostPostedToGL: Decimal;
        InvCostPostedToGLDifference: Decimal;
        CostPostedToGLDifference: Decimal;
        ExpCostPostedToGLDifference: Decimal;
        IsEmptyLine: Boolean;
        // Expected Cost values are inclusive of invoiced values. These exclude invoiced values.
        StartingExpectedNotInvoicedValue: Decimal;
        StartingExpectedNotInvoicedQty: Decimal;
        IncreaseExpectedNotInvoicedValue: Decimal;
        IncreaseExpectedNotInvoicedQty: Decimal;
        DecreaseExpectedNotInvoicedValue: Decimal;
        DecreaseExpectedNotInvoicedQty: Decimal;
        EndingExpectedNotInvoicedValue: Decimal;
        EndingExpectedNotInvoicedQty: Decimal;

    procedure AssignAmounts(ValueEntry: Record "Value Entry"; var InvoicedValue: Decimal; var InvoicedQty: Decimal; var ExpectedValue: Decimal; var ExpectedQty: Decimal; Sign: Decimal)
    begin
        InvoicedValue += ValueEntry."Cost Amount (Actual)" * Sign;
        InvoicedQty += ValueEntry."Invoiced Quantity" * Sign;
        ExpectedValue += ValueEntry."Cost Amount (Expected)" * Sign;
        ExpectedQty += ValueEntry."Item Ledger Entry Quantity" * Sign;
    end;

    procedure CalculateItem(var Item: Record Item)
    var
        IsHandled: Boolean;
        HasEntriesWithinDateRange: Boolean;
        IsZeroLine: Boolean;
    begin
        if EndDate = 0D then
            EndDate := DMY2Date(31, 12, 9999);

        StartingInvoicedValue := 0;
        StartingExpectedValue := 0;
        StartingInvoicedQty := 0;
        StartingExpectedQty := 0;
        IncreaseInvoicedValue := 0;
        IncreaseExpectedValue := 0;
        IncreaseInvoicedQty := 0;
        IncreaseExpectedQty := 0;
        DecreaseInvoicedValue := 0;
        DecreaseExpectedValue := 0;
        DecreaseInvoicedQty := 0;
        DecreaseExpectedQty := 0;
        InvCostPostedToGL := 0;
        CostPostedToGL := 0;
        ExpCostPostedToGL := 0;

        ValueEntry.Reset();
        ValueEntry.SetLoadFields("Valued Quantity", "Item Ledger Entry No.", "Cost Amount (Actual)", "Cost Amount (Expected)", "Invoiced Quantity",
            "Item Ledger Entry Quantity", "Cost Posted to G/L", "Expected Cost Posted to G/L");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ValueEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        ValueEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        OnItemOnAfterGetRecordOnAfterValueEntrySetInitialFilters(ValueEntry, Item);

        ValueEntry.SetRange("Posting Date", 0D, EndDate);
        IsEmptyLine := ValueEntry.IsEmpty();
        if not IsEmptyLine then begin
            ValueEntry.SetRange("Posting Date", StartDate, EndDate);
            HasEntriesWithinDateRange := not ValueEntry.IsEmpty();
        end;
        ValueEntry.SetRange("Posting Date");

        if not IsEmptyLine then begin
            IsEmptyLine := true;
            if StartDate > 0D then begin
                StartingInvoicedValue += Item."Opening Bal. Cost Amt. Act.";
                StartingInvoicedQty += Item."Opening Bal. Inv. Qty.";
                StartingExpectedValue += Item."Opening Bal. Cost Amt. Exp.";
                StartingExpectedQty += Item."Opening Bal. ILE Qty.";

                IsEmptyLine := IsEmptyLine and ((StartingInvoicedValue = 0) and (StartingInvoicedQty = 0));
                if ShowExpected then
                    IsEmptyLine := IsEmptyLine and ((StartingExpectedValue = 0) and (StartingExpectedQty = 0));
            end;

            if HasEntriesWithinDateRange then begin
                IncreaseInvoicedValue += Item."Increases Cost Amt. Act.";
                IncreaseInvoicedQty += Item."Increases Inv. Qty.";
                IncreaseExpectedValue += Item."Increases Cost Amt. Exp.";
                IncreaseExpectedQty += Item."Increases ILE Qty.";

                OnCalculateItemOnBeforeAssignDecreaseAmounts(ValueEntry, Item);
                DecreaseInvoicedValue += Item."Decreases Cost Amt. Act." * -1;
                DecreaseInvoicedQty += Item."Decreases Inv. Qty." * -1;
                DecreaseExpectedValue += Item."Decreases Cost Amt. Exp." * -1;
                DecreaseExpectedQty += Item."Decreases ILE Qty." * -1;
                OnCalculateItemOnAfterAssignDecreaseAmounts(ValueEntry, Item, DecreaseInvoicedValue, DecreaseInvoicedQty, DecreaseExpectedValue, DecreaseExpectedQty, IncreaseInvoicedValue, IncreaseInvoicedQty, IncreaseExpectedValue, IncreaseExpectedQty);

                ValueEntry.SetRange("Posting Date", StartDate, EndDate);
                ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Transfer);
                if ValueEntry.FindSet() then
                    repeat
                        if true in [ValueEntry."Valued Quantity" < 0, not GetOutboundItemEntry(ValueEntry."Item Ledger Entry No.")] then
                            AssignAmounts(ValueEntry, DecreaseInvoicedValue, DecreaseInvoicedQty, DecreaseExpectedValue, DecreaseExpectedQty, -1)
                        else
                            AssignAmounts(ValueEntry, IncreaseInvoicedValue, IncreaseInvoicedQty, IncreaseExpectedValue, IncreaseExpectedQty, 1);
                    until ValueEntry.Next() = 0;

                IsEmptyLine := IsEmptyLine and ((IncreaseInvoicedValue = 0) and (IncreaseInvoicedQty = 0));
                IsEmptyLine := IsEmptyLine and ((DecreaseInvoicedValue = 0) and (DecreaseInvoicedQty = 0));
                if ShowExpected then begin
                    IsEmptyLine := IsEmptyLine and ((IncreaseExpectedValue = 0) and (IncreaseExpectedQty = 0));
                    IsEmptyLine := IsEmptyLine and ((DecreaseExpectedValue = 0) and (DecreaseExpectedQty = 0));
                end;
            end;

            ExpCostPostedToGL += Item."Exp. Cost Posted To G/L";
            InvCostPostedToGL += Item."Cost Posted To G/L";

            StartingExpectedValue += StartingInvoicedValue;
            IncreaseExpectedValue += IncreaseInvoicedValue;
            DecreaseExpectedValue += DecreaseInvoicedValue;

            EndingInvoicedQty := StartingInvoicedQty + IncreaseInvoicedQty - DecreaseInvoicedQty;
            EndingInvoicedValue := StartingInvoicedValue + IncreaseInvoicedValue - DecreaseInvoicedValue;
            EndingExpectedQty := StartingExpectedQty + IncreaseExpectedQty - DecreaseExpectedQty;
            EndingExpectedValue := StartingExpectedValue + IncreaseExpectedValue - DecreaseExpectedValue;

            if ShowExpected then begin
                StartingExpectedNotInvoicedValue := StartingExpectedValue - StartingInvoicedValue;
                IncreaseExpectedNotInvoicedValue := IncreaseExpectedValue - IncreaseInvoicedValue;
                DecreaseExpectedNotInvoicedValue := DecreaseExpectedValue - DecreaseInvoicedValue;
                EndingExpectedNotInvoicedValue := EndingExpectedValue - EndingInvoicedValue;

                StartingExpectedNotInvoicedQty := StartingExpectedQty - StartingInvoicedQty;
                IncreaseExpectedNotInvoicedQty := IncreaseExpectedQty - IncreaseInvoicedQty;
                DecreaseExpectedNotInvoicedQty := DecreaseExpectedQty - DecreaseInvoicedQty;
                EndingExpectedNotInvoicedQty := EndingExpectedQty - EndingInvoicedQty;
            end;

            CostPostedToGL := ExpCostPostedToGL + InvCostPostedToGL;

            InvCostPostedToGLDifference := InvCostPostedToGL - EndingInvoicedValue;
            ExpCostPostedToGLDifference := ExpCostPostedToGL - EndingExpectedNotInvoicedValue;
            CostPostedToGLDifference := CostPostedToGL - EndingExpectedValue;

            if SkipZeroLines then begin
                IsZeroLine := (EndingInvoicedValue = 0) and (EndingInvoicedQty = 0) and (InvCostPostedToGL = 0);
                if ShowExpected then
                    IsZeroLine := IsZeroLine and ((EndingExpectedValue = 0) and (EndingExpectedQty = 0) and (ExpCostPostedToGL = 0));
            end;
        end; // if not IsEmptyLine

        IsHandled := false;
        OnAfterGetRecordItemOnBeforeSkipEmptyLine(Item, StartingInvoicedQty, IncreaseInvoicedQty, DecreaseInvoicedQty, IsHandled, IsEmptyLine, StartingExpectedQty, IncreaseExpectedQty, DecreaseExpectedQty);
        if not IsHandled then
            if IsEmptyLine then
                CurrReport.Skip();

        if SkipZeroLines and IsZeroLine then
            CurrReport.Skip();
    end;

    local procedure GetOutboundItemEntry(ItemLedgerEntryNo: Integer): Boolean
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemApplnEntry.SetCurrentKey("Item Ledger Entry No.");
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        if not ItemApplnEntry.FindFirst() then
            exit(true);

        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ItemLedgEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ItemLedgEntry.SetFilter("Global Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        ItemLedgEntry.SetFilter("Global Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        ItemLedgEntry.SetRange("Entry No.", ItemApplnEntry."Outbound Item Entry No.");
        OnGetOutboundItemEntryOnAfterSetItemLedgEntryFilters(ItemLedgEntry, Item);
        exit(ItemLedgEntry.IsEmpty());
    end;

    procedure SetStartDate(DateValue: Date)
    begin
        StartDate := DateValue;
    end;

    procedure SetEndDate(DateValue: Date)
    begin
        EndDate := DateValue;
    end;

    procedure InitializeRequest(NewStartDate: Date; NewEndDate: Date; NewShowExpected: Boolean)
    begin
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        ShowExpected := NewShowExpected;
    end;

    local procedure GetUrlForReportDrilldown(ItemNumber: Code[20]): Text
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        // Generates a URL to the report which sets tab "Item" and field "Field1" on the request page, such as
        // dynamicsnav://hostname:port/instance/company/runreport?report=5801<&Tenant=tenantId>&filter=Item.Field1:1100.
        // TODO
        // Eventually leverage parameters 5 and 6 of GETURL by adding ",Item,TRUE)" and
        // use filter Item.SETFILTER("No.",'=%1',ItemNumber);.
        exit(GetUrl(ClientTypeManagement.GetCurrentClientType(), CompanyName, OBJECTTYPE::Report, REPORT::"Invt. Valuation - Cost Spec.") +
          StrSubstNo('&filter=Item.Field1:%1', ItemNumber));
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    var
        ExpectedCostsLbl: Label 'This report includes entries that have been posted with expected costs.';
        ExpectedCostsNotCalculatedLbl: Label 'Expected costs have not been calculated.';
    begin
        if (StartDate = 0D) and (EndDate = 0D) then
            EndDate := WorkDate();

        if StartDate in [0D, 00000101D] then
            StartDateText := ''
        else
            StartDateText := Format(StartDate - 1);

        EndDateText := Format(EndDate);

        ItemFilter := Item.GetFilters();
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter
        else
            ItemFilterHeading := '';

        if ShowExpected then
            ReportIncludesExpectedCostsTxt := ExpectedCostsLbl
        else
            ReportIncludesExpectedCostsTxt := ExpectedCostsNotCalculatedLbl;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterItemGetRecord(var Item: Record Item; var SkipItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordItemOnBeforeSkipEmptyLine(var Item: Record Item; var StartingInvoicedQty: Decimal; var IncreaseInvoicedQty: Decimal; var DecreaseInvoicedQty: Decimal; var IsHandled: Boolean; var IsEmptyLine: Boolean; var StartingExpectedQty: Decimal; var IncreaseExpectedQty: Decimal; var DecreaseExpectedQty: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnItemOnAfterGetRecordOnAfterValueEntrySetInitialFilters(var ValueEntry: Record "Value Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateItemOnBeforeAssignDecreaseAmounts(var ValueEntry: Record "Value Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateItemOnAfterAssignDecreaseAmounts(var ValueEntry: Record "Value Entry"; Item: Record Item; var DecreaseInvoicedValue: Decimal; var DecreaseInvoicedQty: Decimal; var DecreaseExpectedValue: Decimal; var DecreaseExpectedQty: Decimal; var IncreaseInvoicedValue: Decimal; var IncreaseInvoicedQty: Decimal; var IncreaseExpectedValue: Decimal; var IncreaseExpectedQty: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetOutboundItemEntryOnAfterSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;
}