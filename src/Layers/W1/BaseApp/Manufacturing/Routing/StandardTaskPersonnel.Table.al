// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

table 99000782 "Standard Task Personnel"
{
    Caption = 'Standard Task Personnel';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            NotBlank = true;
            TableRelation = "Standard Task";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Standard Task Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

