#pragma warning disable AA0247
table 26553 "Stat. Report Table Row"
{
    Caption = 'Stat. Report Table Row';
    DrillDownPageID = "Report Table Rows";
    LookupPageID = "Report Table Rows";
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
        field(4; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(6; "Requisites Group Name"; Text[30])
        {
            Caption = 'Requisites Group Name';
        }
        field(9; "Row Code"; Text[20])
        {
            Caption = 'Row Code';
        }
        field(10; "Excel Row No."; Integer)
        {
            Caption = 'Excel Row No.';
        }
        field(23; Bold; Boolean)
        {
            Caption = 'Bold';
        }
        field(34; "Inserted Requisite"; Boolean)
        {
            Caption = 'Inserted Requisite';
        }
        field(36; "Column Name for Ins. Rqst."; Code[10])
        {
            Caption = 'Column Name for Ins. Rqst.';

            trigger OnValidate()
            begin
                TestField("Inserted Requisite", true);
            end;
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
        StatReportTableMapping.SetRange("Table Row No.", "Line No.");
        StatReportTableMapping.SetFilter("Table Column No.", '>0');
        if not StatReportTableMapping.IsEmpty() then
            StatReportTableMapping.DeleteAll();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Report %1 contains data referred to the %2.';
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
            StatutoryReportDataValue.SetRange("Row No.", "Line No.");
            StatutoryReportDataValue.SetFilter("Column No.", '>0');
            if StatutoryReportDataValue.FindFirst() then
                Error(Text003, "Report Code", GetRecDescription());
        end;
    end;
}

