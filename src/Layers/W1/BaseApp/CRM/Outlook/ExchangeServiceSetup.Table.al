// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

table 5324 "Exchange Service Setup"
{
    Caption = 'Exchange Service Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Azure AD App. ID"; Guid)
        {
            Caption = 'Microsoft Entra App. ID';
        }
        field(3; "Azure AD App. Cert. Thumbprint"; Text[40])
        {
            Caption = 'Microsoft Entra App. Cert. Thumbprint';
        }
        field(4; "Azure AD Auth. Endpoint"; Text[250])
        {
            Caption = 'Microsoft Entra Auth. Endpoint';
        }
        field(5; "Exchange Service Endpoint"; Text[250])
        {
            Caption = 'Exchange Service Endpoint';
        }
        field(6; "Exchange Resource Uri"; Text[250])
        {
            Caption = 'Exchange Resource Uri';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

