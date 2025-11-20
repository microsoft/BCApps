// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.CRM.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;

codeunit 1400 DocumentNoVisibility
{
    SingleInstance = true;

    var
        IsCustNoInitialized: Boolean;
        IsVendNoInitialized: Boolean;
        IsEmployeeNoInitialized: Boolean;
        IsItemNoInitialized: Boolean;
        IsBankNoInitialized: Boolean;
        IsFANoInitialized: Boolean;
        IsResNoInitialized: Boolean;
        IsJobNoInitialized: Boolean;
        IsTransferOrdNoInitialized: Boolean;
        IsContactNoInitialized: Boolean;
        CustNoVisible: Boolean;
        VendNoVisible: Boolean;
        EmployeeNoVisible: Boolean;
        ItemNoVisible: Boolean;
        BankNoVisible: Boolean;
        FANoVisible: Boolean;
        ResNoVisible: Boolean;
        JobNoVisible: Boolean;
        TransferOrdNoVisible: Boolean;
        ContactNoVisible: Boolean;
        SalesDocsNoVisible: Dictionary of [Integer, Boolean];
        PurchaseDocsNoVisible: Dictionary of [Integer, Boolean];

    procedure ClearState()
    begin
        IsCustNoInitialized := false;
        IsVendNoInitialized := false;
        IsEmployeeNoInitialized := false;
        IsItemNoInitialized := false;
        IsBankNoInitialized := false;
        IsFANoInitialized := false;
        IsResNoInitialized := false;
        IsJobNoInitialized := false;
        IsTransferOrdNoInitialized := false;
        IsContactNoInitialized := false;
        CustNoVisible := false;
        VendNoVisible := false;
        EmployeeNoVisible := false;
        ItemNoVisible := false;
        BankNoVisible := false;
        FANoVisible := false;
        ResNoVisible := false;
        JobNoVisible := false;
        TransferOrdNoVisible := false;
        ContactNoVisible := false;

        Clear(SalesDocsNoVisible);
        Clear(PurchaseDocsNoVisible);
    end;

    procedure SalesDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        SalesNoSeriesSetup: Page "Sales No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeSalesDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        if SalesDocsNoVisible.ContainsKey(DocType) then
            exit(SalesDocsNoVisible.Get(DocType));

        DocNoSeries := DetermineSalesSeriesNo(DocType);
        if not NoSeries.Get(DocNoSeries) then begin
            SalesNoSeriesSetup.SetFieldsVisibility(DocType);
            SalesNoSeriesSetup.RunModal();
            DocNoSeries := DetermineSalesSeriesNo(DocType);
        end;
        Result := ForceShowNoSeriesForDocNo(DocNoSeries);
        SalesDocsNoVisible.Add(DocType, Result);
        exit(Result);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Document No. Visibility', '25.0')]
    procedure ServiceDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract; DocNo: Code[20]): Boolean
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
    begin
        exit(ServDocumentNoVisibility.ServiceDocumentNoIsVisible(DocType, DocNo));
    end;
#endif

    procedure PurchaseDocumentNoIsVisible(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; DocNo: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        PurchaseNoSeriesSetup: Page "Purchase No. Series Setup";
        DocNoSeries: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforePurchaseDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if DocNo <> '' then
            exit(false);

        if PurchaseDocsNoVisible.ContainsKey(DocType) then
            exit(PurchaseDocsNoVisible.Get(DocType));

        DocNoSeries := DeterminePurchaseSeriesNo(DocType);
        if not NoSeries.Get(DocNoSeries) then begin
            PurchaseNoSeriesSetup.SetFieldsVisibility(DocType);
            PurchaseNoSeriesSetup.RunModal();
            DocNoSeries := DeterminePurchaseSeriesNo(DocType);
        end;
        Result := ForceShowNoSeriesForDocNo(DocNoSeries);
        PurchaseDocsNoVisible.Add(DocType, Result);
        exit(Result);
    end;

    procedure TransferOrderNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeTransferOrderNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsTransferOrdNoInitialized then
            exit(TransferOrdNoVisible);
        IsTransferOrdNoInitialized := true;

        NoSeriesCode := DetermineTransferOrderSeriesNo();
        TransferOrdNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(TransferOrdNoVisible);
    end;

    procedure CustomerNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeCustomerNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsCustNoInitialized then
            exit(CustNoVisible);
        IsCustNoInitialized := true;

        NoSeriesCode := DetermineCustomerSeriesNo();
        CustNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(CustNoVisible);
    end;

    procedure VendorNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeVendorNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsVendNoInitialized then
            exit(VendNoVisible);
        IsVendNoInitialized := true;

        NoSeriesCode := DetermineVendorSeriesNo();
        VendNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(VendNoVisible);
    end;

    procedure ItemNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeItemNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsItemNoInitialized then
            exit(ItemNoVisible);
        IsItemNoInitialized := true;

        NoSeriesCode := DetermineItemSeriesNo();
        ItemNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ItemNoVisible);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Document No. Visibility', '25.0')]
    procedure ServiceItemNoIsVisible(): Boolean
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
    begin
        exit(ServDocumentNoVisibility.ServiceItemNoIsVisible());
    end;
#endif

    procedure FixedAssetNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeFixedAssetNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsFANoInitialized then
            exit(FANoVisible);
        IsFANoInitialized := true;

        NoSeriesCode := DetermineFixedAssetSeriesNo();
        FANoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(FANoVisible);
    end;

    procedure EmployeeNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeEmployeeNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsEmployeeNoInitialized then
            exit(EmployeeNoVisible);
        IsEmployeeNoInitialized := true;

        NoSeriesCode := DetermineEmployeeSeriesNo();
        EmployeeNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(EmployeeNoVisible);
    end;

    procedure BankAccountNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeBankAccountNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsBankNoInitialized then
            exit(BankNoVisible);
        IsBankNoInitialized := true;

        NoSeriesCode := DetermineBankAccountSeriesNo();
        BankNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(BankNoVisible);
    end;

    procedure ResourceNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeResourceNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsResNoInitialized then
            exit(ResNoVisible);
        IsResNoInitialized := true;

        NoSeriesCode := DetermineResourceSeriesNo();
        ResNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ResNoVisible);
    end;

    procedure JobNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeJobNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsJobNoInitialized then
            exit(JobNoVisible);
        IsJobNoInitialized := true;

        NoSeriesCode := DetermineJobSeriesNo();
        JobNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(JobNoVisible);
    end;

    procedure ContactNoIsVisible(): Boolean
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
        IsVisible: Boolean;
    begin
        IsHandled := false;
        IsVisible := false;
        OnBeforeContactNoIsVisible(IsVisible, IsHandled);
        if IsHandled then
            exit(IsVisible);

        if IsContactNoInitialized then
            exit(ContactNoVisible);
        IsContactNoInitialized := true;

        NoSeriesCode := DetermineContactSeriesNo();
        ContactNoVisible := ForceShowNoSeriesForDocNo(NoSeriesCode);
        exit(ContactNoVisible);
    end;

    procedure CustomerNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineCustomerSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    procedure VendorNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineVendorSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    procedure ItemNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineItemSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    procedure TransferOrderNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineTransferOrderSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    procedure FixedAssetNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineFixedAssetSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    procedure EmployeeNoSeriesIsDefault(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(DetermineEmployeeSeriesNo()) then
            exit(NoSeries."Default Nos.");
        exit(false);
    end;

    local procedure DetermineSalesSeriesNo(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        case DocType of
            DocType::Quote:
                exit(SalesReceivablesSetup."Quote Nos.");
            DocType::Order:
                exit(SalesReceivablesSetup."Order Nos.");
            DocType::Invoice:
                exit(SalesReceivablesSetup."Invoice Nos.");
            DocType::"Credit Memo":
                exit(SalesReceivablesSetup."Credit Memo Nos.");
            DocType::"Blanket Order":
                exit(SalesReceivablesSetup."Blanket Order Nos.");
            DocType::"Return Order":
                exit(SalesReceivablesSetup."Return Order Nos.");
            DocType::Reminder:
                exit(SalesReceivablesSetup."Reminder Nos.");
            DocType::FinChMemo:
                exit(SalesReceivablesSetup."Fin. Chrg. Memo Nos.");
        end;
    end;

    local procedure DeterminePurchaseSeriesNo(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
        ReturnValue: Code[20];
    begin
        PurchasesPayablesSetup.Get();
        case DocType of
            DocType::Quote:
                exit(PurchasesPayablesSetup."Quote Nos.");
            DocType::Order:
                exit(PurchasesPayablesSetup."Order Nos.");
            DocType::Invoice:
                exit(PurchasesPayablesSetup."Invoice Nos.");
            DocType::"Credit Memo":
                exit(PurchasesPayablesSetup."Credit Memo Nos.");
            DocType::"Blanket Order":
                exit(PurchasesPayablesSetup."Blanket Order Nos.");
            DocType::"Return Order":
                exit(PurchasesPayablesSetup."Return Order Nos.");
            else begin
                IsHandled := false;
                OnDeterminePurchaseSeriesNoOnElseDocType(DocType, ReturnValue, IsHandled);
                if IsHandled then
                    exit(ReturnValue);
            end;

        end;
    end;

    local procedure DetermineTransferOrderSeriesNo(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.SetLoadFields("Transfer Order Nos.");
        InventorySetup.Get();
        exit(InventorySetup."Transfer Order Nos.");
    end;

    local procedure DetermineCustomerSeriesNo(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.SetLoadFields("Customer Nos.");
        SalesReceivablesSetup.Get();
        exit(SalesReceivablesSetup."Customer Nos.");
    end;

    local procedure DetermineVendorSeriesNo(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.SetLoadFields("Vendor Nos.");
        PurchasesPayablesSetup.Get();
        exit(PurchasesPayablesSetup."Vendor Nos.");
    end;

    local procedure DetermineItemSeriesNo(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.SetLoadFields("Item Nos.");
        InventorySetup.Get();
        exit(InventorySetup."Item Nos.");
    end;

    local procedure DetermineFixedAssetSeriesNo(): Code[20]
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.SetLoadFields("Fixed Asset Nos.");
        FASetup.Get();
        exit(FASetup."Fixed Asset Nos.");
    end;

    local procedure DetermineEmployeeSeriesNo(): Code[20]
    var
        HumanResourcesSetup: Record "Human Resources Setup";
    begin
        HumanResourcesSetup.SetLoadFields("Employee Nos.");
        HumanResourcesSetup.Get();
        exit(HumanResourcesSetup."Employee Nos.");
    end;

    local procedure DetermineBankAccountSeriesNo(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.SetLoadFields("Bank Account Nos.");
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Bank Account Nos.");
    end;

    local procedure DetermineResourceSeriesNo(): Code[20]
    var
        ResourcesSetup: Record "Resources Setup";
    begin
        ResourcesSetup.SetLoadFields("Resource Nos.");
        ResourcesSetup.Get();
        exit(ResourcesSetup."Resource Nos.");
    end;

    local procedure DetermineJobSeriesNo(): Code[20]
    var
        JobsSetup: Record "Jobs Setup";
    begin
        JobsSetup.SetLoadFields("Job Nos.");
        JobsSetup.Get();
        exit(JobsSetup."Job Nos.");
    end;

    local procedure DetermineContactSeriesNo(): Code[20]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.SetLoadFields("Contact Nos.");
        MarketingSetup.Get();
        exit(MarketingSetup."Contact Nos.");
    end;

    procedure ForceShowNoSeriesForDocNo(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        SeriesDate: Date;
    begin
        if not NoSeries.Get(NoSeriesCode) then
            exit(true);

        SeriesDate := WorkDate();
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        if not NoSeriesRelationship.IsEmpty() then
            exit(true);

        if NoSeries."Manual Nos." or (NoSeries."Default Nos." = false) then
            exit(true);

        exit(NoSeriesBatch.GetNextNo(NoSeriesCode, SeriesDate, true) = '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeServiceDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeServiceDocumentNoIsVisible(DocType, DocNo, IsVisible, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Document No. Visibility', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseDocumentNoIsVisible(DocType: Option; DocNo: Code[20]; var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferOrderNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCustomerNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVendorNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeServiceItemNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeServiceItemNoIsVisible(IsVisible, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Document No. Visibility', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceItemNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFixedAssetNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmployeeNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBankAccountNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResourceNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeContactNoIsVisible(var IsVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeterminePurchaseSeriesNoOnElseDocType(DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; var ReturnValue: Code[20]; var IsHandled: Boolean)
    begin
    end;
}
