// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

page 790 "G/L Account Categories"
{
    AboutTitle = 'About G/L Account Categories';
    AboutText = 'The G/L Account Categories page lets you create simple financial reports based on your chart of accounts. By providing categories, subcategories, and account mapping to your chart of accounts, you can generate basic financial reporting out of the box. If you''re just getting started with financial reporting, the standard reports are excellent options until you become more experienced.';
    AccessByPermission = TableData "G/L Account Category" = R;
    AdditionalSearchTerms = 'general ledger account categories';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Account Categories';
    InsertAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "G/L Account Category";
    SourceTableView = sorting("Presentation Order", "Sibling Sequence No.");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;
                ShowAsTree = true;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Rec."Has Children" or (Rec.Indentation = 0);
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Account Category"; Rec."Account Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category of the G/L account.';
                }
                field(GLAccTotaling; GLAccTotaling)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Accounts in Category';
                    TableRelation = "G/L Account";
                    ToolTip = 'Specifies which G/L accounts are included in the account category.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Rec.LookupTotaling();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        Rec.ValidateTotaling(GLAccTotaling);
                    end;
                }
                field("Additional Report Definition"; Rec."Additional Report Definition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional attributes that are used to create the cash flow statement.';
                }
                field(GetBalance; Rec.GetBalance())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Rec."Has Children" or (Rec.Indentation = 0);
                    ToolTip = 'Specifies the balance of the G/L account.';
                }
            }
        }
        area(factboxes)
        {
            part("G/L Accounts in Category"; "G/L Accounts ListPart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Accounts in Category';
                Editable = false;
                SubPageLink = "Account Subcategory Entry No." = field("Entry No.");
            }
            part("G/L Accounts without Category"; "G/L Accounts ListPart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'G/L Accounts without Category';
                SubPageView = where("Account Subcategory Entry No." = const(0));
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                Enabled = PageEditable;
                Image = NewChartOfAccounts;
                Scope = Repeater;
                ToolTip = 'Create a new G/L account category.';

                trigger OnAction()
                begin
                    SetRow(Rec.InsertRow());
                end;
            }
        }
        area(processing)
        {
            action(MoveUp)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Up';
                Enabled = PageEditable;
                Image = MoveUp;
                Scope = Repeater;
                ToolTip = 'Change the sorting of the account categories.';

                trigger OnAction()
                begin
                    Rec.MoveUp();
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Move Down';
                Enabled = PageEditable;
                Image = MoveDown;
                Scope = Repeater;
                ToolTip = 'Change the sorting of the account categories.';

                trigger OnAction()
                begin
                    Rec.MoveDown();
                end;
            }
            action(Indent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Indent';
                Enabled = PageEditable;
                Image = Indent;
                ToolTip = 'Move the account category to the right.';

                trigger OnAction()
                begin
                    Rec.MakeChildOfPreviousSibling();
                end;
            }
            action(Outdent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outdent';
                Enabled = PageEditable;
                Image = DecreaseIndent;
                ToolTip = 'Move the account category to the left.';

                trigger OnAction()
                begin
                    Rec.MakeSiblingOfParent();
                end;
            }
            action(GenerateAccSched)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate Financial Reports';
                Image = CreateLinesFromJob;
                ToolTip = 'Generate new or replace standard financial reports, such as Balance Sheet, Cash Flow Statement, Income Statement, and Retained Earnings.';

                trigger OnAction()
                var
                    GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
                begin
                    GLAccountCategoryMgt.ConfirmAndRunGenerateAccountSchedules();
                end;
            }
            action(ViewUncategorizedAccounts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Uncategorized Accounts';
                Image = ViewCheck;
                RunObject = page "Uncategorized G/L Accounts";
                ToolTip = 'View a list of Uncategorized G/L Accounts.';
            }
        }
        area(navigation)
        {
            action(GLSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'General Ledger Setup';
                Image = GeneralLedger;
                RunObject = Page "General Ledger Setup";
                ToolTip = 'View or edit the way to handle certain accounting issues in your company.';
            }
            action(AccSchedules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Financial Reporting';
                Image = Accounts;
                RunObject = Page "Financial Reports";
                ToolTip = 'Open your financial reports to analyze figures in general ledger accounts or to compare general ledger entries with general ledger budget entries.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(New_Promoted; New)
                {
                }
                actionref(Outdent_Promoted; Outdent)
                {
                }
                actionref(Indent_Promoted; Indent)
                {
                }
                actionref(MoveUp_Promoted; MoveUp)
                {
                }
                actionref(MoveDown_Promoted; MoveDown)
                {
                }
                actionref(GenerateAccSched_Promoted; GenerateAccSched)
                {
                }
                actionref(ViewUncategorizedAccounts_Promoted; ViewUncategorizedAccounts)
                {
                }
                actionref(GLSetup_Promoted; GLSetup)
                {
                }
                actionref(AccSchedules_Promoted; AccSchedules)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'General', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PageEditable := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Has Children");
        GLAccTotaling := Rec.GetTotaling();
    end;

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Rec.InitializeDataSet();
        Rec.SetAutoCalcFields("Has Children");

        PageEditable := CurrPage.Editable;
    end;

    var
        GLAccTotaling: Code[250];
        PageEditable: Boolean;

    procedure GetSelectionFilter(): Text
    var
        GLAccountCategory: Record "G/L Account Category";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(GLAccountCategory);
        exit(SelectionFilterManagement.GetSelectionFilterForGLAccountCategory(GLAccountCategory));
    end;

    local procedure SetRow(EntryNo: Integer)
    begin
        if EntryNo = 0 then
            exit;
        if Rec.Get(EntryNo) then;
        CurrPage.Update(false);
    end;
}

