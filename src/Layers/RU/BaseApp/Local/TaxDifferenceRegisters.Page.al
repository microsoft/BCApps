#pragma warning disable AA0247
page 17302 "Tax Difference Registers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Difference Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Tax Diff. Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1000000000)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first item entry number in the register.';
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end entry number associated with the tax differences register.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the entries were posted from.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was created.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Tax Diff. Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax Diff. Ledger Entries';
                    Image = LedgerEntries;
                    ToolTip = 'View entries resulting from posting variations in tax amounts caused by the different rules for recognizing income and expenses between entries for book accounting and tax accounting.';

                    trigger OnAction()
                    begin
                        TaxDiffEntry.Reset();
                        TaxDiffEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
                        PAGE.Run(0, TaxDiffEntry);
                    end;
                }
            }
        }
    }

    var
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
}

