// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Inbound side of ContosoInvoice — plugs into the existing V2.0 receive pipeline (IStructuredDataType
// + IStructuredFormatReader). ReadIntoDraft populates the real "E-Document Purchase Header" and
// "E-Document Purchase Line" staging tables.
//
// Also demonstrates the V3 addition to IStructuredDataType: GetSupportedMessages() — the format's
// native message vocabulary.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

codeunit 6923 "Contoso Invoice Structured" implements IStructuredDataType, IStructuredFormatReader
{
    Access = Internal;

    var
        StructuredText: Text;

    // ===== IStructuredDataType =====

    procedure GetFileFormat(): Enum "E-Doc. File Format"
    begin
        exit("E-Doc. File Format"::XML);
    end;

    procedure GetContent(): Text
    begin
        exit(StructuredText);
    end;

    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
    begin
        exit("E-Doc. Read into Draft"::"Contoso Invoice");
    end;

    /// <summary>
    /// V3 addition: the format declares its native message vocabulary.
    /// </summary>
    procedure GetSupportedMessages(): List of [Enum "E-Document Message Type"]
    var
        Native: List of [Enum "E-Document Message Type"];
    begin
        Native.Add(Enum::"E-Document Message Type"::"Contoso Invoice Ack");
        exit(Native);
    end;

    // ===== IStructuredFormatReader =====

    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    var
        PurchHeader: Record "E-Document Purchase Header";
        PurchLine: Record "E-Document Purchase Line";
        Doc: XmlDocument;
        Root: XmlElement;
        LineList: XmlNodeList;
        LineNode: XmlNode;
        InStream: InStream;
        Idx: Integer;
        AmountText: Text;
        QtyText: Text;
        UnitPriceText: Text;
        SubTotalText: Text;
        LineNoText: Text;
        InvoiceNo: Text;
    begin
        StructuredText := '';
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStream, Doc) then
            exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
        if not Doc.GetRoot(Root) then
            exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");

        InvoiceNo := ReadText(Root, 'Header/InvoiceNumber');

        // Header → staging draft. V2 processing reads from these tables, not from fields on the
        // E-Document. No Get/Modify on E-Document needed — the draft IS the structured form.
        if not PurchHeader.Get(EDocument."Entry No") then begin
            PurchHeader.Init();
            PurchHeader."E-Document Entry No." := EDocument."Entry No";
            PurchHeader.Insert();
        end;
        PurchHeader."Sales Invoice No." := CopyStr(InvoiceNo, 1, MaxStrLen(PurchHeader."Sales Invoice No."));
        if Evaluate(PurchHeader."Invoice Date", ReadText(Root, 'Header/IssueDate'), 9) then;
        if Evaluate(PurchHeader."Due Date", ReadText(Root, 'Header/DueDate'), 9) then;
        PurchHeader."Customer Company Name" := CopyStr(ReadText(Root, 'Header/CustomerName'), 1, MaxStrLen(PurchHeader."Customer Company Name"));
        PurchHeader."Customer Company Id" := CopyStr(ReadText(Root, 'Header/CustomerNo'), 1, MaxStrLen(PurchHeader."Customer Company Id"));

        ReadAmount(Root, 'Header/TotalAmount', PurchHeader.Total, PurchHeader."Currency Code");
        PurchHeader.Modify();

        // Lines → staging
        PurchLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        PurchLine.DeleteAll();

        if Root.SelectNodes('c:Lines/c:Line', NamespaceMgr(), LineList) then
            for Idx := 1 to LineList.Count() do begin
                LineList.Get(Idx, LineNode);
                Clear(PurchLine);
                PurchLine."E-Document Entry No." := EDocument."Entry No";

                LineNoText := ReadTextFromNode(LineNode, 'LineNo');
                if not Evaluate(PurchLine."Line No.", LineNoText) then
                    PurchLine."Line No." := Idx * 10000;

                PurchLine."Product Code" := CopyStr(ReadTextFromNode(LineNode, 'No'), 1, MaxStrLen(PurchLine."Product Code"));
                PurchLine.Description := CopyStr(ReadTextFromNode(LineNode, 'Description'), 1, MaxStrLen(PurchLine.Description));

                QtyText := ReadTextFromNode(LineNode, 'Quantity');
                if Evaluate(PurchLine.Quantity, QtyText, 9) then;

                UnitPriceText := ReadTextFromNode(LineNode, 'UnitPrice');
                if Evaluate(PurchLine."Unit Price", UnitPriceText, 9) then;

                SubTotalText := ReadTextFromNode(LineNode, 'LineTotal');
                if Evaluate(PurchLine."Sub Total", SubTotalText, 9) then;

                PurchLine."Currency Code" := PurchHeader."Currency Code";
                PurchLine.Insert();
            end;

        // Stash the raw text for IStructuredDataType.GetContent() — used by viewer pages.
        StructuredText := GetTextFromTempBlob(TempBlob);

        exit(Enum::"E-Doc. Process Draft"::"Purchase Invoice");
    end;

    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
        Content: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(Content);
        Message(Content);
    end;

    // ===== XML helpers =====

    local procedure NamespaceMgr(): XmlNamespaceManager
    var
        NsMgr: XmlNamespaceManager;
    begin
        NsMgr.AddNamespace('c', 'urn:contoso:edi:invoice:1.0');
        exit(NsMgr);
    end;

    local procedure ReadText(Root: XmlElement; XPath: Text): Text
    var
        Node: XmlNode;
        Found: XmlElement;
        Segments: List of [Text];
        Prefixed: Text;
        Segment: Text;
    begin
        // The XPath comes in raw (e.g., 'Header/InvoiceNumber'); prefix each segment with our namespace.
        Segments := XPath.Split('/');
        foreach Segment in Segments do
            if Prefixed = '' then
                Prefixed := 'c:' + Segment
            else
                Prefixed += '/c:' + Segment;

        if not Root.SelectSingleNode(Prefixed, NamespaceMgr(), Node) then
            exit('');
        Found := Node.AsXmlElement();
        exit(Found.InnerText());
    end;

    local procedure ReadTextFromNode(LineNode: XmlNode; LocalName: Text): Text
    var
        Node: XmlNode;
        Found: XmlElement;
    begin
        if not LineNode.SelectSingleNode('c:' + LocalName, NamespaceMgr(), Node) then
            exit('');
        Found := Node.AsXmlElement();
        exit(Found.InnerText());
    end;

    local procedure ReadAmount(Root: XmlElement; XPath: Text; var Amount: Decimal; var Currency: Code[10])
    var
        AmountText: Text;
        CurrencyText: Text;
        Node: XmlNode;
        Found: XmlElement;
        Attribute: XmlAttribute;
        Segments: List of [Text];
        Prefixed: Text;
        Segment: Text;
    begin
        Segments := XPath.Split('/');
        foreach Segment in Segments do
            if Prefixed = '' then
                Prefixed := 'c:' + Segment
            else
                Prefixed += '/c:' + Segment;

        if not Root.SelectSingleNode(Prefixed, NamespaceMgr(), Node) then
            exit;
        Found := Node.AsXmlElement();
        AmountText := Found.InnerText();
        if Evaluate(Amount, AmountText, 9) then;
        if Found.Attributes().Get('currency', Attribute) then begin
            CurrencyText := Attribute.Value();
            Currency := CopyStr(CurrencyText, 1, MaxStrLen(Currency));
        end;
    end;

    local procedure GetTextFromTempBlob(var TempBlob: Codeunit "Temp Blob") Result: Text
    var
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(Result);
    end;
}
