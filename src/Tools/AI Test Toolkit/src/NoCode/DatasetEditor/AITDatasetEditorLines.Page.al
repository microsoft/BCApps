// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// ListPart for displaying test cases in the Dataset Editor.
/// Works with temporary records for editing.
/// </summary>
page 149084 "AIT Dataset Editor Lines"
{
    Caption = 'Test Cases';
    PageType = ListPart;
    SourceTable = "AIT Test Input Line";
    AutoSplitKey = true;
    Extensible = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(TestLines)
            {
                field("Line No."; Rec."Line No.")
                {
                    Caption = 'No.';
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Test Name"; Rec."Test Name")
                {
                    Caption = 'Test Name';
                    ToolTip = 'Specifies the unique name for this test case.';
                    ApplicationArea = All;
                    StyleExpr = NameStyle;

                    trigger OnValidate()
                    begin
                        NotifyParentOfChange();
                    end;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of what this test validates.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        NotifyParentOfChange();
                    end;
                }
                field("Test Setup Reference"; Rec."Test Setup Reference")
                {
                    Caption = 'Test Setup';
                    ToolTip = 'Specifies the test setup file reference (e.g., RUNTIME-CHALLENGE-setup.yml).';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        NotifyParentOfChange();
                    end;
                }
                field(QuerySummary; QuerySummary)
                {
                    Caption = 'Query';
                    ToolTip = 'Specifies a summary of the query configuration.';
                    Editable = false;
                    ApplicationArea = All;
                    StyleExpr = QueryStyle;
                }
                field(ValidationSummary; ValidationSummary)
                {
                    Caption = 'Validations';
                    ToolTip = 'Specifies the validation types configured for this test.';
                    Editable = false;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditTest)
            {
                Caption = 'Edit Test';
                ToolTip = 'Edit the selected test case.';
                Image = Edit;
                Scope = Repeater;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    EditCurrentTest();
                end;
            }
            action(DuplicateTest)
            {
                Caption = 'Duplicate';
                ToolTip = 'Create a copy of the selected test.';
                Image = Copy;
                Scope = Repeater;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    DuplicateCurrentTest();
                end;
            }
            action(DeleteTest)
            {
                Caption = 'Delete';
                ToolTip = 'Delete the selected test.';
                Image = Delete;
                Scope = Repeater;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    if Confirm(DeleteTestQst) then begin
                        DeleteValidationsForLine(Rec."Dataset Code", Rec."Line No.");
                        Rec.Delete();
                        NotifyParentOfChange();
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateDisplayFields();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Dataset Code" := DatasetCode;
        QuerySummary := '';
        ValidationSummary := '';
        NameStyle := 'Attention';
        QueryStyle := 'Subordinate';
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Dataset Code" := DatasetCode;
        NotifyParentOfChange();
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        NotifyParentOfChange();
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        DeleteValidationsForLine(Rec."Dataset Code", Rec."Line No.");
        NotifyParentOfChange();
        exit(true);
    end;

    local procedure UpdateDisplayFields()
    var
        QueryJson: JsonObject;
        Instructions: Text;
    begin
        // Query summary
        QueryJson := Rec.GetQueryJson();
        Instructions := GetJsonText(QueryJson, 'instructions');
        if Instructions <> '' then begin
            if StrLen(Instructions) > 50 then
                QuerySummary := CopyStr(Instructions, 1, 47) + '...'
            else
                QuerySummary := Instructions;
            QueryStyle := 'Standard';
        end else begin
            QuerySummary := '(no instructions)';
            QueryStyle := 'Subordinate';
        end;

        // Validation summary
        ValidationSummary := GetValidationSummary();

        // Name style
        if Rec."Test Name" = '' then
            NameStyle := 'Attention'
        else
            NameStyle := 'Strong';
    end;

    local procedure GetValidationSummary(): Text
    var
        TempValidation: Record "AIT Validation Entry" temporary;
        Summary: TextBuilder;
    begin
        TempValidation.Copy(TempAITValidationEntry, true);
        TempValidation.SetRange("Dataset Code", Rec."Dataset Code");
        TempValidation.SetRange("Line No.", Rec."Line No.");

        if not TempValidation.FindSet() then
            exit('(none)');

        repeat
            if Summary.Length > 0 then
                Summary.Append(', ');
            Summary.Append(TempValidation.GetDisplayText());
        until TempValidation.Next() = 0;

        exit(Summary.ToText());
    end;

    local procedure EditCurrentTest()
    var
        AITTestCaseEditor: Page "AIT Test Case Editor";
    begin
        AITTestCaseEditor.SetTempRecords(Rec, TempAITValidationEntry, false);
        if AITTestCaseEditor.RunModal() = Action::OK then begin
            AITTestCaseEditor.GetTempRecords(Rec, TempAITValidationEntry);
            NotifyParentOfChange();
            CurrPage.Update(false);
        end;
    end;

    local procedure DuplicateCurrentTest()
    var
        TempNewLine: Record "AIT Test Input Line" temporary;
        TempSourceValidation: Record "AIT Validation Entry" temporary;
        TempNewValidation: Record "AIT Validation Entry" temporary;
        NewLineNo: Integer;
        NewEntryNo: Integer;
    begin
        // Find next line number
        TempNewLine.Copy(Rec, true);
        TempNewLine.Reset();
        if TempNewLine.FindLast() then
            NewLineNo := TempNewLine."Line No." + 10000
        else
            NewLineNo := 10000;

        // Copy the test line
        TempNewLine.Init();
        TempNewLine."Dataset Code" := Rec."Dataset Code";
        TempNewLine."Line No." := NewLineNo;
        TempNewLine."Test Name" := CopyStr(Rec."Test Name" + ' (Copy)', 1, MaxStrLen(TempNewLine."Test Name"));
        TempNewLine.Description := Rec.Description;
        TempNewLine."Test Setup Reference" := Rec."Test Setup Reference";
        TempNewLine.SetQueryJson(Rec.GetQueryJson());
        TempNewLine.SetExpectedDataJson(Rec.GetExpectedDataJson());
        TempNewLine.Insert();

        // Copy validations
        TempSourceValidation.Copy(TempAITValidationEntry, true);
        TempSourceValidation.SetRange("Dataset Code", Rec."Dataset Code");
        TempSourceValidation.SetRange("Line No.", Rec."Line No.");
        NewEntryNo := 1;

        if TempSourceValidation.FindSet() then
            repeat
                TempNewValidation.Copy(TempAITValidationEntry, true);
                TempNewValidation.Init();
                TempNewValidation."Dataset Code" := Rec."Dataset Code";
                TempNewValidation."Line No." := NewLineNo;
                TempNewValidation."Entry No." := NewEntryNo;
                TempNewValidation."Validation Type" := TempSourceValidation."Validation Type";
                TempNewValidation."Table Name" := TempSourceValidation."Table Name";
                TempNewValidation."Expected Count" := TempSourceValidation."Expected Count";
                TempNewValidation."Name Prefix" := TempSourceValidation."Name Prefix";
                TempNewValidation."Primary Name Field" := TempSourceValidation."Primary Name Field";
                TempNewValidation."Intervention Type" := TempSourceValidation."Intervention Type";
                TempNewValidation.SetValidationPrompt(TempSourceValidation.GetValidationPrompt());
                TempNewValidation.SetFieldValidations(TempSourceValidation.GetFieldValidations());
                TempNewValidation.Insert();
                NewEntryNo += 1;
            until TempSourceValidation.Next() = 0;

        NotifyParentOfChange();
        CurrPage.Update(false);
    end;

    local procedure DeleteValidationsForLine(ForDatasetCode: Code[100]; ForLineNo: Integer)
    var
        TempValidation: Record "AIT Validation Entry" temporary;
    begin
        TempValidation.Copy(TempAITValidationEntry, true);
        TempValidation.SetRange("Dataset Code", ForDatasetCode);
        TempValidation.SetRange("Line No.", ForLineNo);
        TempValidation.DeleteAll();
    end;

    local procedure NotifyParentOfChange()
    begin
        // The parent page polls for changes via GetTempRecords
        // We mark dirty through Update propagation
    end;

    local procedure GetJsonText(JsonObj: JsonObject; PropertyName: Text): Text
    var
        JsonToken: JsonToken;
    begin
        if JsonObj.Get(PropertyName, JsonToken) then
            if JsonToken.IsValue() then
                exit(JsonToken.AsValue().AsText());
        exit('');
    end;

    internal procedure SetTempRecords(var SourceTestLines: Record "AIT Test Input Line" temporary; var SourceValidations: Record "AIT Validation Entry" temporary; NewDatasetCode: Code[100])
    begin
        DatasetCode := NewDatasetCode;

        // Copy test lines
        Rec.Reset();
        Rec.DeleteAll();
        if SourceTestLines.FindSet() then
            repeat
                if SourceTestLines."Dataset Code" = DatasetCode then begin
                    Rec := SourceTestLines;
                    Rec.Insert();
                end;
            until SourceTestLines.Next() = 0;

        // Copy validations
        TempAITValidationEntry.Reset();
        TempAITValidationEntry.DeleteAll();
        if SourceValidations.FindSet() then
            repeat
                if SourceValidations."Dataset Code" = DatasetCode then begin
                    TempAITValidationEntry := SourceValidations;
                    TempAITValidationEntry.Insert();
                end;
            until SourceValidations.Next() = 0;

        Rec.SetRange("Dataset Code", DatasetCode);
        CurrPage.Update(false);
    end;

    internal procedure GetTempRecords(var DestTestLines: Record "AIT Test Input Line" temporary; var DestValidations: Record "AIT Validation Entry" temporary)
    begin
        // Return all test lines
        DestTestLines.Reset();
        DestTestLines.DeleteAll();
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                DestTestLines := Rec;
                DestTestLines.Insert();
            until Rec.Next() = 0;

        // Return all validations
        DestValidations.Reset();
        DestValidations.DeleteAll();
        TempAITValidationEntry.Reset();
        if TempAITValidationEntry.FindSet() then
            repeat
                DestValidations := TempAITValidationEntry;
                DestValidations.Insert();
            until TempAITValidationEntry.Next() = 0;
    end;

    var
        TempAITValidationEntry: Record "AIT Validation Entry" temporary;
        DatasetCode: Code[100];
        QuerySummary: Text;
        ValidationSummary: Text;
        NameStyle: Text;
        QueryStyle: Text;
        DeleteTestQst: Label 'Delete this test case?';
}
