// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

query 770 "Analysis Line Desc. Count"
{
    Caption = 'Analysis Line Desc. Count';

    elements
    {
        dataitem(Analysis_Line; "Analysis Line")
        {
            column(Analysis_Area; "Analysis Area")
            {
            }
            column(Analysis_Line_Template_Name; "Analysis Line Template Name")
            {
            }
            column(Description; Description)
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

