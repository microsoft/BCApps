// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6401 "E-Document XML Helper"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure InitializePEPPOLNamespaces(var XmlNamespaces: XmlNamespaceManager)
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

#pragma warning disable AA0139 // false positive: overflow handled by MaxLength parameter
    procedure SetStringValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; MaxLength: Integer; var Field: Text)
    var
        XMLNode: XmlNode;
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        if XMLNode.IsXmlElement() then begin
            Field := CopyStr(XMLNode.AsXmlElement().InnerText(), 1, MaxLength);
            exit;
        end;

        if XMLNode.IsXmlAttribute() then begin
            Field := CopyStr(XMLNode.AsXmlAttribute().Value(), 1, MaxLength);
            exit;
        end;
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

    procedure SetCurrencyValueInField(XMLDocument: XmlDocument; XMLNamespaces: XmlNamespaceManager; Path: Text; MaxLength: Integer; var CurrencyField: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
        XMLNode: XmlNode;
        CurrencyCode: Code[10];
    begin
        if not XMLDocument.SelectSingleNode(Path, XMLNamespaces, XMLNode) then
            exit;

        GLSetup.GetRecordOnce();

        if XMLNode.IsXmlElement() then begin
            CurrencyCode := CopyStr(XMLNode.AsXmlElement().InnerText(), 1, MaxLength);
            if GLSetup."LCY Code" <> CurrencyCode then
                CurrencyField := CurrencyCode;
            exit;
        end;

        if XMLNode.IsXmlAttribute() then begin
            CurrencyCode := CopyStr(XMLNode.AsXmlAttribute().Value, 1, MaxLength);
            if GLSetup."LCY Code" <> CurrencyCode then
                CurrencyField := CurrencyCode;
            exit;
        end;
    end;
#pragma warning restore AA0139
}
