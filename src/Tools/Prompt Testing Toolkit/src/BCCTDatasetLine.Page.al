// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149032 "BCCT Dataset Line"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BCCT Dataset Line";
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(DatasetLines)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the line.';
                }
                field(Input; Rec.Input)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the test input.';

                    trigger OnValidate()
                    begin
                        Rec.SetInputBlob(Rec.Input);
                    end;
                }
                field(Output; Rec."Expected Output")
                {
                    ApplicationArea = All;
                    Caption = 'Expected Response';
                    ToolTip = 'Specifies the response for measuring accuracy.';

                    trigger OnValidate()
                    begin
                        Rec.SetExpOutputBlob(Rec."Expected Output");
                    end;
                }
            }
        }
    }


    trigger OnOpenPage()
    begin
        Rec.SetRange("Dataset Name", DatasetName);
    end;

    var
        DatasetName: Code[50];

    internal procedure SetDatasetName(Name: Code[50])
    begin
        DatasetName := Name;
    end;
}