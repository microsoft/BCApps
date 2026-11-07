// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

report 809 "Where-Used List"
{
    ApplicationArea = Assembly;
    Caption = 'Where-Used List';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description";
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
            }
            column(Description_Item; Description)
            {
            }
            column(WhereUsedListCaption; WhereUsedListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            dataitem("BOM Component"; "BOM Component")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting(Type, "No.") where(Type = const(Item));
                dataitem(Item2; Item)
                {
                    DataItemLink = "No." = field("Parent Item No.");
                    DataItemTableView = sorting("No.");
                    column(Position_BOMComponent; "BOM Component".Position)
                    {
                        IncludeCaption = true;
                    }
                    column(ParentItemNo_BOMComponent; "BOM Component"."Parent Item No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_Item2; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(Quantityper_BOMComponent; "BOM Component"."Quantity per")
                    {
                        DecimalPlaces = 0 : 5;
                        IncludeCaption = true;
                    }
                    column(BaseUnitofMeasure_Item2; "Base Unit of Measure")
                    {
                        IncludeCaption = true;
                    }
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Where-Used List';
        AboutText = 'Get a list of the bill of materials that the selected items are components of. Use the report when you must change a component in a BOM. For example, if your vendor can''t deliver an item that you use for assembly or production.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Inventory/Reports/WhereUsedList.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
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
        ItemFilter: Text;
        WhereUsedListCaptionLbl: Label 'Where-Used List';
        PageCaptionLbl: Label 'Page';
}

