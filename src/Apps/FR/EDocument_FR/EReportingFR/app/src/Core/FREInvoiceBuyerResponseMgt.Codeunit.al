// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10988 "FR E-Inv. Buyer Resp. Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure AcceptInvoice(EDocument: Record "E-Document"): Integer
    begin
        exit(SendResponse(EDocument, "E-Doc. Response Type"::Accepted, '', ''));
    end;

    internal procedure RefuseInvoice(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500]): Integer
    begin
        if ReasonCode = '' then
            Error(ReasonCodeRequiredErr);
        if ReasonDescription = '' then
            Error(ReasonDescriptionRequiredErr);
        exit(SendResponse(EDocument, "E-Doc. Response Type"::Refused, ReasonCode, ReasonDescription));
    end;

    local procedure SendResponse(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; ReasonCode: Code[20]; ReasonDescription: Text[500]): Integer
    var
        FREInvoiceBuyerResponse: Record "FR E-Invoice Buyer Response";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
    begin
        ValidateResponse(EDocument);

        BuildResponseMessage(EDocument, ResponseType, ReasonCode, ReasonDescription, TempBlob);
        FREInvoiceBuyerResponse.Init();
        FREInvoiceBuyerResponse."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceBuyerResponse."Reason Code" := ReasonCode;
        FREInvoiceBuyerResponse."Reason Description" := ReasonDescription;
        FREInvoiceBuyerResponse."Response Type" := ResponseType;
        FREInvoiceBuyerResponse."Created At" := CurrentDateTime();
        FREInvoiceBuyerResponse."E-Document Message Entry No." := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", EDocument.Direction::Outgoing,
            ResponseType, EDocument.Service, TempBlob);
        FREInvoiceBuyerResponse.Status := FREInvoiceBuyerResponse.Status::Created;
        FREInvoiceBuyerResponse.Insert();

        EDocumentMessageAPI.SendMessage(FREInvoiceBuyerResponse."E-Document Message Entry No.");
        FREInvoiceBuyerResponse.Status := EDocumentMessageAPI.GetMessageStatus(FREInvoiceBuyerResponse."E-Document Message Entry No.");
        FREInvoiceBuyerResponse.Modify();
        exit(FREInvoiceBuyerResponse."E-Document Message Entry No.");
    end;

    internal procedure GetResponse(EDocument: Record "E-Document")
    var
        FREInvoiceBuyerResponse: Record "FR E-Invoice Buyer Response";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        FREInvoiceBuyerResponse.Get(EDocument."Entry No");
        FREInvoiceBuyerResponse.TestField(Status, FREInvoiceBuyerResponse.Status::"Pending Response");
        EDocumentMessageAPI.GetMessageResponse(FREInvoiceBuyerResponse."E-Document Message Entry No.");
        FREInvoiceBuyerResponse.Status := EDocumentMessageAPI.GetMessageStatus(FREInvoiceBuyerResponse."E-Document Message Entry No.");
        FREInvoiceBuyerResponse.Modify();
    end;

    internal procedure BuildResponseMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; ReasonCode: Code[20]; ReasonDescription: Text[500]; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        AcknowledgementElement: XmlElement;
        ReferenceElement: XmlElement;
        StatusElement: XmlElement;
        OutStream: OutStream;
        StatusCode: Text;
        StatusName: Text;
    begin
        case ResponseType of
            ResponseType::Accepted:
                begin
                    StatusCode := AcceptedStatusCodeTok;
                    StatusName := AcceptedStatusNameTok;
                end;
            ResponseType::Refused:
                begin
                    StatusCode := RefusedStatusCodeTok;
                    StatusName := RefusedStatusNameTok;
                end;
            else
                Error(UnsupportedResponseTypeErr, ResponseType);
        end;

        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := XmlElement.Create('CrossDomainAcknowledgementAndResponse', RsmNamespaceTok);
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('ram', RamNamespaceTok));
        RootElement.Add(XmlAttribute.CreateNamespaceDeclaration('rsm', RsmNamespaceTok));
        RootElement.Add(XmlElement.Create('ExchangedDocument', RsmNamespaceTok,
            XmlElement.Create('ID', RamNamespaceTok, Format(CreateGuid()))));

        AcknowledgementElement := XmlElement.Create('AcknowledgementDocument', RsmNamespaceTok);
        ReferenceElement := XmlElement.Create('ReferenceReferencedDocument', RamNamespaceTok);
        ReferenceElement.Add(XmlElement.Create('IssuerAssignedID', RamNamespaceTok, EDocument."Document No."));
        ReferenceElement.Add(XmlElement.Create('StatusCode', RamNamespaceTok, InvoiceReferenceStatusCodeTok));
        ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, StatusCode));
        ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, StatusName));
        if ResponseType = ResponseType::Refused then begin
            StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
            StatusElement.Add(XmlElement.Create('ReasonCode', RamNamespaceTok, ReasonCode));
            StatusElement.Add(XmlElement.Create('Reason', RamNamespaceTok, ReasonDescription));
            ReferenceElement.Add(StatusElement);
        end;
        AcknowledgementElement.Add(ReferenceElement);
        RootElement.Add(AcknowledgementElement);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure ValidateResponse(EDocument: Record "E-Document")
    var
        FREInvoiceBuyerResponse: Record "FR E-Invoice Buyer Response";
    begin
        EDocument.TestField(Direction, EDocument.Direction::Incoming);
        EDocument.TestField("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.TestField(Service);
        if FREInvoiceBuyerResponse.Get(EDocument."Entry No") then
            Error(AlreadyRespondedErr, EDocument."Document No.");
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        AcceptedStatusCodeTok: Label '212', Locked = true;
        AcceptedStatusNameTok: Label 'Acceptée', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        ReasonCodeRequiredErr: Label 'A refusal reason code is required.';
        ReasonDescriptionRequiredErr: Label 'A refusal reason description is required.';
        AlreadyRespondedErr: Label 'Invoice %1 already has a buyer response.', Comment = '%1 = invoice number';
        UnsupportedResponseTypeErr: Label 'Buyer response type %1 is not supported.', Comment = '%1 = response type';
}