// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Employee;

table 5225 "Employee Payment Buffer"
{
    Caption = 'Employee Payment Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            DataClassification = SystemMetadata;
            TableRelation = Employee;
        }
        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(3; "Employee Ledg. Entry No."; Integer)
        {
            Caption = 'Employee Ledg. Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Employee Ledger Entry";
        }
        field(4; "Dimension Entry No."; Integer)
        {
            Caption = 'Dimension Entry No.';
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
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(8; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(9; "Employee Ledg. Entry Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Employee Ledg. Entry Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(10; "Employee Ledg. Entry Doc. No."; Code[20])
        {
            Caption = 'Employee Ledg. Entry Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
            DataClassification = SystemMetadata;
            TableRelation = "Employee Ledger Entry"."Creditor No." where("Entry No." = field("Employee Ledg. Entry No."));
        }
        field(171; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
            DataClassification = SystemMetadata;
            TableRelation = "Employee Ledger Entry"."Payment Reference" where("Entry No." = field("Employee Ledg. Entry No."));
        }
        field(172; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = SystemMetadata;
            TableRelation = "Employee Ledger Entry"."Payment Method Code" where("Employee No." = field("Employee No."));
        }
        field(173; "Applies-to Ext. Doc. No."; Code[35])
        {
            Caption = 'Applies-to Ext. Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(290; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            DataClassification = SystemMetadata;
            Editable = false;
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
        key(Key1; "Employee No.", "Currency Code", "Employee Ledg. Entry No.", "Dimension Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.")
        {
        }
    }

    fieldgroups
    {
    }
}

