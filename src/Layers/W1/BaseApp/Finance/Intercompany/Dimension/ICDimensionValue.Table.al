// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores intercompany dimension values for cross-company dimension value mapping and synchronization.
/// Enables consistent dimension value structure across multiple intercompany partners.
/// </summary>
table 412 "IC Dimension Value"
{
    Caption = 'IC Dimension Value';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Code of the intercompany dimension that this value belongs to.
        /// </summary>
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
        }
        /// <summary>
        /// Unique code identifying the intercompany dimension value.
        /// </summary>
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the intercompany dimension value.
        /// </summary>
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Type of dimension value controlling posting and hierarchy behavior.
        /// </summary>
        field(4; "Dimension Value Type"; Option)
        {
            AccessByPermission = TableData Dimension = R;
            Caption = 'Dimension Value Type';
            OptionCaption = 'Standard,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Standard,Heading,Total,"Begin-Total","End-Total";
        }
        /// <summary>
        /// Indicates whether the intercompany dimension value is blocked from use.
        /// </summary>
        field(5; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Local dimension code that this intercompany dimension value maps to for transaction processing.
        /// </summary>
        field(6; "Map-to Dimension Code"; Code[20])
        {
            Caption = 'Map-to Dimension Code';
            TableRelation = Dimension.Code;
        }
        /// <summary>
        /// Local dimension value code that this intercompany dimension value maps to for transaction processing.
        /// </summary>
        field(7; "Map-to Dimension Value Code"; Code[20])
        {
            Caption = 'Map-to Dimension Value Code';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Map-to Dimension Code"), Blocked = const(false));
        }
        /// <summary>
        /// Indentation level for hierarchical display of dimension values.
        /// </summary>
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
    }

    keys
    {
        key(Key1; "Dimension Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
#endif
