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
        field(12100; "No. Series Type"; Option)
        {
            Caption = 'No. Series Type';
            OptionCaption = 'Normal,Sales,Purchase';
            OptionMembers = Normal,Sales,Purchase;
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
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