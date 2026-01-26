// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System;
using System.Xml;

codeunit 11308 "INTERVAT Helper"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'http://www.minfin.fgov.be/InputCommon', Locked = true;
        Text002: Label 'The email address "%1" is invalid.';
        XMLDOMMgt: Codeunit "XML DOM Management";

    procedure AddElementDeclarant(XMLCurrNode: DotNet XmlNode; SequenceNumber: Integer)
    begin
        AddElementDeclarantCustom(XMLCurrNode, SequenceNumber, '');
    end;

    procedure AddElementDeclarant(XMLCurrNode: DotNet XmlNode; SequenceNumber: Integer; Comment: Text)
    begin
        AddElementDeclarantCustom(XMLCurrNode, SequenceNumber, Comment);
    end;

    local procedure AddElementDeclarantCustom(XMLCurrNode: DotNet XmlNode; SequenceNumber: Integer; Comment: Text)
    var
        CompanyInformation: Record "Company Information";
        Country: Record "Country/Region";
        XMLNewChild: DotNet XmlNode;
        ParentNode: DotNet XmlNode;
        DeclarantReference: Text[250];
    begin
        CompanyInformation.Get();
        XMLDOMMgt.AddElement(XMLCurrNode, 'Declarant', '', XMLCurrNode.NamespaceURI, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        XMLDOMMgt.AddElement(
          XMLCurrNode, 'common:VATNumber', RemoveNonNumericCharacters(CompanyInformation."Enterprise No."), Text001, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:Name', CompanyInformation.Name, Text001, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:Street', CompanyInformation.Address, Text001, XMLNewChild);
        XMLDOMMgt.AddElement(
          XMLCurrNode, 'common:PostCode', RemoveNonNumericCharacters(CompanyInformation."Post Code"), Text001, XMLNewChild);

        XMLDOMMgt.AddElement(XMLCurrNode, 'common:City', CompanyInformation.City, Text001, XMLNewChild);
        if Country.Get(CompanyInformation."Country/Region Code") then
            XMLDOMMgt.AddElement(XMLCurrNode, 'common:CountryCode', Country."ISO Code", Text001, XMLNewChild);

        if CompanyInformation."E-Mail" <> '' then
            if IsValidEMailAddress(CompanyInformation."E-Mail") then
                XMLDOMMgt.AddElement(XMLCurrNode, 'common:EmailAddress', CompanyInformation."E-Mail", Text001, XMLNewChild)
            else
                Error(Text002, CompanyInformation."E-Mail");

        if CompanyInformation."Phone No." <> '' then
            XMLDOMMgt.AddElement(XMLCurrNode, 'common:Phone', GetValidPhoneNumber(CompanyInformation."Phone No."), Text001, XMLNewChild);
        if Comment <> '' then
            XMLDOMMgt.AddElement(XMLCurrNode, 'common:Comment', Comment, Text001, XMLNewChild);

        DeclarantReference := GetDeclarantReference(SequenceNumber);

        ParentNode := XMLCurrNode.ParentNode;
        XMLDOMMgt.AddAttribute(ParentNode, 'DeclarantReference', DeclarantReference);
    end;

    procedure GetDeclarantReference(SequenceNumber: Integer): Text[250]
    var
        CompanyInformation: Record "Company Information";
        DeclarantReference: Text[250];
    begin
        CompanyInformation.Get();
        DeclarantReference :=
          PadStr('', 4 - StrLen(Format(SequenceNumber)), '0') + Format(SequenceNumber);
        DeclarantReference := RemoveNonNumericCharacters(CompanyInformation."Enterprise No.") + DeclarantReference;

        exit(DeclarantReference);
    end;

    procedure GetReplacedVATDeclaration(SequenceNumber: Integer; Period: Integer; Year: Integer): Text[250]
    var
        CompanyInformation: Record "Company Information";
        DeclarantReference: Text[250];
        DeclarantReferenceTok: Label '%1-%2-%3%4', Locked = true;
    begin
        CompanyInformation.Get();
        DeclarantReference := StrSubstNo(DeclarantReferenceTok, Format(SequenceNumber), RemoveNonNumericCharacters(CompanyInformation."Enterprise No."), Format(Year), Format(Period).PadLeft(2, '0'));

        exit(DeclarantReference);
    end;

    local procedure RemoveNonNumericCharacters(InputString: Text[250]): Text[30]
    begin
        exit(DelChr(InputString, '=', DelChr(InputString, '=', '0123456789')));
    end;

    procedure AddProcessingInstruction(var XMLDocOut: DotNet XmlDocument; XMLFirstNode: DotNet XmlNode)
    var
        ProcessingInstruction: DotNet XmlProcessingInstruction;
    begin
        ProcessingInstruction := XMLDocOut.CreateProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"');
        XMLDocOut.InsertBefore(ProcessingInstruction, XMLFirstNode);
    end;

    procedure IsValidEMailAddress(EMailAddress: Text[80]): Boolean
    var
        i: Integer;
        HasAtSign: Boolean;
    begin
        if EMailAddress = '' then
            exit(true);

        for i := 1 to StrLen(EMailAddress) do
            if EMailAddress[i] = '@' then begin
                if i in [1, StrLen(EMailAddress)] then
                    exit(false);
                if HasAtSign then
                    exit(false);
                HasAtSign := true;
            end else
                if not (IsAlphaNumeric(EMailAddress[i]) or (EMailAddress[i] in ['@', '.', '-', '_'])) then
                    exit(false);

        if not HasAtSign then
            exit(false);

        exit(true);
    end;

    local procedure IsAlphaNumeric(Char: Char): Boolean
    begin
        exit(Char in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z']);
    end;

    procedure GetValidPhoneNumber(Phone: Text[30]): Text[21]
    begin
        if Phone[1] = '+' then
            exit('+' + RemoveNonNumericCharacters(Phone));

        exit(RemoveNonNumericCharacters(Phone));
    end;

    procedure AddElementPeriod(XMLCurrNode: DotNet XmlNode; ChoicePeriodType: Option Month,Quarter; Period: Integer; Year: Integer; PeriodName: Text[30])
    var
        XMLNewChild: DotNet XmlNode;
    begin
        if PeriodName = '' then
            PeriodName := 'Period';

        XMLDOMMgt.AddElement(XMLCurrNode, PeriodName, '', XMLCurrNode.NamespaceURI, XMLNewChild);

        XMLCurrNode := XMLNewChild;
        if ChoicePeriodType = ChoicePeriodType::Quarter then
            XMLDOMMgt.AddElement(XMLCurrNode, 'Quarter', Format(Period), XMLCurrNode.NamespaceURI, XMLNewChild)
        else
            XMLDOMMgt.AddElement(XMLCurrNode, 'Month', Format(Period), XMLCurrNode.NamespaceURI, XMLNewChild);

        XMLDOMMgt.AddElement(XMLCurrNode, 'Year', Format(Year), XMLCurrNode.NamespaceURI, XMLNewChild);
    end;

    procedure GetXMLAmountRepresentation(Amount: Decimal): Text[100]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    procedure GetCpyInfoCountryRegionCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    procedure VerifyCpyInfoEmailExists()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField("E-Mail");
    end;
}

