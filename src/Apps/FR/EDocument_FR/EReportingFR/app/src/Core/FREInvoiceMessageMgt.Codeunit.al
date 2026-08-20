// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 10975 "FR E-Invoice Message Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntry', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
        ProcessApplication(DtldCustLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntryUnapply(var CustomerPostingGroup: Record "Customer Posting Group"; var OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlLine: Record "Gen. Journal Line"; var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        ProcessUnapplication(OldDetailedCustLedgEntry, NewDetailedCustLedgEntry);
    end;

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
        EDocument: Record "E-Document";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not IsInvoiceApplication(DetailedCustLedgEntry) then
            exit;
        if not InvoiceCustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.") then
            exit;
        if not PaymentCustLedgerEntry.Get(DetailedCustLedgEntry."Applied Cust. Ledger Entry No.") then
            exit;
        if PaymentCustLedgerEntry."Document Type" <> PaymentCustLedgerEntry."Document Type"::Payment then
            exit;
        if not FindInvoiceEDocuments(EDocument, InvoiceCustLedgerEntry) then
            exit;

        repeat
            if IsEligibleFrenchEDocument(EDocument) then
                CreateAndSendMessage(
                    EDocument, "FR E-Invoice Message Type"::Collected, DetailedCustLedgEntry.SystemId,
                    -DetailedCustLedgEntry.Amount, DetailedCustLedgEntry."Currency Code", DetailedCustLedgEntry."Posting Date",
                    DetailedCustLedgEntry."Entry No.", 0, '', '');
        until EDocument.Next() = 0;
    end;

    internal procedure ProcessUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CollectedMessage: Record "FR E-Invoice Message";
        EDocument: Record "E-Document";
    begin
        if not IsInvoiceApplication(OldDetailedCustLedgEntry) then
            exit;

        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.SetRange("Detailed Ledger Entry No.", OldDetailedCustLedgEntry."Entry No.");
        if not CollectedMessage.FindSet() then
            exit;

        repeat
            EDocument.Get(CollectedMessage."E-Document Entry No.");
            CreateAndSendMessage(
                EDocument, "FR E-Invoice Message Type"::"Negative Collected", NewDetailedCustLedgEntry.SystemId,
                -CollectedMessage.Amount, CollectedMessage."Currency Code", NewDetailedCustLedgEntry."Posting Date",
                NewDetailedCustLedgEntry."Entry No.", CollectedMessage."Entry No.", '', '');
        until CollectedMessage.Next() = 0;
    end;

    local procedure CreateAndSendMessage(EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type"; SourceOccurrenceID: Guid; Amount: Decimal; CurrencyCode: Code[10]; EventDate: Date; DetailedLedgerEntryNo: Integer; OriginalEntryNo: Integer; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
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

        BuildMessage(EDocument, FREInvoiceMessage, TempBlob);
        FREInvoiceMessage."E-Document Message Entry No." := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", GetResponseType(MessageType), TempBlob);
        FREInvoiceMessage.Modify();
        EDocumentMessageAPI.SendMessage(FREInvoiceMessage."E-Document Message Entry No.");
    end;

    local procedure BuildMessage(EDocument: Record "E-Document"; FREInvoiceMessage: Record "FR E-Invoice Message"; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        AcknowledgementElement: XmlElement;
        ReferenceElement: XmlElement;
        StatusElement: XmlElement;
        AmountElement: XmlElement;
        OutStream: OutStream;
    begin
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := XmlElement.Create('CrossDomainAcknowledgementAndResponse', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('rsm', RsmNamespaceTok));
        RootElement.Add(XmlElement.Create('ExchangedDocument', RsmNamespaceTok,
            XmlElement.Create('ID', RamNamespaceTok, Format(FREInvoiceMessage."Source Occurrence ID"))));

        AcknowledgementElement := XmlElement.Create('AcknowledgementDocument', RsmNamespaceTok);
        ReferenceElement := XmlElement.Create('ReferenceReferencedDocument', RamNamespaceTok);
        ReferenceElement.Add(XmlElement.Create('IssuerAssignedID', RamNamespaceTok, EDocument."Document No."));
        ReferenceElement.Add(XmlElement.Create('StatusCode', RamNamespaceTok, InvoiceReferenceStatusCodeTok));
        if FREInvoiceMessage.Type = FREInvoiceMessage.Type::Refused then begin
            ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, RefusedStatusCodeTok));
            ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, RefusedStatusNameTok));
            StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
            StatusElement.Add(XmlElement.Create('ReasonCode', RamNamespaceTok, FREInvoiceMessage."Reason Code"));
            StatusElement.Add(XmlElement.Create('Reason', RamNamespaceTok, FREInvoiceMessage."Reason Description"));
            ReferenceElement.Add(StatusElement);
        end else begin
            ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, CollectedStatusCodeTok));
            ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, CollectedStatusNameTok));
            StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
            StatusElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, CollectedAmountTypeCodeTok));
            AmountElement := XmlElement.Create('ValueAmount', RamNamespaceTok, Format(FREInvoiceMessage.Amount, 0, 9));
            AmountElement.Add(XmlAttribute.Create('currencyID', ResolveCurrencyCode(FREInvoiceMessage."Currency Code")));
            StatusElement.Add(AmountElement);
            ReferenceElement.Add(StatusElement);
        end;
        AcknowledgementElement.Add(ReferenceElement);
        RootElement.Add(AcknowledgementElement);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure FindInvoiceEDocuments(var EDocument: Record "E-Document"; InvoiceCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if InvoiceCustLedgerEntry."Document Type" <> InvoiceCustLedgerEntry."Document Type"::Invoice then
            exit(false);
        if not SalesInvoiceHeader.Get(InvoiceCustLedgerEntry."Document No.") then
            exit(false);

        EDocument.SetRange("Document Record ID", SalesInvoiceHeader.RecordId);
        EDocument.SetRange(Direction, EDocument.Direction::Outgoing);
        EDocument.SetRange("Document Type", EDocument."Document Type"::"Sales Invoice");
        exit(EDocument.FindSet());
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

    local procedure IsInvoiceApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    begin
        exit(
            (DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::Application) and
            (DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::Invoice) and
            (DetailedCustLedgEntry.Amount < 0));
    end;

    local procedure GetResponseType(MessageType: Enum "FR E-Invoice Message Type"): Enum "E-Doc. Response Type"
    begin
        if MessageType = MessageType::Refused then
            exit("E-Doc. Response Type"::Refused);
        exit("E-Doc. Response Type"::None);
    end;

    local procedure ResolveCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        exit(GeneralLedgerSetup."LCY Code");
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        CollectedStatusCodeTok: Label '212', Locked = true;
        CollectedStatusNameTok: Label 'Encaissée', Locked = true;
        CollectedAmountTypeCodeTok: Label 'MEN', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        ReasonCodeRequiredErr: Label 'A refusal reason code is required.';
        ReasonDescriptionRequiredErr: Label 'A refusal reason description is required.';
        AlreadyRefusedErr: Label 'Invoice %1 has already been refused.', Comment = '%1 = invoice number';
}