namespace Microsoft.SubscriptionBilling;

using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
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
        UpdateCreateContractDeferralsFlag();
        DeleteSalesSubscriptionLinesConnectedToDeletedQuote();
        RemoveDocumentNoFromBillingLines();
        FillPostingGroupsInContractDeferrals();
    end;


    local procedure UpdateCreateContractDeferralsFlag()
    var
        SubPackageLineTemplate: Record "Sub. Package Line Template";
        SubscriptionPackageLine: Record "Subscription Package Line";
        SalesSubscriptionLine: Record "Sales Subscription Line";
        SubscriptionLine: Record "Subscription Line";
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

    local procedure FillPostingGroupsInContractDeferrals()
    var
        CustContractDeferral: Record "Cust. Sub. Contract Deferral";
        VendContractDeferral: Record "Vend. Sub. Contract Deferral";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(FillPostingGroupsInContractDeferralsTag()) then
            exit;

        CustContractDeferral.SetRange("Gen. Bus. Posting Group", '');
        CustContractDeferral.SetRange("Gen. Prod. Posting Group", '');
        if CustContractDeferral.FindSet(true) then
            repeat
                UpdateCustDeferralPostingGroups(CustContractDeferral);
            until CustContractDeferral.Next() = 0;

        VendContractDeferral.SetRange("Gen. Bus. Posting Group", '');
        VendContractDeferral.SetRange("Gen. Prod. Posting Group", '');
        if VendContractDeferral.FindSet(true) then
            repeat
                UpdateVendDeferralPostingGroups(VendContractDeferral);
            until VendContractDeferral.Next() = 0;

        UpgradeTag.SetUpgradeTag(FillPostingGroupsInContractDeferralsTag());
    end;

    local procedure UpdateCustDeferralPostingGroups(var CustContractDeferral: Record "Cust. Sub. Contract Deferral")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CustContractDeferralToUpdate: Record "Cust. Sub. Contract Deferral";
    begin
        CustContractDeferralToUpdate := CustContractDeferral;
        case CustContractDeferral."Document Type" of
            "Rec. Billing Document Type"::Invoice:
                if SalesInvoiceLine.Get(CustContractDeferral."Document No.", CustContractDeferral."Document Line No.") then begin
                    CustContractDeferralToUpdate."Gen. Bus. Posting Group" := SalesInvoiceLine."Gen. Bus. Posting Group";
                    CustContractDeferralToUpdate."Gen. Prod. Posting Group" := SalesInvoiceLine."Gen. Prod. Posting Group";
                    CustContractDeferralToUpdate.Modify(false);
                end;
            "Rec. Billing Document Type"::"Credit Memo":
                if SalesCrMemoLine.Get(CustContractDeferral."Document No.", CustContractDeferral."Document Line No.") then begin
                    CustContractDeferralToUpdate."Gen. Bus. Posting Group" := SalesCrMemoLine."Gen. Bus. Posting Group";
                    CustContractDeferralToUpdate."Gen. Prod. Posting Group" := SalesCrMemoLine."Gen. Prod. Posting Group";
                    CustContractDeferralToUpdate.Modify(false);
                end;
        end;
    end;

    local procedure UpdateVendDeferralPostingGroups(var VendContractDeferral: Record "Vend. Sub. Contract Deferral")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        VendContractDeferralToUpdate: Record "Vend. Sub. Contract Deferral";
    begin
        VendContractDeferralToUpdate := VendContractDeferral;
        case VendContractDeferral."Document Type" of
            "Rec. Billing Document Type"::Invoice:
                if PurchInvLine.Get(VendContractDeferral."Document No.", VendContractDeferral."Document Line No.") then begin
                    VendContractDeferralToUpdate."Gen. Bus. Posting Group" := PurchInvLine."Gen. Bus. Posting Group";
                    VendContractDeferralToUpdate."Gen. Prod. Posting Group" := PurchInvLine."Gen. Prod. Posting Group";
                    VendContractDeferralToUpdate.Modify(false);
                end;
            "Rec. Billing Document Type"::"Credit Memo":
                if PurchCrMemoLine.Get(VendContractDeferral."Document No.", VendContractDeferral."Document Line No.") then begin
                    VendContractDeferralToUpdate."Gen. Bus. Posting Group" := PurchCrMemoLine."Gen. Bus. Posting Group";
                    VendContractDeferralToUpdate."Gen. Prod. Posting Group" := PurchCrMemoLine."Gen. Prod. Posting Group";
                    VendContractDeferralToUpdate.Modify(false);
                end;
        end;
    end;

    local procedure FillPostingGroupsInContractDeferralsTag(): Text[250]
    begin
        exit('MS-623188-FillPostingGroupsInContractDeferrals-20250209');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpdateCreateContractDeferralsFlag());
        PerCompanyUpgradeTags.Add(DeleteSalesSubscriptionLinesConnectedToDeletedQuoteTag());
        PerCompanyUpgradeTags.Add(RemoveDocumentNoFromBillingLinesTag());
        PerCompanyUpgradeTags.Add(FillPostingGroupsInContractDeferralsTag());
    end;
}
