// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Integration;
using System.IO;
using System.Reflection;

page 193 "Incoming Doc. Attach. FactBox"
{
    Caption = 'Incoming Document Files';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Inc. Doc. Attachment Overview";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Name;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleExpressionTxt;
                    ToolTip = 'Specifies the name of the attached file.';

                    trigger OnDrillDown()
                    begin
                        Rec.NameDrillDown();
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the attached file.';
                    Visible = false;
                }
                field("File Extension"; Rec."File Extension")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file extension of the attached file.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming document line was created.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(UploadMainAttachment)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload main attachment';
                Image = Attach;
                ToolTip = 'Attach a file as the main attachment to the incoming document record.';
                Enabled = not HasMainAttachment;

                trigger OnAction()
                begin
                    UploadSingleAttachment();
                end;
            }
            fileuploadaction(UploadSupportingAttachments)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Upload supporting attachments';
                AllowMultipleFiles = true;
                Visible = true;
                Image = Import;
                Enabled = HasMainAttachment;
                ToolTip = 'Attach one or more files as the supporting attachments to the incoming document record.';

                trigger OnAction(files: List of [FileUpload])
                begin
                    UploadMultipleAttachments(files);
                end;
            }
#if not CLEAN25
            action(ImportNew)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'Action ImportNew is replaced by action UploadMainAttachment and UploadSupportingAttachments.';
                ObsoleteTag = '25.0';
                ApplicationArea = Basic, Suite;
                Caption = 'Attach File';
                Image = Attach;
                ToolTip = 'Attach a file to the incoming document record.';
                Visible = false;

                trigger OnAction()
                begin
                    UploadSingleAttachment();
                end;
            }
#endif
            action(IncomingDoc)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Incoming Document';
                Image = Document;
                Enabled = HasAttachments;
                Scope = Repeater;
                ToolTip = 'View or create an incoming document record that is linked to the entry or document.';

                trigger OnAction()
                var
                    IncomingDocument: Record "Incoming Document";
                begin
                    if not IncomingDocument.Get(Rec."Incoming Document Entry No.") then
                        exit;
                    PAGE.RunModal(PAGE::"Incoming Document", IncomingDocument);

                    if IncomingDocument.Get(IncomingDocument."Entry No.") then
                        LoadDataFromIncomingDocument(IncomingDocument);
                end;
            }
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                var
                    IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    FileManagement: Codeunit "File Management";
                    DocumentServiceMgt: Codeunit "Document Service Management";
                    FileName: Text;
                    FileExtension: Text;
                    InStream: InStream;
                begin
                    IncomingDocumentAttachment.Get(Rec."Incoming Document Entry No.", Rec."Line No.");
                    IncomingDocumentAttachment.CalcFields(Content);
                    IncomingDocumentAttachment.Content.CreateInStream(InStream);

                    FileName := FileManagement.StripNotsupportChrInFileName(Rec.Name);
                    FileExtension := StrSubstNo(FileExtensionLbl, Rec."File Extension");
                    DocumentServiceMgt.OpenInOneDrive(FileName, FileExtension, InStream);
                end;
            }
            action(ShareToOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Share';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and share the file. You can also see who it''s already shared with.', Comment = 'OneDrive should not be translated';
                Image = Share;
                Visible = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                var
                    IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    FileManagement: Codeunit "File Management";
                    DocumentServiceMgt: Codeunit "Document Service Management";
                    FileName: Text;
                    FileExtension: Text;
                    InStream: InStream;
                begin
                    IncomingDocumentAttachment.Get(Rec."Incoming Document Entry No.", Rec."Line No.");
                    IncomingDocumentAttachment.CalcFields(Content);
                    IncomingDocumentAttachment.Content.CreateInStream(InStream);

                    FileName := FileManagement.StripNotsupportChrInFileName(Rec.Name);
                    FileExtension := StrSubstNo(FileExtensionLbl, Rec."File Extension");
                    DocumentServiceMgt.ShareWithOneDrive(FileName, FileExtension, InStream);
                end;
            }
            action(OpenInFileViewer)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View';
                Image = View;
                Enabled = ViewEnabled;
                Scope = Repeater;
                ToolTip = 'View the file. You will be able to download the file from the viewer control. Works only on limited number of file types.';

                trigger OnAction()
                begin
                    Rec.NameDrillDown();
                end;
            }
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download';
                Image = Download;
                Enabled = DownloadEnabled;
                Scope = Repeater;
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    Rec.NameDrillDown(true);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentSharing: Codeunit "Document Sharing";
    begin
        StyleExpressionTxt := Rec.GetStyleTxt();

        ShareOptionsEnabled := (not Rec.IsGroupOrLink()) and (IncomingDocumentAttachment.Get(Rec."Incoming Document Entry No.", Rec."Line No.")) and (DocumentSharing.ShareEnabled());
        DownloadEnabled := (not Rec.IsGroupOrLink()) and (IncomingDocumentAttachment.Get(Rec."Incoming Document Entry No.", Rec."Line No."));
        ViewEnabled := DownloadEnabled and IncomingDocumentAttachment.SupportedByFileViewer();
        HasMainAttachment := Rec.Count() > 0;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if LoadedDataFromRecord then begin
            HasAttachments := Rec.FindFirst();
            exit(HasAttachments);
        end;

        if not FilterWasChanged() then
            exit(HasAttachments);

        PreviousViewFilter := Rec.GetView();
        HasAttachments := LoadDataFromOnFindRecord();
        HasMainAttachment := Rec.Count() > 0;
        exit(HasAttachments);
    end;

    var
        MainRecordRef: RecordRef;
        GlobalRecordID: RecordID;
        StyleExpressionTxt: Text;
        FileExtensionLbl: Label '.%1', Locked = true;
        CreateMainDocumentFirstErr: Label 'You must fill in any field to create a main record before you try to attach a document. Refresh the page and try again.';
        LoadedDataFromRecord: Boolean;
        HasAttachments: Boolean;
        ShareOptionsEnabled: Boolean;
        DownloadEnabled: Boolean;
        ViewEnabled: Boolean;
        PreviousViewFilter: text;
        GlobalDocumentNo: text;
        GlobalPostingDate: Date;
        HasMainAttachment: Boolean;

    local procedure PrepareIncDocAttachmentBeforeUpload(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", Rec."Incoming Document Entry No.");
        if GlobalRecordID.TableNo <> 0 then
            MainRecordRef := GlobalRecordID.GetRecord()
        else begin
            if GlobalDocumentNo <> '' then
                IncomingDocumentAttachment.SetRange("Document No.", GlobalDocumentNo);
            if GlobalPostingDate <> 0D then
                IncomingDocumentAttachment.SetRange("Posting Date", GlobalPostingDate);
        end;

        IncomingDocumentAttachment.SetFiltersFromMainRecord(MainRecordRef, IncomingDocumentAttachment);

        // check MainRecordRef is initialized
        if MainRecordRef.Number <> 0 then
            if not MainRecordRef.Get(MainRecordRef.RecordId) then
                Error(CreateMainDocumentFirstErr);
    end;

    local procedure UploadSingleAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
    begin
        PrepareIncDocAttachmentBeforeUpload(IncomingDocumentAttachment);

        if IncomingDocumentAttachment.Import(true) then
            if IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
                LoadDataFromIncomingDocument(IncomingDocument);
    end;

    local procedure UploadMultipleAttachments(Files: List of [FileUpload])
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        PrepareIncDocAttachmentBeforeUpload(IncomingDocumentAttachment);

        if ImportAttachmentIncDoc.ImportMultiple(IncomingDocumentAttachment, true, Files) then
            if IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.") then
                LoadDataFromIncomingDocument(IncomingDocument);
    end;

    procedure LoadDataFromOnFindRecord(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentFound: Boolean;
        CurrentFilterGroup: Integer;
    begin
        CurrentFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        IncomingDocumentFound := FindIncomingDocumentFromFilters(IncomingDocument);
        GlobalDocumentNo := Rec.GetFilter("Document No.");
        Clear(GlobalPostingDate);
        if Rec.GetFilter("Posting Date") <> '' then
            if Evaluate(GlobalPostingDate, Rec.GetFilter("Posting Date")) then;

        Rec.FilterGroup(CurrentFilterGroup);

        Rec.Reset();
        Rec.DeleteAll();

        if not IncomingDocumentFound then
            exit(false);

        Rec.InsertFromIncomingDocument(IncomingDocument, Rec);
        exit(not Rec.IsEmpty());
    end;

    local procedure FindIncomingDocumentFromFilters(var IncomingDocument: Record "Incoming Document"): Boolean
    var
        IncomingDocumentEntryNo: Text;
    begin
        IncomingDocumentEntryNo := Rec.GetFilter("Incoming Document Entry No.");
        if IncomingDocumentEntryNo <> '' then
            exit(IncomingDocument.Get(IncomingDocumentEntryNo));

        exit(IncomingDocument.FindByDocumentNoAndPostingDate(IncomingDocument, Rec.GetFilter("Document No."), Rec.GetFilter("Posting Date")));
    end;

    local procedure FilterWasChanged(): Boolean
    var
        CurrentFilterGroup: Integer;
        CurrentViewFilter: Text;
    begin
        CurrentFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        CurrentViewFilter := Rec.GetView();
        Rec.FilterGroup(CurrentFilterGroup);
        exit(PreviousViewFilter <> CurrentViewFilter);
    end;

    procedure LoadDataFromRecord(MainRecordVariant: Variant)
    var
        IncomingDocument: Record "Incoming Document";
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        LoadedDataFromRecord := true;

        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit;

        OnLoadDataFromRecordOnBeforeDeleteAll(Rec);
        Rec.DeleteAll();

        if not MainRecordRef.Get(MainRecordRef.RecordId) then
            exit;

        if GetIncomingDocumentRecord(MainRecordVariant, IncomingDocument) then
            Rec.InsertFromIncomingDocument(IncomingDocument, Rec);

        OnAfterLoadDataFromRecord(MainRecordRef);
        CurrPage.Update(false);
    end;

    procedure SetCurrentRecordID(NewRecordID: RecordID)
    begin
        if GlobalRecordID = NewRecordID then
            exit;

        GlobalRecordID := NewRecordID;
    end;

    procedure LoadDataFromIncomingDocument(IncomingDocument: Record "Incoming Document")
    begin
        OnLoadDataFromIncomingDocumentOnBeforeDeleteAll(Rec);
        Rec.DeleteAll();
        Rec.InsertFromIncomingDocument(IncomingDocument, Rec);
        CurrPage.Update(false);
    end;

    procedure GetIncomingDocumentRecord(MainRecordVariant: Variant; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        if not DataTypeManagement.GetRecordRef(MainRecordVariant, MainRecordRef) then
            exit(false);

        if MainRecordRef.Number = DATABASE::"Incoming Document" then begin
            IncomingDocument.Copy(MainRecordVariant);
            exit(true);
        end;

        exit(GetIncomingDocumentRecordFromRecordRef(IncomingDocument, MainRecordRef));
    end;

    procedure RecordHasMainAttachment()
    begin
        HasMainAttachment := Rec.Count() > 0;
    end;

    local procedure GetIncomingDocumentRecordFromRecordRef(var IncomingDocument: Record "Incoming Document"; MainRecordRef: RecordRef): Boolean
    begin
        if IncomingDocument.FindFromIncomingDocumentEntryNo(MainRecordRef, IncomingDocument) then
            exit(true);
        if IncomingDocument.FindByDocumentNoAndPostingDate(MainRecordRef, IncomingDocument) then
            exit(true);
        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterLoadDataFromRecord(var MainRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadDataFromRecordOnBeforeDeleteAll(var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadDataFromIncomingDocumentOnBeforeDeleteAll(var TempIncDocAttachmentOverview: Record "Inc. Doc. Attachment Overview" temporary)
    begin
    end;
}
