// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using System.Environment;

report 297 "Batch Post Sales Invoices"
{
    Caption = 'Batch Post Sales Invoices';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Invoice));
            RequestFilterFields = "No.", Status;
            RequestFilterHeading = 'Sales Invoice';

            trigger OnPreDataItem()
            var
                SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
                PostingSelectionManagement: Codeunit "Posting Selection Management";
            begin
                OnBeforeSalesHeaderPreDataItem("Sales Header", SalesBatchPostMgt, PrintDoc);

                PostingSelectionManagement.CheckUserCanInvoiceSales();
                SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Print, PrintDoc);
                SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDateReq);
                SalesBatchPostMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"VAT Date", VATDateReq);
                SalesBatchPostMgt.RunBatch("Sales Header", ReplacePostingDate, PostingDateReq, ReplaceDocumentDate, CalcInvDisc, false, true);

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
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the sales orders'' posting date with the date entered in the field above.';

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
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if the new document date will be applied.';

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
                        ToolTip = 'Specifies if you want to replace the sales invoices VAT date with the date in the VAT Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. Inv. and Pmt. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the invoices before posting.';

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
                        ToolTip = 'Specifies if you want to print the invoice after posting. In the Report Output Type field on the Sales and Receivables page, you define if the report will be printed or output as a PDF.';

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
            IsHandled: Boolean;
        begin
            IsHandled := false;
            OnBeforeOnOpenPage(IsHandled);
            if not IsHandled then begin
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
            end;
            OnAfterOnOpenPage(CalcInvDisc, ReplacePostingDate, ReplaceDocumentDate, PrintDoc, PrintDocVisible, PostingDateReq, ReplaceVATDateReq, VATDateReq);
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

    protected var
        PostingDateReq, VATDateReq : Date;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate, ReplaceVATDateReq : Boolean;
        CalcInvDisc: Boolean;
        PrintDoc: Boolean;
        PrintDocVisible: Boolean;
        VATDateEnabled: Boolean;

    local procedure UpdateVATDate()
    begin
        if ReplaceVATDateReq then
            VATDateReq := PostingDateReq;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var CalcInvDisc: Boolean; var ReplacePostingDate: Boolean; var ReplaceDocumentDate: Boolean; var PrintDoc: Boolean; var PrintDocVisible: Boolean; var PostingDateReq: Date; var ReplaceVATDateReq: Boolean; var VATDateReq: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSalesHeaderPreDataItem(var SalesHeader: Record "Sales Header"; var SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt."; var PrintDoc: Boolean)
    begin
    end;
}

