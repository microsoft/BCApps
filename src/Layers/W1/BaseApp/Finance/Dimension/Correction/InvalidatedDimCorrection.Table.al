// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

table 2587 "Invalidated Dim Correction"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Node Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Node Id';
            Editable = false;
            AutoIncrement = true;
        }

        field(2; "Parent Node Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Node Id';
            Editable = false;
        }

        field(3; "Invalidated Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Invalidated Entry No.';
            Editable = false;
        }

        field(4; "Invalidated By Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Invalidated By Entry No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Node Id")
        {
            Clustered = true;
        }
        key(Key2; "Invalidated Entry No.")
        {
        }
        key(Key3; "Invalidated By Entry No.")
        {
        }
        key(Key4; "Parent Node Id", "Invalidated Entry No.", "Invalidated By Entry No.")
        {
        }
    }
}
