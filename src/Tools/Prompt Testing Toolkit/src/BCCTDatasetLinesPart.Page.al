// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

page 149036 "BCCT Dataset Lines Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BCCT Dataset Line";
    Caption = 'Dataset Lines';
    PopulateAllFields = true;
    DelayedInsert = true;

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
                    Visible = false;
                }
                field(InputText; InputText)
                {
                    ApplicationArea = All;
                    Caption = 'Input Text';
                    ToolTip = 'Specifies the test input.';

                    trigger OnValidate()
                    begin
                        Rec.SetInputTextAsBlob(InputText);
                    end;
                }
                field(ExpectedOutputText; ExpectedOutputText)
                {
                    ApplicationArea = All;
                    Caption = 'Expected Output Response';
                    ToolTip = 'Specifies the response for measuring accuracy.';

                    trigger OnValidate()
                    begin
                        Rec.SetExpectedOutputTextAsBlob(ExpectedOutputText);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InputText := Rec.GetInputBlobAsText();
        ExpectedOutputText := Rec.GetExpectedOutputBlobAsText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Id = 0 then begin
            InputText := '';
            ExpectedOutputText := '';
        end;
    end;

    var
        InputText: Text;
        ExpectedOutputText: Text;
}