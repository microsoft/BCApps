// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.SyncEngine;

table 5383 "Integration Field"
{
    Caption = 'Integration Field';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            ToolTip = 'Specifies the table number that contains this field.';
        }
        field(2; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the name of the field as defined in the AL source code.';
        }
        field(3; "Field Caption"; Text[80])
        {
            Caption = 'Field Caption';
            ToolTip = 'Specifies the caption text for the field.';
        }
        field(4; "Field No."; Integer)
        {
            Caption = 'Field No.';
            ToolTip = 'Specifies the field number that uniquely identifies this field within its table.';
        }
        field(5; IsRuntime; Boolean)
        {
            Caption = 'Is Runtime';
            ToolTip = 'Specifies whether the field is a runtime field.';
        }
    }

    keys
    {
        key(PK; "Table No.", "Field Name")
        {
        }
    }
}