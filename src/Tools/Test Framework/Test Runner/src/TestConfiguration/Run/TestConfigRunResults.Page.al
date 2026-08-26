// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Shows the outcome of every test method captured during the last stability run, for each
/// configuration, so failures are easy to troubleshoot.
/// </summary>
page 130485 "Test Config. Run Results"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = History;
    SourceTable = "Test Configuration Run Result";
    Caption = 'Test Configuration Run Results';
    Editable = false;
    SourceTableView = sorting("Result");

    layout
    {
        area(Content)
        {
            repeater(Results)
            {
                field("Configuration"; Rec."Configuration")
                {
                    ToolTip = 'Specifies the configuration that produced the result.';
                }
                field("Result"; Rec."Result")
                {
                    ToolTip = 'Specifies whether the test method passed or failed.';
                    StyleExpr = ResultStyle;
                }
                field("Codeunit Name"; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the test codeunit.';
                }
                field("Method"; Rec."Method")
                {
                    ToolTip = 'Specifies the test method.';
                }
                field("Error Message Preview"; Rec."Error Message Preview")
                {
                    ToolTip = 'Specifies the beginning of the error message when the test failed.';
                }
                field("Base Suite"; Rec."Base Suite")
                {
                    ToolTip = 'Specifies the base suite that was exercised.';
                }
                field("Generated Suite"; Rec."Generated Suite")
                {
                    ToolTip = 'Specifies the generated suite that was executed.';
                }
                field("Seed"; Rec."Seed")
                {
                    ToolTip = 'Specifies the random seed that was used.';
                }
                field("Seed Set"; Rec."Seed Set")
                {
                    ToolTip = 'Specifies whether a random seed was set by the configuration.';
                }
                field("WorkDate Offset"; Rec."WorkDate Offset")
                {
                    ToolTip = 'Specifies the WorkDate shift that was applied.';
                }
                field("WorkDate"; Rec."WorkDate")
                {
                    ToolTip = 'Specifies the WorkDate the test ran with.';
                }
                field("Reverse Codeunits"; Rec."Reverse Codeunits")
                {
                    ToolTip = 'Specifies whether the codeunits ran in reverse order.';
                }
                field("Reverse Methods"; Rec."Reverse Methods")
                {
                    ToolTip = 'Specifies whether the methods ran in reverse order.';
                }
                field("One By One"; Rec."One By One")
                {
                    ToolTip = 'Specifies whether the test method ran in isolation.';
                }
                field("Duration"; Rec."Duration")
                {
                    ToolTip = 'Specifies how long the test method took.';
                }
                field("Executed At"; Rec."Executed At")
                {
                    ToolTip = 'Specifies when the test method ran.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowError)
            {
                ApplicationArea = All;
                Caption = 'Show error';
                ToolTip = 'Shows the full error message and call stack for the selected result.';
                Image = Error;

                trigger OnAction()
                var
                    ErrorText: Text;
                begin
                    ErrorText := Rec.GetErrorMessage();
                    if Rec.GetErrorCallStack() <> '' then
                        ErrorText += '\\' + Rec.GetErrorCallStack();
                    if ErrorText = '' then
                        ErrorText := NoErrorTxt;
                    Message(ErrorText);
                end;
            }
        }
    }

    var
        ResultStyle: Text;
        NoErrorTxt: Label 'There is no error for this result.';

    trigger OnAfterGetRecord()
    begin
        if Rec."Result" = Rec."Result"::Failure then
            ResultStyle := 'Unfavorable'
        else
            ResultStyle := 'Favorable';
    end;
}
