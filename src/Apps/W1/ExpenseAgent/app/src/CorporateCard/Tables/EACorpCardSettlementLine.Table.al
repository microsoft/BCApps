// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

table 7431 "EA Corp Card Settlement Line"
{
    Access = Internal;
    Caption = 'Corp Card Settlement Statement';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Settlement Entry No."; Integer)
        {
            Caption = 'Settlement Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Settlement"."Settlement Entry No.";
            ToolTip = 'Specifies the settlement that contains this statement.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the line number within the settlement.';
        }
        field(3; "Statement Entry No."; Integer)
        {
            Caption = 'Statement Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Statement"."Statement Entry No.";
            ToolTip = 'Specifies the validated provider statement included in the settlement.';

            trigger OnValidate()
            var
                CorpCardSettlement: Record "EA Corp Card Settlement";
                CorpCardStatement: Record "EA Corp Card Statement";
                OtherSettlementLine: Record "EA Corp Card Settlement Line";
            begin
                CorpCardSettlement.Get("Settlement Entry No.");
                CorpCardSettlement.EnsureOpen();
                if "Statement Entry No." = 0 then begin
                    ClearStatementSnapshot();
                    exit;
                end;

                CorpCardStatement.Get("Statement Entry No.");
                if not (CorpCardStatement.Status in [CorpCardStatement.Status::Validated, CorpCardStatement.Status::ReconciliationRequired]) then
                    Error(StatementStatusNotEligibleErr, CorpCardStatement."Statement No.", CorpCardStatement.Status);
                if CorpCardStatement."Provider Code" <> CorpCardSettlement."Provider Code" then
                    Error(StatementProviderMismatchErr, CorpCardStatement."Statement No.", CorpCardStatement."Provider Code", CorpCardSettlement."Provider Code");
                if CorpCardStatement."Currency Code" <> CorpCardSettlement."Currency Code" then
                    Error(StatementCurrencyMismatchErr, CorpCardStatement."Statement No.", CorpCardStatement."Currency Code", CorpCardSettlement."Currency Code");

                OtherSettlementLine.SetRange("Statement Entry No.", "Statement Entry No.");
                OtherSettlementLine.SetRange(Inactive, false);
                if OtherSettlementLine.FindSet() then
                    repeat
                        if (OtherSettlementLine."Settlement Entry No." <> "Settlement Entry No.") or
                           (OtherSettlementLine."Line No." <> "Line No.")
                        then
                            Error(StatementAlreadySettledErr, CorpCardStatement."Statement No.", OtherSettlementLine."Settlement Entry No.");
                    until OtherSettlementLine.Next() = 0;

                "Statement No." := CorpCardStatement."Statement No.";
                "Statement Date" := CorpCardStatement."Statement Date";
                "Currency Code" := CorpCardStatement."Currency Code";
                "Statement Amount" := CorpCardStatement."Statement Total";
            end;
        }
        field(4; "Statement No."; Code[50])
        {
            Caption = 'Statement No.';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the provider statement number captured when the statement was added.';
        }
        field(5; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the statement date captured when the statement was added.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = AccountData;
            Editable = false;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the statement currency captured when the statement was added.';
        }
        field(7; "Statement Amount"; Decimal)
        {
            Caption = 'Statement Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the statement amount captured when the statement was added.';
        }
        field(8; Inactive; Boolean)
        {
            Caption = 'Inactive';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies whether this historical settlement relationship was released by settlement reversal.';
        }
    }

    keys
    {
        key(PK; "Settlement Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(Statement; "Statement Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        CheckSettlementOpen();
        TestField("Statement Entry No.");
    end;

    trigger OnModify()
    begin
        CheckSettlementOpen();
    end;

    trigger OnDelete()
    begin
        CheckSettlementOpen();
    end;

    local procedure CheckSettlementOpen()
    var
        CorpCardSettlement: Record "EA Corp Card Settlement";
    begin
        CorpCardSettlement.Get("Settlement Entry No.");
        CorpCardSettlement.EnsureOpen();
    end;

    local procedure ClearStatementSnapshot()
    begin
        "Statement No." := '';
        "Statement Date" := 0D;
        "Currency Code" := '';
        "Statement Amount" := 0;
    end;

    var
        StatementAlreadySettledErr: Label 'Statement %1 is already included in settlement entry %2.', Comment = '%1 = statement number, %2 = settlement entry number';
        StatementCurrencyMismatchErr: Label 'Statement %1 has currency %2, but the settlement currency is %3.', Comment = '%1 = statement number, %2 = statement currency, %3 = settlement currency';
        StatementProviderMismatchErr: Label 'Statement %1 belongs to provider %2, but the settlement provider is %3.', Comment = '%1 = statement number, %2 = statement provider, %3 = settlement provider';
        StatementStatusNotEligibleErr: Label 'Statement %1 must be validated or require reconciliation before it can be added to a settlement. Current status: %2.', Comment = '%1 = statement number, %2 = statement status';
}
