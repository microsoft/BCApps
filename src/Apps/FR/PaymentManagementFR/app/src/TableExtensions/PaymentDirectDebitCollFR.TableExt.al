// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;

tableextension 10839 "Payment Direct Debit Coll. FR" extends "Direct Debit Collection"
{
    fields
    {
        field(10831; "Source Table ID FR"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = CustomerContent;
        }
    }

    procedure SetPaymentErrorLink(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if "Source Table ID FR" <> 0 then begin
            GenJnlLine."Journal Template Name" := '';
            GenJnlLine."Journal Batch Name" := Format("Source Table ID FR");
            GenJnlLine."Document No." := Identifier;
            exit;
        end;

        GenJnlLine."Document No." := CopyStr(Format("No."), 1, MaxStrLen(GenJnlLine."Document No."));
    end;
}
