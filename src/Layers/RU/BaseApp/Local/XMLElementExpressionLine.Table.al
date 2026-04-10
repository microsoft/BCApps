#pragma warning disable AA0247
table 26572 "XML Element Expression Line"
{
    Caption = 'XML Element Expression Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(3; "Base XML Element Line No."; Integer)
        {
            Caption = 'Base XML Element Line No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "XML Element Line No."; Integer)
        {
            Caption = 'XML Element Line No.';
            TableRelation = "XML Element Line"."Line No." where("Report Code" = field("Report Code"));
        }
        field(11; "XML Element Name"; Text[30])
        {
            Caption = 'XML Element Name';
        }
        field(20; Value; Text[250])
        {
            Caption = 'Value';
            Editable = false;
        }
        field(21; Source; Option)
        {
            Caption = 'Source';
            OptionCaption = 'Company Information,Director,Accountant,Sender,Export Log,Data Header,Report,Company Address';
            OptionMembers = "Company Information",Director,Accountant,Sender,"Export Log","Data Header","Report","Company Address";

            trigger OnValidate()
            begin
                if Source <> xRec.Source then begin
                    "Field ID" := 0;
                    Value := '';
                end;

                UpdateReferences();
            end;
        }
        field(25; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
        }
        field(27; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                Validate(Value, GetReferenceValue('', ''));
            end;
        }
        field(28; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "String Before"; Text[10])
        {
            Caption = 'String Before';
        }
        field(30; "String After"; Text[10])
        {
            Caption = 'String After';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Base XML Element Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckReportDataExistence();
        if XMLElementLine.Get("Report Code", "Base XML Element Line No.") then
            if XMLElementLine."Source Type" = XMLElementLine."Source Type"::Expression then
                UpdateRequisiteValue(true);
    end;

    trigger OnInsert()
    begin
        CheckReportDataExistence();
    end;

    trigger OnModify()
    begin
        CheckReportDataExistence();
        if XMLElementLine.Get("Report Code", "Base XML Element Line No.") then
            if XMLElementLine."Source Type" = XMLElementLine."Source Type"::Expression then
                UpdateRequisiteValue(false);
    end;

    var
        StatutoryReport: Record "Statutory Report";
        XMLElementLine: Record "XML Element Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Expression cannot be modified because %1 %2 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        StatutoryReportSetup: Record "Statutory Report Setup";

    [Scope('OnPrem')]
    procedure UpdateReferences()
    begin
        case Source of
            Source::"Company Information":
                "Table ID" := DATABASE::"Company Information";
            Source::Director, Source::Accountant, Source::Sender:
                "Table ID" := DATABASE::Employee;
            Source::"Export Log":
                "Table ID" := DATABASE::"Export Log Entry";
            Source::"Data Header":
                "Table ID" := DATABASE::"Statutory Report Data Header";
            Source::Report:
                "Table ID" := DATABASE::"Statutory Report";
            Source::"Company Address":
                "Table ID" := DATABASE::"Company Address";
        end;

        "Field ID" := 0;
    end;

    [Scope('OnPrem')]
    procedure GetReferenceValue(DataHeaderNo: Code[20]; ExportLogEntryNo: Code[20]): Text[250]
    var
        StatutoryReport: Record "Statutory Report";
        CompInfo: Record "Company Information";
        Employee: Record Employee;
        CompanyAddress: Record "Company Address";
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
        ExportLogEntry: Record "Export Log Entry";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        CompInfo.Get();
        case Source of
            Source::"Company Information":
                RecordRef.GetTable(CompInfo);
            Source::Director:
                begin
                    CompInfo.TestField("Director No.");
                    Employee.Get(CompInfo."Director No.");
                    RecordRef.GetTable(Employee);
                end;
            Source::Accountant:
                begin
                    CompInfo.TestField("Accountant No.");
                    Employee.Get(CompInfo."Accountant No.");
                    RecordRef.GetTable(Employee);
                end;
            Source::Sender:
                begin
                    StatutoryReport.Get("Report Code");
                    StatutoryReport.TestField("Sender No.");
                    Employee.Get(StatutoryReport."Sender No.");
                    RecordRef.GetTable(Employee);
                end;
            Source::"Export Log":
                if ExportLogEntryNo <> '' then begin
                    ExportLogEntry.Get(ExportLogEntryNo);
                    RecordRef.GetTable(ExportLogEntry);
                end else
                    exit('');
            Source::"Data Header":
                if DataHeaderNo <> '' then begin
                    StatutoryReportDataHeader.Get(DataHeaderNo);
                    StatutoryReportDataHeader.CalcFields("Requisites Quantity", "Set Requisites Quantity");
                    RecordRef.GetTable(StatutoryReportDataHeader);
                end else
                    exit('');
            Source::Report:
                begin
                    StatutoryReport.Get("Report Code");
                    RecordRef.GetTable(StatutoryReport);
                end;
            Source::"Company Address":
                begin
                    StatutoryReport.Get("Report Code");
                    CompanyAddress.Get(
                      StatutoryReport."Company Address Code",
                      StatutoryReport."Company Address Language Code");
                    RecordRef.GetTable(CompanyAddress);
                end;
            else
                exit('');
        end;
        TestField("Field ID");
        FieldRef := RecordRef.Field("Field ID");
        exit(Format(FieldRef.Value));
    end;

    [Scope('OnPrem')]
    procedure UpdateRequisiteValue(DeleteRecord: Boolean): Text[250]
    begin
        XMLElementLine.Get("Report Code", "Base XML Element Line No.");
        XMLElementLine.UpdateElementValue(Rec, DeleteRecord);
        XMLElementLine.Modify();
        exit(XMLElementLine.Value);
    end;

    [Scope('OnPrem')]
    procedure CheckReportDataExistence()
    begin
        StatutoryReportSetup.Get();
        if not StatutoryReportSetup."Setup Mode" then begin
            XMLElementLine.Get("Report Code", "Base XML Element Line No.");
            StatutoryReport.Get("Report Code");
            if XMLElementLine.IsReportDataExist() then
                Error(Text001,
                  StatutoryReport.TableCaption(),
                  StatutoryReport.Code);
        end;
    end;
}

