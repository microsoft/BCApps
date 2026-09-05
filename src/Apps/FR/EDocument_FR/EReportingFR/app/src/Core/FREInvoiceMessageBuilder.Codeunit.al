// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

codeunit 10976 "FR E-Invoice Message Builder"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure BuildMessage(EDocument: Record "E-Document"; FREInvoiceMessage: Record "FR E-Invoice Message"; var TempBlob: Codeunit "Temp Blob")
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        AcknowledgementElement: XmlElement;
        ReferenceElement: XmlElement;
        StatusElement: XmlElement;
        OutStream: OutStream;
    begin
        FREInvoiceMessage.TestField("Event Date");
        if IsPPFMessage(FREInvoiceMessage) then
            ValidatePPFContext(FREInvoiceMessage);
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := XmlElement.Create('CrossDomainAcknowledgementAndResponse', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('qdt', QdtNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('rsm', RsmNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('udt', UdtNamespaceTok));
        AddExchangedDocumentContext(RootElement, FREInvoiceMessage);
        AddExchangedDocument(RootElement, FREInvoiceMessage);

        AcknowledgementElement := XmlElement.Create('AcknowledgementDocument', RsmNamespaceTok);
        AcknowledgementElement.Add(CreateIndicatorElement('MultipleReferencesIndicator', false));
        AcknowledgementElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, InformationTypeCodeTok));
        AddIssueDateTime(AcknowledgementElement, FREInvoiceMessage."Event Date");
        ReferenceElement := XmlElement.Create('ReferenceReferencedDocument', RamNamespaceTok);
        ReferenceElement.Add(XmlElement.Create('IssuerAssignedID', RamNamespaceTok, EDocument."Document No."));
        ReferenceElement.Add(XmlElement.Create('StatusCode', RamNamespaceTok, InvoiceReferenceStatusCodeTok));
        ReferenceElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, InvoiceTypeCodeTok));
        if IsPPFMessage(FREInvoiceMessage) then begin
            ReferenceElement.Add(CreateDateTimeElement('ReceiptDateTime', FREInvoiceMessage."Invoice Receipt At"));
            ReferenceElement.Add(XmlElement.Create('ReferenceTypeCode', RamNamespaceTok, PPFInvoiceProfileTok));
            ReferenceElement.Add(CreateFormattedIssueDateTime(FREInvoiceMessage."Invoice Issue Date"));
        end;
        case FREInvoiceMessage.Type of
            FREInvoiceMessage.Type::Accepted:
                begin
                    ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, AcceptedStatusCodeTok));
                    ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, AcceptedStatusNameTok));
                end;
            FREInvoiceMessage.Type::Refused:
                begin
                    ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, RefusedStatusCodeTok));
                    ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, RefusedStatusNameTok));
                    if (FREInvoiceMessage."Reason Code" <> '') or (FREInvoiceMessage."Reason Description" <> '') then begin
                        StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
                        if FREInvoiceMessage."Reason Code" <> '' then
                            StatusElement.Add(XmlElement.Create('ReasonCode', RamNamespaceTok, FREInvoiceMessage."Reason Code"));
                        if FREInvoiceMessage."Reason Description" <> '' then
                            StatusElement.Add(XmlElement.Create('Reason', RamNamespaceTok, FREInvoiceMessage."Reason Description"));
                        ReferenceElement.Add(StatusElement);
                    end;
                end;
            FREInvoiceMessage.Type::Collected,
            FREInvoiceMessage.Type::"Negative Collected":
                begin
                    ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, CollectedStatusCodeTok));
                    ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, CollectedStatusNameTok));
                    if IsPPFMessage(FREInvoiceMessage) then
                        ReferenceElement.Add(
                            CreateTradeParty(
                                'IssuerTradeParty', FREInvoiceMessage."Invoice Issuer ID", FREInvoiceMessage."Invoice Issuer Scheme", '', ''));
                    AddVATBreakdown(ReferenceElement, FREInvoiceMessage);
                end;
            else
                RaiseInternalError(StrSubstNo(UnsupportedMessageTypeErr, FREInvoiceMessage.Type));
        end;
        AcknowledgementElement.Add(ReferenceElement);
        RootElement.Add(AcknowledgementElement);
        XmlDoc.Add(RootElement);
        FREInvoiceProfileValidator.Validate(XmlDoc, IsPPFMessage(FREInvoiceMessage));

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure AddExchangedDocumentContext(var RootElement: XmlElement; FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        BusinessProcessElement: XmlElement;
        ContextElement: XmlElement;
        GuidelineElement: XmlElement;
    begin
        ContextElement := XmlElement.Create('ExchangedDocumentContext', RsmNamespaceTok);
        if not IsPPFMessage(FREInvoiceMessage) then begin
            BusinessProcessElement := XmlElement.Create('BusinessProcessSpecifiedDocumentContextParameter', RamNamespaceTok);
            BusinessProcessElement.Add(XmlElement.Create('ID', RamNamespaceTok, RegulatedBusinessProcessTok));
            ContextElement.Add(BusinessProcessElement);
        end;
        GuidelineElement := XmlElement.Create('GuidelineSpecifiedDocumentContextParameter', RamNamespaceTok);
        GuidelineElement.Add(XmlElement.Create('ID', RamNamespaceTok, GetProfileID(FREInvoiceMessage)));
        ContextElement.Add(GuidelineElement);
        RootElement.Add(ContextElement);
    end;

    local procedure AddExchangedDocument(var RootElement: XmlElement; FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        ExchangedDocumentElement: XmlElement;
        IssueDateTimeElement: XmlElement;
    begin
        ExchangedDocumentElement := XmlElement.Create('ExchangedDocument', RsmNamespaceTok);
        ExchangedDocumentElement.Add(XmlElement.Create('ID', RamNamespaceTok, Format(FREInvoiceMessage."Source Occurrence ID")));
        ExchangedDocumentElement.Add(XmlElement.Create('Name', RamNamespaceTok, LifecycleMessageNameTok));
        IssueDateTimeElement := XmlElement.Create('IssueDateTime', RamNamespaceTok);
        IssueDateTimeElement.Add(CreateDateTimeString(FREInvoiceMessage."Created At"));
        ExchangedDocumentElement.Add(IssueDateTimeElement);
        if IsPPFMessage(FREInvoiceMessage) then begin
            ExchangedDocumentElement.Add(
                CreateTradeParty(
                    'SenderTradeParty', FREInvoiceMessage."Sender Platform ID", FREInvoiceMessage."Sender Platform Scheme",
                    FREInvoiceMessage."Sender Platform Name", SenderRoleCodeTok));
            ExchangedDocumentElement.Add(
                CreateTradeParty(
                    'IssuerTradeParty', FREInvoiceMessage."Invoice Issuer ID", FREInvoiceMessage."Invoice Issuer Scheme",
                    FREInvoiceMessage."Invoice Issuer Name", SellerRoleCodeTok));
            ExchangedDocumentElement.Add(
                CreateTradeParty('RecipientTradeParty', PPFIdentifierTok, PPFIdentifierSchemeTok, PPFNameTok, PPFRoleCodeTok));
        end;
        RootElement.Add(ExchangedDocumentElement);
    end;

    local procedure CreateIndicatorElement(ElementName: Text; Value: Boolean) IndicatorElement: XmlElement
    begin
        IndicatorElement := XmlElement.Create(ElementName, RamNamespaceTok);
        IndicatorElement.Add(XmlElement.Create('Indicator', UdtNamespaceTok, Format(Value, 0, 9).ToLower()));
    end;

    local procedure AddVATBreakdown(var ReferenceElement: XmlElement; FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        StatusElement: XmlElement;
        CurrencyCode: Code[10];
    begin
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        if not FREInvoiceMessageVAT.FindSet() then
            RaiseInternalError(StrSubstNo(VATBreakdownErr, FREInvoiceMessage."Entry No."));

        CurrencyCode := ResolveCurrencyCode(FREInvoiceMessage."Currency Code");
        StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
        repeat
            StatusElement.Add(CreateVATCharacteristic(FREInvoiceMessageVAT, CurrencyCode));
        until FREInvoiceMessageVAT.Next() = 0;
        ReferenceElement.Add(StatusElement);
    end;

    local procedure CreateVATCharacteristic(FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT"; CurrencyCode: Code[10]) CharacteristicElement: XmlElement
    var
        AmountElement: XmlElement;
        ValueChangedElement: XmlElement;
    begin
        CharacteristicElement := XmlElement.Create('SpecifiedDocumentCharacteristic', RamNamespaceTok);
        CharacteristicElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, CollectedAmountTypeCodeTok));
        ValueChangedElement := XmlElement.Create('ValueChangedIndicator', RamNamespaceTok);
        ValueChangedElement.Add(XmlElement.Create('IndicatorString', UdtNamespaceTok, 'false'));
        CharacteristicElement.Add(ValueChangedElement);
        AmountElement := XmlElement.Create('ValueAmount', RamNamespaceTok, Format(FREInvoiceMessageVAT.Amount, 0, 9));
        AmountElement.Add(XmlAttribute.Create('currencyID', CurrencyCode));
        CharacteristicElement.Add(AmountElement);
        CharacteristicElement.Add(XmlElement.Create('ValuePercent', RamNamespaceTok, Format(FREInvoiceMessageVAT."VAT %", 0, 9)));
    end;

    local procedure AddIssueDateTime(var AcknowledgementElement: XmlElement; EventDate: Date)
    var
        DateTimeStringElement: XmlElement;
        IssueDateTimeElement: XmlElement;
    begin
        IssueDateTimeElement := XmlElement.Create('IssueDateTime', RamNamespaceTok);
        DateTimeStringElement := XmlElement.Create('DateTimeString', UdtNamespaceTok, Format(EventDate, 0, '<Year4><Month,2><Day,2>000000'));
        DateTimeStringElement.Add(XmlAttribute.Create('format', DateTimeFormatCodeTok));
        IssueDateTimeElement.Add(DateTimeStringElement);
        AcknowledgementElement.Add(IssueDateTimeElement);
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

    local procedure IsPPFMessage(FREInvoiceMessage: Record "FR E-Invoice Message"): Boolean
    begin
        exit(FREInvoiceMessage."Sender Platform ID" <> '');
    end;

    local procedure GetProfileID(FREInvoiceMessage: Record "FR E-Invoice Message"): Text
    begin
        if IsPPFMessage(FREInvoiceMessage) then
            exit(PPFInvoiceProfileTok);
        exit(CDVInvoiceProfileTok);
    end;

    local procedure ValidatePPFContext(FREInvoiceMessage: Record "FR E-Invoice Message")
    begin
        FREInvoiceMessage.TestField("Invoice Issue Date");
        FREInvoiceMessage.TestField("Invoice Receipt At");
        FREInvoiceMessage.TestField("Sender Platform ID");
        FREInvoiceMessage.TestField("Sender Platform Scheme");
        FREInvoiceMessage.TestField("Sender Platform Name");
        FREInvoiceMessage.TestField("Invoice Issuer ID");
        FREInvoiceMessage.TestField("Invoice Issuer Scheme");
        FREInvoiceMessage.TestField("Invoice Issuer Name");
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

    local procedure RaiseInternalError(ErrorMessage: Text)
    var
        InternalErrorInfo: ErrorInfo;
    begin
        InternalErrorInfo.ErrorType := ErrorType::Internal;
        InternalErrorInfo.Message := ErrorMessage;
        InternalErrorInfo.DataClassification := DataClassification::SystemMetadata;
        Error(InternalErrorInfo);
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        QdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:QualifiedDataType:100', Locked = true;
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        RegulatedBusinessProcessTok: Label 'REGULATED', Locked = true;
        CDVInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:invoice', Locked = true;
        PPFInvoiceProfileTok: Label 'urn.cpro.gouv.fr:1p0:CDV:einvoicingF2', Locked = true;
        LifecycleMessageNameTok: Label 'Invoice lifecycle message', Locked = true;
        InformationTypeCodeTok: Label '23', Locked = true;
        DateTimeFormatCodeTok: Label '204', Locked = true;
        DateFormatCodeTok: Label '102', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        InvoiceTypeCodeTok: Label '380', Locked = true;
        CollectedStatusCodeTok: Label '212', Locked = true;
        CollectedStatusNameTok: Label 'Encaissée', Locked = true;
        CollectedAmountTypeCodeTok: Label 'MEN', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        AcceptedStatusCodeTok: Label '205', Locked = true;
        AcceptedStatusNameTok: Label 'Approuvée', Locked = true;
        SenderRoleCodeTok: Label 'WK', Locked = true;
        SellerRoleCodeTok: Label 'SE', Locked = true;
        PPFIdentifierTok: Label '9998', Locked = true;
        PPFIdentifierSchemeTok: Label '0238', Locked = true;
        PPFNameTok: Label 'PPF', Locked = true;
        PPFRoleCodeTok: Label 'DFH', Locked = true;
        VATBreakdownErr: Label 'French invoice message %1 does not have the VAT breakdown required for a collected status message.', Comment = '%1 = French invoice message entry number';
        UnsupportedMessageTypeErr: Label 'French invoice lifecycle message type %1 cannot be sent.', Comment = '%1 = French invoice lifecycle message type';
}