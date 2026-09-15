#pragma warning disable AA0247
page 17316 "Tax Calc. Terms"
{
    Caption = 'Tax Calc. Terms';
    DelayedInsert = true;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Tax Calc. Term";

    layout
    {
        area(content)
        {
            repeater(TermsList)
            {
                field("Term Code"; Rec."Term Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the term code associated with the tax calculation term name.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with the tax calculation term name.';
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

                    trigger OnAssistEdit()
                    var
                        TaxCalcTermLine: Record "Tax Calc. Term Formula";
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        if Rec."Term Code" = '' then
                            exit;
                        TaxCalcTermLine.Reset();
                        TaxCalcTermLine.FilterGroup(2);
                        TaxCalcTermLine.SetRange("Section Code", Rec."Section Code");
                        TaxCalcTermLine.FilterGroup(0);
                        TaxCalcTermLine.SetRange("Term Code", Rec."Term Code");
                        if (Rec."Expression Type" = Rec."Expression Type"::Compare) and not (TaxCalcTermLine.Count = 3) then begin
                            if not (TaxCalcTermLine.Count = 0) then
                                TaxCalcTermLine.DeleteAll();
                            TaxCalcTermLine.Init();
                            TaxCalcTermLine."Section Code" := Rec."Section Code";
                            TaxCalcTermLine."Term Code" := Rec."Term Code";
                            TaxCalcTermLine."Account Type" := TaxCalcTermLine."Account Type"::Termin;
                            TaxCalcTermLine.Operation := TaxCalcTermLine.Operation::"Less 0";
                            TaxCalcTermLine."Line No." := 10000;
                            TaxCalcTermLine.Insert();
                            TaxCalcTermLine.Operation := TaxCalcTermLine.Operation::"Equ 0";
                            TaxCalcTermLine."Line No." := 20000;
                            TaxCalcTermLine.Insert();
                            TaxCalcTermLine.Operation := TaxCalcTermLine.Operation::"Grate 0";
                            TaxCalcTermLine."Line No." := 30000;
                            TaxCalcTermLine.Insert();
                            TaxCalcTermLine."Line No." := 10000;
                            TaxCalcTermLine.Find();
                            Commit();
                        end;
                        PAGE.RunModal(0, TaxCalcTermLine);
                        Rec.Expression :=
                          TaxRegTermMgt.MakeTermExpressionText(Rec."Term Code", Rec."Section Code",
                            DATABASE::"Tax Calc. Term", DATABASE::"Tax Calc. Term Formula");
                    end;
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
                          DATABASE::"Tax Calc. Term", DATABASE::"Tax Calc. Term Formula");
                    end;
                }
            }
        }
    }

    var
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
}

