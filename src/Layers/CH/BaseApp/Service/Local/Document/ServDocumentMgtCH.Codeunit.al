// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Sales.Customer;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 11524 "Serv. Document Mgt. CH"
{
    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLine', '', false, false)]
    local procedure OnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Currency Code" = '' then
            GenJournalLine."Currency Factor" := 1
        else
            GenJournalLine."Currency Factor" := ServiceHeader."Currency Factor";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforeServInvHeaderInsert', '', false, false)]
    local procedure OnBeforeServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
        if (ServiceHeader."Posting Description" = Format(ServiceHeader."Document Type") + ' ' + ServiceHeader."No.") or (ServiceHeader."Posting No." <> '') then
            if ServiceHeader."Document Type" <> ServiceHeader."Document Type"::Order then
                ServiceInvoiceHeader."Posting Description" :=
                  CopyStr(CopyStr(Format(ServiceHeader."Document Type"), 1, 4) + '. ' + ServiceHeader."Posting No." + '/' +
                    ServiceHeader."Bill-to Name", 1, MaxStrLen(ServiceHeader."Posting Description"))
            else
                ServiceInvoiceHeader."Posting Description" :=
                  CopyStr(CopyStr(Format(ServiceHeader."Document Type"), 1, 4) + '. ' + ServiceHeader."No." + '/' +
                    ServiceHeader."Bill-to Name", 1, MaxStrLen(ServiceHeader."Posting Description"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Posting Journals Mgt.", 'OnPostItemJnlLineOnBeforeCreateWhseJnlLine', '', false, false)]
    local procedure OnPostItemJnlLineOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceHeader: Record "Service Header"; var ShouldCreateWhseJnlLine: Boolean; ServiceShipmentHeader: Record "Service Shipment Header"; var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
    begin
        ItemJournalLine."Customer No." := ServiceHeader."Bill-to Customer No.";
        if Customer.Get(ServiceHeader."Bill-to Customer No.") then
            ItemJournalLine."Customer Salesperson Code" := Customer."Salesperson Code";
        ItemJournalLine."Ship-to Address Code" := ServiceHeader."Ship-to Code";
    end;
}