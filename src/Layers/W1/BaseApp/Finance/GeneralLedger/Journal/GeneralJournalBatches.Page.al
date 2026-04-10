// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Reporting;
using System.Environment;

/// <summary>
/// List page for managing general journal batches within journal templates providing batch configuration and navigation.
/// Displays journal batches with their settings including balancing account configuration, number series, and posting parameters.
/// </summary>
/// <remarks>
/// Journal batch management interface for configuring and navigating journal batches within templates.
/// Key features: Batch configuration display, balancing account setup, number series assignment, posting parameter management.
/// Integration: Direct navigation to journal lines, batch-level posting operations, template context filtering.
/// Actions: Open journal lines, post batches, test reports, navigate to ledger entries and registers.
/// </remarks>
page 251 "General Journal Batches"
{
    Caption = 'General Journal Batches';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Gen. Journal Batch";
    AnalysisModeEnabled = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Copy VAT Setup to Jnl. Lines"; Rec."Copy VAT Setup to Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow VAT Difference"; Rec."Allow VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Allow Payment Export"; Rec."Allow Payment Export")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = IsPaymentTemplate;
                }
                field("Suggest Balancing Amount"; Rec."Suggest Balancing Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Statement Import Format"; Rec."Bank Statement Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Copy to Posted Jnl. Lines"; Rec."Copy to Posted Jnl. Lines")
                {
                    ApplicationArea = Suite;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of lines in this journal batch.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
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
        area(processing)
        {
            action(EditJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    GenJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintGenJnlBatch(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post selected journal batches.';

                    trigger OnAction()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlBPost: Codeunit "Gen. Jnl.-B.Post";
                    begin
                        PrepareForPosting(Rec, GenJournalBatch);
                        GenJnlBPost.Run(GenJournalBatch);
                        if GenJnlBPost.JournalWithPostingErrors() then
                            SetSelectionFilterOnRecord(GenJournalBatch, Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post and print selected journal batches.';
                    trigger OnAction()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlBPostPrint: Codeunit "Gen. Jnl.-B.Post+Print";
                    begin
                        PrepareForPosting(Rec, GenJournalBatch);
                        GenJnlBPostPrint.Run(GenJournalBatch);
                        if GenJnlBPostPrint.JournalWithPostingErrors() then
                            SetSelectionFilterOnRecord(GenJournalBatch, Rec);
                    end;
                }
                action(MarkedOnOff)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Failed to Post On/Off';
                    Image = Change;
                    ToolTip = 'Toggle between showing all journal batches and only those that failed to post.';

                    trigger OnAction()
                    begin
                        Rec.MarkedOnly(not Rec.MarkedOnly);
                        CurrPage.Update(false);
                    end;
                }
            }
            group("Periodic Activities")
            {
                Caption = 'Periodic Activities';
                action("Recurring General Journal")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring General Journal';
                    Image = Journal;
                    RunObject = Page "Recurring General Journal";
                    ToolTip = 'Define how to post transactions that recur with few or no changes to general ledger, bank, customer, vendor, and fixed assets accounts.';
                }
                action("G/L Register")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Register';
                    Image = GLRegisters;
                    RunObject = Page "G/L Registers";
                    ToolTip = 'View posted G/L entries.';
                }
            }
        }
        area(reporting)
        {
            action("Detail Trial Balance")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Detail Trial Balance';
                Image = "Report";
                RunObject = Report "Detail Trial Balance";
                ToolTip = 'View detail general ledger account balances and activities.';
            }
#if not CLEAN28
            action("Trial Balance")
            {
                ApplicationArea = Suite;
                Caption = 'Trial Balance (Obsolete)';
                Image = "Report";
                RunObject = Report "Trial Balance";
                ToolTip = 'View general ledger account balances and activities.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                ObsoleteTag = '28.0';
            }
#endif
            action("Trial Balance by Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Trial Balance by Period';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Trial Balance by Period";
                ToolTip = 'View general ledger account balances and activities within a selected period.';
            }
            action(Action10)
            {
                ApplicationArea = Suite;
                Caption = 'G/L Register';
                Image = GLRegisters;
                RunObject = Report "G/L Register";
                ToolTip = 'View posted G/L entries.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(EditJournal_Promoted; EditJournal)
                {
                }
            }
            group(Category_Posting)
            {
                Caption = 'Posting';
                ShowAs = SplitButton;

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
            }
            group(Category_General_Journal)
            {
                Caption = 'General Journal';

                actionref("Recurring General Journal_Promoted"; "Recurring General Journal")
                {
                }
                actionref("G/L Register_Promoted"; "G/L Register")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Detail Trial Balance_Promoted"; "Detail Trial Balance")
                {
                }
#if not CLEAN28
                actionref("Trial Balance_Promoted"; "Trial Balance")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
                    ObsoleteTag = '28.0';
                }
#endif
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if GenJnlTemplateName <> '' then
            Rec."Journal Template Name" := GenJnlTemplateName;
        Rec.SetupNewBatch();
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4]
        then
            exit;
        GenJnlManagement.OpenJnlBatch(Rec);
        ShowAllowPaymentExportForPaymentTemplate();
        // Doing this because if user is using web client then filters on REC are being removed
        // Since filter is removed we need to persist value for template
        // name and use it 'OnNewRecord'
        GenJnlTemplateName := Rec."Journal Template Name";
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        GenJnlManagement: Codeunit GenJnlManagement;
        IsPaymentTemplate: Boolean;
        GenJnlTemplateName: Code[10];

    local procedure DataCaption(): Text[250]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then begin
                GenJnlTemplate.SetFilter(Name, Rec.GetFilter("Journal Template Name"));
                if GenJnlTemplate.FindSet() then
                    if GenJnlTemplate.Next() = 0 then
                        exit(GenJnlTemplate.Name + ' ' + GenJnlTemplate.Description);
            end;
    end;

    local procedure PrepareForPosting(var FromGenJournalBatch: Record "Gen. Journal Batch"; var GenJournalBatchToBePosted: Record "Gen. Journal Batch")
    begin
        GenJournalBatchToBePosted := FromGenJournalBatch;
        GenJournalBatchToBePosted.CopyFilters(FromGenJournalBatch);
        CurrPage.SetSelectionFilter(GenJournalBatchToBePosted);
    end;

    local procedure SetSelectionFilterOnRecord(var PostedGenJournalBatch: Record "Gen. Journal Batch"; var ToGenJournalBatch: Record "Gen. Journal Batch")
    begin
        if PostedGenJournalBatch.FindSet() then
            repeat
                if ToGenJournalBatch.Get(PostedGenJournalBatch."Journal Template Name", PostedGenJournalBatch.Name) then
                    ToGenJournalBatch.Mark(true);
            until PostedGenJournalBatch.Next() = 0;
        ToGenJournalBatch.MarkedOnly(true);
    end;

    local procedure ShowAllowPaymentExportForPaymentTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        if GenJournalTemplate.Get(Rec."Journal Template Name") then
            IsPaymentTemplate := GenJournalTemplate.Type = GenJournalTemplate.Type::Payments;
    end;
}

