// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 10606 "E-Invoice Transfer File"
{
    Caption = 'E-Invoice Transfer File';
    DataClassification = CustomerContent;

    fields
    {
        field(10600; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10601; "Server Temp File Name"; Text[250])
        {
            Caption = 'Server Temp File Name';
        }
        field(10602; "Local File Name"; Text[250])
        {
            Caption = 'Local File Name';
        }
        field(10603; "Local Path"; Text[250])
        {
            Caption = 'Local Path';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

