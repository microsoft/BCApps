#pragma warning disable AA0247
page 12401 "G/L Correspondence Entries"
{
    Caption = 'G/L Correspondence Entries';
    DataCaptionFields = "Debit Account No.", "Credit Account No.";
    Editable = false;
    PageType = List;
    SourceTable = "G/L Correspondence Entry";

    layout
    {
        area(content)
        {
            repeater(Control1210002)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with this correspondence entry.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with this correspondence entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount associated with this correspondence entry.';
                }
                field("Amount (ACY)"; Rec."Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount in alternate reporting currency associated with this correspondence entry.';
                }
                field("Debit Source Type"; Rec."Debit Source Type")
                {
                    ToolTip = 'Specifies the debit source type associated with this correspondence entry.';
                    Visible = false;
                }
                field("Debit Source No."; Rec."Debit Source No.")
                {
                    ToolTip = 'Specifies the debit source number associated with this correspondence entry.';
                    Visible = false;
                }
                field("Credit Source Type"; Rec."Credit Source Type")
                {
                    ToolTip = 'Specifies the credit source type associated with this correspondence entry.';
                    Visible = false;
                }
                field("Credit Source No."; Rec."Credit Source No.")
                {
                    ToolTip = 'Specifies the credit source number associated with this correspondence entry.';
                    Visible = false;
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
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number associated with this correspondence entry.';
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                }
                field("Debit Global Dimension 1 Code"; Rec."Debit Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit Global Dimension 1 code associated with this correspondence entry.';
                }
                field("Debit Global Dimension 2 Code"; Rec."Debit Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit Global Dimension 2 code associated with this correspondence entry.';
                }
                field(Positive; Rec.Positive)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this correspondence entry is positive.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the record was created.';
                }
                field("Credit Global Dimension 1 Code"; Rec."Credit Global Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit Global Dimension 1 code associated with this correspondence entry.';
                }
                field("Credit Global Dimension 2 Code"; Rec."Credit Global Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit Global Dimension 2 code associated with this correspondence entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    NavigateForm.SetDoc(Rec."Posting Date", Rec."Document No.");
                    NavigateForm.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        NavigateForm: Page Navigate;
}

