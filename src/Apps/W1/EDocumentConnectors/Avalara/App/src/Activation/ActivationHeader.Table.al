// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Stores activation header records retrieved from the Avalara E-Invoicing service.
/// </summary>
table 6376 "Activation Header"
{
    Access = Internal;
    Caption = 'Activation Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "Registration Type"; Text[50])
        {
            Caption = 'Registration Type';
        }
        field(3; Jurisdiction; Text[50])
        {
            Caption = 'Jurisdiction';
        }
        field(4; "Scheme Id"; Text[30])
        {
            Caption = 'Scheme Id';
        }
        field(5; Identifier; Text[100])
        {
            Caption = 'Identifier';
        }
        field(6; "Full Authority Value"; Text[250])
        {
            Caption = 'Full Authority Value';
        }
        field(7; "Status Code"; Text[50])
        {
            Caption = 'Status Code';
        }
        field(8; "Status Message"; Text[2048])
        {
            Caption = 'Status Message';
        }
        field(9; "Company Id"; Text[100])
        {
            Caption = 'Company Id';
        }
        field(10; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(11; "Company Location"; Text[250])
        {
            Caption = 'Company Location';
        }
        field(12; "Last Modified"; DateTime)
        {
            Caption = 'Last Modified';
        }
        field(13; "Meta Location"; Text[250])
        {
            Caption = 'Meta Location';
        }
        field(14; "Is Active ID"; Boolean)
        {
            Caption = 'Is Active ID';
        }
    }

    keys
    {
        key(PK; ID) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(Brick; ID, "Registration Type")
        {
        }
        fieldgroup(Dropdown; ID, "Registration Type")
        {
        }
    }
}