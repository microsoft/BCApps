#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 308 "No. Series"
{
    Caption = 'No. Series';
    DataClassification = CustomerContent;
    ObsoleteReason = 'No. Series is moved to Business Foundation';
    ObsoleteState = Moved;
    ObsoleteTag = '24.0';
    MovedTo = 'f3552374-a1f2-4356-848e-196002525837';

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
}
#endif