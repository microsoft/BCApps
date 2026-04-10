#pragma warning disable AA0247
table 26565 "Stat. Report Data Change Log"
{
    Caption = 'Stat. Report Data Change Log';
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
        field(4; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(7; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report".Code;
        }
        field(8; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));
        }
        field(10; "New Value"; Text[100])
        {
            Caption = 'New Value';
        }
        field(11; "Old Value"; Text[100])
        {
            Caption = 'Old Value';
        }
        field(12; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(13; "Date and Time"; DateTime)
        {
            Caption = 'Date and Time';
        }
        field(14; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" where("Report Code" = field("Report Code"),
                                                                           "Table Code" = field("Table Code"),
                                                                           "Report Data No." = field("Report Data No."));
        }
    }

    keys
    {
        key(Key1; "Report Code", "Report Data No.", "Table Code", "Excel Sheet Name", "Row No.", "Column No.", "Version No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User ID" := UserId;
        "Date and Time" := CurrentDateTime;
    end;

    [Scope('OnPrem')]
    procedure ShouldValueBeDisplayed(ShowOnlyChangedValues: Boolean; ReportDataNo: Code[20]; ReportCode: Code[20]; TableCode: Code[20]; ExcelSheetName: Text[30]; RowNo: Integer; ColumnNo: Integer): Boolean
    var
        StatReportDataChangeLog: Record "Stat. Report Data Change Log";
    begin
        if not ShowOnlyChangedValues then
            exit(true);

        StatReportDataChangeLog.SetRange("Report Data No.", ReportDataNo);
        StatReportDataChangeLog.SetRange("Report Code", ReportCode);
        StatReportDataChangeLog.SetRange("Table Code", TableCode);
        StatReportDataChangeLog.SetRange("Row No.", RowNo);
        StatReportDataChangeLog.SetRange("Column No.", ColumnNo);
        StatReportDataChangeLog.SetRange("Excel Sheet Name", ExcelSheetName);
        exit(not StatReportDataChangeLog.IsEmpty);
    end;
}

