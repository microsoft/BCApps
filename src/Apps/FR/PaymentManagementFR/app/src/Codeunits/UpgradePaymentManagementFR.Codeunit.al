#if CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Reflection;
using System.Upgrade;

codeunit 10840 "Upgrade Payment Management FR"
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        UpgradePayment();
    end;

    local procedure UpgradePayment()
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag()) then
            exit;

        TransferFields(Database::"Bank Account", 10805, 10851); //  10805 - the existing field "Agency Code", 10851 - the new field "Agency Code FR"; 
        TransferFields(Database::"Bank Account", 10806, 10852); // 10806 - the existing field "RIB Key", 10852 - the new field "RIB Key FR"; 
        TransferFields(Database::"Bank Account", 10807, 10853); // 10807 - the existing field "RIB Checked", 10853 - the new field "RIB Checked FR",; 
        TransferFields(Database::"Customer Bank Account", 10805, 10851); // 10805 - the existing field "Agency Code", 10851 - the new field "Agency Code FR",; 
        TransferFields(Database::"Customer Bank Account", 10806, 10852); //, 10806 - the existing field "RIB Key", 10852 - the new field "RIB Key FR"; 
        TransferFields(Database::"Customer Bank Account", 10807, 10853); // 10807 - the existing field "RIB Checked", 10853 - the new field "RIB Checked FR";
        TransferFields(Database::"Vendor Bank Account", 10805, 10851); // 10805 - the existing field "Agency Code", 10851 - the new field "Agency Code FR"; 
        TransferFields(Database::"Vendor Bank Account", 10806, 10852); // 10806 - the existing field "RIB Key", 10852 - the new field "RIB Key FR"; 
        TransferFields(Database::"Vendor Bank Account", 10807, 10853); // 10807 - the existing field "RIB Checked", 10853 - the new field "RIB Checked FR";
        TransferRecords(Database::"Bank Account Buffer", Database::"Bank Account Buffer FR");
        TransferRecords(Database::"Payment Class", Database::"Payment Class FR");
        TransferRecords(Database::"Payment Header", Database::"Payment Header FR");
        TransferRecords(Database::"Payment Header Archive", Database::"Payment Header Archive FR");
        TransferRecords(Database::"Payment Line", Database::"Payment Line FR");
        TransferRecords(Database::"Payment Line Archive", Database::"Payment Line Archive FR");
        TransferRecords(Database::"Payment Post. Buffer", Database::"Payment Post. Buffer FR");
        TransferRecords(Database::"Payment Status", Database::"Payment Status FR");
        TransferRecords(Database::"Payment Step", Database::"Payment Step FR");
        TransferRecords(Database::"Payment Step Ledger", Database::"Payment Step Ledger FR");
        TransferRecords(Database::"Payment Address", Database::"Payment Address FR");

        RemapPaymentStepObjectIDs();

        UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag());
    end;

    local procedure RemapPaymentStepObjectIDs()
    var
        PaymentStepFR: Record "Payment Step FR";
        ReportMap: Dictionary of [Integer, Integer];
        XmlPortMap: Dictionary of [Integer, Integer];
        LegacyReportNo: Integer;
        LegacyExportNo: Integer;
    begin
        BuildPaymentStepObjectIDMaps(ReportMap, XmlPortMap);

        if PaymentStepFR.FindSet(true) then
            repeat
                LegacyReportNo := PaymentStepFR."Report No.";
                LegacyExportNo := PaymentStepFR."Export No.";

                case PaymentStepFR."Action Type" of
                    PaymentStepFR."Action Type"::Report:
                        if ReportMap.ContainsKey(LegacyReportNo) then
                            PaymentStepFR."Report No." := ReportMap.Get(LegacyReportNo);
                    PaymentStepFR."Action Type"::File:
                        case PaymentStepFR."Export Type" of
                            PaymentStepFR."Export Type"::Report:
                                if ReportMap.ContainsKey(LegacyExportNo) then
                                    PaymentStepFR."Export No." := ReportMap.Get(LegacyExportNo);
                            PaymentStepFR."Export Type"::XMLport:
                                if XmlPortMap.ContainsKey(LegacyExportNo) then
                                    PaymentStepFR."Export No." := XmlPortMap.Get(LegacyExportNo);
                        end;
                end;

                OnAfterRemapPaymentStepObjectIDs(PaymentStepFR, LegacyReportNo, LegacyExportNo);

                PaymentStepFR.Modify();
            until PaymentStepFR.Next() = 0;
    end;

    local procedure BuildPaymentStepObjectIDMaps(var ReportMap: Dictionary of [Integer, Integer]; var XmlPortMap: Dictionary of [Integer, Integer])
    begin
        ReportMap.Set(10843, 10846); // Recapitulation Form
        ReportMap.Set(10860, 10845); // Payment List
        ReportMap.Set(10862, 10850); // Suggest Vendor Payments FR
        ReportMap.Set(10864, 10849); // Suggest Customer Payments
        ReportMap.Set(10865, 10834); // Bill
        ReportMap.Set(10866, 10836); // Draft
        ReportMap.Set(10867, 10847); // Remittance
        ReportMap.Set(10868, 10837); // Draft notice
        ReportMap.Set(10869, 10838); // Draft recapitulation
        ReportMap.Set(10870, 10852); // Withdraw notice
        ReportMap.Set(10871, 10853); // Withdraw recapitulation
        ReportMap.Set(10872, 10839); // Duplicate parameter
        ReportMap.Set(10873, 10831); // Archive Payment Slips
        ReportMap.Set(10880, 10840); // ETEBAC Files
        ReportMap.Set(10881, 10851); // Withdraw
        ReportMap.Set(10883, 10848); // SEPA ISO20022

        XmlPortMap.Set(10863, 10831); // Import/Export Parameters
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRemapPaymentStepObjectIDs(var PaymentStepFR: Record "Payment Step FR"; LegacyReportNo: Integer; LegacyExportNo: Integer)
    begin
    end;

    procedure TransferRecords(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceField: Record Field;
        SourceRecRef: RecordRef;
        TargetRecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        SourceFieldRefNo: Integer;
    begin
        SourceRecRef.Open(SourceTableId, false);
        TargetRecRef.Open(TargetTableId, false);

        if SourceRecRef.IsEmpty() then
            exit;

        SourceRecRef.FindSet();

        repeat
            Clear(SourceField);
            SourceField.SetRange(TableNo, SourceTableId);
            SourceField.SetRange(Class, SourceField.Class::Normal);
            SourceField.SetRange(Enabled, true);
            if SourceField.Findset() then
                repeat
                    SourceFieldRefNo := SourceField."No.";
                    SourceFieldRef := SourceRecRef.Field(SourceFieldRefNo);
                    TargetFieldRef := TargetRecRef.Field(SourceFieldRefNo);
                    TargetFieldRef.VALUE := SourceFieldRef.VALUE;
                until SourceField.Next() = 0;
            TargetRecRef.Insert();
        until SourceRecRef.Next() = 0;
        SourceRecRef.Close();
        TargetRecRef.Close();
    end;

    procedure TransferFields(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
        TargetFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        RecRef.Open(TableId, false);
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        SourceFieldRef.SetFilter('<>%1', '');

        if RecRef.FindSet() then
            repeat
                TargetFieldRef := RecRef.Field(TargetFieldNo);
                TargetFieldRef.VALUE := SourceFieldRef.VALUE;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
    end;
}
#endif