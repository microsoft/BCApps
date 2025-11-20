// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

query 270 "G/L Budget Entries"
{
    Caption = 'G/L Budget Entries';

    elements
    {
        dataitem(G_L_Budget_Entry; "G/L Budget Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Budget_Name; "Budget Name")
            {
            }
            column(G_L_Account_No; "G/L Account No.")
            {
            }
            column(Business_Unit_Code; "Business Unit Code")
            {
            }
            column(Date; Date)
            {
            }
            column(Amount; Amount)
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
        }
    }
}

