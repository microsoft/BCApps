// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

table 8355 "MCP Server Feature"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Feature; Enum "MCP Server Feature")
        {
            Caption = 'Feature';
        }
        field(2; "Description"; Text[500])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what enabling this server feature does.';
        }
        field(3; "Status"; Option)
        {
            Caption = 'Status';
            OptionMembers = Inactive,Active;
            OptionCaption = 'Inactive,Active';
            ToolTip = 'Specifies whether this server feature is currently active for the configuration.';
        }
    }

    keys
    {
        key(Key1; Feature)
        {
            Clustered = true;
        }
    }
}
