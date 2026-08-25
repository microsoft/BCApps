// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3310 "PA Matching Summary Line"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;
    InherentEntitlements = RIM;
    InherentPermissions = RIM;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Match Method"; Text[30])
        {
            Caption = 'Match Method';
        }
        field(3; Confidence; Text[10])
        {
            Caption = 'Confidence';
        }
        field(4; "Deferral Source"; Text[30])
        {
            Caption = 'Deferral Source';
        }
        field(5; "Has Conflict"; Boolean)
        {
            Caption = 'Has Conflict';
        }
        field(6; "New Pattern"; Boolean)
        {
            Caption = 'New Pattern';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
