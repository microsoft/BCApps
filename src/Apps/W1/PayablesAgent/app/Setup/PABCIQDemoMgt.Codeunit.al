// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

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
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

codeunit 3327 "PA BC IQ Demo Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Dimension Value" = r,
                  tabledata "Cost Entry" = r,
                  tabledata "Cost Type" = rimd,
                  tabledata "G/L Account" = rimd,
                  tabledata "G/L Budget Entry" = r,
                  tabledata "G/L Entry" = r,
                  tabledata "Gen. Business Posting Group" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Product Posting Group" = r,
                  tabledata "PA BC IQ Demo State" = rimd,
                  tabledata "Payment Terms" = r,
                  tabledata "Purchase Header" = r,
                  tabledata "Purchase Line" = r,
                  tabledata "Sales Line" = r,
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

        CreateVATProductPostingGroup();
        CreateDemoGLAccounts(DemoState);
        CreateVATPostingSetup();
        UpdateExistingVendors();
        CreateElectricityVendor();
        CreateBusinessSkills(DemoState);

        DemoState.Insert(true);
    end;

    procedure CleanupCompany()
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        VerifyTargetCompany();
        if not DemoState.Get(StatePrimaryKeyTok) then
            Error(NotConfiguredErr);

        VerifyCleanupIsSafe(DemoState);

        DeleteBusinessSkills(DemoState);
        DeleteVATPostingSetup();
        DeleteDemoGLAccount(MaintenanceLabourAccountNoTok);
        DeleteDemoCostType(MaintenanceLabourAccountNoTok, DemoState."Maintenance Cost Type Created");
        DeleteDemoGLAccount(TrainingCostsAccountNoTok);
        DeleteDemoCostType(TrainingCostsAccountNoTok, DemoState."Training Cost Type Created");
        DeleteElectricityVendor();
        DeleteDemoGLAccount(SalesVATAccountNoTok);
        DeleteDemoGLAccount(PurchaseVATAccountNoTok);
        DeleteVATProductPostingGroup();
        RestoreExistingVendors(DemoState);
        DemoState.Delete(true);
    end;

    procedure IsConfigured(): Boolean
    var
        DemoState: Record "PA BC IQ Demo State";
    begin
        exit(DemoState.Get(StatePrimaryKeyTok));
    end;

    procedure GetStatusText(): Text
    begin
        if CompanyName() <> TargetCompanyNameTok then
            exit(StrSubstNo(WrongCompanyStatusLbl, CompanyName(), TargetCompanyNameTok));
        if IsConfigured() then
            exit(ConfiguredStatusLbl);
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
            Error(AlreadyConfiguredErr);

        VerifyExistingVendor(ConsultingVendorNoTok);
        VerifyExistingVendor(SuppliesVendorNoTok);
        VerifyExistingGLAccount(ElectricityAccountNoTok);
        VerifyExistingGLAccount(RepairMaterialsAccountNoTok);
        VerifyExistingGLAccount(OfficeSuppliesAccountNoTok);
        VerifyExistingGLAccount(AccountingServicesAccountNoTok);
        VerifyExistingGLAccount(SalesVATTemplateAccountNoTok);
        VerifyExistingGLAccount(PurchaseVATTemplateAccountNoTok);
        VerifyRecordDoesNotExist(Database::Vendor, ElectricityVendorNoTok);
        VerifyRecordDoesNotExist(Database::"G/L Account", MaintenanceLabourAccountNoTok);
        VerifyRecordDoesNotExist(Database::"G/L Account", TrainingCostsAccountNoTok);
        VerifyRecordDoesNotExist(Database::"G/L Account", SalesVATAccountNoTok);
        VerifyRecordDoesNotExist(Database::"G/L Account", PurchaseVATAccountNoTok);
        VerifyRecordDoesNotExist(Database::"Cost Type", MaintenanceLabourAccountNoTok);
        VerifyRecordDoesNotExist(Database::"Cost Type", TrainingCostsAccountNoTok);
        VerifyRecordDoesNotExist(Database::"VAT Product Posting Group", GB20Tok);
        VerifyVATPostingSetupDoesNotExist();
        VerifyPostingSetupPrerequisites();
        VerifyDimensionPrerequisites();
        VerifyUnitOfMeasurePrerequisites();
        VerifySkillTitleDoesNotExist(LineClassificationSkillTitleLbl);
        VerifySkillTitleDoesNotExist(ElectricityMeterSkillTitleLbl);
        VerifySkillTitleDoesNotExist(ServiceClassificationSkillTitleLbl);
        VerifySkillTitleDoesNotExist(EffectiveDateSkillTitleLbl);
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

    local procedure VerifyVATPostingSetupDoesNotExist()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.Get(DomesticPostingGroupTok, GB20Tok) then
            Error(ProposedCombinationExistsErr, DomesticPostingGroupTok, GB20Tok);
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

    local procedure VerifySkillTitleDoesNotExist(SkillTitle: Text[250])
    var
        BusinessSkillProvisioning: Codeunit "Business Skill Provisioning";
    begin
        if BusinessSkillProvisioning.SkillTitleExists(SkillTitle) then
            Error(SkillTitleExistsErr, SkillTitle);
    end;

    local procedure RequireRecord(RecordExists: Boolean; RecordCaption: Text; RecordKey: Text)
    begin
        if not RecordExists then
            Error(RequiredRecordMissingErr, RecordCaption, RecordKey);
    end;

    local procedure InitializeState(var DemoState: Record "PA BC IQ Demo State")
    var
        Vendor: Record Vendor;
    begin
        DemoState.Init();
        DemoState."Primary Key" := StatePrimaryKeyTok;

        Vendor.Get(ConsultingVendorNoTok);
        DemoState."Vendor 20000 VAT Reg. No." := Vendor."VAT Registration No.";
        DemoState."Vendor 20000 Payment Terms" := Vendor."Payment Terms Code";

        Vendor.Get(SuppliesVendorNoTok);
        DemoState."Vendor 40000 VAT Reg. No." := Vendor."VAT Registration No.";
        DemoState."Vendor 40000 Payment Terms" := Vendor."Payment Terms Code";
    end;

    local procedure CreateVATProductPostingGroup()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Code := GB20Tok;
        VATProductPostingGroup.Validate(Description, GB20DescriptionLbl);
        VATProductPostingGroup.Insert(true);
    end;

    local procedure CreateDemoGLAccounts(var DemoState: Record "PA BC IQ Demo State")
    begin
        DemoState."Maintenance Cost Type Created" :=
            CreateExpenseAccount(RepairMaterialsAccountNoTok, MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, ServicesPostingGroupTok);
        DemoState."Training Cost Type Created" :=
            CreateExpenseAccount(AccountingServicesAccountNoTok, TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, ServicesPostingGroupTok);
        CreateVATAccount(SalesVATTemplateAccountNoTok, SalesVATAccountNoTok, SalesVATAccountNameLbl);
        CreateVATAccount(PurchaseVATTemplateAccountNoTok, PurchaseVATAccountNoTok, PurchaseVATAccountNameLbl);
    end;

    local procedure CreateExpenseAccount(TemplateAccountNo: Code[20]; NewAccountNo: Code[20]; NewAccountName: Text[100]; GenProductPostingGroupCode: Code[20]): Boolean
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
        NewGLAccount.Validate("VAT Prod. Posting Group", GB20Tok);
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

    local procedure CreateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", DomesticPostingGroupTok);
        VATPostingSetup.Validate("VAT Prod. Posting Group", GB20Tok);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 20);
        VATPostingSetup.Validate("VAT Identifier", GB20Tok);
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
        BusinessSkillProvisioning: Codeunit "Business Skill Provisioning";
    begin
        exit(BusinessSkillProvisioning.CreateCompanySkill(Title, Description, SkillText, TargetCompanyNameTok));
    end;

    local procedure GetLineClassificationSkillText(): Text
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

    local procedure GetElectricityMeterSkillText(): Text
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

    local procedure GetServiceClassificationSkillText(): Text
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

    local procedure GetEffectiveDateSkillText(): Text
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

    local procedure VerifyCleanupIsSafe(DemoState: Record "PA BC IQ Demo State")
    begin
        VerifyUpdatedVendorIsUnchanged(ConsultingVendorNoTok, ConsultingVendorVATRegistrationNoTok);
        VerifyUpdatedVendorIsUnchanged(SuppliesVendorNoTok, SuppliesVendorVATRegistrationNoTok);
        VerifyElectricityVendorIsUnchangedAndUnused();
        VerifyGLAccountIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, ServicesPostingGroupTok, GB20Tok);
        VerifyGLAccountIsUnchangedAndUnused(TrainingCostsAccountNoTok, TrainingCostsAccountNameLbl, ServicesPostingGroupTok, GB20Tok);
        VerifyGLAccountIsUnchangedAndUnused(SalesVATAccountNoTok, SalesVATAccountNameLbl, '', '');
        VerifyGLAccountIsUnchangedAndUnused(PurchaseVATAccountNoTok, PurchaseVATAccountNameLbl, '', '');
        VerifyVATSetupIsUnchangedAndUnused();
        VerifyCostTypeIsUnchangedAndUnused(MaintenanceLabourAccountNoTok, MaintenanceLabourAccountNameLbl, DemoState."Maintenance Cost Type Created");
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

    local procedure VerifyVATSetupIsUnchangedAndUnused()
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Get(GB20Tok);
        if VATProductPostingGroup.Description <> GB20DescriptionLbl then
            Error(RecordChangedAfterSetupErr, VATProductPostingGroup.TableCaption(), GB20Tok);

        VATPostingSetup.Get(DomesticPostingGroupTok, GB20Tok);
        if (VATPostingSetup."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type"::"Normal VAT") or
           (VATPostingSetup."VAT %" <> 20) or
           (VATPostingSetup."VAT Identifier" <> GB20Tok) or
           (VATPostingSetup."Sales VAT Account" <> SalesVATAccountNoTok) or
           (VATPostingSetup."Purchase VAT Account" <> PurchaseVATAccountNoTok)
        then
            Error(RecordChangedAfterSetupErr, VATPostingSetup.TableCaption(), StrSubstNo('%1/%2', DomesticPostingGroupTok, GB20Tok));

        PurchaseLine.SetRange("VAT Prod. Posting Group", GB20Tok);
        if not PurchaseLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GB20Tok);
        SalesLine.SetRange("VAT Prod. Posting Group", GB20Tok);
        if not SalesLine.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GB20Tok);
        VATEntry.SetRange("VAT Prod. Posting Group", GB20Tok);
        if not VATEntry.IsEmpty() then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GB20Tok);
        GLAccount.SetRange("VAT Prod. Posting Group", GB20Tok);
        if GLAccount.Count() <> 2 then
            Error(DemoRecordInUseErr, VATProductPostingGroup.TableCaption(), GB20Tok);
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
        BusinessSkillProvisioning: Codeunit "Business Skill Provisioning";
    begin
        BusinessSkillProvisioning.VerifyCompanySkill(SkillId, ExpectedTitle, ExpectedText, TargetCompanyNameTok);
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
        BusinessSkillProvisioning: Codeunit "Business Skill Provisioning";
    begin
        BusinessSkillProvisioning.DeleteCompanySkill(SkillId, ExpectedTitle, ExpectedText, TargetCompanyNameTok);
    end;

    local procedure DeleteVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(DomesticPostingGroupTok, GB20Tok);
        VATPostingSetup.Delete(true);
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

    local procedure DeleteVATProductPostingGroup()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Get(GB20Tok);
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

    var
        StatePrimaryKeyTok: Label 'SETUP', Locked = true;
        TargetCompanyNameTok: Label 'CRONUS W1', Locked = true;
        ConsultingVendorNoTok: Label '20000', Locked = true;
        SuppliesVendorNoTok: Label '40000', Locked = true;
        ElectricityVendorNoTok: Label 'GB-ELEC', Locked = true;
        ElectricityAccountNoTok: Label '8120', Locked = true;
        RepairMaterialsAccountNoTok: Label '8130', Locked = true;
        MaintenanceLabourAccountNoTok: Label '8140', Locked = true;
        OfficeSuppliesAccountNoTok: Label '8210', Locked = true;
        AccountingServicesAccountNoTok: Label '8630', Locked = true;
        TrainingCostsAccountNoTok: Label '8650', Locked = true;
        SalesVATTemplateAccountNoTok: Label '5610', Locked = true;
        SalesVATAccountNoTok: Label '5612', Locked = true;
        PurchaseVATTemplateAccountNoTok: Label '5630', Locked = true;
        PurchaseVATAccountNoTok: Label '5632', Locked = true;
        DomesticPostingGroupTok: Label 'DOMESTIC', Locked = true;
        MiscPostingGroupTok: Label 'MISC', Locked = true;
        ServicesPostingGroupTok: Label 'SERVICES', Locked = true;
        GB20Tok: Label 'GB20', Locked = true;
        ThirtyDaysPaymentTermsTok: Label '30 DAYS', Locked = true;
        DepartmentDimensionTok: Label 'DEPARTMENT', Locked = true;
        AdministrationDepartmentTok: Label 'ADM', Locked = true;
        ProductionDepartmentTok: Label 'PROD', Locked = true;
        SalesDepartmentTok: Label 'SALES', Locked = true;
        ConsultingVendorVATRegistrationNoTok: Label 'GB234 5678 47', Locked = true;
        SuppliesVendorVATRegistrationNoTok: Label 'GB123 4567 82', Locked = true;
        ElectricityVendorVATRegistrationNoTok: Label 'GB345 6789 12', Locked = true;
        ElectricityVendorNameLbl: Label 'Albion Business Energy Ltd';
        ElectricityVendorAddressLbl: Label '1 Energy Way';
        MaintenanceLabourAccountNameLbl: Label 'Maintenance Labour';
        TrainingCostsAccountNameLbl: Label 'Training Costs';
        SalesVATAccountNameLbl: Label 'Sales VAT 20%';
        PurchaseVATAccountNameLbl: Label 'Purchase VAT 20%';
        GB20DescriptionLbl: Label 'UK standard rate 20%';
        LineClassificationSkillTitleLbl: Label 'PA GB demo - line classification';
        LineClassificationSkillDescriptionLbl: Label 'Classifies repair materials, office consumables, and maintenance labour independently.';
        ElectricityMeterSkillTitleLbl: Label 'PA GB demo - electricity meter departments';
        ElectricityMeterSkillDescriptionLbl: Label 'Maps each commercial electricity meter to its own department.';
        ServiceClassificationSkillTitleLbl: Label 'PA GB demo - professional services';
        ServiceClassificationSkillDescriptionLbl: Label 'Classifies accounting assistance and training by service purpose and beneficiary department.';
        EffectiveDateSkillTitleLbl: Label 'PA GB demo - effective dated bookkeeping';
        EffectiveDateSkillDescriptionLbl: Label 'Overrides historical department coding from 1 October 2026 using the service period.';
        AlreadyConfiguredErr: Label 'The BC IQ Payables Agent demo setup is already configured in this company.';
        NotConfiguredErr: Label 'The BC IQ Payables Agent demo setup is not configured in this company.';
        WrongCompanyErr: Label 'Run this setup only in company %1. The current company is %2.', Comment = '%1 = required company, %2 = current company';
        RequiredRecordMissingErr: Label 'Required %1 %2 does not exist.', Comment = '%1 = record type, %2 = record key';
        ProposedRecordExistsErr: Label '%1 %2 already exists. Cleanup ownership cannot be guaranteed, so setup stopped without changing data.', Comment = '%1 = record type, %2 = record key';
        ProposedCombinationExistsErr: Label 'VAT Posting Setup %1/%2 already exists. Cleanup ownership cannot be guaranteed, so setup stopped without changing data.', Comment = '%1 = VAT business posting group, %2 = VAT product posting group';
        RequiredDimensionValueMissingErr: Label 'Required dimension value %1/%2 does not exist.', Comment = '%1 = dimension code, %2 = value code';
        RequiredDimensionValueBlockedErr: Label 'Required dimension value %1/%2 is blocked.', Comment = '%1 = dimension code, %2 = value code';
        SkillTitleExistsErr: Label 'A Business Central IQ skill titled "%1" already exists. Cleanup ownership cannot be guaranteed, so setup stopped without changing data.', Comment = '%1 = skill title';
        RecordChangedAfterSetupErr: Label '%1 %2 was changed after demo setup. Cleanup stopped to preserve those changes.', Comment = '%1 = record type, %2 = record key';
        DemoRecordInUseErr: Label '%1 %2 is in use. Cleanup stopped and did not remove any demo setup.', Comment = '%1 = record type, %2 = record key';
        ConfiguredStatusLbl: Label 'Configured. The four GB demo skills and required company setup are available.';
        NotConfiguredStatusLbl: Label 'Not configured. Choose Setup Company to create the GB demo setup.';
        WrongCompanyStatusLbl: Label 'Current company: %1. Switch to %2 to use this page.', Comment = '%1 = current company, %2 = required company';
}
