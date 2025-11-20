// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

query 260 "Dimension Set Entries"
{
    Caption = 'Dimension Set Entries';

    elements
    {
        dataitem(Dimension_Set_Entry; "Dimension Set Entry")
        {
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            column(Dimension_Code; "Dimension Code")
            {
            }
            column(Dimension_Value_Code; "Dimension Value Code")
            {
            }
            column(Dimension_Value_ID; "Dimension Value ID")
            {
            }
            column(Dimension_Name; "Dimension Name")
            {
            }
            column(Dimension_Value_Name; "Dimension Value Name")
            {
            }
        }
    }
}

