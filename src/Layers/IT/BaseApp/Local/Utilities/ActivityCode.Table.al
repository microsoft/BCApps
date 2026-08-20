// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN29
namespace Microsoft.Utilities;

table 12124 "Activity Code"
{
    Caption = 'Activity Code';
    LookupPageID = 12124;
    DataClassification = CustomerContent;
    ObsoleteReason = 'Replaced by the Business Activity Code table.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    fields
    {
        field(1; "Code"; Code[6])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif

