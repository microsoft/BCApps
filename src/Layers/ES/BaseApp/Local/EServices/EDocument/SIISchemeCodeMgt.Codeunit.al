// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using System.Utilities;

codeunit 10758 "SII Scheme Code Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';

    procedure GetMaxNumberOfRegimeCodes(): Integer
    begin
        exit(3);
    end;

    procedure SalesDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if not GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            exit(false);
        exit(not SIISalesDocumentSchemeCode.IsEmpty());
    end;

    procedure SalesDrillDownRegimeCodes(RecVar: Variant)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        if GetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecVar) then
            PAGE.RunModal(0, SIISalesDocumentSchemeCode);
    end;

    local procedure GetSIISalesDocRecFromRec(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; RecVar: Variant) Result: Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SalesHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecRef.SetTable(SalesInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesInvoiceHeader."No.");
                    exit(true);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    RecRef.SetTable(SalesCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", SalesCrMemoHeader."No.");
                    exit(true);
                end;
            else
                OnGetSIISalesDocRecFromRec(SIISalesDocumentSchemeCode, RecRef, Result);
        end;
    end;

    internal procedure MoveSalesRegimeCodesToPostedDoc(DocType: Option; DocNo: Code[20]; EntryType: Option; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        NewSIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISalesDocumentSchemeCode.SetRange("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.SetRange("Document Type", DocType);
        SIISalesDocumentSchemeCode.SetRange("Document No.", DocNo);
        if not SIISalesDocumentSchemeCode.FindSet() then
            exit;

        repeat
            NewSIISalesDocumentSchemeCode := SIISalesDocumentSchemeCode;
            NewSIISalesDocumentSchemeCode."Document Type" := PostedDocType;
            NewSIISalesDocumentSchemeCode."Document No." := PostedDocNo;
            NewSIISalesDocumentSchemeCode.Insert();
        until SIISalesDocumentSchemeCode.Next() = 0;
        SIISalesDocumentSchemeCode.DeleteAll(true);
    end;

    procedure PurchDocHasRegimeCodes(RecVar: Variant): Boolean
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if not GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            exit(false);
        exit(not SIIPurchDocSchemeCode.IsEmpty());
    end;

    procedure PurchDrillDownRegimeCodes(RecVar: Variant)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        if GetSIIPurchDocRecFromRec(SIIPurchDocSchemeCode, RecVar) then
            PAGE.RunModal(0, SIIPurchDocSchemeCode);
    end;

    procedure ValidateSalesSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(
          xSIIDocUploadState, SIIDocUploadState, SIISalesDocumentSchemeCode."Entry Type"::Sales);
    end;

    procedure ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(
          xSIIDocUploadState, SIIDocUploadState, SIISalesDocumentSchemeCode."Entry Type"::Service);
    end;

    local procedure ValidateSalesAndServSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State"; EntryType: Option)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        DocType: Option;
    begin
        if xSIIDocUploadState."Sales Special Scheme Code" = SIIDocUploadState."Sales Special Scheme Code" then
            exit;

        DocType := GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState);
        if xSIIDocUploadState."Sales Special Scheme Code" <> xSIIDocUploadState."Sales Special Scheme Code"::" " then
            if SIISalesDocumentSchemeCode.Get(EntryType, DocType, SIIDocUploadState."Document No.",
                 xSIIDocUploadState."Sales Special Scheme Code")
            then
                SIISalesDocumentSchemeCode.Delete(true);

        if SIIDocUploadState."Sales Special Scheme Code" = xSIIDocUploadState."Sales Special Scheme Code"::" " then
            exit;

        SIISalesDocumentSchemeCode.Init();
        SIISalesDocumentSchemeCode.Validate("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.Validate("Document Type", DocType);
        SIISalesDocumentSchemeCode.Validate(
          "Document No.", CopyStr(SIIDocUploadState."Document No.", 1, MaxStrLen(SIISalesDocumentSchemeCode."Document No.")));
        SIISalesDocumentSchemeCode.Validate("Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code");
        SIISalesDocumentSchemeCode.Insert(true);
    end;

    procedure ValidatePurchSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState: Record "SII Doc. Upload State"; SIIDocUploadState: Record "SII Doc. Upload State")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        DocType: Option;
    begin
        if xSIIDocUploadState."Purch. Special Scheme Code" = SIIDocUploadState."Purch. Special Scheme Code" then
            exit;

        DocType := GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState);
        if xSIIDocUploadState."Purch. Special Scheme Code" <> xSIIDocUploadState."Purch. Special Scheme Code"::" " then
            if SIIPurchDocSchemeCode.Get(DocType, SIIDocUploadState."Document No.", xSIIDocUploadState."Purch. Special Scheme Code") then
                SIIPurchDocSchemeCode.Delete(true);

        if SIIDocUploadState."Purch. Special Scheme Code" = SIIDocUploadState."Purch. Special Scheme Code"::" " then
            exit;

        SIIPurchDocSchemeCode.Init();
        SIIPurchDocSchemeCode.Validate("Document Type", DocType);
        SIIPurchDocSchemeCode.Validate(
          "Document No.", CopyStr(SIIDocUploadState."Document No.", 1, MaxStrLen(SIIPurchDocSchemeCode."Document No.")));
        SIIPurchDocSchemeCode.Validate("Special Scheme Code", SIIDocUploadState."Purch. Special Scheme Code");
        SIIPurchDocSchemeCode.Insert(true);
    end;

    procedure UpdatePurchaseSpecialSchemeCodeInPurchaseHeader(PurchaseHeader: Record "Purchase Header"; xPurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if PurchaseHeader."Special Scheme Code" = xPurchaseHeader."Special Scheme Code" then
            exit;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, PurchaseHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            PurchaseLine.Validate("Special Scheme Code", PurchaseHeader."Special Scheme Code");
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    procedure UpdateSalesSpecialSchemeCodeInSalesHeader(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if SalesHeader."Special Scheme Code" = xSalesHeader."Special Scheme Code" then
            exit;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            SalesLine.Validate("Special Scheme Code", SalesHeader."Special Scheme Code");
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('moved to codeunit Serv. SII Management', '27.0')]
    procedure UpdateServiceSpecialSchemeCodeInSalesHeader(ServiceHeader: Record Microsoft.Service.Document."Service Header"; xServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServSIIManagement: Codeunit "Serv. SII Management";
    begin
        ServSIImanagement.UpdateServiceSpecialSchemeCodeInSalesHeader(ServiceHeader, xServiceHeader);
    end;
#endif

    procedure UpdateSalesSpecialSchemeCodeInSalesLine(var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesLine."Special Scheme Code" := SalesLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Sales Special Scheme Code" = VATPostingSetup."Sales Special Scheme Code"::" " then
            exit;
        SalesLine."Special Scheme Code" :=
            "SII Sales Special Scheme Code".FromInteger(VATPostingSetup."Sales Special Scheme Code".AsInteger() - 1);
    end;

    procedure UpdatePurchSpecialSchemeCodeInPurchLine(var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchaseLine."Special Scheme Code" := PurchaseLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Purch. Special Scheme Code" = VATPostingSetup."Purch. Special Scheme Code"::" " then begin
            if VATPostingSetup."VAT Cash Regime" then
                PurchaseLine."Special Scheme Code" := PurchaseLine."Special Scheme Code"::"07 Special Cash";
            exit;
        end;

        PurchaseLine."Special Scheme Code" :=
            "SII Purch. Special Scheme Code".FromInteger(VATPostingSetup."Purch. Special Scheme Code".AsInteger() - 1);
    end;

#if not CLEAN27
    [Obsolete('moved to codeunit Serv. SII Management', '27.0')]
    procedure UpdatePurchSpecialSchemeCodeInServiceine(var ServiceLine: Record Microsoft.Service.Document."Service Line")
    var
        ServSIIManagement: Codeunit "Serv. SII Management";
    begin
        ServSIIManagement.UpdatePurchSpecialSchemeCodeInServiceine(ServiceLine);
    end;
#endif

    local procedure GetSpecialRegimeDocTypeFromSIIDocUploadState(SIIDocUploadState: Record "SII Doc. Upload State"): Integer
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        case SIIDocUploadState."Document Type" of
            SIIDocUploadState."Document Type"::Invoice:
                exit(SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
            SIIDocUploadState."Document Type"::"Credit Memo":
                exit(SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
        end;
    end;

    local procedure GetSIIPurchDocRecFromRec(var SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code"; RecVar: Variant): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            DATABASE::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Inv. Header":
                begin
                    RecRef.SetTable(PurchInvHeader);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchInvHeader."No.");
                    exit(true);
                end;
            DATABASE::"Purch. Cr. Memo Hdr.":
                begin
                    RecRef.SetTable(PurchCrMemoHdr);
                    SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo");
                    SIIPurchDocSchemeCode.SetRange("Document No.", PurchCrMemoHdr."No.");
                    exit(true);
                end;
        end;
    end;

    local procedure MovePurchRegimeCodesToPostedDoc(PurchaseHeader: Record "Purchase Header"; PostedDocType: Option; PostedDocNo: Code[20])
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        NewSIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        SIIPurchDocSchemeCode.SetRange("Document Type", PurchaseHeader."Document Type");
        SIIPurchDocSchemeCode.SetRange("Document No.", PurchaseHeader."No.");
        if not SIIPurchDocSchemeCode.FindSet() then
            exit;

        repeat
            NewSIIPurchDocSchemeCode := SIIPurchDocSchemeCode;
            NewSIIPurchDocSchemeCode."Document Type" := PostedDocType;
            NewSIIPurchDocSchemeCode."Document No." := PostedDocNo;
            NewSIIPurchDocSchemeCode.Insert();
        until SIIPurchDocSchemeCode.Next() = 0;
        SIIPurchDocSchemeCode.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        Found: Boolean;
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIISalesDocumentSchemeCode."Entry Type" := SIISalesDocumentSchemeCode."Entry Type"::Sales;
        SIISalesDocumentSchemeCode."Document Type" := SalesHeader."Document Type".AsInteger();
        SIISalesDocumentSchemeCode."Document No." := SalesHeader."No.";

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            if SalesLine."Special Scheme Code" <> SalesLine."Special Scheme Code"::"01 General" then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SalesLine."Special Scheme Code".AsInteger() + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> SalesLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> SalesLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if (VATPostingSetup."VAT Clause Code" <> '') and
                    (SalesHeader."Special Scheme Code".AsInteger() <= SalesHeader."Special Scheme Code"::"01 General".AsInteger())
                then
                    if VATPostingSetup."VAT Clause Code" <> VATClause.Code then begin
                        VATClause.Get(VATPostingSetup."VAT Clause Code");
                        Found :=
                        VATClause."SII Exemption Code" in [VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21",
                                                            VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22"]
                    end;
                if (VATPostingSetup."Sales Special Scheme Code" <> VATPostingSetup."Sales Special Scheme Code"::" ") and
                   (not SpecialSchemeCodeToInsert)
                then begin
                    SIISalesDocumentSchemeCode."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code".AsInteger();
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
                SalesHeader."Special Scheme Code" :=
                    "SII Sales Special Scheme Code".FromInteger(SIISalesDocumentSchemeCode."Special Scheme Code" - 1);
            end;
        until (SalesLine.Next() = 0) or Found;
        if Found then begin
            SalesHeader."Special Scheme Code" := SalesHeader."Special Scheme Code"::"02 Export";
            if SalesDocHasRegimeCodes(SalesHeader) then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIIPurchDocSchemeCode."Document Type" := PurchaseHeader."Document Type".AsInteger();
        SIIPurchDocSchemeCode."Document No." := PurchaseHeader."No.";

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if not PurchaseLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            if PurchaseLine."Special Scheme Code" <> PurchaseLine."Special Scheme Code"::"01 General" then begin
                SIIPurchDocSchemeCode."Special Scheme Code" := PurchaseLine."Special Scheme Code".AsInteger() + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> PurchaseLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> PurchaseLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if VATPostingSetup."Purch. Special Scheme Code" <> VATPostingSetup."Purch. Special Scheme Code"::" " then begin
                    PurchaseHeader."Special Scheme Code" :=
                        "SII Purch. Special Scheme Code".FromInteger(VATPostingSetup."Purch. Special Scheme Code".AsInteger() - 1);
                    SIIPurchDocSchemeCode."Special Scheme Code" := VATPostingSetup."Purch. Special Scheme Code".AsInteger();
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIIPurchDocSchemeCode.Find() then
                    SIIPurchDocSchemeCode.Insert();
                PurchaseHeader."Special Scheme Code" :=
                    "SII Purch. Special Scheme Code".FromInteger(SIIPurchDocSchemeCode."Special Scheme Code" - 1);
            end;
        until PurchaseLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure OnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", SalesInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        MoveSalesRegimeCodesToPostedDoc(
          SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Sales,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", SalesCrMemoHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvHeaderInsert', '', false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Invoice", PurchInvHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterPurchCrMemoHeaderInsert(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchHeader: Record "Purchase Header"; CommitIsSupressed: Boolean)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        MovePurchRegimeCodesToPostedDoc(PurchHeader, SIIPurchDocSchemeCode."Document Type"::"Posted Credit Memo", PurchCrMemoHdr."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSIISalesDocRecFromRec(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; RecRef: RecordRef; var Result: Boolean)
    begin
    end;
}

