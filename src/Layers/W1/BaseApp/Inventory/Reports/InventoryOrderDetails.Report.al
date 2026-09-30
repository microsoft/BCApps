// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Document;
using System.Utilities;

report 708 "Inventory Order Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Order Details';
    ToolTip = 'View a list of the orders that have not yet been shipped or received and the items in the orders. It shows the order number, customer''s name, shipment date, order quantity, quantity on back order, outstanding quantity and unit price, as well as possible discount percentage and amount. The quantity on back order and outstanding quantity and amount are totaled for each item. The report can be used to find out whether there are currently shipment problems or any can be expected.';
    DefaultRenderingLayout = Excel;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Bin Filter";
            column(ItemTableCaptItemFilter; ItemFilterText)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(StrSbStNoSalOdrLnSalLnFlt; SalesLineFilterText)
            {
            }
            column(SalesLineFilter; SalesLineFilter)
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
            column(OutstandingAmt_SalesLine; "Sales Line"."Outstanding Amount")
            {
                IncludeCaption = true;
            }
            column(InventoryPostingGroup_Item; "Inventory Posting Group")
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; "Assembly BOM")
            {
                IncludeCaption = true;
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "No." = field("No."), "Variant Code" = field("Variant Filter"), "Location Code" = field("Location Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Bin Code" = field("Bin Filter");
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date") where("Document Type" = const(Order), Type = const(Item), "Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = "Shipment Date";
                RequestFilterHeading = 'Sales Order Line';
                column(SalesLineDocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(SalesHeaderBilltoName; SalesHeader."Bill-to Name")
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
                column(BackOrderQty; BackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SalesLineUnitPrice; "Unit Price")
                {
                    IncludeCaption = true;
                }
                column(SalesLineLineDiscount; "Line Discount %")
                {
                    IncludeCaption = true;
                }
                column(InvDiscountAmt_SalesLine; "Inv. Discount Amount")
                {
                    IncludeCaption = true;
                }
                column(OutstandingAmt1_SalesLine; "Outstanding Amount")
                {
                    IncludeCaption = true;
                }
                column(SalesLineDescription; Description)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SalesHeader.Get("Document Type", "Document No.");
                    if SalesHeader."Currency Factor" <> 0 then
                        "Outstanding Amount" :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              WorkDate(), SalesHeader."Currency Code", "Outstanding Amount",
                              SalesHeader."Currency Factor"));
                    if "Shipment Date" < WorkDate() then
                        BackOrderQty := "Outstanding Quantity"
                    else
                        BackOrderQty := 0;

                    SubtotalsOutstandingQty += "Outstanding Quantity";
                    SubtotalsBackOrderQty += BackOrderQty;
                    SubtotalsOutstandingAmt += "Outstanding Amount";
                    TotalsOutstandingAmt += "Outstanding Amount";

                    if not ReportHasData then
                        ReportHasData := true;
                end;
            }
            dataitem(SubTotals; Integer)
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SubTotals_OutstandingQty; SubtotalsOutstandingQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubTotals_BackOrderQty; SubtotalsBackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubTotals_OutstandingAmt; SubtotalsOutstandingAmt)
                {
                    DecimalPlaces = 2 : 2;
                }

                trigger OnPreDataItem()
                begin
                    if "Sales Line".IsEmpty() then
                        CurrReport.Break();
                end;
            }
            trigger OnAfterGetRecord()
            begin
                SubtotalsOutstandingQty := 0;
                SubtotalsBackOrderQty := 0;
                SubtotalsOutstandingAmt := 0;
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Totals_OutstandingAmt; TotalsOutstandingAmt)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Totals_Number; Number)
            {
            }

            trigger OnPreDataItem()
            begin
                if not ReportHasData then
                    CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory Order Details';
        AboutText = 'Analyse your outstanding sales orders to understand your expected sales volume. Show all outstanding sales and highlight overdue sales lines for each item.';

        layout
        {
        }

        actions
        {
        }
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Inventory Order Details Excel';
            LayoutFile = '.\Inventory\Reports\InventoryOrderDetails.xlsx';
            Type = Excel;
            Summary = 'Report layout primarily made for data analysis. Use an Excel editor to modify the layout.';
        }
        layout(Word)
        {
            Caption = 'Inventory Order Details Word';
            LayoutFile = '.\Inventory\Reports\InventoryOrderDetails.docx';
            Type = Word;
            Summary = 'Report layout made for print. Use a Word editor to modify the layout.';
        }
    }

    labels
    {
        DataRetrieved = 'Data retrieved:';
        InventoryOrderDetails = 'Inventory Order Details';
        InventoryOrderDetailsPrint = 'Inventory Order Details (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        InvOrderDetailsAnalysis = 'Inv. Order Details (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        BackOrderQtyLabel = 'Quantity on Back Order';
        ShipmentDateLabel = 'Shipment Date';
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        SalesLineFilter := "Sales Line".GetFilters();
        if ItemFilter <> '' then
            ItemFilterText := StrSubstNo(ItemFilterCaptLbl, ItemFilter);
        if SalesLineFilter <> '' then
            SalesLineFilterText := StrSubstNo(Text000, SalesLineFilter);
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        BackOrderQty: Decimal;
        ItemFilter: Text;
        ItemFilterText: Text;
        SalesLineFilter: Text;
        SalesLineFilterText: Text;
        SubtotalsOutstandingQty: Decimal;
        SubtotalsBackOrderQty: Decimal;
        SubtotalsOutstandingAmt: Decimal;
        TotalsOutstandingAmt: Decimal;
        ReportHasData: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales Order Line: %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemFilterCaptLbl: Label 'Item: %1', Comment = '%1 - item filter';
    protected var
        SalesHeader: Record "Sales Header";
}

