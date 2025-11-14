namespace Microsoft.SubscriptionBilling;

#if not CLEANSCHEMA29
using Microsoft.Finance.GeneralLedger.Setup;
#endif
using Microsoft.Sales.Document;
using System.Upgrade;

codeunit 8032 "Upgrade Subscription Billing"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
#if not CLEANSCHEMA29
        UpdateClosedFlagForServiceCommitments();
        UpdateSourceNoForServiceObjects();
        UpdateTypeNoForContractLines();
        UpdateSourceNoForContractAnalysisEntries();
        UpdateDefaultPeriodsInServiceContractSetup();
        MoveCustContrDimensionToServiceContractSetup();
#endif
        UpdateCreateContractDeferralsFlag();
        DeleteSalesSubscriptionLinesConnectedToDeletedQuote();
        RemoveDocumentNoFromBillingLines();
    end;

#if not CLEANSCHEMA29
    local procedure UpdateTypeNoForContractLines()
    var
        CustomerContractLine: Record "Cust. Sub. Contract Line";
        VendorContractLine: Record "Vend. Sub. Contract Line";
        ServiceObject: Record "Subscription Header";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetTypeNoForContractLinesUpgradeTag()) then
            exit;

        CustomerContractLine.SetRange("Contract Line Type", CustomerContractLine."Contract Line Type"::"Service Commitment");
        if CustomerContractLine.FindSet() then
            repeat
                if ServiceObject.Get(CustomerContractLine."Subscription Header No.") then begin
                    CustomerContractLine."Contract Line Type" := CustomerContractLine."Contract Line Type"::Item;
                    CustomerContractLine."No." := ServiceObject."Source No.";
                    CustomerContractLine.Modify();
                end;
            until CustomerContractLine.Next() = 0;

        VendorContractLine.SetRange("Contract Line Type", VendorContractLine."Contract Line Type"::"Service Commitment");
        if VendorContractLine.FindSet() then
            repeat
                if ServiceObject.Get(VendorContractLine."Subscription Header No.") then begin
                    VendorContractLine."Contract Line Type" := VendorContractLine."Contract Line Type"::Item;
                    VendorContractLine."No." := ServiceObject."Source No.";
                    VendorContractLine.Modify();
                end;
            until VendorContractLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetTypeNoForContractLinesUpgradeTag());
    end;

    local procedure GetTypeNoForContractLinesUpgradeTag(): Code[250]
    begin
        exit('MS-565334-TypeNoForContractLinessUpgradeTag-20250205');
    end;

    local procedure UpdateClosedFlagForServiceCommitments()
    var
        CustomerContractLine: Record "Cust. Sub. Contract Line";
        VendorContractLine: Record "Vend. Sub. Contract Line";
        ServiceCommitment: Record "Subscription Line";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetClosedFlagUpgradeTag()) then
            exit;

        CustomerContractLine.SetLoadFields(Closed, "Subscription Line Entry No.");
        CustomerContractLine.SetRange(Closed, true);
        if CustomerContractLine.FindSet() then
            repeat
                if ServiceCommitment.Get(CustomerContractLine."Subscription Line Entry No.") then begin
                    ServiceCommitment.Closed := CustomerContractLine.Closed;
                    ServiceCommitment.Modify(false);
                end;
            until CustomerContractLine.Next() = 0;

        VendorContractLine.SetLoadFields(Closed, "Subscription Line Entry No.");
        VendorContractLine.SetRange(Closed, true);
        if VendorContractLine.FindSet() then
            repeat
                if ServiceCommitment.Get(VendorContractLine."Subscription Line Entry No.") then begin
                    ServiceCommitment.Closed := VendorContractLine.Closed;
                    ServiceCommitment.Modify(false);
                end;
            until VendorContractLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetClosedFlagUpgradeTag());
    end;

    local procedure GetClosedFlagUpgradeTag(): Code[250]
    begin
        exit('MS-XXXXXX-ClosedFlagUpgradeTag-20241110');
    end;

    local procedure UpdateSourceNoForServiceObjects()
    var
        ServiceObject: Record "Subscription Header";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSourceNoForServiceObjectsUpgradeTag()) then
            exit;

        if ServiceObject.FindSet() then
            repeat
                ServiceObject.Type := ServiceObject.Type::Item;
                ServiceObject."Source No." := ServiceObject."Item No.";
                ServiceObject.Modify();
            until ServiceObject.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetSourceNoForServiceObjectsUpgradeTag());
    end;

    local procedure GetSourceNoForServiceObjectsUpgradeTag(): Code[250]
    begin
        exit('MS-565334-SourceNoForServiceObjectsUpgradeTag-20250205');
    end;

    local procedure UpdateSourceNoForContractAnalysisEntries()
    var
        ContractAnalysisEntry: Record "Sub. Contr. Analysis Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSourceNoForContractAnalysisEntriesUpgradeTag()) then
            exit;

        if ContractAnalysisEntry.FindSet() then
            repeat
                ContractAnalysisEntry."Sub. Header Source Type" := ContractAnalysisEntry."Sub. Header Source Type"::Item;
                ContractAnalysisEntry."Sub. Header Source No." := ContractAnalysisEntry."Service Object Item No.";
                ContractAnalysisEntry.Modify();
            until ContractAnalysisEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetSourceNoForContractAnalysisEntriesUpgradeTag());
    end;

    local procedure GetSourceNoForContractAnalysisEntriesUpgradeTag(): Code[250]
    begin
        exit('MS-565334-SourceNoForContractAnalysisEntriesTag-20250205');
    end;

    local procedure UpdateDefaultPeriodsInServiceContractSetup()
    var
        ServiceContractSetup: Record "Subscription Contract Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetUpdateDefaultPeriodsInServiceContractSetupUpgradeTag()) then
            exit;

        if ServiceContractSetup.Get() then begin
            Evaluate(ServiceContractSetup."Default Billing Base Period", '<1M>');
            Evaluate(ServiceContractSetup."Default Billing Rhythm", '<1M>');
            ServiceContractSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(GetUpdateDefaultPeriodsInServiceContractSetupUpgradeTag());
    end;

    local procedure GetUpdateDefaultPeriodsInServiceContractSetupUpgradeTag(): Code[250]
    begin
        exit('MS-565334-DefaultPeriodsInServiceContractSetupsTag-20250205');
    end;

    local procedure MoveCustContrDimensionToServiceContractSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceContractSetup: Record "Subscription Contract Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetMoveCustContrDimensionUpgradeTag()) then
            exit;

        if not GeneralLedgerSetup.Get() then
            exit;

        if ServiceContractSetup.Get() then begin
            ServiceContractSetup."Dimension Code Cust. Contr." := GeneralLedgerSetup."Dimension Code Cust. Contr.";
            ServiceContractSetup.Modify(false);
        end;

        UpgradeTag.SetUpgradeTag(GetMoveCustContrDimensionUpgradeTag());
    end;

    local procedure GetMoveCustContrDimensionUpgradeTag(): Code[250]
    begin
        exit('MS-565334-MoveCustContrDimension-20250205');
    end;
#endif

    local procedure UpdateCreateContractDeferralsFlag()
    var
        SubPackageLineTemplate: Record "Sub. Package Line Template";
        SubscriptionPackageLine: Record "Subscription Package Line";
        SalesSubscriptionLine: Record "Sales Subscription Line";
        SubscriptionLine: Record "Subscription Line";
        SubscriptionContractType: Record "Subscription Contract Type";
        CustomerSubscriptionContract: Record "Customer Subscription Contract";
        VendorSubscriptionContract: Record "Vendor Subscription Contract";
        ImportedCustSubContract: Record "Imported Cust. Sub. Contract";
        ImportedSubscriptionLine: Record "Imported Subscription Line";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetUpdateCreateContractDeferralsFlag()) then
            exit;

        SubPackageLineTemplate.SetRange("Invoicing via", Enum::"Invoicing Via"::Sales);
        SubPackageLineTemplate.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);

        SubscriptionPackageLine.SetRange("Invoicing via", Enum::"Invoicing Via"::Sales);
        SubscriptionPackageLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);

        SalesSubscriptionLine.SetRange("Invoicing via", Enum::"Invoicing Via"::Sales);
        SalesSubscriptionLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);

        SubscriptionLine.SetRange("Invoicing via", Enum::"Invoicing Via"::Sales);
        SubscriptionLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);

        SubscriptionContractType.SetRange("Def. Without Contr. Deferrals", true);
        SubscriptionContractType.ModifyAll("Create Contract Deferrals", false);
        SubscriptionContractType.SetRange("Def. Without Contr. Deferrals", false);
        SubscriptionContractType.ModifyAll("Create Contract Deferrals", true);

        CustomerSubscriptionContract.SetRange("Without Contract Deferrals", true);
        CustomerSubscriptionContract.ModifyAll("Create Contract Deferrals", false);
        CustomerSubscriptionContract.SetRange("Without Contract Deferrals", false);
        CustomerSubscriptionContract.ModifyAll("Create Contract Deferrals", true);

        VendorSubscriptionContract.SetRange("Without Contract Deferrals", true);
        VendorSubscriptionContract.ModifyAll("Create Contract Deferrals", false);
        VendorSubscriptionContract.SetRange("Without Contract Deferrals", false);
        VendorSubscriptionContract.ModifyAll("Create Contract Deferrals", true);

        ImportedCustSubContract.SetRange("Without Contract Deferrals", true);
        ImportedCustSubContract.ModifyAll("Create Contract Deferrals", false);
        ImportedCustSubContract.SetRange("Without Contract Deferrals", false);
        ImportedCustSubContract.ModifyAll("Create Contract Deferrals", true);

        ImportedSubscriptionLine.SetRange("Invoicing via", Enum::"Invoicing Via"::Sales);
        ImportedSubscriptionLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);

        UpgradeTag.SetUpgradeTag(GetUpdateCreateContractDeferralsFlag());
    end;

    internal procedure GetUpdateCreateContractDeferralsFlag(): Code[250]
    begin
        exit('MS-XXXXXX-UpdateCreateContractDeferralsFlag-20250321');
    end;

    local procedure DeleteSalesSubscriptionLinesConnectedToDeletedQuote()
    var
        SalesSubscriptionLine: Record "Sales Subscription Line";
        SalesHeader: Record "Sales Header";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag()) then
            exit;

        SalesSubscriptionLine.SetRange("Document Type", "Sales Document Type"::Quote);
        if SalesSubscriptionLine.FindSet() then
            repeat
                if not SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesSubscriptionLine."Document No.") then
                    SalesSubscriptionLine.Delete(false);
            until SalesSubscriptionLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag());
    end;

    local procedure DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag(): Text[250]
    begin
        exit('MS-598518-DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag-20250819');
    end;

    local procedure RemoveDocumentNoFromBillingLines()
    var
        BillingLine: Record "Billing Line";
        SalesHeader: Record "Sales Header";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(RemoveDocumentNoFromBillingLinesTag()) then
            exit;

        BillingLine.SetRange(Partner, BillingLine.Partner::Customer);
        BillingLine.SetFilter("Document No.", '<>%1', '');
        if BillingLine.FindSet() then
            repeat
                case BillingLine."Document Type" of
                    BillingLine."Document Type"::Invoice:
                        if not SalesHeader.Get(SalesHeader."Document Type"::Invoice, BillingLine."Document No.") then begin
                            BillingLine."Document Type" := BillingLine."Document Type"::None;
                            BillingLine."Document No." := '';
                            BillingLine.Modify(false);
                        end;
                    BillingLine."Document Type"::"Credit Memo":
                        if not SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", BillingLine."Document No.") then begin
                            BillingLine."Document Type" := BillingLine."Document Type"::None;
                            BillingLine."Document No." := '';
                            BillingLine.Modify(false);
                        end;
                end;
            until BillingLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(RemoveDocumentNoFromBillingLinesTag());
    end;

    local procedure RemoveDocumentNoFromBillingLinesTag(): Text[250]
    begin
        exit('MS-XXXXXX-RemoveDocumentNoFromBillingLines-20250819');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
#if not CLEANSCHEMA29
        PerCompanyUpgradeTags.Add(GetTypeNoForContractLinesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetClosedFlagUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSourceNoForServiceObjectsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSourceNoForContractAnalysisEntriesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUpdateDefaultPeriodsInServiceContractSetupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMoveCustContrDimensionUpgradeTag());
#endif
        PerCompanyUpgradeTags.Add(GetUpdateCreateContractDeferralsFlag());
        PerCompanyUpgradeTags.Add(DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag());
        PerCompanyUpgradeTags.Add(RemoveDocumentNoFromBillingLinesTag());
    end;
}
