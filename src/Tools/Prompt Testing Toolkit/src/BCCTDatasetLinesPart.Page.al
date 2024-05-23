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
    Caption = 'Lines';
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
                field(InputText; TestInputText)
                {
                    ApplicationArea = All;
                    Caption = 'Test Input Text';
                    ToolTip = 'Specifies the test input.';

                    trigger OnValidate()
                    begin
                        Rec.SetInputTextAsBlob(TestInputText);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TestInputText := Rec.GetInputBlobAsText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Id = 0 then
            TestInputText := '';
    end;

    var
        TestInputText: Text;
}