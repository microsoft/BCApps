// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;

page 149042 "AIT CommandLine Card"
{
    Caption = 'AI Test CommandLine Runner';
    PageType = Card;
    Extensible = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("Select Code"; this.AITCode)
                {
                    Caption = 'Select Code', Locked = true;
                    ToolTip = 'Specifies the ID of the suite.';
                    ApplicationArea = All;
                    TableRelation = "AIT Test Suite".Code;

                    trigger OnValidate()
                    var
                        AITTestSuite: record "AIT Test Suite";
                        AITTestMethodLine: record "AIT Test Method Line";
                    begin
                        if not AITTestSuite.Get(this.AITCode) then
                            Error(this.CannotFindAITSuiteErr, this.AITCode);

                        AITTestMethodLine.SetRange("Test Suite Code", this.AITCode);
                        this.NoOfTests := AITTestMethodLine.Count();
                    end;
                }


                field("No. of Tests"; this.NoOfTests)
                {
                    Caption = 'No. of Tests', Locked = true;
                    ToolTip = 'Specifies the number of AIT Suite Lines present in the AIT Suite';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(StartNext)
            {
                Enabled = this.EnableActions;
                ApplicationArea = All;
                Caption = 'Start Next', Locked = true;
                Image = Start;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Starts the next available test.';

                trigger OnAction()
                begin
                    this.StartNextAIT();
                end;
            }
        }
    }

    var
        CannotFindAITSuiteErr: Label 'The specified AIT Suite with code %1 cannot be found.', Comment = '%1 = AIT Suite id.';
        EnableActions: Boolean;
        AITCode: Code[100];
        NoOfTests: Integer;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        this.EnableActions := (EnvironmentInformation.IsSaas() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    local procedure StartNextAIT()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        if AITTestSuite.Get(this.AITCode) then
            AITTestSuiteMgt.StartAITSuite(AITTestSuite);
    end;
}