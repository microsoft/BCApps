// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Card page for viewing and editing an AI feature query schema.
/// </summary>
page 149076 "AIT Query Schema Card"
{
    Caption = 'AI Test Feature Schema';
    PageType = Card;
    SourceTable = "AIT Query Schema";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Feature Code"; Rec."Feature Code")
                {
                    ToolTip = 'Specifies the unique identifier for the AI feature.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the AI feature.';
                }
                field("Default Codeunit ID"; Rec."Default Codeunit ID")
                {
                    ToolTip = 'Specifies the default test codeunit for this feature.';
                }
                field("Default Codeunit Name"; Rec."Default Codeunit Name")
                {
                    ToolTip = 'Specifies the name of the default test codeunit.';
                }
            }
            group(Schema)
            {
                Caption = 'Query Schema';

                field(SchemaPreview; SchemaPreview)
                {
                    Caption = 'Schema JSON';
                    ToolTip = 'Specifies the JSON schema defining the query fields.';
                    MultiLine = true;
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        EditSchemaJson();
                    end;
                }
            }
            part(SchemaFields; "AIT Query Schema Fields")
            {
                Caption = 'Schema Fields';
                SubPageLink = "Feature Code" = field("Feature Code");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditSchemaAction)
            {
                Caption = 'Edit Schema';
                ToolTip = 'Edit the JSON schema for this feature.';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                begin
                    EditSchemaJson();
                end;
            }
            action(NewTestWizard)
            {
                Caption = 'Create Test';
                ToolTip = 'Opens the wizard to create a new test for this feature.';
                Image = NewDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AITDatasetWizard: Page "AIT Dataset Wizard";
                begin
                    AITDatasetWizard.SetFeature(Rec."Feature Code");
                    AITDatasetWizard.RunModal();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        SchemaJson: JsonObject;
        SchemaText: Text;
    begin
        SchemaJson := Rec.GetSchemaJson();
        SchemaJson.WriteTo(SchemaText);
        if StrLen(SchemaText) > 250 then
            SchemaPreview := CopyStr(SchemaText, 1, 247) + '...'
        else
            SchemaPreview := CopyStr(SchemaText, 1, 250);
    end;

    local procedure EditSchemaJson()
    var
        JsonEditor: Page "AIT JSON Editor";
        SchemaJson: JsonObject;
        NewSchemaJson: JsonObject;
        SchemaText: Text;
        NewSchemaText: Text;
    begin
        SchemaJson := Rec.GetSchemaJson();
        SchemaJson.WriteTo(SchemaText);

        JsonEditor.SetJsonContent(SchemaText);
        if JsonEditor.RunModal() = Action::OK then begin
            NewSchemaText := JsonEditor.GetJsonContent();
            if NewSchemaJson.ReadFrom(NewSchemaText) then begin
                Rec.SetSchemaJson(NewSchemaJson);
                Rec.Modify(true);
                CurrPage.Update(false);
            end else
                Error('Invalid JSON format.');
        end;
    end;

    var
        SchemaPreview: Text[250];
}