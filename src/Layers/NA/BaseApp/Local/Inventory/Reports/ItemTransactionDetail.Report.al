// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 10136 "Item Transaction Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemTransactionDetail.rdlc';
    Caption = 'Item Transaction Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Date Filter", "Inventory Posting Group", "Statistics Group";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgerFilter; ItemLedgerFilter)
            {
            }
            column(NewPagePerRecordNo; NewPagePerRecordNo)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Item_Ledger_Entry__TABLECAPTION__________ItemLedgerFilter; "Item Ledger Entry".TableCaption + ': ' + ItemLedgerFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(QuantityOnHand; QuantityOnHandStart)
            {
                DecimalPlaces = 2 : 5;
            }
            column(STRSUBSTNO_Text000_FromDate_; StrSubstNo(Text000, FromDate))
            {
            }
            column(ValueOnHand; ValueOnHandStart)
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Item_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Inventory_Transaction_DetailCaption; Inventory_Transaction_DetailCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Posting_Date_Caption; "Item Ledger Entry".FieldCaption("Posting Date"))
            {
            }
            column(Item_Ledger_Entry__Entry_Type_Caption; Item_Ledger_Entry__Entry_Type_CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Document_No__Caption; "Item Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(QuantityOnHand_Control28Caption; QuantityOnHand_Control28CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Entry_No__Caption; "Item Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Item_Ledger_Entry__Location_Code_Caption; "Item Ledger Entry".FieldCaption("Location Code"))
            {
            }
            column(Item_Ledger_Entry_Quantity_Control5Caption; "Item Ledger Entry".FieldCaption(Quantity))
            {
            }
            column(Item_Ledger_Entry__Cost_Amount__Actual___Control13Caption; "Item Ledger Entry".FieldCaption("Cost Amount (Actual)"))
            {
            }
            column(ValueOnHand_Control26Caption; ValueOnHand_Control26CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Source_No__Caption; "Item Ledger Entry".FieldCaption("Source No."))
            {
            }
            column(Item_Ledger_Entry__Source_Type_Caption; "Item Ledger Entry".FieldCaption("Source Type"))
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            dataitem(PriorItemLedgerEntry; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", "Variant Code", "Location Code", "Posting Date");
                column(ValueEntry__Posting_Date_; ValueEntry."Posting Date")
                {
                }
                column(ValueEntry__Document_No__; ValueEntry."Document No.")
                {
                }
                column(FORMAT_ValueEntry__Source_Type__; Format(ValueEntry."Source Type"))
                {
                }
                column(ValueEntry__Source_No__; ValueEntry."Source No.")
                {
                }
                column(QuantityOnHand_Control1020007; QuantityOnHand)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Adjustment; Adjustment)
                {
                }
                column(ValueOnHand_Control1020009; ValueOnHand)
                {
                }
                column(Entry_No__; -"Entry No.")
                {
                }
                column(PriorItemLedgerEntry_Entry_No_; "Entry No.")
                {
                }
                column(PriorItemLedgerEntry_Item_No_; "Item No.")
                {
                }
                column(PriorItemLedgerEntry_Variant_Code; "Variant Code")
                {
                }
                column(PriorItemLedgerEntry_Location_Code; "Location Code")
                {
                }
                column(PriorItemLedgerEntry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(PriorItemLedgerEntry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Cost_AdjustmentCaption; Cost_AdjustmentCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Adjustment := 0;
                    ValueEntry.Reset();
                    ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
                    ValueEntry.SetRange("Item Ledger Entry No.", "Entry No.");
                    ValueEntry.SetRange("Posting Date", FromDate, ToDate);

                    if ValueEntry.FindSet() then begin
                        repeat
                            Adjustment := Adjustment + ValueEntry."Cost Amount (Actual)";
                        until ValueEntry.Next() = 0;
                        if Adjustment <> 0 then
                            ValueOnHand := ValueOnHand + Adjustment
                        else
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if ItemLedgerFilter <> '' then
                        CurrReport.Break();
                    if not SetCurrentKey("Item No.", "Variant Code", "Global Dimension 1 Code",
                         "Global Dimension 2 Code", "Location Code", "Posting Date")
                    then
                        SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");
                    SetRange("Posting Date", 0D, FromDate - 1);
                end;
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Posting Date" = field("Date Filter");
                DataItemTableView = sorting("Item No.", "Variant Code", "Location Code", "Posting Date");
                RequestFilterFields = "Entry Type";
                column(QuantityOnHandCF; QuantityOnHandCF)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueOnHandCF; ValueOnHandCF)
                {
                }
                column(Item_Ledger_Entry_Quantity; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Cost_Amount__Actual__; "Cost Amount (Actual)")
                {
                }
                column(STRSUBSTNO_Text002__Variant_Code__; StrSubstNo(Text002, "Variant Code"))
                {
                }
                column(ItemVariant_Description; ItemVariant.Description)
                {
                }
                column(Item_Ledger_Entry__Posting_Date_; "Posting Date")
                {
                }
                column(Item_Ledger_Entry__Entry_Type_; "Entry Type")
                {
                }
                column(Item_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(QuantityOnHand_Control28; QuantityOnHand)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Location_Code_; "Location Code")
                {
                }
                column(Item_Ledger_Entry_Quantity_Control5; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Cost_Amount__Actual___Control13; "Cost Amount (Actual)")
                {
                }
                column(ValueOnHand_Control26; ValueOnHand)
                {
                }
                column(Item_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Item_Ledger_Entry__Source_No__; "Source No.")
                {
                }
                column(Item_Ledger_Entry__Source_Type_; "Source Type")
                {
                }
                column(QuantityOnHandCF_Control31; QuantityOnHandCF)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueOnHandCF_Control42; ValueOnHandCF)
                {
                }
                column(Item_Ledger_Entry_Quantity_Control44; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Cost_Amount__Actual___Control45; "Cost Amount (Actual)")
                {
                }
                column(Item_Description_Control32; Item.Description)
                {
                }
                column(QuantityOnHand_Control35; QuantityOnHand)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Item_No__; "Item No.")
                {
                }
                column(STRSUBSTNO_Text001_ToDate_; StrSubstNo(Text001, ToDate))
                {
                }
                column(ValueOnHand_Control48; ValueOnHand)
                {
                }
                column(Variant_Code; "Variant Code")
                {
                }
                column(SumQuantity; SumQuantity)
                {
                }
                column(SumCostAmountActual; SumCostAmountActual)
                {
                }
                column(ItemVariantFlag; ItemVariantFlag)
                {
                }
                column(Item_Ledger_Entry__Item_No___Control49; "Item No.")
                {
                }
                column(Item_Description_Control50; Item.Description)
                {
                }
                column(Item_Ledger_Entry_Quantity_Control52; Quantity)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Cost_Amount__Actual___Control53; "Cost Amount (Actual)")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
                {
                }
                column(Balance_ForwardCaption_Control39; Balance_ForwardCaption_Control39Lbl)
                {
                }
                column(Balance_to_Carry_ForwardCaption; Balance_to_Carry_ForwardCaptionLbl)
                {
                }
                column(Balance_to_Carry_ForwardCaption_Control43; Balance_to_Carry_ForwardCaption_Control43Lbl)
                {
                }
                column(Total_of_EntriesCaption; Total_of_EntriesCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                    if "Invoiced Quantity" <> Quantity then
                        "Cost Amount (Actual)" := "Cost Amount (Expected)";

                    if ItemLedgerFilter = '' then begin
                        QuantityOnHand := QuantityOnHand + Quantity;
                        ValueOnHand := ValueOnHand + "Cost Amount (Actual)";
                    end;

                    SumQuantity := SumQuantity + Quantity;
                    SumCostAmountActual := SumCostAmountActual + "Cost Amount (Actual)";
                    if PreviousVariantCode <> "Variant Code" then begin
                        Clear(ItemVariant);
                        ItemVariantFlag := false;
                        if ItemVariant.Get("Item No.", "Variant Code") and ("Variant Code" <> '') then
                            ItemVariantFlag := true;
                        PreviousVariantCode := "Variant Code";
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not SetCurrentKey("Item No.", "Variant Code", "Global Dimension 1 Code",
                         "Global Dimension 2 Code", "Location Code", "Posting Date")
                    then
                        SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");

                    SumQuantity := 0;
                    SumCostAmountActual := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if ItemLedgerFilter = '' then begin
                    SetRange("Date Filter", 0D, FromDate - 1);
                    CalcFields("Net Change");
                    QuantityOnHand := "Net Change";
                    ValueEntry.Reset();
                    ValueEntry.SetRange("Posting Date", 0D, FromDate - 1);
                    CopyFilter("Location Filter", ValueEntry."Location Code");
                    CopyFilter("Variant Filter", ValueEntry."Variant Code");
                    CopyFilter("Global Dimension 1 Filter", ValueEntry."Global Dimension 1 Code");
                    CopyFilter("Global Dimension 2 Filter", ValueEntry."Global Dimension 2 Code");
                    ValueEntry.SetRange("Item No.", "No.");

                    if not ValueEntry.SetCurrentKey(
                         "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type",
                         "Item Charge No.", "Location Code", "Variant Code", "Global Dimension 1 Code", "Global Dimension 2 Code")
                    then
                        ValueEntry.SetCurrentKey(
                          "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type",
                          "Item Charge No.", "Location Code", "Variant Code");
                    ValueEntry.CalcSums("Cost Amount (Actual)");
                    ValueOnHand := ValueEntry."Cost Amount (Actual)";
                end else begin        // If the user enters any filters for Item Ledger Entries,
                    QuantityOnHand := 0; // the balance to date fields (Qty and Value on Hand) can
                    ValueOnHand := 0;    // never contain the correct values. Therefore, we just
                end;                  // set them all to zero.

                SetRange("Date Filter", FromDate, ToDate);

                ValueOnHandStart := ValueOnHand;
                QuantityOnHandStart := QuantityOnHand;
                if PrintOnlyOnePerPage then
                    NewPagePerRecordNo := NewPagePerRecordNo + 1;
            end;

            trigger OnPreDataItem()
            begin
                FromDate := GetRangeMin("Date Filter");
                ToDate := GetRangeMax("Date Filter");

                NewPagePerRecordNo := 1;
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
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        Caption = 'New Page per Item';
                        ToolTip = 'Specifies that each item begins on a new page.';
                    }
                }
            }
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
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        ItemLedgerFilter := "Item Ledger Entry".GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ItemVariant: Record "Item Variant";
        ValueEntry: Record "Value Entry";
        ItemFilter: Text;
        ItemLedgerFilter: Text;
        PrintOnlyOnePerPage: Boolean;
        FromDate: Date;
        ToDate: Date;
        QuantityOnHand: Decimal;
        ValueOnHand: Decimal;
        QuantityOnHandStart: Decimal;
        ValueOnHandStart: Decimal;
        QuantityOnHandCF: Decimal;
        ValueOnHandCF: Decimal;
        Text000: Label 'Beginning Balance (%1)';
        Text001: Label 'Ending Balance (%1)';
        Text002: Label 'Variant: %1';
        Adjustment: Decimal;
        NewPagePerRecordNo: Integer;
        SumQuantity: Decimal;
        SumCostAmountActual: Decimal;
        PreviousVariantCode: Code[10];
        ItemVariantFlag: Boolean;
        Inventory_Transaction_DetailCaptionLbl: Label 'Inventory Transaction Detail';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_Ledger_Entry__Entry_Type_CaptionLbl: Label 'Entry Type';
        QuantityOnHand_Control28CaptionLbl: Label 'Quantity on Hand';
        ValueOnHand_Control26CaptionLbl: Label 'Value on Hand';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit:';
        Cost_AdjustmentCaptionLbl: Label 'Cost Adjustment';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Balance_ForwardCaption_Control39Lbl: Label 'Balance Forward';
        Balance_to_Carry_ForwardCaptionLbl: Label 'Balance to Carry Forward';
        Balance_to_Carry_ForwardCaption_Control43Lbl: Label 'Balance to Carry Forward';
        Total_of_EntriesCaptionLbl: Label 'Total of Entries';
}

