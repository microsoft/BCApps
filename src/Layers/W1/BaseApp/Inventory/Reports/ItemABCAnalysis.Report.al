// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;

report 723 "Item - ABC Analysis"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item - ABC Analysis';
    DefaultRenderingLayout = Excel;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Inventory Posting Group", "Gen. Prod. Posting Group", "Date Filter", "Location Filter";

            trigger OnPreDataItem()
            begin
                PopulateBuffer();
                Item.SetRange("No.", '');
            end;
        }
        dataitem(TempItemABCBuffer; "Item ABC Buffer")
        {
            DataItemTableView = sorting("Item No.");

            column(ItemNo; "Item No.")
            {
                IncludeCaption = true;
            }
            column(Description; Description)
            {
                IncludeCaption = true;
            }
            column(InventoryPostingGroup; "Inventory Posting Group")
            {
                IncludeCaption = true;
            }
            column(SalesLCY; "Sales (LCY)")
            {
                IncludeCaption = true;
            }
            column(ABC; ABC)
            {
            }
            column(Pct; Pct)
            {
            }
            column(NoA; NoA)
            {
            }
            column(NoB; NoB)
            {
            }
            column(NoC; NoC)
            {
            }
            column(ABLimit; ABLimit)
            {
            }
            column(BCLimit; BCLimit)
            {
            }
            column(AminAmt; AminAmt)
            {
            }
            column(BMinAmt; BMinAmt)
            {
            }
            column(Col1TotalAllRec; Col1TotalAllRec)
            {
            }
            column(NoOfItemsInClass; NoOfItemsInClass)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not PrintZeroLines and ("Sales (LCY)" = 0) then
                    CurrReport.Skip();

                NoOfItemsInClass := 1;

                case true of
                    "Sales (LCY)" >= AminAmt:
                        begin
                            ABC := 'A';
                            NoA := NoA + 1;
                        end;
                    "Sales (LCY)" >= BMinAmt:
                        begin
                            ABC := 'B';
                            NoB := NoB + 1;
                        end;
                    else begin
                        ABC := 'C';
                        NoC := NoC + 1;
                    end;
                end;

                if not Aprint and (ABC = 'A') then
                    CurrReport.Skip();
                if not BPrint and (ABC = 'B') then
                    CurrReport.Skip();
                if not CPrint and (ABC = 'C') then
                    CurrReport.Skip();
                Col1TotalStatistic := Col1TotalStatistic + "Sales (LCY)";
                if Col1TotalAllRec <> 0 then
                    Pct := Round("Sales (LCY)" / Col1TotalAllRec * 100, 0.01, '=');

                PCTTotalStatistic := PCTTotalStatistic + Pct;
                OnAfterTempItemABCBuffer(TempItemABCBuffer, ABC);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item ABC Analysis';
        AboutText = 'Analyze your inventory items by ranking them into A, B, and C categories based on their Sales (LCY) amounts. Use the results to identify high-value items, focus on top performers, and support better purchasing and replenishment decisions.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    group("Ratio Cat. A/B/C")
                    {
                        Caption = 'Ratio Cat. A/B/C';
                        field(RatioCatA; APct)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 0;
                            Caption = 'A';
                            DecimalPlaces = 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with small volume and high value.';

                            trigger OnValidate()
                            begin
                                CPct := CalcPercentage(APct, BPct);
                            end;
                        }
                        field(RatioCatB; BPct)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 0;
                            Caption = 'B';
                            DecimalPlaces = 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with the medium volume and medium value.';

                            trigger OnValidate()
                            begin
                                CPct := CalcPercentage(APct, BPct);
                            end;
                        }
                        field(RatioCatC; CPct)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 0;
                            Caption = 'C';
                            DecimalPlaces = 0;
                            MaxValue = 100;
                            MinValue = 0;
                            ToolTip = 'Specifies items with high volume and small value.';

                            trigger OnValidate()
                            begin
                                BPct := CalcPercentage(APct, CPct);
                            end;
                        }
                    }
                    field(ShowCategoryA; Aprint)
                    {
                        Caption = 'Show Category A';
                        ToolTip = 'Specifies that this category of items are shown.';
                    }
                    field(ShowCategoryB; BPrint)
                    {
                        Caption = 'Show Category B';
                        ToolTip = 'Specifies that this category of items are shown.';
                    }
                    field(ShowCategoryC; CPrint)
                    {
                        Caption = 'Show Category C';
                        ToolTip = 'Specifies that this category of items are shown.';
                    }
                    field(PrintZero; PrintZeroLines)
                    {
                        Caption = 'Print Lines with 0';
                        ToolTip = 'Specifies that lines with no valuation are included. These lines are often excluded from the analysis.';
                    }
                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item Filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Item ABC Analysis';
            Type = Excel;
            LayoutFile = './Inventory/Reports/ItemABCAnalysis.xlsx';
            Summary = 'Built in layout for the Item ABC Analysis Excel report.';
        }
    }

    labels
    {
        ItemABCAnalysisPrintHeadingLbl = 'Item ABC Analysis';
        ItemABCAnalysisPrintLbl = 'Item ABC Analysis (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemABCAnalysisLbl = 'Item ABC (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemABCAnalysisStructureLbl = 'Item ABC Analysis (Structure)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemABCAnalysisStructureHeadingLbl = 'Item ABC Analysis Structure';
        DataRetrievedLbl = 'Data retrieved:';
        PercentageABCLbl = 'Percentage A/B/C:';
        ABCLbl = 'A/B/C';
        PercentageLbl = '%';
        TotalLbl = 'Total';
        ALbl = 'A';
        BLbl = 'B';
        CLbl = 'C';
        RangeLbl = 'Range';
        ShareLbl = 'Share (%)';
        NoLbl = 'No';
        FromCumValueLbl = 'From Cumulative Value';
        FromSingleValueLbl = 'From Single Value';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
        NoOfItemsInClassLbl = 'No. of items in class';
    }

    trigger OnInitReport()
    var
        ABCAnalysisSetup: Record "ABC Analysis Setup";
    begin
        ABCAnalysisSetup.Get();
        if APct = 0 then begin
            APct := ABCAnalysisSetup."Category A";
            BPct := ABCAnalysisSetup."Category B";
            CPct := ABCAnalysisSetup."Category C";
            Aprint := true;
            BPrint := true;
            CPrint := true;
        end;
    end;

    trigger OnPreReport()
    begin
        UpdateRequestPageFilterValues();
    end;

    var
        PreparingLbl: Label 'Preparing Analysis\';
        TotalInAnalysisLbl: Label 'Total in Analysis #1#########\', Comment = '#1 = Number of Items to calculate';
        CalculatedLbl: Label 'Calculated        #2#########\', Comment = '#2 = Number of Items calculated.';
        ItemNoLbl: Label 'Item No.          #3#########', Comment = '#3 = Item No.';
        Window: Dialog;
        NoCalculated: Integer;
        APct: Decimal;
        BPct: Decimal;
        CPct: Decimal;
        ABLimit: Decimal;
        BCLimit: Decimal;
        AminAmt: Decimal;
        BMinAmt: Decimal;
        CumAmt: Decimal;
        Aprint: Boolean;
        BPrint: Boolean;
        CPrint: Boolean;
        NoA: Integer;
        NoB: Integer;
        NoC: Integer;
        PrintZeroLines: Boolean;
        Col1TotalAllRec: Decimal;
        Col1TotalStatistic: Decimal;
        Pct: Decimal;
        PCTTotalStatistic: Decimal;
        ItemFilterHeading: Text;
        NoOfItemsInClass: Integer;

    protected var
        ABC: Text[1];

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    var
        ItemFilter: Text;
    begin
        ItemFilter := Item.GetFilters();
        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter
        else
            ItemFilterHeading := '';
    end;

    local procedure PopulateBuffer()
    begin
        Window.Open(
                          PreparingLbl +
                          TotalInAnalysisLbl +
                          CalculatedLbl +
                          ItemNoLbl);
        Window.Update(1, Format(Item.Count));

        Item.SetLoadFields(Description, "Inventory Posting Group");
        if Item.FindSet() then
            repeat
                Item.CalcFields("Sales (LCY)");
                TempItemABCBuffer.Init();
                TempItemABCBuffer."Sales (LCY)" := Item."Sales (LCY)";
                TempItemABCBuffer."Item No." := Item."No.";
                TempItemABCBuffer.Description := Item.Description;
                TempItemABCBuffer."Inventory Posting Group" := Item."Inventory Posting Group";
                TempItemABCBuffer.Insert();

                Col1TotalAllRec := Col1TotalAllRec + Item."Sales (LCY)";

                NoCalculated := NoCalculated + 1;
                if NoCalculated mod 100 = 0 then begin
                    Window.Update(2, Format(NoCalculated));
                    Window.Update(3, Format(Item."No."));
                end;
            until Item.Next() = 0;

        Item.FindFirst();

        ABLimit := Col1TotalAllRec / 100 * (BPct + CPct);
        BCLimit := Col1TotalAllRec / 100 * CPct;

        TempItemABCBuffer.SetCurrentKey("Sales (LCY)", "Item No.");
        if TempItemABCBuffer.FindSet() then
            repeat
                CumAmt := CumAmt + TempItemABCBuffer."Sales (LCY)";
                if (CumAmt > BCLimit) and (BMinAmt = 0) then
                    BMinAmt := TempItemABCBuffer."Sales (LCY)";
                if (CumAmt > ABLimit) and (AminAmt = 0) then
                    AminAmt := TempItemABCBuffer."Sales (LCY)";
            until TempItemABCBuffer.Next() = 0;
    end;

    local procedure CalcPercentage(Value1: Decimal; Value2: Decimal): Decimal
    var
        MaxValueErrorErr: Label 'The sum of percentages cannot exceed 100%. Please adjust the values and try again.';
    begin
        if Value1 + Value2 >= 100 then
            Error(MaxValueErrorErr);

        exit(100 - Value1 - Value2);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterTempItemABCBuffer(var ItemABCBuffer: Record "Item ABC Buffer"; ABC: Text[1])
    begin
    end;
}
