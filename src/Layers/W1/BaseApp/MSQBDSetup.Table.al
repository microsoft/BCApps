// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 7880 "MS-QBD Setup"
{
    Caption = 'MS-QBD Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(3; "Last Sent To"; Text[250])
        {
            Caption = 'Last Sent To';
            ExtendedDatatype = EMail;
        }
        field(4; LastEmailBodyPath; Text[250])
        {
            Caption = 'LastEmailBodyPath';
        }
        field(5; "Last Sent CC"; Text[250])
        {
            Caption = 'Last Sent CC';
        }
        field(6; "Last Sent BCC"; Text[250])
        {
            Caption = 'Last Sent BCC';
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

