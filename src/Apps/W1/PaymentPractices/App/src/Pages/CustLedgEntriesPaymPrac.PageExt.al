// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Sales.Receivables;

pageextension 686 "Cust. Ledg. Entries Paym. Prac" extends "Customer Ledger Entries"
{
    layout
    {
        addafter("On Hold")
        {
            field("Overdue Due to Dispute"; Rec."Overdue Due to Dispute")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
    }
}
