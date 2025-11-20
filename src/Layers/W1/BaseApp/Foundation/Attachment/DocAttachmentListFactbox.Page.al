// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

using Microsoft.CRM.Outlook;
using System.Integration;

page 1178 "Doc. Attachment List Factbox"
{
    Caption = 'Documents';
    PageType = ListPart;
    DeleteAllowed = true;
    DelayedInsert = true;
    InsertAllowed = false;
    SourceTable = "Document Attachment";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec."File Name")
                {
                    Caption = 'Name';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the attached file.';
                    Width = 30;

                    trigger OnDrillDown()
                    begin
                        if Rec.SupportedByFileViewer() then
                            Rec.ViewFile()
                        else
                            Rec.Export(true);
                    end;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the file extension of the attachment.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInDetail)
            {
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                Caption = 'Show details';
                ToolTip = 'Open the document in detail.';
                Visible = true;
                trigger OnAction()
                begin
                    LoadAndRunDocumentAttachmentDetail();
                end;
            }
            fileuploadaction(AttachmentsUpload)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload files';
                AllowMultipleFiles = true;
                Visible = true;
                Image = Import;

                trigger OnAction(files: List of [FileUpload])
                var
                    DocumentAttachment: Record "Document Attachment";
                    DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
#if not CLEAN25
                    DocumentAttachmentFactbox: Page "Document Attachment Factbox";
#endif
                    RecRef: RecordRef;
                begin
#if not CLEAN25
                    if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then begin
                        DocumentAttachmentFactbox.OnBeforeDrillDown(Rec, RecRef);
                        OnAfterGetRecRefFail(Rec, RecRef);
                    end;
#else
                    if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then
                        OnAfterGetRecRefFail(Rec, RecRef);
#endif
                    DocumentAttachment.SaveAttachment(files, RecRef);
                    CurrPage.Update();
                end;
            }
            action(AttachFromEmail)
            {
                ApplicationArea = All;
                Caption = 'Attach from email';
                Image = Email;
                Enabled = EmailHasAttachments;
                Scope = Page;
                ToolTip = 'Attach files directly from email.';
                Visible = IsOfficeAddIn;

                trigger OnAction()
                begin
                    InitiateAttachFromEmail();
                end;

            }
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsVisible;
                Enabled = not IsMultiSelect;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Open);
                end;
            }
            action(EditInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can edit the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = (ShareOptionsVisible and ShareEditOptionVisible);
                Enabled = not IsMultiSelect;
                Scope = Repeater;

                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Edit);
                end;
            }
            action(ShareWithOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Share';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and share the file. You can also see who it''s already shared with.', Comment = 'OneDrive should not be translated';
                Image = Share;
                Visible = ShareOptionsVisible;
                Enabled = not IsMultiSelect;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive("Document Sharing Intent"::Share);
                end;
            }
            action(OpenInFileViewer)
            {
                ApplicationArea = All;
                Caption = 'View';
                Image = View;
                Enabled = ViewEnabled;
                Scope = Repeater;
                ToolTip = 'View the file. You will be able to download the file from the viewer control. Works only on limited number of file types.';

                trigger OnAction()
                begin
                    if Rec."File Name" <> '' then
                        Rec.ViewFile()
                    else
                        Error(CannotDownloadOrViewFileWithEmptyNameErr);
                end;
            }
            action(DownloadInRepeater)
            {
                ApplicationArea = All;
                Caption = 'Download';
                Image = Download;
                Enabled = DownloadEnabled;
                Scope = Repeater;
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    if Rec."File Name" <> '' then
                        Rec.Export(true)
                    else
                        Error(CannotDownloadOrViewFileWithEmptyNameErr);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        // When adding this factbox to a main page, the UpadtePropagation property is set to "Both" to ensure the main page is updated when a record is deleted.
        // This is necessary to call `CurrPage.Update()` to have the property take effect.
        if GuiAllowed then
            CurrPage.Update();
    end;

    local procedure LoadAndRunDocumentAttachmentDetail()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        DocumentAttachmentDetails: Page "Document Attachment Details";
#if not CLEAN25
        DocumentAttachmentFactbox: Page "Document Attachment Factbox";
#endif
        RecRef: RecordRef;
    begin
        if Rec."Table ID" = 0 then
            exit;

#if not CLEAN25
        if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then begin
            DocumentAttachmentFactbox.OnBeforeDrillDown(Rec, RecRef);
            OnAfterGetRecRefFail(Rec, RecRef);
        end;
#else
        if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then
            OnAfterGetRecRefFail(Rec, RecRef);
#endif
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
#if not CLEAN25
        DocumentAttachmentFactbox.OnBeforeDocumentAttachmentDetailsRunModal(Rec, RecRef, DocumentAttachmentDetails);
#endif  
        OnBeforeDocumentAttachmentDetailsRunModal(Rec, RecRef, DocumentAttachmentDetails);
        DocumentAttachmentDetails.RunModal();
    end;

    local procedure InitiateAttachFromEmail()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
#if not CLEAN25
        DocumentAttachmentFactbox: Page "Document Attachment Factbox";
#endif
        RecRef: RecordRef;
    begin
#if not CLEAN25
        if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then begin
            DocumentAttachmentFactbox.OnBeforeDrillDown(Rec, RecRef);
            OnAfterGetRecRefFail(Rec, RecRef);
        end;
#else
        if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then
            OnAfterGetRecRefFail(Rec, RecRef);
#endif
        OfficeMgmt.InitiateSendToAttachments(RecRef);
        CurrPage.Update(true);
    end;

    local procedure UpdateActionsVisibility()
    var
        SelectedDocumentAttachment: Record "Document Attachment";
        DocumentSharing: Codeunit "Document Sharing";
    begin
        CurrPage.SetSelectionFilter(SelectedDocumentAttachment);
        IsMultiSelect := SelectedDocumentAttachment.Count() > 1;
        DownloadEnabled := Rec.HasContent() and (not IsMultiSelect);
        ViewEnabled := DownloadEnabled and Rec.SupportedByFileViewer();

        if OfficeMgmt.IsAvailable() or OfficeMgmt.IsPopOut() then begin
            ShareOptionsVisible := false;
            ShareEditOptionVisible := false;
        end else begin
            ShareOptionsVisible := (Rec.HasContent()) and (DocumentSharing.ShareEnabled());
            ShareEditOptionVisible := DocumentSharing.EditEnabledForFile('.' + Rec."File Extension");
        end;
    end;

    trigger OnInit()
    var
        OfficeHostMgmt: Codeunit "Office Host Management";
    begin
        IsOfficeAddin := OfficeMgmt.IsAvailable();

        if IsOfficeAddin then
            EmailHasAttachments := OfficeHostMgmt.EmailHasAttachments()
        else
            EmailHasAttachments := false;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateActionsVisibility();
        Rec.FilterGroup := 4;
        if Rec.GetFilter("VAT Report Config. Code") <> '' then
            Evaluate(Rec."VAT Report Config. Code", Rec.GetFilter("VAT Report Config. Code"));
        Rec.FilterGroup := 0;
    end;

    var
        OfficeMgmt: Codeunit "Office Management";
        ShareOptionsVisible: Boolean;
        ShareEditOptionVisible: Boolean;
        DownloadEnabled: Boolean;
        ViewEnabled: Boolean;
        IsMultiSelect: Boolean;
        IsOfficeAddIn: Boolean;
        EmailHasAttachments: Boolean;
        CannotDownloadOrViewFileWithEmptyNameErr: Label 'The file must have a name.';

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecRefFail(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDocumentAttachmentDetailsRunModal(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var DocumentAttachmentDetails: Page "Document Attachment Details")
    begin
    end;
}

