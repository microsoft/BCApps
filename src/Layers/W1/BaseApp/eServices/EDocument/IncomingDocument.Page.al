// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Navigate;
using Microsoft.Utilities;
using System.Automation;
using System.Device;
using System.Environment;
using System.IO;
using System.Utilities;
using System.Threading;

page 189 "Incoming Document"
{
    Caption = 'Incoming Document';
    PageType = Document;
    SourceTable = "Incoming Document";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the description of the incoming document. You must enter the description manually.';
                }
                field(URL; Rec.URL)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link to Document';
                    ExtendedDatatype = URL;
                    Importance = Additional;
                    ToolTip = 'Specifies a link to the attached file.';

                    trigger OnValidate()
                    begin
                        Rec.SetURL(Rec.URL);
                        CurrPage.Update();
                    end;
                }
                field(MainAttachment; AttachmentFileName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Main Attachment';
                    Editable = false;
                    Enabled = RecordHasAttachment;
                    ToolTip = 'Specifies the main attachment. Only this attachment is processed by the OCR and document exchange services.';

                    trigger OnDrillDown()
                    begin
                        Rec.MainAttachmentDrillDown();
                        CurrPage.Update();
                    end;
                }
                field("Data Exchange Type"; Rec."Data Exchange Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsDataExchTypeEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the data exchange type that is used to process the incoming document when it is an electronic document.';

                    trigger OnValidate()
                    begin
                        if not Rec.DefaultAttachmentIsXML() then
                            Error(InvalidTypeErr);
                    end;
                }
                field("Record"; RecordLinkTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record';
                    Editable = false;
                    ToolTip = 'Specifies the record, document, journal line, or ledger entry, that is linked to the incoming document.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowRecord();
                        CurrPage.Update();
                    end;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of document or journal that the incoming document can be connected to.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the related document or journal line that is created for the incoming document.';
                    Visible = false;
                }
                field(StatusField; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    StyleExpr = StatusStyleText;
                    ToolTip = 'Specifies the status of the incoming document record.';
                }
                field("OCR Status"; Rec."OCR Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the incoming document record when it takes part in the OCR process.';

                    trigger OnDrillDown()
                    var
                        OCRServiceSetup: Record "OCR Service Setup";
                        OCRServiceMgt: Codeunit "OCR Service Mgt.";
                    begin
                        if not OCRServiceSetup.IsEmpty() then
                            HyperLink(OCRServiceMgt.GetStatusHyperLink(Rec));
                    end;
                }
                field("OCR Track ID"; Rec."OCR Track ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the process stage of the track ID in relation to the OCR service.';
                }
                field("Job Queue Status"; Rec."Job Queue Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the job queue entry that is processing the incoming document.';

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                    begin
                        if Rec."Job Queue Status" = Rec."Job Queue Status"::" " then
                            exit;
                        JobQueueEntry.ShowStatusMsg(Rec."Job Queue Entry ID");
                    end;
                }
                group(Control71)
                {
                    ShowCaption = false;
                    field("OCR Service Doc. Template Code"; Rec."OCR Service Doc. Template Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the code of the document template that you want the OCR service provider to use when they convert the incoming-document file to an electronic document. Chose the field to pick a supported document template from the OCR Service Setup window.';
                    }
                    field("OCR Service Doc. Template Name"; Rec."OCR Service Doc. Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the document template that you want the OCR service provider to use when they convert the incoming-document file to an electronic document. Chose the field to pick a supported document template from the OCR Service Setup window.';
                    }
                    field(OCRResultFileName; OCRResultFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'OCR Result';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies what process stage the attached PDF or image file is in relation to the OCR service.';

                        trigger OnDrillDown()
                        begin
                            Rec.OCRResultDrillDown();
                            CurrPage.Update();
                        end;
                    }
                }
                group(Control72)
                {
                    ShowCaption = false;
                    field("Created Date-Time"; Rec."Created Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document line was created.';
                    }
                    field("Created By User Name"; Rec."Created By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who created the incoming document line.';
                    }
                    field(Released; Rec.Released)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the incoming document has been approved.';
                        Visible = false;
                    }
                    field("Released Date-Time"; Rec."Released Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document was approved.';
                    }
                    field("Released By User Name"; Rec."Released By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who approved the incoming document.';
                    }
                    field("Last Date-Time Modified"; Rec."Last Date-Time Modified")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the incoming document line was last modified.';
                    }
                    field("Last Modified By User Name"; Rec."Last Modified By User Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies the name of the user who last modified the incoming document line.';
                    }
                    field(Posted; Rec.Posted)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies if the document or journal line that was created for this incoming document has been posted.';
                    }
                    field("Posted Date-Time"; Rec."Posted Date-Time")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies when the related document or journal line was posted.';
                    }
                    field("Posting Date"; Rec."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies when the document or journal line that relates to the incoming document was posted.';
                        Visible = false;
                    }
                }
            }
            part(SupportingAttachments; "Incoming Document Attachments")
            {
                ApplicationArea = All;
                Caption = 'Supporting Attachments';
                ShowFilter = false;
                UpdatePropagation = Both;
                Visible = AdditionalAttachmentsPresent;
            }
            group(FinancialInformation)
            {
                Caption = 'Financial Information';
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor on the incoming document. The field may be filled automatically.';
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the vendor on the incoming document. The field may be filled automatically.';
                }
                field("Vendor VAT Registration No."; Rec."Vendor VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the VAT registration number of the vendor, if the document contains that number. The field may be filled automatically.';
                }
                field("Vendor IBAN"; Rec."Vendor IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the IBAN of the vendor on the incoming document.';
                }
                field("Vendor Bank Branch No."; Rec."Vendor Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank branch number of the vendor on the incoming document.';
                }
                field("Vendor Bank Account No."; Rec."Vendor Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account number of the vendor on the incoming document.';
                }
                field("Vendor Phone No."; Rec."Vendor Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the phone number of the vendor on the incoming document.';
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Order No.';
                    Editable = false;
                    ToolTip = 'Specifies the order number, if the document contains that number. The field may be filled automatically.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date that is printed on the incoming document. This is the date when the vendor created the invoice, for example. The field may be filled automatically.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the vendor document must be paid. The field may be filled automatically.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code, if the document contains that code. The field may be filled automatically.';
                }
                field("Amount Excl. VAT"; Rec."Amount Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount excluding VAT for the whole document. The field may be filled automatically.';
                }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount including VAT for the whole document. The field may be filled automatically.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                }
            }
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Errors and Warnings';
                ShowFilter = false;
            }
        }
        area(factboxes)
        {
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            systempart(Control38; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control39; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
#if not CLEAN25
#pragma warning disable AL0545
        area(creation)
        {
        }
#pragma warning restore AL0545
#endif
        area(navigation)
        {
            group(Action57)
            {
                Caption = 'Setup';
                action(Setup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup';
                    Image = Setup;
                    RunObject = Page "Incoming Documents Setup";
                    ToolTip = 'Define the general journal type to use when creating journal lines. You can also specify whether it requires approval to create documents and journal lines.';
                }
                action(DataExchangeTypes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Exchange Types';
                    Image = Entries;
                    RunObject = Page "Data Exchange Types";
                    ToolTip = 'View the data exchange types that are available to convert electronic documents to documents in Dynamics 365.';
                }
                action(ActivityLog)
                {
                    ApplicationArea = Basic, Suite;
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
                action(OCRSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'OCR Setup';
                    Image = ServiceSetup;
                    ToolTip = 'Open the OCR Service Setup window, for example to change credentials or enable the service.';
                    Visible = ShowOCRSetup;

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"OCR Service Setup");
                        CurrPage.Update();
                        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Web then
                            if Rec.OCRIsEnabled() then begin
                                OnCloseIncomingDocumentFromAction(Rec);
                                CurrPage.Close();
                            end;
                    end;
                }
                action(ApprovalEntries)
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
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }
            }
        }
        area(processing)
        {
            action(CreateDocument)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Document';
                Enabled = AutomaticCreationActionsAreEnabled;
                Image = CreateDocument;
                ToolTip = 'Create a document, such as a purchase invoice, automatically by converting the electronic document that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    Rec."Created Doc. Error Msg. Type" := Rec."Created Doc. Error Msg. Type"::Warning;
                    Rec.Modify();
                    Rec.CreateDocumentWithDataExchange();
                end;
            }
            action(CreateGenJnlLine)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Journal Line';
                Enabled = AutomaticCreationActionsAreEnabled;
                Image = TransferToGeneralJournal;
                ToolTip = 'Create a journal line automatically by converting the electronic document that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    Rec.CreateGeneralJournalLineWithDataExchange();
                end;
            }
            action(CreateManually)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Manually';
                Image = CreateCreditMemo;
                ToolTip = 'Create a document, such as a purchase invoice, manually from information in the file that is attached to the incoming document record.';

                trigger OnAction()
                begin
                    if not AskUserPermission() then
                        exit;

                    Rec.CreateManually();
                end;
            }
            action(AttachFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach File';
                Image = Attach;
                ToolTip = 'Attach a file to the incoming document record.';

                trigger OnAction()
                begin
                    Rec.ImportAttachment(Rec);
                    CurrPage.Update(true);
                end;
            }
            action(ReplaceMainAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Replace Main Attachment';
                Enabled = ReplaceMainAttachmentEnabled;
                Image = Interaction;
                ToolTip = 'Attach another file to be used as the main file attachment on the incoming document record.';

                trigger OnAction()
                begin
                    Rec.ReplaceOrInsertMainAttachment();
                    Clear(Rec."Data Exchange Type");
                end;
            }
            action(AttachFromCamera)
            {
                ApplicationArea = All;
                Caption = 'Attach Image from Camera';
                Enabled = AttachEnabled;
                Image = Camera;
                ToolTip = 'Add a picture from your device camera to the document.';
                Visible = HasCamera;

                trigger OnAction()
                var
                    IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    InStr: InStream;
                    PictureName: Text;
                begin
                    if Camera.GetPicture(InStr, PictureName) then
                        Rec.AddAttachmentFromStream(IncomingDocumentAttachment, PictureName, '', InStr);
                end;
            }
            action(TextToAccountMapping)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Map Text to Account';
                Image = MapAccounts;
                RunObject = Page "Text-to-Account Mapping Wksh.";
                ToolTip = 'Create a mapping of text on incoming documents to identical text on specific debit, credit, and balancing accounts in the general ledger or on bank accounts so that the resulting document or journal lines are prefilled with the specified information.';
            }
            group(Action45)
            {
                Caption = 'Release';
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Enabled = RecordHasAttachment;
                    Image = Approve;
                    ToolTip = 'Release the incoming document to indicate that it has been approved by the incoming document approver.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualRelease(Rec);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Enabled = RecordHasAttachment;
                    Image = ReOpen;
                    ToolTip = 'Reopen the incoming document record after it has been approved by the incoming document approver.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualReopen(Rec);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Enabled = RecordHasAttachment;
                    Image = Reject;
                    ToolTip = 'Reject to approve the incoming document.';

                    trigger OnAction()
                    var
                        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
                    begin
                        ReleaseIncomingDocument.PerformManualReject(Rec);
                    end;
                }
            }
            group(Status)
            {
                Caption = 'Status';
                action(SetToProcessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set To Processed';
                    Enabled = not Rec.Processed;
                    Image = Archive;
                    ToolTip = 'Set the incoming document to processed. It will then be moved to the Processed Incoming Documents window.';

                    trigger OnAction()
                    begin
                        Rec.Validate(Processed, true);
                        Rec.Modify(true);
                    end;
                }
                action(SetToUnprocessed)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set To Unprocessed';
                    Enabled = Rec.Processed;
                    Image = ReOpen;
                    ToolTip = 'Set the incoming document to unprocessed. This allows you to edit information or perform actions for the incoming document.';

                    trigger OnAction()
                    begin
                        Rec.Validate(Processed, false);
                        Rec.Modify(true);
                    end;
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
                        Rec.TestReadyForApproval();
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(RejectApproval)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject to approve the incoming document.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
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
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the incoming document. You can send an approval request as part of a workflow if this has been set up in your organization.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        Rec.TestReadyForApproval();
                        if ApprovalsMgmt.CheckIncomingDocApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendIncomingDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel requesting approval of the incoming document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelIncomingDocApprovalRequest(Rec);
                    end;
                }
            }
            group("Incoming Document")
            {
                Caption = 'Incoming Document';
                action(OpenDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open Record';
                    Enabled = RecordLinkExists;
                    Image = ViewDetails;
                    ToolTip = 'Open the document, journal line, or entry that the incoming document is linked to.';

                    trigger OnAction()
                    begin
                        Rec.ShowRecord();
                    end;
                }
                action(RemoveReferencedRecord)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Reference to Record';
                    Enabled = RecordLinkExists;
                    Image = ClearLog;
                    ToolTip = 'Remove the link that exists from the incoming document to a document, journal line, or entry.';

                    trigger OnAction()
                    begin
                        Rec.RemoveReferencedRecords();
                    end;
                }
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                    trigger OnAction()
                    var
                        NavigatePage: Page Navigate;
                    begin
                        if not Rec.Posted then
                            Error(NoPostedDocumentsErr);
                        NavigatePage.SetDoc(Rec."Posting Date", Rec."Document No.");
                        NavigatePage.Run();
                    end;
                }
                group(Action51)
                {
                    Caption = 'Record';
                    Enabled = false;
                    Image = Document;
                    Visible = false;
                    action(Journal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Line';
                        Image = Journal;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        var
                            GenJournalBatch: Record "Gen. Journal Batch";
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            if not AskUserPermission() then
                                exit;

                            Rec.CreateGenJnlLine();
                            IncomingDocumentsSetup.Fetch();
                            GenJournalBatch.Get(IncomingDocumentsSetup."General Journal Template Name", IncomingDocumentsSetup."General Journal Batch Name");
                            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
                        end;
                    }
                    action(PurchaseInvoice)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Invoice';
                        Image = Purchase;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission() then
                                exit;

                            Rec.CreatePurchInvoice();
                        end;
                    }
                    action(PurchaseCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Credit Memo';
                        Image = CreditMemo;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission() then
                                exit;

                            Rec.CreatePurchCreditMemo();
                        end;
                    }
                    action(SalesInvoice)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Invoice';
                        Image = Sales;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission() then
                                exit;

                            Rec.CreateSalesInvoice();
                        end;
                    }
                    action(SalesCreditMemo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Credit Memo';
                        Image = CreditMemo;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Process;
                        ToolTip = 'Open the record that the incoming document is linked to.';

                        trigger OnAction()
                        begin
                            if not AskUserPermission() then
                                exit;

                            Rec.CreateSalesCreditMemo();
                        end;
                    }
                }
            }
            group(OCR)
            {
                Caption = 'OCR';
                action(SendToJobQueue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to Job Queue';
                    Enabled = RecordHasAttachment;
                    Image = Translation;
                    ToolTip = 'Send the attached PDF or image file to the OCR service by the job queue according to the schedule, provided that no errors exist.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        Rec.SendToJobQueue(true);
                    end;
                }
                action(RemoveFromJobQueue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove from Job Queue';
                    Enabled = RecordHasAttachment;
                    Image = Translation;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        Rec.RemoveFromJobQueue(true);
                    end;
                }
                action(SendToOcr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to OCR Service';
                    Enabled = CanBeSentToOCR;
                    Image = Translations;
                    ToolTip = 'Send the attached PDF or image file to the OCR service immediately.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        Rec.SendToOCR(true);
                    end;
                }
                action(ReceiveFromOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive from OCR Service';
                    Enabled = EnableReceiveFromOCR;
                    Image = Translations;
                    ToolTip = 'Get any electronic documents that are ready to receive from the OCR service.';
                    Visible = OCRServiceIsEnabled;

                    trigger OnAction()
                    begin
                        Rec.RetrieveFromOCR(true);
                    end;
                }
                action(CorrectOCRData)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Correct OCR Data';
                    Enabled = OCRDataCorrectionEnabled;
                    Image = EditAttachment;
                    RunObject = Page "OCR Data Correction";
                    RunPageOnRec = true;
                    ToolTip = 'Open a window where you can teach the OCR service how to interpret data on PDF and image files so that future documents created by the OCR service are more correct.';
                    Visible = OCRServiceIsEnabled;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CreateManually_Promoted; CreateManually)
                {
                }
                actionref(CreateDocument_Promoted; CreateDocument)
                {
                }
                actionref(CreateGenJnlLine_Promoted; CreateGenJnlLine)
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reject_Promoted; Reject)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                group(Category_Category5)
                {
                    Caption = 'Status', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(SetToProcessed_Promoted; SetToProcessed)
                    {
                    }
                    actionref(SetToUnprocessed_Promoted; SetToUnprocessed)
                    {
                    }
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref(AttachFile_Promoted; AttachFile)
                {
                }
                actionref(ReplaceMainAttachment_Promoted; ReplaceMainAttachment)
                {
                }
                actionref(AttachFromCamera_Promoted; AttachFromCamera)
                {
                }
                actionref(TextToAccountMapping_Promoted; TextToAccountMapping)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(RejectApproval_Promoted; RejectApproval)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Incoming Document', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(OpenDocument_Promoted; OpenDocument)
                {
                }
                actionref(RemoveReferencedRecord_Promoted; RemoveReferencedRecord)
                {
                }
                actionref(ApprovalEntries_Promoted; ApprovalEntries)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'OCR', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(SendToOcr_Promoted; SendToOcr)
                {
                }
                actionref(ReceiveFromOCR_Promoted; ReceiveFromOCR)
                {
                }
                actionref(CorrectOCRData_Promoted; CorrectOCRData)
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
    begin
        IsDataExchTypeEditable := not (Rec.Status in [Rec.Status::Created, Rec.Status::Posted]);
        ShowErrors();
        SetCalculatedFields();
        RecordHasAttachment := Rec.HasAttachment();
        SetControlVisibility();
        AttachEnabled := Rec."Entry No." <> 0;
        StatusStyleText := Rec.GetStatusStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.URL := CopyStr(Rec.GetURL(), 1, MaxStrLen(Rec.URL));
        ShowErrors();
        EnableReceiveFromOCR := Rec.WaitingToReceiveFromOCR();
        CurrPage.Editable(not Rec.Processed);
    end;

    trigger OnInit()
    begin
        IsDataExchTypeEditable := true;
        EnableReceiveFromOCR := Rec.WaitingToReceiveFromOCR();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        AttachEnabled := true;
    end;

    trigger OnModifyRecord(): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        OCRDataCorrectionEnabled := Rec.GetGeneratedFromOCRAttachment(IncomingDocumentAttachment);
        RecordHasAttachment := Rec.HasAttachment();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.URL := '';
    end;

    trigger OnOpenPage()
    begin
        HasCamera := Camera.IsAvailable();
        UpdateOCRSetupVisibility();
    end;

    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        ClientTypeManagement: Codeunit "Client Type Management";
        Camera: Codeunit Camera;
        HasCamera: Boolean;
        StatusStyleText: Text;
        AttachmentFileName: Text;
        RecordLinkTxt: Text;
        OCRResultFileName: Text;
        IsDataExchTypeEditable: Boolean;
        OCRDataCorrectionEnabled: Boolean;
        AdditionalAttachmentsPresent: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        EnableReceiveFromOCR: Boolean;
        CanCancelApprovalForRecord: Boolean;
        OCRServiceIsEnabled: Boolean;
        ShowOCRSetup: Boolean;
        AutomaticCreationActionsAreEnabled: Boolean;
        RecordHasAttachment: Boolean;
        RecordLinkExists: Boolean;
        CanBeSentToOCR: Boolean;
        AttachEnabled: Boolean;
        ReplaceMainAttachmentEnabled: Boolean;

        AutomaticProcessingQst: Label 'The Data Exchange Type field is filled on at least one of the selected Incoming Documents.\\Are you sure you want to create documents manually?', Comment = '%1 is Data Exchange Type';
        InvalidTypeErr: Label 'The default attachment is not an XML document.';
        NoPostedDocumentsErr: Label 'There are no posted documents.';

    protected procedure AskUserPermission(): Boolean
    begin
        if Rec."Data Exchange Type" = '' then
            exit(true);

        if Rec.Status <> Rec.Status::New then
            exit(true);

        exit(Confirm(AutomaticProcessingQst));
    end;

    local procedure ShowErrors()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update();
    end;

    local procedure SetCalculatedFields()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        OCRDataCorrectionEnabled := Rec.GetGeneratedFromOCRAttachment(IncomingDocumentAttachment);
        AttachmentFileName := Rec.GetMainAttachmentFileName();
        RecordLinkTxt := Rec.GetRecordLinkText();
        OCRResultFileName := Rec.GetOCRResutlFileName();
        AdditionalAttachmentsPresent := Rec.GetAdditionalAttachments(IncomingDocumentAttachment);
        if AdditionalAttachmentsPresent then
            CurrPage.SupportingAttachments.PAGE.LoadDataIntoPart(Rec);
    end;

    local procedure SetControlVisibility()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RelatedRecord: Variant;
    begin
        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.Page.SetFilterOnWorkflowRecord(Rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
        UpdateOCRSetupVisibility();
        AutomaticCreationActionsAreEnabled := Rec."Data Exchange Type" <> '';
        RecordLinkExists := Rec.GetRecord(RelatedRecord);
        CanBeSentToOCR := VerifyCanBeSentToOCR();
        ReplaceMainAttachmentEnabled := Rec.CanReplaceMainAttachment();
    end;

    [IntegrationEvent(true, true)]
    local procedure OnCloseIncomingDocumentFromAction(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    local procedure VerifyCanBeSentToOCR(): Boolean
    begin
        if not RecordHasAttachment then
            exit(false);

        exit(not (Rec."OCR Status" in
                  [Rec."OCR Status"::Sent, Rec."OCR Status"::Success, Rec."OCR Status"::"Awaiting Verification"]));
    end;

    local procedure UpdateOCRSetupVisibility()
    begin
        OCRServiceIsEnabled := Rec.OCRIsEnabled();
        ShowOCRSetup := not OCRServiceIsEnabled;
    end;
}

