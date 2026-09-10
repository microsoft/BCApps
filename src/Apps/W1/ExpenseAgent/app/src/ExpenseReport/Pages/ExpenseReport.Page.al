// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Enums;
using Microsoft.Utilities;
using System.Security.User;

page 6910 "Expense Report"
{
    Caption = 'Expense Report';
    PageType = Card;
    SourceTable = "Expense Report Header";
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
                    ToolTip = 'Specifies the expense report number. Visible when document numbers are shown.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit()
                    end;
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the expense user for the report.';
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
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Posting Date field.';
                    Importance = Additional;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies dimension 1 used for analytics and posting.';
                    Importance = Additional;
                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies dimension 2 used for analytics and posting.';
                    Importance = Additional;
                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV();
                    end;
                }
                field("Reimbursement Currency Code"; Rec."Reimbursement Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Reimbursement Currency Code field.';
                    Importance = Additional;

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        Clear(ChangeExchangeRate);
                        if Rec."Posting Date" <> 0D then
                            ChangeExchangeRate.SetParameter(Rec."Reimbursement Currency Code", Rec."Reimbursement Currency Factor", Rec."Posting Date")
                        else
                            ChangeExchangeRate.SetParameter(Rec."Reimbursement Currency Code", Rec."Reimbursement Currency Factor", WorkDate());
                        if ChangeExchangeRate.RunModal() = Action::OK then
                            Rec.Validate("Reimbursement Currency Factor", ChangeExchangeRate.GetParameter());
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current status of the expense report, for example Draft, Released, or Posted.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group used when posting VAT for this expense report.';
                    Importance = Additional;
                    Visible = false;
                }
                field("Spend Request No."; Rec."Spend Request No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Final Approver No."; Rec."Final Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the final approver for the expense report, prepopulated from the expense user''s approver.';
                    Importance = Additional;
                    Editable = false;
                    Visible = AgentEnabled;
                }
                field("Interim Approver No."; Rec."Interim Approver No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the optional interim approver who approves before the final approver.';
                    Importance = Additional;
                    Editable = false;
                    Visible = AgentEnabled;
                }
                group("Approver Comment")
                {
                    Caption = 'Approval Comments';

                    field(ApproverComment; ApproverComment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Approver Comment';
                        DrillDown = true;
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the latest comment from the approver. Drill down to view the full comment.';

                        trigger OnDrillDown()
                        begin
                            if ApproverComment <> '' then
                                Message(ApproverComment);
                        end;
                    }
                    field(SubmitterComment; SubmitterComment)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Submitter Comment';
                        DrillDown = true;
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the latest comment from the submitter. Drill down to view the full comment.';

                        trigger OnDrillDown()
                        begin
                            if SubmitterComment <> '' then
                                Message(SubmitterComment);
                        end;
                    }
                }
            }
            part("Expense Report Subform"; "Expense Report SubPage")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
                Enabled = Rec."No." <> '';
            }
            group(Attestation)
            {
                Caption = 'Attestation';
                Visible = ShowAttestationFastTab;
                field("Anti-Corruption Attestation"; Rec."Anti-corruption attestation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether you accepted the anti-corruption attestation.';
                }
                field("Anti-Corruption Description"; Rec."Anti-corruption description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies details that explain the anti-corruption attestation when required.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                field(Corrected; Rec.Corrected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this report corrects a previously posted report.';
                    Editable = false;
                }
                field("Corrected Document No."; Rec."Corrected Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that this report corrects.';
                    Editable = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language code used for the report.';
                    Importance = Additional;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code for corrections or cancellations.';
                    Importance = Additional;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the responsibility center used for posting and reporting.';
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
                Provider = "Expense Report Subform";
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense Report Line"), "No." = field("Document No."), "Line No." = field("Line No.");
            }
#if not CLEAN29
#pragma warning disable AL0432
            part("Expense Report Statistics"; "Expense Report Statistics")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
                ObsoleteReason = 'Replaced by Expense Report FactBox';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Visible = false;
            }
#pragma warning restore AL0432
#endif
            part("Expense Report FactBox"; "Expense Report FactBox")
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
                SubPageLink = "Expense Report No." = field("No.");
                Visible = Rec."No." <> '';
            }
            part(RuleViolations; "Expense Report Rule Violations")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rule Violations';
                Provider = "Expense Report Subform";
                UpdatePropagation = Both;
                SubPageLink = "Expense Report No." = field("Document No."), "Report Line No." = field("Line No.");
                Visible = Rec."No." <> '';
            }
            part(Activity; "Expense Activity Log FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'History';
                SubPageLink = "Source Table ID" = const(Database::"Expense Report Header"),
                              "Source Record System ID" = field(SystemId);
                Visible = Rec."No." <> '';
            }
            part("Expense Picture"; "Expense Picture")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview';
                Provider = "Expense Report Subform";
                SubPageLink = "Document Type" = const(Expense), "Table ID" = const(Database::"Expense Report Line"), "No." = field("Document No."), "Line No." = field("Line No."), "File Type" = const("Document Attachment File Type"::PDF);
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
            group(Action21)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Suite;
                    Caption = 'Release';
                    Enabled = Rec.Status = Rec.Status::Open;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
                    begin
                        ReleaseExpenseReportDoc.PerformManualReopen(Rec);
                    end;
                }
            }
            group("Posting")
            {
                Caption = 'Posting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post this expense report.';

                    trigger OnAction()
                    begin
                        PostDocument(Enum::"Navigate After Posting"::"Posted Document");
                    end;
                }
                action(PostAndNew)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and New';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'Alt+F9';
                    ToolTip = 'Post the sales document and create a new, empty one.';

                    trigger OnAction()
                    begin
                        PostDocument(Enum::"Navigate After Posting"::"New Document");
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        Rec.Preview(Rec);
                    end;
                }
            }
            group("Functions")
            {
                Caption = 'Functions';
                Image = "Action";
                action(GetExpenseLine)
                {
                    ApplicationArea = Basic, Suite;
                    Image = Import;
                    Caption = 'Get Expense Line';
                    ToolTip = 'Executes the Get Expense Line action.';

                    trigger OnAction()
                    var
                        CreateExpenseReport: Codeunit "Create Expense Report";
                    begin
                        CreateExpenseReport.AddExpensesToReport(Rec);

                        CurrPage.Update(true);
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                Image = Approvals;
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    Visible = ApprovalActionsEnabled;
                    ToolTip = 'Approve the expense report that is pending your approval. Only the assigned approver can approve it.';

                    trigger OnAction()
                    begin
                        ProcessApprovalAction(RefActionType::Approve);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    Visible = ApprovalActionsEnabled;
                    ToolTip = 'Reject the expense report that is pending your approval. Only the assigned approver can reject it.';

                    trigger OnAction()
                    begin
                        ProcessApprovalAction(RefActionType::Reject);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';

                action(Submit)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Submit';
                    Image = ReleaseDoc;
                    Enabled = SubmitEnabled;
                    Visible = ApprovalWorkflowEnabled;
                    ShortCutKey = 'F9';
                    ToolTip = 'Submit all open expense report.';

                    trigger OnAction()
                    begin
                        SubmitExpenseReport();
                    end;
                }
                action(ReopenSubmitted)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Reopen Submitted';
                    Image = ReOpen;
                    Enabled = ReopenSubmittedEnabled;
                    Visible = ApprovalWorkflowEnabled;
                    ToolTip = 'Reopen all submitted or rejected expense report.';

                    trigger OnAction()
                    begin
                        ReopenSubmittedExpenseReport();
                    end;
                }
                action("Assign Interim Approver")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assign Interim Approver';
                    Image = UserSetup;
                    ToolTip = 'Assign an optional interim approver who approves before the final approver.';
                    Visible = AgentEnabled;
                    Enabled = Rec.Status = Rec.Status::"Pending Approval";

                    trigger OnAction()
                    begin
                        AssignInterimApproverExpenseReport();
                    end;
                }
            }
        }
        area(Navigation)
        {
            group("Expense")
            {
                Caption = 'Expense';
                action("Comments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Expense Report Comment Sheet";
                    RunPageLink = "Document Type" = const("Expense Report"), "No." = field("No."), "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                    Visible = Rec."No." <> '';
                }
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
#if not CLEAN30
                action(VATSpecification)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Specification';
                    Image = VATStatement;
                    RunObject = Page "Expense Report Line VAT Spec.";
                    RunPageLink = "Document No." = field("No."), "Document Line No." = const(0);
                    ToolTip = 'View the VAT details for the record.';
                    Visible = false;
                    ObsoleteReason = 'Replaced by Expense Report Statistics';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
#endif
                action("Spend Request")
                {
                    ApplicationArea = Basic, Suite;
                    Image = ProjectExpense;
                    Caption = 'Travel Request';
                    ToolTip = 'View the details of the travel request associated with this expense report.';
                    RunObject = Page "Travel Request Card";
                    RunPageLink = "No." = field("Spend Request No.");
                    Visible = Rec."Spend Request No." <> '';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    RunObject = Page "Expense Report Stats";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View statistical information, such as VAT amounts, for the expense report.';
                    Visible = Rec."No." <> '';
                }
            }
        }
        area(Reporting)
        {
            group(Report)
            {
                Caption = 'Report';
                Image = Print;

                action("Expense Report Details")
                {
                    Caption = 'Expense Report Details';
                    ApplicationArea = Basic, Suite;
                    Image = Report;
                    ToolTip = 'Run the detailed expense report for this expense report.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        ExpenseReportHeader := Rec;
                        ExpenseReportHeader.SetRecFilter();
                        Report.RunModal(Report::"Expense Report Details", true, false, ExpenseReportHeader);
                    end;
                }
                action("Expense Report Summary Page")
                {
                    Caption = 'Expense Report Summary Page';
                    ApplicationArea = Basic, Suite;
                    Image = Report;
                    ToolTip = 'Run the summary page report for this expense report.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        ExpenseReportHeader := Rec;
                        ExpenseReportHeader.SetRecFilter();
                        Report.RunModal(Report::"Expense Report Summary Page", true, false, ExpenseReportHeader);
                    end;
                }
                action("Expense Report Cover Page")
                {
                    Caption = 'Expense Report Cover Page';
                    ApplicationArea = Basic, Suite;
                    Image = Report;
                    ToolTip = 'Run the cover page report for this expense report.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        ExpenseReportHeader := Rec;
                        ExpenseReportHeader.SetRecFilter();
                        Report.RunModal(Report::"Expense Report Cover Page", true, false, ExpenseReportHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Home';

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
                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PostAndNew_Promoted; PostAndNew)
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                }
                actionref(GetExpenseLine_Promoted; GetExpenseLine)
                {
                }
            }
            group(Category_Approval)
            {
                Caption = 'Approval';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
            }
            group("Category_Request Approval")
            {
                Caption = 'Request Approval';

                actionref(Submit_Promoted; Submit)
                {
                }
                actionref(ReopenSubmitted_Promoted; ReopenSubmitted)
                {
                }
                actionref(AssignInterimApprover_Promoted; "Assign Interim Approver")
                {
                }
            }
            group(Category_Expense)
            {
                Caption = 'Expense';

                actionref(comments_Promoted; "Comments")
                {
                }
                actionref(dimension_Promoted; Dimensions)
                {
                }
#if not CLEAN30
                actionref(VATSpecification_Promoted; VATSpecification)
                {
                    ObsoleteReason = 'Replaced by Expense Report Statistics';
                    ObsoleteState = Pending;
                    ObsoleteTag = '30.0';
                }
#endif
                actionref("Spend Request_Promoted"; "Spend Request")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ExpenseUser: Record "Expense User";
        UserSetup: Record "User Setup";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        if ExpenseAgentSetup."Enable Approval Workflow" then begin
            ExpenseReportApprovalMgmt.GetCurrentUserSetupForApproval(UserSetup);
            if not UserSetup."Unlimited Expense Approval" then begin
                CheckSetDefaultOwnerFilter();
                ExpenseUserNo := ExpenseReportApprovalMgmt.GetExpenseUserNo();
                ExpenseUser.Get(ExpenseUserNo);
            end;
        end;

        SetDocNoVisible();
        UpdateControls();
        SetControlVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if ExpenseUserNo <> '' then begin
            Rec.Validate("Expense User No.", ExpenseUserNo);
            Rec.UpdateApproverID();
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
        SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        SetControlVisibility();
        ApproverComment := Rec.GetApproverComment();
        SubmitterComment := Rec.GetSubmitterComment();
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        RefActionType: Enum "Expense Approval Action";
        OpenPostedExpenseReportQst: Label 'The Expense Report is posted as number %1 and moved to the Posted Expense Report window.\\Do you want to open the posted expense report?', Comment = '%1 = posted document number';
        ShowAttestationFastTab: Boolean;
        ApprovalWorkflowEnabled: Boolean;
        DocNoVisible: Boolean;
        ExpenseUserNo: Code[20];
        ApproverComment: Text;
        SubmitterComment: Text;
        ApprovalActionsEnabled: Boolean;
        AgentEnabled: Boolean;

    protected var
        SubmitEnabled: Boolean;
        ReopenSubmittedEnabled: Boolean;
        ReopenApprovedEnabled: Boolean;
        ApproveEnabled: Boolean;

    local procedure UpdateControls()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        SubmitEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::Submit);
        ReopenSubmittedEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::"Reopen Submitted");
        ApproveEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::Approve);
        ReopenApprovedEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::"Reopen Approved");

        ExpenseAgentSetup.GetRecordOnce();
        AgentEnabled := ExpenseAgentSetup."Enable Agent";
        ApprovalActionsEnabled := ExpenseAgentSetup."Enable Agent" and ApproveEnabled and (Rec."Approver Expense User ID" = UserId());
    end;

    local procedure CheckSetDefaultOwnerFilter()
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        Rec.FilterGroup(2);
        if (Rec.GetFilter("Created By") = '') and (Rec.GetFilter("Approver Expense User ID") = '') then
            ExpenseReportApprovalMgmt.FilterExpenseReports(Rec, Rec.FieldNo("Created By"));

        Rec.FilterGroup(0);
    end;

    internal procedure Process(ActionType: Enum "Expense Approval Action")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
        ExpenseReportApprovalAction: Enum "Expense Approval Action";
    begin
        ExpenseReportLine.SetRange("Document No.", Rec."No.");
        if ExpenseReportLine.IsEmpty() then
            ExpenseReportApprovalMgt.NoExpenseLinesToProcess(ExpenseReportApprovalAction);

        ExpenseReportApprovalMgt.ProcessAction(Rec, ActionType);

        CurrPage.Update(true);
    end;

    local procedure SubmitExpenseReport()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if ExpenseReportApprovalMgt.ConfirmAction(RefActionType::Submit) then
            Process(RefActionType::Submit);
    end;

    local procedure ReopenSubmittedExpenseReport()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if ExpenseReportApprovalMgt.ConfirmAction(RefActionType::"Reopen Submitted") then
            Process(RefActionType::"Reopen Submitted");
    end;

    local procedure AssignInterimApproverExpenseReport()
    var
        ExpenseUserInterimApprover: Record "Expense User";
        ExpenseUsers: Page "Expense Users";
    begin
        ExpenseUserInterimApprover.SetRange("Can Approve", true);
        ExpenseUserInterimApprover.SetFilter("No.", '<>%1', Rec."Expense User No.");

        ExpenseUsers.LookupMode(true);
        ExpenseUsers.SetTableView(ExpenseUserInterimApprover);
        if ExpenseUsers.RunModal() <> Action::LookupOK then
            exit;

        ExpenseUsers.GetRecord(ExpenseUserInterimApprover);
        Rec.AssignInterimApprover(ExpenseUserInterimApprover."No.");
        CurrPage.Update(false);
    end;

    local procedure ProcessApprovalAction(ActionType: Enum "Expense Approval Action")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if not ExpenseReportApprovalMgt.ConfirmAction(ActionType) then
            exit;

        ExpenseReportLine.SetRange("Document No.", Rec."No.");
        if ExpenseReportLine.IsEmpty() then
            ExpenseReportApprovalMgt.NoExpenseLinesToProcess(ActionType);

        case ActionType of
            ActionType::Approve:
                Rec.PerformManualApproved(Rec."Approver Expense User No.");
            ActionType::Reject:
                Rec.PerformManualRejected(Rec."Approver Expense User No.", '');
        end;
        CurrPage.Update(false);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit "Expense Doc No Visibility";
    begin
        DocNoVisible := DocumentNoVisibility.ExpenseReportDocumentNoIsVisible(Rec."No.");
    end;

    local procedure SetControlVisibility()
    begin
        ExpenseAgentSetup.GetRecordOnce();
        ApprovalWorkflowEnabled := ExpenseAgentSetup."Enable Approval Workflow";
        ShowAttestationFastTab := ExpenseAgentSetup."Enable Anti-Corp. Statement";
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure PostDocument(Navigate: Enum "Navigate After Posting")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        InstructionMgt: Codeunit "Instruction Mgt.";
        DocumentIsPosted: Boolean;
    begin
        ExpenseReportPost.PostExpenseReport(Rec);
        DocumentIsPosted := (not ExpenseReportHeader.Get(Rec."No."));

        case Navigate of
            Enum::"Navigate After Posting"::"Posted Document":
                begin
                    if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode()) then
                        ShowPostedConfirmationMessage();

                    if DocumentIsPosted then
                        CurrPage.Close();
                end;
            Enum::"Navigate After Posting"::"New Document":
                if DocumentIsPosted then begin
                    Clear(ExpenseReportHeader);
                    ExpenseReportHeader.Init();
                    ExpenseReportHeader.Insert(true);
                    PAGE.Run(PAGE::"Expense Report", ExpenseReportHeader);
                end;
        end;
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not ExpenseReportHeader.Get(Rec."No.") then begin
            PostedExpenseReportHeader.SetRange("No.", Rec."Last Posting No.");
            if PostedExpenseReportHeader.FindFirst() then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedExpenseReportQst, PostedExpenseReportHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode())
                then
                    InstructionMgt.ShowPostedDocument(PostedExpenseReportHeader, Page::"Posted Expense Report");
        end;
    end;
}