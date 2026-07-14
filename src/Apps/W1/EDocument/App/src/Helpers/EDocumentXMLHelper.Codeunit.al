// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Helpers;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Utilities;

codeunit 6410 "EDocument XML Helper"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetStringValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; MaxLength: Integer; var Field: Variant)
    var
        Value: Text;
    begin
        if not TryGetNodeValue(XMLDocument, XMLNamespaces, Path, Value) then
            exit;

        Field := CopyStr(Value, 1, MaxLength);
    end;

    procedure SetDateValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DateValue: Date)
    var
        Value: Text;
    begin
        if not TryGetNodeValue(XMLDocument, XMLNamespaces, Path, Value) then
            exit;

        if Value <> '' then
            Evaluate(DateValue, Value, 9);
    end;

    procedure SetNumberValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DecimalValue: Decimal)
    var
        Value: Text;
    begin
        if not TryGetNodeValue(XMLDocument, XMLNamespaces, Path, Value) then
            exit;

        if Value <> '' then
            Evaluate(DecimalValue, Value, 9);
    end;

    procedure SetCurrencyValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; MaxLength: Integer; var CurrencyCode: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        Value: Text;
    begin
        if not TryGetNodeValue(XMLDocument, XMLNamespaces, Path, Value) then
            exit;

        CurrencyCode := CopyStr(Value, 1, MaxLength);
        GLSetup.Get();
        if CurrencyCode = GLSetup."LCY Code" then
            CurrencyCode := '';
    end;

    procedure GetNodeValue(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text): Text
    var
        Value: Text;
    begin
        if TryGetNodeValue(XMLDocument, XMLNamespaces, Path, Value) then
            exit(Value);

        exit('');
    end;

    local procedure TryGetNodeValue(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var Value: Text): Boolean
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit(false);

        if XMLNode.IsXmlElement() then begin
            Value := XMLNode.AsXmlElement().InnerText();
            exit(true);
        end;

        if XMLNode.IsXmlAttribute() then begin
            Value := XMLNode.AsXmlAttribute().Value();
            exit(true);
        end;

        exit(false);
    end;
}
