#pragma warning disable AA0247
page 17214 "Tax Register G/L Corr. Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Register G/L Correspondence Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Register G/L Corr. Entry";
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
                    ToolTip = 'Specifies the debit account number associated with the tax register corresponding entry.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with the tax register corresponding entry.';
                }
                field("Register Type"; Rec."Register Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the register type associated with the tax register corresponding entry.';
                }
                field("Tax Register ID Totaling"; Rec."Tax Register ID Totaling")
                {
                    ToolTip = 'Specifies the tax register ID totaling associated with the tax register corresponding entry.';
                    Visible = false;
                }
                field(GetTaxRegName; Rec.GetTaxRegName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Registers List';

                    trigger OnAssistEdit()
                    begin
                        Rec.LookupTaxRegName();
                    end;

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownTaxRegName();
                    end;
                }
                field("Debit Account Name"; Rec."Debit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account name associated with the tax register corresponding entry.';
                }
                field("Credit Account Name"; Rec."Credit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account name associated with the tax register corresponding entry.';
                }
            }
        }
    }

    actions
    {
    }
}

