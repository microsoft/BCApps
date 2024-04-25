namespace System.Tooling;
page 149041 "BCCT Dataset"
{
    Caption = 'BCCT Datasets';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BCCT Dataset";

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
                    trigger OnValidate()
                    var
                        DatasetLine: Record "BCCT Dataset Line";
                    begin
                        if Rec."Dataset Name" = '' then
                            Error('Dataset Name cannot be empty.');
                        DatasetLine.Reset();
                        DatasetLine.SetRange("Dataset Name", xRec."Dataset Name");
                        if Datasetline.FindSet() then
                            repeat
                                DatasetLine."Dataset Name" := Rec."Dataset Name";
                                DatasetLine.Modify();
                            until DatasetLine.Next() = 0;
                    end;
                }
                field(Count; Rec."Input Count")
                {
                    ApplicationArea = All;
                    Caption = 'Input Count';
                    ToolTip = 'Specifies the number of inputs in the dataset.';
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

                actionref(SplitUpload1; UploadDataset)
                {
                }
                actionref(SplitUpload2; UploadDataset2)
                {
                }
                actionref(SplitUpload3; UploadDataset3)
                {
                }

            }

            actionref(EditDatasetPromoted; EditDataset) { }
        }
        area(Processing)
        {
            action(UploadDataset)
            {
                Image = Attach;
                ApplicationArea = All;
                Caption = 'Upload Dataset';
                ToolTip = 'Upload the dataset.';

                trigger OnAction()
                var
                    PromptRec: Record "BCCT Dataset Line";
                    PromptInStream: InStream;
                    FromFilter: Text;
                    CsvLine: Text;
                    Lines: List of [Text];
                    Line: Text;
                    LineList: List of [Text];
                    FragmentToAdd: Integer;
                    UploadedFileName: Text;
                begin
                    FromFilter := 'All Files (*.*)|*.*';
                    UploadIntoStream(DialogTitleLbl, '', FromFilter, UploadedFileName, PromptInStream);
                    while PromptInStream.ReadText(CsvLine) > 1 do begin
                        CsvLine := CsvLine.Replace('""', '''');
                        Lines.Add(CsvLine);
                    end;

                    Rec.Init();
                    Rec."Dataset Name" := CopyStr(UploadedFileName, 1, MaxStrLen(Rec."Dataset Name"));

                    if Lines.Count > 0 then begin
                        Lines.RemoveAt(1);
                        foreach Line in Lines do begin
                            LineList := Line.Split('"');
                            FragmentToAdd := LineList.Count;
                            if (LineList.Get(FragmentToAdd) = '') and (FragmentToAdd > 1) then
                                FragmentToAdd := FragmentToAdd - 1;
                            PromptRec.Init();
                            PromptRec.Id := 0;
                            PromptRec."Dataset Name" := Rec."Dataset Name";
                            PromptRec.Input := CopyStr(LineList.Get(FragmentToAdd).Trim(), 1, MaxStrLen(PromptRec.Input));
                            PromptRec.SetInputBlob(LineList.Get(FragmentToAdd).Trim());
                            PromptRec.Insert();
                        end;
                        Clear(LineList);
                    end;
                    Rec.Insert();
                    CurrPage.Update();
                end;
            }

            action(UploadDataset2)
            {
                Image = Attach;
                ApplicationArea = All;
                Caption = 'Upload without processing lines';
                Tooltip = 'Loads csv file';
                trigger OnAction()
                var
                    PromptRec: Record "BCCT Dataset Line";
                    PromptInStream: InStream;
                    FromFilter: Text;
                    CsvLine: Text;
                    Lines: List of [Text];
                    Line: Text;
                    LineList: List of [Text];
                    UploadedFileName: Text;
                begin
                    FromFilter := 'All Files (*.*)|*.*';
                    UploadIntoStream(DialogTitleLbl, '', FromFilter, UploadedFileName, PromptInStream);

                    Rec.Init();
                    Rec."Dataset Name" := CopyStr(UploadedFileName, 1, MaxStrLen(Rec."Dataset Name"));

                    while PromptInStream.ReadText(CsvLine) > 1 do
                        Lines.Add(CsvLine);

                    if Lines.Count > 0 then begin
                        Lines.RemoveAt(1);
                        foreach Line in Lines do begin
                            PromptRec.Init();
                            PromptRec.Id := 0;
                            PromptRec."Dataset Name" := Rec."Dataset Name";
                            PromptRec.Input := CopyStr(Line.Trim(), 1, MaxStrLen(PromptRec.Input));
                            PromptRec.SetInputBlob(Line.Trim());
                            PromptRec.Insert();
                        end;
                        Clear(LineList);
                    end;

                    Rec.Insert();
                    CurrPage.Update();
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
                    PromptRec: Record "BCCT Dataset Line";
                    PromptInStream: InStream;
                    FromFilter: Text;
                    CsvLine: Text;
                    Lines: List of [Text];
                    Line: Text;
                    LineList: List of [Text];
                    UploadedFileName: Text;
                begin
                    FromFilter := 'All Files (*.*)|*.*';
                    UploadIntoStream(DialogTitleLbl, '', FromFilter, UploadedFileName, PromptInStream);
                    while PromptInStream.ReadText(CsvLine) > 1 do begin
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
                            PromptRec.Init();
                            PromptRec.Id := 0;
                            PromptRec."Dataset Name" := Rec."Dataset Name";
                            if LineList.Count > 0 then begin
                                PromptRec.Input := CopyStr(LineList.Get(1).Trim(), 1, MaxStrLen(PromptRec.Input));
                                PromptRec.SetInputBlob(LineList.Get(1).Trim());
                            end;
                            if LineList.Count > 1 then begin
                                PromptRec.SetExpOutputBlob(LineList.Get(2).Trim());
                                PromptRec."Expected Output" := CopyStr(LineList.Get(2).Trim(), 1, MaxStrLen(PromptRec."Expected Output"));
                            end;
                            PromptRec.Insert();

                            Clear(LineList);
                        end;
                        Rec.Insert();
                        CurrPage.Update();
                    end;
                end;
            }
            action(EditDataset)
            {
                ApplicationArea = All;
                Scope = Repeater;
                Caption = 'Edit Dataset';
                Image = Edit;
                ToolTip = 'Edit the dataset.';

                trigger OnAction()
                var
                    PTFDatasetPrompts: Record "BCCT Dataset Line";
                    PTFDatasetPromptsPage: Page "BCCT Dataset Line";
                begin
                    PTFDatasetPrompts.SetFilter("Dataset Name", Rec."Dataset Name");
                    PTFDatasetPromptsPage.SetDatasetName(Rec."Dataset Name");
                    PTFDatasetPromptsPage.SetRecord(PTFDatasetPrompts);
                    PTFDatasetPromptsPage.Run();
                end;
            }
        }
    }

    var
        DialogTitleLbl: Label 'Please select the dataset to upload';
}