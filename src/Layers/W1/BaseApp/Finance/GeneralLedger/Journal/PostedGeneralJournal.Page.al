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

/// <summary>
/// Provides read-only access to posted general journal lines for historical analysis and audit trail purposes.
/// Displays completed journal transactions with full posting details including dimensions, amounts, and posting references.
/// </summary>
/// <remarks>
/// Historical journal view for posted transaction analysis and audit purposes. Provides comprehensive access to
/// posted journal line details including G/L register references, dimension information, and transaction history.
/// Key features: Posted transaction browsing, dimension analysis, audit trail access, navigation to related entries.
/// Integration: Links to G/L entries, dimension corrections, and navigation functions for complete transaction traceability.
/// </remarks>
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
                }
                field("G/L Register No."; Rec."G/L Register No.")
                {
                    Style = Strong;
                    StyleExpr = Bold;
                    ApplicationArea = Basic, Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in local currency (including VAT) that the journal line consists of.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Amount"; Rec."VAT Amount")
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
                field("Bal. Gen. Posting Type"; Rec."Bal. Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Gen. Bus. Posting Group"; Rec."Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Gen. Prod. Posting Group"; Rec."Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = Suite;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Journal Batch Name"; Rec."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
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

