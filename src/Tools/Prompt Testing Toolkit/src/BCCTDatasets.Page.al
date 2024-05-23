// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;
page 149041 "BCCT Datasets"
{
    Caption = 'BCCT Datasets';
    PageType = List;
    CardPageId = "BCCT Dataset";
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BCCT Dataset";
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Dataset)
            {
                field("Dataset Name"; Rec."Dataset Name")
                {
                    ApplicationArea = All;
                    Caption = 'Dataset Name';
                    ToolTip = 'Specifies Dataset Name';
                    Editable = true;
                }
                field(Count; Rec."Line Count")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Entries';
                    ToolTip = 'Specifies the number of entries in the dataset.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(UploadMultipleRef; UploadDatasets)
            {
            }
        }
        area(Processing)
        {
            fileuploadaction(UploadDatasets)
            {
                Caption = 'Upload Datasets';
                AllowMultipleFiles = true;
                ToolTip = 'Uploads datasets from jsonl files';
                AllowedFileExtensions = '.jsonl';
                Image = Attach;

                trigger OnAction(Files: List of [FileUpload])
                var
                    CurrentFile: FileUpload;
                    FileDataInStream: InStream;
                begin
                    foreach CurrentFile in files do begin
                        CurrentFile.CreateInStream(FileDataInStream, TextEncoding::UTF8);
                        Rec.UploadDataset(FileDataInStream, CopyStr(CurrentFile.FileName, 1, MaxStrLen(Rec."Dataset Name")));
                    end;
                end;
            }
        }
    }
}