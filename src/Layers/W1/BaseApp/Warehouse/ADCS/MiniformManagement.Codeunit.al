// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System;
using System.Xml;

codeunit 7702 "Miniform Management"
{

    trigger OnRun()
    begin
    end;

    var
        NodeDoesNotExistErr: Label 'The Node does not exist.';

    [Scope('OnPrem')]
    procedure ReceiveXML(xmlin: DotNet XmlDocument)
    var
        MiniFormHeader: Record "Miniform Header";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSManagement: Codeunit "ADCS Management";
        DOMxmlin: DotNet XmlDocument;
        RootNode: DotNet XmlNode;
        ReturnedNode: DotNet XmlNode;
        TextValue: Text[250];
    begin
        DOMxmlin := xmlin;
        RootNode := DOMxmlin.DocumentElement;
        if XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode) then begin
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
    procedure Initialize(var MiniformHeader: Record "Miniform Header"; var Rec: Record "Miniform Header"; var DOMxmlin: DotNet XmlDocument; var ReturnedNode: DotNet XmlNode; var RootNode: DotNet XmlNode; var XMLDOMMgt: Codeunit "XML DOM Management"; var ADCSCommunication: Codeunit "ADCS Communication"; var ADCSUserId: Text[250]; var CurrentCode: Text[250]; var StackCode: Text[250]; var WhseEmpId: Text[250]; var LocationFilter: Text[250])
    begin
        DOMxmlin := DOMxmlin.XmlDocument();

        MiniformHeader := Rec;
        MiniformHeader.LoadXMLin(DOMxmlin);
        RootNode := DOMxmlin.DocumentElement;
        XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode);
        CurrentCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'UseCaseCode');
        StackCode := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'StackCode');
        ADCSUserId := ADCSCommunication.GetNodeAttribute(ReturnedNode, 'LoginID');
        ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter);
    end;
}

