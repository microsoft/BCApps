#pragma warning disable AA0247
table 26570 "XML Element Line"
{
    Caption = 'XML Element Line';
    LookupPageID = "XML Element Line List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Report Code"; Code[20])
        {
            Caption = 'Report Code';
            TableRelation = "Statutory Report".Code;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Element Name"; Text[150])
        {
            Caption = 'Element Name';
            NotBlank = true;
        }
        field(4; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
        }
        field(5; "Parent Element Name"; Text[150])
        {
            Caption = 'Parent Element Name';
        }
        field(6; "Element Type"; Option)
        {
            Caption = 'Element Type';
            OptionCaption = 'Complex,Simple,Attribute';
            OptionMembers = Complex,Simple,Attribute;

            trigger OnValidate()
            begin
                if "Element Type" <> xRec."Element Type" then
                    if "Element Type" = "Element Type"::Complex then begin
                        TestField("Data Type", "Data Type"::" ");
                        TestField("Source Type", "Source Type"::" ");
                        if "Link Type" = "Link Type"::Value then
                            FieldError("Link Type");
                    end else
                        if "Link Type" in ["Link Type"::Table, "Link Type"::Grouping] then
                            FieldError("Link Type");
            end;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(8; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(9; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(10; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = ' ,Text,Integer,Decimal,Date';
            OptionMembers = " ",Text,"Integer",Decimal,Date;

            trigger OnValidate()
            begin
                if "Data Type" <> xRec."Data Type" then begin
                    if "Data Type" <> "Data Type"::" " then
                        if "Element Type" = "Element Type"::Complex then
                            FieldError("Element Type");
                    "XML Export Date Format" := "XML Export Date Format"::" ";
                end;
            end;
        }
        field(12; "Link Type"; Option)
        {
            Caption = 'Link Type';
            OptionCaption = ' ,Value,Table,Grouping';
            OptionMembers = " ",Value,"Table",Grouping;

            trigger OnValidate()
            begin
                if "Link Type" <> xRec."Link Type" then
                    TestField("Source Type", "Source Type"::" ");

                case "Link Type" of
                    "Link Type"::" ":
                        "Table Code" := '';
                    "Link Type"::Value:
                        begin
                            if "Element Type" = "Element Type"::Complex then
                                FieldError("Element Type");

                            if "Source Type" = "Source Type"::" " then
                                "Source Type" := "Source Type"::"Table Data";
                        end;
                end;
            end;
        }
        field(13; "Service Element"; Boolean)
        {
            Caption = 'Service Element';
        }
        field(15; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            TableRelation = "Statutory Report Table".Code where("Report Code" = field("Report Code"));

            trigger OnValidate()
            var
                StatReportTableColumn: Record "Stat. Report Table Column";
            begin
                if "Table Code" <> xRec."Table Code" then begin
                    "Row Link No." := 0;
                    "Column Link No." := 0;
                end;

                if ("Table Code" <> '') and
                   ("Link Type" = "Link Type"::Value) and
                   ("Source Type" = "Source Type"::"Table Data")
                then begin
                    StatReportTableColumn.SetRange("Report Code", "Report Code");
                    StatReportTableColumn.SetRange("Table Code", "Table Code");
                    if StatReportTableColumn.Count = 1 then begin
                        StatReportTableColumn.FindFirst();
                        "Column Link No." := StatReportTableColumn."Line No.";
                    end;
                end;
            end;
        }
        field(18; "Export Type"; Option)
        {
            Caption = 'Export Type';
            OptionCaption = 'Required,Optional';
            OptionMembers = Required,Optional;
        }
        field(22; Choice; Boolean)
        {
            Caption = 'Choice';

            trigger OnValidate()
            begin
                if Choice then
                    TestField("Element Type", "Element Type"::Complex);
            end;
        }
        field(30; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Expression,Constant,Table Data,Individual Element,Inserted Element,Compound Element';
            OptionMembers = " ",Expression,Constant,"Table Data","Individual Element","Inserted Element","Compound Element";
        }
        field(31; Value; Text[250])
        {
            Caption = 'Value';

            trigger OnValidate()
            begin
                if Value <> '' then
                    TestField("Source Type", "Source Type"::Constant);
            end;
        }
        field(32; "Row Link No."; Integer)
        {
            Caption = 'Row Link No.';

            trigger OnValidate()
            begin
                if "Row Link No." <> 0 then begin
                    if not ("Source Type" in
                            ["Source Type"::"Table Data", "Source Type"::"Individual Element", "Source Type"::"Inserted Element"])
                    then
                        FieldError("Source Type");

                    if "Source Type" in ["Source Type"::"Table Data", "Source Type"::"Inserted Element"] then
                        StatReportTableRow.Get("Report Code", "Table Code", "Row Link No.");

                    if "Source Type" = "Source Type"::"Individual Element" then
                        TableIndividualRequisite.Get("Report Code", "Table Code", "Row Link No.");
                end;
            end;
        }
        field(33; "Column Link No."; Integer)
        {
            Caption = 'Column Link No.';

            trigger OnValidate()
            begin
                if "Column Link No." <> 0 then begin
                    TestField("Table Code");
                    TestField("Source Type", "Source Type"::"Table Data");

                    if "Column Link No." > 0 then
                        StatReportTableColumn.Get("Report Code", "Table Code", "Column Link No.");
                end;
            end;
        }
        field(34; "Excel Mapping Type"; Option)
        {
            Caption = 'Excel Mapping Type';
            OptionCaption = 'Single-cell,Multi-cell';
            OptionMembers = "Single-cell","Multi-cell";

            trigger OnValidate()
            begin
                if "Excel Mapping Type" <> xRec."Excel Mapping Type" then begin
                    "Horizontal Cells Quantity" := 1;
                    "Vertical Cells Quantity" := 1;
                    "Vertical Cells Delta" := 1;
                end;
            end;
        }
        field(35; "Excel Cell Name"; Code[10])
        {
            Caption = 'Excel Cell Name';
        }
        field(36; "Horizontal Cells Quantity"; Integer)
        {
            Caption = 'Horizontal Cells Quantity';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                TestField("Excel Mapping Type", "Excel Mapping Type"::"Multi-cell");
            end;
        }
        field(37; "Vertical Cells Quantity"; Integer)
        {
            Caption = 'Vertical Cells Quantity';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                TestField("Excel Mapping Type", "Excel Mapping Type"::"Multi-cell");
            end;
        }
        field(38; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            TableRelation = "Stat. Report Excel Sheet"."Sheet Name" where("Report Code" = field("Report Code"),
                                                                           "Report Data No." = const(''));
        }
        field(40; "Fraction Digits"; Integer)
        {
            Caption = 'Fraction Digits';
        }
        field(41; "OKEI Scaling"; Boolean)
        {
            Caption = 'OKEI Scaling';
        }
        field(42; "XML Export Date Format"; Option)
        {
            Caption = 'XML Export Date Format';
            OptionCaption = ' ,YYYY-MM-DD';
            OptionMembers = " ","YYYY-MM-DD";

            trigger OnValidate()
            begin
                if "XML Export Date Format" <> "XML Export Date Format"::" " then
                    TestField("Data Type", "Data Type"::Date);
            end;
        }
        field(43; Alignment; Option)
        {
            Caption = 'Alignment';
            OptionCaption = 'Left,Right';
            OptionMembers = Left,Right;
        }
        field(44; "Pad Character"; Text[1])
        {
            Caption = 'Pad Character';
        }
        field(45; "Template Data"; Boolean)
        {
            Caption = 'Template Data';
        }
        field(47; "Vertical Cells Delta"; Integer)
        {
            Caption = 'Vertical Cells Delta';

            trigger OnValidate()
            begin
                if "Vertical Cells Delta" <> 0 then
                    TestField("Excel Mapping Type", "Excel Mapping Type"::"Multi-cell");
            end;
        }
    }

    keys
    {
        key(Key1; "Report Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Report Code", "Parent Line No.", "Sequence No.")
        {
        }
        key(Key3; "Report Code", "Sequence No.")
        {
        }
        key(Key4; "Report Code", "Table Code", "Row Link No.", "Column Link No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
    begin
        CheckReportDataExistence(Text001);

        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
        if not XMLElementExpressionLine.IsEmpty() then
            XMLElementExpressionLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestField("Element Name");
        CheckReportDataExistence(Text002);
    end;

    trigger OnModify()
    begin
        CheckReportDataExistence(Text005);
    end;

    var
        StatutoryReport: Record "Statutory Report";
        StatReportTableRow: Record "Stat. Report Table Row";
        TableIndividualRequisite: Record "Table Individual Requisite";
        StatReportTableColumn: Record "Stat. Report Table Column";
        StatutoryReportSetup: Record "Statutory Report Setup";
        FormatVersion: Record "Format Version";
        ExcelMgt: Codeunit "Excel Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 cannot be deleted because %2 %3 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label '%1 cannot be inserted because %2 %3 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '''%1'' can not be formated to %2 for %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        EntryNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'You must specify %1 in %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label '%1 cannot be modified because %2 %3 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label '%1 is not defined in %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure ExportValue(var XMLNode: DotNet XmlNode; StatRepBuffer: Record "Statutory Report Buffer"; var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        CreatedXMLNode: DotNet XmlNode;
    begin
        case "Element Type" of
            "Element Type"::Complex:
                case "Link Type" of
                    "Link Type"::Grouping:
                        ProcessGrouping(XMLNode, StatRepBuffer, ElementValueBuffer);
                    "Link Type"::Table:
                        ProcessTable(XMLNode, StatRepBuffer, ElementValueBuffer);
                    else begin
                        AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);
                        if "Element Name" = 'öá®½' then begin
                            StatutoryReport.Get("Report Code");
                            FormatVersion.Get(StatutoryReport."Format Version Code");
                            FormatVersion.TestField("Version No.");
                            if FormatVersion."Version No."[1] = '4' then begin
                                AddAttribute(
                                  CreatedXMLNode,
                                  'xmlns:xsi',
                                  'http://www.w3.org/2001/XMLSchema-instance');

                                AddAttribute(
                                  CreatedXMLNode,
                                  'xsi:noNamespaceSchemaLocation',
                                  FormatVersion."XML Schema File Name");
                            end;
                        end;

                        ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                        CheckEmptyNode(XMLNode, CreatedXMLNode);
                    end;
                end;
            "Element Type"::Attribute:
                AddAttribute(XMLNode, "Element Name", GetElementFormattedValue(StatRepBuffer, ElementValueBuffer));
            "Element Type"::Simple:
                AddElement(XMLNode, "Element Name", GetElementFormattedValue(StatRepBuffer, ElementValueBuffer), '', CreatedXMLNode);
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessGrouping(var XMLNode: DotNet XmlNode; StatRepBuffer: Record "Statutory Report Buffer"; var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        StatutoryReportTable: Record "Statutory Report Table";
        ScalableTableRow: Record "Scalable Table Row";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        PageIndicBuffer: Record "Statutory Report Buffer" temporary;
        XMLElementLine: Record "XML Element Line";
        PageIndicationXMLElement: Record "Page Indication XML Element";
        CreatedXMLNode: DotNet XmlNode;
        EntryNo: Integer;
        IndicElementValue: Text[250];
    begin
        TestField("Table Code");

        StatutoryReportTable.Get("Report Code", "Table Code");

        if StatutoryReportTable."Vertical Table" then begin
            StatReportExcelSheet.SetCurrentKey("Report Code", "Report Data No.", "Sequence No.");
            StatReportExcelSheet.SetRange("Report Code", "Report Code");
            StatReportExcelSheet.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
            StatReportExcelSheet.SetRange("Table Code", "Table Code");
            if StatReportExcelSheet.FindSet() then
                repeat
                    // collect indication values from scalable table rows
                    ScalableTableRow.SetRange("Report Code", "Report Code");
                    ScalableTableRow.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
                    ScalableTableRow.SetRange("Table Code", StatutoryReportTable.Code);
                    if ScalableTableRow.FindSet() then
                        repeat
                            StatRepBuffer."Scalable Table Row No." := ScalableTableRow."Line No.";
                            StatRepBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";

                            IndicElementValue := '';
                            PageIndicationXMLElement.SetRange("Report Code", "Report Code");
                            PageIndicationXMLElement.SetRange("Table Code", "Table Code");
                            if PageIndicationXMLElement.FindSet() then
                                repeat
                                    XMLElementLine.Get("Report Code", PageIndicationXMLElement."XML Element Line No.");
                                    IndicElementValue := IndicElementValue + XMLElementLine.GetElementValue(StatRepBuffer);
                                until PageIndicationXMLElement.Next() = 0;

                            if IndicElementValue <> '' then begin
                                PageIndicBuffer.SetRange("Page Indic. Requisite Value", IndicElementValue);
                                if PageIndicBuffer.IsEmpty() then begin
                                    EntryNo := EntryNo + 1;
                                    PageIndicBuffer."Entry No." := EntryNo;
                                    PageIndicBuffer."Page Indic. Requisite Value" := IndicElementValue;
                                    PageIndicBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                                    PageIndicBuffer.Insert();
                                end;
                            end;
                        until ScalableTableRow.Next() = 0;
                until StatReportExcelSheet.Next() = 0;

            PageIndicBuffer.Reset();
            if PageIndicBuffer.FindSet() then begin
                AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);

                repeat
                    StatRepBuffer."Excel Sheet Name" := PageIndicBuffer."Excel Sheet Name";
                    StatRepBuffer."Page Indic. Requisite Value" := PageIndicBuffer."Page Indic. Requisite Value";
                    StatRepBuffer."Scalable Table Row No." := 0;

                    ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                until PageIndicBuffer.Next() = 0;

                CheckEmptyNode(XMLNode, CreatedXMLNode);
            end;
        end else begin
            // collect indication values from Excel sheets
            StatReportExcelSheet.SetCurrentKey("Report Code", "Report Data No.", "Sequence No.");
            StatReportExcelSheet.SetRange("Report Code", "Report Code");
            StatReportExcelSheet.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
            StatReportExcelSheet.SetRange("Table Code", "Table Code");
            if StatReportExcelSheet.FindSet() then
                repeat
                    if StatutoryReportTable."Multipage Table" and (not StatutoryReportTable."Scalable Table") and
                       (StatReportExcelSheet."Page Indic. Requisite Value" = '')
                    then begin
                        // ñ½´ ÓÑá½¿ºáµ¿¿ ßÔÓ. 16 ½¿ßÔ 03 »Ó«ñ«½ªÑ¡¿Ñ
                        EntryNo := EntryNo + 1;
                        PageIndicBuffer."Entry No." := EntryNo;
                        PageIndicBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                        PageIndicBuffer."Page Indic. Requisite Value" := StatReportExcelSheet."Page Indic. Requisite Value";
                        PageIndicBuffer.Insert();
                    end else begin
                        PageIndicBuffer.SetRange("Page Indic. Requisite Value", StatReportExcelSheet."Page Indic. Requisite Value");
                        if PageIndicBuffer.IsEmpty() then begin
                            EntryNo := EntryNo + 1;
                            PageIndicBuffer."Entry No." := EntryNo;
                            PageIndicBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                            PageIndicBuffer."Page Indic. Requisite Value" := StatReportExcelSheet."Page Indic. Requisite Value";
                            PageIndicBuffer.Insert();
                        end;
                    end;
                until StatReportExcelSheet.Next() = 0;

            PageIndicBuffer.Reset();
            if PageIndicBuffer.FindSet() then
                repeat
                    AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);

                    StatRepBuffer."Excel Sheet Name" := PageIndicBuffer."Excel Sheet Name";
                    StatRepBuffer."Page Indic. Requisite Value" := PageIndicBuffer."Page Indic. Requisite Value";
                    StatRepBuffer."Scalable Table Row No." := 0;

                    ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                    CheckEmptyNode(XMLNode, CreatedXMLNode);
                until PageIndicBuffer.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessTable(var XMLNode: DotNet XmlNode; StatRepBuffer: Record "Statutory Report Buffer"; var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        ScalableTableRow: Record "Scalable Table Row";
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        XMLElementLine: Record "XML Element Line";
        PageIndicationXMLElement: Record "Page Indication XML Element";
        CreatedXMLNode: DotNet XmlNode;
        IndicElementValue: Text[250];
    begin
        TestField("Table Code");
        StatutoryReportTable.Get("Report Code", "Table Code");

        if StatutoryReportTable."Vertical Table" then begin
            ScalableTableRow.SetRange("Report Code", "Report Code");
            ScalableTableRow.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
            ScalableTableRow.SetRange("Table Code", "Table Code");
            ScalableTableRow.SetRange("Excel Sheet Name", StatRepBuffer."Excel Sheet Name");
            if ScalableTableRow.FindSet() then
                repeat
                    StatRepBuffer."Scalable Table Row No." := ScalableTableRow."Line No.";

                    IndicElementValue := '';
                    PageIndicationXMLElement.SetRange("Report Code", "Report Code");
                    PageIndicationXMLElement.SetRange("Table Code", "Table Code");
                    if PageIndicationXMLElement.FindSet() then
                        repeat
                            XMLElementLine.Get("Report Code", PageIndicationXMLElement."XML Element Line No.");
                            IndicElementValue := IndicElementValue + XMLElementLine.GetElementValue(StatRepBuffer);
                        until PageIndicationXMLElement.Next() = 0;

                    if IndicElementValue = StatRepBuffer."Page Indic. Requisite Value" then begin
                        AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);

                        StatRepBuffer."Scalable Table Row No." := ScalableTableRow."Line No.";

                        ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                        CheckEmptyNode(XMLNode, CreatedXMLNode);
                    end;
                until ScalableTableRow.Next() = 0;
        end else begin
            StatReportExcelSheet.SetRange("Report Code", "Report Code");
            StatReportExcelSheet.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
            StatReportExcelSheet.SetRange("Table Code", "Table Code");
            if StatRepBuffer."Page Indic. Requisite Value" <> '' then
                StatReportExcelSheet.SetRange("Page Indic. Requisite Value", StatRepBuffer."Page Indic. Requisite Value");
            if StatReportExcelSheet.FindSet() then
                repeat
                    if StatutoryReportTable."Scalable Table" then begin
                        ScalableTableRow.SetRange("Report Code", "Report Code");
                        ScalableTableRow.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
                        ScalableTableRow.SetRange("Table Code", "Table Code");
                        ScalableTableRow.SetRange("Excel Sheet Name", StatReportExcelSheet."Sheet Name");
                        if ScalableTableRow.FindSet() then
                            repeat
                                StatRepBuffer."Scalable Table Row No." := ScalableTableRow."Line No.";
                                StatRepBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                                if not ((not StatRepBuffer."Calculation Values Mode") and
                                        ElementIsEmpty(StatRepBuffer))
                                then begin
                                    AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);

                                    ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                                    CheckEmptyNode(XMLNode, CreatedXMLNode);
                                end;
                            until ScalableTableRow.Next() = 0;
                    end else begin
                        AddElement(XMLNode, "Element Name", '', '', CreatedXMLNode);

                        StatRepBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                        StatRepBuffer."Scalable Table Row No." := 0;

                        ProcessChildren(CreatedXMLNode, StatRepBuffer, ElementValueBuffer);
                        CheckEmptyNode(XMLNode, CreatedXMLNode);
                    end;
                until StatReportExcelSheet.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetElementValue(StatRepBuffer: Record "Statutory Report Buffer") ElementValue: Text[250]
    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatutoryReportDataValue: Record "Statutory Report Data Value";
        XMLElementLine: Record "XML Element Line";
        XMLElementExpressionLine: Record "XML Element Expression Line";
        RowNo: Integer;
    begin
        if StatRepBuffer."Excel Sheet Name" = '' then
            if "Table Code" <> '' then
                if StatutoryReportTable.Get("Report Code", "Table Code") then
                    StatRepBuffer."Excel Sheet Name" := StatutoryReportTable."Excel Sheet Name";

        if (StatRepBuffer."Scalable Table Row No." = 0) or ("Source Type" = "Source Type"::"Individual Element") then
            RowNo := "Row Link No."
        else
            RowNo := StatRepBuffer."Scalable Table Row No.";

        ElementValue := '';

        case "Source Type" of
            "Source Type"::Constant:
                ElementValue := Value;
            "Source Type"::Expression:
                begin
                    XMLElementExpressionLine.SetRange("Report Code", "Report Code");
                    XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
                    if XMLElementExpressionLine.FindSet() then
                        repeat
                            ElementValue :=
                              ElementValue +
                              XMLElementExpressionLine."String Before" +
                              XMLElementExpressionLine.GetReferenceValue(StatRepBuffer."Report Data No.", '') +
                              XMLElementExpressionLine."String After";
                        until XMLElementExpressionLine.Next() = 0;
                end;
            "Source Type"::"Table Data",
          "Source Type"::"Individual Element",
          "Source Type"::"Inserted Element":
                if StatutoryReportDataValue.Get(
                     StatRepBuffer."Report Data No.",
                     "Report Code",
                     "Table Code",
                     StatRepBuffer."Excel Sheet Name",
                     RowNo,
                     "Column Link No.")
                then
                    ElementValue := StatutoryReportDataValue.Value;
            "Source Type"::"Compound Element":
                begin
                    XMLElementExpressionLine.SetRange("Report Code", "Report Code");
                    XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
                    if XMLElementExpressionLine.FindSet() then
                        repeat
                            if XMLElementLine.Get("Report Code", XMLElementExpressionLine."XML Element Line No.") then
                                ElementValue :=
                                  ElementValue +
                                  XMLElementExpressionLine."String Before" +
                                  XMLElementLine.GetElementValue(StatRepBuffer) +
                                  XMLElementExpressionLine."String After";
                        until XMLElementExpressionLine.Next() = 0;

                    if StrLen(ElementValue) <> 0 then
                        if "Data Type" = "Data Type"::Integer then begin
                            if StrPos(ElementValue, '-') = StrLen(ElementValue) then
                                ElementValue := CopyStr(ElementValue, 1, StrLen(ElementValue) - 1);

                            if StrPos(ElementValue, '-0') > 0 then
                                ElementValue := CopyStr(ElementValue, 1, StrLen(ElementValue) - 2);

                            if StrPos(ElementValue, '0-') > 0 then
                                ElementValue := CopyStr(ElementValue, 2, StrLen(ElementValue) - 1);
                        end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetTableCode(): Code[20]
    var
        ParentRequisiteLine: Record "XML Element Line";
    begin
        TestField("Parent Line No.");
        if "Parent Line No." <> 0 then begin
            ParentRequisiteLine.Get("Report Code", "Parent Line No.");
            if ParentRequisiteLine."Link Type" = ParentRequisiteLine."Link Type"::Table then begin
                ParentRequisiteLine.TestField("Table Code");
                exit(ParentRequisiteLine."Table Code");
            end;

            exit(ParentRequisiteLine.GetTableCode());
        end;
    end;

    [Scope('OnPrem')]
    procedure AddElement(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; var CreatedXMLNode: DotNet XmlNode) ExitStatus: Integer
    var
        NewChildNode: DotNet XmlNode;
        XmlNodeType: DotNet XmlNodeType;
    begin
        if "Service Element" then
            exit;

        NewChildNode := XMLNode.OwnerDocument.CreateNode(XmlNodeType.Element, NodeName, NameSpace);

        if IsNull(NewChildNode) then begin
            ExitStatus := 50;
            exit;
        end;

        if NodeText <> '' then
            NewChildNode.InnerText := NodeText;

        if XMLNode.NodeType.Equals(XmlNodeType.ProcessingInstruction) then
            CreatedXMLNode := XMLNode.OwnerDocument.AppendChild(NewChildNode)
        else begin
            XMLNode.AppendChild(NewChildNode);
            CreatedXMLNode := NewChildNode;
        end;

        ExitStatus := 0;
    end;

    [Scope('OnPrem')]
    procedure AddAttribute(var XMLNode: DotNet XmlNode; Name: Text[260]; NodeValue: Text[260]) ExitStatus: Integer
    var
        XMLNewAttributeNode: DotNet XmlNode;
    begin
        if "Service Element" then
            exit;

        if IsValueEmpty(NodeValue) then
            if "Export Type" = "Export Type"::Optional then
                exit;

        XMLNewAttributeNode := XMLNode.OwnerDocument.CreateAttribute(Name);

        if IsNull(XMLNewAttributeNode) then begin
            ExitStatus := 60;
            exit(ExitStatus)
        end;

        if NodeValue <> '' then
            XMLNewAttributeNode.Value := NodeValue;

        XMLNode.Attributes.SetNamedItem(XMLNewAttributeNode);
    end;

    [Scope('OnPrem')]
    procedure ElementIsEmpty(StatRepBuffer: Record "Statutory Report Buffer"): Boolean
    var
        ChildSchemaLine: Record "XML Element Line";
    begin
        case "Element Type" of
            "Element Type"::Complex:
                begin
                    ChildSchemaLine.SetCurrentKey("Report Code", "Sequence No.");
                    ChildSchemaLine.SetRange("Report Code", "Report Code");
                    ChildSchemaLine.SetRange("Parent Line No.", "Line No.");
                    if ChildSchemaLine.FindSet() then
                        repeat
                            if not ChildSchemaLine.ElementIsEmpty(StatRepBuffer) then
                                exit(false);
                        until ChildSchemaLine.Next() = 0;
                end;
            "Element Type"::Attribute,
            "Element Type"::Simple:
                if GetElementValue(StatRepBuffer) <> '' then
                    exit(false);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure NodeIsEmpty(var XMLNode: DotNet XmlNode): Boolean
    var
        NodeList: DotNet XmlNodeList;
        AttributeList: DotNet XmlNamedNodeMap;
        ChildNode: DotNet XmlNode;
        i: Integer;
        NodeValue: Text[1024];
        AttrValue: Text[1024];
    begin
        if not XMLNode.HasChildNodes then begin
            NodeValue := CopyStr(XMLNode.InnerText, 1, MaxStrLen(NodeValue));
            if NodeValue <> '' then
                exit(false);
        end;

        AttributeList := XMLNode.Attributes;
        for i := 0 to AttributeList.Count - 1 do begin
            ChildNode := AttributeList.Item(i);
            AttrValue := CopyStr(ChildNode.InnerText, 1, MaxStrLen(AttrValue));
            if AttrValue <> '' then
                exit(false);
        end;

        NodeList := XMLNode.ChildNodes;
        for i := 0 to NodeList.Count - 1 do begin
            ChildNode := NodeList.Item(i);
            if not NodeIsEmpty(ChildNode) then
                exit(false);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckEmptyNode(var XMLNode: DotNet XmlNode; var CreatedXMLNode: DotNet XmlNode)
    begin
        if Choice or ("Export Type" = "Export Type"::Optional) then
            if NodeIsEmpty(CreatedXMLNode) then
                XMLNode.RemoveChild(CreatedXMLNode);
    end;

    [Scope('OnPrem')]
    procedure UpdateElementValue(ChangedRequisiteExpressionLine: Record "XML Element Expression Line"; DeleteRecord: Boolean)
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
    begin
        TestField("Source Type", "Source Type"::Expression);
        Value := '';
        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
        if XMLElementExpressionLine.FindSet() then
            repeat
                if XMLElementExpressionLine."Line No." <> ChangedRequisiteExpressionLine."Line No." then
                    Value := Value + XMLElementExpressionLine."String Before" +
                      XMLElementExpressionLine.Value + XMLElementExpressionLine."String After"
                else
                    if not DeleteRecord then
                        Value := Value + ChangedRequisiteExpressionLine."String Before" +
                          ChangedRequisiteExpressionLine.Value + ChangedRequisiteExpressionLine."String After";
            until XMLElementExpressionLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateExpression()
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
    begin
        TestField("Source Type", "Source Type"::Expression);
        XMLElementExpressionLine.SetRange("Report Code", "Report Code");
        XMLElementExpressionLine.SetRange("Base XML Element Line No.", "Line No.");
        if XMLElementExpressionLine.FindSet() then
            repeat
                XMLElementExpressionLine.Value := XMLElementExpressionLine.GetReferenceValue('', '');
                XMLElementExpressionLine.Modify();
            until XMLElementExpressionLine.Next() = 0;

        Clear(XMLElementExpressionLine);
        UpdateElementValue(XMLElementExpressionLine, false);
    end;

    [Scope('OnPrem')]
    procedure LookupRow()
    var
        StatReportTableRow: Record "Stat. Report Table Row";
        TableIndividualRequisite: Record "Table Individual Requisite";
        ReportTableRows: Page "Report Table Rows";
        TableIndividualRequisites: Page "Table Individual Requisites";
    begin
        if not ("Source Type" in
                ["Source Type"::"Table Data", "Source Type"::"Individual Element", "Source Type"::"Inserted Element"])
        then
            FieldError("Source Type");

        TestField("Table Code");

        case "Source Type" of
            "Source Type"::"Table Data",
            "Source Type"::"Inserted Element":
                begin
                    ReportTableRows.Editable := false;
                    ReportTableRows.LookupMode := true;
                    StatReportTableRow.SetRange("Report Code", "Report Code");
                    StatReportTableRow.SetRange("Table Code", "Table Code");
                    ReportTableRows.SetTableView(StatReportTableRow);
                    if "Row Link No." <> 0 then begin
                        StatReportTableRow.Get("Report Code", "Table Code", "Row Link No.");
                        ReportTableRows.SetRecord(StatReportTableRow);
                    end;
                    if ReportTableRows.RunModal() = ACTION::LookupOK then begin
                        ReportTableRows.GetRecord(StatReportTableRow);
                        "Row Link No." := StatReportTableRow."Line No.";
                    end;
                end;
            "Source Type"::"Individual Element":
                begin
                    TableIndividualRequisites.Editable := false;
                    TableIndividualRequisites.LookupMode := true;
                    TableIndividualRequisite.SetRange("Report Code", "Report Code");
                    TableIndividualRequisite.SetRange("Table Code", "Table Code");
                    TableIndividualRequisites.SetTableView(TableIndividualRequisite);
                    if "Row Link No." <> 0 then
                        if not TableIndividualRequisite.Get("Report Code", "Table Code", "Row Link No.") then begin
                            "Row Link No." := 0;
                            Modify();
                            Commit();
                        end else
                            TableIndividualRequisites.SetRecord(TableIndividualRequisite);
                    if TableIndividualRequisites.RunModal() = ACTION::LookupOK then begin
                        TableIndividualRequisites.GetRecord(TableIndividualRequisite);
                        "Row Link No." := TableIndividualRequisite."Line No.";
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupColumn()
    var
        StatReportTableColumn: Record "Stat. Report Table Column";
        ReportTableColumns: Page "Report Table Columns";
    begin
        case "Source Type" of
            "Source Type"::Expression,
          "Source Type"::Constant,
          "Source Type"::"Individual Element",
          "Source Type"::"Compound Element",
          "Source Type"::"Inserted Element":
                TestField("Source Type", "Source Type"::"Table Data");
            "Source Type"::"Table Data":
                begin
                    TestField("Table Code");
                    StatReportTableColumn.SetRange("Report Code", "Report Code");
                    StatReportTableColumn.SetRange("Table Code", "Table Code");
                    ReportTableColumns.SetTableView(StatReportTableColumn);
                    if "Column Link No." <> 0 then begin
                        StatReportTableColumn.Get("Report Code", "Table Code", "Column Link No.");
                        ReportTableColumns.SetRecord(StatReportTableColumn);
                    end;
                    ReportTableColumns.Editable := false;
                    ReportTableColumns.LookupMode := true;
                    if ReportTableColumns.RunModal() = ACTION::LookupOK then begin
                        ReportTableColumns.GetRecord(StatReportTableColumn);
                        "Column Link No." := StatReportTableColumn."Line No.";
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure FormatValue(FormatType: Option File,Excel,Storage; ValueToFormat: Text[250]; var FormattedValue: Text[250]; var ErrorMessage: Text[250]): Boolean
    var
        IntegerValue: BigInteger;
        DecimalValue: Decimal;
        FractionValue: Decimal;
        DateValue: Date;
    begin
        if FormatType = FormatType::Storage then
            if "Data Type" <> "Data Type"::Text then begin
                if "Excel Mapping Type" <> "Excel Mapping Type"::"Single-cell" then
                    ValueToFormat := DelChr(ValueToFormat, '=', '-')
            end else
                ValueToFormat := DelChr(ValueToFormat, '>', '-');

        case "Data Type" of
            "Data Type"::" ":
                begin
                    ErrorMessage := StrSubstNo(Text006, FieldCaption("Data Type"), GetRecordDescription());
                    exit(false);
                end;
            "Data Type"::Text:
                begin
                    StatutoryReport.Get("Report Code");
                    if (FormatType = FormatType::Excel) and StatutoryReport."Uppercase Text Excel Format" then
                        FormattedValue := AlignFormattedValue(UpperCase(ValueToFormat))
                    else
                        if (FormatType = FormatType::File) and StatutoryReport."Uppercase Text XML Format" then
                            FormattedValue := UpperCase(ValueToFormat)
                        else
                            FormattedValue := ValueToFormat;
                end;
            "Data Type"::Integer:
                begin
                    ValueToFormat := DelChr(ValueToFormat, '<>', ' ');
                    ValueToFormat := DelChr(ValueToFormat, '>', '-');
                    if ValueToFormat = '' then begin
                        FormattedValue := FormatEmptyValue();
                        exit(true);
                    end;
                    if not Evaluate(IntegerValue, ValueToFormat) then begin
                        ErrorMessage := StrSubstNo(Text003, ValueToFormat, "Data Type", GetRecordDescription());
                        exit(false);
                    end;

                    if FormatType = FormatType::Excel then
                        FormattedValue := AlignFormattedValue(Format(IntegerValue))
                    else
                        FormattedValue := Format(IntegerValue);
                end;
            "Data Type"::Decimal:
                begin
                    ValueToFormat := DelChr(ValueToFormat, '<>', ' ');
                    if ValueToFormat = '' then begin
                        FormattedValue := FormatEmptyValue();
                        exit(true);
                    end;

                    if not Evaluate(DecimalValue, ValueToFormat) then
                        if not Evaluate(DecimalValue, ValueToFormat, 9) then begin
                            ErrorMessage := StrSubstNo(Text003, ValueToFormat, "Data Type", GetRecordDescription());
                            exit(false);
                        end;

                    case FormatType of
                        FormatType::File:
                            FormattedValue := Format(DecimalValue, 0, StrSubstNo('<Precision,%1:%1><Standard Format,9>', "Fraction Digits"));
                        FormatType::Excel:
                            if "Excel Mapping Type" = "Excel Mapping Type"::"Multi-cell" then begin
                                IntegerValue := Round(DecimalValue, 1, '<');
                                FractionValue := DecimalValue - IntegerValue;

                                FormattedValue :=
                                    AlignFormattedValue(Format(IntegerValue) + '.' + CopyStr(Format(FractionValue), 3));
                            end else
                                FormattedValue := Format(DecimalValue);
                        FormatType::Storage:
                            begin
                                DecimalValue := Round(DecimalValue, Power(10, -"Fraction Digits"));
                                FormattedValue := Format(DecimalValue, 0, 1);
                            end;
                    end;
                end;
            "Data Type"::Date:
                begin
                    ValueToFormat := DelChr(ValueToFormat, '<>', ' ');
                    if not Evaluate(DateValue, ValueToFormat) then begin
                        ErrorMessage := StrSubstNo(Text003, ValueToFormat, "Data Type", GetRecordDescription());
                        exit(false);
                    end;
                    if (DateValue = 0D) and (FormatType = FormatType::Excel) then
                        FormattedValue := '--.--.----'
                    else
                        FormattedValue := Format(DateValue, 0, '<Day,2>.<Month,2>.<Year4>');
                    if FormatType = FormatType::File then
                        case "XML Export Date Format" of
                            "XML Export Date Format"::"YYYY-MM-DD":
                                FormattedValue := Format(DateValue, 0, 9);
                        end;
                end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ExportToExcel(var TempExcelBuffer: Record "Excel Buffer"; ElementValue: Text[250]; var ErrorMessage: Text[250]; ExcelCellName: Code[10]): Boolean
    var
        StatutoryReportTable: Record "Statutory Report Table";
        CurrCellName: Code[10];
        NextRowFirstCellName: Code[10];
        CellsQty: Integer;
        i: Integer;
        j: Integer;
        index: Integer;
        VerticalTable: Boolean;
        MultiCellMappingType: Option Row,Column,"Area";
        Delta: Integer;
    begin
        case "Excel Mapping Type" of
            "Excel Mapping Type"::"Single-cell":
                begin
                    if ExcelCellName = '' then begin
                        ErrorMessage := StrSubstNo(Text004, FieldCaption("Excel Cell Name"), GetRecordDescription());
                        exit(false);
                    end;
                    TempExcelBuffer.EnterCellByCellName(ExcelCellName, ElementValue);
                end;
            "Excel Mapping Type"::"Multi-cell":
                begin
                    if "Horizontal Cells Quantity" = 0 then begin
                        ErrorMessage := StrSubstNo(Text004, FieldCaption("Horizontal Cells Quantity"), GetRecordDescription());
                        exit(false);
                    end;

                    if "Table Code" <> '' then begin
                        StatutoryReportTable.Get("Report Code", "Table Code");
                        VerticalTable := StatutoryReportTable."Vertical Table";
                    end;

                    CellsQty := "Horizontal Cells Quantity" * "Vertical Cells Quantity";
                    MultiCellMappingType := GetMultiCellMappingType();

                    case MultiCellMappingType of
                        MultiCellMappingType::Row:
                            begin
                                if VerticalTable or StatutoryReportTable."Scalable Table" then
                                    CurrCellName := ExcelCellName
                                else
                                    CurrCellName := "Excel Cell Name";

                                for i := 1 to CellsQty do begin
                                    if not IsEmptySymbol(Format(ElementValue[i])) then
                                        TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(ElementValue[i]));
                                    CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);
                                end;
                            end;
                        MultiCellMappingType::Column:
                            begin
                                CurrCellName := "Excel Cell Name";

                                for i := 1 to CellsQty do begin
                                    if not IsEmptySymbol(Format(ElementValue[i])) then
                                        TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(ElementValue[i]));
                                    CurrCellName := TempExcelBuffer.GetNextRowCellName(CurrCellName);
                                end;
                            end;
                        MultiCellMappingType::Area:
                            begin
                                CurrCellName := "Excel Cell Name";

                                for j := 1 to "Vertical Cells Quantity" do begin
                                    if j > 1 then begin
                                        NextRowFirstCellName :=
                                          ExcelMgt.CellName2ColumnName("Excel Cell Name") +
                                          Format(ExcelMgt.CellName2RowNo(CurrCellName));

                                        for Delta := 1 to "Vertical Cells Delta" do
                                            NextRowFirstCellName := TempExcelBuffer.GetNextRowCellName(NextRowFirstCellName);

                                        CurrCellName := NextRowFirstCellName;
                                    end;

                                    for i := 1 to "Horizontal Cells Quantity" do begin
                                        index := i + (j - 1) * "Horizontal Cells Quantity";
                                        if not IsEmptySymbol(Format(ElementValue[index])) then
                                            TempExcelBuffer.EnterCellByCellName(CurrCellName, Format(ElementValue[index]));
                                        CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);
                                    end;
                                end;
                            end;
                    end;
                end;
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImportFromExcel(var TempExcelBuffer: Record "Excel Buffer" temporary; var ElementValue: Text[250]; var ErrorMessage: Text[250]; ExcelCellName: Code[10]): Boolean
    var
        StatutoryReportTable: Record "Statutory Report Table";
        CurrCellName: Code[10];
        NextRowFirstCellName: Code[10];
        i: Integer;
        j: Integer;
        CellValue: Text[250];
        VerticalTable: Boolean;
        MultiCellMappingType: Option Row,Column,"Area";
        Delta: Integer;
    begin
        case "Excel Mapping Type" of
            "Excel Mapping Type"::"Single-cell":
                begin
                    if ExcelCellName = '' then begin
                        ErrorMessage := StrSubstNo(Text004, FieldCaption("Excel Cell Name"), GetRecordDescription());
                        exit(false);
                    end;
                    ElementValue := Format(TempExcelBuffer.GetValueByCellName(ExcelCellName), 0, 2)
                end;
            "Excel Mapping Type"::"Multi-cell":
                begin
                    if "Excel Cell Name" = '' then begin
                        ErrorMessage := StrSubstNo(Text004, FieldCaption("Excel Cell Name"), GetRecordDescription());
                        exit(false);
                    end;

                    if "Horizontal Cells Quantity" = 0 then begin
                        ErrorMessage := StrSubstNo(Text004, FieldCaption("Horizontal Cells Quantity"), GetRecordDescription());
                        exit(false);
                    end;

                    if "Table Code" <> '' then begin
                        StatutoryReportTable.Get("Report Code", "Table Code");
                        VerticalTable := StatutoryReportTable."Vertical Table";
                    end;

                    MultiCellMappingType := GetMultiCellMappingType();

                    case MultiCellMappingType of
                        MultiCellMappingType::Row:
                            begin
                                if VerticalTable or StatutoryReportTable."Scalable Table" then
                                    CurrCellName := ExcelCellName
                                else
                                    CurrCellName := "Excel Cell Name";

                                for i := 1 to "Horizontal Cells Quantity" do begin
                                    ElementValue := ElementValue + Format(TempExcelBuffer.GetValueByCellName(CurrCellName));
                                    CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);
                                end;
                            end;
                        MultiCellMappingType::Column:
                            for i := 1 to "Vertical Cells Quantity" do begin
                                ElementValue := ElementValue + Format(TempExcelBuffer.GetValueByCellName(CurrCellName));
                                CurrCellName := TempExcelBuffer.GetNextRowCellName(CurrCellName);
                            end;
                        MultiCellMappingType::Area:
                            begin
                                CurrCellName := "Excel Cell Name";

                                for j := 1 to "Vertical Cells Quantity" do begin
                                    if j > 1 then begin
                                        NextRowFirstCellName :=
                                          ExcelMgt.CellName2ColumnName("Excel Cell Name") +
                                          Format(ExcelMgt.CellName2RowNo(CurrCellName));

                                        for Delta := 1 to "Vertical Cells Delta" do
                                            NextRowFirstCellName := TempExcelBuffer.GetNextRowCellName(NextRowFirstCellName);

                                        CurrCellName := NextRowFirstCellName;
                                    end;

                                    for i := 1 to "Horizontal Cells Quantity" do begin
                                        if i > 1 then
                                            CurrCellName := TempExcelBuffer.GetNextColumnCellName(CurrCellName);

                                        CellValue := Format(TempExcelBuffer.GetValueByCellName(CurrCellName));
                                        if CellValue = '' then
                                            CellValue := ' ';
                                        ElementValue := ElementValue + CellValue;
                                    end;
                                end;
                            end;
                    end;

                    ElementValue := DelChr(ElementValue, '<>', ' ');
                end;
        end;

        if IsValueEmpty(ElementValue) then
            ElementValue := '';

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetRecordDescription(): Text[250]
    begin
        exit(StrSubstNo('%1 %2=''%3'', %4=''%5'', %6=''%7''', TableCaption(),
            FieldCaption("Report Code"), "Report Code",
            FieldCaption("Line No."), "Line No.",
            FieldCaption("Element Name"), "Element Name"));
    end;

    [Scope('OnPrem')]
    procedure UpdateTableCode(TableCode: Code[20])
    var
        ChildRequisiteLine: Record "XML Element Line";
    begin
        ChildRequisiteLine.SetRange("Report Code", "Report Code");
        ChildRequisiteLine.SetRange("Parent Line No.", "Line No.");
        if ChildRequisiteLine.FindSet() then
            repeat
                if ChildRequisiteLine."Element Type" = ChildRequisiteLine."Element Type"::Complex then
                    ChildRequisiteLine.UpdateTableCode(TableCode)
                else
                    if ChildRequisiteLine."Table Code" = '' then begin
                        ChildRequisiteLine.Validate("Table Code", TableCode);
                        ChildRequisiteLine.Modify();
                    end;
            until ChildRequisiteLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure IsValueEmpty(ElementValue: Text[250]): Boolean
    begin
        if ElementValue = '' then
            exit(true);

        case "Data Type" of
            "Data Type"::Date:
                if ElementValue = '..' then
                    exit(true);
            "Data Type"::Decimal:
                if ElementValue = '.' then
                    exit(true);
            "Data Type"::Text:
                if ElementValue = '/' then
                    exit(true);
            "Data Type"::Integer:
                if ElementValue = '0' then
                    exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ProcessChildren(var XMLNode: DotNet XmlNode; StatRepBuffer: Record "Statutory Report Buffer"; var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        ChildRequisiteLine: Record "XML Element Line";
    begin
        ChildRequisiteLine.SetCurrentKey("Report Code", "Sequence No.");
        ChildRequisiteLine.SetRange("Report Code", "Report Code");
        ChildRequisiteLine.SetRange("Parent Line No.", "Line No.");
        if ChildRequisiteLine.FindSet() then
            repeat
                ChildRequisiteLine.CheckComplexTable(StatRepBuffer);
                ChildRequisiteLine.ExportValue(XMLNode, StatRepBuffer, ElementValueBuffer);
            until ChildRequisiteLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckComplexTable(var StatRepBuffer: Record "Statutory Report Buffer")
    var
        StatReportExcelSheet: Record "Stat. Report Excel Sheet";
        StatutoryReportTable: Record "Statutory Report Table";
    begin
        if "Table Code" <> '' then begin
            StatutoryReportTable.Get("Report Code", "Table Code");
            if ((not StatutoryReportTable."Scalable Table") and (StatutoryReportTable."Parent Table Code" <> '')) or
               (StatutoryReportTable."Scalable Table" and
                ("Source Type" = "Source Type"::"Individual Element")) and
               (not StatutoryReportTable."Vertical Table") or
               (StatutoryReportTable."Multipage Table" and
                not StatutoryReportTable."Scalable Table" and
                not StatutoryReportTable."Vertical Table" and
                not ("Link Type" = "Link Type"::Table) and
                (StatRepBuffer."Page Indic. Requisite Value" <> ''))
            then begin
                StatReportExcelSheet.SetRange("Report Code", "Report Code");
                StatReportExcelSheet.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
                StatReportExcelSheet.SetRange("Table Code", "Table Code");
                StatReportExcelSheet.SetRange("Page Indic. Requisite Value", StatRepBuffer."Page Indic. Requisite Value");
                if StatReportExcelSheet.FindFirst() then begin
                    StatRepBuffer."Excel Sheet Name" := StatReportExcelSheet."Sheet Name";
                    StatRepBuffer."Table Code" := "Table Code";
                    StatutoryReportTable.Get("Report Code", "Table Code");
                    if not StatutoryReportTable."Scalable Table" then
                        StatRepBuffer."Scalable Table Row No." := 0;
                end else
                    if "Excel Sheet Name" <> StatRepBuffer."Excel Sheet Name" then begin
                        StatReportExcelSheet.Reset();
                        StatReportExcelSheet.SetRange("Report Code", "Report Code");
                        StatReportExcelSheet.SetRange("Report Data No.", StatRepBuffer."Report Data No.");
                        StatReportExcelSheet.SetRange("Table Code", "Table Code");
                        StatReportExcelSheet.SetRange("Parent Sheet Name", "Excel Sheet Name");
                        StatReportExcelSheet.SetRange("Sheet Name", StatRepBuffer."Excel Sheet Name");
                        if StatReportExcelSheet.IsEmpty() then
                            StatRepBuffer."Excel Sheet Name" := "Excel Sheet Name";
                    end;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddElementValueBufferLine(StatRepBuffer: Record "Statutory Report Buffer"; ElementValue: Text[250]; var ElementValueBuffer: Record "Statutory Report Buffer")
    var
        StatutoryReportTable: Record "Statutory Report Table";
        StatReportTableColumn: Record "Stat. Report Table Column";
        ScalableTableRow: Record "Scalable Table Row";
        VertTableRowShift: Integer;
    begin
        if ElementValueBuffer.FindLast() then;
        EntryNo := ElementValueBuffer."Entry No." + 1;

        ElementValueBuffer.Init();
        ElementValueBuffer."Entry No." := EntryNo;
        if (StatRepBuffer."Excel Sheet Name" = '') and ("Excel Sheet Name" <> '') then
            ElementValueBuffer."Excel Sheet Name" := "Excel Sheet Name"
        else
            ElementValueBuffer."Excel Sheet Name" := StatRepBuffer."Excel Sheet Name";
        ElementValueBuffer."XML Element Line No." := "Line No.";
        ElementValueBuffer.Value := ElementValue;
        ElementValueBuffer."Excel Cell Name" := "Excel Cell Name";
        ElementValueBuffer."Table Code" := "Table Code";

        if ("Source Type" = "Source Type"::"Table Data") and ("Table Code" <> '') then begin
            StatutoryReportTable.Get("Report Code", "Table Code");
            if StatutoryReportTable."Scalable Table" then begin
                if "Column Link No." <> 0 then
                    if StatReportTableColumn.Get("Report Code", "Table Code", "Column Link No.") then
                        VertTableRowShift := StatReportTableColumn."Vert. Table Row Shift";

                if ScalableTableRow.Get(
                     StatRepBuffer."Report Data No.",
                     "Report Code",
                     "Table Code",
                     StatRepBuffer."Excel Sheet Name",
                     StatRepBuffer."Scalable Table Row No.")
                then
                    ElementValueBuffer."Excel Cell Name" :=
                      ExcelMgt.CellName2ColumnName("Excel Cell Name") +
                      Format(ScalableTableRow."Excel Row No." + VertTableRowShift);
            end;
        end;
        ElementValueBuffer."Template Data" := "Template Data";
        ElementValueBuffer.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetElementFormattedValue(StatRepBuffer: Record "Statutory Report Buffer"; var ElementValueBuffer: Record "Statutory Report Buffer"): Text[250]
    var
        ElementValue: Text[250];
        FormattedValue: Text[250];
        ErrorMessage: Text[250];
    begin
        ElementValue := GetElementValue(StatRepBuffer);

        if StatRepBuffer."Calculation Values Mode" then begin
            if not FormatValue(1, ElementValue, FormattedValue, ErrorMessage) then
                Error(ErrorMessage);
            AddElementValueBufferLine(StatRepBuffer, FormattedValue, ElementValueBuffer);
        end else
            if not FormatValue(0, ElementValue, FormattedValue, ErrorMessage) then
                Error(ErrorMessage);

        exit(FormattedValue);
    end;

    [Scope('OnPrem')]
    procedure IsEmptySymbol(ElementCharecter: Text[1]): Boolean
    begin
        if ElementCharecter in ['', ' '] then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetMultiCellMappingType(): Integer
    begin
        case true of
            ("Horizontal Cells Quantity" > 1) and ("Vertical Cells Quantity" = 1):
                exit(0);
            ("Horizontal Cells Quantity" = 1) and ("Vertical Cells Quantity" > 1):
                exit(1);
            ("Horizontal Cells Quantity" > 1) and ("Vertical Cells Quantity" > 1):
                exit(2);
        end;
    end;

    procedure IsReportDataExist(): Boolean
    var
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
    begin
        StatutoryReportDataHeader.SetRange("Report Code", "Report Code");
        exit(not StatutoryReportDataHeader.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure CopyElement(ReportFromCode: Code[20])
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        XMLElementExpressionLineFrom: Record "XML Element Expression Line";
    begin
        XMLElementExpressionLineFrom.SetRange("Report Code", ReportFromCode);
        XMLElementExpressionLineFrom.SetRange("Base XML Element Line No.", "Line No.");
        if XMLElementExpressionLineFrom.FindSet() then
            repeat
                XMLElementExpressionLine := XMLElementExpressionLineFrom;
                XMLElementExpressionLine."Report Code" := "Report Code";
                XMLElementExpressionLine.Insert();
            until XMLElementExpressionLineFrom.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckReportDataExistence(ErrorMessage: Text[250])
    begin
        StatutoryReportSetup.Get();
        if not StatutoryReportSetup."Setup Mode" then begin
            StatutoryReport.Get("Report Code");
            if IsReportDataExist() then
                Error(ErrorMessage,
                  GetRecordDescription(),
                  StatutoryReport.TableCaption(),
                  StatutoryReport.Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure AlignFormattedValue(FormattedValue: Text[250]): Text[250]
    begin
        if ("Excel Mapping Type" <> "Excel Mapping Type"::"Multi-cell") or
           ("Horizontal Cells Quantity" = 0) or ("Vertical Cells Quantity" = 0) or ("Template Data") or
           (("Pad Character" = '') and (FormattedValue = ''))
        then
            exit(FormattedValue);

        if "Pad Character" = '' then
            "Pad Character" := ' ';

        if "Horizontal Cells Quantity" * "Vertical Cells Quantity" > StrLen(FormattedValue) then
            case Alignment of
                Alignment::Left:
                    exit(
                      CopyStr(FormattedValue, 1, StrLen(FormattedValue)) +
                      PadStr(
                        '',
                        "Horizontal Cells Quantity" * "Vertical Cells Quantity" - StrLen(FormattedValue),
                        "Pad Character"));
                Alignment::Right:
                    exit(
                      PadStr(
                        '',
                        "Horizontal Cells Quantity" * "Vertical Cells Quantity" - StrLen(FormattedValue),
                        "Pad Character") +
                      CopyStr(FormattedValue, 1, StrLen(FormattedValue)));
            end
        else
            exit(FormattedValue);
    end;

    [Scope('OnPrem')]
    procedure FormatEmptyValue(): Text[250]
    begin
        if ("Excel Mapping Type" <> "Excel Mapping Type"::"Multi-cell") or ("Pad Character" = '') or
           ("Horizontal Cells Quantity" = 0) or ("Vertical Cells Quantity" = 0) or ("Template Data")
        then
            exit('');

        exit(PadStr('', "Horizontal Cells Quantity" * "Vertical Cells Quantity", "Pad Character"));
    end;
}

