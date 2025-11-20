// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

query 5502 "Tax Groups For Tax Areas"
{
    Caption = 'Tax Groups For Tax Areas';

    elements
    {
        dataitem(Tax_Area; "Tax Area")
        {
            column(Tax_Area_Code; "Code")
            {
            }
            dataitem(Tax_Area_Line; "Tax Area Line")
            {
                DataItemLink = "Tax Area" = Tax_Area.Code;
                SqlJoinType = InnerJoin;
                column(Tax_Jurisdiction_Code; "Tax Jurisdiction Code")
                {
                }
                dataitem(Tax_Detail; "Tax Detail")
                {
                    DataItemLink = "Tax Jurisdiction Code" = Tax_Area_Line."Tax Jurisdiction Code";
                    SqlJoinType = InnerJoin;
                    column(Tax_Group_Code; "Tax Group Code")
                    {
                    }
                }
            }
        }
    }
}

