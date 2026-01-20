// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Card page for viewing and editing an AI Test Input.
/// </summary>
page 149071 "AIT Test Input Card"
{
    Caption = 'AI Test Input';
    PageType = Card;
    SourceTable = "AIT Test Input";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
            }
            group(QueryGroup)
            {
                Caption = 'Query';

                field(QueryPreview; QueryPreview)
                {
                    Caption = 'Query JSON';
                    ToolTip = 'Specifies the query configuration as JSON.';
                    MultiLine = true;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        EditQueryJson();
                    end;
                }
            }
            group(ExpectedDataGroup)
            {
                Caption = 'Expected Data';

                field(ExpectedDataPreview; ExpectedDataPreview)
                {
                    Caption = 'Expected Data JSON';
                    ToolTip = 'Specifies the expected data/validation configuration as JSON.';
                    MultiLine = true;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        EditExpectedDataJson();
                    end;
                }
            }
            group(Metadata)
            {
                Caption = 'Metadata';

                field("Created At"; Rec."Created At")
                {
                    ToolTip = 'Specifies when this test was created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ToolTip = 'Specifies who created this test.';
                }
                field("Modified At"; Rec."Modified At")
                {
                    ToolTip = 'Specifies when this test was last modified.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditQuery)
            {
                Caption = 'Edit Query';
                ToolTip = 'Edit the query JSON.';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EditQueryJson();
                end;
            }
            action(EditExpectedData)
            {
                Caption = 'Edit Expected Data';
                ToolTip = 'Edit the expected data JSON.';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EditExpectedDataJson();
                end;
            }
            action(ExportToTestFramework)
            {
                Caption = 'Export to Test Framework';
                ToolTip = 'Exports this test input to the Test Runner framework.';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AITNoCodeMgt: Codeunit "AIT No Code Mgt";
                begin
                    AITNoCodeMgt.ExportToTestInput(Rec);
                    Message('Test input exported successfully.');
                end;
            }
            action(ViewFullJSON)
            {
                Caption = 'View Full JSON';
                ToolTip = 'View the complete test input JSON.';
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
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePreviews();
    end;

    local procedure UpdatePreviews()
    var
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
        JsonText: Text;
    begin
        QueryJson := Rec.GetQueryJson();
        QueryJson.WriteTo(JsonText);
        QueryPreview := CopyStr(JsonText, 1, 2048);

        ExpectedDataJson := Rec.GetExpectedDataJson();
        ExpectedDataJson.WriteTo(JsonText);
        ExpectedDataPreview := CopyStr(JsonText, 1, 2048);
    end;

    local procedure EditQueryJson()
    var
        JsonEditor: Page "AIT JSON Editor";
        QueryJson: JsonObject;
        NewQueryJson: JsonObject;
        JsonText: Text;
        NewJsonText: Text;
    begin
        QueryJson := Rec.GetQueryJson();
        QueryJson.WriteTo(JsonText);

        JsonEditor.SetJsonContent(JsonText);
        if JsonEditor.RunModal() = Action::OK then begin
            NewJsonText := JsonEditor.GetJsonContent();
            if NewQueryJson.ReadFrom(NewJsonText) then begin
                Rec.SetQueryJson(NewQueryJson);
                Rec.Modify(true);
                UpdatePreviews();
            end else
                Error('Invalid JSON format.');
        end;
    end;

    local procedure EditExpectedDataJson()
    var
        JsonEditor: Page "AIT JSON Editor";
        ExpectedDataJson: JsonObject;
        NewExpectedDataJson: JsonObject;
        JsonText: Text;
        NewJsonText: Text;
    begin
        ExpectedDataJson := Rec.GetExpectedDataJson();
        ExpectedDataJson.WriteTo(JsonText);

        JsonEditor.SetJsonContent(JsonText);
        if JsonEditor.RunModal() = Action::OK then begin
            NewJsonText := JsonEditor.GetJsonContent();
            if NewExpectedDataJson.ReadFrom(NewJsonText) then begin
                Rec.SetExpectedDataJson(NewExpectedDataJson);
                Rec.Modify(true);
                UpdatePreviews();
            end else
                Error('Invalid JSON format.');
        end;
    end;

    var
        QueryPreview: Text[2048];
        ExpectedDataPreview: Text[2048];
}
