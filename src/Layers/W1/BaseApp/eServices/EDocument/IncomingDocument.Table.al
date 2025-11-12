// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Archive;
using Microsoft.Purchases.Archive;
using Microsoft.Utilities;
using System;
using System.Automation;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Threading;
using System.Utilities;

table 130 "Incoming Document"
{
    Caption = 'Incoming Document';
    DataCaptionFields = "Vendor Name", "Vendor Invoice No.", Description;
    DrillDownPageID = "Incoming Documents";
    LookupPageID = "Incoming Documents";
    Permissions = TableData "G/L Entry" = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            Editable = false;
        }
        field(4; "Created By User ID"; Guid)
        {
            Caption = 'Created By User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            TableRelation = User;
        }
        field(5; "Created By User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Created By User ID")));
            Caption = 'Created By User Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Released; Boolean)
        {
            Caption = 'Released';
            Editable = false;
        }
        field(7; "Released Date-Time"; DateTime)
        {
            Caption = 'Released Date-Time';
            Editable = false;
        }
        field(8; "Released By User ID"; Guid)
        {
            Caption = 'Released By User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            TableRelation = User;
        }
        field(9; "Released By User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Released By User ID")));
            Caption = 'Released By User Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
            Editable = false;
        }
        field(11; "Last Modified By User ID"; Guid)
        {
            Caption = 'Last Modified By User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            Editable = false;
            TableRelation = User;
        }
        field(12; "Last Modified By User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("Last Modified By User ID")));
            Caption = 'Last Modified By User Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
        field(14; "Posted Date-Time"; DateTime)
        {
            Caption = 'Posted Date-Time';
            Editable = false;
        }
        field(15; "Document Type"; Enum "Incoming Related Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
            InitValue = " ";
        }
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(17; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
            Editable = false;
        }
        field(18; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'New,Released,Rejected,Posted,Created,Failed,Pending Approval';
            OptionMembers = New,Released,Rejected,Posted,Created,Failed,"Pending Approval";
        }
        field(60; URL; Text[1024])
        {
            Caption = 'URL';
            Editable = false;
        }
        field(23; "Vendor Name"; Text[100])
        {
            Caption = 'Vendor Name';
        }
        field(24; "Vendor VAT Registration No."; Text[30])
        {
            Caption = 'Vendor VAT Registration No.';
        }
        field(25; "Vendor IBAN"; Code[50])
        {
            Caption = 'Vendor IBAN';
        }
        field(26; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(27; "Vendor Bank Branch No."; Text[20])
        {
            Caption = 'Vendor Bank Branch No.';
        }
        field(28; "Vendor Bank Account No."; Text[30])
        {
            Caption = 'Vendor Bank Account No.';
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Data Exchange Type"; Code[20])
        {
            Caption = 'Data Exchange Type';
            TableRelation = "Data Exchange Type";
        }
        field(31; "OCR Data Corrected"; Boolean)
        {
            Caption = 'OCR Data Corrected';
            InitValue = false;
        }
        field(32; "OCR Status"; Option)
        {
            Caption = 'OCR Status';
            Editable = false;
            OptionCaption = ' ,Ready,Sent,Error,Success,Awaiting Verification';
            OptionMembers = " ",Ready,Sent,Error,Success,"Awaiting Verification";
        }
        field(33; "OCR Track ID"; Text[20])
        {
            Caption = 'OCR Track ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(38; "OCR Service Doc. Template Code"; Code[20])
        {
            Caption = 'OCR Service Doc. Template Code';
            TableRelation = "OCR Service Document Template";

            trigger OnValidate()
            begin
                CalcFields("OCR Service Doc. Template Name");
            end;
        }
        field(39; "OCR Service Doc. Template Name"; Text[50])
        {
            CalcFormula = lookup("OCR Service Document Template".Name where(Code = field("OCR Service Doc. Template Code")));
            Caption = 'OCR Service Doc. Template Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "OCR Process Finished"; Boolean)
        {
            Caption = 'OCR Process Finished';
        }
        field(41; "Created Doc. Error Msg. Type"; Option)
        {
            Caption = 'Created Doc. Error Msg. Type';
            InitValue = Error;
            OptionCaption = ' ,Error,Warning';
            OptionMembers = " ",Error,Warning;
        }
        field(42; "Vendor Id"; Guid)
        {
            Caption = 'Vendor Id';
            TableRelation = Vendor.SystemId;
        }
        field(50; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';

            trigger OnLookup()
            var
                Currency: Record Currency;
            begin
                if PAGE.RunModal(PAGE::Currencies, Currency) = ACTION::LookupOK then
                    "Currency Code" := Currency.Code;
            end;

            trigger OnValidate()
            var
                GeneralLedgerSetup: Record "General Ledger Setup";
                Currency: Record Currency;
            begin
                GeneralLedgerSetup.Get();
                if (not Currency.Get("Currency Code")) and ("Currency Code" <> '') and ("Currency Code" <> GeneralLedgerSetup."LCY Code") then
                    Error(InvalidCurrencyCodeErr);
            end;
        }
        field(51; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Excl. VAT';
        }
        field(52; "Amount Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Incl. VAT';
        }
        field(53; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(54; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(55; "Vendor Invoice No."; Code[35])
        {
            Caption = 'Vendor Invoice No.';
        }
        field(56; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(57; "Vendor Phone No."; Text[30])
        {
            Caption = 'Vendor Phone No.';
        }
        field(58; "Related Record ID"; RecordID)
        {
            Caption = 'Related Record ID';
            DataClassification = CustomerContent;
        }
        field(160; "Job Queue Status"; Enum "Inc. Doc. Job Queue Status")
        {
            Caption = 'Job Queue Status';
            Editable = false;

            trigger OnLookup()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if Rec."Job Queue Status" = Rec."Job Queue Status"::" " then
                    exit;
                JobQueueEntry.ShowStatusMsg(Rec."Job Queue Entry ID");
            end;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(162; Processed; Boolean)
        {
            Caption = 'Processed';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
        key(Key4; "OCR Status")
        {
        }
        key(Key5; "Vendor No.")
        {
        }
        key(Key6; Processed)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Created Date-Time", Description, "Amount Incl. VAT", Status, "Currency Code")
        {
        }
    }

    trigger OnDelete()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ActivityLog: Record "Activity Log";
    begin
        TestField(Posted, false);

        DeleteApprovalEntries();
        ClearRelatedRecords();

        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        if not IncomingDocumentAttachment.IsEmpty() then
            IncomingDocumentAttachment.DeleteAll();

        ActivityLog.SetRange("Record ID", Rec.RecordId);
        if not ActivityLog.IsEmpty() then
            ActivityLog.DeleteAll();

        ClearErrorMessages();
    end;

    trigger OnInsert()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if OCRServiceSetup.Get() then;
        "Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        "Created By User ID" := UserSecurityId();
        if "OCR Service Doc. Template Code" = '' then
            "OCR Service Doc. Template Code" := OCRServiceSetup."Default OCR Doc. Template";
    end;

    trigger OnModify()
    begin
        "Last Date-Time Modified" := RoundDateTime(CurrentDateTime, 60000);
        "Last Modified By User ID" := UserSecurityId();
    end;

    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        TempErrorMessage: Record "Error Message" temporary;
        DocumentType: Option Invoice,"Credit Memo";

        UrlTooLongErr: Label 'Only URLs with a maximum of %1 characters are allowed.', Comment = '%1 = length of the URL field (e.g. 1024).';
        NoDocumentMsg: Label 'There is no incoming document for this combination of posting date and document number.';
        AlreadyUsedInJnlErr: Label 'The incoming document has already been assigned to journal batch %1, line number. %2.', Comment = '%1 = journal batch name, %2=line number.';
        AlreadyUsedInDocHdrErr: Label 'The incoming document has already been assigned to %1 %2 (%3).', Comment = '%1=document type, %2=document number, %3=table name, e.g. Sales Header.';
        DocPostedErr: Label 'The document related to this incoming document has been posted.';
        DocApprovedErr: Label 'This incoming document requires releasing.';
#pragma warning disable AA0470
        DetachQst: Label 'Do you want to remove the reference from this incoming document to posted document %1, posting date %2?';
#pragma warning restore AA0470
        NotSupportedPurchErr: Label 'Purchase documents of type %1 are not supported.', Comment = '%1 will be Sales/Purchase Header. %2 will be invoice, Credit Memo.';
        NotSupportedSalesErr: Label 'Sales documents of type %1 are not supported.', Comment = '%1 will be Sales/Purchase Header. %2 will be invoice, Credit Memo.';
        EntityNotFoundErr: Label 'Cannot create the document. Make sure the data exchange definition is correct.';
        DocAlreadyCreatedErr: Label 'The document has already been created.';
        DocNotCreatedMsg: Label 'The document was not created due to errors in the conversion process.';
        DocCreatedMsg: Label '%1 %2 has been created.', Comment = '%1 can be Purchase Invoice, %2 is an ID (e.g. 1001)';
        DocCreatedWarningsMsg: Label '%1 %2 has been created with warnings.', Comment = '%1 can be Purchase Invoice, %2 is an ID (e.g. 1001)';
        RemovePostedRecordManuallyMsg: Label 'The reference to the posted record has been removed.\\Remember to correct the posted record if needed.';
        DeleteRecordQst: Label 'The reference to the record has been removed.\\Do you want to delete the record?';
        DocWhenApprovalIsCompleteErr: Label 'The document can only be created when the approval process is complete.';
        InvalidCurrencyCodeErr: Label 'You must enter a valid currency code.';
        ReplaceMainAttachmentQst: Label 'Are you sure you want to replace the attached file?';
        PurchaseTxt: Label 'Purchase';
        SalesTxt: Label 'Sales';
        PurchaseInvoiceTxt: Label 'Purchase Invoice';
        PurchaseCreditMemoTxt: Label 'Purchase Credit Memo';
        SalesInvoiceTxt: Label 'Sales Invoice';
        SalesCreditMemoTxt: Label 'Sales Credit Memo';
        JournalTxt: Label 'Journal';
        DoYouWantToRemoveReferenceQst: Label 'Do you want to remove the reference?';
        DataExchangeTypeEmptyErr: Label 'You must select a value in the Data Exchange Type field on the incoming document.';
        NoDocAttachErr: Label 'No document is attached.\\Attach a document, and then try again.';
        GeneralLedgerEntriesTxt: Label 'General Ledger Entries';
        CannotReplaceMainAttachmentErr: Label 'Cannot replace the main attachment because the document has already been sent to OCR.';

    procedure GetURL(): Text
    begin
        exit(URL);
    end;

    procedure SetURL(NewURL: Text)
    begin
        TestField(Status, Status::New);
        TestField(Posted, false);

        if StrLen(NewURL) > MaxStrLen(URL) then
            Error(UrlTooLongErr, MaxStrLen(URL));

        URL := NewURL;
    end;

    local procedure DeleteApprovalEntries()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteApprovalEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.DeleteApprovalEntries(Rec.RecordId);
    end;

    [Scope('OnPrem')]
    procedure Release()
    var
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        ReleaseIncomingDocument.PerformManualRelease(Rec);
    end;

    procedure Reject()
    var
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        ReleaseIncomingDocument.PerformManualReject(Rec);
    end;

    procedure CheckNotCreated()
    begin
        if Status = Status::Created then
            Error(DocAlreadyCreatedErr);
    end;

    procedure CreateDocumentWithDataExchange()
    var
        RelatedRecord: Variant;
    begin
        if GetRecord(RelatedRecord) then
            Error(DocAlreadyCreatedErr);

        CreateWithDataExchange("Document Type"::" ")
    end;

    procedure TryCreateDocumentWithDataExchange()
    begin
        CreateDocumentWithDataExchange();
    end;

    procedure CreateReleasedDocumentWithDataExchange()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        RecordRef: RecordRef;
        Variant: Variant;
    begin
        CreateWithDataExchange("Document Type"::" ");
        GetRecord(Variant);
        RecordRef.GetTable(Variant);
        if RecordRef.Number <> Database::"Purchase Header" then
            exit;
        RecordRef.SetTable(PurchaseHeader);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
    end;

    local procedure CreateWithDataExchange(DocumentType: Enum "Incoming Related Document Type")
    var
        ErrorMessage: Record "Error Message";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
        OldStatus: Option;
    begin
        Find();

        if ApprovalsMgmt.IsIncomingDocApprovalsWorkflowEnabled(Rec) and (Status = Status::New) then
            Error(DocWhenApprovalIsCompleteErr);

        OnCheckIncomingDocCreateDocRestrictions();

        if "Data Exchange Type" = '' then
            Error(DataExchangeTypeEmptyErr);

        "Document Type" := DocumentType;
        Modify();

        ClearErrorMessages();
        TestReadyForProcessing();

        CheckNotCreated();

        if Status in [Status::New, Status::Failed] then begin
            OldStatus := Status;
            CODEUNIT.Run(CODEUNIT::"Release Incoming Document", Rec);
            TestField(Status, Status::Released);
            Status := OldStatus;
            Modify();
        end;

        Commit();
        if not CODEUNIT.Run(CODEUNIT::"Incoming Doc. with Data. Exch.", Rec) then begin
            ErrorMessage.CopyFromTemp(TempErrorMessage);
            SetProcessFailed('');
            exit;
        end;

        ErrorMessage.SetContext(Rec.RecordId);
        if ErrorMessage.HasErrors(false) then begin
            SetProcessFailed('');
            exit;
        end;

        // identify the created doc
        if not UpdateDocumentFields() then begin
            SetProcessFailed('');
            exit;
        end;

        ReleaseIncomingDocument.Create(Rec);

        ShowResultMessage(ErrorMessage);
    end;

    local procedure ShowResultMessage(var ErrorMessage: Record "Error Message")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResultMessage(Rec, ErrorMessage, IsHandled);
        if IsHandled then
            exit;

        if ErrorMessage.ErrorMessageCount(ErrorMessage."Message Type"::Warning) > 0 then
            Message(DocCreatedWarningsMsg, Format("Document Type"), "Document No.")
        else
            Message(DocCreatedMsg, Format("Document Type"), "Document No.");
    end;

    procedure CreateManually()
    var
        RelatedRecord: Variant;
        DocumentTypeOption, DocumentTypeEnum : Integer;
        IsHandled: Boolean;
        CreatedDocumentType: Dictionary of [Integer, Integer];
        CreatedDocumentStrMenu: Text;
    begin
        IsHandled := false;
        OnBeforeCreateManually(Rec, IsHandled);
        if IsHandled then
            exit;

        if GetRecord(RelatedRecord) then
            Error(DocAlreadyCreatedErr);

        CreatedDocumentType.Add(1, "Document Type"::Journal.AsInteger());
        CreatedDocumentType.Add(2, "Document Type"::"Sales Invoice".AsInteger());
        CreatedDocumentType.Add(3, "Document Type"::"Sales Credit Memo".AsInteger());
        CreatedDocumentType.Add(4, "Document Type"::"Purchase Invoice".AsInteger());
        CreatedDocumentType.Add(5, "Document Type"::"Purchase Credit Memo".AsInteger());
        CreatedDocumentStrMenu := StrSubstNo('%1,%2,%3,%4,%5', JournalTxt, SalesInvoiceTxt, SalesCreditMemoTxt, PurchaseInvoiceTxt, PurchaseCreditMemoTxt);
        OnAfterSetCreatedDocumentType(CreatedDocumentType, CreatedDocumentStrMenu);

        DocumentTypeOption := StrMenu(CreatedDocumentStrMenu, 1);
        if DocumentTypeOption < 1 then
            exit;

        DocumentTypeEnum := CreatedDocumentType.Get(DocumentTypeOption);
        case DocumentTypeEnum of
            "Document Type"::"Purchase Invoice".AsInteger():
                CreatePurchInvoice();
            "Document Type"::"Purchase Credit Memo".AsInteger():
                CreatePurchCreditMemo();
            "Document Type"::"Sales Invoice".AsInteger():
                CreateSalesInvoice();
            "Document Type"::"Sales Credit Memo".AsInteger():
                CreateSalesCreditMemo();
            "Document Type"::Journal.AsInteger():
                CreateGenJnlLine();
            else
                OnAfterCreateDocumentType(Rec, DocumentTypeEnum);
        end;

        OnAfterCreateManually(Rec);
    end;

    procedure CreateGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        LastGenJnlLine: Record "Gen. Journal Line";
        LineNo: Integer;
        JournalTemplate: Code[10];
        JournalBatch: Code[10];
        IsHandled: Boolean;
    begin
        if "Document Type" <> "Document Type"::Journal then
            TestIfAlreadyExists();
        TestReadyForProcessing();
        OnBeforeGetJournalTemplateAndBatch(JournalTemplate, JournalBatch, IsHandled);
        if not IsHandled then begin
            IncomingDocumentsSetup.TestField("General Journal Template Name");
            IncomingDocumentsSetup.TestField("General Journal Batch Name");
            JournalTemplate := IncomingDocumentsSetup."General Journal Template Name";
            JournalBatch := IncomingDocumentsSetup."General Journal Batch Name";
        end;
        GenJnlLine.SetRange("Journal Template Name", JournalTemplate);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatch);
        GenJnlLine.SetRange("Incoming Document Entry No.", "Entry No.");
        if not GenJnlLine.IsEmpty() then
            exit; // instead; go to the document

        GenJnlLine.SetRange("Incoming Document Entry No.");

        "Document Type" := "Document Type"::Journal;

        if GenJnlLine.FindLast() then;
        LastGenJnlLine := GenJnlLine;
        LineNo := GenJnlLine."Line No." + 10000;
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := JournalTemplate;
        GenJnlLine."Journal Batch Name" := JournalBatch;
        GenJnlLine."Line No." := LineNo;
        GenJnlLine.SetUpNewLine(LastGenJnlLine, 0, true);
        GenJnlLine."Incoming Document Entry No." := "Entry No.";
        GenJnlLine.Description := CopyStr(Description, 1, MaxStrLen(GenJnlLine.Description));

        OnCreateGenJnlLineOnBeforeGenJnlLineInsert(GenJnlLine, LastGenJnlLine);
        if GenJnlLine.Insert(true) then
            OnAfterCreateGenJnlLineFromIncomingDocSuccess(Rec)
        else
            OnAfterCreateGenJnlLineFromIncomingDocFail(Rec);

        if GenJnlLine.HasLinks then
            GenJnlLine.DeleteLinks();
        if GetURL() <> '' then
            GenJnlLine.AddLink(GetURL(), Description);

        IsHandled := false;
        OnCreateGenJnlLineOnBeforeShowRecord(Rec, IsHandled);
        if not IsHandled then
            ShowRecord();
    end;

    procedure CreatePurchInvoice()
    begin
        if "Document Type" <> "Document Type"::"Purchase Invoice" then
            TestIfAlreadyExists();

        "Document Type" := "Document Type"::"Purchase Invoice";
        CreatePurchDoc(DocumentType::Invoice);
    end;

    procedure CreatePurchCreditMemo()
    begin
        if "Document Type" <> "Document Type"::"Purchase Credit Memo" then
            TestIfAlreadyExists();

        "Document Type" := "Document Type"::"Purchase Credit Memo";
        CreatePurchDoc(DocumentType::"Credit Memo");
    end;

    procedure CreateSalesInvoice()
    begin
        if "Document Type" <> "Document Type"::"Sales Invoice" then
            TestIfAlreadyExists();

        "Document Type" := "Document Type"::"Sales Invoice";
        CreateSalesDoc(DocumentType::Invoice);
    end;

    procedure CreateSalesCreditMemo()
    begin
        if "Document Type" <> "Document Type"::"Sales Credit Memo" then
            TestIfAlreadyExists();

        "Document Type" := "Document Type"::"Sales Credit Memo";
        CreateSalesDoc(DocumentType::"Credit Memo");
    end;

    [Scope('OnPrem')]
    procedure CreateGeneralJournalLineWithDataExchange()
    var
        ErrorMessage: Record "Error Message";
        RelatedRecord: Variant;
    begin
        if GetRecord(RelatedRecord) then
            Error(DocAlreadyCreatedErr);

        CreateWithDataExchange("Document Type"::Journal);

        ErrorMessage.SetContext(Rec.RecordId);
        if not ErrorMessage.HasErrors(false) then
            OnAfterCreateGenJnlLineFromIncomingDocSuccess(Rec)
        else
            OnAfterCreateGenJnlLineFromIncomingDocFail(Rec);
    end;

    [Scope('OnPrem')]
    procedure TryCreateGeneralJournalLineWithDataExchange()
    begin
        CreateGeneralJournalLineWithDataExchange();
    end;

    procedure RemoveReferenceToWorkingDocument(EntryNo: Integer)
    begin
        if EntryNo = 0 then
            exit;
        if not Get(EntryNo) then
            exit;

        TestField(Posted, false);

        "Document Type" := "Document Type"::" ";
        "Document No." := '';
        // To clear the filters and prevent the page from putting values back
        SetRange("Document Type");
        SetRange("Document No.");

        if Released then
            Status := Status::Released
        else
            Status := Status::New;

        ClearErrorMessages();
        "Created Doc. Error Msg. Type" := "Created Doc. Error Msg. Type"::Error;

        OnRemoveReferenceToWorkingDocumentOnBeforeModify(Rec);
        Modify();
    end;

    procedure RemoveIncomingDocumentEntryNoFromUnpostedDocument()
    var
        SalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        RelatedRecordRecordRef: RecordRef;
        RelatedRecordFieldRef: FieldRef;
        RelatedRecordVariant: Variant;
    begin
        if not GetUnpostedRecord(RelatedRecordVariant) then
            exit;
        RelatedRecordRecordRef.GetTable(RelatedRecordVariant);
        DataTypeManagement.FindFieldByName(
          RelatedRecordRecordRef, RelatedRecordFieldRef, SalesHeader.FieldName("Incoming Document Entry No."));
        RelatedRecordFieldRef.Value := 0;
        RelatedRecordRecordRef.Modify(true);
    end;

    procedure CreateIncomingDocument(NewDescription: Text; NewURL: Text): Integer
    begin
        Reset();
        Clear(Rec);
        Init();
        Description := CopyStr(NewDescription, 1, MaxStrLen(Description));
        SetURL(NewURL);
        Insert(true);
        exit("Entry No.");
    end;

    procedure CreateIncomingDocument(PictureInStream: InStream; FileName: Text)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileManagement: Codeunit "File Management";
    begin
        IncomingDocument.CopyFilters(Rec);
        CreateIncomingDocument(FileManagement.GetFileNameWithoutExtension(FileName), '');
        AddAttachmentFromStream(IncomingDocumentAttachment, FileName, FileManagement.GetExtension(FileName), PictureInStream);
        CopyFilters(IncomingDocument);
    end;

    procedure TestIfAlreadyExists()
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestIfAlreadyExists(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Journal:
                begin
                    GenJnlLine.SetRange("Incoming Document Entry No.", "Entry No.");
                    if GenJnlLine.FindFirst() then
                        Error(AlreadyUsedInJnlErr, GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
                end;
            "Document Type"::"Sales Invoice", "Document Type"::"Sales Credit Memo":
                begin
                    SalesHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    if SalesHeader.FindFirst() then
                        Error(AlreadyUsedInDocHdrErr, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.TableCaption());
                end;
            "Document Type"::"Purchase Invoice", "Document Type"::"Purchase Credit Memo":
                begin
                    PurchaseHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    if PurchaseHeader.FindFirst() then
                        Error(AlreadyUsedInDocHdrErr, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseHeader.TableCaption());
                end;
            else
                OnTestIfAlreadyExists("Document Type", "Entry No.");
        end;
    end;

    procedure TestReadyForProcessing()
    begin
        TestReadyForProcessingForcePosted(false);
    end;

    local procedure TestReadyForProcessingForcePosted(ForcePosted: Boolean)
    begin
        if not ForcePosted and Posted then
            Error(DocPostedErr);

        IncomingDocumentsSetup.Fetch();
        if IncomingDocumentsSetup."Require Approval To Create" and (not Released) then
            Error(DocApprovedErr);
    end;

    procedure PostedDocExists(DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        SetRange(Posted, true);
        SetRange("Document No.", DocumentNo);
        SetRange("Posting Date", PostingDate);
        exit(not IsEmpty);
    end;

    procedure GetRelatedDocType(PostingDate: Date; DocNo: Code[20]; var IsPosted: Boolean): Enum "Incoming Related Document Type"
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLEntry: Record "G/L Entry";
        IncomingRelatedDocumentType: Enum "Incoming Related Document Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRelatedDocType(PostingDate, DocNo, IsPosted, IncomingRelatedDocumentType, IsHandled);
        if IsHandled then
            exit(IncomingRelatedDocumentType);

        IsPosted := true;
        case true of
            ((PostingDate = 0D) or (DocNo = '')):
                exit("Document Type"::" ");
            PurchInvHeader.Get(DocNo):
                if PurchInvHeader."Posting Date" = PostingDate then
                    exit("Document Type"::"Purchase Invoice");
            PurchCrMemoHdr.Get(DocNo):
                if PurchCrMemoHdr."Posting Date" = PostingDate then
                    exit("Document Type"::"Purchase Credit Memo");
            SalesInvoiceHeader.Get(DocNo):
                if SalesInvoiceHeader."Posting Date" = PostingDate then
                    exit("Document Type"::"Sales Invoice");
            SalesCrMemoHeader.Get(DocNo):
                if SalesCrMemoHeader."Posting Date" = PostingDate then
                    exit("Document Type"::"Sales Credit Memo");
            else
                GLEntry.SetRange("Posting Date", PostingDate);
                GLEntry.SetRange("Document No.", DocNo);
                IsPosted := not GLEntry.IsEmpty();
                exit("Document Type"::Journal);
        end;
        IsPosted := false;
        exit("Document Type"::" ");
    end;

    procedure SetPostedDocFields(PostingDate: Date; DocNo: Code[20])
    begin
        SetPostedDocFieldsForcePosted(PostingDate, DocNo, false);
    end;

    procedure SetPostedDocFieldsForcePosted(PostingDate: Date; DocNo: Code[20]; ForcePosted: Boolean)
    var
        CurrIncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachmentCopy: Record "Incoming Document Attachment";
        RelatedRecordRef: RecordRef;
        RelatedRecord: Variant;
    begin
        TestReadyForProcessingForcePosted(ForcePosted);
        if Posted then begin
            CurrIncomingDocument.CreateIncomingDocument('', '');
            CurrIncomingDocument.TransferFields(Rec, false);
            CurrIncomingDocument.Modify();
        end;
        Posted := true;
        Status := Status::Posted;
        Processed := true;
        "Posted Date-Time" := CurrentDateTime;
        "Document No." := DocNo;
        "Posting Date" := PostingDate;
        if FindPostedRecord(RelatedRecord) then begin
            RelatedRecordRef.GetTable(RelatedRecord);
            "Related Record ID" := RelatedRecordRef.RecordId;
        end;
        ClearErrorMessages();
        Modify(true);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        if not IncomingDocumentAttachment.Findset() then
            exit;

        repeat
            if CurrIncomingDocument."Entry No." <> 0 then begin
                IncomingDocumentAttachmentCopy := IncomingDocumentAttachment;
                IncomingDocumentAttachmentCopy."Incoming Document Entry No." := CurrIncomingDocument."Entry No.";
                IncomingDocumentAttachmentCopy.Insert();
            end;
            IncomingDocumentAttachment."Document No." := "Document No.";
            IncomingDocumentAttachment."Posting Date" := "Posting Date";
            IncomingDocumentAttachment.Modify();
        until IncomingDocumentAttachment.Next() = 0;
    end;

    procedure UndoPostedDocFields()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DummyRecordID: RecordID;
    begin
        if "Entry No." = 0 then
            exit;
        if not Posted then
            exit;
        if not Confirm(StrSubstNo(DetachQst, "Document No.", "Posting Date"), false) then
            exit;
        Posted := false;
        Processed := false;
        Status := Status::Released;
        "Posted Date-Time" := 0DT;
        "Related Record ID" := DummyRecordID;
        "Document No." := '';
        "Document Type" := "Document Type"::" ";
        "Posting Date" := 0D;

        // To clear the filters and prevent the page from putting values back
        SetRange("Posted Date-Time");
        SetRange("Document No.");
        SetRange("Document Type");
        SetRange("Posting Date");

        Modify(true);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.ModifyAll("Document No.", "Document No.");
        IncomingDocumentAttachment.ModifyAll("Posting Date", "Posting Date");

        Message(RemovePostedRecordManuallyMsg);
    end;

    procedure UpdateIncomingDocumentFromPosting(IncomingDocumentNo: Integer; PostingDate: Date; DocNo: Code[20])
    var
        IncomingDocument: Record "Incoming Document";
        IsHandled: Boolean;
    begin
        if IncomingDocumentNo = 0 then
            exit;

        if not IncomingDocument.Get(IncomingDocumentNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateIncomingDocumentFromPosting(IncomingDocumentNo, PostingDate, DocNo, IsHandled);
        if IsHandled then
            exit;

        IncomingDocument.SetPostedDocFieldsForcePosted(PostingDate, DocNo, true);
        IncomingDocument.Modify();
    end;

    local procedure ClearRelatedRecords()
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        case "Document Type" of
            "Document Type"::Journal:
                begin
                    GenJnlLine.SetRange("Incoming Document Entry No.", "Entry No.");
                    GenJnlLine.ModifyAll("Incoming Document Entry No.", 0, true);
                end;
            "Document Type"::"Sales Invoice", "Document Type"::"Sales Credit Memo":
                begin
                    SalesHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    SalesHeader.ModifyAll("Incoming Document Entry No.", 0, true);

                    SalesHeaderArchive.SetRange("Incoming Document Entry No.", "Entry No.");
                    if not SalesHeaderArchive.IsEmpty() then
                        SalesHeaderArchive.ModifyAll("Incoming Document Entry No.", 0, true);
                end;
            "Document Type"::"Purchase Invoice", "Document Type"::"Purchase Credit Memo":
                begin
                    PurchaseHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    PurchaseHeader.ModifyAll("Incoming Document Entry No.", 0, true);

                    PurchaseHeaderArchive.SetRange("Incoming Document Entry No.", "Entry No.");
                    if not PurchaseHeaderArchive.IsEmpty() then
                        PurchaseHeaderArchive.ModifyAll("Incoming Document Entry No.", 0, true);
                end;
            else
                OnAfterClearRelatedRecords("Document Type", "Entry No.");
        end;
    end;

    local procedure CreateSalesDoc(DocType: Option)
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        TestReadyForProcessing();
        SalesHeader.SetRange("Incoming Document Entry No.", "Entry No.");
        if not SalesHeader.IsEmpty() then begin
            ShowRecord();
            exit;
        end;
        SalesHeader.Reset();
        SalesHeader.Init();
        case DocType of
            DocumentType::Invoice:
                SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
            DocumentType::"Credit Memo":
                SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        end;
        OnBeforeCreateSalesHeaderFromIncomingDoc(SalesHeader);
        SalesHeader.Insert(true);
        OnAfterCreateSalesHeaderFromIncomingDoc(SalesHeader);
        if GetURL() <> '' then
            SalesHeader.AddLink(GetURL(), Description);
        SalesHeader."Incoming Document Entry No." := "Entry No.";
        SalesHeader.Modify();
        OnCreateSalesDocOnAfterModifySalesHeader(Rec, SalesHeader);
        "Document No." := SalesHeader."No.";
        Modify(true);
        Commit();

        IsHandled := false;
        OnCreateSalesDocOnBeforeShowRecord(Rec, IsHandled);
        if not IsHandled then
            ShowRecord();
    end;

    local procedure CreatePurchDoc(DocType: Option)
    var
        PurchHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        TestReadyForProcessing();
        PurchHeader.SetRange("Incoming Document Entry No.", "Entry No.");
        if not PurchHeader.IsEmpty() then begin
            ShowRecord();
            exit;
        end;
        PurchHeader.Reset();
        PurchHeader.Init();
        case DocType of
            DocumentType::Invoice:
                PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
            DocumentType::"Credit Memo":
                PurchHeader."Document Type" := PurchHeader."Document Type"::"Credit Memo";
        end;
        OnCreatePurchDocOnBeforePurchHeaderInsert(PurchHeader);
        PurchHeader.Insert(true);
        OnAfterCreatePurchHeaderFromIncomingDoc(PurchHeader);
        if GetURL() <> '' then
            PurchHeader.AddLink(GetURL(), Description);
        PurchHeader."Incoming Document Entry No." := "Entry No.";
        PurchHeader.Modify();
        OnCreatePurchDocOnAfterModifyPurchaseHeader(Rec, PurchHeader);
        "Document No." := PurchHeader."No.";
        Modify(true);
        Commit();

        IsHandled := false;
        OnCreatePurchDocOnBeforeShowRecord(Rec, IsHandled);
        if not IsHandled then
            ShowRecord();
    end;

    procedure SetGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Incoming Document Entry No." = 0 then
            exit;
        Get(GenJnlLine."Incoming Document Entry No.");
        TestReadyForProcessing();
        TestIfAlreadyExists();
        "Document Type" := "Document Type"::Journal;
        Modify(true);
        if not DocLinkExists(GenJnlLine) then
            GenJnlLine.AddLink(GetURL(), Description);
    end;

    procedure SetSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Incoming Document Entry No." = 0 then
            exit;
        Get(SalesHeader."Incoming Document Entry No.");
        TestReadyForProcessing();
        TestIfAlreadyExists();
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Invoice:
                "Document Type" := "Document Type"::"Sales Invoice";
            SalesHeader."Document Type"::"Credit Memo":
                "Document Type" := "Document Type"::"Sales Credit Memo";
        end;
        Modify();
        if not DocLinkExists(SalesHeader) then
            SalesHeader.AddLink(GetURL(), Description);
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit ServDocExchangeMgt', '25.0')]
    procedure SetServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServDocExchangeMgt: Codeunit "Serv. Doc. Exchange Mgt.";
    begin
        ServDocExchangeMgt.SetServiceDoc(ServiceHeader, Rec);
    end;
#endif

    procedure SetPurchDoc(var PurchaseHeader: Record "Purchase Header")
    begin
        if PurchaseHeader."Incoming Document Entry No." = 0 then
            exit;
        Get(PurchaseHeader."Incoming Document Entry No.");
        TestReadyForProcessing();
        TestIfAlreadyExists();
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Invoice:
                "Document Type" := "Document Type"::"Purchase Invoice";
            PurchaseHeader."Document Type"::"Credit Memo":
                "Document Type" := "Document Type"::"Purchase Credit Memo";
        end;
        Modify();
        if not DocLinkExists(PurchaseHeader) then
            PurchaseHeader.AddLink(GetURL(), Description);
    end;

    procedure DocLinkExists(RecVar: Variant): Boolean
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        if GetURL() = '' then
            exit(true);
        RecRef.GetTable(RecVar);
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.SetRange(URL1, URL);
        RecordLink.SetRange(Description, Description);
        exit(not RecordLink.IsEmpty);
    end;

    procedure HyperlinkToDocument(DocumentNo: Code[20]; PostingDate: Date)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if ForwardToExistingLink(DocumentNo, PostingDate) then
            exit;
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.SetFilter(Type, '<>%1', IncomingDocumentAttachment.Type::XML);
        if IncomingDocumentAttachment.FindFirst() then
            IncomingDocumentAttachment.Export('', true);
    end;

    procedure ForwardToExistingLink(DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        SetRange("Document No.", DocumentNo);
        SetRange("Posting Date", PostingDate);
        if not FindFirst() then begin
            Message(NoDocumentMsg);
            exit(true);
        end;
        if GetURL() <> '' then begin
            HyperLink(GetURL());
            exit(true);
        end;
    end;

    procedure ShowCard(DocumentNo: Code[20]; PostingDate: Date)
    begin
        SetRange("Document No.", DocumentNo);
        SetRange("Posting Date", PostingDate);
        if not FindFirst() then
            exit;
        SetRecFilter();
        PAGE.Run(PAGE::"Incoming Document", Rec);
    end;

    procedure ShowCardFromEntryNo(EntryNo: Integer)
    begin
        if EntryNo = 0 then
            exit;
        Get(EntryNo);
        SetRecFilter();
        PAGE.Run(PAGE::"Incoming Document", Rec);
    end;

    procedure ImportAttachment(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.NewAttachment();
        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.")
    end;

    [Scope('OnPrem')]
    procedure AddXmlAttachmentFromXmlText(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; OrgFileName: Text; XmlText: Text)
    var
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TestField("Entry No.");
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        if not IncomingDocumentAttachment.FindLast() then
            IncomingDocumentAttachment."Line No." := 10000
        else
            IncomingDocumentAttachment."Line No." += 10000;
        IncomingDocumentAttachment."Incoming Document Entry No." := "Entry No.";
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.Name :=
          CopyStr(FileManagement.GetFileNameWithoutExtension(OrgFileName), 1, MaxStrLen(IncomingDocumentAttachment.Name));
        IncomingDocumentAttachment.Validate("File Extension", 'xml');
        IncomingDocumentAttachment.Content.CreateOutStream(OutStr, TEXTENCODING::UTF8);
        OutStr.WriteText(XmlText);
        IncomingDocumentAttachment.Insert(true);
        if IncomingDocumentAttachment.Type in [IncomingDocumentAttachment.Type::Image, IncomingDocumentAttachment.Type::PDF] then
            IncomingDocumentAttachment.OnAttachBinaryFile();
    end;

    procedure AddAttachmentFromStream(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; OrgFileName: Text; FileExtension: Text; var InStr: InStream)
    var
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
    begin
        TestField("Entry No.");
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        if not IncomingDocumentAttachment.FindLast() then
            IncomingDocumentAttachment."Line No." := 10000
        else
            IncomingDocumentAttachment."Line No." += 10000;
        IncomingDocumentAttachment."Incoming Document Entry No." := "Entry No.";
        IncomingDocumentAttachment.Init();
        IncomingDocumentAttachment.Name :=
          CopyStr(FileManagement.GetFileNameWithoutExtension(OrgFileName), 1, MaxStrLen(IncomingDocumentAttachment.Name));
        IncomingDocumentAttachment.Validate(
          "File Extension", CopyStr(FileExtension, 1, MaxStrLen(IncomingDocumentAttachment."File Extension")));
        IncomingDocumentAttachment.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        IncomingDocumentAttachment.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure AddAttachmentFromServerFile(FileName: Text; FilePath: Text)
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileManagement: Codeunit "File Management";
        File: File;
        InStr: InStream;
    begin
        if (FileName = '') or (FilePath = '') then
            exit;
        if not File.Open(FilePath) then
            exit;
        File.CreateInStream(InStr);
        AddAttachmentFromStream(IncomingDocumentAttachment, FileName, FileManagement.GetExtension(FileName), InStr);
        File.Close();
        if Erase(FilePath) then;
    end;

    local procedure SetProcessFailed(ErrorMsg: Text[2048])
    var
        ErrorMessage: Record "Error Message";
        ReleaseIncomingDocument: Codeunit "Release Incoming Document";
    begin
        ReleaseIncomingDocument.Fail(Rec);

        if ErrorMsg = '' then begin
            ErrorMsg := CopyStr(GetLastErrorText, 1, MaxStrLen(ErrorMessage."Message"));
            ClearLastError();
        end;

        if ErrorMsg <> '' then begin
            ErrorMessage.SetContext(Rec.RecordId);
            ErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, ErrorMsg);
        end;

        if GuiAllowed then
            Message(DocNotCreatedMsg);
    end;

    [TryFunction]
    local procedure UpdateDocumentFields()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocExists: Boolean;
    begin
        // If purchase
        PurchaseHeader.SetRange("Incoming Document Entry No.", "Entry No.");
        if PurchaseHeader.FindFirst() then begin
            case PurchaseHeader."Document Type" of
                PurchaseHeader."Document Type"::Invoice:
                    "Document Type" := "Document Type"::"Purchase Invoice";
                PurchaseHeader."Document Type"::"Credit Memo":
                    "Document Type" := "Document Type"::"Purchase Credit Memo";
                else
                    Error(NotSupportedPurchErr, Format(PurchaseHeader."Document Type"));
            end;
            "Document No." := PurchaseHeader."No.";
            exit;
        end;

        // If sales
        SalesHeader.SetRange("Incoming Document Entry No.", "Entry No.");
        if SalesHeader.FindFirst() then begin
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Invoice:
                    "Document Type" := "Document Type"::"Sales Invoice";
                SalesHeader."Document Type"::"Credit Memo":
                    "Document Type" := "Document Type"::"Sales Credit Memo";
                else
                    Error(NotSupportedSalesErr, Format(SalesHeader."Document Type"));
            end;
            "Document No." := SalesHeader."No.";
            exit;
        end;

        OnUpdateDocumentFieldsOnAfterUpdateDocuments(Rec, DocExists);
        if DocExists then
            exit;

        // If general journal line
        GenJournalLine.SetRange("Incoming Document Entry No.", "Entry No.");
        if GenJournalLine.FindFirst() then begin
            "Document No." := GenJournalLine."Document No.";
            exit;
        end;

        DocExists := false;
        OnAfterUpdateDocumentFields(Rec, DocExists);
        if not DocExists then
            Error(EntityNotFoundErr);
    end;

    local procedure ClearErrorMessages()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        ErrorMessage.DeleteAll();
        TempErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        TempErrorMessage.DeleteAll();
    end;

    procedure SelectIncomingDocument(EntryNo: Integer; RelatedRecordID: RecordID): Integer
    var
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        IncomingDocument: Record "Incoming Document";
        IncomingDocuments: Page "Incoming Documents";
    begin
        if EntryNo <> 0 then begin
            IncomingDocument.Get(EntryNo);
            IncomingDocuments.SetRecord(IncomingDocument);
        end;
        if IncomingDocumentsSetup.Get() then
            if IncomingDocumentsSetup."Require Approval To Create" then
                IncomingDocument.SetRange(Released, true);
        IncomingDocument.SetRange(Posted, false);
        IncomingDocuments.SetTableView(IncomingDocument);
        IncomingDocuments.LookupMode := true;
        if IncomingDocuments.RunModal() = ACTION::LookupOK then begin
            IncomingDocuments.GetRecord(IncomingDocument);
            IncomingDocument.Validate("Related Record ID", RelatedRecordID);
            IncomingDocument.Modify();
            exit(IncomingDocument."Entry No.");
        end;
        exit(EntryNo);
    end;

    procedure SelectIncomingDocumentForPostedDocument(DocumentNo: Code[20]; PostingDate: Date; RelatedRecordID: RecordID)
    var
        IncomingDocument: Record "Incoming Document";
        EntryNo: Integer;
        IsPosted: Boolean;
    begin
        if (DocumentNo = '') or (PostingDate = 0D) then
            exit;
        EntryNo := SelectIncomingDocument(0, RelatedRecordID);
        if EntryNo = 0 then
            exit;

        IncomingDocument.Get(EntryNo);
        IncomingDocument.SetPostedDocFields(PostingDate, DocumentNo);
        IncomingDocument."Document Type" := GetRelatedDocType(PostingDate, DocumentNo, IsPosted);
    end;

    [Scope('OnPrem')]
    procedure SendToJobQueue(ShowMessages: Boolean)
    var
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        SendIncomingDocumentToOCR.SetShowMessages(ShowMessages);
        SendIncomingDocumentToOCR.SendToJobQueue(Rec);
    end;

    [Scope('OnPrem')]
    procedure ResetOriginalOCRData()
    var
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
        OriginalXMLRootNode: DotNet XmlNode;
    begin
        OCRServiceMgt.GetOriginalOCRXMLRootNode(Rec, OriginalXMLRootNode);
        OCRServiceMgt.UpdateIncomingDocWithOCRData(Rec, OriginalXMLRootNode);
    end;

    [Scope('OnPrem')]
    procedure UploadCorrectedOCRData(): Boolean
    var
        OCRServiceMgt: Codeunit "OCR Service Mgt.";
    begin
        exit(OCRServiceMgt.UploadCorrectedOCRFile(Rec))
    end;

    procedure SaveErrorMessages(var TempErrorMessageRef: Record "Error Message" temporary)
    var
        EntryNo: Integer;
    begin
        if not TempErrorMessageRef.FindSet() then
            exit;

        Clear(TempErrorMessage);
        if TempErrorMessage.FindLast() then;
        EntryNo := TempErrorMessage.ID + 1;

        repeat
            TempErrorMessage.TransferFields(TempErrorMessageRef);
            TempErrorMessage.ID := EntryNo;
            TempErrorMessage.Insert();
            EntryNo += 1;
        until TempErrorMessageRef.Next() = 0;
    end;

    procedure RemoveFromJobQueue(ShowMessages: Boolean)
    var
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        SendIncomingDocumentToOCR.SetShowMessages(ShowMessages);
        SendIncomingDocumentToOCR.RemoveFromJobQueue(Rec);
    end;

    [Scope('OnPrem')]
    procedure SendToOCR(ShowMessages: Boolean)
    var
        IncomingDocumentCopy: Record "Incoming Document";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        IncomingDocumentCopy.Copy(Rec);
        IncomingDocumentCopy.Reset();
        SendIncomingDocumentToOCR.SetShowMessages(ShowMessages);
        SendIncomingDocumentToOCR.SendDocToOCR(IncomingDocumentCopy);
        SendIncomingDocumentToOCR.ScheduleJobQueueReceive();
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        Status := NewStatus;
        Modify();
    end;

    [Scope('OnPrem')]
    procedure RetrieveFromOCR(ShowMessages: Boolean)
    var
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
    begin
        SendIncomingDocumentToOCR.SetShowMessages(ShowMessages);
        SendIncomingDocumentToOCR.RetrieveDocFromOCR(Rec);
    end;

    procedure GetGeneratedFromOCRAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.SetRange("Generated from OCR", true);
        exit(IncomingDocumentAttachment.FindFirst());
    end;

    procedure GetDataExchangePath(FieldNumber: Integer): Text
    var
        DataExchangeType: Record "Data Exchange Type";
        DataExchLineDef: Record "Data Exch. Line Def";
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        DataExchangePath: Text;
    begin
        if not DataExchangeType.Get("Data Exchange Type") then
            exit('');

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchangeType."Data Exch. Def. Code");
        DataExchLineDef.SetRange("Parent Code", '');
        if not DataExchLineDef.FindFirst() then
            exit('');

        OnGetDataExchangePathOnBeforeCase(DataExchLineDef, FieldNumber, DataExchangePath);
        if DataExchangePath <> '' then
            exit(DataExchangePath);

        case FieldNumber of
            FieldNo("Vendor Name"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name")));
            FieldNo("Vendor Id"):
                exit(DataExchLineDef.GetPath(Database::Vendor, Vendor.FieldNo(SystemId)));
            FieldNo("Vendor No."):
                exit(DataExchLineDef.GetPath(Database::Vendor, Vendor.FieldNo("No.")));
            FieldNo("Vendor VAT Registration No."):
                exit(DataExchLineDef.GetPath(Database::Vendor, Vendor.FieldNo("VAT Registration No.")));
            FieldNo("Vendor IBAN"):
                exit(DataExchLineDef.GetPath(Database::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN)));
            FieldNo("Vendor Bank Branch No."):
                exit(DataExchLineDef.GetPath(Database::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Branch No.")));
            FieldNo("Vendor Bank Account No."):
                exit(DataExchLineDef.GetPath(Database::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Account No.")));
            FieldNo("Vendor Phone No."):
                exit(DataExchLineDef.GetPath(Database::Vendor, Vendor.FieldNo("Phone No.")));
            FieldNo("Vendor Invoice No."):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No.")));
            FieldNo("Document Date"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Document Date")));
            FieldNo("Due Date"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Due Date")));
            FieldNo("Currency Code"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Currency Code")));
            FieldNo("Amount Excl. VAT"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo(Amount)));
            FieldNo("Amount Incl. VAT"):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Amount Including VAT")));
            FieldNo("Order No."):
                exit(DataExchLineDef.GetPath(Database::"Purchase Header", PurchaseHeader.FieldNo("Vendor Order No.")));
            FieldNo("VAT Amount"):
                exit(DataExchLineDef.GetPath(Database::"G/L Entry", GLEntry.FieldNo("VAT Amount")));
            else begin
                OnGetDataExchangePath(DataExchLineDef, FieldNumber, DataExchangePath);
                if DataExchangePath <> '' then
                    exit(DataExchangePath);
            end;
        end;

        exit('');
    end;

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        RelatedRecord: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowRecord(Rec, IsHandled);
        if IsHandled then
            exit;

        if GetRecord(RelatedRecord) then begin
            DataTypeManagement.GetRecordRef(RelatedRecord, RecRef);
            PageManagement.PageRun(RecRef);
        end;
    end;

    procedure GetRecord(var RelatedRecord: Variant): Boolean
    begin
        if Posted then
            exit(GetPostedRecord(RelatedRecord));
        exit(GetUnpostedRecord(RelatedRecord));
    end;

    local procedure GetPostedRecord(var RelatedRecord: Variant): Boolean
    var
        RelatedRecordRef: RecordRef;
    begin
        if GetRelatedRecord(RelatedRecordRef) then begin
            RelatedRecord := RelatedRecordRef;
            exit(true);
        end;
        exit(FindPostedRecord(RelatedRecord));
    end;

    local procedure FindPostedRecord(var RelatedRecord: Variant): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLEntry: Record "G/L Entry";
        RecordFound: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Journal:
                begin
                    GLEntry.SetCurrentKey("Document No.", "Posting Date");
                    GLEntry.SetRange("Document No.", "Document No.");
                    GLEntry.SetRange("Posting Date", "Posting Date");
                    if GLEntry.FindFirst() then begin
                        RelatedRecord := GLEntry;
                        exit(true);
                    end;
                end;
            "Document Type"::"Sales Invoice":
                if SalesInvoiceHeader.Get("Document No.") then begin
                    RelatedRecord := SalesInvoiceHeader;
                    exit(true);
                end;
            "Document Type"::"Sales Credit Memo":
                if SalesCrMemoHeader.Get("Document No.") then begin
                    RelatedRecord := SalesCrMemoHeader;
                    exit(true);
                end;
            "Document Type"::"Purchase Invoice":
                if PurchInvHeader.Get("Document No.") then begin
                    RelatedRecord := PurchInvHeader;
                    exit(true);
                end;
            "Document Type"::"Purchase Credit Memo":
                if PurchCrMemoHdr.Get("Document No.") then begin
                    RelatedRecord := PurchCrMemoHdr;
                    exit(true);
                end;
        end;
        RecordFound := false;
        OnAfterFindPostedRecord(RelatedRecord, RecordFound, Rec);
        exit(RecordFound);
    end;

    local procedure GetUnpostedRecord(var RelatedRecord: Variant): Boolean
    var
        RelatedRecordRef: RecordRef;
    begin
        if GetRelatedRecord(RelatedRecordRef) then begin
            RelatedRecord := RelatedRecordRef;
            exit(true);
        end;
        exit(FindUnpostedRecord(RelatedRecord));
    end;

    local procedure FindUnpostedRecord(var RelatedRecord: Variant): Boolean
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        RecordFound: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Journal:
                begin
                    GenJournalLine.SetRange("Incoming Document Entry No.", "Entry No.");
                    if GenJournalLine.FindFirst() then begin
                        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
                        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                        OnFindUnpostedRecordOnAfterFilterGenJournalLine(Rec, GenJournalLine);
                        RelatedRecord := GenJournalLine;
                        exit(true)
                    end;
                end;
            "Document Type"::"Sales Invoice",
            "Document Type"::"Sales Credit Memo":
                begin
                    SalesHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    if SalesHeader.FindFirst() then begin
                        RelatedRecord := SalesHeader;
                        exit(true);
                    end;
                end;
            "Document Type"::"Purchase Invoice",
            "Document Type"::"Purchase Credit Memo":
                begin
                    PurchaseHeader.SetRange("Incoming Document Entry No.", "Entry No.");
                    if PurchaseHeader.FindFirst() then begin
                        RelatedRecord := PurchaseHeader;
                        exit(true);
                    end;
                end;
        end;
        RecordFound := false;
        OnAfterFindUnpostedRecord(RelatedRecord, RecordFound, Rec);
        exit(RecordFound);
    end;

    local procedure GetRelatedRecord(var RelatedRecordRef: RecordRef): Boolean
    var
        RelatedRecordID: RecordID;
    begin
        RelatedRecordID := "Related Record ID";
        if RelatedRecordID.TableNo = 0 then
            exit(false);
        RelatedRecordRef := RelatedRecordID.GetRecord();
        exit(RelatedRecordRef.Get(RelatedRecordID));
    end;

    procedure RemoveLinkToRelatedRecord()
    var
        DummyRecordID: RecordID;
    begin
        "Related Record ID" := DummyRecordID;
        "Document No." := '';
        "Document Type" := "Document Type"::" ";
        Modify(true);
    end;

    procedure RemoveReferencedRecords()
    var
        RecRef: RecordRef;
        NavRecordVariant: Variant;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRemoveReferencedRecords(Rec, IsHandled);
        if IsHandled then
            exit;

        if Posted then
            UndoPostedDocFields()
        else begin
            if not Confirm(DoYouWantToRemoveReferenceQst) then
                exit;

            if Confirm(DeleteRecordQst) then
                if GetRecord(NavRecordVariant) then begin
                    RecRef.GetTable(NavRecordVariant);
                    RecRef.Delete(true);
                    exit;
                end;

            RemoveIncomingDocumentEntryNoFromUnpostedDocument();
            RemoveReferenceToWorkingDocument("Entry No.");
        end;
    end;

    procedure CreateFromAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocument: Record "Incoming Document";
    begin
        if IncomingDocumentAttachment.Import(true) then begin
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
            PAGE.Run(PAGE::"Incoming Document", IncomingDocument);
        end;
    end;

    procedure GetMainAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.SetRange("Main Attachment", true);
        exit(IncomingDocumentAttachment.FindFirst())
    end;

    procedure GetMainAttachmentFileName(): Text
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if GetMainAttachment(IncomingDocumentAttachment) then
            exit(IncomingDocumentAttachment.GetFullName());

        exit('');
    end;

    procedure GetRecordLinkText(): Text
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        VariantRecord: Variant;
    begin
        if GetRecord(VariantRecord) and DataTypeManagement.GetRecordRef(VariantRecord, RecRef) then
            exit(GetRelatedRecordCaption(RecRef));
        exit('');
    end;

    local procedure GetRelatedRecordCaption(var RelatedRecordRef: RecordRef): Text
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecCaption: Text;
    begin
        if RelatedRecordRef.IsEmpty() then
            exit('');

        case RelatedRecordRef.Number of
            Database::"Sales Header":
                RecCaption := StrSubstNo('%1 %2', SalesTxt, GetRecordCaption(RelatedRecordRef));
            Database::"Sales Invoice Header":
                RecCaption := StrSubstNo('%1 - %2', SalesInvoiceTxt, GetRecordCaption(RelatedRecordRef));
            Database::"Sales Cr.Memo Header":
                RecCaption := StrSubstNo('%1 - %2', SalesCreditMemoTxt, GetRecordCaption(RelatedRecordRef));
            Database::"Purchase Header":
                RecCaption := StrSubstNo('%1 %2', PurchaseTxt, GetRecordCaption(RelatedRecordRef));
            Database::"Purch. Inv. Header":
                RecCaption := StrSubstNo('%1 - %2', PurchaseInvoiceTxt, GetRecordCaption(RelatedRecordRef));
            Database::"Purch. Cr. Memo Hdr.":
                RecCaption := StrSubstNo('%1 - %2', PurchaseCreditMemoTxt, GetRecordCaption(RelatedRecordRef));
            Database::"G/L Entry":
                RecCaption := StrSubstNo('%1 - %2', "Document Type", GeneralLedgerEntriesTxt);
            Database::"Gen. Journal Line":
                if Posted then
                    RecCaption := StrSubstNo('%1 - %2', "Document Type", GeneralLedgerEntriesTxt)
                else begin
                    RelatedRecordRef.SetTable(GenJournalLine);
                    if GenJournalLine."Document Type" <> GenJournalLine."Document Type"::" " then
                        RecCaption := StrSubstNo('%1 - %2', GenJournalLine."Document Type", GetRecordCaption(RelatedRecordRef))
                    else
                        RecCaption := StrSubstNo('%1 - %2', JournalTxt, GetRecordCaption(RelatedRecordRef));
                end;
            else
                RecCaption := StrSubstNo('%1 - %2', RelatedRecordRef.Caption, GetRecordCaption(RelatedRecordRef));
        end;
        OnAfterGetRelatedRecordCaption(RelatedRecordRef, RecCaption);
        exit(RecCaption);
    end;

    procedure GetRecordCaption(var RecRef: RecordRef): Text
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyNo: Integer;
        FieldNo: Integer;
        RecCaption: Text;
    begin
        for KeyNo := 1 to RecRef.KeyCount do begin
            KeyRef := RecRef.KeyIndex(KeyNo);
            if KeyRef.Active then begin
                for FieldNo := 1 to KeyRef.FieldCount do begin
                    FieldRef := KeyRef.FieldIndex(FieldNo);
                    if RecCaption <> '' then
                        RecCaption := StrSubstNo('%1 - %2', RecCaption, FieldRef.Value)
                    else
                        RecCaption := Format(FieldRef.Value);
                end;
                break;
            end
        end;
        exit(RecCaption);
    end;

    procedure GetOCRResutlFileName(): Text
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileName: Text;
    begin
        FileName := '';
        if GetGeneratedFromOCRAttachment(IncomingDocumentAttachment) then
            FileName := IncomingDocumentAttachment.GetFullName();

        exit(FileName);
    end;

    [Scope('OnPrem')]
    procedure MainAttachmentDrillDown()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not GetMainAttachment(IncomingDocumentAttachment) then begin
            IncomingDocumentAttachment.NewAttachment();
            exit;
        end;

        // Download
        IncomingDocumentAttachment.Export('', true);
    end;

    [Scope('OnPrem')]
    procedure ReplaceOrInsertMainAttachment()
    begin
        ReplaceMainAttachment('');
    end;

    [Scope('OnPrem')]
    procedure ReplaceMainAttachment(FilePath: Text)
    var
        MainIncomingDocumentAttachment: Record "Incoming Document Attachment";
        NewIncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
    begin
        if not CanReplaceMainAttachment() then
            Error(CannotReplaceMainAttachmentErr);

        if not GetMainAttachment(MainIncomingDocumentAttachment) then begin
            MainIncomingDocumentAttachment.NewAttachment();
            exit;
        end;

        if not Confirm(ReplaceMainAttachmentQst) then
            exit;

        if FilePath = '' then
            ImportAttachmentIncDoc.UploadFile(NewIncomingDocumentAttachment, FilePath);

        if FilePath = '' then
            exit;

        MainIncomingDocumentAttachment.Delete();
        Commit();

        NewIncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        ImportAttachmentIncDoc.ImportAttachment(NewIncomingDocumentAttachment, FilePath);
    end;

    [Scope('OnPrem')]
    procedure ShowMainAttachment()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if GetMainAttachment(IncomingDocumentAttachment) then
            IncomingDocumentAttachment.Export('', true);
    end;

    [Scope('OnPrem')]
    procedure OCRResultDrillDown()
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        if not GetGeneratedFromOCRAttachment(IncomingDocumentAttachment) then
            exit;

        IncomingDocumentAttachment.Export('', true);
    end;

    procedure GetAdditionalAttachments(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Boolean
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.SetRange("Main Attachment", false);
        IncomingDocumentAttachment.SetRange("Generated from OCR", false);
        exit(IncomingDocumentAttachment.FindSet());
    end;

    procedure DefaultAttachmentIsXML(): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        IncomingDocumentAttachment.SetRange(Default, true);

        if IncomingDocumentAttachment.FindFirst() then
            exit(IncomingDocumentAttachment.Type = IncomingDocumentAttachment.Type::XML);

        exit(false);
    end;

    procedure FindByDocumentNoAndPostingDate(MainRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATEntry: Record "VAT Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentNoFieldRef: FieldRef;
        PostingDateFieldRef: FieldRef;
    begin
        if not DataTypeManagement.FindFieldByName(MainRecordRef, DocumentNoFieldRef, SalesInvoiceHeader.FieldName("No.")) then
            if not DataTypeManagement.FindFieldByName(MainRecordRef, DocumentNoFieldRef, VATEntry.FieldName("Document No.")) then
                exit(false);

        if not DataTypeManagement.FindFieldByName(MainRecordRef, PostingDateFieldRef, SalesInvoiceHeader.FieldName("Posting Date")) then
            exit(false);

        exit(FindByDocumentNoAndPostingDate(IncomingDocument, DocumentNoFieldRef.Value, PostingDateFieldRef.Value))
    end;

    procedure FindByDocumentNoAndPostingDate(MainRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"; DocumentNo: Text; PostingDateText: Text): Boolean
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Date;
    begin
        if (DocumentNo = '') or (PostingDateText = '') then
            exit(false);

        if not Evaluate(PostingDate, PostingDateText) then
            exit(false);

        IncomingDocument.SetRange("Document No.", DocumentNo);
        IncomingDocument.SetRange("Posting Date", PostingDate);

        case MainRecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Sales Invoice");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Purch. Inv. Header":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Sales Credit Memo");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Purchase Credit Memo");
                    IncomingDocument.SetRange(Posted, true);
                end;
            Database::"Sales Header":
                begin
                    MainRecordRef.SetTable(SalesHeader);
                    case SalesHeader."Document Type" of
                        SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Quote:
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Sales Invoice");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                        SalesHeader."Document Type"::"Credit Memo":
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Sales Credit Memo");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                    end;
                end;
            Database::"Purchase Header":
                begin
                    MainRecordRef.SetTable(PurchaseHeader);
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Quote:
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Purchase Invoice");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                        PurchaseHeader."Document Type"::"Credit Memo":
                            begin
                                IncomingDocument.SetRange("Document Type", IncomingDocument."Document Type"::"Purchase Credit Memo");
                                IncomingDocument.SetRange(Posted, false);
                            end;
                    end
                end;
            else
                OnFindByDocumentNoAndPostingDateOnSetFilters(IncomingDocument, MainRecordRef);
        end;

        exit(IncomingDocument.FindFirst());
    end;

    procedure FindByDocumentNoAndPostingDate(var IncomingDocument: Record "Incoming Document"; DocumentNo: Text; PostingDateText: Text): Boolean
    var
        PostingDate: Date;
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        if (DocumentNo = '') or (PostingDateText = '') then
            exit(false);

        if not Evaluate(PostingDate, PostingDateText) then
            exit(false);

        IsHandled := false;
        OnFindByDocumentNoAndPostingDateOnBeforeFind(IncomingDocument, DocumentNo, PostingDate, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        IncomingDocument.SetRange("Document No.", DocumentNo);
        IncomingDocument.SetRange("Posting Date", PostingDate);
        exit(IncomingDocument.FindFirst());
    end;

    procedure FindFromIncomingDocumentEntryNo(MainRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document") Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        IncomingDocumentEntryNoFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindFromIncomingDocumentEntryNo(MainRecordRef, IncomingDocument, Result, IsHandled);
        if IsHandled then
            exit;

        if not DataTypeManagement.FindFieldByName(
             MainRecordRef, IncomingDocumentEntryNoFieldRef, SalesHeader.FieldName("Incoming Document Entry No."))
        then
            exit(false);

        exit(IncomingDocument.Get(Format(IncomingDocumentEntryNoFieldRef.Value)));
    end;

    procedure GetStatusStyleText(): Text
    begin
        case Status of
            Status::Rejected,
          Status::Failed:
                exit('Unfavorable');
            else
                exit('Standard');
        end;
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckIncomingDocReleaseRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckIncomingDocCreateDocRestrictions()
    begin
    end;

    [IntegrationEvent(true, false)]
    [Scope('OnPrem')]
    procedure OnCheckIncomingDocSetForOCRRestrictions()
    begin
    end;

    procedure WaitingToReceiveFromOCR(): Boolean
    begin
        if "OCR Status" in ["OCR Status"::Sent, "OCR Status"::"Awaiting Verification"] then
            exit(true);
        exit(false);
    end;

    procedure OCRIsEnabled(): Boolean
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if not OCRServiceSetup.Get() then
            exit(false);
        exit(OCRServiceSetup.Enabled);
    end;

    procedure IsADocumentAttached(): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", "Entry No.");
        if GetURL() = '' then
            if IncomingDocumentAttachment.IsEmpty() then
                exit(false);
        exit(true);
    end;

    procedure TestReadyForApproval()
    begin
        if IsADocumentAttached() then
            exit;
        Error(NoDocAttachErr);
    end;

    procedure HasAttachment(): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        exit(GetMainAttachment(IncomingDocumentAttachment));
    end;

    procedure CanReplaceMainAttachment() CanReplaceMainAttachment: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeCanReplaceMainAttachment(CanReplaceMainAttachment, Rec, IsHandled);
        if IsHandled then
            exit(CanReplaceMainAttachment);
        if not HasAttachment() then
            exit(true);
        exit(not WasSentToOCR());
    end;

    local procedure WasSentToOCR(): Boolean
    begin
        exit("OCR Status" <> "OCR Status"::" ");
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateGenJnlLineFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateGenJnlLineFromIncomingDocFail(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateManually(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateSalesHeaderFromIncomingDoc(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreatePurchHeaderFromIncomingDoc(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPostedRecord(var RelatedRecord: Variant; var RecordFound: Boolean; var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindUnpostedRecord(var RelatedRecord: Variant; var RecordFound: Boolean; var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRelatedRecordCaption(var RelatedRecordRef: RecordRef; var RecCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDocumentFields(var IncomingDocument: Record "Incoming Document"; var DocExists: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateManually(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateSalesHeaderFromIncomingDoc(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteApprovalEntries(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowResultMessage(var IncomingDocument: Record "Incoming Document"; var ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromIncomingDocumentEntryNo(MainRecordRef: RecordRef; var IncomingDocument: Record "Incoming Document"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePurchDocOnBeforePurchHeaderInsert(var PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateGenJnlLineOnBeforeGenJnlLineInsert(var GenJnlLine: Record "Gen. Journal Line"; LastGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDataExchangePath(DataExchLineDef: Record "Data Exch. Line Def"; FieldNumber: Integer; var DataExchangePath: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetJournalTemplateAndBatch(var JournalTemplate: Code[10]; var JournalBatch: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGenJnlLineOnBeforeShowRecord(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocOnBeforeShowRecord(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocOnBeforeShowRecord(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveReferenceToWorkingDocumentOnBeforeModify(var IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCreatedDocumentType(var CreatedDocumentType: Dictionary of [Integer, Integer]; var CreatedDocumentStrMenu: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDocumentType(var IncomingDocument: Record "Incoming Document"; DocumentTypeEnum: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestIfAlreadyExists(IncomingRelatedDocumentType: Enum "Incoming Related Document Type"; EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRelatedDocType(PostingDate: Date; DocNo: Code[20]; var IsPosted: Boolean; var IncomingRelatedDocumentType: Enum "Incoming Related Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearRelatedRecords(IncomingRelatedDocumentType: Enum "Incoming Related Document Type"; EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDataExchangePathOnBeforeCase(DataExchLineDef: Record "Data Exch. Line Def"; FieldNumber: Integer; DataExchangePath: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRemoveReferencedRecords(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindByDocumentNoAndPostingDateOnBeforeFind(var IncomingDocument: Record "Incoming Document"; DocumentNo: Text; PostingDate: Date; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesDocOnAfterModifySalesHeader(var IncomingDocument: Record "Incoming Document"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePurchDocOnAfterModifyPurchaseHeader(var IncomingDocument: Record "Incoming Document"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateIncomingDocumentFromPosting(IncomingDocumentNo: Integer; PostingDate: Date; DocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowRecord(var IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindUnpostedRecordOnAfterFilterGenJournalLine(var IncomingDocument: Record "Incoming Document"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCanReplaceMainAttachment(var CanReplaceMainAttachment: Boolean; IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestIfAlreadyExists(IncomingDocument: Record "Incoming Document"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDocumentFieldsOnAfterUpdateDocuments(var IncomingDocument: Record "Incoming Document"; var DocExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindByDocumentNoAndPostingDateOnSetFilters(var IncomingDocument: Record "Incoming Document"; MainRecordRef: RecordRef)
    begin
    end;
}
