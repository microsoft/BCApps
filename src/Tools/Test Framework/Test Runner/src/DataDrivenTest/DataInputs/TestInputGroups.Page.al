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

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(Code; Rec.Code)
                {
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
                ToolTip = 'Import data-driven test inputs from a JSON or JSONL file';
                AllowedFileExtensions = '.jsonl', '.json';
                Image = Attach;

                trigger OnAction(Files: List of [FileUpload])
                var
                    TestInputsManagement: Codeunit "Test Inputs Management";
                    CurrentFile: FileUpload;
                    FileDataInStream: InStream;
                begin
                    foreach CurrentFile in files do begin
                        CurrentFile.CreateInStream(FileDataInStream, TextEncoding::UTF8);
                        TestInputsManagement.UploadAndImportDataInputsFromJson(CurrentFile.FileName, FileDataInStream);
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