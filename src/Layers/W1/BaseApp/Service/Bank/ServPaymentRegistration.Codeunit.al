// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Service.Document;

codeunit 6469 "Serv. Payment Registration"
{
    var
        ServiceQuoteTxt: Label 'Service Quote';
        ServiceOrderTxt: Label 'Service Order';
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCreditMemoTxt: Label 'Service Credit Memo';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnAfterFindRecords', '', false, false)]
    local procedure OnAfterFindRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocNoFilter: Code[20]; AmountFilter: Decimal; AmountTolerancePerc: Decimal; sender: Codeunit "Payment Registration Mgt.")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        if ServiceHeader.ReadPermission then begin
            ServiceHeader.Reset();
            ServiceHeader.SetFilter("No.", DocNoFilter);
            if ServiceHeader.FindSet() then
                repeat
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                    ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                    ServiceLine.CalcSums("Amount Including VAT");
                    if sender.IsWithinTolerance(ServiceLine."Amount Including VAT", AmountFilter, AmountTolerancePerc) then
                        sender.InsertDocSearchResult(
                          TempDocumentSearchResult, ServiceHeader."No.", ServiceHeader."Document Type".AsInteger(), DATABASE::"Service Header",
                          GetServiceHeaderDescription(ServiceHeader), ServiceLine."Amount Including VAT");
                until ServiceHeader.Next() = 0;
        end;
    end;

    local procedure GetServiceHeaderDescription(ServiceHeader: Record "Service Header"): Text[50]
    begin
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                exit(ServiceQuoteTxt);
            ServiceHeader."Document Type"::Order:
                exit(ServiceOrderTxt);
            ServiceHeader."Document Type"::Invoice:
                exit(ServiceInvoiceTxt);
            ServiceHeader."Document Type"::"Credit Memo":
                exit(ServiceCreditMemoTxt);
            else
                exit(ServiceOrderTxt);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Payment Registration Mgt.", 'OnShowRecords', '', false, false)]
    local procedure OnShowRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary)
    begin
        case TempDocumentSearchResult."Table ID" of
            DATABASE::"Service Header":
                ShowServiceHeaderRecords(TempDocumentSearchResult);
        end;
    end;

    local procedure ShowServiceHeaderRecords(var TempDocumentSearchResult: Record "Document Search Result" temporary)
    var
        ServiceHeader: Record "Service Header";
    begin
        TempDocumentSearchResult.TestField("Table ID", DATABASE::"Service Header");
        ServiceHeader.SetRange("Document Type", TempDocumentSearchResult."Doc. Type");
        ServiceHeader.SetRange("No.", TempDocumentSearchResult."Doc. No.");

        case TempDocumentSearchResult."Doc. Type" of
            ServiceHeader."Document Type"::Quote.AsInteger():
                PAGE.Run(PAGE::"Service Quote", ServiceHeader);
            ServiceHeader."Document Type"::Order.AsInteger():
                PAGE.Run(PAGE::"Service Order", ServiceHeader);
            ServiceHeader."Document Type"::Invoice.AsInteger():
                PAGE.Run(PAGE::"Service Invoice", ServiceHeader);
            ServiceHeader."Document Type"::"Credit Memo".AsInteger():
                PAGE.Run(PAGE::"Service Credit Memo", ServiceHeader);
            else
                PAGE.Run(0, ServiceHeader);
        end;
    end;
}
