#pragma warning disable AA0247
page 17205 "Tax Register Calc. Templ. Subf"
{
    AutoSplitKey = true;
    Caption = 'Template Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Register Template";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Report Line Code"; Rec."Report Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the report line code associated with the tax register template.';
                }
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax register template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the description associated with the tax register template.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field("Link Tax Register No."; Rec."Link Tax Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the link tax register number associated with the tax register template.';
                }
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field(Value; Rec.Value)
                {
                    ToolTip = 'Specifies the value associated with the tax register template.';
                    Visible = false;
                }
                field(Indentation; Rec.Indentation)
                {
                    ToolTip = 'Specifies the indentation of the line.';
                    Visible = false;
                }
                field(Bold; Rec.Bold)
                {
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                    Visible = false;
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ToolTip = 'Specifies the interval that you want to use as the rounding difference.';
                    Visible = false;
                }
                field(Period; Rec.Period)
                {
                    ToolTip = 'Specifies the period associated with the tax register template.';
                    Visible = false;
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    DrillDown = false;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        ShowDimensionsFilters();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        Rec.CalcFields("Dimensions Filters");
        if Rec."Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';
        DescriptionOnFormat();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DimFilters := '';
    end;

    var
#pragma warning disable AA0074
        Text1001: Label 'Present';
#pragma warning restore AA0074
        DimFilters: Text[30];
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        GLSetup: Record "General Ledger Setup";
    begin
        if (Rec."Line No." <> 0) and (Rec."Expression Type" = Rec."Expression Type"::Term) then begin
            GLSetup.Get();
            if (GLSetup."Global Dimension 1 Code" <> '') or
               (GLSetup."Global Dimension 2 Code" <> '')
            then begin
                TaxRegDimFilter.FilterGroup(2);
                TaxRegDimFilter.SetRange("Section Code", Rec."Section Code");
                TaxRegDimFilter.SetRange("Tax Register No.", Rec.Code);
                TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
                case true of
                    (GLSetup."Global Dimension 1 Code" <> '') and (GLSetup."Global Dimension 2 Code" <> ''):
                        TaxRegDimFilter.SetFilter("Dimension Code", '%1|%2',
                          GLSetup."Global Dimension 1 Code", GLSetup."Global Dimension 2 Code");
                    (GLSetup."Global Dimension 1 Code" <> ''):
                        TaxRegDimFilter.SetRange("Dimension Code", GLSetup."Global Dimension 1 Code");
                    else
                        TaxRegDimFilter.SetRange("Dimension Code", GLSetup."Global Dimension 2 Code");
                end;
                TaxRegDimFilter.FilterGroup(0);
                TaxRegDimFilter.SetRange("Line No.", Rec."Line No.");
                PAGE.RunModal(0, TaxRegDimFilter);
            end else
                GLSetup.TestField("Global Dimension 1 Code");
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
        DescriptionEmphasize := Rec.Bold;
    end;
}

