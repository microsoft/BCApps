// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149039 "AIT Test Data Compare"
{
    Caption = 'AI Test Data';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AIT Log Entry";
    Extensible = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Test Data")
            {
                ShowCaption = false;

                grid(Data)
                {
                    ShowCaption = false;

                    group(Input)
                    {
                        Caption = 'Input';

                        field("View"; TestInputView)
                        {
                            Caption = 'Input View';
                            ToolTip = 'Specifies what is shown from the input.';

                            trigger OnValidate()
                            begin
                                UpdateTestData();
                            end;
                        }

                        part("Data Input"; "AIT Test Data")
                        {
                            Caption = 'Output Data';
                        }
                    }

                    group(Output)
                    {
                        Caption = 'Output';

                        field("Output View"; TestOutputView)
                        {
                            Caption = 'Output View';
                            ToolTip = 'Specifies what is shown from the output.';

                            trigger OnValidate()
                            begin
                                UpdateTestData();
                            end;
                        }

                        part("Data Output"; "AIT Test Data")
                        {
                            Caption = 'Input Data';
                        }
                    }


                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateTestData();
    end;

    local procedure UpdateTestData()
    var
        AITTestData: Codeunit "AIT Test Data";
        TestInput: Text;
        TestOutput: Text;
    begin
        TestInput := AITTestData.UpdateTestInput(Rec.GetInputBlob(), TestInputView);
        TestOutput := AITTestData.UpdateTestOutput(Rec.GetOutputBlob(), TestOutputView);

        CurrPage."Data Input".Page.SetTestData(TestInput);
        CurrPage."Data Output".Page.SetTestData(TestOutput);
    end;

    var
        TestInputView: Enum "AIT Test Input - View";
        TestOutputView: Enum "AIT Test Output - View";
}