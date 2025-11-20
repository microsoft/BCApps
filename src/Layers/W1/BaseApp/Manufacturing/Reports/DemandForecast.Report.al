#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Sales.Document;
using System.Utilities;

report 99003804 "Demand Forecast"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/DemandForecast.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Demand Forecast (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been deprecated and will be removed in a future release.';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem("Production Forecast Entry"; "Production Forecast Entry")
        {
            DataItemTableView = sorting("Production Forecast Name", "Item No.", "Variant Code", "Location Code", "Forecast Date", "Component Forecast");
            RequestFilterFields = "Production Forecast Name", "Item No.", "Forecast Date";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ForecastEntryTblCaptFilt; TableCaption + ': ' + ForecastFilter)
            {
            }
            column(ForecastFilter; ForecastFilter)
            {
            }
            column(ItemNo_ForecastEntry; "Item No.")
            {
                IncludeCaption = true;
            }
            column(VariantCode_ForecastEntry; "Variant Code")
            {
                IncludeCaption = true;
            }
            column(ForecastDt_ForecastEntry; Format("Forecast Date"))
            {
            }
            column(ForecastQty_ForecastEntry; "Forecast Quantity")
            {
            }
            column(LocationCode_ForecastEntry; "Location Code")
            {
                IncludeCaption = true;
            }
            column(Desc_ForecastEntry; Description)
            {
                IncludeCaption = true;
            }
            column(EntryNo_ForecastEntry; "Entry No.")
            {
            }
            column(ProductionForecastCaption; ProductionForecastCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(SalesOrdShipmentDateCapt; SalesOrdShipmentDateCaptLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            column(TypeCaption; TypeCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(ForecastCaption; ForecastCaptionLbl)
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemTableView = sorting("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
                column(DocNo_SalesLine; "Document No.")
                {
                }
                column(Qty_SalesLine; Quantity)
                {
                }
                column(ShipmentDate_SalesLine; Format("Shipment Date"))
                {
                }
                column(Desc_SalesLine; Description)
                {
                }
                column(No_SalesLine; "No.")
                {
                }
                column(SalesOrderCaption; SalesOrderCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Total := Total - Quantity;
                end;

                trigger OnPreDataItem()
                begin
                    if not (ProdForecastEntry.Next() = 0) then
                        SetRange("Shipment Date",
                          "Production Forecast Entry"."Forecast Date",
                          ProdForecastEntry."Forecast Date" - 1)
                    else
                        SetFilter("Shipment Date", '%1..', "Production Forecast Entry"."Forecast Date");
                    SetRange(Type, Type::Item);
                    SetRange("No.", "Production Forecast Entry"."Item No.");
                    SetRange("Document Type", "Document Type"::Order);
                    if InventorySetup."Use Forecast on Locations" then
                        SetRange("Location Code", "Production Forecast Entry"."Location Code");
                    if InventorySetup."Use Forecast on Variants" then
                        SetRange("Variant Code", "Production Forecast Entry"."Variant Code");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(Total; Total)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TotalCaption; TotalCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                ProdForecastEntry.Copy("Production Forecast Entry");
                ProdForecastEntry.SetRange("Production Forecast Name", "Production Forecast Name");
                ProdForecastEntry.SetRange("Item No.", "Item No.");
                ProdForecastEntry.SetRange("Forecast Date", "Forecast Date");
                if InventorySetup."Use Forecast on Locations" then
                    ProdForecastEntry.SetRange("Location Code", "Location Code");
                if InventorySetup."Use Forecast on Variants" then
                    ProdForecastEntry.SetRange("Variant Code", "Variant Code");
                Total := 0;
                repeat
                    Total += ProdForecastEntry."Forecast Quantity";
                until ProdForecastEntry.Next() = 0;
                ProdForecastEntry.SetRange("Forecast Date");

                Copy(ProdForecastEntry);
                CopyFilters(ProdForecastEntry2);
                "Forecast Quantity" := Total;
            end;

            trigger OnPreDataItem()
            begin
                ProdForecastEntry2.Copy("Production Forecast Entry");
                InventorySetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Demand Forecast (Obsolete)';
        AboutText = 'Helps you plan future production needs by predicting the demand for items based on historical data and other factors. Use the report to help ensure that production schedules align with anticipated sales and inventory requirements.** This report is obsolete and will be removed in a future release.** Please refer to the report documentation for alternative ways to retrieve this information.';
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
        ForecastFilter := "Production Forecast Entry".GetFilters();
    end;

    var
        ProdForecastEntry: Record "Production Forecast Entry";
        ProdForecastEntry2: Record "Production Forecast Entry";
        InventorySetup: Record "Inventory Setup";
        Total: Decimal;
        ForecastFilter: Text;
        ProductionForecastCaptionLbl: Label 'Demand Forecast';
        CurrReportPageNoCaptionLbl: Label 'Page';
        SalesOrdShipmentDateCaptLbl: Label 'Date';
        QuantityCaptionLbl: Label 'Quantity';
        TypeCaptionLbl: Label 'Type';
        NoCaptionLbl: Label 'No.';
        ForecastCaptionLbl: Label 'Forecast';
        SalesOrderCaptionLbl: Label 'Sales Order';
        TotalCaptionLbl: Label 'Total';
}

#endif