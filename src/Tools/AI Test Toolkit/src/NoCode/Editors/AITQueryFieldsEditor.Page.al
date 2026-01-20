// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Dynamic query field editor that renders fields based on schema.
/// Used by the No-Code wizard to edit feature-specific query fields.
/// </summary>
page 149067 "AIT Query Fields Editor"
{
    Caption = 'Query Fields';
    PageType = ListPart;
    SourceTable = "AIT Query Schema Field";
    SourceTableTemporary = true;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Fields)
            {
                field("Field Label"; Rec."Field Label")
                {
                    Caption = 'Field';
                    ToolTip = 'Specifies the name of the query field.';
                    Editable = false;
                    StyleExpr = FieldStyle;
                    ApplicationArea = All;
                }
                field(FieldTypeDisplay; FieldTypeDisplay)
                {
                    Caption = 'Type';
                    ToolTip = 'Specifies the data type of the field.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(ValueDisplay; ValueDisplay)
                {
                    Caption = 'Value';
                    ToolTip = 'Specifies the value. Click to edit.';
                    ApplicationArea = All;
                    StyleExpr = ValueStyle;

                    trigger OnValidate()
                    begin
                        SetValueFromDisplay();
                        Rec.Modify();
                        UpdateDisplayValues();
                    end;

                    trigger OnAssistEdit()
                    begin
                        EditValue();
                    end;
                }
                field(Required; RequiredText)
                {
                    Caption = 'Required';
                    ToolTip = 'Specifies whether this field is required.';
                    Editable = false;
                    StyleExpr = RequiredStyle;
                    ApplicationArea = All;
                }
                field("Field Description"; Rec."Field Description")
                {
                    Caption = 'Help';
                    ToolTip = 'Specifies what this field is for.';
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayValues();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateDisplayValues();
    end;

    internal procedure SetFields(var SourceFields: Record "AIT Query Schema Field" temporary)
    var
        MultilineText: Text;
        ListArray: JsonArray;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if SourceFields.FindSet() then
            repeat
                Rec := SourceFields;
                Rec.Insert();
                // Copy blob fields explicitly - they are not copied with record assignment
                if SourceFields."Field Type" = SourceFields."Field Type"::MultilineText then begin
                    MultilineText := SourceFields.GetMultilineValue();
                    if MultilineText <> '' then begin
                        Rec.SetMultilineValue(MultilineText);
                        Rec.Modify();
                    end;
                end;
                if SourceFields."Field Type" = SourceFields."Field Type"::FileList then begin
                    ListArray := SourceFields.GetListValue();
                    if ListArray.Count > 0 then begin
                        Rec.SetListValue(ListArray);
                        Rec.Modify();
                    end;
                end;
            until SourceFields.Next() = 0;

        if Rec.FindFirst() then;
    end;

    internal procedure GetFields(var TargetFields: Record "AIT Query Schema Field" temporary)
    var
        MultilineText: Text;
        ListArray: JsonArray;
    begin
        TargetFields.Reset();
        TargetFields.DeleteAll();

        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TargetFields := Rec;
                TargetFields.Insert();
                // Copy blob fields explicitly - they are not copied with record assignment
                if Rec."Field Type" = Rec."Field Type"::MultilineText then begin
                    MultilineText := Rec.GetMultilineValue();
                    if MultilineText <> '' then begin
                        TargetFields.SetMultilineValue(MultilineText);
                        TargetFields.Modify();
                    end;
                end;
                if Rec."Field Type" = Rec."Field Type"::FileList then begin
                    ListArray := Rec.GetListValue();
                    if ListArray.Count > 0 then begin
                        TargetFields.SetListValue(ListArray);
                        TargetFields.Modify();
                    end;
                end;
            until Rec.Next() = 0;
    end;

    local procedure UpdateDisplayValues()
    var
        FileArray: JsonArray;
        FileToken: JsonToken;
        FileList: TextBuilder;
        MultilineText: Text;
    begin
        // Set field style for required fields
        if Rec."Is Required" then begin
            FieldStyle := 'Strong';
            RequiredText := '*';
            RequiredStyle := 'Attention';
        end else begin
            FieldStyle := 'Standard';
            RequiredText := '';
            RequiredStyle := 'Standard';
        end;

        // Set type display
        case Rec."Field Type" of
            Rec."Field Type"::Text:
                FieldTypeDisplay := 'Text';
            Rec."Field Type"::MultilineText:
                FieldTypeDisplay := 'Multiline';
            Rec."Field Type"::Boolean:
                FieldTypeDisplay := 'Yes/No';
            Rec."Field Type"::Integer:
                FieldTypeDisplay := 'Integer';
            Rec."Field Type"::FileList:
                FieldTypeDisplay := 'Files';
            Rec."Field Type"::JsonObject:
                FieldTypeDisplay := 'JSON';
        end;

        // Set value display and style based on field type
        ValueStyle := 'Standard';
        case Rec."Field Type" of
            Rec."Field Type"::Text:
                ValueDisplay := Rec."Text Value";
            Rec."Field Type"::MultilineText:
                begin
                    MultilineText := Rec.GetMultilineValue();
                    if MultilineText = '' then begin
                        ValueDisplay := '(click to edit)';
                        ValueStyle := 'Subordinate';
                    end else begin
                        ValueDisplay := CopyStr(MultilineText, 1, 100);
                        if StrLen(MultilineText) > 100 then
                            ValueDisplay += '...';
                    end;
                end;
            Rec."Field Type"::Boolean:
                if Rec."Boolean Value" then
                    ValueDisplay := 'Yes'
                else
                    ValueDisplay := 'No';
            Rec."Field Type"::Integer:
                ValueDisplay := Format(Rec."Integer Value");
            Rec."Field Type"::FileList:
                begin
                    FileArray := Rec.GetListValue();
                    if FileArray.Count = 0 then begin
                        ValueDisplay := '(click to add files)';
                        ValueStyle := 'Subordinate';
                    end else begin
                        foreach FileToken in FileArray do begin
                            if FileList.Length > 0 then
                                FileList.Append(', ');
                            FileList.Append(FileToken.AsValue().AsText());
                        end;
                        ValueDisplay := CopyStr(FileList.ToText(), 1, 100);
                        if StrLen(FileList.ToText()) > 100 then
                            ValueDisplay += '...';
                    end;
                end;
        end;
    end;

    local procedure SetValueFromDisplay()
    var
        IntVal: Integer;
    begin
        // Handle inline editing for simple types
        case Rec."Field Type" of
            Rec."Field Type"::Text:
                Rec."Text Value" := CopyStr(ValueDisplay, 1, MaxStrLen(Rec."Text Value"));
            Rec."Field Type"::Boolean:
                Rec."Boolean Value" := (LowerCase(ValueDisplay) in ['yes', 'true', '1']);
            Rec."Field Type"::Integer:
                if Evaluate(IntVal, ValueDisplay) then
                    Rec."Integer Value" := IntVal;
        // MultilineText and FileList require AssistEdit
        end;
    end;

    local procedure EditValue()
    var
        MultilineEditor: Page "AIT Multiline Editor";
        FileListEditor: Page "AIT File List Editor";
        BooleanOptions: Text;
        SelectedOption: Integer;
        FileArray: JsonArray;
        CurrentValue: Text;
        NewValue: Text;
    begin
        case Rec."Field Type" of
            Rec."Field Type"::MultilineText:
                begin
                    CurrentValue := Rec.GetMultilineValue();
                    MultilineEditor.SetContent(CurrentValue, Rec."Field Label");
                    if MultilineEditor.RunModal() = Action::OK then begin
                        NewValue := MultilineEditor.GetContent();
                        Rec.SetMultilineValue(NewValue);
                        Rec.Modify();
                    end;
                end;
            Rec."Field Type"::Boolean:
                begin
                    BooleanOptions := 'No,Yes';
                    if Rec."Boolean Value" then
                        SelectedOption := 2
                    else
                        SelectedOption := 1;
                    if StrMenu(BooleanOptions, SelectedOption, 'Select value for ' + Rec."Field Label") > 0 then begin
                        Rec."Boolean Value" := (SelectedOption = 2);
                        Rec.Modify();
                    end;
                end;
            Rec."Field Type"::FileList:
                begin
                    FileArray := Rec.GetListValue();
                    FileListEditor.SetFiles(FileArray);
                    if FileListEditor.RunModal() = Action::OK then begin
                        FileArray := FileListEditor.GetFiles();
                        Rec.SetListValue(FileArray);
                        Rec.Modify();
                    end;
                end;
        end;
        UpdateDisplayValues();
    end;

    var
        FieldStyle: Text;
        RequiredText: Text[1];
        RequiredStyle: Text;
        FieldTypeDisplay: Text[20];
        ValueDisplay: Text;
        ValueStyle: Text;
}