#pragma warning disable AA0247
page 17242 "Tax Reg G/L Corres Dim Filters"
{
    Caption = 'Tax Reg G/L Corres Dim Filters';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Register Dim. Filter";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Tax Register No."; Rec."Tax Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax register number associated with the tax register dimension filter.';
                }
                field(TaxRegDescription; Rec.TaxRegDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the record or entry.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with the tax register dimension filter.';
                }
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension value that the data is filtered by.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CreateTaxRegDimFilter();
    end;

    var
        SectionCode: Code[10];
        TaxRegGLCorrEntryNo: Integer;

    [Scope('OnPrem')]
    procedure SetTaxRegGLCorr(NewSectionCode: Code[10]; NewTaxRegGLCorrEntryNo: Integer)
    begin
        SectionCode := NewSectionCode;
        TaxRegGLCorrEntryNo := NewTaxRegGLCorrEntryNo;
    end;

    [Scope('OnPrem')]
    procedure CreateTaxRegDimFilter()
    var
        TaxRegDimCorrFilter: Record "Tax Register Dim. Corr. Filter";
        TaxRegDimFilter: Record "Tax Register Dim. Filter";
    begin
        TaxRegDimFilter.SetCurrentKey("Section Code", "Entry No.");
        TaxRegDimFilter.SetRange("Section Code", SectionCode);

        TaxRegDimCorrFilter.SetRange("Section Code", SectionCode);
        TaxRegDimCorrFilter.SetRange("G/L Corr. Entry No.", TaxRegGLCorrEntryNo);
        TaxRegDimCorrFilter.SetRange("Connection Type", TaxRegDimCorrFilter."Connection Type"::Filters);
        if TaxRegDimCorrFilter.Find('-') then
            repeat
                TaxRegDimFilter.SetRange("Entry No.", TaxRegDimCorrFilter."Connection Entry No.");
                if TaxRegDimFilter.FindFirst() then begin
                    Rec := TaxRegDimFilter;
                    Rec.Insert();
                end;
            until TaxRegDimCorrFilter.Next() = 0;
    end;
}

