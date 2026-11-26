// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

tableextension 10794 "Service Cr.Memo Header ES" extends "Service Cr.Memo Header"
{
    fields
    {
        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Invoice Header";

            trigger OnLookup()
            var
                PostedServiceInvoices: Page "Posted Service Invoices";
                ServiceInvoiceHeader: Record "Service Invoice Header";
            begin
                ServiceInvoiceHeader.SetCurrentKey("No.");
                ServiceInvoiceHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
                ServiceInvoiceHeader.SetRange("No.", "Corrected Invoice No.");

                PostedServiceInvoices.SetTableView(ServiceInvoiceHeader);
                PostedServiceInvoices.SetRecord(ServiceInvoiceHeader);
                PostedServiceInvoices.LookupMode(true);
                if PostedServiceInvoices.RunModal() = ACTION::LookupOK then
                    PostedServiceInvoices.GetRecord(ServiceInvoiceHeader);
                Clear(PostedServiceInvoices);
            end;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif       
    }

}