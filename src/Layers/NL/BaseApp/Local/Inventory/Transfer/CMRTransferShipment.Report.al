// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;

report 11402 "CMR - Transfer Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Transfer/CMRTransferShipment.rdlc';
    Caption = 'CMR - Transfer Shipment';
    ApplicationArea = Warehouse;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(Transfer_Shipment_Header_No_; "No.")
            {
            }
            dataitem("Transfer Shipment Line"; "Transfer Shipment Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");
                column(FromAddr_1_; FromAddr[1])
                {
                }
                column(FromAddr_2_; FromAddr[2])
                {
                }
                column(FromAddr_3_; FromAddr[3])
                {
                }
                column(FromAddr_4_; FromAddr[4])
                {
                }
                column(FromAddr_5_; FromAddr[5])
                {
                }
                column(ToAddr_5_; ToAddr[5])
                {
                }
                column(ToAddr_4_; ToAddr[4])
                {
                }
                column(ToAddr_3_; ToAddr[3])
                {
                }
                column(ToAddr_2_; ToAddr[2])
                {
                }
                column(ToAddr_1_; ToAddr[1])
                {
                }
                column(TransferTo; TransferTo)
                {
                }
                column(TransferFrom; TransferFrom)
                {
                }
                column(Transfer_Shipment_Header___Shipment_Date_; Format("Transfer Shipment Header"."Shipment Date"))
                {
                }
                column(ShippingAgent_Name; ShippingAgent.Name)
                {
                }
                column(Transfer_Shipment_Line__Item_No__; "Item No.")
                {
                }
                column(Transfer_Shipment_Line__Units_per_Parcel_; "Units per Parcel")
                {
                }
                column(Transfer_Shipment_Line__Unit_of_Measure_; "Unit of Measure")
                {
                }
                column(Transfer_Shipment_Line_Description; Description)
                {
                }
                column(Item__Tariff_No__; Item."Tariff No.")
                {
                }
                column(Transfer_Shipment_Line__Gross_Weight_; "Gross Weight")
                {
                }
                column(Transfer_Shipment_Line__Unit_Volume_; "Unit Volume")
                {
                }
                column(FromAddr_5__Control1000023; FromAddr[5])
                {
                }
                column(FromAddr_4__Control1000024; FromAddr[4])
                {
                }
                column(FromAddr_3__Control1000025; FromAddr[3])
                {
                }
                column(FromAddr_2__Control1000026; FromAddr[2])
                {
                }
                column(FromAddr_1__Control1000027; FromAddr[1])
                {
                }
                column(EstdIn; EstdIn)
                {
                }
                column(WORKDATE; Format(WorkDate()))
                {
                }
                column(Transfer_Shipment_Line_Document_No_; "Document No.")
                {
                }
                column(Transfer_Shipment_Line_Line_No_; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Units per Parcel" <> 0 then begin
                        "Units per Parcel" := Round(Quantity / "Units per Parcel", 1, '>');
                        "Unit of Measure" := Text000;
                    end else
                        "Units per Parcel" := Quantity;

                    Item.Get("Item No.");

                    "Gross Weight" := Quantity * "Gross Weight";
                    "Unit Volume" := Quantity * "Unit Volume";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.TransferShptTransferFrom(FromAddr, "Transfer Shipment Header");
                FormatAddr.TransferShptTransferTo(ToAddr, "Transfer Shipment Header");

                if not Country.Get("Trsf.-from Country/Region Code") then
                    Country.Init();
                TransferFrom := DelChr(AddText("Transfer-from City") + AddText(Country.Name), '>', ', ');
                EstdIn := "Transfer-from City";

                if not Country.Get("Trsf.-to Country/Region Code") then
                    Country.Init();
                TransferTo := DelChr(AddText("Transfer-to City") + AddText(Country.Name), '>', ', ');

                if not ShippingAgent.Get("Shipping Agent Code") then
                    ShippingAgent.Init();
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
        ShippingAgent: Record "Shipping Agent";
        Country: Record "Country/Region";
        FormatAddr: Codeunit "Format Address";
        FromAddr: array[8] of Text[100];
        ToAddr: array[8] of Text[100];
        TransferFrom: Text[80];
        TransferTo: Text[80];
        EstdIn: Text[50];
        Text000: Label 'parcel(s)';

    [Scope('OnPrem')]
    procedure AddText(Text: Text[249]): Text[250]
    begin
        if Text <> '' then
            exit(Text + ', ');
    end;
}

