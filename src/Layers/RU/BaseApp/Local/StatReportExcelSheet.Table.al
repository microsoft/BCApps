#pragma warning disable AA0247
table 26562 "Stat. Report Excel Sheet"
{
    Caption = 'Stat. Report Excel Sheet';
    LookupPageID = "Stat. Report Excel Sheets";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(2; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));
        }
        field(3; "Report Data No."; Code[20])
        {
            Caption = 'Report Data No.';
            TableRelation = "Statutory Report Data Header"."No.";
        }
        field(4; "Sheet Name"; Text[30])
        {
            Caption = 'Sheet Name';
        }
        field(5; "Parent Sheet Name"; Text[30])
        {
            Caption = 'Parent Sheet Name';
        }
        field(6; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(7; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(8; "Page Indic. Requisite Value"; Text[100])
        {
            Caption = 'Page Indic. Requisite Value';
        }
        field(9; "Table Sequence No."; Integer)
        {
            Caption = 'Table Sequence No.';
        }
        field(15; "Page Number Excel Cell Name"; Code[10])
        {
            Caption = 'Page Number Excel Cell Name';
        }
        field(16; "Page Number Horiz. Cells Qty"; Integer)
        {
            Caption = 'Page Number Horiz. Cells Qty';
            InitValue = 1;
            MinValue = 1;
        }
        field(17; "Page Number Vertical Cells Qty"; Integer)
        {
            Caption = 'Page Number Vertical Cells Qty';
            InitValue = 1;
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Report Code", "Report Data No.", "Table Code", "Sheet Name")
        {
            Clustered = true;
        }
        key(Key2; "Report Code", "Table Code", "Report Data No.", "Parent Sheet Name", "Sequence No.")
        {
        }
        key(Key3; "Report Code", "Table Code", "Report Data No.", "Sequence No.")
        {
        }
        key(Key4; "Report Code", "Report Data No.", "Table Sequence No.")
        {
        }
        key(Key5; "Report Code", "Report Data No.", "Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ScalableTableRow: Record "Scalable Table Row";
    begin
        ScalableTableRow.SetRange("Report Data No.", "Report Data No.");
        ScalableTableRow.SetRange("Report Code", "Report Code");
        ScalableTableRow.SetRange("Table Code", "Table Code");
        ScalableTableRow.SetRange("Excel Sheet Name", "Sheet Name");
        ScalableTableRow.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
    begin
        if "Parent Sheet Name" <> '' then begin
            StatReportExcelSheet.SetCurrentKey(
              "Report Code", "Table Code", "Report Data No.", "Parent Sheet Name", "Sequence No.");
            StatReportExcelSheet.SetRange("Report Code", "Report Code");
            StatReportExcelSheet.SetRange("Report Data No.", "Report Data No.");
            StatReportExcelSheet.SetRange("Table Code", "Table Code");
            StatReportExcelSheet.SetRange("Parent Sheet Name", "Parent Sheet Name");
            if StatReportExcelSheet.FindLast() then;
            "Sequence No." := StatReportExcelSheet."Sequence No." + 1;
        end;
        StatutoryReportTable.Get("Report Code", "Table Code");
        "Table Sequence No." := StatutoryReportTable."Sequence No.";
    end;

    var
        StatutoryReportTable: Record "Statutory Report Table";

    [Scope('OnPrem')]
    procedure GetParentExcelSheetName(ReportCode: Code[20]; ReportDataHeaderNo: Code[20]; TableCode: Code[20]; ExcelSheetName: Text[30]): Text[30]
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
    begin
        StatReportExcelSheet.SetRange("Report Code", ReportCode);
        StatReportExcelSheet.SetRange("Report Data No.", ReportDataHeaderNo);
        StatReportExcelSheet.SetRange("Table Code", TableCode);
        StatReportExcelSheet.SetRange("Sheet Name", ExcelSheetName);
        if StatReportExcelSheet.FindFirst() then
            exit(StatReportExcelSheet."Parent Sheet Name");
    end;
}

