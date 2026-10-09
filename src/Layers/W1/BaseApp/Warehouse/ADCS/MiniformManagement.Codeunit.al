// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

#if not CLEAN30
using System;
using System.Xml;
#endif

codeunit 7702 "Miniform Management"
{

    trigger OnRun()
    begin
    end;

    var
        NodeDoesNotExistErr: Label 'The Node does not exist.';

    [Scope('OnPrem')]
    procedure ReceiveXML(xmlin: XmlDocument)
    var
        MiniFormHeader: Record "Miniform Header";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSManagement: Codeunit "ADCS Management";
        DOMxmlin: XmlDocument;
        RootElement: XmlElement;
        ReturnedNode: XmlNode;
        TextValue: Text[250];
        HeaderFound: Boolean;
    begin
        DOMxmlin := xmlin;
        if DOMxmlin.GetRoot(RootElement) then
            HeaderFound := RootElement.SelectSingleNode('Header', ReturnedNode);
        if HeaderFound then begin
            TextValue := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
            if UpperCase(TextValue) = 'HELLO' then
                TextValue := ADCSCommunication.GetLoginFormCode();
            MiniFormHeader.Get(TextValue);
            MiniFormHeader.TestField("Handling Codeunit");
            MiniFormHeader.SaveXMLin(DOMxmlin);
            if not CODEUNIT.Run(MiniFormHeader."Handling Codeunit", MiniFormHeader) then
                ADCSManagement.SendError(GetLastErrorText());
        end else
            Error(NodeDoesNotExistErr);
    end;

    [Scope('OnPrem')]
    procedure Initialize(var MiniformHeader: Record "Miniform Header"; var Rec: Record "Miniform Header"; var DOMxmlin: XmlDocument; var ReturnedNode: XmlNode; var RootNode: XmlNode; var ADCSCommunication: Codeunit "ADCS Communication"; var ADCSUserId: Text[250]; var CurrentCode: Text[250]; var StackCode: Text[250]; var WhseEmpId: Text[250]; var LocationFilter: Text[250])
    var
        RootElement: XmlElement;
    begin
        Clear(DOMxmlin);

        MiniformHeader := Rec;
        MiniformHeader.LoadXMLin(DOMxmlin);
        DOMxmlin.GetRoot(RootElement);
        RootNode := RootElement.AsXmlNode();
        RootNode.SelectSingleNode('Header', ReturnedNode);
        CurrentCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
        StackCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'StackCode');
        ADCSUserId := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'LoginID');
        ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Replaced by ReceiveXML with a parameter of the native XmlDocument type.', '30.0')]
    procedure ReceiveXML(xmlin: DotNet XmlDocument)
    var
        NativeXmlDocument: XmlDocument;
    begin
        if not IsNull(xmlin) then
            if not IsNull(xmlin.DocumentElement) then
                XmlDocument.ReadFrom(xmlin.OuterXml(), NativeXmlDocument);
        ReceiveXML(NativeXmlDocument);
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced by Initialize with parameters of the native XmlDocument and XmlNode types.', '30.0')]
    procedure Initialize(var MiniformHeader: Record "Miniform Header"; var Rec: Record "Miniform Header"; var DOMxmlin: DotNet XmlDocument; var ReturnedNode: DotNet XmlNode; var RootNode: DotNet XmlNode; var XMLDOMMgt: Codeunit "XML DOM Management"; var ADCSCommunication: Codeunit "ADCS Communication"; var ADCSUserId: Text[250]; var CurrentCode: Text[250]; var StackCode: Text[250]; var WhseEmpId: Text[250]; var LocationFilter: Text[250])
    begin
        DOMxmlin := DOMxmlin.XmlDocument();

        MiniformHeader := Rec;
        MiniformHeader.LoadXMLin(DOMxmlin);
        RootNode := DOMxmlin.DocumentElement;
        ReturnedNode := RootNode.SelectSingleNode('Header');
        CurrentCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
        StackCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'StackCode');
        ADCSUserId := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'LoginID');
        ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter);
    end;
#endif
}
