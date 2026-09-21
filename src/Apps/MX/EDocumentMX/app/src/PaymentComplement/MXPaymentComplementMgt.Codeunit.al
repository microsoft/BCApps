// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.History;
using System.Utilities;

codeunit 3357 "MX Payment Complement Mgt."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "MX Payment Complement" = rimd;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Payment Occurrence Mgt.", 'OnAfterCreatePaymentOccurrence', '', false, false)]
    local procedure OnAfterCreatePaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    var
        Detail: Record "Detailed Cust. Ledg. Entry";
        Payment: Record "Cust. Ledger Entry";
    begin
        if not Detail.Get(EDocPaymentOccurrence."Detailed Ledger Entry No.") then
            exit;
        if not FindPayment(Detail, Payment) then
            exit;
        if EDocPaymentOccurrence.Type = EDocPaymentOccurrence.Type::Applied then
            Create(Payment, EDocPaymentOccurrence."Source Occurrence ID")
        else
            MarkReversed(Payment."Entry No.");
    end;

    local procedure Create(Payment: Record "Cust. Ledger Entry"; SourceOccurrenceId: Guid)
    var
        Parent: Record "E-Document";
        Complement: Record "MX Payment Complement";
        MessageAPI: Codeunit "E-Document Message API";
        Builder: Codeunit "MX Payment Complement Builder";
        Validation: Codeunit "EDoc CFDI Validation MX";
        PaymentRef: RecordRef;
        Payload: Codeunit "Temp Blob";
    begin
        Complement.SetRange("Payment Entry No.", Payment."Entry No.");
        if Complement.FindFirst() then
            exit;
        if not FindParent(Payment, Parent) then
            exit;
        PaymentRef.GetTable(Payment);
        Validation.CheckPaymentDocument(PaymentRef);
        Complement.Init();
        Complement."Payment Entry No." := Payment."Entry No.";
        Complement."Parent E-Document Entry No." := Parent."Entry No";
        Complement."Source Occurrence ID" := SourceOccurrenceId;
        Complement."Created At" := CurrentDateTime();
        Complement.Insert();
        Builder.Build(Payment, Payload);
        Complement."E-Document Message Entry No." := MessageAPI.CreateMessage(Parent, "E-Document Message Type"::"MX CFDI Payment Complement", "E-Doc. Response Type"::None, Payload);
        Complement.Modify();
        MessageAPI.QueueMessage(Complement."E-Document Message Entry No.");
    end;

    local procedure MarkReversed(PaymentEntryNo: Integer)
    var
        Complement: Record "MX Payment Complement";
    begin
        Complement.SetRange("Payment Entry No.", PaymentEntryNo);
        if Complement.FindFirst() then begin
            Complement.Reversed := true;
            Complement.Modify();
        end;
    end;

    local procedure FindPayment(Detail: Record "Detailed Cust. Ledg. Entry"; var Payment: Record "Cust. Ledger Entry"): Boolean
    var
        Candidate: Record "Cust. Ledger Entry";
    begin
        if Candidate.Get(Detail."Cust. Ledger Entry No.") then
            if Candidate."Document Type" = Candidate."Document Type"::Payment then begin Payment := Candidate; exit(true); end;
        if Candidate.Get(Detail."Applied Cust. Ledger Entry No.") then
            if Candidate."Document Type" = Candidate."Document Type"::Payment then begin Payment := Candidate; exit(true); end;
    end;

    local procedure FindParent(Payment: Record "Cust. Ledger Entry"; var Parent: Record "E-Document"): Boolean
    var
        Detail: Record "Detailed Cust. Ledg. Entry";
        Applied: Record "Cust. Ledger Entry";
        SalesInvoice: Record "Sales Invoice Header";
        ServiceInvoice: Record "Service Invoice Header";
    begin
        Detail.SetRange("Cust. Ledger Entry No.", Payment."Entry No.");
        Detail.SetRange("Entry Type", Detail."Entry Type"::Application);
        Detail.SetRange(Unapplied, false);
        if Detail.FindSet() then
            repeat
                if Applied.Get(Detail."Applied Cust. Ledger Entry No.") and (Applied."Document Type" = Applied."Document Type"::Invoice) then begin
                    if SalesInvoice.Get(Applied."Document No.") then if FindClearedEDocument(SalesInvoice.RecordId(), Parent) then exit(true);
                    if ServiceInvoice.Get(Applied."Document No.") then if FindClearedEDocument(ServiceInvoice.RecordId(), Parent) then exit(true);
                end;
            until Detail.Next() = 0;
    end;

    local procedure FindClearedEDocument(DocumentId: RecordId; var Parent: Record "E-Document"): Boolean
    begin
        Parent.SetRange("Document Record ID", DocumentId);
        Parent.SetFilter("Clearance Date", '<>%1', 0DT);
        exit(Parent.FindFirst());
    end;
}
