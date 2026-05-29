// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149049 "AIT Log Entry Outcome Part"
{
    ApplicationArea = All;
    Caption = 'Test Outcome';
    PageType = CardPart;
    Editable = false;
    SourceTable = "AIT Log Entry";
    Extensible = true;

    layout
    {
        area(Content)
        {
            field(Status; Rec.Status)
            {
                StyleExpr = StatusStyleExpr;
            }
            field(Accuracy; Rec."Test Method Line Accuracy")
            {
                Caption = 'Evaluation Result';
                ToolTip = 'Specifies the accuracy of the eval line.';
                AutoFormatType = 0;
            }
            field(TurnsText; TurnsText)
            {
                Caption = 'No. of Turns Passed';
                ToolTip = 'Specifies the number of turns that passed out of the total number of turns.';
                StyleExpr = TurnsStyleExpr;
            }
            group(ErrorMessageGroup)
            {
                Caption = 'Error Message';
                field(ErrorMessage; ErrorMessage)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the error message from the eval.';
                    Style = Unfavorable;
                    Multiline = true;

                    trigger OnDrillDown()
                    begin
                        Message(ErrorMessage);
                    end;
                }
            }
            field(Duration; Rec."Duration (ms)")
            {
                Caption = 'Duration (ms)';
                ToolTip = 'Specifies the duration of the test execution in milliseconds.';
                AutoFormatType = 0;
            }
        }
    }

    var
        TurnsText: Text;
        ErrorMessage: Text;
        StatusStyleExpr: Text;
        TurnsStyleExpr: Text;

    trigger OnAfterGetRecord()
    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        TurnsText := AITTestSuiteMgt.GetTurnsAsText(Rec);
        SetStatusStyleExpr();
        SetTurnsStyleExpr();
        SetErrorMessage();
    end;

    local procedure SetStatusStyleExpr()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyleExpr := Format(PageStyle::Favorable);
            Rec.Status::Error:
                StatusStyleExpr := Format(PageStyle::Unfavorable);
            Rec.Status::Skipped:
                StatusStyleExpr := Format(PageStyle::Ambiguous);
            else
                StatusStyleExpr := '';
        end;
    end;

    local procedure SetTurnsStyleExpr()
    begin
        case Rec."No. of Turns Passed" of
            Rec."No. of Turns":
                TurnsStyleExpr := Format(PageStyle::Favorable);
            0:
                TurnsStyleExpr := Format(PageStyle::Unfavorable);
            else
                TurnsStyleExpr := Format(PageStyle::Ambiguous);
        end;
    end;

    local procedure SetErrorMessage()
    begin
        ErrorMessage := '';
        if Rec.Status = Rec.Status::Error then
            ErrorMessage := Rec.GetMessage();
    end;
}
