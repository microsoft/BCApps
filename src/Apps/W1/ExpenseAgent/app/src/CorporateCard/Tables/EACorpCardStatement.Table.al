// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using System.IO;

table 7422 "EA Corp Card Statement"
{
    Caption = 'Corp Card Statement';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Statements";
    DrillDownPageId = "EA Corp Card Statement";
    ReplicateData = false;

    fields
    {
        field(1; "Statement Entry No."; Integer)
        {
            Caption = 'Statement Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the internal entry number of the imported corporate card statement.';
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Provider".Code;
            ToolTip = 'Specifies the provider that issued the corporate card statement.';
        }
        field(3; "Started DT"; DateTime)
        {
            Caption = 'Started Date-Time';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies when import of the corporate card statement started.';
        }
        field(4; "Ended DT"; DateTime)
        {
            Caption = 'Ended Date-Time';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies when import of the corporate card statement ended.';
        }
        field(5; "Source Ref"; Text[100])
        {
            Caption = 'Source Reference';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the source reference of the imported statement.';
        }
        field(6; Status; Enum "EA Corp Card Stmt Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the import and validation status of the corporate card statement.';
        }
        field(7; Imported; Integer)
        {
            Caption = 'Imported';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the number of imported corporate card transactions.';
        }
        field(8; Rejected; Integer)
        {
            Caption = 'Rejected';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the number of rejected corporate card transactions.';
        }
        field(9; Duplicates; Integer)
        {
            Caption = 'Duplicates';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the number of duplicate corporate card transactions.';
        }
        field(10; Exceptions; Integer)
        {
            Caption = 'Exceptions';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the number of corporate card transactions that have exceptions.';
        }
        field(11; "Data Exch Entry No."; Integer)
        {
            Caption = 'Data Exchange Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Data Exch."."Entry No.";
            ToolTip = 'Specifies the data exchange entry number for the imported corporate card transactions.';
        }
        field(12; "Imported Transactions"; Integer)
        {
            Caption = 'Imported Transactions';
            FieldClass = FlowField;
            CalcFormula = count("EA Corp Card Trans" where("Statement Entry No." = field("Statement Entry No."), "Provider Code" = field("Provider Code")));
            Editable = false;
            ToolTip = 'Specifies the number of imported corporate card transactions.';
        }
        field(13; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the name of the source file that was imported.';
        }
        field(14; "Source Payload Hash"; Text[64])
        {
            Caption = 'Source Payload Hash';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the SHA-256 hash of the source payload that was imported.';
        }
        field(15; "Statement No."; Code[50])
        {
            Caption = 'Statement No.';
            DataClassification = AccountData;
            ToolTip = 'Specifies the statement identifier assigned by the corporate card provider.';
        }
        field(16; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the date of the corporate card statement.';
        }
        field(17; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the first transaction date covered by the statement.';
        }
        field(18; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the last transaction date covered by the statement.';
        }
        field(19; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = AccountData;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency of the corporate card statement. A blank value represents the local currency.';
        }
        field(20; "Statement Total"; Decimal)
        {
            Caption = 'Statement Total';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            ToolTip = 'Specifies the total amount reported by the corporate card provider.';
        }
        field(21; "Transaction Total"; Decimal)
        {
            Caption = 'Transaction Total';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            CalcFormula = sum("EA Corp Card Trans".Amount where("Statement Entry No." = field("Statement Entry No.")));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total amount of the imported statement transactions.';
        }
        field(22; "Matched Transactions"; Integer)
        {
            Caption = 'Matched Transactions';
            CalcFormula = count("EA Corp Card Trans" where("Statement Entry No." = field("Statement Entry No."), "Expense No." = filter(<> '')));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of statement transactions linked to expenses.';
        }
        field(23; "Settlement Entry No."; Integer)
        {
            Caption = 'Settlement Entry No.';
            CalcFormula = lookup("EA Corp Card Settlement Line"."Settlement Entry No." where("Statement Entry No." = field("Statement Entry No."), Inactive = const(false)));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the settlement that includes this statement.';
        }
        field(24; "Reconciled Transactions"; Integer)
        {
            Caption = 'Reconciled Transactions';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the number of statement transactions reconciled to corporate card bank account ledger entries at closure.';
        }
        field(25; "Reconciled Amount"; Decimal)
        {
            Caption = 'Reconciled Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the statement transaction amount reconciled at closure.';
        }
        field(26; "Closed At"; DateTime)
        {
            Caption = 'Closed At';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies when reconciliation of the corporate card statement was closed.';
        }
        field(27; "Closed By User ID"; Code[50])
        {
            Caption = 'Closed By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Specifies the user who closed reconciliation of the corporate card statement.';
        }
        field(28; "Prev. Reconciled Transactions"; Integer)
        {
            Caption = 'Previous Reconciled Transactions';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the reconciled transaction count captured before reconciliation was invalidated.';
        }
        field(29; "Prev. Reconciled Amount"; Decimal)
        {
            Caption = 'Previous Reconciled Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the reconciled amount captured before reconciliation was invalidated.';
        }
        field(30; "Previous Closed At"; DateTime)
        {
            Caption = 'Previous Closed At';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies when the previous reconciliation closure occurred.';
        }
        field(31; "Previous Closed By User ID"; Code[50])
        {
            Caption = 'Previous Closed By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Specifies the user who completed the previous reconciliation closure.';
        }
        field(32; "Reconciliation Invalidated At"; DateTime)
        {
            Caption = 'Reconciliation Invalidated At';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies when the statement reconciliation was invalidated.';
        }
        field(33; "Reconciliation Invalidated By"; Code[50])
        {
            Caption = 'Reconciliation Invalidated By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            ToolTip = 'Specifies the user who invalidated the statement reconciliation.';
        }
        field(34; "Recon. Invalidation Reason"; Text[250])
        {
            Caption = 'Reconciliation Invalidation Reason';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies why statement reconciliation must be performed again.';
        }
    }

    keys
    {
        key(PK; "Statement Entry No.")
        {
            Clustered = true;
        }
        key(Provider; "Provider Code", "Started DT")
        {
        }
        key(ProviderStatement; "Provider Code", "Statement No.")
        {
        }
        key(StatementDate; "Statement Date")
        {
        }
    }

    trigger OnDelete()
    var
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardSettlementLine.SetRange("Statement Entry No.", "Statement Entry No.");
        if CorpCardSettlementLine.FindFirst() then
            Error(StatementInSettlementErr, "Statement No.", CorpCardSettlementLine."Settlement Entry No.");

        CorpCardTrans.SetRange("Statement Entry No.", "Statement Entry No.");
        CorpCardTrans.SetRange("Provider Code", "Provider Code");
        CorpCardTrans.DeleteAll(true);

        CorpCardException.SetRange("Statement Entry No.", "Statement Entry No.");
        CorpCardException.DeleteAll(true);
    end;

    trigger OnModify()
    begin
        if xRec.Status = xRec.Status::Closed then
            Error(ClosedStatementCannotChangeErr, "Statement No.");
    end;

    var
        ClosedStatementCannotChangeErr: Label 'Corporate card statement %1 is closed and cannot be changed.', Comment = '%1 = statement number';
        StatementInSettlementErr: Label 'Statement %1 cannot be deleted because it is included in settlement entry %2.', Comment = '%1 = statement number, %2 = settlement entry number';
}