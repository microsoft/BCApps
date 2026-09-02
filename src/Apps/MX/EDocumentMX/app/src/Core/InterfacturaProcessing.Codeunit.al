codeunit 3305 "Interfactura Processing"
{
    Access = Internal;

    var
        InterfacturaSetup: Record "MX Connection Setup";
        ConnectionSetupErr: Label 'You must enable Interfactura Setup.';
        BatchSoapRequestMsg: Label 'Sending batch soap request of type %1', Locked = true;
        NoResponseErr: Label 'Remote service did not provide a response. Open Interfactura Setup page and make sure that the Document Registration Endpoint and the certificate are correctly specified and try again.';
        NoResponseTelemetryErr: Label 'Could not get response.', Locked = true;
        CommunicationErr: Label 'Remote service returned an unexpected response: %1.', Comment = '%1 is the error message.';
        CommunicationTelemetryErr: Label 'Communication error: %1.', Comment = '%1 is the error message.', Locked = true;
        BatchSoapRequestSuccMsg: Label 'Batch soap request of type %1 successfully executed', Locked = true;
        FeatureNameTxt: Label 'Interfactura Document Registration';
        EmptyRequestLbl: Label 'The request is empty.';
        ParseErr: Label 'Failed to parse document from Interfactura API';
        MissingPACWebServiceDetailErr: Label 'PAC Web Service Detail for %1 is missing or incomplete.';
        MissingStampedDataErr: Label 'No stamped CFDI data was found for this document. Cancellation requires a stamped UUID.';
        MissingCancelRequestErr: Label 'The cancellation request could not be generated.';
        MissingCancellationIdErr: Label 'Cancellation status cannot be requested because CFDI Cancellation ID is missing.';
        DefaultCancellationReasonLbl: Label '02', Locked = true;


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
        if not InvokeSoapRequest(EDocument, RequestTxt, RequestType, ErrorText, SendContext) then
            Error(ErrorText);

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
        IsSuccessful: Boolean;
        HttpClient: HttpClient;
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
        ContentHeaders, RequestHeaders : HttpHeaders;
        WebServiceUrl, StatusDescription : Text;
        StatusCode: Integer;
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

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(WebServiceUrl);

        HttpRequest.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/xml');
        RequestHeaders.Add('Accept-Encoding', 'utf-8');
        RequestHeaders.Add('SOAPAction', MXPACWebServiceDetail."Method Name");

        HttpRequest.Content.WriteFrom(RequestText);
        HttpRequest.Content.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/xml');
        HttpRequest.Content(HttpRequest.Content);

        IsSuccessful := HttpClient.Send(HttpRequest, HttpResponse);
        if not IsSuccessful then begin
            Session.LogMessage('0000QWY', NoResponseTelemetryErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            ErrorText := NoResponseErr;
            exit(false);
        end;

        StatusCode := HttpResponse.HttpStatusCode;
        StatusDescription := HttpResponse.ReasonPhrase;
        if not (StatusCode in [200, 202]) then begin
            Session.LogMessage('0000QWZ', StrSubstNo(CommunicationTelemetryErr, Format(StatusCode) + ' ' + StatusDescription), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);
            ErrorText := StrSubstNo(CommunicationErr, Format(StatusCode) + ' ' + StatusDescription);
            exit(false);
        end;

        HttpResponse.Content().ReadAs(ResponseTxt);
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

        if ErrorText <> '' then
            Session.LogMessage('0000QX3', ErrorText, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureNameTxt);

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
    begin
        if EDocument."Clearance Date" <> 0DT then begin
            Status := Enum::"E-Document Service Status"::Approved;
            exit(true);
        end;

        if not EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code) then begin
            Status := Enum::"E-Document Service Status"::"Pending Response";
            exit(false);
        end;

        case EDocumentServiceStatus.Status of
            EDocumentServiceStatus.Status::Cleared:
                begin
                    Status := Enum::"E-Document Service Status"::Approved;
                    exit(true);
                end;
            EDocumentServiceStatus.Status::Rejected,
            EDocumentServiceStatus.Status::"Not Cleared":
                begin
                    Status := Enum::"E-Document Service Status"::Rejected;
                    exit(true);
                end;
            else begin
                Status := Enum::"E-Document Service Status"::"Pending Response";
                exit(false);
            end;
        end;
    end;

    procedure CancelEDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var Status: Enum "E-Document Service Status"): Boolean
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        TempBlob: Codeunit "Temp Blob";
        RequestType: Option "Request Stamp",Cancel,CancelRequest;
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        RequestTxt, ResponseTxt, ErrorText : Text;
        UUID, DateTimeStampedTxt, SubstitutionUUID : Text[50];
        CancellationReasonCode: Code[10];
        CancelDateTimeTxt: Text[50];
    begin
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);

        if EDocumentServiceStatus.Status = EDocumentServiceStatus.Status::"Pending Response" then
            exit(RequestCancellationStatus(EDocument, EDocumentServiceStatus, HttpRequest, HttpResponse, Status));

        if not GetStampedCFDIData(EDocument, UUID, DateTimeStampedTxt) then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingStampedDataErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        CancellationReasonCode := GetCancellationReasonCode(EDocument);
        SubstitutionUUID := GetSubstitutionUUID(EDocument);
        CancelDateTimeTxt := Format(CurrentDateTime(), 0, 9);

        CFDICancellationMX.CreateCancellationXML(CancelDateTimeTxt, DateTimeStampedTxt, UUID, CancellationReasonCode, SubstitutionUUID, TempBlob);
        RequestTxt := GetRequestText(TempBlob);
        if RequestTxt = '' then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingCancelRequestErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        RequestType := RequestType::Cancel;
        if not InvokeSoapRequestCore(RequestTxt, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            if ErrorText <> '' then
                EDocErrorHelper.LogSimpleErrorMessage(EDocument, ErrorText);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        CFDICancellationMX.ProcessCancellationResponse(ResponseTxt, EDocument);
        Status := MapCancellationStatusFromResponse(ResponseTxt, EDocumentServiceStatus.Status);
        exit(true);
    end;

    local procedure RequestCancellationStatus(var EDocument: Record "E-Document"; EDocumentServiceStatus: Record "E-Document Service Status"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var Status: Enum "E-Document Service Status"): Boolean
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        TempBlob: Codeunit "Temp Blob";
        RequestType: Option "Request Stamp",Cancel,CancelRequest;
        RequestTxt, ResponseTxt, ErrorText : Text;
        CancellationId: Text;
    begin
        CancellationId := GetCancellationId(EDocument);
        if CancellationId = '' then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingCancellationIdErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        CFDICancellationMX.CreateCancelStatusRequestXML(CancellationId, TempBlob);
        RequestTxt := GetRequestText(TempBlob);
        if RequestTxt = '' then begin
            EDocErrorHelper.LogSimpleErrorMessage(EDocument, MissingCancelRequestErr);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        RequestType := RequestType::CancelRequest;
        if not InvokeSoapRequestCore(RequestTxt, RequestType, HttpRequest, HttpResponse, ResponseTxt, ErrorText) then begin
            if ErrorText <> '' then
                EDocErrorHelper.LogSimpleErrorMessage(EDocument, ErrorText);
            Status := EDocumentServiceStatus.Status;
            exit(false);
        end;

        CFDICancellationMX.ProcessCancellationResponse(ResponseTxt, EDocument);
        Status := MapCancellationStatusFromResponse(ResponseTxt, EDocumentServiceStatus.Status);
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

    local procedure GetCancellationReasonCode(EDocument: Record "E-Document"): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ReasonTxt: Text;
    begin
        RecRef.GetTable(EDocument);
        if TryGetFieldRefByName(RecRef, 'Cancellation Reason Code', FieldRef) then begin
            ReasonTxt := Format(FieldRef.Value);
            if ReasonTxt <> '' then
                exit(CopyStr(ReasonTxt, 1, 10));
        end;

        exit(CopyStr(DefaultCancellationReasonLbl, 1, 10));
    end;

    local procedure GetSubstitutionUUID(EDocument: Record "E-Document"): Text[50]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(EDocument);
        if TryGetFieldRefByName(RecRef, 'Substitution UUID', FieldRef) then
            exit(CopyStr(Format(FieldRef.Value), 1, 50));

        exit('');
    end;

    local procedure GetCancellationId(EDocument: Record "E-Document"): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(EDocument);
        if TryGetFieldRefByName(RecRef, 'CFDI Cancellation ID', FieldRef) then
            exit(Format(FieldRef.Value));

        if TryGetFieldRefByName(RecRef, 'Cancellation ID', FieldRef) then
            exit(Format(FieldRef.Value));

        exit('');
    end;

    local procedure MapCancellationStatusFromResponse(ResponseTxt: Text; FallbackStatus: Enum "E-Document Service Status"): Enum "E-Document Service Status"
    var
        XmlDoc: XmlDocument;
        ResultNode: XmlNode;
        StatusTxt: Text;
    begin
        if not TryReadXml(ResponseTxt, XmlDoc) then
            exit(FallbackStatus);

        if not TryGetResultNode(XmlDoc, ResultNode) then
            exit(FallbackStatus);

        StatusTxt := GetXmlAttribute(ResultNode, 'Estatus');
        if StatusTxt = '' then
            StatusTxt := GetXmlAttribute(ResultNode, 'Resultado');

        case UpperCase(StatusTxt) of
            'ENPROCESO':
                exit(Enum::"E-Document Service Status"::"Pending Response");
            'RECHAZADO':
                exit(Enum::"E-Document Service Status"::Rejected);
            'CANCELADO':
                exit(Enum::"E-Document Service Status"::Canceled);
            else
                exit(FallbackStatus);
        end;
    end;

    local procedure TryGetFieldRefByName(var RecRef: RecordRef; FieldName: Text; var FoundFieldRef: FieldRef): Boolean
    var
        Index: Integer;
        CurrentFieldRef: FieldRef;
    begin
        for Index := 1 to RecRef.FieldCount do begin
            CurrentFieldRef := RecRef.FieldIndex(Index);
            if LowerCase(CurrentFieldRef.Name) = LowerCase(FieldName) then begin
                FoundFieldRef := CurrentFieldRef;
                exit(true);
            end;
        end;

        exit(false);
    end;

}