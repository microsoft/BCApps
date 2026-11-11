// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

#pragma warning disable AS0088
tableextension 7000104 "Sales Header ES" extends "Sales Header"
{
    fields
    {
        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
            begin
                if SalesInvoiceHeader.LookupInvoice("Bill-to Customer No.") then
                    Validate("Corrected Invoice No.", SalesInvoiceHeader."No.");
            end;

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
            begin
                if "Corrected Invoice No." <> '' then
                    SalesInvoiceHeader.CheckCorrectedDocumentExist("Bill-to Customer No.", "Corrected Invoice No.");

                OnAfterValidateCorrectedInvoiceNoOnSII(Rec);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCorrectedInvoiceNoOnSII(var SalesHeader: Record "Sales Header")
    begin
    end;
}
