// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 10004 "MX Electronic Invoicing Setup"
{
    Caption = 'MX Electronic Invoicing Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Download XML with Requests"; Boolean)
        {
            Caption = 'Download XML with Requests';
        }
        field(4; "Download SaaS Request"; Boolean)
        {
            Caption = 'Download SaaS Request';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

