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
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        AcknowledgementElement: XmlElement;
        ReferenceElement: XmlElement;
        StatusElement: XmlElement;
        AmountElement: XmlElement;
        OutStream: OutStream;
    begin
        FREInvoiceMessage.TestField("Event Date");
        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := XmlElement.Create('CrossDomainAcknowledgementAndResponse', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('rsm', RsmNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('udt', UdtNamespaceTok));
        RootElement.Add(XmlElement.Create('ExchangedDocument', RsmNamespaceTok,
            XmlElement.Create('ID', RamNamespaceTok, Format(FREInvoiceMessage."Source Occurrence ID"))));

        AcknowledgementElement := XmlElement.Create('AcknowledgementDocument', RsmNamespaceTok);
        AddIssueDateTime(AcknowledgementElement, FREInvoiceMessage."Event Date");
        ReferenceElement := XmlElement.Create('ReferenceReferencedDocument', RamNamespaceTok);
        ReferenceElement.Add(XmlElement.Create('IssuerAssignedID', RamNamespaceTok, EDocument."Document No."));
        ReferenceElement.Add(XmlElement.Create('StatusCode', RamNamespaceTok, InvoiceReferenceStatusCodeTok));
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
                    StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
                    StatusElement.Add(XmlElement.Create('ReasonCode', RamNamespaceTok, FREInvoiceMessage."Reason Code"));
                    StatusElement.Add(XmlElement.Create('Reason', RamNamespaceTok, FREInvoiceMessage."Reason Description"));
                    ReferenceElement.Add(StatusElement);
                end;
            FREInvoiceMessage.Type::Collected,
            FREInvoiceMessage.Type::"Negative Collected":
                begin
                    ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, CollectedStatusCodeTok));
                    ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, CollectedStatusNameTok));
                    StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
                    StatusElement.Add(XmlElement.Create('TypeCode', RamNamespaceTok, CollectedAmountTypeCodeTok));
                    AmountElement := XmlElement.Create('ValueAmount', RamNamespaceTok, Format(FREInvoiceMessage.Amount, 0, 9));
                    AmountElement.Add(XmlAttribute.Create('currencyID', ResolveCurrencyCode(FREInvoiceMessage."Currency Code")));
                    StatusElement.Add(AmountElement);
                    ReferenceElement.Add(StatusElement);
                end;
            else
                Error(UnsupportedMessageTypeErr, FREInvoiceMessage.Type);
        end;
        AcknowledgementElement.Add(ReferenceElement);
        RootElement.Add(AcknowledgementElement);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
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
        UdtNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100', Locked = true;
        DateTimeFormatCodeTok: Label '204', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        CollectedStatusCodeTok: Label '212', Locked = true;
        CollectedStatusNameTok: Label 'Encaissée', Locked = true;
        CollectedAmountTypeCodeTok: Label 'MEN', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        AcceptedStatusCodeTok: Label '205', Locked = true;
        AcceptedStatusNameTok: Label 'Approuvée', Locked = true;
        UnsupportedMessageTypeErr: Label 'French invoice lifecycle message type %1 cannot be sent.', Comment = '%1 = French invoice lifecycle message type';
}