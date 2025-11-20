// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.Dimension.Correction;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Navigate;
using System.Automation;

page 182 "Posted General Journal"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted General Journal';
    PageType = Worksheet;
    SourceTable = "Posted Gen. Journal Line";
    UsageCategory = History;
    DeleteAllowed = false;
    SourceTableView = sorting("G/L Register No.") order(descending);

    layout
    {
        area(content)
        {
            group(CurrentFilters)
            {
                ShowCaption = false;

                field(CurrentJnlTemplateName; CurrentJnlTemplateName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Template Name';
                    ToolTip = 'Specifies the name of the journal template.';
                    Editable = false;
                }
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    ToolTip = 'Specifies the name of the journal batch.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        SetTemplateBatchName();
                    end;
                }
            }

            repeater(Control1)
            {
                ShowCaption = false;
                Editable = false;
                field("Document No."; Rec."Document No.")
                {
                    Style = Strong;
                    StyleExpr = Bold;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    Style = Strong;
                    StyleExpr = Bold;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger register.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the entry on the journal line is.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the entry on the journal line will be posted to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                    ToolTip = 'Specifies the code of the currency for the amounts on the journal line.';
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type that will be used when you post the entry on this journal line.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business posting group code that will be used when you post the entry on the journal line.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of items to be included on the journal line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in local currency (including VAT) that the journal line consists of.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of, if it is a debit amount.';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount (including VAT) that the journal line consists of, if it is a credit amount.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of VAT included in the total amount.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the balancing account type that should be used in this journal line.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry for the journal line will posted (for example, a cash account for cash purchases).';
                }
                field("Bal. Gen. Posting Type"; Rec."Bal. Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general posting type associated with the balancing account that will be used when you post the entry on the journal line.';
                }
                field("Bal. Gen. Bus. Posting Group"; Rec."Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general business posting group code associated with the balancing account that will be used when you post the entry.';
                }
                field("Bal. Gen. Prod. Posting Group"; Rec."Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general product posting group code associated with the balancing account that will be used when you post the entry.';
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the deferral template that governs how expenses or revenue are deferred to the different accounting periods when the expenses or revenue were incurred.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal template.';
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1900919607; "Dimension Set Entries FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
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
        area(Processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";

                action(CopySelected)
                {
                    Caption = 'Copy Selected Lines to Journal';
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = CopyToGL;
                    ToolTip = 'Copies selected posted journal lines to general journal.';

                    trigger OnAction()
                    var
                        PostedGenJournalLine: Record "Posted Gen. Journal Line";
                        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(PostedGenJournalLine);
                        CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);
                    end;
                }
                action(CopyRegister)
                {
                    Caption = 'Copy G/L Register to Journal';
                    ApplicationArea = Basic, Suite;
                    Ellipsis = true;
                    Image = CopyToGL;
                    ToolTip = 'Copies selected g/l register posted journal lines to general journal.';

                    trigger OnAction()
                    var
                        PostedGenJournalLine: Record "Posted Gen. Journal Line";
                        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(PostedGenJournalLine);
                        CopyGenJournalMgt.CopyGLRegister(PostedGenJournalLine);
                    end;
                }
                action(FindEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected line.';

                    trigger OnAction()
                    var
                        Navigate: Page Navigate;
                    begin
                        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                        Navigate.Run();
                    end;
                }

                action(ChangeDimensions)
                {
                    ApplicationArea = All;
                    Image = ChangeDimensions;
                    Caption = 'Correct Dimensions';
                    ToolTip = 'Correct dimensions for the related general ledger entries.';

                    trigger OnAction()
                    var
                        GLEntry: Record "G/L Entry";
                        DimensionCorrection: Record "Dimension Correction";
                        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                    begin
                        Rec.TestField("Document No.");
                        Rec.TestField("Posting Date");
                        GLEntry.SetRange("Document No.", Rec."Document No.");
                        GLEntry.SetRange("Posting Date", Rec."Posting Date");
                        DimensionCorrectionMgt.CreateCorrectionFromFilter(GLEntry, DimensionCorrection);
                        Page.Run(PAGE::"Dimension Correction Draft", DimensionCorrection);
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are approved and posted through General Journal.';

                    trigger OnAction()
                    var
                        GLRegister: Record "G/L Register";
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if GLRegister.Get(Rec."G/L Register No.") then
                            ApprovalsMgmt.ShowPostedApprovalEntries(GLRegister.RecordId);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopySelected_Promoted; CopySelected)
                {
                }
                actionref(CopyRegister_Promoted; CopyRegister)
                {
                }
                actionref(FindEntries_Promoted; FindEntries)
                {
                }
            }
        }
    }

    var
        Bold: Boolean;
        CurrentJnlBatchName: Code[10];
        CurrentJnlTemplateName: Code[10];
        GLRegisterNo: Integer;

    trigger OnAfterGetRecord()
    begin
        if GLRegisterNo <> Rec."G/L Register No." then begin
            Bold := true;
            GLRegisterNo := Rec."G/L Register No.";
        end else
            Bold := false;
    end;

    local procedure SetTemplateBatchName()
    begin
        if not LookuptemplateBatchName() then
            exit;

        Rec.SetRange("Journal Template Name", CurrentJnlTemplateName);
        Rec.SetRange("Journal Batch Name", CurrentJnlBatchName);
        if Rec.FindSet() then;
        CurrPage.Update(false);
    end;

    local procedure LookuptemplateBatchName(): Boolean
    var
        PostedGenJournalBatch: Record "Posted Gen. Journal Batch";
    begin
        if Page.RunModal(0, PostedGenJournalBatch) = Action::LookupOK then begin
            CurrentJnlTemplateName := PostedGenJournalBatch."Journal Template Name";
            CurrentJnlBatchName := PostedGenJournalBatch.Name;
            exit(true);
        end;

        exit(false);
    end;
}

