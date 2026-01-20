// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// No-Code wizard for creating AI test datasets without writing YAML files.
/// A dataset contains multiple tests, each with its own setup, query, and validations.
/// Guides users through: Feature selection → Dataset basics → Tests management → Review and export.
/// </summary>
page 149082 "AIT Dataset Wizard"
{
    Caption = 'Create AI Test Dataset';
    PageType = NavigatePage;
    ApplicationArea = All;
    SourceTable = "AIT Test Input";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(Step1FeatureSelection)
            {
                Caption = '';
                Visible = CurrentStep = 1;

                group(Step1Header)
                {
                    Caption = 'Select AI Feature';
                    InstructionalText = 'Choose the AI feature you want to create tests for. All tests in this dataset will use the same feature schema.';
                }
                group(Step1Content)
                {
                    ShowCaption = false;

                    field(FeatureCode; Rec."Feature Code")
                    {
                        Caption = 'AI Feature';
                        ToolTip = 'Select the AI feature to test.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            LoadFeatureDescription();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            AITQuerySchema: Record "AIT Query Schema";
                            AITQuerySchemas: Page "AIT Query Schemas";
                        begin
                            AITQuerySchemas.LookupMode := true;
                            if AITQuerySchemas.RunModal() = Action::LookupOK then begin
                                AITQuerySchemas.GetRecord(AITQuerySchema);
                                Rec."Feature Code" := AITQuerySchema."Feature Code";
                                LoadFeatureDescription();
                                Text := Rec."Feature Code";
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                    field(FeatureDescription; FeatureDescription)
                    {
                        Caption = 'Feature Description';
                        ToolTip = 'Specifies the description of the selected AI feature.';
                        Editable = false;
                        ApplicationArea = All;
                    }
                }
            }
            group(Step2DatasetBasics)
            {
                Caption = '';
                Visible = CurrentStep = 2;

                group(Step2Header)
                {
                    Caption = 'Dataset Information';
                    InstructionalText = 'Provide the basic information for your test dataset.';
                }
                group(Step2Content)
                {
                    ShowCaption = false;

                    field(DatasetCode; Rec."Dataset Code")
                    {
                        Caption = 'Dataset Code';
                        ToolTip = 'A unique code for this dataset. Tests in the same dataset are grouped together and exported as one file.';
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field(DatasetDescription; DatasetDescription)
                    {
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of what this dataset tests.';
                        ApplicationArea = All;
                    }
                }
            }
            group(Step3Tests)
            {
                Caption = '';
                Visible = CurrentStep = 3;

                group(Step3Header)
                {
                    Caption = 'Manage Tests';
                    InstructionalText = 'Add tests to this dataset. Each test has its own instructions, setup, and validations. Click "Add Test" to create a new test.';
                }
                group(Step3Content)
                {
                    ShowCaption = false;

                    part(TestLinesPart; "AIT Test Lines")
                    {
                        Caption = 'Tests';
                        ApplicationArea = All;
                        UpdatePropagation = Both;
                    }
                }
                group(Step3Summary)
                {
                    Caption = '';

                    field(TestCountInfo; TestCountInfo)
                    {
                        Caption = 'Test Count';
                        ToolTip = 'Specifies the number of tests in this dataset.';
                        Editable = false;
                        ApplicationArea = All;
                        StyleExpr = TestCountStyle;
                    }
                }
            }
            group(Step4Review)
            {
                Caption = '';
                Visible = CurrentStep = 4;

                group(Step4Header)
                {
                    Caption = 'Review and Export';
                    InstructionalText = 'Review the dataset configuration and export it to the test framework.';
                }
                group(Step4Summary)
                {
                    Caption = 'Dataset Summary';

                    field(SummaryFeature; Rec."Feature Code")
                    {
                        Caption = 'Feature';
                        Editable = false;
                        ApplicationArea = All;
                    }
                    field(SummaryDataset; Rec."Dataset Code")
                    {
                        Caption = 'Dataset Code';
                        Editable = false;
                        ApplicationArea = All;
                    }
                    field(SummaryTestCount; TestCount)
                    {
                        Caption = 'Number of Tests';
                        ToolTip = 'Specifies the number of tests in this dataset.';
                        Editable = false;
                        ApplicationArea = All;
                    }
                }
                group(Step4JsonPreview)
                {
                    Caption = 'Generated Dataset (JSON)';

                    field(JsonPreview; JsonPreview)
                    {
                        Caption = 'JSON Preview';
                        ToolTip = 'Specifies a preview of the generated test dataset JSON.';
                        MultiLine = true;
                        Editable = false;
                        ApplicationArea = All;
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                ToolTip = 'Go to the previous step.';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = CurrentStep > 1;

                trigger OnAction()
                begin
                    CurrentStep -= 1;
                    UpdateControls();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ToolTip = 'Go to the next step.';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = CurrentStep < 4;

                trigger OnAction()
                begin
                    ValidateCurrentStep();
                    CurrentStep += 1;
                    UpdateControls();
                end;
            }
            action(Finish)
            {
                Caption = 'Export Dataset';
                ToolTip = 'Export the dataset to the test framework.';
                Image = Export;
                InFooterBar = true;
                Visible = CurrentStep = 4;

                trigger OnAction()
                begin
                    ExportDataset();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentStep := 1;
        Rec.Init();
        Rec."Dataset Code" := 'NEW-DATASET';
        Rec.Insert(false);
        UpdateControls();
    end;

    procedure SetFeature(NewFeatureCode: Code[50])
    begin
        Rec."Feature Code" := NewFeatureCode;
        LoadFeatureDescription();
    end;

    local procedure LoadFeatureDescription()
    var
        AITQuerySchema: Record "AIT Query Schema";
    begin
        if AITQuerySchema.Get(Rec."Feature Code") then
            FeatureDescription := AITQuerySchema.Description
        else
            FeatureDescription := '';
    end;

    local procedure ValidateCurrentStep()
    begin
        case CurrentStep of
            1:
                if Rec."Feature Code" = '' then
                    Error('Please select an AI feature.');
            2:
                if Rec."Dataset Code" = '' then
                    Error('Please enter a dataset code.');
            3:
                begin
                    UpdateTestCount();
                    if TestCount = 0 then
                        Error('Please add at least one test to the dataset.');
                end;
        end;
    end;

    local procedure UpdateControls()
    begin
        case CurrentStep of
            3:
                begin
                    EnsureDatasetRecordExists();
                    CurrPage.TestLinesPart.Page.SetDatasetContext(Rec."Dataset Code", Rec."Feature Code");
                    UpdateTestCount();
                end;
            4:
                begin
                    UpdateTestCount();
                    BuildJsonPreview();
                end;
        end;
    end;

    local procedure EnsureDatasetRecordExists()
    var
        AITTestInput: Record "AIT Test Input";
    begin
        if not AITTestInput.Get(Rec."Dataset Code", '') then begin
            // Create the dataset header record
            AITTestInput.Init();
            AITTestInput."Dataset Code" := Rec."Dataset Code";
            AITTestInput."Test Name" := ''; // Empty test name indicates header
            AITTestInput.Description := DatasetDescription;
            AITTestInput."Feature Code" := Rec."Feature Code";
            AITTestInput.Insert(true);
        end else begin
            AITTestInput.Description := DatasetDescription;
            AITTestInput."Feature Code" := Rec."Feature Code";
            AITTestInput.Modify(true);
        end;
    end;

    local procedure UpdateTestCount()
    var
        AITTestInputLine: Record "AIT Test Input Line";
    begin
        AITTestInputLine.SetRange("Dataset Code", Rec."Dataset Code");
        TestCount := AITTestInputLine.Count;

        if TestCount = 0 then begin
            TestCountInfo := 'No tests added yet. Click "Add Test" to create your first test.';
            TestCountStyle := 'Attention';
        end else begin
            TestCountInfo := StrSubstNo(TestCountLbl, TestCount);
            TestCountStyle := 'Favorable';
        end;
    end;

    local procedure BuildJsonPreview()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
        DatasetJson: JsonObject;
        JsonText: Text;
    begin
        DatasetJson := AITNoCodeMgt.BuildDatasetJson(Rec."Dataset Code");
        DatasetJson.WriteTo(JsonText);
        JsonPreview := JsonText;
    end;

    local procedure ExportDataset()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
    begin
        AITNoCodeMgt.ExportDatasetToTestInput(Rec."Dataset Code");
        Message('Dataset "%1" with %2 test(s) has been exported successfully.', Rec."Dataset Code", TestCount);
    end;

    var
        CurrentStep: Integer;
        FeatureDescription: Text[250];
        DatasetDescription: Text[250];
        TestCount: Integer;
        TestCountInfo: Text;
        TestCountStyle: Text;
        JsonPreview: Text;
        TestCountLbl: Label '%1 test(s) in this dataset', Comment = '%1 = number of tests';
}
