// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Ledger;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 1104 "Cost Entry"
{
    Caption = 'Cost Entry';
    DataClassification = CustomerContent;
    DrillDownPageID = "Cost Entries";
    LookupPageID = "Cost Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Cost Type No."; Code[20])
        {
            Caption = 'Cost Type No.';
            TableRelation = "Cost Type";
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';
        }
        field(17; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
        }
        field(18; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
        }
        field(20; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";
        }
        field(21; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";
        }
        field(27; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(28; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            TableRelation = "G/L Account";
        }
        field(29; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            Editable = false;
            TableRelation = "G/L Entry";
        }
        field(30; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(31; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(32; Allocated; Boolean)
        {
            Caption = 'Allocated';
        }
        field(33; "Allocated with Journal No."; Integer)
        {
            Caption = 'Allocated with Register No.';
        }
        field(40; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(41; "Batch Name"; Code[10])
        {
            Caption = 'Batch Name';
            TableRelation = "Gen. Journal Batch";
        }
        field(50; "Allocation Description"; Text[80])
        {
            Caption = 'Allocation Description';
        }
        field(51; "Allocation ID"; Code[10])
        {
            Caption = 'Allocation ID';
            TableRelation = "Cost Allocation Source";
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
        }
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
        }
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Cost Type No.", "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount";
        }
        key(Key3; "Cost Type No.", "Cost Center Code", "Cost Object Code", Allocated, "Posting Date")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Additional-Currency Amount", "Add.-Currency Debit Amount", "Add.-Currency Credit Amount";
        }
        key(Key4; "Cost Center Code", "Cost Type No.", Allocated, "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key5; "Cost Object Code", "Cost Type No.", Allocated, "Posting Date")
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Allocation ID", "Posting Date")
        {
        }
        key(Key7; "Document No.", "Posting Date")
        {
        }
        key(Key8; "Allocated with Journal No.")
        {
        }
        key(Key9; "Cost Type No.", "Posting Date", "Cost Center Code", "Cost Object Code")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Posting Date", Amount)
        {
        }
    }

    procedure GetCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;
}
