// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestTools.TestRunner;

pageextension 130488 "Test Config. AL Test Suites" extends "AL Test Suites"
{
    layout
    {
        addafter(Description)
        {
            field("Created From Suite"; Rec."Created From Suite")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the parent of this generated stability suite.';
            }
            field(Configuration; Rec.Configuration)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the configuration assigned when this suite was generated.';
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenSuite)
            {
                ApplicationArea = All;
                Caption = 'Open Suite';
                ToolTip = 'Opens the saved suite and its results without regenerating its lines.';
                Image = View;

                trigger OnAction()
                var
                    ALTestTool: Page "AL Test Tool";
                begin
                    ALTestTool.SetSuiteName(Rec.Name);
                    ALTestTool.Run();
                end;
            }
            action(RunSuite)
            {
                ApplicationArea = All;
                Caption = 'Run Suite';
                ToolTip = 'Runs the saved suite normally without regenerating it.';
                Image = TestReport;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    TestConfigurationMgt.RunSuite(Rec.Name);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
