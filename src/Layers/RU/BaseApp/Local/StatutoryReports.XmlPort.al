#pragma warning disable AA0247
xmlport 26550 "Statutory Reports"
{
    Caption = 'Statutory Reports';

    schema
    {
        textelement(StatutoryReports)
        {
            tableelement("statutory report group"; "Statutory Report Group")
            {
                MinOccurs = Zero;
                XmlName = 'StatutoryReportGroup';
                UseTemporary = true;
                fieldelement(Code; "Statutory Report Group".Code)
                {
                }
                fieldelement(Description; "Statutory Report Group".Description)
                {
                }
            }
            tableelement("statutory report"; "Statutory Report")
            {
                MinOccurs = Zero;
                XmlName = 'StatutoryReport';
                UseTemporary = true;
                fieldelement(Code; "Statutory Report".Code)
                {
                }
                fieldelement(Description; "Statutory Report".Description)
                {
                }
                fieldelement(GroupCode; "Statutory Report"."Group Code")
                {
                }
                fieldelement(FormatVersionCode; "Statutory Report"."Format Version Code")
                {
                }
                fieldelement(SequenceNo; "Statutory Report"."Sequence No.")
                {
                }
                fieldelement(SenderNo; "Statutory Report"."Sender No.")
                {
                }
                fieldelement(ReportType; "Statutory Report"."Report Type")
                {
                }
                fieldelement(Active; "Statutory Report".Active)
                {
                }
                fieldelement(StartingDate; "Statutory Report"."Starting Date")
                {
                }
                fieldelement(EndingDate; "Statutory Report"."Ending Date")
                {
                }
                fieldelement(Header; "Statutory Report".Header)
                {
                }
                fieldelement(UppercaseTextExcelFormat; "Statutory Report"."Uppercase Text Excel Format")
                {
                    MinOccurs = Zero;
                }
                fieldelement(UppercaseTextXMLFormat; "Statutory Report"."Uppercase Text XML Format")
                {
                    MinOccurs = Zero;
                }
                tableelement("statutory report table"; "Statutory Report Table")
                {
                    LinkFields = "Report Code" = field(Code);
                    LinkTable = "Statutory Report";
                    MinOccurs = Zero;
                    XmlName = 'StatutoryReportTable';
                    UseTemporary = true;
                    fieldelement(ReportCode; "Statutory Report Table"."Report Code")
                    {
                    }
                    fieldelement(Code; "Statutory Report Table".Code)
                    {
                    }
                    fieldelement(Description; "Statutory Report Table".Description)
                    {
                    }
                    fieldelement(SequenceNo; "Statutory Report Table"."Sequence No.")
                    {
                    }
                    fieldelement(ExcelSheetName; "Statutory Report Table"."Excel Sheet Name")
                    {
                    }
                    fieldelement(ScalableTable; "Statutory Report Table"."Scalable Table")
                    {
                    }
                    fieldelement(RowCode; "Statutory Report Table"."Row Code")
                    {
                    }
                    fieldelement(ScalableTableFirstRowNo; "Statutory Report Table"."Scalable Table First Row No.")
                    {
                    }
                    fieldelement(ScalableTableRowStep; "Statutory Report Table"."Scalable Table Row Step")
                    {
                    }
                    fieldelement(ScalableTableMaxRowsQty; "Statutory Report Table"."Scalable Table Max Rows Qty")
                    {
                    }
                    fieldelement(MultipageTable; "Statutory Report Table"."Multipage Table")
                    {
                    }
                    fieldelement(PageIndicationText; "Statutory Report Table"."Page Indication Text")
                    {
                    }
                    fieldelement(PageIndicExcelCellName; "Statutory Report Table"."Page Indic. Excel Cell Name")
                    {
                    }
                    fieldelement(PageIndicRequisiteLineNo; "Statutory Report Table"."Page Indic. Requisite Line No.")
                    {
                    }
                    fieldelement(TableIndicationText; "Statutory Report Table"."Table Indication Text")
                    {
                    }
                    fieldelement(TableIndicExcelCellName; "Statutory Report Table"."Table Indic. Excel Cell Name")
                    {
                    }
                    fieldelement(VerticalTable; "Statutory Report Table"."Vertical Table")
                    {
                    }
                    fieldelement(ParentTableCode; "Statutory Report Table"."Parent Table Code")
                    {
                    }
                    fieldelement(IntSourceType; "Statutory Report Table"."Int. Source Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceSectionCode; "Statutory Report Table"."Int. Source Section Code")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceNo; "Statutory Report Table"."Int. Source No.")
                    {
                        MinOccurs = Zero;
                    }
                    tableelement("stat. report table row"; "Stat. Report Table Row")
                    {
                        LinkFields = "Report Code" = field("Report Code"), "Table Code" = field(Code);
                        LinkTable = "Statutory Report Table";
                        MinOccurs = Zero;
                        XmlName = 'StatReportTableRow';
                        UseTemporary = true;
                        fieldelement(ReportCode; "Stat. Report Table Row"."Report Code")
                        {
                        }
                        fieldelement(TableCode; "Stat. Report Table Row"."Table Code")
                        {
                        }
                        fieldelement(LineNo; "Stat. Report Table Row"."Line No.")
                        {
                        }
                        fieldelement(Description; "Stat. Report Table Row".Description)
                        {
                        }
                        fieldelement(RequisitesGroupName; "Stat. Report Table Row"."Requisites Group Name")
                        {
                        }
                        fieldelement(RowCode; "Stat. Report Table Row"."Row Code")
                        {
                        }
                        fieldelement(ExcelRowNo; "Stat. Report Table Row"."Excel Row No.")
                        {
                        }
                        fieldelement(Bold; "Stat. Report Table Row".Bold)
                        {
                        }
                        fieldelement(InsertedRequisite; "Stat. Report Table Row"."Inserted Requisite")
                        {
                        }
                        fieldelement(ColumnNoForInsRequisite; "Stat. Report Table Row"."Column Name for Ins. Rqst.")
                        {
                        }
                    }
                    tableelement("stat. report table column"; "Stat. Report Table Column")
                    {
                        LinkFields = "Report Code" = field("Report Code"), "Table Code" = field(Code);
                        LinkTable = "Statutory Report Table";
                        MinOccurs = Zero;
                        XmlName = 'StatReportTableColumn';
                        UseTemporary = true;
                        fieldelement(ReportCode; "Stat. Report Table Column"."Report Code")
                        {
                        }
                        fieldelement(TableCode; "Stat. Report Table Column"."Table Code")
                        {
                        }
                        fieldelement(LineNo; "Stat. Report Table Column"."Line No.")
                        {
                        }
                        fieldelement(ColumnHeader; "Stat. Report Table Column"."Column Header")
                        {
                        }
                        fieldelement(ColumnNo; "Stat. Report Table Column"."Column No.")
                        {
                        }
                        fieldelement(ExcelColumnName; "Stat. Report Table Column"."Excel Column Name")
                        {
                        }
                        fieldelement(VertTableRowShift; "Stat. Report Table Column"."Vert. Table Row Shift")
                        {
                        }
                    }
                    tableelement("table individual requisite"; "Table Individual Requisite")
                    {
                        LinkFields = "Report Code" = field("Report Code"), "Table Code" = field(Code);
                        LinkTable = "Statutory Report Table";
                        MinOccurs = Zero;
                        XmlName = 'TableIndividualRequisite';
                        UseTemporary = true;
                        fieldelement(ReportCode; "Table Individual Requisite"."Report Code")
                        {
                        }
                        fieldelement(TableCode; "Table Individual Requisite"."Table Code")
                        {
                        }
                        fieldelement(LineNo; "Table Individual Requisite"."Line No.")
                        {
                        }
                        fieldelement(Description; "Table Individual Requisite".Description)
                        {
                        }
                        fieldelement(RequisitesGroupName; "Table Individual Requisite"."Requisites Group Name")
                        {
                        }
                        fieldelement(RowCode; "Table Individual Requisite"."Row Code")
                        {
                        }
                        fieldelement(ColumnNo; "Table Individual Requisite"."Column No.")
                        {
                        }
                        fieldelement(Bold; "Table Individual Requisite".Bold)
                        {
                        }
                    }
                }
                tableelement("xml element line"; "XML Element Line")
                {
                    LinkFields = "Report Code" = field(Code);
                    LinkTable = "Statutory Report";
                    MinOccurs = Zero;
                    XmlName = 'XMLElementLine';
                    UseTemporary = true;
                    fieldelement(ReportCode; "XML Element Line"."Report Code")
                    {
                    }
                    fieldelement(LineNo; "XML Element Line"."Line No.")
                    {
                    }
                    fieldelement(RequisiteName; "XML Element Line"."Element Name")
                    {
                    }
                    fieldelement(ParentLineNo; "XML Element Line"."Parent Line No.")
                    {
                    }
                    fieldelement(ParentRequisiteName; "XML Element Line"."Parent Element Name")
                    {
                    }
                    fieldelement(ElementType; "XML Element Line"."Element Type")
                    {
                    }
                    fieldelement(Description; "XML Element Line".Description)
                    {
                    }
                    fieldelement(SequenceNo; "XML Element Line"."Sequence No.")
                    {
                    }
                    fieldelement(Indentation; "XML Element Line".Indentation)
                    {
                    }
                    fieldelement(DataType; "XML Element Line"."Data Type")
                    {
                    }
                    fieldelement(LinkType; "XML Element Line"."Link Type")
                    {
                    }
                    fieldelement(ServiceElement; "XML Element Line"."Service Element")
                    {
                    }
                    fieldelement(TableCode; "XML Element Line"."Table Code")
                    {
                    }
                    fieldelement(ExportType; "XML Element Line"."Export Type")
                    {
                    }
                    fieldelement(Choice; "XML Element Line".Choice)
                    {
                    }
                    fieldelement(SourceType; "XML Element Line"."Source Type")
                    {
                    }
                    fieldelement(Value; "XML Element Line".Value)
                    {
                    }
                    fieldelement(RowLinkNo; "XML Element Line"."Row Link No.")
                    {
                    }
                    fieldelement(ColumnLinkNo; "XML Element Line"."Column Link No.")
                    {
                    }
                    fieldelement(ExcelMappingType; "XML Element Line"."Excel Mapping Type")
                    {
                    }
                    fieldelement(ExcelCellName; "XML Element Line"."Excel Cell Name")
                    {
                    }
                    fieldelement(HorizontalCellsQuantity; "XML Element Line"."Horizontal Cells Quantity")
                    {
                    }
                    fieldelement(VerticalCellsQuantity; "XML Element Line"."Vertical Cells Quantity")
                    {
                    }
                    fieldelement(VerticalCellsDelta; "XML Element Line"."Vertical Cells Delta")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ExcelSheetName; "XML Element Line"."Excel Sheet Name")
                    {
                    }
                    fieldelement(FractionDigits; "XML Element Line"."Fraction Digits")
                    {
                    }
                    fieldelement(OKEIScaling; "XML Element Line"."OKEI Scaling")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(XMLExportDateFormat; "XML Element Line"."XML Export Date Format")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(Alignment; "XML Element Line".Alignment)
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(PadCharacter; "XML Element Line"."Pad Character")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TemplateData; "XML Element Line"."Template Data")
                    {
                        MinOccurs = Zero;
                    }
                    tableelement("xml element expression line"; "XML Element Expression Line")
                    {
                        LinkFields = "Report Code" = field("Report Code"), "Base XML Element Line No." = field("Line No.");
                        LinkTable = "XML Element Line";
                        MinOccurs = Zero;
                        XmlName = 'XMLElementExpressionLine';
                        UseTemporary = true;
                        fieldelement(ReportCode; "XML Element Expression Line"."Report Code")
                        {
                        }
                        fieldelement(BaseXMLElementLineNo; "XML Element Expression Line"."Base XML Element Line No.")
                        {
                        }
                        fieldelement(LineNo; "XML Element Expression Line"."Line No.")
                        {
                        }
                        fieldelement(XMLElementLineNo; "XML Element Expression Line"."XML Element Line No.")
                        {
                        }
                        fieldelement(XMLElementName; "XML Element Expression Line"."XML Element Name")
                        {
                        }
                        fieldelement(Value; "XML Element Expression Line".Value)
                        {
                        }
                        fieldelement(Source; "XML Element Expression Line".Source)
                        {
                        }
                        fieldelement(TableID; "XML Element Expression Line"."Table ID")
                        {
                        }
                        fieldelement(FieldID; "XML Element Expression Line"."Field ID")
                        {
                        }
                        fieldelement(FieldName; "XML Element Expression Line"."Field Name")
                        {
                        }
                        fieldelement(StringBefore; "XML Element Expression Line"."String Before")
                        {
                        }
                        fieldelement(StringAfter; "XML Element Expression Line"."String After")
                        {
                        }
                    }
                }
                tableelement("page indication xml element"; "Page Indication XML Element")
                {
                    LinkFields = "Report Code" = field(Code);
                    LinkTable = "Statutory Report";
                    MinOccurs = Zero;
                    XmlName = 'PageIndicationXMLElement';
                    UseTemporary = true;
                    fieldelement(ReportCode; "Page Indication XML Element"."Report Code")
                    {
                    }
                    fieldelement(TableCode; "Page Indication XML Element"."Table Code")
                    {
                    }
                    fieldelement(LineNo; "Page Indication XML Element"."Line No.")
                    {
                    }
                    fieldelement(XMLElementLineNo; "Page Indication XML Element"."XML Element Line No.")
                    {
                    }
                    fieldelement(XMLElementName; "Page Indication XML Element"."XML Element Name")
                    {
                    }
                }
                tableelement("stat. report excel sheet"; "Stat. Report Excel Sheet")
                {
                    LinkFields = "Report Code" = field(Code);
                    LinkTable = "Statutory Report";
                    MinOccurs = Zero;
                    XmlName = 'StatReportExcelSheet';
                    SourceTableView = where("Report Data No." = const(''));
                    UseTemporary = true;
                    fieldelement(ReportCode; "Stat. Report Excel Sheet"."Report Code")
                    {
                    }
                    fieldelement(TableCode; "Stat. Report Excel Sheet"."Table Code")
                    {
                    }
                    fieldelement(SheetName; "Stat. Report Excel Sheet"."Sheet Name")
                    {
                    }
                    fieldelement(PageNumberExcelCellName; "Stat. Report Excel Sheet"."Page Number Excel Cell Name")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(PageNumberHorizCellsQty; "Stat. Report Excel Sheet"."Page Number Horiz. Cells Qty")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(PageNumberVerticalCellsQty; "Stat. Report Excel Sheet"."Page Number Vertical Cells Qty")
                    {
                        MinOccurs = Zero;
                    }
                }
                tableelement("stat. report table mapping"; "Stat. Report Table Mapping")
                {
                    LinkFields = "Report Code" = field(Code);
                    LinkTable = "Statutory Report";
                    MinOccurs = Zero;
                    XmlName = 'StatReportTableMapping';
                    UseTemporary = true;
                    fieldelement(ReportCode; "Stat. Report Table Mapping"."Report Code")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TableCode; "Stat. Report Table Mapping"."Table Code")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TableRowNo; "Stat. Report Table Mapping"."Table Row No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TableColumnNo; "Stat. Report Table Mapping"."Table Column No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TableRowDescription; "Stat. Report Table Mapping"."Table Row Description")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(TableColumnHeader; "Stat. Report Table Mapping"."Table Column Header")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceType; "Stat. Report Table Mapping"."Int. Source Type")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceSectionCode; "Stat. Report Table Mapping"."Int. Source Section Code")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceNo; "Stat. Report Table Mapping"."Int. Source No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(InternalSourceRowNo; "Stat. Report Table Mapping"."Internal Source Row No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(InternalSourceColumnNo; "Stat. Report Table Mapping"."Internal Source Column No.")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceRowDescription; "Stat. Report Table Mapping"."Int. Source Row Description")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(IntSourceColumnHeader; "Stat. Report Table Mapping"."Int. Source Column Header")
                    {
                        MinOccurs = Zero;
                    }
                }
            }
            tableelement("format version"; "Format Version")
            {
                LinkTable = "Statutory Report";
                MinOccurs = Zero;
                XmlName = 'FormatVersion';
                UseTemporary = true;
                fieldelement(FormatVersionCode; "Format Version".Code)
                {
                }
                fieldelement(KNDCode; "Format Version"."KND Code")
                {
                }
                fieldelement(ReportDescription; "Format Version"."Report Description")
                {
                }
                fieldelement(PartNo; "Format Version"."Part No.")
                {
                }
                fieldelement(VerisionNo; "Format Version"."Version No.")
                {
                }
                fieldelement(ReportType; "Format Version"."Report Type")
                {
                }
                fieldelement(UsageStartingDate; "Format Version"."Usage Starting Date")
                {
                }
                fieldelement(UsageFirstReportingPeriod; "Format Version"."Usage First Reporting Period")
                {
                }
                fieldelement(UsageEndingDate; "Format Version"."Usage Ending Date")
                {
                }
                fieldelement(RegisterNo; "Format Version"."Register No.")
                {
                }
                fieldelement(ExcelFileName; "Format Version"."Excel File Name")
                {
                }
                fieldelement(XMLSchemaFileName; "Format Version"."XML Schema File Name")
                {
                }
                fieldelement(FormSequenceNoApprDate; "Format Version"."Form Order No. & Appr. Date")
                {
                }
                fieldelement(FormatSequenceNoApprDate; "Format Version"."Format Order No. & Appr. Date")
                {
                }
                fieldelement(Comment; "Format Version".Comment)
                {
                }
                fieldelement(XMLFileNameElementName; "Format Version"."XML File Name Element Name")
                {
                    MinOccurs = Zero;
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportGroup: Record "Statutory Report Group";
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableColumn: Record "Stat. Report Table Column";
        TableIndividualRequisite: Record "Table Individual Requisite";
        XMLElementLine: Record "XML Element Line";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        FormatVersion: Record "Format Version";
        XMLElementExpressionLine: Record "XML Element Expression Line";
        PageIndicationXMLElement: Record "Page Indication XML Element";
        StatReportTableMapping: Record "Stat. Report Table Mapping";

    [Scope('OnPrem')]
    procedure SetData(var TempStatutoryReport: Record "Statutory Report")
    begin
        "Statutory Report".Reset();
        "Statutory Report".DeleteAll();
        if TempStatutoryReport.FindSet() then
            repeat
                "Statutory Report" := TempStatutoryReport;
                "Statutory Report".Insert();
                if TempStatutoryReport."Group Code" <> '' then
                    if not "Statutory Report Group".Get(TempStatutoryReport."Group Code") then
                        if StatutoryReportGroup.Get(TempStatutoryReport."Group Code") then begin
                            "Statutory Report Group" := StatutoryReportGroup;
                            "Statutory Report Group".Insert();
                        end;

                StatutoryReportTable.SetRange("Report Code", TempStatutoryReport.Code);
                if StatutoryReportTable.FindSet() then
                    repeat
                        "Statutory Report Table" := StatutoryReportTable;
                        "Statutory Report Table".Insert();

                        StatReportTableRow.SetRange("Report Code", StatutoryReportTable."Report Code");
                        StatReportTableRow.SetRange("Table Code", StatutoryReportTable.Code);
                        if StatReportTableRow.FindSet() then
                            repeat
                                "Stat. Report Table Row" := StatReportTableRow;
                                "Stat. Report Table Row".Insert();
                            until StatReportTableRow.Next() = 0;

                        StatReportTableColumn.SetRange("Report Code", StatutoryReportTable."Report Code");
                        StatReportTableColumn.SetRange("Table Code", StatutoryReportTable.Code);
                        if StatReportTableColumn.FindSet() then
                            repeat
                                "Stat. Report Table Column" := StatReportTableColumn;
                                "Stat. Report Table Column".Insert();
                            until StatReportTableColumn.Next() = 0;

                        TableIndividualRequisite.SetRange("Report Code", StatutoryReportTable."Report Code");
                        TableIndividualRequisite.SetRange("Table Code", StatutoryReportTable.Code);
                        if TableIndividualRequisite.FindSet() then
                            repeat
                                "Table Individual Requisite" := TableIndividualRequisite;
                                "Table Individual Requisite".Insert();
                            until TableIndividualRequisite.Next() = 0;
                    until StatutoryReportTable.Next() = 0;

                if not TempStatutoryReport.Header then begin
                    FormatVersion.Get(TempStatutoryReport."Format Version Code");
                    if not "Format Version".Get(TempStatutoryReport."Format Version Code") then begin
                        "Format Version" := FormatVersion;
                        "Format Version".Insert();
                    end;
                end;

                StatReportExcelSheet.SetRange("Report Code", TempStatutoryReport.Code);
                StatReportExcelSheet.SetFilter("Report Data No.", '');
                if StatReportExcelSheet.FindSet() then
                    repeat
                        "Stat. Report Excel Sheet" := StatReportExcelSheet;
                        "Stat. Report Excel Sheet".Insert();
                    until StatReportExcelSheet.Next() = 0;

                XMLElementLine.SetRange("Report Code", TempStatutoryReport.Code);
                if XMLElementLine.FindSet() then
                    repeat
                        "XML Element Line" := XMLElementLine;
                        "XML Element Line".Insert();
                    until XMLElementLine.Next() = 0;

                XMLElementExpressionLine.SetRange("Report Code", TempStatutoryReport.Code);
                if XMLElementExpressionLine.FindSet() then
                    repeat
                        "XML Element Expression Line" := XMLElementExpressionLine;
                        "XML Element Expression Line".Insert();
                    until XMLElementExpressionLine.Next() = 0;

                PageIndicationXMLElement.SetRange("Report Code", TempStatutoryReport.Code);
                if PageIndicationXMLElement.FindSet() then
                    repeat
                        "Page Indication XML Element" := PageIndicationXMLElement;
                        "Page Indication XML Element".Insert();
                    until PageIndicationXMLElement.Next() = 0;

                StatReportTableMapping.SetRange("Report Code", TempStatutoryReport.Code);
                if StatReportTableMapping.FindSet() then
                    repeat
                        "Stat. Report Table Mapping" := StatReportTableMapping;
                        "Stat. Report Table Mapping".Insert();
                    until StatReportTableMapping.Next() = 0;
            until TempStatutoryReport.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportData(PathName: Text[1024])
    begin
        "Format Version".Reset();
        if "Format Version".FindSet() then
            repeat
                if not FormatVersion.Get("Format Version".Code) then begin
                    FormatVersion := "Format Version";
                    if FormatVersion."Excel File Name" <> '' then
                        FormatVersion.ImportExcelTemplate(PathName + FormatVersion."Excel File Name");
                    if FormatVersion."XML Schema File Name" <> '' then
                        FormatVersion.ImportXMLSchema(PathName + FormatVersion."XML Schema File Name");
                    FormatVersion.Insert();
                end;
            until "Format Version".Next() = 0;

        "Statutory Report".Reset();
        if "Statutory Report".FindSet() then
            repeat
                if StatutoryReport.Get("Statutory Report".Code) then
                    StatutoryReport.Delete(true);
                StatutoryReport := "Statutory Report";
                StatutoryReport.Insert();
            until "Statutory Report".Next() = 0;

        "Statutory Report Group".Reset();
        if "Statutory Report Group".FindSet() then
            repeat
                if StatutoryReportGroup.Get("Statutory Report Group".Code) then
                    StatutoryReportGroup.Delete(true);
                StatutoryReportGroup := "Statutory Report Group";
                StatutoryReportGroup.Insert();
            until "Statutory Report Group".Next() = 0;

        "Statutory Report Table".Reset();
        if "Statutory Report Table".FindSet() then
            repeat
                if StatutoryReportTable.Get("Statutory Report Table"."Report Code",
                  "Statutory Report Table".Code)
                then
                    StatutoryReportTable.Delete(true);
                StatutoryReportTable := "Statutory Report Table";
                StatutoryReportTable.Insert();
            until "Statutory Report Table".Next() = 0;

        "Stat. Report Table Row".Reset();
        if "Stat. Report Table Row".FindSet() then
            repeat
                if StatReportTableRow.Get("Stat. Report Table Row"."Report Code",
                  "Stat. Report Table Row"."Table Code", "Stat. Report Table Row"."Line No.")
                then
                    StatReportTableRow.Delete(true);
                StatReportTableRow := "Stat. Report Table Row";
                StatReportTableRow.Insert();
            until "Stat. Report Table Row".Next() = 0;

        "Stat. Report Table Column".Reset();
        if "Stat. Report Table Column".FindSet() then
            repeat
                if StatReportTableColumn.Get("Stat. Report Table Column"."Report Code",
                  "Stat. Report Table Column"."Table Code", "Stat. Report Table Column"."Line No.")
                then
                    StatReportTableColumn.Delete(true);
                StatReportTableColumn := "Stat. Report Table Column";
                StatReportTableColumn.Insert();
            until "Stat. Report Table Column".Next() = 0;

        "Table Individual Requisite".Reset();
        if "Table Individual Requisite".FindSet() then
            repeat
                if TableIndividualRequisite.Get("Table Individual Requisite"."Report Code",
                  "Table Individual Requisite"."Table Code", "Table Individual Requisite"."Line No.")
                then
                    TableIndividualRequisite.Delete(true);
                TableIndividualRequisite := "Table Individual Requisite";
                TableIndividualRequisite.Insert();
            until "Table Individual Requisite".Next() = 0;

        "XML Element Line".Reset();
        if "XML Element Line".FindSet() then
            repeat
                if XMLElementLine.Get("XML Element Line"."Report Code", "XML Element Line"."Line No.") then
                    XMLElementLine.Delete(true);
                XMLElementLine := "XML Element Line";
                XMLElementLine.Insert();
            until "XML Element Line".Next() = 0;

        "XML Element Expression Line".Reset();
        if "XML Element Expression Line".FindSet() then
            repeat
                if XMLElementExpressionLine.Get(
                  "XML Element Expression Line"."Report Code",
                  "XML Element Expression Line"."Base XML Element Line No.",
                  "XML Element Expression Line"."Line No.")
                then
                    XMLElementExpressionLine.Delete(true);
                XMLElementExpressionLine := "XML Element Expression Line";
                XMLElementExpressionLine.Insert();
            until "XML Element Expression Line".Next() = 0;

        "Page Indication XML Element".Reset();
        if "Page Indication XML Element".FindSet() then
            repeat
                if PageIndicationXMLElement.Get(
                  "Page Indication XML Element"."Report Code",
                  "Page Indication XML Element"."Table Code",
                  "Page Indication XML Element"."Line No.")
                then
                    PageIndicationXMLElement.Delete();
                PageIndicationXMLElement := "Page Indication XML Element";
                PageIndicationXMLElement.Insert();
            until "Page Indication XML Element".Next() = 0;

        "Stat. Report Excel Sheet".Reset();
        if "Stat. Report Excel Sheet".FindFirst() then
            repeat
                if StatReportExcelSheet.Get("Stat. Report Excel Sheet"."Report Code",
                  '', "Stat. Report Excel Sheet"."Table Code", "Stat. Report Excel Sheet"."Sheet Name")
                then
                    StatReportExcelSheet.Delete();

                StatReportExcelSheet := "Stat. Report Excel Sheet";
                StatReportExcelSheet.Insert();
            until "Stat. Report Excel Sheet".Next() = 0;

        "Stat. Report Table Mapping".Reset();
        if "Stat. Report Table Mapping".FindSet() then
            repeat
                if StatReportTableMapping.Get(
                  "Stat. Report Table Mapping"."Report Code",
                  "Stat. Report Table Mapping"."Table Code",
                  "Stat. Report Table Mapping"."Table Row No.",
                  "Stat. Report Table Mapping"."Table Column No.")
                then
                    StatReportTableMapping.Delete();

                StatReportTableMapping := "Stat. Report Table Mapping";
                StatReportTableMapping.Insert();
            until "Stat. Report Table Mapping".Next() = 0;
    end;
}

