// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Navigate;

page 6998 "Posted Expense Report"
{
    Caption = 'Posted Expense Report';
    PageType = Card;
    SourceTable = "Posted Expense Report Header";
    InsertAllowed = false;
    Editable = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the expense report number.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense user number assigned to this report.';
                    Importance = Additional;
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense user name for this report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the expense report.';
                    Importance = Additional;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date used for accounting entries.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the first shortcut dimension code for posting analysis.';
                    Importance = Additional;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the second shortcut dimension code for posting analysis.';
                    Importance = Additional;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group used for tax posting.';
                    Importance = Additional;
                    Visible = false;
                }
                field("Spend Request No."; Rec."Spend Request No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            part("Posted Expense Report Subform"; "Posted Expense Report SubP.")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Attestation)
            {
                Caption = 'Attestation';
                Visible = Rec."Anti-corruption attestation";
                field("Anti-Corruption Attestation"; Rec."Anti-corruption attestation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the anti-corruption attestation has been accepted.';
                }
                field("Anti-Corruption Description"; Rec."Anti-corruption description")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies additional details for the anti-corruption attestation.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field(Corrected; Rec.Corrected)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies whether this report has been corrected.';
                    Editable = false;
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Corrected Document No."; Rec."Corrected Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the document number of the original report that was corrected.';
                    Editable = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the responsibility center used to assign costs.';
                    Importance = Additional;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                Provider = "Posted Expense Report Subform";
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Posted Expense Report Line"), "No." = field("Document No."), "Line No." = field("Line No.");
            }
#if not CLEAN29
#pragma warning disable AL0432
            part("Posted Exp. Report Statistics"; "Posted Exp. Report Statistics")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
                ObsoleteReason = 'Replaced by Posted Expense Report FactBox';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Visible = false;
            }
#pragma warning restore AL0432
#endif
            part("Posted Expense Report FactBox"; "Posted Expense Report FactBox")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
            }
            part(expenseFactbox; "Expense Factbox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expense';
                UpdatePropagation = Both;
                SubPageLink = "Posted Expense Report No." = field("No.");
            }
            part(Activity; "Expense Activity Log FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'History';
                SubPageLink = "Source Table ID" = const(Database::"Posted Expense Report Header"),
                              "Source Record System ID" = field(SystemId);
                Visible = Rec."No." <> '';
            }
            part("Expense Picture"; "Expense Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Provider = "Posted Expense Report Subform";
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Posted Expense Report Line"), "No." = field("Document No."), "Line No." = field("Line No."), "File Type" = const("Document Attachment File Type"::PDF);
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
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    RunObject = Page "Posted Expense Report Stats";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View statistical information, such as VAT amounts, for the posted expense report.';
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
                action("Spend Request")
                {
                    ApplicationArea = Basic, Suite;
                    Image = ProjectExpense;
                    Caption = 'Travel Request';
                    ToolTip = 'View the details of the travel request associated with this posted expense report.';
                    RunObject = Page "Travel Request Card";
                    RunPageLink = "No." = field("Spend Request No.");
                    Visible = Rec."Spend Request No." <> '';
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
            action(SendReimbursementNotification)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send Reimbursement Notification';
                Image = SendEmailPDF;
                ToolTip = 'Send an email notification to the expense user that the reimbursement for this posted expense report has been processed.';

                trigger OnAction()
                var
                    ExpenseReportPost: Codeunit "Expense Report-Post";
                begin
                    if ExpenseReportPost.CheckAndSendReimbursementNotification(Rec) then
                        Message(ReimbursementNotificationSentMsg);
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
                actionref(SendReimbursementNotification_Promoted; SendReimbursementNotification)
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
                    actionref(Statistics_Promoted; Statistics)
                    {
                    }
                    actionref(Employee_Promoted; Employee)
                    {
                    }
                    actionref("Expense User_Promoted"; "Expense User")
                    {
                    }
                    actionref("Spend Request_Promoted"; "Spend Request")
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
        ReimbursementNotificationSentMsg: Label 'The reimbursement notification was sent successfully.';

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;
}