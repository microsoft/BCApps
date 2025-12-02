// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Sales.Receivables;

tableextension 686 "Cust. Ledg. Entry Paym. Prac." extends "Cust. Ledger Entry"
{
    fields
    {
        field(686; "Overdue Due to Dispute"; Boolean)
        {
            Caption = 'Overdue Due to Dispute';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if the late payment on this invoice was due to a dispute.';

            trigger OnValidate()
            begin
                if Rec."Document Type" <> Rec."Document Type"::Invoice then
                    Error(OverdueDueToDisputeOnlyForInvoicesErr);
            end;
        }
    }

    var
        OverdueDueToDisputeOnlyForInvoicesErr: Label 'Overdue Due to Dispute can only be set on invoice entries.';
}