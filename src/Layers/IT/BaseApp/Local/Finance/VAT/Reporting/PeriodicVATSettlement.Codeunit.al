// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;

codeunit 12195 "Periodic VAT Settlement"
{
    Access = Public;

    internal procedure CheckIfSplitIsNeeded(Period: Code[10]): Boolean
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        VATSetup: Record "VAT Setup";
    begin
        PeriodicVATSettlementEntry.SetRange("VAT Period", Period);
        VATSetup.Get();
        if VATSetup."Per Activity Code Settl. Entry" then
            PeriodicVATSettlementEntry.SetRange("Activity Code", '');
        exit(not PeriodicVATSettlementEntry.IsEmpty());

    end;

    internal procedure CreateSeparateEntries(Period: Code[10])
    var
        BusinessActivity: Record "Business Activity";
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
    begin
        if BusinessActivity.FindSet() then
            repeat
                InsertPeriodicVATSettlementEntry(PeriodicVATSettlementEntry, Period, BusinessActivity.Code);
            until BusinessActivity.Next() = 0;
    end;


    internal procedure ValidateSplit(VATPeriod: Code[10]) Valid: Boolean
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
        PeriodicVATSettlementEntry2: Record "Periodic VAT Settlement Entry";
        VATSetup: Record "VAT Setup";
        PriorPeriodOutputVAT, PriorPeriodInputVAT, AddCurrPriorPerInpVAT, AddCurrPriorPerOutVAT, PriorYearInputVAT, PriorYearOutputVAT : Decimal;
    begin
        VATSetup.Get();
        PeriodicVATSettlementEntry.SetRange("VAT Period", VATPeriod);
        if VATSetup."Per Activity Code Settl. Entry" then
            PeriodicVATSettlementEntry.SetRange("Activity Code", '');
        PeriodicVATSettlementEntry.FindFirst();
        PeriodicVATSettlementEntry2.SetRange("VAT Period", VATPeriod);
        if VATSetup."Per Activity Code Settl. Entry" then
            PeriodicVATSettlementEntry2.SetFilter("Activity Code", '<>%1', '');
        if PeriodicVATSettlementEntry2.FindSet() then
            repeat
                PriorPeriodOutputVAT += PeriodicVATSettlementEntry2."Prior Period Output VAT";
                PriorPeriodInputVAT += PeriodicVATSettlementEntry2."Prior Period Input VAT";
                AddCurrPriorPerInpVAT += PeriodicVATSettlementEntry2."Add Curr. Prior Per. Inp. VAT";
                AddCurrPriorPerOutVAT += PeriodicVATSettlementEntry2."Add Curr. Prior Per. Out VAT";
                PriorYearInputVAT += PeriodicVATSettlementEntry2."Prior Year Input VAT";
                PriorYearOutputVAT += PeriodicVATSettlementEntry2."Prior Year Output VAT";
            until PeriodicVATSettlementEntry2.Next() = 0;
        Valid := (PeriodicVATSettlementEntry."Prior Period Input VAT" = PriorPeriodInputVAT) and
                 (PeriodicVATSettlementEntry."Prior Period Output VAT" = PriorPeriodOutputVAT) and
                 (PeriodicVATSettlementEntry."Add Curr. Prior Per. Inp. VAT" = AddCurrPriorPerInpVAT) and
                 (PeriodicVATSettlementEntry."Add Curr. Prior Per. Out VAT" = AddCurrPriorPerOutVAT) and
                 (PeriodicVATSettlementEntry."Prior Year Input VAT" = PriorYearInputVAT) and
                 (PeriodicVATSettlementEntry."Prior Year Output VAT" = PriorYearOutputVAT);
    end;

    local procedure InsertPeriodicVATSettlementEntry(var PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry"; Period: Code[10]; BusinessActivityCode: Code[10])
    begin
        PeriodicVATSettlementEntry.Init();
        PeriodicVATSettlementEntry."VAT Period" := Period;
        PeriodicVATSettlementEntry."Activity Code" := CopyStr(BusinessActivityCode, 1, MaxStrLen(PeriodicVATSettlementEntry."Activity Code"));
        if PeriodicVATSettlementEntry.Insert() then;
    end;

}