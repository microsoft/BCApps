// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 5805 "Item Register - Value"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemRegisterValue.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Register Value';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Register"; "Item Register")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemRegistryCaption; TableCaption + ': ' + ItemRegFilter)
            {
            }
            column(No_ItemRegister; "No.")
            {
            }
            column(ItemEntryTypeTotalCost1; ItemEntryTypeTotalCost[1])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalAmount1; ItemEntryTypeTotalAmount[1])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription1; ItemEntryTypeDescription[1])
            {
            }
            column(EntryTypeTotalCost1; EntryTypeTotalCost[1])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeDescription1; EntryTypeDescription[1])
            {
            }
            column(ShowTotalLineSummary1; ShowTotalLineSummary[1])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp1; ItemEntryTypeTotalCostExp[1])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCostExp1; EntryTypeTotalCostExp[1])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost2; ItemEntryTypeTotalCost[2])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalAmount2; ItemEntryTypeTotalAmount[2])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription2; ItemEntryTypeDescription[2])
            {
            }
            column(EntryTypeTotalCost2; EntryTypeTotalCost[2])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeDescription2; EntryTypeDescription[2])
            {
            }
            column(ShowTotalLineSummary2; ShowTotalLineSummary[2])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp2; ItemEntryTypeTotalCostExp[2])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCostExp2; EntryTypeTotalCostExp[2])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost3; ItemEntryTypeTotalCost[3])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalAmount3; ItemEntryTypeTotalAmount[3])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription3; ItemEntryTypeDescription[3])
            {
            }
            column(EntryTypeTotalCost3; EntryTypeTotalCost[3])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeDescription3; EntryTypeDescription[3])
            {
            }
            column(ShowTotalLineSummary3; ShowTotalLineSummary[3])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp3; ItemEntryTypeTotalCostExp[3])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCostExp3; EntryTypeTotalCostExp[3])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCost4; EntryTypeTotalCost[4])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeDescription4; EntryTypeDescription[4])
            {
            }
            column(ItemEntryTypeDescription4; ItemEntryTypeDescription[4])
            {
            }
            column(ItemEntryTypeTotalAmount4; ItemEntryTypeTotalAmount[4])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost4; ItemEntryTypeTotalCost[4])
            {
                AutoFormatType = 1;
            }
            column(ShowTotalLineSummary4; ShowTotalLineSummary[4])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp4; ItemEntryTypeTotalCostExp[4])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCostExp4; EntryTypeTotalCostExp[4])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCost5; EntryTypeTotalCost[5])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeDescription5; EntryTypeDescription[5])
            {
            }
            column(ItemEntryTypeTotalAmount5; ItemEntryTypeTotalAmount[5])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription5; ItemEntryTypeDescription[5])
            {
            }
            column(ItemEntryTypeTotalCost5; ItemEntryTypeTotalCost[5])
            {
                AutoFormatType = 1;
            }
            column(ShowTotalLineSummary5; ShowTotalLineSummary[5])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp5; ItemEntryTypeTotalCostExp[5])
            {
                AutoFormatType = 1;
            }
            column(EntryTypeTotalCostExp5; EntryTypeTotalCostExp[5])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription6; ItemEntryTypeDescription[6])
            {
            }
            column(ItemEntryTypeTotalAmount6; ItemEntryTypeTotalAmount[6])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost6; ItemEntryTypeTotalCost[6])
            {
                AutoFormatType = 1;
            }
            column(ShowTotalLineSummary6; ShowTotalLineSummary[6])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp6; ItemEntryTypeTotalCostExp[6])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost7; ItemEntryTypeTotalCost[7])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalAmount7; ItemEntryTypeTotalAmount[7])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription7; ItemEntryTypeDescription[7])
            {
            }
            column(ShowTotalLineSummary7; ShowTotalLineSummary[7])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp7; ItemEntryTypeTotalCostExp[7])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost8; ItemEntryTypeTotalCost[8])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalAmount8; ItemEntryTypeTotalAmount[8])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription8; ItemEntryTypeDescription[8])
            {
            }
            column(ShowTotalLineSummary8; ShowTotalLineSummary[8])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp8; ItemEntryTypeTotalCostExp[8])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription9; ItemEntryTypeDescription[9])
            {
            }
            column(ItemEntryTypeTotalAmount9; ItemEntryTypeTotalAmount[9])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost9; ItemEntryTypeTotalCost[9])
            {
                AutoFormatType = 1;
            }
            column(ShowTotalLineSummary9; ShowTotalLineSummary[9])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp9; ItemEntryTypeTotalCostExp[9])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeDescription10; ItemEntryTypeDescription[10])
            {
            }
            column(ItemEntryTypeTotalAmount10; ItemEntryTypeTotalAmount[10])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCost10; ItemEntryTypeTotalCost[10])
            {
                AutoFormatType = 1;
            }
            column(ShowTotalLineSummary10; ShowTotalLineSummary[10])
            {
                AutoFormatType = 1;
            }
            column(ItemEntryTypeTotalCostExp10; ItemEntryTypeTotalCostExp[10])
            {
                AutoFormatType = 1;
            }
            column(CostAmountActual_ValueEntry; "Value Entry"."Cost Amount (Actual)")
            {
            }
            column(SalesAmountActual_ValueEntry; "Value Entry"."Sales Amount (Actual)")
            {
            }
            column(CostAmountExpected_ValueEntry; "Value Entry"."Cost Amount (Expected)")
            {
            }
            column(ItemRegisterValueCaption; ItemRegisterValueCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ValEntyItmLedgEntyTypCptn; ValEntyItmLedgEntyTypCptnLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(ValueEntrySalesAmtActCptn; ValueEntrySalesAmtActCptnLbl)
            {
            }
            column(UnitAmountCaption; UnitAmountCaptionLbl)
            {
            }
            column(ItemRegisterNoCaption; ItemRegisterNoCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(EntryNo_ValueEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CostAmountActual1_ValueEntry; "Cost Amount (Actual)")
                {
                    AutoFormatType = 1;
                    IncludeCaption = true;
                }
                column(CostperUnit_ValueEntry; "Cost per Unit")
                {
                    IncludeCaption = true;
                }
                column(SalesAmountActual1_ValueEntry; "Sales Amount (Actual)")
                {
                }
                column(UnitAmount; UnitAmount)
                {
                    AutoFormatType = 2;
                }
                column(InvoicedQuantity_ValueEntry; "Invoiced Quantity")
                {
                    IncludeCaption = true;
                }
                column(ItemLedgerEntryType_ValueEntry; "Item Ledger Entry Type")
                {
                }
                column(PostingDate_ValueEntry; "Posting Date")
                {
                    IncludeCaption = true;
                }
                column(ItemDescription; ItemDescription)
                {
                }
                column(ItemNo_ValueEntry; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(ItemLedgerEntryNo_ValueEntry; "Item Ledger Entry No.")
                {
                    IncludeCaption = true;
                }
                column(EntryType_ValueEntry; "Entry Type")
                {
                    IncludeCaption = true;
                }
                column(CostAmountExpected1_ValueEntry; "Cost Amount (Expected)")
                {
                    IncludeCaption = true;
                }
                column(ItemEntryTypeDescription11; ItemEntryTypeDescription[1])
                {
                }
                column(ItemEntryTypeTotalAmount11; ItemEntryTypeTotalAmount[1])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost11; ItemEntryTypeTotalCost[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCost11; EntryTypeTotalCost[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription11; EntryTypeDescription[1])
                {
                }
                column(ShowItemLineSummary1; ShowItemLineSummary[1])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp11; ItemEntryTypeTotalCostExp[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCostExp11; EntryTypeTotalCostExp[1])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost12; ItemEntryTypeTotalCost[2])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount12; ItemEntryTypeTotalAmount[2])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription12; ItemEntryTypeDescription[2])
                {
                }
                column(EntryTypeDescription12; EntryTypeDescription[2])
                {
                }
                column(EntryTypeTotalCost12; EntryTypeTotalCost[2])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary2; ShowItemLineSummary[2])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp12; ItemEntryTypeTotalCostExp[2])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCostExp12; EntryTypeTotalCostExp[2])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost13; ItemEntryTypeTotalCost[3])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount13; ItemEntryTypeTotalAmount[3])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription13; ItemEntryTypeDescription[3])
                {
                }
                column(EntryTypeDescription13; EntryTypeDescription[3])
                {
                }
                column(EntryTypeTotalCost13; EntryTypeTotalCost[3])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary3; ShowItemLineSummary[3])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp13; ItemEntryTypeTotalCostExp[3])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCostExp13; EntryTypeTotalCostExp[3])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription14; EntryTypeDescription[4])
                {
                }
                column(EntryTypeTotalCost14; EntryTypeTotalCost[4])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost14; ItemEntryTypeTotalCost[4])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount14; ItemEntryTypeTotalAmount[4])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription14; ItemEntryTypeDescription[4])
                {
                }
                column(ShowItemLineSummary4; ShowItemLineSummary[4])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp14; ItemEntryTypeTotalCostExp[4])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCostExp14; EntryTypeTotalCostExp[4])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription15; EntryTypeDescription[5])
                {
                }
                column(EntryTypeTotalCost15; EntryTypeTotalCost[5])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription15; ItemEntryTypeDescription[5])
                {
                }
                column(ItemEntryTypeTotalAmount15; ItemEntryTypeTotalAmount[5])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost15; ItemEntryTypeTotalCost[5])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary5; ShowItemLineSummary[5])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp15; ItemEntryTypeTotalCostExp[5])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeTotalCostExp15; EntryTypeTotalCostExp[5])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription16; ItemEntryTypeDescription[6])
                {
                }
                column(ItemEntryTypeTotalCost16; ItemEntryTypeTotalCost[6])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount16; ItemEntryTypeTotalAmount[6])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary6; ShowItemLineSummary[6])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp16; ItemEntryTypeTotalCostExp[6])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost17; ItemEntryTypeTotalCost[7])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount17; ItemEntryTypeTotalAmount[7])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription17; ItemEntryTypeDescription[7])
                {
                }
                column(ShowItemLineSummary7; ShowItemLineSummary[7])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp17; ItemEntryTypeTotalCostExp[7])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost18; ItemEntryTypeTotalCost[8])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalAmount18; ItemEntryTypeTotalAmount[8])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription18; ItemEntryTypeDescription[8])
                {
                }
                column(ShowItemLineSummary8; ShowItemLineSummary[8])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp18; ItemEntryTypeTotalCostExp[8])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription19; ItemEntryTypeDescription[9])
                {
                }
                column(ItemEntryTypeTotalAmount19; ItemEntryTypeTotalAmount[9])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost19; ItemEntryTypeTotalCost[9])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary9; ShowItemLineSummary[9])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp19; ItemEntryTypeTotalCostExp[9])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeDescription20; ItemEntryTypeDescription[10])
                {
                }
                column(ItemEntryTypeTotalAmount20; ItemEntryTypeTotalAmount[10])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCost20; ItemEntryTypeTotalCost[10])
                {
                    AutoFormatType = 1;
                }
                column(ShowItemLineSummary10; ShowItemLineSummary[10])
                {
                    AutoFormatType = 1;
                }
                column(ItemEntryTypeTotalCostExp20; ItemEntryTypeTotalCostExp[10])
                {
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    Clear(ItemEntryTypeTotalCost);
                    Clear(ItemEntryTypeTotalCostExp);
                    Clear(ItemEntryTypeTotalAmount);
                    Clear(EntryTypeTotalCost);
                    Clear(EntryTypeTotalCostExp);

                    if Item.Get("Item No.") then
                        ItemDescription := Item.Description;

                    if "Valued Quantity" <> 0 then
                        UnitAmount := ("Sales Amount (Actual)" + "Discount Amount") / "Valued Quantity"
                    else
                        UnitAmount := 0;

                    ItemEntryTypeTotalCost["Item Ledger Entry Type".AsInteger() + 1] := "Cost Amount (Actual)";
                    ItemEntryTypeTotalCostExp["Item Ledger Entry Type".AsInteger() + 1] := "Cost Amount (Expected)";
                    ItemEntryTypeTotalAmount["Item Ledger Entry Type".AsInteger() + 1] := "Sales Amount (Actual)";
                    ShowItemLineSummary["Item Ledger Entry Type".AsInteger() + 1] := true;
                    ShowTotalLineSummary["Item Ledger Entry Type".AsInteger() + 1] := true;

                    EntryTypeTotalCost["Entry Type".AsInteger() + 1] := "Cost Amount (Actual)";
                    EntryTypeTotalCostExp["Entry Type".AsInteger() + 1] := "Cost Amount (Expected)";
                    ShowItemLineSummary["Entry Type".AsInteger() + 1] := true;
                    ShowTotalLineSummary["Entry Type".AsInteger() + 1] := true;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Entry No.", "Item Register"."From Value Entry No.", "Item Register"."To Value Entry No.");
                    SetFilter("Item Register No.", '0|%1', "Item Register"."No.");

                    Clear(ShowItemLineSummary);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(ItemEntryTypeTotalCost);
                Clear(ItemEntryTypeTotalCostExp);
                Clear(ItemEntryTypeTotalAmount);
                Clear(EntryTypeTotalCost);
                Clear(EntryTypeTotalCostExp);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemRegFilter := "Item Register".GetFilters();
        for i := 1 to ArrayLen(ItemEntryTypeDescription) do begin
            "Value Entry"."Item Ledger Entry Type" := "Item Ledger Entry Type".FromInteger(i - 1);
            ItemEntryTypeDescription[i] := Format("Value Entry"."Item Ledger Entry Type");
        end;

        for i := 1 to ArrayLen(EntryTypeDescription) do begin
            "Value Entry"."Entry Type" := Enum::"Cost Entry Type".FromInteger(i - 1);
            EntryTypeDescription[i] := Format("Value Entry"."Entry Type");
        end;
    end;

    var
        Item: Record Item;
        ItemRegFilter: Text;
        ItemDescription: Text[100];
        i: Integer;
        UnitAmount: Decimal;
        ItemEntryTypeDescription: array[10] of Text;
        ItemEntryTypeTotalAmount: array[10] of Decimal;
        ItemEntryTypeTotalCost: array[10] of Decimal;
        ItemEntryTypeTotalCostExp: array[10] of Decimal;
        EntryTypeDescription: array[5] of Text;
        EntryTypeTotalCost: array[5] of Decimal;
        EntryTypeTotalCostExp: array[5] of Decimal;
        ShowItemLineSummary: array[10] of Boolean;
        ShowTotalLineSummary: array[10] of Boolean;
        ItemRegisterValueCaptionLbl: Label 'Item Register - Value';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ValEntyItmLedgEntyTypCptnLbl: Label 'Item Ledger Entry Type';
        ItemDescriptionCaptionLbl: Label 'Description';
        ValueEntrySalesAmtActCptnLbl: Label 'Amount';
        UnitAmountCaptionLbl: Label 'Unit Amount';
        ItemRegisterNoCaptionLbl: Label 'Register No.';
        TotalCaptionLbl: Label 'Total';
}

