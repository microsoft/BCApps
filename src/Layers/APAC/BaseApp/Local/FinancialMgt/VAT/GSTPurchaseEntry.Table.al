// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

table 28160 "GST Purchase Entry"
{
    Caption = 'GST Purchase Entry';
    LookupPageID = "GST Purchase Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "GST Entry No."; Integer)
        {
            Caption = 'GST Entry No.';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(7; "Document Line Type"; Enum "Purchase Line Type")
        {
            Caption = 'Document Line Type';
        }
        field(8; "Document Line Code"; Text[30])
        {
            Caption = 'Document Line Code';
        }
        field(9; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(10; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
        }
        field(11; "Document Line Description"; Text[100])
        {
            Caption = 'Document Line Description';
        }
        field(12; "GST Entry Type"; Option)
        {
            Caption = 'GST Entry Type';
            OptionCaption = ' ,Purchase,Sale,Settlement';
            OptionMembers = " ",Purchase,Sale,Settlement;

            trigger OnValidate()
            begin
                if "GST Entry Type" = "GST Entry Type"::Settlement then
                    Error(Text000, FieldCaption("GST Entry Type"), "GST Entry Type");
            end;
        }
        field(13; "GST Base"; Decimal)
        {
            Caption = 'GST Base';
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(15; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
        }
        field(16; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(17; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "GST Entry No.", "Document No.", "Document Type", "VAT Prod. Posting Group")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label 'You cannot change the contents of this field when %1 is %2.';
}

