// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores intercompany dimension definitions for cross-company dimension mapping and synchronization.
/// Enables consistent dimension structure across multiple intercompany partners.
/// </summary>
table 411 "IC Dimension"
{
    Caption = 'IC Dimension';
    DataCaptionFields = "Code", Name;
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique code identifying the intercompany dimension.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the intercompany dimension.
        /// </summary>
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Indicates whether the intercompany dimension is blocked from use.
        /// </summary>
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Local dimension code that this intercompany dimension maps to for transaction processing.
        /// </summary>
        field(4; "Map-to Dimension Code"; Code[20])
        {
            Caption = 'Map-to Dimension Code';
            TableRelation = Dimension;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Blocked, "Map-to Dimension Code")
        {
        }
    }
}
#endif
