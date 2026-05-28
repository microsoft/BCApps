// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Implementer code. Inbound IO for the Contoso Ack. Pure parse — reads the XML, sets
// Msg."Status Code" and Msg."Related E-Document No." (parent resolution). State transitions
// are NOT here; they're in Type.ApplyMessage.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 6925 "Contoso Ack Reader" implements IEDocumentMessageReader
{
    Access = Internal;

    procedure ParseMessage(var Msg: Record "E-Document Message"; TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Doc: XmlDocument;
        Root: XmlElement;
        InStream: InStream;
        InvoiceNo: Text;
        StatusText: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStream, Doc) then
            exit(false);
        if not Doc.GetRoot(Root) then
            exit(false);

        InvoiceNo := SelectText(Root, 'RelatedInvoiceNumber');
        StatusText := SelectText(Root, 'Status');
        if (InvoiceNo = '') or (StatusText = '') then
            exit(false);

        // Parent resolution — find the outbound E-Document by the invoice number we sent.
        if not ResolveParent(InvoiceNo, Msg) then
            exit(false);

        Msg."Status Code" := CopyStr(UpperCase(StatusText), 1, MaxStrLen(Msg."Status Code"));
        exit(true);
    end;

    local procedure ResolveParent(InvoiceNumber: Text; var Msg: Record "E-Document Message"): Boolean
    var
        EDoc: Record "E-Document";
    begin
        EDoc.SetRange("Document No.", InvoiceNumber);
        EDoc.SetRange(Direction, EDoc.Direction::Outgoing);
        if not EDoc.FindFirst() then
            exit(false);
        Msg."Related E-Document No." := EDoc."Entry No";
        exit(true);
    end;

    local procedure SelectText(Root: XmlElement; LocalName: Text) Value: Text
    var
        Node: XmlNode;
        NsMgr: XmlNamespaceManager;
        Found: XmlElement;
    begin
        NsMgr.AddNamespace('c', 'urn:contoso:edi:messages:1.0');
        if not Root.SelectSingleNode('c:' + LocalName, NsMgr, Node) then
            exit('');
        Found := Node.AsXmlElement();
        exit(Found.InnerText());
    end;
}
