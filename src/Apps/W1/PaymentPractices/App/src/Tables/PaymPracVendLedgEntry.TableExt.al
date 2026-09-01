// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;

tableextension 681 "Paym. Prac. Vend. Ledg. Entry" extends "Vendor Ledger Entry"
{
    fields
    {
        field(680; "SCF Payment Date"; Date)
        {
            Caption = 'SCF Payment Date';
            ToolTip = 'Specifies when the supplier received payment from a finance provider under a supply chain finance arrangement. When filled in, replaces the payment posting date for calculating actual payment days.';
            DataClassification = CustomerContent;
        }
    }
}
