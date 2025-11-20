// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

query 251 "G/L Budget Entry Dimensions"
{
    Caption = 'G/L Budget Entry Dimensions';

    elements
    {
        dataitem(G_L_Budget_Entry; "G/L Budget Entry")
        {
            filter(Budget_Name; "Budget Name")
            {
            }
            filter(G_L_Account_No; "G/L Account No.")
            {
            }
            filter(Date; Date)
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
        }
    }
}

