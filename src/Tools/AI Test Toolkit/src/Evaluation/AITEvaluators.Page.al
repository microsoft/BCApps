// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.AITestToolkit;

page 149045 "AIT Evaluators"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "AIT Evaluator";

    layout
    {
        area(Content)
        {
            repeater(Evaluators)
            {
                field("Test Suite Code"; Rec."Test Suite Code")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Eval Suite Code';
                    ToolTip = 'Specifies the code of the eval suite.';
                    Visible = false;
                }
                field("Test Method Line"; Rec."Test Method Line")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Eval Method Line';
                    ToolTip = 'Specifies the line number of the eval method.';
                    Visible = false;
                }
                field(Evaluator; Rec.Evaluator)
                {
                    ApplicationArea = All;
                    Caption = 'Evaluator';
                    ToolTip = 'Specifies the evaluator to use in the eval suite.';
                }
                field(EvaluatorType; Rec."Evaluator Type")
                {
                    ApplicationArea = All;
                    Caption = 'Evaluator Type';
                    ToolTip = 'Specifies the type of evaluator.';
                }
            }
        }

    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Test Method Line" := TestMethodLineNo;
    end;

    var
        TestMethodLineNo: Integer;

    internal procedure SetTestMethodLine(LineNo: Integer)
    begin
        TestMethodLineNo := LineNo;
    end;
}