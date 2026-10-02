// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Ledger;

table 7430 "EA Corp Card Settlement"
{
    Access = Internal;
    Caption = 'Corp Card Settlement';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Settlements";
    DrillDownPageId = "EA Corp Card Settlement";
    ReplicateData = false;

    fields
    {
        field(1; "Settlement Entry No."; Integer)
        {
            Caption = 'Settlement Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the internal entry number of the corporate card settlement.';
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Provider".Code;
            ToolTip = 'Specifies the corporate card provider being settled.';

            trigger OnValidate()
            var
                CorpCardProvider: Record "EA Corp Card Provider";
                CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
            begin
                EnsureOpen();
                if "Provider Code" = xRec."Provider Code" then
                    exit;

                CorpCardSettlementLine.SetRange("Settlement Entry No.", "Settlement Entry No.");
                if not CorpCardSettlementLine.IsEmpty() then
                    Error(ProviderCannotChangeErr);

                if "Provider Code" = '' then begin
                    "Corp Card Bank Account No." := '';
                    "Payment Bank Account No." := '';
                    exit;
                end;

                CorpCardProvider.Get("Provider Code");
                "Corp Card Bank Account No." := CorpCardProvider."Corp Card Bank Account No.";
                "Payment Bank Account No." := CorpCardProvider."Payment Bank Account No.";
            end;
        }
        field(3; "Settlement No."; Code[50])
        {
            Caption = 'Settlement No.';
            DataClassification = AccountData;
            ToolTip = 'Specifies the settlement identifier assigned by the corporate card provider.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(4; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the date on which the provider settlement is due or collected.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = AccountData;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency of the settlement. A blank value represents the local currency.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(6; "Settlement Amount"; Decimal)
        {
            Caption = 'Settlement Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            ToolTip = 'Specifies the amount that the provider will collect from the payment bank account.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(7; "Corp Card Bank Account No."; Code[20])
        {
            Caption = 'Corporate Card Bank Account No.';
            DataClassification = AccountData;
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Specifies the bank account that represents the corporate card liability and will receive the settlement.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(8; "Payment Bank Account No."; Code[20])
        {
            Caption = 'Payment Bank Account No.';
            DataClassification = AccountData;
            TableRelation = "Bank Account"."No.";
            ToolTip = 'Specifies the real bank account from which the corporate card provider will be paid.';

            trigger OnValidate()
            begin
                EnsureOpen();
            end;
        }
        field(9; Status; Enum "EA Corp Card Settle Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the lifecycle status of the corporate card settlement.';
        }
        field(10; "Statement Total"; Decimal)
        {
            Caption = 'Statement Total';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("EA Corp Card Settlement Line"."Statement Amount" where("Settlement Entry No." = field("Settlement Entry No.")));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total amount of the statements included in this settlement.';
        }
        field(11; "Statement Count"; Integer)
        {
            Caption = 'Statement Count';
            CalcFormula = count("EA Corp Card Settlement Line" where("Settlement Entry No." = field("Settlement Entry No.")));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of statements included in this settlement.';
        }
        field(12; "Posted Document No."; Code[20])
        {
            Caption = 'Posted Document No.';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the document number used to post the settlement.';
        }
        field(13; "Posted Date"; Date)
        {
            Caption = 'Posted Date';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the date on which the settlement was posted.';
        }
        field(14; "Corp Card Bank Acc. Entry No."; Integer)
        {
            Caption = 'Corporate Card Bank Account Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
            ToolTip = 'Specifies the bank account ledger entry that clears the corporate card liability.';
        }
        field(15; "Payment Bank Acc. Entry No."; Integer)
        {
            Caption = 'Payment Bank Account Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
            ToolTip = 'Specifies the bank account ledger entry for the payment from the real bank account.';
        }
        field(16; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "G/L Register"."No.";
            ToolTip = 'Specifies the G/L register created by settlement posting.';
        }
        field(17; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the transaction number assigned to the settlement entries.';
        }
        field(18; "Reversal Reason"; Text[250])
        {
            Caption = 'Reversal Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies why the posted corporate card settlement must be reversed.';

            trigger OnValidate()
            begin
                if Status <> Status::Posted then
                    Error(ReversalReasonRequiresPostedErr);
            end;
        }
        field(19; "Reversal Transaction No."; Integer)
        {
            Caption = 'Reversal Transaction No.';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the transaction number created by settlement reversal.';
        }
        field(20; "Reversal G/L Register No."; Integer)
        {
            Caption = 'Reversal G/L Register No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "G/L Register"."No.";
            ToolTip = 'Specifies the G/L register created by settlement reversal.';
        }
        field(21; "Corp Card Reversal Entry No."; Integer)
        {
            Caption = 'Corporate Card Reversal Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
            ToolTip = 'Specifies the reversal entry for the corporate card bank account.';
        }
        field(22; "Payment Reversal Entry No."; Integer)
        {
            Caption = 'Payment Reversal Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
            ToolTip = 'Specifies the reversal entry for the payment bank account.';
        }
        field(23; "Reversed At"; DateTime)
        {
            Caption = 'Reversed At';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies when the settlement was reversed.';
        }
        field(24; "Reversed By User ID"; Code[50])
        {
            Caption = 'Reversed By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Specifies the user who reversed the settlement.';
        }
    }

    keys
    {
        key(PK; "Settlement Entry No.")
        {
            Clustered = true;
        }
        key(ProviderSettlement; "Provider Code", "Settlement No.")
        {
        }
        key(SettlementDate; "Settlement Date")
        {
        }
    }

    trigger OnDelete()
    var
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
    begin
        EnsureOpen();
        CorpCardSettlementLine.SetRange("Settlement Entry No.", "Settlement Entry No.");
        CorpCardSettlementLine.DeleteAll(true);
    end;

    internal procedure EnsureOpen()
    begin
        if Status <> Status::Open then
            Error(SettlementNotOpenErr, "Settlement Entry No.", Status);
    end;

    var
        ProviderCannotChangeErr: Label 'The provider cannot be changed after statements have been added to the settlement.';
        ReversalReasonRequiresPostedErr: Label 'A reversal reason can be entered only for a posted settlement.';
        SettlementNotOpenErr: Label 'Settlement entry %1 must be open before it can be changed. Current status: %2.', Comment = '%1 = settlement entry number, %2 = status';
}
