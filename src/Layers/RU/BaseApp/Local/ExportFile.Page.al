#pragma warning disable AA0247
page 26575 "Export File"
{
    Caption = 'Export File';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(FileName; FileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'File Name';
                    ToolTip = 'Specifies the name of the file.';

                    trigger OnAssistEdit()
                    var
                        WindowTitle: Text[50];
                    begin
                        case FileType of
                            FileType::"Electronic File":
                                WindowTitle := Text001;
                            FileType::"Excel File":
                                WindowTitle := Text002;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if HiddenFileName <> '' then
            FileName := HiddenFileName;
    end;

    var
        FileType: Option "Electronic File","Excel File";
        FileName: Text[250];
        HiddenFileName: Text[250];
#pragma warning disable AA0074
        Text001: Label 'Save Electronic File';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Save Excel File';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetParameters(NewFileName: Text[250]; NewFileType: Option)
    begin
        HiddenFileName := NewFileName;
        FileType := NewFileType;
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewFileName: Text[250])
    begin
        NewFileName := FileName;
    end;
}

