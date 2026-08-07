#if not CLEANSCHEMA32
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

#if not CLEAN29
using Microsoft.Bank.BankAccount;
#endif

table 32000003 "Foreign Payment Types"
{
    Caption = 'Foreign Payment Types';
#if not CLEAN29
    LookupPageID = "Payment Method Codes";
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '32.0';
#endif
    ObsoleteReason = 'Moved to Banking and Payments FI app.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[1])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Code Type"; Option)
        {
            Caption = 'Code Type';
            OptionCaption = 'Payment Method,Service Fee';
            OptionMembers = "Payment Method","Service Fee";
        }
        field(3; Description; Text[35])
        {
            Caption = 'Description';
        }
        field(4; Banks; Text[100])
        {
            Caption = 'Banks';
        }
    }

    keys
    {
        key(Key1; "Code", "Code Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif

