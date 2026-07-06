#if not CLEAN28
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
    ObsoleteTag = '28.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        DescriptionTxt: Label 'Existing records in FR BaseApp fields will be copied to Sales FR App fields';

    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        if TempDocumentEntry.IsEmpty() then begin
            SetUpgradeTag(false);
            exit(false);
        end;
        exit(true);
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
    begin
        UpdateFeatureDataUpdateStatus.SetRange("Feature Key", FeatureDataUpdateStatus."Feature Key");
        UpdateFeatureDataUpdateStatus.SetFilter("Company Name", '<>%1', FeatureDataUpdateStatus."Company Name");
        UpdateFeatureDataUpdateStatus.ModifyAll("Feature Status", FeatureDataUpdateStatus."Feature Status");

        SetUpgradeTag(true);
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
        Customer: Record Customer;
        Contact: Record Contact;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if Customer.FindSet() then
            repeat
                Customer."SIREN No. FR" := Customer."SIREN No.";
                Customer.Modify();
            until Customer.Next() = 0;

        if Contact.FindSet() then
            repeat
                Contact."SIREN No. FR" := Contact."SIREN No.";
                Contact.Modify();
            until Contact.Next() = 0;

        if SalesCrMemoHeader.FindSet() then
            repeat
                SalesCrMemoHeader."VAT Paid on Debits FR" := SalesCrMemoHeader."VAT Paid on Debits";
                SalesCrMemoHeader.Modify();
            until SalesCrMemoHeader.Next() = 0;

        if SalesHeader.FindSet() then
            repeat
                SalesHeader."VAT Paid on Debits FR" := SalesHeader."VAT Paid on Debits";
                SalesHeader.Modify();
            until SalesHeader.Next() = 0;

        if SalesInvoiceHeader.FindSet() then
            repeat
                SalesInvoiceHeader."VAT Paid on Debits FR" := SalesInvoiceHeader."VAT Paid on Debits";
                SalesInvoiceHeader.Modify();
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
    begin
        // Set the upgrade tag to indicate that the data update is executed/skipped and the feature is enabled.
        // This is needed when the feature is enabled by default in a future version, to skip the data upgrade.
        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag()) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRUpgradeTag());
        if not DataUpgradeExecuted then
            UpgradeTag.SetSkippedUpgrade(UpgTagSalesFR.GetSalesFRUpgradeTag(), true);
    end;
}
#endif
