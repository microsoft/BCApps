#pragma warning disable AA0247
page 26550 "Statutory Reports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statutory Reports';
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Statutory Report";
    SourceTableView = sorting("Sequence No.");
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = CodeEmphasize;
                    ToolTip = 'Specifies the code for statutory reports.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the statutory report.';
                }
                field("Format Version Code"; Rec."Format Version Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format version code associated with the statutory report.';
                }
                field(Header; Rec.Header)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the header associated with the statutory report.';
                }
                field("Report Type"; Rec."Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report type associated with the statutory report.';
                }
                field("Sender No."; Rec."Sender No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sender number associated with the statutory report.';
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the statutory report is active.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending date associated with the statutory report.';
                }
                field("Recipient Tax Authority Code"; Rec."Recipient Tax Authority Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = "Tax Authorities";
                    ToolTip = 'Specifies the recipient tax authority code associated with the statutory report.';
                }
                field("Recipient Tax Authority SONO"; Rec."Recipient Tax Authority SONO")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first four digits of the VAT registration number for the recipient tax authority code.';
                }
                field("Admin. Tax Authority Code"; Rec."Admin. Tax Authority Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the administrative tax authority code associated with the statutory report.';
                }
                field("Admin. Tax Authority SONO"; Rec."Admin. Tax Authority SONO")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first four digits of the VAT registration number for the administrative tax authority code.';
                }
                field("Company Address Code"; Rec."Company Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company address code associated with the statutory report.';
                }
                field("Company Address Language Code"; Rec."Company Address Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company address language code associated with the statutory report.';
                }
                field("Uppercase Text Excel Format"; Rec."Uppercase Text Excel Format")
                {
                    ApplicationArea = Basic, Suite;
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
            group("&Setup")
            {
                Caption = '&Setup';
                Image = Setup;
                action(Tables)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tables';
                    Image = "Table";
                    RunObject = Page "Statutory Report Tables";
                    RunPageLink = "Report Code" = field(Code);
                    ShortCutKey = 'Ctrl+T';
                }
                action("XML Element Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'XML Element Lines';
                    Image = GetLines;
                    RunObject = Page "XML Element Lines";
                    RunPageLink = "Report Code" = field(Code);
                    ShortCutKey = 'Ctrl+E';
                    ToolTip = 'Set up or edit XML files associated with statutory reporting.';
                }
                separator(Action1210015)
                {
                }
                action("Copy Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Report';
                    Ellipsis = true;
                    Image = Copy;

                    trigger OnAction()
                    begin
                        Rec.CopyReport();
                    end;
                }
                separator(Action1210034)
                {
                }
                action("Export Report Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Report Settings';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export the report setup information.';

                    trigger OnAction()
                    var
                        StatutoryReport: Record "Statutory Report";
                        StatutoryReportMgt: Codeunit "Statutory Report Management";
                    begin
                        CurrPage.SetSelectionFilter(StatutoryReport);
                        StatutoryReportMgt.ExportReportSettings(StatutoryReport);
                    end;
                }
                action("Import Report Settings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Report Settings';
                    Ellipsis = true;
                    Image = Import;

                    trigger OnAction()
                    var
                        StatutoryReportMgt: Codeunit "Statutory Report Management";
                        FileName: Text;
                    begin
                        FileName := FileMgt.UploadFile(Text007, '.xml');

                        if FileName <> '' then
                            StatutoryReportMgt.ImportReportSettings(FileName);
                    end;
                }
            }
        }
        area(processing)
        {
            action("Report Data")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Report Data';
                Image = RegisteredDocs;
                RunObject = Page "Report Data List";
                RunPageLink = "Report Code" = field(Code);
                ToolTip = 'Preview and verify the data for the statutory report. The list contains one line for each set of report data that you have created for this directory.';
            }
            action("Export Log")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export &Log';
                Image = ExportFile;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Report Export Log";
                RunPageLink = "Report Code" = field(Code);
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Report Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Report Data';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'Generate data for the statutory report.';

                    trigger OnAction()
                    var
                        StatutoryReport: Record "Statutory Report";
                        StatutoryReportDataHeader: Record "Statutory Report Data Header";
                        CreateReportData: Page "Create Report Data";
                        OKEIType: Option "383","384","385";
                        DocumentType: Option Primary,Correction;
                        PeriodType: Option " ",Month,Quarter,Year;
                        DataSource: Option Database,Excel;
                        CorrNumber: Integer;
                        PeriodNo: Integer;
                        CreationDate: Date;
                        StartDate: Date;
                        EndDate: Date;
                        PeriodSign: Code[2];
                        DataDescription: Text[250];
                        PeriodName: Text[30];
                    begin
                        CreateReportData.SetParameters(Rec.Code);
                        if CreateReportData.RunModal() <> ACTION::OK then
                            exit;

                        CreateReportData.GetParameters(
                          CreationDate, StartDate, EndDate, DocumentType, OKEIType, CorrNumber, DataDescription,
                          PeriodType, PeriodNo, PeriodSign, PeriodName, DataSource);

                        if (StartDate = 0D) and (EndDate = 0D) then
                            Error(StartEndDateErr);

                        StatutoryReportDataHeader.CreateReportHeader(
                          Rec, CreationDate, StartDate, EndDate, DocumentType, OKEIType, CorrNumber, DataDescription, PeriodNo, PeriodSign, PeriodName);

                        StatutoryReport := Rec;
                        StatutoryReport.CreateReportData(StatutoryReportDataHeader."No.", StartDate, EndDate, DataSource);
                    end;
                }
                separator(Action1210027)
                {
                }
                action("Move Up")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    ShortCutKey = 'Shift+Ctrl+W';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveUp();
                    end;
                }
                action("Move Down")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    ShortCutKey = 'Shift+Ctrl+S';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveDown();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Report Data_Promoted"; "Report Data")
                {
                }
                actionref("Create Report Data_Promoted"; "Create Report Data")
                {
                }
                actionref("XML Element Lines_Promoted"; "XML Element Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        CodeOnFormat();
        DescriptionOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        StatutoryReport: Record "Statutory Report";
        SequenceNo: Integer;
    begin
        StatutoryReport.SetCurrentKey("Sequence No.");

        if BelowxRec then begin
            if StatutoryReport.FindLast() then;
            Rec."Sequence No." := StatutoryReport."Sequence No." + 1;
        end else begin
            SequenceNo := xRec."Sequence No.";

            StatutoryReport.SetFilter("Sequence No.", '%1..', SequenceNo);
            if StatutoryReport.Find('+') then
                repeat
                    StatutoryReport."Sequence No." := StatutoryReport."Sequence No." + 1;
                    StatutoryReport.Modify();
                until StatutoryReport.Next(-1) = 0;
            Rec."Sequence No." := SequenceNo;
        end;
    end;

    var
        FileMgt: Codeunit "File Management";
        StartEndDateErr: Label 'You must specify Start Date or\and End Date.';
#pragma warning disable AA0074
        Text007: Label 'Import';
#pragma warning restore AA0074
        CodeEmphasize: Boolean;
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    [Scope('OnPrem')]
    procedure MoveUp()
    var
        UpperStatutoryReport: Record "Statutory Report";
        SequenceNo: Integer;
    begin
        UpperStatutoryReport.SetCurrentKey("Sequence No.");
        UpperStatutoryReport.SetFilter("Sequence No.", '..%1', Rec."Sequence No." - 1);
        if UpperStatutoryReport.FindLast() then begin
            SequenceNo := UpperStatutoryReport."Sequence No.";
            UpperStatutoryReport."Sequence No." := Rec."Sequence No.";
            UpperStatutoryReport.Modify();
            Rec."Sequence No." := SequenceNo;
            Rec.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure MoveDown()
    var
        LowerStatutoryReport: Record "Statutory Report";
        SequenceNo: Integer;
    begin
        LowerStatutoryReport.SetCurrentKey("Sequence No.");
        LowerStatutoryReport.SetFilter("Sequence No.", '%1..', Rec."Sequence No." + 1);
        if LowerStatutoryReport.FindFirst() then begin
            SequenceNo := LowerStatutoryReport."Sequence No.";
            LowerStatutoryReport."Sequence No." := Rec."Sequence No.";
            LowerStatutoryReport.Modify();

            Rec."Sequence No." := SequenceNo;
            Rec.Modify();
        end;
    end;

    local procedure CodeOnFormat()
    begin
        CodeEmphasize := Rec.Header;
    end;

    local procedure DescriptionOnFormat()
    begin
        if Rec.Header then
            DescriptionIndent := 0
        else
            DescriptionIndent := 1;

        DescriptionEmphasize := Rec.Header;
    end;
}

