// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;
using System.Utilities;

/// <summary>
/// Generic Dataset Editor for editing Test Input datasets.
/// Loads Test Input records into temporary tables for editing, then saves back.
/// </summary>
page 149083 "AIT Dataset Editor"
{
    Caption = 'Dataset Editor';
    PageType = Document;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Test Input Group";
    DataCaptionExpression = Rec.Code + ' - ' + Rec.Description;
    Extensible = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Dataset';

                field(DatasetCode; Rec.Code)
                {
                    Caption = 'Dataset Code';
                    ToolTip = 'Specifies the unique code for this dataset.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of this dataset.';
                    ApplicationArea = All;
                }
                field(TestCount; TestCount)
                {
                    Caption = 'Number of Tests';
                    ToolTip = 'Specifies the number of test cases in this dataset.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field(IsDirty; IsDirty)
                {
                    Caption = 'Unsaved Changes';
                    ToolTip = 'Specifies whether there are unsaved changes in this dataset.';
                    Editable = false;
                    ApplicationArea = All;
                    StyleExpr = DirtyStyle;
                }
            }
            part(TestLinesPart; "AIT Dataset Editor Lines")
            {
                Caption = 'Test Cases';
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveChanges)
            {
                Caption = 'Save Changes';
                ToolTip = 'Saves all changes back to the Test Input records.';
                Image = Save;
                ApplicationArea = All;
                Enabled = IsDirty;

                trigger OnAction()
                begin
                    SaveDataset();
                    IsDirty := false;
                    UpdateDirtyStyle();
                    Message(SavedMsg);
                end;
            }
            action(DiscardChanges)
            {
                Caption = 'Discard Changes';
                ToolTip = 'Discards all changes and reloads from the Test Input records.';
                Image = Undo;
                ApplicationArea = All;
                Enabled = IsDirty;

                trigger OnAction()
                begin
                    if not Confirm(DiscardChangesQst) then
                        exit;

                    LoadDataset();
                    IsDirty := false;
                    UpdateDirtyStyle();
                end;
            }
            action(AddTest)
            {
                Caption = 'Add Test';
                ToolTip = 'Add a new test case to this dataset.';
                Image = Add;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    AddNewTest();
                end;
            }
            action(ExportYaml)
            {
                Caption = 'Export to YAML';
                ToolTip = 'Exports the dataset to a YAML file.';
                Image = Export;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExportDatasetToYaml();
                end;
            }
            action(ImportYaml)
            {
                Caption = 'Import from YAML';
                ToolTip = 'Imports test cases from a YAML file.';
                Image = Import;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ImportDatasetFromYaml();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SaveChanges_Promoted; SaveChanges)
                {
                }
                actionref(DiscardChanges_Promoted; DiscardChanges)
                {
                }
                actionref(AddTest_Promoted; AddTest)
                {
                }
            }
            group(Category_ImportExport)
            {
                Caption = 'Import/Export';

                actionref(ExportYaml_Promoted; ExportYaml)
                {
                }
                actionref(ImportYaml_Promoted; ImportYaml)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadDataset();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if IsDirty then
            if not Confirm(UnsavedChangesQst) then
                exit(false);
        exit(true);
    end;

    local procedure LoadDataset()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
    begin
        AITNoCodeMgt.LoadDatasetFromTestInputs(Rec.Code, TempAITTestInputLine, TempAITValidationEntry);
        TestCount := TempAITTestInputLine.Count();
        CurrPage.TestLinesPart.Page.SetTempRecords(TempAITTestInputLine, TempAITValidationEntry, Rec.Code);
    end;

    local procedure SaveDataset()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
    begin
        CurrPage.TestLinesPart.Page.GetTempRecords(TempAITTestInputLine, TempAITValidationEntry);
        AITNoCodeMgt.SaveDatasetToTestInputs(Rec.Code, TempAITTestInputLine, TempAITValidationEntry);
    end;

    local procedure AddNewTest()
    var
        AITTestCaseEditor: Page "AIT Test Case Editor";
        NewLineNo: Integer;
    begin
        CurrPage.TestLinesPart.Page.GetTempRecords(TempAITTestInputLine, TempAITValidationEntry);

        TempAITTestInputLine.Reset();
        if TempAITTestInputLine.FindLast() then
            NewLineNo := TempAITTestInputLine."Line No." + 10000
        else
            NewLineNo := 10000;

        TempAITTestInputLine.Init();
        TempAITTestInputLine."Dataset Code" := Rec.Code;
        TempAITTestInputLine."Line No." := NewLineNo;
        TempAITTestInputLine."Test Name" := '';
        TempAITTestInputLine.Insert();

        AITTestCaseEditor.SetTempRecords(TempAITTestInputLine, TempAITValidationEntry, true);
        if AITTestCaseEditor.RunModal() = Action::OK then begin
            AITTestCaseEditor.GetTempRecords(TempAITTestInputLine, TempAITValidationEntry);
            IsDirty := true;
            UpdateDirtyStyle();
            TestCount := TempAITTestInputLine.Count();
            CurrPage.TestLinesPart.Page.SetTempRecords(TempAITTestInputLine, TempAITValidationEntry, Rec.Code);
        end else
            // User cancelled - remove the new record
            TempAITTestInputLine.Delete();
    end;

    local procedure ExportDatasetToYaml()
    var
        TempBlob: Codeunit "Temp Blob";
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
        YamlText: Text;
    begin
        CurrPage.TestLinesPart.Page.GetTempRecords(TempAITTestInputLine, TempAITValidationEntry);
        YamlText := AITNoCodeMgt.BuildDatasetYaml(TempAITTestInputLine, TempAITValidationEntry);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(YamlText);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        FileName := Rec.Code + '.yaml';
        DownloadFromStream(InStream, 'Export Dataset', '', 'YAML Files (*.yaml)|*.yaml', FileName);
    end;

    local procedure ImportDatasetFromYaml()
    var
        AITNoCodeMgt: Codeunit "AIT No Code Mgt";
        InStream: InStream;
        FileName: Text;
        YamlText: Text;
        Line: Text;
    begin
        if not UploadIntoStream('Import Dataset', '', 'YAML Files (*.yaml;*.yml)|*.yaml;*.yml', FileName, InStream) then
            exit;

        // Read all text from stream
        while not InStream.EOS do begin
            InStream.ReadText(Line);
            YamlText += Line + '\n';
        end;

        AITNoCodeMgt.ParseDatasetYaml(YamlText, Rec.Code, TempAITTestInputLine, TempAITValidationEntry);
        TestCount := TempAITTestInputLine.Count();
        IsDirty := true;
        UpdateDirtyStyle();
        CurrPage.TestLinesPart.Page.SetTempRecords(TempAITTestInputLine, TempAITValidationEntry, Rec.Code);
        Message(ImportedMsg, TempAITTestInputLine.Count());
    end;

    local procedure UpdateDirtyStyle()
    begin
        if IsDirty then
            DirtyStyle := 'Attention'
        else
            DirtyStyle := 'Favorable';
    end;

    internal procedure MarkDirty()
    begin
        IsDirty := true;
        UpdateDirtyStyle();
    end;

    var
        TempAITTestInputLine: Record "AIT Test Input Line" temporary;
        TempAITValidationEntry: Record "AIT Validation Entry" temporary;
        TestCount: Integer;
        IsDirty: Boolean;
        DirtyStyle: Text;
        SavedMsg: Label 'Changes saved successfully.';
        DiscardChangesQst: Label 'Discard all changes and reload from the database?';
        UnsavedChangesQst: Label 'There are unsaved changes. Close without saving?';
        ImportedMsg: Label 'Imported %1 test case(s).', Comment = '%1 = number of tests';
}
