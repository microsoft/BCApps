// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Modal page for editing a single test line within a dataset.
/// Used by the Test Lines page to add or edit tests.
/// </summary>
page 149081 "AIT Test Line Editor"
{
    Caption = 'Edit Test';
    PageType = Card;
    SourceTable = "AIT Test Input Line";
    DataCaptionExpression = Rec."Test Name";

    layout
    {
        area(Content)
        {
            group(TestBasics)
            {
                Caption = 'Test Details';

                field("Test Name"; Rec."Test Name")
                {
                    Caption = 'Test Name';
                    ToolTip = 'Specifies the unique name for this test case.';
                    ApplicationArea = All;
                    ShowMandatory = true;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of what this test validates.';
                    ApplicationArea = All;
                }
                field("Test Setup Reference"; Rec."Test Setup Reference")
                {
                    Caption = 'Test Setup File';
                    ToolTip = 'Specifies the test setup file reference (e.g., RUNTIME-CHALLENGE-LISTS-20-setup.yml).';
                    ApplicationArea = All;
                }
            }
            group(QueryGroup)
            {
                Caption = 'Query Configuration';

                part(QueryFieldsEditor; "AIT Query Fields Editor")
                {
                    Caption = 'Query Fields';
                    ApplicationArea = All;
                    UpdatePropagation = Both;
                }
            }
            group(ValidationGroup)
            {
                Caption = 'Validations';

                part(ValidationsEditor; "AIT Validations Editor")
                {
                    Caption = 'Validation Entries';
                    ApplicationArea = All;
                    UpdatePropagation = Both;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OK)
            {
                Caption = 'OK';
                ToolTip = 'Save the test and close.';
                Image = Approve;
                InFooterBar = true;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    SaveTest();
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Close without saving.';
                Image = Cancel;
                InFooterBar = true;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if IsNewTest then begin
            Rec.Init();
            Rec."Dataset Code" := DatasetCode;
            Rec."Line No." := LineNo;
            Rec.Insert(true);
        end;

        LoadQuerySchema();
        CurrPage.ValidationsEditor.Page.SetContext(Rec."Dataset Code", Rec."Line No.");
    end;

    var
        TempQuerySchemaField: Record "AIT Query Schema Field" temporary;
        DatasetCode: Code[100];
        FeatureCode: Code[50];
        LineNo: Integer;
        IsNewTest: Boolean;

    internal procedure SetContext(NewDatasetCode: Code[100]; NewFeatureCode: Code[50]; NewLineNo: Integer; NewTest: Boolean)
    begin
        DatasetCode := NewDatasetCode;
        FeatureCode := NewFeatureCode;
        LineNo := NewLineNo;
        IsNewTest := NewTest;
    end;

    local procedure LoadQuerySchema()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
        QueryJson: JsonObject;
    begin
        // Load schema fields for this feature
        AITNoCodeMgt.LoadQuerySchemaFields(FeatureCode, TempQuerySchemaField);

        // If editing existing test, populate fields from stored query
        if not IsNewTest then begin
            QueryJson := Rec.GetQueryJson();
            if QueryJson.Keys.Count > 0 then
                AITNoCodeMgt.PopulateFieldsFromQueryJson(QueryJson, TempQuerySchemaField);
        end;

        CurrPage.QueryFieldsEditor.Page.SetFields(TempQuerySchemaField);
    end;

    local procedure SaveTest()
    var
        AITValidationEntry: Record "AIT Validation Entry";
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
        ErrorMessage: Text;
    begin
        // Validate required fields
        if Rec."Test Name" = '' then
            Error('Please enter a test name.');

        // Get query fields from editor and validate
        CurrPage.QueryFieldsEditor.Page.GetFields(TempQuerySchemaField);
        if not AITNoCodeMgt.ValidateRequiredFields(TempQuerySchemaField, ErrorMessage) then
            Error(ErrorMessage);

        // Build and save query JSON
        QueryJson := AITNoCodeMgt.BuildQueryJsonFromFields(TempQuerySchemaField);
        Rec.SetQueryJson(QueryJson);

        // Build expected_data JSON from validation entries
        AITValidationEntry.SetRange("Dataset Code", Rec."Dataset Code");
        AITValidationEntry.SetRange("Line No.", Rec."Line No.");
        if AITValidationEntry.FindSet() then
            repeat
                AITValidationEntry.BuildValidationJson(ExpectedDataJson);
            until AITValidationEntry.Next() = 0;

        Rec.SetExpectedDataJson(ExpectedDataJson);
        Rec.Modify(true);
    end;
}
