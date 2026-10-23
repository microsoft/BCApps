// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestTools.TestRunner;

/// <summary>
/// Generation-only transport for the PowerShell stability flow.
/// </summary>
pageextension 130487 "Test Config. Cmd Line Tool" extends "Command Line Test Tool"
{
    layout
    {
        addlast(content)
        {
            group(TestConfigurationGroup)
            {
                Caption = 'Stability';
                field(TestConfigSuiteName; TestConfigSuiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Stability Parent Suite';
                    ToolTip = 'Specifies the parent suite whose saved configurations will be generated.';
                }
                field(TestConfigSuitesJSON; TestConfigSuitesJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Generated Stability Suites JSON';
                    ToolTip = 'Specifies the generated suite codes and their configuration codes. Generation does not run tests.';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(GenerateStabilitySuites)
            {
                ApplicationArea = All;
                Caption = 'Generate Stability Suites';
                ToolTip = 'Replaces all stability suites for the parent and returns their codes without running tests.';
                Image = CreateDocuments;

                trigger OnAction()
                var
                    ALTestSuite: Record "AL Test Suite";
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                    SuiteNames: List of [Code[10]];
                    SuiteName: Code[10];
                    Suites: JsonArray;
                    Suite: JsonObject;
                begin
                    Clear(TestConfigSuitesJSON);
                    SuiteNames := TestConfigurationMgt.GenerateStabilitySuites(GetCurrentSuite());
                    foreach SuiteName in SuiteNames do begin
                        ALTestSuite.Get(SuiteName);
                        Clear(Suite);
                        Suite.Add('suite', SuiteName);
                        Suite.Add('configuration', ALTestSuite.Configuration);
                        Suites.Add(Suite);
                    end;
                    Suites.WriteTo(TestConfigSuitesJSON);
                    CurrPage.Update(false);
                end;
            }
            action(ResetStabilityMode)
            {
                ApplicationArea = All;
                Caption = 'Reset Stability Mode';
                ToolTip = 'Resets the active configuration and libraries without changing saved suites or results.';
                Image = Undo;

                trigger OnAction()
                var
                    TestConfigurationMgt: Codeunit "Test Configuration Mgt";
                begin
                    TestConfigurationMgt.ResetStabilityMode(GetCurrentSuite());
                    Clear(TestConfigSuitesJSON);
                end;
            }
        }
    }

    var
        TestConfigSuitesJSON: Text;
        TestConfigSuiteName: Code[10];

    local procedure GetCurrentSuite(): Code[10]
    begin
        if TestConfigSuiteName <> '' then
            exit(TestConfigSuiteName);
        Rec.TestField("Test Suite");
        exit(Rec."Test Suite");
    end;
}
