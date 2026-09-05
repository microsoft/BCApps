namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

page 6339 "Sust. G/L - Sust. Ledger Rel."
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L - Sustainability Entry Relations';
    PageType = List;
    SourceTable = "Sust. G/L - Sust. Ledger Rel.";
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ToolTip = 'Specifies the general ledger entry that the amount was collected from.';

                    trigger OnDrillDown()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        if GLEntry.Get(Rec."G/L Entry No.") then
                            Page.Run(Page::"General Ledger Entries", GLEntry);
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date of the collected general ledger entry.';
                }
                field("Collected Amount"; Rec."Collected Amount")
                {
                    ToolTip = 'Specifies the amount that was collected from the general ledger entry.';
                }
                field("Account Category"; Rec."Account Category")
                {
                    ToolTip = 'Specifies the sustainability account category that the general ledger entry was collected under.';
                }
                field("Sust. Ledger Entry No."; Rec."Sust. Ledger Entry No.")
                {
                    ToolTip = 'Specifies the sustainability ledger entry that was created from the collected amount.';

                    trigger OnDrillDown()
                    var
                        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
                    begin
                        if SustainabilityLedgerEntry.Get(Rec."Sust. Ledger Entry No.") then
                            Page.Run(Page::"Sustainability Ledger Entries", SustainabilityLedgerEntry);
                    end;
                }
            }
        }
    }
}
