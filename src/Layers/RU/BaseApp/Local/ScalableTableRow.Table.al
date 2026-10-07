#pragma warning disable AA0247
table 26555 "Scalable Table Row"
{
    Caption = 'Scalable Table Row';
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
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(10; "Excel Row No."; Integer)
        {
            Caption = 'Excel Row No.';
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
        key(Key1; "Report Data No.", "Report Code", "Table Code", "Excel Sheet Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StatutoryReportDataValue: Record "Statutory Report Data Value";
    begin
        StatutoryReportDataValue.SetRange("Report Data No.", "Report Data No.");
        StatutoryReportDataValue.SetRange("Report Code", "Report Code");
        StatutoryReportDataValue.SetRange("Table Code", "Table Code");
        StatutoryReportDataValue.SetRange("Excel Sheet Name", "Excel Sheet Name");
        StatutoryReportDataValue.SetRange("Row No.", "Line No.");
        StatutoryReportDataValue.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        StatutoryReportTable: Record "Statutory Report Table";
        ScalableTableRow: Record "Scalable Table Row";
    begin
        StatutoryReportTable.Get("Report Code", "Table Code");
        StatutoryReportTable.TestField("Scalable Table Max Rows Qty");
        ScalableTableRow.SetRange("Report Data No.", "Report Data No.");
        ScalableTableRow.SetRange("Report Code", "Report Code");
        ScalableTableRow.SetRange("Table Code", "Table Code");
        ScalableTableRow.SetRange("Excel Sheet Name", "Excel Sheet Name");
        if ScalableTableRow.Count >= StatutoryReportTable."Scalable Table Max Rows Qty" then
            Error(Text002, StatutoryReportTable.GetRecDescription(), StatutoryReportTable."Scalable Table Max Rows Qty");
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Table %1 can''t contain more then %2 rows.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

