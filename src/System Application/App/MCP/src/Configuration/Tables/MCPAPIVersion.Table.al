// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

table 8354 "MCP API Version"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "API Version"; Text[30])
        {
            Caption = 'API Version';
        }
    }

    keys
    {
        key(Key1; "API Version")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}