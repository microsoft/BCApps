// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Setup;
using System.Security.User;
using Microsoft.Service.Posting;
using System.Environment;

report 6001 "Batch Post Service Orders"
{
    Caption = 'Batch Post Service Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", Status, Priority;

            trigger OnAfterGetRecord()
            begin
                if CalcInvDisc then
                    CalculateInvoiceDiscount();

                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));

                if PostServiceHeader("Service Header") then begin
                    CounterOK := CounterOK + 1;
                    if MarkedOnly then
                        Mark(false);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
                Message(Text002, CounterOK, CounterTotal);
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                CounterTotal := Count;
                Window.Open(Text001);
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
                    field(Ship; ShipReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Ship';
                        ToolTip = 'Specifies if the orders are shipped when posted. When you select this check box, it applies to all the orders that are posted.';
                    }
                    field(Invoice; InvReq)
                    {
                        ApplicationArea = Service;
                        Editable = PostInvoiceEditable;
                        Caption = 'Invoice';
                        ToolTip = 'Specifies if the orders are invoiced when posted. If you select this check box, it applies to all the orders that are posted.';
                    }
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that is to be used as the document date or the posting date when you post if you select the Replace Document Date check box or the Replace Posting Date check box.';
                    }
                    field(ReplacePostingDate_Option; ReplacePostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the service orders with the date that is entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);

                            OnAfterValidateReplacePostingDate("Service Header", ReplacePostingDate);
                        end;
                    }
                    field(ReplaceDocumentDate_Option; ReplaceDocumentDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the service orders with the date in the Posting Date field.';
                    }
                    field(CalcInvDiscount; CalcInvDisc)
                    {
                        ApplicationArea = Service;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies if you want the invoice discount amount to be automatically calculated on the orders before posting.';

                        trigger OnValidate()
                        begin
                            SalesSetup.Get();
                            SalesSetup.TestField("Calc. Inv. Discount", false);
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
            ClientTypeManagement: Codeunit "Client Type Management";
            UserSetupManagement: Codeunit "User Setup Management";
            Ship, Consume, Invoice : Boolean;
        begin
            if ClientTypeManagement.GetCurrentClientType() <> ClientType::Background then
                InitValues();

            UserSetupManagement.GetServiceInvoicePostingPolicy(Ship, Consume, Invoice);
            if Ship then
                InvReq := Invoice;
            PostInvoiceEditable := not Ship;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnAfterPostReport("Service Header");
    end;

    trigger OnPreReport()
    begin
        OnBeforePreReport();
    end;

    var
        ServLine: Record "Service Line";
        SalesSetup: Record "Sales & Receivables Setup";
        ServCalcDisc: Codeunit "Service-Calc. Discount";
        ServPost: Codeunit "Service-Post";
        Window: Dialog;
        ShipReq: Boolean;
        InvReq: Boolean;
        PostingDateReq: Date;
        CounterTotal: Integer;
        Counter: Integer;
        CounterOK: Integer;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;
        PostInvoiceEditable: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
#pragma warning disable AA0470
        Text001: Label 'Posting orders  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 orders out of a total of %2 have now been posted.';
#pragma warning restore AA0470
        Text003: Label 'The exchange rate associated with the new posting date on the service header will not apply to the service lines.';
#pragma warning restore AA0074

    local procedure CalculateInvoiceDiscount()
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Service Header"."Document Type");
        ServLine.SetRange("Document No.", "Service Header"."No.");
        if ServLine.FindFirst() then
            if ServCalcDisc.Run(ServLine) then begin
                "Service Header".Get("Service Header"."Document Type", "Service Header"."No.");
                Commit();
            end;
    end;

    procedure InitializeRequest(ShipReqFrom: Boolean; InvReqFrom: Boolean; PostingDateReqFrom: Date; ReplacePostingDateFrom: Boolean; ReplaceDocumentDateFrom: Boolean; CalcInvDiscFrom: Boolean)
    begin
        InitValues();
        ShipReq := ShipReqFrom;
        InvReq := InvReqFrom;
        PostingDateReq := PostingDateReqFrom;
        ReplacePostingDate := ReplacePostingDateFrom;
        ReplaceDocumentDate := ReplaceDocumentDateFrom;
        if CalcInvDiscFrom then
            SalesSetup.TestField("Calc. Inv. Discount", false);
        CalcInvDisc := CalcInvDiscFrom;
    end;

    procedure InitValues()
    begin
        SalesSetup.Get();
        CalcInvDisc := SalesSetup."Calc. Inv. Discount";
        ReplacePostingDate := false;
        ReplaceDocumentDate := false;
    end;

    local procedure PostServiceHeader(var ServiceHeader: Record "Service Header") ReturnValue: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostServiceHeader(ServiceHeader, IsHandled, ReturnValue, ReplacePostingDate, ReplaceDocumentDate, PostingDateReq, ShipReq, InvReq);
        if IsHandled then
            exit(ReturnValue);

        Clear(ServPost);
        ServPost.SetPostingDate(ReplacePostingDate, ReplaceDocumentDate, PostingDateReq);
        ServPost.SetPostingOptions(ShipReq, false, InvReq);
        ServPost.SetHideValidationDialog(true);
        exit(ServPost.Run(ServiceHeader));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostReport(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostServiceHeader(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean; var ReturnValue: Boolean; ReplacePostingDate: Boolean; ReplaceDocumentDate: Boolean; PostingDateReq: Date; ShipReq: Boolean; InvReq: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateReplacePostingDate(var ServiceHeader: Record "Service Header"; ReplacePostingDate: Boolean)
    begin
    end;
}
