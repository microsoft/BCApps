// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Utilities;

table 5637 "FA G/L Posting Buffer"
{
    Caption = 'FA G/L Posting Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(3; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(4; Correction; Boolean)
        {
            Caption = 'Correction';
            DataClassification = SystemMetadata;
        }
        field(5; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(6; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(7; "FA Entry Type"; Option)
        {
            Caption = 'FA Entry Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Fixed Asset,Maintenance';
            OptionMembers = " ","Fixed Asset",Maintenance;
        }
        field(8; "FA Entry No."; Integer)
        {
            Caption = 'FA Entry No.';
            DataClassification = SystemMetadata;
        }
        field(9; "Automatic Entry"; Boolean)
        {
            Caption = 'Automatic Entry';
            DataClassification = SystemMetadata;
        }
        field(10; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "FA Posting Group";
        }
#pragma warning disable AS0070
        field(11; "FA Allocation Type"; Enum "FA Allocation Type")
        {
            Caption = 'FA Allocation Type';
            DataClassification = SystemMetadata;
        }
#pragma warning restore AS0070
        field(12; "FA Allocation Line No."; Integer)
        {
            Caption = 'FA Allocation Line No.';
            DataClassification = SystemMetadata;
        }
        field(15; "Original General Journal Line"; Boolean)
        {
            Caption = 'Original General Journal Line';
            DataClassification = SystemMetadata;
        }
        field(16; "Net Disposal"; Boolean)
        {
            Caption = 'Net Disposal';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
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

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}

