// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// List part for editing validation entries for a test line.
/// Supports multiple validations of different types per test.
/// </summary>
page 149080 "AIT Validations Editor"
{
    Caption = 'Validations';
    PageType = ListPart;
    SourceTable = "AIT Validation Entry";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Validations)
            {
                field("Validation Type"; Rec."Validation Type")
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of validation to perform.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateFieldVisibility();
                        CurrPage.Update(false);
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    Caption = 'Table';
                    ToolTip = 'Specifies the table to validate records in.';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Expected Count"; Rec."Expected Count")
                {
                    Caption = 'Count';
                    ToolTip = 'Specifies the expected number of records.';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Name Prefix"; Rec."Name Prefix")
                {
                    Caption = 'Name Prefix';
                    ToolTip = 'Specifies the name prefix to filter records.';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Primary Name Field"; Rec."Primary Name Field")
                {
                    Caption = 'Name Field';
                    ToolTip = 'Specifies the primary name field if not "Name".';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Intervention Type"; Rec."Intervention Type")
                {
                    Caption = 'Intervention';
                    ToolTip = 'Specifies the expected intervention request type.';
                    ApplicationArea = All;
                    Visible = ShowInterventionField;
                }
                field(PromptPreview; PromptPreview)
                {
                    Caption = 'Prompt';
                    ToolTip = 'Specifies the validation prompt. Click to edit.';
                    Editable = false;
                    ApplicationArea = All;
                    Visible = ShowPromptField;
                    StyleExpr = PromptStyle;

                    trigger OnAssistEdit()
                    begin
                        EditValidationPrompt();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddValidation)
            {
                Caption = 'Add Validation';
                ToolTip = 'Add a new validation entry.';
                Image = Add;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddNewValidation();
                end;
            }
            action(EditPrompt)
            {
                Caption = 'Edit Prompt';
                ToolTip = 'Edit the validation prompt for this entry.';
                Image = Edit;
                Scope = Repeater;
                ApplicationArea = All;
                Visible = Rec."Validation Type" = Rec."Validation Type"::ValidationPrompt;

                trigger OnAction()
                begin
                    EditValidationPrompt();
                end;
            }
            action(EditFields)
            {
                Caption = 'Edit Field Validations';
                ToolTip = 'Edit additional field validations for database records.';
                Image = EditLines;
                Scope = Repeater;
                ApplicationArea = All;
                Visible = Rec."Validation Type" = Rec."Validation Type"::DatabaseRecords;

                trigger OnAction()
                begin
                    EditFieldValidations();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayValues();
        UpdateFieldVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayValues();
        UpdateFieldVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Dataset Code" := DatasetCode;
        Rec."Line No." := LineNo;
        Rec."Entry No." := Rec.GetNextEntryNo(DatasetCode, LineNo);
    end;

    var
        DatasetCode: Code[100];
        LineNo: Integer;
        PromptPreview: Text;
        PromptStyle: Text;
        ShowTableFields: Boolean;
        ShowPromptField: Boolean;
        ShowInterventionField: Boolean;

    internal procedure SetContext(NewDatasetCode: Code[100]; NewLineNo: Integer)
    begin
        DatasetCode := NewDatasetCode;
        LineNo := NewLineNo;
        Rec.SetRange("Dataset Code", DatasetCode);
        Rec.SetRange("Line No.", LineNo);
        CurrPage.Update(false);
    end;

    internal procedure GetValidationCount(): Integer
    begin
        Rec.SetRange("Dataset Code", DatasetCode);
        Rec.SetRange("Line No.", LineNo);
        exit(Rec.Count);
    end;

    local procedure UpdateDisplayValues()
    var
        PromptText: Text;
    begin
        PromptText := Rec.GetValidationPrompt();
        if PromptText = '' then begin
            PromptPreview := '(click to edit)';
            PromptStyle := 'Subordinate';
        end else begin
            PromptPreview := CopyStr(PromptText, 1, 100);
            if StrLen(PromptText) > 100 then
                PromptPreview += '...';
            PromptStyle := 'Standard';
        end;
    end;

    local procedure UpdateFieldVisibility()
    begin
        ShowTableFields := Rec."Validation Type" in [Rec."Validation Type"::DatabaseRecords, Rec."Validation Type"::MessageContent];
        ShowPromptField := Rec."Validation Type" = Rec."Validation Type"::ValidationPrompt;
        ShowInterventionField := Rec."Validation Type" = Rec."Validation Type"::InterventionRequest;
    end;

    local procedure AddNewValidation()
    var
        NewEntry: Record "AIT Validation Entry";
    begin
        NewEntry.Init();
        NewEntry."Dataset Code" := DatasetCode;
        NewEntry."Line No." := LineNo;
        NewEntry."Entry No." := NewEntry.GetNextEntryNo(DatasetCode, LineNo);
        NewEntry."Validation Type" := NewEntry."Validation Type"::DatabaseRecords;
        NewEntry.Insert(true);
        CurrPage.Update(false);
    end;

    local procedure EditValidationPrompt()
    var
        MultilineEditor: Page "AIT Multiline Editor";
        CurrentPrompt: Text;
        NewPrompt: Text;
    begin
        CurrentPrompt := Rec.GetValidationPrompt();
        MultilineEditor.SetContent(CurrentPrompt, 'Validation Prompt');
        if MultilineEditor.RunModal() = Action::OK then begin
            NewPrompt := MultilineEditor.GetContent();
            Rec.SetValidationPrompt(NewPrompt);
            Rec.Modify(true);
            UpdateDisplayValues();
            CurrPage.Update(false);
        end;
    end;

    local procedure EditFieldValidations()
    var
        JsonEditor: Page "AIT JSON Editor";
        FieldsArray: JsonArray;
        FieldsText: Text;
        NewFieldsText: Text;
    begin
        FieldsArray := Rec.GetFieldValidations();
        FieldsArray.WriteTo(FieldsText);
        if FieldsText = '[]' then
            FieldsText := '[{"name": "Field Name", "value": "Expected Value"}]';

        JsonEditor.SetJsonContent(FieldsText);
        if JsonEditor.RunModal() = Action::OK then begin
            NewFieldsText := JsonEditor.GetJsonContent();
            if FieldsArray.ReadFrom(NewFieldsText) then begin
                Rec.SetFieldValidations(FieldsArray);
                Rec.Modify(true);
            end else
                Error('Invalid JSON format. Expected an array of field validations.');
        end;
    end;
}
