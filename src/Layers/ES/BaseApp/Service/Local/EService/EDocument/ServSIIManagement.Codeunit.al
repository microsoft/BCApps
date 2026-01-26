// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using System.Utilities;

codeunit 10759 "Serv. SII Management"
{
    var
        SIIManagement: Codeunit "SII Management";
        SIIJobManagement: Codeunit "SII Job Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';


    [EventSubscriber(ObjectType::Table, Database::"SII Doc. Upload State", 'OnUpdateFieldsForServiceInvoice', '', true, true)]
    local procedure OnUpdateFieldsForServiceInvoice(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var Result: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Posting No.", DocumentNo);
        if ServiceHeader.FindFirst() then begin
            if not IsAllowedServInvType(ServiceHeader."Invoice Type".AsInteger()) then
                ServiceHeader.FieldError("Invoice Type");
            // Increase Invoice Type and Special Scheme Code because in SII Doc. Upload state there is blank option in the beginning
            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                ServiceHeader."Bill-to Customer No.", ServiceHeader."Invoice Type".AsInteger() + 1, 0,
                ServiceHeader."Special Scheme Code".AsInteger() + 1,
                ServiceHeader."Succeeded Company Name", ServiceHeader."Succeeded VAT Registration No.", ServiceHeader."ID Type");
            TempSIIDocUploadState."Issued By Third Party" := ServiceHeader."Issued By Third Party";
            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(ServiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(ServiceHeader.GetSIILastSummaryDocNo(), 1, 35);
            Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"SII Doc. Upload State", 'OnUpdateFieldsForServiceCreditMemo', '', true, true)]
    local procedure OnUpdateFieldsForServiceCreditMemo(DocumentNo: Code[35]; var TempSIIDocUploadState: Record "SII Doc. Upload State" temporary; var Result: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Posting No.", DocumentNo);
        if ServiceHeader.FindFirst() then begin
            TempSIIDocUploadState.UpdateSalesSIIDocUploadStateInfo(
                ServiceHeader."Bill-to Customer No.", 0, ServiceHeader."Cr. Memo Type".AsInteger() + 1,
                ServiceHeader."Special Scheme Code".AsInteger() + 1,
                ServiceHeader."Succeeded Company Name", ServiceHeader."Succeeded VAT Registration No.", ServiceHeader."ID Type");
            TempSIIDocUploadState."Issued By Third Party" := ServiceHeader."Issued By Third Party";
            TempSIIDocUploadState."First Summary Doc. No." := CopyStr(ServiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
            TempSIIDocUploadState."Last Summary Doc. No." := CopyStr(ServiceHeader.GetSIILastSummaryDocNo(), 1, 35);
            Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"SII Doc. Upload State", 'OnAfterIsCreditmemoRemovalOnGetCorrectionType', '', true, true)]
    local procedure OnAfterIsCreditmemoRemovalOnGetCorrectionType(CustLedgerEntry: Record "Cust. Ledger Entry"; var Result: Boolean; var ShouldExit: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then begin
            Result := ServiceCrMemoHeader."Correction Type" = ServiceCrMemoHeader."Correction Type"::Removal;
            ShouldExit := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure OnAfterPostServiceDoc(var ServiceHeader: Record "Service Header")
    var
        SIISetup: Record "SII Setup";
#if not CLEAN27
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
#endif
        JobType: Option HandlePending,HandleCommError,InitialUpload;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterPostServiceDoc(ServiceHeader, IsHandled);
#if not CLEAN27 
        SIIJobUploadPendingDocs.RunOnBeforeOnAfterPostServiceDoc(ServiceHeader, IsHandled);
#endif
        if not IsHandled then
            exit;

        if not SIISetup.IsEnabled() then
            exit;

        if ServiceHeader.IsTemporary or ServiceHeader."Do Not Send To SII" then
            exit;

        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
    end;

    procedure IsAllowedServInvType(InvType: Option): Boolean
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        exit(InvType in [ServiceInvoiceHeader."Invoice Type"::"F1 Invoice".AsInteger(),
                         ServiceInvoiceHeader."Invoice Type"::"F2 Simplified Invoice".AsInteger(),
                         ServiceInvoiceHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices".AsInteger(),
                         ServiceInvoiceHeader."Invoice Type"::"F4 Invoice summary entry".AsInteger()]);
    end;

    procedure UpdateSIIInfoInServiceDoc(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader."Special Scheme Code" :=
            SIIManagement.GetSalesSpecialSchemeCode(ServiceHeader."Bill-to Customer No.", ServiceHeader."VAT Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterPostServiceDoc(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var IsHandled: Boolean)
    begin
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII Scheme Code Mgt.", 'OnGetSIISalesDocRecFromRec', '', true, true)]
    local procedure OnGetSIISalesDocRecFromRec(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; RecRef: RecordRef; var Result: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case RecRef.Number of
            DATABASE::"Service Header":
                begin
                    RecRef.SetTable(ServiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", ServiceHeader."Document Type");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceHeader."No.");
                    Result := true;
                end;
            DATABASE::"Service Invoice Header":
                begin
                    RecRef.SetTable(ServiceInvoiceHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    Result := true;
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    RecRef.SetTable(ServiceCrMemoHeader);
                    SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
                    SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo");
                    SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceCrMemoHeader."No.");
                    Result := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        Found: Boolean;
        SpecialSchemeCodeToInsert: Boolean;
    begin
        SIISalesDocumentSchemeCode."Entry Type" := SIISalesDocumentSchemeCode."Entry Type"::Service;
        SIISalesDocumentSchemeCode."Document Type" := PassedServHeader."Document Type".AsInteger();
        SIISalesDocumentSchemeCode."Document No." := PassedServHeader."No.";

        ServiceLine.SetRange("Document Type", PassedServHeader."Document Type");
        ServiceLine.SetRange("Document No.", PassedServHeader."No.");
        if not ServiceLine.FindSet() then
            exit;

        repeat
            SpecialSchemeCodeToInsert := false;
            if ServiceLine."Special Scheme Code" <> ServiceLine."Special Scheme Code"::"01 General" then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := ServiceLine."Special Scheme Code".AsInteger() + 1;
                SpecialSchemeCodeToInsert := true;
            end;
            if (VATPostingSetup."VAT Bus. Posting Group" <> ServiceLine."VAT Bus. Posting Group") or
                (VATPostingSetup."VAT Prod. Posting Group" <> ServiceLine."VAT Prod. Posting Group")
            then begin
                if not VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
                    VATPostingSetup.Init();
                if (VATPostingSetup."VAT Clause Code" <> '') and
                    (PassedServHeader."Special Scheme Code".AsInteger() <= PassedServHeader."Special Scheme Code"::"01 General".AsInteger())
                then
                    if VATPostingSetup."VAT Clause Code" <> VATClause.Code then begin
                        VATClause.Get(VATPostingSetup."VAT Clause Code");
                        Found :=
                          VATClause."SII Exemption Code" in [VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21",
                                                              VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22"]
                    end;
                if (VATPostingSetup."Sales Special Scheme Code" <> VATPostingSetup."Sales Special Scheme Code"::" ") and
                   (not SpecialSchemeCodeToInsert) then begin
                    SIISalesDocumentSchemeCode."Special Scheme Code" := VATPostingSetup."Sales Special Scheme Code".AsInteger();
                    SpecialSchemeCodeToInsert := true;
                end;
            end;
            if SpecialSchemeCodeToInsert then begin
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
                PassedServHeader."Special Scheme Code" :=
                    "SII Sales Special Scheme Code".FromInteger(SIISalesDocumentSchemeCode."Special Scheme Code" - 1);
            end;
        until (ServiceLine.Next() = 0) or Found;
        if Found then begin
            PassedServHeader."Special Scheme Code" := PassedServHeader."Special Scheme Code"::"02 Export";
            if SIISchemeCodeMgt.SalesDocHasRegimeCodes(PassedServHeader) then begin
                SIISalesDocumentSchemeCode."Special Scheme Code" := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
                if not SIISalesDocumentSchemeCode.Find() then
                    SIISalesDocumentSchemeCode.Insert();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterServInvHeaderInsert', '', false, false)]
    local procedure OnAfterServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISchemeCodeMgt.MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice", ServiceInvoiceHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterServCrMemoHeaderInsert', '', false, false)]
    local procedure OnAfterServCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISchemeCodeMgt.MoveSalesRegimeCodesToPostedDoc(
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", SIISalesDocumentSchemeCode."Entry Type"::Service,
          SIISalesDocumentSchemeCode."Document Type"::"Posted Credit Memo", ServiceCrMemoHeader."No.");
    end;

    procedure UpdateServiceSpecialSchemeCodeInSalesHeader(ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ServiceHeader."Special Scheme Code" = xServiceHeader."Special Scheme Code" then
            exit;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if not ServiceLine.FindSet(true) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ConfirmChangeQst, ServiceHeader.FieldCaption("Special Scheme Code")), true) then
            exit;
        repeat
            ServiceLine.Validate("Special Scheme Code", ServiceHeader."Special Scheme Code");
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    procedure UpdatePurchSpecialSchemeCodeInServiceine(var ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        ServiceLine."Special Scheme Code" := ServiceLine."Special Scheme Code"::"01 General";
        if not VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
            exit;
        if VATPostingSetup."Sales Special Scheme Code" = VATPostingSetup."Sales Special Scheme Code"::" " then
            exit;
        ServiceLine."Special Scheme Code" :=
            "SII Sales Special Scheme Code".FromInteger(VATPostingSetup."Sales Special Scheme Code".AsInteger() - 1);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnGetCorrectionInfoFromDocument', '', false, false)]
    local procedure OnGetCorrectionInfoFromDocument(DocumentNo: Code[20]; var CorrectedInvoiceNo: Code[20]; var CorrectionType: Option; var IsHandled: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(DocumentNo) then begin
            CorrectedInvoiceNo := ServiceCrMemoHeader."Corrected Invoice No.";
            CorrectionType := ServiceCrMemoHeader."Correction Type";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SII XML Creator", 'OnGetOperationDescriptionFromDocument', '', false, false)]
    local procedure OnGetOperationDesacriptionFromDocument(DocumentNo: Code[35]; var OperationDescription: Text; var ShouldExit: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceInvoiceHeader.Get(DocumentNo) then begin
            OperationDescription := ServiceInvoiceHeader."Operation Description" + ServiceInvoiceHeader."Operation Description 2";
            ShouldExit := true;
        end else
            if ServiceCrMemoHeader.Get(DocumentNo) then begin
                OperationDescription := ServiceCrMemoHeader."Operation Description" + ServiceCrMemoHeader."Operation Description 2";
                ShouldExit := true;
            end;
    end;
}