// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

table 6701 "Exchange Contact"
{
    Caption = 'Exchange Contact';
    DataClassification = CustomerContent;
    ExternalName = 'Contact';
    TableType = Exchange;

    fields
    {
        field(2; GivenName; Text[30])
        {
            Caption = 'GivenName';
        }
        field(3; MiddleName; Text[30])
        {
            Caption = 'MiddleName';
        }
        field(4; Surname; Text[30])
        {
            Caption = 'Surname';
        }
        field(5; Initials; Text[30])
        {
            Caption = 'Initials';
        }
        field(6; FullName; Text[50])
        {
            Caption = 'FullName';
            ExternalName = 'CompleteName';
        }
        field(10; PostalCode; Text[20])
        {
            Caption = 'PostalCode';
            ExternalName = 'AddressBusinessPostalCode';
        }
        field(22; EMailAddress1; Text[80])
        {
            Caption = 'E-Mail';
            ExternalName = 'EmailAddress1';
            ExternalType = 'String';
        }
        field(23; EMailAddress2; Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
            ExternalName = 'EMailAddress2';
            ExternalType = 'String';
        }
        field(33; CompanyName; Text[100])
        {
            Caption = 'CompanyName';
        }
        field(34; BusinessHomePage; Text[80])
        {
            Caption = 'BusinessHomePage';
        }
        field(35; BusinessPhone1; Text[30])
        {
            Caption = 'BusinessPhone1';
            ExternalName = 'PhoneNumbers.BusinessPhone';
        }
        field(36; MobilePhone; Text[30])
        {
            Caption = 'MobilePhone';
            ExternalName = 'PhoneNumbers.MobilePhone';
        }
        field(37; BusinessFax; Text[30])
        {
            Caption = 'BusinessFax';
            ExternalName = 'PhoneNumbers.BusinessFax';
        }
        field(38; Street; Text[104])
        {
            Caption = 'Street';
            ExternalName = 'AddressBusinessStreet';
        }
        field(39; City; Text[30])
        {
            Caption = 'City';
            ExternalName = 'AddressBusinessCity';
        }
        field(40; Region; Text[10])
        {
            Caption = 'Region';
            ExternalName = 'AddressBusinessRegion';
        }
        field(41; JobTitle; Text[30])
        {
            Caption = 'JobTitle';
        }
        field(42; State; Text[30])
        {
            Caption = 'State';
            ExternalName = 'AddressBusinessState';
        }
        field(95; LastModifiedTime; DateTime)
        {
            Caption = 'LastModifiedTime';
        }
    }

    keys
    {
        key(Key1; EMailAddress1)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

