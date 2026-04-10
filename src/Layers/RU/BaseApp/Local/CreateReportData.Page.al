#pragma warning disable AA0247
page 26574 "Create Report Data"
{
    Caption = 'Create Report Data';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(DataSource; DataSource)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Source';
                    OptionCaption = 'NAV Reporting,Excel File';

                    trigger OnValidate()
                    begin
                        if DataSource = DataSource::"Excel File" then
                            ExcelFileDataSourceOnValidate();
                        if DataSource = DataSource::"NAV Reporting" then
                            NAVReportingDataSourceOnValida();
                    end;
                }
                field(DataDescription; DataDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Description';
                }
                field(CreationDate; CreationDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Creation Date';
                    ToolTip = 'Specifies when the report data was created.';
                }
                field(ProgressiveTotalCheckBox; ProgressiveTotal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Progressive Total';
                    Enabled = ProgressiveTotalCheckBoxEnable;

                    trigger OnValidate()
                    begin
                        UpdateControls();
                        UpdatePeriodType();
                    end;
                }
                field(Periodicity; Periodicity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Periodicity';
                    OptionCaption = ' ,Month,Quarter,Year';
                    ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                    trigger OnValidate()
                    begin
                        if StatutoryReport."Report Type" in [StatutoryReport."Report Type"::Tax, StatutoryReport."Report Type"::Accounting] then
                            if Periodicity = Periodicity::" " then
                                Error(Text006, StatutoryReport.FieldCaption("Report Type"), StatutoryReport."Report Type");

                        if StatutoryReport."Report Type" = StatutoryReport."Report Type"::Accounting then
                            if Periodicity = Periodicity::Month then
                                Error(Text007, StatutoryReport.FieldCaption("Report Type"), StatutoryReport."Report Type");

                        ExternReportManagement.InitPeriod(CalendarPeriod, Periodicity - 1);
                        UpdateControls();
                        UpdatePeriodType();
                    end;
                }
                field(AccountingPeriodTextBox; AccountPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Period';
                    Enabled = AccountingPeriodTextBoxEnable;
                    ToolTip = 'Specifies the accounting period to include data for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ExternReportManagement.SelectPeriod(Text, CalendarPeriod, ProgressiveTotal);
                        DatePeriod.Copy(CalendarPeriod);
                        ExternReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);
                        StartDate := DatePeriod."Period Start";
                        EndDate := DatePeriod."Period End";
                        CurrPage.Update();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        DatePeriod.Copy(CalendarPeriod);
                        ExternReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);
                        StartDate := DatePeriod."Period Start";
                        EndDate := DatePeriod."Period End";
                        UpdateControls();
                        UpdatePeriodType();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies if the period is Day, Month, or Quarter.';
                }
                field(StartDateTextBox; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Period Date';
                    Editable = StartDateTextBoxEditable;
                    ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                }
                field(EndDateTextBox; EndDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Period Date';
                    Editable = EndDateTextBoxEditable;
                }
                field(OKEI; OKEI)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OKEI';
                    OptionCaption = '383 - RUR,384 - thous. RUR,385 - mln. RUR';
                    ToolTip = 'Specifies the unit of measure for amounts that are associated with the statutory report data header.';
                }
                field(DocumentType; DocumentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    OptionCaption = 'Primary,Correction';
                    ToolTip = 'Specifies the type of the related document.';

                    trigger OnValidate()
                    begin
                        if DocumentType = DocumentType::Correction then
                            CorrectionDocumentTypeOnValida();
                        if DocumentType = DocumentType::Primary then
                            PrimaryDocumentTypeOnValidate();
                    end;
                }
                field(CorrNumberTextBox; CorrNumber)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Correction Number';
                    Enabled = CorrNumberTextBoxEnable;
                    MaxValue = 999;
                    MinValue = 1;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        ProgressiveTotalCheckBoxEnable := true;
        AccountingPeriodTextBoxEnable := true;
        CorrNumberTextBoxEnable := true;
        EndDateTextBoxEditable := true;
        StartDateTextBoxEditable := true;
    end;

    trigger OnOpenPage()
    begin
        GLSetup.Get();

        if CreationDate = 0D then
            CreationDate := Today;

        case true of
            (StatutoryReport."Report Type" = StatutoryReport."Report Type"::Accounting) and (Periodicity < 1):
                Periodicity := 2;
            (StatutoryReport."Report Type" = StatutoryReport."Report Type"::Tax) and (Periodicity = 0):
                Periodicity := 1;
        end;

        DataDescription := StatutoryReport.Description;

        UpdateControls();
        UpdatePeriodType();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        StatutoryReport: Record "Statutory Report";
        DatePeriod: Record Date;
        CalendarPeriod: Record Date;
        ExternReportManagement: Codeunit PeriodReportManagement;
        CreationDate: Date;
        StartDate: Date;
        EndDate: Date;
        AccountPeriod: Text[30];
        DataDescription: Text[250];
        ProgressiveTotal: Boolean;
        OKEI: Option "383","384","385";
        DocumentType: Option Primary,Correction;
        Periodicity: Option " ",Month,Quarter,Year;
        DataSource: Option "NAV Reporting","Excel File";
        CorrNumber: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Periodiocity can''t be empty for %1 = %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PeriodType: Code[2];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'Periodiocity can''t be Month for %1 = %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label 'The combination Periodicity=%1, Progressive Total=%2 is not defined. Please enter the value for Period Type manually.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StartDateTextBoxEditable: Boolean;
        EndDateTextBoxEditable: Boolean;
        CorrNumberTextBoxEnable: Boolean;
        AccountingPeriodTextBoxEnable: Boolean;
        ProgressiveTotalCheckBoxEnable: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(NewReportCode: Code[20])
    begin
        StatutoryReport.Get(NewReportCode);
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewCreationDate: Date; var NewStartDate: Date; var NewEndDate: Date; var NewDocumentType: Option; var NewOKEI: Option; var NewCorrNumber: Integer; var NewDataDescription: Text[250]; var NewPeriodicity: Option; var NewPeriodNo: Integer; var NewPeriodType: Code[2]; var NewPeriodName: Text[30]; var NewDataSource: Option)
    begin
        NewCreationDate := CreationDate;
        NewStartDate := StartDate;
        NewEndDate := EndDate;
        NewDocumentType := DocumentType;
        NewOKEI := OKEI;
        NewCorrNumber := CorrNumber;
        NewDataDescription := DataDescription;
        NewPeriodicity := Periodicity;
        if Periodicity in [Periodicity::Month, Periodicity::Quarter] then
            NewPeriodNo := CalendarPeriod."Period No.";
        NewPeriodType := PeriodType;
        NewPeriodName := AccountPeriod;
        NewDataSource := DataSource;
    end;

    [Scope('OnPrem')]
    procedure UpdateControls()
    var
        ParsedAccountPeriod: Text[30];
    begin
        if DocumentType = DocumentType::Primary then
            CorrNumber := 0;

        CorrNumberTextBoxEnable := DocumentType = DocumentType::Correction;

        if Periodicity > 0 then begin
            if CalendarPeriod."Period Start" = 0D then
                ExternReportManagement.InitPeriod(CalendarPeriod, Periodicity - 1);
            ExternReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, ProgressiveTotal);
            ParsedAccountPeriod := AccountPeriod;
            if ExternReportManagement.ParseCaptionPeriodName(ParsedAccountPeriod, CalendarPeriod, ProgressiveTotal) then
                AccountPeriod := ParsedAccountPeriod;
            DatePeriod.Copy(CalendarPeriod);
            ExternReportManagement.PeriodSetup(DatePeriod, ProgressiveTotal);
            AccountingPeriodTextBoxEnable := true;
            ProgressiveTotalCheckBoxEnable := true;
            StartDateTextBoxEditable := false;
            EndDateTextBoxEditable := false;
            StartDate := DatePeriod."Period Start";
            EndDate := DatePeriod."Period End";
        end else begin
            AccountingPeriodTextBoxEnable := false;
            ProgressiveTotalCheckBoxEnable := false;
            StartDateTextBoxEditable := true;
            EndDateTextBoxEditable := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdatePeriodType()
    begin
        case Periodicity of
            Periodicity::Month:
                if ProgressiveTotal then
                    PeriodType := Format(CalendarPeriod."Period No." + 34)
                else
                    PeriodType := '35';
            Periodicity::Quarter:
                if ProgressiveTotal then
                    case CalendarPeriod."Period No." of
                        1:
                            PeriodType := '21';
                        2:
                            PeriodType := '31';
                        3:
                            PeriodType := '33';
                        4:
                            PeriodType := '34';
                    end
                else
                    case CalendarPeriod."Period No." of
                        1:
                            PeriodType := '21';
                        2:
                            PeriodType := '22';
                        3:
                            PeriodType := '23';
                        4:
                            PeriodType := '24';
                    end;
            Periodicity::Year:
                if not ProgressiveTotal then
                    PeriodType := '46'
                else begin
                    PeriodType := '';
                    Message(Text009, Periodicity, ProgressiveTotal);
                end;
        end;
    end;

    local procedure CorrectionDocumentTypeOnAfterV()
    begin
        UpdateControls();
        if CorrNumber = 0 then
            CorrNumber := 1;
    end;

    local procedure PrimaryDocumentTypeOnAfterVali()
    begin
        UpdateControls();
    end;

    local procedure NAVReportingDataSourceOnAfterV()
    begin
        UpdateControls();
    end;

    local procedure ExcelFileDataSourceOnAfterVali()
    begin
        UpdateControls();
    end;

    local procedure NAVReportingDataSourceOnValida()
    begin
        NAVReportingDataSourceOnAfterV();
    end;

    local procedure ExcelFileDataSourceOnValidate()
    begin
        ExcelFileDataSourceOnAfterVali();
    end;

    local procedure PrimaryDocumentTypeOnValidate()
    begin
        PrimaryDocumentTypeOnAfterVali();
    end;

    local procedure CorrectionDocumentTypeOnValida()
    begin
        CorrectionDocumentTypeOnAfterV();
    end;
}

