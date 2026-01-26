// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

report 12137 "LIFO Valuation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Costing/LIFOValuation.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'LIFO Valuation';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Lifo Band"; "Lifo Band")
        {
            DataItemTableView = sorting("Item No.", "Competence Year");
            RequestFilterFields = "Competence Year";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CompetenceYearFormat_LifoBand; Format("Competence Year"))
            {
            }
            column(IncrementQty_LifoBand; "Increment Quantity")
            {
            }
            column(AbsorbedQty_LifoBand; "Absorbed Quantity")
            {
            }
            column(ResidualQty_LifoBand; "Residual Quantity")
            {
            }
            column(YearAverageCost_LifoBand; "Year Average Cost")
            {
            }
            column(LIFOCategory; LIFOCategory)
            {
            }
            column(ItemNo; ItemNo)
            {
            }
            column(Value; Value)
            {
            }
            column(UOM; UOM)
            {
            }
            column(PrintItem; PrintItem)
            {
            }
            column(OldItem; OldItem)
            {
            }
            column(EntryNo_LifoBand; "Entry No.")
            {
            }
            column(ItemNo_LifoBand; "Item No.")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ItemFiscalLIFOReportCaption; ItemFiscalLIFORepCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(LIFOCategoryCaption; LIFOCategoryCaptionLbl)
            {
            }
            column(CompetenceYearCaption; CompetenceYearCaptionLbl)
            {
            }
            column(IncrementQtyCaption_LifoBand; FieldCaption("Increment Quantity"))
            {
            }
            column(AbsorbedQtyCaption_LifoBand; FieldCaption("Absorbed Quantity"))
            {
            }
            column(ResidualQtyCaption_LifoBand; FieldCaption("Residual Quantity"))
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            column(UMCaption; UMCaptionLbl)
            {
            }
            column(ValueCaption; ValueCaptionLbl)
            {
            }
            column(TotalsCaption; TotalsCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                ItemNo := '';
                LIFOCategory := '';
                UOM := '';
                PrintItem := false;
                Item.Get("Item No.");
                Value := "Residual Quantity" * "Year Average Cost";
                if OldItem <> "Item No." then begin
                    PrintItem := true;
                    OldItem := "Item No.";
                end;
                if PrintItem then begin
                    ItemNo := "Item No.";
                    LIFOCategory := "Lifo Category";
                    UOM := Item."Base Unit of Measure";
                end;
            end;
        }
        dataitem("LIFO Category2"; "Lifo Band")
        {
            DataItemTableView = sorting("Lifo Category", "Item No.", "Competence Year");
            column(LifoCategory_LIFOCategory2; "Lifo Category")
            {
            }
            column(IncrementQty_LIFOCategory2; "Increment Quantity")
            {
            }
            column(AbsorbedQty_LIFOCategory2; "Absorbed Quantity")
            {
            }
            column(ResidualQty_LIFOCategory2; "Residual Quantity")
            {
            }
            column(LIFOCategDescription; LIFOCateg.Description)
            {
            }
            column(CategValue; CategValue)
            {
            }
            column(NotDefMsg; NotDefMsg)
            {
            }
            column(EntryNo_LIFOCategory2; "Entry No.")
            {
            }
            column(LifoCategoryCaption_LIFOCategory2; FieldCaption("Lifo Category"))
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(LIFOUOMCaption; LIFOUOMCaptionLbl)
            {
            }
            column(IncrementQtyCaption_LIFOCategory2; FieldCaption("Increment Quantity"))
            {
            }
            column(AbsorbedQtyCaption_LIFOCategory2; FieldCaption("Absorbed Quantity"))
            {
            }
            column(ResidualQtyCaption_LIFOCategory2; FieldCaption("Residual Quantity"))
            {
            }
            column(CategoryTotalsCaption; CategoryTotalsCaptionLbl)
            {
            }
            column(GeneralTotalCaption; GeneralTotalCaptionLbl)
            {
            }
            column(ValueCaptionLIFOCategory2; ValueCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                CategValue := "Residual Quantity" * "Year Average Cost";
                if LIFOCateg.Get("Lifo Category") then;
            end;

            trigger OnPreDataItem()
            begin
                CopyFilters("Lifo Band");
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
    var
        LIFOBand: Record "Lifo Band";
    begin
        LIFOBand.CopyFilters("Lifo Band");
        LIFOBand.SetRange(Definitive, false);
        if LIFOBand.FindFirst() then
            NotDefMsg := Text12100;
        OldItem := '';
    end;

    var
        LIFOCateg: Record "Lifo Category";
        NotDefMsg: Text[100];
        ItemNo: Code[20];
        LIFOCategory: Code[20];
        UOM: Code[20];
        PrintItem: Boolean;
        Value: Decimal;
        CategValue: Decimal;
        Text12100: Label 'Warning: Not all LIFO Bands are final, the current report is a draft.';
        OldItem: Code[20];
        PageCaptionLbl: Label 'Page';
        ItemFiscalLIFORepCaptionLbl: Label 'Item Fiscal LIFO Report';
        ItemNoCaptionLbl: Label 'Item No.';
        LIFOCategoryCaptionLbl: Label 'LIFO Category';
        CompetenceYearCaptionLbl: Label 'Competence Year';
        UnitCostCaptionLbl: Label 'Unit Cost';
        UMCaptionLbl: Label 'U.M.';
        ValueCaptionLbl: Label 'Value';
        TotalsCaptionLbl: Label 'Totals';
        DescriptionCaptionLbl: Label 'Description';
        LIFOUOMCaptionLbl: Label 'LIFO Unit of Measure';
        CategoryTotalsCaptionLbl: Label 'Category Totals';
        GeneralTotalCaptionLbl: Label 'General Total';
}

