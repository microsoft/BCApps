namespace System.IO;

page 8628 "Config. Selection"
{
    Caption = 'Config. Selection';
    PageType = List;
    SourceTable = "Config. Selection";
    SourceTableTemporary = true;
    SourceTableView = sorting("Vertical Sorting");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the configuration package has been selected.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the configuration package part. The part can be one of the following types:';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that is used in the configuration selection.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = NameEmphasize;
                    ToolTip = 'Specifies the name of the of the configuration package.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Select All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select All';
                Image = AllLines;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                begin
                    Rec.ModifyAll(Selected, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Select All_Promoted"; "Select All")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        case Rec."Line Type" of
            Rec."Line Type"::Group:
                NameIndent := 1;
            Rec."Line Type"::Table:
                NameIndent := 2;
        end;

        NameEmphasize := (NameIndent in [0, 1]);
    end;

    var
        NameIndent: Integer;
        NameEmphasize: Boolean;

    procedure Set(var TempConfigSelection: Record "Config. Selection" temporary)
    begin
        if TempConfigSelection.FindSet() then
            repeat
                Rec.Init();
                Rec."Line No." := TempConfigSelection."Line No.";
                Rec."Table ID" := TempConfigSelection."Table ID";
                Rec.Name := TempConfigSelection.Name;
                Rec."Line Type" := TempConfigSelection."Line Type";
                Rec."Parent Line No." := TempConfigSelection."Parent Line No.";
                Rec."Vertical Sorting" := TempConfigSelection."Vertical Sorting";
                Rec.Selected := TempConfigSelection.Selected;
                Rec.Insert();
            until TempConfigSelection.Next() = 0;
    end;

    procedure Get(var TempConfigSelection: Record "Config. Selection" temporary): Integer
    var
        Counter: Integer;
    begin
        Counter := 0;
        TempConfigSelection.DeleteAll();
        if Rec.FindSet() then
            repeat
                TempConfigSelection.Init();
                TempConfigSelection."Line No." := Rec."Line No.";
                TempConfigSelection."Table ID" := Rec."Table ID";
                TempConfigSelection.Name := Rec.Name;
                TempConfigSelection."Line Type" := Rec."Line Type";
                TempConfigSelection."Parent Line No." := Rec."Parent Line No.";
                TempConfigSelection."Vertical Sorting" := Rec."Vertical Sorting";
                TempConfigSelection.Selected := Rec.Selected;
                if Rec.Selected then
                    Counter += 1;
                TempConfigSelection.Insert();
            until Rec.Next() = 0;

        exit(Counter);
    end;
}

