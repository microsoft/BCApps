// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// List part showing test lines within a dataset.
/// Embedded in the No-Code wizard to manage multiple tests per dataset.
/// </summary>
page 149079 "AIT Test Lines"
{
    Caption = 'Tests in Dataset';
    PageType = ListPart;
    SourceTable = "AIT Test Input Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Tests)
            {
                field("Test Name"; Rec."Test Name")
                {
                    Caption = 'Test Name';
                    ToolTip = 'Specifies the name of this test case.';
                    ApplicationArea = All;
                    StyleExpr = NameStyle;
                }
                field("Test Setup Reference"; Rec."Test Setup Reference")
                {
                    Caption = 'Setup';
                    ToolTip = 'Specifies the test setup file reference.';
                    ApplicationArea = All;
                }
                field(ValidationsDisplay; ValidationsDisplay)
                {
                    Caption = 'Validations';
                    ToolTip = 'Specifies the validations configured for this test.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies what this test validates.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddTest)
            {
                Caption = 'Add Test';
                ToolTip = 'Add a new test to this dataset.';
                Image = Add;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddNewTest();
                end;
            }
            action(EditTest)
            {
                Caption = 'Edit Test';
                ToolTip = 'Edit the selected test.';
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

    var
        DatasetCode: Code[100];
        FeatureCode: Code[50];
        ValidationsDisplay: Text;
        NameStyle: Text;

    internal procedure SetDatasetContext(NewDatasetCode: Code[100]; NewFeatureCode: Code[50])
    begin
        DatasetCode := NewDatasetCode;
        FeatureCode := NewFeatureCode;
        Rec.SetRange("Dataset Code", DatasetCode);
        CurrPage.Update(false);
    end;

    internal procedure GetTestCount(): Integer
    begin
        Rec.SetRange("Dataset Code", DatasetCode);
        exit(Rec.Count);
    end;

    local procedure UpdateDisplayValues()
    var
        AITValidationEntry: Record "AIT Validation Entry";
        ValidationTexts: TextBuilder;
    begin
        // Build validations display
        AITValidationEntry.SetRange("Dataset Code", Rec."Dataset Code");
        AITValidationEntry.SetRange("Line No.", Rec."Line No.");
        if AITValidationEntry.FindSet() then
            repeat
                if ValidationTexts.Length > 0 then
                    ValidationTexts.Append(', ');
                ValidationTexts.Append(AITValidationEntry.GetDisplayText());
            until AITValidationEntry.Next() = 0;

        if ValidationTexts.Length = 0 then
            ValidationsDisplay := '(none)'
        else
            ValidationsDisplay := CopyStr(ValidationTexts.ToText(), 1, 250);

        // Style test name based on completeness
        if Rec."Test Name" = '' then
            NameStyle := 'Attention'
        else
            NameStyle := 'Strong';
    end;

    local procedure AddNewTest()
    var
        AITTestLineEditor: Page "AIT Test Line Editor";
        NewLineNo: Integer;
    begin
        NewLineNo := Rec.GetNextLineNo(DatasetCode);

        AITTestLineEditor.SetContext(DatasetCode, FeatureCode, NewLineNo, true);
        if AITTestLineEditor.RunModal() = Action::OK then
            CurrPage.Update(false);
    end;

    local procedure EditCurrentTest()
    var
        AITTestLineEditor: Page "AIT Test Line Editor";
    begin
        AITTestLineEditor.SetContext(DatasetCode, FeatureCode, Rec."Line No.", false);
        AITTestLineEditor.SetRecord(Rec);
        if AITTestLineEditor.RunModal() = Action::OK then
            CurrPage.Update(false);
    end;

    local procedure DuplicateCurrentTest()
    var
        NewTestLine: Record "AIT Test Input Line";
        AITValidationEntry: Record "AIT Validation Entry";
        NewValidationEntry: Record "AIT Validation Entry";
        NewLineNo: Integer;
        NewEntryNo: Integer;
    begin
        NewLineNo := Rec.GetNextLineNo(DatasetCode);

        // Copy the test line
        NewTestLine.Init();
        NewTestLine."Dataset Code" := Rec."Dataset Code";
        NewTestLine."Line No." := NewLineNo;
        NewTestLine."Test Name" := CopyStr(Rec."Test Name" + ' (Copy)', 1, MaxStrLen(NewTestLine."Test Name"));
        NewTestLine.Description := Rec.Description;
        NewTestLine."Test Setup Reference" := Rec."Test Setup Reference";
        NewTestLine.Insert(true);

        // Copy blob fields
        NewTestLine.SetQueryJson(Rec.GetQueryJson());
        NewTestLine.SetExpectedDataJson(Rec.GetExpectedDataJson());
        NewTestLine.Modify();

        // Copy validation entries
        AITValidationEntry.SetRange("Dataset Code", Rec."Dataset Code");
        AITValidationEntry.SetRange("Line No.", Rec."Line No.");
        if AITValidationEntry.FindSet() then begin
            NewEntryNo := 0;
            repeat
                NewEntryNo += 1;
                NewValidationEntry.Init();
                NewValidationEntry."Dataset Code" := NewTestLine."Dataset Code";
                NewValidationEntry."Line No." := NewTestLine."Line No.";
                NewValidationEntry."Entry No." := NewEntryNo;
                NewValidationEntry."Validation Type" := AITValidationEntry."Validation Type";
                NewValidationEntry."Table Name" := AITValidationEntry."Table Name";
                NewValidationEntry."Expected Count" := AITValidationEntry."Expected Count";
                NewValidationEntry."Name Prefix" := AITValidationEntry."Name Prefix";
                NewValidationEntry."Primary Name Field" := AITValidationEntry."Primary Name Field";
                NewValidationEntry."Intervention Type" := AITValidationEntry."Intervention Type";
                NewValidationEntry.Insert(true);

                // Copy blob fields
                NewValidationEntry.SetValidationPrompt(AITValidationEntry.GetValidationPrompt());
                NewValidationEntry.SetFieldValidations(AITValidationEntry.GetFieldValidations());
                NewValidationEntry.Modify();
            until AITValidationEntry.Next() = 0;
        end;

        CurrPage.Update(false);
        Message('Test duplicated as "%1"', NewTestLine."Test Name");
    end;
}
