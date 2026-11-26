// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// List page for managing dimension values within a specific dimension.
/// Provides comprehensive interface for creating, editing, and organizing dimension values with hierarchical support.
/// </summary>
/// <remarks>
/// Supports hierarchical dimension value structures with Begin-Total and End-Total types for reporting and analysis.
/// Includes functionality for dimension value indentation, translation management, and bulk operations.
/// </remarks>
pageextension 537 "IC Dimension Values" extends "Dimension Values"
{
    layout
    {
        addafter(Blocked)
        {
            field("Map-to IC Dimension Value Code"; Rec."Map-to IC Dimension Value Code")
            {
                ApplicationArea = Dimensions;
                Visible = false;
            }
        }
    }
}
