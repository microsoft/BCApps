// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.EServices.EDocument;
using Microsoft.Inventory.Location;
using System.Xml;

codeunit 3361 "CFDI XML Helper MX"
{
    procedure AddElement(var XMLNode: XmlNode; NodeName: Text; NodeText: Text; NamespaceURI: Text; var CreatedXmlNode: XmlNode): Boolean
    begin
        if not XMLNode.IsXmlElement() then
            exit(false);

        NodeText := RemoveInvalidChars(NodeText);
        CreatedXmlNode := XmlElement.Create(NodeName, NamespaceURI, NodeText).AsXmlNode();
        exit(XMLNode.AsXmlElement().Add(CreatedXmlNode));
    end;

    procedure AddElementCFDI(var XMLNode: XmlNode; NodeName: Text; NodeText: Text; var CreatedXmlNode: XmlNode): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        NodeText := RemoveInvalidChars(NodeText);
        exit(XMLDOMManagement.AddElementWithPrefix(XMLNode, NodeName, NodeText, 'cfdi', CFDINamespaceTxt, CreatedXmlNode));
    end;

    procedure AddAttribute(XMLNode: XmlNode; AttribName: Text; AttribValue: Text)
    begin
        AddAttributeSimple(XMLNode, AttribName, RemoveInvalidChars(AttribValue));
    end;

    procedure AddAttributeSimple(XMLNode: XmlNode; AttribName: Text; AttribValue: Text)
    begin
        if AttribValue = '' then
            exit;

        if not XMLNode.IsXmlElement() then
            exit;

        XMLNode.AsXmlElement().SetAttribute(AttribName, AttribValue);
    end;

    procedure AddElementCCE(var XMLNode: XmlNode; NodeName: Text; NodeText: Text; NamespaceURI: Text; var CreatedXmlNode: XmlNode): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        NodeText := RemoveInvalidChars(NodeText);
        exit(XMLDOMManagement.AddElementWithPrefix(XMLNode, NodeName, NodeText, 'cce20', NamespaceURI, CreatedXmlNode));
    end;

    procedure AddNodeDomicilio(SATAddressID: Integer; Address: Text[100]; var XMLNode: XmlNode)
    var
        SATAddress: Record "SAT Address";
        SATSuburb: Record "SAT Suburb";
        SATUtilities: Codeunit "SAT Utilities";
    begin
        SATAddress.Get(SATAddressID);
        SATSuburb.Get(SATAddress."SAT Suburb ID");

        if Address <> '' then
            AddAttributeSimple(XMLNode, 'Calle', Address);
        AddAttributeSimple(XMLNode, 'Colonia', SATSuburb."Suburb Code");
        if SATAddress."SAT Locality Code" <> '' then
            AddAttributeSimple(XMLNode, 'Localidad', SATAddress."SAT Locality Code");
        if SATAddress."SAT Municipality Code" <> '' then
            AddAttributeSimple(XMLNode, 'Municipio', SATAddress."SAT Municipality Code");
        AddAttributeSimple(XMLNode, 'Estado', SATAddress."SAT State Code");
        AddAttributeSimple(XMLNode, 'Pais', SATUtilities.GetSATCountryCode(SATAddress."Country/Region Code"));
        AddAttributeSimple(XMLNode, 'CodigoPostal', SATSuburb."Postal Code");
    end;

    procedure AddElementCartaPorte(var XMLNode: XmlNode; NodeName: Text; NodeText: Text; NamespaceURI: Text; var CreatedXmlNode: XmlNode): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        NodeText := RemoveInvalidChars(NodeText);

        if NamespaceURI = '' then
            exit(AddElement(XMLNode, NodeName, NodeText, CartaPorte31NamespaceTxt, CreatedXmlNode));

        exit(XMLDOMManagement.AddElementWithPrefix(XMLNode, NodeName, NodeText, 'cartaporte31', NamespaceURI, CreatedXmlNode));
    end;

    procedure AddNodeCartaPorteUbicacion(TipoUbicacion: Text; Location: Record Location; LocationPrefix: Text[2]; RFCNo: Text; ForeignRegId: Text; ResidenciaFiscal: Text; FechaHoraSalidaLlegada: Text; DistanciaRecorrida: Text; var XMLCurrNode: XmlNode; var XMLNewChild: XmlNode)
    var
        UbicacionNode: XmlNode;
        DomicilioNode: XmlNode;
    begin
        AddElementCartaPorte(XMLCurrNode, 'Ubicacion', '', '', UbicacionNode);
        XMLCurrNode := UbicacionNode;
        AddAttribute(XMLCurrNode, 'TipoUbicacion', TipoUbicacion);
        if Location."ID Ubicacion" <> 0 then
            AddAttribute(XMLCurrNode, 'IDUbicacion', LocationPrefix + Format(Location."ID Ubicacion"));
        AddAttribute(XMLCurrNode, 'RFCRemitenteDestinatario', RFCNo);
        if ForeignRegId <> '' then begin
            AddAttribute(XMLCurrNode, 'NumRegIdTrib', ForeignRegId);
            AddAttribute(XMLCurrNode, 'ResidenciaFiscal', ResidenciaFiscal);
        end;
        AddAttribute(XMLCurrNode, 'FechaHoraSalidaLlegada', FechaHoraSalidaLlegada);
        if DistanciaRecorrida <> '' then
            AddAttribute(XMLCurrNode, 'DistanciaRecorrida', DistanciaRecorrida);

        AddElementCartaPorte(XMLCurrNode, 'Domicilio', '', '', DomicilioNode);
        AddNodeDomicilio(Location."SAT Address ID", Location.Address, DomicilioNode);
        XMLNewChild := UbicacionNode;
    end;

    procedure InitXMLNamespaces(var NSManager: XmlNamespaceManager)
    begin
        NSManager.AddNamespace('cfdi', CFDINamespaceTxt);
        NSManager.AddNamespace('tfd', TimbreFiscalDigitalNamespaceTxt);
        NSManager.AddNamespace('pago20', Pago20NamespaceTxt);
        NSManager.AddNamespace('cartaporte31', CartaPorte31NamespaceTxt);
        NSManager.AddNamespace('cce20', ComercioExterior20NamespaceTxt);
        NSManager.AddNamespace('xsi', XSINamespaceTxt);
    end;

    procedure FormatAmount(Amount: Decimal): Text
    var
        DecimalPlaces: Integer;
    begin
        if Round(Abs(Amount), 0.01, '=') = Abs(Amount) then
            DecimalPlaces := 2
        else
            DecimalPlaces := 6;

        exit(
          Format(
            Abs(Amount), 0,
            '<Precision,' + Format(DecimalPlaces) + ':' + Format(DecimalPlaces) + '><Standard Format,1>'));
    end;

    procedure FormatDateTime(DT: DateTime): Text
    begin
        exit(Format(DT, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
    end;

    procedure GetSATDescription(Code: Code[10]; TableNo: Integer): Text
    var
        RecRef: RecordRef;
        CodeField: FieldRef;
        DescField: FieldRef;
    begin
        if (Code = '') or (TableNo = 0) then
            exit('');

        RecRef.Open(TableNo);

        CodeField := RecRef.Field(1);
        DescField := RecRef.Field(2);
        CodeField.SetRange(Code);

        if RecRef.FindFirst() then
            exit(Format(DescField.Value));

        exit('');
    end;

    local procedure RemoveInvalidChars(PassedStr: Text): Text
    begin
        PassedStr := DelChr(PassedStr, '=', '|');
        PassedStr := RemoveExtraWhiteSpaces(PassedStr);
        exit(PassedStr);
    end;

    local procedure RemoveExtraWhiteSpaces(StrParam: Text) StrReturn: Text
    var
        Cntr1: Integer;
        Cntr2: Integer;
        WhiteSpaceFound: Boolean;
    begin
        StrParam := DelChr(StrParam, '<>', ' ');
        WhiteSpaceFound := false;
        Cntr2 := 1;

        for Cntr1 := 1 to StrLen(StrParam) do
            if StrParam[Cntr1] <> ' ' then begin
                WhiteSpaceFound := false;
                StrReturn[Cntr2] := StrParam[Cntr1];
                Cntr2 += 1;
            end else
                if not WhiteSpaceFound then begin
                    WhiteSpaceFound := true;
                    StrReturn[Cntr2] := StrParam[Cntr1];
                    Cntr2 += 1;
                end;
    end;

    var
        XSINamespaceTxt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        CFDINamespaceTxt: Label 'http://www.sat.gob.mx/cfd/4', Locked = true;
        TimbreFiscalDigitalNamespaceTxt: Label 'http://www.sat.gob.mx/TimbreFiscalDigital', Locked = true;
        Pago20NamespaceTxt: Label 'http://www.sat.gob.mx/Pagos20', Locked = true;
        CartaPorte31NamespaceTxt: Label 'http://www.sat.gob.mx/CartaPorte31', Locked = true;
        ComercioExterior20NamespaceTxt: Label 'http://www.sat.gob.mx/ComercioExterior20', Locked = true;
}