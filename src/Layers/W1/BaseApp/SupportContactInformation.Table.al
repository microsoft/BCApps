// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Email;
using System.Integration;

table 9165 "Support Contact Information"
{
    Caption = 'Support Contact Information';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(5; Name; Text[250])
        {
            Caption = 'Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; Email; Text[250])
        {
            Caption = 'Email';
            DataClassification = EndUserIdentifiableInformation;
            ExtendedDatatype = EMail;

            trigger OnValidate()
            begin
                MailManagement.ValidateEmailAddressField(Email);
            end;
        }
        field(13; URL; Text[250])
        {
            Caption = 'URL';
            DataClassification = CustomerContent;
            ExtendedDatatype = URL;

            trigger OnValidate()
            begin
                if URL <> '' then
                    if not WebRequestHelper.IsValidUriWithoutProtocol(URL) then
                        Error(InvalidUriErr);
            end;
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
        MailManagement: Codeunit "Mail Management";
        WebRequestHelper: Codeunit "Web Request Helper";
        InvalidUriErr: Label 'The specified value is not a valid URL. You must specify a link to your website, such as https://mycompany.com/support.', Comment = 'The URL to include must be an example URL. The aim is to help the user understand what kind of input is expected from them. It should not be an existing web page. ';
}

