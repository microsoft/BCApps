// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 9128 "Invt. Doc Ship. Detail Factbox"
{
    Caption = 'Shipping Details';
    PageType = CardPart;
    ApplicationArea = Warehouse;
    SourceTable = "Warehouse Activity Line";

    layout
    {
        area(Content)
        {
            field("Shipment Method Code"; Rec."Shipment Method Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the delivery conditions of the related shipment.';
            }
            field("Shipping Agent Code"; Rec."Shipping Agent Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies which shipping agent is used to transport the products.';
            }
            field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code that represents the default shipping agent service.';
            }
            field(Number; Number)
            {
                Caption = 'Ship-to Code';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code for delivery address.';
            }
            field(Name; Name)
            {
                Caption = 'Name';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the name that products on the document will be shipped to.';
            }
            field(Name2; Name2)
            {
                Caption = 'Name 2';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies additional name information.';
            }
            field(Address; Address)
            {
                Caption = 'Address';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the address that products on the document will be shipped to.';
            }
            field(Address2; Address2)
            {
                Caption = 'Address 2';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies additional address information.';
            }
            field(City; City)
            {
                Caption = 'City';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the city of the address.';
            }
            group(CountyGroup)
            {
                ShowCaption = false;
                Visible = IsCountyVisible;
                field(County; County)
                {
                    Caption = 'County';
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the state, province or county of the address.';
                }
            }
            field(PostCode; PostCode)
            {
                Caption = 'Post Code';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the postal code.';
            }
            field(CountryRegion; CountryRegion)
            {
                Caption = 'Country/Region';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the country or region.';
            }
            field(Contact; Contact)
            {
                Caption = 'Contact';
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the name of the contact person at the address that products on the document will be shipped to.';
            }
        }
    }

    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        Number: Text;
        Name: Text;
        Name2: Text;
        Address: Text;
        Address2: Text;
        City: Text;
        County: Text;
        PostCode: Text;
        CountryRegion: Text;
        Contact: Text;

    trigger OnAfterGetCurrRecord()
    begin
        ActivateFields();
    end;

    trigger OnOpenPage()
    begin
        ActivateFields();
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec."Source Type" of
            Database::"Sales Line":
                begin
                    GetSalesHeader();
                    Number := SalesHeader."Ship-to Code";
                    Name := SalesHeader."Ship-to Name";
                    Name2 := SalesHeader."Ship-to Name 2";
                    Address := SalesHeader."Ship-to Address";
                    Address2 := SalesHeader."Ship-to Address 2";
                    City := SalesHeader."Ship-to City";
                    County := SalesHeader."Ship-to County";
                    PostCode := SalesHeader."Ship-to Post Code";
                    CountryRegion := SalesHeader."Ship-to Country/Region Code";
                    Contact := SalesHeader."Ship-to Contact";
                end;
            Database::"Purchase Line":
                begin
                    GetPurchaseHeader();
                    Number := PurchaseHeader."Ship-to Code";
                    Name := PurchaseHeader."Ship-to Name";
                    Name2 := PurchaseHeader."Ship-to Name 2";
                    Address := PurchaseHeader."Ship-to Address";
                    Address2 := PurchaseHeader."Ship-to Address 2";
                    City := PurchaseHeader."Ship-to City";
                    County := PurchaseHeader."Ship-to County";
                    PostCode := PurchaseHeader."Ship-to Post Code";
                    CountryRegion := PurchaseHeader."Ship-to Country/Region Code";
                    Contact := PurchaseHeader."Ship-to Contact";
                end;
            Database::"Transfer Line":
                begin
                    GetTransferHeader();
                    Number := TransferHeader."Transfer-to Code";
                    Name := TransferHeader."Transfer-to Name";
                    Name2 := TransferHeader."Transfer-to Name 2";
                    Address := TransferHeader."Transfer-to Address";
                    Address2 := TransferHeader."Transfer-to Address 2";
                    City := TransferHeader."Transfer-to City";
                    County := TransferHeader."Transfer-to County";
                    PostCode := TransferHeader."Transfer-to Post Code";
                    CountryRegion := TransferHeader."Trsf.-to Country/Region Code";
                    Contact := TransferHeader."Transfer-to Contact";
                end;
        end;
    end;

    local procedure ActivateFields()
    begin
        IsCountyVisible := FormatAddress.UseCounty(CountryRegion);
    end;

    local procedure GetSalesHeader()
    begin
        if (Rec."Source Subtype" <> SalesHeader."Document Type".AsInteger()) or (Rec."Source No." <> SalesHeader."No.") then
            SalesHeader.Get(Rec."Source Subtype", Rec."Source No.");
    end;

    local procedure GetPurchaseHeader()
    begin
        if (Rec."Source Subtype" <> PurchaseHeader."Document Type".AsInteger()) or (Rec."Source No." <> PurchaseHeader."No.") then
            PurchaseHeader.Get(Rec."Source Subtype", Rec."Source No.");
    end;

    local procedure GetTransferHeader()
    begin
        if Rec."Source No." <> TransferHeader."No." then
            TransferHeader.Get(Rec."Source No.");
    end;
}
