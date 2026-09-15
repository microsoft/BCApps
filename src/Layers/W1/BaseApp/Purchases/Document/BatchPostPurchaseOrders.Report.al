// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using System.Environment;
using System.Security.User;

report 496 "Batch Post Purchase Orders"
{
    Caption = 'Batch Post Purchase Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Purchase Order';

            trigger OnPreDataItem()
            var
                PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
            begin
                OnBeforePurchaseBatchPostMgt("Purchase Header", ReceiveReq, InvReq, PurchaseBatchPostMgt);

                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Print, PrintDoc);
                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDateReq);
                PurchaseBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"VAT Date", VATDateReq);
                PurchaseBatchPostMgt.RunBatch(
                  "Purchase Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, ReceiveReq, InvReq);

                OnAfterPurchaseBatchPostMgt("Purchase Header", PurchaseBatchPostMgt);

                CurrReport.Break();
            end;
        }
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
                    field(Receive; ReceiveReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Receive';
                        ToolTip = 'Specifies whether the purchase orders will be received when posted. If you place a check mark in the box, it will apply to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Suite;
                        Editable = PostInvoiceEditable;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies whether the purchase orders will be invoiced when posted. If you place a check mark in the box, it will apply to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program will use as the document and/or posting date when you post if you place a checkmark in one or both of the following boxes.';

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
                        ToolTip = 'Specifies the date that the program will use as the VAT date when you post if you place a checkmark in Replace VAT Date.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the orders'' posting date with the date entered in the field above.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);

                            if VATReportingDateMgt.IsVATDateUsageSetToPostingDate() then
                                ReplaceVATDateReq := ReplacePostingDate;
                            UpdateVATDate();
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the purchase orders'' document date with the date in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if VATReportingDateMgt.IsVATDateUsageSetToDocumentDate() then
                                ReplaceVATDateReq := ReplaceDocumentDate;
                            UpdateVATDate();
                        end;
                    }
                    field(ReplaceVATDate; ReplaceVATDateReq)
                    {
                        ApplicationArea = VAT;
                        Caption = 'Replace VAT Date';
                        Editable = VATDateEnabled;
                        Visible = VATDateEnabled;
                        ToolTip = 'Specifies if you want to replace the purchase orders'' VAT date with the date in the VAT Date field.';
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            PurchasesPayablesSetup.Get();
                            PurchasesPayablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the order after posting. In the Report Output Type field on the Purchases and Payables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                        begin
                            if PrintDoc then begin
                                PurchasesPayablesSetup.Get();
                                if PurchasesPayablesSetup."Post with Job Queue" then
                                    PurchasesPayablesSetup.TestField("Post & Print with Job Queue");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            PurchasesPayablesSetup: Record "Purchases & Payables Setup";
            ClientTypeManagement: Codeunit "Client Type Management";
            UserSetupManagement: Codeunit "User Setup Management";
            Receive: Boolean;
            Invoice: Boolean;
        begin
            if not VATReportingDateMgt.IsVATDateEnabled() then begin
                ReplaceVATDateReq := ReplacePostingDate;
                VATDateReq := PostingDateReq;
            end;
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            PurchasesPayablesSetup.Get();
            CalcInvDisc := PurchasesPayablesSetup."Calc. Inv. Discount";
            PrintDoc := false;
            PrintDocVisible := PurchasesPayablesSetup."Post & Print with Job Queue";
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
            UserSetupManagement.GetPurchaseInvoicePostingPolicy(Receive, Invoice);
            if Receive then
                InvReq := Invoice;
            PostInvoiceEditable := not Receive;
            OnAfterOnOpenPage(ReceiveReq, InvReq, PostingDateReq, ReplacePostingDate, ReplaceDocumentDate, CalcInvDisc, ReplaceVATDateReq, VATDateReq);
        end;
    }

    labels
    {
    }

    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
#pragma warning disable AA0074
        Text003: Label 'The exchange rate associated with the new posting date on the purchase header will not apply to the purchase lines.';
#pragma warning restore AA0074

    protected var
        ReceiveReq: Boolean;
        InvReq: Boolean;
        PostingDateReq, VATDateReq : Date;
        ReplacePostingDate, ReplaceVATDateReq : Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        PrintDocVisible: Boolean;
        VATDateEnabled: Boolean;
        PostInvoiceEditable: Boolean;

    procedure InitializeRequest(NewReceiveReq: Boolean; NewInvReq: Boolean; NewPostingDateReq: Date; NewVatDateReq: Date; NewReplacePostingDate: Boolean; NewReplaceDocumentDate: Boolean; NewReplaceVATDate: Boolean; NewCalcInvDisc: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        ReceiveReq := NewReceiveReq;
        InvReq := NewInvReq;
        PostingDateReq := NewPostingDateReq;
        VATDateReq := NewVatDateReq;
        ReplaceVATDateReq := NewReplaceVATDate;
        ReplacePostingDate := NewReplacePostingDate;
        ReplaceDocumentDate := NewReplaceDocumentDate;
        if NewCalcInvDisc then
            PurchasesPayablesSetup.TestField("Calc. Inv. Discount", false);
        CalcInvDisc := NewCalcInvDisc;
    end;

    local procedure UpdateVATDate()
    begin
        if ReplaceVATDateReq then
            VATDateReq := PostingDateReq;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var ReceiveReq: Boolean; var InvReq: Boolean; var PostingDateReq: Date; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var CalcInvDisc: Boolean; var ReplaceVATDateReq: Boolean; var VATDateReq: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseBatchPostMgt(var PurchaseHeader: Record "Purchase Header"; var ReceiveReq: Boolean; var InvReq: Boolean; var PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseBatchPostMgt(var PurchaseHeader: Record "Purchase Header"; var PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.")
    begin
    end;
}

