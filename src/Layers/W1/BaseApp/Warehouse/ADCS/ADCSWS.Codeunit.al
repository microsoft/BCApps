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
        InputText: Text;
        ByteOrderMark: Text[1];
    begin
        InputText := Document;
        ByteOrderMark[1] := 65279;
        if StrPos(InputText, ByteOrderMark) = 1 then
            InputText := DelStr(InputText, 1, 1);
        if InputText <> '' then
            XmlDocument.ReadFrom(InputText, InputXmlDocument);
        ADCSManagement.ProcessDocument(InputXmlDocument);
        ADCSManagement.GetOutboundDocument(OutputXmlDocument);
        OutputXmlDocument.WriteTo(Document);
    end;
}
