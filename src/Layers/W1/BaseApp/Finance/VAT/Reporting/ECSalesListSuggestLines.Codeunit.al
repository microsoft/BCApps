// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using System.Utilities;

codeunit 140 "EC Sales List Suggest Lines"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog();

        if not Rec.IsPeriodValid() then begin
            ErrorMessage.LogMessage(Rec, Rec.FieldNo("No."), ErrorMessage."Message Type"::Error, InvalidPeriodErr);
            exit;
        end;

        VATReportHeader := Rec;
        ECSLVATReportLine.ClearLines(Rec);
        PopulateVatEntryLines();
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        ErrorMessage: Record "Error Message";
        InvalidPeriodErr: Label 'The period is not valid.';

    local procedure PopulateVatEntryLines()
    var
        CompanyInformation: Record "Company Information";
        EUVATEntries: Query "EU VAT Entries";
    begin
        CompanyInformation.Get();
        EUVATEntries.SetRange(VATReportingDate, VATReportHeader."Start Date", VATReportHeader."End Date");
        EUVATEntries.SetFilter(CountryCode, '<>%1', CompanyInformation."Country/Region Code");
        OnPopulateVatEntryLinesOnAfterEUVATEntriesSetFilters(VATReportHeader, EUVATEntries);

        EUVATEntries.Open();
        while EUVATEntries.Read() do
            AddOrUpdateECLLine(EUVATEntries);
        RowsTotalCorrection();
        DeleteZeroAmountLines();
    end;

    local procedure GetECLLine(var ECSLVATReportLine: Record "ECSL VAT Report Line"; EUVATEntries: Query "EU VAT Entries")
    var
        LastId: Integer;
        TrnIndicator: Integer;
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("Country Code", EUVATEntries.CountryCode);
        ECSLVATReportLine.SetRange("Customer VAT Reg. No.", EUVATEntries.VAT_Registration_No);
        TrnIndicator := GetIndicatorCode(EUVATEntries.EU_3_Party_Trade, EUVATEntries.EU_Service);
        ECSLVATReportLine.SetRange("Transaction Indicator", TrnIndicator);

        if not ECSLVATReportLine.FindFirst() then begin
            ECSLVATReportLine.Reset();
            ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
            if ECSLVATReportLine.FindLast() then
                LastId := ECSLVATReportLine."Line No.";

            ECSLVATReportLine.Init();
            ECSLVATReportLine."Line No." := LastId + 1;
            ECSLVATReportLine.Validate("Report No.", VATReportHeader."No.");
            ECSLVATReportLine.Validate("Country Code", EUVATEntries.CountryCode);
            ECSLVATReportLine.Validate("Customer VAT Reg. No.", EUVATEntries.VAT_Registration_No);
            ECSLVATReportLine.Validate("Transaction Indicator", TrnIndicator);
            ECSLVATReportLine.Insert();
        end;
    end;

    local procedure AddOrUpdateECLLine(EUVATEntries: Query "EU VAT Entries")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddOrUpdateECLLine(EUVATEntries, ECSLVATReportLine, IsHandled);
        if IsHandled then
            exit;

        GetECLLine(ECSLVATReportLine, EUVATEntries);
        ECSLVATReportLine."Total Value Of Supplies" += EUVATEntries.Base;
        AddToRepLineRelation(EUVATEntries, ECSLVATReportLine);
        ECSLVATReportLine.Modify(true);
    end;

    local procedure GetIndicatorCode(EU3rdPartyTrade: Boolean; EUService: Boolean): Integer
    begin
        if EUService then
            exit(3);

        if EU3rdPartyTrade then
            exit(2);

        exit(0);
    end;

    local procedure AddToRepLineRelation(EUVATEntries: Query "EU VAT Entries"; ECSLVATReportLine: Record "ECSL VAT Report Line")
    var
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.Validate("ECSL Report No.", VATReportHeader."No.");
        ECSLVATReportLineRelation.Validate("ECSL Line No.", ECSLVATReportLine."Line No.");
        ECSLVATReportLineRelation.Validate("VAT Entry No.", EUVATEntries.Entry_No);
        ECSLVATReportLineRelation.Insert(true);
    end;

    local procedure RowsTotalCorrection()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");

        if not ECSLVATReportLine.FindSet() then
            exit;
        repeat
            ECSLVATReportLine."Total Value Of Supplies" := -Round(ECSLVATReportLine."Total Value Of Supplies", 1);
            ECSLVATReportLine.Modify(true);
        until ECSLVATReportLine.Next() = 0;
    end;

    local procedure DeleteZeroAmountLines()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
    begin
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", ECSLVATReportLine."Report No.");

        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("Total Value Of Supplies", 0);
        if not ECSLVATReportLine.FindSet() then
            exit;

        repeat
            ECSLVATReportLineRelation.SetRange("ECSL Line No.", ECSLVATReportLine."Line No.");
            ECSLVATReportLineRelation.DeleteAll();
        until ECSLVATReportLine.Next() = 0;

        ECSLVATReportLine.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddOrUpdateECLLine(EUVATEntries: Query "EU VAT Entries"; var ECSLVATReportLine: Record "ECSL VAT Report Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPopulateVatEntryLinesOnAfterEUVATEntriesSetFilters(var VATReportHeader: Record "VAT Report Header"; var EUVATEntries: Query "EU VAT Entries")
    begin
    end;
}

