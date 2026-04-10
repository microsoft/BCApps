#pragma warning disable AA0247
page 17206 "Tax Register Entr. Templ. Subf"
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
                    ToolTip = 'Specifies the report line code associated with the tax register template.';
                    Visible = false;
                }
                field("Link Tax Register No."; Rec."Link Tax Register No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the link tax register number associated with the tax register template.';
                    Visible = false;
                }
                field("Sum Field No."; Rec."Sum Field No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the sum field number associated with the tax register template.';
                    Visible = false;
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
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Term Line Code"; Rec."Term Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term line code associated with the tax register template.';
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
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period associated with the tax register template.';
                }
                field(DimFilters; DimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions Filters';
                    DrillDown = false;
                    ToolTip = 'Specifies a filter for dimensions by which data is included.';

                    trigger OnAssistEdit()
                    begin
                        ShowDimensionsFilters();
                    end;
                }
                field(GLCorrDimFilters; GLCorrDimFilters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Corr. Dimensions Filters';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the dimensions by which data is shown.';

                    trigger OnAssistEdit()
                    begin
                        ShowGLCorrDimensionsFilters();
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
        Rec.CalcFields("Dimensions Filters", "G/L Corr. Dimensions Filters");
        if Rec."Dimensions Filters" then
            DimFilters := Text1001
        else
            DimFilters := '';

        if Rec."G/L Corr. Dimensions Filters" then
            GLCorrDimFilters := Text1001
        else
            GLCorrDimFilters := '';
        DescriptionOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
        Rec."Link Tax Register No." := Rec.Code;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
        Rec."Link Tax Register No." := Rec.Code;
        DimFilters := '';
        GLCorrDimFilters := '';
    end;

    var
#pragma warning disable AA0074
        Text1001: Label 'Present';
#pragma warning restore AA0074
        TaxRegisterName: Record "Tax Register";
        DimFilters: Text[30];
        GLCorrDimFilters: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label '%1 should be used for this type of tax register.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    [Scope('OnPrem')]
    procedure ShowDimensionsFilters()
    var
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
        TaxRegSection: Record "Tax Register Section";
        DimCodeFilter: Text[1024];
    begin
        CurrPage.SaveRecord();
        Commit();
        TaxRegisterName.Get(Rec."Section Code", Rec.Code);
        if TaxRegisterName."Table ID" = DATABASE::"Tax Register G/L Entry" then
            Error(Text1002, Rec.FieldCaption("G/L Corr. Dimensions Filters"));

        if (Rec."Line No." <> 0) and (Rec."Expression Type" = Rec."Expression Type"::SumField) then begin
            TaxRegSection.Get(Rec."Section Code");
            if (TaxRegSection."Dimension 1 Code" <> '') or
               (TaxRegSection."Dimension 2 Code" <> '') or
               (TaxRegSection."Dimension 3 Code" <> '') or
               (TaxRegSection."Dimension 4 Code" <> '')
            then begin
                TaxRegDimFilter.FilterGroup(2);
                TaxRegDimFilter.SetRange("Section Code", Rec."Section Code");
                TaxRegDimFilter.SetRange("Tax Register No.", Rec.Code);
                TaxRegDimFilter.SetRange(Define, TaxRegDimFilter.Define::Template);
                if TaxRegSection."Dimension 1 Code" <> '' then
                    DimCodeFilter := TaxRegSection."Dimension 1 Code";
                if TaxRegSection."Dimension 2 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 2 Code");
                if TaxRegSection."Dimension 3 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 3 Code");
                if TaxRegSection."Dimension 4 Code" <> '' then
                    DimCodeFilter := StrSubstNo('%1|%2', DimCodeFilter, TaxRegSection."Dimension 4 Code");
                DimCodeFilter := DelChr(DimCodeFilter, '<', '|');
                TaxRegDimFilter.SetFilter("Dimension Code", DimCodeFilter);
                TaxRegDimFilter.FilterGroup(0);
                TaxRegDimFilter.SetRange("Line No.", Rec."Line No.");
                PAGE.RunModal(0, TaxRegDimFilter);
            end;
        end;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure ShowGLCorrDimensionsFilters()
    var
        TaxRegGLCorrDimFilter: Record "Tax Reg. G/L Corr. Dim. Filter";
    begin
        CurrPage.SaveRecord();
        Commit();
        TaxRegisterName.Get(Rec."Section Code", Rec.Code);
        if (TaxRegisterName."Table ID" = DATABASE::"Tax Register G/L Entry") and (Rec."Line No." <> 0) then begin
            TaxRegGLCorrDimFilter.FilterGroup(2);
            TaxRegGLCorrDimFilter.SetRange("Section Code", Rec."Section Code");
            TaxRegGLCorrDimFilter.SetRange("Tax Register No.", Rec.Code);
            TaxRegGLCorrDimFilter.SetRange(Define, TaxRegGLCorrDimFilter.Define::Template);
            TaxRegGLCorrDimFilter.SetRange("Line No.", Rec."Line No.");
            TaxRegGLCorrDimFilter.FilterGroup(0);
            PAGE.RunModal(0, TaxRegGLCorrDimFilter);
        end else
            Error(Text1002, Rec.FieldCaption("Dimensions Filters"));
        CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
        DescriptionEmphasize := Rec.Bold;
    end;
}

