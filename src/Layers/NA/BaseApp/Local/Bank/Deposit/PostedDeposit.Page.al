// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

using Microsoft.Bank.BankAccount;

page 10143 "Posted Deposit"
{
    Caption = 'Posted Deposit';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Posted Deposit Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the document number of the deposit document.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the bank account to which the deposit was made.';
                }
                field("Total Deposit Amount"; Rec."Total Deposit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount deposited to the bank account.';
                }
                field("Total Deposit Lines"; Rec."Total Deposit Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the sum of the amounts in the Amount fields on the associated posted deposit lines.';
                }
                field(Difference; GetDifference())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date the deposit was posted.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date of the deposit document.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the value assigned to this dimension for this deposit.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the bank account that the deposit was deposited in.';
                }
            }
            part(Subform; "Posted Deposit Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Deposit No." = field("No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = false;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Deposit")
            {
                Caption = '&Deposit';
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = field("Bank Account No."),
                                  "No." = field("No.");
                    RunPageView = where("Table Name" = const("Posted Deposit"));
                    ToolTip = 'View deposit comments that apply.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedDepositHeader: Record "Posted Deposit Header";
                begin
                    PostedDepositHeader.SetRange("No.", Rec."No.");
                    REPORT.Run(REPORT::Deposit, true, false, PostedDepositHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Deposit', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }

    local procedure GetDifference(): Decimal
    begin
        Rec.CalcFields("Total Deposit Lines");
        exit(Rec."Total Deposit Amount" - Rec."Total Deposit Lines");
    end;
}

