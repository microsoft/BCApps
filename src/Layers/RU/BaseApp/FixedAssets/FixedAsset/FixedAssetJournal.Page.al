// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.Foundation.Reporting;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;

page 5629 "Fixed Asset Journal"
{
    ApplicationArea = FixedAssets;
    AutoSplitKey = true;
    Caption = 'Fixed Asset Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "FA Journal Line";
    UsageCategory = Tasks;
    AboutTitle = 'About Fixed Asset Journal';
    AboutText = 'With the **Fixed Asset Journal**, All entries are posted to the fixed asset ledger entry only such as acquisition, depreciation, disposal, write-down, appreciation and maintenance.';

    layout
    {
        area(content)
        {
            group(Control120)
            {
                ShowCaption = false;
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        FAJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                        SetControlAppearanceFromBatch();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        FAJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali();
                    end;
                }
                field(FAJnlBatchApprovalStatus; FAJnlBatchApprovalStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approval Status';
                    Editable = false;
                    Visible = EnabledFAJnlBatchWorkflowsExist;
                    ToolTip = 'Specifies the approval status for fixed asset journal batch.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ShowMandatory = true;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';

                    trigger OnValidate()
                    begin
                        FAJnlManagement.GetFA(Rec."FA No.", FADescription);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Manage FA posting type';
                    AboutText = 'Specify the FA posting type for the fixed asset transactions such as acquisition, depreciation, disposal, write-down, appreciation and maintenance.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset. ';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Salvage Value"; Rec."Salvage Value")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("No. of Depreciation Days"; Rec."No. of Depreciation Days")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depr. until FA Posting Date"; Rec."Depr. until FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depr. Acquisition Cost"; Rec."Depr. Acquisition Cost")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Maintenance Code"; Rec."Maintenance Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Insurance No."; Rec."Insurance No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Budgeted FA No."; Rec."Budgeted FA No.")
                {
                    ApplicationArea = Suite;
                }
                field("Duplicate in Depreciation Book"; Rec."Duplicate in Depreciation Book")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Use Duplication List"; Rec."Use Duplication List")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA Reclassification Entry"; Rec."FA Reclassification Entry")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Error Entry No."; Rec."FA Error Entry No.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Actual Quantity"; Rec."Actual Quantity")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the actual quantity associated with the fixed asset journal line.';
                }
                field("Calc. Quantity"; Rec."Calc. Quantity")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the calculated quantity associated with the fixed asset journal line.';
                }
                field("Actual Amount"; Rec."Actual Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the actual amount of the fixed asset journal line.';
                }
                field("Calc. Amount"; Rec."Calc. Amount")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the calculated amount of the fixed asset journal line.';
                }
                field("Depr. Bonus"; Rec."Depr. Bonus")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the fixed asset journal line contains a depreciation bonus.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    ToolTip = 'Specifies the dimension value code linked to the journal line.';
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                fixed(Control1900116601)
                {
                    ShowCaption = false;
                    group("FA Description")
                    {
                        Caption = 'FA Description';
                        field(FADescription; FADescription)
                        {
                            ApplicationArea = FixedAssets;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies a description of the fixed asset.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part(WorkflowStatusBatch; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Batch Workflows';
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatusOnBatch;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
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
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("Fixed &Asset")
            {
                Caption = 'Fixed &Asset';
                Image = FixedAssets;
                action("&Card")
                {
                    ApplicationArea = FixedAssets;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Fixed Asset Card";
                    RunPageLink = "No." = field("FA No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the fixed asset.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Codeunit "FA Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowJournalApprovalEntries(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate &FA")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Calculate &FA';
                    Ellipsis = true;
                    Image = Calculate;
                    RunObject = Report "Calc. FA Inventory";
                    ToolTip = 'Create a list of fixed assets that are to be inventoried.';
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("&Test Report")
                {
                    ApplicationArea = FixedAssets;
                    Caption = '&Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the resulting fixed asset entries to see the consequences before you perform the actual posting.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintFAJnlLine(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"FA. Jnl.-Post", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        FAJnlPost: Codeunit "FA. Jnl.-Post";
                    begin
                        FAJnlPost.Preview(Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"FA. Jnl.-Post+Print", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = FixedAssets;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    DocPrint.PrintFAJnlDoc(Rec);
                end;
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                group(SendApprovalRequest)
                {
                    Caption = 'Send Approval Request';
                    Image = SendApprovalRequest;
                    action(SendApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = not OpenApprovalEntriesOnJnlBatchExist and CanRequestFlowApprovalForBatch and EnabledFAJnlBatchWorkflowsExist;
                        Image = SendApprovalRequest;
                        ToolTip = 'Send all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TrySendJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
                        end;
                    }
                }
                group(CancelApprovalRequest)
                {
                    Caption = 'Cancel Approval Request';
                    Image = Cancel;
                    action(CancelApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = CanCancelApprovalForJnlBatch or CanCancelFlowApprovalForBatch;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel sending all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TryCancelJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
                        end;
                    }
                }
                group(Flow)
                {
                    Caption = 'Power Automate';
                    Image = Flow;

                    customaction(CreateApprovalFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_faJournal';
                    }
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveFAJournalRequest(Rec);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectFAJournalRequest(Rec);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateFAJournalRequest(Rec);
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser or ApprovalEntriesExistSentByCurrentUser;

                    trigger OnAction()
                    var
                        FAJournalBatch: Record "FA Journal Batch";
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if OpenApprovalEntriesOnJnlBatchExist then
                            if FAJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                                ApprovalsMgmt.GetApprovalComment(FAJournalBatch);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), Rec."Journal Batch Name", Rec."Journal Template Name");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                actionref("Calculate &FA_Promoted"; "Calculate &FA")
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group("Category_Request Approval")
            {
                Caption = 'Request Approval';

                group("Category_Send Approval Request")
                {
                    Caption = 'Send Approval Request';

                    actionref(SendApprovalRequestJournalBatch_Promoted; SendApprovalRequestJournalBatch)
                    {
                    }
                }
                group("Category_Cancel Approval Request")
                {
                    Caption = 'Cancel Approval Request';

                    actionref(CancelApprovalRequestJournalBatch_Promoted; CancelApprovalRequestJournalBatch)
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(EditInExcel_Promoted; EditInExcel)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        FAJnlManagement.GetFA(Rec."FA No.", FADescription);
        if FAJournalBatch.Get(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then begin
            FAJournalBatch.SetApprovalStateForBatch(FAJournalBatch, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnJnlBatchExist, CanCancelApprovalForJnlBatch, CanRequestFlowApprovalForBatch, CanCancelFlowApprovalForBatch, ApprovalEntriesExistSentByCurrentUser, EnabledFAJnlBatchWorkflowsExist);
            ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(FAJournalBatch.RecordId());
        end;

        ApprovalMgmt.GetFAJnlBatchApprovalStatus(Rec, FAJnlBatchApprovalStatus, EnabledFAJnlBatchWorkflowsExist);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ApprovalMgmt.CleanFAJournalApprovalStatus(Rec, FAJnlBatchApprovalStatus);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
        EnvironmentInfo: Codeunit "Environment Information";
        JnlSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        IsSaaS := EnvironmentInfo.IsSaaS();
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        SetDimensionsVisibility();

        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            FAJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
            SetControlAppearanceFromBatch();
            exit;
        end;
        FAJnlManagement.TemplateSelection(PAGE::"Fixed Asset Journal", 0, false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        FAJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);

        SetControlAppearanceFromBatch();
    end;

    var
        FAJnlManagement: Codeunit FAJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        DocPrint: Codeunit "Document-Print";
        ClientTypeManagement: Codeunit "Client Type Management";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
        IsSaaSExcelAddinEnabled: Boolean;

    protected var
        CurrentJnlBatchName: Code[10];
        FADescription: Text[100];
        FAJnlBatchApprovalStatus: Text[20];
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        ApprovalEntriesExistSentByCurrentUser: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesOnJnlBatchExist: Boolean;
        EnabledFAJnlBatchWorkflowsExist: Boolean;
        ShowWorkflowStatusOnBatch: Boolean;
        CanCancelApprovalForJnlBatch: Boolean;
        CanRequestFlowApprovalForBatch: Boolean;
        CanCancelFlowApprovalForBatch: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        IsSaaS: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        FAJnlManagement.SetName(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();
        CurrPage.Update(false);
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    local procedure SetControlAppearanceFromBatch()
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        if not FAJournalBatch.Get(Rec.GetRangeMax("Journal Batch Name"), CurrentJnlBatchName) then
            exit;

        ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.Page.SetFilterOnWorkflowRecord(FAJournalBatch.RecordId());
        FAJournalBatch.SetApprovalStateForBatch(FAJournalBatch, Rec, OpenApprovalEntriesExistForCurrUser, OpenApprovalEntriesOnJnlBatchExist, CanCancelApprovalForJnlBatch, CanRequestFlowApprovalForBatch, CanCancelFlowApprovalForBatch, ApprovalEntriesExistSentByCurrentUser, EnabledFAJnlBatchWorkflowsExist);
    end;

#pragma warning disable AL0523
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FAJournalLine: Record "FA Journal Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;
#pragma warning restore AL0523

}

