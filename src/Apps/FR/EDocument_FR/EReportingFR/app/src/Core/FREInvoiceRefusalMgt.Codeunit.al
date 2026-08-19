// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10988 "FR E-Invoice Refusal Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure RefuseInvoice(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500]): Integer
    var
        FREInvoiceRefusal: Record "FR E-Invoice Refusal";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
    begin
        ValidateRefusal(EDocument, ReasonCode, ReasonDescription);

        BuildRefusalMessage(EDocument, ReasonCode, ReasonDescription, TempBlob);
        FREInvoiceRefusal.Init();
        FREInvoiceRefusal."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceRefusal."Reason Code" := ReasonCode;
        FREInvoiceRefusal."Reason Description" := ReasonDescription;
        FREInvoiceRefusal."Created At" := CurrentDateTime();
        FREInvoiceRefusal."E-Document Message Entry No." := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", EDocument.Direction::Outgoing,
            "E-Doc. Response Type"::Refused, EDocument.Service, TempBlob);
        FREInvoiceRefusal.Status := FREInvoiceRefusal.Status::Created;
        FREInvoiceRefusal.Insert();

        EDocumentMessageAPI.SendMessage(FREInvoiceRefusal."E-Document Message Entry No.");
        FREInvoiceRefusal.Status := EDocumentMessageAPI.GetMessageStatus(FREInvoiceRefusal."E-Document Message Entry No.");
        FREInvoiceRefusal.Modify();
        exit(FREInvoiceRefusal."E-Document Message Entry No.");
    end;

    internal procedure GetRefusalResponse(EDocument: Record "E-Document")
    var
        FREInvoiceRefusal: Record "FR E-Invoice Refusal";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        FREInvoiceRefusal.Get(EDocument."Entry No");
        FREInvoiceRefusal.TestField(Status, FREInvoiceRefusal.Status::"Pending Response");
        EDocumentMessageAPI.GetMessageResponse(FREInvoiceRefusal."E-Document Message Entry No.");
        FREInvoiceRefusal.Status := EDocumentMessageAPI.GetMessageStatus(FREInvoiceRefusal."E-Document Message Entry No.");
        FREInvoiceRefusal.Modify();
    end;

    internal procedure BuildRefusalMessage(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500]; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        AcknowledgementElement: XmlElement;
        ReferenceElement: XmlElement;
        StatusElement: XmlElement;
        OutStream: OutStream;
    begin
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
        ReferenceElement.Add(XmlElement.Create('ProcessConditionCode', RamNamespaceTok, RefusedStatusCodeTok));
        ReferenceElement.Add(XmlElement.Create('ProcessCondition', RamNamespaceTok, RefusedStatusNameTok));
        StatusElement := XmlElement.Create('SpecifiedDocumentStatus', RamNamespaceTok);
        StatusElement.Add(XmlElement.Create('ReasonCode', RamNamespaceTok, ReasonCode));
        StatusElement.Add(XmlElement.Create('Reason', RamNamespaceTok, ReasonDescription));
        ReferenceElement.Add(StatusElement);
        AcknowledgementElement.Add(ReferenceElement);
        RootElement.Add(AcknowledgementElement);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure ValidateRefusal(EDocument: Record "E-Document"; ReasonCode: Code[20]; ReasonDescription: Text[500])
    var
        FREInvoiceRefusal: Record "FR E-Invoice Refusal";
    begin
        EDocument.TestField(Direction, EDocument.Direction::Incoming);
        EDocument.TestField("Document Type", EDocument."Document Type"::"Purchase Invoice");
        EDocument.TestField(Service);
        if ReasonCode = '' then
            Error(ReasonCodeRequiredErr);
        if ReasonDescription = '' then
            Error(ReasonDescriptionRequiredErr);
        if FREInvoiceRefusal.Get(EDocument."Entry No") then
            Error(AlreadyRefusedErr, EDocument."Document No.");
    end;

    var
        RsmNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100', Locked = true;
        RamNamespaceTok: Label 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100', Locked = true;
        InvoiceReferenceStatusCodeTok: Label '47', Locked = true;
        RefusedStatusCodeTok: Label '210', Locked = true;
        RefusedStatusNameTok: Label 'Refusée', Locked = true;
        ReasonCodeRequiredErr: Label 'A refusal reason code is required.';
        ReasonDescriptionRequiredErr: Label 'A refusal reason description is required.';
        AlreadyRefusedErr: Label 'Invoice %1 has already been refused.', Comment = '%1 = invoice number';
}