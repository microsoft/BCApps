#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10533 "MTD-Liability"
{
    Caption = 'VAT Liability';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "From Date"; Date)
        {
            Caption = 'From Date';
        }
        field(2; "To Date"; Date)
        {
            Caption = 'To Date';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',VAT Return Debit Charge';
            OptionMembers = ,"VAT Return Debit Charge";
        }
        field(4; "Original Amount"; Decimal)
        {
            Caption = 'Original Amount';
        }
        field(5; "Outstanding Amount"; Decimal)
        {
            Caption = 'Outstanding Amount';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
    }

    keys
    {
        key(Key1; "From Date", "To Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif