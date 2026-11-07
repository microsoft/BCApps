#pragma warning disable AA0247
page 17207 "Tax Register Term"
{
    Caption = 'Tax Register Term';
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Tax Register Term";

    layout
    {
        area(content)
        {
            repeater(TermsList)
            {
                field("Term Code"; Rec."Term Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term code associated with the tax register term name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax register term name.';
                }
                field("Expression Type"; Rec."Expression Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the related tax calculation term is named, such as Plus/Minus, Multiply/Divide, and Compare.';
                }
                field(Expression; Rec.Expression)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the expression of the related XML element.';
                }
                field("Rounding Precision"; Rec."Rounding Precision")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the interval that you want to use as the rounding difference.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Check Term")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check Term';
                    Image = CheckList;
                    ToolTip = 'Verify the tax register term name.';

                    trigger OnAction()
                    begin
                        TaxRegTermMgt.CheckTaxRegTerm(
                          false, Rec."Section Code",
                          DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Check Term_Promoted"; "Check Term")
                {
                }
            }
        }
    }

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
}

