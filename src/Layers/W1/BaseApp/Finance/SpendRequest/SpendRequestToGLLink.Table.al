// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

table 6845 "Spend Request To G/L Link"
{
    Caption = 'Spend Request To G/L Link';
    DataClassification = SystemMetadata;
    LookupPageId = "Spend Request To G/L Link";
    DrillDownPageId = "Spend Request To G/L Link";
    InherentEntitlements = rimdx;
    InherentPermissions = rimdx;

    fields
    {
        field(1; "Spend Request No."; Code[20])
        {
            Caption = 'Spend Request No.';
            ToolTip = 'Specifies the spend request no. that this link points to.';
            DataClassification = CustomerContent;
            TableRelation = "Spend Request";
        }
        field(2; "Spend Request Detail No."; Integer)
        {
            Caption = 'Spend Request Detail No.';
            ToolTip = 'Specifies the spend request line no. that this link points to.';
        }
        field(3; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            ToolTip = 'Specifies the spend g/l entry no. that this link points to.';
            TableRelation = "G/L Entry";
        }
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            ToolTip = 'The G/L Account that the expenses were posted to.';
            TableRelation = "G/L Account";
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the g/l entry that this record points to.';
            AutoFormatExpression = '';
            AutoFormatType = 1;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the g/l entry that this record points to.';
        }
        field(10; "Detail Description"; Text[100])
        {
            Caption = 'Detail Description';
            Editable = false;
            ToolTip = 'Specifies the description from the spend request detail.';
            FieldClass = FlowField;
            CalcFormula = lookup("Spend Request Detail".Description where("Spend Request No." = field("Spend Request No."), "Line No." = field("Spend Request Detail No.")));
        }
        field(11; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            ToolTip = 'Specifies the posting description from the g/l entry.';
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry"."Document No." where("Entry No." = field("G/L Entry No.")));
        }
        field(12; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            Editable = false;
            ToolTip = 'Specifies the posting description from the g/l entry.';
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry".Description where("Entry No." = field("G/L Entry No.")));
        }
    }
    keys
    {
        key(Key1; "Spend Request No.", "Spend Request Detail No.", "G/L Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "G/L Account No.", "Posting Date")
        {
            IncludedFields = Amount;
        }
    }
}
