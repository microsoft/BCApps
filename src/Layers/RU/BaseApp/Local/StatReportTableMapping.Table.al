#pragma warning disable AA0247
table 26587 "Stat. Report Table Mapping"
{
    Caption = 'Stat. Report Table Mapping';
    DataCaptionFields = "Report Code", "Table Code", "Table Row Description", "Table Column Header";
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
        field(3; "Table Row No."; Integer)
        {
            Caption = 'Table Row No.';
        }
        field(4; "Table Column No."; Integer)
        {
            Caption = 'Table Column No.';
        }
        field(5; "Table Row Description"; Text[250])
        {
            Caption = 'Table Row Description';
        }
        field(6; "Table Column Header"; Text[250])
        {
            Caption = 'Table Column Header';
        }
        field(7; "Int. Source Type"; Option)
        {
            Caption = 'Int. Source Type';
            OptionCaption = ' ,Acc. Schedule,Tax Register,Tax Difference,Payroll Analysis Report';
            OptionMembers = " ","Acc. Schedule","Tax Register","Tax Difference","Payroll Analysis Report";

            trigger OnValidate()
            begin
                if "Int. Source Type" <> xRec."Int. Source Type" then begin
                    "Int. Source Section Code" := '';
                    "Int. Source No." := '';
                    "Internal Source Row No." := 0;
                    "Internal Source Column No." := 0;
                    "Int. Source Row Description" := '';
                    "Int. Source Column Header" := '';
                end;
            end;
        }
        field(8; "Int. Source Section Code"; Code[10])
        {
            Caption = 'Int. Source Section Code';
            TableRelation = if ("Int. Source Type" = filter("Tax Register")) "Tax Register Section"
            else
            if ("Int. Source Type" = const("Tax Difference")) "Tax Calc. Section";

            trigger OnValidate()
            begin
                if "Int. Source Type" in ["Int. Source Type"::" ", "Int. Source Type"::"Acc. Schedule"] then
                    FieldError("Int. Source Type");

                if "Int. Source Section Code" <> xRec."Int. Source Section Code" then
                    "Int. Source No." := '';
            end;
        }
        field(9; "Int. Source No."; Code[10])
        {
            Caption = 'Int. Source No.';
            TableRelation = if ("Int. Source Type" = const("Acc. Schedule")) "Acc. Schedule Name"
            else
            if ("Int. Source Type" = const("Tax Register")) "Tax Register"."No." where("Section Code" = field("Int. Source Section Code"))
            else
            if ("Int. Source Type" = const("Tax Difference")) "Tax Calc. Header"."No." where("Section Code" = field("Int. Source Section Code"));

            trigger OnValidate()
            begin
                if "Int. Source No." <> xRec."Int. Source No." then begin
                    "Internal Source Row No." := 0;
                    "Internal Source Column No." := 0;
                    "Int. Source Row Description" := '';
                    case "Int. Source Type" of
                        "Int. Source Type"::"Acc. Schedule":
                            "Int. Source Column Header" := '';
                        "Int. Source Type"::"Tax Register",
                      "Int. Source Type"::"Tax Difference":
                            "Int. Source Column Header" :=
                              TaxRegisterAccumulation.FieldCaption(Amount);
                    end;
                end;
            end;
        }
        field(10; "Internal Source Row No."; Integer)
        {
            Caption = 'Internal Source Row No.';
        }
        field(11; "Internal Source Column No."; Integer)
        {
            Caption = 'Internal Source Column No.';
        }
        field(12; "Int. Source Row Description"; Text[250])
        {
            Caption = 'Int. Source Row Description';
        }
        field(13; "Int. Source Column Header"; Text[250])
        {
            Caption = 'Int. Source Column Header';
        }
        field(14; "Int. Source Col. Lay. Name"; Code[10])
        {
            Caption = 'Int. Source Column Layout';
        }
    }

    keys
    {
        key(Key1; "Report Code", "Table Code", "Table Row No.", "Table Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 - %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TaxRegisterAccumulation: Record "Tax Register Accumulation";

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(StrSubstNo(Text001, "Int. Source Row Description", "Int. Source Column Header"));
    end;

    [Scope('OnPrem')]
    procedure ShowMappingCard(ReportCode: Code[20]; TableCode: Code[20]; LineNo: Integer; ColumnNo: Integer; var NewRecordDescription: Text[250])
    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
        StatReportTableColumn: Record "Stat. Report Table Column";
        TableIndividualRequisite: Record "Table Individual Requisite";
        UpdatedStatReportTableMapping: Record "Stat. Report Table Mapping";
        StatRepTableCellMapping: Page "Stat. Rep. Table Cell Mapping";
        NewRecord: Boolean;
        Description: Text[250];
    begin
        StatutoryReportTable.Get(ReportCode, TableCode);
        StatutoryReportTable.TestField("Int. Source Type");
        StatutoryReportTable.TestField("Int. Source No.");

        if ColumnNo <> 0 then begin
            StatReportTableColumn.Get(ReportCode, TableCode, ColumnNo);
            StatReportTableRow.Get(ReportCode, TableCode, LineNo);
            Description := StatReportTableRow.Description;
        end else begin
            TableIndividualRequisite.Get(ReportCode, TableCode, LineNo);
            Description := TableIndividualRequisite.Description
        end;
        if not StatReportTableMapping.Get(ReportCode, TableCode, LineNo, ColumnNo) then begin
            StatReportTableMapping.Init();
            StatReportTableMapping."Report Code" := ReportCode;
            StatReportTableMapping."Table Code" := TableCode;
            StatReportTableMapping."Table Row No." := LineNo;
            StatReportTableMapping."Table Column No." := ColumnNo;
            StatReportTableMapping."Table Row Description" := Description;
            StatReportTableMapping."Table Column Header" := StatReportTableColumn."Column Header";
            StatReportTableMapping."Int. Source Type" := StatutoryReportTable."Int. Source Type";
            StatReportTableMapping."Int. Source Section Code" := StatutoryReportTable."Int. Source Section Code";
            StatReportTableMapping.Validate("Int. Source No.", StatutoryReportTable."Int. Source No.");
            NewRecord := true;
        end;
        StatRepTableCellMapping.SetData(StatReportTableMapping);
        if StatRepTableCellMapping.RunModal() = ACTION::OK then begin
            StatRepTableCellMapping.GetRecord(UpdatedStatReportTableMapping);

            // UpdatedStatReportTableMapping pointing to Temporary table which is the source of StatRepTableCellMapping page
            // So we need copy fields (instead of direct variable assignment)
            StatReportTableMapping.TransferFields(UpdatedStatReportTableMapping);
            if NewRecord then
                StatReportTableMapping.Insert()
            else
                StatReportTableMapping.Modify();

            NewRecordDescription := StatReportTableMapping.GetRecDescription();
        end;
    end;
}

