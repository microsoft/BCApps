#pragma warning disable AA0247
table 26552 "Statutory Report Table"
{
    Caption = 'Statutory Report Table';
    LookupPageID = "Statutory Report Tables";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report";
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(9; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(11; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" where("Report Code" = field("Report Code"),
                                                                           "Report Data No." = const(''));

            trigger OnLookup()
            begin
                StatutoryReport.Get("Report Code");
                StatutoryReport.LookupExcelSheetNames("Excel Sheet Name");
            end;
        }
        field(12; "Scalable Table"; Boolean)
        {
            Caption = 'Scalable Table';

            trigger OnValidate()
            begin
                if not "Scalable Table" then begin
                    "Scalable Table First Row No." := 0;
                    "Scalable Table Row Step" := 0;
                    "Scalable Table Max Rows Qty" := 0;
                    "Vertical Table" := false;
                    DeletePageIndicationElements();

                    if not "Multipage Table" then begin
                        "Page Indication Text" := '';
                        "Page Indic. Excel Cell Name" := '';
                        "Page Indic. Requisite Line No." := 0;
                    end;
                end else begin
                    "Table Indication Text" := '';
                    "Table Indic. Excel Cell Name" := '';
                end;
            end;
        }
        field(15; "Row Code"; Text[20])
        {
            Caption = 'Row Code';
        }
        field(16; "Rows Quantity"; Integer)
        {
            CalcFormula = count("Stat. Report Table Row" where("Report Code" = field("Report Code"),
                                                                "Table Code" = field(Code)));
            Caption = 'Rows Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Columns Quantity"; Integer)
        {
            CalcFormula = count("Stat. Report Table Column" where("Report Code" = field("Report Code"),
                                                                   "Table Code" = field(Code)));
            Caption = 'Columns Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Scalable Table First Row No."; Integer)
        {
            Caption = 'Scalable Table First Row No.';

            trigger OnValidate()
            begin
                TestField("Scalable Table", true);
            end;
        }
        field(21; "Scalable Table Row Step"; Integer)
        {
            Caption = 'Scalable Table Row Step';

            trigger OnValidate()
            begin
                TestField("Scalable Table", true);
            end;
        }
        field(22; "Scalable Table Max Rows Qty"; Integer)
        {
            Caption = 'Scalable Table Max Rows Qty';
        }
        field(23; "Multipage Table"; Boolean)
        {
            Caption = 'Multipage Table';

            trigger OnValidate()
            begin
                if not "Multipage Table" then begin
                    "Table Indication Text" := '';
                    "Table Indic. Excel Cell Name" := '';

                    if not "Scalable Table" then begin
                        "Page Indication Text" := '';
                        "Page Indic. Excel Cell Name" := '';
                        "Page Indic. Requisite Line No." := 0;
                    end;

                    DeletePageIndicationElements();
                end;

                if "Multipage Table" then
                    "Vertical Table" := false;
            end;
        }
        field(24; "Page Indication Text"; Text[250])
        {
            Caption = 'Page Indication Text';

            trigger OnValidate()
            begin
                if not "Scalable Table" then
                    TestField("Multipage Table", true);
            end;
        }
        field(25; "Page Indic. Excel Cell Name"; Code[10])
        {
            Caption = 'Page Indic. Excel Cell Name';

            trigger OnValidate()
            begin
                if not "Scalable Table" then
                    TestField("Multipage Table", true);
            end;
        }
        field(26; "Page Indic. Requisite Line No."; Integer)
        {
            Caption = 'Page Indic. Requisite Line No.';
            TableRelation = "Table Individual Requisite"."Line No." where("Report Code" = field("Report Code"),
                                                                           "Table Code" = field(Code));

            trigger OnValidate()
            begin
                TestField("Multipage Table", true);
            end;
        }
        field(27; "Table Indication Text"; Text[250])
        {
            Caption = 'Table Indication Text';

            trigger OnValidate()
            begin
                if "Table Indication Text" <> '' then begin
                    TestField("Scalable Table", false);
                    TestField("Multipage Table", true);
                end;
            end;
        }
        field(28; "Table Indic. Excel Cell Name"; Code[10])
        {
            Caption = 'Table Indic. Excel Cell Name';

            trigger OnValidate()
            begin
                if "Table Indic. Excel Cell Name" <> '' then begin
                    TestField("Scalable Table", false);
                    TestField("Multipage Table", true);
                end;
            end;
        }
        field(30; "Parent Table Code"; Code[20])
        {
            Caption = 'Parent Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));

            trigger OnValidate()
            begin
                if "Parent Table Code" = Code then
                    FieldError("Parent Table Code");
            end;
        }
        field(31; "Vertical Table"; Boolean)
        {
            Caption = 'Vertical Table';

            trigger OnValidate()
            begin
                TestField("Scalable Table", true);
                if "Vertical Table" then
                    "Multipage Table" := false
                else
                    DeletePageIndicationElements();
            end;
        }
        field(50; "Int. Source Type"; Option)
        {
            Caption = 'Int. Source Type';
            OptionCaption = ' ,Acc. Schedule,Tax Register,Tax Difference';
            OptionMembers = " ","Acc. Schedule","Tax Register","Tax Difference";

            trigger OnValidate()
            begin
                if "Int. Source Type" <> xRec."Int. Source Type" then begin
                    "Int. Source Section Code" := '';
                    Validate("Int. Source No.", '');
                end;
            end;
        }
        field(51; "Int. Source Section Code"; Code[10])
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
                    Validate("Int. Source No.", '');
            end;
        }
        field(52; "Int. Source No."; Code[10])
        {
            Caption = 'Int. Source No.';
            TableRelation = if ("Int. Source Type" = const("Acc. Schedule")) "Acc. Schedule Name"
            else
            if ("Int. Source Type" = const("Tax Register")) "Tax Register"."No." where("Section Code" = field("Int. Source Section Code"))
            else
            if ("Int. Source Type" = const("Tax Difference")) "Tax Calc. Header"."No." where("Section Code" = field("Int. Source Section Code"));

            trigger OnValidate()
            begin
                if "Int. Source No." <> xRec."Int. Source No." then
                    if "Int. Source No." <> '' then begin
                        TestField("Int. Source Type");
                        UpdateIntSourceLinks();
                    end else
                        CheckIntSourceMappingExistence();
            end;
        }
        field(53; "Int. Source Col. Name"; Code[10])
        {
            Caption = 'Int. Source Column Layout';
            TableRelation = "Column Layout Name";
        }
    }

    keys
    {
        key(Key1; "Report Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Report Code", "Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StatReportTableColumn: Record "Stat. Report Table Column";
        StatReportTableRow: Record "Stat. Report Table Row";
        TableIndividualRequisite: Record "Table Individual Requisite";
        PageIndicationXMLElement: Record "Page Indication XML Element";
    begin
        StatReportTableColumn.SetRange("Report Code", "Report Code");
        StatReportTableColumn.SetRange("Table Code", Code);
        if StatReportTableColumn.FindFirst() then
            StatReportTableColumn.DeleteAll(true);

        StatReportTableRow.SetRange("Report Code", "Report Code");
        StatReportTableRow.SetRange("Table Code", Code);
        if StatReportTableRow.FindFirst() then
            StatReportTableRow.DeleteAll(true);

        TableIndividualRequisite.SetRange("Report Code", "Report Code");
        TableIndividualRequisite.SetRange("Table Code", Code);
        if TableIndividualRequisite.FindFirst() then
            TableIndividualRequisite.DeleteAll(true);

        PageIndicationXMLElement.SetRange("Report Code", "Report Code");
        PageIndicationXMLElement.SetRange("Table Code", Code);
        if PageIndicationXMLElement.FindFirst() then
            PageIndicationXMLElement.DeleteAll(true);
    end;

    var
        StatutoryReport: Record "Statutory Report";
        ExcelMgt: Codeunit "Excel Management";
#pragma warning disable AA0074
        Text008: Label 'You must specify an Acc. Schedule Name.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text009: Label 'You must specify a Column Layout Name.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text018: Label 'All related page indication elements will be deleted. Proceed?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text019: Label 'All related mapping information will be deleted. Do you want to continue?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text023: Label 'Account schedule has been created successfully.';
#pragma warning restore AA0074

    procedure CreateAccSchedule()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableColumn: Record "Stat. Report Table Column";
        CreateAccScheduleForm: Page "Create Acc. Schedule";
        AccSchedName: Code[10];
        ColLayoutName: Code[10];
        ReplaceExistLines: Boolean;
        LineNo: Integer;
    begin
        CreateAccScheduleForm.SetParameters("Report Code", Code);
        if CreateAccScheduleForm.RunModal() <> ACTION::OK then
            exit;

        CreateAccScheduleForm.GetParameters(AccSchedName, ColLayoutName, ReplaceExistLines);

        if AccSchedName = '' then
            Error(Text008);

        if ColLayoutName = '' then
            Error(Text009);

        AccScheduleLine.SetRange("Schedule Name", AccSchedName);
        if ReplaceExistLines then begin
            if AccScheduleLine.FindFirst() then
                AccScheduleLine.DeleteAll();
        end else begin
            if AccScheduleLine.FindLast() then;
            LineNo := AccScheduleLine."Line No.";
        end;

        StatReportTableRow.SetRange("Report Code", "Report Code");
        StatReportTableRow.SetRange("Table Code", Code);
        if StatReportTableRow.FindSet() then
            repeat
                LineNo := LineNo + 10000;
                AccScheduleLine.Init();
                AccScheduleLine."Schedule Name" := AccSchedName;
                AccScheduleLine."Line No." := LineNo;
                AccScheduleLine.Description := StatReportTableRow.Description;
                AccScheduleLine.Bold := StatReportTableRow.Bold;
                AccScheduleLine.Insert();
            until StatReportTableRow.Next() = 0;

        ColumnLayout.SetRange("Column Layout Name", ColLayoutName);
        if ColumnLayout.IsEmpty() then begin
            LineNo := 0;
            StatReportTableColumn.SetRange("Report Code", "Report Code");
            StatReportTableColumn.SetRange("Table Code", Code);
            if StatReportTableColumn.FindSet() then
                repeat
                    LineNo := LineNo + 10000;
                    ColumnLayout."Column Layout Name" := ColLayoutName;
                    ColumnLayout."Line No." := LineNo;
                    ColumnLayout."Column Header" :=
                      CopyStr(StatReportTableColumn."Column Header",
                        1,
                        MaxStrLen(ColumnLayout."Column Header"));
                    ColumnLayout.Insert();
                until StatReportTableColumn.Next() = 0;
        end;

        Message(Text023);
    end;

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(StrSubstNo('%1 %2=''%3'', %4=''%5''', TableCaption(),
            FieldCaption("Report Code"), "Report Code",
            FieldCaption(Code), Code));
    end;

    [Scope('OnPrem')]
    procedure CopyTableStructure(ReportFromCode: Code[20]; TableFromCode: Code[20])
    var
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableRowFrom: Record "Stat. Report Table Row";
        StatReportTableColumn: Record "Stat. Report Table Column";
        StatReportTableColumnFrom: Record "Stat. Report Table Column";
        TableIndividualRequisite: Record "Table Individual Requisite";
        TableIndividualRequisiteFrom: Record "Table Individual Requisite";
    begin
        StatReportTableRowFrom.SetRange("Report Code", ReportFromCode);
        StatReportTableRowFrom.SetRange("Table Code", TableFromCode);
        if StatReportTableRowFrom.FindSet() then
            repeat
                StatReportTableRow := StatReportTableRowFrom;
                StatReportTableRow."Report Code" := "Report Code";
                StatReportTableRow.Insert();
            until StatReportTableRowFrom.Next() = 0;

        StatReportTableColumnFrom.SetRange("Report Code", ReportFromCode);
        StatReportTableColumnFrom.SetRange("Table Code", TableFromCode);
        if StatReportTableColumnFrom.FindSet() then
            repeat
                StatReportTableColumn := StatReportTableColumnFrom;
                StatReportTableColumn."Report Code" := "Report Code";
                StatReportTableColumn.Insert();
            until StatReportTableColumnFrom.Next() = 0;

        TableIndividualRequisiteFrom.SetRange("Report Code", ReportFromCode);
        TableIndividualRequisiteFrom.SetRange("Table Code", TableFromCode);
        if TableIndividualRequisiteFrom.FindSet() then
            repeat
                TableIndividualRequisite := TableIndividualRequisiteFrom;
                TableIndividualRequisite."Report Code" := "Report Code";
                TableIndividualRequisite.Insert();
            until TableIndividualRequisiteFrom.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportExcelSheet(DataHeaderNo: Code[20]; var TempExcelBuffer: Record "Excel Buffer" temporary; ExcelSheetName: Text[30]; var ErrorMessage: Text[250]): Boolean
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        PrevStatReportExcelSheet: Record "Stat. Report Excel Sheet";
    begin
        StatReportExcelSheet."Report Code" := "Report Code";
        StatReportExcelSheet."Table Code" := Code;
        StatReportExcelSheet."Report Data No." := DataHeaderNo;
        StatReportExcelSheet."Sheet Name" := ExcelSheetName;
        StatReportExcelSheet."Parent Sheet Name" := "Excel Sheet Name";
        if "Excel Sheet Name" = ExcelSheetName then
            StatReportExcelSheet."New Page" := true;
        StatReportExcelSheet.Insert(true);

        StatutoryReport.Get("Report Code");

        if not ImportExcelSheetXML(DataHeaderNo, TempExcelBuffer, ExcelSheetName, ErrorMessage, StatReportExcelSheet) then
            exit(false);

        if "Multipage Table" and not "Scalable Table" then begin
            StatReportExcelSheet."New Page" := true;
            StatReportExcelSheet.Modify();
        end;

        if "Multipage Table" and "Scalable Table" then begin
            PrevStatReportExcelSheet.SetCurrentKey("Report Code", "Table Code", "Report Data No.", "Parent Sheet Name", "Sequence No.");
            PrevStatReportExcelSheet.SetRange("Report Code", "Report Code");
            PrevStatReportExcelSheet.SetRange("Report Data No.", DataHeaderNo);
            PrevStatReportExcelSheet.SetRange("Table Code", Code);
            PrevStatReportExcelSheet.SetRange("Parent Sheet Name", StatReportExcelSheet."Parent Sheet Name");
            PrevStatReportExcelSheet.SetFilter("Sequence No.", '<%1', StatReportExcelSheet."Sequence No.");
            if PrevStatReportExcelSheet.FindLast() then begin
                if StatReportExcelSheet."Page Indic. Requisite Value" <>
                   PrevStatReportExcelSheet."Page Indic. Requisite Value"
                then begin
                    StatReportExcelSheet."New Page" := true;
                    StatReportExcelSheet.Modify();
                end;
            end else begin
                StatReportExcelSheet."New Page" := true;
                StatReportExcelSheet.Modify();
            end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImportExcelSheetXML(DataHeaderNo: Code[20]; var TempExcelBuffer: Record "Excel Buffer" temporary; ExcelSheetName: Text[30]; var ErrorMessage: Text[250]; var StatReportExcelSheet: Record "Stat. Report Excel Sheet"): Boolean
    var
        ParentStatReportExcelSheet: Record "Stat. Report Excel Sheet";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        XMLElementLine: Record "XML Element Line";
        CellValueAsText: Text[250];
    begin
        if "Scalable Table" then
            if not ImportScalableTableDataXML(DataHeaderNo, TempExcelBuffer, ExcelSheetName, ErrorMessage) then
                exit(false);

        XMLElementLine.SetRange("Report Code", "Report Code");
        XMLElementLine.SetRange("Table Code", Code);
        if "Scalable Table" then
            XMLElementLine.SetRange("Source Type", XMLElementLine."Source Type"::"Individual Element",
              XMLElementLine."Source Type"::"Inserted Element")
        else
            XMLElementLine.SetRange("Source Type", XMLElementLine."Source Type"::"Table Data",
              XMLElementLine."Source Type"::"Inserted Element");
        if XMLElementLine.FindSet() then
            repeat
                if XMLElementLine."Excel Cell Name" <> '' then begin
                    CellValueAsText := '';
                    if not XMLElementLine.ImportFromExcel(TempExcelBuffer, CellValueAsText,
                         ErrorMessage, XMLElementLine."Excel Cell Name")
                    then
                        exit(false);

                    StatutoryReportDataValue.Init();
                    StatutoryReportDataValue."Report Data No." := DataHeaderNo;
                    StatutoryReportDataValue."Report Code" := "Report Code";
                    StatutoryReportDataValue."Table Code" := XMLElementLine."Table Code";
                    StatutoryReportDataValue."Excel Sheet Name" := ExcelSheetName;
                    StatutoryReportDataValue."Row No." := XMLElementLine."Row Link No.";
                    StatutoryReportDataValue."Column No." := XMLElementLine."Column Link No.";
                    if not XMLElementLine.FormatValue(2, CellValueAsText, StatutoryReportDataValue.Value, ErrorMessage) then
                        exit(false);
                    StatutoryReportDataValue.Insert();
                end;
            until XMLElementLine.Next() = 0;

        UpdatePageIndicReqValue(DataHeaderNo, ExcelSheetName, StatReportExcelSheet);

        if "Parent Table Code" <> '' then begin
            // take page indication Requisite value from the last sheet of the parent table
            ParentStatReportExcelSheet.SetCurrentKey("Report Code", "Report Data No.", "Table Sequence No.");
            ParentStatReportExcelSheet.SetRange("Report Code", "Report Code");
            ParentStatReportExcelSheet.SetRange("Report Data No.", DataHeaderNo);
            ParentStatReportExcelSheet.SetRange("Table Code", "Parent Table Code");
            if ParentStatReportExcelSheet.FindLast() then
                if StatReportExcelSheet."Page Indic. Requisite Value" = '' then begin
                    StatReportExcelSheet."Page Indic. Requisite Value" := ParentStatReportExcelSheet."Page Indic. Requisite Value";
                    StatReportExcelSheet.Modify();
                end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImportScalableTableDataXML(ResultCode: Code[20]; var TempExcelBuffer: Record "Excel Buffer" temporary; ExcelSheetName: Text[30]; var ErrorMessage: Text[250]): Boolean
    var
        StatReportTableColumn: Record "Stat. Report Table Column";
        ScalableTableRow: Record "Scalable Table Row";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        XMLElementLine: Record "XML Element Line";
        CellValueAsText: Text[250];
        CellName: Code[10];
        DistensTabMaxRowNumber: Integer;
        CurrRowNo: Integer;
        LineNo: Integer;
    begin
        DistensTabMaxRowNumber := "Scalable Table First Row No." +
          "Scalable Table Max Rows Qty" * "Scalable Table Row Step";

        CurrRowNo := "Scalable Table First Row No.";
        while CurrRowNo < DistensTabMaxRowNumber do begin
            StatReportTableColumn.SetRange("Report Code", "Report Code");
            StatReportTableColumn.SetRange("Table Code", Code);
            if StatReportTableColumn.FindSet() then
                repeat
                    XMLElementLine.SetRange("Report Code", "Report Code");
                    XMLElementLine.SetRange("Table Code", Code);
                    XMLElementLine.SetRange("Column Link No.", StatReportTableColumn."Line No.");
                    if XMLElementLine.FindFirst() then begin
                        CellValueAsText := '';
                        if "Vertical Table" then
                            CellName := ExcelMgt.CellName2ColumnName(XMLElementLine."Excel Cell Name") +
                              Format(CurrRowNo + StatReportTableColumn."Vert. Table Row Shift")
                        else
                            CellName := ExcelMgt.CellName2ColumnName(XMLElementLine."Excel Cell Name") +
                              Format(CurrRowNo + ExcelMgt.CellName2RowNo(XMLElementLine."Excel Cell Name") - "Scalable Table First Row No.");

                        if not XMLElementLine.ImportFromExcel(TempExcelBuffer, CellValueAsText, ErrorMessage, CellName) then
                            exit(false);

                        ScalableTableRow.SetRange("Report Data No.", ResultCode);
                        ScalableTableRow.SetRange("Report Code", "Report Code");
                        ScalableTableRow.SetRange("Table Code", Code);
                        ScalableTableRow.SetRange("Excel Sheet Name", ExcelSheetName);
                        ScalableTableRow.SetRange("Excel Row No.", CurrRowNo);
                        if not ScalableTableRow.FindFirst() then begin
                            ScalableTableRow.SetRange("Report Data No.", ResultCode);
                            ScalableTableRow.SetRange("Report Code", "Report Code");
                            ScalableTableRow.SetRange("Table Code", Code);
                            ScalableTableRow.SetRange("Excel Sheet Name", ExcelSheetName);
                            if ScalableTableRow.FindLast() then;
                            LineNo := ScalableTableRow."Line No." + 10000;

                            ScalableTableRow.Init();
                            ScalableTableRow."Report Data No." := ResultCode;
                            ScalableTableRow."Report Code" := "Report Code";
                            ScalableTableRow."Table Code" := Code;
                            ScalableTableRow."Excel Sheet Name" := ExcelSheetName;
                            ScalableTableRow."Line No." := LineNo;
                            ScalableTableRow."Excel Row No." := CurrRowNo;
                            ScalableTableRow.Insert();
                        end;

                        StatutoryReportDataValue.Init();
                        StatutoryReportDataValue."Report Data No." := ResultCode;
                        StatutoryReportDataValue."Report Code" := "Report Code";
                        StatutoryReportDataValue."Table Code" := Code;
                        StatutoryReportDataValue."Excel Sheet Name" := ExcelSheetName;
                        StatutoryReportDataValue."Row No." := ScalableTableRow."Line No.";
                        StatutoryReportDataValue."Column No." := StatReportTableColumn."Line No.";
                        if not XMLElementLine.FormatValue(2, CellValueAsText, StatutoryReportDataValue.Value, ErrorMessage) then
                            exit(false);
                        StatutoryReportDataValue.Insert();
                    end;
                until StatReportTableColumn.Next() = 0;

            CurrRowNo := CurrRowNo + "Scalable Table Row Step";
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckTableIdentText(var TempExcelBuffer: Record "Excel Buffer" temporary): Boolean
    begin
        if "Table Indic. Excel Cell Name" <> '' then
            exit(TempExcelBuffer.GetValueByCellName("Table Indic. Excel Cell Name") = "Table Indication Text");

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetXMLElementValue(var XMLElementLine: Record "XML Element Line"; DataHeaderNo: Code[20]; ExcelSheetName: Text[30]): Text[250]
    var
        StatRepBuffer: Record "Statutory Report Buffer";
    begin
        StatRepBuffer."Report Data No." := DataHeaderNo;
        StatRepBuffer."Excel Sheet Name" := ExcelSheetName;
        exit(XMLElementLine.GetElementValue(StatRepBuffer));
    end;

    [Scope('OnPrem')]
    procedure DeletePageIndicationElements()
    var
        PageIndicationXMLElement: Record "Page Indication XML Element";
    begin
        if (not "Vertical Table") and (not "Multipage Table") then begin
            PageIndicationXMLElement.SetRange("Report Code", "Report Code");
            PageIndicationXMLElement.SetRange("Table Code", Code);
            if not PageIndicationXMLElement.IsEmpty() then begin
                if not Confirm(Text018) then
                    Error('');
                PageIndicationXMLElement.DeleteAll();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateIntSourceLinks()
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        ColumnLayout: Record "Column Layout";
        TaxRegisterTemplate: Record "Tax Register Template";
        TaxRegisterAccumulation: Record "Tax Register Accumulation";
        TaxCalcLine: Record "Tax Calc. Line";
        StatReportTableRow: Record "Stat. Report Table Row";
        StatReportTableColumn: Record "Stat. Report Table Column";
        StatReportTableMapping: Record "Stat. Report Table Mapping";
    begin
        CheckIntSourceMappingExistence();

        StatReportTableColumn.SetRange("Report Code", "Report Code");
        StatReportTableColumn.SetRange("Table Code", Code);

        case "Int. Source Type" of
            "Int. Source Type"::"Acc. Schedule":
                begin
                    Rec.TestField("Int. Source Col. Name");
                    AccScheduleLine.SetRange("Schedule Name", "Int. Source No.");
                    StatReportTableRow.SetRange("Report Code", "Report Code");
                    StatReportTableRow.SetRange("Table Code", Code);

                    ColumnLayout.SetRange("Column Layout Name", Rec."Int. Source Col. Name");

                    if AccScheduleLine.FindSet() and StatReportTableRow.FindSet() then
                        repeat
                            if ColumnLayout.FindSet() and StatReportTableColumn.FindSet() then
                                repeat
                                    StatReportTableMapping.Init();
                                    StatReportTableMapping."Report Code" := "Report Code";
                                    StatReportTableMapping."Table Code" := Code;
                                    StatReportTableMapping."Table Row No." := StatReportTableRow."Line No.";
                                    StatReportTableMapping."Table Column No." := StatReportTableColumn."Line No.";
                                    StatReportTableMapping."Table Row Description" := StatReportTableRow.Description;
                                    StatReportTableMapping."Table Column Header" := StatReportTableColumn."Column Header";
                                    StatReportTableMapping."Int. Source Type" := "Int. Source Type";
                                    StatReportTableMapping."Int. Source Section Code" := "Int. Source Section Code";
                                    StatReportTableMapping."Int. Source No." := "Int. Source No.";
                                    StatReportTableMapping."Internal Source Row No." := AccScheduleLine."Line No.";
                                    StatReportTableMapping."Internal Source Column No." := ColumnLayout."Line No.";
                                    StatReportTableMapping."Int. Source Row Description" := AccScheduleLine.Description;
                                    StatReportTableMapping."Int. Source Column Header" := ColumnLayout."Column Header";
                                    StatReportTableMapping.Insert();
                                until (ColumnLayout.Next() = 0) or (StatReportTableColumn.Next() = 0);
                        until (AccScheduleLine.Next() = 0) or (StatReportTableRow.Next() = 0);
                end;
            "Int. Source Type"::"Tax Register":
                begin
                    TaxRegisterTemplate.SetRange("Section Code", "Int. Source Section Code");
                    TaxRegisterTemplate.SetRange(Code, "Int. Source No.");
                    StatReportTableRow.SetRange("Report Code", "Report Code");
                    StatReportTableRow.SetRange("Table Code", Code);

                    if TaxRegisterTemplate.FindSet() and
                       StatReportTableColumn.FindFirst() and
                       StatReportTableRow.FindSet()
                    then
                        repeat
                            StatReportTableMapping.Init();
                            StatReportTableMapping."Report Code" := "Report Code";
                            StatReportTableMapping."Table Code" := Code;
                            StatReportTableMapping."Table Row No." := StatReportTableRow."Line No.";
                            StatReportTableMapping."Table Column No." := StatReportTableColumn."Line No.";
                            StatReportTableMapping."Table Row Description" := StatReportTableRow.Description;
                            StatReportTableMapping."Table Column Header" := StatReportTableColumn."Column Header";
                            StatReportTableMapping."Int. Source Type" := "Int. Source Type";
                            StatReportTableMapping."Int. Source Section Code" := "Int. Source Section Code";
                            StatReportTableMapping."Int. Source No." := "Int. Source No.";
                            StatReportTableMapping."Internal Source Row No." := TaxRegisterTemplate."Line No.";
                            StatReportTableMapping."Internal Source Column No." := 10000;
                            StatReportTableMapping."Int. Source Row Description" := TaxRegisterTemplate.Description;
                            StatReportTableMapping."Int. Source Column Header" := TaxRegisterAccumulation.FieldCaption(Amount);
                            StatReportTableMapping.Insert();
                        until (TaxRegisterTemplate.Next() = 0) or (StatReportTableRow.Next() = 0);
                end;
            "Int. Source Type"::"Tax Difference":
                begin
                    TaxCalcLine.SetRange("Section Code", "Int. Source Section Code");
                    TaxCalcLine.SetRange(Code, "Int. Source No.");
                    StatReportTableRow.SetRange("Report Code", "Report Code");
                    StatReportTableRow.SetRange("Table Code", Code);

                    if TaxCalcLine.FindSet() and
                       StatReportTableColumn.FindFirst() and
                       StatReportTableRow.FindSet()
                    then
                        repeat
                            StatReportTableMapping.Init();
                            StatReportTableMapping."Report Code" := "Report Code";
                            StatReportTableMapping."Table Code" := Code;
                            StatReportTableMapping."Table Row No." := StatReportTableRow."Line No.";
                            StatReportTableMapping."Table Column No." := StatReportTableColumn."Line No.";
                            StatReportTableMapping."Table Row Description" := StatReportTableRow.Description;
                            StatReportTableMapping."Table Column Header" := StatReportTableColumn."Column Header";
                            StatReportTableMapping."Int. Source Type" := "Int. Source Type";
                            StatReportTableMapping."Int. Source Section Code" := "Int. Source Section Code";
                            StatReportTableMapping."Int. Source No." := "Int. Source No.";
                            StatReportTableMapping."Internal Source Row No." := TaxCalcLine."Line No.";
                            StatReportTableMapping."Internal Source Column No." := 10000;
                            StatReportTableMapping."Int. Source Row Description" := TaxCalcLine.Description;
                            StatReportTableMapping."Int. Source Column Header" := TaxRegisterAccumulation.FieldCaption(Amount);
                            StatReportTableMapping.Insert();
                        until (TaxCalcLine.Next() = 0) or (StatReportTableRow.Next() = 0);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckIntSourceMappingExistence()
    var
        StatReportTableMapping: Record "Stat. Report Table Mapping";
    begin
        StatReportTableMapping.SetRange("Report Code", "Report Code");
        StatReportTableMapping.SetRange("Table Code", Code);
        StatReportTableMapping.SetFilter("Table Column No.", '<>0');
        if not StatReportTableMapping.IsEmpty() then
            if Confirm(Text019) then
                StatReportTableMapping.DeleteAll()
            else
                Error('');
    end;

    [Scope('OnPrem')]
    procedure UpdatePageIndicReqValue(DataHeaderNo: Code[20]; ExcelSheetName: Text[30]; var StatReportExcelSheet: Record "Stat. Report Excel Sheet")
    var
        XMLElementLine: Record "XML Element Line";
        PageIndicationXMLElement: Record "Page Indication XML Element";
        RequisiteValue: Text[250];
    begin
        PageIndicationXMLElement.SetRange("Report Code", "Report Code");
        PageIndicationXMLElement.SetRange("Table Code", Code);
        if PageIndicationXMLElement.FindSet() then begin
            repeat
                XMLElementLine.Get("Report Code", PageIndicationXMLElement."XML Element Line No.");
                RequisiteValue := GetXMLElementValue(XMLElementLine, DataHeaderNo, ExcelSheetName);
                if RequisiteValue <> '' then
                    StatReportExcelSheet."Page Indic. Requisite Value" := StatReportExcelSheet."Page Indic. Requisite Value" + RequisiteValue;
            until PageIndicationXMLElement.Next() = 0;

            StatReportExcelSheet.Modify();
        end;
    end;
}

