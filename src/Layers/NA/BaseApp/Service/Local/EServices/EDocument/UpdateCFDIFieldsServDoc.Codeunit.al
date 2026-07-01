// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 27091 "Update CFDI Fields Serv. Doc"
{
    Permissions = TableData "Service Invoice Header" = rm,
                  TableData "Service Cr.Memo Header" = rm;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update CFDI Fields Sales Doc", 'OnAfterOnRun', '', false, false)]
    local procedure OnAfterOnRun()
    begin
        UpdateServiceDocuments();
    end;

    local procedure UpdateServiceDocuments()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        Customer.SetFilter("CFDI Purpose", '<>%1', '');
        if Customer.IsEmpty() then
            exit;

        Customer.FindSet();
        repeat
            ServiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceHeader.IsEmpty() then begin
                ServiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                ServiceHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;

            ServiceInvoiceHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              ServiceInvoiceHeader."Electronic Document Status"::" ",
              ServiceInvoiceHeader."Electronic Document Status"::"Stamp Request Error",
              ServiceInvoiceHeader."Electronic Document Status"::"Cancel Error");
            ServiceInvoiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceInvoiceHeader.IsEmpty() then
                ServiceInvoiceHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");

            ServiceCrMemoHeader.SetFilter(
              "Electronic Document Status", '%1|%2|%3',
              ServiceCrMemoHeader."Electronic Document Status"::" ",
              ServiceCrMemoHeader."Electronic Document Status"::"Stamp Request Error",
              ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error");
            ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Customer."No.");
            if not ServiceCrMemoHeader.IsEmpty() then begin
                ServiceCrMemoHeader.ModifyAll("CFDI Purpose", Customer."CFDI Purpose");
                ServiceCrMemoHeader.ModifyAll("CFDI Relation", Customer."CFDI Relation");
            end;
        until Customer.Next() = 0;
    end;
}