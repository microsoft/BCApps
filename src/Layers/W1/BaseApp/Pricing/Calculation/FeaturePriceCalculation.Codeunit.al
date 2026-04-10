// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using System.Environment.Configuration;
using System.Threading;

/// <summary>
/// Copies pricing data from old tables to "Price List Line" and "Price List Header" table.
/// </summary>
codeunit 7049 "Feature - Price Calculation" implements "Feature Data Update"
{

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        Codeunit.Run(Codeunit::"Price Calculation Mgt.");
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
        StartDateTime: DateTime;
    begin
        FillPriceListNos();
        CreateDefaultPriceLists();

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.SetGenerateHeader(FeatureDataUpdateStatus."Use Default Price Lists");

        AdjustCRMConnectionSetup();

        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesLineDiscount.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchasePrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, PurchaseLineDiscount.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobItemPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobGLAccountPrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, JobResourcePrice.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ResourceCost.TableCaption(), StartDateTime);

        StartDateTime := CurrentDateTime;
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ResourcePrice.TableCaption(), StartDateTime);

        OnUpdateDataOnBeforeUpdateAmountTypeOnHeaders(FeatureDataUpdateStatus);

        UpdateAmountTypeOnHeaders();
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := StrSubstNo(DescrTok, GetListOfTables(), Description2Txt);
    end;

    var
        PriceListLine: Record "Price List Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        Description1Txt: Label 'Records from %1, %2, %3, %4, %5, %6, %7, %8, %9, and %10 tables',
        Comment = '%1, %2, %3, %4, %5, %6, %7, %8, %9, %10 - table captions';
        Description2Txt: Label 'will be copied to the Price List Header and Price List Line tables.';
        DescrTok: Label '%1 %2', Locked = true;
        XJPLTok: Label 'J-PL';
        XJobPriceListLbl: Label 'Project Price List';
        XJ00001Tok: Label 'J00001';
        XJ99999Tok: Label 'J99999';
        XPPLTok: Label 'P-PL';
        XPurchasePriceListLbl: Label 'Purchase Price List';
        XP00001Tok: Label 'P00001';
        XP99999Tok: Label 'P99999';
        XSPLTok: Label 'S-PL';
        XSalesPriceListLbl: Label 'Sales Price List';
        XS00001Tok: Label 'S00001';
        XS99999Tok: Label 'S99999';
        FeatureIsOffErr: Label 'This page is used by a feature that is not enabled.\For more information, see Feature Management.';
        FeatureIsOnErr: Label 'This page is no longer available. It was used by a feature that has been replaced or removed.\For more information, see Feature Management.';

    local procedure AdjustCRMConnectionSetup()
    var
        CRMFullSyncReviewLine: Record "CRM Full Synch. Review Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationRecord.SetFilter("Table ID", '%1|%2', Database::"Customer Price Group", Database::"Sales Price");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();
        if CRMIntegrationManagement.IsCRMIntegrationEnabled() then begin
            RemoveIntegrationTableMapping(Database::"Customer Price Group", Database::"CRM Pricelevel");
            RemoveIntegrationTableMapping(Database::"Sales Price", Database::"CRM ProductPricelevel");
            CRMSetupDefaults.ResetExtendedPriceListConfiguration();
            if CRMFullSyncReviewLine.Get('CUSTPRCGRP-PRICE') then
                CRMFullSyncReviewLine.Delete();
            if CRMFullSyncReviewLine.Get('SALESPRC-PRODPRICE') then
                CRMFullSyncReviewLine.Delete();
        end;
    end;

    local procedure CountRecords()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        CRMIntegrationRecord.SetFilter("Table ID", '%1|%2', Database::"Customer Price Group", Database::"Sales Price");
        InsertDocumentEntry(Database::"CRM Integration Record", CRMIntegrationRecord.TableCaption(), CRMIntegrationRecord.Count());
        InsertDocumentEntry(Database::"Sales Price", SalesPrice.TableCaption(), SalesPrice.Count());
        InsertDocumentEntry(Database::"Sales Line Discount", SalesLineDiscount.TableCaption(), SalesLineDiscount.Count());
        InsertDocumentEntry(Database::"Purchase Price", PurchasePrice.TableCaption(), PurchasePrice.Count());
        InsertDocumentEntry(Database::"Purchase Line Discount", PurchaseLineDiscount.TableCaption(), PurchaseLineDiscount.Count());
        InsertDocumentEntry(Database::"Job Item Price", JobItemPrice.TableCaption(), JobItemPrice.Count());
        InsertDocumentEntry(Database::"Job G/L Account Price", JobGLAccountPrice.TableCaption(), JobGLAccountPrice.Count());
        InsertDocumentEntry(Database::"Job Resource Price", JobResourcePrice.TableCaption(), JobResourcePrice.Count());
        InsertDocumentEntry(Database::"Resource Price", ResourcePrice.TableCaption(), ResourcePrice.Count());
        InsertDocumentEntry(Database::"Resource Cost", ResourceCost.TableCaption(), ResourceCost.Count());

        OnAfterCountRecords(TempDocumentEntry);
    end;

    local procedure FillPriceListNos()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Price List Nos." = '' then begin
            SalesReceivablesSetup."Price List Nos." := GetPriceListNoSeries(XSPLTok, XSalesPriceListLbl, XS00001Tok, XS99999Tok);
            SalesReceivablesSetup.Modify();
        end;
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Price List Nos." = '' then begin
            PurchasesPayablesSetup."Price List Nos." := GetPriceListNoSeries(XPPLTok, XPurchasePriceListLbl, XP00001Tok, XP99999Tok);
            PurchasesPayablesSetup.Modify();
        end;
        JobsSetup.Get();
        if JobsSetup."Price List Nos." = '' then begin
            JobsSetup."Price List Nos." := GetPriceListNoSeries(XJPLTok, XJobPriceListLbl, XJ00001Tok, XJ99999Tok);
            JobsSetup.Modify();
        end;
    end;

    procedure GetPriceListNoSeries(SeriesCode: Code[20]; Description: Text[100]; StartingNo: Code[20]; EndingNo: Code[20]): Code[20];
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if NoSeries.Get(SeriesCode) then
            exit(SeriesCode);

        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine.Validate("Starting No.", StartingNo);
        NoSeriesLine.Validate("Ending No.", EndingNo);
        NoSeriesLine.Validate("Increment-by No.", 1);
        NoSeriesLine.Insert(true);
        exit(SeriesCode);
    end;

    local procedure GetListOfTables() Result: Text;
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        ResourceCost: Record "Resource Cost";
        ResourcePrice: Record "Resource Price";
    begin
        Result := StrSubstNo(
                      Description1Txt,
                      SalesPrice.TableCaption(), SalesLineDiscount.TableCaption(),
                      PurchasePrice.TableCaption(), PurchaseLineDiscount.TableCaption(),
                      JobItemPrice.TableCaption(), JobGLAccountPrice.TableCaption(), JobResourcePrice.TableCaption(),
                      JobResourcePrice.TableCaption(), ResourcePrice.TableCaption(), ResourceCost.TableCaption());
        OnAfterGetListOfTables(Result);
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure RemoveIntegrationTableMapping(TableId: Integer; IntTableId: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", TableId);
        IntegrationTableMapping.SetRange("Integration Table ID", IntTableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                if not JobQueueEntry.IsEmpty() then
                    JobQueueEntry.DeleteAll(true);
                IntegrationTableMapping.Delete(true);
            until IntegrationTableMapping.Next() = 0;
    end;

    local procedure CreateDefaultPriceLists()
    begin
        DefineDefaultPriceList("Price Type"::Sale, "Price Source Group"::Customer);
        DefineDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Vendor);
        DefineDefaultPriceList("Price Type"::Sale, "Price Source Group"::Job);
        DefineDefaultPriceList("Price Type"::Purchase, "Price Source Group"::Job);
    end;

    local procedure UpdateAmountTypeOnHeaders()
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader.SetLoadFields("Amount Type");
        if PriceListHeader.FindSet(true) then
            repeat
                PriceListHeader.UpdateAmountType();
            until PriceListHeader.Next() = 0;
    end;

    procedure DefineDefaultPriceList(PriceType: Enum "Price Type"; SourceGroup: Enum "Price Source Group") DefaultPriceListCode: Code[20];
    var
        PriceListManagement: Codeunit "Price List Management";
    begin
        DefaultPriceListCode := PriceListManagement.DefineDefaultPriceList(PriceType, SourceGroup);
    end;

    procedure FailIfFeatureDisabled()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if not PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            error(FeatureIsOffErr);
    end;

    procedure FailIfFeatureEnabled()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then
            error(FeatureIsOnErr)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCountRecords(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetListOfTables(var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDataOnBeforeUpdateAmountTypeOnHeaders(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;
}
