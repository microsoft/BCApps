// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Journal;

tableextension 6976 "Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(6500; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6501; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
            DataClassification = CustomerContent;
        }
        field(6502; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category"));
            DataClassification = CustomerContent;
        }
    }
}