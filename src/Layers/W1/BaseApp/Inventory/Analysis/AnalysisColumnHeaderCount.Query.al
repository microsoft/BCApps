// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

query 771 "Analysis Column Header Count"
{
    Caption = 'Analysis Column Header Count';

    elements
    {
        dataitem(Analysis_Column; "Analysis Column")
        {
            column(Analysis_Area; "Analysis Area")
            {
            }
            column(Analysis_Column_Template; "Analysis Column Template")
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

