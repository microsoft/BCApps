// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.History;

#pragma warning disable AS0088
tableextension 7000105 "Purchase Header ES" extends "Purchase Header"
{
    fields
    {
        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                PurchaseInvoiceHeader: Record "Purch. Inv. Header";
            begin
                if PurchaseInvoiceHeader.LookupInvoice("Pay-to Vendor No.") then
                    Validate("Corrected Invoice No.", PurchaseInvoiceHeader."No.");
            end;

            trigger OnValidate()
            var
                PurchaseInvoiceHeader: Record "Purch. Inv. Header";
            begin
                if "Corrected Invoice No." <> '' then
                    PurchaseInvoiceHeader.CheckCorrectedDocumentExist("Pay-to Vendor No.", "Corrected Invoice No.");
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
