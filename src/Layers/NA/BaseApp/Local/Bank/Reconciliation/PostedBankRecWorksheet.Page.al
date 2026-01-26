// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;

page 10125 "Posted Bank Rec. Worksheet"
{
    Caption = 'Posted Bank Rec. Worksheet';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Posted Bank Rec. Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("G/L Balance (LCY)"; Rec."G/L Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the G/L balance for the assigned account number, based on the G/L Bank Account No. field.';
                }
                field("G/L Balance"; Rec."G/L Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the general ledger balance for the assigned account number.';
                }
                field("""Positive Adjustments"" - ""Negative Bal. Adjustments"""; Rec."Positive Adjustments" - Rec."Negative Bal. Adjustments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '+ Positive Adjustments';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of positive adjustments for the bank statement.';
                }
                field("""G/L Balance"" + (""Positive Adjustments"" - ""Negative Bal. Adjustments"")"; Rec."G/L Balance" + (Rec."Positive Adjustments" - Rec."Negative Bal. Adjustments"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subtotal';
                    Editable = false;
                    ToolTip = 'Specifies a subtotal amount for the posted worksheet. The subtotal is calculated by using the general ledger balance and any positive or negative adjustments.';
                }
                field("""Negative Adjustments"" - ""Positive Bal. Adjustments"""; Rec."Negative Adjustments" - Rec."Positive Bal. Adjustments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '- Negative Adjustments';
                    Editable = false;
                    ToolTip = 'Specifies the total of the negative adjustment lines for the bank statement.';
                }
                field("Ending G/L Balance"; Rec."G/L Balance" + (Rec."Positive Adjustments" - Rec."Negative Bal. Adjustments") + (Rec."Negative Adjustments" - Rec."Positive Bal. Adjustments"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending G/L Balance';
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the G/L Balance field, plus the Positive Adjustments field, minus the Negative Adjustments field. This is what the G/L balance will be after the bank reconciliation worksheet is posted and the adjustments are posted to the general ledger.';
                }
                field(Difference; (Rec."G/L Balance" + (Rec."Positive Adjustments" - Rec."Negative Bal. Adjustments") + (Rec."Negative Adjustments" - Rec."Positive Bal. Adjustments")) - ((Rec."Statement Balance" + Rec."Outstanding Deposits") - Rec."Outstanding Checks"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the Amount field and the Cleared Amount field.';
                }
                field("Cleared With./Chks. Per Stmnt."; Rec."Cleared With./Chks. Per Stmnt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the cleared withdrawals/checks for the statement being reconciled.';
                }
                field("Cleared Inc./Dpsts. Per Stmnt."; Rec."Cleared Inc./Dpsts. Per Stmnt.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total of the cleared increases/deposits for the statement being reconciled.';
                }
                field("Statement Balance"; Rec."Statement Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance on Statement';
                    Editable = false;
                    ToolTip = 'Specifies the amount entered by the operator from the balance found on the bank statement.';
                }
                field("Outstanding Deposits"; Rec."Outstanding Deposits")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '+ Outstanding Deposits';
                    Editable = false;
                    ToolTip = 'Specifies the total of outstanding deposits of type Increase for the bank statement.';
                }
                field("""Statement Balance"" + ""Outstanding Deposits"""; Rec."Statement Balance" + Rec."Outstanding Deposits")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subtotal';
                    Editable = false;
                    ToolTip = 'Specifies a subtotal amount for the posted worksheet. The subtotal is calculated by using the general ledger balance and any positive or negative adjustments.';
                }
                field("Outstanding Checks"; Rec."Outstanding Checks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '- Outstanding Checks';
                    Editable = false;
                    ToolTip = 'Specifies the total of outstanding check withdrawals for the bank statement.';
                }
                field("(""Statement Balance"" + ""Outstanding Deposits"") - ""Outstanding Checks"""; (Rec."Statement Balance" + Rec."Outstanding Deposits") - Rec."Outstanding Checks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Balance';
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the Balance on Statement field, plus the Outstanding Deposits field, minus the Outstanding Checks field.';
                }
            }
            group(Checks)
            {
                Caption = 'Checks';
                part(ChecksSubForm; "Posted Bank Rec. Chk Lines Sub")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = field("Bank Account No."),
                                  "Statement No." = field("Statement No."),
                                  "Record Type" = const(Check);
                }
            }
            group("Deposits/Transfers")
            {
                Caption = 'Deposits/Transfers';
                part(DepositsSubForm; "Posted Bank Rec. Dep Lines Sub")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = field("Bank Account No."),
                                  "Statement No." = field("Statement No.");
                    SubPageView = where("Record Type" = const(Deposit));
                }
            }
            group(Adjustments)
            {
                Caption = 'Adjustments';
                part(AdjustmentsSubForm; "Posted Bank Rec. Adj Lines Sub")
                {
                    ApplicationArea = Basic, Suite;
                    SubPageLink = "Bank Account No." = field("Bank Account No."),
                                  "Statement No." = field("Statement No.");
                    SubPageView = where("Record Type" = const(Adjustment));
                }
            }
            group("Control Info")
            {
                Caption = 'Control Info';
                field("Bank Account No.2"; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the code for the bank account the reconciliation applies to.';
                }
                field("Statement No.2"; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the statement number to be reconciled.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code assigned to the bank account.';
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies currency conversions when posting adjustments for bank accounts with a foreign currency code assigned.';
                }
                field("Statement Date2"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the as-of date of the statement. All G/L balances will be calculated based upon this date.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of times the statement has been printed.';
                }
                field("Date Created"; Rec."Date Created")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a date automatically populated when the record is created.';
                }
                field("Time Created"; Rec."Time Created")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the  time created, which is automatically populated when the record is created.';
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    DrillDown = false;
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the User ID of the person who created the record.';
                }
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
            group("&Bank Rec.")
            {
                Caption = '&Bank Rec.';
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Bank Comment Sheet";
                    RunPageLink = "Bank Account No." = field("Bank Account No."),
                                  "No." = field("Statement No.");
                    RunPageView = where("Table Name" = const("Posted Bank Rec."));
                    ToolTip = 'View comments that apply.';
                }
                action("C&ard")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ard';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("Bank Account No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the bank account that is being reconciled. ';
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
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Rec.PrintRecords(true);
                end;
            }
            action(Navigate)
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
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    procedure SetupRecord()
    begin
        Rec.SetRange("Date Filter", Rec."Statement Date");
        Rec.CalcFields("Positive Adjustments",
          "Negative Adjustments",
          "Positive Bal. Adjustments",
          "Negative Bal. Adjustments");
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        SetupRecord();
    end;
}

