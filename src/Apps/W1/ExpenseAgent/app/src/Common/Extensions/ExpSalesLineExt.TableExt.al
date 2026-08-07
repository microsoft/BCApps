// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Sales.Document;

tableextension 6901 "Exp - Sales Line - Ext" extends "Sales Line"
{
    fields
    {
        field(6900; "Posted Exp. Report No."; Code[20])
        {
            Caption = 'Posted Expense Report No.';
            DataClassification = CustomerContent;
            TableRelation = "Posted Expense Report Header"."No.";
        }
        field(6901; "Posted Exp. Report Line No."; Integer)
        {
            Caption = 'Posted Expense Report Line No.';
            DataClassification = CustomerContent;
        }
    }
}