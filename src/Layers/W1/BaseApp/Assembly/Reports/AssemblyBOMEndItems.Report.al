// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

report 812 "Assembly BOM - End Items"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/Reports/AssemblyBOMEndItems.rdlc';
    AdditionalSearchTerms = 'kit bill of material end items';
    ApplicationArea = Assembly;
    Caption = 'Assembly BOM - End Items';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Base Unit of Measure", "Shelf No.", "Assembly BOM";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(Inventory_Item; Inventory)
            {
                IncludeCaption = true;
            }
            column(UnitCost_Item; "Unit Cost")
            {
                IncludeCaption = true;
            }
            column(ReorderPoint_Item; "Reorder Point")
            {
                IncludeCaption = true;
            }
            column(BOMFinishedGoodsCaption; BOMFinishedGoodsCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                BOMComp.Reset();
                BOMComp.SetCurrentKey(Type, "No.");
                BOMComp.SetRange(Type, BOMComp.Type::Item);
                BOMComp.SetRange("No.", "No.");
                if BOMComp.FindFirst() then // Part of a BOM
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Assembly BOM - End Items';
        AboutText = 'Get a list of items or bill of materials (BOMs) that aren''t components in other BOMs.';

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
        ItemFilter := Item.GetFilters();
    end;

    var
        BOMComp: Record "BOM Component";
        ItemFilter: Text;
        BOMFinishedGoodsCaptionLbl: Label 'BOM - Finished Goods';
        PageCaptionLbl: Label 'Page';
}

