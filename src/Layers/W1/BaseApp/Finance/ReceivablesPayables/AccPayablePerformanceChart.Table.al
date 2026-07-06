// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

table 9045 "Acc. Payable Performance Chart"
{
    Caption = 'Payable Performance Chart';
    DataClassification = CustomerContent;
    ReplicateData = false;

    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Code Unit ID"; Integer)
        {
            Caption = 'Code Unit ID';
        }
        field(2; "Chart Name"; Text[60])
        {
            Caption = 'Chart Name';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
    }

    keys
    {
        key(PK; "Code Unit ID", "Chart Name")
        {
            Clustered = true;
        }
    }
}
