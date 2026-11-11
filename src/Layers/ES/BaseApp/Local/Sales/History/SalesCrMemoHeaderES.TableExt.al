// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

#pragma warning disable AS0088
tableextension 7000106 "Sales Cr.Memo Header ES" extends "Sales Cr.Memo Header"
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
                SalesInvoiceHeader: Record "Sales Invoice Header";
            begin
                if SalesInvoiceHeader.LookupInvoice("Bill-to Customer No.") then
                    Validate("Corrected Invoice No.", SalesInvoiceHeader."No.");
            end;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
    }
}
