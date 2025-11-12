// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

query 763 "Colm. Layt. Colm. Header Count"
{
    Caption = 'Colm. Layt. Colm. Header Count';

    elements
    {
        dataitem(Column_Layout; "Column Layout")
        {
            column(Column_Layout_Name; "Column Layout Name")
            {
            }
            column(Column_Header; "Column Header")
            {
            }
            column(Count_)
            {
                ColumnFilter = Count_ = filter(> 1);
                Method = Count;
            }
        }
    }
}

