// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;
using System;
using System.Xml;

table 11308 Representative
{
    Caption = 'Representative';
    DrillDownPageID = "Representative List";
    LookupPageID = "Representative List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Text[20])
        {
            Caption = 'ID';
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "E-Mail"; Text[50])
        {
            Caption = 'E-Mail';

            trigger OnValidate()
            begin
                if not INTERVATHelper.IsValidEMailAddress("E-Mail") then
                    Error(Text002, "E-Mail");
            end;
        }
        field(5; Phone; Text[21])
        {
            Caption = 'Phone';
        }
        field(6; "Issued by"; Code[10])
        {
            Caption = 'Issued by';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region" where("EU Country/Region Code" = filter(<> ''));
        }
        field(7; "Identification Type"; Option)
        {
            Caption = 'Identification Type';
            OptionCaption = ' ,NVAT,TIN';
            OptionMembers = " ",NVAT,TIN;

            trigger OnValidate()
            begin
                if ("Identification Type" < 0) or ("Identification Type" > 2) then
                    Error(Text001, "Identification Type");
            end;
        }
        field(8; Address; Text[50])
        {
            Caption = 'Address';
        }
        field(9; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(10; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12; County; Text[30])
        {
            Caption = 'County';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label 'Unsupported value ''%1'' for Representative Identification Type.';
        Text002: Label 'The email address "%1" is invalid.';
        Text003: Label 'http://www.minfin.fgov.be/InputCommon', Locked = true;
        Text004: Label 'You have indicated that representative should be included. You must specify mandatory fields : %1.';
        PostCode: Record "Post Code";
        INTERVATHelper: Codeunit "INTERVAT Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";

    procedure CheckCompletion(): Boolean
    var
        ListOfFields: Text[250];
    begin
        ListOfFields := GetListOfEmptyFields();
        if ListOfFields <> '' then
            Error(Text004, ListOfFields);
        exit(true);
    end;

    local procedure GetListOfEmptyFields(): Text[250]
    var
        ListOfFields: Text[250];
    begin
        ListOfFields := '';
        if "Identification Type" = 0 then
            AddFieldNameToList(FieldCaption("Identification Type"), ListOfFields);
        if ID = '' then
            AddFieldNameToList(FieldCaption(ID), ListOfFields);
        if Name = '' then
            AddFieldNameToList(FieldCaption(Name), ListOfFields);
        if "E-Mail" = '' then
            AddFieldNameToList(FieldCaption("E-Mail"), ListOfFields);
        if Phone = '' then
            AddFieldNameToList(FieldCaption(Phone), ListOfFields);
        if "Issued by" = '' then
            AddFieldNameToList(FieldCaption("Issued by"), ListOfFields);
        if Address = '' then
            AddFieldNameToList(FieldCaption(Address), ListOfFields);
        if City = '' then
            AddFieldNameToList(FieldCaption(City), ListOfFields);
        if "Post Code" = '' then
            AddFieldNameToList(FieldCaption("Post Code"), ListOfFields);
        if "Country/Region Code" = '' then
            AddFieldNameToList(FieldCaption("Country/Region Code"), ListOfFields);
        exit(ListOfFields);
    end;

    local procedure AddFieldNameToList(FieldName: Text[50]; var List: Text[250])
    var
        Delimiter: Text[2];
    begin
        Delimiter := ', ';
        if List = '' then
            Delimiter := '';
        List := List + Delimiter + FieldName;
    end;

    [Scope('OnPrem')]
    procedure AddRepresentativeElement(XMLCurrNode: DotNet XmlNode; NameSpace: Text[250]; SequenceNumber: Integer)
    var
        XMLNewChild: DotNet XmlNode;
        ParentNode: DotNet XmlNode;
        CreatedXMLNode: DotNet XmlNode;
        RepresentativeReference: Text[50];
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'Representative', '', NameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        XMLDOMMgt.AddElement(XMLCurrNode, 'common:RepresentativeID', ID, Text003, XMLNewChild);
        XMLDOMMgt.AddAttribute(XMLNewChild, 'issuedBy', "Issued by");
        XMLDOMMgt.AddAttribute(XMLNewChild, 'identificationType', Format("Identification Type"));
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:Name', Name, Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:Street', Address, Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:PostCode', "Post Code", Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:City', City, Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:CountryCode', "Country/Region Code", Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:EmailAddress', "E-Mail", Text003, XMLNewChild);
        XMLDOMMgt.AddElement(XMLCurrNode, 'common:Phone', INTERVATHelper.GetValidPhoneNumber(Phone), Text003, XMLNewChild);

        RepresentativeReference :=
          PadStr('', 4 - StrLen(Format(SequenceNumber)), '0') + Format(SequenceNumber);

        ParentNode := XMLCurrNode.ParentNode;
        XMLDOMMgt.AddElement(
          ParentNode, 'RepresentativeReference', RepresentativeReference,
          XMLCurrNode.NamespaceURI,
          CreatedXMLNode)
    end;

    [Scope('OnPrem')]
    procedure LookupIssuedBy(var EntrdValue: Text[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
        CountryRegion.Code := "Issued by";
        if PAGE.RunModal(0, CountryRegion) <> ACTION::LookupOK then
            exit(false);

        EntrdValue := CountryRegion.Code;
        "Issued by" := CountryRegion.Code;
        exit(true);
    end;
}

