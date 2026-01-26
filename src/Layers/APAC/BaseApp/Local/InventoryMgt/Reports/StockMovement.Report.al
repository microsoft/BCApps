// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 28022 "Stock Movement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/InventoryMgt/Reports/StockMovement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Stock Movement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(ItemDateFilter; ItemDateFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(OpeningBalance; OpeningBalance2)
            {
            }
            column(Item__Description_2_; "Description 2")
            {
            }
            column(Text001; Text001Lbl)
            {
            }
            column(Text002; Text002Lbl)
            {
            }
            column(TotalQuantity; TotalQuantity)
            {
            }
            column(TotalPos; TotalPos)
            {
            }
            column(TotalNeg; TotalNeg)
            {
            }
            column(OpeningBalance_Control1500033; OpeningBalance)
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Stock_MovementCaption; Stock_MovementCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Posting_Date_Caption; Item_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Item_Ledger_Entry_QuantityCaption; "Item Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Item_Ledger_Entry__Location_Code_Caption; "Item Ledger Entry".FieldCaption("Location Code"))
            {
            }
            column(Item_Ledger_Entry__Document_No__Caption; "Item Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Item_Ledger_Entry__Entry_Type_Caption; "Item Ledger Entry".FieldCaption("Entry Type"))
            {
            }
            column(PositiveCaption; PositiveCaptionLbl)
            {
            }
            column(NegativeCaption; NegativeCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__External_Document_No__Caption; "Item Ledger Entry".FieldCaption("External Document No."))
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Posting Date" = field("Date Filter");
                column(Item_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Item_Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Item_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Item_Ledger_Entry__Location_Code_; "Location Code")
                {
                }
                column(Item_Ledger_Entry_Quantity; Quantity)
                {
                }
                column(Pos; Pos)
                {
                }
                column(Neg; Neg)
                {
                }
                column(OpeningBalance_Control1500027; OpeningBalance)
                {
                }
                column(Item_Ledger_Entry__External_Document_No__; "External Document No.")
                {
                }
                column(Item_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Item_Ledger_Entry_Item_No_; "Item No.")
                {
                }
                column(Item_Ledger_Entry_Posting_Date; "Posting Date")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Pos := 0;
                    Neg := 0;
                    if "Item Ledger Entry".Quantity > 0 then
                        Pos := "Item Ledger Entry".Quantity
                    else
                        Neg := "Item Ledger Entry".Quantity;
                    OpeningBalance := OpeningBalance + "Item Ledger Entry".Quantity;
                    TotalPos := TotalPos + Pos;
                    TotalNeg := TotalNeg + Neg;
                    TotalQuantity := TotalQuantity + "Item Ledger Entry".Quantity;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TotalQuantity := 0;
                TotalPos := 0;
                TotalNeg := 0;
                OpeningBalance := 0;
                if ItemDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change");
                        OpeningBalance := "Net Change";
                        OpeningBalance2 := OpeningBalance;
                        SetFilter("Date Filter", ItemDateFilter);
                    end;
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
        ItemDateFilter := Item.GetFilter("Date Filter");
    end;

    var
        Pos: Decimal;
        Neg: Decimal;
        OpeningBalance: Decimal;
        TotalQuantity: Decimal;
        TotalPos: Decimal;
        TotalNeg: Decimal;
        ItemDateFilter: Text[60];
        OpeningBalance2: Decimal;
        Text001Lbl: Label 'Opening Balance';
        Text002Lbl: Label 'Closing Balance';
        Stock_MovementCaptionLbl: Label 'Stock Movement';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        PositiveCaptionLbl: Label 'Positive';
        NegativeCaptionLbl: Label 'Negative';
        BalanceCaptionLbl: Label 'Balance';
}

