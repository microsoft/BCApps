// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

/// <summary>
/// Setup table for dimensions that are blocked from dimension correction operations. Prevents specific dimensions from being modified through dimension correction processes.
/// </summary>
table 2580 "Dim Correction Blocked Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Code of the dimension that is blocked from dimension correction operations.
        /// </summary>
        field(1; "Dimension Code"; Code[20])
        {
            ToolTip = 'Specifies the dimension that cannot be used for corrections.';
            DataClassification = CustomerContent;
            TableRelation = Dimension.Code;
        }
    }

    keys
    {
        key(Key1; "Dimension Code")
        {
            Clustered = true;
        }
    }
}
