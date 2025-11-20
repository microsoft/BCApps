// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Archive;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

report 292 "Copy Sales Document"
{
    Caption = 'Copy Sales Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentType; FromDocType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document Type';
                        ToolTip = 'Specifies the type of document that is processed by the report or batch job.';

                        trigger OnValidate()
                        begin
                            FromDocNo := '';
                            ValidateDocNo();
                        end;
                    }
                    field(DocumentNo; FromDocNo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Document No.';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo();
                        end;
                    }
                    field(FromDocNoOccurrence; FromDocNoOccurrence)
                    {
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Doc. No. Occurrence';
                        Editable = false;
                        ToolTip = 'Specifies the number of times the No. value has been used in the number series.';
                    }
                    field(FromDocVersionNo; FromDocVersionNo)
                    {
                        ApplicationArea = Suite;
                        BlankZero = true;
                        Caption = 'Version No.';
                        Editable = false;
                        ToolTip = 'Specifies the version of the document to be copied.';
                    }
                    field(SellToCustNo; FromSalesHeader."Sell-to Customer No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sell-to Customer No.';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer number that will appear on the new sales document.';
                    }
                    field(SellToCustName; FromSalesHeader."Sell-to Customer Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sell-to Customer Name';
                        Editable = false;
                        ToolTip = 'Specifies the sell-to customer name that will appear on the new sales document.';
                    }
                    field(IncludeHeader_Options; IncludeHeader)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the information from the document header. When you copy quotes, if the posting date field of the new document is empty, the work date is used as the posting date of the new document.';

                        trigger OnValidate()
                        begin
                            ValidateIncludeHeader();
                        end;
                    }
                    field(RecalculateLines; RecalculateLines)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recalculate Lines';
                        ToolTip = 'Specifies that lines are recalculate and inserted on the sales document you are creating. The batch job retains the item numbers and item quantities but recalculates the amounts on the lines based on the customer information on the new document header. In this way, the batch job accounts for item prices and discounts that are specifically linked to the customer on the new header.';

                        trigger OnValidate()
                        begin
                            if (FromDocType = FromDocType::"Posted Shipment") or (FromDocType = FromDocType::"Posted Return Receipt") then
                                RecalculateLines := true;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FromDocNo <> '' then begin
                case FromDocType of
                    FromDocType::Quote:
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Quote, FromDocNo) then
                            ;
                    FromDocType::"Blanket Order":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Blanket Order", FromDocNo) then
                            ;
                    FromDocType::Order:
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Order, FromDocNo) then
                            ;
                    FromDocType::Invoice:
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::Invoice, FromDocNo) then
                            ;
                    FromDocType::"Return Order":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Return Order", FromDocNo) then
                            ;
                    FromDocType::"Credit Memo":
                        if FromSalesHeader.Get(FromSalesHeader."Document Type"::"Credit Memo", FromDocNo) then
                            ;
                    FromDocType::"Posted Shipment":
                        if FromSalesShptHeader.Get(FromDocNo) then
                            FromSalesHeader.TransferFields(FromSalesShptHeader);
                    FromDocType::"Posted Invoice":
                        if FromSalesInvHeader.Get(FromDocNo) then
                            FromSalesHeader.TransferFields(FromSalesInvHeader);
                    FromDocType::"Posted Return Receipt":
                        if FromReturnRcptHeader.Get(FromDocNo) then
                            FromSalesHeader.TransferFields(FromReturnRcptHeader);
                    FromDocType::"Posted Credit Memo":
                        if FromSalesCrMemoHeader.Get(FromDocNo) then
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                    FromDocType::"Arch. Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::Order, FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    FromDocType::"Arch. Quote":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::Quote, FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    FromDocType::"Arch. Blanket Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::"Blanket Order", FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                    FromDocType::"Arch. Return Order":
                        if FromSalesHeaderArchive.Get(FromSalesHeaderArchive."Document Type"::"Return Order", FromDocNo, FromDocNoOccurrence, FromDocVersionNo) then
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                end;
                if FromSalesHeader."No." = '' then
                    FromDocNo := '';
            end;
            ValidateDocNo();

            OnAfterOpenPage();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::OK then
                if FromDocNo = '' then
                    Error(DocNoNotSerErr)
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ExactCostReversingMandatory: Boolean;
    begin
        OnBeforePreReport();

        SalesSetup.Get();
        ExactCostReversingMandatory := SalesSetup."Exact Cost Reversing Mandatory";

        OnPreReportOnBeforeCopyDocMgtSetProperties(FromDocType, FromDocNo, SalesHeader, ExactCostReversingMandatory);
        CopyDocMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, ExactCostReversingMandatory, false);
        CopyDocMgt.SetArchDocVal(FromDocNoOccurrence, FromDocVersionNo);

        OnPreReportOnBeforeCopySalesDoc(CopyDocMgt, FromDocType.AsInteger(), FromDocNo, SalesHeader, CurrReport.UseRequestPage(), IncludeHeader, RecalculateLines, ExactCostReversingMandatory);

        CopyDocMgt.CopySalesDoc(FromDocType, FromDocNo, SalesHeader);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The price information may not be reversed correctly, if you copy a %1. If possible copy a %2 instead or use %3 functionality.';
#pragma warning restore AA0470
        Text001: Label 'Undo Shipment';
        Text002: Label 'Undo Return Receipt';
#pragma warning restore AA0074
        DocNoNotSerErr: Label 'Select a document number to continue, or choose Cancel to close the page.';

    protected var
        SalesHeader: Record "Sales Header";
        FromSalesHeader: Record "Sales Header";
        FromSalesShptHeader: Record "Sales Shipment Header";
        FromSalesInvHeader: Record "Sales Invoice Header";
        FromReturnRcptHeader: Record "Return Receipt Header";
        FromSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FromSalesHeaderArchive: Record "Sales Header Archive";
        SalesSetup: Record "Sales & Receivables Setup";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        FromDocType: Enum "Sales Document Type From";
        FromDocNo: Code[20];
        FromDocNoOccurrence: Integer;
        FromDocVersionNo: Integer;
        IncludeHeader: Boolean;
        RecalculateLines: Boolean;

    procedure SetSalesHeader(var NewSalesHeader: Record "Sales Header")
    begin
        NewSalesHeader.TestField("No.");
        SalesHeader := NewSalesHeader;
    end;

    local procedure ValidateDocNo()
    var
        FromDocType2: Enum "Sales Document Type From";
    begin
        if FromDocNo = '' then begin
            FromSalesHeader.Init();
            FromDocNoOccurrence := 0;
            FromDocVersionNo := 0;
        end else
            if FromSalesHeader."No." = '' then begin
                FromSalesHeader.Init();
                case FromDocType of
                    FromDocType::Quote,
                    FromDocType::Order,
                    FromDocType::Invoice,
                    FromDocType::"Credit Memo",
                    FromDocType::"Blanket Order",
                    FromDocType::"Return Order":
                        FromSalesHeader.Get(CopyDocMgt.GetSalesDocumentType(FromDocType), FromDocNo);
                    FromDocType::"Posted Shipment":
                        begin
                            FromSalesShptHeader.Get(FromDocNo);
                            FromSalesHeader.TransferFields(FromSalesShptHeader);
                            if SalesHeader."Document Type" in
                               [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"]
                            then begin
                                FromDocType2 := FromDocType2::"Posted Invoice";
                                Message(Text000, FromDocType, FromDocType2, Text001);
                            end;
                        end;
                    FromDocType::"Posted Invoice":
                        begin
                            FromSalesInvHeader.Get(FromDocNo);
                            FromSalesHeader.TransferFields(FromSalesInvHeader);
                            OnValidateDocNoOnAfterTransferFieldsFromSalesInvHeader(FromSalesHeader, FromSalesInvHeader);
                        end;
                    FromDocType::"Posted Return Receipt":
                        begin
                            FromReturnRcptHeader.Get(FromDocNo);
                            FromSalesHeader.TransferFields(FromReturnRcptHeader);
                            OnValidateDocNoOnAfterTransferFieldsFromReturnReceiptHeader(FromSalesHeader, FromReturnRcptHeader);
                            if SalesHeader."Document Type" in
                               [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]
                            then begin
                                FromDocType2 := FromDocType2::"Posted Credit Memo";
                                Message(Text000, FromDocType, FromDocType2, Text002);
                            end;
                        end;
                    FromDocType::"Posted Credit Memo":
                        begin
                            FromSalesCrMemoHeader.Get(FromDocNo);
                            FromSalesHeader.TransferFields(FromSalesCrMemoHeader);
                            OnValidateDocNoOnAfterTransferFieldsFromSalesCrMemoHeader(FromSalesHeader, FromSalesCrMemoHeader);
                        end;
                    FromDocType::"Arch. Quote",
                    FromDocType::"Arch. Order",
                    FromDocType::"Arch. Blanket Order",
                    FromDocType::"Arch. Return Order":
                        begin
                            FindFromSalesHeaderArchive();
                            FromSalesHeader.TransferFields(FromSalesHeaderArchive);
                        end;
                end;
            end;
        FromSalesHeader."No." := '';

        IncludeHeader :=
          (FromDocType in [FromDocType::"Posted Invoice", FromDocType::"Posted Credit Memo"]) and
          ((FromDocType = FromDocType::"Posted Credit Memo") <>
           (SalesHeader."Document Type" in
            [SalesHeader."Document Type"::"Return Order", SalesHeader."Document Type"::"Credit Memo"])) and
          (SalesHeader."Bill-to Customer No." in [FromSalesHeader."Bill-to Customer No.", '']);

        OnBeforeValidateIncludeHeader(IncludeHeader, FromSalesHeader);
        ValidateIncludeHeader();
        OnAfterValidateIncludeHeader(IncludeHeader, RecalculateLines);
    end;

    local procedure FindFromSalesHeaderArchive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindFromSalesHeaderArchive(FromSalesHeaderArchive, FromDocType, FromDocNo, FromDocNoOccurrence, FromDocVersionNo, IsHandled);
        if IsHandled then
            exit;

        if not FromSalesHeaderArchive.Get(
             CopyDocMgt.GetSalesDocumentType(FromDocType), FromDocNo, FromDocNoOccurrence, FromDocVersionNo)
        then begin
            FromSalesHeaderArchive.SetRange("No.", FromDocNo);
            if FromSalesHeaderArchive.FindLast() then begin
                FromDocNoOccurrence := FromSalesHeaderArchive."Doc. No. Occurrence";
                FromDocVersionNo := FromSalesHeaderArchive."Version No.";
            end;
        end;
    end;

    procedure LookupDocNo()
    begin
        OnBeforeLookupDocNo(SalesHeader, FromDocType, FromDocNo);

        case FromDocType of
            FromDocType::Quote,
            FromDocType::Order,
            FromDocType::Invoice,
            FromDocType::"Credit Memo",
            FromDocType::"Blanket Order",
            FromDocType::"Return Order":
                LookupSalesDoc();
            FromDocType::"Posted Shipment":
                LookupPostedShipment();
            FromDocType::"Posted Invoice":
                LookupPostedInvoice();
            FromDocType::"Posted Return Receipt":
                LookupPostedReturn();
            FromDocType::"Posted Credit Memo":
                LookupPostedCrMemo();
            FromDocType::"Arch. Quote",
            FromDocType::"Arch. Order",
            FromDocType::"Arch. Blanket Order",
            FromDocType::"Arch. Return Order":
                LookupSalesArchive();
        end;

        ValidateDocNo();
    end;

    local procedure LookupSalesDoc()
    begin
        OnBeforeLookupSalesDoc(FromSalesHeader, SalesHeader, FromDocType);

        FromSalesHeader.FilterGroup := 0;
        FromSalesHeader.SetRange("Document Type", CopyDocMgt.GetSalesDocumentType(FromDocType));
        if SalesHeader."Document Type" = CopyDocMgt.GetSalesDocumentType(FromDocType) then
            FromSalesHeader.SetFilter("No.", '<>%1', SalesHeader."No.");
        FromSalesHeader.FilterGroup := 2;
        FromSalesHeader."Document Type" := CopyDocMgt.GetSalesDocumentType(FromDocType);
        FromSalesHeader."No." := FromDocNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesHeader.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromSalesHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesHeader.Find('=><') then;
            end;
        OnLookupSalesDocOnBeforeRunLookup(FromSalesHeader, SalesHeader, FromDocType);
        if Page.RunModal(0, FromSalesHeader) = Action::LookupOK then
            FromDocNo := FromSalesHeader."No.";
    end;

    local procedure LookupSalesArchive()
    begin
        FromSalesHeaderArchive.Reset();
        OnLookupSalesArchiveOnBeforeSetFilters(FromSalesHeaderArchive, SalesHeader, FromDocType);
        FromSalesHeaderArchive.FilterGroup := 0;
        FromSalesHeaderArchive.SetRange("Document Type", CopyDocMgt.GetSalesDocumentType(FromDocType));
        FromSalesHeaderArchive.FilterGroup := 2;
        FromSalesHeaderArchive."Document Type" := CopyDocMgt.GetSalesDocumentType(FromDocType);
        FromSalesHeaderArchive."No." := FromDocNo;
        FromSalesHeaderArchive."Doc. No. Occurrence" := FromDocNoOccurrence;
        FromSalesHeaderArchive."Version No." := FromDocVersionNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesHeaderArchive.SetCurrentKey("Document Type", "Sell-to Customer No.") then begin
                FromSalesHeaderArchive."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesHeaderArchive.Find('=><') then;
            end;
        if Page.RunModal(0, FromSalesHeaderArchive) = Action::LookupOK then begin
            FromDocNo := FromSalesHeaderArchive."No.";
            FromDocNoOccurrence := FromSalesHeaderArchive."Doc. No. Occurrence";
            FromDocVersionNo := FromSalesHeaderArchive."Version No.";
            RequestOptionsPage.Update(false);
        end;
    end;

    local procedure LookupPostedShipment()
    begin
        OnBeforeLookupPostedShipment(FromSalesShptHeader, SalesHeader);

        FromSalesShptHeader."No." := FromDocNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesShptHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesShptHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesShptHeader.Find('=><') then;
            end;
        if Page.RunModal(0, FromSalesShptHeader) = Action::LookupOK then
            FromDocNo := FromSalesShptHeader."No.";
    end;

    local procedure LookupPostedInvoice()
    begin
        OnBeforeLookupPostedInvoice(FromSalesInvHeader, SalesHeader);

        FromSalesInvHeader."No." := FromDocNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesInvHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesInvHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesInvHeader.Find('=><') then;
            end;
        FromSalesInvHeader.FilterGroup(2);
        FromSalesInvHeader.SetRange("Prepayment Invoice", false);
        FromSalesInvHeader.FilterGroup(0);
        OnLookupPostedInvoiceOnBeforeRunLookup(FromSalesInvHeader, SalesHeader);
        if Page.RunModal(0, FromSalesInvHeader) = Action::LookupOK then
            FromDocNo := FromSalesInvHeader."No.";
    end;

    local procedure LookupPostedCrMemo()
    begin
        OnBeforeLookupPostedCrMemo(FromSalesCrMemoHeader, SalesHeader);

        FromSalesCrMemoHeader."No." := FromDocNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromSalesCrMemoHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromSalesCrMemoHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromSalesCrMemoHeader.Find('=><') then;
            end;
        FromSalesCrMemoHeader.FilterGroup(2);
        FromSalesCrMemoHeader.SetRange("Prepayment Credit Memo", false);
        FromSalesCrMemoHeader.FilterGroup(0);
        OnLookupPostedCrMemoOnBeforeRunLookup(FromSalesCrMemoHeader, SalesHeader);
        if Page.RunModal(0, FromSalesCrMemoHeader) = Action::LookupOK then
            FromDocNo := FromSalesCrMemoHeader."No.";
    end;

    local procedure LookupPostedReturn()
    begin
        OnBeforeLookupPostedReturn(FromReturnRcptHeader, SalesHeader);

        FromReturnRcptHeader."No." := FromDocNo;
        if (FromDocNo = '') and (SalesHeader."Sell-to Customer No." <> '') then
            if FromReturnRcptHeader.SetCurrentKey("Sell-to Customer No.") then begin
                FromReturnRcptHeader."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                if FromReturnRcptHeader.Find('=><') then;
            end;
        if Page.RunModal(0, FromReturnRcptHeader) = Action::LookupOK then
            FromDocNo := FromReturnRcptHeader."No.";
    end;

    local procedure ValidateIncludeHeader()
    begin
        RecalculateLines :=
          (FromDocType in [FromDocType::"Posted Shipment", FromDocType::"Posted Return Receipt"]) or not IncludeHeader;

        OnAfterValidateIncludeHeaderProcedure(IncludeHeader, RecalculateLines, SalesHeader, FromDocType);
    end;

    procedure SetParameters(NewFromDocType: Enum "Sales Document Type From"; NewFromDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        SetParameters(NewFromDocType, NewFromDocNo, 0, 0, NewIncludeHeader, NewRecalcLines);
    end;

    procedure SetParameters(NewFromDocType: Enum "Sales Document Type From"; NewFromDocNo: Code[20]; NewFromDocNoOccurrence: Integer; NewFromDocVersionNo: Integer; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    begin
        FromDocType := NewFromDocType;
        FromDocNo := NewFromDocNo;
        FromDocNoOccurrence := NewFromDocNoOccurrence;
        FromDocVersionNo := NewFromDocVersionNo;
        IncludeHeader := NewIncludeHeader;
        RecalculateLines := NewRecalcLines;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterValidateIncludeHeader(var IncludeHeader: Boolean; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterValidateIncludeHeaderProcedure(var IncludeHeader: Boolean; var RecalculateLines: Boolean; SalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromSalesHeaderArchive(var FromSalesHeaderArchive: Record "Sales Header Archive"; DocType: Enum "Sales Document Type From"; DocNo: Code[20]; var DocNoOccurrence: Integer; var DocVersionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocNo(var SalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From"; var FromDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSalesDoc(var FromSalesHeader: Record "Sales Header"; var SalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedCrMemo(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedInvoice(var FromSalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedShipment(var FromSalesShptHeader: Record "Sales Shipment Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostedReturn(var FromReturnRcptHeader: Record "Return Receipt Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateIncludeHeader(var DoIncludeHeader: Boolean; FromSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSalesArchiveOnBeforeSetFilters(var FromSalesHeaderArchive: Record "Sales Header Archive"; var SalesHeader: Record "Sales Header"; FromDocType: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPreReportOnBeforeCopySalesDoc(var CopyDocumentMgt: Codeunit "Copy Document Mgt."; DocType: Integer; DocNo: Code[20]; SalesHeader: Record "Sales Header"; CurrReportUseRequestPage: Boolean; IncludeHeader: Boolean; RecalculateLines: Boolean; ExactCostReversingMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreReportOnBeforeCopyDocMgtSetProperties(FromDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; SalesHeader: Record "Sales Header"; var ExactCostReversingMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromSalesInvHeader(FromSalesHeader: Record "Sales Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromSalesCrMemoHeader(FromSalesHeader: Record "Sales Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDocNoOnAfterTransferFieldsFromReturnReceiptHeader(FromSalesHeader: Record "Sales Header"; FromReturnReceiptHeader: Record "Return Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSalesDocOnBeforeRunLookup(var FromSalesHeader: Record "Sales Header"; var SalesHeader: Record "Sales Header"; SalesDocumentTypeFrom: Enum "Sales Document Type From")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupPostedInvoiceOnBeforeRunLookup(var FromSalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupPostedCrMemoOnBeforeRunLookup(var FromSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header");
    begin
    end;
}

