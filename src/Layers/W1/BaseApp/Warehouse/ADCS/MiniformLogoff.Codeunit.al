// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System;
using System.Xml;

codeunit 7706 "Miniform Logoff"
{
    TableNo = "Miniform Header";

    trigger OnRun()
    var
        MiniformMgt: Codeunit "Miniform Management";
    begin
        MiniformMgt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        if Rec.Code <> CurrentCode then
            SendForm(1)
        else
            Process();

        Clear(DOMxmlin);
    end;

    var
        MiniformHeader: Record "Miniform Header";
        MiniformHeader2: Record "Miniform Header";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSMgt: Codeunit "ADCS Management";
        ReturnedNode: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        DOMxmlin: DotNet XmlDocument;
        TextValue: Text[250];
        ADCSUserId: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        CurrentCode: Text[250];
        StackCode: Text[250];
        NoInputNodeErr: Label 'No input Node found.';

    local procedure Process()
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.InnerText
        else
            Error(NoInputNodeErr);

        ADCSCommunication.GetCallMiniForm(MiniformHeader.Code, MiniformHeader2, TextValue);
        ADCSCommunication.IncreaseStack(DOMxmlin, MiniformHeader.Code);
        MiniformHeader2.SaveXMLin(DOMxmlin);
        CODEUNIT.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;

    local procedure SendForm(ActiveInputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, '', DOMxmlin, ActiveInputField, '', ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

