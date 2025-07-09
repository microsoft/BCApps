// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

page 149044 "AIT Column Mappings"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "AIT Column Mapping";

    layout
    {
        area(Content)
        {
            repeater(ColumnMappings)
            {
                field("Test Suite Code"; Rec."Test Suite Code")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Test Suite Code';
                    ToolTip = 'Specifies the code of the test suite.';
                }
                field("Test Method Line"; Rec."Test Method Line")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Test Method Line';
                    ToolTip = 'Specifies the line number of the test method.';
                }
                field(Column; Rec.Column)
                {
                    ApplicationArea = All;
                    Caption = 'Column';
                    ToolTip = 'Specifies the column from the test output data to use in evaluation.';
                }
                field("Target Column"; Rec."Target Column")
                {
                    ApplicationArea = All;
                    Caption = 'Target Column';
                    ToolTip = 'Specifies the target column from the test output data to use in evaluation.';
                }
            }
        }
    }
}