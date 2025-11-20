// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using System.Upgrade;
using System.Environment;

codeunit 104059 "Serv. Upgrade BaseApp"
{
    Subtype = Upgrade;

    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ServiceBlockedAlreadySetLbl: Label 'CopyItemSalesBlockedToServiceBlocked skipped. %1 already set for at least one record in table %2.', Comment = '%1 = Field Caption, %2 = Table Caption', Locked = true;
        ServiceMgtSetupDoesNotExistLbl: Label 'EnableDeleteFiledContractsWithRelatedMainContract upgrade skipped. Service Mgt. Setup not found.', Locked = true;
        DeleteFiledContractsWithRelatedMainContractAlreadySetErr: Label 'EnableDeleteFiledContractsWithRelatedMainContract upgrade skipped. %1 already enabled in Service Mgt. Setup.', Comment = '%1 = "Del. Filed Cont. w. main Cont." Field Name', Locked = true;

    trigger OnCheckPreconditionsPerDatabase()
    begin
        HybridDeployment.VerifyCanStartUpgrade('');
    end;

    trigger OnCheckPreconditionsPerCompany()
    begin
        HybridDeployment.VerifyCanStartUpgrade(CompanyName());
    end;

    trigger OnUpgradePerCompany()
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateServiceLineOrderNo();
        CopyItemSalesBlockedToServiceBlocked();
        UpgradeServiceItemWorksheetReportSelection();
        UpdateServiceEntries();
        EnableDeleteFiledContractsWithRelatedMainContract();

        if not UpgradeTag.HasUpgradeTag(GetVATDateFieldServiceBlankUpgrade()) then begin
            UpdateServiceBlankEntries();
            UpgradeTag.SetUpgradeTag(GetVATDateFieldServiceBlankUpgrade());
        end;
    end;

    local procedure UpdateServiceLineOrderNo()
    var
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetServiceLineOrderNoUpgradeTag()) then
            exit;

        ServiceLine.SetLoadFields("Shipment No.", "Shipment Line No.");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetFilter("Shipment No.", '<>%1', '');
        ServiceLine.SetFilter("Shipment Line No.", '<>%1', 0);
        if ServiceLine.FindSet(true) then
            repeat
                ServiceShipmentLine.SetLoadFields("Order No.");
                if ServiceShipmentLine.Get(ServiceLine."Shipment No.", ServiceLine."Shipment Line No.") then begin
                    ServiceLine."Order No." := ServiceShipmentLine."Order No.";
                    ServiceLine.Modify();
                end;
            until ServiceLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetServiceLineOrderNoUpgradeTag());
    end;

    local procedure CopyItemSalesBlockedToServiceBlocked()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemTempl: Record "Item Templ.";
        ServiceItem: Record "Service Item";
        DataTransfer: DataTransfer;
        SkipUpgrade: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCopyItemSalesBlockedToServiceBlockedUpgradeTag()) then
            exit;

        SkipUpgrade := ServiceItem.IsEmpty();

        if not SkipUpgrade then begin
            Item.SetRange("Service Blocked", true);
            SkipUpgrade := not Item.IsEmpty();
            if SkipUpgrade then
                Session.LogMessage('0000LZQ', StrSubstNo(ServiceBlockedAlreadySetLbl, Item.FieldCaption("Service Blocked"), Item.TableCaption()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
        end;
        if not SkipUpgrade then begin
            ItemVariant.SetRange("Service Blocked", true);
            SkipUpgrade := not ItemVariant.IsEmpty();
            if SkipUpgrade then
                Session.LogMessage('0000LZR', StrSubstNo(ServiceBlockedAlreadySetLbl, ItemVariant.FieldCaption("Service Blocked"), ItemVariant.TableCaption()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
        end;
        if not SkipUpgrade then begin
            ItemTempl.SetRange("Service Blocked", true);
            SkipUpgrade := not ItemTempl.IsEmpty();
            if SkipUpgrade then
                Session.LogMessage('0000LZS', StrSubstNo(ServiceBlockedAlreadySetLbl, ItemTempl.FieldCaption("Service Blocked"), ItemTempl.TableCaption()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
        end;

        if not SkipUpgrade then begin
            DataTransfer.SetTables(Database::"Item", Database::"Item");
            DataTransfer.AddSourceFilter(Item.FieldNo("Sales Blocked"), '=%1', true);
            DataTransfer.AddFieldValue(Item.FieldNo("Sales Blocked"), Item.FieldNo("Service Blocked"));
            DataTransfer.UpdateAuditFields := false;
            DataTransfer.CopyFields();
            Clear(DataTransfer);

            DataTransfer.SetTables(Database::"Item Variant", Database::"Item Variant");
            DataTransfer.AddSourceFilter(ItemVariant.FieldNo("Sales Blocked"), '=%1', true);
            DataTransfer.AddFieldValue(ItemVariant.FieldNo("Sales Blocked"), ItemVariant.FieldNo("Service Blocked"));
            DataTransfer.UpdateAuditFields := false;
            DataTransfer.CopyFields();
            Clear(DataTransfer);

            DataTransfer.SetTables(Database::"Item Templ.", Database::"Item Templ.");
            DataTransfer.AddSourceFilter(ItemTempl.FieldNo("Sales Blocked"), '=%1', true);
            DataTransfer.AddFieldValue(ItemTempl.FieldNo("Sales Blocked"), ItemTempl.FieldNo("Service Blocked"));
            DataTransfer.UpdateAuditFields := false;
            DataTransfer.CopyFields();
            Clear(DataTransfer);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCopyItemSalesBlockedToServiceBlockedUpgradeTag());
    end;

    local procedure UpgradeServiceItemWorksheetReportSelection()
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        if UpgradeTag.HasUpgradeTag(GetServiceItemWorksheetSelectionUpgradeTag()) then
            exit;
        ReportSelectionMgt.InitReportSelection(Enum::"Report Selection Usage"::"SM.Item WorkSheet");
        UpgradeTag.SetUpgradeTag(GetServiceItemWorksheetSelectionUpgradeTag());
    end;

    local procedure UpdateServiceEntries()
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        VATDateDataTransfer: DataTransfer;
        BlankDate: Date;
    begin
        if UpgradeTag.HasUpgradeTag(GetVATDateFieldServiceUpgrade()) then
            exit;

        BlankDate := 0D;

        ServiceInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not ServiceInvHeader.IsEmpty() then
            exit;

        ServiceCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not ServiceCrMemoHeader.IsEmpty() then
            exit;

        VATDateDataTransfer.SetTables(Database::"Service Invoice Header", Database::"Service Invoice Header");
        VATDateDataTransfer.AddFieldValue(ServiceInvHeader.FieldNo("Posting Date"), ServiceInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Service Cr.Memo Header", Database::"Service Cr.Memo Header");
        VATDateDataTransfer.AddFieldValue(ServiceCrMemoHeader.FieldNo("Posting Date"), ServiceCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(GetVATDateFieldServiceUpgrade());
    end;

    local procedure UpdateServiceBlankEntries()
    var
        GLSetup: Record Microsoft.Finance.GeneralLedger.Setup."General Ledger Setup";
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Service Invoice Header", Database::"Service Invoice Header");
        VATDateDataTransfer.AddSourceFilter(ServiceInvHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(ServiceInvHeader.FieldNo("Posting Date"), ServiceInvHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(ServiceInvHeader.FieldNo("Document Date"), ServiceInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Service Cr.Memo Header", Database::"Service Cr.Memo Header");
        VATDateDataTransfer.AddSourceFilter(ServiceCrMemoHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(ServiceCrMemoHeader.FieldNo("Posting Date"), ServiceCrMemoHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(ServiceCrMemoHeader.FieldNo("Document Date"), ServiceCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;

    local procedure EnableDeleteFiledContractsWithRelatedMainContract()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SkipUpgrade: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag()) then
            exit;

        if not ServiceMgtSetup.Get() then begin
            Session.LogMessage('0000NGU', ServiceMgtSetupDoesNotExistLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
            SkipUpgrade := true;
        end;

        if not SkipUpgrade then
            if ServiceMgtSetup."Del. Filed Cont. w. main Cont." then begin
                Session.LogMessage('0000NGV', StrSubstNo(DeleteFiledContractsWithRelatedMainContractAlreadySetErr, ServiceMgtSetup.FieldName("Del. Filed Cont. w. main Cont.")), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
                SkipUpgrade := true;
            end else begin
                ServiceMgtSetup."Del. Filed Cont. w. main Cont." := true;
                ServiceMgtSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag());
    end;

    // Upgrade definitions

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetVATDateFieldServiceUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldServiceBlankUpgrade());
        PerCompanyUpgradeTags.Add(GetServiceItemWorksheetSelectionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Microsoft.Foundation.Company."Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure SetDefaultsOnCompanyInitialize()
    begin
        if not UpgradeTag.HasUpgradeTag(GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag());
    end;

    procedure GetVATDateFieldServiceUpgrade(): Code[250]
    begin
        exit('MS-447067-GetVATDateFieldServiceUpgrade-20220830');
    end;

    internal procedure GetVATDateFieldServiceBlankUpgrade(): Code[250]
    begin
        exit('MS-465444-GetVATDateFieldServiceBlankUpgrade-20230301');
    end;

    internal procedure GetServiceItemWorksheetSelectionUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-840-ServiceItemWorksheetSelection-20240719');
    end;

    internal procedure GetEnableDeleteFiledContractsWithRelatedMainContractUpgradeTag(): Code[250]
    begin
        exit('MS-366089-EnableDeleteFiledContractsWithRelatedMainContractUpgradeTag-20241001');
    end;
}
