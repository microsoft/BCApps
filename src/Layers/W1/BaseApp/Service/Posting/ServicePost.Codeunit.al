// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Service.Archive;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;

codeunit 5980 "Service-Post"
{
    Permissions = TableData "Service Header" = rimd,
                  TableData "Service Item Line" = rimd,
                  TableData "Service Line" = rimd,
                  TableData "Service Shipment Item Line" = rimd,
                  TableData "Service Shipment Header" = rimd,
                  TableData "Service Shipment Line" = rimd,
                  TableData "Service Invoice Header" = rimd,
                  TableData "Service Invoice Line" = rimd,
                  TableData "Service Cr.Memo Header" = rimd,
                  TableData "Service Cr.Memo Line" = rimd,
                  tabledata "G/L Entry" = r;
    TableNo = "Service Header";

    trigger OnRun()
    var
        TempServiceLine: Record "Service Line" temporary;
    begin
        OnBeforeRun(Rec);

        PostWithLines(Rec, TempServiceLine, Ship, Consume, Invoice);
    end;

    var
        ServiceShptLine: Record "Service Shipment Line";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCode: Record "Source Code";
        ServiceSetup: Record "Service Mgt. Setup";
        ServiceInvLine: Record "Service Invoice Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        TempWarehouseShipmentHeader: Record "Warehouse Shipment Header" temporary;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TempWarehouseShipmentLine: Record "Warehouse Shipment Line" temporary;
        GLSetup: Record "General Ledger Setup";
        ServDocumentsMgt: Codeunit "Serv-Documents Mgt.";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        WhsePostShpt: Codeunit "Whse.-Post Shipment";
        Window: Dialog;
        PostingDate: Date;
        OrderArchived: Boolean;
        ReplaceDocumentDate: Boolean;
        ReplacePostingDate: Boolean;
        PostingDateExists: Boolean;
        Ship: Boolean;
        Consume: Boolean;
        Invoice: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Posting lines              #2######\';
        Text003: Label 'Posting serv. and VAT      #3######\';
        Text004: Label 'Posting to customers       #4######\';
        Text005: Label 'Posting to bal. account    #5######';
        Text006: Label 'Posting lines              #2######';
#pragma warning restore AA0470
        Text007: Label 'is not within your range of allowed posting dates';
#pragma warning restore AA0074
        WhseShip: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;
        NotSupportedDocumentTypeErr: Label 'Document type %1 is not supported.', Comment = '%1=Document Type e.g. Invoice';
        HideValidationDialog: Boolean;

    procedure PostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        [SecurityFiltering(SecurityFilter::Ignored)]
        GLEntry: Record "G/L Entry";
        ServDocReg: Record "Service Document Register";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WarehouseShipmentHeaderLocal: Record "Warehouse Shipment Header";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        WhseServiceRelease: Codeunit "Whse.-Service Release";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ServDocNo: Code[20];
        ServDocType: Integer;
        ServInvoiceNo: Code[20];
        ServCrMemoNo: Code[20];
        ServShipmentNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWithLines(PassedServHeader, PassedServLine, PassedShip, PassedConsume, PassedInvoice, PostingDateExists, HideValidationDialog, IsHandled, PreviewMode, ReplacePostingDate, PostingDate, ReplaceDocumentDate, SuppressCommit);
        if not IsHandled then begin

            ServiceHeader := PassedServHeader;

            Clear(ServDocumentsMgt);

            ValidatePostingAndDocumentDate(ServiceHeader);

            Initialize(ServiceHeader, PassedServLine, PassedShip, PassedConsume, PassedInvoice);

            if GuiAllowed() then begin
                if Invoice then
                    Window.Open('#1#################################\\' + Text002 + Text003 + Text004 + Text005)
                else
                    Window.Open('#1#################################\\' + Text006);
                Window.Update(1, StrSubstNo('%1 %2', ServiceHeader."Document Type", ServiceHeader."No."));
            end;

            if ServDocumentsMgt.SetNoSeries(ServiceHeader, PreviewMode) then begin
                ServiceHeader.Modify();
                if not SuppressCommit and not PreviewMode then
                    Commit();
            end;

            if PreviewMode then
                ServiceHeader.Consistent(false); // Safety net to prevent commits

            ServDocumentsMgt.CalcInvDiscount();
            ServiceHeader.Find();

            CollectWhseShipmentInformation(PassedServHeader);

            LockTables(ServiceLine, GLEntry);
            // fetch related document (if any), for testing invoices and credit memos fields.
            Clear(ServDocReg);
            ServDocReg.ServiceDocument(ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServDocType, ServDocNo);
            // update quantites upon posting options and test related fields.
            ServDocumentsMgt.CheckAndBlankQtys(ServDocType);
            // create posted documents (both header and lines).
            WhseShip := false;
            if Ship then begin
                ServShipmentNo := ServDocumentsMgt.PrepareShipmentHeader();
                WhseShip := not TempWarehouseShipmentHeader.IsEmpty();
            end;
            if Invoice then
                if ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice] then begin
                    ServInvoiceNo := ServDocumentsMgt.PrepareInvoiceHeader(Window);
                    ServDocumentsMgt.UpdateIncomingDocument(ServiceHeader."Incoming Document Entry No.", ServiceHeader."Posting Date", ServInvoiceNo);
                end else begin
                    ServCrMemoNo := ServDocumentsMgt.PrepareCrMemoHeader(Window);
                    ServDocumentsMgt.UpdateIncomingDocument(ServiceHeader."Incoming Document Entry No.", ServiceHeader."Posting Date", ServCrMemoNo);
                end;

            if WhseShip then begin
                WarehouseShipmentHeader.Get(TempWarehouseShipmentHeader."No.");
                OnBeforeCreatePostedWhseShptHeader(PostedWhseShipmentHeader, WarehouseShipmentHeader, ServiceHeader);
                WhsePostShpt.CreatePostedShptHeader(PostedWhseShipmentHeader, WarehouseShipmentHeader, ServiceHeader."Shipping No.", ServiceHeader."Posting Date");
            end;
            // main lines posting routine via Journals
            ServDocumentsMgt.PostDocumentLines(Window);
            ServDocumentsMgt.CollectTrackingSpecification(TempTrackingSpecification);

            ServDocumentsMgt.SetLastNos(ServiceHeader);
            ServiceHeader.Modify();

            if not OrderArchived then begin
                ServiceDocumentArchiveMgmt.AutoArchiveServiceDocument(ServiceHeader);
                OrderArchived := true;
            end;

            // handling afterposting modification/deletion of documents
            ServDocumentsMgt.UpdateDocumentLines();

            ServDocumentsMgt.InsertValueEntryRelation();

            if WhseShip then begin
                if TempWarehouseShipmentLine.FindSet() then
                    repeat
                        WarehouseShipmentLine.Get(TempWarehouseShipmentLine."No.", TempWarehouseShipmentLine."Line No.");
                        WhsePostShpt.CreatePostedShptLine(WarehouseShipmentLine, PostedWhseShipmentHeader,
                          PostedWhseShipmentLine, TempTrackingSpecification);
                    until TempWarehouseShipmentLine.Next() = 0;
                if WarehouseShipmentHeaderLocal.Get(WarehouseShipmentHeader."No.") then
                    UpdateWhseDocuments();
            end;

            if PreviewMode then begin
                if GuiAllowed() then
                    Window.Close();
                GenJnlPostPreview.ThrowError();
            end;

            Finalize(ServiceHeader);

            OnAfterFinalizePostingOnBeforeCommit(
              PassedServHeader, PassedServLine, ServDocumentsMgt, PassedShip, PassedConsume, PassedInvoice);

            if WhseShip then
                WhseServiceRelease.Release(ServiceHeader);

            if not SuppressCommit then
                Commit();

            OnAfterPostServiceDoc(ServiceHeader, ServShipmentNo, ServInvoiceNo, ServCrMemoNo, ServDocumentsMgt, SuppressCommit, PassedShip, PassedConsume, PassedInvoice, WhseShip);

            if GuiAllowed() then
                Window.Close();
            UpdateAnalysisView.UpdateAll(0, true);
            UpdateItemAnalysisView.UpdateAll(0, true);

            PassedServHeader := ServiceHeader;
        end;

        OnAfterPostWithLines(PassedServHeader, IsHandled);
    end;

    local procedure UpdateWhseDocuments()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseDocuments(WarehouseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        WhsePostShpt.PostUpdateWhseDocuments(WarehouseShipmentHeader);
    end;

    local procedure Initialize(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        OnBeforeInitialize(PassedServiceHeader, PassedServiceLine, PassedShip, PassedConsume, PassedInvoice, PreviewMode);
        CheckServiceDocument(PassedServiceHeader, PassedServiceLine);
        SetPostingOptions(PassedShip, PassedConsume, PassedInvoice);

        ServDocumentsMgt.Initialize(PassedServiceHeader, PassedServiceLine);

        // Also calls procedure of the same name from ServDocMgt.
        // Might change the value of global Ship,Consume,Invoice vars.
        CheckAndSetPostingConstants(PassedServiceHeader, PassedShip, PassedConsume, PassedInvoice);

        OnInitializeOnAfterCheckAndSetPostingConstants(
            PassedServiceHeader, PassedServiceLine, PassedShip, PassedConsume, PassedInvoice, PreviewMode);

        // check for service lines with adjusted price
        if (not HideValidationDialog or not GuiAllowed) and
           Invoice and (PassedServiceHeader."Document Type" = PassedServiceHeader."Document Type"::Order)
        then
            ServDocumentsMgt.CheckAdjustedLines();

        OnAfterInitialize(PassedServiceHeader, PassedServiceLine);
    end;

    procedure CheckServiceDocument(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    var
        ServReportDistributionMgt: Codeunit "Serv. Report Distribution Mgt.";
    begin
        TestMandatoryFields(PassedServiceHeader, PassedServiceLine);
        ServReportDistributionMgt.RunDefaultCheckServiceElectronicDocument(PassedServiceHeader);
        ServDocumentsMgt.CheckServiceDocument(PassedServiceHeader, PassedServiceLine);
    end;

    local procedure Finalize(var PassedServiceHeader: Record "Service Header")
    begin
        ServDocumentsMgt.Finalize(PassedServiceHeader);
    end;

    local procedure CheckAndSetPostingConstants(var ServiceHeader: Record "Service Header"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAndSetPostingConstants(ServiceHeader, ServDocumentsMgt, PassedShip, PassedConsume, PassedInvoice, IsHandled);
        if IsHandled then
            exit;

        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Invoice:
                begin
                    PassedShip := true;
                    PassedInvoice := true;
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    PassedShip := false;
                    PassedInvoice := true;
                end;
        end;

        ServDocumentsMgt.CheckAndSetPostingConstants(PassedShip, PassedConsume, PassedInvoice);

        if not (PassedShip or PassedInvoice or PassedConsume) then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        if Invoice and (ServiceHeader."Document Type" <> ServiceHeader."Document Type"::"Credit Memo") then
            ServiceHeader.TestField(ServiceHeader."Due Date");
        OnCheckAndSetConstantsOnBeforeSetPostingOptions(ServiceHeader, Invoice, Ship);
        SetPostingOptions(PassedShip, PassedConsume, PassedInvoice);
    end;

    local procedure ValidatePostingAndDocumentDate(var ServiceHeader: Record "Service Header")
    begin
        OnBeforeValidatePostingAndDocumentDate(ServiceHeader, PostingDateExists, ReplacePostingDate, ReplaceDocumentDate, PostingDate);
        if PostingDateExists and (ReplacePostingDate or (ServiceHeader."Posting Date" = 0D)) then begin
            ServiceHeader.Validate("Posting Date", PostingDate);
            ServiceHeader.Validate("Currency Code");
        end;
        if PostingDateExists and (ReplaceDocumentDate or (ServiceHeader."Document Date" = 0D)) then begin
            ServiceHeader.Validate("Document Date", PostingDate);
            OnValidatePostingAndDocumentDateOnAfterValidateDocumentDate(ServiceHeader);
        end;

        OnAfterValidatePostingAndDocumentDate(ServiceHeader, PreviewMode);
    end;

    local procedure TestMandatoryFields(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestMandatoryFields(PassedServiceHeader, PassedServiceLine, Invoice, IsHandled);
        if IsHandled then
            exit;

        PassedServiceHeader.TestField("Document Type", ErrorInfo.Create());
        PassedServiceHeader.TestField("Customer No.", ErrorInfo.Create());
        PassedServiceHeader.TestField("Bill-to Customer No.", ErrorInfo.Create());
        PassedServiceHeader.TestField("Posting Date", ErrorInfo.Create());
        PassedServiceHeader.TestField("Document Date", ErrorInfo.Create());
        GLSetup.Get();
        if GLSetup."Journal Templ. Name Mandatory" then
            PassedServiceHeader.TestField("Journal Templ. Name", ErrorInfo.Create());
        if PassedServiceLine.IsEmpty() then
            TestServLinePostingDate(PassedServiceHeader."Document Type", PassedServiceHeader."No.", PassedServiceHeader."Journal Templ. Name")
        else
            if PassedServiceHeader."Posting Date" <> PassedServiceLine."Posting Date" then begin
                CheckDateNotAllowedForServiceLine(PassedServiceHeader, PassedServiceLine);
                if GenJnlCheckLine.DateNotAllowed(PassedServiceHeader."Posting Date", PassedServiceHeader."Journal Templ. Name") then
                    PassedServiceHeader.FieldError(PassedServiceHeader."Posting Date", ErrorInfo.Create(Text007, true));
            end;
        PassedServiceHeader.TestMandatoryFields(PassedServiceLine);
    end;

    local procedure CheckDateNotAllowedForServiceLine(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line")
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDateNotAllowedForServiceLine(PassedServiceLine, IsHandled);
        if IsHandled then
            exit;

        if PassedServiceLine.Type <> PassedServiceLine.Type::" " then
            if GenJnlCheckLine.DateNotAllowed(PassedServiceLine."Posting Date", PassedServiceHeader."Journal Templ. Name") then
                PassedServiceLine.FieldError("Posting Date", ErrorInfo.Create(Text007, true));
    end;

    procedure SetPostingDate(NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewPostingDate: Date)
    var
        IsHandled: Boolean;
        SavedSuppressCommit: Boolean;
        SavedHideValidationDialog: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetPostingDate(PostingDateExists, ReplacePostingDate, ReplaceDocumentDate, PostingDate, IsHandled);
        if IsHandled then
            exit;

        SavedSuppressCommit := SuppressCommit;
        SavedHideValidationDialog := HideValidationDialog;
        ClearAll();
        SuppressCommit := SavedSuppressCommit;
        HideValidationDialog := SavedHideValidationDialog;

        PostingDateExists := true;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        PostingDate := NewPostingDate;
    end;

    procedure SetPostingOptions(PassedShip: Boolean; PassedConsume: Boolean; PassedInvoice: Boolean)
    begin
        Ship := PassedShip;
        Consume := PassedConsume;
        Invoice := PassedInvoice;
        ServDocumentsMgt.SetPostingOptions(Ship, Consume, Invoice);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure TestDeleteHeader(ServiceHeader: Record "Service Header"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceInvHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        Clear(ServiceShptHeader);
        Clear(ServiceInvHeader);
        Clear(ServiceCrMemoHeader);
        ServiceSetup.Get();

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        if (ServiceHeader."Shipping No. Series" <> '') and (ServiceHeader."Shipping No." <> '') then begin
            ServiceHeader.CalcFields("Work Description");
            ServiceShptHeader.TransferFields(ServiceHeader);
            OnTestDeleteHeaderOnAfterServiceShptHeaderTransferFields(ServiceShptHeader, ServiceHeader);
            ServiceShptHeader."No." := ServiceHeader."Shipping No.";
            ServiceShptHeader."Posting Date" := Today;
            ServiceShptHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServiceShptHeader."User ID"));
            ServiceShptHeader."Source Code" := SourceCode.Code;
        end;

        if (ServiceHeader."Posting No. Series" <> '') and
           ((ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice]) and
            (ServiceHeader."Posting No." <> '') or
            (ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice) and
            (ServiceHeader."No. Series" = ServiceHeader."Posting No. Series"))
        then begin
            ServiceHeader.CalcFields("Work Description");
            ServiceInvHeader.TransferFields(ServiceHeader);
            OnTestDeleteHeaderOnAfterServiceInvHeaderTransferFields(ServiceInvHeader, ServiceHeader);
            if ServiceHeader."Posting No." <> '' then
                ServiceInvHeader."No." := ServiceHeader."Posting No.";
            if ServiceHeader."Document Type" = ServiceHeader."Document Type"::Invoice then begin
                ServiceInvHeader."Pre-Assigned No. Series" := ServiceHeader."No. Series";
                ServiceInvHeader."Pre-Assigned No." := ServiceHeader."No.";
            end else begin
                ServiceInvHeader."Pre-Assigned No. Series" := '';
                ServiceInvHeader."Pre-Assigned No." := '';
                ServiceInvHeader."Order No. Series" := ServiceHeader."No. Series";
                ServiceInvHeader."Order No." := ServiceHeader."No.";
            end;
            ServiceInvHeader."Posting Date" := Today;
            ServiceInvHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServiceInvHeader."User ID"));
            ServiceInvHeader."Source Code" := SourceCode.Code;
        end;

        if (ServiceHeader."Posting No. Series" <> '') and
           ((ServiceHeader."Document Type" in [ServiceHeader."Document Type"::"Credit Memo"]) and
            (ServiceHeader."Posting No." <> '') or
            (ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo") and
            (ServiceHeader."No. Series" = ServiceHeader."Posting No. Series"))
        then begin
            ServiceHeader.CalcFields("Work Description");
            ServiceCrMemoHeader.TransferFields(ServiceHeader);
            OnTestDeleteHeaderOnAfterServiceCrMemoHeaderTransferFields(ServiceCrMemoHeader, ServiceHeader);
            if ServiceHeader."Posting No." <> '' then
                ServiceCrMemoHeader."No." := ServiceHeader."Posting No.";
            ServiceCrMemoHeader."Pre-Assigned No. Series" := ServiceHeader."No. Series";
            ServiceCrMemoHeader."Pre-Assigned No." := ServiceHeader."No.";
            ServiceCrMemoHeader."Posting Date" := Today;
            ServiceCrMemoHeader."User ID" := CopyStr(UserId(), 1, MaxStrLen(ServiceCrMemoHeader."User ID"));
            ServiceCrMemoHeader."Source Code" := SourceCode.Code;
        end;
    end;

    local procedure LockTables(var ServiceLine: Record "Service Line"; var GLEntry: Record "G/L Entry")
    var
        InvSetup: Record "Inventory Setup";
    begin
        ServiceLine.LockTable();

        if not InvSetup.OptimGLEntLockForMultiuserEnv() then begin
            GLEntry.LockTable();
            OnLockTablesOnBeforeGLEntryFindLast(GLEntry);
            GLEntry.GetLastEntryNo();
        end;
    end;

    procedure DeleteHeader(ServiceHeader: Record "Service Header"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceInvHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        TestDeleteHeader(ServiceHeader, ServiceShptHeader, ServiceInvHeader, ServiceCrMemoHeader);
        if ServiceShptHeader."No." <> '' then begin
            OnBeforeServiceShptHeaderInsert(ServiceShptHeader, ServiceHeader);
            ServiceShptHeader.Insert();
            ServiceShptLine.Init();
            ServiceShptLine."Document No." := ServiceShptHeader."No.";
            ServiceShptLine."Line No." := 10000;
            ServiceShptLine.Description := SourceCode.Description;
            OnDeleteHeaderOnBeforeServiceShptLineInsert(ServiceHeader, ServiceShptHeader, ServiceShptLine);
            ServiceShptLine.Insert();
        end;

        if ServiceInvHeader."No." <> '' then begin
            OnBeforeServiceInvHeaderInsert(ServiceInvHeader, ServiceHeader);
            ServiceInvHeader.Insert();
            ServiceInvLine.Init();
            ServiceInvLine."Document No." := ServiceInvHeader."No.";
            ServiceInvLine."Line No." := 10000;
            ServiceInvLine.Description := SourceCode.Description;
            OnDeleteHeaderOnBeforeServiceInvLineInsert(ServiceHeader, ServiceInvHeader, ServiceInvLine);
            ServiceInvLine.Insert();
        end;

        if ServiceCrMemoHeader."No." <> '' then begin
            OnBeforeServiceCrMemoHeaderInsert(ServiceCrMemoHeader, ServiceHeader);
            ServiceCrMemoHeader.Insert();
            ServiceCrMemoLine.Init();
            ServiceCrMemoLine."Document No." := ServiceCrMemoHeader."No.";
            ServiceCrMemoLine."Line No." := 10000;
            ServiceCrMemoLine.Description := SourceCode.Description;
            OnDeleteHeaderOnBeforeServiceCrMemoLineInsert(ServiceHeader, ServiceCrMemoHeader, ServiceCrMemoLine);
            ServiceCrMemoLine.Insert();
        end;
        OnAfterDeleteHeader(ServiceHeader, ServiceShptHeader, ServiceInvHeader, ServiceCrMemoHeader);
    end;

    local procedure CollectWhseShipmentInformation(ServiceHeader: Record "Service Header")
    var
        WarehouseShipmentHeaderLocal: Record "Warehouse Shipment Header";
        WarehouseShipmentLineLocal: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
    begin
        TempWarehouseShipmentHeader.DeleteAll();
        TempWarehouseShipmentLine.DeleteAll();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("Qty. to Ship", '<>%1', 0);
        if not ServiceLine.FindSet() then
            exit;
        WarehouseShipmentLineLocal.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLineLocal.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLineLocal.SetRange("Source Subtype", ServiceHeader."Document Type");
        WarehouseShipmentLineLocal.SetRange("Source No.", ServiceHeader."No.");
        repeat
            WarehouseShipmentLineLocal.SetRange("Source Line No.", ServiceLine."Line No.");
            if WarehouseShipmentLineLocal.FindSet() then
                repeat
                    if WarehouseShipmentLineLocal."Qty. to Ship" <> 0 then begin
                        TempWarehouseShipmentLine := WarehouseShipmentLineLocal;
                        TempWarehouseShipmentLine.Insert();
                        WarehouseShipmentHeaderLocal.Get(WarehouseShipmentLineLocal."No.");
                        TempWarehouseShipmentHeader := WarehouseShipmentHeaderLocal;
                        if TempWarehouseShipmentHeader.Insert() then;
                    end;
                until WarehouseShipmentLineLocal.Next() = 0;
        until ServiceLine.Next() = 0;
    end;

    local procedure TestServLinePostingDate(ServHeaderDocType: Enum "Service Document Type"; ServHeaderNo: Code[20]; JnlTemplateName: Code[10])
    var
        ServLine: Record "Service Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        ServLine.SetRange("Document Type", ServHeaderDocType);
        ServLine.SetRange("Document No.", ServHeaderNo);
        ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
        if ServLine.FindSet() then
            repeat
                if GenJnlCheckLine.DateNotAllowed(ServLine."Posting Date", JnlTemplateName) then
                    ServLine.FieldError("Posting Date", ErrorInfo.Create(Text007, true));
            until ServLine.Next() = 0;
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    procedure GetPostedDocumentRecord(ServiceHeader: Record "Service Header"; var PostedServiceDocumentVariant: Variant)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order:
                if Invoice then begin
                    ServiceInvHeader.Get(ServiceHeader."Last Posting No.");
                    ServiceInvHeader.SetRecFilter();
                    PostedServiceDocumentVariant := ServiceInvHeader;
                end;
            ServiceHeader."Document Type"::Invoice:
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServiceInvHeader.Get(ServiceHeader."No.")
                    else
                        ServiceInvHeader.Get(ServiceHeader."Last Posting No.");

                    ServiceInvHeader.SetRecFilter();
                    PostedServiceDocumentVariant := ServiceInvHeader;
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServiceCrMemoHeader.Get(ServiceHeader."No.")
                    else
                        ServiceCrMemoHeader.Get(ServiceHeader."Last Posting No.");
                    ServiceCrMemoHeader.SetRecFilter();
                    PostedServiceDocumentVariant := ServiceCrMemoHeader;
                end;
            else
                Error(NotSupportedDocumentTypeErr, ServiceHeader."Document Type");
        end;
    end;

    procedure SendPostedDocumentRecord(ServiceHeader: Record "Service Header"; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Order:
                if Invoice then begin
                    ServiceInvHeader.Get(ServiceHeader."Last Posting No.");
                    ServiceInvHeader.SetRecFilter();
                    ServiceInvHeader.SendProfile(DocumentSendingProfile);
                end;
            ServiceHeader."Document Type"::Invoice:
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServiceInvHeader.Get(ServiceHeader."No.")
                    else
                        ServiceInvHeader.Get(ServiceHeader."Last Posting No.");

                    ServiceInvHeader.SetRecFilter();
                    ServiceInvHeader.SendProfile(DocumentSendingProfile);
                end;
            ServiceHeader."Document Type"::"Credit Memo":
                begin
                    if ServiceHeader."Last Posting No." = '' then
                        ServiceCrMemoHeader.Get(ServiceHeader."No.")
                    else
                        ServiceCrMemoHeader.Get(ServiceHeader."Last Posting No.");
                    ServiceCrMemoHeader.SetRecFilter();
                    ServiceCrMemoHeader.SendProfile(DocumentSendingProfile);
                end;
            else
                Error(NotSupportedDocumentTypeErr, ServiceHeader."Document Type");
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFinalizePostingOnBeforeCommit(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var ServDocumentsMgt: Codeunit "Serv-Documents Mgt."; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostServiceDoc(var ServiceHeader: Record "Service Header"; ServShipmentNo: Code[20]; ServInvoiceNo: Code[20]; ServCrMemoNo: Code[20]; var ServDocumentsMgt: Codeunit "Serv-Documents Mgt."; CommitIsSuppressed: Boolean; PassedShip: Boolean; PassedConsume: Boolean; PassedInvoice: Boolean; WhseShip: Boolean)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWithLines(var PassedServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostingAndDocumentDate(var ServiceHeader: Record "Service Header"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingAndDocumentDateOnAfterValidateDocumentDate(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAndSetPostingConstants(var ServiceHeader: Record "Service Header"; var ServDocumentsMgt: Codeunit "Serv-Documents Mgt."; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedWhseShptHeader(var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWithLines(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean; var PostingDateExists: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean; PreviewMode: Boolean; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetPostingDate(var PostingDateExists: Boolean; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShptHeaderInsert(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceCrMemoHeaderInsert(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestMandatoryFields(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseDocuments(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHeaderOnBeforeServiceShptLineInsert(var ServiceHeader: Record "Service Header"; var ServiceShipmentHeader: Record "Service Shipment Header"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHeaderOnBeforeServiceInvLineInsert(var ServiceHeader: Record "Service Header"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceInvoiceLine: Record "Service Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHeaderOnBeforeServiceCrMemoLineInsert(var ServiceHeader: Record "Service Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockTablesOnBeforeGLEntryFindLast(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestDeleteHeaderOnAfterServiceShptHeaderTransferFields(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestDeleteHeaderOnAfterServiceInvHeaderTransferFields(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestDeleteHeaderOnAfterServiceCrMemoHeaderTransferFields(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeOnAfterCheckAndSetPostingConstants(var PassedServiceHeader: Record "Service Header"; var PassedServiceLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteHeader(var ServiceHeader: Record "Service Header"; var ServiceShipmentHeader: Record "Service Shipment Header"; var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceCrMemoHeader: Record "Service Cr.Memo Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingAndDocumentDate(var ServiceHeader: Record "Service Header"; var PostingDateExists: Boolean; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDateNotAllowedForServiceLine(var PassedServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAndSetConstantsOnBeforeSetPostingOptions(var ServiceHeader: Record "Service Header"; Invoice: Boolean; Ship: Boolean)
    begin
    end;
}