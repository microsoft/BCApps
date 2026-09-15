// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 27032 "Update CFDI Fields Sales Doc"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;

    trigger OnRun()
    begin
        UpdateSalesDocuments();

        OnAfterOnRun();
    end;

    local procedure UpdateSalesDocuments()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Customer.SetFilter("CFDI Purpose", '<>%1', '');
        if Customer.IsEmpty() then
            exit;

        Customer.FindSet();
        repeat
            SalesHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesHeader.IsEmpty() then begin
                SalesHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            SalesHeader.SetRange("Bill-to Customer No.", '');
            SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesHeader.IsEmpty() then begin
                SalesHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            SalesInvoiceHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              SalesInvoiceHeader."Electronic Document Status"::" ",
              SalesInvoiceHeader."Electronic Document Status"::"Stamp Request Error",
              SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
            SalesInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesInvoiceHeader.IsEmpty() then
                SalesInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
            SalesInvoiceHeader.SetRange("Bill-to Customer No.", '');
            SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesInvoiceHeader.IsEmpty() then
                SalesInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");

            SalesCrMemoHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              SalesCrMemoHeader."Electronic Document Status"::" ",
              SalesCrMemoHeader."Electronic Document Status"::"Stamp Request Error",
              SalesCrMemoHeader."Electronic Document Status"::"Cancel Error");
            SalesCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not SalesCrMemoHeader.IsEmpty() then begin
                SalesCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
            SalesCrMemoHeader.SetRange("Bill-to Customer No.", '');
            SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
            if not SalesCrMemoHeader.IsEmpty() then begin
                SalesCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                SalesCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
        until Customer.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun()
    begin
    end;
}

