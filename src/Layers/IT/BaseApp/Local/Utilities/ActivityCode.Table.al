// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA33
namespace Microsoft.Utilities;

table 12124 "Activity Code"
{
    Caption = 'Activity Code';
#if not CLEAN30
    LookupPageID = 12124;
#endif
    DataClassification = CustomerContent;
    ObsoleteReason = 'Replaced by the Business Activity Code table.';
#if not CLEAN30
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '33.0';
#endif

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

