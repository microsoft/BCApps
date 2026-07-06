// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Reports;

using Microsoft.Inventory.Item;

report 810 "Assembly BOM - Raw Materials"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/Reports/AssemblyBOMRawMaterials.rdlc';
    AdditionalSearchTerms = 'bill of material raw';
    ApplicationArea = Assembly;
    Caption = 'BOM - Raw Materials';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where("Assembly BOM" = const(false));
            RequestFilterFields = "No.", "Base Unit of Measure", "Shelf No.";
            column(CompanyName_Item; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaptionItemFilter; TableCaption + ': ' + ItemFilter)
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
            column(VendorNo_Item; "Vendor No.")
            {
                IncludeCaption = true;
            }
            column(LeadTimeCalculation_Item; "Lead Time Calculation")
            {
                IncludeCaption = true;
            }
            column(BOMRawMaterialsCaption; BOMRawMaterialsCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About BOM - Raw Materials';
        AboutText = 'Get an overview of the components in an item''s bill of materials, for both assembly and production.';

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
        BOMRawMaterialsCaptionLbl: Label 'BOM - Raw Materials';
        CurrReportPageNoCaptionLbl: Label 'Page';
}

