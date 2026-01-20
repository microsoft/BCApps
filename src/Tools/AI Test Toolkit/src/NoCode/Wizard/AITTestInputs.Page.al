// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// List page for viewing and managing AI Test Inputs created via the No-Code wizard.
/// </summary>
page 149070 "AIT Test Inputs"
{
    Caption = 'AI Test Inputs';
    PageType = List;
    SourceTable = "AIT Test Input";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "AIT Test Input Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(TestInputs)
            {
                field("Dataset Code"; Rec."Dataset Code")
                {
                    ToolTip = 'Specifies the dataset this test belongs to.';
                }
                field("Test Name"; Rec."Test Name")
                {
                    ToolTip = 'Specifies the name of the test.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of what this test validates.';
                }
                field("Feature Code"; Rec."Feature Code")
                {
                    ToolTip = 'Specifies the AI feature this test is for.';
                }
                field("Test Setup Reference"; Rec."Test Setup Reference")
                {
                    ToolTip = 'Specifies the test setup file reference.';
                }
                field("Created At"; Rec."Created At")
                {
                    ToolTip = 'Specifies when this test was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ToolTip = 'Specifies who created this test.';
                }
            }
        }
        area(FactBoxes)
        {
            part(JsonPreview; "AIT Test Input JSON Preview")
            {
                Caption = 'JSON Preview';
                SubPageLink = "Dataset Code" = field("Dataset Code"), "Test Name" = field("Test Name");
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewTestWizard)
            {
                Caption = 'New Test';
                ToolTip = 'Opens the wizard to create a new test.';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = New;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AITDatasetWizard: Page "AIT Dataset Wizard";
                begin
                    AITDatasetWizard.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(ExportToTestFramework)
            {
                Caption = 'Export to Test Framework';
                ToolTip = 'Exports the selected test inputs to the Test Runner framework.';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AITTestInput: Record "AIT Test Input";
                    AITNoCodeMgt: Codeunit "AIT No Code Mgt";
                    ExportCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(AITTestInput);
                    if AITTestInput.FindSet() then
                        repeat
                            AITNoCodeMgt.ExportToTestInput(AITTestInput);
                            ExportCount += 1;
                        until AITTestInput.Next() = 0;

                    Message('%1 test input(s) exported successfully.', ExportCount);
                end;
            }
            action(ViewJSON)
            {
                Caption = 'View JSON';
                ToolTip = 'View the complete JSON for this test input.';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    TestInputJson: JsonObject;
                    JsonText: Text;
                begin
                    TestInputJson := Rec.BuildTestInputJson();
                    TestInputJson.WriteTo(JsonText);
                    Message(JsonText);
                end;
            }
        }
        area(Navigation)
        {
            action(Features)
            {
                Caption = 'AI Features';
                ToolTip = 'View and manage AI feature schemas.';
                Image = Setup;
                RunObject = page "AIT Query Schemas";
            }
        }
    }
}
