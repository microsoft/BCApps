// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using System.Globalization;

report 9091 "Combine Service Shipments"
{
    ApplicationArea = Service;
    Caption = 'Combine Service Shipments';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(ServiceOrderHeader; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "Combine Shipments", "Customer No.", "Bill-to Customer No.", "Currency Code", "EU 3-Party Trade", "Dimension Set ID", "Journal Templ. Name") where("Document Type" = const(Order), "Combine Shipments" = const(true));
            RequestFilterFields = "Customer No.", "Bill-to Customer No.";
            RequestFilterHeading = 'Service Order';
            dataitem("Service Shipment Header"; "Service Shipment Header")
            {
                DataItemLink = "Order No." = field("No.");
                DataItemTableView = sorting("Order No.");
                RequestFilterFields = "Posting Date";
                RequestFilterHeading = 'Posted Service Shipment';
                dataitem("Service Shipment Line"; "Service Shipment Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemTableView = sorting("Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        CustIsBlocked: Boolean;
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeServiceShipmentLineOnAfterGetRecord("Service Shipment Line", IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        if Type = Type::" " then
                            if (not CopyTextLines) or ("Attached to Line No." <> 0) then
                                CurrReport.Skip();

                        if ("Qty. Shipped Not Invoiced" <> 0) or (Type = Type::" ") then begin
                            if ("Bill-to Customer No." <> Customer."No.") and
                               ("Customer No." <> '')
                            then
                                if "Bill-to Customer No." <> '' then
                                    Customer.Get("Bill-to Customer No.")
                                else
                                    if "Customer No." <> '' then
                                        Customer.Get("Customer No.");

                            CustIsBlocked := Customer.Blocked in [Customer.Blocked::All, Customer.Blocked::Invoice];
                            OnBeforeCustIsBlockedOnAfterGetRecord(ServiceOrderHeader, ServiceHeader, "Service Shipment Line", Customer, CustIsBlocked);
                            if not CustIsBlocked then begin
                                if ShouldFinalizeServiceInvHeader(ServiceOrderHeader, ServiceHeader, "Service Shipment Line") then begin
                                    if ServiceHeader."No." <> '' then
                                        FinalizeServiceInvHeader();
                                    InsertServiceInvHeader();
                                    ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                                    ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                                    ServiceLine."Document Type" := ServiceHeader."Document Type";
                                    ServiceLine."Document No." := ServiceHeader."No.";
                                end;
                                IsHandled := false;
                                OnServiceShipmentLineBeforeInsertInvLineFromShptLine("Service Shipment Line", IsHandled);
                                if not IsHandled then begin
                                    ServiceShipmentLine := "Service Shipment Line";
                                    HasAmount := HasAmount or ("Qty. Shipped Not Invoiced" <> 0);
                                    OnServiceShipmentLineOnAfterGetRecordOnBeforeInsertInvLineFromShptLine(ServiceLine, ServiceShipmentLine);
                                    ServiceShipmentLine.InsertInvLineFromShptLine(ServiceLine);
                                end;
                            end else
                                NoOfServiceInvErrors := NoOfServiceInvErrors + 1;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    DueDate: Date;
                    PmtDiscDate: Date;
                    PmtDiscPct: Decimal;
                begin
                    if GuiAllowed() then
                        Window.Update(3, "No.");

                    if IsCompletelyInvoiced() then
                        CurrReport.Skip();

                    if OnlyStdPmtTerms then begin
                        Customer.Get("Bill-to Customer No.");
                        PaymentTerms.Get(Customer."Payment Terms Code");
                        if PaymentTerms.Code = "Payment Terms Code" then begin
                            DueDate := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                            PmtDiscDate := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                            PmtDiscPct := PaymentTerms."Discount %";
                            if (DueDate <> "Due Date") or
                               (PmtDiscDate <> "Pmt. Discount Date") or
                               (PmtDiscPct <> "Payment Discount %")
                            then begin
                                NoOfskippedShiment := NoOfskippedShiment + 1;
                                CurrReport.Skip();
                            end;
                        end else begin
                            NoOfskippedShiment := NoOfskippedShiment + 1;
                            CurrReport.Skip();
                        end;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnAfterGetRecordServiceOrderHeader(ServiceOrderHeader, IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if GuiAllowed() then begin
                    Window.Update(1, "Bill-to Customer No.");
                    Window.Update(2, "No.");
                end
            end;

            trigger OnPostDataItem()
            begin
                CurrReport.Language := ReportLanguage;
                if ReportFormatRegion <> '' then
                    CurrReport.FormatRegion := ReportFormatRegion;
                if GuiAllowed() then
                    Window.Close();
                ShowResult();
            end;

            trigger OnPreDataItem()
            begin
                if PostingDateReq = 0D then
                    Error(Text000);
                if DocDateReq = 0D then
                    Error(Text001);
                if VATDateReq = 0D then
                    Error(VATDateEmptyErr);

                if GuiAllowed() then
                    Window.Open(
                      Text002 +
                      Text003 +
                      Text004 +
                      Text005);

                OnServiceOrderHeaderOnPreDataItem(ServiceOrderHeader);
                ReportLanguage := CurrReport.Language();
                ReportFormatRegion := CopyStr(CurrReport.FormatRegion(), 1, StrLen(ReportFormatRegion));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the invoice(s) that the batch job creates. This field must be filled in.';

                        trigger OnValidate()
                        begin
                            UpdateVATDate();
                        end;
                    }
                    field(DocDateReq; DocDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the invoice(s) that the batch job creates. This field must be filled in.';

                        trigger OnValidate()
                        begin
                            UpdateVATDate();
                        end;
                    }
                    field(VATDate; VATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies the VAT Date for the invoice(s) that the batch job creates. This field must be filled in.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the shipment.';

                        trigger OnValidate()
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PostInv; PostInv)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Invoices';
                        ToolTip = 'Specifies if you want to have the invoices posted immediately.';
                    }
                    field(OnlyStdPmtTerms; OnlyStdPmtTerms)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Std. Payment Terms';
                        ToolTip = 'Specifies if you want to include shipments with standard payments terms. If you select this option, you must manually invoice all other shipments.';
                    }
                    field(CopyTextLines; CopyTextLines)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy Text Lines';
                        ToolTip = 'Specifies if you want manually written text on the shipment lines to be copied to the invoice.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
            IsHandled: Boolean;
        begin
            IsHandled := false;
            OnBeforeOnOpenPage(IsHandled);
            if IsHandled then
                exit;

            if PostingDateReq = 0D then
                PostingDateReq := WorkDate();
            if DocDateReq = 0D then
                DocDateReq := WorkDate();
            if VATDateReq = 0D then
                VATDateReq := GeneralLedgerSetup.GetVATDate(PostingDateReq, DocDateReq);
            SalesSetup.Get();
            CalcInvDisc := SalesSetup."Calc. Inv. Discount";
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnBeforePostReport();
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport();
    end;

    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        SalesSetup: Record "Sales & Receivables Setup";
        ServiceCalcDiscount: Codeunit "Service-Calc. Discount";
        ServicePost: Codeunit "Service-Post";
        HideDialog: Boolean;
        Window: Dialog;
        NoOfServiceInv: Integer;
        NoOfskippedShiment: Integer;
        NotAllInvoicesCreatedMsg: Label 'Not all the invoices were created. A total of %1 invoices were not created.', Comment = '%1-Number of invoices';
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Enter the document date.';
        Text002: Label 'Combining shipments...\\';
        Text003: Label 'Customer No.    #1##########\';
        Text004: Label 'Order No.       #2##########\';
        Text005: Label 'Shipment No.    #3##########';
        Text007: Label 'Not all the invoices were posted. A total of %1 invoices were not posted.';
        Text008: Label 'There is nothing to combine.';
        Text010: Label 'The shipments are now combined and the number of invoices created is %1.';
        Text011: Label 'The shipments are now combined, and the number of invoices created is %1.\%2 Shipments with nonstandard payment terms have not been combined.', Comment = '%1-Number of invoices,%2-Number Of shipments';
        VATDateEmptyErr: Label 'Enter the VAT date.';

    protected var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        LanguageMgt: Codeunit Language;
        CalcInvDisc: Boolean;
        CopyTextLines: Boolean;
        HasAmount: Boolean;
        OnlyStdPmtTerms: Boolean;
        PostInv: Boolean;
        VATDateEnabled: Boolean;
        DocDateReq: Date;
        PostingDateReq: Date;
        VATDateReq: Date;
        NoOfServiceInvErrors: Integer;
        ReportLanguage: Integer;
        ReportFormatRegion: Text[80];


    local procedure FinalizeServiceInvHeader()
    var
        HasError: Boolean;
        ShouldPostInv: Boolean;
    begin
        HasError := false;
        OnBeforeFinalizeServiceInvHeader(ServiceHeader, HasAmount, HasError);
        if HasError then
            NoOfServiceInvErrors += 1;

        if (not HasAmount) or HasError then begin
            OnFinalizeServiceInvHeaderOnBeforeDelete(ServiceHeader);
            ServiceHeader.Delete(true);
            OnFinalizeServiceInvHeaderOnAfterDelete(ServiceHeader);
            exit;
        end;
        OnFinalizeServiceInvHeader(ServiceHeader);
        if CalcInvDisc then
            ServiceCalcDiscount.Run(ServiceLine);
        ServiceHeader.Find();
        Commit();
        Clear(ServiceCalcDiscount);
        Clear(ServicePost);
        NoOfServiceInv := NoOfServiceInv + 1;
        ShouldPostInv := PostInv;
        OnFinalizeServiceInvHeaderOnAfterCalcShouldPostInv(ServiceHeader, NoOfServiceInv, ShouldPostInv);
        if ShouldPostInv then begin
            Clear(ServicePost);
            if not ServicePost.Run(ServiceHeader) then
                NoOfServiceInvErrors := NoOfServiceInvErrors + 1;
        end;
    end;

    local procedure InsertServiceInvHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServiceInvHeader(ServiceHeader, ServiceOrderHeader, "Service Shipment Header", "Service Shipment Line", NoOfServiceInv, HasAmount, IsHandled);
        if not IsHandled then begin
            GeneralLedgerSetup.Get();
            Clear(ServiceHeader);
            ServiceHeader.Init();
            ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
            ServiceHeader."No." := '';
            OnBeforeServiceInvHeaderInsert(ServiceHeader, ServiceOrderHeader);
            ServiceHeader.Insert(true);
            ValidateCustomerNo(ServiceHeader, ServiceOrderHeader);
            ServiceHeader.Validate("Posting Date", PostingDateReq);
            ServiceHeader.Validate("Document Date", DocDateReq);
            ServiceHeader.Validate("VAT Reporting Date", VATDateReq);
            ServiceHeader.Validate("Currency Code", ServiceOrderHeader."Currency Code");
            ServiceHeader.Validate("EU 3-Party Trade", ServiceOrderHeader."EU 3-Party Trade");
            if GeneralLedgerSetup."Journal Templ. Name Mandatory" then
                ServiceHeader.Validate("Journal Templ. Name", ServiceOrderHeader."Journal Templ. Name");
            ServiceHeader."Salesperson Code" := ServiceOrderHeader."Salesperson Code";
            ServiceHeader."Shortcut Dimension 1 Code" := ServiceOrderHeader."Shortcut Dimension 1 Code";
            ServiceHeader."Shortcut Dimension 2 Code" := ServiceOrderHeader."Shortcut Dimension 2 Code";
            ServiceHeader."Dimension Set ID" := ServiceOrderHeader."Dimension Set ID";
            OnBeforeServiceInvHeaderModify(ServiceHeader, ServiceOrderHeader);
            ServiceHeader.Modify();
            Commit();
            HasAmount := false;
        end;
        OnAfterInsertServiceInvHeader(ServiceHeader, "Service Shipment Header");
    end;

    procedure InitializeRequest(NewPostingDate: Date; NewDocDate: Date; NewCalcInvDisc: Boolean; NewPostInv: Boolean; NewOnlyStdPmtTerms: Boolean; NewCopyTextLines: Boolean)
    begin
        PostingDateReq := NewPostingDate;
        DocDateReq := NewDocDate;
        VATDateReq := GeneralLedgerSetup.GetVATDate(PostingDateReq, DocDateReq);
        CalcInvDisc := NewCalcInvDisc;
        PostInv := NewPostInv;
        OnlyStdPmtTerms := NewOnlyStdPmtTerms;
        CopyTextLines := NewCopyTextLines;
    end;

    procedure InitializeRequest(NewPostingDate: Date; NewDocDate: Date; NewVATDate: Date; NewCalcInvDisc: Boolean; NewPostInv: Boolean; NewOnlyStdPmtTerms: Boolean; NewCopyTextLines: Boolean)
    begin
        InitializeRequest(NewPostingDate, NewDocDate, NewCalcInvDisc, NewPostInv, NewOnlyStdPmtTerms, NewCopyTextLines);
        VATDateReq := NewVATDate;
    end;

    local procedure ValidateCustomerNo(var ToServiceHeader: Record "Service Header"; FromServiceOrderHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCustomerNo(ToServiceHeader, FromServiceOrderHeader, "Service Shipment Header", "Service Shipment Line", IsHandled);
        if IsHandled then
            exit;

        ToServiceHeader.Validate("Customer No.", FromServiceOrderHeader."Customer No.");
        ToServiceHeader.Validate("Bill-to Customer No.", FromServiceOrderHeader."Bill-to Customer No.");
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure ShowResult()
    begin
        OnBeforeShowResult(ServiceHeader, NoOfServiceInvErrors, PostInv);

        if ServiceHeader."No." <> '' then begin // Not the first time
            FinalizeServiceInvHeader();
            OnServiceShipmentHeaderOnAfterFinalizeServiceInvHeader(ServiceHeader, NoOfServiceInvErrors, PostInv, HideDialog);
            if (NoOfServiceInvErrors = 0) and not HideDialog then begin
                if NoOfskippedShiment > 0 then
                    Message(Text011, NoOfServiceInv, NoOfskippedShiment)
                else
                    Message(Text010, NoOfServiceInv);
            end else
                if not HideDialog then
                    if PostInv then
                        Message(Text007, NoOfServiceInvErrors)
                    else
                        Message(NotAllInvoicesCreatedMsg, NoOfServiceInvErrors)
        end else
            if not HideDialog then
                Message(Text008);
    end;

    local procedure ShouldFinalizeServiceInvHeader(ServiceOrderHeader: Record "Service Header"; ServiceHeader: Record "Service Header"; ServiceShipmentLine: Record "Service Shipment Line") Finalize: Boolean
    begin
        Finalize :=
          (ServiceOrderHeader."Customer No." <> ServiceHeader."Customer No.") or
          (ServiceOrderHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No.") or
          (ServiceOrderHeader."Currency Code" <> ServiceHeader."Currency Code") or
          (ServiceOrderHeader."EU 3-Party Trade" <> ServiceHeader."EU 3-Party Trade") or
          (ServiceOrderHeader."Dimension Set ID" <> ServiceHeader."Dimension Set ID") or
          (ServiceOrderHeader."Journal Templ. Name" <> ServiceHeader."Journal Templ. Name");

        OnAfterShouldFinalizeServiceInvHeader(ServiceOrderHeader, ServiceHeader, Finalize, ServiceShipmentLine, "Service Shipment Header");
        exit(Finalize);
    end;

    local procedure UpdateVATDate()
    begin
        VATDateReq := GeneralLedgerSetup.GetVATDate(PostingDateReq, DocDateReq);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordServiceOrderHeader(var ServiceOrderHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertServiceInvHeader(var ServiceHeader: Record "Service Header"; var ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeServiceInvHeader(var ServiceHeader: Record "Service Header"; var HasAmount: Boolean; var HasError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceInvHeader(var ServiceInvoiceHeader: Record "Service Header"; ServiceOrderHeader: Record "Service Header"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line"; var NoOfServiceInv: Integer; var HasAmount: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvHeaderInsert(var ServiceHeader: Record "Service Header"; ServiceOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResult(var ServiceInvoiceHeader: Record "Service Header"; var NoOfServiceInvErrors: Integer; PostInvoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvHeaderModify(var ServiceHeader: Record "Service Header"; ServiceOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceShipmentLineOnAfterGetRecord(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNo(var ToServiceHeader: Record "Service Header"; var FromServiceOrderHeader: Record "Service Header"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeServiceInvHeader(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeServiceInvHeaderOnAfterDelete(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeServiceInvHeaderOnAfterCalcShouldPostInv(var ServiceHeader: Record "Service Header"; var NoOfServiceInv: Integer; var ShouldPostInv: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeServiceInvHeaderOnBeforeDelete(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceOrderHeaderOnPreDataItem(var ServiceOrderHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldFinalizeServiceInvHeader(var ServiceOrderHeader: Record "Service Header"; ServiceHeader: Record "Service Header"; var Finalize: Boolean; ServiceShipmentLine: Record "Service Shipment Line"; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceShipmentLineOnAfterGetRecordOnBeforeInsertInvLineFromShptLine(var ServiceLine: Record "Service Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceShipmentLineBeforeInsertInvLineFromShptLine(ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnServiceShipmentHeaderOnAfterFinalizeServiceInvHeader(var ServiceHeader: Record "Service Header"; var NoOfServiceInvErrors: Integer; PostInvoice: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustIsBlockedOnAfterGetRecord(OrderServiceHeader: Record "Service Header"; ServiceHeader: Record "Service Header"; ServiceShipmentLine: Record "Service Shipment Line"; Customer: Record Customer; var CustIsBlocked: Boolean)
    begin
    end;
}