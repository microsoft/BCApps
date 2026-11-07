#pragma warning disable AA0247
page 17329 "Tax Calc. Corresp. Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Calculation Correspondence Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Calc. G/L Corr. Entry";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with the tax calculation corresponding entry.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with the tax calculation corresponding entry.';
                }
                field("Tax Register ID Totaling"; Rec."Tax Register ID Totaling")
                {
                    ToolTip = 'Specifies the totaling tax register ID associated with the tax calculation corresponding entry.';
                    Visible = false;
                }
                field("TaxCalcName()"; Rec.TaxCalcName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Registers List';

                    trigger OnAssistEdit()
                    begin
                        Rec.LookupTaxCalcHeader();
                    end;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownTaxCalcHeader();
                    end;
                }
                field("Debit Account Name"; Rec."Debit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account name associated with the tax calculation corresponding entry.';
                }
                field("Credit Account Name"; Rec."Credit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account name associated with the tax calculation corresponding entry.';
                }
            }
        }
    }

    actions
    {
    }
}

