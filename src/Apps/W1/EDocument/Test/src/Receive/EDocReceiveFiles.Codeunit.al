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

    procedure GetAlternateNamespaceDocument(): Text
    var
        Document: Text;
        AggregateNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        BasicNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
    begin
        Document := GetLineRoundingDocument();
        Document := Document.Replace(
            StrSubstNo('xmlns:cac="%1"', AggregateNamespaceUriLbl),
            StrSubstNo('xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.2" xmlns:cac1="%1"', AggregateNamespaceUriLbl));
        Document := Document.Replace(
            StrSubstNo('xmlns:cbc="%1"', BasicNamespaceUriLbl),
            StrSubstNo('xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0" xmlns:cbc1="%1"', BasicNamespaceUriLbl));
        Document := Document.Replace('<cac:', '<cac1:').Replace('</cac:', '</cac1:');
        Document := Document.Replace('<cbc:', '<cbc1:').Replace('</cbc:', '</cbc1:');
        exit(Document);
    end;

    procedure GetSwappedNamespaceDocument(): Text
    var
        Document: Text;
        AggregateNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        BasicNamespaceUriLbl: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
    begin
        Document := GetLineRoundingDocument();
        Document := Document.Replace(
            StrSubstNo('xmlns:cac="%1"', AggregateNamespaceUriLbl),
            StrSubstNo('xmlns:temporaryAggregate="%1"', AggregateNamespaceUriLbl));
        Document := Document.Replace(
            StrSubstNo('xmlns:cbc="%1"', BasicNamespaceUriLbl),
            StrSubstNo('xmlns:temporaryBasic="%1"', BasicNamespaceUriLbl));
        Document := Document.Replace('<cac:', '<temporaryAggregate:').Replace('</cac:', '</temporaryAggregate:');
        Document := Document.Replace('<cbc:', '<temporaryBasic:').Replace('</cbc:', '</temporaryBasic:');
        Document := Document.Replace('xmlns:temporaryAggregate=', 'xmlns:cbc=').Replace('<temporaryAggregate:', '<cbc:').Replace('</temporaryAggregate:', '</cbc:');
        Document := Document.Replace('xmlns:temporaryBasic=', 'xmlns:cac=').Replace('<temporaryBasic:', '<cac:').Replace('</temporaryBasic:', '</cac:');
        exit(Document);
    end;

}