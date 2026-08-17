// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

report 10143 "Item List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemList.rdlc';
    Caption = 'Item List';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group", "Shelf No.", "Location Filter";
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
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(MoreInfo; MoreInfo)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item_Comment; Format(Comment))
            {
            }
            column(Item__Costing_Method_; "Costing Method")
            {
            }
            column(Item__Shelf_No__; "Shelf No.")
            {
            }
            column(Item__Substitutes_Exist_; Format("Substitutes Exist"))
            {
            }
            column(Item_Blocked; Format(Blocked))
            {
            }
            column(Item_Inventory; Inventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(TotalValue; TotalValue)
            {
            }
            column(TotalValue_Control7; TotalValue)
            {
            }
            column(Item__Base_Unit_of_Measure__Control8; "Base Unit of Measure")
            {
            }
            column(Item_Inventory_Control15; Inventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item_Blocked_Control16; Blocked)
            {
            }
            column(Item__Substitutes_Exist__Control21; "Substitutes Exist")
            {
            }
            column(Item__Shelf_No___Control36; "Shelf No.")
            {
            }
            column(Item__Costing_Method__Control68; "Costing Method")
            {
            }
            column(Item_Description_Control69; Description)
            {
            }
            column(Item__No___Control70; "No.")
            {
            }
            column(Item__Alternative_Item_No__; "Alternative Item No.")
            {
            }
            column(Item__Description_2_; "Description 2")
            {
            }
            column(Item__Tax_Group_Code_; "Tax Group Code")
            {
            }
            column(Item__Vendor_Item_No__; "Vendor Item No.")
            {
            }
            column(SeeComment; SeeComment)
            {
            }
            column(Item__Vendor_No__; "Vendor No.")
            {
            }
            column(Item__Lead_Time_Calculation_; "Lead Time Calculation")
            {
            }
            column(Item__Reorder_Point_; "Reorder Point")
            {
                DecimalPlaces = 2 : 5;
            }
            column(UseSKU; UseSKU)
            {
            }
            column(AnyVariants; AnyVariants())
            {
            }
            column(Item__Stockkeeping_Unit_Exists_; "Stockkeeping Unit Exists")
            {
            }
            column(Item__No___Control49; "No.")
            {
            }
            column(Item_Description_Control50; Description)
            {
            }
            column(Item__Costing_Method__Control51; "Costing Method")
            {
            }
            column(Item__Shelf_No___Control52; "Shelf No.")
            {
            }
            column(Item__Substitutes_Exist__Control53; "Substitutes Exist")
            {
            }
            column(Item_Blocked_Control54; Blocked)
            {
            }
            column(Item_Inventory_Control55; Inventory)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Base_Unit_of_Measure__Control56; "Base Unit of Measure")
            {
            }
            column(TotalValue_Control57; TotalValue)
            {
            }
            column(Item__Alternative_Item_No___Control58; "Alternative Item No.")
            {
            }
            column(Item__Description_2__Control59; "Description 2")
            {
            }
            column(Item__Tax_Group_Code__Control60; "Tax Group Code")
            {
            }
            column(Item__Vendor_Item_No___Control62; "Vendor Item No.")
            {
            }
            column(SeeComment_Control63; SeeComment)
            {
            }
            column(Item__Vendor_No___Control64; "Vendor No.")
            {
            }
            column(Item__Lead_Time_Calculation__Control65; "Lead Time Calculation")
            {
            }
            column(Item__Reorder_Point__Control66; "Reorder Point")
            {
                DecimalPlaces = 2 : 5;
            }
            column(TotalValue_Control37; TotalValue)
            {
            }
            column(NewTotalValue; NewTotalValue)
            {
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Item_ListCaption; Item_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item_CommentCaption; Item_CommentCaptionLbl)
            {
            }
            column(Item__Costing_Method_Caption; FieldCaption("Costing Method"))
            {
            }
            column(Item_InventoryCaption; FieldCaption(Inventory))
            {
            }
            column(TotalValueCaption; TotalValueCaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__Shelf_No__Caption; FieldCaption("Shelf No."))
            {
            }
            column(Item__Substitutes_Exist_Caption; Item__Substitutes_Exist_CaptionLbl)
            {
            }
            column(Item_BlockedCaption; Item_BlockedCaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Item__No___Control49Caption; Item__No___Control49CaptionLbl)
            {
            }
            column(Item__Costing_Method__Control51Caption; FieldCaption("Costing Method"))
            {
            }
            column(Item__Substitutes_Exist__Control53Caption; FieldCaption("Substitutes Exist"))
            {
            }
            column(Item_Blocked_Control54Caption; FieldCaption(Blocked))
            {
            }
            column(Item__Alternative_Item_No___Control58Caption; FieldCaption("Alternative Item No."))
            {
            }
            column(Item__Tax_Group_Code__Control60Caption; FieldCaption("Tax Group Code"))
            {
            }
            column(Item_Inventory_Control55Caption; FieldCaption(Inventory))
            {
            }
            column(TotalValue_Control57Caption; TotalValue_Control57CaptionLbl)
            {
            }
            column(Item__Vendor_Item_No___Control62Caption; FieldCaption("Vendor Item No."))
            {
            }
            column(Item_Description_Control50Caption; FieldCaption(Description))
            {
            }
            column(Item__Vendor_No___Control64Caption; FieldCaption("Vendor No."))
            {
            }
            column(Item__Lead_Time_Calculation__Control65Caption; FieldCaption("Lead Time Calculation"))
            {
            }
            column(Item__Reorder_Point__Control66Caption; FieldCaption("Reorder Point"))
            {
            }
            column(Item__Base_Unit_of_Measure__Control56Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Item__Shelf_No___Control52Caption; FieldCaption("Shelf No."))
            {
            }
            column(Alt_Caption; Alt_CaptionLbl)
            {
            }
            column(Ven_Caption; Ven_CaptionLbl)
            {
            }
            column(Alt_Caption_Control61; Alt_Caption_Control61Lbl)
            {
            }
            column(Ven_Caption_Control67; Ven_Caption_Control67Lbl)
            {
            }
            column(Item_Variant_CodeCaption; Item_Variant_CodeCaptionLbl)
            {
            }
            column(Item_Variant_DescriptionCaption; Item_Variant_DescriptionCaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Item Variant"; "Item Variant")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.", Code);
                column(Item_Variant_Code; Code)
                {
                }
                column(Item_Variant_Description; Description)
                {
                }
                column(Item_Variant_Item_No_; "Item No.")
                {
                }

                trigger OnPreDataItem()
                begin
                    if not MoreInfo or UseSKU then
                        CurrReport.Break();
                end;
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(TotalValue_Control1480000; TotalValue)
                {
                }
                column(Item__Base_Unit_of_Measure__Control1480001; Item."Base Unit of Measure")
                {
                }
                column(Stockkeeping_Unit_Inventory; Inventory)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Blocked_Control1480003; Item.Blocked)
                {
                }
                column(Item__Substitutes_Exist__Control1480004; Item."Substitutes Exist")
                {
                }
                column(Stockkeeping_Unit__Shelf_No__; "Shelf No.")
                {
                }
                column(Item__Costing_Method__Control1480006; Item."Costing Method")
                {
                }
                column(Stockkeeping_Unit_Description; Description)
                {
                }
                column(Stockkeeping_Unit__Item_No__; "Item No.")
                {
                }
                column(Item__Alternative_Item_No___Control1480009; Item."Alternative Item No.")
                {
                }
                column(Stockkeeping_Unit__Description_2_; "Description 2")
                {
                }
                column(Item__Tax_Group_Code__Control1480011; Item."Tax Group Code")
                {
                }
                column(Stockkeeping_Unit__Vendor_Item_No__; "Vendor Item No.")
                {
                }
                column(SeeComment_Control1480016; SeeComment)
                {
                }
                column(Stockkeeping_Unit__Vendor_No__; "Vendor No.")
                {
                }
                column(Stockkeeping_Unit__Lead_Time_Calculation_; "Lead Time Calculation")
                {
                }
                column(Stockkeeping_Unit__Reorder_Point_; "Reorder Point")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Stockkeeping_Unit__Location_Code_; "Location Code")
                {
                }
                column(Stockkeeping_Unit__Variant_Code_; "Variant Code")
                {
                }
                column(Stockkeeping_Unit_Date_Filter; "Date Filter")
                {
                }
                column(Alt_Caption_Control1480012; Alt_Caption_Control1480012Lbl)
                {
                }
                column(Ven_Caption_Control1480020; Ven_Caption_Control1480020Lbl)
                {
                }
                column(Stockkeeping_Unit__Location_Code_Caption; FieldCaption("Location Code"))
                {
                }
                column(Stockkeeping_Unit__Variant_Code_Caption; FieldCaption("Variant Code"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Comment, Inventory, Description, "Description 2");
                    if Comment then
                        SeeComment := Text001;
                    /* Calculate the Total Value of the Inventory on Hand */
                    TotalValue := 0;
                    ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", "Item No.");
                    ItemLedgerEntry.SetRange(Open, true);
                    Item.CopyFilter("Date Filter", ItemLedgerEntry."Posting Date");
                    Item.CopyFilter("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
                    Item.CopyFilter("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
                    if "Location Code" = '' then
                        Item.CopyFilter("Location Filter", ItemLedgerEntry."Location Code")
                    else
                        ItemLedgerEntry.SetRange("Location Code", "Location Code");
                    if "Variant Code" <> '' then
                        ItemLedgerEntry.SetRange("Variant Code", "Variant Code");
                    if ItemLedgerEntry.Find('-') then
                        repeat
                            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                            if ItemLedgerEntry."Invoiced Quantity" <> ItemLedgerEntry.Quantity then
                                ItemLedgerEntry."Cost Amount (Actual)" := ItemLedgerEntry."Cost Amount (Expected)";
                            TotalValue := TotalValue +
                              ItemLedgerEntry."Remaining Quantity" * ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity;
                        until ItemLedgerEntry.Next() = 0;
                    NewTotalValue := NewTotalValue + TotalValue;

                end;

                trigger OnPreDataItem()
                begin
                    if not MoreInfo or not UseSKU or not Item."Stockkeeping Unit Exists" then
                        CurrReport.Break();
                    Clear(TotalValue);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields(Inventory, Comment, "Substitutes Exist", "Stockkeeping Unit Exists");
                if Comment then
                    SeeComment := Text000
                else
                    SeeComment := '';
                /* Calculate the Total Value of the Inventory on Hand */
                if not UseSKU then begin
                    TotalValue := 0;
                    ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date");
                    ItemLedgerEntry.SetRange("Item No.", "No.");
                    ItemLedgerEntry.SetRange(Open, true);
                    CopyFilter("Date Filter", ItemLedgerEntry."Posting Date");
                    CopyFilter("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
                    CopyFilter("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
                    CopyFilter("Location Filter", ItemLedgerEntry."Location Code");
                    if ItemLedgerEntry.Find('-') then
                        repeat
                            ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
                            if ItemLedgerEntry."Invoiced Quantity" <> ItemLedgerEntry.Quantity then
                                ItemLedgerEntry."Cost Amount (Actual)" := ItemLedgerEntry."Cost Amount (Expected)";
                            TotalValue := TotalValue +
                              ItemLedgerEntry."Remaining Quantity" * ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity;
                        until ItemLedgerEntry.Next() = 0;
                end;
                NewTotalValue := NewTotalValue + TotalValue;

            end;

            trigger OnPreDataItem()
            begin
                Clear(TotalValue);
                NewTotalValue := 0;
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
                    field(MoreInfo; MoreInfo)
                    {
                        Caption = 'Include Additional Info.';
                        ToolTip = 'Specifies if you want to include additional information about every item. This additional information includes a listing of all item variants.';

                        trigger OnValidate()
                        begin
                            SetUpOptions();
                        end;
                    }
                    field(UseSKU; UseSKU)
                    {
                        Caption = 'Use Stockkeeping Unit';
                        Enabled = UseSKUEnable;
                        ToolTip = 'Specifies if you want to only include items that are set up as SKUs. This adds SKU-related fields, such as the Location Code, Variant Code, and Qty. in Transit fields, to the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            UseSKUEnable := true;
        end;

        trigger OnOpenPage()
        begin
            SetUpOptions();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
    end;

    var
        CompanyInformation: Record "Company Information";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemFilter: Text;
        MoreInfo: Boolean;
        TotalValue: Decimal;
        SeeComment: Text[30];
        Text000: Label '(See Comment)';
        UseSKU: Boolean;
        Text001: Label '(See SKU Comment)';
        NewTotalValue: Decimal;
        UseSKUEnable: Boolean;
        Item_ListCaptionLbl: Label 'Item List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_CommentCaptionLbl: Label 'Comment';
        TotalValueCaptionLbl: Label 'Inventory Value ($)';
        Item__Substitutes_Exist_CaptionLbl: Label 'Substitutes Exist';
        Item_BlockedCaptionLbl: Label 'Blocked';
        Item__No___Control49CaptionLbl: Label 'Item No.';
        TotalValue_Control57CaptionLbl: Label 'Inventory Value ($)';
        Alt_CaptionLbl: Label 'Alt:';
        Ven_CaptionLbl: Label 'Ven:';
        Alt_Caption_Control61Lbl: Label 'Alt:';
        Ven_Caption_Control67Lbl: Label 'Ven:';
        Item_Variant_CodeCaptionLbl: Label 'Variant';
        Item_Variant_DescriptionCaptionLbl: Label 'Variant Description';
        Report_TotalCaptionLbl: Label 'Report Total';
        Alt_Caption_Control1480012Lbl: Label 'Alt:';
        Ven_Caption_Control1480020Lbl: Label 'Ven:';

    procedure AnyVariants(): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        ItemVariant.SetRange("Item No.", Item."No.");
        exit(ItemVariant.FindFirst())
    end;

    local procedure SetUpOptions()
    begin
        PageSetUpOptions();
    end;

    local procedure PageSetUpOptions()
    begin
        if not MoreInfo then
            UseSKU := false;
        UseSKUEnable := MoreInfo;
    end;
}

