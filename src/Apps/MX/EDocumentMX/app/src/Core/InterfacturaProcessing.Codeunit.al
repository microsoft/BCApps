// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Sales.History;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Security.Encryption;
using System.Utilities;

codeunit 3355 "Interfactura Processing"
{
    Access = Internal;

    var
        InterfacturaSetup: Record "MX Connection Setup";
        ConnectionSetupErr: Label 'You must enable Interfactura Setup.';
        BatchSoapRequestMsg: Label 'Sending batch soap request of type %1', Locked = true;
        NoResponseErr: Label 'Remote service did not provide a response. Open Interfactura Setup page and make sure that the Document Registration Endpoint and the certificate are correctly specified and try again.';
        NoResponseTelemetryErr: Label 'Could not get response.', Locked = true;
        CommunicationErr: Label 'Remote service returned an unexpected response: %1.', Comment = '%1 is the error message.';
        BatchSoapRequestSuccMsg: Label 'Batch soap request of type %1 successfully executed', Locked = true;
        FeatureNameTxt: Label 'Interfactura Document Registration';
        EmptyRequestLbl: Label 'The request is empty.';
        ParseErr: Label 'Failed to parse document from Interfactura API';
        MissingPACWebServiceDetailErr: Label 'PAC Web Service Detail for %1 is missing or incomplete.';
        MissingStampedDataErr: Label 'No stamped CFDI data was found for this document. Cancellation requires a stamped UUID.';
        InvalidStatusForCancellationErr: Label 'The document cannot be cancelled because it has status %1.', Comment = '%1 = current service status';
        MissingCancelRequestErr: Label 'The cancellation request could not be generated.';
        CFDIServiceNameTxt: Label 'CFDI', Locked = true;
        StampRequestedMsg: Label 'Sending stamp request for E-Document %1.', Locked = true;
        StampSuccessMsg: Label 'Stamp request successful for E-Document %1.', Locked = true;
        StampFailedMsg: Label 'Stamp request failed for E-Document %1: %2', Locked = true;
        CancelRequestedMsg: Label 'Cancellation request submitted for E-Document %1.', Locked = true;
        CancelSuccessMsg: Label 'Cancellation succeeded for E-Document %1.', Locked = true;
        PaymentStampRequestedMsg: Label 'Sending payment complement stamp request.', Locked = true;
        PaymentStampSuccessMsg: Label 'Payment complement stamp request successful.', Locked = true;
        PaymentStampFailedMsg: Label 'Payment complement stamp request failed: %1', Locked = true;
        SecurityAuditPACRejectedTxt: Label 'PAC rejected CFDI stamp request for E-Document %1: %2', Locked = true, Comment = '%1 - E-Document entry no, %2 - PAC error';
        SecurityAuditCancelRequestedTxt: Label 'CFDI cancellation request submitted for E-Document %1.', Locked = true, Comment = '%1 - E-Document entry no';


    procedure SendEDocument(var TempBlob: Codeunit "Temp Blob"; var EDocument: Record "E-Document"; var SendContext: Codeunit SendContext)
    var
        ErrorText, RequestTxt : Text;
        RequestType: Option "Request Stamp",Cancel,CancelRequest;
    begin
        RequestTxt := GetRequestText(TempBlob);

        if RequestTxt = '' then begin
            ErrorText := EmptyRequestLbl;
            exit;
        end;
        RequestType := RequestType::"Request Stamp";
        Session.LogMessage('0000QX4', StrSubstNo(StampRequestedMsg, EDocument."Entry No"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        if not InvokeSoapRequest(EDocument, RequestTxt, RequestType, ErrorText, SendContext) then
            Error(ErrorText);

        Session.LogMessage('0000QX5', StrSubstNo(StampSuccessMsg, EDocument."Entry No"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        TryProcessAdvanceReverseAfterSettle(EDocument);

    end;

    internal procedure SendPaymentComplement(var TempBlob: Codeunit "Temp Blob"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestTxt: Text;
        ResponseTxt: Text;
        ErrorText: Text;
        RequestType: Option "Request Stamp",Cancel,CancelRequest;
    begin
        RequestTxt := GetRequestText(TempBlob);
        if RequestTxt = '' then
            Error(EmptyRequestLbl);
        RequestType := RequestType::"Request Stamp";
        Session.LogMessage('0000QX6', PaymentStampRequestedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        if not InvokeSoapRequestCore(RequestTxt, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            Session.LogMessage('0000QX7', StrSubstNo(PaymentStampFailedMsg, ErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            Error(ErrorText);
        end;
        MessageContext.Http().SetHttpRequestMessage(HttpRequest);
        MessageContext.Http().SetHttpResponseMessage(HttpResponse);
        if GetResultCodeFromResponse(ResponseTxt) <> '1' then begin
            ErrorText := GetResponseErrorText(ResponseTxt);
            Session.LogMessage('0000QX7', StrSubstNo(PaymentStampFailedMsg, ErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            Error(ErrorText);
        end;
        Session.LogMessage('0000QX8', PaymentStampSuccessMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
    end;

    local procedure TryProcessAdvanceReverseAfterSettle(var EDocument: Record "E-Document")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CFDIDocuments: Record "CFDI Documents";
        ExportInterfacturaMX: Codeunit "Export Interfactura MX";
        RequestType: Option "Request Stamp",Cancel,CancelRequest;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        AdvanceUUID: Text[50];
        ReverseSignedXmlTxt: Text;
        ResponseTxt: Text;
        ErrorText: Text;
        ResultCode: Text;
    begin
        if not IsAdvanceSettleSalesInvoice(EDocument, SalesInvoiceHeader) then
            exit;

        if EDocument."Clearance Date" = 0DT then
            exit;

        AdvanceUUID := FindPrepaymentUUID(SalesInvoiceHeader);
        if AdvanceUUID = '' then
            exit;

        if not EnsureAdvanceReverseDocument(CFDIDocuments, SalesInvoiceHeader, AdvanceUUID) then
            exit;

        if CFDIDocuments."Electronic Document Sent" then
            exit;

        if not ExportInterfacturaMX.CreateAdvanceReverseSignedXML(SalesInvoiceHeader, AdvanceUUID, ReverseSignedXmlTxt) then
            exit;

        SaveTextBlobToCFDIDocuments(CFDIDocuments, CFDIDocuments.FieldNo("Signed Document XML"), ReverseSignedXmlTxt);

        RequestType := RequestType::"Request Stamp";
        if not InvokeSoapRequestCore(ReverseSignedXmlTxt, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            if ErrorText <> '' then begin
                CFDIDocuments."Error Description" := CopyStr(ErrorText, 1, MaxStrLen(CFDIDocuments."Error Description"));
                CFDIDocuments.Modify();
            end;
            exit;
        end;

        ResultCode := GetResultCodeFromResponse(ResponseTxt);
        if ResultCode <> '1' then begin
            if ErrorText = '' then
                ErrorText := GetResponseErrorText(ResponseTxt);
            CFDIDocuments."Error Description" := CopyStr(ErrorText, 1, MaxStrLen(CFDIDocuments."Error Description"));
            CFDIDocuments.Modify();
            exit;
        end;

        SaveTextBlobToCFDIDocuments(CFDIDocuments, CFDIDocuments.FieldNo("Original Document XML"), ResponseTxt);
        CFDIDocuments."No. of E-Documents Sent" += 1;
        CFDIDocuments."Electronic Document Sent" := true;
        CFDIDocuments."Date/Time Sent" := Format(CurrentDateTime(), 0, 9);
        CFDIDocuments."Date/Time Stamp Received" := CurrentDateTime();
        if TryGetStampedUUIDFromResponse(ResponseTxt, AdvanceUUID) then
            CFDIDocuments."Fiscal Invoice Number PAC" := AdvanceUUID;
        CFDIDocuments.Modify();
    end;

    local procedure IsAdvanceSettleSalesInvoice(EDocument: Record "E-Document"; var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if EDocument."Document Record ID".TableNo <> Database::"Sales Invoice Header" then
            exit(false);

        if not SalesInvoiceHeader.Get(EDocument."Document Record ID") then
            exit(false);

        if SalesInvoiceHeader."Prepayment Invoice" then
            exit(false);

        if SalesInvoiceHeader."Prepayment Order No." = '' then
            exit(false);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("Prepayment Line", true);
        exit(not SalesInvoiceLine.IsEmpty());
    end;

    local procedure FindPrepaymentUUID(SalesInvoiceHeader: Record "Sales Invoice Header"): Text[50]
    var
        PrepaymentInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader."Prepayment Order No." = '' then
            exit('');

        PrepaymentInvoiceHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        PrepaymentInvoiceHeader.SetRange("Prepayment Order No.", SalesInvoiceHeader."Prepayment Order No.");
        PrepaymentInvoiceHeader.SetRange("Prepayment Invoice", true);
        PrepaymentInvoiceHeader.SetFilter("Fiscal Invoice Number PAC", '<>%1', '');
        if not PrepaymentInvoiceHeader.FindLast() then
            exit('');

        exit(CopyStr(PrepaymentInvoiceHeader."Fiscal Invoice Number PAC", 1, 50));
    end;

    local procedure EnsureAdvanceReverseDocument(var CFDIDocuments: Record "CFDI Documents"; SalesInvoiceHeader: Record "Sales Invoice Header"; AdvanceUUID: Text[50]): Boolean
    begin
        if CFDIDocuments.Get(SalesInvoiceHeader."No.", Database::"Sales Invoice Header", true, true) then
            exit(true);

        CFDIDocuments.Init();
        CFDIDocuments."No." := SalesInvoiceHeader."No.";
        CFDIDocuments."Document Table ID" := Database::"Sales Invoice Header";
        CFDIDocuments.Prepayment := true;
        CFDIDocuments.Reversal := true;
        CFDIDocuments."Date/Time First Req. Sent" := Format(CurrentDateTime(), 0, 9);
        CFDIDocuments."Fiscal Invoice Number PAC" := AdvanceUUID;
        CFDIDocuments.Insert();
        exit(true);
    end;

    local procedure SaveTextBlobToCFDIDocuments(var CFDIDocuments: Record "CFDI Documents"; FieldNo: Integer; BlobText: Text)
    var
        RecRef: RecordRef;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BlobText);

        RecRef.GetTable(CFDIDocuments);
        TempBlob.ToRecordRef(RecRef, FieldNo);
        RecRef.SetTable(CFDIDocuments);
        CFDIDocuments.Modify();
    end;

    local procedure GetResultCodeFromResponse(ResponseText: Text): Text
    var
        XmlDoc: XmlDocument;
        ResultNode: XmlNode;
    begin
        if not TryReadXml(ResponseText, XmlDoc) then
            exit('');
        if not TryGetResultNode(XmlDoc, ResultNode) then
            exit('');
        exit(GetXmlAttribute(ResultNode, 'IdRespuesta'));
    end;

    local procedure GetResponseErrorText(ResponseText: Text): Text
    var
        XmlDoc: XmlDocument;
        ResultNode: XmlNode;
        Description: Text;
        Detail: Text;
    begin
        if not TryReadXml(ResponseText, XmlDoc) then
            exit('');
        if not TryGetResultNode(XmlDoc, ResultNode) then
            exit('');

        Description := GetXmlAttribute(ResultNode, 'Descripcion');
        Detail := GetXmlAttribute(ResultNode, 'Detalle');
        if (Description <> '') and (Detail <> '') then
            exit(Description + ': ' + Detail);
        if Description <> '' then
            exit(Description);
        exit(Detail);
    end;

    local procedure TryGetStampedUUIDFromResponse(ResponseText: Text; var UUID: Text[50]): Boolean
    var
        XmlDoc: XmlDocument;
        WrappedXmlDoc: XmlDocument;
        ResultNode: XmlNode;
        WrappedXmlText: Text;
        NamespaceManager: XmlNamespaceManager;
        TimbreNode: XmlNode;
    begin
        UUID := '';
        if not TryReadXml(ResponseText, XmlDoc) then
            exit(false);
        if not TryGetResultNode(XmlDoc, ResultNode) then
            exit(false);

        WrappedXmlText := '<root>' + ResultNode.AsXmlElement().InnerXml() + '</root>';
        if not TryReadXml(WrappedXmlText, WrappedXmlDoc) then
            exit(false);

        NamespaceManager.NameTable(WrappedXmlDoc.NameTable());
        NamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        NamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');

        if not WrappedXmlDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', NamespaceManager, TimbreNode) then
            exit(false);

        UUID := CopyStr(GetXmlAttribute(TimbreNode, 'UUID'), 1, MaxStrLen(UUID));
        exit(UUID <> '');
    end;

    internal procedure InvokeSoapRequest(var EDocument: Record "E-Document"; RequestText: Text; RequestType: Option "Request Stamp",Cancel,CancelRequest; var ErrorText: Text; var SendContext: Codeunit SendContext): Boolean
    var
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        ResponseTxt: Text;
    begin
        HttpRequest := SendContext.Http().GetHttpRequestMessage();
        if not InvokeSoapRequestCore(RequestText, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            SendContext.Http().SetHttpRequestMessage(HttpRequest);
            SendContext.Http().SetHttpResponseMessage(HttpResponse);
            exit(false);
        end;

        SendContext.Http().SetHttpRequestMessage(HttpRequest);
        SendContext.Http().SetHttpResponseMessage(HttpResponse);

        if not ParseResponse(EDocument, ResponseTxt, SendContext, ErrorText) then
            exit(false);
        exit(true);
    end;

    local procedure InvokeSoapRequestCore(RequestText: Text; RequestType: Option "Request Stamp",Cancel,CancelRequest; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var ResponseTxt: Text; var ErrorText: Text): Boolean
    var
        EInvoiceCommunication: Codeunit "EInvoice Communication";
        CertificateManagement: Codeunit "Certificate Management";
        IsolatedCertificate: Record "Isolated Certificate";
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
        WebServiceUrl: Text;
        CertBase64: Text;
        CertPassword: SecretText;
    begin
        if not InterfacturaSetup.Get() then begin
            ErrorText := ConnectionSetupErr;
            exit(false);
        end;

        if not InterfacturaSetup.Enabled then begin
            ErrorText := ConnectionSetupErr;
            exit(false);
        end;

        if not MXPACWebServiceDetail.Get(InterfacturaSetup.Id, RequestType) then begin
            ErrorText := StrSubstNo(MissingPACWebServiceDetailErr, Format(RequestType));
            exit(false);
        end;

        MXPACWebServiceDetail.TestField(Address);
        MXPACWebServiceDetail.TestField("Method Name");

        WebServiceUrl := MXPACWebServiceDetail.Address;
        Session.LogMessage('0000QWW', StrSubstNo(BatchSoapRequestMsg, Format(RequestType)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);

        Commit();

        InterfacturaSetup.TestField("PAC Certificate");
        if not IsolatedCertificate.Get(InterfacturaSetup."PAC Certificate") then begin
            ErrorText := StrSubstNo(CommunicationErr, StrSubstNo('PAC certificate %1 not found.', InterfacturaSetup."PAC Certificate"));
            exit(false);
        end;

        CertBase64 := CertificateManagement.GetCertAsBase64String(IsolatedCertificate);
        CertPassword := CertificateManagement.GetPasswordAsSecret(IsolatedCertificate);
        if CertBase64 = '' then begin
            ErrorText := StrSubstNo(CommunicationErr, 'PAC certificate is empty.');
            exit(false);
        end;

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(WebServiceUrl);

        EInvoiceCommunication.AddParameters(RequestText);
        if RequestType = RequestType::"Request Stamp" then
            EInvoiceCommunication.AddParameters(false);

        ResponseTxt := EInvoiceCommunication.InvokeMethodWithCertificate(
            WebServiceUrl,
            MXPACWebServiceDetail."Method Name",
            CertBase64,
            CertPassword);

        HttpRequest.Content.WriteFrom(RequestText);
        HttpResponse.Content.WriteFrom(ResponseTxt);

        if ResponseTxt = '' then begin
            Session.LogMessage('0000QWY', NoResponseTelemetryErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            ErrorText := NoResponseErr;
            exit(false);
        end;

        Session.LogMessage('0000QX0', StrSubstNo(BatchSoapRequestSuccMsg, Format(RequestType)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        exit(true);
    end;

    procedure ParseResponse(var EDocument: Record "E-Document"; var ResponseText: Text; var SendContext: Codeunit SendContext; var ErrorText: Text): Boolean
    var
        XmlDoc: XmlDocument;
        ResultNode: XmlNode;
        ResultCode, Description, Detail, StampedXml : Text;
        ClearanceDateTime: DateTime;
    begin
        if ResponseText = '' then begin
            Session.LogMessage('0000QX1', EmptyRequestLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            exit(false);
        end;

        if not TryReadXml(ResponseText, XmlDoc) then begin
            ErrorText := ParseErr;
            exit(false);
        end;

        if not TryGetResultNode(XmlDoc, ResultNode) then begin
            ErrorText := ParseErr;
            exit(false);
        end;

        ResultCode := GetXmlAttribute(ResultNode, 'IdRespuesta');
        if ResultCode <> '1' then begin
            Description := GetXmlAttribute(ResultNode, 'Descripcion');
            Detail := GetXmlAttribute(ResultNode, 'Detalle');
            ErrorText := Description;
            if (ErrorText <> '') and (Detail <> '') then
                ErrorText += ': ' + Detail;
            if ErrorText = '' then
                ErrorText := Detail;
            if ErrorText = '' then
                ErrorText := StrSubstNo(CommunicationErr, ResultCode);
        end else begin
            StampedXml := '<root>' + ResultNode.AsXmlElement().InnerXml() + '</root>';
            if not TryGetStampedDateTime(StampedXml, ClearanceDateTime) then
                ClearanceDateTime := CurrentDateTime();

            SaveStampedCFDI(EDocument, StampedXml);
        end;

        if ErrorText <> '' then begin
            Session.LogMessage('0000QX3', StrSubstNo(StampFailedMsg, EDocument."Entry No", ErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            Session.LogSecurityAudit(CFDIServiceNameTxt, SecurityOperationResult::Failure, StrSubstNo(SecurityAuditPACRejectedTxt, EDocument."Entry No", ErrorText), AuditCategory::CustomerFacing);
        end;

        UpdateEdocument(EDocument, ResultCode = '1', ClearanceDateTime, SendContext, ErrorText);
        exit(ErrorText = '');
    end;

    [TryFunction]
    local procedure TryReadXml(XmlText: Text; var XmlDoc: XmlDocument)
    begin
        XmlDocument.ReadFrom(XmlText, XmlDoc);
    end;

    local procedure TryGetResultNode(XmlDoc: XmlDocument; var ResultNode: XmlNode): Boolean
    begin
        exit(XmlDoc.SelectSingleNode('Resultado', ResultNode));
    end;

    local procedure GetXmlAttribute(Node: XmlNode; AttributeName: Text): Text
    var
        Attributes: XmlAttributeCollection;
        Attribute: XmlAttribute;
    begin
        if not Node.IsXmlElement() then
            exit('');

        Attributes := Node.AsXmlElement().Attributes();
        if not Attributes.Get(AttributeName, Attribute) then
            exit('');

        exit(Attribute.Value());
    end;

    local procedure TryGetStampedDateTime(StampedXml: Text; var StampedDateTime: DateTime): Boolean
    var
        XmlDoc: XmlDocument;
        XmlNamespaceManager: XmlNamespaceManager;
        TimbreNode: XmlNode;
        StampedDateTimeTxt: Text;
    begin
        if not TryReadXml(StampedXml, XmlDoc) then
            exit(false);

        XmlNamespaceManager.NameTable(XmlDoc.NameTable());
        XmlNamespaceManager.AddNamespace('cfdi', 'http://www.sat.gob.mx/cfd/4');
        XmlNamespaceManager.AddNamespace('tfd', 'http://www.sat.gob.mx/TimbreFiscalDigital');

        if not XmlDoc.SelectSingleNode('cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital', XmlNamespaceManager, TimbreNode) then
            exit(false);

        StampedDateTimeTxt := GetXmlAttribute(TimbreNode, 'FechaTimbrado');
        exit(Evaluate(StampedDateTime, StampedDateTimeTxt, 9));
    end;

    procedure SaveStampedCFDI(var EDocument: Record "E-Document"; StampedXml: Text)
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
        OutStream: OutStream;
    begin
        if EDocument."Structured Data Entry No." <> 0 then
            EDocDataStorage.Get(EDocument."Structured Data Entry No.")
        else begin
            EDocDataStorage.Init();
            EDocDataStorage.Insert(true);
            EDocument."Structured Data Entry No." := EDocDataStorage."Entry No.";
        end;

        EDocDataStorage.Name := 'StampedCFDI.xml';
        EDocDataStorage."File Format" := EDocDataStorage."File Format"::XML;
        Clear(EDocDataStorage."Data Storage");
        EDocDataStorage."Data Storage".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(StampedXml);
        EDocDataStorage.Modify();

        CFDIWriteBackMX.CreateQRCodeForEDocument(EDocument, StampedXml);
    end;

    local procedure GetRequestText(var TempBlob: Codeunit "Temp Blob") RequestTxt: Text
    var
        FileInStream: InStream;
        RequestLineTxt: Text;
    begin
        TempBlob.CreateInStream(FileInStream, TextEncoding::UTF8);
        while not FileInStream.EOS do begin
            FileInStream.ReadText(RequestLineTxt);
            RequestTxt += RequestLineTxt;
        end;
        exit(RequestTxt);
    end;

    procedure UpdateEdocument(var EDocument: Record "E-Document"; IsCleared: Boolean; ClearanceDateTime: DateTime; var SendContext: Codeunit SendContext; ErrorText: Text)
    var
        EDocumentLogHelper: Codeunit "E-Document Log Helper";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        EDocumentServiceStatus: Enum "E-Document Service Status";
    begin
        EDocument."Last Clearance Request Time" := CurrentDateTime();
        EDocument."Clearance Date" := ClearanceDateTime;
        EDocument.Modify();

        if IsCleared then
            EDocumentServiceStatus := "E-Document Service Status"::Cleared
        else
            EDocumentServiceStatus := "E-Document Service Status"::"Not Cleared";

        SendContext.Status().SetStatus(EDocumentServiceStatus);
        EDocumentLogHelper.InsertLog(EDocument, EDocument.GetEDocumentService(), EDocumentServiceStatus);
        if ErrorText <> '' then
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, ErrorText);
    end;

    procedure GetDocumentResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    begin
        exit(CheckIfDocumentStatusSuccessful(EDocument, EDocumentService, HttpRequest, HttpResponse));
    end;

    local procedure CheckIfDocumentStatusSuccessful(EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var HttpRequestMessage: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        if EDocument."Clearance Date" <> 0DT then
            exit(true);

        if EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code) then
            if EDocumentServiceStatus.Status = EDocumentServiceStatus.Status::Cleared then
                exit(true);

        exit(false);
    end;

    procedure GetDocumentApproval(EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage; var Status: Enum "E-Document Service Status"): Boolean
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
    begin
        if not EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code) then begin
            Status := Enum::"E-Document Service Status"::"Pending Response";
            exit(false);
        end;

        Status := EDocumentServiceStatus.Status;
        exit(false);
    end;

    procedure CancelEDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var Status: Enum "E-Document Service Status"): Boolean
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        TempBlob: Codeunit "Temp Blob";
        RequestType: Option "Request Stamp",Cancel;
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        RequestTxt, ResponseTxt, ErrorText : Text;
        UUID, DateTimeStampedTxt, SubstitutionUUID : Text[50];
        CancellationReasonCode: Code[10];
        CancelDateTimeTxt: Text[50];
    begin
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);

        if not IsStatusValidForCancellation(EDocumentServiceStatus.Status) then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(InvalidStatusForCancellationErr, EDocumentServiceStatus.Status));
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        if not GetStampedCFDIData(EDocument, UUID, DateTimeStampedTxt) then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingStampedDataErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        if not ConfirmCancellationReason(CancellationReasonCode, SubstitutionUUID) then begin
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;
        CancelDateTimeTxt := Format(CurrentDateTime(), 0, 9);

        CFDICancellationMX.CreateCancellationXML(CancelDateTimeTxt, DateTimeStampedTxt, UUID, CancellationReasonCode, SubstitutionUUID, TempBlob);
        RequestTxt := GetRequestText(TempBlob);
        if RequestTxt = '' then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingCancelRequestErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        RequestType := RequestType::Cancel;
        Session.LogMessage('0000QX9', StrSubstNo(CancelRequestedMsg, EDocument."Entry No"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        Session.LogSecurityAudit(CFDIServiceNameTxt, SecurityOperationResult::Success, StrSubstNo(SecurityAuditCancelRequestedTxt, EDocument."Entry No"), AuditCategory::CustomerFacing);
        if not InvokeSoapRequestCore(RequestTxt, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            if ErrorText <> '' then
                EDocErrorHelper.LogSimpleErrorMessage(EDocument, ErrorText);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        CFDICancellationMX.ProcessCancellationResponse(ResponseTxt, EDocument, Status);
        if Status = Enum::"E-Document Service Status"::Canceled then
            Session.LogMessage('0000QXA', StrSubstNo(CancelSuccessMsg, EDocument."Entry No"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
        exit(true);
    end;

    local procedure GetStampedCFDIData(EDocument: Record "E-Document"; var UUID: Text[50]; var DateTimeStampedTxt: Text[50]): Boolean
    var
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
    begin
        UUID := '';
        DateTimeStampedTxt := '';

        if EDocument."Document Record ID".TableNo = 0 then
            exit(false);

        UUID := CopyStr(CFDIWriteBackMX.GetUUIDForDocument(EDocument."Document Record ID"), 1, MaxStrLen(UUID));
        if UUID = '' then
            exit(false);

        if EDocument."Clearance Date" <> 0DT then
            DateTimeStampedTxt := CopyStr(Format(EDocument."Clearance Date", 0, 9), 1, MaxStrLen(DateTimeStampedTxt))
        else
            DateTimeStampedTxt := CopyStr(Format(CurrentDateTime(), 0, 9), 1, MaxStrLen(DateTimeStampedTxt));

        exit(true);
    end;

    local procedure IsStatusValidForCancellation(ServiceStatus: Enum "E-Document Service Status"): Boolean
    begin
        exit(ServiceStatus in [
            Enum::"E-Document Service Status"::Sent,
            Enum::"E-Document Service Status"::"Pending Response",
            Enum::"E-Document Service Status"::"Cancel Error",
            Enum::"E-Document Service Status"::Approved]);
    end;

    local procedure ConfirmCancellationReason(var CancellationReasonCode: Code[10]; var SubstitutionUUID: Text[50]): Boolean
    var
        CancelReasonDlg: Page "MX CFDI Cancel Reason Dlg";
    begin
        if CancelReasonDlg.RunModal() <> Action::OK then
            exit(false);
        CancellationReasonCode := CancelReasonDlg.GetReasonCode();
        SubstitutionUUID := CancelReasonDlg.GetSubstitutionUUID();
        exit(true);
    end;

}
