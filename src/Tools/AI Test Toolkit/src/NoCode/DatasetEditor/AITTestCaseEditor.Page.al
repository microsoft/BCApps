// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Modal editor for a single test case.
/// Provides structured editing for query (instructions, message) and validations.
/// </summary>
page 149085 "AIT Test Case Editor"
{
    Caption = 'Test Case Editor';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "AIT Test Input Line";
    Extensible = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Test Case';

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
                    ToolTip = 'Specifies the test setup file reference (e.g., RUNTIME-CHALLENGE-setup.yml).';
                    ApplicationArea = All;
                }
            }
            group(QueryGroup)
            {
                Caption = 'Query';

                field(Instructions; Instructions)
                {
                    Caption = 'Instructions';
                    ToolTip = 'Specifies the agent instructions for this test.';
                    ApplicationArea = All;
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        UpdateQueryJson();
                    end;
                }
                field(Message; UserMessage)
                {
                    Caption = 'Message';
                    ToolTip = 'Specifies the incoming user message (for message-based tests).';
                    ApplicationArea = All;
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        UpdateQueryJson();
                    end;
                }
                field(AttachmentFiles; AttachmentFilesText)
                {
                    Caption = 'Attachment Files';
                    ToolTip = 'Specifies attachment file names (comma-separated).';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateQueryJson();
                    end;
                }
                field(ExpectAnnotations; ExpectAnnotations)
                {
                    Caption = 'Expect Annotations';
                    ToolTip = 'Specifies whether to expect annotation warnings in the response.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateQueryJson();
                    end;
                }
            }
            group(ValidationGroup)
            {
                Caption = 'Validations';

                part(ValidationsPart; "AIT Test Case Validations")
                {
                    Caption = 'Validation Entries';
                    ApplicationArea = All;
                }
            }
            group(RawJsonGroup)
            {
                Caption = 'Raw JSON';
                Visible = ShowRawJson;

                field(QueryJsonText; QueryJsonText)
                {
                    Caption = 'Query JSON';
                    ToolTip = 'Specifies the raw query JSON.';
                    ApplicationArea = All;
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        ParseQueryJson();
                    end;
                }
                field(ExpectedDataJsonText; ExpectedDataJsonText)
                {
                    Caption = 'Expected Data JSON';
                    ToolTip = 'Specifies the raw expected data JSON.';
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ToggleRawJson)
            {
                Caption = 'Toggle Raw JSON';
                ToolTip = 'Show/hide raw JSON fields for advanced editing.';
                Image = ViewDetails;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ShowRawJson := not ShowRawJson;
                    if ShowRawJson then
                        UpdateJsonDisplay();
                end;
            }
            action(AddValidation)
            {
                Caption = 'Add Validation';
                ToolTip = 'Add a new validation entry.';
                Image = Add;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.ValidationsPart.Page.AddNewValidation();
                end;
            }
        }
        area(Promoted)
        {
            actionref(AddValidation_Promoted; AddValidation)
            {
            }
            actionref(ToggleRawJson_Promoted; ToggleRawJson)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadFromRecord();
        CurrPage.ValidationsPart.Page.SetTempRecords(TempAITValidationEntry, Rec."Dataset Code", Rec."Line No.");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            SaveToRecord();
            CurrPage.ValidationsPart.Page.GetTempRecords(TempAITValidationEntry);
        end;
        exit(true);
    end;

    local procedure LoadFromRecord()
    var
        QueryJson: JsonObject;
        Token: JsonToken;
        FilesArray: JsonArray;
        FileToken: JsonToken;
        FileText: TextBuilder;
    begin
        QueryJson := Rec.GetQueryJson();

        // Load instructions
        if QueryJson.Get('instructions', Token) then
            if Token.IsValue() then
                Instructions := Token.AsValue().AsText();

        // Load message
        if QueryJson.Get('message', Token) then
            if Token.IsValue() then
                UserMessage := Token.AsValue().AsText();

        // Load attachment_files
        if QueryJson.Get('attachment_files', Token) then
            if Token.IsArray() then begin
                FilesArray := Token.AsArray();
                foreach FileToken in FilesArray do begin
                    if FileText.Length > 0 then
                        FileText.Append(', ');
                    FileText.Append(FileToken.AsValue().AsText());
                end;
                AttachmentFilesText := FileText.ToText();
            end;

        // Load expect_annotations
        if QueryJson.Get('expect_annotations', Token) then
            if Token.IsValue() then
                ExpectAnnotations := Token.AsValue().AsBoolean();

        if ShowRawJson then
            UpdateJsonDisplay();
    end;

    local procedure SaveToRecord()
    begin
        UpdateQueryJson();
        BuildExpectedDataFromValidations();
    end;

    local procedure UpdateQueryJson()
    var
        QueryJson: JsonObject;
        FilesArray: JsonArray;
        FileName: Text;
        FileNames: List of [Text];
    begin
        if Instructions <> '' then
            QueryJson.Add('instructions', Instructions);

        if UserMessage <> '' then
            QueryJson.Add('message', UserMessage);

        if AttachmentFilesText <> '' then begin
            FileNames := AttachmentFilesText.Split(',');
            foreach FileName in FileNames do begin
                FileName := FileName.Trim();
                if FileName <> '' then
                    FilesArray.Add(FileName);
            end;
            if FilesArray.Count > 0 then
                QueryJson.Add('attachment_files', FilesArray);
        end;

        if ExpectAnnotations then
            QueryJson.Add('expect_annotations', true);

        Rec.SetQueryJson(QueryJson);
        Rec.Modify();

        if ShowRawJson then
            UpdateJsonDisplay();
    end;

    local procedure ParseQueryJson()
    var
        QueryJson: JsonObject;
    begin
        if QueryJsonText = '' then
            exit;

        if not QueryJson.ReadFrom(QueryJsonText) then begin
            Message(InvalidJsonMsg);
            exit;
        end;

        Rec.SetQueryJson(QueryJson);
        Rec.Modify();
        LoadFromRecord();
    end;

    local procedure BuildExpectedDataFromValidations()
    var
        TempValidation: Record "AIT Validation Entry" temporary;
        ExpectedDataJson: JsonObject;
    begin
        CurrPage.ValidationsPart.Page.GetTempRecords(TempAITValidationEntry);

        TempValidation.Copy(TempAITValidationEntry, true);
        TempValidation.SetRange("Dataset Code", Rec."Dataset Code");
        TempValidation.SetRange("Line No.", Rec."Line No.");

        if TempValidation.FindSet() then
            repeat
                TempValidation.BuildValidationJson(ExpectedDataJson);
            until TempValidation.Next() = 0;

        Rec.SetExpectedDataJson(ExpectedDataJson);
        Rec.Modify();
    end;

    local procedure UpdateJsonDisplay()
    var
        QueryJson: JsonObject;
        ExpectedDataJson: JsonObject;
    begin
        QueryJson := Rec.GetQueryJson();
        QueryJson.WriteTo(QueryJsonText);

        ExpectedDataJson := Rec.GetExpectedDataJson();
        ExpectedDataJson.WriteTo(ExpectedDataJsonText);
    end;

    internal procedure SetTempRecords(var SourceLine: Record "AIT Test Input Line" temporary; var SourceValidations: Record "AIT Validation Entry" temporary; IsNewRecord: Boolean)
    begin
        // Copy the line
        Rec := SourceLine;
        if not Rec.Insert() then
            Rec.Modify();

        // Copy validations for this line
        TempAITValidationEntry.Reset();
        TempAITValidationEntry.DeleteAll();
        SourceValidations.Reset();
        if SourceValidations.FindSet() then
            repeat
                if (SourceValidations."Dataset Code" = Rec."Dataset Code") and
                   (SourceValidations."Line No." = Rec."Line No.") then begin
                    TempAITValidationEntry := SourceValidations;
                    TempAITValidationEntry.Insert();
                end;
            until SourceValidations.Next() = 0;
    end;

    internal procedure GetTempRecords(var DestLine: Record "AIT Test Input Line" temporary; var DestValidations: Record "AIT Validation Entry" temporary)
    begin
        // Update the line
        if DestLine.Get(Rec."Dataset Code", Rec."Line No.") then begin
            DestLine := Rec;
            DestLine.Modify();
        end else begin
            DestLine := Rec;
            DestLine.Insert();
        end;

        // Remove old validations for this line
        DestValidations.SetRange("Dataset Code", Rec."Dataset Code");
        DestValidations.SetRange("Line No.", Rec."Line No.");
        DestValidations.DeleteAll();
        DestValidations.Reset();

        // Copy current validations
        TempAITValidationEntry.Reset();
        if TempAITValidationEntry.FindSet() then
            repeat
                if (TempAITValidationEntry."Dataset Code" = Rec."Dataset Code") and
                   (TempAITValidationEntry."Line No." = Rec."Line No.") then begin
                    DestValidations := TempAITValidationEntry;
                    DestValidations.Insert();
                end;
            until TempAITValidationEntry.Next() = 0;
    end;

    var
        TempAITValidationEntry: Record "AIT Validation Entry" temporary;
        Instructions: Text;
        UserMessage: Text;
        AttachmentFilesText: Text;
        ExpectAnnotations: Boolean;
        QueryJsonText: Text;
        ExpectedDataJsonText: Text;
        ShowRawJson: Boolean;
        InvalidJsonMsg: Label 'Invalid JSON format.';
}
