// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

table 7703 "Miniform Function"
{
    Caption = 'Miniform Function';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Miniform Code"; Code[20])
        {
            Caption = 'Miniform Code';
            TableRelation = "Miniform Header".Code;
        }
        field(2; "Function Code"; Code[20])
        {
            Caption = 'Function Code';
            TableRelation = "Miniform Function Group".Code;
        }
    }

    keys
    {
        key(Key1; "Miniform Code", "Function Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

