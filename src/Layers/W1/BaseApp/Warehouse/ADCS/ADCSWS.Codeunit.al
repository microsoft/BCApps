// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

codeunit 7714 "ADCS WS"
{

    trigger OnRun()
    begin
    end;

    var
        ADCSManagement: Codeunit "ADCS Management";

    procedure ProcessDocument(var Document: Text)
    var
        InputXmlDocument: XmlDocument;
        OutputXmlDocument: XmlDocument;
        RootElement: XmlElement;
        InputText: Text;
        ByteOrderMark: Text[1];
    begin
        InputText := Document;
        ByteOrderMark[1] := 65279;
        if StrPos(InputText, ByteOrderMark) = 1 then
            InputText := DelStr(InputText, 1, 1);
        if InputText <> '' then begin
            XmlDocument.ReadFrom(InputText, InputXmlDocument);
            if InputXmlDocument.GetRoot(RootElement) then
                RemoveWhitespaceNodes(RootElement);
        end;
        ADCSManagement.ProcessDocument(InputXmlDocument);
        ADCSManagement.GetOutboundDocument(OutputXmlDocument);
        Document := ADCSManagement.WriteDocumentToText(OutputXmlDocument);
    end;

    local procedure RemoveWhitespaceNodes(ParentElement: XmlElement)
    var
        ChildNodes: XmlNodeList;
        ChildNode: XmlNode;
        WhitespaceChars: Text[4];
        Index: Integer;
    begin
        // The former DotNet XmlDocument dropped whitespace-only text nodes when loading the request
        WhitespaceChars[1] := 9;
        WhitespaceChars[2] := 10;
        WhitespaceChars[3] := 13;
        WhitespaceChars[4] := 32;
        ChildNodes := ParentElement.GetChildNodes();
        for Index := ChildNodes.Count() downto 1 do begin
            ChildNodes.Get(Index, ChildNode);
            if ChildNode.IsXmlText() then begin
                if DelChr(ChildNode.AsXmlText().Value(), '=', WhitespaceChars) = '' then
                    ChildNode.Remove();
            end else
                if ChildNode.IsXmlElement() then
                    RemoveWhitespaceNodes(ChildNode.AsXmlElement());
        end;
    end;
}
