// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Temporary table to hold field name/value pairs for generic record editing.
/// Used by BC14 Buffer Record Editor page to display and edit any buffer table record.
/// </summary>
table 50198 "BC14 Buffer Field Editor"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(2; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
        }
        field(3; "Field Value"; Text[2048])
        {
            Caption = 'Field Value';
        }
        field(4; "Field Type"; Text[30])
        {
            Caption = 'Field Type';
        }
        field(5; "Is Editable"; Boolean)
        {
            Caption = 'Is Editable';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Field No.")
        {
            Clustered = true;
        }
    }
}
