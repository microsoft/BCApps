// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

page 130462 "Test Input Groups"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Test Input Group";
    CardPageId = "Test Input";
    Caption = 'Test Inputs';
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTableView = sorting("Group Name", Indentation, Code);

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                TreeInitialState = CollapseAll;
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Group Name";
                ShowAsTree = true;

                field(Indentation; Rec.Indentation)
                {
                    Visible = false;
                    Caption = 'Indentation';
                    ToolTip = 'Specifies the indentation level for the tree view';
                }
                field("Group Name"; Rec."Group Name")
                {
                }
                field(Code; Rec.Code)
                {
                }
                field("Language Name"; Rec."Language Name")
                {
                }
                field("Language Tag"; Rec."Language Tag")
                {
                }
                field("Language ID"; Rec."Language ID")
                {
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("No. of Entries"; Rec."No. of Entries")
                {
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            fileuploadaction(ImportDataInputs)
            {
                Caption = 'Import data-driven test inputs';
                AllowMultipleFiles = true;
                ToolTip = 'Import data-driven test inputs from a JSON, JSONL or YAML file';
                AllowedFileExtensions = '.jsonl', '.json', '.yaml';
                Image = Attach;

                trigger OnAction(Files: List of [FileUpload])
                var
                    TestInputsManagement: Codeunit "Test Inputs Management";
                    CurrentFile: FileUpload;
                    FileDataInStream: InStream;
                begin
                    foreach CurrentFile in Files do begin
                        CurrentFile.CreateInStream(FileDataInStream, TextEncoding::UTF8);
                        TestInputsManagement.UploadAndImportDataInputs(CurrentFile.FileName, FileDataInStream);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            actionref(ImportDefinition_Promoted; ImportDataInputs)
            {
            }
        }
    }
}