// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Lists the outcome of every test method executed during a stability run, grouped implicitly by
/// preset combination. Use it to troubleshoot failures produced by a specific combination.
/// </summary>
page 130475 "Stability Run Results"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Stability Run Result";
    Caption = 'Stability Run Results';
    Editable = false;
    SourceTableView = sorting("Entry No.");
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Results)
            {
                field("Configuration"; Rec."Configuration")
                {
                    ToolTip = 'Specifies the stability preset combination that produced this result.';
                }
                field("Codeunit Name"; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the test codeunit.';
                }
                field("Method"; Rec."Method")
                {
                    ToolTip = 'Specifies the test method.';
                }
                field("Result"; Rec."Result")
                {
                    ToolTip = 'Specifies whether the test passed or failed.';
                    StyleExpr = ResultStyleExpr;
                }
                field("Seed"; Rec."Seed")
                {
                    ToolTip = 'Specifies the pseudo-random seed used.';
                }
                field("Seed Overridden"; Rec."Seed Overridden")
                {
                    ToolTip = 'Specifies whether the seed was forced by the stability run.';
                }
                field("WorkDate Offset"; Rec."WorkDate Offset")
                {
                    ToolTip = 'Specifies the WorkDate offset applied during the run.';
                }
                field("WorkDate"; Rec."WorkDate")
                {
                    ToolTip = 'Specifies the WorkDate used during the run.';
                }
                field("Reverse Codeunits"; Rec."Reverse Codeunits")
                {
                    ToolTip = 'Specifies whether the codeunits were executed in reverse order.';
                }
                field("Reverse Methods"; Rec."Reverse Methods")
                {
                    ToolTip = 'Specifies whether the methods were executed in reverse order.';
                }
                field("One By One"; Rec."One By One")
                {
                    ToolTip = 'Specifies whether the methods were executed in isolation.';
                }
                field("Duration"; Rec."Duration")
                {
                    ToolTip = 'Specifies how long the test method ran.';
                }
                field("Executed At"; Rec."Executed At")
                {
                    ToolTip = 'Specifies when the test method was executed.';
                }
                field("Error Message Preview"; Rec."Error Message Preview")
                {
                    ToolTip = 'Specifies the beginning of the error message for a failed test.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowError)
            {
                ApplicationArea = All;
                Caption = 'Show Error';
                ToolTip = 'Shows the full error message and call stack for the selected result.';
                Image = ShowList;

                trigger OnAction()
                begin
                    if Rec."Result" <> Rec."Result"::Failure then
                        exit;
                    Message(ErrorDetailsMsg, Rec.GetErrorMessage(), Rec.GetErrorCallStack());
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Result" = Rec."Result"::Failure then
            ResultStyleExpr := 'Unfavorable'
        else
            ResultStyleExpr := 'Favorable';
    end;

    var
        ResultStyleExpr: Text;
        ErrorDetailsMsg: Label '%1\%2', Comment = '%1 = error message, %2 = error call stack';
}
