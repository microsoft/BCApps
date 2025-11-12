// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using System.Environment;

codeunit 399 "Copy Tax Setup From Company"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Tax Groups        @1@@@@@@@@@@@\';
        Text001: Label 'Tax Jurisdictions @2@@@@@@@@@@@\';
        Text002: Label 'Tax Areas         @3@@@@@@@@@@@\';
        Text003: Label 'Tax Detail        @4@@@@@@@@@@@';
#pragma warning restore AA0074
        Window: Dialog;
        CurrentRecord: Integer;
        RecordCount: Integer;

    procedure CopyTaxInfo(SourceCompany: Record Company; CopyTable: array[4] of Boolean)
    begin
        Window.Open(Text000 +
          Text001 +
          Text002 +
          Text003);

        if CopyTable[1] then
            CopyTaxGroup(SourceCompany);

        if CopyTable[2] then
            CopyTaxJurisdiction(SourceCompany);

        if CopyTable[3] then
            CopyTaxArea(SourceCompany);

        if CopyTable[4] then
            CopyTaxDetail(SourceCompany);

        Window.Close();
    end;

    local procedure CopyTaxJurisdiction(SourceCompany: Record Company)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        SourceTaxJurisdiction: Record "Tax Jurisdiction";
    begin
        SourceTaxJurisdiction.ChangeCompany(SourceCompany.Name);
        if not SourceTaxJurisdiction.Find('-') then
            exit;
        RecordCount := SourceTaxJurisdiction.Count();
        CurrentRecord := 0;
        repeat
            CurrentRecord := CurrentRecord + 1;
            Window.Update(2, Round(CurrentRecord / RecordCount * 10000, 1));
            TaxJurisdiction.Init();
            TaxJurisdiction.TransferFields(SourceTaxJurisdiction);
            if TaxJurisdiction.Insert() then;
        until SourceTaxJurisdiction.Next() = 0;
    end;

    local procedure CopyTaxGroup(SourceCompany: Record Company)
    var
        SourceTaxGroup: Record "Tax Group";
        TaxGroup: Record "Tax Group";
    begin
        SourceTaxGroup.ChangeCompany(SourceCompany.Name);
        if not SourceTaxGroup.Find('-') then
            exit;
        RecordCount := SourceTaxGroup.Count();
        CurrentRecord := 0;
        repeat
            CurrentRecord := CurrentRecord + 1;
            Window.Update(1, Round(CurrentRecord / RecordCount * 10000, 1));
            TaxGroup.Init();
            TaxGroup.TransferFields(SourceTaxGroup);
            if TaxGroup.Insert() then;
        until SourceTaxGroup.Next() = 0;
    end;

    local procedure CopyTaxArea(SourceCompany: Record Company)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxArea: Record "Tax Area";
        SourceTaxAreaLine: Record "Tax Area Line";
        SourceTaxArea: Record "Tax Area";
    begin
        SourceTaxArea.ChangeCompany(SourceCompany.Name);
        SourceTaxAreaLine.ChangeCompany(SourceCompany.Name);
        if not SourceTaxArea.Find('-') then
            exit;
        RecordCount := SourceTaxArea.Count();
        CurrentRecord := 0;
        repeat
            CurrentRecord := CurrentRecord + 1;
            Window.Update(3, Round(CurrentRecord / RecordCount * 10000, 1));
            TaxArea.Init();
            TaxArea.TransferFields(SourceTaxArea);
            if TaxArea.Insert() then;
            SourceTaxAreaLine.SetRange("Tax Area", SourceTaxArea.Code);
            if SourceTaxAreaLine.Find('-') then
                repeat
                    TaxAreaLine.Init();
                    TaxAreaLine.TransferFields(SourceTaxAreaLine);
                    if TaxAreaLine.Insert() then;
                until SourceTaxAreaLine.Next() = 0;
        until SourceTaxArea.Next() = 0;
    end;

    local procedure CopyTaxDetail(SourceCompany: Record Company)
    var
        SourceTaxDetail: Record "Tax Detail";
        TaxDetail: Record "Tax Detail";
    begin
        SourceTaxDetail.ChangeCompany(SourceCompany.Name);
        if not SourceTaxDetail.Find('-') then
            exit;
        RecordCount := SourceTaxDetail.Count();
        CurrentRecord := 0;
        repeat
            CurrentRecord := CurrentRecord + 1;
            Window.Update(4, Round(CurrentRecord / RecordCount * 10000, 1));
            TaxDetail.Init();
            TaxDetail.TransferFields(SourceTaxDetail);
            if TaxDetail.Insert() then;
        until SourceTaxDetail.Next() = 0;
    end;
}

