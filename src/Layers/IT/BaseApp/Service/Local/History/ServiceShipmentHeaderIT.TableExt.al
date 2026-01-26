// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Shipping;
using Microsoft.Purchases.Vendor;

tableextension 12458 "Service Shipment Header IT" extends "Service Shipment Header"
{
    fields
    {
        modify("Shipment Method Code")
        {
            trigger OnAfterValidate()
            begin
                if "Shipping Agent Code" <> '' then
                    CheckShipAgentMethodComb();
                if not ShipmentMethod.ThirdPartyLoader("Shipment Method Code") and
                  ("3rd Party Loader Type" <> "3rd Party Loader Type"::" ")
                then begin
                    "3rd Party Loader Type" := "3rd Party Loader Type"::" ";
                    "3rd Party Loader No." := '';
                end;
            end;
        }
        modify("Shipping Agent Code")
        {
            trigger OnAfterValidate()
            begin
                if "Shipment Method Code" <> '' then
                    CheckShipAgentMethodComb();
                UpdateTDDPreparedBy();
            end;
        }
        field(12174; "3rd Party Loader Type"; Option)
        {
            Caption = '3rd Party Loader Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "3rd Party Loader Type" <> "3rd Party Loader Type"::" " then
                    ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
                if "3rd Party Loader Type" <> xRec."3rd Party Loader Type" then
                    "3rd Party Loader No." := '';
            end;
        }
        field(12175; "3rd Party Loader No."; Code[20])
        {
            Caption = '3rd Party Loader No.';
            DataClassification = CustomerContent;
            TableRelation = if ("3rd Party Loader Type" = const(Vendor)) Vendor
            else
            if ("3rd Party Loader Type" = const(Contact)) Contact where(Type = filter(Company));

            trigger OnValidate()
            begin
                ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
            end;
        }
        field(12176; "Additional Information"; Text[50])
        {
            Caption = 'Additional Information';
            DataClassification = CustomerContent;
        }
        field(12177; "Additional Notes"; Text[50])
        {
            Caption = 'Additional Notes';
            DataClassification = CustomerContent;
        }
        field(12178; "Additional Instructions"; Text[50])
        {
            Caption = 'Additional Instructions';
            DataClassification = CustomerContent;
        }
        field(12179; "TDD Prepared By"; Text[50])
        {
            Caption = 'TDD Prepared By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12182; "Fattura Project Code"; Code[15])
        {
            Caption = 'Fattura Project Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Project));
        }
        field(12183; "Fattura Tender Code"; Code[15])
        {
            Caption = 'Fattura Tender Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Tender));
        }
        field(12184; "Customer Purchase Order No."; Text[35])
        {
            Caption = 'Customer Purchase Order No.';
            DataClassification = CustomerContent;
        }
    }

    var
        ShipmentMethod: Record "Shipment Method";
        MustBeVendorContactErr: Label ' %1 %2 must be Vendor/Contact for %3 %4 3rd-Party Loader.', Comment = '%1 %2 - Shipping Agent Code, %3 %4 - Shipment Method Code';

    local procedure UpdateTDDPreparedBy()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then begin
            if "TDD Prepared By" = '' then
                "TDD Prepared By" := CopyStr(UserId(), 1, 50);
        end else
            "TDD Prepared By" := '';
    end;

    local procedure CheckShipAgentMethodComb()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") and
          not ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code")
        then
            Error(
              MustBeVendorContactErr, FieldCaption("Shipping Agent Code"), "Shipping Agent Code",
              FieldCaption("Shipment Method Code"), "Shipment Method Code");
    end;

    procedure CheckTDDData(): Boolean
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        CheckShipAgentMethodComb();
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") then begin
            TestField("3rd Party Loader Type");
            TestField("3rd Party Loader No.");
        end else begin
            TestField("3rd Party Loader Type", "3rd Party Loader Type"::" ");
            TestField("3rd Party Loader No.", '');
        end;
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then begin
            TestField("TDD Prepared By");
            exit(true);
        end;
    end;

    procedure GetTDDAddr(var ShippingAgentAddr: array[8] of Text[100]; var LoaderAddr: array[8] of Text[100])
    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        Contact: Record Contact;
        ShippingAgent: Record "Shipping Agent";
    begin
        ShippingAgent.GetTDDAddr("Shipping Agent Code", ShippingAgentAddr);
        case "3rd Party Loader Type" of
            "3rd Party Loader Type"::Vendor:
                Vendor.GetTDDAddr("3rd Party Loader No.", LoaderAddr);
            "3rd Party Loader Type"::Contact:
                Contact.GetTDDAddr("3rd Party Loader No.", LoaderAddr);
            "3rd Party Loader Type"::" ":
                CompanyInfo.GetTDDAddr(LoaderAddr);
        end;
    end;
}