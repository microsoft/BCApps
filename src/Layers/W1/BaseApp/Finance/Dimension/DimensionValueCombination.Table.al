// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Stores blocked dimension value combinations to prevent invalid dimension pairings.
/// Defines restrictions between specific dimension values to enforce business rules and compliance requirements.
/// </summary>
/// <remarks>
/// Used by dimension validation to prevent incompatible dimension value combinations during posting.
/// Supports business rule enforcement where certain department and project combinations are not allowed.
/// Integrates with dimension management validation to block restricted dimension combinations across all transactions.
/// </remarks>
table 351 "Dimension Value Combination"
{
    Caption = 'Dimension Value Combination';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// First dimension code in the blocked combination pair.
        /// </summary>
        field(1; "Dimension 1 Code"; Code[20])
        {
            Caption = 'Dimension 1 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        /// <summary>
        /// First dimension value code that forms part of the blocked combination.
        /// </summary>
        field(2; "Dimension 1 Value Code"; Code[20])
        {
            Caption = 'Dimension 1 Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension 1 Code"),
                                                         Blocked = const(false));
        }
        /// <summary>
        /// Second dimension code in the blocked combination pair.
        /// </summary>
        field(3; "Dimension 2 Code"; Code[20])
        {
            Caption = 'Dimension 2 Code';
            NotBlank = true;
            TableRelation = Dimension.Code;
        }
        /// <summary>
        /// Second dimension value code that forms part of the blocked combination.
        /// </summary>
        field(4; "Dimension 2 Value Code"; Code[20])
        {
            Caption = 'Dimension 2 Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension 2 Code"),
                                                         Blocked = const(false));
        }
    }

    keys
    {
        key(Key1; "Dimension 1 Code", "Dimension 1 Value Code", "Dimension 2 Code", "Dimension 2 Value Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

