// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Vendor;
using System.Text;

page 28092 "Post Dated Checks-Purchases"
{
    AutoSplitKey = true;
    Caption = 'Post Dated Checks-Purchases';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Post Dated Check Line";
    SourceTableView = sorting("Line Number")
                      where("Account Type" = filter(" " | Vendor | "G/L Account"));

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    ToolTip = 'Specifies a filter, that will filter entries by date. You can enter a particular date or a time interval.';

                    trigger OnValidate()
                    begin
                        DateFilterOnAfterValidate();
                    end;
                }
                field(VendorNo; VendorNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor';
                    ToolTip = 'Specifies the vendor.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Clear(VendorList);
                        VendorList.LookupMode(true);
                        if not (VendorList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := VendorList.GetSelectionFilter();
                        exit(true);

                        UpdateVendor();
                        Rec.SetFilter("Check Date", DateFilter);
                        if not Rec.FindFirst() then
                            UpdateBalance();
                    end;

                    trigger OnValidate()
                    begin
                        VendorNoOnAfterValidate();
                    end;
                }
            }
            repeater(Control1500007)
            {
                ShowCaption = false;
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the entry on the journal line will be posted to.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document no. for this post-dated check journal.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the post-dated check journal line.';
                }
                field("Check Date"; Rec."Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the post-dated check when it is supposed to be banked.';
                    Visible = true;
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check No. for the post-dated check.';
                    Visible = true;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the post-dated check.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Amount of the post-dated check.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated amount in LCY.';
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when we received the post-dated check.';
                }
                field("Replacement Check"; Rec."Replacement Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this check is a replacement for any earlier unusable check.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line will be applied to an already-posted document.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line will be applied to an already-posted document.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the transaction for your reference.';
                }
                field("Bank Account"; Rec."Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account No. where you want to bank the post-dated check.';
                    Visible = true;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the payment journal line.';
                }
                field("Batch Name"; Rec."Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a default batch.';
                }
            }
            group(Control1500001)
            {
                ShowCaption = false;
                field(Description2; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description for the post-dated check journal line.';
                }
                field(VendorBalance; VendorBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance in your currency.';
                }
                field(LineCount; LineCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Count';
                    Editable = false;
                    ToolTip = 'Specifies the number of journal lines.';
                }
                field(LineAmount; LineAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount for the line.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Visible = false;
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
                    ToolTip = 'View or edit dimensions for the selected records.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("&Account")
            {
                Caption = '&Account';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View more information about the selected line.';

                    trigger OnAction()
                    begin
                        case Rec."Account Type" of
                            Rec."Account Type"::"G/L Account":
                                begin
                                    GLAccount.Get(Rec."Account No.");
                                    PAGE.RunModal(PAGE::"G/L Account Card", GLAccount);
                                end;
                            Rec."Account Type"::Vendor:
                                begin
                                    Vendor.Get(Rec."Account No.");
                                    PAGE.RunModal(PAGE::"Vendor Card", Vendor);
                                end;
                        end;
                    end;
                }
            }
            group("F&unction")
            {
                Caption = 'F&unction';
                Image = "Action";
                action("&Suggest Checks to Bank")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Suggest Checks to Bank';
                    Image = FilterLines;
                    ToolTip = 'Get a list of checks to bank based on the check date.';

                    trigger OnAction()
                    begin
                        VendorNo := '';
                        DateFilter := '';
                        Rec.SetView('SORTING(Line Number) where(Account Type=FILTER(Vendor|G/L Account))');

                        BankDate := '..' + Format(WorkDate());
                        Rec.SetFilter("Date Filter", BankDate);
                        Rec.SetFilter("Check Date", Rec.GetFilter("Date Filter"));
                        CurrPage.Update(false);
                        CountCheck := Rec.Count();
                        Message(Text002, CountCheck);
                    end;
                }
                action("Show &All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show &All';
                    Image = RemoveFilterLines;
                    ToolTip = 'Clear the filters and view all check lines.';

                    trigger OnAction()
                    begin
                        VendorNo := '';
                        DateFilter := '';
                        Rec.SetView('SORTING(Line Number) where(Account Type=FILTER(Vendor|G/L Account))');
                    end;
                }
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply &Entries';
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Apply the lines to the related documents.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.ApplyEntries(Rec);
                    end;
                }
            }
            group("&Payment")
            {
                Caption = '&Payment';
                action(SuggestVendorPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Vendor Payments';
                    Image = SuggestVendorPayments;
                    ToolTip = 'View the suggest document.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Account Type", Rec."Account Type"::Vendor);
                        PostDatedCheckMgt.SuggestVendorPayments();
                    end;
                }
                action("Preview Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Check';
                    Image = ViewCheck;
                    ToolTip = 'View a preview of the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.PreviewCheck(Rec);
                    end;
                }
                action("Print Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Check';
                    Image = PrintCheck;
                    ToolTip = 'Print the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.PrintCheck(Rec);
                    end;
                }
                action("Void Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Check';
                    Image = VoidCheck;
                    ToolTip = 'Start the process of voiding the check.';

                    trigger OnAction()
                    begin
                        PostDatedCheckMgt.VoidCheck(Rec);
                    end;
                }
                action(CreateCheckInstallments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Check Installments';
                    Image = Installments;
                    ToolTip = 'Start the process of creating check installments for post-dated checks. You can define the number of installments that a payment will be divided into, the percent of interest, and the period in which the checks will be created.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Check Date");
                        Rec.TestField("Account Type", Rec."Account Type"::Vendor);
                        Rec.TestField("Bank Account");
                        Rec.TestField("Document No.");
                        Rec.TestField("Check Printed", false);
                        CreateInstallments.SetPostDatedCheckLine(Rec);
                        CreateInstallments.RunModal();
                        Clear(CreateInstallments);
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(CreatePaymentJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Payment Journal';
                    Image = SuggestVendorPayments;
                    ToolTip = 'Open the payment journal and create journal lines based on your current selection.';

                    trigger OnAction()
                    begin
                        if Confirm(Text001, false) then begin
                            PostDatedCheckMgt.Post(Rec);
                            VendorNo := '';
                            DateFilter := '';
                            Rec.Reset();
                        end;
                        Rec.SetFilter("Account Type", 'Vendor|G/L Account');
                    end;
                }
                action("Print Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Report';
                    ToolTip = 'Print a report based on the current filters on the check line.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Post Dated Checks", true, true, Rec);
                    end;
                }
                action("Print Acknowledgement Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Acknowledgement Receipt';
                    Image = PrintAcknowledgement;
                    ToolTip = 'Print the receipt.';

                    trigger OnAction()
                    begin
                        PostDatedCheck.CopyFilters(Rec);
                        PostDatedCheck.SetRange("Account Type", Rec."Account Type");
                        PostDatedCheck.SetRange("Account No.", Rec."Account No.");
                        if PostDatedCheck.FindFirst() then
                            REPORT.RunModal(REPORT::"PDC Acknowledgement Receipt", true, true, PostDatedCheck);
                    end;
                }
            }
            action("Cash Receipt Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Receipt Journal';
                Image = CashReceiptJournal;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Cash Receipt Journal";
                ToolTip = 'Open the cash receipt journal and create journal lines based on your current selection.';
            }
        }
        area(reporting)
        {
            action("PDC Acknowledgement Receipt")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'PDC Acknowledgement Receipt';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "PDC Acknowledgement Receipt";
                ToolTip = 'Create a PDC acknowledgement receipt.';
            }
            action("Post Dated Checks")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Post Dated Checks';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Post Dated Checks";
                ToolTip = 'View the information that you want to print on the Post Dated Checks report based on the filters that you have set up for the check line.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreatePaymentJournal_Promoted; CreatePaymentJournal)
                {
                }
                actionref(Card_Promoted; Card)
                {
                }
                actionref("&Suggest Checks to Bank_Promoted"; "&Suggest Checks to Bank")
                {
                }
                actionref("Show &All_Promoted"; "Show &All")
                {
                }
                actionref(ApplyEntries_Promoted; ApplyEntries)
                {
                }
                actionref("Preview Check_Promoted"; "Preview Check")
                {
                }
                actionref("Print Check_Promoted"; "Print Check")
                {
                }
                actionref("Void Check_Promoted"; "Void Check")
                {
                }
                actionref(CreateCheckInstallments_Promoted; CreateCheckInstallments)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateBalance();
    end;

    var
        Text001: Label 'Are you sure you want to create Cash Journal Lines?';
        Text002: Label 'There are %1 check(s) to bank.';
        VendorNo: Code[250];
        Vendor: Record Vendor;
        PostDatedCheck: Record "Post Dated Check Line";
        GLAccount: Record "G/L Account";
        VendorList: Page "Vendor List";
        CreateInstallments: Report "Create Check Installments";
        PostDatedCheckMgt: Codeunit PostDatedCheckMgt;
        FilterTokens: Codeunit "Filter Tokens";
        CountCheck: Integer;
        LineCount: Integer;
        VendorBalance: Decimal;
        LineAmount: Decimal;
        DateFilter: Text[250];
        BankDate: Text[30];

    [Scope('OnPrem')]
    procedure UpdateBalance()
    begin
        LineAmount := 0;
        LineCount := 0;
        if Vendor.Get(Rec."Account No.") then begin
            Vendor.CalcFields("Balance (LCY)");
            VendorBalance := Vendor."Balance (LCY)";
        end else
            VendorBalance := 0;
        PostDatedCheck.Reset();
        PostDatedCheck.SetCurrentKey("Account Type", "Account No.");
        if DateFilter <> '' then
            PostDatedCheck.SetFilter("Check Date", DateFilter);
        PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Vendor);
        if VendorNo <> '' then
            PostDatedCheck.SetRange("Account No.", VendorNo);
        if PostDatedCheck.FindSet() then begin
            repeat
                LineAmount := LineAmount + PostDatedCheck."Amount (LCY)";
            until PostDatedCheck.Next() = 0;
            LineCount := PostDatedCheck.Count();
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVendor()
    begin
        if VendorNo = '' then
            Rec.SetRange("Account No.")
        else
            Rec.SetRange("Account No.", VendorNo);
        CurrPage.Update(false);
    end;

    local procedure DateFilterOnAfterValidate()
    begin
        FilterTokens.MakeDateFilter(DateFilter);
        Rec.SetFilter("Check Date", DateFilter);
        UpdateVendor();
        UpdateBalance();
    end;

    local procedure VendorNoOnAfterValidate()
    begin
        Rec.SetFilter("Check Date", DateFilter);
        UpdateVendor();
        UpdateBalance();
    end;
}

