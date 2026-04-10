// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Displays all master data records where a specific default dimension is currently assigned.
/// Provides read-only view for analyzing dimension usage across tables and records.
/// </summary>
/// <remarks>
/// Enables impact analysis before modifying or deleting dimension values by showing current usage patterns.
/// Supports dimension cleanup and validation workflows for dimension management operations.
/// </remarks>
page 544 "Default Dimension Where-Used"
{
    PageType = List;
    SourceTable = "Default Dimension";
    InsertAllowed = false;
    Editable = false;
    DeleteAllowed = false;
    DataCaptionFields = "Dimension Value Code", "Dimension Code";


    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
