// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

// MOCK: stand-in persistence for the API Tools / AL Query Tools activation flags. The real booleans
// belong on the platform-owned "MCP Configuration" table, which the app cannot extend; when the
// platform ships them, delete this table and repoint MCPConfigImplementation at the real fields.
table 8356 "MCP Feature Activation"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'MCP Feature Activation';

    fields
    {
        field(1; "Config Id"; Guid)
        {
            Caption = 'Config Id';
        }
        field(2; "Enable API Tools"; Boolean)
        {
            Caption = 'Enable API Tools';
        }
        field(3; "Enable AL Query Tools"; Boolean)
        {
            Caption = 'Enable AL Query Tools';
        }
    }

    keys
    {
        key(PK; "Config Id")
        {
            Clustered = true;
        }
    }
}
