// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Bank.Reconciliation;
using Microsoft.BusinessSkill;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

codeunit 3327 "PA BC IQ Demo Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Cost Entry" = r,
                  tabledata "Cost Type" = rimd,
                  tabledata "Default Dimension" = rimd,
                  tabledata "Dimension Value" = r,
                  tabledata "G/L Account" = rimd,
                  tabledata "G/L Budget Entry" = r,
                  tabledata "G/L Entry" = r,
                  tabledata "Gen. Business Posting Group" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Product Posting Group" = r,
                  tabledata "PA BC IQ Demo State" = rimd,
                  tabledata "Payables Agent Setup" = rimd,
                  tabledata "Payment Terms" = r,
                  tabledata "Purch. Inv. Header" = r,
                  tabledata "Purchase Header" = rimd,
                  tabledata "Purchase Line" = rimd,
                  tabledata "Sales Line" = r,
                  tabledata "Text-to-Account Mapping" = rimd,
                  tabledata "Unit of Measure" = r,
                  tabledata "VAT Business Posting Group" = r,
                  tabledata "VAT Entry" = r,
                  tabledata "VAT Posting Setup" = rimd,
                  tabledata "VAT Product Posting Group" = rimd,
                  tabledata Vendor = rimd,
                  tabledata "Vendor Ledger Entry" = r,
                  tabledata "Vendor Posting Group" = r;

    procedure SetupCompany()
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        VerifyTargetCompany();
        VerifySetupPrerequisites();
        InitializeState(DemoState);

        CreateVATProductPostingGroups();
        CreateDemoGLAccounts(DemoState);
        UpdateExistingAccountVATDefaults();
        CreateVATPostingSetups();
        UpdateExistingVendors();
        CreateElectricityVendor();
        CreateDefaultDimensions(DemoState);
        CreateTextToAccountMappings(DemoState);
        CreateHistoryInvoices(DemoState);
        CreateBusinessSkills(DemoState);
        SetBusinessCentralIQEnabled(false);

        DemoState.Insert(true);
    end;

    procedure UpgradeCompany()
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        VerifyTargetCompany();
        if not DemoState.Get(StatePrimaryKeyTok) then
            Error(NotConfiguredErr);
        if DemoState."Setup Version" = 2 then
            Error(AlreadyConfiguredErr);
        if DemoState."Setup Version" <> 0 then
            Error(UnsupportedSetupVersionErr, DemoState."Setup Version");

        CleanupLegacyCompany(DemoState);
        SetupCompany();
    end;

    procedure CleanupCompany()
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        VerifyTargetCompany();
        if not DemoState.Get(StatePrimaryKeyTok) then
            Error(NotConfiguredErr);

        if DemoState."Setup Version" = 0 then begin
            CleanupLegacyCompany(DemoState);
            exit;
        end;
        if DemoState."Setup Version" <> 2 then
            Error(UnsupportedSetupVersionErr, DemoState."Setup Version");

        VerifyCleanupIsSafe(DemoState);

        DeleteHistoryInvoices(DemoState);
        DeleteBusinessSkills(DemoState);
        DeleteTextToAccountMappings(DemoState);
        DeleteDefaultDimensions(DemoState);
        DeleteVATPostingSetups();
        DeleteDemoExpenseAccount(MeteredElectricityAccountNoTok, DemoState."Electricity Cost Type Created");
        DeleteDemoExpenseAccount(RepairMaterialsAccountNoTok, DemoState."Repair Mat. Cost Type Created");
        DeleteDemoExpenseAccount(MaintenanceLabourAccountNoTok, DemoState."Maintenance Cost Type Created");
        DeleteDemoExpenseAccount(OfficeConsumablesAccountNoTok, DemoState."Office Cons. Cost Type Created");
        DeleteDemoExpenseAccount(TrainingCostsAccountNoTok, DemoState."Training Cost Type Created");
        DeleteElectricityVendor();
        DeleteDemoGLAccount(SalesVATAccountNoTok);
        DeleteDemoGLAccount(PurchaseVATAccountNoTok);
        RestoreExistingAccountVATDefaults(DemoState);
        DeleteVATProductPostingGroups();
        RestoreExistingVendors(DemoState);
        SetBusinessCentralIQEnabled(DemoState."Original Use BC IQ");
        DemoState.Delete(true);
    end;

    procedure SetBusinessCentralIQEnabled(Enabled: Boolean)
    var
        DemoState: Record "PA BC IQ Demo State";
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        VerifyTargetCompany();
        if not DemoState.Get(StatePrimaryKeyTok) or (DemoState."Setup Version" <> 2) then
            Error(NotConfiguredErr);

        PayablesAgentSetup.GetSetup();
        if PayablesAgentSetup."Use Business Central IQ" = Enabled then
            exit;
        PayablesAgentSetup."Use Business Central IQ" := Enabled;
        PayablesAgentSetup.Modify(true);
    end;

    procedure IsConfigured(): Boolean
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        exit(DemoState.Get(StatePrimaryKeyTok) and (DemoState."Setup Version" = 2));
    end;

    procedure NeedsUpgrade(): Boolean
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        exit(DemoState.Get(StatePrimaryKeyTok) and (DemoState."Setup Version" <> 2));
    end;

    procedure IsBusinessCentralIQEnabled(): Boolean
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if not PayablesAgentSetup.GetSetup(false) then
            exit(false);
        exit(PayablesAgentSetup."Use Business Central IQ");
    end;

    procedure GetHistoryInvoiceCount(): Integer
    var
        DemoState: Record "PA BC IQ Demo State";
        PurchaseHeader: Record "Purchase Header";
        Count: Integer;
    begin
        if not DemoState.Get(StatePrimaryKeyTok) or (DemoState."Setup Version" <> 2) then
            exit(0);

        if PurchaseHeader.GetBySystemId(DemoState."June History System ID") then
            Count += 1;
        if PurchaseHeader.GetBySystemId(DemoState."July History System ID") then
            Count += 1;
        if PurchaseHeader.GetBySystemId(DemoState."August History System ID") then
            Count += 1;
        if PurchaseHeader.GetBySystemId(DemoState."September History System ID") then
            Count += 1;
        exit(Count);
    end;

    procedure GetStatusText(): Text
    begin
        if CompanyName() <> TargetCompanyNameTok then
            exit(StrSubstNo(WrongCompanyStatusLbl, CompanyName(), TargetCompanyNameTok));
        if NeedsUpgrade() then
            exit(UpgradeRequiredStatusLbl);
        if IsConfigured() then
            if IsConfigurationIntact() then
                exit(ConfiguredStatusLbl)
            else
                exit(IncompleteStatusLbl);
        exit(NotConfiguredStatusLbl);
    end;

    local procedure VerifyTargetCompany()
    begin
        if CompanyName() <> TargetCompanyNameTok then
            Error(WrongCompanyErr, TargetCompanyNameTok, CompanyName());
    end;

    local procedure VerifySetupPrerequisites()
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        if DemoState.Get(StatePrimaryKeyTok) then
            if DemoState."Setup Version" = 2 then
                Error(AlreadyConfiguredErr)
            else
                Error(UpgradeRequiredErr);

        VerifyExistingVendor(ConsultingVendorNoTok);
        VerifyExistingVendor(SuppliesVendorNoTok);
        VerifyExistingGLAccount(ElectricityAccountNoTok);
        VerifyExistingGLAccount(RepairMaintenanceAccountNoTok);
        VerifyExistingGLAccount(OfficeSuppliesAccountNoTok);
        VerifyExistingGLAccount(ConsultantServicesAccountNoTok);
        VerifyExistingGLAccount(AccountingServicesAccountNoTok);
        VerifyExistingGLAccount(SalesVATTemplateAccountNoTok);
        VerifyExistingGLAccount(PurchaseVATTemplateAccountNoTok);

        VerifyRecordDoesNotExist(Database::Vendor, ElectricityVendorNoTok);
        VerifyProposedGLAccountDoesNotExist(MeteredElectricityAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(RepairMaterialsAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(MaintenanceLabourAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(OfficeConsumablesAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(TrainingCostsAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(SalesVATAccountNoTok);
        VerifyProposedGLAccountDoesNotExist(PurchaseVATAccountNoTok);
        VerifyVATProductPostingGroupsDoNotExist();
        VerifyVATPostingSetupsDoNotExist();
        VerifyTextMappingsDoNotExist();
        VerifyHistoryInvoicesDoNotExist();
        VerifyPostingSetupPrerequisites();
        VerifyDimensionPrerequisites();
        VerifyUnitOfMeasurePrerequisites();
    end;

    local procedure VerifyExistingVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(VendorNo) then
            Error(RequiredRecordMissingErr, Vendor.TableCaption(), VendorNo);
    end;

    local procedure VerifyExistingGLAccount(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(GLAccountNo) then
            Error(RequiredRecordMissingErr, GLAccount.TableCaption(), GLAccountNo);
    end;

    local procedure VerifyProposedGLAccountDoesNotExist(GLAccountNo: Code[20])
    begin
        VerifyRecordDoesNotExist(Database::"G/L Account", GLAccountNo);
        VerifyRecordDoesNotExist(Database::"Cost Type", GLAccountNo);
    end;

    local procedure VerifyRecordDoesNotExist(TableNo: Integer; RecordKey: Code[20])
    var
        RecordRef: RecordRef;
        PrimaryKeyField: FieldRef;
    begin
        RecordRef.Open(TableNo);
        PrimaryKeyField := RecordRef.FieldIndex(1);
        PrimaryKeyField.SetRange(RecordKey);
        if not RecordRef.IsEmpty() then
            Error(ProposedRecordExistsErr, RecordRef.Caption(), RecordKey);
        RecordRef.Close();
    end;

    local procedure VerifyVATProductPostingGroupsDoNotExist()
    begin
        VerifyRecordDoesNotExist(Database::"VAT Product Posting Group", GenericVATProductGroupTok);
        VerifyRecordDoesNotExist(Database::"VAT Product Posting Group", GoodsVATProductGroupTok);
        VerifyRecordDoesNotExist(Database::"VAT Product Posting Group", ServicesVATProductGroupTok);
        VerifyRecordDoesNotExist(Database::"VAT Product Posting Group", UtilitiesVATProductGroupTok);
    end;

    local procedure VerifyVATPostingSetupsDoNotExist()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VerifyVATPostingSetupDoesNotExist(VATPostingSetup, GenericVATProductGroupTok);
        VerifyVATPostingSetupDoesNotExist(VATPostingSetup, GoodsVATProductGroupTok);
        VerifyVATPostingSetupDoesNotExist(VATPostingSetup, ServicesVATProductGroupTok);
        VerifyVATPostingSetupDoesNotExist(VATPostingSetup, UtilitiesVATProductGroupTok);
    end;

    local procedure VerifyVATPostingSetupDoesNotExist(var VATPostingSetup: Record "VAT Posting Setup"; VATProductPostingGroupCode: Code[20])
    begin
        if VATPostingSetup.Get(DomesticPostingGroupTok, VATProductPostingGroupCode) then
            Error(ProposedCombinationExistsErr, DomesticPostingGroupTok, VATProductPostingGroupCode);
    end;

    local procedure VerifyTextMappingsDoNotExist()
    begin
        VerifyTextMappingDoesNotExist(SuppliesVendorNoTok, RepairMaterialsMappingTextLbl);
        VerifyTextMappingDoesNotExist(SuppliesVendorNoTok, OfficeConsumablesMappingTextLbl);
        VerifyTextMappingDoesNotExist(SuppliesVendorNoTok, MaintenanceLabourMappingTextLbl);
        VerifyTextMappingDoesNotExist(ElectricityVendorNoTok, ElectricityMappingTextLbl);
        VerifyTextMappingDoesNotExist(ConsultingVendorNoTok, AccountingMappingTextLbl);
        VerifyTextMappingDoesNotExist(ConsultingVendorNoTok, TrainingMappingTextLbl);
        VerifyTextMappingDoesNotExist(ConsultingVendorNoTok, ConsultingMappingTextLbl);
        VerifyTextMappingDoesNotExist(ConsultingVendorNoTok, MonthlyBookkeepingMappingTextLbl);
    end;

    local procedure VerifyTextMappingDoesNotExist(VendorNo: Code[20]; MappingText: Text[250])
    var
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccountMapping.SetRange("Vendor No.", VendorNo);
        TextToAccountMapping.SetRange("Mapping Text", MappingText);
        if not TextToAccountMapping.IsEmpty() then
            Error(ProposedTextMappingExistsErr, VendorNo, MappingText);
    end;

    local procedure VerifyHistoryInvoicesDoNotExist()
    begin
        VerifyHistoryInvoiceDoesNotExist(JuneVendorInvoiceNoTok);
        VerifyHistoryInvoiceDoesNotExist(JulyVendorInvoiceNoTok);
        VerifyHistoryInvoiceDoesNotExist(AugustVendorInvoiceNoTok);
        VerifyHistoryInvoiceDoesNotExist(SeptemberVendorInvoiceNoTok);
    end;

    local procedure VerifyHistoryInvoiceDoesNotExist(VendorInvoiceNo: Code[35])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("Buy-from Vendor No.", ConsultingVendorNoTok);
        PurchaseHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        if not PurchaseHeader.IsEmpty() then
            Error(ProposedHistoryInvoiceExistsErr, VendorInvoiceNo);
        PurchInvHeader.SetRange("Buy-from Vendor No.", ConsultingVendorNoTok);
        PurchInvHeader.SetRange("Vendor Invoice No.", VendorInvoiceNo);
        if not PurchInvHeader.IsEmpty() then
            Error(ProposedHistoryInvoiceExistsErr, VendorInvoiceNo);
    end;

    local procedure VerifyPostingSetupPrerequisites()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        PaymentTerms: Record "Payment Terms";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        RequireRecord(GenBusinessPostingGroup.Get(DomesticPostingGroupTok), GenBusinessPostingGroup.TableCaption(), DomesticPostingGroupTok);
        RequireRecord(GenProductPostingGroup.Get(MiscPostingGroupTok), GenProductPostingGroup.TableCaption(), MiscPostingGroupTok);
        RequireRecord(GenProductPostingGroup.Get(ServicesPostingGroupTok), GenProductPostingGroup.TableCaption(), ServicesPostingGroupTok);
        RequireRecord(PaymentTerms.Get(ThirtyDaysPaymentTermsTok), PaymentTerms.TableCaption(), ThirtyDaysPaymentTermsTok);
        RequireRecord(VATBusinessPostingGroup.Get(DomesticPostingGroupTok), VATBusinessPostingGroup.TableCaption(), DomesticPostingGroupTok);
        RequireRecord(VendorPostingGroup.Get(DomesticPostingGroupTok), VendorPostingGroup.TableCaption(), DomesticPostingGroupTok);
    end;

    local procedure VerifyDimensionPrerequisites()
    begin
        VerifyDimensionValue(AdministrationDepartmentTok);
        VerifyDimensionValue(ProductionDepartmentTok);
        VerifyDimensionValue(SalesDepartmentTok);
    end;

    local procedure VerifyDimensionValue(DimensionValueCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        if not DimensionValue.Get(DepartmentDimensionTok, DimensionValueCode) then
            Error(RequiredDimensionValueMissingErr, DepartmentDimensionTok, DimensionValueCode);
        if DimensionValue.Blocked then
            Error(RequiredDimensionValueBlockedErr, DepartmentDimensionTok, DimensionValueCode);
    end;

    local procedure VerifyUnitOfMeasurePrerequisites()
    begin
        VerifyUnitOfMeasure('KWH');
        VerifyUnitOfMeasure('HOUR');
        VerifyUnitOfMeasure('PACK');
        VerifyUnitOfMeasure('SET');
    end;

    local procedure VerifyUnitOfMeasure(UnitOfMeasureCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not UnitOfMeasure.Get(UnitOfMeasureCode) then
            Error(RequiredRecordMissingErr, UnitOfMeasure.TableCaption(), UnitOfMeasureCode);
    end;

    local procedure RequireRecord(RecordExists: Boolean; RecordCaption: Text; RecordKey: Text)
    begin
        if not RecordExists then
            Error(RequiredRecordMissingErr, RecordCaption, RecordKey);
    end;

    local procedure InitializeState(var DemoState: Record "PA BC IQ Demo State")
    var
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        PayablesAgentSetup: Record "Payables Agent Setup";
        Vendor: Record Vendor;
    begin
        DemoState.Init();
        DemoState."Primary Key" := StatePrimaryKeyTok;
        DemoState."Setup Version" := 2;

        Vendor.Get(ConsultingVendorNoTok);
        DemoState."Vendor 20000 VAT Reg. No." := Vendor."VAT Registration No.";
        DemoState."Vendor 20000 Payment Terms" := Vendor."Payment Terms Code";

        Vendor.Get(SuppliesVendorNoTok);
        DemoState."Vendor 40000 VAT Reg. No." := Vendor."VAT Registration No.";
        DemoState."Vendor 40000 Payment Terms" := Vendor."Payment Terms Code";

        DemoState."Account 8120 VAT Prod. Group" := GetAccountVATProductPostingGroup(GLAccount, ElectricityAccountNoTok);
        DemoState."Account 8130 VAT Prod. Group" := GetAccountVATProductPostingGroup(GLAccount, RepairMaintenanceAccountNoTok);
        DemoState."Account 8210 VAT Prod. Group" := GetAccountVATProductPostingGroup(GLAccount, OfficeSuppliesAccountNoTok);
        DemoState."Account 8320 VAT Prod. Group" := GetAccountVATProductPostingGroup(GLAccount, ConsultantServicesAccountNoTok);
        DemoState."Account 8630 VAT Prod. Group" := GetAccountVATProductPostingGroup(GLAccount, AccountingServicesAccountNoTok);

        if DefaultDimension.Get(Database::Vendor, ConsultingVendorNoTok, DepartmentDimensionTok) then begin
            DemoState."Vendor 20000 Dept. Existed" := true;
            DemoState."Vendor 20000 Dept. Value" := DefaultDimension."Dimension Value Code";
            DemoState."Vendor 20000 Dept. Posting" := DefaultDimension."Value Posting";
        end;

        PayablesAgentSetup.GetSetup();
        DemoState."Original Use BC IQ" := PayablesAgentSetup."Use Business Central IQ";
    end;

    local procedure GetAccountVATProductPostingGroup(var GLAccount: Record "G/L Account"; GLAccountNo: Code[20]): Code[20]
    begin
        GLAccount.Get(GLAccountNo);
        exit(GLAccount."VAT Prod. Posting Group");
    end;

    local procedure CreateVATProductPostingGroups()
    begin
        CreateVATProductPostingGroup(GenericVATProductGroupTok, GenericVATDescriptionLbl);
        CreateVATProductPostingGroup(GoodsVATProductGroupTok, GoodsVATDescriptionLbl);
        CreateVATProductPostingGroup(ServicesVATProductGroupTok, ServicesVATDescriptionLbl);
        CreateVATProductPostingGroup(UtilitiesVATProductGroupTok, UtilitiesVATDescriptionLbl);
    end;

    local procedure CreateVATProductPostingGroup(GroupCode: Code[20]; GroupDescription: Text[100])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := GroupCode;
        VATProductPostingGroup.Validate(Description, GroupDescription);
        VATProductPostingGroup.Insert(true);
    end;

    local procedure CreateDemoGLAccounts(var DemoState: Record "PA BC IQ Demo State")
    begin
        DemoState."Electricity Cost Type Created" :=
            CreateExpenseAccount(ElectricityAccountNoTok, MeteredElectricityAccountNoTok, MeteredElectricityAccountNameLbl, MiscPostingGroupTok, UtilitiesVATProductGroupTok);
        DemoState."Repair Mat. Cost Type Created" :=
            CreateExpenseAccount(RepairMaintenanceAccountNoTok, RepairMaterialsAccountNoTok, RepairMaterialsAccountNameLbl, MiscPostingGroupTok, GoodsVATProductGroupTok);
        DemoState."Maintenance Cost Type Created" :=
            CreateExpenseAccount(RepairMaintenanceAccountNoTok, MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, ServicesPostingGroupTok, ServicesVATProductGroupTok);
        DemoState."Office Cons. Cost Type Created" :=
            CreateExpenseAccount(OfficeSuppliesAccountNoTok, OfficeConsumablesAccountNoTok, OfficeConsumablesAccountNameLbl, MiscPostingGroupTok, GoodsVATProductGroupTok);
        DemoState."Training Cost Type Created" :=
            CreateExpenseAccount(AccountingServicesAccountNoTok, TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, ServicesPostingGroupTok, ServicesVATProductGroupTok);
        CreateVATAccount(SalesVATTemplateAccountNoTok, SalesVATAccountNoTok, SalesVATAccountNameLbl);
        CreateVATAccount(PurchaseVATTemplateAccountNoTok, PurchaseVATAccountNoTok, PurchaseVATAccountNameLbl);
    end;

    local procedure CreateExpenseAccount(TemplateAccountNo: Code[20]; NewAccountNo: Code[20]; NewAccountName: Text[100]; GenProductPostingGroupCode: Code[20]; VATProductPostingGroupCode: Code[20]): Boolean
    var
        CostType: Record "Cost Type";
        NewGLAccount: Record "G/L Account";
        TemplateGLAccount: Record "G/L Account";
    begin
        TemplateGLAccount.Get(TemplateAccountNo);
        NewGLAccount.Init();
        NewGLAccount.TransferFields(TemplateGLAccount, false);
        NewGLAccount."No." := NewAccountNo;
        NewGLAccount.Validate(Name, NewAccountName);
        NewGLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroupCode);
        NewGLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        NewGLAccount."Global Dimension 1 Code" := '';
        NewGLAccount."Global Dimension 2 Code" := '';
        NewGLAccount.Insert(true);
        exit((NewGLAccount."Cost Type No." = NewAccountNo) and CostType.Get(NewAccountNo));
    end;

    local procedure CreateVATAccount(TemplateAccountNo: Code[20]; NewAccountNo: Code[20]; NewAccountName: Text[100])
    var
        NewGLAccount: Record "G/L Account";
        TemplateGLAccount: Record "G/L Account";
    begin
        TemplateGLAccount.Get(TemplateAccountNo);
        NewGLAccount.Init();
        NewGLAccount.TransferFields(TemplateGLAccount, false);
        NewGLAccount."No." := NewAccountNo;
        NewGLAccount.Validate(Name, NewAccountName);
        NewGLAccount.Validate("Direct Posting", false);
        NewGLAccount.Validate("Gen. Prod. Posting Group", '');
        NewGLAccount.Validate("VAT Prod. Posting Group", '');
        NewGLAccount."Global Dimension 1 Code" := '';
        NewGLAccount."Global Dimension 2 Code" := '';
        NewGLAccount.Insert(true);
    end;

    local procedure UpdateExistingAccountVATDefaults()
    begin
        UpdateAccountVATProductPostingGroup(ElectricityAccountNoTok, GenericVATProductGroupTok);
        UpdateAccountVATProductPostingGroup(RepairMaintenanceAccountNoTok, GenericVATProductGroupTok);
        UpdateAccountVATProductPostingGroup(OfficeSuppliesAccountNoTok, GenericVATProductGroupTok);
        UpdateAccountVATProductPostingGroup(ConsultantServicesAccountNoTok, GenericVATProductGroupTok);
        UpdateAccountVATProductPostingGroup(AccountingServicesAccountNoTok, GenericVATProductGroupTok);
    end;

    local procedure UpdateAccountVATProductPostingGroup(GLAccountNo: Code[20]; VATProductPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetups()
    begin
        CreateVATPostingSetup(GenericVATProductGroupTok);
        CreateVATPostingSetup(GoodsVATProductGroupTok);
        CreateVATPostingSetup(ServicesVATProductGroupTok);
        CreateVATPostingSetup(UtilitiesVATProductGroupTok);
    end;

    local procedure CreateVATPostingSetup(VATProductPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", DomesticPostingGroupTok);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 20);
        VATPostingSetup.Validate("VAT Identifier", VATProductPostingGroupCode);
        VATPostingSetup.Validate("Sales VAT Account", SalesVATAccountNoTok);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAccountNoTok);
        VATPostingSetup.Insert(true);
    end;

    local procedure UpdateExistingVendors()
    begin
        UpdateExistingVendor(ConsultingVendorNoTok, ConsultingVendorVATRegistrationNoTok);
        UpdateExistingVendor(SuppliesVendorNoTok, SuppliesVendorVATRegistrationNoTok);
    end;

    local procedure UpdateExistingVendor(VendorNo: Code[20]; VATRegistrationNo: Text[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Validate("Payment Terms Code", ThirtyDaysPaymentTermsTok);
        Vendor.Modify(true);
    end;

    local procedure CreateElectricityVendor()
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := ElectricityVendorNoTok;
        Vendor.Validate(Name, ElectricityVendorNameLbl);
        Vendor.Validate(Address, ElectricityVendorAddressLbl);
        Vendor.Validate("Country/Region Code", 'GB');
        Vendor.Validate(City, 'Birmingham');
        Vendor.Validate("Post Code", 'B1 1AA');
        Vendor.Validate("VAT Registration No.", ElectricityVendorVATRegistrationNoTok);
        Vendor.Validate("Payment Terms Code", ThirtyDaysPaymentTermsTok);
        Vendor.Validate("Gen. Bus. Posting Group", DomesticPostingGroupTok);
        Vendor.Validate("VAT Bus. Posting Group", DomesticPostingGroupTok);
        Vendor.Validate("Vendor Posting Group", DomesticPostingGroupTok);
        Vendor.Insert(true);
    end;

    local procedure CreateDefaultDimensions(var DemoState: Record "PA BC IQ Demo State")
    begin
        SetVendorDepartmentDefault(ConsultingVendorNoTok, SalesDepartmentTok);
        SetVendorDepartmentDefault(ElectricityVendorNoTok, AdministrationDepartmentTok);
    end;

    local procedure SetVendorDepartmentDefault(VendorNo: Code[20]; DepartmentCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        if not DefaultDimension.Get(Database::Vendor, VendorNo, DepartmentDimensionTok) then begin
            DefaultDimension.Init();
            DefaultDimension.Validate("Table ID", Database::Vendor);
            DefaultDimension.Validate("No.", VendorNo);
            DefaultDimension.Validate("Dimension Code", DepartmentDimensionTok);
            DefaultDimension.Insert(true);
        end;
        DefaultDimension.Validate("Dimension Value Code", DepartmentCode);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::" ");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateTextToAccountMappings(var DemoState: Record "PA BC IQ Demo State")
    begin
        DemoState."Repair Material Mapping Line" := CreateTextToAccountMapping(SuppliesVendorNoTok, RepairMaterialsMappingTextLbl, RepairMaintenanceAccountNoTok);
        DemoState."Office Consum. Mapping Line" := CreateTextToAccountMapping(SuppliesVendorNoTok, OfficeConsumablesMappingTextLbl, OfficeSuppliesAccountNoTok);
        DemoState."Maintenance Mapping Line" := CreateTextToAccountMapping(SuppliesVendorNoTok, MaintenanceLabourMappingTextLbl, RepairMaintenanceAccountNoTok);
        DemoState."Electricity Mapping Line" := CreateTextToAccountMapping(ElectricityVendorNoTok, ElectricityMappingTextLbl, ElectricityAccountNoTok);
        DemoState."Accounting Mapping Line" := CreateTextToAccountMapping(ConsultingVendorNoTok, AccountingMappingTextLbl, ConsultantServicesAccountNoTok);
        DemoState."Training Mapping Line" := CreateTextToAccountMapping(ConsultingVendorNoTok, TrainingMappingTextLbl, ConsultantServicesAccountNoTok);
        DemoState."Consulting Mapping Line" := CreateTextToAccountMapping(ConsultingVendorNoTok, ConsultingMappingTextLbl, ConsultantServicesAccountNoTok);
        DemoState."Monthly Books Mapping Line" := CreateTextToAccountMapping(ConsultingVendorNoTok, MonthlyBookkeepingMappingTextLbl, AccountingServicesAccountNoTok);
    end;

    local procedure CreateTextToAccountMapping(VendorNo: Code[20]; MappingText: Text[250]; DebitAccountNo: Code[20]): Integer
    var
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        if TextToAccountMapping.FindLast() then;
        TextToAccountMapping.Init();
        TextToAccountMapping."Line No." += 10000;
        TextToAccountMapping.Validate("Mapping Text", MappingText);
        TextToAccountMapping.Validate("Debit Acc. No.", DebitAccountNo);
        TextToAccountMapping.Validate("Vendor No.", VendorNo);
        TextToAccountMapping.Insert(true);
        exit(TextToAccountMapping."Line No.");
    end;

    local procedure CreateHistoryInvoices(var DemoState: Record "PA BC IQ Demo State")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateHistoryInvoice(PurchaseHeader, JuneVendorInvoiceNoTok, DMY2Date(30, 6, 2026), JuneServiceDescriptionLbl);
        DemoState."June History System ID" := PurchaseHeader.SystemId;
        DemoState."June History Document No." := PurchaseHeader."No.";

        CreateHistoryInvoice(PurchaseHeader, JulyVendorInvoiceNoTok, DMY2Date(31, 7, 2026), JulyServiceDescriptionLbl);
        DemoState."July History System ID" := PurchaseHeader.SystemId;
        DemoState."July History Document No." := PurchaseHeader."No.";

        CreateHistoryInvoice(PurchaseHeader, AugustVendorInvoiceNoTok, DMY2Date(31, 8, 2026), AugustServiceDescriptionLbl);
        DemoState."August History System ID" := PurchaseHeader.SystemId;
        DemoState."August History Document No." := PurchaseHeader."No.";

        CreateHistoryInvoice(PurchaseHeader, SeptemberVendorInvoiceNoTok, DMY2Date(30, 9, 2026), SeptemberServiceDescriptionLbl);
        DemoState."September History System ID" := PurchaseHeader.SystemId;
        DemoState."September History Document No." := PurchaseHeader."No.";
    end;

    local procedure CreateHistoryInvoice(var PurchaseHeader: Record "Purchase Header"; VendorInvoiceNo: Code[35]; PostingDate: Date; ServiceDescription: Text[100])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Clear(PurchaseHeader);
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader."No." := '';
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", ConsultingVendorNoTok);
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Modify(true);

        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Validate(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.Validate("No.", AccountingServicesAccountNoTok);
        PurchaseLine.Validate(Description, ServiceDescription);
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 1500);
        PurchaseLine.Validate("VAT Prod. Posting Group", GenericVATProductGroupTok);
        PurchaseLine.Validate("Shortcut Dimension 1 Code", SalesDepartmentTok);
        PurchaseLine.Insert(true);
    end;

    local procedure CreateBusinessSkills(var DemoState: Record "PA BC IQ Demo State")
    begin
        DemoState."Line Classification Skill ID" :=
            CreateCompanySkill(LineClassificationSkillTitleLbl, LineClassificationSkillDescriptionLbl, GetLineClassificationSkillText());
        DemoState."Electricity Meter Skill ID" :=
            CreateCompanySkill(ElectricityMeterSkillTitleLbl, ElectricityMeterSkillDescriptionLbl, GetElectricityMeterSkillText());
        DemoState."Service Class. Skill ID" :=
            CreateCompanySkill(ServiceClassificationSkillTitleLbl, ServiceClassificationSkillDescriptionLbl, GetServiceClassificationSkillText());
        DemoState."Effective Date Skill ID" :=
            CreateCompanySkill(EffectiveDateSkillTitleLbl, EffectiveDateSkillDescriptionLbl, GetEffectiveDateSkillText());
    end;

    local procedure CreateCompanySkill(Title: Text[250]; Description: Text[2048]; SkillText: Text): BigInteger
    var
        BusinessSkillBuilder: Codeunit "Business Skill Builder";
    begin
        exit(
            BusinessSkillBuilder.Initialize(Title, SkillText)
                .SetDescription(Description)
                .SetActive(true)
                .AddCompany(TargetCompanyNameTok)
                .Create());
    end;

    local procedure GetLineClassificationSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to invoices from vendor 40000.');
        Instructions.AppendLine('Replacement parts and materials used for repairs or maintenance map to G/L account 8135 - Repair Materials, General Product Posting Group MISC, and VAT Product Posting Group GB20-GOODS.');
        Instructions.AppendLine('Office paper and other office consumables map to G/L account 8215 - Office Consumables, General Product Posting Group MISC, and VAT Product Posting Group GB20-GOODS.');
        Instructions.AppendLine('Maintenance labour or technician work without separately supplied materials maps to G/L account 8140 - Maintenance Labour, General Product Posting Group SERVICES, and VAT Product Posting Group GB20-SERV.');
        Instructions.AppendLine('Classify every line from the nature of the purchase, not merely from the VAT percentage.');
        Instructions.AppendLine('Keep separately priced categories on separate lines.');
        Instructions.AppendLine('If one charge combines categories without a price breakdown, request clarification.');
        Instructions.AppendLine('Use VAT Business Posting Group DOMESTIC.');
        Instructions.Append('If the supplier VAT differs from the valid configured calculation, request review instead of changing VAT setup.');
        exit(Instructions.ToText());
    end;

    local procedure GetElectricityMeterSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to electricity invoices from vendor GB-ELEC.');
        Instructions.AppendLine('Use G/L account 8125 - Metered Electricity and VAT Product Posting Group GB20-UTIL.');
        Instructions.AppendLine('Read the meter number on every line.');
        Instructions.AppendLine('Meter E26A001947 maps to DEPARTMENT = PROD.');
        Instructions.AppendLine('Meter E26A001948 maps to DEPARTMENT = ADM.');
        Instructions.AppendLine('Keep different meters on separate lines.');
        Instructions.AppendLine('Do not apply one meter''s department to the entire invoice or infer it from vendor history.');
        Instructions.AppendLine('If a meter is missing or unknown, request its department mapping instead of guessing.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC.');
        exit(Instructions.ToText());
    end;

    local procedure GetServiceClassificationSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to invoices from vendor 20000.');
        Instructions.AppendLine('Bookkeeping, preparation of accounts, or accounting assistance maps to G/L account 8630 - Legal and Accounting Services, DEPARTMENT = ADM, and VAT Product Posting Group GB20-SERV.');
        Instructions.AppendLine('Employee training or learning workshops map to G/L account 8650 - Training Costs, VAT Product Posting Group GB20-SERV, and the beneficiary department stated on the invoice line.');
        Instructions.AppendLine('Generic "Consulting services" without a purpose requires clarification before selecting an account or department.');
        Instructions.AppendLine('Training without a beneficiary department requires clarification.');
        Instructions.AppendLine('Do not automatically assume SALES and do not use vendor history or another line to fill missing information.');
        Instructions.AppendLine('Apply the rule separately to each line.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC.');
        exit(Instructions.ToText());
    end;

    local procedure GetEffectiveDateSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to monthly bookkeeping and accounting assistance from vendor 20000.');
        Instructions.AppendLine('Use G/L account 8630 - Legal and Accounting Services and VAT Product Posting Group GB20-SERV.');
        Instructions.AppendLine('Read the service period from the invoice line description.');
        Instructions.AppendLine('Periods entirely before 1 October 2026 use DEPARTMENT = SALES.');
        Instructions.AppendLine('Periods starting on or after 1 October 2026 use DEPARTMENT = ADM.');
        Instructions.AppendLine('This rule overrides historical coding even when previous invoices for the same service used SALES.');
        Instructions.AppendLine('Do not use the invoice date.');
        Instructions.AppendLine('If the service period is missing or crosses the effective date ambiguously, request clarification.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC.');
        exit(Instructions.ToText());
    end;

    local procedure VerifyCleanupIsSafe(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyUpdatedVendorIsUnchanged(ConsultingVendorNoTok, ConsultingVendorVATRegistrationNoTok);
        VerifyUpdatedVendorIsUnchanged(SuppliesVendorNoTok, SuppliesVendorVATRegistrationNoTok);
        VerifyElectricityVendorIsUnchangedAndUnused();
        VerifyExistingAccountVATDefault(ElectricityAccountNoTok, GenericVATProductGroupTok);
        VerifyExistingAccountVATDefault(RepairMaintenanceAccountNoTok, GenericVATProductGroupTok);
        VerifyExistingAccountVATDefault(OfficeSuppliesAccountNoTok, GenericVATProductGroupTok);
        VerifyExistingAccountVATDefault(ConsultantServicesAccountNoTok, GenericVATProductGroupTok);
        VerifyExistingAccountVATDefault(AccountingServicesAccountNoTok, GenericVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(MeteredElectricityAccountNoTok, MeteredElectricityAccountNameLbl, MiscPostingGroupTok, UtilitiesVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(RepairMaterialsAccountNoTok, RepairMaterialsAccountNameLbl, MiscPostingGroupTok, GoodsVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, ServicesPostingGroupTok, ServicesVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(OfficeConsumablesAccountNoTok, OfficeConsumablesAccountNameLbl, MiscPostingGroupTok, GoodsVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, ServicesPostingGroupTok, ServicesVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(SalesVATAccountNoTok, SalesVATAccountNameLbl, '', '');
        VerifyGLAccountIsUnchangedAndUnused(PurchaseVATAccountNoTok, PurchaseVATAccountNameLbl, '', '');
        VerifyVATSetupIsUnchangedAndUnused(DemoState);
        VerifyDefaultDimensionsAreUnchanged();
        VerifyTextToAccountMappingsAreUnchanged(DemoState);
        VerifyHistoryInvoices(DemoState);
        VerifyCostTypeIsUnchangedAndUnused(MeteredElectricityAccountNoTok, MeteredElectricityAccountNameLbl, DemoState."Electricity Cost Type Created");
        VerifyCostTypeIsUnchangedAndUnused(RepairMaterialsAccountNoTok, RepairMaterialsAccountNameLbl, DemoState."Repair Mat. Cost Type Created");
        VerifyCostTypeIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, DemoState."Maintenance Cost Type Created");
        VerifyCostTypeIsUnchangedAndUnused(OfficeConsumablesAccountNoTok, OfficeConsumablesAccountNameLbl, DemoState."Office Cons. Cost Type Created");
        VerifyCostTypeIsUnchangedAndUnused(TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, DemoState."Training Cost Type Created");
        VerifySkillIsUnchanged(DemoState."Line Classification Skill ID", LineClassificationSkillTitleLbl, GetLineClassificationSkillText());
        VerifySkillIsUnchanged(DemoState."Electricity Meter Skill ID", ElectricityMeterSkillTitleLbl, GetElectricityMeterSkillText());
        VerifySkillIsUnchanged(DemoState."Service Class. Skill ID", ServiceClassificationSkillTitleLbl, GetServiceClassificationSkillText());
        VerifySkillIsUnchanged(DemoState."Effective Date Skill ID", EffectiveDateSkillTitleLbl, GetEffectiveDateSkillText());
    end;

    local procedure VerifyUpdatedVendorIsUnchanged(VendorNo: Code[20]; ExpectedVATRegistrationNo: Text[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        if (Vendor."VAT Registration No." <> ExpectedVATRegistrationNo) or
           (Vendor."Payment Terms Code" <> ThirtyDaysPaymentTermsTok)
        then
            Error(RecordChangedAfterSetupErr, Vendor.TableCaption(), VendorNo);
    end;

    local procedure VerifyElectricityVendorIsUnchangedAndUnused()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Vendor.Get(ElectricityVendorNoTok);
        if (Vendor.Name <> ElectricityVendorNameLbl) or
           (Vendor.Address <> ElectricityVendorAddressLbl) or
           (Vendor.City <> 'Birmingham') or
           (Vendor."Post Code" <> 'B1 1AA') or
           (Vendor."Country/Region Code" <> 'GB') or
           (Vendor."VAT Registration No." <> ElectricityVendorVATRegistrationNoTok) or
           (Vendor."Payment Terms Code" <> ThirtyDaysPaymentTermsTok) or
           (Vendor."Gen. Bus. Posting Group" <> DomesticPostingGroupTok) or
           (Vendor."VAT Bus. Posting Group" <> DomesticPostingGroupTok) or
           (Vendor."Vendor Posting Group" <> DomesticPostingGroupTok)
        then
            Error(RecordChangedAfterSetupErr, Vendor.TableCaption(), ElectricityVendorNoTok);

        PurchaseHeader.SetRange("Buy-from Vendor No.", ElectricityVendorNoTok);
        if not PurchaseHeader.IsEmpty() then
            Error(DemoRecordInUseErr, Vendor.TableCaption(), ElectricityVendorNoTok);
        VendorLedgerEntry.SetRange("Vendor No.", ElectricityVendorNoTok);
        if not VendorLedgerEntry.IsEmpty() then
            Error(DemoRecordInUseErr, Vendor.TableCaption(), ElectricityVendorNoTok);
    end;

    local procedure VerifyExistingAccountVATDefault(GLAccountNo: Code[20]; ExpectedVATProductPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        if GLAccount."VAT Prod. Posting Group" <> ExpectedVATProductPostingGroup then
            Error(RecordChangedAfterSetupErr, GLAccount.TableCaption(), GLAccountNo);
    end;

    local procedure VerifyGLAccountIsUnchangedAndUnused(GLAccountNo: Code[20]; ExpectedName: Text[100]; ExpectedGenProductPostingGroup: Code[20]; ExpectedVATProductPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        GLAccount.Get(GLAccountNo);
        if (GLAccount.Name <> ExpectedName) or
           (GLAccount."Gen. Prod. Posting Group" <> ExpectedGenProductPostingGroup) or
           (GLAccount."VAT Prod. Posting Group" <> ExpectedVATProductPostingGroup)
        then
            Error(RecordChangedAfterSetupErr, GLAccount.TableCaption(), GLAccountNo);

        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if not GLEntry.IsEmpty() then
            Error(DemoRecordInUseErr, GLAccount.TableCaption(), GLAccountNo);
        GLBudgetEntry.SetRange("G/L Account No.", GLAccountNo);
        if not GLBudgetEntry.IsEmpty() then
            Error(DemoRecordInUseErr, GLAccount.TableCaption(), GLAccountNo);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccountNo);
        if not GenJournalLine.IsEmpty() then
            Error(DemoRecordInUseErr, GLAccount.TableCaption(), GLAccountNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.SetRange("No.", GLAccountNo);
        if not PurchaseLine.IsEmpty() then
            Error(DemoRecordInUseErr, GLAccount.TableCaption(), GLAccountNo);
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", GLAccountNo);
        if not SalesLine.IsEmpty() then
            Error(DemoRecordInUseErr, GLAccount.TableCaption(), GLAccountNo);
    end;

    local procedure VerifyVATSetupIsUnchangedAndUnused(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyVATProductPostingGroup(GenericVATProductGroupTok, GenericVATDescriptionLbl);
        VerifyVATProductPostingGroup(GoodsVATProductGroupTok, GoodsVATDescriptionLbl);
        VerifyVATProductPostingGroup(ServicesVATProductGroupTok, ServicesVATDescriptionLbl);
        VerifyVATProductPostingGroup(UtilitiesVATProductGroupTok, UtilitiesVATDescriptionLbl);
        VerifyVATPostingSetup(GenericVATProductGroupTok);
        VerifyVATPostingSetup(GoodsVATProductGroupTok);
        VerifyVATPostingSetup(ServicesVATProductGroupTok);
        VerifyVATPostingSetup(UtilitiesVATProductGroupTok);
        VerifyVATProductPostingGroupUnused(GenericVATProductGroupTok, DemoState);
        VerifyVATProductPostingGroupUnused(GoodsVATProductGroupTok, DemoState);
        VerifyVATProductPostingGroupUnused(ServicesVATProductGroupTok, DemoState);
        VerifyVATProductPostingGroupUnused(UtilitiesVATProductGroupTok, DemoState);
        VerifyVATProductPostingGroupAccountUsage(GenericVATProductGroupTok, 5);
        VerifyVATProductPostingGroupAccountUsage(GoodsVATProductGroupTok, 2);
        VerifyVATProductPostingGroupAccountUsage(ServicesVATProductGroupTok, 2);
        VerifyVATProductPostingGroupAccountUsage(UtilitiesVATProductGroupTok, 1);
    end;

    local procedure VerifyVATProductPostingGroup(GroupCode: Code[20]; ExpectedDescription: Text[100])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Get(GroupCode);
        if VATProductPostingGroup.Description <> ExpectedDescription then
            Error(RecordChangedAfterSetupErr, VATProductPostingGroup.TableCaption(), GroupCode);
    end;

    local procedure VerifyVATPostingSetup(VATProductPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(DomesticPostingGroupTok, VATProductPostingGroupCode);
        if (VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Normal VAT") or
           (VATPostingSetup."VAT %" <> 20) or
           (VATPostingSetup."VAT Identifier" <> VATProductPostingGroupCode) or
           (VATPostingSetup."Sales VAT Account" <> SalesVATAccountNoTok) or
           (VATPostingSetup."Purchase VAT Account" <> PurchaseVATAccountNoTok)
        then
            Error(RecordChangedAfterSetupErr, VATPostingSetup.TableCaption(), StrSubstNo('%1/%2', DomesticPostingGroupTok, VATProductPostingGroupCode));
    end;

    local procedure VerifyVATProductPostingGroupUnused(VATProductPostingGroupCode: Code[20]; DemoState: Record "PA BC IQ Demo State")
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        PurchaseLine.SetRange("VAT Prod. Posting Group", VATProductPostingGroupCode);
        ExcludeHistoryDocuments(PurchaseLine, DemoState);
        if not PurchaseLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), VATProductPostingGroupCode);
        SalesLine.SetRange("VAT Prod. Posting Group", VATProductPostingGroupCode);
        if not SalesLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), VATProductPostingGroupCode);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProductPostingGroupCode);
        if not VATEntry.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), VATProductPostingGroupCode);
    end;

    local procedure ExcludeHistoryDocuments(var PurchaseLine: Record "Purchase Line"; DemoState: Record "PA BC IQ Demo State")
    begin
        PurchaseLine.SetFilter(
            "Document No.",
            '<>%1&<>%2&<>%3&<>%4',
            DemoState."June History Document No.",
            DemoState."July History Document No.",
            DemoState."August History Document No.",
            DemoState."September History Document No.");
    end;

    local procedure VerifyVATProductPostingGroupAccountUsage(VATProductPostingGroupCode: Code[20]; ExpectedAccountCount: Integer)
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        GLAccount.SetRange("VAT Prod. Posting Group", VATProductPostingGroupCode);
        if GLAccount.Count() <> ExpectedAccountCount then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), VATProductPostingGroupCode);
    end;

    local procedure VerifyDefaultDimensionsAreUnchanged()
    begin
        VerifyVendorDepartmentDefault(ConsultingVendorNoTok, SalesDepartmentTok);
        VerifyVendorDepartmentDefault(ElectricityVendorNoTok, AdministrationDepartmentTok);
    end;

    local procedure VerifyVendorDepartmentDefault(VendorNo: Code[20]; ExpectedDepartment: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(Database::Vendor, VendorNo, DepartmentDimensionTok);
        if (DefaultDimension."Dimension Value Code" <> ExpectedDepartment) or
           (DefaultDimension."Value Posting" <> DefaultDimension."Value Posting"::" ")
        then
            Error(RecordChangedAfterSetupErr, DefaultDimension.TableCaption(), StrSubstNo('%1/%2', VendorNo, DepartmentDimensionTok));
    end;

    local procedure VerifyTextToAccountMappingsAreUnchanged(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyTextToAccountMapping(DemoState."Repair Material Mapping Line", SuppliesVendorNoTok, RepairMaterialsMappingTextLbl, RepairMaintenanceAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Office Consum. Mapping Line", SuppliesVendorNoTok, OfficeConsumablesMappingTextLbl, OfficeSuppliesAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Maintenance Mapping Line", SuppliesVendorNoTok, MaintenanceLabourMappingTextLbl, RepairMaintenanceAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Electricity Mapping Line", ElectricityVendorNoTok, ElectricityMappingTextLbl, ElectricityAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Accounting Mapping Line", ConsultingVendorNoTok, AccountingMappingTextLbl, ConsultantServicesAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Training Mapping Line", ConsultingVendorNoTok, TrainingMappingTextLbl, ConsultantServicesAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Consulting Mapping Line", ConsultingVendorNoTok, ConsultingMappingTextLbl, ConsultantServicesAccountNoTok);
        VerifyTextToAccountMapping(DemoState."Monthly Books Mapping Line", ConsultingVendorNoTok, MonthlyBookkeepingMappingTextLbl, AccountingServicesAccountNoTok);
    end;

    local procedure VerifyTextToAccountMapping(LineNo: Integer; ExpectedVendorNo: Code[20]; ExpectedMappingText: Text[250]; ExpectedDebitAccountNo: Code[20])
    var
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccountMapping.Get(LineNo);
        if (TextToAccountMapping."Vendor No." <> ExpectedVendorNo) or
           (TextToAccountMapping."Mapping Text" <> ExpectedMappingText) or
           (TextToAccountMapping."Debit Acc. No." <> ExpectedDebitAccountNo) or
           (TextToAccountMapping."Credit Acc. No." <> '')
        then
            Error(RecordChangedAfterSetupErr, TextToAccountMapping.TableCaption(), Format(LineNo));
    end;

    local procedure VerifyHistoryInvoices(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyHistoryInvoice(DemoState."June History System ID", JuneVendorInvoiceNoTok, DMY2Date(30, 6, 2026), JuneServiceDescriptionLbl);
        VerifyHistoryInvoice(DemoState."July History System ID", JulyVendorInvoiceNoTok, DMY2Date(31, 7, 2026), JulyServiceDescriptionLbl);
        VerifyHistoryInvoice(DemoState."August History System ID", AugustVendorInvoiceNoTok, DMY2Date(31, 8, 2026), AugustServiceDescriptionLbl);
        VerifyHistoryInvoice(DemoState."September History System ID", SeptemberVendorInvoiceNoTok, DMY2Date(30, 9, 2026), SeptemberServiceDescriptionLbl);
    end;

    local procedure VerifyHistoryInvoice(SystemId: Guid; ExpectedVendorInvoiceNo: Code[35]; ExpectedPostingDate: Date; ExpectedDescription: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if not PurchaseHeader.GetBySystemId(SystemId) then begin
            PurchInvHeader.SetRange("Buy-from Vendor No.", ConsultingVendorNoTok);
            PurchInvHeader.SetRange("Vendor Invoice No.", ExpectedVendorInvoiceNo);
            if not PurchInvHeader.IsEmpty() then
                Error(HistoryInvoicePostedErr, ExpectedVendorInvoiceNo);
            exit;
        end;

        if (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Invoice) or
           (PurchaseHeader."Buy-from Vendor No." <> ConsultingVendorNoTok) or
           (PurchaseHeader."Vendor Invoice No." <> ExpectedVendorInvoiceNo) or
           (PurchaseHeader."Posting Date" <> ExpectedPostingDate)
        then
            Error(RecordChangedAfterSetupErr, PurchaseHeader.TableCaption(), PurchaseHeader."No.");

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.Count() <> 1 then
            Error(RecordChangedAfterSetupErr, PurchaseHeader.TableCaption(), PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        if (PurchaseLine.Type <> PurchaseLine.Type::"G/L Account") or
           (PurchaseLine."No." <> AccountingServicesAccountNoTok) or
           (PurchaseLine.Description <> ExpectedDescription) or
           (PurchaseLine.Quantity <> 1) or
           (PurchaseLine."Direct Unit Cost" <> 1500) or
           (PurchaseLine."VAT Prod. Posting Group" <> GenericVATProductGroupTok) or
           (PurchaseLine."Shortcut Dimension 1 Code" <> SalesDepartmentTok)
        then
            Error(RecordChangedAfterSetupErr, PurchaseHeader.TableCaption(), PurchaseHeader."No.");
    end;

    local procedure VerifyCostTypeIsUnchangedAndUnused(CostTypeNo: Code[20]; ExpectedName: Text[100]; WasCreated: Boolean)
    var
        CostEntry: Record "Cost Entry";
        CostType: Record "Cost Type";
    begin
        if not WasCreated then
            exit;

        CostType.Get(CostTypeNo);
        if (CostType.Name <> ExpectedName) or (CostType."G/L Account Range" <> CostTypeNo) then
            Error(RecordChangedAfterSetupErr, CostType.TableCaption(), CostTypeNo);
        CostEntry.SetRange("Cost Type No.", CostTypeNo);
        if not CostEntry.IsEmpty() then
            Error(DemoRecordInUseErr, CostType.TableCaption(), CostTypeNo);
    end;

    local procedure VerifySkillIsUnchanged(SkillId: BigInteger; ExpectedTitle: Text[250]; ExpectedText: Text)
    var
        BusinessSkillLifecycle: Codeunit "Business Skill Lifecycle";
    begin
        BusinessSkillLifecycle.VerifyCompanySkill(SkillId, ExpectedTitle, ExpectedText, TargetCompanyNameTok);
    end;

    local procedure DeleteHistoryInvoices(DemoState: Record "PA BC IQ Demo State")
    begin
        DeleteHistoryInvoice(DemoState."June History System ID");
        DeleteHistoryInvoice(DemoState."July History System ID");
        DeleteHistoryInvoice(DemoState."August History System ID");
        DeleteHistoryInvoice(DemoState."September History System ID");
    end;

    local procedure DeleteHistoryInvoice(SystemId: Guid)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseHeader.GetBySystemId(SystemId) then
            PurchaseHeader.Delete(true);
    end;

    local procedure DeleteBusinessSkills(DemoState: Record "PA BC IQ Demo State")
    begin
        DeleteBusinessSkill(DemoState."Line Classification Skill ID", LineClassificationSkillTitleLbl, GetLineClassificationSkillText());
        DeleteBusinessSkill(DemoState."Electricity Meter Skill ID", ElectricityMeterSkillTitleLbl, GetElectricityMeterSkillText());
        DeleteBusinessSkill(DemoState."Service Class. Skill ID", ServiceClassificationSkillTitleLbl, GetServiceClassificationSkillText());
        DeleteBusinessSkill(DemoState."Effective Date Skill ID", EffectiveDateSkillTitleLbl, GetEffectiveDateSkillText());
    end;

    local procedure DeleteBusinessSkill(SkillId: BigInteger; ExpectedTitle: Text[250]; ExpectedText: Text)
    var
        BusinessSkillLifecycle: Codeunit "Business Skill Lifecycle";
    begin
        BusinessSkillLifecycle.DeleteCompanySkill(SkillId, ExpectedTitle, ExpectedText, TargetCompanyNameTok);
    end;

    local procedure DeleteTextToAccountMappings(DemoState: Record "PA BC IQ Demo State")
    begin
        DeleteTextToAccountMapping(DemoState."Repair Material Mapping Line");
        DeleteTextToAccountMapping(DemoState."Office Consum. Mapping Line");
        DeleteTextToAccountMapping(DemoState."Maintenance Mapping Line");
        DeleteTextToAccountMapping(DemoState."Electricity Mapping Line");
        DeleteTextToAccountMapping(DemoState."Accounting Mapping Line");
        DeleteTextToAccountMapping(DemoState."Training Mapping Line");
        DeleteTextToAccountMapping(DemoState."Consulting Mapping Line");
        DeleteTextToAccountMapping(DemoState."Monthly Books Mapping Line");
    end;

    local procedure DeleteTextToAccountMapping(LineNo: Integer)
    var
        TextToAccountMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccountMapping.Get(LineNo);
        TextToAccountMapping.Delete(true);
    end;

    local procedure DeleteDefaultDimensions(DemoState: Record "PA BC IQ Demo State")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(Database::Vendor, ElectricityVendorNoTok, DepartmentDimensionTok);
        DefaultDimension.Delete(true);

        if DemoState."Vendor 20000 Dept. Existed" then begin
            DefaultDimension.Get(Database::Vendor, ConsultingVendorNoTok, DepartmentDimensionTok);
            DefaultDimension.Validate("Dimension Value Code", DemoState."Vendor 20000 Dept. Value");
            DefaultDimension.Validate("Value Posting", DemoState."Vendor 20000 Dept. Posting");
            DefaultDimension.Modify(true);
        end else
            if DefaultDimension.Get(Database::Vendor, ConsultingVendorNoTok, DepartmentDimensionTok) then
                DefaultDimension.Delete(true);
    end;

    local procedure DeleteVATPostingSetups()
    begin
        DeleteVATPostingSetup(UtilitiesVATProductGroupTok);
        DeleteVATPostingSetup(ServicesVATProductGroupTok);
        DeleteVATPostingSetup(GoodsVATProductGroupTok);
        DeleteVATPostingSetup(GenericVATProductGroupTok);
    end;

    local procedure DeleteVATPostingSetup(VATProductPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(DomesticPostingGroupTok, VATProductPostingGroupCode);
        VATPostingSetup.Delete(true);
    end;

    local procedure DeleteDemoExpenseAccount(GLAccountNo: Code[20]; CostTypeWasCreated: Boolean)
    begin
        DeleteDemoGLAccount(GLAccountNo);
        DeleteDemoCostType(GLAccountNo, CostTypeWasCreated);
    end;

    local procedure DeleteDemoGLAccount(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Delete(false);
    end;

    local procedure DeleteDemoCostType(CostTypeNo: Code[20]; WasCreated: Boolean)
    var
        CostType: Record "Cost Type";
    begin
        if not WasCreated then
            exit;
        CostType.Get(CostTypeNo);
        CostType.Delete(true);
    end;

    local procedure DeleteElectricityVendor()
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(ElectricityVendorNoTok);
        Vendor.Delete(true);
    end;

    local procedure RestoreExistingAccountVATDefaults(DemoState: Record "PA BC IQ Demo State")
    begin
        UpdateAccountVATProductPostingGroup(ElectricityAccountNoTok, DemoState."Account 8120 VAT Prod. Group");
        UpdateAccountVATProductPostingGroup(RepairMaintenanceAccountNoTok, DemoState."Account 8130 VAT Prod. Group");
        UpdateAccountVATProductPostingGroup(OfficeSuppliesAccountNoTok, DemoState."Account 8210 VAT Prod. Group");
        UpdateAccountVATProductPostingGroup(ConsultantServicesAccountNoTok, DemoState."Account 8320 VAT Prod. Group");
        UpdateAccountVATProductPostingGroup(AccountingServicesAccountNoTok, DemoState."Account 8630 VAT Prod. Group");
    end;

    local procedure DeleteVATProductPostingGroups()
    begin
        DeleteVATProductPostingGroup(UtilitiesVATProductGroupTok);
        DeleteVATProductPostingGroup(ServicesVATProductGroupTok);
        DeleteVATProductPostingGroup(GoodsVATProductGroupTok);
        DeleteVATProductPostingGroup(GenericVATProductGroupTok);
    end;

    local procedure DeleteVATProductPostingGroup(VATProductPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Get(VATProductPostingGroupCode);
        VATProductPostingGroup.Delete(true);
    end;

    local procedure RestoreExistingVendors(DemoState: Record "PA BC IQ Demo State")
    begin
        RestoreExistingVendor(
            ConsultingVendorNoTok,
            DemoState."Vendor 20000 VAT Reg. No.",
            DemoState."Vendor 20000 Payment Terms");
        RestoreExistingVendor(
            SuppliesVendorNoTok,
            DemoState."Vendor 40000 VAT Reg. No.",
            DemoState."Vendor 40000 Payment Terms");
    end;

    local procedure RestoreExistingVendor(VendorNo: Code[20]; VATRegistrationNo: Text[20]; PaymentTermsCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure IsConfigurationIntact(): Boolean
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        Vendor: Record Vendor;
    begin
        exit(
            Vendor.Get(ElectricityVendorNoTok) and
            GLAccount.Get(MeteredElectricityAccountNoTok) and
            GLAccount.Get(RepairMaterialsAccountNoTok) and
            GLAccount.Get(MaintenanceLabourAccountNoTok) and
            GLAccount.Get(OfficeConsumablesAccountNoTok) and
            GLAccount.Get(TrainingCostsAccountNoTok) and
            VATProductPostingGroup.Get(GenericVATProductGroupTok) and
            VATProductPostingGroup.Get(GoodsVATProductGroupTok) and
            VATProductPostingGroup.Get(ServicesVATProductGroupTok) and
            VATProductPostingGroup.Get(UtilitiesVATProductGroupTok) and
            VATPostingSetup.Get(DomesticPostingGroupTok, GenericVATProductGroupTok) and
            VATPostingSetup.Get(DomesticPostingGroupTok, GoodsVATProductGroupTok) and
            VATPostingSetup.Get(DomesticPostingGroupTok, ServicesVATProductGroupTok) and
            VATPostingSetup.Get(DomesticPostingGroupTok, UtilitiesVATProductGroupTok));
    end;

    local procedure CleanupLegacyCompany(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyLegacyCleanupIsSafe(DemoState);
        DeleteLegacyBusinessSkills(DemoState);
        DeleteVATPostingSetup(GenericVATProductGroupTok);
        DeleteDemoGLAccount(MaintenanceLabourAccountNoTok);
        DeleteDemoCostType(MaintenanceLabourAccountNoTok, DemoState."Maintenance Cost Type Created");
        DeleteDemoGLAccount(TrainingCostsAccountNoTok);
        DeleteDemoCostType(TrainingCostsAccountNoTok, DemoState."Training Cost Type Created");
        DeleteElectricityVendor();
        DeleteDemoGLAccount(SalesVATAccountNoTok);
        DeleteDemoGLAccount(PurchaseVATAccountNoTok);
        DeleteVATProductPostingGroup(GenericVATProductGroupTok);
        RestoreExistingVendors(DemoState);
        DemoState.Delete(true);
    end;

    local procedure VerifyLegacyCleanupIsSafe(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyUpdatedVendorIsUnchanged(ConsultingVendorNoTok, ConsultingVendorVATRegistrationNoTok);
        VerifyUpdatedVendorIsUnchanged(SuppliesVendorNoTok, SuppliesVendorVATRegistrationNoTok);
        VerifyElectricityVendorIsUnchangedAndUnused();
        VerifyGLAccountIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, ServicesPostingGroupTok, GenericVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, ServicesPostingGroupTok, GenericVATProductGroupTok);
        VerifyGLAccountIsUnchangedAndUnused(SalesVATAccountNoTok, SalesVATAccountNameLbl, '', '');
        VerifyGLAccountIsUnchangedAndUnused(PurchaseVATAccountNoTok, PurchaseVATAccountNameLbl, '', '');
        VerifyLegacyVATSetupIsUnchangedAndUnused();
        VerifyCostTypeIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, DemoState."Maintenance Cost Type Created");
        VerifyCostTypeIsUnchangedAndUnused(TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, DemoState."Training Cost Type Created");
        VerifySkillIsUnchanged(DemoState."Line Classification Skill ID", LineClassificationSkillTitleLbl, GetLegacyLineClassificationSkillText());
        VerifySkillIsUnchanged(DemoState."Electricity Meter Skill ID", ElectricityMeterSkillTitleLbl, GetLegacyElectricityMeterSkillText());
        VerifySkillIsUnchanged(DemoState."Service Class. Skill ID", ServiceClassificationSkillTitleLbl, GetLegacyServiceClassificationSkillText());
        VerifySkillIsUnchanged(DemoState."Effective Date Skill ID", EffectiveDateSkillTitleLbl, GetLegacyEffectiveDateSkillText());
    end;

    local procedure VerifyLegacyVATSetupIsUnchangedAndUnused()
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VerifyVATProductPostingGroup(GenericVATProductGroupTok, GenericVATDescriptionLbl);
        VerifyVATPostingSetup(GenericVATProductGroupTok);
        PurchaseLine.SetRange("VAT Prod. Posting Group", GenericVATProductGroupTok);
        if not PurchaseLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GenericVATProductGroupTok);
        SalesLine.SetRange("VAT Prod. Posting Group", GenericVATProductGroupTok);
        if not SalesLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GenericVATProductGroupTok);
        VATEntry.SetRange("VAT Prod. Posting Group", GenericVATProductGroupTok);
        if not VATEntry.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GenericVATProductGroupTok);
        GLAccount.SetRange("VAT Prod. Posting Group", GenericVATProductGroupTok);
        if GLAccount.Count() <> 2 then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GenericVATProductGroupTok);
    end;

    local procedure DeleteLegacyBusinessSkills(DemoState: Record "PA BC IQ Demo State")
    begin
        DeleteBusinessSkill(DemoState."Line Classification Skill ID", LineClassificationSkillTitleLbl, GetLegacyLineClassificationSkillText());
        DeleteBusinessSkill(DemoState."Electricity Meter Skill ID", ElectricityMeterSkillTitleLbl, GetLegacyElectricityMeterSkillText());
        DeleteBusinessSkill(DemoState."Service Class. Skill ID", ServiceClassificationSkillTitleLbl, GetLegacyServiceClassificationSkillText());
        DeleteBusinessSkill(DemoState."Effective Date Skill ID", EffectiveDateSkillTitleLbl, GetLegacyEffectiveDateSkillText());
    end;

    local procedure GetLegacyLineClassificationSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to invoices from vendor 40000.');
        Instructions.AppendLine('Replacement parts and materials used for repairs or maintenance map to G/L account 8130 - Repairs and Maintenance and General Product Posting Group MISC.');
        Instructions.AppendLine('Office paper and other office consumables map to G/L account 8210 - Office Supplies and General Product Posting Group MISC.');
        Instructions.AppendLine('Maintenance labour or technician work without separately supplied materials maps to G/L account 8140 - Maintenance Labour and General Product Posting Group SERVICES.');
        Instructions.AppendLine('Classify every line from the nature of the purchase, not merely from the VAT percentage.');
        Instructions.AppendLine('Keep separately priced categories on separate lines.');
        Instructions.AppendLine('If one charge combines categories without a price breakdown, request clarification.');
        Instructions.AppendLine('Use VAT Business Posting Group DOMESTIC and VAT Product Posting Group GB20.');
        Instructions.Append('If the supplier VAT differs from the valid configured calculation, request review instead of changing VAT setup.');
        exit(Instructions.ToText());
    end;

    local procedure GetLegacyElectricityMeterSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to electricity invoices from vendor GB-ELEC.');
        Instructions.AppendLine('Use G/L account 8120 - Electricity and Heating.');
        Instructions.AppendLine('Read the meter number on every line.');
        Instructions.AppendLine('Meter E26A001947 maps to DEPARTMENT = PROD.');
        Instructions.AppendLine('Meter E26A001948 maps to DEPARTMENT = ADM.');
        Instructions.AppendLine('Keep different meters on separate lines.');
        Instructions.AppendLine('Do not apply one meter''s department to the entire invoice or infer it from vendor history.');
        Instructions.AppendLine('If a meter is missing or unknown, request its department mapping instead of guessing.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC and VAT Product Posting Group GB20.');
        exit(Instructions.ToText());
    end;

    local procedure GetLegacyServiceClassificationSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to invoices from vendor 20000.');
        Instructions.AppendLine('Bookkeeping, preparation of accounts, or accounting assistance maps to G/L account 8630 - Legal and Accounting Services and DEPARTMENT = ADM.');
        Instructions.AppendLine('Employee training or learning workshops map to G/L account 8650 - Training Costs and the beneficiary department stated on the invoice line.');
        Instructions.AppendLine('Generic "Consulting services" without a purpose requires clarification before selecting an account or department.');
        Instructions.AppendLine('Training without a beneficiary department requires clarification.');
        Instructions.AppendLine('Do not automatically assume SALES and do not use vendor history or another line to fill missing information.');
        Instructions.AppendLine('Apply the rule separately to each line.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC and VAT Product Posting Group GB20.');
        exit(Instructions.ToText());
    end;

    local procedure GetLegacyEffectiveDateSkillText(): Text
    var
        Instructions: TextBuilder;
    begin
        Instructions.AppendLine('Apply only in CRONUS W1 to monthly bookkeeping and accounting assistance from vendor 20000.');
        Instructions.AppendLine('Use G/L account 8630 - Legal and Accounting Services.');
        Instructions.AppendLine('Read the service period from the invoice line description.');
        Instructions.AppendLine('Periods entirely before 1 October 2026 use DEPARTMENT = SALES.');
        Instructions.AppendLine('Periods starting on or after 1 October 2026 use DEPARTMENT = ADM.');
        Instructions.AppendLine('This rule overrides historical coding even when previous invoices for the same service used SALES.');
        Instructions.AppendLine('Do not use the invoice date.');
        Instructions.AppendLine('If the service period is missing or crosses the effective date ambiguously, request clarification.');
        Instructions.Append('Use VAT Business Posting Group DOMESTIC and VAT Product Posting Group GB20.');
        exit(Instructions.ToText());
    end;

    var
        StatePrimaryKeyTok: Label 'SETUP', Locked = true;
        TargetCompanyNameTok: Label 'CRONUS W1', Locked = true;
        ConsultingVendorNoTok: Label '20000', Locked = true;
        SuppliesVendorNoTok: Label '40000', Locked = true;
        ElectricityVendorNoTok: Label 'GB-ELEC', Locked = true;
        ElectricityAccountNoTok: Label '8120', Locked = true;
        MeteredElectricityAccountNoTok: Label '8125', Locked = true;
        RepairMaintenanceAccountNoTok: Label '8130', Locked = true;
        RepairMaterialsAccountNoTok: Label '8135', Locked = true;
        MaintenanceLabourAccountNoTok: Label '8140', Locked = true;
        OfficeSuppliesAccountNoTok: Label '8210', Locked = true;
        OfficeConsumablesAccountNoTok: Label '8215', Locked = true;
        ConsultantServicesAccountNoTok: Label '8320', Locked = true;
        AccountingServicesAccountNoTok: Label '8630', Locked = true;
        TrainingCostsAccountNoTok: Label '8650', Locked = true;
        SalesVATTemplateAccountNoTok: Label '5610', Locked = true;
        SalesVATAccountNoTok: Label '5612', Locked = true;
        PurchaseVATTemplateAccountNoTok: Label '5630', Locked = true;
        PurchaseVATAccountNoTok: Label '5632', Locked = true;
        DomesticPostingGroupTok: Label 'DOMESTIC', Locked = true;
        MiscPostingGroupTok: Label 'MISC', Locked = true;
        ServicesPostingGroupTok: Label 'SERVICES', Locked = true;
        GenericVATProductGroupTok: Label 'GB20', Locked = true;
        GoodsVATProductGroupTok: Label 'GB20-GOODS', Locked = true;
        ServicesVATProductGroupTok: Label 'GB20-SERV', Locked = true;
        UtilitiesVATProductGroupTok: Label 'GB20-UTIL', Locked = true;
        ThirtyDaysPaymentTermsTok: Label '30 DAYS', Locked = true;
        DepartmentDimensionTok: Label 'DEPARTMENT', Locked = true;
        AdministrationDepartmentTok: Label 'ADM', Locked = true;
        ProductionDepartmentTok: Label 'PROD', Locked = true;
        SalesDepartmentTok: Label 'SALES', Locked = true;
        JuneVendorInvoiceNoTok: Label 'PA-HIST-2606', Locked = true;
        JulyVendorInvoiceNoTok: Label 'PA-HIST-2607', Locked = true;
        AugustVendorInvoiceNoTok: Label 'PA-HIST-2608', Locked = true;
        SeptemberVendorInvoiceNoTok: Label 'PA-HIST-2609', Locked = true;
        ConsultingVendorVATRegistrationNoTok: Label 'GB234 5678 47', Locked = true;
        SuppliesVendorVATRegistrationNoTok: Label 'GB123 4567 82', Locked = true;
        ElectricityVendorVATRegistrationNoTok: Label 'GB345 6789 12', Locked = true;
        ElectricityVendorNameLbl: Label 'Albion Business Energy Ltd';
        ElectricityVendorAddressLbl: Label '1 Energy Way';
        MeteredElectricityAccountNameLbl: Label 'Metered Electricity';
        RepairMaterialsAccountNameLbl: Label 'Repair Materials';
        MaintenanceLabourAccountNameLbl: Label 'Maintenance Labour';
        OfficeConsumablesAccountNameLbl: Label 'Office Consumables';
        TrainingCostsAccountNameLbl: Label 'Training Costs';
        SalesVATAccountNameLbl: Label 'Sales VAT 20%';
        PurchaseVATAccountNameLbl: Label 'Purchase VAT 20%';
        GenericVATDescriptionLbl: Label 'UK standard rate 20%';
        GoodsVATDescriptionLbl: Label 'UK standard-rated goods 20%';
        ServicesVATDescriptionLbl: Label 'UK standard-rated services 20%';
        UtilitiesVATDescriptionLbl: Label 'UK standard-rated utilities 20%';
        RepairMaterialsMappingTextLbl: Label 'Replacement parts and materials for repairs', Locked = true;
        OfficeConsumablesMappingTextLbl: Label 'A4 office paper and consumable supplies', Locked = true;
        MaintenanceLabourMappingTextLbl: Label 'Preventive maintenance technician labour', Locked = true;
        ElectricityMappingTextLbl: Label 'Electricity', Locked = true;
        AccountingMappingTextLbl: Label 'Bookkeeping and preparation of September 2026 accounts', Locked = true;
        TrainingMappingTextLbl: Label 'Employee training workshop', Locked = true;
        ConsultingMappingTextLbl: Label 'Consulting services', Locked = true;
        MonthlyBookkeepingMappingTextLbl: Label 'Monthly bookkeeping and accounting assistance', Locked = true;
        JuneServiceDescriptionLbl: Label 'Monthly bookkeeping and accounting assistance - 01/06/2026 to 30/06/2026';
        JulyServiceDescriptionLbl: Label 'Monthly bookkeeping and accounting assistance - 01/07/2026 to 31/07/2026';
        AugustServiceDescriptionLbl: Label 'Monthly bookkeeping and accounting assistance - 01/08/2026 to 31/08/2026';
        SeptemberServiceDescriptionLbl: Label 'Monthly bookkeeping and accounting assistance - 01/09/2026 to 30/09/2026';
        LineClassificationSkillTitleLbl: Label 'PA GB demo - line classification';
        LineClassificationSkillDescriptionLbl: Label 'Overrides broad expense defaults with company-specific repair, consumable, and labour classifications.';
        ElectricityMeterSkillTitleLbl: Label 'PA GB demo - electricity meter departments';
        ElectricityMeterSkillDescriptionLbl: Label 'Overrides centralized utility defaults using account, VAT, and department rules for each meter.';
        ServiceClassificationSkillTitleLbl: Label 'PA GB demo - professional services';
        ServiceClassificationSkillDescriptionLbl: Label 'Overrides generic consulting defaults with company-specific service accounts and beneficiary departments.';
        EffectiveDateSkillTitleLbl: Label 'PA GB demo - effective dated bookkeeping';
        EffectiveDateSkillDescriptionLbl: Label 'Overrides repeated historical SALES coding from 1 October 2026 using the service period.';
        AlreadyConfiguredErr: Label 'The BC IQ Payables Agent demo setup is already configured in this company.';
        NotConfiguredErr: Label 'The BC IQ Payables Agent demo setup is not configured in this company.';
        UpgradeRequiredErr: Label 'The previous BC IQ Payables Agent demo setup is configured. Choose Upgrade Company before using the expanded demo.';
        UnsupportedSetupVersionErr: Label 'Demo setup version %1 is not supported.', Comment = '%1 = setup version';
        WrongCompanyErr: Label 'Run this setup only in company %1. The current company is %2.', Comment = '%1 = required company, %2 = current company';
        RequiredRecordMissingErr: Label 'Required %1 %2 does not exist.', Comment = '%1 = record type, %2 = record key';
        ProposedRecordExistsErr: Label '%1 %2 already exists. Cleanup ownership cannot be guaranteed, so setup stopped without changing data.', Comment = '%1 = record type, %2 = record key';
        ProposedCombinationExistsErr: Label 'VAT Posting Setup %1/%2 already exists. Cleanup ownership cannot be guaranteed, so setup stopped without changing data.', Comment = '%1 = VAT business posting group, %2 = VAT product posting group';
        ProposedTextMappingExistsErr: Label 'Text-to-account mapping for vendor %1 and text "%2" already exists. Cleanup ownership cannot be guaranteed.', Comment = '%1 = vendor number, %2 = mapping text';
        ProposedHistoryInvoiceExistsErr: Label 'Purchase invoice history identifier %1 already exists. Cleanup ownership cannot be guaranteed.', Comment = '%1 = vendor invoice number';
        RequiredDimensionValueMissingErr: Label 'Required dimension value %1/%2 does not exist.', Comment = '%1 = dimension code, %2 = value code';
        RequiredDimensionValueBlockedErr: Label 'Required dimension value %1/%2 is blocked.', Comment = '%1 = dimension code, %2 = value code';
        RecordChangedAfterSetupErr: Label '%1 %2 was changed after demo setup. Cleanup stopped to preserve those changes.', Comment = '%1 = record type, %2 = record key';
        DemoRecordInUseErr: Label '%1 %2 is in use. Cleanup stopped and did not remove any demo setup.', Comment = '%1 = record type, %2 = record key';
        HistoryInvoicePostedErr: Label 'History invoice %1 was posted. Cleanup stopped and will not remove or reverse posted history.', Comment = '%1 = vendor invoice number';
        ConfiguredStatusLbl: Label 'Configured. Baseline mappings, four comparison skills, and four unposted history invoices are available.';
        IncompleteStatusLbl: Label 'The setup state exists, but one or more required demo records are missing. Do not run cleanup until the configuration is repaired.';
        UpgradeRequiredStatusLbl: Label 'The previous demo setup is configured. Choose Upgrade Company to replace it with the comparison setup.';
        NotConfiguredStatusLbl: Label 'Not configured. Choose Setup Company to create the GB comparison setup.';
        WrongCompanyStatusLbl: Label 'Current company: %1. Switch to %2 to use this page.', Comment = '%1 = current company, %2 = required company';
}
