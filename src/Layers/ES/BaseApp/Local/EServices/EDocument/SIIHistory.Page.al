// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Navigate;
using System.IO;
using System.Utilities;

page 10752 "SII History"
{
    ApplicationArea = All;
    Caption = 'SII History';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "SII History";
    SourceTableView = sorting(Id)
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            group(SendingInformation)
            {
                Caption = 'Sending Information';
                Visible = NewSendingExperienceAvailable;
                field(RefreshSendingStateControl; RefreshSendingStateTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Refresh Sending State';
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        SIISendingState.Refresh();
                    end;
                }
                field(SendingStatus; SIISendingState.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Sending Status';
                    Editable = false;
                    ToolTip = 'Specifies the sending status. Drill down to see the associated job queue entry.';

                    trigger OnDrillDown()
                    begin
                        SIISendingState.LookupJobQueueEntry();
                    end;
                }
                field(ResetSendingStatus; ResetSendingStateTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Reset Sending Status';
                    Editable = false;
                    ShowCaption = false;
                    Importance = Additional;

                    trigger OnDrillDown()
                    begin
                        SIISendingState.ResetSending();
                    end;
                }
            }
            repeater(Group)
            {
                field("State ID"; Rec."Document State Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the state ID.';
                    Visible = false;
                }
                field(Date; Rec."Request Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the request date.';
                }
                field("Document Source"; SIIDocUploadState."Document Source")
                {
                    ApplicationArea = All;
                    Caption = 'Document Source';
                    Editable = false;
                    ToolTip = 'Specifies the document source.';
                }
                field("Document Type"; SIIDocUploadState."Document Type")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the document type.';
                }
                field("Document No."; SIIDocUploadState."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    Editable = false;
                    ToolTip = 'Specifies the Document No.';
                }
                field(CVNo; SIIDocUploadState."CV No.")
                {
                    ApplicationArea = All;
                    Caption = 'Customer/Vendor No.';
                    ToolTip = 'Specifies the customer/vendor no. of the entry.';
                }
                field("Posting Date"; SIIDocUploadState."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                    Editable = false;
                    ToolTip = 'Specifies the posting date.';
                }
                field(SalesInvType; SIIDocUploadState."Sales Invoice Type")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Invoice Type';
                    ToolTip = 'Specifies the type of the sales invoice.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Invoice Type"));
                    end;
                }
                field(SalesCrMemoType; SIIDocUploadState."Sales Cr. Memo Type")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Cr. Memo Type';
                    ToolTip = 'Specifies the type of the sales credit memo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Cr. Memo Type"));
                    end;
                }
                field(SalesSpecialSchemeCode; SIIDocUploadState."Sales Special Scheme Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Special Scheme Code';
                    Editable = false;
                    ToolTip = 'Specifies the special scheme code of the sales document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Sales Special Scheme Code"));
                    end;
                }
                field(PurchInvType; SIIDocUploadState."Purch. Invoice Type")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Invoice Type';
                    ToolTip = 'Specifies the type of the purchase invoice.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Invoice Type"));
                    end;
                }
                field(PurchCrMemoType; SIIDocUploadState."Purch. Cr. Memo Type")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Cr. Memo Type';
                    ToolTip = 'Specifies the type of the purchase credit memo.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Cr. Memo Type"));
                    end;
                }
                field(PurchSpecialSchemeCode; SIIDocUploadState."Purch. Special Scheme Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Special Scheme Code';
                    Editable = false;
                    ToolTip = 'Specifies the special scheme code of the purchase document.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateDocInfoOnSIIDocUploadState(SIIDocUploadState.FieldNo("Purch. Special Scheme Code"));
                    end;
                }
                field(RetryAccepted; SIIDocUploadState."Retry Accepted")
                {
                    ApplicationArea = All;
                    Caption = 'Retry Accepted';
                    ToolTip = 'Specifies if the already accepted entry to be send to SII system again.';
                }
                field(SucceededCompanyName; SIIDocUploadState."Succeeded Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Succeeded Company Name';
                    ToolTip = 'Specifies the name of the company successor in connection with corporate restructuring.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Succeeded Company Name"));
                    end;
                }
                field(SucceededVATRegistrationNo; SIIDocUploadState."Succeeded VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'Succeeded VAT Registration No.';
                    ToolTip = 'Specifies the VAT registration number of the company successor in connection with corporate restructuring.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Succeeded VAT Registration No."));
                    end;
                }
                field(SIIVersionNo; SIIDocUploadState."Version No.")
                {
                    ApplicationArea = All;
                    Caption = 'SII Version No.';
                    ToolTip = 'Specifies which version of the immediate VAT information system is used.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo("Version No."));
                    end;
                }
                field(IDType; SIIDocUploadState.IDType)
                {
                    ApplicationArea = All;
                    Caption = 'ID Type';
                    ToolTip = 'Specifies which ID type of the immediate VAT information system is used.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SIIDocUploadState.UpdateFieldOnSIIDOcUploadState(SIIDocUploadState.FieldNo(IDType));
                    end;
                }
                field(AcceptedByUserID; SIIDocUploadState."Accepted By User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Accepted By User ID';
                    ToolTip = 'Specifies the user who manually change the status to Accepted by action Mark As Accepted.';
                    Visible = false;
                }
                field(AcceptedDateTime; SIIDocUploadState."Accepted Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'Accepted Date Time';
                    ToolTip = 'Specifies the date and time when user change the status to Accepted by action Mark As Accepted.';
                    Visible = false;
                }
                field("Upload Type"; Rec."Upload Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the upload Type.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the status.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the error Message.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Retry)
            {
                ApplicationArea = All;
                Caption = 'Retry';
                Enabled = Enabled;
                Image = Refresh;
                Scope = Repeater;
                ToolTip = 'Retry to send the document to SII.';
                Visible = RecordsFound;

                trigger OnAction()
                begin
                    IssueManualRequest(false);
                end;
            }
            action("Retry All")
            {
                ApplicationArea = All;
                Caption = 'Retry All';
                Enabled = EnabledBatchSubmission;
                Image = Refresh;
                Scope = Repeater;
                ToolTip = 'Retry to send all non-accepted documents to SII.';

                trigger OnAction()
                begin
                    RetryAllRequests();
                end;
            }
            action("Retry Accepted")
            {
                ApplicationArea = All;
                Caption = 'Retry Accepted';
                Enabled = Enabled;
                Image = Refresh;
                Scope = Repeater;
                ToolTip = 'Retry to send accepted documents to SII.';

                trigger OnAction()
                begin
                    if Confirm(RetryAcceptedQst) then
                        IssueManualRequest(true);
                end;
            }
            action("Generate Collections In Cash")
            {
                ApplicationArea = All;
                Caption = 'Generate Collections In Cash';
                Enabled = Enabled;
                Image = CreateLinesFromJob;
                Scope = Repeater;

                trigger OnAction()
                var
                    SIIManagement: Codeunit "SII Management";
                begin
                    SIIManagement.Run347DeclarationToGenerateCollectionsInCash();
                    CurrPage.Update();
                end;
            }
            action("Mark As Accepted")
            {
                ApplicationArea = All;
                Caption = 'Mark As Accepted';
                Enabled = Enabled;
                Scope = Repeater;
                ToolTip = 'Mark as accepted. A new pending entry will be created.';
                Visible = ShowAdvancedActions;

                trigger OnAction()
                var
                    SIIHistory: Record "SII History";
                    SIIManagement: Codeunit "SII Management";
                begin
                    CurrPage.SetSelectionFilter(SIIHistory);
                    SIIManagement.MarkAsAccepted(SIIHistory);
                end;
            }
            action("Mark As Not Accepted")
            {
                ApplicationArea = All;
                Caption = 'Mark As Not Accepted';
                Enabled = Enabled;
                Scope = Repeater;
                ToolTip = 'Mark as not accepted. A new pending entry will be created.';
                Visible = ShowAdvancedActions;

                trigger OnAction()
                var
                    SIIHistory: Record "SII History";
                    SIIManagement: Codeunit "SII Management";
                begin
                    CurrPage.SetSelectionFilter(SIIHistory);
                    SIIManagement.MarkAsNotAccepted(SIIHistory);
                end;
            }
            action(UploadPendingDocuments)
            {
                ApplicationArea = All;
                Caption = 'Upload Pending Documents';
                Enabled = Enabled;
                Visible = UploadPendingDocsVisible;
                Image = SendTo;
                Scope = Repeater;
                ToolTip = 'Upload pending documents to SII. If you enabled the ''Enable Batch Submissions'' option then documents will be sent when their number exceeds the ''Job Batch Submission Threshold'' in the SII Setup.';

                trigger OnAction()
                var
                    SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
                begin
                    SIIDocUploadManagement.UploadPendingDocuments();
                    CurrPage.Update();
                end;
            }
            action("Recreate Missing SII Entries")
            {
                ApplicationArea = All;
                Caption = 'Recreate Missing SII Entries';
                Enabled = Enabled;
                Image = CreateLinesFromTimesheet;
                RunObject = Page "Recreate Missing SII Entries";
                Scope = Repeater;
                ToolTip = 'Recreate missing SII entries manually.';
                Visible = ShowAdvancedActions;
            }
        }
        area(navigation)
        {
            action("&Navigate")
            {
                ApplicationArea = All;
                Caption = 'Find entries...';
                Enabled = RecordsFound;
                Image = Navigate;
                Scope = Repeater;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc(SIIDocUploadState."Posting Date", CopyStr(SIIDocUploadState."Document No.", 1, 20));
                    Navigate.Run();
                end;
            }
            action(ShowRequest)
            {
                ApplicationArea = All;
                Caption = 'Show Request XML';
                Enabled = HasRequestXML;
                Image = SendTo;
                Scope = Repeater;
                ToolTip = 'Displays the XML sent to the web service as a message.';

                trigger OnAction()
                var
                    SIISession: Record "SII Session";
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    FileName: Text;
                begin
                    FileName := FileManagement.ServerTempFileName('xml');
                    SIISession.Get(Rec."Session Id");
                    SIISession.CalcFields("Request XML");
                    TempBlob.FromRecord(SIISession, SIISession.FieldNo("Request XML"));
                    FileManagement.BLOBExportWithEncoding(TempBlob, FileName, true, TEXTENCODING::UTF8);
                end;
            }
            action(ShowResponse)
            {
                ApplicationArea = All;
                Caption = 'Show Response XML';
                Enabled = HasResponseXML;
                Image = Receipt;
                Scope = Repeater;
                ToolTip = 'Displays the response received from the web service as a message.';

                trigger OnAction()
                var
                    SIISession: Record "SII Session";
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    FileName: Text;
                begin
                    FileName := FileManagement.ServerTempFileName('xml');
                    SIISession.Get(Rec."Session Id");
                    SIISession.CalcFields("Response XML");
                    TempBlob.FromRecord(SIISession, SIISession.FieldNo("Response XML"));
                    FileManagement.BLOBExportWithEncoding(TempBlob, FileName, true, TEXTENCODING::UTF8);
                end;
            }
            action(DownloadRequestXML)
            {
                ApplicationArea = All;
                Caption = 'Download Request Xml';
                Image = Filed;
                ToolTip = 'Downlod a single request xml for selected documents.';

                trigger OnAction()
                var
                    SIIHistory: Record "SII History";
                    SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
                begin
                    CurrPage.SetSelectionFilter(SIIHistory);
                    SIIDocUploadManagement.DownloadRequestForMultipleDocuments(SIIHistory);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Retry_Promoted; Retry)
                {
                }
                actionref("Retry All_Promoted"; "Retry All")
                {
                }
                actionref("Retry Accepted_Promoted"; "Retry Accepted")
                {
                }
                actionref("Generate Collections In Cash_Promoted"; "Generate Collections In Cash")
                {
                }
                actionref("Mark As Accepted_Promoted"; "Mark As Accepted")
                {
                }
                actionref("Mark As Not Accepted_Promoted"; "Mark As Not Accepted")
                {
                }
                actionref(UploadPendingDocuments_Promoted; UploadPendingDocuments)
                {
                }
                actionref("Recreate Missing SII Entries_Promoted"; "Recreate Missing SII Entries")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Edit', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(ShowRequest_Promoted; ShowRequest)
                {
                }
                actionref(ShowResponse_Promoted; ShowResponse)
                {
                }
                actionref(DownloadRequestXL_Promoted; DownloadRequestXML)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Related Information', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        SIISession: Record "SII Session";
    begin
        if SIISession.Get(Rec."Session Id") then begin
            HasRequestXML := SIISession."Request XML".HasValue;
            HasResponseXML := SIISession."Response XML".HasValue;
        end else begin
            HasRequestXML := false;
            HasResponseXML := false;
        end;
    end;

    trigger OnAfterGetRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        RecordsFound := true;
        StyleText := SIIManagement.GetSIIStyle(Rec.Status.AsInteger());
        SIIDocUploadState.Get(Rec."Document State Id");
    end;

    trigger OnInit()
    var
        SIISetup: Record "SII Setup";
        SIIJobManagement: Codeunit "SII Job Management";
    begin
        if SIISetup.Get() then begin
            Enabled := SIISetup.Enabled;
            EnabledBatchSubmission := Enabled and SIISetup."Enable Batch Submissions";
            ShowAdvancedActions := SIISetup."Show Advanced Actions";
            UploadPendingDocsVisible := SIISetup."Do Not Schedule JQ Entry";
        end else begin
            Enabled := false;
            EnabledBatchSubmission := false;
            ShowAdvancedActions := false;
            UploadPendingDocsVisible := false;
        end;
        NewSendingExperienceAvailable := SIISetup."New Automatic Sending Exp.";
        SIIJobManagement.CreateAndStartJobQueueEntryForMissingEntryDetection(SIISetup."Auto Missing Entries Check");
    end;

    trigger OnOpenPage()
    begin
        if Rec.FindFirst() then;
        SIISendingState.Refresh();
    end;

    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIISendingState: Record "SII Sending State";
        RecordsFound: Boolean;
        HasRequestXML: Boolean;
        HasResponseXML: Boolean;
        StyleText: Text;
        Enabled: Boolean;
        EnabledBatchSubmission: Boolean;
        UploadPendingDocsVisible: Boolean;
        RetryAcceptedQst: Label 'Accepted entries have been selected. Do you want to resend them?';
        ShowAdvancedActions: Boolean;
        NewSendingExperienceAvailable: Boolean;
        RefreshSendingStateTxt: Label 'Refresh sending state';
        ResetSendingStateTxt: Label 'Reset sending state';

    local procedure IssueManualRequest(RetryAccepted: Boolean)
    var
        SIIHistory: Record "SII History";
        TempSIIDocUploadState: Record "SII Doc. Upload State" temporary;
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        if EnabledBatchSubmission then
            CurrPage.SetSelectionFilter(SIIHistory)
        else begin
            SIIHistory := Rec;
            SIIHistory.SetRecFilter();
        end;

        SIIHistory.Ascending(false);
        if RetryAccepted then
            SIIHistory.SetRange(Status, SIIHistory.Status::Accepted)
        else
            SIIHistory.SetFilter(Status, '<>%1', SIIHistory.Status::Accepted);

        if SIIHistory.FindSet(true) then
            repeat
                CreateNewRequestPerDocument(
                  TempSIIDocUploadState, SIIHistory, SIIHistory."Upload Type", RetryAccepted or (SIIHistory.Status = SIIHistory.Status::"Accepted With Errors"));
            until SIIHistory.Next() = 0;
        SIIDocUploadManagement.UploadManualDocument();
    end;

    local procedure RetryAllRequests()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        SIIDocUploadState.SetFilter(Status, '<>%1', Rec.Status::Accepted);
        if SIIDocUploadState.FindSet(true) then begin
            SIIHistory.Ascending(false);
            repeat
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                if SIIHistory.FindFirst() then
                    if SIIHistory.Status <> SIIHistory.Status::Pending then
                        Rec.CreateNewRequest(
                          SIIHistory."Document State Id", SIIHistory."Upload Type", 1, true,
                          SIIHistory.Status = SIIHistory.Status::"Accepted With Errors")
                    else
                        if not SIIHistory."Is Manual" then begin
                            SIIHistory."Is Manual" := true;
                            SIIHistory.Modify();
                            SIIDocUploadState."Is Manual" := true;
                            SIIDocUploadState.Modify();
                        end;
            until SIIDocUploadState.Next() = 0;
        end;
        SIIDocUploadManagement.UploadManualDocument();
    end;

    local procedure CreateNewRequestPerDocument(var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var SIIHistory: Record "SII History"; UploadType: Option; IsAcceptedWithErrorRetry: Boolean)
    begin
        if not TempSIIDocUploadState.Get(SIIHistory."Document State Id") then begin
            TempSIIDocUploadState.Id := SIIHistory."Document State Id";
            TempSIIDocUploadState.Insert();

            if SIIHistory.Status <> SIIHistory.Status::Pending then
                // We set 1 retry for manual call.
                SIIHistory.CreateNewRequest(SIIHistory."Document State Id", UploadType, 1, true, IsAcceptedWithErrorRetry)
            else
                if not SIIHistory."Is Manual" and (SIIHistory.Status <> SIIHistory.Status::Accepted) then begin
                    SIIHistory."Is Manual" := true;
                    SIIHistory.Modify();
                    SIIDocUploadState.Get(SIIHistory."Document State Id");
                    SIIDocUploadState."Is Manual" := true;
                    SIIDocUploadState.Modify();
                end;
        end;
    end;
}

