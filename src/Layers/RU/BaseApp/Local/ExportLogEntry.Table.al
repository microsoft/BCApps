#pragma warning disable AA0247
table 26567 "Export Log Entry"
{
    Caption = 'Export Log Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(6; "Report Data No."; Code[20])
        {
            Caption = 'Report Data No.';
        }
        field(10; "File ID"; Code[35])
        {
            Caption = 'File ID';
        }
        field(13; "Sender No."; Code[20])
        {
            Caption = 'Sender No.';
            TableRelation = Employee;
        }
        field(20; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(21; "Exported File"; BLOB)
        {
            Caption = 'Exported File';
        }
        field(22; "Export Date"; Date)
        {
            Caption = 'Export Date';
        }
        field(23; "Export Time"; Time)
        {
            Caption = 'Export Time';
        }
        field(24; "Year-YY"; Code[2])
        {
            Caption = 'Year-YY';
            Numeric = true;
        }
        field(25; Month; Code[2])
        {
            Caption = 'Month';
            Numeric = true;
        }
        field(26; Day; Code[2])
        {
            Caption = 'Day';
            Numeric = true;
        }
        field(27; Hour; Code[2])
        {
            Caption = 'Hour';
            Numeric = true;
        }
        field(28; Minute; Code[2])
        {
            Caption = 'Minute';
            Numeric = true;
        }
        field(29; Second; Code[2])
        {
            Caption = 'Second';
            Numeric = true;
        }
        field(30; Year; Code[4])
        {
            Caption = 'Year';
            Numeric = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            SRSetup.Get();
            SRSetup.TestField("Report Export Log Nos");
            "No." := NoSeries.GetNextNo(SRSetup."Report Export Log Nos", Today());
        end;

        "Export Date" := Today;
        "Export Time" := Time;
        "Year-YY" := Format("Export Date", 0, '<Year,2>');
        Month := Format("Export Date", 0, '<Month,2>');
        Day := Format("Export Date", 0, '<Day,2>');
        Hour := Format("Export Time", 0, '<Hours24,2><Filler Character,0>');
        Minute := Format("Export Time", 0, '<Minutes,2>');
        Second := Format("Export Time", 0, '<Seconds,2>');
    end;

    var
        SRSetup: Record "Statutory Report Setup";
}

