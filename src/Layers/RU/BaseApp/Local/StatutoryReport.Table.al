#pragma warning disable AA0247
table 26550 "Statutory Report"
{
    Caption = 'Statutory Report';
    LookupPageID = "Statutory Reports";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Group Code"; Code[20])
        {
            Caption = 'Group Code';
            TableRelation = "Statutory Report Group";

            trigger OnValidate()
            begin
                TestField(Header, false);
            end;
        }
        field(6; "Format Version Code"; Code[20])
        {
            Caption = 'Format Version Code';
            TableRelation = "Format Version";

            trigger OnValidate()
            var
                StatutoryReportDataHeader: Record "Statutory Report Data Header";
            begin
                TestField(Header, false);
                if "Format Version Code" <> xRec."Format Version Code" then begin
                    StatutoryReportDataHeader.SetRange("Report Code", Code);
                    if not StatutoryReportDataHeader.IsEmpty() then
                        Error(Text030,
                          FieldCaption("Format Version Code"),
                          TableCaption,
                          Code);

                    if "Format Version Code" <> '' then begin
                        TestField(Code);
                        FormatVersion.Get("Format Version Code");
                        FormatVersion.TestField("Excel File Name");
                        if FormatVersion."XML Schema File Name" = '' then
                            Message(Text027, FormatVersion.GetRecDescription());
                        Description := FormatVersion."Report Description";
                        "Report Type" := FormatVersion."Report Type";
                        "Starting Date" := FormatVersion."Usage Starting Date";
                        "Ending Date" := FormatVersion."Usage Ending Date";
                        ImportExcelSheetNames();
                        if ConfirmImportXMLSchema() then
                            ImportXMLSchema();
                    end;
                end;
            end;
        }
        field(9; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(10; "Excel File Name"; Text[250])
        {
            Caption = 'Excel File Name';
        }
        field(12; "Report Template"; BLOB)
        {
            Caption = 'Report Template';
        }
        field(13; "Sender No."; Code[20])
        {
            Caption = 'Sender No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                TestField(Header, false);
            end;
        }
        field(14; "Report Type"; Option)
        {
            Caption = 'Report Type';
            OptionCaption = ' ,Tax,Accounting';
            OptionMembers = " ",Tax,Accounting;

            trigger OnValidate()
            begin
                TestField(Header, false);
            end;
        }
        field(15; Active; Boolean)
        {
            Caption = 'Active';

            trigger OnValidate()
            begin
                TestField(Header, false);
            end;
        }
        field(16; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                TestField(Header, false);
            end;
        }
        field(17; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(20; "Recipient Tax Authority Code"; Code[20])
        {
            Caption = 'Recipient Tax Authority Code';
            TableRelation = Vendor."No." where("Vendor Type" = const("Tax Authority"));

            trigger OnValidate()
            begin
                if "Recipient Tax Authority Code" <> '' then begin
                    Vendor.Get("Recipient Tax Authority Code");
                    "Recipient Tax Authority SONO" := CopyStr(Vendor."VAT Registration No.", 1, 4);
                end else
                    "Recipient Tax Authority SONO" := '';
            end;
        }
        field(21; "Recipient Tax Authority SONO"; Code[4])
        {
            Caption = 'Recipient Tax Authority SONO';
        }
        field(22; "Admin. Tax Authority Code"; Code[20])
        {
            Caption = 'Admin. Tax Authority Code';
            TableRelation = Vendor."No." where("Vendor Type" = const("Tax Authority"));

            trigger OnValidate()
            begin
                if "Admin. Tax Authority Code" <> '' then begin
                    Vendor.Get("Admin. Tax Authority Code");
                    "Admin. Tax Authority SONO" := CopyStr(Vendor."VAT Registration No.", 1, 4);
                end else
                    "Admin. Tax Authority SONO" := '';
            end;
        }
        field(23; "Admin. Tax Authority SONO"; Code[4])
        {
            Caption = 'Admin. Tax Authority SONO';
        }
        field(25; Header; Boolean)
        {
            Caption = 'Header';

            trigger OnValidate()
            begin
                if "Format Version Code" <> '' then
                    Error(Text031,
                      FieldCaption(Header),
                      Header,
                      FieldCaption("Format Version Code"));

                if Header then begin
                    "Group Code" := '';
                    "Format Version Code" := '';
                    "Sender No." := '';
                    "Report Type" := "Report Type"::" ";
                    Active := false;
                    "Ending Date" := 0D;
                    "Company Address Code" := '';
                    "Company Address Language Code" := '';
                    "Uppercase Text Excel Format" := false;
                end;
            end;
        }
        field(26; "Company Address Code"; Code[10])
        {
            Caption = 'Company Address Code';
            TableRelation = "Company Address".Code where("Address Type" = const(Legal));

            trigger OnLookup()
            begin
                Clear(CompanyAddressList);
                if CompanyAddress.Get("Company Address Code", "Company Address Language Code") then
                    CompanyAddressList.SetRecord(CompanyAddress);

                CompanyAddressList.LookupMode := true;
                if CompanyAddressList.RunModal() = ACTION::LookupOK then begin
                    CompanyAddressList.GetRecord(CompanyAddress);
                    if ("Company Address Code" <> CompanyAddress.Code) or
                       ("Company Address Language Code" <> CompanyAddress."Language Code")
                    then
                        TestField(Header, false);
                    "Company Address Code" := CompanyAddress.Code;
                    "Company Address Language Code" := CompanyAddress."Language Code";
                end;
            end;

            trigger OnValidate()
            begin
                if "Company Address Code" <> xRec."Company Address Code" then begin
                    "Company Address Language Code" := '';
                    if "Company Address Code" <> '' then
                        TestField(Header, false);
                end;
            end;
        }
        field(27; "Company Address Language Code"; Code[10])
        {
            Caption = 'Company Address Language Code';
            TableRelation = "Company Address"."Language Code" where(Code = field("Company Address Code"),
                                                                     "Address Type" = const(Legal));

            trigger OnValidate()
            begin
                if ("Company Address Language Code" <> xRec."Company Address Language Code") and
                   ("Company Address Language Code" <> '')
                then
                    TestField(Header, false);
            end;
        }
        field(28; "Uppercase Text Excel Format"; Boolean)
        {
            Caption = 'Uppercase Text Excel Format';

            trigger OnValidate()
            begin
                if "Uppercase Text Excel Format" then
                    TestField(Header, false);
            end;
        }
        field(29; "Uppercase Text XML Format"; Boolean)
        {
            Caption = 'Uppercase Text XML Format';

            trigger OnValidate()
            begin
                if "Uppercase Text XML Format" then
                    TestField(Header, false);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        XMLElementLine: Record "XML Element Line";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
    begin
        StatutoryReportTable.SetRange("Report Code", Code);
        if StatutoryReportTable.FindFirst() then
            StatutoryReportTable.DeleteAll(true);

        StatutoryReportDataHeader.SetRange("Report Code", Code);
        if StatutoryReportDataHeader.FindFirst() then
            StatutoryReportDataHeader.DeleteAll(true);

        XMLElementLine.SetRange("Report Code", Code);
        if not XMLElementLine.IsEmpty() then
            XMLElementLine.DeleteAll(true);

        StatReportExcelSheet.SetRange("Report Code", Code);
        StatReportExcelSheet.SetRange("Report Data No.", '');
        StatReportExcelSheet.DeleteAll();
    end;

    trigger OnInsert()
    begin
        StatutoryReportSetup.Get();
        if not Header then begin
            if "Company Address Code" = '' then
                "Company Address Code" := StatutoryReportSetup."Default Comp. Addr. Code";
            if "Company Address Language Code" = '' then
                "Company Address Language Code" := StatutoryReportSetup."Default Comp. Addr. Lang. Code";
        end;
    end;

    var
        Vendor: Record Vendor;
        StatutoryReportSetup: Record "Statutory Report Setup";
        FormatVersion: Record "Format Version";
        CompanyAddress: Record "Company Address";
        TempBlob: Codeunit "Temp Blob";
        CompanyAddressList: Page "Company Address List";
        FileMgt: Codeunit "File Management";
        XlWrkBkWriter: DotNet WorkbookWriter;
        XlWrkBkReader: DotNet WorkbookReader;
        XlWrkShtWriter: DotNet WorksheetWriter;
        XlWrkShtReader: DotNet WorksheetReader;
        RootNode: DotNet XmlNode;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Tables for %1 already exist and will be deleted. Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text010: Label 'Import data from Excel...';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text011: Label 'You must specify Statutury Report Code.';
#pragma warning restore AA0074
        i: Integer;
        EndOfLoop: Integer;
        SequenceNo: Integer;
        LineNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text023: Label 'File %1 is not a XML schema.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text026: Label 'The existent XML schema will be deleted. Do you want to continue?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text027: Label '%1 does not contain XML schema.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text028: Label 'The existent Excel template settings will be deleted. Do you want to continue?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text029: Label 'XML Element Lines for Report %1 already exist and will be deleted. Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text030: Label '%1 cannot be changed because %2 %3 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text031: Label '%1 cannot be %2 because %3 is not empty.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text032: Label 'This function is allowed for classic client only.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CreateReportData(ReportDataNo: Code[20]; StartDate: Date; EndDate: Date; DataSource: Option Database,Excel)
    begin
        case DataSource of
            DataSource::Database:
                CalculateDataFromIntSource(ReportDataNo, StartDate, EndDate);
            DataSource::Excel:
                ImportDataFromExcel(ReportDataNo);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalculateDataFromIntSource(DataHeaderNo: Code[20]; StartDate: Date; EndDate: Date): Boolean
    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableColumn: Record "Stat. Report Table Column";
        TableIndividualRequisite: Record "Table Individual Requisite";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
    begin
        StatutoryReportTable.SetRange("Report Code", Code);
        if StatutoryReportTable.FindSet() then begin
            repeat
                StatReportExcelSheet."Report Code" := Code;
                StatReportExcelSheet."Table Code" := StatutoryReportTable.Code;
                StatReportExcelSheet."Report Data No." := DataHeaderNo;
                StatReportExcelSheet."Sheet Name" := StatutoryReportTable."Excel Sheet Name";
                if not StatReportExcelSheet.Find() then
                    StatReportExcelSheet.Insert(true);

                if StatutoryReportTable."Int. Source Type" <> StatutoryReportTable."Int. Source Type"::" " then begin
                    StatReportTableRow.SetRange("Report Code", Code);
                    StatReportTableRow.SetRange("Table Code", StatutoryReportTable.Code);
                    StatReportTableColumn.SetRange("Report Code", Code);
                    StatReportTableColumn.SetRange("Table Code", StatutoryReportTable.Code);

                    if StatReportTableRow.FindSet() then
                        repeat
                            if StatReportTableColumn.FindSet() then
                                repeat
                                    CreateCellFromIntSource(
                                      DataHeaderNo,
                                      Code,
                                      StatutoryReportTable.Code,
                                      StatReportTableRow."Line No.",
                                      StatReportTableColumn."Line No.",
                                      StartDate,
                                      EndDate,
                                      StatReportExcelSheet."Sheet Name");
                                until StatReportTableColumn.Next() = 0;
                        until StatReportTableRow.Next() = 0;

                    TableIndividualRequisite.SetRange("Report Code", Code);
                    TableIndividualRequisite.SetRange("Table Code", StatutoryReportTable.Code);
                    if TableIndividualRequisite.FindSet() then
                        repeat
                            CreateCellFromIntSource(
                              DataHeaderNo,
                              Code,
                              StatutoryReportTable.Code,
                              TableIndividualRequisite."Line No.",
                              0,
                              StartDate,
                              EndDate,
                              StatReportExcelSheet."Sheet Name");
                        until TableIndividualRequisite.Next() = 0;
                end;
            until StatutoryReportTable.Next() = 0;
            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CreateCellFromIntSource(DataHeaderNo: Code[20]; ReportCode: Code[20]; TableCode: Code[20]; RowNo: Integer; ColumnNo: Integer; StartDate: Date; EndDate: Date; SheetName: Text[30])
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TaxRegisterAccumulation: Record "Tax Register Accumulation";
        TaxCalcAccumulation: Record "Tax Calc. Accumulation";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        AccSchedManagement: Codeunit AccSchedManagement;
        CellValue: Decimal;
    begin
        if StatReportTableMapping.Get(
             ReportCode,
             TableCode,
             RowNo,
             ColumnNo)
        then
            if StatReportTableMapping."Int. Source No." <> '' then begin
                case StatReportTableMapping."Int. Source Type" of
                    StatReportTableMapping."Int. Source Type"::"Acc. Schedule":
                        begin
                            StatReportTableMapping.TestField("Int. Source Col. Lay. Name");
                            AccScheduleLine.Get(
                              StatReportTableMapping."Int. Source No.",
                              StatReportTableMapping."Internal Source Row No.");
                            AccScheduleLine.SetFilter("Date Filter", '%1..%2', StartDate, EndDate);
                            ColumnLayout.Get(
                              StatReportTableMapping."Int. Source Col. Lay. Name",
                              StatReportTableMapping."Internal Source Column No.");

                            CellValue := AccSchedManagement.CalcCell(AccScheduleLine, ColumnLayout, false);
                        end;
                    StatReportTableMapping."Int. Source Type"::"Tax Register":
                        begin
                            TaxRegisterAccumulation.SetRange("Section Code", StatReportTableMapping."Int. Source Section Code");
                            TaxRegisterAccumulation.SetRange("Tax Register No.", StatReportTableMapping."Int. Source No.");
                            TaxRegisterAccumulation.SetFilter("Starting Date", '%1..', StartDate);
                            TaxRegisterAccumulation.SetFilter("Ending Date", '..%1', EndDate);
                            TaxRegisterAccumulation.SetRange("Template Line No.", StatReportTableMapping."Internal Source Row No.");
                            if TaxRegisterAccumulation.FindLast() then
                                CellValue := TaxRegisterAccumulation.Amount;
                        end;
                    StatReportTableMapping."Int. Source Type"::"Tax Difference":
                        begin
                            TaxCalcAccumulation.SetRange("Section Code", StatReportTableMapping."Int. Source Section Code");
                            TaxCalcAccumulation.SetRange("Register No.", StatReportTableMapping."Int. Source No.");
                            TaxCalcAccumulation.SetFilter("Starting Date", '%1..', StartDate);
                            TaxCalcAccumulation.SetFilter("Ending Date", '..%1', EndDate);
                            TaxCalcAccumulation.SetRange("Template Line No.", StatReportTableMapping."Internal Source Row No.");
                            if TaxCalcAccumulation.FindLast() then
                                CellValue := TaxCalcAccumulation.Amount;
                        end;
                end;

                CellValue := AdjustByOKEI(
                    DataHeaderNo,
                    TableCode,
                    RowNo,
                    ColumnNo,
                    CellValue);

                StatutoryReportDataValue.AddValue(
                  DataHeaderNo,
                  ReportCode,
                  TableCode,
                  SheetName,
                  RowNo,
                  ColumnNo,
                  Format(CellValue));
            end;
    end;

    [Scope('OnPrem')]
    procedure ImportDataFromExcel(DataHeaderNo: Code[20])
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        StatutoryReportTable: Record "Statutory Report Table";
        SectionCellNameBuffer: Record "Statutory Report Buffer" temporary;
        SheetNames: DotNet ArrayList;
        SheetName: Text[250];
        Window: Dialog;
        SectionName: Text[250];
        ErrorMessage: Text[250];
        FileName: Text;
    begin
        Window.Open(Text010);

        FillSectionCellNameBuffer(SectionCellNameBuffer);

        FileName := FileMgt.UploadFile('Import Excel File', '.xlsx');
        FileMgt.IsAllowedPath(FileName, false);
        XlWrkBkReader := XlWrkBkReader.Open(FileName);
        SheetNames := SheetNames.ArrayList(XlWrkBkReader.SheetNames());

        if IsNull(SheetNames) then
            exit;

        i := 0;
        EndOfLoop := SheetNames.Count();
        while i <= EndOfLoop - 1 do begin
            SheetName := SheetNames.Item(i);
            XlWrkShtReader := XlWrkBkReader.GetWorksheetByName(SheetName);

            StatutoryReportTable.Reset();
            StatutoryReportTable.SetRange("Report Code", Code);
            StatutoryReportTable.SetRange("Excel Sheet Name", XlWrkShtReader.Name);
            if StatutoryReportTable.FindSet() then
                repeat
                    TempExcelBuffer.OpenBook(FileName, XlWrkShtReader.Name);
                    TempExcelBuffer.ReadSheet();
                    if not StatutoryReportTable.ImportExcelSheet(DataHeaderNo, TempExcelBuffer, XlWrkShtReader.Name, ErrorMessage) then
                        ErrorExcelProcessing(ErrorMessage);
                until StatutoryReportTable.Next() = 0
            else begin
                SectionName := FindSectionName(SectionCellNameBuffer, TempExcelBuffer);
                if SectionName <> '' then begin
                    StatutoryReportTable.SetRange("Excel Sheet Name");
                    StatutoryReportTable.SetRange("Page Indication Text", SectionName);
                    if StatutoryReportTable.FindSet() then
                        repeat
                            if StatutoryReportTable.CheckTableIdentText(TempExcelBuffer) then
                                if not StatutoryReportTable.ImportExcelSheet(DataHeaderNo, TempExcelBuffer, XlWrkShtReader.Name, ErrorMessage) then
                                    ErrorExcelProcessing(ErrorMessage);
                        until StatutoryReportTable.Next() = 0;
                end;
            end;

            i := i + 1;
        end;

        Window.Close();
        CloseBook();
    end;

    [Scope('OnPrem')]
    procedure CloseBook()
    begin
        if not IsNull(XlWrkBkWriter) then begin
            XlWrkBkWriter.ClearFormulaCalculations();
            XlWrkBkWriter.ValidateDocument();
            XlWrkBkWriter.Close();
            Clear(XlWrkShtWriter);
            Clear(XlWrkBkWriter);
        end;

        if not IsNull(XlWrkBkReader) then begin
            Clear(XlWrkShtReader);
            Clear(XlWrkBkReader);
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyReport()
    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportTable: Record "Statutory Report Table";
        StatutoryReportTableFrom: Record "Statutory Report Table";
        XMLElementLine: Record "XML Element Line";
        XMLElementLineFrom: Record "XML Element Line";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        StatReportTableMappingFrom: Record "Stat. Report Table Mapping";
        CopyReportStructure: Page "Copy Statutory Report";
        CopyReportFromCode: Code[20];
    begin
        CopyReportStructure.SetParameters(Code);
        if CopyReportStructure.RunModal() <> ACTION::OK then
            exit;

        CopyReportStructure.GetParameters(CopyReportFromCode);
        if CopyReportFromCode = '' then
            Error(Text011);

        StatutoryReportTable.SetRange("Report Code", Code);
        if not StatutoryReportTable.IsEmpty() then
            if Confirm(Text003, false, Code) then
                StatutoryReportTable.DeleteAll(true)
            else
                Error('');

        XMLElementLine.SetRange("Report Code", Code);
        if not XMLElementLine.IsEmpty() then
            if Confirm(Text029, false, Code) then
                XMLElementLine.DeleteAll(true)
            else
                Error('');

        StatutoryReport.Get(CopyReportFromCode);
        "Format Version Code" := StatutoryReport."Format Version Code";
        Description := StatutoryReport.Description;
        "Group Code" := StatutoryReport."Group Code";
        "Sender No." := StatutoryReport."Sender No.";
        "Report Type" := StatutoryReport."Report Type";
        Active := StatutoryReport.Active;
        "Ending Date" := StatutoryReport."Ending Date";
        "Starting Date" := StatutoryReport."Starting Date";
        "Recipient Tax Authority Code" := StatutoryReport."Recipient Tax Authority Code";
        "Recipient Tax Authority SONO" := StatutoryReport."Recipient Tax Authority SONO";
        "Admin. Tax Authority Code" := StatutoryReport."Admin. Tax Authority Code";
        "Admin. Tax Authority SONO" := StatutoryReport."Admin. Tax Authority SONO";
        Header := StatutoryReport.Header;
        Modify();

        StatutoryReportTableFrom.SetRange("Report Code", CopyReportFromCode);
        if StatutoryReportTableFrom.FindSet() then
            repeat
                StatutoryReportTable := StatutoryReportTableFrom;
                StatutoryReportTable."Report Code" := Code;
                StatutoryReportTable.Insert();
                StatutoryReportTable.CopyTableStructure(CopyReportFromCode, StatutoryReportTableFrom.Code);
            until StatutoryReportTableFrom.Next() = 0;

        XMLElementLineFrom.SetRange("Report Code", CopyReportFromCode);
        if XMLElementLineFrom.FindSet() then
            repeat
                XMLElementLine := XMLElementLineFrom;
                XMLElementLine."Report Code" := Code;
                XMLElementLine.Insert();
                XMLElementLine.CopyElement(CopyReportFromCode);
            until XMLElementLineFrom.Next() = 0;

        StatReportTableMappingFrom.SetRange("Report Code", CopyReportFromCode);
        if StatReportTableMappingFrom.FindSet() then
            repeat
                StatReportTableMapping := StatReportTableMappingFrom;
                StatReportTableMapping."Report Code" := Code;
                StatReportTableMapping.Insert();
            until StatReportTableMappingFrom.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ErrorExcelProcessing(ErrorMessage: Text[250])
    begin
        CloseBook();
        Error(ErrorMessage);
    end;

    [Scope('OnPrem')]
    procedure FillSectionCellNameBuffer(var SectionCellNameBuffer: Record "Statutory Report Buffer")
    var
        StatutoryReportTable: Record "Statutory Report Table";
        EntryNo: Integer;
    begin
        StatutoryReportTable.SetRange("Report Code", Code);
        if StatutoryReportTable.FindSet() then
            repeat
                if StatutoryReportTable."Scalable Table" or StatutoryReportTable."Multipage Table" then begin
                    StatutoryReportTable.TestField("Page Indic. Excel Cell Name");
                    SectionCellNameBuffer.SetRange("Section Excel Cell Name", StatutoryReportTable."Page Indic. Excel Cell Name");
                    if not SectionCellNameBuffer.FindFirst() then begin
                        EntryNo := EntryNo + 1;
                        SectionCellNameBuffer."Entry No." := EntryNo;
                        SectionCellNameBuffer."Section Excel Cell Name" := StatutoryReportTable."Page Indic. Excel Cell Name";
                        SectionCellNameBuffer.Insert();
                    end;
                end;
            until StatutoryReportTable.Next() = 0;

        SectionCellNameBuffer.Reset();
    end;

    [Scope('OnPrem')]
    procedure FindSectionName(var SectionCellNameBuffer: Record "Statutory Report Buffer"; var TempExcelBuffer: Record "Excel Buffer" temporary) SectionName: Text[250]
    var
        StatutoryReportTable: Record "Statutory Report Table";
    begin
        SectionCellNameBuffer.Reset();
        StatutoryReportTable.SetRange("Report Code", Code);
        if SectionCellNameBuffer.FindSet() then
            repeat
                SectionName :=
                  CopyStr(TempExcelBuffer.GetValueByCellName(SectionCellNameBuffer."Section Excel Cell Name"), 1, MaxStrLen(SectionName));
                if SectionName <> '' then begin
                    StatutoryReportTable.SetRange("Page Indication Text", SectionName);
                    if StatutoryReportTable.FindFirst() then
                        exit;
                end;
            until SectionCellNameBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportExcelSheetNames()
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        SheetNames: DotNet ArrayList;
        SheetName: Text[250];
        FileName: Text[1024];
    begin
        FormatVersion.Get("Format Version Code");
        if FormatVersion."Excel File Name" = '' then
            exit;

        FormatVersion.CalcFields("Report Template");
        TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("Report Template"));
        FileName := FileMgt.ServerTempFileName('xlsx');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);

        StatReportExcelSheet.SetRange("Report Code", Code);
        StatReportExcelSheet.SetRange("Report Data No.", '');
        if not StatReportExcelSheet.IsEmpty() then
            if not Confirm(Text028, false) then
                Error('');
        StatReportExcelSheet.DeleteAll();

        FileMgt.IsAllowedPath(FileName, false);
        XlWrkBkReader := XlWrkBkReader.Open(FileName);
        SheetNames := SheetNames.ArrayList(XlWrkBkReader.SheetNames());

        if IsNull(SheetNames) then
            exit;

        i := 0;
        EndOfLoop := SheetNames.Count();
        while i <= EndOfLoop - 1 do begin
            SheetName := SheetNames.Item(i);
            XlWrkShtReader := XlWrkBkReader.GetWorksheetByName(SheetName);

            if SheetName <> '' then begin
                StatReportExcelSheet."Report Code" := Code;
                StatReportExcelSheet."Report Data No." := '';
                StatReportExcelSheet."Sequence No." := i;
                StatReportExcelSheet."Sheet Name" := XlWrkShtReader.Name;
                StatReportExcelSheet.Insert();
            end;

            i := i + 1;
        end;
        CloseBook();
    end;

    [Scope('OnPrem')]
    procedure LookupExcelSheetNames(var ExcelSheetName: Text[250])
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        SelectExcelSheetName: Page "Select Excel Sheet Name";
    begin
        StatReportExcelSheet.FilterGroup(2);
        StatReportExcelSheet.SetRange("Report Code", Code);
        StatReportExcelSheet.SetRange("Report Data No.", '');
        StatReportExcelSheet.FilterGroup(0);
        if ExcelSheetName <> '' then begin
            StatReportExcelSheet.SetRange("Sheet Name", ExcelSheetName);
            if StatReportExcelSheet.FindFirst() then;
            StatReportExcelSheet.SetRange("Sheet Name");
            SelectExcelSheetName.SetRecord(StatReportExcelSheet);
        end;
        SelectExcelSheetName.SetTableView(StatReportExcelSheet);
        SelectExcelSheetName.LookupMode := true;
        if SelectExcelSheetName.RunModal() = ACTION::LookupOK then begin
            SelectExcelSheetName.GetRecord(StatReportExcelSheet);
            ExcelSheetName := StatReportExcelSheet."Sheet Name";
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportXMLSchema()
    var
        XMLElementLine: Record "XML Element Line";
        FormatVersion: Record "Format Version";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDoc: DotNet XmlDocument;
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        InStr: InStream;
        FileName: Text[250];
    begin
        FormatVersion.Get("Format Version Code");
        if FormatVersion."XML Schema File Name" = '' then
            exit;

        XMLElementLine.SetRange("Report Code", Code);
        XMLElementLine.DeleteAll();

        FormatVersion.CalcFields("XML Schema");
        TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("XML Schema"));
        FileName := FileMgt.ServerTempFileName('xml');
        FileMgt.BLOBExportToServerFile(TempBlob, FileName);

        TempBlob.CreateInStream(InStr);
        XMLDOMManagement.LoadXMLDocumentFromInStream(InStr, XmlDoc);

        RootNode := XmlDoc.DocumentElement;
        if ExtractPrefix(RootNode.Name) <> 'schema' then
            Error(Text023, FileName);

        NodeList := RootNode.ChildNodes;
        i := 0;
        repeat
            ChildNode := NodeList.Item(i);
            i += 1;
        until (i = NodeList.Count) or (ExtractPrefix(ChildNode.Name) = 'element');

        ParseNode(ChildNode, 0, 0, false);
    end;

    [Scope('OnPrem')]
    procedure ParseNode(Node: DotNet XmlNode; ParentEntryNo: Integer; IndentNo: Integer; Choice: Boolean)
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ElementName: Text[150];
        TypeName: Text[100];
        RefName: Text[100];
        i: Integer;
        EntryNo: Integer;
        ChoiceNode: Boolean;
        ElementType: Option Complex,Simple;
    begin
        case ExtractPrefix(Node.Name) of
            'element':
                begin
                    if GetAttribute(Node, 'name', ElementName) then begin
                        ElementType := GetElementType(Node);

                        EntryNo := AddSchemaLine(
                            Node,
                            ParentEntryNo,
                            ElementName,
                            ElementType,
                            IndentNo,
                            Choice);

                        if GetAttribute(Node, 'type', TypeName) and (ElementType = ElementType::Complex) then
                            ParseType(TypeName, EntryNo, IndentNo, Choice);
                    end;

                    if GetAttribute(Node, 'ref', RefName) then
                        ParseRef(RefName, ParentEntryNo, IndentNo - 1);
                end;
            'attribute':
                if GetAttribute(Node, 'name', ElementName) then
                    EntryNo := AddSchemaLine(
                        Node,
                        ParentEntryNo,
                        ElementName,
                        2,
                        IndentNo,
                        Choice);
            'choice':
                ChoiceNode := true;
        end;

        if ElementName <> '' then begin
            ParentEntryNo := EntryNo;
            IndentNo := IndentNo + 1;
        end;

        NodeList := Node.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            ParseNode(ChildNode, ParentEntryNo, IndentNo, ChoiceNode);
        end;
    end;

    [Scope('OnPrem')]
    procedure ParseType(TypeName: Text[100]; ParentEntryNo: Integer; IndentNo: Integer; Choice: Boolean)
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ElementName: Text[150];
        i: Integer;
    begin
        NodeList := RootNode.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) in ['complexType', 'simpleType'] then
                if GetAttribute(ChildNode, 'name', ElementName) then
                    if ElementName = TypeName then
                        case ExtractPrefix(ChildNode.Name) of
                            'complexType':
                                ParseNode(ChildNode, ParentEntryNo, IndentNo + 1, false);
                            'simpleType':
                                AddSchemaLine(
                                  ChildNode,
                                  ParentEntryNo,
                                  ElementName,
                                  1,
                                  IndentNo,
                                  Choice);
                        end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ParseRef(RefName: Text[100]; ParentEntryNo: Integer; IndentNo: Integer)
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ElementName: Text[150];
        i: Integer;
    begin
        NodeList := RootNode.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) = 'element' then
                if GetAttribute(ChildNode, 'name', ElementName) then
                    if ElementName = RefName then
                        ParseNode(ChildNode, ParentEntryNo, IndentNo + 1, false);
        end;
    end;

    [Scope('OnPrem')]
    procedure AddSchemaLine(Node: DotNet XmlNode; ParentEntryNo: Integer; ElementName: Text[150]; ElementType: Option Complex,Simple,Attribute; IndentNo: Integer; Choice: Boolean): Integer
    var
        XMLElementLine: Record "XML Element Line";
        ParentXMLElementLine: Record "XML Element Line";
        TypeName: Text[100];
        Use: Text[100];
        DataType: Option " ",Text,"Integer",Decimal,Date;
        FractionDigits: Integer;
    begin
        LineNo := LineNo + 10000;

        XMLElementLine."Report Code" := Code;
        XMLElementLine."Line No." := LineNo;
        XMLElementLine."Parent Line No." := ParentEntryNo;
        if ParentXMLElementLine.Get(Code, ParentEntryNo) then
            XMLElementLine."Parent Element Name" := ParentXMLElementLine."Element Name";
        XMLElementLine."Element Name" := ElementName;
        XMLElementLine."Element Type" := ElementType;
        if ElementType in [ElementType::Simple, ElementType::Attribute] then
            XMLElementLine."Link Type" := XMLElementLine."Link Type"::Value;
        XMLElementLine.Indentation := IndentNo;
        XMLElementLine."Sequence No." := SequenceNo;
        XMLElementLine.Description := GetNodeDescription(Node);
        XMLElementLine.Choice := Choice;
        if GetAttribute(Node, 'use', Use) then
            case Use of
                'required':
                    XMLElementLine."Export Type" := XMLElementLine."Export Type"::Required;
                'optional':
                    XMLElementLine."Export Type" := XMLElementLine."Export Type"::Optional;
            end
        else
            XMLElementLine."Export Type" := XMLElementLine."Export Type"::Optional;

        if ElementType in [ElementType::Simple, ElementType::Attribute] then
            // look for the type in the current node
            if GetNodeType(Node, DataType, FractionDigits) then
                XMLElementLine."Data Type" := DataType
            else
                if GetAttribute(Node, 'type', TypeName) then
                    // look through the list of simple types
                    if GetNodeType2(TypeName, DataType, FractionDigits) then
                        XMLElementLine."Data Type" := DataType;
        XMLElementLine."Fraction Digits" := FractionDigits;
        XMLElementLine.Insert();

        SequenceNo := SequenceNo + 1;

        exit(XMLElementLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure GetNodeDescription(Node: DotNet XmlNode): Text[250]
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        AnnotationNode: DotNet XmlNode;
        i: Integer;
    begin
        NodeList := Node.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) = 'annotation' then begin
                AnnotationNode := ChildNode.FirstChild;
                if not IsNull(AnnotationNode) then
                    exit(CopyStr(AnnotationNode.InnerText, 1, MaxStrLen(Description)));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetNodeType(Node: DotNet XmlNode; var DataType: Option " ",Text,"Integer",Decimal,Date; var FractionDigits: Integer): Boolean
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ElementName: Text[150];
        ElementType: Text[100];
        Base: Text[100];
        i: Integer;
    begin
        if GetAttribute(Node, 'name', ElementName) then
            if ElementName = '´Š¢´Š¢ÔáÆ´Š¢´Š¢' then begin
                DataType := DataType::Date;
                exit(true);
            end;

        if GetAttribute(Node, 'type', ElementType) then
            if ExtractPrefix(ElementType) in ['gYear', 'restriction', 'string'] then begin
                DataType := DataType::Text;
                exit(true);
            end;

        NodeList := Node.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) = 'restriction' then begin
                if GetAttribute(ChildNode, 'base', Base) then
                    case ExtractPrefix(Base) of
                        'string',
                        'gYear':
                            begin
                                DataType := DataType::Text;
                                exit(true);
                            end;
                        'integer',
                        'unsignedLong',
                        'positiveInteger':
                            begin
                                DataType := DataType::Integer;
                                exit(true);
                            end;
                        'decimal':
                            begin
                                DataType := DataType::Decimal;
                                if GetFractionDigits(ChildNode, FractionDigits) then
                                    exit(true);
                            end;
                        else
                            // look through the list of simple types
                            if GetNodeType2(Base, DataType, FractionDigits) then
                                exit(true);
                    end;
            end else
                if GetNodeType(ChildNode, DataType, FractionDigits) then
                    exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetNodeType2(TypeName: Text[100]; var DataType: Option " ",Text,"Integer",Decimal,Date; var FractionDigits: Integer): Boolean
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ChildNodeName: Text[100];
        i: Integer;
    begin
        NodeList := RootNode.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) = 'simpleType' then
                if GetAttribute(ChildNode, 'name', ChildNodeName) then
                    if ChildNodeName = TypeName then
                        if GetNodeType(ChildNode, DataType, FractionDigits) then
                            exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetFractionDigits(Node: DotNet XmlNode; var FractionDigits: Integer): Boolean
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        Value: Text[100];
        i: Integer;
    begin
        NodeList := Node.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if ExtractPrefix(ChildNode.Name) = 'fractionDigits' then
                if GetAttribute(ChildNode, 'value', Value) then
                    if Evaluate(FractionDigits, Value) then
                        exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetAttribute(var XMLNode: DotNet XmlNode; AttributeName: Text[250]; var AttributeValue: Text[250]): Boolean
    var
        XMLAttribute: DotNet XmlAttribute;
    begin
        XMLAttribute := XMLNode.SelectSingleNode(StrSubstNo('@%1', AttributeName));

        if IsNull(XMLAttribute) then
            exit(false);

        AttributeValue := XMLAttribute.Value();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure AdjustByOKEI(DataHeaderNo: Code[20]; TableCode: Code[20]; RowNo: Integer; ColumnNo: Integer; Amount: Decimal): Decimal
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        XMLElementLine: Record "XML Element Line";
        OKEIScaling: Boolean;
    begin
        StatutoryReportDataHeader.Get(DataHeaderNo);

        XMLElementLine.SetCurrentKey("Report Code", "Table Code", "Row Link No.", "Column Link No.");
        XMLElementLine.SetRange("Report Code", Code);
        XMLElementLine.SetRange("Table Code", TableCode);
        XMLElementLine.SetRange("Row Link No.", RowNo);
        XMLElementLine.SetRange("Column Link No.", ColumnNo);
        if XMLElementLine.FindFirst() then
            OKEIScaling := XMLElementLine."OKEI Scaling";

        if OKEIScaling then
            case StatutoryReportDataHeader.OKEI of
                '383':
                    exit(Round(Amount, 1));
                '384':
                    exit(Round(Amount / 1000, 1));
                '385':
                    exit(Round(Amount / 1000000, 1));
            end;

        exit(Amount);
    end;

    [Scope('OnPrem')]
    procedure CheckServiceTier()
    begin
        Error(Text032);
    end;

    [Scope('OnPrem')]
    procedure GetElementType(Node: DotNet XmlNode): Integer
    var
        NodeList: DotNet XmlNodeList;
        ChildNode: DotNet XmlNode;
        ElementName: Text[150];
        TypeName: Text[100];
        i: Integer;
        ElementType: Option Complex,Simple;
    begin
        if GetAttribute(Node, 'type', TypeName) then begin
            NodeList := RootNode.ChildNodes;
            for i := 0 to NodeList.Count - 1 do begin
                ChildNode := NodeList.Item(i);
                if ExtractPrefix(ChildNode.Name) in ['complexType', 'simpleType'] then
                    if GetAttribute(ChildNode, 'name', ElementName) then
                        if ElementName = TypeName then
                            case ExtractPrefix(ChildNode.Name) of
                                'complexType':
                                    exit(ElementType::Complex);
                                'simpleType':
                                    exit(ElementType::Simple);
                            end;
            end;
        end else begin
            NodeList := Node.ChildNodes;
            for i := 0 to NodeList.Count - 1 do begin
                ChildNode := NodeList.Item(i);
                if ExtractPrefix(ChildNode.Name) in ['complexType', 'simpleType'] then
                    case ExtractPrefix(ChildNode.Name) of
                        'complexType':
                            exit(ElementType::Complex);
                        'simpleType':
                            exit(ElementType::Simple);
                    end;
            end;
        end;

        exit(ElementType::Simple);
    end;

    [Scope('OnPrem')]
    procedure ExtractPrefix(ElementName: Text[150]): Text[100]
    begin
        if CopyStr(LowerCase(ElementName), 1, 3) = 'xs:' then
            exit(CopyStr(ElementName, 4));
        if CopyStr(LowerCase(ElementName), 1, 4) = 'xsd:' then
            exit(CopyStr(ElementName, 5));

        exit(ElementName);
    end;

    local procedure ConfirmImportXMLSchema(): Boolean
    var
        XMLElementLine: Record "XML Element Line";
    begin
        XMLElementLine.SetRange("Report Code", Code);
        if not XMLElementLine.IsEmpty() then
            exit(Confirm(Text026, false));

        exit(true);
    end;
}

