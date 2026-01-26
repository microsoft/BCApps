// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Contact;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

table 12203 "Fattura Header"
{
    Caption = 'Fattura Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
        }
        field(2; "Customer No"; Code[20])
        {
            Caption = 'Customer No';
        }
        field(3; "Fattura Document Type"; Text[10])
        {
            Caption = 'Fattura Document Type';
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; "Entry Type"; Enum "Fattura Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(8; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,,Invoice,Credit Memo';
            OptionMembers = " ",,Invoice,"Credit Memo";
        }
        field(9; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(10; "Total Inv. Discount"; Decimal)
        {
            Caption = 'Total Inv. Discount';
        }
        field(11; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
        }
        field(12; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
        }
        field(13; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
        }
        field(20; "Fattura Project Code"; Code[15])
        {
            Caption = 'Fattura Project Code';
            TableRelation = "Fattura Project Info".Code where(Type = filter(Project));
        }
        field(21; "Fattura Tender Code"; Code[15])
        {
            Caption = 'Fattura Tender Code';
            TableRelation = "Fattura Project Info".Code where(Type = filter(Tender));
        }
        field(22; "Customer Purchase Order No."; Text[35])
        {
            Caption = 'Customer Purchase Order No.';
        }
        field(23; "Fattura PA Payment Method"; Code[4])
        {
            Caption = 'Fattura PA Payment Method';
        }
        field(24; "Fattura Payment Terms Code"; Code[4])
        {
            Caption = 'Fattura Payment Terms Code';
        }
        field(25; "Transmission Type"; Code[5])
        {
            Caption = 'Transmission Type';
        }
        field(26; "Progressive No."; Code[20])
        {
            Caption = 'Progressive No.';
        }
        field(30; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            OptionCaption = ' ,Customer,Contact,Vendor';
            OptionMembers = " ",Customer,Contact,Vendor;
        }
        field(31; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
        }
        field(50; "Fattura Stamp"; Boolean)
        {
            Caption = 'Fattura Stamp';
        }
        field(51; "Fattura Stamp Amount"; Decimal)
        {
            Caption = 'Fattura Stamp Amount';
        }
        field(60; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(61; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(70; "Applied Doc. No."; Code[20])
        {
            Caption = 'Applied Doc. No.';
        }
        field(71; "Applied Posting Date"; Date)
        {
            Caption = 'Applied Posting Date';
        }
        field(72; "Appl. Fattura Project Code"; Code[15])
        {
            Caption = 'Appl. Fattura Project Code';
            TableRelation = "Fattura Project Info".Code where(Type = filter(Project));
        }
        field(73; "Appl. Fattura Tender Code"; Code[15])
        {
            Caption = 'Appl. Fattura Tender Code';
            TableRelation = "Fattura Project Info".Code where(Type = filter(Tender));
        }
        field(74; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(75; "Self-Billing Document"; Boolean)
        {
            Caption = 'Self-Billing Document';
        }
        field(76; "Fattura Vendor No."; Code[20])
        {
            Caption = 'Fattura Vendor No.';
            TableRelation = Vendor;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetTableID() TableID: Integer
    begin
        case "Entry Type" of
            "Entry Type"::Sales:
                begin
                    if "Document Type" = "Document Type"::Invoice then
                        exit(DATABASE::"Sales Invoice Header");
                    exit(DATABASE::"Sales Cr.Memo Header");
                end;
            else
                OnGetTableID(Rec, TableID);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTaxRepresentative(var TempVendor: Record Vendor temporary): Boolean
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case "Tax Representative Type" of
            "Tax Representative Type"::Contact:
                begin
                    Contact.Get("Tax Representative No.");
                    TempVendor."Country/Region Code" := Contact."Country/Region Code";
                    TempVendor."VAT Registration No." := Contact."VAT Registration No.";
                    TempVendor.Name := Contact.Name;
                    exit(true);
                end;
            "Tax Representative Type"::Customer:
                begin
                    Customer.Get("Tax Representative No.");
                    TempVendor."Country/Region Code" := Customer."Country/Region Code";
                    TempVendor."VAT Registration No." := Customer."VAT Registration No.";
                    TempVendor."Individual Person" := Customer."Individual Person";
                    TempVendor."First Name" := Customer."First Name";
                    TempVendor."Last Name" := Customer."Last Name";
                    TempVendor.Name := Customer.Name;
                    exit(true);
                end;
            "Tax Representative Type"::Vendor:
                begin
                    Vendor.Get("Tax Representative No.");
                    TempVendor := Vendor;
                    exit(true);
                end;
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTableID(var FatturaHeader: Record "Fattura Header"; var TableID: Integer)
    begin
    end;
}

