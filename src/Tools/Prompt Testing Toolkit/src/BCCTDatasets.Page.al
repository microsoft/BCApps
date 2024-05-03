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
            group(UploadGroup)
            {
                ShowAs = SplitButton;

                actionref(UploadMultipleRef; UploadDatasets)
                {
                }
                actionref(SplitUpload1; UploadDataset2)
                {
                }
                actionref(SplitUpload3; UploadDataset3)
                {
                }

            }
        }
        area(Processing)
        {
            fileuploadaction(UploadDatasets)
            {
                Caption = 'Upload Datasets';
                AllowMultipleFiles = true;
                AllowedFileExtensions = '.jsonl';
                Image = Attach;

                trigger OnAction(Files: List of [FileUpload])
                var
                    DatasetLine: Record "BCCT Dataset Line";
                    CurrentFile: FileUpload;
                    DataInStream: InStream;
                    JsonLine: Text; //TODO: consider adding validation
                begin
                    foreach CurrentFile in files do begin
                        CurrentFile.CreateInStream(DataInStream, TextEncoding::UTF8);
                        Rec.Init();
                        Rec."Dataset Name" := CopyStr(CurrentFile.FileName, 1, MaxStrLen(Rec."Dataset Name"));
                        Rec.Insert();

                        while DataInStream.ReadText(JsonLine) > 0 do begin
                            DatasetLine.Init();
                            DatasetLine.Id := 0;
                            DatasetLine."Dataset Name" := Rec."Dataset Name";
                            DatasetLine.SetInputTextAsBlob(JsonLine.Trim());
                            DatasetLine.Insert();
                        end
                    end;
                end;
            }
            action(UploadDataset2)
            {
                Image = Attach;
                ApplicationArea = All;
                Caption = 'Upload dataset';
                Tooltip = 'Loads a file and converts the lines to inputs for the dataset';
                trigger OnAction()
                var
                    DatasetLine: Record "BCCT Dataset Line";
                    DataInStream: InStream;
                    FromFilter: Text;
                    CsvLine: Text;
                    Lines: List of [Text];
                    Line: Text;
                    LineList: List of [Text];
                    UploadedFileName: Text;
                begin
                    FromFilter := 'All Files (*.*)|*.*';
                    if not UploadIntoStream(DialogTitleLbl, '', FromFilter, UploadedFileName, DataInStream) then exit;

                    Rec.Init();
                    Rec."Dataset Name" := CopyStr(UploadedFileName, 1, MaxStrLen(Rec."Dataset Name"));
                    Rec.Insert();

                    while DataInStream.ReadText(CsvLine) > 1 do
                        Lines.Add(CsvLine);

                    if Lines.Count > 0 then begin
                        if UploadedFileName.EndsWith('.csv') then
                            Lines.RemoveAt(1);
                        foreach Line in Lines do begin
                            DatasetLine.Init();
                            DatasetLine.Id := 0;
                            DatasetLine."Dataset Name" := Rec."Dataset Name";
                            DatasetLine.SetInputTextAsBlob(Line.Trim());
                            DatasetLine.Insert();
                        end;
                        Clear(LineList);
                    end;
                    CurrPage.Update(false);
                end;
            }

            action(UploadDataset3)
            {
                Image = Attach;
                ApplicationArea = All;
                Caption = 'Upload Dataset with Expected Responses';
                ToolTip = 'Upload the dataset.';

                trigger OnAction()
                var
                    DatasetLine: Record "BCCT Dataset Line";
                    DataInStream: InStream;
                    FromFilter: Text;
                    CsvLine: Text;
                    Lines: List of [Text];
                    Line: Text;
                    LineList: List of [Text];
                    UploadedFileName: Text;
                begin
                    FromFilter := 'All Files (*.*)|*.*';
                    UploadIntoStream(DialogTitleLbl, '', FromFilter, UploadedFileName, DataInStream);
                    while DataInStream.ReadText(CsvLine) > 1 do begin
                        CsvLine := CsvLine.Replace('""', '''');
                        Lines.Add(CsvLine);
                    end;

                    Rec.Init();
                    Rec."Dataset Name" := CopyStr(UploadedFileName, 1, MaxStrLen(Rec."Dataset Name"));

                    if Lines.Count > 0 then begin
                        Lines.RemoveAt(1);
                        foreach Line in Lines do begin
                            LineList := Line.Split('"');
                            LineList.Remove('');
                            LineList.Remove(',');
                            DatasetLine.Init();
                            DatasetLine.Id := 0;
                            DatasetLine."Dataset Name" := Rec."Dataset Name";
                            if LineList.Count > 0 then
                                DatasetLine.SetInputTextAsBlob(LineList.Get(1).Trim());
                            if LineList.Count > 1 then
                                DatasetLine.SetExpectedOutputTextAsBlob(LineList.Get(2).Trim());
                            DatasetLine.Insert();

                            Clear(LineList);
                        end;
                        Rec.Insert();
                        CurrPage.Update();
                    end;
                end;
            }
        }
    }

    var
        DialogTitleLbl: Label 'Please select the dataset to upload';
}