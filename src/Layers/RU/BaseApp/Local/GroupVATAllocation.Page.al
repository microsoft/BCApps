#pragma warning disable AA0247
page 14928 "Group VAT Allocation"
{
    AutoSplitKey = true;
    Caption = 'Group VAT Allocation';
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Default VAT Allocation Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of default VAT allocation.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to post the VAT allocation to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the default VAT allocation entry.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the base amount if full, depreciated, or remaining.';
                }
                field("Allocation %"; Rec."Allocation %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the amount to be allocated to VAT.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, of the transaction.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    [Scope('OnPrem')]
    procedure GetRecords(var GroupVATAllocLine: Record "Default VAT Allocation Line" temporary)
    begin
        GroupVATAllocLine.DeleteAll();
        if Rec.FindSet() then
            repeat
                GroupVATAllocLine := Rec;
                GroupVATAllocLine.Insert();
            until Rec.Next() = 0;
    end;
}

