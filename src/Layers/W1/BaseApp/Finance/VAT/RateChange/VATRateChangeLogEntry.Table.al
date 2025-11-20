// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using System.Reflection;

table 552 "VAT Rate Change Log Entry"
{
    Caption = 'VAT Rate Change Log Entry';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Converted Date"; Date)
        {
            Caption = 'Converted Date';
        }
        field(2; "Entry No."; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(10; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(11; "Table Caption"; Text[80])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = const(Table),
                                                             "Object ID" = field("Table ID")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(30; "Old Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Old Gen. Prod. Posting Group';
        }
        field(31; "New Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'New Gen. Prod. Posting Group';
        }
        field(32; "Old VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Old VAT Prod. Posting Group';
        }
        field(33; "New VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'New VAT Prod. Posting Group';
        }
        field(40; Converted; Boolean)
        {
            Caption = 'Converted';
        }
        field(50; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Converted Date", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
        key(Key3; "Table ID")
        {
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    procedure UpdateGroups(OldGenProdPostingGroup: Code[20]; NewGenProdPostingGroup: Code[20]; OldVATProdPostingGroup: Code[20]; NewVATProdPostingGroup: Code[20])
    begin
        "Old Gen. Prod. Posting Group" := OldGenProdPostingGroup;
        "New Gen. Prod. Posting Group" := NewGenProdPostingGroup;
        "Old VAT Prod. Posting Group" := OldVATProdPostingGroup;
        "New VAT Prod. Posting Group" := NewVATProdPostingGroup;
    end;
}

