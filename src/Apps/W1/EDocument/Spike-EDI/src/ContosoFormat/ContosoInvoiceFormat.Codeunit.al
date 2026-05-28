// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// ContosoInvoice — a fictional minimal XML invoice format, bi-directional. Implements
// the existing "E-Document" interface. Real code: iterates Sales Invoice Lines via the
// RecordRef parameter, validates customer name on Check, fills basic info on receive.
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using System.Utilities;

codeunit 6922 "Contoso Invoice Format" implements "E-Document"
{
    Access = Internal;

    var
        DocumentTypeNotSupportedErr: Label '%1 value %2 is not supported by Contoso Invoice format.', Comment = '%1 = field caption, %2 = field value';
        CustomerNameMissingErr: Label 'Sell-to Customer Name is required to export a Contoso Invoice.';

    // ===== "E-Document" — outbound =====

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        case SourceDocumentHeader.Number of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    if SalesHeader."Sell-to Customer Name" = '' then
                        Error(CustomerNameMissingErr);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    if SalesInvoiceHeader."Sell-to Customer Name" = '' then
                        Error(CustomerNameMissingErr);
                end;
        end;
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        OutStream: OutStream;
        Xml: Text;
    begin
        case EDocument."Document Type" of
            EDocument."Document Type"::"Sales Invoice":
                Xml := BuildSalesInvoiceXml(SourceDocumentHeader);
            else
                EDocErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(DocumentTypeNotSupportedErr, EDocument.FieldCaption("Document Type"), EDocument."Document Type"));
        end;

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Xml);
    end;

    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        // Out of scope for the spike; matches PEPPOL implementation which is also empty.
    end;

    // ===== "E-Document" — inbound (V1.0 entry points; V2.0 uses IStructuredDataType) =====

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        Doc: XmlDocument;
        Root: XmlElement;
        InStream: InStream;
        InvNo: Text;
        Total: Decimal;
        Currency: Text;
        IssueDate: Date;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        if not XmlDocument.ReadFrom(InStream, Doc) then
            exit;
        if not Doc.GetRoot(Root) then
            exit;

        InvNo := ReadText(Root, 'InvoiceNumber');
        if InvNo <> '' then begin
            EDocument."Document No." := CopyStr(InvNo, 1, MaxStrLen(EDocument."Document No."));
            // Set "Incoming E-Document No." so EDocument.IsDuplicate() distinguishes this
            // inbound row from the outbound original (outbound rows leave it blank).
            EDocument."Incoming E-Document No." := CopyStr(InvNo, 1, MaxStrLen(EDocument."Incoming E-Document No."));
        end;

        if ReadAmount(Root, 'TotalAmount', Total, Currency) then begin
            EDocument."Amount Incl. VAT" := Total;
            EDocument."Currency Code" := CopyStr(Currency, 1, MaxStrLen(EDocument."Currency Code"));
        end;

        if Evaluate(IssueDate, ReadText(Root, 'IssueDate'), 9) then
            EDocument."Document Date" := IssueDate;
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        // V1.0 inbound pipeline. V2.0 (preferred) routes through "Contoso Invoice Structured"
        // which implements IStructuredDataType + IStructuredFormatReader.
    end;

    // ===== XML build =====

    local procedure BuildSalesInvoiceXml(var SourceDocumentHeader: RecordRef): Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        Sb: TextBuilder;
    begin
        SourceDocumentHeader.SetTable(SalesInvHeader);

        Sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Sb.AppendLine('<ContosoInvoice xmlns="urn:contoso:edi:invoice:1.0">');
        Sb.AppendLine('  <Header>');
        Sb.AppendLine(StrSubstNo('    <InvoiceNumber>%1</InvoiceNumber>', SalesInvHeader."No."));
        Sb.AppendLine(StrSubstNo('    <IssueDate>%1</IssueDate>', Format(SalesInvHeader."Document Date", 0, 9)));
        Sb.AppendLine(StrSubstNo('    <DueDate>%1</DueDate>', Format(SalesInvHeader."Due Date", 0, 9)));
        Sb.AppendLine(StrSubstNo('    <CustomerName>%1</CustomerName>', Xml(SalesInvHeader."Sell-to Customer Name")));
        Sb.AppendLine(StrSubstNo('    <CustomerNo>%1</CustomerNo>', SalesInvHeader."Sell-to Customer No."));

        SalesInvHeader.CalcFields("Amount Including VAT");
        Sb.AppendLine(StrSubstNo('    <TotalAmount currency="%1">%2</TotalAmount>', SalesInvHeader."Currency Code", Format(SalesInvHeader."Amount Including VAT", 0, 9)));
        Sb.AppendLine('  </Header>');

        Sb.AppendLine('  <Lines>');
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        if SalesInvLine.FindSet() then
            repeat
                Sb.AppendLine('    <Line>');
                Sb.AppendLine(StrSubstNo('      <LineNo>%1</LineNo>', SalesInvLine."Line No."));
                Sb.AppendLine(StrSubstNo('      <No>%1</No>', SalesInvLine."No."));
                Sb.AppendLine(StrSubstNo('      <Description>%1</Description>', Xml(SalesInvLine.Description)));
                Sb.AppendLine(StrSubstNo('      <Quantity>%1</Quantity>', Format(SalesInvLine.Quantity, 0, 9)));
                Sb.AppendLine(StrSubstNo('      <UnitPrice>%1</UnitPrice>', Format(SalesInvLine."Unit Price", 0, 9)));
                Sb.AppendLine(StrSubstNo('      <LineTotal>%1</LineTotal>', Format(SalesInvLine."Amount Including VAT", 0, 9)));
                Sb.AppendLine('    </Line>');
            until SalesInvLine.Next() = 0;
        Sb.AppendLine('  </Lines>');

        Sb.AppendLine('</ContosoInvoice>');
        exit(Sb.ToText());
    end;

    // ===== XML read =====

    local procedure ReadText(Root: XmlElement; LocalName: Text) Value: Text
    var
        Node: XmlNode;
        Found: XmlElement;
        NsMgr: XmlNamespaceManager;
    begin
        NsMgr.AddNamespace('c', 'urn:contoso:edi:invoice:1.0');
        if not Root.SelectSingleNode('c:' + LocalName, NsMgr, Node) then
            exit('');
        Found := Node.AsXmlElement();
        exit(Found.InnerText());
    end;

    local procedure ReadAmount(Root: XmlElement; LocalName: Text; var Amount: Decimal; var Currency: Text): Boolean
    var
        Node: XmlNode;
        Found: XmlElement;
        NsMgr: XmlNamespaceManager;
        AmountText: Text;
        Attribute: XmlAttribute;
    begin
        NsMgr.AddNamespace('c', 'urn:contoso:edi:invoice:1.0');
        if not Root.SelectSingleNode('c:' + LocalName, NsMgr, Node) then
            exit(false);
        Found := Node.AsXmlElement();
        AmountText := Found.InnerText();
        if not Evaluate(Amount, AmountText, 9) then
            exit(false);
        if Found.Attributes().Get('currency', Attribute) then
            Currency := Attribute.Value();
        exit(true);
    end;

    local procedure Xml(Source: Text): Text
    begin
        exit(Source
            .Replace('&', '&amp;')
            .Replace('<', '&lt;')
            .Replace('>', '&gt;')
            .Replace('"', '&quot;'));
    end;
}
