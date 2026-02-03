// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.DemoData.Common;
using Microsoft.DemoData.Finance;
using Microsoft.DemoData.Jobs;
using Microsoft.DemoData.Purchases;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Document;

codeunit 5430 "Create E-Doc. Sample Invoices"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocumentModuleSetup: Record "E-Document Module Setup";
        CreateGLAccount: Codeunit "Create G/L Account";
        RecurrentExpenseAccountNo, DeliveryExpenseGLAccNo : Code[20];
    begin
        if EDocumentModuleSetup.Get() then;
        if EDocumentModuleSetup."Recurring Expense G/L Acc. No" = '' then
            RecurrentExpenseAccountNo := CreateGLAccount.OtherComputerExpenses()
        else
            RecurrentExpenseAccountNo := EDocumentModuleSetup."Recurring Expense G/L Acc. No";
        if EDocumentModuleSetup."Delivery Expense G/L Acc. No" = '' then
            DeliveryExpenseGLAccNo := CreateGLAccount.DeliveryExpenses()
        else
            DeliveryExpenseGLAccNo := EDocumentModuleSetup."Delivery Expense G/L Acc. No";
        GenerateContosoInboundEDocuments(RecurrentExpenseAccountNo, DeliveryExpenseGLAccNo, EDocumentModuleSetup."Sample Invoice Date");
        GenerateSampleInvoices();
    end;

    local procedure GenerateContosoInboundEDocuments(RecurrentExpenseAccountNo: Code[20]; DeliveryExpenseGLAccNo: Code[20]; SampleInvoiceDate: Date)
    var
        ContosoInboundEDocument: Codeunit "Contoso Inbound E-Document";
        CreateVendor: Codeunit "Create Vendor";
        CreateCommonUnitOfMeasure: Codeunit "Create Common Unit Of Measure";
        CreateEDocumentMasterData: Codeunit "Create E-Document Master Data";
        CreateJobItem: Codeunit "Create Job Item";
        CreateAllocationAccount: Codeunit "Create Allocation Account";
        CreateDeferralTemplate: Codeunit "Create Deferral Template";
        EDocSamplePurchaseInvoice: Codeunit "E-Doc Sample Purchase Invoice";
        AccountingServicesJanuaryLbl: Label 'Accounting support period: January', MaxLength = 100;
        AccountingServicesFebruaryLbl: Label 'Accounting support period: February', MaxLength = 100;
        AccountingServicesMarchLbl: Label 'Accounting support period: March', MaxLength = 100;
        AccountingServicesDecemberLbl: Label 'Accounting support period: December', MaxLength = 100;
        AccountingServicesMayLbl: Label 'Accounting support period: May', MaxLength = 100;
        SavedWorkDate: Date;
    begin
        SavedWorkDate := WorkDate();
        if SampleInvoiceDate = 0D then
            SampleInvoiceDate := EDocSamplePurchaseInvoice.GetSampleInvoicePostingDate();
        WorkDate(SampleInvoiceDate);
        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.EUGraphicDesign(), SampleInvoiceDate, '245');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"Allocation Account", CreateAllocationAccount.Licenses(),
            CreateAllocationAccount.LicensesDescription(), 6, 500, CreateDeferralTemplate.DeferralCode1Y(), '');
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticFirstUp(), SampleInvoiceDate, '1419');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", RecurrentExpenseAccountNo,
            AccountingServicesJanuaryLbl, 6, 200, '', CreateCommonUnitOfMeasure.Hour());
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticFirstUp(), SampleInvoiceDate, '1425');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", RecurrentExpenseAccountNo,
            AccountingServicesFebruaryLbl, 19, 200, '', CreateCommonUnitOfMeasure.Hour());
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticFirstUp(), SampleInvoiceDate, '1437');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", RecurrentExpenseAccountNo,
            AccountingServicesMarchLbl, 2, 200, '', CreateCommonUnitOfMeasure.Hour());
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticFirstUp(), SampleInvoiceDate, '1479');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", RecurrentExpenseAccountNo,
            AccountingServicesMayLbl, 16, 200, '', CreateCommonUnitOfMeasure.Hour());
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticFirstUp(), SampleInvoiceDate, '1456');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", RecurrentExpenseAccountNo,
            AccountingServicesDecemberLbl, 7, 200, '', CreateCommonUnitOfMeasure.Hour());
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.ExportFabrikam(), SampleInvoiceDate, 'F12938');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.WholeDecafBeansColombia(),
            '', 50, 5, '', CreateCommonUnitOfMeasure.Piece());
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::Item, CreateJobItem.ItemConsumable(),
            '', 50, 65, '', CreateCommonUnitOfMeasure.Piece());
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::"G/L Account", DeliveryExpenseGLAccNo,
            CreateAllocationAccount.LicensesDescription(), 1, 60, '', '');
        ContosoInboundEDocument.Generate();

        ContosoInboundEDocument.AddEDocPurchaseHeader(CreateVendor.DomesticWorldImporter(), SampleInvoiceDate, '000982');
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.SmartGrindHome(),
            '', 100, 299, '', CreateCommonUnitOfMeasure.Piece());
        ContosoInboundEDocument.AddEDocPurchaseLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.PrecisionGrindHome(),
            '', 50, 199, '', CreateCommonUnitOfMeasure.Piece());
        ContosoInboundEDocument.Generate();
        WorkDate(SavedWorkDate);
    end;

    local procedure GenerateSampleInvoices()
    var
        EDocSamplePurchaseInvoice: Codeunit "E-Doc Sample Purchase Invoice";
        CreateVendor: Codeunit "Create Vendor";
        CreateEDocumentMasterData: Codeunit "Create E-Document Master Data";
        CreateJobItem: Codeunit "Create Job Item";
        CreateCommonUnitOfMeasure: Codeunit "Create Common Unit Of Measure";
        CreateAllocationAccount: Codeunit "Create Allocation Account";
        YearlyLicenstCostLbl: Label 'Yearly license cost mapped to a G/L account';
        BasicCoffeeEquipmentLbl: Label 'Basic coffee equipment mapped to vendor''s Item References';
        CoffeeBeansAndPartsLbl: Label 'Coffee beans and parts with shipping cost that needs human intervention';
    begin
        EDocSamplePurchaseInvoice.SetMixLayoutsForPDFGeneration();
        EDocSamplePurchaseInvoice.AddInvoice(CreateVendor.ExportFabrikam(), '108925', CoffeeBeansAndPartsLbl);
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.WholeDecafBeansColombia(), '', 50, 5, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::Item, CreateJobItem.ItemConsumable(), '', 50, 65, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::" ", '', CreateAllocationAccount.LicensesDescription(), 1, 60, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.Generate();

        EDocSamplePurchaseInvoice.AddInvoice(CreateVendor.DomesticWorldImporter(), '108426', BasicCoffeeEquipmentLbl);
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.SmartGrindHome(), '', 100, 299, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::Item, CreateEDocumentMasterData.PrecisionGrindHome(), '', 50, 199, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.Generate();

        EDocSamplePurchaseInvoice.AddInvoice(CreateVendor.EUGraphicDesign(), '108427', YearlyLicenstCostLbl);
        EDocSamplePurchaseInvoice.AddLine(
            Enum::"Purchase Line Type"::" ", '', CreateAllocationAccount.LicensesDescription(), 6, 500, '', CreateCommonUnitOfMeasure.Piece());
        EDocSamplePurchaseInvoice.Generate();
    end;
}