#pragma warning disable AA0247
page 17330 "Tax Calc. Cor. Dim. Filters"
{
    Caption = 'Tax Calc. Cor. Dim. Filters';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. Dim. Filter";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Register No."; Rec."Register No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the register number associated with the tax calculation dimension filter.';
                }
                field("TaxCalcDescription()"; Rec.TaxCalcDescription())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the record or entry.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the dimension code associated with the tax calculation dimension filter.';
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
        CreateTemplateDimFilterMARK();
    end;

    var
        SectionCode: Code[10];
        TemplateCorrespEntryNo: Integer;

    [Scope('OnPrem')]
    procedure SetTemplateCorresp(NewSectionCode: Code[10]; NewTemplateCorrespEntryNo: Integer)
    begin
        SectionCode := NewSectionCode;
        TemplateCorrespEntryNo := NewTemplateCorrespEntryNo;
    end;

    [Scope('OnPrem')]
    procedure CreateTemplateDimFilterMARK()
    var
        TemplateDimCorrespFilter: Record "Tax Calc. Dim. Corr. Filter";
        TemplateDimFilter: Record "Tax Calc. Dim. Filter";
    begin
        TemplateDimFilter.Reset();
        TemplateDimFilter.SetCurrentKey("Section Code", "Entry No.");
        TemplateDimFilter.SetRange("Section Code", SectionCode);

        TemplateDimCorrespFilter.SetRange("Section Code", SectionCode);
        TemplateDimCorrespFilter.SetRange("Corresp. Entry No.", TemplateCorrespEntryNo);
        if TemplateDimCorrespFilter.FindSet() then
            repeat
                TemplateDimFilter.SetRange("Entry No.", TemplateDimCorrespFilter."Connection Entry No.");
                if TemplateDimFilter.FindFirst() then begin
                    Rec := TemplateDimFilter;
                    Rec.Insert();
                end;
            until TemplateDimCorrespFilter.Next() = 0;
    end;
}

