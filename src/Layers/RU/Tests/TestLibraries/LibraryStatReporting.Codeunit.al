codeunit 143014 "Library - Stat. Reporting"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Scope('OnPrem')]
    procedure CreateStatutoryReport(var StatutoryReport: Record "Statutory Report")
    begin
        StatutoryReport.Init();
        StatutoryReport.Validate(Code, LibraryUtility.GenerateRandomCode(StatutoryReport.FieldNo(Code), DATABASE::"Statutory Report"));
        StatutoryReport.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateStatutoryReportData(var StatutoryReport: Record "Statutory Report")
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        AccountingPeriod: Record "Accounting Period";
        StartDate: Date;
        EndDate: Date;
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, true);
        AccountingPeriod.FindLast();
        StartDate := AccountingPeriod."Starting Date";
        EndDate := CalcDate('<CY>', StartDate);
        StatutoryReportDataHeader.CreateReportHeader(
          StatutoryReport, EndDate, StartDate, EndDate, 0, 0, 0, 'Test', 3, '46', '2016');
        StatutoryReport.CreateReportData(StatutoryReportDataHeader."No.", StartDate, EndDate, 0); // From database
    end;

    [Scope('OnPrem')]
    procedure CreateXMLElementLine(var XMLElementLine: Record "XML Element Line"; ReportCode: Code[20]; SourceType: Option; LineValue: Text[250]): Integer
    var
        RecRef: RecordRef;
    begin
        XMLElementLine.Init();
        XMLElementLine."Report Code" := ReportCode;
        RecRef.GetTable(XMLElementLine);
        XMLElementLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, XMLElementLine.FieldNo("Line No."));
        XMLElementLine."Source Type" := SourceType;
        XMLElementLine."Data Type" := XMLElementLine."Data Type"::Integer;
        XMLElementLine.Value := LineValue;
        XMLElementLine.Insert();
        exit(XMLElementLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure CreateXMLElementExpressionLine(ReportCode: Code[20]; BaseXMLElementLineNo: Integer; ChildXMLElementLineNo: Integer)
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        RecRef: RecordRef;
    begin
        XMLElementExpressionLine.Init();
        XMLElementExpressionLine."Report Code" := ReportCode;
        XMLElementExpressionLine."Base XML Element Line No." := BaseXMLElementLineNo;
        RecRef.GetTable(XMLElementExpressionLine);
        XMLElementExpressionLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, XMLElementExpressionLine.FieldNo("Line No."));
        XMLElementExpressionLine."XML Element Line No." := ChildXMLElementLineNo;
        XMLElementExpressionLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ReleaseStatutoryReportDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    var
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        StatutoryReportMgt.ReleaseDataHeader(StatutoryReportDataHeader);
    end;

    [Scope('OnPrem')]
    procedure ReopenStatutoryReportDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    var
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        StatutoryReportMgt.ReopenDataHeader(StatutoryReportDataHeader);
    end;
}

