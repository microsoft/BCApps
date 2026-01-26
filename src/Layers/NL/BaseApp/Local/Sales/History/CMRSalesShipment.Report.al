// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 11401 "CMR - Sales Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/History/CMRSalesShipment.rdlc';
    Caption = 'CMR - Sales Shipment';
    ApplicationArea = Warehouse;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Sales Shipment Header"; "Sales Shipment Header")
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(Sales_Shipment_Header_No_; "No.")
            {
            }
            dataitem("Sales Shipment Line"; "Sales Shipment Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.") where(Type = const(Item));
                column(SenderAddr_1_; SenderAddr[1])
                {
                }
                column(SenderAddr_2_; SenderAddr[2])
                {
                }
                column(SenderAddr_3_; SenderAddr[3])
                {
                }
                column(SenderAddr_4_; SenderAddr[4])
                {
                }
                column(SenderAddr_5_; SenderAddr[5])
                {
                }
                column(ShipToAddr_5_; ShipToAddr[5])
                {
                }
                column(ShipToAddr_4_; ShipToAddr[4])
                {
                }
                column(ShipToAddr_3_; ShipToAddr[3])
                {
                }
                column(ShipToAddr_2_; ShipToAddr[2])
                {
                }
                column(ShipToAddr_1_; ShipToAddr[1])
                {
                }
                column(ShipTo; ShipTo)
                {
                }
                column(ShipFrom; ShipFrom)
                {
                }
                column(Sales_Shipment_Header___Shipment_Date_; Format("Sales Shipment Header"."Shipment Date"))
                {
                }
                column(ShippingAgent_Name; ShippingAgent.Name)
                {
                }
                column(Sales_Shipment_Line__No__; "No.")
                {
                }
                column(Sales_Shipment_Line__Units_per_Parcel_; "Units per Parcel")
                {
                }
                column(Sales_Shipment_Line__Unit_of_Measure_; "Unit of Measure")
                {
                }
                column(Sales_Shipment_Line_Description; Description)
                {
                }
                column(Item__Tariff_No__; Item."Tariff No.")
                {
                }
                column(Sales_Shipment_Line__Gross_Weight_; "Gross Weight")
                {
                }
                column(Sales_Shipment_Line__Unit_Volume_; "Unit Volume")
                {
                }
                column(SenderAddr_5__Control1000023; SenderAddr[5])
                {
                }
                column(SenderAddr_4__Control1000024; SenderAddr[4])
                {
                }
                column(SenderAddr_3__Control1000025; SenderAddr[3])
                {
                }
                column(SenderAddr_2__Control1000026; SenderAddr[2])
                {
                }
                column(SenderAddr_1__Control1000027; SenderAddr[1])
                {
                }
                column(EstdIn; EstdIn)
                {
                }
                column(WORKDATE; Format(WorkDate()))
                {
                }
                column(Sales_Shipment_Line_Document_No_; "Document No.")
                {
                }
                column(Sales_Shipment_Line_Line_No_; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Units per Parcel" <> 0 then begin
                        "Units per Parcel" := Round(Quantity / "Units per Parcel", 1, '>');
                        "Unit of Measure" := ParcelTxt;
                    end else
                        "Units per Parcel" := Quantity;

                    Item.Get("No.");

                    "Gross Weight" := Quantity * "Gross Weight";
                    "Unit Volume" := Quantity * "Unit Volume";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SalesShipmentLine.Reset();
                SalesShipmentLine.SetRange("Document No.", "No.");
                SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
                if not SalesShipmentLine.FindFirst() then
                    CurrReport.Skip();

                if "Location Code" <> '' then begin
                    Location.Get("Location Code");
                    FormatAddr.FormatAddr(
                      SenderAddr, Location.Name, Location."Name 2", '', Location.Address, Location."Address 2",
                      Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
                    if not Country.Get(Location."Country/Region Code") then
                        Country.Init();
                    ShipFrom := DelChr(AddText(Location.City) + AddText(Country.Name), '>', ', ');
                    EstdIn := Location.City;
                end else begin
                    CompanyInfo.Get();
                    FormatAddr.FormatAddr(
                      SenderAddr, CompanyInfo.Name, CompanyInfo."Name 2", '', CompanyInfo.Address, CompanyInfo."Address 2",
                      CompanyInfo.City, CompanyInfo."Post Code", CompanyInfo.County, CompanyInfo."Country/Region Code");
                    if not Country.Get(CompanyInfo."Country/Region Code") then
                        Country.Init();
                    ShipFrom := DelChr(AddText(CompanyInfo.City) + AddText(Country.Name), '>', ', ');
                    EstdIn := CompanyInfo.City;
                end;

                FormatAddr.FormatAddr(
                  ShipToAddr, "Ship-to Name", "Ship-to Name 2", '', "Ship-to Address", "Ship-to Address 2",
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");

                if not ShippingAgent.Get("Shipping Agent Code") then
                    ShippingAgent.Init();

                if not Country.Get("Ship-to Country/Region Code") then
                    Country.Init();

                ShipTo := DelChr(AddText("Ship-to City") + AddText(Country.Name), '>', ', ');
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

    var
        Item: Record Item;
        SalesShipmentLine: Record "Sales Shipment Line";
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        ShippingAgent: Record "Shipping Agent";
        Country: Record "Country/Region";
        FormatAddr: Codeunit "Format Address";
        SenderAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        ShipTo: Text[80];
        ShipFrom: Text[80];
        EstdIn: Text[50];
        ParcelTxt: Label 'parcel(s)';

    [Scope('OnPrem')]
    procedure AddText(Text: Text[249]): Text[250]
    begin
        if Text <> '' then
            exit(Text + ', ');
    end;
}

