// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Service.Comment;
using Microsoft.Utilities;

page 5971 "Posted Service Credit Memos"
{
    ApplicationArea = Service;
    Caption = 'Posted Service Credit Memos';
    CardPageID = "Posted Service Credit Memo";
    Editable = false;
    PageType = List;
    SourceTable = "Service Cr.Memo Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a document number that refers to the customer''s numbering system.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                }
                field(Amount; Rec.Amount)
                {
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = true;
                }
                field("Document Exchange Status"; Rec."Document Exchange Status")
                {
                    ApplicationArea = Service;
                    StyleExpr = DocExchStatusStyle;
                    Visible = DocExchStatusVisible;

                    trigger OnDrillDown()
                    var
                        DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                    begin
                        DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Cr.Memo Header"),
                              "No." = field("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                Image = CreditMemo;
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        Rec.OpenStatistics();
                    end;
                }
#endif
                action(ServiceStatistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = true;
#else
                    Visible = false;
#endif
                    RunObject = Page "Service Credit Memo Statistics";
                    RunPageOnRec = true;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = Type = const(General),
                                  "Table Name" = const("Service Cr.Memo Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.SendRecords();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ServCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.PrintRecords(true);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Service;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    ServCrMemoHeader: Record "Service Cr.Memo Header";
                begin
                    ServCrMemoHeader := Rec;
                    ServCrMemoHeader.SetRecFilter();
                    Rec.PrintToDocumentAttachment(ServCrMemoHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                begin
                    ActivityLog.ShowEntries(Rec.RecordId);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_CategoryPrint)
                {
                    ShowAs = SplitButton;

                    actionref("&Print_Promoted"; "&Print")
                    {
                    }
                    actionref(AttachAsPDF_Promoted; AttachAsPDF)
                    {
                    }
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group("Category_Credit Memo")
                {
                    Caption = 'Credit Memo';
#if not CLEAN27
                    actionref(Statistics_Promoted; Statistics)
                    {
                        ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '27.0';
                    }
#else
                    actionref(ServiceStatistics_Promoted; ServiceStatistics)
                    {
                    }
#endif
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref(ActivityLog_Promoted; ActivityLog)
                    {
                    }
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnOpenPage()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ServiceCrMemoHeader.CopyFilters(Rec);
        ServiceCrMemoHeader.SetFilter("Document Exchange Status", '<>%1', Rec."Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not ServiceCrMemoHeader.IsEmpty();
    end;

    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
}