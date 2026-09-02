codeunit 3314 "MX Interfactura Impl." implements IDocumentSender, IDocumentReceiver, IDocumentResponseHandler, IDocumentAction, ISentDocumentActions
{
    Access = Internal;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        MXConnectionSetup: Record "MX Connection Setup";
        TempBlob: Codeunit "Temp Blob";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
    begin
        if not MXConnectionSetup.Get() then
            Error(MissingSetupErr);

        if not MXConnectionSetup.Enabled then
            Error(DisabledSetupErr);

        if MXConnectionSetup."Send Mode" = MXConnectionSetup."Send Mode"::Test then begin
            SendMockResponse(EDocument, SendContext);
            exit;
        end;

        if MXConnectionSetup."Send Mode" = MXConnectionSetup."Send Mode"::Production then begin
            TempBlob := SendContext.GetTempBlob();
            InterfacturaProcessing.SendEDocument(TempBlob, EDocument, SendContext);
            SendContext.Http().SetHttpRequestMessage(HttpRequest);
            SendContext.Http().SetHttpResponseMessage(HttpResponse);
        end;

    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Not implemented for Interfactura
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
        // Not implemented for Interfactura
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext): Boolean
    var
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Success: Boolean;
    begin
        Success := InterfacturaProcessing.GetDocumentResponse(EDocument, EDocumentService, HttpRequest, HttpResponse);
        SendContext.Http().SetHttpRequestMessage(HttpRequest);
        SendContext.Http().SetHttpResponseMessage(HttpResponse);
        exit(Success);
    end;

    procedure GetApprovalStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext) Success: Boolean
    var
        Status: Enum "E-Document Service Status";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
    begin
        Success := InterfacturaProcessing.GetDocumentApproval(EDocument, EDocumentService, HttpRequest, HttpResponse, Status);
        ActionContext.Status().SetStatus(Status);
        ActionContext.Http().SetHttpRequestMessage(HttpRequest);
        ActionContext.Http().SetHttpResponseMessage(HttpResponse);
    end;

    procedure GetCancellationStatus(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext) Success: Boolean
    var
        MXConnectionSetup: Record "MX Connection Setup";
        Status: Enum "E-Document Service Status";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
    begin
        if MXConnectionSetup.Get() and (MXConnectionSetup."Send Mode" = MXConnectionSetup."Send Mode"::Test) then begin
            Success := CancelMockResponse(EDocument, Status, HttpRequest, HttpResponse);
            ActionContext.Status().SetStatus(Status);
            ActionContext.Http().SetHttpRequestMessage(HttpRequest);
            ActionContext.Http().SetHttpResponseMessage(HttpResponse);
            exit;
        end;

        Success := InterfacturaProcessing.CancelEDocument(EDocument, EDocumentService, HttpRequest, HttpResponse, Status);
        ActionContext.Status().SetStatus(Status);
        ActionContext.Http().SetHttpRequestMessage(HttpRequest);
        ActionContext.Http().SetHttpResponseMessage(HttpResponse);
    end;

    local procedure CancelMockResponse(var EDocument: Record "E-Document"; var Status: Enum "E-Document Service Status"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    var
        CFDICancellationMX: Codeunit "CFDI Cancellation MX";
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
        TempBlob: Codeunit "Temp Blob";
        UUID: Text;
        RequestTxt: Text;
        MockResponseTxt: Text;
        CancellationReasonCode: Code[10];
    begin
        UUID := CFDIWriteBackMX.GetUUIDForDocument(EDocument."Document Record ID");
        if UUID = '' then begin
            Status := Enum::"E-Document Service Status"::Cleared;
            exit(false);
        end;

        CancellationReasonCode := GetCancellationReasonCode(EDocument);
        CFDICancellationMX.CreateCancellationXML(
            Format(CurrentDateTime(), 0, 9), Format(CurrentDateTime(), 0, 9), CopyStr(UUID, 1, 50), CancellationReasonCode, '', TempBlob);
        RequestTxt := ReadBlobAsText(TempBlob);

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(MockRequestUriLbl);
        HttpRequest.Content.WriteFrom(RequestTxt);

        MockResponseTxt := StrSubstNo(
            MockCancelResponseTxtLbl,
            Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'),
            DelChr(Format(CreateGuid()), '=', '{}'));
        HttpResponse.Content.WriteFrom(MockResponseTxt);

        CFDICancellationMX.ProcessCancellationResponse(MockResponseTxt, EDocument);
        DownloadCancelXmlPair(EDocument."Entry No", MockResponseTxt);

        Status := Enum::"E-Document Service Status"::Canceled;
        exit(true);
    end;

    local procedure DownloadXmlText(XmlText: Text; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XmlText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    local procedure DownloadCancelXmlPair(EntryNo: Integer; ResponseTxt: Text)
    begin
        if GuiAllowed() then
            DownloadXmlText(ResponseTxt, StrSubstNo(CancelResponseFileNameLbl, EntryNo));
    end;

    local procedure DownloadStampXmlPair(EntryNo: Integer; ResponseTxt: Text)
    begin
        if GuiAllowed() then
            DownloadXmlText(ResponseTxt, StrSubstNo(StampResponseFileNameLbl, EntryNo));
    end;

    procedure InvokeAction(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; ActionContext: Codeunit ActionContext): Boolean
    begin
        // Not implemented for Interfactura
        exit(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"E-Document Service", OnBeforeOpenServiceIntegrationSetupPage, '', false, false)]
    local procedure OnBeforeOpenServiceIntegrationSetupPage(EDocumentService: Record "E-Document Service"; var IsServiceIntegrationSetupRun: Boolean)
    var
        MXConnectionSetupCard: Page "Interfactura Connection Setup";
    begin
        if EDocumentService."Service Integration V2" <> EDocumentService."Service Integration V2"::"Interfactura Service" then
            exit;

        MXConnectionSetupCard.RunModal();
        IsServiceIntegrationSetupRun := true;
    end;

    local procedure SendMockResponse(var EDocument: Record "E-Document"; SendContext: Codeunit SendContext)
    var
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
        TempBlob: Codeunit "Temp Blob";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestTxt: Text;
        MockResponseTxt: Text;
    begin
        TempBlob := SendContext.GetTempBlob();
        RequestTxt := ReadBlobAsText(TempBlob);

        HttpRequest := SendContext.Http().GetHttpRequestMessage();
        HttpRequest.Method := 'POST';
        if MXPACWebServiceDetail.Get('', MXPACWebServiceDetail.Type::"Request Stamp") then
            HttpRequest.SetRequestUri(MXPACWebServiceDetail.Address)
        else
            HttpRequest.SetRequestUri(MockRequestUriLbl);

        HttpRequest.Content.WriteFrom(RequestTxt);
        SendContext.Http().SetHttpRequestMessage(HttpRequest);

        // In test mode we return the actual XML payload generated for the document, augmented with a mock
        // TimbreFiscalDigital node (fake UUID/seals), so it can be printed/validated and also cancelled later
        // without relying on a real PAC endpoint.
        if RequestTxt <> '' then
            MockResponseTxt := InjectMockTimbreFiscalDigital(RequestTxt)
        else
            MockResponseTxt := StrSubstNo(MockResponseTxtLbl, Format(EDocument."Entry No"));

        HttpResponse.Content.WriteFrom(MockResponseTxt);
        SendContext.Http().SetHttpResponseMessage(HttpResponse);

        // Persist the stamped XML (with the fake TimbreFiscalDigital/UUID) so later actions
        // (cancellation, QR code, write-back) can find it via "Structured Data Entry No.",
        // exactly as the real Interfactura flow does with a genuine PAC response.
        InterfacturaProcessing.SaveStampedCFDI(EDocument, MockResponseTxt);
        DownloadStampXmlPair(EDocument."Entry No", MockResponseTxt);

        EDocument."Last Clearance Request Time" := CurrentDateTime();
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Modify();

        SendContext.Status().SetStatus(Enum::"E-Document Service Status"::Cleared);
    end;

    local procedure InjectMockTimbreFiscalDigital(RequestXml: Text): Text
    var
        NewGuid: Guid;
        UUIDTxt: Text;
        TimbreXml: Text;
        ClosingTagPos: Integer;
    begin
        NewGuid := CreateGuid();
        UUIDTxt := DelChr(Format(NewGuid), '=', '{}');

        TimbreXml :=
            '<cfdi:Complemento>' +
            '<tfd:TimbreFiscalDigital xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" Version="1.1" ' +
            'UUID="' + UUIDTxt + '" ' +
            'FechaTimbrado="' + Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>') + '" ' +
            'RfcProvCertif="MOC010101MOC" SelloCFD="MOCKSELLOCFD" NoCertificadoSAT="00001000000000000000" SelloSAT="MOCKSELLOSAT"/>' +
            '</cfdi:Complemento>';

        ClosingTagPos := StrPos(RequestXml, '</cfdi:Comprobante>');
        if ClosingTagPos = 0 then
            exit(RequestXml);

        exit(CopyStr(RequestXml, 1, ClosingTagPos - 1) + TimbreXml + CopyStr(RequestXml, ClosingTagPos));
    end;

    local procedure ReadBlobAsText(TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Chunk: Text;
        ResultTxt: Text;
    begin
        if not TempBlob.HasValue() then
            exit('');

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS do begin
            InStr.ReadText(Chunk);
            ResultTxt += Chunk;
        end;

        exit(ResultTxt);
    end;

    local procedure GetCancellationReasonCode(EDocument: Record "E-Document"): Code[10]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Field: Record "Field";
        ReasonCode: Code[10];
    begin
        if EDocument."Document Record ID".TableNo = 0 then
            Error(CancellationReasonCodeRequiredErr);

        RecRef.Get(EDocument."Document Record ID");

        Field.SetRange(TableNo, RecRef.Number);
        Field.SetFilter(FieldName, 'CFDI Cancellation Reason Code');

        if not Field.FindFirst() then
            Error(CancellationReasonCodeRequiredErr);

        FieldRef := RecRef.Field(Field."No.");
        ReasonCode := CopyStr(Format(FieldRef.Value), 1, 10);

        if ReasonCode = '' then
            Error(CancellationReasonCodeRequiredErr);

        exit(ReasonCode);
    end;

    var
        InterfacturaProcessing: Codeunit "Interfactura Processing";
        MissingSetupErr: Label 'Interfactura Connection Setup must be configured before sending.';
        DisabledSetupErr: Label 'Interfactura Connection Setup must be enabled before sending.';
        CancellationReasonCodeRequiredErr: Label 'Cancellation Reason Code must be filled in before canceling the e-document.';
        MockRequestUriLbl: Label 'https://mock.local/interfactura/request-stamp', Locked = true;
        MockResponseTxtLbl: Label 'MOCK INTERFACTURA RESPONSE - E-Document %1', Comment = '%1 = E-Document Entry No.';
        MockCancelResponseTxtLbl: Label '<Resultado IdRespuesta="1" Estatus="Cancelado" Resultado="Cancelado" ConsultaCancelacionId="%2"><Evento Fecha="%1"/></Resultado>', Comment = '%1 = Cancellation date/time, %2 = Consultation Cancellation ID', Locked = true;
        CancelResponseFileNameLbl: Label 'CancelaCFD_Response_%1.xml', Comment = '%1 = E-Document Entry No.', Locked = true;
        StampResponseFileNameLbl: Label 'Stamp_Response_%1.xml', Comment = '%1 = E-Document Entry No.', Locked = true;

}