// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

/// <summary>
/// Replaces the XML that the ZUGFeRD export embeds into the PDF with a UBL invoice,
/// so that tests get a PDF whose embedded attachment is XML but not a Cross Industry Invoice.
/// </summary>
codeunit 148504 "ZUGFeRD UBL Attachment Mock"
{
    EventSubscriberInstance = Manual;

    var
        UBLInvoiceTok: Label '<?xml version="1.0" encoding="UTF-8"?><Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"><ID>UBL-1</ID></Invoice>', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export ZUGFeRD Document", OnCreateXMLOnBeforeSalesInvXmlDocumentWriteToFile, '', false, false)]
    local procedure ReplaceInvoiceWithUBLInvoice(var XMLDoc: XmlDocument)
    begin
        XmlDocument.ReadFrom(UBLInvoiceTok, XMLDoc);
    end;
}
