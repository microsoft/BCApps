// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Utilities;

report 718 "Inventory - Sales Back Orders"
{
    AdditionalSearchTerms = 'delayed order,unfulfilled demand';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Sales Back Orders';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Bin Filter";
#if not CLEAN27
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(ItemTableCaptItemFilter; TableCaption + ': ' + ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(StrSubStNoSalesLineFltr; StrSubstNo(Text000, SalesLineFilter))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemFilterTxt; ItemFilterTxt)
            {
            }
            column(SalesLineFilter; SalesLineFilter)
            {
            }
            column(SalesLineFilterTxt; SalesLineFilterTxt)
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
#if not CLEAN27
            column(VariantFilter_Item; "Variant Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(LocationFilter_Item; "Location Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(BinFilter_Item; "Bin Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(GlobalDim1Filter_Item; "Global Dimension 1 Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(GlobalDim2Filter_Item; "Global Dimension 2 Filter")
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(InvSalesBackOrdersCaption; InvSalesBackOrdersCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustNameCaption; CustNameCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustPhoneNoCaption; CustPhoneNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(SalesLineShipDateCaption; SalesLineShipDateCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(OtherBackOrdersCaption; OtherBackOrdersCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Bin Code" = field("Bin Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where(Type = const(Item), "Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(DocumentNo_SalesLine; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(CustName_SalesLine; Cust.Name)
                {
                    IncludeCaption = true;
                }
                column(CustPhoneNo_SalesLine; Cust."Phone No.")
                {
                    IncludeCaption = true;
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Quantity_SalesLine; Quantity)
                {
                    IncludeCaption = true;
                }
                column(OutstandingQty_SalesLine; "Outstanding Quantity")
                {
                    IncludeCaption = true;
                }
                column(OtherBackOrders_SalesLine; OtherBackOrdersText)
                {
                }
                trigger OnAfterGetRecord()
                begin
                    if "Shipment Date" >= WorkDate() then
                        CurrReport.Skip();
                    Cust.Get("Bill-to Customer No.");

                    SalesOrderLine.SetRange("Bill-to Customer No.", Cust."No.");
                    SalesOrderLine.SetFilter("No.", '<>' + Item."No.");
                    OtherBackOrdersText := SalesOrderLine.FindFirst() ? 'Yes' : 'No';
                    SubtotalsOutstandingQty += "Sales Line"."Outstanding Quantity";
                end;

                trigger OnPreDataItem()
                begin
                    SalesOrderLine.SetCurrentKey("Document Type", "Bill-to Customer No.");
                    SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
                    SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);
                    SalesOrderLine.SetRange("Shipment Date", 0D, WorkDate() - 1);
                    SalesOrderLine.SetFilter("Outstanding Quantity", '<>0');
                end;
            }
            dataitem(SubTotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SubTotals_Outstanding_Qty; SubtotalsOutstandingQty)
                {
                    DecimalPlaces = 0 : 5;
                }

                trigger OnPreDataItem()
                begin
                    "Sales Line".SetFilter("Shipment Date", '<%1', WorkDate());
                    if "Sales Line".IsEmpty() then
                        CurrReport.Break()
                end;
            }
            trigger OnAfterGetRecord()
            begin
                SubtotalsOutstandingQty := 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Sales Back Orders';
        AboutText = 'See an overview of sales orders that can''''t be fulfilled due to out-of-stock items. This report highlights sales lines that are overdue to be shipped and includes information on the document & customer the order is linked to.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Visible = false;
                    Caption = 'Options';
                    field(ShipmentDateFilter; ShipmentDateFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Shipment Date Filter';
                    }
                }
            }
        }

        actions
        {
        }
        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            ShipmentDateFilter := "Sales Line".GetFilter("Shipment Date");
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory - Sales Back Orders Excel';
            LayoutFile = '.\Inventory\Reports\InventorySalesBackOrders.xlsx';
            Type = Excel;
            Summary = 'Built in layout for the Inventory - Sales Back Orders report.';
        }
        layout(Word)
        {
            Caption = 'Inventory - Sales Back Orders Word';
            LayoutFile = '.\Inventory\Reports\InventorySalesBackOrders.docx';
            Type = Word;
            Summary = 'Built in layout for the Inventory - Sales Back Orders word report.';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Inventory - Sales Back Orders RDLC';
            Type = RDLC;
            LayoutFile = '.\Inventory\Reports\InventorySalesBackOrders.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }

    labels
    {
        DataRetrieved = 'Data retrieved:';
        InventorySalesBackOrders = 'Inventory - Sales Back Orders';
        InventorySalesBackOrdersPrint = 'Inv. - S. Back Orders (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvSalesBackOrdersAnalysis = 'Inv. - S. Back Order (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        ShipmentDateLabel = 'Shipment Date';
        OtherBackOrdersLabel = 'Other Back Orders';
        // Word layout field captions. To be replaced with the IncludeCaption property in a future release along with RDLC layout removal.
        ItemNoCaptionLbl = 'Item No.';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
        if ItemFilter <> '' then
            ItemFilterTxt := Item.TableCaption + ': ' + ItemFilter;
        if SalesLineFilter <> '' then
            SalesLineFilterTxt := StrSubstNo(Text000, SalesLineFilter);
    end;

    var
        Cust: Record Customer;
        SalesOrderLine: Record "Sales Line";
        OtherBackOrdersText: Text;
        ItemFilter: Text;
        ItemFilterTxt: Text;
        SalesLineFilter: Text;
        SalesLineFilterTxt: Text;
        ShipmentDateFilter: Text;
        SubtotalsOutstandingQty: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
#if not CLEAN27
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        InvSalesBackOrdersCaptionLbl: Label 'Inventory - Sales Back Orders';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CurrReportPageNoCaptionLbl: Label 'Page';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CustNameCaptionLbl: Label 'Customer';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CustPhoneNoCaptionLbl: Label 'Phone No.';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        SalesLineShipDateCaptionLbl: Label 'Shipment Date';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        OtherBackOrdersCaptionLbl: Label 'Other Back Orders';
#endif
}

