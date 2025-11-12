// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System;
using System.IO;
using System.Reflection;
using System.Utilities;
using System.Xml;

table 133 "Incoming Document Attachment"
{
    Caption = 'Incoming Document Attachment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(4; "Created By User Name"; Code[50])
        {
            Caption = 'Created By User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Image,PDF,Word,Excel,PowerPoint,Email,XML,Other';
            OptionMembers = " ",Image,PDF,Word,Excel,PowerPoint,Email,XML,Other;
        }
        field(7; "File Extension"; Text[30])
        {
            Caption = 'File Extension';

            trigger OnValidate()
            begin
                case LowerCase("File Extension") of
                    'jpg', 'jpeg', 'bmp', 'png', 'tiff', 'tif', 'gif':
                        Type := Type::Image;
                    'pdf':
                        Type := Type::PDF;
                    'docx', 'doc':
                        Type := Type::Word;
                    'xlsx', 'xls':
                        Type := Type::Excel;
                    'pptx', 'ppt':
                        Type := Type::PowerPoint;
                    'msg':
                        Type := Type::Email;
                    'xml':
                        Type := Type::XML;
                    else
                        Type := Type::Other;
                end;
            end;
        }
        field(8; Content; BLOB)
        {
            Caption = 'Content';
            SubType = Bitmap;
        }
        field(9; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; "Document Table No. Filter"; Integer)
        {
            Caption = 'Document Table No. Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Document Type Filter"; Enum "Incoming Document Type")
        {
            Caption = 'Document Type Filter';
            FieldClass = FlowFilter;
        }
        field(13; "Document No. Filter"; Code[20])
        {
            Caption = 'Document No. Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Journal Template Name Filter"; Code[20])
        {
            Caption = 'Journal Template Name Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Journal Batch Name Filter"; Code[20])
        {
            Caption = 'Journal Batch Name Filter';
            FieldClass = FlowFilter;
        }
        field(16; "Journal Line No. Filter"; Integer)
        {
            Caption = 'Journal Line No. Filter';
            FieldClass = FlowFilter;
        }
        field(17; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            begin
                if Default and (not xRec.Default) then begin
                    ClearDefaultAttachmentsFromIncomingDocument();
                    FindDataExchType();
                    UpdateIncomingDocumentHeaderFields();
                end else
                    CheckDefault();
            end;
        }
        field(18; "Use for OCR"; Boolean)
        {
            Caption = 'Use for OCR';

            trigger OnValidate()
            begin
                if "Use for OCR" then
                    if not (Type in [Type::PDF, Type::Image]) then
                        Error(MustBePdfOrPictureErr, Type::PDF, Type::Image);
            end;
        }
        field(19; "External Document Reference"; Text[50])
        {
            Caption = 'External Document Reference';
        }
        field(20; "OCR Service Document Reference"; Text[50])
        {
            Caption = 'OCR Service Document Reference';
        }
        field(21; "Generated from OCR"; Boolean)
        {
            Caption = 'Generated from OCR';
            Editable = false;
        }
        field(22; "Main Attachment"; Boolean)
        {
            Caption = 'Main Attachment';

            trigger OnValidate()
            begin
                CheckMainAttachment();
            end;
        }
    }

    keys
    {
        key(Key1; "Incoming Document Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Created Date-Time", Name, "File Extension", Type)
        {
        }
    }

    trigger OnDelete()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DeleteOtherAttachmentsFirstErr: Label 'You must delete all other attachments before you can delete attachment marked as %1.', Comment = '%1 - Field Caption';
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
        IncomingDocumentAttachment.SetFilter("Line No.", '<>%1', "Line No.");

        if Default then
            if not IncomingDocumentAttachment.IsEmpty() then
                Error(DeleteOtherAttachmentsFirstErr, Rec.FieldCaption(Default));

        if "Main Attachment" then
            if not IncomingDocumentAttachment.IsEmpty() then
                Error(DeleteOtherAttachmentsFirstErr, Rec.FieldCaption("Main Attachment"));
    end;

    trigger OnInsert()
    begin
        TestField("Incoming Document Entry No.");
        "Created Date-Time" := RoundDateTime(CurrentDateTime, 1000);
        "Created By User Name" := CopyStr(UserId(), 1, MaxStrLen("Created By User Name"));

        SetFirstAttachmentAsDefault();
        SetFirstAttachmentAsMain();

        CheckDefault();
        CheckMainAttachment();
    end;

    trigger OnModify()
    begin
        CheckDefault();
        CheckMainAttachment();
    end;

    var
        DeleteQst: Label 'Do you want to delete the attachment?';
        MustBePdfOrPictureErr: Label 'Only files of type %1 and %2 can be used for OCR.', Comment = '%1 and %2 are file types: PDF and Picture';
        NotifIncDocCompletedMsg: Label 'The action to create an incoming document from file has completed.';

    procedure NewAttachment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNewAttachment(Rec, IsHandled);
        if IsHandled then
            exit;

        if not CODEUNIT.Run(CODEUNIT::"Import Attachment - Inc. Doc.", Rec) then
            Error(GetLastErrorText());
    end;

    procedure NewAttachmentFromGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Line No." = 0 then
            exit;
        SetRange("Incoming Document Entry No.", GenJournalLine."Incoming Document Entry No.");
        SetRange("Journal Template Name Filter", GenJournalLine."Journal Template Name");
        SetRange("Journal Batch Name Filter", GenJournalLine."Journal Batch Name");
        SetRange("Journal Line No. Filter", GenJournalLine."Line No.");

        NewAttachment();
    end;

    procedure NewAttachmentFromSalesDocument(SalesHeader: Record "Sales Header")
    begin
        NewAttachmentFromDocument(
          SalesHeader."Incoming Document Entry No.",
          DATABASE::"Sales Header",
          SalesHeader."Document Type".AsInteger(),
          SalesHeader."No.");
    end;

    procedure NewAttachmentFromPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        NewAttachmentFromDocument(
          PurchaseHeader."Incoming Document Entry No.",
          DATABASE::"Purchase Header",
          PurchaseHeader."Document Type".AsInteger(),
          PurchaseHeader."No.");
    end;

    procedure NewAttachmentFromDocument(EntryNo: Integer; TableID: Integer; DocumentType: Option; DocumentNo: Code[20])
    begin
        ApplyFiltersForDocument(EntryNo, TableID, DocumentType, DocumentNo);
        NewAttachment();
        SendNotifActionCompleted();
    end;

    procedure NewAttachmentFromPurchaseDocument(PurchaseHeader: Record "Purchase Header"; FileName: Text[250]; var TempBlob: Codeunit "Temp Blob")
    begin
        NewAttachmentFromDocument(
          PurchaseHeader."Incoming Document Entry No.",
          DATABASE::"Purchase Header",
          PurchaseHeader."Document Type".AsInteger(),
          PurchaseHeader."No.",
          FileName,
          TempBlob);
    end;

    procedure NewAttachmentFromDocument(EntryNo: Integer; TableID: Integer; DocumentType: Option; DocumentNo: Code[20]; FileName: Text[250]; var TempBlob: Codeunit "Temp Blob")
    var
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        ApplyFiltersForDocument(EntryNo, TableID, DocumentType, DocumentNo);
        ImportAttachmentIncDoc.ImportAttachment(Rec, FileName, TempBlob);
        if GuiAllowed() then
            SendNotifActionCompleted();
    end;

    local procedure ApplyFiltersForDocument(EntryNo: Integer; TableID: Integer; DocumentType: Option; DocumentNo: Code[20])
    begin
        Rec.SetRange("Incoming Document Entry No.", EntryNo);
        Rec.SetRange("Document Table No. Filter", TableID);
        Rec.SetRange("Document Type Filter", DocumentType);
        Rec.SetRange("Document No. Filter", DocumentNo);
    end;


    procedure NewAttachmentFromPostedDocument(DocumentNo: Code[20]; PostingDate: Date)
    begin
        SetRange("Document No.", DocumentNo);
        SetRange("Posting Date", PostingDate);
        NewAttachment();
        if GuiAllowed() then
            SendNotifActionCompleted();
    end;

    procedure Import() IsImported: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        IsImported := false;
        OnBeforeImport(Rec, IsImported, IsHandled);
        if IsHandled then
            exit(IsImported);

        exit(Import(false));
    end;

    procedure Import(RethrowError: Boolean): Boolean
    begin
        if CODEUNIT.Run(CODEUNIT::"Import Attachment - Inc. Doc.", Rec) then
            exit(true);

        if not RethrowError then
            exit(false);

        Error(GetLastErrorText());
    end;

    [Scope('OnPrem')]
    procedure Export(DefaultFileName: Text; ShowFileDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        OnBeforeExport(Rec);

        if not GetContent(TempBlob) then
            exit;

        if DefaultFileName = '' then
            DefaultFileName := Name + '.' + "File Extension";

        exit(FileMgt.BLOBExport(TempBlob, DefaultFileName, ShowFileDialog));
    end;

    procedure GetContent(var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        if "Incoming Document Entry No." = 0 then
            exit(false);

        OnGetBinaryContent(TempBlob, "Incoming Document Entry No.");
        if not TempBlob.HasValue() then
            TempBlob.FromRecord(Rec, FieldNo(Content));
        exit(TempBlob.HasValue());
    end;

    procedure DeleteAttachment()
    var
        IncomingDocument: Record "Incoming Document";
        CannotDeleteDefaultAttachmentErr: Label 'You cannot delete the default attachment.';
    begin
        TestField("Incoming Document Entry No.");
        TestField("Line No.");

        if Default then
            Error(CannotDeleteDefaultAttachmentErr);

        IncomingDocument.Get("Incoming Document Entry No.");
        IncomingDocument.TestField(Posted, false);
        if Confirm(DeleteQst, false) then
            Delete();
    end;

    local procedure CheckDefault()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OnlyOneDefaultAttachmentAllowedErr: Label 'There can only be one default attachment.';
        MustHaveOneDefaultAttachmentErr: Label 'First attachment must be marked as default.';
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
        IncomingDocumentAttachment.SetFilter("Line No.", '<>%1', "Line No.");
        IncomingDocumentAttachment.SetRange(Default, true);
        if IncomingDocumentAttachment.IsEmpty() then begin
            if not Default then
                Error(MustHaveOneDefaultAttachmentErr);
        end else
            if Default then
                Error(OnlyOneDefaultAttachmentAllowedErr);
    end;

    local procedure ClearDefaultAttachmentsFromIncomingDocument()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
        IncomingDocumentAttachment.SetFilter("Line No.", '<>%1', "Line No.");
        IncomingDocumentAttachment.ModifyAll(Default, false);
    end;

    [Scope('OnPrem')]
    procedure SendToOCR()
    var
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        CalcFields(Content);
        OnGetBinaryContent(TempBlob, "Incoming Document Entry No.");
        if not TempBlob.HasValue() then
            TempBlob.FromRecord(Rec, FieldNo(Content));

        if "External Document Reference" = '' then
            "External Document Reference" := LowerCase(DelChr(Format(CreateGuid()), '=', '{}-'));
        Modify();
        IncomingDocument.Get("Incoming Document Entry No.");
        OCRServiceMgt.UploadAttachment(
          TempBlob,
          StrSubstNo('%1.%2', Name, "File Extension"),
          "External Document Reference",
          IncomingDocument."OCR Service Doc. Template Code",
          IncomingDocument.RecordId);
    end;

    procedure GetFullName(): Text
    begin
        exit(StrSubstNo('%1.%2', Name, "File Extension"));
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnAttachBinaryFile()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetBinaryContent(var TempBlob: Codeunit "Temp Blob"; IncomingDocumentEntryNo: Integer)
    begin
    end;

    local procedure FindDataExchType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindDataExchType(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::XML then
            exit;
        Commit();
        if CODEUNIT.Run(CODEUNIT::"Data Exch. Type Selector", Rec) then;
    end;

    local procedure UpdateIncomingDocumentHeaderFields()
    var
        IncomingDocument: Record "Incoming Document";
        TempBlob: Codeunit "Temp Blob";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLRootNode: DotNet XmlNode;
        InStream: InStream;
    begin
        if Type <> Type::XML then
            exit;
        OnGetBinaryContent(TempBlob, "Incoming Document Entry No.");
        if not TempBlob.HasValue() then
            TempBlob.FromRecord(Rec, FieldNo(Content));

        TempBlob.CreateInStream(InStream);
        if not XMLDOMManagement.LoadXMLNodeFromInStream(InStream, XMLRootNode) then
            exit;
        if not IncomingDocument.Get(Rec."Incoming Document Entry No.") then
            exit;
        ExtractHeaderFields(XMLRootNode, IncomingDocument);
    end;

    [Scope('OnPrem')]
    procedure ExtractHeaderFields(var XMLRootNode: DotNet XmlNode; var IncomingDocument: Record "Incoming Document")
    var
        TempFieldBuffer: Record "Field Buffer" temporary;
    begin
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Id"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Name"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Invoice No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Order No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Document Date"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Due Date"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Amount Excl. VAT"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Amount Incl. VAT"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("VAT Amount"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Currency Code"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor VAT Registration No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor IBAN"));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Bank Branch No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Bank Account No."));
        AddFieldToFieldBuffer(TempFieldBuffer, IncomingDocument.FieldNo("Vendor Phone No."));

        OnBeforeExtractHeaderFields(TempFieldBuffer, IncomingDocument);

        TempFieldBuffer.Reset();
        TempFieldBuffer.FindSet();
        repeat
            ExtractHeaderField(XMLRootNode, IncomingDocument, TempFieldBuffer."Field ID");
        until TempFieldBuffer.Next() = 0;
    end;

    local procedure ExtractHeaderField(var XMLRootNode: DotNet XmlNode; var IncomingDocument: Record "Incoming Document"; FieldNo: Integer)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        ImportXMLFileToDataExch: Codeunit "Import XML File to Data Exch.";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        XmlNamespaceManager: DotNet XmlNamespaceManager;
        DateVar: Date;
        DecimalVar: Decimal;
        IntegerVar: Integer;
        GuidVar: Guid;
        XmlValue: Text;
        XPath: Text;
    begin
        IncomingDocument.Find();
        XPath := IncomingDocument.GetDataExchangePath(FieldNo);
        if XPath = '' then
            exit;
        XPath := ImportXMLFileToDataExch.EscapeMissingNamespacePrefix(XPath);
        RecRef.GetTable(IncomingDocument);
        FieldRef := RecRef.Field(FieldNo);
        XMLDOMManagement.AddNamespaces(XmlNamespaceManager, XMLRootNode.OwnerDocument);
        XmlValue := XMLDOMManagement.FindNodeTextNs(XMLRootNode, XPath, XmlNamespaceManager);

        case FieldRef.Type of
            FieldType::Text, FieldType::Code:
                FieldRef.Value := CopyStr(XmlValue, 1, FieldRef.Length);
            FieldType::Date:
                if Evaluate(DateVar, XmlValue, 9) then
                    FieldRef.Value := DateVar
                else
                    if Evaluate(DateVar, OCRServiceMgt.DateConvertYYYYMMDD2XML(XmlValue), 9) then
                        FieldRef.Value := DateVar;
            FieldType::Integer:
                if Evaluate(IntegerVar, XmlValue, 9) then
                    FieldRef.Value := IntegerVar;
            FieldType::Decimal:
                if Evaluate(DecimalVar, XmlValue, 9) then
                    FieldRef.Value := DecimalVar;
            FieldType::GUID:
                if Evaluate(GuidVar, XmlValue, 9) then
                    FieldRef.Value := GuidVar;
        end;
        RecRef.SetTable(IncomingDocument);

        OnAfterSetValueOnExtractHeaderField(IncomingDocument, FieldNo);
        IncomingDocument.Modify();
    end;

    local procedure CheckMainAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        OnlyOneMainAttachmentAllowedErr: Label 'There can only be one Main Attachment.';
        MustHaveOneMainAttachmentErr: Label 'First attachment must be marked as Main Attachment.';
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
        IncomingDocumentAttachment.SetFilter("Line No.", '<>%1', "Line No.");
        IncomingDocumentAttachment.SetRange("Main Attachment", true);

        if "Main Attachment" and not IncomingDocumentAttachment.IsEmpty() then
            Error(OnlyOneMainAttachmentAllowedErr);
        if not "Main Attachment" and IncomingDocumentAttachment.IsEmpty() then
            Error(MustHaveOneMainAttachmentErr);
    end;

    local procedure SetFirstAttachmentAsDefault()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not Default then begin
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
            IncomingDocumentAttachment.SetRange(Default, true);
            if IncomingDocumentAttachment.IsEmpty() then
                Validate(Default, true);
        end;
    end;

    local procedure SetFirstAttachmentAsMain()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not "Main Attachment" then begin
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Incoming Document Entry No.");
            IncomingDocumentAttachment.SetRange("Main Attachment", true);
            if IncomingDocumentAttachment.IsEmpty() then
                Validate("Main Attachment", true);
        end;
    end;

    procedure SetFiltersFromMainRecord(var MainRecordRef: RecordRef; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        DataTypeManagement: Codeunit "Data Type Management";
        EnumAssignmentMgt: Codeunit "Enum Assignment Management";
        DocumentNoFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
        PostingDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFiltersFromMainRecord(MainRecordRef, IncomingDocumentAttachment, IsHandled);
        if IsHandled then
            exit;

        case MainRecordRef.Number of
            DATABASE::"Incoming Document":
                exit;
            DATABASE::"Sales Header":
                begin
                    MainRecordRef.SetTable(SalesHeader);
                    IncomingDocumentAttachment.SetRange("Document Table No. Filter", MainRecordRef.Number);
                    IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetSalesIncomingDocumentType(SalesHeader."Document Type"));
                    IncomingDocumentAttachment.SetRange("Document No. Filter", SalesHeader."No.");
                end;
            DATABASE::"Purchase Header":
                begin
                    MainRecordRef.SetTable(PurchaseHeader);
                    IncomingDocumentAttachment.SetRange("Document Table No. Filter", MainRecordRef.Number);
                    IncomingDocumentAttachment.SetRange("Document Type Filter", EnumAssignmentMgt.GetPurchIncomingDocumentType(PurchaseHeader."Document Type"));
                    IncomingDocumentAttachment.SetRange("Document No. Filter", PurchaseHeader."No.");
                end;
            DATABASE::"Gen. Journal Line":
                begin
                    MainRecordRef.SetTable(GenJournalLine);
                    IncomingDocumentAttachment.SetRange("Document Table No. Filter", MainRecordRef.Number);
                    IncomingDocumentAttachment.SetRange("Journal Template Name Filter", GenJournalLine."Journal Template Name");
                    IncomingDocumentAttachment.SetRange("Journal Batch Name Filter", GenJournalLine."Journal Batch Name");
                    IncomingDocumentAttachment.SetRange("Journal Line No. Filter", GenJournalLine."Line No.");
                end;
            else begin
                if not DataTypeManagement.FindFieldByName(MainRecordRef, DocumentNoFieldRef, GenJournalLine.FieldName("Document No.")) then
                    if not DataTypeManagement.FindFieldByName(MainRecordRef, DocumentNoFieldRef, PurchInvHeader.FieldName("No.")) then
                        exit;
                if not DataTypeManagement.FindFieldByName(MainRecordRef, PostingDateFieldRef, GenJournalLine.FieldName("Posting Date")) then
                    exit;
                IncomingDocumentAttachment.SetRange("Document No.", Format(DocumentNoFieldRef.Value));
                Evaluate(PostingDate, Format(PostingDateFieldRef.Value));
                IncomingDocumentAttachment.SetRange("Posting Date", PostingDate);
            end;
        end;
    end;

    procedure AddFieldToFieldBuffer(var TempFieldBuffer: Record "Field Buffer" temporary; FieldID: Integer)
    begin
        TempFieldBuffer.Init();
        TempFieldBuffer.Order += 1;
        TempFieldBuffer."Table ID" := DATABASE::"Incoming Document";
        TempFieldBuffer."Field ID" := FieldID;
        TempFieldBuffer.Insert();
    end;

    procedure SendNotifActionCompleted()
    var
        Notification: Notification;
    begin
        Notification.Id := CreateGuid();
        Notification.Message := NotifIncDocCompletedMsg;
        Notification.Scope := NOTIFICATIONSCOPE::LocalScope;
        Notification.Send();
    end;

    procedure SetContentFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Content));
        RecordRef.SetTable(Rec);
    end;

    internal procedure SupportedByFileViewer(): Boolean
    begin
        case Type of
            Type::PDF:
                exit(true);
            Type::" ":
                begin
                    if Rec."File Extension" <> '' then
                        exit(LowerCase(Rec."File Extension") = 'pdf');

                    exit(Lowercase(Rec.Name).EndsWith('pdf'))
                end;
            else
                exit(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnBeforeExtractHeaderFields(var TempFieldBuffer: Record "Field Buffer" temporary; var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExport(var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSetFiltersFromMainRecord(var MainRecordRef: RecordRef; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValueOnExtractHeaderField(var IncomingDocument: Record "Incoming Document"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDataExchType(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImport(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IsImported: Boolean; var IsHandled: Boolean)
    begin
    end;
}
