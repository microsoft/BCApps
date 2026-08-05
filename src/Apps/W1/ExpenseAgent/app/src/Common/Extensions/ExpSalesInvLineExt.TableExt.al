// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Sales.History;

tableextension 6905 "Exp - Sales Inv Line - Ext" extends "Sales Invoice Line"
{
    fields
    {
        field(6900; "Posted Exp. Report No."; Code[20])
        {
            Caption = 'Posted Expense Report No.';
            DataClassification = CustomerContent;
            TableRelation = "Expense Report Header"."No.";
        }
        field(6901; "Posted Exp. Report Line No."; Integer)
        {
            Caption = 'Posted Expense Report Line No.';
            DataClassification = CustomerContent;
        }
    }
}