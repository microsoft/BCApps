// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using System.Environment.Configuration;
using System.Utilities;

page 615 "IC Inbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Inbox Transactions';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    AboutTitle = 'About Intercompany Inbox Transactions';
    AboutText = 'Review, filter, and process incoming intercompany transactions from partner companies, choosing to accept, reject, or cancel each item and automatically create related documents or journal entries upon acceptance.';
    SourceTable = "IC Inbox Transaction";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control25)
            {
                ShowCaption = false;
                field(PartnerFilter; PartnerFilter)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Partner Filter';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. If the field is blank, the window will show the transactions for all of your intercompany partners. You can set a filter to determine the partner or partners whose transactions will be shown in the window.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PartnerList: Page "IC Partner List";
                    begin
                        PartnerList.LookupMode(true);
                        if not (PartnerList.RunModal() = ACTION::LookupOK) then
                            exit(false);
                        Text := PartnerList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        PartnerFilterOnAfterValidate();
                    end;
                }
                field(ShowLines; ShowLines)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Transaction Source';
                    OptionCaption = ' ,Returned by Partner,Created by Partner';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see only new transactions that your intercompany partner(s) have created, only transactions that you created and your intercompany partner(s) returned to you, or both.';

                    trigger OnValidate()
                    begin
                        Rec.SetRange("Transaction Source");
                        case ShowLines of
                            ShowLines::"Returned by Partner":
                                Rec.SetRange("Transaction Source", Rec."Transaction Source"::"Returned by Partner");
                            ShowLines::"Created by Partner":
                                Rec.SetRange("Transaction Source", Rec."Transaction Source"::"Created by Partner");
                        end;
                        ShowLinesOnAfterValidate();
                    end;
                }
                field(ShowAction; ShowAction)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Line Action';
                    OptionCaption = 'All,No Action,Accept,Return to IC Partner';
                    ToolTip = 'Specifies how you want to filter the lines shown in the window. You can choose to see all lines, or only lines with a specific option in the Line Action field.';

                    trigger OnValidate()
                    begin
                        Rec.SetRange("Line Action");
                        case ShowAction of
                            ShowAction::"No Action":
                                Rec.SetRange("Line Action", Rec."Line Action"::"No Action");
                            ShowAction::Accept:
                                Rec.SetRange("Line Action", Rec."Line Action"::Accept);
                            ShowAction::"Return to IC Partner":
                                Rec.SetRange("Line Action", Rec."Line Action"::"Return to IC Partner");
                            ShowAction::Cancel:
                                Rec.SetRange("Line Action", Rec."Line Action"::Cancel);
                        end;
                        ShowActionOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the transaction''s entry number.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
#if not CLEAN27
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
                    ObsoleteReason = 'Replaced with IC Source Type for consistent naming.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                field("IC Source Type"; Rec."IC Source Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Transaction Source"; Rec."Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Line Action"; Rec."Line Action")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies what action is taken for the line when you choose the Complete Line Actions action.';
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
        area(navigation)
        {
            group("&Inbox Transaction")
            {
                Caption = '&Inbox Transaction';
                Image = Import;
                action(GoToHandledInbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Handled Inbox';
                    Tooltip = 'Navigate to the intercompany handled inbox transactions.';
                    RunObject = page "Handled IC Inbox Transactions";
                    RunPageMode = View;
                    Image = SendTo;
                }
                action(GoToOutbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Outbox';
                    Tooltip = 'Navigate to the intercompany outbox transactions.';
                    RunObject = page "IC Outbox Transactions";
                    Image = ExportMessage;
                }
                action(GoToHandledOutbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Handled Outbox';
                    Tooltip = 'Navigate to the intercompany handled outbox transactions.';
                    RunObject = page "Handled IC Outbox Transactions";
                    RunPageMode = View;
                    Image = ExportMessage;
                }
                action(Details)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Details';
                    Image = View;
                    ToolTip = 'View transaction details.';

                    trigger OnAction()
                    begin
                        Rec.ShowDetails();
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "IC Comment Sheet";
                    RunPageLink = "Table Name" = const("IC Inbox Transaction"),
                                  "Transaction No." = field("Transaction No."),
                                  "IC Partner Code" = field("IC Partner Code"),
                                  "Transaction Source" = field("Transaction Source");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Complete Line Actions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Carry out Line Actions';
                    Ellipsis = true;
                    Image = CompleteLine;
                    ToolTip = 'Carry out the actions that are specified on the lines.';

                    trigger OnAction()
                    begin
                        RunInboxTransactions(Rec);
                    end;
                }
                action("Import Transaction File")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Import Transaction File';
                    Image = Import;
                    RunObject = Codeunit "IC Inbox Import";
                    RunPageOnRec = true;
                    ToolTip = 'Import a file to create the transaction with.';
                }
            }
            group(LineActions)
            {
                Caption = 'Actions';
                action("No Action")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'No Action';
                    Image = Cancel;
                    Scope = Repeater;
                    ToolTip = 'Sets the Line Action to No action so that the selected entries stay in the inbox.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ICInboxTransaction);
                        if ICInboxTransaction.FindSet() then
                            repeat
                                ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::"No Action";
                                ICInboxTransaction.Modify();
                            until ICInboxTransaction.Next() = 0;
                    end;
                }
                action(Accept)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Accept';
                    Image = Approve;
                    Scope = Repeater;
                    ToolTip = 'Will accept the selected entries and create corresponding documents or journal lines.';

                    trigger OnAction()
                    var
                        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                    begin
                        CurrPage.SetSelectionFilter(ICInboxTransaction);
                        if ICInboxTransaction.FindSet() then
                            repeat
                                Rec.TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
                                ICInboxTransaction.Validate("Line Action", ICInboxTransaction."Line Action"::Accept);
                                ICInboxTransaction.Modify();
                            until ICInboxTransaction.Next() = 0;

                        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                            RunInboxTransactions(ICInboxTransaction);
                    end;
                }
                action("Return to IC Partner")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Return to IC Partner';
                    Image = Return;
                    Scope = Repeater;
                    ToolTip = 'Will move the selected to the outbox so you can send them back to IC partner.';

                    trigger OnAction()
                    var
                        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                    begin
                        CurrPage.SetSelectionFilter(ICInboxTransaction);
                        if ICInboxTransaction.FindSet() then
                            repeat
                                Rec.TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
                                ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::"Return to IC Partner";
                                ICInboxTransaction.Modify();
                            until ICInboxTransaction.Next() = 0;

                        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                            RunInboxTransactions(ICInboxTransaction);
                    end;
                }
                action(Cancel)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Cancel';
                    Image = Cancel;
                    Scope = Repeater;
                    ToolTip = 'Will delete the selected entries from the outbox.';

                    trigger OnAction()
                    var
                        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                    begin
                        CurrPage.SetSelectionFilter(ICInboxTransaction);
                        if ICInboxTransaction.FindSet() then
                            repeat
                                ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::Cancel;
                                ICInboxTransaction.Modify();
                            until ICInboxTransaction.Next() = 0;

                        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                            RunInboxTransactions(ICInboxTransaction);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Details_Promoted; Details)
                {
                }
                actionref("Complete Line Actions_Promoted"; "Complete Line Actions")
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
            group(Category_Navigation)
            {
                Caption = 'Navigate';
                actionref(GoToHandledInbox_Promoted; GoToHandledInbox)
                {
                }
                actionref(GoToOutbox_Promoted; GoToOutbox)
                {
                }
                actionref(GoToHandledOutbox_Promoted; GoToHandledOutbox)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Functions', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category5)
            {
                Caption = 'Inbox Transaction', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Category6)
            {
                Caption = 'Actions', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Accept_Promoted; Accept)
                {
                }
                actionref(Cancel_Promoted; Cancel)
                {
                }
                actionref("Return to IC Partner_Promoted"; "Return to IC Partner")
                {
                }
                actionref("No Action_Promoted"; "No Action")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        PartnerFilter: Code[250];
        ShowLines: Option " ","Returned by Partner","Created by Partner";
        ShowAction: Option All,"No Action",Accept,"Return to IC Partner",Cancel;

    local procedure PartnerFilterOnAfterValidate()
    begin
        Rec.SetFilter("IC Partner Code", PartnerFilter);
        CurrPage.Update(false);
    end;

    local procedure ShowLinesOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    local procedure ShowActionOnAfterValidate()
    begin
        CurrPage.Update(false);
    end;

    procedure RunInboxTransactions(var ICInboxTransaction: Record "IC Inbox Transaction")
    var
        ICInboxTransactionCopy: Record "IC Inbox Transaction";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ConfirmManagement: Codeunit "Confirm Management";
        RunReport: Boolean;
        PurchaseInvoicePreviouslySentAsOrderMsg: Label 'A purchase order for this invoice has already been received from intercompany partner %1. Receiving it again can lead to duplicate information. Do you want to receive it?', Comment = '%1 - Intercompany Partner Code';
    begin
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            RunReport := false
        else
            RunReport := true;

        ICInboxTransactionCopy.Copy(ICInboxTransaction);
        ICInboxTransactionCopy.SetRange("IC Source Type", ICInboxTransactionCopy."IC Source Type"::Journal);

        if not ICInboxTransactionCopy.IsEmpty() then
            RunReport := true;

        Commit();
        if SalesInvoicePreviouslySentAsOrder(Rec) then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(PurchaseInvoicePreviouslySentAsOrderMsg, Rec."IC Partner Code"), true) then
                Error('');
        REPORT.RunModal(REPORT::"Complete IC Inbox Action", RunReport, false, ICInboxTransaction);
        CurrPage.Update(true);
    end;

    local procedure SalesInvoicePreviouslySentAsOrder(ICInboxTransaction: Record "IC Inbox Transaction"): Boolean
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
    begin
        if ICInboxTransaction."Document Type" <> ICInboxTransaction."Document Type"::Invoice then
            exit(false);
        if ICInboxTransaction."IC Source Type" <> ICInboxTransaction."IC Source Type"::"Purchase Document" then
            exit(false);
        if ICInboxTransaction."Transaction Source" <> ICInboxTransaction."Transaction Source"::"Created by Partner" then
            exit(false);
        if not ICInboxPurchaseHeader.Get(ICInboxTransaction."Transaction No.", ICInboxTransaction."IC Partner Code", ICInboxTransaction."Transaction Source") then
            exit(false);
        HandledICInboxTrans.SetRange("IC Partner Code", ICInboxTransaction."IC Partner Code");
        HandledICInboxTrans.SetRange("Transaction Source", ICInboxTransaction."Transaction Source");
        HandledICInboxTrans.SetRange("Document No.", ICInboxPurchaseHeader."Vendor Order No.");
        HandledICInboxTrans.SetRange("IC Source Type", ICInboxTransaction."IC Source Type");
        HandledICInboxTrans.SetRange("Document Type", ICInboxTransaction."Document Type"::Order);
        exit(not HandledICInboxTrans.IsEmpty());
    end;
}

