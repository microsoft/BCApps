// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;

page 6987 "Posted Expense Reports"
{
    Caption = 'Posted Expense Reports';
    PageType = List;
    ApplicationArea = Basic, Suite;
    CardPageID = "Posted Expense Report";
    UsageCategory = History;
    RefreshOnActivate = true;
    SourceTable = "Posted Expense Report Header";
    Editable = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the posted expense report number.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ToolTip = 'Specifies the expense user number for the posted report.';
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ToolTip = 'Specifies the expense user name for the posted report.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the posted expense report.';
                }
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ToolTip = 'Specifies the posting group that determines ledger accounts for this employee.';
                }
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ToolTip = 'Specifies the date of the expense report.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date used for accounting entries.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the first shortcut dimension code for posting analysis.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the second shortcut dimension code for posting analysis.';
                }
                field(Canceled; Rec.Canceled)
                {
                }
            }
        }
        area(factboxes)
        {
            part(expenseFactbox; "Expense Factbox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expense';
                UpdatePropagation = Both;
                SubPageLink = "Posted Expense Report No." = field("No.");
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
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View dimensions, such as area, project, or department, that are assigned to sustainability value entry.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Comments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Expense Report Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Expense Report"), "No." = field("No."), "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Employee)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee';
                    Image = Employee;
                    ToolTip = 'View or edit detailed information about the employee.';

                    trigger OnAction()
                    begin
                        Rec.ShowEmployeeCard();
                    end;
                }
                action("Expense User")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense User';
                    Image = Employee;
                    RunObject = Page "Expense User";
                    RunPageLink = "No." = field("Expense User No.");
                    ToolTip = 'View or edit detailed information about the expense user.';
                }
            }
        }
        area(processing)
        {
            action("Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    NavigatePage.SetDoc(Rec."Posting Date", Rec."No.");
                    NavigatePage.Run();
                end;
            }
            action(CancelPostedExpenseReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                Image = Cancel;
                Enabled = not Rec.Canceled;
                ToolTip = 'Cancel the posted expense report. The general ledger, VAT, employee, and project entries are reversed, and the related expenses are released so they can be added to a new expense report.';

                trigger OnAction()
                var
                    CancelPostedExpenseReport: Codeunit "Cancel Posted Expense Report";
                begin
                    CancelPostedExpenseReport.CancelPostedExpenseReport(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Home';

                actionref("Navigate_Promoted"; "Navigate")
                {
                }
                actionref(CancelPostedExpenseReport_Promoted; CancelPostedExpenseReport)
                {
                }
                group("Category_Expense Report")
                {
                    Caption = 'Expense Report';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref(Comments_Promoted; Comments)
                    {
                    }
                    actionref(Employee_Promoted; Employee)
                    {
                    }
                    actionref("Expense User_Promoted"; "Expense User")
                    {
                    }
                }
                group(Category_Report)
                {
                    Caption = 'Report';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        NavigatePage: Page Navigate;
        Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible : Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}