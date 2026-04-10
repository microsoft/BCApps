#pragma warning disable AA0247
table 26563 "Statutory Report Data Header"
{
    Caption = 'Statutory Report Data Header';
    LookupPageID = "Report Data List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            NotBlank = true;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(3; "Date Filter"; Text[30])
        {
            Caption = 'Date Filter';
            Editable = false;
        }
        field(6; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(8; "Document Type"; Code[3])
        {
            Caption = 'Document Type';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(9; "Correction Number"; Integer)
        {
            Caption = 'Correction Number';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(12; "Dimension 1 Filter"; Text[50])
        {
            Caption = 'Dimension 1 Filter';
        }
        field(13; "Dimension 2 Filter"; Text[50])
        {
            Caption = 'Dimension 2 Filter';
        }
        field(14; "Dimension 3 Filter"; Text[50])
        {
            Caption = 'Dimension 3 Filter';
        }
        field(15; "Dimension 4 Filter"; Text[50])
        {
            Caption = 'Dimension 4 Filter';
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(21; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(23; OKEI; Code[3])
        {
            Caption = 'OKEI';
            Editable = false;
        }
        field(24; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released,Sent';
            OptionMembers = Open,Released,Sent;
        }
        field(25; "No. in Year"; Code[8])
        {
            Caption = 'No. in Year';
            Numeric = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(32; "Requisites Quantity"; Integer)
        {
            Caption = 'Requisites Quantity';
            FieldClass = FlowField;
        }
        field(33; "Set Requisites Quantity"; Integer)
        {
            Caption = 'Set Requisites Quantity';
            FieldClass = FlowField;
        }
        field(34; Period; Text[30])
        {
            Caption = 'Period';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(35; "Report Type"; Code[1])
        {
            Caption = 'Report Type';
        }
        field(36; "Period Year"; Code[4])
        {
            Caption = 'Period Year';
            Numeric = true;
        }
        field(37; "Period Type"; Code[2])
        {
            Caption = 'Period Type';
            Numeric = true;

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(38; "Period No."; Code[3])
        {
            Caption = 'Period No.';

            trigger OnValidate()
            begin
                TestField(Status, Status::Open);
            end;
        }
        field(39; "Start Period Date"; Date)
        {
            Caption = 'Start Period Date';
        }
        field(40; "End Period Date"; Date)
        {
            Caption = 'End Period Date';
        }
        field(41; "Creation Day"; Code[2])
        {
            Caption = 'Creation Day';
        }
        field(42; "Creation Month No."; Code[2])
        {
            Caption = 'Creation Month No.';
        }
        field(43; "Creation Month in Words"; Text[20])
        {
            Caption = 'Creation Month in Words';
        }
        field(44; "Creation Year"; Code[2])
        {
            Caption = 'Creation Year';
        }
        field(45; "Creation Date Code"; Code[8])
        {
            Caption = 'Creation Date Code';
        }
        field(50; "GUID Value"; Code[36])
        {
            Caption = 'GUID Value';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Period Year", "No. in Year")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        ScalableTableRow: Record "Scalable Table Row";
    begin
        TestField(Status, Status::Open);

        StatutoryReportDataValue.SetRange("Report Data No.", "No.");
        if StatutoryReportDataValue.FindFirst() then
            StatutoryReportDataValue.DeleteAll();

        StatReportDataChangeLog.SetRange("Report Data No.", "No.");
        if StatReportDataChangeLog.FindFirst() then
            StatReportDataChangeLog.DeleteAll();

        StatReportExcelSheet.SetRange("Report Code", "Report Code");
        StatReportExcelSheet.SetRange("Report Data No.", "No.");
        StatReportExcelSheet.DeleteAll();

        ScalableTableRow.SetRange("Report Code", "Report Code");
        ScalableTableRow.SetRange("Report Data No.", "No.");
        ScalableTableRow.DeleteAll();
    end;

    trigger OnInsert()
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        NoSeries: Codeunit "No. Series";
        NoInYear: Integer;
    begin
        if "No." = '' then begin
            SRSetup.Get();
            SRSetup.TestField("Report Data Nos");
            "No." := NoSeries.GetNextNo(SRSetup."Report Data Nos");
        end;

        StatutoryReportDataHeader.SetCurrentKey("Period Year", "No. in Year");
        StatutoryReportDataHeader.SetRange("Period Year", "Period Year");
        if StatutoryReportDataHeader.FindLast() then;
        if Evaluate(NoInYear, StatutoryReportDataHeader."No. in Year") then;
        "No. in Year" := Format(NoInYear + 1, 8, '<integer,8><Filler Character,0>');

        "GUID Value" := CopyStr(Format(CreateGuid()), 2, 36);
    end;

    var
        CompInfo: Record "Company Information";
        SRSetup: Record "Statutory Report Setup";
        StatutoryReport: Record "Statutory Report";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
        WorkbookSheetBuffer: Record "Statutory Report Buffer" temporary;
        FormatVersion: Record "Format Version";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
#pragma warning disable AA0074
        Text002: Label 'You must specify the File Name.';
#pragma warning restore AA0074
        ReportFile: File;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label 'Export to Excel\Processing sheet #1##############\Sheet progress   @2@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text012: Label 'Opening workbook';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text013: Label 'Value of the %1 cannot be empty.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text014: Label 'XML file is verified.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text015: Label 'Data has been successfully updated.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text016: Label 'Report %1 does not have linked internal data sources.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Export';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text009: Label 'All Files (*.*)|*.*';
#pragma warning restore AA0074
        [WithEvents]
        XmlReaderSettings: DotNet XmlReaderSettings;
        XlWrkBkWriter: DotNet WorkbookWriter;
        XlWrkBkReader: DotNet WorkbookReader;
        XlWrkShtReader: DotNet WorksheetReader;
        ServerFileName: Text;
        TestMode: Boolean;
        ExcelFilesFilterTxt: Label 'Excel Files (*.xlsx;)|*.xlsx;', Comment = '{Split=r''\|''}{Locked=s''1''}';

    [Scope('OnPrem')]
    procedure CreateReportHeader(StatutoryReport: Record "Statutory Report"; CreationDate: Date; StartDate: Date; EndDate: Date; DocumentType: Option Primary,Correction; OKEIType: Option "383","384","385"; CorrNumber: Integer; DataDescription: Text[250]; PeriodNo: Integer; PeriodType: Code[2]; PeriodName: Text[30])
    var
        LocalisationMgt: Codeunit "Localisation Management";
    begin
        Init();
        "Report Code" := StatutoryReport.Code;
        if StartDate = EndDate then
            "Date Filter" := Format(StartDate)
        else
            "Date Filter" := StrSubstNo('%1..%2', StartDate, EndDate);
        Description := DataDescription;
        "User ID" := UserId;
        case DocumentType of
            DocumentType::Primary:
                "Document Type" := '0';
            DocumentType::Correction:
                "Document Type" := Format(CorrNumber);
        end;

        "Correction Number" := CorrNumber;
        "Creation Date" := CreationDate;
        "Start Period Date" := StartDate;
        "End Period Date" := EndDate;
        "Period Type" := PeriodType;
        if PeriodNo <> 0 then
            "Period No." := Format(PeriodNo, 2, '<Integer,2><Filler Character,0>');
        if StatutoryReport."Report Type" <> StatutoryReport."Report Type"::" " then
            "Report Type" := Format("Report Type", 1, 2);
        "Period Year" := Format(StartDate, 0, '<Year4>');
        "Creation Day" := Format(CreationDate, 0, '<Day,2><Filler Character,0>');
        "Creation Month No." := Format(CreationDate, 0, '<Month,2><Filler Character,0>');
        "Creation Month in Words" := CopyStr(LocalisationMgt.Month2Text(CreationDate), 1, MaxStrLen("Creation Month in Words"));
        "Creation Year" := Format(CreationDate, 0, '<Year><Filler Character,0>');
        "Creation Date Code" := Format(CreationDate, 0, '<Year4><Month,2><Day,2><Filler Character,0>');
        OKEI := Format(OKEIType);
        Period := PeriodName;
        Insert(true);
    end;

    procedure ExportResultsToExcel()
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        ReportSheetBuffer: Record "Statutory Report Buffer" temporary;
        XMLElementValueBuffer: Record "Statutory Report Buffer" temporary;
        XMLElementLine: Record "XML Element Line";
        PageNumberElement: Record "XML Element Line";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        Window: Dialog;
        FileName: Text;
        ErrorMessage: Text[250];
        TotalElementsQty: Integer;
        Counter: Integer;
        PageNumberCellsQty: Integer;
        PageNumber: Integer;
        PageNumberValue: Code[20];
    begin
        TestField("Report Code");
        if Status = Status::Open then
            FieldError(Status);

        StatutoryReport.Get("Report Code");

        StatutoryReport.TestField("Format Version Code");
        FormatVersion.Get(StatutoryReport."Format Version Code");
        FormatVersion.TestField("Excel File Name");

        FormatVersion.CalcFields("Report Template");
        if FormatVersion."Report Template".HasValue() then begin
            FileName := FileMgt.ServerTempFileName('xlsx');
            if Exists(FileName) then
                Erase(FileName);
            TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("Report Template"));
            FileMgt.BLOBExportToServerFile(TempBlob, FileName);
            if FileName = '' then
                exit;
        end;

        Window.Open(Text012);

        CreateXMLElementValues(XMLElementValueBuffer);

        if FileName = '' then
            Error(Text002);

        FillWorkbookSheetBuffer(FileName);
        FillReportSheetBuffer(ReportSheetBuffer, XMLElementValueBuffer);

        ProcessReportExcelSheets(ReportSheetBuffer, FileName);
        FillWorkbookSheetBuffer(FileName);

        Window.Close();

        Window.Open(Text008);
        TempExcelBuffer.OpenBookForUpdate(FileName);

        ReportSheetBuffer.Reset();
        if ReportSheetBuffer.FindSet() then
            repeat
                TempExcelBuffer.DeleteAll();
                TempExcelBuffer.SetActiveWriterSheet(ReportSheetBuffer."Excel Sheet Name");

                Window.Update(1, ReportSheetBuffer."Excel Sheet Name");
                StatReportExcelSheet.Get("Report Code", '', '', ReportSheetBuffer."Parent Excel Sheet Name");

                if (StatReportExcelSheet."Page Number Excel Cell Name" <> '') and
                   ExcelSheetHasValues(XMLElementValueBuffer, ReportSheetBuffer."Excel Sheet Name")
                then begin
                    PageNumber := PageNumber + 1;
                    PageNumberElement."Excel Cell Name" := StatReportExcelSheet."Page Number Excel Cell Name";
                    PageNumberElement."Horizontal Cells Quantity" := StatReportExcelSheet."Page Number Horiz. Cells Qty";
                    PageNumberElement."Vertical Cells Quantity" := StatReportExcelSheet."Page Number Vertical Cells Qty";
                    PageNumberCellsQty :=
                      StatReportExcelSheet."Page Number Horiz. Cells Qty" *
                      StatReportExcelSheet."Page Number Vertical Cells Qty";
                    if PageNumberCellsQty > 1 then
                        PageNumberElement."Excel Mapping Type" := PageNumberElement."Excel Mapping Type"::"Multi-cell";
                    PageNumberValue :=
                      PadStr('', PageNumberCellsQty - StrLen(Format(PageNumber)), '0') +
                      Format(PageNumber);
                    PageNumberElement.ExportToExcel(TempExcelBuffer, PageNumberValue, ErrorMessage, PageNumberElement."Excel Cell Name");
                end;

                XMLElementValueBuffer.Reset();
                XMLElementValueBuffer.SetRange("Excel Sheet Name", ReportSheetBuffer."Excel Sheet Name");
                TotalElementsQty := XMLElementValueBuffer.Count();
                Counter := 0;
                if XMLElementValueBuffer.FindSet() then
                    repeat
                        XMLElementLine.Get("Report Code", XMLElementValueBuffer."XML Element Line No.");
                        if XMLElementLine."Excel Cell Name" <> '' then
                            if not XMLElementLine.ExportToExcel(
                                  TempExcelBuffer,
                                  XMLElementValueBuffer.Value,
                                  ErrorMessage,
                                  XMLElementValueBuffer."Excel Cell Name")
                            then
                                ErrorExcelProcessing(ErrorMessage, FileName);
                        Counter := Counter + 1;
                        Window.Update(2, Round(Counter / TotalElementsQty * 10000, 1));
                    until XMLElementValueBuffer.Next() = 0;

                TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer);
            until ReportSheetBuffer.Next() = 0;

        TempExcelBuffer.CloseBook();

        FileMgt.DownloadHandler(FileName, 'Export to Excel', '', ExcelFilesFilterTxt, FormatVersion."Excel File Name");

        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure ExportResultsToXML()
    var
        ExportLogEntry: Record "Export Log Entry";
        XMLElementLine: Record "XML Element Line";
        StatRepBuffer: Record "Statutory Report Buffer";
        ElementValueBuffer: Record "Statutory Report Buffer" temporary;
        XMLExcelReportsMgt: Codeunit "XML-Excel Reports Mgt.";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        XmlDoc: DotNet XmlDocument;
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text[250];
    begin
        TestField(Status, Status::Released);
        CompInfo.Get();
        StatutoryReport.Get("Report Code");
        FormatVersion.Get(StatutoryReport."Format Version Code");
        FormatVersion.TestField("XML File Name Element Name");

        XMLElementLine.SetRange("Report Code", "Report Code");
        XMLElementLine.SetRange("Element Name", FormatVersion."XML File Name Element Name");
        XMLElementLine.FindFirst();
        StatRepBuffer."Report Data No." := "No.";
        FileName := XMLElementLine.GetElementValue(StatRepBuffer);
        if FileName = '' then
            Error(Text013, XMLElementLine.GetRecordDescription());
        FileName := FileName + '.xml';

        ExportLogEntry."Report Code" := "Report Code";
        ExportLogEntry."Report Data No." := "No.";
        ExportLogEntry.Description := Description;
        ExportLogEntry.Year := Format("Creation Date", 4, '<Year4>');
        ExportLogEntry."Sender No." := StatutoryReport."Sender No.";
        ExportLogEntry.Insert(true);

        CreateXML(XmlDoc, ElementValueBuffer, StatRepBuffer);

        TempBlob.CreateOutStream(OutStr);
        XMLExcelReportsMgt.SaveXMLDocWithEncoding(OutStr, XmlDoc, 'windows-1251');

        if not TestMode then begin
            TempBlob.CreateInStream(InStr);
            DownloadFromStream(InStr, Text006, '', Text009, FileName);
        end else
            FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);

        RecordRef.GetTable(ExportLogEntry);
        TempBlob.ToRecordRef(RecordRef, ExportLogEntry.FieldNo("Exported File"));
        RecordRef.SetTable(ExportLogEntry);
        while StrPos(FileName, '\') <> 0 do
            FileName := CopyStr(FileName, StrPos(FileName, '\') + 1);
        ExportLogEntry."File Name" := FileName;
        ExportLogEntry.Modify();
        Status := Status::Sent;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure FindExcelSheet(ExcelSheetName: Text[50]) Found: Boolean
    begin
        WorkbookSheetBuffer.SetRange("Excel Sheet Name", ExcelSheetName);
        Found := WorkbookSheetBuffer.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure FillWorkbookSheetBuffer(FileName: Text)
    var
        SheetNames: DotNet ArrayList;
        i: Integer;
        EndOfLoop: Integer;
    begin
        XlWrkBkReader := XlWrkBkReader.Open(FileName);
        SheetNames := SheetNames.ArrayList(XlWrkBkReader.SheetNames());
        if IsNull(SheetNames) then
            exit;

        WorkbookSheetBuffer.Reset();
        WorkbookSheetBuffer.DeleteAll();
        i := 1;
        EndOfLoop := SheetNames.Count();
        while i <= EndOfLoop do begin
            XlWrkShtReader := XlWrkBkReader.GetWorksheetByName(SheetNames.Item(i - 1));
            WorkbookSheetBuffer."Entry No." := i;
            WorkbookSheetBuffer."Excel Sheet Name" := XlWrkShtReader.Name;
            WorkbookSheetBuffer.Insert();
            i := i + 1;
        end;

        XlWrkBkReader.Close();
    end;

    [Scope('OnPrem')]
    procedure ErrorExcelProcessing(ErrorMessage: Text[250]; FileName: Text)
    begin
        if Exists(FileName) then
            if Erase(FileName) then;
        Error(ErrorMessage);
    end;

    [Scope('OnPrem')]
    procedure FillReportSheetBuffer(var ReportSheetBuffer: Record "Statutory Report Buffer"; var XMLElementValueBuffer: Record "Statutory Report Buffer")
    begin
        XMLElementValueBuffer.Reset();
        XMLElementValueBuffer.SetFilter("Excel Sheet Name", '<>''''');
        XMLElementValueBuffer.SetFilter("Excel Cell Name", '<>''''');
        if XMLElementValueBuffer.FindSet() then
            repeat
                AddReportSheetBufferLine(
                  ReportSheetBuffer,
                  XMLElementValueBuffer."Excel Sheet Name",
                  XMLElementValueBuffer."Table Code");
            until XMLElementValueBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure AddReportSheetBufferLine(var ReportSheetBuffer: Record "Statutory Report Buffer"; ExcelSheetName: Text[30]; TableCode: Code[20])
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        EntryNo: Integer;
    begin
        ReportSheetBuffer.Reset();
        if ReportSheetBuffer.FindLast() then;
        EntryNo := ReportSheetBuffer."Entry No." + 1;

        ReportSheetBuffer.SetRange("Excel Sheet Name", ExcelSheetName);
        if ReportSheetBuffer.IsEmpty() then begin
            ReportSheetBuffer."Entry No." := EntryNo;
            ReportSheetBuffer."Table Code" := TableCode;
            ReportSheetBuffer."Excel Sheet Name" := ExcelSheetName;
            ReportSheetBuffer."Parent Excel Sheet Name" :=
              StatReportExcelSheet.GetParentExcelSheetName("Report Code", "No.", TableCode, ExcelSheetName);
            if ReportSheetBuffer."Parent Excel Sheet Name" = '' then
                ReportSheetBuffer."Parent Excel Sheet Name" := ReportSheetBuffer."Excel Sheet Name";
            ReportSheetBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessReportExcelSheets(var ReportSheetBuffer: Record "Statutory Report Buffer"; FileName: Text)
    begin
        ReportSheetBuffer.Reset();
        ReportSheetBuffer.SetFilter("Parent Excel Sheet Name", '<>''''');
        if ReportSheetBuffer.Find('+') then begin
            XlWrkBkWriter := XlWrkBkWriter.Open(FileName);
            repeat
                if not FindExcelSheet(ReportSheetBuffer."Excel Sheet Name") then
                    XlWrkBkWriter.CopySheet(
                      ReportSheetBuffer."Parent Excel Sheet Name", ReportSheetBuffer."Excel Sheet Name",
                      ReportSheetBuffer."Parent Excel Sheet Name", false);
            until ReportSheetBuffer.Next(-1) = 0;
            XlWrkBkWriter.Close();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetFileName() FileName: Text[250]
    var
        i: Integer;
    begin
        FileName := FormatVersion."Excel File Name";

        if StrPos(FileName, '.') <> 0 then begin
            i := StrLen(FileName);
            repeat
                i := i - 1;
            until (i = 1) or (FileName[i] = '.');
            FileName := "Report Code" + ' ' + Period + CopyStr(FileName, i);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateXMLElementValues(var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        StatRepBuffer: Record "Statutory Report Buffer";
        XmlDoc: DotNet XmlDocument;
    begin
        CompInfo.Get();
        SRSetup.Get();
        StatRepBuffer."Calculation Values Mode" := true;
        CreateXML(XmlDoc, ElementValueBuffer, StatRepBuffer);
    end;

    [Scope('OnPrem')]
    procedure CheckXML()
    var
        StatutoryReportBuffer: Record "Statutory Report Buffer";
        TempStatutoryReportBufferElementValue: Record "Statutory Report Buffer" temporary;
        TempNameValueBufferValidation: Record "Name/Value Buffer" temporary;
        XmlDoc: DotNet XmlDocument;
    begin
        StatutoryReportBuffer.Init();
        CreateXML(XmlDoc, TempStatutoryReportBufferElementValue, StatutoryReportBuffer);

        if not ValidateXMLFile(XmlDoc, TempNameValueBufferValidation) then begin
            // IF required to show page without extra buttons
            if PAGE.RunModal(PAGE::"Name/Value Lookup", TempNameValueBufferValidation) = ACTION::LookupOK then;
        end else
            Message(Text014);
    end;

    [Scope('OnPrem')]
    procedure CreateXML(var XmlDoc: DotNet XmlDocument; var ElementValueBuffer: Record "Statutory Report Buffer"; StatRepBuffer: Record "Statutory Report Buffer")
    var
        XMLElementLine: Record "XML Element Line";
        ProcInstr: DotNet XmlProcessingInstruction;
    begin
        XmlDoc := XmlDoc.XmlDocument();

        ProcInstr := XmlDoc.CreateProcessingInstruction('xml', ' version="1.0" encoding="windows-1251"');
        XmlDoc.AppendChild(ProcInstr);

        StatRepBuffer."Report Data No." := "No.";

        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");
        XMLElementLine.SetRange("Report Code", "Report Code");
        if XMLElementLine.FindFirst() then
            XMLElementLine.ExportValue(ProcInstr, StatRepBuffer, ElementValueBuffer);
    end;

    local procedure ValidateXMLFile(var XmlRequestDoc: DotNet XmlDocument; var TempNameValueBufferValidation: Record "Name/Value Buffer" temporary): Boolean
    var
        FormatVersion: Record "Format Version";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlValidationDoc: DotNet XmlDocument;
        XmlSchemaValidationFlags: DotNet XmlSchemaValidationFlags;
        ValidationType: DotNet ValidationType;
        FileName: Text;
        SchemaFileName: Text;
    begin
        TempNameValueBufferValidation.DeleteAll();

        StatutoryReport.Get("Report Code");
        StatutoryReport.TestField("Format Version Code");
        FormatVersion.Get(StatutoryReport."Format Version Code");
        FormatVersion.CalcFields("XML Schema");
        if not FormatVersion."XML Schema".HasValue() then
            exit(true);

        FileName := FileMgt.ServerTempFileName('xml');
        XmlRequestDoc.Save(FileName);

        TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("XML Schema"));
        SchemaFileName := FileMgt.ServerTempFileName('xsd');
        FileMgt.BLOBExportToServerFile(TempBlob, SchemaFileName);

        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.Schemas.Add('', SchemaFileName);
        XmlReaderSettings.ValidationFlags := XmlSchemaValidationFlags.ReportValidationWarnings;
        XmlReaderSettings.ValidationType := ValidationType.Schema;

        TempNameValueBuffer.DeleteAll();

        // The XmlDocument validates the XML document contained
        // in the XmlReader as it is loaded into the DOM.
        XMLDOMManagement.LoadXMLDocumentFromFileWithXmlReaderSettings(FileName, XmlValidationDoc, XmlReaderSettings);
        if TempNameValueBuffer.FindSet() then
            repeat
                TempNameValueBufferValidation := TempNameValueBuffer;
                TempNameValueBufferValidation.Insert();
            until TempNameValueBuffer.Next() = 0;

        FileMgt.DeleteServerFile(FileName);

        exit(TempNameValueBuffer.Count = 0);
    end;

    [Scope('OnPrem')]
    procedure UpdateData()
    begin
        TestField(Status, Status::Open);
        StatutoryReport.Get("Report Code");
        if StatutoryReport.CalculateDataFromIntSource("No.", "Start Period Date", "End Period Date") then
            Message(Text015)
        else
            Message(Text016, "Report Code");
    end;

    local procedure ExcelSheetHasValues(var XMLElementValueBuffer: Record "Statutory Report Buffer" temporary; ExcelSheetName: Text[30]): Boolean
    begin
        XMLElementValueBuffer.SetRange("Excel Sheet Name", ExcelSheetName);
        XMLElementValueBuffer.SetRange("Template Data", false);
        XMLElementValueBuffer.SetFilter(Value, '<>%1', '');
        exit(not XMLElementValueBuffer.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    [Scope('OnPrem')]
    procedure WriteLine(LineText: Text[1024])
    begin
        ReportFile.Write(LineText);
    end;

    trigger XmlReaderSettings::ValidationEventHandler(sender: Variant; e: DotNet ValidationEventArgs)
    begin
        TempNameValueBuffer.Init();
        TempNameValueBuffer.ID := TempNameValueBuffer.Count + 1;
        TempNameValueBuffer.Name := e.Severity.ToString();
        TempNameValueBuffer.Value := e.Message;
        TempNameValueBuffer.Insert();
    end;
}

