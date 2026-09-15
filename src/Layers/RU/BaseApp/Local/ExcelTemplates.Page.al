#pragma warning disable AA0247
page 14919 "Excel Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Excel Templates';
    PageType = List;
    SourceTable = "Excel Template";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for a Microsoft Excel template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of a Microsoft Excel template.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file name for a Microsoft Excel template.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Import Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Template';
                    Ellipsis = true;
                    Image = ImportExcel;

                    trigger OnAction()
                    var
                        RecordRef: RecordRef;
                        TemplateExists: Boolean;
                    begin
                        TemplateExists := Rec.BLOB.HasValue;
                        Filename := FileMgt.BLOBImport(TempBlob, '*.xls');
                        if Filename = '' then
                            exit;
                        if TemplateExists then
                            if not Confirm(Text001, false, Rec.Code) then
                                exit;
                        TempBlob.ToRecordRef(RecordRef, Rec.FieldNo(BLOB));

                        Rec.UpdateTemplateHeight(Filename);

                        while StrPos(Filename, '\') <> 0 do
                            Filename := CopyStr(Filename, StrPos(Filename, '\') + 1);
                        Rec."File Name" := CopyStr(Filename, 1, MaxStrLen(Rec."File Name"));
                        CurrPage.SaveRecord();
                    end;
                }
                action("E&xport Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport Template';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Export the template for use in another database.';

                    trigger OnAction()
                    begin
                        Rec.CalcFields(BLOB);
                        if Rec.BLOB.HasValue() then begin
                            TempBlob.FromRecord(Rec, Rec.FieldNo(BLOB));
                            FileMgt.BLOBExport(TempBlob, Rec."File Name", true);
                        end;
                    end;
                }
                action("Delete Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Template';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        if Rec.BLOB.HasValue() then
                            if Confirm(Text002, false, Rec.Code) then begin
                                Rec.CalcFields(BLOB);
                                Clear(Rec.BLOB);
                                Rec."File Name" := '';
                                CurrPage.SaveRecord();
                            end;
                    end;
                }
            }
        }
    }

    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Do you want to replace the existing definition for template %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Do you want to delete the definition for template %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Filename: Text;
}

