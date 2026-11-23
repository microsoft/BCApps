// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

codeunit 139635 "E-Doc. Receive Files"
{
    procedure GetDocument1(): Text
    begin
        exit(NavApp.GetResourceAsText('peppol/PEPPOL1.xml'));
    end;

    procedure GetLineRoundingDocument(): Text
    begin
        exit(NavApp.GetResourceAsText('peppol/PEPPOL_LineRounding.xml'));
    end;

    procedure GetCompleteAlternateInvoiceDocument(): Text
    var
        Document: Text;
        InvoiceNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;
    begin
        Document := ConvertToAlternateNamespaceAliases(GetDocument1());
        Document := Document.Replace(
            '<Invoice ',
            '<ubl:Invoice xmlns:ubl="' + InvoiceNamespaceUriLbl + '" ');
        Document := Document.Replace('</Invoice>', '</ubl:Invoice>');
        Document := Document.Replace(
            '<cac1:LegalMonetaryTotal>',
            '<cac1:LegalMonetaryTotal><cbc:TaxExclusiveAmount currencyID="GBP">9999.00</cbc:TaxExclusiveAmount>');
        Document := AddDocumentCharge(Document, '<cac1:TaxTotal>');
        exit(Document);
    end;

    procedure GetCompleteAlternateCreditNoteDocument(): Text
    var
        Document: Text;
        CreditNoteLine: Text;
        CreditNoteLineStart: Integer;
        CreditNoteNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2', Locked = true;
        BasicNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
    begin
        Document := NavApp.GetResourceAsText('peppol/peppol-creditnote-0.xml');
        Document := ConvertToAlternateNamespaceAliases(Document);
        Document := Document.Replace(
            '<CreditNote ',
            '<ubl:CreditNote xmlns:ubl="' + CreditNoteNamespaceUriLbl + '" ');
        Document := Document.Replace('</CreditNote>', '</ubl:CreditNote>');
        Document := Document.Replace(
            'xmlns:cbc1="' + BasicNamespaceUriLbl + '"',
            'xmlns:cbc1="' + BasicNamespaceUriLbl + '" xmlns:cbc2="' + BasicNamespaceUriLbl + '"');
        CreditNoteLineStart := StrPos(Document, '<cac1:CreditNoteLine>');
        CreditNoteLine := CopyStr(Document, CreditNoteLineStart);
        CreditNoteLine := CreditNoteLine.Replace('<cbc1:', '<cbc2:').Replace('</cbc1:', '</cbc2:');
        Document := CopyStr(Document, 1, CreditNoteLineStart - 1) + CreditNoteLine;
        Document := AddAttachment(Document, '<cac1:AccountingSupplierParty>');
        Document := AddDocumentCharge(Document, '<cac1:TaxTotal>');
        exit(Document);
    end;

    local procedure ConvertToAlternateNamespaceAliases(Document: Text): Text
    var
        AggregateNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        BasicNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
    begin
        Document := Document.Replace(
            'xmlns:cac="' + AggregateNamespaceUriLbl + '"',
            'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.2" xmlns:cac1="' + AggregateNamespaceUriLbl + '"');
        Document := Document.Replace(
            'xmlns:cbc="' + BasicNamespaceUriLbl + '"',
            'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0" xmlns:cbc1="' + BasicNamespaceUriLbl + '"');
        Document := Document.Replace('<cac:', '<cac1:').Replace('</cac:', '</cac1:');
        Document := Document.Replace('<cbc:', '<cbc1:').Replace('</cbc:', '</cbc1:');
        exit(Document);
    end;

    local procedure AddAttachment(Document: Text; BeforePath: Text): Text
    var
        AttachmentXmlLbl: Label '<cac1:AdditionalDocumentReference><cbc1:ID>credit-note.pdf</cbc1:ID><cac1:Attachment><cbc1:EmbeddedDocumentBinaryObject mimeCode="application/pdf" filename="credit-note.pdf">QkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQgQkMgUEVQUE9MIGNyZWRpdCBub3RlIGF0dGFjaG1lbnQg</cbc1:EmbeddedDocumentBinaryObject></cac1:Attachment></cac1:AdditionalDocumentReference>', Locked = true;
    begin
        exit(Document.Replace(BeforePath, AttachmentXmlLbl + BeforePath));
    end;

    local procedure AddDocumentCharge(Document: Text; BeforePath: Text): Text
    var
        ChargeXmlLbl: Label '<cac1:AllowanceCharge><cbc1:ChargeIndicator>true</cbc1:ChargeIndicator><cbc1:AllowanceChargeReason>Handling charge</cbc1:AllowanceChargeReason><cbc1:Amount currencyID="GBP">25</cbc1:Amount></cac1:AllowanceCharge>', Locked = true;
    begin
        exit(Document.Replace(BeforePath, ChargeXmlLbl + BeforePath));
    end;

}