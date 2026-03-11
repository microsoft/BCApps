// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

codeunit 139983 "Subc. Management Library"
{
    procedure Initialize()
    begin
        CreateSubcontractingManagementSetup();
    end;

    procedure CreateSubcontractingManagementSetup()
    var
        SubcontractingManagementSetup: Record "Subc. Management Setup";
    begin
        SubcontractingManagementSetup.Reset();
        if not SubcontractingManagementSetup.Get() then begin
            SubcontractingManagementSetup.Init();
            SubcontractingManagementSetup.Insert(true);
        end;
    end;

    procedure CreateSubContractingPrice(var SubcontractorPrices: Record "Subcontractor Price"; WorkCenterNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; StandardTaskCode: Code[10]; VariantCode: Code[10]; StartDate: Date; UnitOfMeasureCode: Code[10]; MinimumQuantity: Decimal; CurrencyCode: Code[10])
    begin
        SubcontractorPrices.Init();
        SubcontractorPrices.Validate("Work Center No.", WorkCenterNo);
        SubcontractorPrices.Validate("Vendor No.", VendorNo);
        SubcontractorPrices.Validate("Item No.", ItemNo);
        SubcontractorPrices.Validate("Standard Task Code", StandardTaskCode);
        SubcontractorPrices.Validate("Variant Code", VariantCode);
        SubcontractorPrices.Validate("Starting Date", StartDate);
        SubcontractorPrices.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SubcontractorPrices.Validate("Minimum Quantity", MinimumQuantity);
        SubcontractorPrices.Validate("Currency Code", CurrencyCode);
        SubcontractorPrices.Insert(true);
    end;

    procedure CreateSubcontractorPrice(Item: Record Item; WorkCenterNo: Code[20]; var SubcontractorPrice: Record "Subcontractor Price")
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        LibraryRandom: Codeunit "Library - Random";
        i: Integer;
        NoOfLoops: Integer;
    begin
        SubcontractorPrice.DeleteAll();
        NoOfLoops := LibraryRandom.RandInt(20);

        WorkCenter.Get(WorkCenterNo);
        Vendor.Get(WorkCenter."Subcontractor No.");
        for i := 1 to NoOfLoops do begin
            SubcontractorPrice.Init();
            SubcontractorPrice."Vendor No." := Vendor."No.";
            SubcontractorPrice."Item No." := Item."No.";
            SubcontractorPrice."Work Center No." := WorkCenter."No.";
            SubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
            SubcontractorPrice."Currency Code" := Vendor."Currency Code";
            SubcontractorPrice."Minimum Quantity" := i;
            SubcontractorPrice."Direct Unit Cost" := LibraryRandom.RandInt(100);
            SubcontractorPrice.Insert();
        end;
    end;
}