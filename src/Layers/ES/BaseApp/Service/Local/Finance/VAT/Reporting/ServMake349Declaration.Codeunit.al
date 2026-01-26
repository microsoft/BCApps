// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Service.History;

codeunit 10710 "Serv. Make 349 Declaration"
{
    SingleInstance = true;

    var
        TempServiceInvLines: Record "Service Invoice Line" temporary;

    [EventSubscriber(ObjectType::Report, Report::"Make 349 Declaration", 'OnAfterInitReport', '', true, true)]
    local procedure OnAfterInitReport()
    begin
        TempServiceInvLines.Reset();
        TempServiceInvLines.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 349 Declaration", 'OnGetCorrectedInvoicePostingDate', '', true, true)]
    local procedure OnGetCorrectedInvoicePostingDate(DocumentNo: Code[20]; var PostingDate: Date; var ShouldExit: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        if ServiceCrMemoHeader.Get(DocumentNo) then
            if ServiceInvoiceHeader.Get(ServiceCrMemoHeader."Corrected Invoice No.") then begin
                PostingDate := ServiceInvoiceHeader."Posting Date";
                ShouldExit := true;
            end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 349 Declaration", 'OnIsCorrectiveCrMemoForSales', '', true, true)]
    local procedure OnIsCorrectiveCrMemoForSales(DocumentNo: Code[20]; var Result: Boolean);
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if ServiceCrMemoHeader.Get(DocumentNo) then
            Result := ServiceCrMemoHeader."Corrected Invoice No." <> '';
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 349 Declaration", 'OnGetPostedCountryLocCodeInvoice', '', true, true)]
    local procedure OnGetPostedCountryLocCodeInvoice(DocNo: Code[20]; var LocationDifferentCountryCode: Boolean; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean; var AmountToIncludeIn349: Decimal; var Result: Boolean; sender: Report "Make 349 Declaration")
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceInvLines: Record "Service Invoice Line";
        Location: Record Location;
    begin
        if ServiceInvHeader.Get(DocNo) then begin
            if ServiceInvHeader."Location Code" <> '' then begin
                if Location.Get(ServiceInvHeader."Location Code") then begin
                    EUCountryHeaderLocationCode := sender.FindEUCountryRegionCode(Location."Country/Region Code");
                    LocationDifferentCountryCode :=
                        sender.IsSalesLocationDifferentCountryCode(
                            EUCountryHeaderLocationCode, ServiceInvHeader."Customer No.", ServiceInvHeader."Location Code");
                end;
            end else begin
                TempServiceInvLines.SetRange("Document No.", DocNo);
                TempServiceInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                TempServiceInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                if not TempServiceInvLines.FindFirst() then begin
                    ServiceInvLines.SetRange("Document No.", DocNo);
                    ServiceInvLines.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                    ServiceInvLines.SetRange("VAT Prod. Posting Group", VATPPG);
                    if ServiceInvLines.FindSet() then
                        repeat
                            if ServiceInvLines."Location Code" <> '' then begin
                                if Location.Get(ServiceInvLines."Location Code") then
                                    EUCountryLinesLocationCode := sender.FindEUCountryRegionCode(Location."Country/Region Code");
                                if EUCountryLinesLocationCode then begin
                                    AmountToIncludeIn349 := AmountToIncludeIn349 + ServiceInvLines.Amount;
                                    LocationDifferentCountryCode :=
                                        sender.IsSalesLocationDifferentCountryCode(true, ServiceInvLines."Customer No.", ServiceInvLines."Location Code");
                                    TempServiceInvLines := ServiceInvLines;
                                    TempServiceInvLines.Insert();
                                end;
                            end else
                                if CompInforShipToCountryCode then begin
                                    EUCountryLinesLocationCode := true;
                                    AmountToIncludeIn349 := AmountToIncludeIn349 + ServiceInvLines.Amount;
                                    TempServiceInvLines := ServiceInvLines;
                                    TempServiceInvLines.Insert();
                                end;
                        until ServiceInvLines.Next() = 0;
                end;
            end;
            Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Make 349 Declaration", 'OnGetPostedCountryLocCodeServiceCrMemo', '', true, true)]
    local procedure OnGetPostedCountryLocCodeServiceCrMemo(DocNo: Code[20]; CompInforShipToCountryCode: Boolean; VATEntry: Record "VAT Entry"; VATPPG: Code[20]; var EUCountryHeaderLocationCode: Boolean; var EUCountryLinesLocationCode: Boolean; var Result: Boolean; sender: Report "Make 349 Declaration")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        Location: Record Location;
    begin
        if ServiceCrMemoHeader.Get(DocNo) then begin
            if ServiceCrMemoHeader."Location Code" <> '' then begin
                if Location.Get(ServiceCrMemoHeader."Location Code") then begin
                    EUCountryHeaderLocationCode := sender.FindEUCountryRegionCode(Location."Country/Region Code");
                    sender.IsSalesLocationDifferentCountryCode(
                        EUCountryHeaderLocationCode, ServiceCrMemoHeader."Customer No.", ServiceCrMemoHeader."Location Code");
                end;
            end else begin
                ServiceCrMemoLine.SetRange("Document No.", DocNo);
                ServiceCrMemoLine.SetRange("Gen. Prod. Posting Group", VATEntry."Gen. Prod. Posting Group");
                ServiceCrMemoLine.SetRange("VAT Prod. Posting Group", VATPPG);
                if ServiceCrMemoLine.Find('-') then
                    repeat
                        if ServiceCrMemoLine."Location Code" <> '' then begin
                            if Location.Get(ServiceCrMemoLine."Location Code") then begin
                                EUCountryLinesLocationCode := sender.FindEUCountryRegionCode(Location."Country/Region Code");
                                sender.IsSalesLocationDifferentCountryCode(
                                    EUCountryHeaderLocationCode, ServiceCrMemoLine."Customer No.", ServiceCrMemoLine."Location Code");
                            end;
                        end else
                            if CompInforShipToCountryCode then
                                EUCountryLinesLocationCode := true;
                    until ServiceCrMemoLine.Next() = 0;
            end;
            Result := true;
        end;
    end;
}