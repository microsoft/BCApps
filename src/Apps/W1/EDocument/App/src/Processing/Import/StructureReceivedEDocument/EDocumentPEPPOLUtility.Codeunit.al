// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

codeunit 6401 "E-Document PEPPOL Utility"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure InitializePEPPOL3Namespaces(var XmlNamespaces: XmlNamespaceManager)
    var
        CommonAggregateComponentsLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2';
        CommonBasicComponentsLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
        DocumentationLbl: Label 'urn:un:unece:uncefact:documentation:2';
        QualifiedDatatypesLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:QualifiedDatatypes-2';
        UnqualifiedDataTypesSchemaModuleLbl: Label 'urn:un:unece:uncefact:data:specification:UnqualifiedDataTypesSchemaModule:2';
        DefaultInvoiceLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
        DefaultCreditNoteLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
    begin
        XmlNamespaces.AddNamespace('cac', CommonAggregateComponentsLbl);
        XmlNamespaces.AddNamespace('cbc', CommonBasicComponentsLbl);
        XmlNamespaces.AddNamespace('ccts', DocumentationLbl);
        XmlNamespaces.AddNamespace('qdt', QualifiedDatatypesLbl);
        XmlNamespaces.AddNamespace('udt', UnqualifiedDataTypesSchemaModuleLbl);
        XmlNamespaces.AddNamespace('inv', DefaultInvoiceLbl);
        XmlNamespaces.AddNamespace('cre', DefaultCreditNoteLbl);
    end;

    procedure TryGetStringValue(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var Value: Text): Boolean
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

    procedure SetNumberValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DecimalValue: Decimal)
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        if not XMLNode.IsXmlElement() then
            exit;

        if XMLNode.AsXmlElement().InnerText() <> '' then
            Evaluate(DecimalValue, XMLNode.AsXmlElement().InnerText(), 9);
    end;

    procedure SetDateValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; var DateValue: Date)
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        if not XMLNode.IsXmlElement() then
            exit;

        if XMLNode.AsXmlElement().InnerText() <> '' then
            Evaluate(DateValue, XMLNode.AsXmlElement().InnerText(), 9);
    end;

}
