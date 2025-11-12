// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using System.Utilities;

report 7130 "Item Budget"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemBudget.rdlc';
    Caption = 'Item Budget';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemBudgetFilter; ItemBudgetFilter)
            {
            }
            column(ValueType; ValueType)
            {
                OptionCaption = 'Sales Amount,Cost Amount,Quantity';
                OptionMembers = "Sales Amount","Cost Amount",Quantity;
            }
            column(AnalysisAreaSelection; AnalysisAreaSelection)
            {
            }
            column(InThousands; InThousands)
            {
            }
            column(ItemCaptionItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5]))
            {
            }
            column(PeriodStartDate6; Format(PeriodStartDate[6]))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PeriodStartDate51; Format(PeriodStartDate[5] - 1))
            {
            }
            column(PeriodStartDate61; Format(PeriodStartDate[6] - 1))
            {
            }
            column(PeriodStartDate71; Format(PeriodStartDate[7] - 1))
            {
            }
            column(ItemBudgetCaption; ItemBudgetCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemBudgetFilterCaption; ItemBudgetFilterCaptionLbl)
            {
            }
            column(ValueTypeCaption; ValueTypeCaptionLbl)
            {
            }
            column(AnalysisAreaSelectionCptn; AnalysisAreaSelectionCptnLbl)
            {
            }
            column(AmountsareinThousandsCptn; AmountsareinThousandsCptnLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(No_Item; Item."No.")
                {
                    IncludeCaption = true;
                }
                column(Description_Item; Item.Description)
                {
                }
                column(ItemBudgetedAmount1; ItemBudgetedAmount[1])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ItemBudgetedAmount2; ItemBudgetedAmount[2])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ItemBudgetedAmount3; ItemBudgetedAmount[3])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ItemBudgetedAmount4; ItemBudgetedAmount[4])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ItemBudgetedAmount5; ItemBudgetedAmount[5])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(ItemBudgetedAmount6; ItemBudgetedAmount[6])
                {
                    DecimalPlaces = 0 : 0;
                }
            }

            trigger OnAfterGetRecord()
            begin
                ItemStatBuffer.Reset();
                ItemStatBuffer.SetRange("Analysis Area Filter", AnalysisAreaSelection);
                ItemStatBuffer.SetRange("Item Filter", "No.");
                ItemStatBuffer.SetFilter("Budget Filter", '%1', ItemBudgetFilter);
                ItemStatBuffer.SetFilter("Global Dimension 1 Filter", '%1', GetFilter("Global Dimension 1 Filter"));
                ItemStatBuffer.SetFilter("Global Dimension 2 Filter", '%1', GetFilter("Global Dimension 2 Filter"));
                for i := 1 to 6 do begin
                    ItemStatBuffer.SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    case ValueType of
                        ValueType::"Sales Amount":
                            begin
                                ItemStatBuffer.CalcFields("Budgeted Sales Amount");
                                if InThousands then
                                    ItemStatBuffer."Budgeted Sales Amount" := ItemStatBuffer."Budgeted Sales Amount" / 1000;
                                ItemBudgetedAmount[i] := Round(ItemStatBuffer."Budgeted Sales Amount", 1);
                            end;
                        ValueType::"Cost Amount":
                            begin
                                ItemStatBuffer.CalcFields("Budgeted Cost Amount");
                                if InThousands then
                                    ItemStatBuffer."Budgeted Cost Amount" := ItemStatBuffer."Budgeted Cost Amount" / 1000;
                                ItemBudgetedAmount[i] := Round(ItemStatBuffer."Budgeted Cost Amount", 1);
                            end;
                        ValueType::Quantity:
                            begin
                                ItemStatBuffer.CalcFields("Budgeted Quantity");
                                if InThousands then
                                    ItemStatBuffer."Budgeted Quantity" := ItemStatBuffer."Budgeted Quantity" / 1000;
                                ItemBudgetedAmount[i] := Round(ItemStatBuffer."Budgeted Quantity", 1);
                            end;
                    end;
                end;
                ItemStatBuffer.SetRange("Date Filter", PeriodStartDate[1], PeriodStartDate[7] - 1);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AnalysisArea; AnalysisAreaSelection)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Analysis Area';
                        ToolTip = 'Specifies the application area of the item budget entry. Sales: The budget was set up in Sales & Receivables. Purchase: The budget was set up in Purchases & Payables.';
                    }
                    field(ItemBudgetFilterCtrl; ItemBudgetFilter)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Filter';
                        TableRelation = "Item Budget Name".Name;
                        ToolTip = 'Specifies the item budget(s) for which budget figures are shown.';
                    }
                    field(ShowValueAs; ValueType)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Show Value As';
                        OptionCaption = 'Sales Amount,Cost Amount,Quantity';
                        ToolTip = 'Specifies if the item budget shows sales amounts, cost amounts, or quantities.';
                    }
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(AmountsInWhole1000s; InThousands)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Amounts in whole 1000s';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := WorkDate();
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        for i := 2 to 7 do
            PeriodStartDate[i] := CalcDate(PeriodLength, PeriodStartDate[i - 1]);
    end;

    var
        ItemStatBuffer: Record "Item Statistics Buffer";
        PeriodLength: DateFormula;
        InThousands: Boolean;
        AnalysisAreaSelection: Enum "Analysis Area Type";
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
        ItemFilter: Text;
        ItemBudgetFilter: Text[250];
        ItemBudgetedAmount: array[6] of Decimal;
        PeriodStartDate: array[7] of Date;
        i: Integer;
        ItemBudgetCaptionLbl: Label 'Item Budget';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemBudgetFilterCaptionLbl: Label 'Budget Filter';
        ValueTypeCaptionLbl: Label 'Show Value As';
        AnalysisAreaSelectionCptnLbl: Label 'Analysis Area';
        AmountsareinThousandsCptnLbl: Label 'Amounts are in whole 1000s.';
        ItemDescriptionCaptionLbl: Label 'Name';
}

