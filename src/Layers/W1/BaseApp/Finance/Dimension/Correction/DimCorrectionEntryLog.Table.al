// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

/// <summary>
/// Logs entry number ranges processed during dimension correction operations.
/// Tracks processing progress for resumable correction jobs.
/// </summary>
table 2583 "Dim Correction Entry Log"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the parent dimension correction entry.
        /// </summary>
        field(1; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        /// <summary>
        /// Starting entry number of the processed range.
        /// </summary>
        field(2; "Start Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        /// <summary>
        /// Ending entry number of the processed range.
        /// </summary>
        field(3; "End Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "Dimension Correction Entry No.", "Start Entry No.", "End Entry No.")
        {
        }
    }
}
