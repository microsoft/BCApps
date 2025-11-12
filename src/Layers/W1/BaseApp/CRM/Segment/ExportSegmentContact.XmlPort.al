// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;
using System.Utilities;

xmlport 5051 "Export Segment Contact"
{
    Caption = 'Export Segment Contact';
    Direction = Export;
    Format = VariableText;
    TableSeparator = '<NewLine>';
    TextEncoding = UTF8;

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
                        ContNoTitle := Cont.FieldCaption("No.");
                    end;
                }
                textelement(ContExternalIDTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExternalIDTitle := Cont.FieldCaption("External ID");
                    end;
                }
                textelement(ContNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContNameTitle := Cont.FieldCaption(Name);
                    end;
                }
                textelement(ContName2Title)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContName2Title := Cont.FieldCaption("Name 2");
                    end;
                }
                textelement(ContAddressTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddressTitle := Cont.FieldCaption(Address);
                    end;
                }
                textelement(ContAddress2Title)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddress2Title := Cont.FieldCaption("Address 2");
                    end;
                }
                textelement(ContCountyTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCountyTitle := Cont.FieldCaption(County);
                    end;
                }
                textelement(ContPostCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPostCodeTitle := Cont.FieldCaption("Post Code");
                    end;
                }
                textelement(ContCityTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCityTitle := Cont.FieldCaption(City);
                    end;
                }
                textelement(ContCountryRegionCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCountryRegionCodeTitle := Cont.FieldCaption("Country/Region Code");
                    end;
                }
                textelement(ContPhoneNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPhoneNoTitle := Cont.FieldCaption("Phone No.");
                    end;
                }
                textelement(ContTelexNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexNoTitle := Cont.FieldCaption("Telex No.");
                    end;
                }
                textelement(ContFaxNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFaxNoTitle := Cont.FieldCaption("Fax No.");
                    end;
                }
                textelement(ContTelexAnswerBackTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexAnswerBackTitle := Cont.FieldCaption("Telex Answer Back");
                    end;
                }
                textelement(ContTerritoryCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTerritoryCodeTitle := Cont.FieldCaption("Territory Code");
                    end;
                }
                textelement(ContCurrencyCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCurrencyCodeTitle := Cont.FieldCaption("Currency Code");
                    end;
                }
                textelement(ContLanguageCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContLanguageCodeTitle := Cont.FieldCaption("Language Code");
                    end;
                }
                textelement(ContSalespersonCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalespersonCodeTitle := Cont.FieldCaption("Salesperson Code");
                    end;
                }
                textelement(ContVATRegistrationNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContVATRegistrationNoTitle := Cont.FieldCaption("VAT Registration No.");
                    end;
                }
                textelement("ContE-MailTitle")
                {

                    trigger OnBeforePassVariable()
                    begin
                        "ContE-MailTitle" := Cont.FieldCaption("E-Mail");
                    end;
                }
                textelement(ContHomePageTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContHomePageTitle := Cont.FieldCaption("Home Page");
                    end;
                }
                textelement(ContTypeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTypeTitle := Cont.FieldCaption(Type);
                    end;
                }
                textelement(ContCompanyNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyNameTitle := Cont.FieldCaption("Company Name");
                    end;
                }
                textelement(ContCompanyNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyNoTitle := Cont.FieldCaption("Company No.");
                    end;
                }
                textelement(ContFirstNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFirstNameTitle := Cont.FieldCaption("First Name");
                    end;
                }
                textelement(ContMiddleNameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMiddleNameTitle := Cont.FieldCaption("Middle Name");
                    end;
                }
                textelement(ContSurnameTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSurnameTitle := Cont.FieldCaption(Surname);
                    end;
                }
                textelement(ContJobTitleTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContJobTitleTitle := Cont.FieldCaption("Job Title");
                    end;
                }
                textelement(ContInitialsTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContInitialsTitle := Cont.FieldCaption(Initials);
                    end;
                }
                textelement(ContExtensionNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExtensionNoTitle := Cont.FieldCaption("Extension No.");
                    end;
                }
                textelement(ContMobilePhoneNoTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMobilePhoneNoTitle := Cont.FieldCaption("Mobile Phone No.");
                    end;
                }
                textelement(ContPagerTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPagerTitle := Cont.FieldCaption(Pager);
                    end;
                }
                textelement(ContOrganizationalLevelCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContOrganizationalLevelCodeTitle := Cont.FieldCaption("Organizational Level Code");
                    end;
                }
                textelement(ContExcludefromSegmentTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExcludefromSegmentTitle := Cont.FieldCaption("Exclude from Segment");
                    end;
                }
                textelement(ContCorrespondenceTypeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCorrespondenceTypeTitle := Cont.FieldCaption("Correspondence Type");
                    end;
                }
                textelement(ContSalutationCodeTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalutationCodeTitle := Cont.FieldCaption("Salutation Code");
                    end;
                }
            }
            tableelement("Segment Line"; "Segment Line")
            {
                XmlName = 'SegmentLine';
                SourceTableView = sorting("Segment No.", "Line No.");
                textelement(ContNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContNo := Cont."No.";
                    end;
                }
                textelement(ContExternalID)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExternalID := Cont."External ID";
                    end;
                }
                textelement(ContName)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContName := Cont.Name;
                    end;
                }
                textelement(ContName2)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContName2 := Cont."Name 2";
                    end;
                }
                textelement(ContAddress)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddress := Cont.Address;
                    end;
                }
                textelement(ContAddress2)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContAddress2 := Cont."Address 2";
                    end;
                }
                textelement(ContCounty)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCounty := Cont.County;
                    end;
                }
                textelement(ContPostCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPostCode := Cont."Post Code";
                    end;
                }
                textelement(ContCity)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCity := Cont.City;
                    end;
                }
                textelement(ContCountryRegionCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCountryRegionCode := Cont."Country/Region Code";
                    end;
                }
                textelement(ContPhoneNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPhoneNo := Cont."Phone No.";
                    end;
                }
                textelement(ContTelexNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexNo := Cont."Telex No.";
                    end;
                }
                textelement(ContFaxNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFaxNo := Cont."Fax No.";
                    end;
                }
                textelement(ContTelexAnswerBack)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTelexAnswerBack := Cont."Telex Answer Back";
                    end;
                }
                textelement(ContTerritoryCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContTerritoryCode := Cont."Territory Code";
                    end;
                }
                textelement(ContCurrencyCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCurrencyCode := Cont."Currency Code";
                    end;
                }
                textelement(ContLanguageCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContLanguageCode := Cont."Language Code";
                    end;
                }
                textelement(ContSalespersonCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalespersonCode := Cont."Salesperson Code";
                    end;
                }
                textelement(ContVATRegistrationNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContVATRegistrationNo := Cont."VAT Registration No.";
                    end;
                }
                textelement(ContEMail)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContEMail := Cont."E-Mail";
                    end;
                }
                textelement(ContHomePage)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContHomePage := Cont."Home Page";
                    end;
                }
                textelement(ContType)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContType := Format(Cont.Type, 0, 2);
                    end;
                }
                textelement(ContCompanyName)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyName := Cont."Company Name";
                    end;
                }
                textelement(ContCompanyNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCompanyNo := Cont."Company No.";
                    end;
                }
                textelement(ContFirstName)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContFirstName := Cont."First Name";
                    end;
                }
                textelement(ContMiddleName)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMiddleName := Cont."Middle Name";
                    end;
                }
                textelement(ContSurName)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSurName := Cont.Surname;
                    end;
                }
                textelement(ContJobTitle)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContJobTitle := Cont."Job Title";
                    end;
                }
                textelement(ContInitials)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContInitials := Cont.Initials;
                    end;
                }
                textelement(ContExtensionNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExtensionNo := Cont."Extension No.";
                    end;
                }
                textelement(ContMobilePhoneNo)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContMobilePhoneNo := Cont."Mobile Phone No.";
                    end;
                }
                textelement(ContPager)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContPager := Cont.Pager;
                    end;
                }
                textelement(ContOrganizationalLevelCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContOrganizationalLevelCode := Cont."Organizational Level Code";
                    end;
                }
                textelement(ContExcludeFromSegment)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContExcludeFromSegment := Format(Cont."Exclude from Segment");
                    end;
                }
                textelement(ContCorrespondenceType)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContCorrespondenceType := Format(Cont."Correspondence Type", 0, 2);
                    end;
                }
                textelement(ContSalutationCode)
                {

                    trigger OnBeforePassVariable()
                    begin
                        ContSalutationCode := Cont."Salutation Code";
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    Cont.Get("Segment Line"."Contact No.");
                end;
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

    var
        Cont: Record Contact;
}

