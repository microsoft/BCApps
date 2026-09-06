// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using System.Utilities;

codeunit 11347 "SEPA CT pain.001.001.03 NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEPA CT-Export File", 'OnBeforeBLOBExport', '', false, false)]
    local procedure OnBeforeBLOBExport(var TempBlob: Codeunit "Temp Blob"; CreditTransferRegister: Record "Credit Transfer Register"; UseComonDialog: Boolean; var FieldCreated: Boolean; var IsHandled: Boolean)
    var
        PaymentXmlDocument: XmlDocument;
        XmlRootElement: XmlElement;
        XmlInStream: InStream;
        XmlOutStream: OutStream;
    begin
        TempBlob.CreateInStream(XmlInStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(XmlInStream, PaymentXmlDocument);
        if not PaymentXmlDocument.GetRoot(XmlRootElement) then
            exit;
        if XmlRootElement.NamespaceUri() <> Pain00100103NamespaceTok then
            exit;

        XmlRootElement.SetAttribute('xmlns:xsi', XmlSchemaInstanceNamespaceTok);
        TempBlob.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        PaymentXmlDocument.WriteTo(XmlOutStream);
    end;

    var
        Pain00100103NamespaceTok: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03', Locked = true;
        XmlSchemaInstanceNamespaceTok: Label 'http://www.w3.org/2001/XMLSchemainstance', Locked = true;
}
