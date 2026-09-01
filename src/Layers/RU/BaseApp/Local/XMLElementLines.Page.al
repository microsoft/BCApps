#pragma warning disable AA0247
page 26587 "XML Element Lines"
{
    Caption = 'XML Element Lines';
    DataCaptionFields = "Report Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "XML Element Line";
    SourceTableView = sorting("Report Code", "Sequence No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                IndentationColumn = "Element NameIndent";
                IndentationControls = "Element Name";
                ShowCaption = false;
                field("Element Name"; Rec."Element Name")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = "Element NameEmphasize";
                    ToolTip = 'Specifies the element name associated with the XML element line.';
                }
                field(Indentation; Rec.Indentation)
                {
                    Editable = false;
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the parent line number associated with the XML element line.';
                    Visible = false;
                }
                field("Element Type"; Rec."Element Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the element type associated with the XML element line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML element line.';
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data type associated with the XML element line.';
                }
                field("Link Type"; Rec."Link Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link type associated with the XML element line.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source type that applies to the source number that is shown in the Source No. field.';

                    trigger OnValidate()
                    var
                        XMLElementExpressionLine: Record "XML Element Expression Line";
                    begin
                        if Rec."Source Type" <> xRec."Source Type" then begin
                            if Rec."Source Type" <> Rec."Source Type"::" " then
                                Rec.TestField("Link Type", Rec."Link Type"::Value);
                            Rec.CheckReportDataExistence(Text005);

                            case xRec."Source Type" of
                                xRec."Source Type"::Expression:
                                    begin
                                        XMLElementExpressionLine.Reset();
                                        XMLElementExpressionLine.SetRange("Report Code", Rec."Report Code");
                                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", Rec."Line No.");
                                        if XMLElementExpressionLine.FindFirst() then
                                            if Confirm(Text002) then begin
                                                XMLElementExpressionLine.DeleteAll();
                                                Rec.Value := '';
                                            end else
                                                Error('');
                                    end;
                                xRec."Source Type"::"Compound Element":
                                    begin
                                        XMLElementExpressionLine.Reset();
                                        XMLElementExpressionLine.SetRange("Report Code", Rec."Report Code");
                                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", Rec."Line No.");
                                        if XMLElementExpressionLine.FindFirst() then
                                            if Confirm(Text004) then
                                                XMLElementExpressionLine.DeleteAll()
                                            else
                                                Error('');
                                    end;
                                xRec."Source Type"::"Inserted Element",
                              xRec."Source Type"::"Individual Element":
                                    Rec."Column Link No." := 0;
                            end;

                            if Rec."Source Type" <> Rec."Source Type"::Constant then
                                Rec.Value := '';

                            case Rec."Source Type" of
                                Rec."Source Type"::" ",
                              Rec."Source Type"::Expression,
                              Rec."Source Type"::Constant,
                              Rec."Source Type"::"Individual Element",
                              Rec."Source Type"::"Compound Element":
                                    Rec."Column Link No." := 0;
                                Rec."Source Type"::"Inserted Element":
                                    Rec."Column Link No." := -10000;
                            end;

                            Rec."Row Link No." := 0;
                        end;
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the XML element line.';
                }
                field("Export Type"; Rec."Export Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the export type associated with the XML element line.';
                }
                field("Service Element"; Rec."Service Element")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the service element associated with the XML element line.';
                }
                field(Choice; Rec.Choice)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the XML element line is a choice line.';
                }
                field("OKEI Scaling"; Rec."OKEI Scaling")
                {
                    ToolTip = 'Specifies if OKEI scaling is associated with the XML element line.';
                    Visible = false;
                }
                field("Table Code"; Rec."Table Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table code associated with the XML element line.';

                    trigger OnValidate()
                    begin
                        TableCodeOnAfterValidate();
                    end;
                }
                field("Row Link No."; Rec."Row Link No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the row link number of the XML element line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupRow();
                    end;
                }
                field("Column Link No."; Rec."Column Link No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the column link number of the XML element line.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupColumn();
                    end;
                }
                field("Excel Mapping Type"; Rec."Excel Mapping Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel mapping type associated with the XML element line.';
                }
                field("Excel Sheet Name"; Rec."Excel Sheet Name")
                {
                    ToolTip = 'Specifies the Microsoft Excel sheet name of the XML element line.';
                    Visible = false;
                }
                field("Excel Cell Name"; Rec."Excel Cell Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel cell name associated with the XML element line.';
                }
                field("Horizontal Cells Quantity"; Rec."Horizontal Cells Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the horizontal cells of the XML element line.';
                }
                field("Vertical Cells Quantity"; Rec."Vertical Cells Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the vertical cells of the XML element line.';
                }
                field("Vertical Cells Delta"; Rec."Vertical Cells Delta")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of rows between cells for the multi-cell XML element line.';
                }
                field("Fraction Digits"; Rec."Fraction Digits")
                {
                    ToolTip = 'Specifies the fraction digits of the XML element line.';
                    Visible = false;
                }
                field("XML Export Date Format"; Rec."XML Export Date Format")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Alignment; Rec.Alignment)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pad Character"; Rec."Pad Character")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Template Data"; Rec."Template Data")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Element)
            {
                Caption = 'Element';
                action("Expression Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expression Lines';
                    Image = AdjustItemCost;
                    ShortCutKey = 'Shift+Ctrl+E';

                    trigger OnAction()
                    var
                        XMLElementExpressionLine: Record "XML Element Expression Line";
                        XMLElementExpressionLines: Page "XML Element Expression Lines";
                    begin
                        Rec.TestField("Source Type", Rec."Source Type"::Expression);
                        XMLElementExpressionLine.FilterGroup(2);
                        XMLElementExpressionLine.SetRange("Report Code", Rec."Report Code");
                        XMLElementExpressionLine.SetRange("Base XML Element Line No.", Rec."Line No.");
                        XMLElementExpressionLine.FilterGroup(0);
                        XMLElementExpressionLines.SetTableView(XMLElementExpressionLine);
                        XMLElementExpressionLines.RunModal();
                    end;
                }
                action("Compound Element Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Compound Element Lines';
                    Image = ExplodeBOM;
                    ShortCutKey = 'Shift+Ctrl+C';

                    trigger OnAction()
                    begin
                        ShowCompoundElementLines();
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Move Up")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Up';
                    Image = MoveUp;
                    ShortCutKey = 'Shift+Ctrl+W';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveUp();
                    end;
                }
                action("Move Down")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Down';
                    Image = MoveDown;
                    ShortCutKey = 'Shift+Ctrl+S';
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        MoveDown();
                    end;
                }
                action("Move Right")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Right';
                    Image = NextRecord;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        MoveRight();
                    end;
                }
                action("Move Left")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Left';
                    Image = PreviousRecord;

                    trigger OnAction()
                    begin
                        MoveLeft();
                    end;
                }
                separator(Action1210038)
                {
                }
                action("Update Expression")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Expression';
                    Image = Refresh;
                    ToolTip = 'Update the related element expression.';

                    trigger OnAction()
                    begin
                        Rec.UpdateExpression();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Move Up_Promoted"; "Move Up")
                {
                }
                actionref("Move Down_Promoted"; "Move Down")
                {
                }
                actionref("Move Right_Promoted"; "Move Right")
                {
                }
                actionref("Move Left_Promoted"; "Move Left")
                {
                }
                actionref("Expression Lines_Promoted"; "Expression Lines")
                {
                }
                actionref("Compound Element Lines_Promoted"; "Compound Element Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        "Element NameIndent" := 0;
        ElementNameOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        XMLElementLine: Record "XML Element Line";
        SequenceNo: Integer;
        LineNo: Integer;
    begin
        XMLElementLine.SetRange("Report Code", Rec."Report Code");
        if XMLElementLine.Find('+') then;
        LineNo := XMLElementLine."Line No." + 10000;

        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");

        if BelowxRec then begin
            if XMLElementLine.Find('+') then;
            Rec."Sequence No." := XMLElementLine."Sequence No." + 1;
            Rec."Line No." := LineNo;
        end else begin
            SequenceNo := xRec."Sequence No.";

            XMLElementLine.SetFilter("Sequence No.", '%1..', SequenceNo);
            if XMLElementLine.Find('+') then
                repeat
                    XMLElementLine."Sequence No." := XMLElementLine."Sequence No." + 1;
                    XMLElementLine.Modify();
                until XMLElementLine.Next(-1) = 0;

            Rec."Line No." := LineNo;
            Rec."Sequence No." := SequenceNo;
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not BelowxRec then begin
            Rec.Indentation := xRec.Indentation;
            Rec."Parent Line No." := xRec."Parent Line No.";
            Rec."Element Type" := xRec."Element Type";
        end;
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'All related expression lines will be deleted. Proceed?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'All related compound element lines will be deleted. Proceed?';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label '%1 cannot be modified because %2 %3 contains report data.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        "Element NameEmphasize": Boolean;
        "Element NameIndent": Integer;

    [Scope('OnPrem')]
    procedure MoveUp()
    var
        UpperLine: Record "XML Element Line";
        SequenceNo: Integer;
        CurrLineNo: Integer;
    begin
        Rec.CheckReportDataExistence(Text005);
        UpperLine.SetCurrentKey("Report Code", "Sequence No.");
        UpperLine.SetRange("Report Code", Rec."Report Code");
        UpperLine.SetFilter("Sequence No.", '..%1', Rec."Sequence No." - 1);
        if UpperLine.FindLast() then begin
            SequenceNo := UpperLine."Sequence No.";
            UpperLine."Sequence No." := Rec."Sequence No.";
            UpperLine.Modify();

            CurrLineNo := Rec."Line No.";

            Rec.Get(Rec."Report Code", UpperLine."Line No.");
            Rec."Sequence No." := UpperLine."Sequence No.";
            Rec.Modify();

            Rec.Get(Rec."Report Code", CurrLineNo);
            Rec.Indentation := UpperLine.Indentation;
            Rec."Sequence No." := SequenceNo;
            Rec.Modify(true);

            UpperLine.Get(Rec."Report Code", CurrLineNo);
            UpperLine.Indentation := Rec.Indentation;
            UpperLine."Sequence No." := SequenceNo;
            UpperLine.Modify();
        end;

        UpdateLinks();
    end;

    [Scope('OnPrem')]
    procedure MoveDown()
    var
        LowerLine: Record "XML Element Line";
        SequenceNo: Integer;
        CurrLineNo: Integer;
    begin
        Rec.CheckReportDataExistence(Text005);
        LowerLine.SetCurrentKey("Report Code", "Sequence No.");
        LowerLine.SetRange("Report Code", Rec."Report Code");
        LowerLine.SetFilter("Sequence No.", '%1..', Rec."Sequence No." + 1);
        if LowerLine.FindFirst() then begin
            SequenceNo := LowerLine."Sequence No.";
            LowerLine."Sequence No." := Rec."Sequence No.";
            LowerLine.Modify();

            CurrLineNo := Rec."Line No.";

            Rec.Get(Rec."Report Code", LowerLine."Line No.");
            Rec."Sequence No." := LowerLine."Sequence No.";
            Rec.Modify();

            Rec.Get(Rec."Report Code", CurrLineNo);
            Rec.Indentation := LowerLine.Indentation;
            Rec."Sequence No." := SequenceNo;
            Rec.Modify(true);

            LowerLine.Get(Rec."Report Code", CurrLineNo);
            LowerLine.Indentation := Rec.Indentation;
            LowerLine."Sequence No." := SequenceNo;
            LowerLine.Modify();
        end;
        UpdateLinks();
    end;

    [Scope('OnPrem')]
    procedure MoveRight()
    begin
        Rec.CheckReportDataExistence(Text005);
        Rec.Indentation := Rec.Indentation + 1;
        Rec.Modify(true);
        UpdateLinks();
    end;

    [Scope('OnPrem')]
    procedure MoveLeft()
    begin
        Rec.CheckReportDataExistence(Text005);
        if Rec.Indentation > 0 then begin
            Rec.Indentation := Rec.Indentation - 1;
            Rec.Modify(true);
        end;
        UpdateLinks();
    end;

    [Scope('OnPrem')]
    procedure UpdateLinks()
    var
        XMLElementLine: Record "XML Element Line";
        ParentLine: Record "XML Element Line";
    begin
        ParentLine.SetCurrentKey("Report Code", "Sequence No.");
        ParentLine.SetRange("Report Code", Rec."Report Code");

        XMLElementLine.SetCurrentKey("Report Code", "Sequence No.");
        XMLElementLine.SetRange("Report Code", Rec."Report Code");
        if XMLElementLine.FindSet() then
            repeat
                if XMLElementLine.Indentation > 0 then begin
                    ParentLine.SetFilter("Sequence No.", '<%1', XMLElementLine."Sequence No.");
                    ParentLine.SetFilter(Indentation, '<%1', XMLElementLine.Indentation);
                    if ParentLine.FindLast() then begin
                        XMLElementLine."Parent Line No." := ParentLine."Line No.";
                        XMLElementLine.Modify();
                    end;
                end else begin
                    XMLElementLine."Parent Line No." := 0;
                    XMLElementLine.Modify();
                end;
            until XMLElementLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ShowCompoundElementLines()
    var
        XMLElementExpressionLine: Record "XML Element Expression Line";
        CompoundXMLElementLines: Page "Compound XML Element Lines";
    begin
        Rec.TestField("Source Type", Rec."Source Type"::"Compound Element");
        XMLElementExpressionLine.FilterGroup(2);
        XMLElementExpressionLine.SetRange("Report Code", Rec."Report Code");
        XMLElementExpressionLine.SetRange("Base XML Element Line No.", Rec."Line No.");
        XMLElementExpressionLine.FilterGroup(0);
        CompoundXMLElementLines.SetTableView(XMLElementExpressionLine);
        CompoundXMLElementLines.RunModal();
    end;

    local procedure TableCodeOnAfterValidate()
    begin
        if Rec."Table Code" <> '' then begin
            CurrPage.SaveRecord();
            Rec.UpdateTableCode(Rec."Table Code");
            CurrPage.Update();
        end;
    end;

    local procedure ElementNameOnFormat()
    begin
        "Element NameIndent" := Rec.Indentation;
        "Element NameEmphasize" := Rec."Element Type" = Rec."Element Type"::Complex;
    end;
}

