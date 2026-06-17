// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149043 "AIT Batch Run Dialog"
{
    Caption = 'Batch Run';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;

                field(Iterations; Iterations)
                {
                    ApplicationArea = All;
                    Caption = 'Number of iterations';
                    ToolTip = 'Specifies the number of iterations to run.';
                }
            }
        }
    }

    var
        Iterations: Integer;

    trigger OnInit()
    begin
        Iterations := 1;
    end;

    procedure GetNumberOfIterations(): Integer
    begin
        exit(Iterations);
    end;
}