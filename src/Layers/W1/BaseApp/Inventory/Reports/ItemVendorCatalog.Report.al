// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;

report 720 "Item/Vendor Catalog"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item/Vendor Catalog';
    DefaultRenderingLayout = Excel;
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(Item_TABLECAPTION__________ItemFilter; ItemFilterHeading)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
                IncludeCaption = true;
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
#if not CLEAN28
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item_Vendor_CatalogCaption; Item_Vendor_CatalogCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Purchase_Price__Vendor_No__Caption; ItemVend.FieldCaption("Vendor No."))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Purchase_Price__Starting_Date_Caption; Purchase_Price__Starting_Date_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Purchase_Price__Direct_Unit_Cost_Caption; Direct_Unit_Cost_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemVend__Lead_Time_Calculation_Caption; ItemVend__Lead_Time_Calculation_CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemVend__Vendor_Item_No__Caption; ItemVend__Vendor_Item_No__CaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
            column(ExtendedPriceFeatureEnabled; ExtendedPriceEnabled)
            {
            }
            dataitem("Purchase Price"; "Purchase Price")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.");
                column(Purchase_Price__Vendor_No__; "Vendor No.")
                {
                    IncludeCaption = true;
                }
                column(Vend_Name; Vend.Name)
                {
                    IncludeCaption = true;
                }
                column(Purchase_Price__Starting_Date_; Format("Starting Date"))
                {
                }
                column(Purchase_Price__Direct_Unit_Cost_; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(Purchase_Price__Currency_Code_; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(ItemVend__Lead_Time_Calculation_; ItemVend."Lead Time Calculation")
                {
                }
                column(ItemVend__Vendor_Item_No__; ItemVend."Vendor Item No.")
                {
                }

                trigger OnPreDataItem()
                begin
                    if ExtendedPriceEnabled then
                        CurrReport.Break();
                end;

                trigger OnAfterGetRecord()
                begin
                    InitGlobals("Vendor No.", "Item No.", "Variant Code");
                end;
            }
            dataitem(PriceListLine; "Price List Line")
            {
                DataItemLink = "Asset No." = field("No.");
                DataItemTableView = sorting("Asset No.") where("Source Type" = const(Vendor), "Asset Type" = const(Item), Status = const(Active));
                column(Price_Vendor_No; "Source No.")
                {
                }
                column(Price_Vend_Name; Vend.Name)
                {
                }
                column(Price_Starting_Date; Format("Starting Date"))
                {
                }
                column(Price_Direct_Unit_Cost; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                }
                column(Price_Currency_Code_; "Currency Code")
                {
                }
                column(ItemVend_Lead_Time_Calculation; ItemVend."Lead Time Calculation")
                {
                }
                column(ItemVend_Vendor_Item_No; ItemVend."Vendor Item No.")
                {
                }

                trigger OnPreDataItem()
                begin
                    if not ExtendedPriceEnabled then
                        CurrReport.Break();
                end;

                trigger OnAfterGetRecord()
                begin
                    InitGlobals("Source No.", "Asset No.", "Variant Code");
                end;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Item/Vendor Catalog';
        AboutText = 'Shows a catalog of items with vendor-specific information, including vendor numbers, item references, and prices. Use this report to review or share vendor catalogs, compare vendor offerings, and support purchasing decisions.';
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    // Used to set a report header across multiple languages
                    field(RequestItemFilterHeading; ItemFilterHeading)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Filter';
                        ToolTip = 'Specifies the Item Filters applied to this report.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnClosePage()
        begin
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Item/Vendor Catalog Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/ItemVendorCatalog.xlsx';
            Summary = 'Built in layout for the Item/Vendor Catalog Excel report.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Item/Vendor Catalog RDLC (Obsolete)';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/ItemVendorCatalog.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by an Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Built in layout for the Item/Vendor Catalog RDLC (Obsolete) report.';
        }
#endif
    }

    labels
    {
        ItemVendorCatalogLbl = 'Item/Vendor Catalog';
        ItemVendorCatalogPrintLbl = 'Item Vendor Catalog (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemVendorCatalogAnalysisLbl = 'Item Vendor Catalog (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        ItemNoLbl = 'Item No.';
        DateLbl = 'Date';
        ItemVendorNoLbl = 'Item Vendor No.';
        LeadTimeCalculationLbl = 'Lead Time Calculation';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
    }

    trigger OnPreReport()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        UpdateRequestPageFilterValues();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ItemVend: Record "Item Vendor";
        Vend: Record Vendor;
        ItemFilter: Text;
        ItemFilterHeading: Text;
        ExtendedPriceEnabled: Boolean;
#if not CLEAN28
        Item_Vendor_CatalogCaptionLbl: Label 'Item/Vendor Catalog';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vend_NameCaptionLbl: Label 'Name';
        Purchase_Price__Starting_Date_CaptionLbl: Label 'Date';
        ItemVend__Lead_Time_Calculation_CaptionLbl: Label 'Lead Time Calculation';
        ItemVend__Vendor_Item_No__CaptionLbl: Label 'Item Vendor No.';
        Direct_Unit_Cost_CaptionLbl: Label 'Direct Unit Cost';
#endif

    local procedure InitGlobals(VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if VendorNo <> Vend."No." then
            Vend.Get(VendorNo);

        if not ItemVend.Get(VendorNo, ItemNo, VariantCode) then
            ItemVend.Init();
    end;

    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        ItemFilter := Item.GetFilters();

        if ItemFilter <> '' then
            ItemFilterHeading := Item.TableCaption + ': ' + ItemFilter;
    end;
}

