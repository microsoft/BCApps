// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

query 256 "CF Forecast Entry Dimensions"
{
    Caption = 'CF Forecast Entry Dimensions';

    elements
    {
        dataitem(Cash_Flow_Forecast_Entry; "Cash Flow Forecast Entry")
        {
            filter(Cash_Flow_Forecast_No; "Cash Flow Forecast No.")
            {
            }
            filter(Cash_Flow_Date; "Cash Flow Date")
            {
            }
            filter(Cash_Flow_Account_No; "Cash Flow Account No.")
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
            column(Sum_Amount_LCY; "Amount (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

