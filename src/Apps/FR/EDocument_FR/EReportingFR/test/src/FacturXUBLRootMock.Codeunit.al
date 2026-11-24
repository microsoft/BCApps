// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument.Formats;

/// <summary>
/// Replaces the root element of the XML that the Factur-X export embeds into the PDF with a UBL invoice root,
/// so that tests get a PDF whose embedded attachment is XML but not a Cross Industry Invoice.
/// </summary>
codeunit 148152 "Factur-X UBL Root Mock"
{
    EventSubscriberInstance = Manual;

    var
        UBLInvoiceNamespaceTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CII XML Builder", OnBeforeAddExchangedDocumentContext, '', false, false)]
    local procedure ReplaceRootWithUBLInvoice(var RootElement: XmlElement)
    var
        UBLRootElement: XmlElement;
    begin
        UBLRootElement := XmlElement.Create('Invoice', UBLInvoiceNamespaceTok);
        RootElement.ReplaceWith(UBLRootElement);
        RootElement := UBLRootElement;
    end;
}
