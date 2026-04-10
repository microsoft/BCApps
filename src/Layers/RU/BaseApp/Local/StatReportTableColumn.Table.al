#pragma warning disable AA0247
table 26554 "Stat. Report Table Column"
{
    Caption = 'Stat. Report Table Column';
    DrillDownPageID = "Report Table Columns";
    LookupPageID = "Report Table Columns";
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
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Column Header"; Text[250])
        {
            Caption = 'Column Header';
        }
        field(7; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(8; "Excel Column Name"; Code[10])
        {
            Caption = 'Excel Column Name';
        }
        field(9; "Vert. Table Row Shift"; Integer)
        {
            Caption = 'Vert. Table Row Shift';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Table Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckExistentReportData();
        StatReportTableMapping.SetRange("Report Code", "Report Code");
        StatReportTableMapping.SetRange("Table Code", "Table Code");
        StatReportTableMapping.SetRange("Table Column No.", "Line No.");
        if not StatReportTableMapping.IsEmpty() then
            StatReportTableMapping.DeleteAll();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Report %1 contains data referred to the %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StatReportTableMapping: Record "Stat. Report Table Mapping";

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(StrSubstNo('%1 %2=''%3'', %4=''%5'', %6=''%7''', TableCaption(),
            FieldCaption("Report Code"), "Report Code",
            FieldCaption("Table Code"), "Table Code",
            FieldCaption("Line No."), "Line No."));
    end;

    [Scope('OnPrem')]
    procedure CheckExistentReportData()
    var
        StatutoryReportDataValue: Record "Statutory Report Data Value";
    begin
        if "Table Code" <> '' then begin
            StatutoryReportDataValue.SetRange("Report Code", "Report Code");
            StatutoryReportDataValue.SetRange("Table Code", "Table Code");
            StatutoryReportDataValue.SetRange("Column No.", "Line No.");
            if StatutoryReportDataValue.FindFirst() then
                Error(Text001, "Report Code", GetRecDescription());
        end;
    end;
}

