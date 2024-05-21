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
                ToolTip = 'Uploads datasets from files';
                AllowedFileExtensions = '.jsonl';
                Image = Attach;

                trigger OnAction(Files: List of [FileUpload])
                var
                    ExistingDatasets: Record "BCCT Dataset";
                    DatasetLine: Record "BCCT Dataset Line";
                    CurrentFile: FileUpload;
                    DataInStream: InStream;
                    JsonLine: Text;
                    JsonLineObj: JsonObject;
                    DatasetName: Text[100];
                    Options: Text;
                    Selected: Integer;
                    StrMenuLbl: Label 'Overwrite,Rename and Upload,Exit';
                    DialogTitleLbl: Label 'Dataset with name %1 already exists. Choose one of the following options:', Comment = '%1=Dataset Name';
                begin
                    foreach CurrentFile in files do begin
                        CurrentFile.CreateInStream(DataInStream, TextEncoding::UTF8);
                        DatasetName := CopyStr(CurrentFile.FileName, 1, MaxStrLen(Rec."Dataset Name"));
                        ExistingDatasets.SetLoadFields("Dataset Name");
                        ExistingDatasets.SetRange("Dataset Name", DatasetName);
                        if not ExistingDatasets.IsEmpty() then begin
                            // Show menu dialog dialog
                            Options := StrMenuLbl;
                            Selected := Dialog.StrMenu(Options, 3, StrSubstNo(DialogTitleLbl, DatasetName));
                            case Selected of
                                1:
                                    begin
                                        DatasetLine.SetRange("Dataset Name", DatasetName);
                                        DatasetLine.DeleteAll();
                                    end;
                                2:
                                    begin
                                        DatasetName := DatasetName + ' - ' + CreateGuid();
                                        Rec.Init();
                                        Rec."Dataset Name" := DatasetName;
                                        Rec.Insert();
                                    end;
                                3:
                                    exit;
                            end;
                        end
                        else begin
                            Rec.Init();
                            Rec."Dataset Name" := DatasetName;
                            Rec.Insert();
                        end;

                        while DataInStream.ReadText(JsonLine) > 0 do begin
                            DatasetLine.Init();
                            DatasetLine.Id := 0;
                            DatasetLine."Dataset Name" := DatasetName;
                            JsonLineObj.ReadFrom(JsonLine.Trim()); //Validate the JSON line
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