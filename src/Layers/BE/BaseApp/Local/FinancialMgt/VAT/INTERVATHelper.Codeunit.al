// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
#if not CLEAN30
using System;
#endif
using System.Utilities;

codeunit 11308 "INTERVAT Helper"
{

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'http://www.minfin.fgov.be/InputCommon', Locked = true;
        Text002: Label 'The email address "%1" is invalid.';

#if not CLEAN30
    [Obsolete('Use AddElementDeclarant with an XmlElement parameter instead.', '30.0')]
    procedure AddElementDeclarant(XMLCurrNode: DotNet XmlNode; SequenceNumber: Integer)
    begin
        AddElementDeclarantCustom(XMLCurrNode, SequenceNumber, '');
    end;

    [Obsolete('Use AddElementDeclarant with an XmlElement parameter instead.', '30.0')]
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
        AddDotNetElement(XMLCurrNode, 'Declarant', '', XMLCurrNode.NamespaceURI, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        AddDotNetElement(
          XMLCurrNode, 'common:VATNumber', RemoveNonNumericCharacters(CompanyInformation."Enterprise No."), Text001, XMLNewChild);
        AddDotNetElement(XMLCurrNode, 'common:Name', CompanyInformation.Name, Text001, XMLNewChild);
        AddDotNetElement(XMLCurrNode, 'common:Street', CompanyInformation.Address, Text001, XMLNewChild);
        AddDotNetElement(
          XMLCurrNode, 'common:PostCode', RemoveNonNumericCharacters(CompanyInformation."Post Code"), Text001, XMLNewChild);

        AddDotNetElement(XMLCurrNode, 'common:City', CompanyInformation.City, Text001, XMLNewChild);
        if Country.Get(CompanyInformation."Country/Region Code") then
            AddDotNetElement(XMLCurrNode, 'common:CountryCode', Country."ISO Code", Text001, XMLNewChild);

        if CompanyInformation."E-Mail" <> '' then
            if IsValidEMailAddress(CompanyInformation."E-Mail") then
                AddDotNetElement(XMLCurrNode, 'common:EmailAddress', CompanyInformation."E-Mail", Text001, XMLNewChild)
            else
                Error(Text002, CompanyInformation."E-Mail");

        if CompanyInformation."Phone No." <> '' then
            AddDotNetElement(XMLCurrNode, 'common:Phone', GetValidPhoneNumber(CompanyInformation."Phone No."), Text001, XMLNewChild);
        if Comment <> '' then
            AddDotNetElement(XMLCurrNode, 'common:Comment', Comment, Text001, XMLNewChild);

        DeclarantReference := GetDeclarantReference(SequenceNumber);

        ParentNode := XMLCurrNode.ParentNode;
        AddDotNetAttribute(ParentNode, 'DeclarantReference', DeclarantReference);
    end;

    local procedure AddDotNetElement(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode)
    begin
        CreatedXMLNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if NodeText <> '' then
            CreatedXMLNode.InnerText := NodeText;
        XMLNode.AppendChild(CreatedXMLNode);
    end;

    local procedure AddDotNetAttribute(var XMLNode: DotNet XmlNode; Name: Text; NodeValue: Text)
    var
        XMLNewAttributeNode: DotNet XmlNode;
    begin
        XMLNewAttributeNode := XMLNode.OwnerDocument.CreateAttribute(Name);
        if NodeValue <> '' then
            XMLNewAttributeNode.Value := NodeValue;
        XMLNode.Attributes.SetNamedItem(XMLNewAttributeNode);
    end;
#endif

    /// <summary>
    /// Adds the Declarant element, built from the company information, as a child of the specified element
    /// and sets the DeclarantReference attribute on the specified element.
    /// The 'common' prefix for the http://www.minfin.fgov.be/InputCommon namespace must be declared on an ancestor element.
    /// </summary>
    procedure AddElementDeclarant(ParentElement: XmlElement; SequenceNumber: Integer)
    begin
        AddDeclarantElement(ParentElement, SequenceNumber, '');
    end;

    /// <summary>
    /// Adds the Declarant element, built from the company information and the specified comment, as a child of the specified element
    /// and sets the DeclarantReference attribute on the specified element.
    /// The 'common' prefix for the http://www.minfin.fgov.be/InputCommon namespace must be declared on an ancestor element.
    /// </summary>
    procedure AddElementDeclarant(ParentElement: XmlElement; SequenceNumber: Integer; Comment: Text)
    begin
        AddDeclarantElement(ParentElement, SequenceNumber, Comment);
    end;

    local procedure AddDeclarantElement(ParentElement: XmlElement; SequenceNumber: Integer; Comment: Text)
    var
        CompanyInformation: Record "Company Information";
        Country: Record "Country/Region";
        DeclarantElement: XmlElement;
    begin
        CompanyInformation.Get();
        DeclarantElement := XmlElement.Create('Declarant', ParentElement.NamespaceUri());
        ParentElement.Add(DeclarantElement);
        AddChildElement(DeclarantElement, 'VATNumber', RemoveNonNumericCharacters(CompanyInformation."Enterprise No."), Text001);
        AddChildElement(DeclarantElement, 'Name', CompanyInformation.Name, Text001);
        AddChildElement(DeclarantElement, 'Street', CompanyInformation.Address, Text001);
        AddChildElement(DeclarantElement, 'PostCode', RemoveNonNumericCharacters(CompanyInformation."Post Code"), Text001);

        AddChildElement(DeclarantElement, 'City', CompanyInformation.City, Text001);
        if Country.Get(CompanyInformation."Country/Region Code") then
            AddChildElement(DeclarantElement, 'CountryCode', Country."ISO Code", Text001);

        if CompanyInformation."E-Mail" <> '' then
            if IsValidEMailAddress(CompanyInformation."E-Mail") then
                AddChildElement(DeclarantElement, 'EmailAddress', CompanyInformation."E-Mail", Text001)
            else
                Error(Text002, CompanyInformation."E-Mail");

        if CompanyInformation."Phone No." <> '' then
            AddChildElement(DeclarantElement, 'Phone', GetValidPhoneNumber(CompanyInformation."Phone No."), Text001);
        if Comment <> '' then
            AddChildElement(DeclarantElement, 'Comment', Comment, Text001);

        ParentElement.SetAttribute('DeclarantReference', GetDeclarantReference(SequenceNumber));
    end;

    local procedure AddChildElement(ParentElement: XmlElement; LocalName: Text; Value: Text; NamespaceUri: Text)
    var
        ChildElement: XmlElement;
    begin
        ChildElement := XmlElement.Create(LocalName, NamespaceUri);
        if Value <> '' then
            ChildElement.Add(XmlText.Create(Value));
        ParentElement.Add(ChildElement);
    end;

    /// <summary>
    /// Writes an INTERVAT document to the specified stream as UTF-8 without a byte order mark.
    /// </summary>
    internal procedure WriteDocument(XmlDoc: XmlDocument; var TargetOutStream: OutStream)
    var
        TempBlob: Codeunit "Temp Blob";
        RootElement: XmlElement;
        ChildElement: XmlElement;
        ChildNode: XmlNode;
        XmlOutStream: OutStream;
        XmlInStream: InStream;
    begin
        // The INTERVAT files have always redeclared the default namespace on each child of the root element.
        XmlDoc.GetRoot(RootElement);
        foreach ChildNode in RootElement.GetChildElements() do begin
            ChildElement := ChildNode.AsXmlElement();
            ChildElement.Add(XmlAttribute.Create('xmlns', ChildElement.NamespaceUri()));
        end;

        TempBlob.CreateOutStream(XmlOutStream);
        XmlDoc.WriteTo(XmlOutStream);
        TempBlob.CreateInStream(XmlInStream);
        CopyWithoutByteOrderMark(XmlInStream, TargetOutStream);
    end;

    local procedure CopyWithoutByteOrderMark(var SourceInStream: InStream; var TargetOutStream: OutStream)
    var
        Bytes: array[3] of Byte;
        BytesRead: Integer;
        i: Integer;
    begin
        for i := 1 to 3 do
            BytesRead += SourceInStream.Read(Bytes[i]);
        if not ((BytesRead = 3) and (Bytes[1] = 239) and (Bytes[2] = 187) and (Bytes[3] = 191)) then
            for i := 1 to BytesRead do
                TargetOutStream.Write(Bytes[i]);
        CopyStream(TargetOutStream, SourceInStream);
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

#if not CLEAN30
    [Obsolete('Create the native XmlDocument with XmlDocument.ReadFrom, including the <?xml version="1.0" encoding="UTF-8"?> declaration, instead.', '30.0')]
    procedure AddProcessingInstruction(var XMLDocOut: DotNet XmlDocument; XMLFirstNode: DotNet XmlNode)
    var
        ProcessingInstruction: DotNet XmlProcessingInstruction;
    begin
        ProcessingInstruction := XMLDocOut.CreateProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"');
        XMLDocOut.InsertBefore(ProcessingInstruction, XMLFirstNode);
    end;
#endif

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

#if not CLEAN30
    [Obsolete('Use AddElementPeriod with an XmlElement parameter instead.', '30.0')]
    procedure AddElementPeriod(XMLCurrNode: DotNet XmlNode; ChoicePeriodType: Option Month,Quarter; Period: Integer; Year: Integer; PeriodName: Text[30])
    var
        XMLNewChild: DotNet XmlNode;
    begin
        if PeriodName = '' then
            PeriodName := 'Period';

        AddDotNetElement(XMLCurrNode, PeriodName, '', XMLCurrNode.NamespaceURI, XMLNewChild);

        XMLCurrNode := XMLNewChild;
        if ChoicePeriodType = ChoicePeriodType::Quarter then
            AddDotNetElement(XMLCurrNode, 'Quarter', Format(Period), XMLCurrNode.NamespaceURI, XMLNewChild)
        else
            AddDotNetElement(XMLCurrNode, 'Month', Format(Period), XMLCurrNode.NamespaceURI, XMLNewChild);

        AddDotNetElement(XMLCurrNode, 'Year', Format(Year), XMLCurrNode.NamespaceURI, XMLNewChild);
    end;
#endif

    /// <summary>
    /// Adds a period element (named Period unless another name is specified) with the month or quarter and the year
    /// as a child of the specified element. The period element is returned.
    /// </summary>
    procedure AddElementPeriod(ParentElement: XmlElement; ChoicePeriodType: Option Month,Quarter; Period: Integer; Year: Integer; PeriodName: Text[30]) PeriodElement: XmlElement
    begin
        if PeriodName = '' then
            PeriodName := 'Period';

        PeriodElement := XmlElement.Create(PeriodName, ParentElement.NamespaceUri());
        ParentElement.Add(PeriodElement);
        if ChoicePeriodType = ChoicePeriodType::Quarter then
            AddChildElement(PeriodElement, 'Quarter', Format(Period), PeriodElement.NamespaceUri())
        else
            AddChildElement(PeriodElement, 'Month', Format(Period), PeriodElement.NamespaceUri());

        AddChildElement(PeriodElement, 'Year', Format(Year), PeriodElement.NamespaceUri());
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

