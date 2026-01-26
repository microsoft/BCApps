// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Finance.GeneralLedger.Journal;

table 11000006 "CBG Statement Line Add. Info."
{
    Caption = 'CBG Statement Line Add. Info.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(2; "CBG Statement No."; Integer)
        {
            Caption = 'CBG Statement No.';
            NotBlank = true;
            TableRelation = "CBG Statement"."No." where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "CBG Statement Line No."; Integer)
        {
            Caption = 'CBG Statement Line No.';
            TableRelation = "CBG Statement Line"."Line No." where("Journal Template Name" = field("Journal Template Name"),
                                                                   "No." = field("CBG Statement No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(6; "Information Type"; Enum "CBG Statement Information Type")
        {
            Caption = 'Information Type';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "CBG Statement No.", "CBG Statement Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

