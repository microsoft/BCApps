// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;

page 6989 Expenses
{
    Caption = 'Expenses';
    PageType = List;
    ApplicationArea = Basic, Suite;
    CardPageID = Expense;
    UsageCategory = Lists;
    RefreshOnActivate = true;
    SourceTable = Expense;
    Editable = false;

    AboutTitle = 'About expenses';
    AboutText = 'Record and submit expenses incurred by employees by entering categories, amounts, dates, and required information to ensure compliance with company policies.';
    AdditionalSearchTerms = 'Receipt, Spend, Cost Item, Claim Item';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies a unique number that identifies the expense.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ToolTip = 'Specifies the expense user who incurred the expense.';
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ToolTip = 'Specifies the date the expense occurred.';
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyleTxt;
                    ToolTip = 'Specifies the current status of the expense.';
                }
                field("Expense Category"; Rec."Expense Category")
                {
                    ToolTip = 'Specifies the category of the expense.';
                }
                field("Merchant Name"; Rec."Merchant Name")
                {
                    ToolTip = 'Specifies the name of the merchant where the expense occurred.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the total amount in the expense currency.';
                }
            }
        }
        area(factboxes)
        {
            part(Statistics; "Expense Statistics")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expense Statistics';
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense"), "No." = field("No.");
            }
            part("Expense Picture"; "Expense Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense"), "No." = field("No."), "File Type" = const("Document Attachment File Type"::PDF);
                ShowFilter = false;
            }
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Show My Expenses")
            {
                Caption = 'Show My Expenses';
                Image = UseFilters;
                ToolTip = 'Filters the list to your expenses.';
                trigger OnAction()
                begin
                    Rec.FilterByCurrentUser();
                    if Rec.FindSet() then;
                end;
            }
            group("Functions")
            {
                Caption = 'Functions';
                Image = "Action";
                action("Create Expense Report")
                {
                    Caption = 'Create Expense Report';
                    Image = NewDocument;
                    ToolTip = 'Create a report with the selected expenses. Available if selected expenses are released.';
                    Enabled = Rec.Status = Rec.Status::Released;

                    trigger OnAction()
                    var
                        Expenses: Record Expense;
                        CreateExpenseReport: Codeunit "Create Expense Report";
                    begin
                        CurrPage.SetSelectionFilter(Expenses);
                        CreateExpenseReport.AddExpensesToReport(Expenses);
                    end;
                }
            }
            group(Action12)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the selected expenses and lock editing. Reopen to edit.';

                    trigger OnAction()
                    var
                        Expense: Record Expense;
                    begin
                        CurrPage.SetSelectionFilter(Expense);
                        Rec.PerformManualRelease(Expense);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Reopen the selected expenses to allow edits.';

                    trigger OnAction()
                    var
                        Expense: Record Expense;
                    begin
                        CurrPage.SetSelectionFilter(Expense);
                        Rec.PerformManualReopen(Expense);
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                trigger OnAction()
                begin
                    Rec.ShowDocDim();
                    CurrPage.SaveRecord();
                end;
            }
            action("VAT Specification")
            {
                Image = VATPostingSetup;
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Specification';
                RunObject = Page "Expense VAT Specification";
                RunPageLink = "Expense No." = field("No.");
                Enabled = Rec."No." <> '';
                ToolTip = 'View or edit the per-rate VAT specification captured from the original invoice for the selected expense.';
            }
            action("Expense Report")
            {
                Image = Document;
                ApplicationArea = Basic, Suite;
                Caption = 'Expense Report';
                RunObject = Page "Expense Report";
                RunPageLink = "No." = field("Expense Report No.");
                Enabled = (Rec."Expense Report No." <> '') and (Rec."Posted Expense Report No." = '');
                ToolTip = 'View the details of the expense report associated with this expense.';
            }
            action("Posted Expense Report")
            {
                Image = Document;
                ApplicationArea = Basic, Suite;
                Caption = 'Posted Expense Report';
                RunObject = Page "Posted Expense Report";
                RunPageLink = "No." = field("Posted Expense Report No.");
                Enabled = Rec."Posted Expense Report No." <> '';
                ToolTip = 'View the details of the posted expense report associated with this expense.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Home';

                actionref(CreateExpenseReport_Promoted; "Create Expense Report")
                {
                }
            }
            group(Category_Release)
            {
                Caption = 'Release';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
            }
            group(Category_Expense)
            {
                Caption = 'Expense';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(VATSpecification_Promoted; "VAT Specification")
                {
                }
                actionref(ExpenseReport_Promoted; "Expense Report")
                {
                }
                actionref(PostedExpenseReport_Promoted; "Posted Expense Report")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyleTxt := Rec.GetStatusStyleText();
    end;

    var
        StatusStyleTxt: Text;
}