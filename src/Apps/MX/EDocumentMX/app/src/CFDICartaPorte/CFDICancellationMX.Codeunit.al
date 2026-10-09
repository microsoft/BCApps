// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Foundation.Company;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 3359 "CFDI Cancellation MX"
{
    procedure CreateCancellationXML(CancelDateTime: Text[50]; DateTimeStamped: Text; UUID: Text[50]; CancellationReasonCode: Code[10]; SubstitutionUUID: Text[50]; var TempBlob: Codeunit "Temp Blob")
    var
        CompanyInformation: Record "Company Information";
        XmlDoc: XmlDocument;
        CancelRootNode: XmlElement;
        RootNode: XmlElement;
        FoliosNode: XmlElement;
        FolioNode: XmlElement;
        OutStr: OutStream;
    begin
        CompanyInformation.Get();
        CancelRootNode := XmlElement.Create('CancelaCFD');
        RootNode := XmlElement.Create('Cancelacion');
        RootNode.SetAttribute('Fecha', CancelDateTime);
        RootNode.SetAttribute('RfcEmisor', CompanyInformation."RFC Number");

        FoliosNode := XmlElement.Create('Folios');
        FolioNode := XmlElement.Create('Folio');

        FolioNode.SetAttribute('FechaTimbrado', DateTimeStamped);
        FolioNode.SetAttribute('UUID', UUID);
        FolioNode.SetAttribute('MotivoCancelacion', Format(CancellationReasonCode));
        if SubstitutionUUID <> '' then
            FolioNode.SetAttribute('FolioSustitucion', SubstitutionUUID);

        FoliosNode.Add(FolioNode.AsXmlNode());
        RootNode.Add(FoliosNode.AsXmlNode());
        CancelRootNode.Add(RootNode.AsXmlNode());
        XmlDoc.Add(CancelRootNode.AsXmlNode());

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    procedure CreateCancelStatusRequestXML(CFDICancellationID: Text; var TempBlob: Codeunit "Temp Blob")
    var
        CompanyInformation: Record "Company Information";
        XmlDoc: XmlDocument;
        RootNode: XmlElement;
        OutStr: OutStream;
    begin
        CompanyInformation.Get();

        RootNode := XmlElement.Create('ConsultaCancelacion');
        RootNode.SetAttribute('RfcEmisor', CompanyInformation."RFC Number");
        RootNode.SetAttribute('ConsultaCancelacionId', CFDICancellationID);

        XmlDoc.Add(RootNode.AsXmlNode());

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStr);
    end;

    procedure ProcessCancellationResponse(ResponseXML: Text; var EDocument: Record "E-Document"; var ResultStatus: Enum "E-Document Service Status")
    var
        ServiceStatus: Enum "E-Document Service Status";
        StatusToken: Text;
        ResultText: Text;
        DateTimeCancelledTxt: Text;
        CancellationId: Text;
        IsHandled: Boolean;
    begin
        ParseCancellationResponse(ResponseXML, StatusToken, ResultText, DateTimeCancelledTxt, CancellationId);

        IsHandled := false;
        OnMapCancellationStatusToken(StatusToken, ServiceStatus, IsHandled);

        if not IsHandled then begin
            case LowerCase(StatusToken) of
                'enproceso', 'en proceso':
                    ServiceStatus := Enum::"E-Document Service Status"::"Pending Response";
                'cancelado':
                    ServiceStatus := Enum::"E-Document Service Status"::Canceled;
                'rechazado':
                    ServiceStatus := Enum::"E-Document Service Status"::Rejected;
                else
                    ServiceStatus := GetCancellationStatus(EDocument);
            end;
        end;

        ResultStatus := ServiceStatus;
        ApplyCancellationToEDocument(EDocument, ServiceStatus, ResultText, DateTimeCancelledTxt, CancellationId);

        OnAfterProcessCancellationResponse(EDocument, StatusToken, ResultText, DateTimeCancelledTxt, CancellationId);
    end;

    procedure GetCancellationStatus(EDocument: Record "E-Document"): Enum "E-Document Service Status"
    var
        ServiceStatus: Enum "E-Document Service Status";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCancellationStatusFromPAC(EDocument, ServiceStatus, IsHandled);
        if IsHandled then
            exit(ServiceStatus);

        if TryGetServiceStatusFromEDocument(EDocument, ServiceStatus) then
            exit(ServiceStatus);

        exit(ServiceStatus);
    end;

    local procedure ParseCancellationResponse(ResponseXML: Text; var StatusToken: Text; var ResultText: Text; var DateTimeCancelledTxt: Text; var CancellationId: Text)
    var
        XmlDoc: XmlDocument;
        ResultNode: XmlNode;
        EventNode: XmlNode;
        IdRespuesta: Text;
        Descripcion: Text;
        Detalle: Text;
    begin
        StatusToken := '';
        ResultText := '';
        DateTimeCancelledTxt := '';
        CancellationId := '';

        if (ResponseXML = '') or (not TryLoadXml(ResponseXML, XmlDoc)) then begin
            StatusToken := 'Rechazado';
            ResultText := CopyStr(ResponseXML, 1, 250);
            exit;
        end;

        if not XmlDoc.SelectSingleNode('/Resultado', ResultNode) then
            if not XmlDoc.SelectSingleNode('Resultado', ResultNode) then
                ResultNode := XmlDoc.AsXmlNode();

        IdRespuesta := GetNodeAttribute(ResultNode, 'IdRespuesta');
        StatusToken := GetNodeAttribute(ResultNode, 'Estatus');
        if StatusToken = '' then
            StatusToken := GetNodeAttribute(ResultNode, 'Estado');

        ResultText := GetNodeAttribute(ResultNode, 'Resultado');
        Descripcion := GetNodeAttribute(ResultNode, 'Descripcion');
        Detalle := GetNodeAttribute(ResultNode, 'Detalle');

        if ResultText = '' then
            ResultText := Descripcion;
        if (ResultText <> '') and (Detalle <> '') then
            ResultText := ResultText + ': ' + Detalle;
        if (ResultText = '') and (Detalle <> '') then
            ResultText := Detalle;

        CancellationId := GetNodeAttribute(ResultNode, 'ConsultaCancelacionId');

        if ResultNode.SelectSingleNode('Evento', EventNode) then
            DateTimeCancelledTxt := GetNodeAttribute(EventNode, 'Fecha');

        if IdRespuesta <> '' then
            if IdRespuesta <> '1' then begin
                StatusToken := 'Rechazado';
                exit;
            end;

        if (StatusToken = '') and (CancellationId <> '') then
            StatusToken := 'EnProceso';

        if StatusToken = '' then
            StatusToken := DeriveStatusFromText(ResponseXML, ResultText);
    end;

    [TryFunction]
    local procedure TryLoadXml(XmlText: Text; var XmlDoc: XmlDocument)
    begin
        XmlDocument.ReadFrom(XmlText, XmlDoc);
    end;

    local procedure GetNodeAttribute(Node: XmlNode; AttributeName: Text): Text
    var
        AttrCollection: XmlAttributeCollection;
        Attr: XmlAttribute;
    begin
        if not Node.IsXmlElement() then
            exit('');

        AttrCollection := Node.AsXmlElement().Attributes();
        if not AttrCollection.Get(AttributeName, Attr) then
            exit('');

        exit(Attr.Value());
    end;

    local procedure DeriveStatusFromText(ResponseXML: Text; ResultText: Text): Text
    var
        FullTxt: Text;
    begin
        FullTxt := LowerCase(ResponseXML + ' ' + ResultText);

        if StrPos(FullTxt, 'enproceso') > 0 then
            exit('EnProceso');
        if StrPos(FullTxt, 'en proceso') > 0 then
            exit('EnProceso');
        if StrPos(FullTxt, 'cancelado') > 0 then
            exit('Cancelado');
        if StrPos(FullTxt, 'rechazado') > 0 then
            exit('Rechazado');

        exit('Rechazado');
    end;

    local procedure ApplyCancellationToEDocument(var EDocument: Record "E-Document"; ServiceStatus: Enum "E-Document Service Status"; ResultText: Text; DateTimeCancelledTxt: Text; CancellationId: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(EDocument);

        TrySetFieldValueByName(RecRef, 'Service Status', ServiceStatus);
        TrySetFieldValueByName(RecRef, 'Error Message', CopyStr(ResultText, 1, 250));
        TrySetFieldValueByName(RecRef, 'Error Description', CopyStr(ResultText, 1, 250));
        TrySetFieldValueByName(RecRef, 'CFDI Cancellation ID', CopyStr(CancellationId, 1, 50));
        TrySetDateTimeOrTextByName(RecRef, 'Date/Time Canceled', DateTimeCancelledTxt);

        RecRef.Modify();
        RecRef.SetTable(EDocument);
    end;

    local procedure TryGetServiceStatusFromEDocument(EDocument: Record "E-Document"; var ServiceStatus: Enum "E-Document Service Status"): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(EDocument);
        if not TryFindFieldByName(RecRef, 'Service Status', FieldRef) then
            exit(false);

        exit(TryReadEnumFromFieldRef(FieldRef, ServiceStatus));
    end;

    [TryFunction]
    local procedure TryReadEnumFromFieldRef(FieldRef: FieldRef; var ServiceStatus: Enum "E-Document Service Status")
    begin
        ServiceStatus := FieldRef.Value;
    end;

    local procedure TrySetFieldValueByName(var RecRef: RecordRef; FieldName: Text; Value: Variant)
    var
        FieldRef: FieldRef;
    begin
        if not TryFindFieldByName(RecRef, FieldName, FieldRef) then
            exit;

        TryAssignFieldValue(FieldRef, Value);
    end;

    local procedure TrySetDateTimeOrTextByName(var RecRef: RecordRef; FieldName: Text; DateTimeText: Text)
    var
        FieldRef: FieldRef;
        DateTimeValue: DateTime;
    begin
        if DateTimeText = '' then
            exit;

        if not TryFindFieldByName(RecRef, FieldName, FieldRef) then
            exit;

        case FieldRef.Type() of
            FieldType::DateTime:
                if Evaluate(DateTimeValue, DateTimeText) then
                    TryAssignFieldValue(FieldRef, DateTimeValue);
            FieldType::Text, FieldType::Code:
                TryAssignFieldValue(FieldRef, DateTimeText);
        end;
    end;

    [TryFunction]
    local procedure TryAssignFieldValue(var FieldRef: FieldRef; Value: Variant)
    begin
        FieldRef.Value := Value;
    end;

    local procedure TryFindFieldByName(var RecRef: RecordRef; FieldName: Text; var FoundFieldRef: FieldRef): Boolean
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

    [IntegrationEvent(false, false)]
    local procedure OnMapCancellationStatusToken(StatusToken: Text; var ServiceStatus: Enum "E-Document Service Status"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCancellationStatusFromPAC(EDocument: Record "E-Document"; var ServiceStatus: Enum "E-Document Service Status"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessCancellationResponse(EDocument: Record "E-Document"; StatusToken: Text; ResultText: Text; DateTimeCancelledTxt: Text; CancellationId: Text)
    begin
    end;
}