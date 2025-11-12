// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

query 253 "Analysis View Budg. Entry Dims"
{
    Caption = 'Analysis View Budg. Entry Dims';

    elements
    {
        dataitem(Analysis_View_Budget_Entry; "Analysis View Budget Entry")
        {
            SqlJoinType = CrossJoin;
            filter(Analysis_View_Code; "Analysis View Code")
            {
            }
            filter(Budget_Name; "Budget Name")
            {
            }
            filter(Business_Unit_Code; "Business Unit Code")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            filter(G_L_Account_No; "G/L Account No.")
            {
            }
            column(Dimension_1_Value_Code; "Dimension 1 Value Code")
            {
            }
            column(Dimension_2_Value_Code; "Dimension 2 Value Code")
            {
            }
            column(Dimension_3_Value_Code; "Dimension 3 Value Code")
            {
            }
            column(Dimension_4_Value_Code; "Dimension 4 Value Code")
            {
            }
            column(Sum_Amount; Amount)
            {
                Method = Sum;
            }
        }
    }
}

