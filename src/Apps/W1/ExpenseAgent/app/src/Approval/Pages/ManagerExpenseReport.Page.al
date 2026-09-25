// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Enums;
using Microsoft.Utilities;
using System.Security.User;

page 6980 "Manager Expense Report"
{
    Caption = 'Manager Expense Report';
    PageType = Card;
    SourceTable = "Expense Report Header";
    DataCaptionExpression = Rec."No.";
    RefreshOnActivate = true;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the expense report number.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit()
                    end;
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense user number for the report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                    ToolTip = 'Specifies shortcut dimension 1 for categorizing the report.';
                    Importance = Additional;
                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies shortcut dimension 2 for categorizing the report.';
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

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the approval status of the expense report.';
                    Importance = Additional;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group used for tax posting.';
                    Importance = Additional;
                    Visible = false;
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
                Visible = ShowAttestationFastTab;
                field("Anti-Corruption Attestation"; Rec."Anti-corruption attestation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the anti-corruption attestation has been confirmed for this report.';
                }
                field("Anti-Corruption Description"; Rec."Anti-corruption description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies details about the anti-corruption attestation for this report.';
                }
            }
            group(Administration)
            {
                field(Corrected; Rec.Corrected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this report corrects a previous report.';
                    Editable = false;
                }
                field("Corrected Document No."; Rec."Corrected Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the report that this report corrects.';
                    Editable = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language code used for this report.';
                    Importance = Additional;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code that explains why this report was created or modified.';
                    Importance = Additional;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the responsibility center used to assign costs for this report.';
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
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = ReleaseDoc;
                    Enabled = ApproveEnabled;
                    Visible = ManagerExpense;
                    ToolTip = 'Approves the submitted expense report.';

                    trigger OnAction()
                    begin
                        ApproveExpenseReport();
                    end;
                }
                action(ReopenApproved)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen Approved';
                    Image = ReOpen;
                    Enabled = ReopenApprovedEnabled;
                    Visible = ManagerExpense;
                    ToolTip = 'Reopens approved or rejected expense reports so they can be processed again.';

                    trigger OnAction()
                    begin
                        ReopenApprovedExpenseReport();
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    Enabled = ApproveEnabled;
                    Visible = ManagerExpense;
                    ToolTip = 'Rejects the submitted expense report.';

                    trigger OnAction()
                    begin
                        RejectExpenseReport();
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
                    ToolTip = 'Posts this expense report and creates the related ledger entries.';

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
                    ToolTip = 'Posts this expense report and opens a new, blank report.';

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
                    ToolTip = 'Specifies the ledger entries that will be created when this report is posted.';

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
                    ToolTip = 'Adds expense lines to this report from available sources.';

                    trigger OnAction()
                    var
                        CreateExpenseReport: Codeunit "Create Expense Report";
                    begin
                        CreateExpenseReport.AddExpensesToReport(Rec);

                        CurrPage.Update(true);
                    end;
                }
            }
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
                    ToolTip = 'Releases this report so it continues to the next processing stage. Reopen a released report before changing it.';

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
                    ToolTip = 'Reopens a released report so you can make changes.';

                    trigger OnAction()
                    var
                        ReleaseExpenseReportDoc: Codeunit "Release Exp. Report Document";
                    begin
                        ReleaseExpenseReportDoc.PerformManualReopen(Rec);
                    end;
                }
            }
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
                    ToolTip = 'Specifies comments for this report and lets you add new comments.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'Specifies dimensions such as area, project, or department that you can assign to this report to distribute costs and analyze transactions.';
                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
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
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Home';

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
                actionref(GetExpenseLine_Promoted; GetExpenseLine)
                {
                }
            }
            group(Category_Approval)
            {
                Caption = 'Approve';

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

                actionref(ReopenApproved_Promoted; ReopenApproved)
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
            end else
                ManagerExpense := true;
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
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        RefActionType: Enum "Expense Approval Action";
        OpenPostedExpenseReportQst: Label 'The Expense Report is posted as number %1 and moved to the Posted Expense Report window.\\Do you want to open the posted expense report?', Comment = '%1 = posted document number';
        ShowAttestationFastTab: Boolean;
        DocNoVisible: Boolean;
        ExpenseUserNo: Code[20];

    protected var
        ReopenApprovedEnabled: Boolean;
        ApproveEnabled: Boolean;
        ManagerExpense: Boolean;

    local procedure UpdateControls()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        ApproveEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::Approve);
        ReopenApprovedEnabled := ExpenseReportApprovalMgt.CanPerformApprovalAction(Rec, RefActionType::"Reopen Approved");
    end;

    local procedure CheckSetDefaultOwnerFilter()
    var
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        Rec.FilterGroup(2);
        if (Rec.GetFilter("Created By") = '') and (Rec.GetFilter("Approver Expense User ID") = '') then
            ExpenseReportApprovalMgmt.FilterExpenseReports(Rec, Rec.FieldNo("Created By"));

        if (Rec.GetFilter("Created By") = '') and (Rec.GetFilter("Approver Expense User ID") <> '') then
            ManagerExpense := true and ExpenseAgentSetup."Enable Approval Workflow";

        if (Rec.GetFilter("Created By") <> '') and (Rec.GetFilter("Approver Expense User ID") = '') then
            ManagerExpense := false and ExpenseAgentSetup."Enable Approval Workflow";

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

    local procedure ApproveExpenseReport()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if ExpenseReportApprovalMgt.ConfirmAction(RefActionType::Approve) then
            Process(RefActionType::Approve);
    end;

    local procedure RejectExpenseReport()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if ExpenseReportApprovalMgt.ConfirmAction(RefActionType::Reject) then
            Process(RefActionType::Reject);
    end;

    local procedure ReopenApprovedExpenseReport()
    var
        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
    begin
        if ExpenseReportApprovalMgt.ConfirmAction(RefActionType::"Reopen Approved") then
            Process(RefActionType::"Reopen Approved");
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