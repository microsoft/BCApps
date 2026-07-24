// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10975 "FR E-Invoice Lifecycle Msg." implements IEDocMessageBuilder
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure BuildMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob")
    var
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
    begin
        FREInvoiceLifecycle.SetCurrentKey("E-Document Entry No.", "Created At");
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.SetRange("E-Document Message Entry No.", 0);
        FREInvoiceLifecycle.SetRange("Processing Status", FREInvoiceLifecycle."Processing Status"::Queued);
        if not FREInvoiceLifecycle.FindFirst() then
            Error(NoCapturedOccurrenceErr, EDocument."Entry No");

        BuildLifecycleMessage(EDocument, FREInvoiceLifecycle, TempBlob);
    end;

    internal procedure BuildLifecycleMessage(EDocument: Record "E-Document"; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        OutStream: OutStream;
    begin
        FREInvoiceLifecycle.TestField("E-Document Entry No.", EDocument."Entry No");

        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := BuildLifecycleElement(EDocument, FREInvoiceLifecycle);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure BuildLifecycleElement(EDocument: Record "E-Document"; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle") RootElement: XmlElement
    begin
        RootElement := XmlElement.Create('CrossDomainAcknowledgementAndResponse', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('qdt', QdtNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('udt', UdtNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('rsm', RsmNamespaceTok));

        if IsPPFMessage(FREInvoiceLifecycle) then
            ValidatePPFContext(FREInvoiceLifecycle);

        AddExchangedDocumentContext(RootElement, FREInvoiceLifecycle);
        AddExchangedDocument(RootElement, FREInvoiceLifecycle);
        AddAcknowledgementDocument(RootElement, EDocument, FREInvoiceLifecycle);
    end;

    local procedure AddExchangedDocumentContext(var RootElement: XmlElement; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        BusinessProcessElement: XmlElement;
        ContextElement: XmlElement;
        GuidelineElement: XmlElement;
    begin
        ContextElement := XmlElement.Create('ExchangedDocumentContext', RsmNamespaceTok);
        if not IsPPFMessage(FREInvoiceLifecycle) then begin
            BusinessProcessElement := XmlElement.Create('BusinessProcessSpecifiedDocumentContextParameter', RamNamespaceTok);
            BusinessProcessElement.Add(XmlElement.Create('ID', RamNamespaceTok, RegulatedBusinessProcessTok));
            ContextElement.Add(BusinessProcessElement);
        end;
        GuidelineElement := XmlElement.Create('GuidelineSpecifiedDocumentContextParameter', RamNamespaceTok);
        GuidelineElement.Add(XmlElement.Create('ID', RamNamespaceTok, GetProfileID(FREInvoiceLifecycle)));
        ContextElement.Add(GuidelineElement);
        RootElement.Add(ContextElement);
    end;

    local procedure AddExchangedDocument(var RootElement: XmlElement; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        ExchangedDocumentElement: XmlElement;
        IssueDateTimeElement: XmlElement;
    begin
        ExchangedDocumentElement := XmlElement.Create('ExchangedDocument', RsmNamespaceTok);
        ExchangedDocumentElement.Add(XmlElement.Create('ID', RamNamespaceTok, Format(FREInvoiceLifecycle."Source Occurrence ID")));
        ExchangedDocumentElement.Add(XmlElement.Create('Name', RamNamespaceTok, LifecycleMessageNameTok));
        IssueDateTimeElement := XmlElement.Create('IssueDateTime', RamNamespaceTok);
        IssueDateTimeElement.Add(CreateDateTimeString(FREInvoiceLifecycle."Created At"));
        ExchangedDocumentElement.Add(IssueDateTimeElement);
        if IsPPFMessage(FREInvoiceLifecycle) then begin
            ExchangedDocumentElement.Add(
                CreateTradeParty(
                    'SenderTradeParty', FREInvoiceLifecycle."Sender Platform ID", FREInvoiceLifecycle."Sender Platform Scheme",
                    FREInvoiceLifecycle."Sender Platform Name", SenderRoleCodeTok));
            ExchangedDocumentElement.Add(
                CreateTradeParty(
                    'IssuerTradeParty', FREInvoiceLifecycle."Invoice Issuer ID", FREInvoiceLifecycle."Invoice Issuer Scheme",
                    FREInvoiceLifecycle."Invoice Issuer Name", SellerRoleCodeTok));
            ExchangedDocumentElement.Add(
                CreateTradeParty('RecipientTradeParty', PPFIdentifierTok, PPFIdentifierSchemeTok, PPFNameTok, PPFRoleCodeTok));
        end;
        RootElement.Add(ExchangedDocumentElement);
    end;

    local procedure AddAcknowledgementDocument(var RootElement: XmlElement; EDocument: Record "E-Document"; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        AcknowledgementDocumentElement: XmlElement;
        IssueDateTimeElement: XmlElement;
        MultipleReferencesElement: XmlElement;
        ReferenceDocumentElement: XmlElement;
    begin
        ValidatePaymentStatus(FREInvoiceLifecycle."Lifecycle Status");

        AcknowledgementDocumentElement := XmlElement.Create('AcknowledgementDocument', RsmNamespaceTok);
        MultipleReferencesElement := XmlElement.Create('MultipleReferencesIndicator', RamNamespaceTok);
        MultipleReferencesElement.Add(XmlElement.Create('Indicator', UdtNamespaceTok, 'false'));
        AcknowledgementDocumentElement.Add(MultipleReferencesElement);
        AcknowledgementDocumentElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, InformationTypeCodeTok));

        IssueDateTimeElement := XmlElement.Create('IssueDateTime', RamNamespaceTok);
        IssueDateTimeElement.Add(CreateDateTimeString(CreateDateTime(FREInvoiceLifecycle."Event Date", 000000T)));
        AcknowledgementDocumentElement.Add(IssueDateTimeElement);

        ReferenceDocumentElement := XmlElement.Create('ReferenceReferencedDocument', RamNamespaceTok);
        ReferenceDocumentElement.Add(XmlElement.Create('IssuerAssignedID', RamNamespaceTok, EDocument."Document No."));
        ReferenceDocumentElement.Add(XmlElement.Create('StatusCode', RamNamespaceTok, InvoiceReferenceStatusCodeTok));
        ReferenceDocumentElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, InvoiceTypeCodeTok));
        if IsPPFMessage(FREInvoiceLifecycle) then begin
            ReferenceDocumentElement.Add(CreateDateTimeElement('ReceiptDateTime', FREInvoiceLifecycle."Invoice Receipt At"));
            ReferenceDocumentElement.Add(XmlElement.Create('ReferenceTypeCode', RamNamespaceTok, PPFInvoiceProfileTok));
            ReferenceDocumentElement.Add(CreateFormattedIssueDateTime(FREInvoiceLifecycle."Invoice Issue Date"));
        end;
        ReferenceDocumentElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, CollectedStatusCodeTok));
        ReferenceDocumentElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, CollectedStatusNameTok));
        if IsPPFMessage(FREInvoiceLifecycle) then
            ReferenceDocumentElement.Add(
                CreateTradeParty(
                    'IssuerTradeParty', FREInvoiceLifecycle."Invoice Issuer ID", FREInvoiceLifecycle."Invoice Issuer Scheme",
                    '', ''));
        AddVATBreakdown(ReferenceDocumentElement, FREInvoiceLifecycle);
        AcknowledgementDocumentElement.Add(ReferenceDocumentElement);
        RootElement.Add(AcknowledgementDocumentElement);
    end;

    local procedure AddVATBreakdown(var ReferenceDocumentElement: XmlElement; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        SpecifiedDocumentStatusElement: XmlElement;
    begin
        FREInvoiceLifecycleVAT.SetRange("Lifecycle Entry No.", FREInvoiceLifecycle."Entry No.");
        if not FREInvoiceLifecycleVAT.FindSet() then
            Error(VATBreakdownErr, FREInvoiceLifecycle."Entry No.");

        SpecifiedDocumentStatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
        repeat
            SpecifiedDocumentStatusElement.Add(CreateVATCharacteristic(FREInvoiceLifecycleVAT));
        until FREInvoiceLifecycleVAT.Next() = 0;
        ReferenceDocumentElement.Add(SpecifiedDocumentStatusElement);
    end;

    local procedure CreateVATCharacteristic(FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT") CharacteristicElement: XmlElement
    var
        AmountElement: XmlElement;
        ValueChangedElement: XmlElement;
    begin
        CharacteristicElement := XmlElement.Create('SpecifiedDocumentCharacteristic', RamNamespaceTok);
        CharacteristicElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, CollectedAmountTypeCodeTok));
        ValueChangedElement := XmlElement.Create('ValueChangedIndicator', RamNamespaceTok);
        ValueChangedElement.Add(XmlElement.Create('IndicatorString', UdtNamespaceTok, 'false'));
        CharacteristicElement.Add(ValueChangedElement);
        AmountElement := XmlElement.Create('ValueAmount', RamNamespaceTok, Format(FREInvoiceLifecycleVAT."Reported Amount", 0, 9));
        AmountElement.Add(XmlAttribute.Create('currencyID', FREInvoiceLifecycleVAT."Currency Code"));
        CharacteristicElement.Add(AmountElement);
        CharacteristicElement.Add(XmlElement.Create('ValuePercent', RamNamespaceTok, Format(FREInvoiceLifecycleVAT."VAT %", 0, 9)));
    end;

    local procedure CreateDateTimeString(Value: DateTime) DateTimeStringElement: XmlElement
    begin
        DateTimeStringElement := XmlElement.Create('DateTimeString', UdtNamespaceTok, Format(Value, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        DateTimeStringElement.Add(XmlAttribute.Create('format', DateTimeFormatCodeTok));
    end;

    local procedure CreateDateTimeElement(ElementName: Text; Value: DateTime) DateTimeElement: XmlElement
    begin
        DateTimeElement := XmlElement.Create(ElementName, RamNamespaceTok);
        DateTimeElement.Add(CreateDateTimeString(Value));
    end;

    local procedure CreateFormattedIssueDateTime(Value: Date) FormattedIssueDateTimeElement: XmlElement
    var
        DateTimeStringElement: XmlElement;
    begin
        FormattedIssueDateTimeElement := XmlElement.Create('FormattedIssueDateTime', RamNamespaceTok);
        DateTimeStringElement := XmlElement.Create('DateTimeString', QdtNamespaceTok, Format(Value, 0, '<Year4><Month,2><Day,2>'));
        DateTimeStringElement.Add(XmlAttribute.Create('format', DateFormatCodeTok));
        FormattedIssueDateTimeElement.Add(DateTimeStringElement);
    end;

    local procedure CreateTradeParty(ElementName: Text; Identifier: Text; IdentifierScheme: Text; PartyName: Text; RoleCode: Text) TradePartyElement: XmlElement
    var
        GlobalIDElement: XmlElement;
    begin
        TradePartyElement := XmlElement.Create(ElementName, RamNamespaceTok);
        GlobalIDElement := XmlElement.Create('GlobalID', RamNamespaceTok, Identifier);
        GlobalIDElement.Add(XmlAttribute.Create('schemeID', IdentifierScheme));
        TradePartyElement.Add(GlobalIDElement);
        if PartyName <> '' then
            TradePartyElement.Add(XmlElement.Create('Name', RamNamespaceTok, PartyName));
        if RoleCode <> '' then
            TradePartyElement.Add(XmlElement.Create('RoleCode', RamNamespaceTok, RoleCode));
    end;

    local procedure IsPPFMessage(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"): Boolean
    begin
        exit(FREInvoiceLifecycle."Sender Platform ID" <> '');
    end;

    local procedure GetProfileID(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"): Text
    begin
        if IsPPFMessage(FREInvoiceLifecycle) then
            exit(PPFInvoiceProfileTok);
        exit(CDVInvoiceProfileTok);
    end;

    local procedure ValidatePPFContext(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    begin
        FREInvoiceLifecycle.TestField("Invoice Issue Date");
        FREInvoiceLifecycle.TestField("Invoice Receipt At");
        FREInvoiceLifecycle.TestField("Sender Platform ID");
        FREInvoiceLifecycle.TestField("Sender Platform Scheme");
        FREInvoiceLifecycle.TestField("Sender Platform Name");
        FREInvoiceLifecycle.TestField("Invoice Issuer ID");
        FREInvoiceLifecycle.TestField("Invoice Issuer Scheme");
        FREInvoiceLifecycle.TestField("Invoice Issuer Name");
    end;

    local procedure ValidatePaymentStatus(LifecycleStatus: Enum "FR E-Invoice Lifecycle Status")
    begin
        if not (LifecycleStatus in [LifecycleStatus::Collected, LifecycleStatus::"Negative Collected"]) then
            Error(UnsupportedLifecycleStatusErr, LifecycleStatus);
    end;

    var
        NoCapturedOccurrenceErr: Label 'No unprocessed French invoice lifecycle occurrence exists for E-Document entry %1.', Comment = '%1 = E-Document entry number';
        VATBreakdownErr: Label 'Lifecycle occurrence %1 does not have the VAT breakdown required for a French collected status message.', Comment = '%1 = lifecycle occurrence entry number';
        UnsupportedLifecycleStatusErr: Label 'Lifecycle status %1 is not supported by the French collected status message builder.', Comment = '%1 = lifecycle status';
        LifecycleMessageNameTok: Label 'Invoice lifecycle collected status', Locked = true;
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        QdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:QualifiedDataType:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        RegulatedBusinessProcessTok: Label 'REGULATED', Locked = true;
        CDVInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:invoice', Locked = true;
        PPFInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:einvoicingF2', Locked = true;
        InformationTypeCodeTok: Label '23', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        InvoiceTypeCodeTok: Label '380', Locked = true;
        CollectedStatusCodeTok: Label '212', Locked = true;
        CollectedStatusNameTok: Label 'Encaissée', Locked = true;
        CollectedAmountTypeCodeTok: Label 'MEN', Locked = true;
        DateTimeFormatCodeTok: Label '204', Locked = true;
        DateFormatCodeTok: Label '102', Locked = true;
        SenderRoleCodeTok: Label 'WK', Locked = true;
        SellerRoleCodeTok: Label 'SE', Locked = true;
        PPFIdentifierTok: Label '9998', Locked = true;
        PPFIdentifierSchemeTok: Label '0238', Locked = true;
        PPFNameTok: Label 'PPF', Locked = true;
        PPFRoleCodeTok: Label 'DFH', Locked = true;
}