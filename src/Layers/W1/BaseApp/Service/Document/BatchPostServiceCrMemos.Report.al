// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Setup;
using Microsoft.Service.Posting;
using System.Environment;

report 6005 "Batch Post Service Cr. Memos"
{
    Caption = 'Batch Post Service Cr. Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Header"; "Service Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const("Credit Memo"));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                if CalcInvDisc then
                    CalculateInvoiceDiscount();

                Counter := Counter + 1;
                Window.Update(1, "No.");
                Window.Update(2, Round(Counter / CounterTotal * 10000, 1));
                Clear(ServPost);
                ServPost.SetPostingDate(ReplacePostingDate, ReplaceDocumentDate, PostingDateReq);
                ServPost.SetPostingOptions(true, false, true); // ship, consume, invoice
                if ServPost.Run("Service Header") then begin
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
            var
                ServPostingSelectionMgt: Codeunit "Serv. Posting Selection Mgt.";
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                ServPostingSelectionMgt.CheckUserCanInvoiceService();
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
                    field(PostingDate; PostingDateReq)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that the program uses as the posting date or document date when you post, if you select the Replace Posting Date field or the Replace Document Date field or both.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the posting date of the credit memo with the date that you entered in the Posting Date field.';

                        trigger OnValidate()
                        begin
                            if ReplacePostingDate then
                                Message(Text003);

                            OnAfterValidateReplacePostingDate("Service Header", ReplacePostingDate);
                        end;
                    }
                    field(ReplaceDocumentDate; ReplaceDocumentDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Replace Document Date';
                        ToolTip = 'Specifies if you want to replace the document date of the credit memo with the date in the Posting Date field.';
                    }
                    field(CalcInvDisc; CalcInvDisc)
                    {
                        ApplicationArea = Service;
                        Caption = 'Calc. Inv. Discount';
                        ToolTip = 'Specifies whether the inventory discount should be calculated.';

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
        begin
            if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
                exit;
            SalesSetup.Get();
            CalcInvDisc := SalesSetup."Calc. Inv. Discount";
            ReplacePostingDate := false;
            ReplaceDocumentDate := false;
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
        PostingDateReq: Date;
        CounterTotal: Integer;
        Counter: Integer;
        CounterOK: Integer;
        ReplacePostingDate: Boolean;
        ReplaceDocumentDate: Boolean;
        CalcInvDisc: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter the posting date.';
#pragma warning disable AA0470
        Text001: Label 'Posting credit memos  #1########## @2@@@@@@@@@@@@@';
        Text002: Label '%1 credit memos out of a total of %2 have now been posted.';
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

    procedure InitializeRequest(PostingDateReqFrom: Date; ReplacePostingDateFrom: Boolean; ReplaceDocumentDateFrom: Boolean; CalcInvDiscFrom: Boolean)
    begin
        PostingDateReq := PostingDateReqFrom;
        ReplacePostingDate := ReplacePostingDateFrom;
        ReplaceDocumentDate := ReplaceDocumentDateFrom;
        CalcInvDisc := CalcInvDiscFrom;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostReport(var ServiceHeader: Record "Service Header")
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

