// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Query object providing G/L entry data aggregated by dimensions for analytical reporting.
/// Enables dimensional analysis with sum calculations for amounts, debits, and credits.
/// </summary>
/// <remarks>
/// Data source: G/L Entry table. Aggregates amounts by dimension combinations.
/// Supports filtering by G/L account, posting date, business unit, and global dimensions.
/// Used for dimensional financial analysis and reporting with sum calculations.
/// </remarks>
query 250 "G/L Entry Dimensions"
{
    Caption = 'G/L Entry Dimensions';

    elements
    {
        dataitem(G_L_Entry; "G/L Entry")
        {
            filter(G_L_Account_No; "G/L Account No.")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            filter(Business_Unit_Code; "Business Unit Code")
            {
            }
            filter(Global_Dimension_1_Code; "Global Dimension 1 Code")
            {
            }
            filter(Global_Dimension_2_Code; "Global Dimension 2 Code")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            column(Sum_Amount; Amount)
            {
                Method = Sum;
            }
            column(Sum_Debit_Amount; "Debit Amount")
            {
                Method = Sum;
            }
            column(Sum_Credit_Amount; "Credit Amount")
            {
                Method = Sum;
            }
        }
    }
}

