// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

table 8352 "MCP Config Warning"
{
    Access = Public;
    Extensible = false;
    DataClassification = SystemMetadata;
    TableType = Temporary;
    Caption = 'MCP Configuration Warning';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Config Id"; Guid)
        {
            Caption = 'Config Id';
            ToolTip = 'Specifies the ID of the MCP configuration.';
        }
        field(3; "Tool Id"; Guid)
        {
            Caption = 'Tool Id';
            ToolTip = 'Specifies the ID of the tool that has a warning.';
        }
        field(4; "Warning Type"; Enum "MCP Config Warning Type")
        {
            Caption = 'Warning Type';
            ToolTip = 'Specifies the type of warning.';
        }
        field(5; "Additional Info"; Text[2048])
        {
            Caption = 'Additional Info';
            ToolTip = 'Specifies additional information about the warning, such as missing parent page IDs.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Config Id", "Tool Id")
        {
        }
    }
}
