// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 5700 "Catalog Item Sales"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/CatalogItemSales.rdlc';
    AdditionalSearchTerms = 'non-inventoriable sale,special sales order';
    ApplicationArea = Basic, Suite;
    Caption = 'Catalog Item Sales';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Ledger Entry"; "Item Ledger Entry")
        {
            DataItemTableView = sorting("Item No.", "Entry Type");
            RequestFilterFields = "Item No.", "Location Code", "Posting Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CaptionLedgFilter; TableCaption + ': ' + ItemLedgerFilter)
            {
            }
            column(ItemLedgerFilter; ItemLedgerFilter)
            {
            }
            column(ValueEntryInvoicedQty; -"Value Entry"."Invoiced Quantity")
            {
                DecimalPlaces = 0 : 5;
            }
            column(SalesAmtAct_ValueEntry; "Value Entry"."Sales Amount (Actual)")
            {
            }
            column(ItemDescription; Item.Description)
            {
            }
            column(ItemLedgerEntryItemNo; "Item No.")
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(NonstockItemSalesCaption; NonstockItemSalesCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(ValueEntryDocDateCaption; ValueEntryDocDateCaptionLbl)
            {
            }
            column(ValueEntryPostingDateCaption; ValueEntryPostingDateCaptionLbl)
            {
            }
            column(TotalSalesCaption; TotalSalesCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Item Ledger Entry No." = field("Entry No.");
                DataItemTableView = sorting("Item Ledger Entry No.");
                column(ValueEntryDocumentNo; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(ValueEntryDocDate; Format("Document Date"))
                {
                }
                column(ValueEntryPostingDate; Format("Posting Date"))
                {
                }
                column(LocCode_ValueEntry; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(ItemLedrEntryPurCode; "Item Ledger Entry"."Purchasing Code")
                {
                    IncludeCaption = true;
                }
                column(DropShip_ValueEntry; "Drop Shipment")
                {
                    IncludeCaption = true;
                }
                column(InvoicedQuantity; -"Invoiced Quantity")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ValueEntryItemNo; "Item No.")
                {
                }
                column(FormatDropShipment; Format("Drop Shipment"))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Expected Cost" then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Entry Type" <> "Entry Type"::Sale then begin
                    SetRange("Item No.", "Item No.");
                    SetRange("Entry Type", "Entry Type");
                    Find('+');
                    SetRange("Item No.");
                    SetRange("Entry Type");
                end;

                if not Nonstock then
                    CurrReport.Skip();

                if not Item.Get("Item No.") then
                    Item.Description := '';
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
    begin
        ItemLedgerFilter := "Item Ledger Entry".GetFilters();
    end;

    var
        Item: Record Item;
        ItemLedgerFilter: Text;
        CurrReportPageNoCaptionLbl: Label 'Page';
        NonstockItemSalesCaptionLbl: Label 'Catalog Item - Sales';
        ItemNoCaptionLbl: Label 'Item No.';
        QuantityCaptionLbl: Label 'Quantity';
        AmountCaptionLbl: Label 'Amount';
        ValueEntryDocDateCaptionLbl: Label 'Document Date';
        ValueEntryPostingDateCaptionLbl: Label 'Posting Date';
        TotalSalesCaptionLbl: Label 'Total Sales';
}

