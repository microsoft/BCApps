// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

table 8350 "MCP API Publisher Group"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "API Publisher"; Text[40])
        {
            DataClassification = ToBeClassified;
            Caption = 'API Publisher';
        }
        field(2; "API Group"; Text[40])
        {
            DataClassification = ToBeClassified;
            Caption = 'API Group';
        }
    }

    keys
    {
        key(Key1; "API Publisher", "API Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}