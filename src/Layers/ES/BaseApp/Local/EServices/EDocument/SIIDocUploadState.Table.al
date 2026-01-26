// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

table 10752 "SII Doc. Upload State"
{
    Caption = 'SII Doc. Upload States';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            NotBlank = true;
        }
        field(2; "Entry No"; Integer)
        {
            Caption = 'Entry No';
        }
        field(3; "Document Source"; Enum "SII Doc. Upload State Document Source")
        {
            Caption = 'Document Source';
            NotBlank = true;
        }
        field(4; "Document Type"; Enum "SII Doc. Upload State Document Type")
        {
            Caption = 'Document Type';
        }
        field(5; "Document No."; Code[35])
        {
            Caption = 'Document No.';
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7; "Transaction Type"; Option)
        {
            Caption = 'Transaction Type';
            OptionCaption = 'Regular,Intracommunity,RetryAccepted,Collection In Cash';
            OptionMembers = Regular,Intracommunity,RetryAccepted,"Collection In Cash";
        }
        field(8; Status; Enum "SII Document Status")
        {
            Caption = 'Status';
            NotBlank = true;
        }
        field(9; "Is Credit Memo Removal"; Boolean)
        {
            Caption = 'Is Credit Memo Removal';
        }
        field(10; "Is Manual"; Boolean)
        {
            Caption = 'Is Manual';
        }
        field(11; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(12; "Corrected Doc. No."; Code[35])
        {
            Caption = 'Corrected Doc. No.';
            DataClassification = CustomerContent;
        }
        field(13; "Corr. Posting Date"; Date)
        {
            Caption = 'Corr. Posting Date';
            DataClassification = CustomerContent;
        }
        field(20; "Sales Invoice Type"; Enum "SII Sales Upload Invoice Type")
        {
            Caption = 'Sales Invoice Type';

            trigger OnValidate()
            begin
                if "Sales Invoice Type" <> "Sales Invoice Type"::" " then begin
                    TestField("Document Source", "Document Source"::"Customer Ledger");
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(21; "Sales Cr. Memo Type"; Enum "SII Sales Upload Credit Memo Type")
        {
            Caption = 'Sales Cr. Memo Type';

            trigger OnValidate()
            begin
                if "Sales Cr. Memo Type" <> "Sales Cr. Memo Type"::" " then begin
                    TestField("Document Source", "Document Source"::"Customer Ledger");
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(22; "Sales Special Scheme Code"; Enum "SII Sales Upload Scheme Code")
        {
            Caption = 'Sales Special Scheme Code';

            trigger OnValidate()
            begin
                if "Sales Special Scheme Code" <> "Sales Special Scheme Code"::"01 General" then
                    TestField("Document Source", "Document Source"::"Customer Ledger");
            end;
        }
        field(23; "Purch. Invoice Type"; Enum "SII Purch. Upload Invoice Type")
        {
            Caption = 'Purch. Invoice Type';

            trigger OnValidate()
            begin
                if "Purch. Invoice Type" <> "Purch. Invoice Type"::" " then begin
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(24; "Purch. Cr. Memo Type"; Enum "SII Purch. Upload Cr. Memo Type")
        {
            Caption = 'Purch. Cr. Memo Type';

            trigger OnValidate()
            begin
                if "Purch. Cr. Memo Type" <> "Purch. Cr. Memo Type"::" " then begin
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(25; "Purch. Special Scheme Code"; Enum "SII Purch. Upload Scheme Code")
        {
            Caption = 'Purch. Special Scheme Code';

            trigger OnValidate()
            begin
                if "Purch. Special Scheme Code" <> "Purch. Special Scheme Code"::" " then
                    TestField("Document Source", "Document Source"::"Vendor Ledger");
            end;
        }
        field(30; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            TableRelation = if ("Document Source" = const("Customer Ledger")) Customer
            else
            if ("Document Source" = const("Vendor Ledger")) Vendor;
        }
        field(31; "Total Amount In Cash"; Decimal)
        {
            Caption = 'Total Amount In Cash';

            trigger OnValidate()
            begin
                if "Total Amount In Cash" <> 0 then
                    TestField("Transaction Type", "Transaction Type"::"Collection In Cash");
            end;
        }
        field(40; "Retry Accepted"; Boolean)
        {
            Caption = 'Retry Accepted';
        }
        field(41; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(42; "CV Name"; Text[100])
        {
            Caption = 'CV Name';
        }
        field(43; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(44; IDType; Enum "SII ID Type")
        {
            Caption = 'IDType';
        }
        field(50; "Inv. Entry No"; Integer)
        {
            Caption = 'Inv. Entry No';
            DataClassification = SystemMetadata;
        }
        field(60; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
        }
        field(61; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
        }
        field(62; "Issued By Third Party"; Boolean)
        {
            Caption = 'Issued By Third Party';
        }
        field(63; "First Summary Doc. No."; Text[250])
        {
        }
        field(64; "Last Summary Doc. No."; Text[250])
        {
        }
        field(70; "Version No."; Option)
        {
            Caption = 'Version No.';
            OptionCaption = '1.1,1.0,1.1bis';
            OptionMembers = "1.1","1.0","2.1";
        }
        field(80; "Accepted By User ID"; Code[50])
        {
            Caption = 'Accepted By User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(81; "Accepted Date Time"; DateTime)
        {
            Caption = 'Accepted Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(82; "CSV Response"; Text[250])
        {
            Caption = 'CSV Response';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Entry No")
        {
        }
        key(Key3; Status, "Is Manual")
        {
        }
        key(Key4; "Document No.", "Document Source", "Document Type")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateNewRequest(EntryNo: Integer; DocumentSource: Option "Customer Ledger","Vendor Ledger","Detailed Customer Ledger","Detailed Vendor Ledger"; DocumentType: Option; DocumentNo: Code[35]; ExternalDocumentNo: Code[35]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
            EntryNo, 0, "SII Doc. Upload State Document Source".FromInteger(DocumentSource),
            "SII Doc. Upload State Document Type".FromInteger(DocumentType), DocumentNo, ExternalDocumentNo, PostingDate);
    end;

    procedure CreateNewCollectionsInCashRequest(CustomerNo: Code[20]; PostingDate: Date; TotalAmount: Decimal): Boolean
    var
        Customer: Record Customer;
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        SIIDocUploadState.SetRange("Posting Date", PostingDate);
        SIIDocUploadState.SetRange("CV No.", CustomerNo);
        SIIDocUploadState.SetRange("Transaction Type", SIIDocUploadState."Transaction Type"::"Collection In Cash");
        if SIIDocUploadState.FindFirst() then begin
            if SIIDocUploadState."Total Amount In Cash" = TotalAmount then
                exit(false);
            SIIDocUploadState.Validate("Total Amount In Cash", TotalAmount);
            SIIDocUploadState.Validate("Retry Accepted",
              SIIDocUploadState.Status in [SIIDocUploadState.Status::Accepted, SIIDocUploadState.Status::"Accepted With Errors"]);
            SIIDocUploadState.Modify(true);
            SIIHistory.CreateNewRequest(
              SIIDocUploadState.Id, SIIHistory."Upload Type"::"Collection In Cash", 4, false, SIIDocUploadState."Retry Accepted");
            exit(true);
        end;
        SIIDocUploadState.Init();
        SIIDocUploadState."Document Source" := SIIDocUploadState."Document Source"::"Customer Ledger";
        SIIDocUploadState."Posting Date" := PostingDate;
        SetStatus(SIIDocUploadState);
        SIIDocUploadState."Transaction Type" := SIIDocUploadState."Transaction Type"::"Collection In Cash";
        SIIDocUploadState.Validate("CV No.", CustomerNo);
        Customer.Get(SIIDocUploadState."CV No.");
        SIIDocUploadState.Validate("VAT Registration No.", Customer."VAT Registration No.");
        SIIDocUploadState.Validate("CV Name", Customer.Name);
        SIIDocUploadState.Validate("Country/Region Code", Customer."Country/Region Code");
        SIIDocUploadState.Validate("Total Amount In Cash", TotalAmount);
        SIIDocUploadState.Insert();
        SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::"Collection In Cash", 4, false, false);
        exit(true);
    end;

    procedure CreateNewVendPmtRequest(PmtEntryNo: Integer; InvEntryNo: Integer; DocumentNo: Code[35]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, InvEntryNo, "Document Source"::"Detailed Vendor Ledger", "Document Type"::Payment, DocumentNo, '', PostingDate);
    end;

    procedure CreateNewVendRefundRequest(PmtEntryNo: Integer; CrEntryNo: Integer; DocumentNo: Code[35]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, CrEntryNo, "Document Source"::"Detailed Vendor Ledger", "Document Type"::Refund, DocumentNo, '', PostingDate);
    end;

    procedure CreateNewCustPmtRequest(PmtEntryNo: Integer; InvEntryNo: Integer; DocumentNo: Code[30]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, InvEntryNo, "Document Source"::"Detailed Customer Ledger", "Document Type"::Payment, DocumentNo, '', PostingDate);
    end;

    procedure CreateNewCustRefundRequest(PmtEntryNo: Integer; CrEntryNo: Integer; DocumentNo: Code[30]; PostingDate: Date)
    begin
        CreateNewRequestInternal(
          PmtEntryNo, CrEntryNo, "Document Source"::"Detailed Customer Ledger", "Document Type"::Refund, DocumentNo, '', PostingDate);
    end;

    local procedure CreateNewRequestInternal(EntryNo: Integer; InvEntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35]; ExternalDocumentNo: Code[35]; PostingDate: Date)
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
        TempSIIDocUploadState: Record "SII Doc. Upload State" temporary;
        SIIManagement: Codeunit "SII Management";
        IsCVPayment: Boolean;
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        IsCVPayment := DocumentSource in [SIIDocUploadState."Document Source"::"Detailed Customer Ledger",
                                          SIIDocUploadState."Document Source"::"Detailed Vendor Ledger"];
        if IsCVPayment then
            SIIDocUploadState.SetRange("Inv. Entry No", InvEntryNo)
        else
            SIIDocUploadState.SetRange("Entry No", EntryNo);
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        if SIIDocUploadState.FindFirst() then begin
            if IsCVPayment then begin
                // Create additional request to handle one more partial payment if no such request in state Pending
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                SIIHistory.SetRange(Status, SIIHistory.Status::Pending);
                if SIIHistory.IsEmpty() then
                    SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::Regular, 4, false, true);
            end;
            exit;
        end;

        TempSIIDocUploadState.Init();
        ValidateDocInfo(TempSIIDocUploadState, EntryNo, DocumentSource, DocumentType, DocumentNo);
        SIIDocUploadState.Init();
        SIIDocUploadState := TempSIIDocUploadState;
        SIIDocUploadState."Document No." := DocumentNo;
        SIIDocUploadState."External Document No." := ExternalDocumentNo;
        SIIDocUploadState."Posting Date" := PostingDate;
        SIIDocUploadState."Transaction Type" := SIIDocUploadState."Transaction Type"::Regular;
        SIIDocUploadState."Inv. Entry No" := InvEntryNo;
        SIIDocUploadState.GetCorrectionInfo(
          SIIDocUploadState."Corrected Doc. No.", SIIDocUploadState."Corr. Posting Date", SIIDocUploadState."Posting Date");
        SIIDocUploadState."Version No." := GetSIIVersionNo();
        SetStatus(SIIDocUploadState);
        OnCreateNewRequestInternalOnBeforeSIIDocUploadStateInsert(SIIDocUploadState, EntryNo, InvEntryNo, DocumentSource, DocumentType, DocumentNo, ExternalDocumentNo, PostingDate);
        SIIDocUploadState.Insert();

        SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type"::Regular, 4, false, false);
    end;

    procedure CreateCommunicationErrorRetries()
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.SetRange(Status, SIIDocUploadState.Status::"Communication Error");

        if SIIDocUploadState.FindSet() then
            repeat
                // We want latest first. Ideally we'd use something like 'by date desc', but since NAV does not allow us to do that,
                // we rely on PK and that the date does not change in a weird way.
                SIIHistory.Reset();
                SIIHistory.Ascending(false);
                SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                SIIHistory.SetRange("Is Manual", false);

                SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
                // If the latest doc is in "CommunicationError" state, we issue a retry.
                CreateCommunicationErrorRetryRequest(SIIHistory);
            until SIIDocUploadState.Next() = 0;
    end;

    local procedure CreateCommunicationErrorRetryRequest(var SIIHistory: Record "SII History")
    begin
        if SIIHistory.FindFirst() then
            if SIIHistory.Status = SIIHistory.Status::"Communication Error" then
                SIIHistory.CreateNewRequest(
                  SIIHistory."Document State Id", SIIHistory."Upload Type",
                  SIIHistory."Retries Left", false, false);
    end;

    local procedure SetStatus(var SIIDocUploadState: Record "SII Doc. Upload State")
    begin
        SIIDocUploadState.Status := Status::Pending;
    end;

    procedure UpdateDocInfoOnSIIDocUploadState(DocFieldNo: Integer)
    begin
        if not (Status in [Status::Pending, Status::Incorrect, Status::"Accepted With Errors"]) then
            FieldError(Status);
        UpdateFieldOnSIIDOcUploadState(DocFieldNo);
    end;

    procedure UpdateFieldOnSIIDOcUploadState(FieldNo: Integer)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldRef.Value);
        RecRef.Modify(true);
        RecRef.SetTable(Rec);
    end;

    procedure GetSIIDocUploadStateByCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        Reset();
        SetRange("Document Source", "Document Source"::"Customer Ledger");
        case CustLedgEntry."Document Type" of
            CustLedgEntry."Document Type"::Invoice:
                SetRange("Document Type", "Document Type"::Invoice);
            CustLedgEntry."Document Type"::"Credit Memo":
                SetRange("Document Type", "Document Type"::"Credit Memo");
            else
                exit;
        end;
        SetRange("Entry No", CustLedgEntry."Entry No.");
        FindFirst();
    end;

    procedure GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        Reset();
        SetRange("Document Source", "Document Source"::"Vendor Ledger");
        case VendorLedgerEntry."Document Type" of
            VendorLedgerEntry."Document Type"::Invoice:
                SetRange("Document Type", "Document Type"::Invoice);
            VendorLedgerEntry."Document Type"::"Credit Memo":
                SetRange("Document Type", "Document Type"::"Credit Memo");
            else
                exit;
        end;
        SetRange("Entry No", VendorLedgerEntry."Entry No.");
        FindFirst();
    end;

    procedure GetSIIDocUploadStateByDocument(DocSource: Option; DocType: Option; PostingDate: Date; DocNo: Code[20]): Boolean
    begin
        SetRange("Document Source", DocSource);
        SetRange("Document Type", DocType);
        SetRange("Posting Date", PostingDate);
        SetRange("Document No.", DocNo);
        exit(FindLast());
    end;

    local procedure GetSIIVersionNo(): Integer
    begin
        if Date2DMY(WorkDate(), 3) >= 2021 then
            exit("Version No."::"2.1");
        exit("Version No."::"1.1");
    end;

    procedure ValidateDocInfo(var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; EntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SIIManagement: Codeunit "SII Management";
    begin
        TempSIIDocUploadState.Validate("Entry No", EntryNo);
        TempSIIDocUploadState.Validate("Document Source", DocumentSource);
        TempSIIDocUploadState.Validate("Document Type", DocumentType);
        TempSIIDocUploadState.Validate("Is Credit Memo Removal", TempSIIDocUploadState.IsCreditMemoRemoval());
        case DocumentSource of
            "Document Source"::"Customer Ledger":
                case DocumentType of
                    "Document Type"::Invoice:
                        if SalesInvoiceHeader.Get(DocumentNo) then begin
                            if not SIIManagement.IsAllowedSalesInvType(SalesInvoiceHeader."Invoice Type".AsInteger()) then
                                SalesInvoiceHeader.FieldError("Invoice Type");
                            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                                SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."Invoice Type".AsInteger() + 1, 0,
                                SalesInvoiceHeader."Special Scheme Code".AsInteger() + 1, SalesInvoiceHeader."Succeeded Company Name",
                                SalesInvoiceHeader."Succeeded VAT Registration No.", SalesInvoiceHeader."ID Type".AsInteger());
                            TempSIIDocUploadState."Issued By Third Party" := SalesInvoiceHeader."Issued By Third Party";
                            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(SalesInvoiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
                            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(SalesInvoiceHeader.GetSIILastSummaryDocNo(), 1, 35);
                        end else
                            UpdateFieldsForInvoice(DocumentNo, EntryNo, TempSIIDocUploadState);
                    "Document Type"::"Credit Memo":
                        if SalesCrMemoHeader.Get(DocumentNo) then begin
                            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                              SalesCrMemoHeader."Bill-to Customer No.", 0, SalesCrMemoHeader."Cr. Memo Type".AsInteger() + 1,
                              SalesCrMemoHeader."Special Scheme Code".AsInteger() + 1, SalesCrMemoHeader."Succeeded Company Name",
                              SalesCrMemoHeader."Succeeded VAT Registration No.", SalesCrMemoHeader."ID Type".AsInteger());
                            TempSIIDocUploadState."Issued By Third Party" := SalesCrMemoHeader."Issued By Third Party";
                            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIIFirstSummaryDocNo(), 1, 35);
                            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIILastSummaryDocNo(), 1, 35);
                        end else
                            UpdateFieldsForCreditMemo(DocumentNo, EntryNo, TempSIIDocUploadState);
                end;
            "Document Source"::"Vendor Ledger":
                case DocumentType of
                    "Document Type"::Invoice:
                        if PurchInvHeader.Get(DocumentNo) then
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              PurchInvHeader."Pay-to Vendor No.", PurchInvHeader."Invoice Type".AsInteger() + 1, 0,
                              PurchInvHeader."Special Scheme Code".AsInteger() + 1,
                              PurchInvHeader."Succeeded Company Name", PurchInvHeader."Succeeded VAT Registration No.",
                              PurchInvHeader."ID Type".AsInteger())
                        else begin
                            VendLedgEntry.Get(EntryNo);
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              VendLedgEntry."Vendor No.", VendLedgEntry."Invoice Type".AsInteger() + 1, 0,
                              VendLedgEntry."Special Scheme Code".AsInteger() + 1,
                              VendLedgEntry."Succeeded Company Name", VendLedgEntry."Succeeded VAT Registration No.",
                              VendLedgEntry."ID Type".AsInteger());
                        end;
                    "Document Type"::"Credit Memo":
                        if PurchCrMemoHdr.Get(DocumentNo) then
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              PurchCrMemoHdr."Pay-to Vendor No.", 0, PurchCrMemoHdr."Cr. Memo Type".AsInteger() + 1,
                              PurchCrMemoHdr."Special Scheme Code".AsInteger() + 1,
                              PurchCrMemoHdr."Succeeded Company Name", PurchCrMemoHdr."Succeeded VAT Registration No.",
                              PurchCrMemoHdr."ID Type".AsInteger())
                        else begin
                            VendLedgEntry.Get(EntryNo);
                            TempSIIDocUploadState.UpdatePurchSIIDocUploadState(
                              VendLedgEntry."Vendor No.", 0, VendLedgEntry."Cr. Memo Type".AsInteger() + 1,
                              VendLedgEntry."Special Scheme Code".AsInteger() + 1,
                              VendLedgEntry."Succeeded Company Name", VendLedgEntry."Succeeded VAT Registration No.",
                              VendLedgEntry."ID Type".AsInteger());
                        end;
                end;
        end;
        OnAfterValidateDocInfo(TempSIIDocUploadState, EntryNo, DocumentSource, DocumentType, DocumentNo);
    end;

    local procedure UpdateFieldsForInvoice(DocumentNo: Code[35]; EntryNo: Integer; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not UpdateFieldsForServiceInvoice(DocumentNo, TempSIIDocUploadState) then begin
            CustLedgerEntry.Get(EntryNo);
            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                CustLedgerEntry."Customer No.", CustLedgerEntry."Invoice Type".AsInteger() + 1, 0,
                CustLedgerEntry."Special Scheme Code".AsInteger() + 1,
                CustLedgerEntry."Succeeded Company Name", CustLedgerEntry."Succeeded VAT Registration No.",
                CustLedgerEntry."ID Type".AsInteger());
            TempSIIDocUploadState."Issued By Third Party" := CustLedgerEntry."Issued By Third Party";
            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(CustLedgerEntry.GetSIIFirstSummaryDocNo(), 1, 35);
            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(CustLedgerEntry.GetSIILastSummaryDocNo(), 1, 35);
        end;
    end;

    local procedure UpdateFieldsForServiceInvoice(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary) Result: Boolean
    begin
        OnUpdateFieldsForServiceInvoice(DocumentNo, TempSIIDocUploadState, Result);
    end;

    local procedure UpdateFieldsForCreditMemo(DocumentNo: Code[35]; EntryNo: Integer; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not UpdateFieldsForServiceCreditMemo(DocumentNo, TempSIIDocUploadState) then begin
            CustLedgerEntry.Get(EntryNo);
            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                CustLedgerEntry."Customer No.", 0, CustLedgerEntry."Cr. Memo Type".AsInteger() + 1,
                CustLedgerEntry."Special Scheme Code".AsInteger() + 1,
                CustLedgerEntry."Succeeded Company Name", CustLedgerEntry."Succeeded VAT Registration No.",
                CustLedgerEntry."ID Type".AsInteger());
            TempSIIDocUploadState."Issued By Third Party" := CustLedgerEntry."Issued By Third Party";
            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(CustLedgerEntry.GetSIIFirstSummaryDocNo(), 1, 35);
            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(CustLedgerEntry.GetSIILastSummaryDocNo(), 1, 35);
        end;
    end;

    local procedure UpdateFieldsForServiceCreditMemo(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary) Result: Boolean
    begin
        OnUpdateFieldsForServiceCreditMemo(DocumentNo, TempSIIDocUploadState, Result);
    end;

    procedure IsCreditMemoRemoval(): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Result: Boolean;
        ShouldExit: Boolean;
    begin
        if ("Document Source" = "Document Source"::"Customer Ledger") and ("Document Type" = "Document Type"::"Credit Memo") then
            if CustLedgerEntry.Get("Entry No") then begin
                if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                    exit(SalesCrMemoHeader."Correction Type" = SalesCrMemoHeader."Correction Type"::Removal);

                Result := false;
                ShouldExit := false;
                OnAfterIsCreditmemoRemovalOnGetCorrectionType(CustLedgerEntry, Result, ShouldExit);
                if ShouldExit then
                    exit(Result);
            end;

        if ("Document Source" = "Document Source"::"Vendor Ledger") and ("Document Type" = "Document Type"::"Credit Memo") then
            if VendorLedgerEntry.Get("Entry No") then
                if PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.") then
                    exit(PurchCrMemoHdr."Correction Type" = PurchCrMemoHdr."Correction Type"::Removal);

        exit(false);
    end;

    procedure GetCorrectionInfo(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        CorrectedDocNo := '';
        CorrectionDate := 0D;
        if ("Document Source" in ["Document Source"::"Detailed Customer Ledger", "Document Source"::"Detailed Vendor Ledger"]) or
           ("Document Type" in ["Document Type"::Payment, "Document Type"::Invoice])
        then
            exit;

        if "Document Source" = "Document Source"::"Customer Ledger" then begin
            if SalesCrMemoHeader.Get("Document No.") then
                GetCorrInfoFromCustLedgEntry(CorrectedDocNo, CorrectionDate, SalesCrMemoHeader."Corrected Invoice No.")
            else begin
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
                CustLedgerEntry.SetRange("Document No.", "Document No.");
                CustLedgerEntry.SetRange("Posting Date", PostingDate);
                if CustLedgerEntry.FindFirst() then
                    GetCorrInfoFromCustLedgEntry(CorrectedDocNo, CorrectionDate, CustLedgerEntry."Corrected Invoice No.");
            end;
            exit;
        end;

        if PurchCrMemoHdr.Get("Document No.") then
            GetCorrInfoFromVendLedgEntry(CorrectedDocNo, CorrectionDate, PurchCrMemoHdr."Corrected Invoice No.")
        else begin
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
            VendorLedgerEntry.SetRange("Document No.", "Document No.");
            VendorLedgerEntry.SetRange("Posting Date", PostingDate);
            if VendorLedgerEntry.FindFirst() then
                GetCorrInfoFromVendLedgEntry(CorrectedDocNo, CorrectionDate, VendorLedgerEntry."Corrected Invoice No.");
        end;
    end;

    local procedure GetCorrInfoFromCustLedgEntry(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if DocNo = '' then
            exit;

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        if CustLedgerEntry.FindFirst() then begin
            CorrectedDocNo := CustLedgerEntry."Document No.";
            CorrectionDate := CustLedgerEntry."Posting Date";
        end;
    end;

    local procedure GetCorrInfoFromVendLedgEntry(var CorrectedDocNo: Code[35]; var CorrectionDate: Date; DocNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if DocNo = '' then
            exit;

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        if VendorLedgerEntry.FindFirst() then begin
            if VendorLedgerEntry."External Document No." = '' then
                CorrectedDocNo := VendorLedgerEntry."Document No."
            else
                CorrectedDocNo := VendorLedgerEntry."External Document No.";
            CorrectionDate := VendorLedgerEntry."Document Date";
        end;
    end;

    procedure UpdateSalesSIIDocUploadStateInfo(CustNo: Code[20]; InvType: Option; CrMemoType: Option; SpecialSchemeCode: Option; SucceededCompanyName: Text[250]; SucceededVATRegNo: Text[20]; NewIDType: Option)
    begin
        Validate("CV No.", CustNo);
        if InvType = 0 then
            Validate("Sales Cr. Memo Type", CrMemoType)
        else
            Validate("Sales Invoice Type", InvType);
        Validate("Sales Special Scheme Code", SpecialSchemeCode);
        Validate("Succeeded Company Name", SucceededCompanyName);
        Validate("Succeeded VAT Registration No.", SucceededVATRegNo);
        Validate(IDType, NewIDType);
    end;

    procedure UpdatePurchSIIDocUploadState(VendNo: Code[20]; InvType: Option; CrMemoType: Option; SpecialSchemeCode: Option; SucceededCompanyName: Text[250]; SucceededVATRegNo: Text[20]; NewIDType: Option)
    begin
        Validate("CV No.", VendNo);
        if InvType = 0 then
            Validate("Purch. Cr. Memo Type", CrMemoType)
        else
            Validate("Purch. Invoice Type", InvType);
        Validate("Purch. Special Scheme Code", SpecialSchemeCode);
        Validate("Succeeded Company Name", SucceededCompanyName);
        Validate("Succeeded VAT Registration No.", SucceededVATRegNo);
        Validate(IDType, NewIDType);
    end;

    procedure GetSpecialSchemeCodes(var RegimeCodes: array[3] of Code[2])
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        i: Integer;
    begin
        case "Document Source" of
            "Document Source"::"Customer Ledger":
                begin
                    case "Document Type" of
                        "Document Type"::Invoice:
                            SIISalesDocumentSchemeCode.SetRange(
                              "Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                        "Document Type"::"Credit Memo":
                            SIISalesDocumentSchemeCode.SetRange(
                              "Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                        else
                            exit;
                    end;
                    SIISalesDocumentSchemeCode.SetRange("Document No.", "Document No.");
                    if SIISalesDocumentSchemeCode.FindSet() then begin
                        repeat
                            i += 1;
                            RegimeCodes[i] := CopyStr(Format(SIISalesDocumentSchemeCode."Special Scheme Code"), 1, 2);
                        until (SIISalesDocumentSchemeCode.Next() = 0) or (i = ArrayLen(RegimeCodes));
                        exit;
                    end;
                    RegimeCodes[1] := CopyStr(Format("Sales Special Scheme Code"), 1, 2);
                end;
            "Document Source"::"Vendor Ledger":
                begin
                    case "Document Type" of
                        "Document Type"::Invoice:
                            SIIPurchDocSchemeCode.SetRange(
                              "Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
                        "Document Type"::"Credit Memo":
                            SIIPurchDocSchemeCode.SetRange(
                              "Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo");
                        else
                            exit;
                    end;
                    SIIPurchDocSchemeCode.SetRange("Document No.", "Document No.");
                    if SIIPurchDocSchemeCode.FindSet() then begin
                        repeat
                            i += 1;
                            RegimeCodes[i] := CopyStr(Format(SIIPurchDocSchemeCode."Special Scheme Code"), 1, 2);
                        until (SIIPurchDocSchemeCode.Next() = 0) or (i = ArrayLen(RegimeCodes));
                        exit;
                    end;
                    RegimeCodes[1] := CopyStr(Format("Purch. Special Scheme Code"), 1, 2);
                end;
        end;
    end;

    procedure AssignPurchSchemeCode(SchemeCode: Enum "SII Purch. Special Scheme Code")
    begin
        "Purch. Special Scheme Code" := "SII Purch. Upload Scheme Code".FromInteger(SchemeCode.AsInteger() + 1);
    end;

    procedure AssignSalesSchemeCode(SchemeCode: Enum "SII Sales Special Scheme Code")
    begin
        "Sales Special Scheme Code" := "SII Sales Upload Scheme Code".FromInteger(SchemeCode.AsInteger() + 1);
    end;

    procedure AssignPurchInvoiceType(InvoiceType: Enum "SII Purch. Invoice Type")
    begin
        "Purch. Invoice Type" := "SII Purch. Upload Invoice Type".FromInteger((InvoiceType.AsInteger() + 1));
    end;

    procedure AssignSalesInvoiceType(InvoiceType: Enum "SII Sales Invoice Type")
    begin
        "Sales Invoice Type" := "SII Sales Upload Invoice Type".FromInteger((InvoiceType.AsInteger() + 1));
    end;

    procedure AssignPurchCreditMemoType(CreditMemoType: Enum "SII Purch. Credit Memo Type")
    begin
        "Purch. Cr. Memo Type" := "SII Purch. Upload Cr. Memo Type".FromInteger((CreditMemoType.AsInteger() + 1));
    end;

    procedure AssignSalesCreditMemoType(CreditMemoType: Enum "SII Sales Credit Memo Type")
    begin
        "Sales Cr. Memo Type" := "SII Sales Upload Credit Memo Type".FromInteger((CreditMemoType.AsInteger() + 1));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateDocInfo(var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; EntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewRequestInternalOnBeforeSIIDocUploadStateInsert(var SIIDocUploadState: Record "SII Doc. Upload State"; EntryNo: Integer; InvEntryNo: Integer; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[35]; ExternalDocumentNo: Code[35]; PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreditmemoRemovalOnGetCorrectionType(CustLedgerEntry: Record "Cust. Ledger Entry"; var Result: Boolean; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFieldsForServiceInvoice(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFieldsForServiceCreditMemo(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var Result: Boolean)
    begin
    end;
}

