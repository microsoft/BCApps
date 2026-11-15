// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 17701 "Sales Address Mgt."
{
    var
        UnsupportedAddressRoleErr: Label 'Unsupported sales address role: %1.', Comment = '%1 = address role';

    procedure FormatAddress(SalesHeader: Record "Sales Header"; AddressRole: Enum "Sales Address Role"): Text
    var
        TempAddress: Record Location temporary;
        LocationAddressMgt: Codeunit "Location Address Mgt.";
    begin
        GetAddress(SalesHeader, AddressRole, TempAddress);
        exit(LocationAddressMgt.FormatAddress(TempAddress));
    end;

    procedure FormatAddress(SalesInvoiceHeader: Record "Sales Invoice Header"; AddressRole: Enum "Sales Address Role"): Text
    var
        TempSalesHeader: Record "Sales Header" temporary;
    begin
        TempSalesHeader."Sell-to Address" := SalesInvoiceHeader."Sell-to Address";
        TempSalesHeader."Sell-to Address 2" := SalesInvoiceHeader."Sell-to Address 2";
        TempSalesHeader."Sell-to City" := SalesInvoiceHeader."Sell-to City";
        TempSalesHeader."Sell-to Post Code" := SalesInvoiceHeader."Sell-to Post Code";
        TempSalesHeader."Sell-to County" := SalesInvoiceHeader."Sell-to County";
        TempSalesHeader."Sell-to Country/Region Code" := SalesInvoiceHeader."Sell-to Country/Region Code";
        TempSalesHeader."Bill-to Address" := SalesInvoiceHeader."Bill-to Address";
        TempSalesHeader."Bill-to Address 2" := SalesInvoiceHeader."Bill-to Address 2";
        TempSalesHeader."Bill-to City" := SalesInvoiceHeader."Bill-to City";
        TempSalesHeader."Bill-to Post Code" := SalesInvoiceHeader."Bill-to Post Code";
        TempSalesHeader."Bill-to County" := SalesInvoiceHeader."Bill-to County";
        TempSalesHeader."Bill-to Country/Region Code" := SalesInvoiceHeader."Bill-to Country/Region Code";
        TempSalesHeader."Ship-to Address" := SalesInvoiceHeader."Ship-to Address";
        TempSalesHeader."Ship-to Address 2" := SalesInvoiceHeader."Ship-to Address 2";
        TempSalesHeader."Ship-to City" := SalesInvoiceHeader."Ship-to City";
        TempSalesHeader."Ship-to Post Code" := SalesInvoiceHeader."Ship-to Post Code";
        TempSalesHeader."Ship-to County" := SalesInvoiceHeader."Ship-to County";
        TempSalesHeader."Ship-to Country/Region Code" := SalesInvoiceHeader."Ship-to Country/Region Code";
        exit(FormatAddress(TempSalesHeader, AddressRole));
    end;

    procedure EditAddress(var SalesHeader: Record "Sales Header"; AddressRole: Enum "Sales Address Role"): Boolean
    var
        TempAddress: Record Location temporary;
        UpdatedSalesHeader: Record "Sales Header";
        AddressEditor: Page "Location Address Editor";
    begin
        GetAddress(SalesHeader, AddressRole, TempAddress);
        AddressEditor.SetLocation(TempAddress);
        if AddressEditor.RunModal() <> Action::OK then
            exit(false);

        AddressEditor.GetLocation(TempAddress);
        UpdatedSalesHeader := SalesHeader;
        case AddressRole of
            AddressRole::SellTo:
                ApplySellToAddress(UpdatedSalesHeader, TempAddress);
            AddressRole::BillTo:
                ApplyBillToAddress(UpdatedSalesHeader, TempAddress);
            AddressRole::ShipTo:
                ApplyShipToAddress(UpdatedSalesHeader, TempAddress);
            else
                Error(UnsupportedAddressRoleErr, AddressRole);
        end;
        SalesHeader := UpdatedSalesHeader;
        exit(true);
    end;

    local procedure GetAddress(SalesHeader: Record "Sales Header"; AddressRole: Enum "Sales Address Role"; var TempAddress: Record Location temporary)
    begin
        Clear(TempAddress);
        case AddressRole of
            AddressRole::SellTo:
                begin
                    TempAddress.Address := SalesHeader."Sell-to Address";
                    TempAddress."Address 2" := SalesHeader."Sell-to Address 2";
                    TempAddress.City := SalesHeader."Sell-to City";
                    TempAddress."Post Code" := SalesHeader."Sell-to Post Code";
                    TempAddress.County := SalesHeader."Sell-to County";
                    TempAddress."Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
                end;
            AddressRole::BillTo:
                begin
                    TempAddress.Address := SalesHeader."Bill-to Address";
                    TempAddress."Address 2" := SalesHeader."Bill-to Address 2";
                    TempAddress.City := SalesHeader."Bill-to City";
                    TempAddress."Post Code" := SalesHeader."Bill-to Post Code";
                    TempAddress.County := SalesHeader."Bill-to County";
                    TempAddress."Country/Region Code" := SalesHeader."Bill-to Country/Region Code";
                end;
            AddressRole::ShipTo:
                begin
                    TempAddress.Address := SalesHeader."Ship-to Address";
                    TempAddress."Address 2" := SalesHeader."Ship-to Address 2";
                    TempAddress.City := SalesHeader."Ship-to City";
                    TempAddress."Post Code" := SalesHeader."Ship-to Post Code";
                    TempAddress.County := SalesHeader."Ship-to County";
                    TempAddress."Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
                end;
            else
                Error(UnsupportedAddressRoleErr, AddressRole);
        end;
    end;

    local procedure ApplySellToAddress(var SalesHeader: Record "Sales Header"; TempAddress: Record Location temporary)
    begin
        if SalesHeader."Sell-to Country/Region Code" <> TempAddress."Country/Region Code" then
            SalesHeader.Validate("Sell-to Country/Region Code", TempAddress."Country/Region Code");
        if SalesHeader."Sell-to Address" <> TempAddress.Address then
            SalesHeader.Validate("Sell-to Address", TempAddress.Address);
        if SalesHeader."Sell-to Address 2" <> TempAddress."Address 2" then
            SalesHeader.Validate("Sell-to Address 2", TempAddress."Address 2");
        if SalesHeader."Sell-to Post Code" <> TempAddress."Post Code" then
            SalesHeader.Validate("Sell-to Post Code", TempAddress."Post Code");
        if SalesHeader."Sell-to City" <> TempAddress.City then
            SalesHeader.Validate("Sell-to City", TempAddress.City);
        if SalesHeader."Sell-to County" <> TempAddress.County then
            SalesHeader.Validate("Sell-to County", TempAddress.County);
    end;

    local procedure ApplyBillToAddress(var SalesHeader: Record "Sales Header"; TempAddress: Record Location temporary)
    begin
        if SalesHeader."Bill-to Country/Region Code" <> TempAddress."Country/Region Code" then
            SalesHeader.Validate("Bill-to Country/Region Code", TempAddress."Country/Region Code");
        if SalesHeader."Bill-to Address" <> TempAddress.Address then
            SalesHeader.Validate("Bill-to Address", TempAddress.Address);
        if SalesHeader."Bill-to Address 2" <> TempAddress."Address 2" then
            SalesHeader.Validate("Bill-to Address 2", TempAddress."Address 2");
        if SalesHeader."Bill-to Post Code" <> TempAddress."Post Code" then
            SalesHeader.Validate("Bill-to Post Code", TempAddress."Post Code");
        if SalesHeader."Bill-to City" <> TempAddress.City then
            SalesHeader.Validate("Bill-to City", TempAddress.City);
        if SalesHeader."Bill-to County" <> TempAddress.County then
            SalesHeader.Validate("Bill-to County", TempAddress.County);
    end;

    local procedure ApplyShipToAddress(var SalesHeader: Record "Sales Header"; TempAddress: Record Location temporary)
    begin
        if SalesHeader."Ship-to Country/Region Code" <> TempAddress."Country/Region Code" then
            SalesHeader.Validate("Ship-to Country/Region Code", TempAddress."Country/Region Code");
        if SalesHeader."Ship-to Address" <> TempAddress.Address then
            SalesHeader.Validate("Ship-to Address", TempAddress.Address);
        if SalesHeader."Ship-to Address 2" <> TempAddress."Address 2" then
            SalesHeader.Validate("Ship-to Address 2", TempAddress."Address 2");
        if SalesHeader."Ship-to Post Code" <> TempAddress."Post Code" then
            SalesHeader.Validate("Ship-to Post Code", TempAddress."Post Code");
        if SalesHeader."Ship-to City" <> TempAddress.City then
            SalesHeader.Validate("Ship-to City", TempAddress.City);
        if SalesHeader."Ship-to County" <> TempAddress.County then
            SalesHeader.Validate("Ship-to County", TempAddress.County);
    end;
}
