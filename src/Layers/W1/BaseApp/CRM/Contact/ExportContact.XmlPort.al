// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using System.Utilities;

xmlport 5050 "Export Contact"
{
    Caption = 'Export Contact';
    Direction = Export;
    Format = VariableText;
    TableSeparator = '<NewLine>';
    TextEncoding = UTF8;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Integer; Integer)
            {
                XmlName = 'ContactHeader';
                SourceTableView = sorting(Number) where(Number = const(1));
                textelement(ContNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContNoTitle := Contact.FieldCaption("No.");
                    end;
                }
                textelement(ContExternalIDTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExternalIDTitle := Contact.FieldCaption("External ID");
                    end;
                }
                textelement(ContNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContNameTitle := Contact.FieldCaption(Name);
                    end;
                }
                textelement(ContName2Title)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContName2Title := Contact.FieldCaption("Name 2");
                    end;
                }
                textelement(ContAddressTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddressTitle := Contact.FieldCaption(Address);
                    end;
                }
                textelement(ContAddress2Title)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddress2Title := Contact.FieldCaption("Address 2");
                    end;
                }
                textelement(ContCountyTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCountyTitle := Contact.FieldCaption(County);
                    end;
                }
                textelement(ContPostCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPostCodeTitle := Contact.FieldCaption("Post Code");
                    end;
                }
                textelement(ContCityTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCityTitle := Contact.FieldCaption(City);
                    end;
                }
                textelement(ContCountryRegionCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCountryRegionCodeTitle := Contact.FieldCaption("Country/Region Code");
                    end;
                }
                textelement(ContPhoneNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPhoneNoTitle := Contact.FieldCaption("Phone No.");
                    end;
                }
                textelement(ContTelexNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexNoTitle := Contact.FieldCaption("Telex No.");
                    end;
                }
                textelement(ContFaxNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFaxNoTitle := Contact.FieldCaption("Fax No.");
                    end;
                }
                textelement(ContTelexAnswerBackTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexAnswerBackTitle := Contact.FieldCaption("Telex Answer Back");
                    end;
                }
                textelement(ContTerritoryCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTerritoryCodeTitle := Contact.FieldCaption("Territory Code");
                    end;
                }
                textelement(ContCurrencyCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCurrencyCodeTitle := Contact.FieldCaption("Currency Code");
                    end;
                }
                textelement(ContLanguageCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContLanguageCodeTitle := Contact.FieldCaption("Language Code");
                    end;
                }
                textelement(ContSalespersonCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalespersonCodeTitle := Contact.FieldCaption("Salesperson Code");
                    end;
                }
                textelement(ContVATRegistrationNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContVATRegistrationNoTitle := Contact.FieldCaption("VAT Registration No.");
                    end;
                }
                textelement("ContE-MailTitle")
                {

                    trigger OnBeforePassVariable()
                    begin
                        "ContE-MailTitle" := Contact.FieldCaption("E-Mail");
                    end;
                }
                textelement(ContHomePageTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContHomePageTitle := Contact.FieldCaption("Home Page");
                    end;
                }
                textelement(ContTypeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTypeTitle := Contact.FieldCaption(Type);
                    end;
                }
                textelement(ContCompanyNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyNameTitle := Contact.FieldCaption("Company Name");
                    end;
                }
                textelement(ContCompanyNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyNoTitle := Contact.FieldCaption("Company No.");
                    end;
                }
                textelement(ContFirstNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFirstNameTitle := Contact.FieldCaption("First Name");
                    end;
                }
                textelement(ContMiddleNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMiddleNameTitle := Contact.FieldCaption("Middle Name");
                    end;
                }
                textelement(ContSurnameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSurnameTitle := Contact.FieldCaption(Surname);
                    end;
                }
                textelement(ContJobTitleTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContJobTitleTitle := Contact.FieldCaption("Job Title");
                    end;
                }
                textelement(ContInitialsTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContInitialsTitle := Contact.FieldCaption(Initials);
                    end;
                }
                textelement(ContExtensionNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExtensionNoTitle := Contact.FieldCaption("Extension No.");
                    end;
                }
                textelement(ContMobilePhoneNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMobilePhoneNoTitle := Contact.FieldCaption("Mobile Phone No.");
                    end;
                }
                textelement(ContPagerTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPagerTitle := Contact.FieldCaption(Pager);
                    end;
                }
                textelement(ContOrganizationalLevelCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContOrganizationalLevelCodeTitle := Contact.FieldCaption("Organizational Level Code");
                    end;
                }
                textelement(ContExcludefromSegmentTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExcludefromSegmentTitle := Contact.FieldCaption("Exclude from Segment");
                    end;
                }
                textelement(ContCorrespondenceTypeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCorrespondenceTypeTitle := Contact.FieldCaption("Correspondence Type");
                    end;
                }
                textelement(ContSalutationCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalutationCodeTitle := Contact.FieldCaption("Salutation Code");
                    end;
                }
            }
            tableelement(Contact; Contact)
            {
                RequestFilterFields = "No.";
                XmlName = 'Contact';
                fieldelement(No; Contact."No.")
                {
                }
                fieldelement(ExternalID; Contact."External ID")
                {
                }
                fieldelement(Name; Contact.Name)
                {
                }
                fieldelement(Name2; Contact."Name 2")
                {
                }
                fieldelement(Address; Contact.Address)
                {
                }
                fieldelement(Address2; Contact."Address 2")
                {
                }
                fieldelement(County; Contact.County)
                {
                }
                fieldelement(PostCode; Contact."Post Code")
                {
                }
                fieldelement(City; Contact.City)
                {
                }
                fieldelement(CountryRegionCode; Contact."Country/Region Code")
                {
                }
                fieldelement(PhoneNo; Contact."Phone No.")
                {
                }
                fieldelement(TelexNo; Contact."Telex No.")
                {
                }
                fieldelement(FaxNo; Contact."Fax No.")
                {
                }
                fieldelement(TelexAnswerBack; Contact."Telex Answer Back")
                {
                }
                fieldelement(TerritoryCide; Contact."Territory Code")
                {
                }
                fieldelement(CurrencyCode; Contact."Currency Code")
                {
                }
                fieldelement(LanguageCode; Contact."Language Code")
                {
                }
                fieldelement(SalespersonCode; Contact."Salesperson Code")
                {
                }
                fieldelement(VatRegistrationNo; Contact."VAT Registration No.")
                {
                }
                fieldelement("E-Mail"; Contact."E-Mail")
                {
                }
                fieldelement(HomePage; Contact."Home Page")
                {
                }
                fieldelement(Type; Contact.Type)
                {
                }
                fieldelement(CompanyName; Contact."Company Name")
                {
                }
                fieldelement(CompanyNo; Contact."Company No.")
                {
                }
                fieldelement(FirstName; Contact."First Name")
                {
                }
                fieldelement(MiddleName; Contact."Middle Name")
                {
                }
                fieldelement(SurName; Contact.Surname)
                {
                }
                fieldelement(Jobtitle; Contact."Job Title")
                {
                }
                fieldelement(Initials; Contact.Initials)
                {
                }
                fieldelement(ExtensionNo; Contact."Extension No.")
                {
                }
                fieldelement(MobilePhoneNo; Contact."Mobile Phone No.")
                {
                }
                fieldelement(Pager; Contact.Pager)
                {
                }
                fieldelement(OrganizationalLevelCode; Contact."Organizational Level Code")
                {
                }
                fieldelement(ExcludefromSegment; Contact."Exclude from Segment")
                {
                }
                fieldelement(CorrespondanceType; Contact."Correspondence Type")
                {
                }
                fieldelement(SalutationCode; Contact."Salutation Code")
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}

