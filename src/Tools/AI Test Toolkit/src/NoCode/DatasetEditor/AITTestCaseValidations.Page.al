// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// ListPart for editing validation entries within a test case.
/// Supports the fixed validation structures: validate_records_db, validate_records_msg, validation_prompt, intervention_request_type.
/// </summary>
page 149086 "AIT Test Case Validations"
{
    Caption = 'Validations';
    PageType = ListPart;
    SourceTable = "AIT Validation Entry";
    AutoSplitKey = true;
    Extensible = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Validations)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'No.';
                    ToolTip = 'Specifies the entry number.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Validation Type"; Rec."Validation Type")
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the validation type: Database Records, Message Content, Validation Prompt, or Intervention Request.';
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
                    Caption = 'Expected Count';
                    ToolTip = 'Specifies the expected number of records.';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Name Prefix"; Rec."Name Prefix")
                {
                    Caption = 'Name Prefix';
                    ToolTip = 'Specifies the name prefix filter.';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Primary Name Field"; Rec."Primary Name Field")
                {
                    Caption = 'Primary Name Field';
                    ToolTip = 'Specifies the primary name field if not "Name".';
                    ApplicationArea = All;
                    Visible = ShowTableFields;
                }
                field("Intervention Type"; Rec."Intervention Type")
                {
                    Caption = 'Intervention Type';
                    ToolTip = 'Specifies the expected intervention request type.';
                    ApplicationArea = All;
                    Visible = ShowInterventionField;
                }
                field(PromptPreview; PromptPreview)
                {
                    Caption = 'Prompt';
                    ToolTip = 'Specifies the validation prompt. Click to edit.';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowPromptField;

                    trigger OnAssistEdit()
                    begin
                        EditValidationPrompt();
                    end;
                }
                field(Summary; Rec.GetDisplayText())
                {
                    Caption = 'Summary';
                    ToolTip = 'Specifies a summary of this validation.';
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
            action(AddDbValidation)
            {
                Caption = 'Add Database Validation';
                ToolTip = 'Add a database record validation.';
                Image = Database;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddValidationOfType("AIT Validation Type"::DatabaseRecords);
                end;
            }
            action(AddMsgValidation)
            {
                Caption = 'Add Message Validation';
                ToolTip = 'Add a message content validation.';
                Image = SendMail;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddValidationOfType("AIT Validation Type"::MessageContent);
                end;
            }
            action(AddPromptValidation)
            {
                Caption = 'Add Prompt Validation';
                ToolTip = 'Add a custom LLM validation prompt.';
                Image = Questionaire;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddValidationOfType("AIT Validation Type"::ValidationPrompt);
                end;
            }
            action(AddInterventionValidation)
            {
                Caption = 'Add Intervention Validation';
                ToolTip = 'Add an intervention request type validation.';
                Image = Interaction;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddValidationOfType("AIT Validation Type"::InterventionRequest);
                end;
            }
            action(EditPrompt)
            {
                Caption = 'Edit Prompt';
                ToolTip = 'Edit the validation prompt.';
                Image = Edit;
                Scope = Repeater;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    EditValidationPrompt();
                end;
            }
            action(EditFields)
            {
                Caption = 'Edit Field Validations';
                ToolTip = 'Edit additional field validation criteria.';
                Image = EditLines;
                Scope = Repeater;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    EditFieldValidations();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateFieldVisibility();
        UpdatePromptPreview();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Dataset Code" := DatasetCode;
        Rec."Line No." := LineNo;
        ShowTableFields := true;
        ShowPromptField := false;
        ShowInterventionField := false;
        PromptPreview := '';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Dataset Code" := DatasetCode;
        Rec."Line No." := LineNo;
        exit(true);
    end;

    local procedure UpdateFieldVisibility()
    begin
        ShowTableFields := Rec."Validation Type" in
            ["AIT Validation Type"::DatabaseRecords, "AIT Validation Type"::MessageContent];
        ShowPromptField := Rec."Validation Type" = "AIT Validation Type"::ValidationPrompt;
        ShowInterventionField := Rec."Validation Type" = "AIT Validation Type"::InterventionRequest;
    end;

    local procedure UpdatePromptPreview()
    var
        FullPrompt: Text;
    begin
        if Rec."Validation Type" <> "AIT Validation Type"::ValidationPrompt then begin
            PromptPreview := '';
            exit;
        end;

        FullPrompt := Rec.GetValidationPrompt();
        if StrLen(FullPrompt) > 50 then
            PromptPreview := CopyStr(FullPrompt, 1, 47) + '...'
        else
            PromptPreview := FullPrompt;
    end;

    local procedure AddValidationOfType(ValidationType: Enum "AIT Validation Type")
    var
        NewEntryNo: Integer;
    begin
        Rec.Reset();
        Rec.SetRange("Dataset Code", DatasetCode);
        Rec.SetRange("Line No.", LineNo);
        if Rec.FindLast() then
            NewEntryNo := Rec."Entry No." + 1
        else
            NewEntryNo := 1;

        Rec.Init();
        Rec."Dataset Code" := DatasetCode;
        Rec."Line No." := LineNo;
        Rec."Entry No." := NewEntryNo;
        Rec."Validation Type" := ValidationType;
        Rec.Insert();

        UpdateFieldVisibility();
        CurrPage.Update(false);
    end;

    internal procedure AddNewValidation()
    begin
        AddValidationOfType("AIT Validation Type"::DatabaseRecords);
    end;

    local procedure EditValidationPrompt()
    var
        AITMultilineEditor: Page "AIT Multiline Editor";
        PromptText: Text;
    begin
        PromptText := Rec.GetValidationPrompt();
        AITMultilineEditor.SetContent(PromptText, 'Validation Prompt');
        if AITMultilineEditor.RunModal() = Action::OK then begin
            Rec.SetValidationPrompt(AITMultilineEditor.GetContent());
            Rec.Modify();
            UpdatePromptPreview();
            CurrPage.Update(false);
        end;
    end;

    local procedure EditFieldValidations()
    var
        AITJSONEditor: Page "AIT JSON Editor";
        FieldsJson: JsonArray;
        FieldsText: Text;
    begin
        FieldsJson := Rec.GetFieldValidations();
        FieldsJson.WriteTo(FieldsText);

        AITJSONEditor.SetJsonContent(FieldsText);
        if AITJSONEditor.RunModal() = Action::OK then begin
            FieldsText := AITJSONEditor.GetJsonContent();
            if FieldsText <> '' then
                if FieldsJson.ReadFrom(FieldsText) then begin
                    Rec.SetFieldValidations(FieldsJson);
                    Rec.Modify();
                end;
        end;
    end;

    internal procedure SetTempRecords(var SourceValidations: Record "AIT Validation Entry" temporary; NewDatasetCode: Code[100]; NewLineNo: Integer)
    begin
        DatasetCode := NewDatasetCode;
        LineNo := NewLineNo;

        Rec.Reset();
        Rec.DeleteAll();

        SourceValidations.Reset();
        if SourceValidations.FindSet() then
            repeat
                if (SourceValidations."Dataset Code" = DatasetCode) and
                   (SourceValidations."Line No." = LineNo) then begin
                    Rec := SourceValidations;
                    Rec.Insert();
                end;
            until SourceValidations.Next() = 0;

        Rec.SetRange("Dataset Code", DatasetCode);
        Rec.SetRange("Line No.", LineNo);
        CurrPage.Update(false);
    end;

    internal procedure GetTempRecords(var DestValidations: Record "AIT Validation Entry" temporary)
    begin
        // Remove old validations for this line from destination
        DestValidations.SetRange("Dataset Code", DatasetCode);
        DestValidations.SetRange("Line No.", LineNo);
        DestValidations.DeleteAll();
        DestValidations.Reset();

        // Copy current validations
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                DestValidations := Rec;
                DestValidations.Insert();
            until Rec.Next() = 0;
    end;

    var
        DatasetCode: Code[100];
        LineNo: Integer;
        ShowTableFields: Boolean;
        ShowPromptField: Boolean;
        ShowInterventionField: Boolean;
        PromptPreview: Text;
}
