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
            ToolTip = 'Specifies the supply chain finance payment date for this vendor ledger entry.';
            DataClassification = CustomerContent;
        }
    }
}
