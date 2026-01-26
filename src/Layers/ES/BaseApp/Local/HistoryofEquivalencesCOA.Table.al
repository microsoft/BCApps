#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.GeneralLedger.Account;

table 10724 "History of Equivalences COA"
{
    Caption = 'History of Equivalences COA';
    ObsoleteReason = 'Obsolete feature';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Old G/L Account No."; Code[20])
        {
            Caption = 'Old G/L Account No.';
        }
        field(3; "Old G/L Account Name"; Text[30])
        {
            Caption = 'Old G/L Account Name';
            FieldClass = FlowField;
        }
        field(4; "New G/L Account No."; Code[20])
        {
            Caption = 'New G/L Account No.';
            TableRelation = "G/L Account"."No.";
            ValidateTableRelation = true;
        }
        field(5; "New G/L Account Name"; Text[30])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("New G/L Account No.")));
            Caption = 'New G/L Account Name';
            FieldClass = FlowField;
        }
        field(6; "Date Runned"; Date)
        {
            Caption = 'Date Runned';
        }
        field(7; Balance; Decimal)
        {
            Caption = 'Balance';
        }
        field(8; "Balance date"; Date)
        {
            Caption = 'Balance date';
        }
        field(9; "Old Acc. Pre Impl. Balance"; Decimal)
        {
            Caption = 'Old Acc. Pre Impl. Balance';
        }
        field(10; "New Acc. Post Impl. Balance"; Decimal)
        {
            Caption = 'New Acc. Post Impl. Balance';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif