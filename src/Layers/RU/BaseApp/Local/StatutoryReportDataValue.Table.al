#pragma warning disable AA0247
table 26564 "Statutory Report Data Value"
{
    Caption = 'Statutory Report Data Value';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Data No."; Code[20])
        {
            Caption = 'Report Data No.';
            TableRelation = "Statutory Report Data Header";
        }
        field(2; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(6; Value; Text[150])
        {
            Caption = 'Value';

            trigger OnValidate()
            begin
                TestReportDataStatus();

                if Value <> xRec.Value then
                    AddChangeHistoryEntry();
            end;
        }
        field(7; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(8; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));
        }
        field(11; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" where("Report Code" = field("Report Code"),
                                                                           "Table Code" = field("Table Code"),
                                                                           "Report Data No." = field("Report Data No."));
        }
    }

    keys
    {
        key(Key1; "Report Data No.", "Report Code", "Table Code", "Excel Sheet Name", "Row No.", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
    begin
        TestReportDataStatus();

        StatReportDataChangeLog.SetRange("Report Data No.", "Report Data No.");
        StatReportDataChangeLog.SetRange("Report Code", "Report Code");
        StatReportDataChangeLog.SetRange("Table Code", "Table Code");
        StatReportDataChangeLog.SetRange("Excel Sheet Name", "Excel Sheet Name");
        StatReportDataChangeLog.SetRange("Row No.", "Row No.");
        StatReportDataChangeLog.SetRange("Column No.", "Column No.");
        StatReportDataChangeLog.DeleteAll();
    end;

    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";

    [Scope('OnPrem')]
    procedure AddChangeHistoryEntry()
    var
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
        VersionNo: Integer;
    begin
        StatReportDataChangeLog.SetRange("Report Data No.", "Report Data No.");
        StatReportDataChangeLog.SetRange("Report Code", "Report Code");
        StatReportDataChangeLog.SetRange("Table Code", "Table Code");
        StatReportDataChangeLog.SetRange("Excel Sheet Name", "Excel Sheet Name");
        StatReportDataChangeLog.SetRange("Row No.", "Row No.");
        StatReportDataChangeLog.SetRange("Column No.", "Column No.");
        if StatReportDataChangeLog.FindLast() then;
        VersionNo := StatReportDataChangeLog."Version No." + 1;

        StatReportDataChangeLog.Init();
        StatReportDataChangeLog."Report Data No." := "Report Data No.";
        StatReportDataChangeLog."Report Code" := "Report Code";
        StatReportDataChangeLog."Table Code" := "Table Code";
        StatReportDataChangeLog."Excel Sheet Name" := "Excel Sheet Name";
        StatReportDataChangeLog."Row No." := "Row No.";
        StatReportDataChangeLog."Column No." := "Column No.";
        StatReportDataChangeLog."Version No." := VersionNo;
        StatReportDataChangeLog."New Value" := Value;
        StatReportDataChangeLog."Old Value" := xRec.Value;

        StatReportDataChangeLog.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure TestReportDataStatus()
    begin
        StatutoryReportDataHeader.Get("Report Data No.");
        StatutoryReportDataHeader.TestField(Status, StatutoryReportDataHeader.Status::Open);
    end;

    [Scope('OnPrem')]
    procedure AddValue(ReportDataNo: Code[20]; ReportCode: Code[20]; TableCode: Code[20]; SheetName: Text[30]; RowNo: Integer; ColumnNo: Integer; CellValue: Text[150])
    begin
        "Report Data No." := ReportDataNo;
        "Report Code" := ReportCode;
        "Row No." := RowNo;
        "Column No." := ColumnNo;
        "Table Code" := TableCode;
        "Excel Sheet Name" := SheetName;
        if Find() then begin
            Value := CellValue;
            Modify();
        end else begin
            Value := CellValue;
            Insert();
        end;
    end;
}

