#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Navigate;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 10812 "Feature - Sales FR" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = TableData "Feature Data Update Status" = rm;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature Sales FR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        DescriptionTxt: Label 'Existing records in FR BaseApp fields will be copied to Sales FR App fields';

    procedure IsDataUpdateRequired(): Boolean;
    var
        SalesFR: Codeunit "Sales FR";
    begin
        SalesFR.LogFeatureDiscovered();
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty());
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
    var
        UpdateFeatureDataUpdateStatus: Record "Feature Data Update Status";
        SalesFR: Codeunit "Sales FR";
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");

        SetUpgradeTag();
        SalesFR.LogFeatureSetUp();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        StartDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Sales FR', StartDateTime);
        UpgradeSalesFR();
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Sales FR', EndDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure CountRecords()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        TempDocumentEntry.Reset();
        TempDocumentEntry.DeleteAll();

        InsertDocumentEntry(Database::Customer, Customer.TableCaption, Customer.Count());
        InsertDocumentEntry(Database::Contact, Contact.TableCaption, Contact.Count());
        InsertDocumentEntry(Database::"Sales Cr.Memo Header", SalesCrMemoHeader.TableCaption, SalesCrMemoHeader.Count());
        InsertDocumentEntry(Database::"Sales Header", SalesHeader.TableCaption, SalesHeader.Count());
        InsertDocumentEntry(Database::"Sales Invoice Header", SalesInvoiceHeader.TableCaption, SalesInvoiceHeader.Count());
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

    local procedure UpgradeSalesFR()
    var
        SalesFRHelperProcedures: Codeunit "Sales FR Helper Procedures";
    begin
        SalesFRHelperProcedures.TransferFields(Database::Customer, 10805, 10806, ''); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        SalesFRHelperProcedures.TransferFields(Database::Contact, 10805, 10806, ''); // 10805 - the existing field "SIREN No.", 10806 - the new field "SIREN No. FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Cr.Memo Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
        SalesFRHelperProcedures.TransferFields(Database::"Sales Invoice Header", 10801, 10802, false); // 10801 - the existing field "VAT Paid on Debits", 10802 - the new field "VAT Paid on Debits FR";
    end;

    local procedure SetUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        // Set the upgrade tag only after the data update has actually run, so that the version 31
        // upgrade does not copy the data a second time. The tag is deliberately not set when the
        // feature is enabled without a data update, because records created while the feature is
        // still off must be migrated by the version 31 upgrade.
        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag());
    end;
}
#endif
