// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130461 "Test Outputs"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Test Output";
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(Name; Rec."Method Name")
                {
                }
                field("Data Input"; Rec."Data Input")
                {
                }
                field(TestOutput; TestOutputTxt)
                {
                    Caption = 'Test Output';
                    ToolTip = 'Specifies the test output for the test method line';
                    Editable = false;
                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetOutput());
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TestOutputTxt := Rec.GetOutput();
    end;

    var
        TestOutputTxt: Text;
}