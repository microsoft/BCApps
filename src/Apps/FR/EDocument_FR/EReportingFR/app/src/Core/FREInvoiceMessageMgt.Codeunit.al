// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 10975 "FR E-Invoice Message Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure RefuseInvoice(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        EDocument.TestField(Direction, EDocument.Direction::Incoming);
        EDocument.TestField("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.TestField(Service);
        if ReasonCode = '' then
            Error(ReasonCodeRequiredErr);
        if ReasonDescription = '' then
            Error(ReasonDescriptionRequiredErr);

        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Refused);
        if not FREInvoiceMessage.IsEmpty() then
            Error(AlreadyRefusedErr, EDocument."Document No.");

        CreateAndSendMessage(EDocument, FREInvoiceMessage.Type::Refused, CreateGuid(), 0, '', Today(), 0, 0, ReasonCode, ReasonDescription);
    end;

    internal procedure ProcessApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);
    end;

    internal procedure ProcessUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessUnapplication(OldDetailedCustLedgEntry, NewDetailedCustLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Payment Occurrence Mgt.", 'OnAfterCreatePaymentOccurrence', '', false, false)]
    local procedure OnAfterCreatePaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    var
        CollectedMessage: Record "FR E-Invoice Message";
        EDocument: Record "E-Document";
        OriginalOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        EDocument.Get(EDocPaymentOccurrence."E-Document Entry No.");
        if not IsEligibleFrenchEDocument(EDocument) then
            exit;

        if EDocPaymentOccurrence.Type = EDocPaymentOccurrence.Type::Applied then begin
            CreateAndSendMessage(
                EDocument, "FR E-Invoice Message Type"::Collected, EDocPaymentOccurrence."Source Occurrence ID",
                EDocPaymentOccurrence.Amount, EDocPaymentOccurrence."Currency Code", EDocPaymentOccurrence."Event Date",
                EDocPaymentOccurrence."Detailed Ledger Entry No.", 0, '', '');
            exit;
        end;

        if not OriginalOccurrence.Get(EDocPaymentOccurrence."Original Occurrence Entry No.") then
            exit;
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.SetRange("Source Occurrence ID", OriginalOccurrence."Source Occurrence ID");
        if not CollectedMessage.FindFirst() then
            exit;

        CreateAndSendMessage(
            EDocument, "FR E-Invoice Message Type"::"Negative Collected", EDocPaymentOccurrence."Source Occurrence ID",
            EDocPaymentOccurrence.Amount, EDocPaymentOccurrence."Currency Code", EDocPaymentOccurrence."Event Date",
            EDocPaymentOccurrence."Detailed Ledger Entry No.", CollectedMessage."Entry No.", '', '');
    end;

    local procedure CreateAndSendMessage(EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type"; SourceOccurrenceID: Guid; Amount: Decimal; CurrencyCode: Code[10]; EventDate: Date; DetailedLedgerEntryNo: Integer; OriginalEntryNo: Integer; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange("Source Occurrence ID", SourceOccurrenceID);
        FREInvoiceMessage.SetRange(Type, MessageType);
        if FREInvoiceMessage.FindFirst() then
            exit;

        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := MessageType;
        FREInvoiceMessage."Source Occurrence ID" := SourceOccurrenceID;
        FREInvoiceMessage."Original Entry No." := OriginalEntryNo;
        FREInvoiceMessage.Amount := Amount;
        FREInvoiceMessage."Currency Code" := CurrencyCode;
        FREInvoiceMessage."Event Date" := EventDate;
        FREInvoiceMessage."Detailed Ledger Entry No." := DetailedLedgerEntryNo;
        FREInvoiceMessage."Reason Code" := ReasonCode;
        FREInvoiceMessage."Reason Description" := ReasonDescription;
        FREInvoiceMessage."Created At" := CurrentDateTime();
        FREInvoiceMessage.Insert();

        FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);
        FREInvoiceMessage."E-Document Message Entry No." := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", GetResponseType(MessageType), TempBlob);
        FREInvoiceMessage.Modify();
        EDocumentMessageAPI.QueueMessage(FREInvoiceMessage."E-Document Message Entry No.");
    end;

    local procedure IsEligibleFrenchEDocument(EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        if not EDocumentService.Get(EDocument.Service) then
            exit(false);
        if not (EDocumentService."Document Format" in [EDocumentService."Document Format"::"Peppol BIS 3.0 FR", EDocumentService."Document Format"::"Factur-X FR"]) then
            exit(false);
        if not EDocumentServiceStatus.Get(EDocument."Entry No", EDocument.Service) then
            exit(false);
        exit(EDocumentServiceStatus.Status in [EDocumentServiceStatus.Status::Approved, EDocumentServiceStatus.Status::Cleared]);
    end;

    local procedure GetResponseType(MessageType: Enum "FR E-Invoice Message Type"): Enum "E-Doc. Response Type"
    begin
        if MessageType = MessageType::Refused then
            exit("E-Doc. Response Type"::Refused);
        exit("E-Doc. Response Type"::None);
    end;

    var
        ReasonCodeRequiredErr: Label 'A refusal reason code is required.';
        ReasonDescriptionRequiredErr: Label 'A refusal reason description is required.';
        AlreadyRefusedErr: Label 'Invoice %1 has already been refused.', Comment = '%1 = invoice number';
}