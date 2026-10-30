// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Sales.Receivables;
using Microsoft.eServices.EDocument.Processing.Message;
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
            Create(Payment, EDocPaymentOccurrence)
        else
            MarkReversed(Payment."Entry No.");
    end;

    local procedure Create(Payment: Record "Cust. Ledger Entry"; EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
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
        Complement.SetRange(Reversed, false);
        if Complement.FindFirst() then begin
            if (Complement."E-Document Message Entry No." <> 0) and
               (MessageAPI.GetMessageStatus(Complement."E-Document Message Entry No.") = Enum::"E-Doc. Message Status"::Created)
            then
                ScheduleDispatcher();
            exit;
        end;
        if not Parent.Get(EDocPaymentOccurrence."E-Document Entry No.") then
            exit;
        if not ResolveService(Parent) then
            exit;
        if Parent."Clearance Date" = 0DT then begin
            if HasClearedEDocument(Parent."Document Record ID") then
                exit;
            // Fail so Core retries the occurrence once the invoice is stamped, instead of marking it processed
            Error(InvoiceNotStampedErr, Parent."Document No.");
        end;
        PaymentRef.GetTable(Payment);
        Validation.CheckPaymentDocument(PaymentRef);
        Complement.Init();
        Complement."Payment Entry No." := Payment."Entry No.";
        Complement."Parent E-Document Entry No." := Parent."Entry No";
        Complement."Source Occurrence ID" := EDocPaymentOccurrence."Source Occurrence ID";
        Complement."Created At" := CurrentDateTime();
        Complement.Insert();
        Builder.Build(Payment, Payload);
        Complement."E-Document Message Entry No." := MessageAPI.CreateMessage(Parent, "E-Document Message Type"::"MX CFDI Payment Complement", "E-Doc. Response Type"::None, Payload);
        Complement.Modify();
        ScheduleDispatcher();
    end;

    local procedure ScheduleDispatcher()
    begin
        if not TaskScheduler.CanCreateTask() then
            Error(BackgroundTasksUnavailableErr);
        TaskScheduler.CreateTask(Codeunit::"MX Payment Compl. Dispatcher", 0, true);
    end;

    local procedure MarkReversed(PaymentEntryNo: Integer)
    var
        Complement: Record "MX Payment Complement";
    begin
        Complement.SetRange("Payment Entry No.", PaymentEntryNo);
        Complement.SetRange(Reversed, false);
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
            if Candidate."Document Type" = Candidate."Document Type"::Payment then begin
                Payment := Candidate;
                exit(true);
            end;
        if Candidate.Get(Detail."Applied Cust. Ledger Entry No.") then
            if Candidate."Document Type" = Candidate."Document Type"::Payment then begin
                Payment := Candidate;
                exit(true);
            end;
    end;

    local procedure ResolveService(var EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        if EDocumentService.Get(EDocument.Service) and (EDocumentService."Service Integration V2" = Enum::"Service Integration"::"Interfactura Service") then
            exit(true);

        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        if EDocumentServiceStatus.FindSet() then
            repeat
                if EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code") then
                    if EDocumentService."Service Integration V2" = Enum::"Service Integration"::"Interfactura Service" then begin
                        EDocument.Service := EDocumentService.Code;
                        exit(true);
                    end;
            until EDocumentServiceStatus.Next() = 0;
    end;

    local procedure HasClearedEDocument(DocumentId: RecordId): Boolean
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", DocumentId);
        EDocument.SetFilter("Clearance Date", '<>%1', 0DT);
        exit(not EDocument.IsEmpty());
    end;

    var
        BackgroundTasksUnavailableErr: Label 'The payment complement cannot be sent because background tasks are not available. It will be retried automatically.';
        InvoiceNotStampedErr: Label 'The payment complement cannot be created yet because invoice %1 is not stamped. It will be retried automatically.', Comment = '%1 = invoice document number';
}