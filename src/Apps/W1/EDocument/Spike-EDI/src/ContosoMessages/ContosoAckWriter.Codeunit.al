// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// Implementer code. Outbound IO for the Contoso Ack. Pure generate — builds the XML and sets
// Msg."Status Code". Transport via IDocumentSender (handled by framework). Post-send transition
// happens via Type.ApplyMessage (also framework-driven).
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 6926 "Contoso Ack Writer" implements IEDocumentMessageWriter
{
    Access = Internal;

    procedure GenerateMessage(Related: Record "E-Document"; var Msg: Record "E-Document Message"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        OutStream: OutStream;
        Sb: TextBuilder;
    begin
        // Spike: hardcode status to ACCEPTED. Production: a Generate Context (or pre-call prompt
        // via the modal) would capture user choice (Accept / Reject).
        if Msg."Status Code" = '' then
            Msg."Status Code" := 'ACCEPTED';

        Sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>');
        Sb.AppendLine('<ContosoInvoiceAck xmlns="urn:contoso:edi:messages:1.0">');
        Sb.AppendLine(StrSubstNo('  <RelatedInvoiceNumber>%1</RelatedInvoiceNumber>', Related."Document No."));
        Sb.AppendLine(StrSubstNo('  <Status>%1</Status>', Msg."Status Code"));
        Sb.AppendLine(StrSubstNo('  <ResponseDate>%1</ResponseDate>', Format(CurrentDateTime(), 0, 9)));
        Sb.AppendLine('</ContosoInvoiceAck>');

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Sb.ToText());
        exit(true);
    end;
}
