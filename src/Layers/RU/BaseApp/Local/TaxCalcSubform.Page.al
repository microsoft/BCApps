#pragma warning disable AA0247
page 17315 "Tax Calc. Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Tax Calc. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Tax Diff. Amount (Tax)"; Rec."Tax Diff. Amount (Tax)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax differences amount associated with the tax calculation line.';

                    trigger OnValidate()
                    begin
                        TaxDiffAmountTaxOnAfterValidat();
                    end;
                }
                field("Tax Diff. Amount (Base)"; Rec."Tax Diff. Amount (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base tax differences amount associated with the tax calculation line.';

                    trigger OnValidate()
                    begin
                        TaxDiffAmountBaseOnAfterValida();
                    end;
                }
                field("Line Code"; Rec."Line Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line code associated with the tax calculation line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = DescriptionEmphasize;
                    ToolTip = 'Specifies the line code description associated with the tax calculation line.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field name associated with the tax calculation line.';
                }
                field(Disposed; Rec.Disposed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the tax calculation line is disposed.';
                }
                field("FA Type"; Rec."FA Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset type associated with the tax calculation line.';
                }
                field("Belonging to Manufacturing"; Rec."Belonging to Manufacturing")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the fixed asset is used in manufacturing.';
                }
                field("Depreciation Group"; Rec."Depreciation Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation group associated with the tax calculation line.';
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
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Expression Type" := Rec."Expression Type"::SumField;
    end;

    var
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    local procedure TaxDiffAmountTaxOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure TaxDiffAmountBaseOnAfterValida()
    begin
        CurrPage.Update();
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
        DescriptionEmphasize := Rec.Bold;
    end;
}

