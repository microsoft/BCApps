// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Query providing direct access to dimension set entry data for reporting and analysis.
/// Retrieves all dimension set entries with associated dimension and dimension value information.
/// </summary>
/// <remarks>
/// Optimized for scenarios requiring full dimension set entry details including codes, names, and identifiers.
/// Provides structured access to dimension set data without complex joins or filtering logic.
/// Suitable for data export, reporting, and integration scenarios requiring complete dimension information.
/// </remarks>
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

