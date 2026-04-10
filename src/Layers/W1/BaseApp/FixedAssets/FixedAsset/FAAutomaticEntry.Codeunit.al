// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Maintenance;

codeunit 5607 "FA Automatic Entry"
{

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";

    procedure AdjustFALedgEntry(var FALedgEntry: Record "FA Ledger Entry")
    begin
        FA.Get(FALedgEntry."FA No.");
        if not FA."Budgeted Asset" then
            FALedgEntry.Quantity := 0;
        FALedgEntry."Bal. Account Type" := FALedgEntry."Bal. Account Type"::"G/L Account";
        FALedgEntry."Bal. Account No." := '';
        FALedgEntry."VAT Amount" := 0;
        FALedgEntry."Gen. Posting Type" := FALedgEntry."Gen. Posting Type"::" ";
        FALedgEntry."Gen. Bus. Posting Group" := '';
        FALedgEntry."Gen. Prod. Posting Group" := '';
        FALedgEntry."VAT Bus. Posting Group" := '';
        FALedgEntry."VAT Prod. Posting Group" := '';
        FALedgEntry."Reclassification Entry" := false;
        FALedgEntry."Index Entry" := false;
    end;

    procedure AdjustMaintenanceLedgEntry(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        FA.Get(MaintenanceLedgEntry."FA No.");
        if not FA."Budgeted Asset" then
            MaintenanceLedgEntry.Quantity := 0;
        MaintenanceLedgEntry."Bal. Account Type" := MaintenanceLedgEntry."Bal. Account Type"::"G/L Account";
        MaintenanceLedgEntry."Bal. Account No." := '';
        MaintenanceLedgEntry."VAT Amount" := 0;
        MaintenanceLedgEntry."Gen. Posting Type" := MaintenanceLedgEntry."Gen. Posting Type"::" ";
        MaintenanceLedgEntry."Gen. Bus. Posting Group" := '';
        MaintenanceLedgEntry."Gen. Prod. Posting Group" := '';
        MaintenanceLedgEntry."VAT Bus. Posting Group" := '';
        MaintenanceLedgEntry."VAT Prod. Posting Group" := '';
        MaintenanceLedgEntry."Index Entry" := false;
    end;

    procedure AdjustGLEntry(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.Quantity := 0;
        GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
        GLEntry."Bal. Account No." := '';
        GLEntry."VAT Amount" := 0;
        GLEntry."Gen. Posting Type" := GLEntry."Gen. Posting Type"::" ";
        GLEntry."Gen. Bus. Posting Group" := '';
        GLEntry."Gen. Prod. Posting Group" := '';
        GLEntry."VAT Bus. Posting Group" := '';
        GLEntry."VAT Prod. Posting Group" := '';
    end;
}

