#pragma warning disable AA0247
page 26552 "Statutory Report Tables"
{
    Caption = 'Statutory Report Tables';
    DataCaptionFields = "Report Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Statutory Report Table";
    SourceTableView = sorting("Report Code", "Sequence No.");

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code associated with the statutory report table.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the statutory report table.';
                }
                field("Excel Sheet Name"; Rec."Excel Sheet Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Microsoft Excel sheet name associated with the statutory report table.';
                }
                field("Rows Quantity"; Rec."Rows Quantity")
                {
                    ToolTip = 'Specifies the rows quantity associated with the statutory report table.';
                    Visible = false;
                }
                field("Columns Quantity"; Rec."Columns Quantity")
                {
                    ToolTip = 'Specifies the columns quantity associated with the statutory report table.';
                    Visible = false;
                }
                field("Scalable Table"; Rec."Scalable Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the scalable table associated with the statutory report table.';
                }
                field("Vertical Table"; Rec."Vertical Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vertical table associated with the statutory report table.';
                }
                field("Scalable Table First Row No."; Rec."Scalable Table First Row No.")
                {
                    ToolTip = 'Specifies the scalable table first row number associated with the statutory report table.';
                    Visible = false;
                }
                field("Scalable Table Row Step"; Rec."Scalable Table Row Step")
                {
                    ToolTip = 'Specifies the scalable table row step associated with the statutory report table.';
                    Visible = false;
                }
                field("Scalable Table Max Rows Qty"; Rec."Scalable Table Max Rows Qty")
                {
                    ToolTip = 'Specifies the scalable table rows maximum quantity associated with the statutory report table.';
                    Visible = false;
                }
                field("Multipage Table"; Rec."Multipage Table")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the multipage table associated with the statutory report table.';
                }
                field("Page Indication Text"; Rec."Page Indication Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page indication text associated with the statutory report table.';
                }
                field("Page Indic. Excel Cell Name"; Rec."Page Indic. Excel Cell Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the page indication Microsoft Excel cell name associated with the statutory report table.';
                }
                field(PageIndicRowNo; PageIndicRowNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Indic. Requisite Row Code';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.TestField("Multipage Table", true);

                        TableIndividualRequisite.FilterGroup(2);
                        TableIndividualRequisite.SetRange("Report Code", Rec."Report Code");
                        TableIndividualRequisite.SetRange("Table Code", Rec.Code);
                        TableIndividualRequisite.FilterGroup(0);
                        if PAGE.RunModal(0, TableIndividualRequisite) = ACTION::LookupOK then begin
                            Rec."Page Indic. Requisite Line No." := TableIndividualRequisite."Line No.";
                            PageIndicRowNo := TableIndividualRequisite."Row Code";
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.TestField("Multipage Table", true);

                        if PageIndicRowNo <> '' then begin
                            TableIndividualRequisite.SetRange("Report Code", Rec."Report Code");
                            TableIndividualRequisite.SetRange("Table Code", Rec.Code);
                            TableIndividualRequisite.SetRange("Row Code", PageIndicRowNo);
                            TableIndividualRequisite.FindFirst();
                            Rec."Page Indic. Requisite Line No." := TableIndividualRequisite."Line No.";
                        end else
                            Rec."Page Indic. Requisite Line No." := 0;
                    end;
                }
                field(PageIndicationForXML; GetPageIndicForXML())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Page Indication for XML';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PageIndicationXMLElement: Record "Page Indication XML Element";
                    begin
                        if not (Rec."Multipage Table" or Rec."Vertical Table") then
                            Error(Text003,
                              Rec.FieldCaption("Multipage Table"),
                              Rec.FieldCaption("Vertical Table"),
                              Rec.GetRecDescription());

                        PageIndicationXMLElement.FilterGroup(2);
                        PageIndicationXMLElement.SetRange("Report Code", Rec."Report Code");
                        PageIndicationXMLElement.SetRange("Table Code", Rec.Code);
                        PageIndicationXMLElement.FilterGroup(0);
                        PAGE.RunModal(0, PageIndicationXMLElement);
                    end;
                }
                field("Table Indication Text"; Rec."Table Indication Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table indication text associated with the statutory report table.';
                }
                field("Table Indic. Excel Cell Name"; Rec."Table Indic. Excel Cell Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table indication Microsoft Excel cell name associated with the statutory report table.';
                }
                field("Parent Table Code"; Rec."Parent Table Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the parent table code associated with the statutory report table.';
                }
                field("Int. Source Type"; Rec."Int. Source Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source type of the statutory report table.';
                }
                field("Int. Source Section Code"; Rec."Int. Source Section Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source section code associated with the statutory report table.';
                }
                field("Int. Source No."; Rec."Int. Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source number associated with the statutory report table.';
                }
                field("Int. Source Col. Name"; Rec."Int. Source Col. Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal source number associated with the statutory report column layout.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Table")
            {
                Caption = '&Table';
                action(RowsMenuItem)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Rows';
                    Image = GetLines;
                    RunObject = Page "Report Table Rows";
                    RunPageLink = "Report Code" = field("Report Code"),
                                  "Table Code" = field(Code);
                }
                action("&Columns")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Columns';
                    Image = Column;
                    RunObject = Page "Report Table Columns";
                    RunPageLink = "Report Code" = field("Report Code"),
                                  "Table Code" = field(Code);
                    ToolTip = 'Enter settings to define the values that the column displays in a report.';
                }
                action("&Individual Requisites")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Individual Requisites';
                    Image = AdjustItemCost;
                    RunObject = Page "Table Individual Requisites";
                    RunPageLink = "Report Code" = field("Report Code"),
                                  "Table Code" = field(Code);
                    ToolTip = 'View and edit individual requisites for the statutory report.';
                }
                action("Internal Data Source &Mapping")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Internal Data Source &Mapping';
                    Image = CheckRulesSyntax;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Stat. Report Table Mapping";
                    RunPageLink = "Report Code" = field("Report Code"),
                                  "Table Code" = field(Code);
                    RunPageMode = Edit;
                    ToolTip = 'View mappings between statutory report tables.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Account Schedule")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Account Schedule';
                    Ellipsis = true;
                    Image = NewChartOfAccounts;

                    trigger OnAction()
                    begin
                        Rec.CreateAccSchedule();
                    end;
                }
                separator(Action1210022)
                {
                }
                action("Update Internal Data Source Links")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Internal Data Source Links';
                    Image = Refresh;
                    ToolTip = 'Refresh mappings between statutory report tables.';

                    trigger OnAction()
                    begin
                        Rec.UpdateIntSourceLinks();
                    end;
                }
                separator(Action1210060)
                {
                }
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
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RowsMenuItem_Promoted; RowsMenuItem)
                {
                }
                actionref("&Columns_Promoted"; "&Columns")
                {
                }
                actionref("&Individual Requisites_Promoted"; "&Individual Requisites")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PageIndicRowNo := '';
        if Rec."Page Indic. Requisite Line No." <> 0 then begin
            TableIndividualRequisite.Get(Rec."Report Code", Rec.Code, Rec."Page Indic. Requisite Line No.");
            PageIndicRowNo := TableIndividualRequisite."Row Code";
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        StatutoryReportTable: Record "Statutory Report Table";
        SequenceNo: Integer;
    begin
        StatutoryReportTable.SetCurrentKey("Report Code", "Sequence No.");
        StatutoryReportTable.SetRange("Report Code", Rec."Report Code");

        if BelowxRec then begin
            if StatutoryReportTable.FindLast() then;
            Rec."Sequence No." := StatutoryReportTable."Sequence No." + 1;
        end else begin
            SequenceNo := xRec."Sequence No.";

            StatutoryReportTable.SetFilter("Sequence No.", '%1..', SequenceNo);
            if StatutoryReportTable.Find('+') then
                repeat
                    StatutoryReportTable."Sequence No." := StatutoryReportTable."Sequence No." + 1;
                    StatutoryReportTable.Modify();
                until StatutoryReportTable.Next(-1) = 0;
            Rec."Sequence No." := SequenceNo;
        end;
    end;

    var
        TableIndividualRequisite: Record "Table Individual Requisite";
        PageIndicRowNo: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 or %2 should be Yes in %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure MoveUp()
    var
        UpperStatutoryReportTable: Record "Statutory Report Table";
        SequenceNo: Integer;
    begin
        UpperStatutoryReportTable.SetCurrentKey("Report Code", "Sequence No.");
        UpperStatutoryReportTable.SetRange("Report Code", Rec."Report Code");
        UpperStatutoryReportTable.SetFilter("Sequence No.", '..%1', Rec."Sequence No." - 1);
        if UpperStatutoryReportTable.FindLast() then begin
            SequenceNo := UpperStatutoryReportTable."Sequence No.";
            UpperStatutoryReportTable."Sequence No." := Rec."Sequence No.";
            UpperStatutoryReportTable.Modify();

            Rec."Sequence No." := SequenceNo;
            Rec.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure MoveDown()
    var
        LowerStatutoryReportTable: Record "Statutory Report Table";
        SequenceNo: Integer;
    begin
        LowerStatutoryReportTable.SetCurrentKey("Report Code", "Sequence No.");
        LowerStatutoryReportTable.SetRange("Report Code", Rec."Report Code");
        LowerStatutoryReportTable.SetFilter("Sequence No.", '%1..', Rec."Sequence No." + 1);
        if LowerStatutoryReportTable.FindFirst() then begin
            SequenceNo := LowerStatutoryReportTable."Sequence No.";
            LowerStatutoryReportTable."Sequence No." := Rec."Sequence No.";
            LowerStatutoryReportTable.Modify();

            Rec."Sequence No." := SequenceNo;
            Rec.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPageIndicForXML() PageIndicationForXML: Text[250]
    var
        PageIndicationXMLElement: Record "Page Indication XML Element";
    begin
        PageIndicationForXML := '';
        PageIndicationXMLElement.SetRange("Report Code", Rec."Report Code");
        PageIndicationXMLElement.SetRange("Table Code", Rec.Code);
        if PageIndicationXMLElement.FindSet() then
            repeat
                if PageIndicationForXML = '' then
                    PageIndicationForXML := PageIndicationXMLElement."XML Element Name"
                else
                    PageIndicationForXML := PageIndicationForXML + '|' + PageIndicationXMLElement."XML Element Name";
            until PageIndicationXMLElement.Next() = 0;
    end;
}

