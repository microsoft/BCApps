// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using System.Environment;
using System.Security.User;

report 6655 "Batch Post Sales Return Orders"
{
    Caption = 'Batch Post Sales Return Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Return Order"));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Return Order';

            trigger OnPreDataItem()
            var
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeSalesHeaderOnPreDataItem("Sales Header", ReceiveReq, InvReq, SalesBatchPostMgt, IsHandled);
                if not IsHandled then begin
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Receive, ReceiveReq);
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Print, PrintDoc);
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDateReq);
                    SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"VAT Date", VATDateReq);
                    SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, InvReq);
                end;

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
                    field(ReceiveReq; ReceiveReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Receive';
                        ToolTip = 'Specifies if the orders are received when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(InvReq; InvReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Editable = PostInvoiceEditable;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies if the orders are invoiced when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that you want to use as the document date or the posting date when you post if you select the Replace Document Date check box or the Replace Posting Date check box.';

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
                        ToolTip = 'Specifies the date that you want to use as the VAT date when you post if you select the VAT Document Date check box.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the orders with the date that is entered in the Posting Date field.';

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
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the orders with the date in the Posting Date field.';

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
                        ToolTip = 'Specifies if you want to replace the VAT date of the orders with the date in the VAT Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            SalesReceivablesSetup.Get();
                            SalesReceivablesSetup.TestField("Calc. Inv. Discount", false);
                        end;
                    }
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = PrintDocVisible;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want to print the return order after posting. In the Report Output Type field on the Sales & Receivables page, you define if the report will be printed or output as a PDF.';

                        trigger OnValidate()
                        var
                            SalesReceivablesSetup: Record "Sales & Receivables Setup";
                        begin
                            if PrintDoc then begin
                                SalesReceivablesSetup.Get();
                                if SalesReceivablesSetup."Post with Job Queue" then
                                    SalesReceivablesSetup.TestField("Post & Print with Job Queue");
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
            SalesReceivablesSetup: Record "Sales & Receivables Setup";
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
            SalesReceivablesSetup.Get();
            CalcInvDisc := SalesReceivablesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
            ReplaceVATDateReq := false;
            PrintDoc := false;
            PrintDocVisible := SalesReceivablesSetup."Post & Print with Job Queue";
            VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
            UserSetupManagement.GetSalesInvoicePostingPolicy(Receive, Invoice);
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
        Text003: Label 'The exchange rate associated with the new posting date on the sales header will apply to the sales lines.';
#pragma warning restore AA0074
        PrintDoc: Boolean;
        PrintDocVisible: Boolean;
        VATDateEnabled: Boolean;
        PostInvoiceEditable: Boolean;

    protected var
        PostingDateReq, VATDateReq : Date;
        ReceiveReq: Boolean;
        InvReq: Boolean;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate, ReplaceVATDateReq : Boolean;
        CalcInvDisc: Boolean;

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
    local procedure OnBeforeSalesHeaderOnPreDataItem(var SalesHeader: Record "Sales Header"; var ReceiveReq: Boolean; var InvReq: Boolean; var SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt."; var IsHandled: Boolean)
    begin
    end;
}

