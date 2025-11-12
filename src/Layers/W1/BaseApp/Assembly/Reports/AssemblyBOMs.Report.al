// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

report 801 "Assembly BOMs"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/Reports/AssemblyBOMs.rdlc';
    AdditionalSearchTerms = 'bill of material';
    ApplicationArea = Assembly;
    Caption = 'BOMs';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptionItemFilter; TableCaption + ': ' + ItemFilter)
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
            column(BOMsCaption; BOMsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(BOMCompAssemblyBOMCaption; BOMCompAssemblyBOMCaptionLbl)
            {
            }
            dataitem("BOM Component"; "BOM Component")
            {
                CalcFields = "Assembly BOM";
                DataItemLink = "Parent Item No." = field("No.");
                DataItemTableView = sorting("Parent Item No.", "Line No.");
                column(Position_BOMComp; Position)
                {
                    IncludeCaption = true;
                }
                column(Type_BOMComp; Type)
                {
                    IncludeCaption = true;
                }
                column(No_BOMComp; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_BOMComp; Description)
                {
                    IncludeCaption = true;
                }
                column(AssemblyBOM_BOMComp; Format("Assembly BOM"))
                {
                }
                column(Quantityper_BOMComp; "Quantity per")
                {
                    IncludeCaption = true;
                }
                column(UnitofMeasureCode_BOMComp; "Unit of Measure Code")
                {
                    IncludeCaption = true;
                }
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About BOMs';
        AboutText = 'Get an overview of assembly bills of materials (BOMs), including BOMs that are part of the main BOM.';

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
        ItemFilter: Text;
        BOMsCaptionLbl: Label 'BOMs';
        CurrReportPageNoCaptionLbl: Label 'Page';
        BOMCompAssemblyBOMCaptionLbl: Label 'BOM';
}

