// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.VAT.Ledger;

codeunit 10769 "Service Cr. Memo Header - Edit"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader := Rec;
        ServiceCrMemoHeader.LockTable();
        ServiceCrMemoHeader.Find();
        OnRunOnAfterServiceCrMemoHeaderFind(ServiceCrMemoHeader, Rec);
        OnRunOnBeforeServiceCrMemoHeaderModify(ServiceCrMemoHeader, Rec);
        OnRunOnBeforeTestFieldNo(ServiceCrMemoHeader, Rec);

        ServiceCrMemoHeader.TestField("No.", Rec."No.");
        ServiceCrMemoHeader.Modify();
        Rec := ServiceCrMemoHeader;
        OnRunOnAfterServiceCrMemoHeaderEdit(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceCrMemoHeaderModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", 'OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales', '', false, false)]
    local procedure OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales(var VATEntry: Record "VAT Entry"; StartDateFormula: DateFormula; EndDateFormula: DateFormula; var Result: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceCrMemoHeader.Get(VATEntry."Document No.");
        if ServiceCrMemoHeader."Corrected Invoice No." = '' then
            Result := false
        else begin
            ServiceInvoiceHeader.Get(ServiceCrMemoHeader."Corrected Invoice No.");
            Result := not (ServiceInvoiceHeader."Posting Date" in
                        [CalcDate(StartDateFormula, ServiceCrMemoHeader."Posting Date") ..
                            CalcDate(EndDateFormula, ServiceCrMemoHeader."Posting Date")]);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterServiceCrMemoHeaderFind(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeTestFieldNo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterServiceCrMemoHeaderEdit(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;
}
