#pragma warning disable AA0247
page 26586 "Format Versions"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Format Versions';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Format Version";
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
                    ToolTip = 'Specifies the format version code for the statutory reports.';
                }
                field("KND Code"; Rec."KND Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the classification of fiscal documentation that is assigned to each statutory report.';
                }
                field("Report Description"; Rec."Report Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report description associated with the version format for the statutory reports.';
                }
                field("Report Type"; Rec."Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format version report type for the statutory reports. Report types include Accounting and Tax.';
                }
                field("Excel File Name"; Rec."Excel File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel file name of the version format associated with the statutory report.';
                }
                field("XML Schema File Name"; Rec."XML Schema File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XML schema file name of the version format associated with the statutory report.';
                }
                field("XML File Name Element Name"; Rec."XML File Name Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the XML file name element name of the statutory report setup information.';
                }
                field("Part No."; Rec."Part No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the part number associated with the version format for the statutory reports.';
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version format number for the statutory reports.';
                }
                field("Usage Starting Date"; Rec."Usage Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the usage start date associated with the version format for the statutory reports.';
                }
                field("Usage First Reporting Period"; Rec."Usage First Reporting Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first reporting period for the usage associated with the statutory reports.';
                }
                field("Usage Ending Date"; Rec."Usage Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the usage end date associated with the version format for the statutory reports.';
                }
                field("Register No."; Rec."Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the register number associated with the version format for the statutory reports.';
                }
                field("Form Order No. & Appr. Date"; Rec."Form Order No. & Appr. Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the form order number and approval date associated with the statutory reports.';
                }
                field("Format Order No. & Appr. Date"; Rec."Format Order No. & Appr. Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version format order number and approval date associated with the statutory reports.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version format comment associated with the statutory reports.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Excel &Template")
            {
                Caption = 'Excel &Template';
                action("Import Excel Template")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Excel Template';
                    Ellipsis = true;
                    Image = Excel;
                    ToolTip = 'Import an Excel template.';

                    trigger OnAction()
                    begin
                        if Rec.HasLinkedReports() then
                            Error(Text006, Rec.FieldCaption("Report Template"));
                        Rec.ImportExcelTemplate('');
                        CurrPage.SaveRecord();
                    end;
                }
                action("&Export")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    begin
                        Rec.ExportExcelTemplate(Rec."Excel File Name");
                    end;
                }
                action("&Delete")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Delete';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        Clear(Rec."Report Template");
                        Rec."Excel File Name" := '';
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("XML &Schema")
            {
                Caption = 'XML &Schema';
                action("Import XML Schema")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import XML Schema';
                    Ellipsis = true;
                    Image = TransferFunds;

                    trigger OnAction()
                    begin
                        if Rec.HasLinkedReports() then
                            Error(Text006, Rec.FieldCaption("XML Schema"));
                        Rec.ImportXMLSchema('');
                        CurrPage.SaveRecord();
                    end;
                }
                action(Action1210065)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    begin
                        Rec.ExportXMLSchema(Rec."XML Schema File Name");
                    end;
                }
                action(Action1210066)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Delete';
                    Image = Delete;

                    trigger OnAction()
                    begin
                        Clear(Rec."XML Schema");
                        Rec."XML Schema File Name" := '';
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Export Format Versions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export Format Versions';
                    Ellipsis = true;
                    Image = Export;

                    trigger OnAction()
                    begin
                        ExportFormatVersions();
                    end;
                }
                action("&Import Format Versions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Format Versions';
                    Ellipsis = true;
                    Image = Import;

                    trigger OnAction()
                    begin
                        ImportFormatVersions();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Import Excel Template_Promoted"; "Import Excel Template")
                {
                }
                actionref("Import XML Schema_Promoted"; "Import XML Schema")
                {
                }
            }
        }
    }

    var
        FileMgt: Codeunit "File Management";
        FileName: Text[1024];
        PathName: Text[1024];
#pragma warning disable AA0074
        Text004: Label 'Select a filename to import Format Versions.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Select a filename to export Format Versions to.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'You cannot import %1 because there are linked reports.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ExportFormatVersions()
    var
        FormatVersion: Record "Format Version";
        FormatVersions: XMLport "Format Versions";
        OutputFile: File;
        OutStr: OutStream;
    begin
        FileName := FileMgt.ServerTempFileName('xml');

        CurrPage.SetSelectionFilter(FormatVersion);

        OutputFile.Create(FileName);
        OutputFile.CreateOutStream(OutStr);
        FormatVersions.SetDestination(OutStr);
        FormatVersions.SetData(FormatVersion);
        FormatVersions.Export();
        OutputFile.Close();
        Clear(OutStr);

        Download(FileName, Text005, '', '', FileName);

        PathName := GetPathName(FileName);

        if FormatVersion.FindSet() then
            repeat
                FormatVersion.ExportExcelTemplate(PathName + FormatVersion."Excel File Name");
                FormatVersion.ExportXMLSchema(PathName + FormatVersion."XML Schema File Name");
            until FormatVersion.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportFormatVersions()
    var
        FormatVersions: XMLport "Format Versions";
        InStr: InStream;
    begin
        if not UploadIntoStream(Text004, '', '*.xml|*.xml', FileName, InStr) then
            exit;
        PathName := GetPathName(FileName);
        FormatVersions.SetSource(InStr);
        FormatVersions.Import();
        FormatVersions.ImportData(PathName);
        Clear(InStr);
    end;

    [Scope('OnPrem')]
    procedure GetPathName(FullFileName: Text[1024]) PathName: Text[1024]
    var
        i: Integer;
    begin
        for i := StrLen(FullFileName) downto 1 do
            if FullFileName[i] = '\' then begin
                PathName := CopyStr(FullFileName, 1, i);
                exit;
            end;

        exit;
    end;
}

