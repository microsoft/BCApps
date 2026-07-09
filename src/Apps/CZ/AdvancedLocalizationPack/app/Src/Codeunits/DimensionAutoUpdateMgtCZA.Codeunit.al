// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Bank.BankAccount;
using Microsoft.CashFlow.Setup;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Diagnostics;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Utilities;

codeunit 31395 "Dimension Auto.Update Mgt. CZA"
{
    Permissions = TableData "Dimension Value" = rim,
                  TableData "Default Dimension" = r;
    SingleInstance = true;

    var
        TempChangeLogSetupTable: Record "Change Log Setup (Table)" temporary;
        TempDefaultDimension: Record "Default Dimension" temporary;
        TempAutoCreateDimAllObjWithCaption: Record AllObjWithCaption temporary;
        DimChangeSetupRead: Boolean;
        RunEmployeeOnAfterInsertEvent: Boolean;
        RunCustomerOnAfterInsertEvent: Boolean;
        RunVendorOnAfterInsertEvent: Boolean;
        RunItemOnAfterInsertEvent: Boolean;
        RunGLAccountOnAfterInsertEvent: Boolean;
        RunResourceOnAfterInsertEvent: Boolean;
        RunResourceGroupOnAfterInsertEvent: Boolean;
        RunJobOnAfterInsertEvent: Boolean;
        RunBankAccountOnAfterInsertEvent: Boolean;
        RunFixedAssetOnAfterInsertEvent: Boolean;
        RunInsuranceOnAfterInsertEvent: Boolean;
        RunResponsibilityCenterOnAfterInsertEvent: Boolean;
        RunSalespersonPurchaserOnAfterInsertEvent: Boolean;
        RunCampaignOnAfterInsertEvent: Boolean;
        RunCashFlowManualExpenseOnAfterInsertEvent: Boolean;
        RunCashFlowManualRevenueOnAfterInsertEvent: Boolean;
        RunVendorTemplOnAfterInsertEvent: Boolean;
        RunCustomerTemplOnAfterInsertEvent: Boolean;
        RunItemTemplOnAfterInsertEvent: Boolean;
        RunEmployeeTemplOnAfterInsertEvent: Boolean;
        RunWorkCenterOnAfterInsertEvent: Boolean;
        RunItemChargeOnAfterInsertEvent: Boolean;
        RunEmployeeOnAfterRenameEvent: Boolean;
        RunCustomerOnAfterRenameEvent: Boolean;
        RunVendorOnAfterRenameEvent: Boolean;
        RunItemOnAfterRenameEvent: Boolean;
        RunGLAccountOnAfterRenameEvent: Boolean;
        RunResourceOnAfterRenameEvent: Boolean;
        RunResourceGroupOnAfterRenameEvent: Boolean;
        RunJobOnAfterRenameEvent: Boolean;
        RunBankAccountOnAfterRenameEvent: Boolean;
        RunFixedAssetOnAfterRenameEvent: Boolean;
        RunInsuranceOnAfterRenameEvent: Boolean;
        RunResponsibilityCenterOnAfterRenameEvent: Boolean;
        RunSalespersonPurchaserOnAfterRenameEvent: Boolean;
        RunCampaignOnAfterRenameEvent: Boolean;
        RunCashFlowManualExpenseOnAfterRenameEvent: Boolean;
        RunCashFlowManualRevenueOnAfterRenameEvent: Boolean;
        RunVendorTemplOnAfterRenameEvent: Boolean;
        RunCustomerTemplOnAfterRenameEvent: Boolean;
        RunItemTemplOnAfterRenameEvent: Boolean;
        RunEmployeeTemplOnAfterRenameEvent: Boolean;
        RunWorkCenterOnAfterRenameEvent: Boolean;
        RunItemChargeOnAfterRenameEvent: Boolean;
        SkipRenameLinkedMasterRecord: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if CompanyName = '' then
            exit;

        CheckChangeSetupRead();

        if TempChangeLogSetupTable.Get(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;

        if TempAutoCreateDimAllObjWithCaption.Get(TempAutoCreateDimAllObjWithCaption."Object Type"::Table, TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseRename := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure DimensionInsert(RecRef: RecordRef)
    var
        DimensionAutoCreateMgtCZA: Codeunit "Dimension Auto.Create Mgt. CZA";
        PrimaryKeyFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if RecRef.IsTemporary then
            exit;

        if RecRef.Number = Database::"Default Dimension" then
            ClearSetup();
        CheckChangeSetupRead();

        if TempAutoCreateDimAllObjWithCaption.Get(TempAutoCreateDimAllObjWithCaption."Object Type"::Table, RecRef.Number) then begin
            PrimaryKeyRef := RecRef.KeyIndex(1);
            PrimaryKeyFieldRef := PrimaryKeyRef.FieldIndex(1);
            DimensionAutoCreateMgtCZA.AutoCreateDimension(RecRef.Number, format(PrimaryKeyFieldRef.Value));
        end;

        if not TempChangeLogSetupTable.Get(RecRef.Number) then
            exit;

        UpdateDimensionValue(RecRef, RecRef, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"GlobalTriggerManagement", 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure DimensionModify(RecRef: RecordRef)
    var
        xRecRef: RecordRef;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if RecRef.IsTemporary then
            exit;

        if RecRef.Number = Database::"Default Dimension" then
            ClearSetup();
        CheckChangeSetupRead();
        if not TempChangeLogSetupTable.Get(RecRef.Number) then
            exit;

        if not xRecRef.Get(RecRef.RecordId) then
            xRecRef := RecRef;

        UpdateDimensionValue(RecRef, xRecRef, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseRename', '', false, false)]
    local procedure HandleMasterRecordRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        OldPKFieldRef: FieldRef;
        NewPKFieldRef: FieldRef;
        OldNo: Text;
        NewNo: Text;
    begin
        if RecRef.IsTemporary() then
            exit;
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;
        if RecRef.Number = Database::"Dimension Value" then
            exit;
        if RecRef.Number = Database::"Default Dimension" then
            exit;
        CheckChangeSetupRead();
        if not TempAutoCreateDimAllObjWithCaption.Get(TempAutoCreateDimAllObjWithCaption."Object Type"::Table, RecRef.Number) then
            exit;

        OldPKFieldRef := xRecRef.KeyIndex(1).FieldIndex(1);
        NewPKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
        OldNo := Format(OldPKFieldRef.Value);
        NewNo := Format(NewPKFieldRef.Value);
        if OldNo = NewNo then
            exit;

        SkipRenameLinkedMasterRecord := false;
        RenameLinkedDimensionValues(RecRef, xRecRef, OldNo, NewNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnAfterRenameEvent', '', false, false)]
    local procedure HandleDimensionValueRename(var Rec: Record "Dimension Value"; var xRec: Record "Dimension Value"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not GuiAllowed() then
            exit;
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;
        if Rec.Code = xRec.Code then
            exit;

        RenameLinkedMasterRecords(Rec."Dimension Code", xRec.Code, Rec.Code);
    end;

    local procedure RenameLinkedDimensionValues(var RecRef: RecordRef; var xRecRef: RecordRef; OldNo: Text; NewNo: Text)
    var
        DefaultDimension: Record "Default Dimension";
        CardDefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        TempCandidateDimensionValue: Record "Dimension Value" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        NewPKFieldRef: FieldRef;
        IsHandled: Boolean;
        RenameDimensionValueQst: Label 'A dimension value with the same code is set on this card. Do you also want to rename the dimension value %1 ''%2'' to ''%3''?', Comment = '%1 = Dimension Code, %2 = Old Code, %3 = New Code';
    begin
        IsHandled := false;
        OnBeforeRenameLinkedDimensionValues(RecRef, xRecRef, OldNo, NewNo, SkipRenameLinkedMasterRecord, IsHandled);
        if IsHandled then
            exit;

        SkipRenameLinkedMasterRecord := false;
        SetRequestRunOnAfterRenameEventByTable(RecRef.Number, false);
        NewPKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
        if not xRecRef.Get(xRecRef.RecordId) then
            exit;

        DefaultDimension.SetRange("Table ID", RecRef.Number);
        DefaultDimension.SetRange("No.", '');
        DefaultDimension.SetRange("Automatic Create CZA", true);
        if DefaultDimension.FindSet() then
            repeat
                if CardDefaultDimension.Get(RecRef.Number, NewNo, DefaultDimension."Dimension Code") then
                    if CardDefaultDimension."Dimension Value Code" = OldNo then
                        if DimensionValue.Get(DefaultDimension."Dimension Code", OldNo) then begin
                            TempCandidateDimensionValue := DimensionValue;
                            if TempCandidateDimensionValue.Insert() then;
                        end;
            until DefaultDimension.Next() = 0;

        if TempCandidateDimensionValue.FindSet() then
            repeat
                if DimensionValue.Get(TempCandidateDimensionValue."Dimension Code", OldNo) then
                    if ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(RenameDimensionValueQst, TempCandidateDimensionValue."Dimension Code", OldNo, NewNo), false)
                    then begin
                        SkipRenameLinkedMasterRecord := true;
                        DimensionValue.Rename(TempCandidateDimensionValue."Dimension Code", NewNo);
                        NewPKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
                        if Format(NewPKFieldRef.Value) <> NewNo then
                            NewPKFieldRef.Value := NewNo;
                        SetRequestRunOnAfterRenameEventByTable(RecRef.Number, true);
                        UpdateDimensionValue(RecRef, xRecRef, false);
                        if not xRecRef.Get(xRecRef.RecordId) then
                            xRecRef := RecRef;
                    end else begin
                        NewPKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
                        if Format(NewPKFieldRef.Value) <> NewNo then
                            NewPKFieldRef.Value := NewNo;
                    end;
            until TempCandidateDimensionValue.Next() = 0;
    end;

    local procedure RenameLinkedMasterRecords(DimensionCode: Code[20]; OldNo: Text; NewNo: Text)
    var
        DefaultDimension: Record "Default Dimension";
        AllObjWithCaption: Record AllObjWithCaption;
        TempCandidate: Record AllObjWithCaption temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        PKFieldRef: FieldRef;
        TableCaption: Text;
        IsHandled: Boolean;
        RenameMasterRecordQst: Label 'A %1 ''%2'' is linked to this dimension value. Do you also want to rename it to ''%3''?', Comment = '%1 = Table Caption, %2 = Old Code, %3 = New Code';
    begin
        IsHandled := false;
        OnBeforeRenameLinkedMasterRecord(DimensionCode, OldNo, NewNo, SkipRenameLinkedMasterRecord, IsHandled);
        if IsHandled then
            exit;

        if SkipRenameLinkedMasterRecord then begin
            SkipRenameLinkedMasterRecord := false;
            exit;
        end;

        DefaultDimension.SetRange("Dimension Code", DimensionCode);
        DefaultDimension.SetRange("No.", '');
        DefaultDimension.SetRange("Automatic Create CZA", true);
        if DefaultDimension.FindSet() then
            repeat
                Clear(RecRef);
                RecRef.Open(DefaultDimension."Table ID");
                PKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
                PKFieldRef.SetRange(OldNo);
                if RecRef.FindFirst() then begin
                    if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, DefaultDimension."Table ID") then
                        TableCaption := AllObjWithCaption."Object Caption"
                    else
                        TableCaption := RecRef.Caption();
                    if not TempCandidate.Get(TempCandidate."Object Type"::Table, DefaultDimension."Table ID") then begin
                        TempCandidate.Init();
                        TempCandidate."Object Type" := TempCandidate."Object Type"::Table;
                        TempCandidate."Object ID" := DefaultDimension."Table ID";
                        TempCandidate."Object Caption" := CopyStr(TableCaption, 1, MaxStrLen(TempCandidate."Object Caption"));
                        TempCandidate.Insert();
                    end;
                end;
                RecRef.Close();
            until DefaultDimension.Next() = 0;

        if TempCandidate.FindSet() then
            repeat
                Clear(RecRef);
                RecRef.Open(TempCandidate."Object ID");
                PKFieldRef := RecRef.KeyIndex(1).FieldIndex(1);
                PKFieldRef.SetRange(OldNo);
                if RecRef.FindFirst() then
                    if ConfirmManagement.GetResponseOrDefault(
                        StrSubstNo(RenameMasterRecordQst, TempCandidate."Object Caption", OldNo, NewNo), false)
                    then begin
                        xRecRef := RecRef;
                        RecRef.Rename(NewNo);
                        UpdateDimensionValue(RecRef, xRecRef, false);
                    end;
                RecRef.Close();
            until TempCandidate.Next() = 0;
    end;

    local procedure UpdateDimensionValue(DimValRecordRef: RecordRef; XDimValRecordRef: RecordRef; IsInsert: Boolean)
    var
        DimensionValue: Record "Dimension Value";
        RecField: Record "Field";
        DescrFieldRef: FieldRef;
        OldDescrFieldRef: FieldRef;
        PrimaryKeyFieldRef: FieldRef;
        PrimaryKeyRef: KeyRef;
        TempValueText: Text;
        OldTempValueText: Text;
        IsUpdate: Boolean;
    begin
        TempDefaultDimension.Reset();
        TempDefaultDimension.SetRange("Table ID", DimValRecordRef.Number);
        TempDefaultDimension.SetRange("Automatic Create CZA", true);
        TempDefaultDimension.SetRange("No.", '');
        TempDefaultDimension.SetFilter("Dim. Description Field ID CZA", '<>%1', 0);
        TempDefaultDimension.SetFilter("Dim. Description Update CZA", '<>%1', TempDefaultDimension."Dim. Description Update CZA"::" ");
        if TempDefaultDimension.FindSet(false) then
            repeat
                IsUpdate := false;
                DescrFieldRef := DimValRecordRef.Field(TempDefaultDimension."Dim. Description Field ID CZA");
                PrimaryKeyRef := DimValRecordRef.KeyIndex(1);
                PrimaryKeyFieldRef := PrimaryKeyRef.FieldIndex(1);
                if DimensionValue.Get(TempDefaultDimension."Dimension Code", Format(PrimaryKeyFieldRef.Value)) then begin
                    if RecField.Get(TempDefaultDimension."Table ID", TempDefaultDimension."Dim. Description Field ID CZA") then
                        if RecField.Class = RecField.Class::FlowField then
                            DescrFieldRef.CalcField();
                    TempValueText := Format(DescrFieldRef.Value);
                    if TempDefaultDimension."Dim. Description Format CZA" <> '' then
                        TempValueText := StrSubstNo(TempDefaultDimension."Dim. Description Format CZA", TempValueText);
                    if TempValueText <> '' then
                        TempValueText := CopyStr(TempValueText, 1, MaxStrLen(DimensionValue.Name));
                    if TempDefaultDimension."Dim. Description Update CZA" = TempDefaultDimension."Dim. Description Update CZA"::Create then
                        if (DimensionValue.Name = '') or IsInsert then
                            IsUpdate := true
                        else begin
                            OldDescrFieldRef := XDimValRecordRef.Field(TempDefaultDimension."Dim. Description Field ID CZA");
                            if RecField.Get(TempDefaultDimension."Table ID", TempDefaultDimension."Dim. Description Field ID CZA") then
                                if RecField.Class = RecField.Class::FlowField then
                                    OldDescrFieldRef.CalcField();
                            OldTempValueText := Format(OldDescrFieldRef.Value);
                            if TempDefaultDimension."Dim. Description Format CZA" <> '' then
                                OldTempValueText := StrSubstNo(TempDefaultDimension."Dim. Description Format CZA", OldTempValueText);
                            if OldTempValueText <> '' then
                                OldTempValueText := CopyStr(OldTempValueText, 1, MaxStrLen(DimensionValue.Name));
                            IsUpdate := DimensionValue.Name = OldTempValueText;
                        end
                    else
                        IsUpdate := true;
                    if (DimensionValue.Name <> TempValueText) and IsUpdate then begin
                        DimensionValue.Name := CopyStr(TempValueText, 1, MaxStrLen(DimensionValue.Name));
                        DimensionValue.Modify();
                    end;
                end;
            until TempDefaultDimension.Next() = 0;
    end;

    local procedure CheckChangeSetupRead()
    var
        SystemInitialization: Codeunit "System Initialization";
    begin
        if SystemInitialization.IsInProgress() then
            exit;
        if not DimChangeSetupRead then begin
            ReadSetup();
            DimChangeSetupRead := true;
        end;
    end;

    local procedure ReadSetup()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        DefaultDimension: Record "Default Dimension";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DefaultDimension.SetRange("Automatic Create CZA", true);
        DefaultDimension.SetRange("No.", '');
        DefaultDimension.SetFilter("Dim. Description Field ID CZA", '<>%1', 0);
        DefaultDimension.SetFilter("Dim. Description Update CZA", '<>%1', DefaultDimension."Dim. Description Update CZA"::" ");
        if DefaultDimension.FindSet(false) then
            repeat
                if not TempChangeLogSetupTable.Get(DefaultDimension."Table ID") then begin
                    TempChangeLogSetupTable."Table No." := DefaultDimension."Table ID";
                    TempChangeLogSetupTable.Insert();
                end;
                TempDefaultDimension := DefaultDimension;
                TempDefaultDimension.Insert();
            until DefaultDimension.Next() = 0;

        DefaultDimension.SetRange("Dim. Description Field ID CZA");
        DefaultDimension.SetRange("Dim. Description Update CZA");
        if DefaultDimension.FindSet(false) then
            repeat
                if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, DefaultDimension."Table ID") then
                    DimensionManagement.DefaultDimInsertTempObject(TempAutoCreateDimAllObjWithCaption, DefaultDimension."Table ID");
            until DefaultDimension.Next() = 0;
    end;

    internal procedure ForceSetDimChangeSetupRead()
    begin
        ClearSetup();
    end;

    local procedure ClearSetup()
    begin
        TempChangeLogSetupTable.Reset();
        TempChangeLogSetupTable.DeleteAll(false);
        TempDefaultDimension.Reset();
        TempDefaultDimension.DeleteAll(false);
        TempAutoCreateDimAllObjWithCaption.Reset();
        TempAutoCreateDimAllObjWithCaption.DeleteAll(false);
        DimChangeSetupRead := false;
    end;

    internal procedure SetRequestRunEmployeeOnAfterInsertEvent(SetRunEmployeeOnAfterInsertEvent: Boolean)
    begin
        RunEmployeeOnAfterInsertEvent := SetRunEmployeeOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunEmployeeOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunEmployeeOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunCustomerOnAfterInsertEvent(SetRunCustomerOnAfterInsertEvent: Boolean)
    begin
        RunCustomerOnAfterInsertEvent := SetRunCustomerOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunCustomerOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunCustomerOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunVendorOnAfterInsertEvent(SetRunVendorOnAfterInsertEvent: Boolean)
    begin
        RunVendorOnAfterInsertEvent := SetRunVendorOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunVendorOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunVendorOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunItemOnAfterInsertEvent(SetRunItemOnAfterInsertEvent: Boolean)
    begin
        RunItemOnAfterInsertEvent := SetRunItemOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunItemOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunItemOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunGLAccountOnAfterInsertEvent(SetRunGLAccountOnAfterInsertEvent: Boolean)
    begin
        RunGLAccountOnAfterInsertEvent := SetRunGLAccountOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunGLAccountOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunGLAccountOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunResourceOnAfterInsertEvent(SetRunResourceOnAfterInsertEvent: Boolean)
    begin
        RunResourceOnAfterInsertEvent := SetRunResourceOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunResourceOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunResourceOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunResourcegroupOnAfterInsertEvent(SetRunResourceGroupOnAfterInsertEvent: Boolean)
    begin
        RunResourceGroupOnAfterInsertEvent := SetRunResourceGroupOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunResourceGroupOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunResourceGroupOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunJobOnAfterInsertEvent(SetRunJobOnAfterInsertEvent: Boolean)
    begin
        RunJobOnAfterInsertEvent := SetRunJobOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunJobOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunJobOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunBankAccountOnAfterInsertEvent(SetRunBankAccountOnAfterInsertEvent: Boolean)
    begin
        RunBankAccountOnAfterInsertEvent := SetRunBankAccountOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunBankAccountOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunBankAccountOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunFixedAssetOnAfterInsertEvent(SetRunFixedAssetOnAfterInsertEvent: Boolean)
    begin
        RunFixedAssetOnAfterInsertEvent := SetRunFixedAssetOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunFixedAssetOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunFixedAssetOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunInsuranceOnAfterInsertEvent(SetRunInsuranceOnAfterInsertEvent: Boolean)
    begin
        RunInsuranceOnAfterInsertEvent := SetRunInsuranceOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunInsuranceOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunInsuranceOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunResponsibilityCenterOnAfterInsertEvent(SetRunResponsibilityCenterOnAfterInsertEvent: Boolean)
    begin
        RunResponsibilityCenterOnAfterInsertEvent := SetRunResponsibilityCenterOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunResponsibilityCenterOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunResponsibilityCenterOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunSalespersonPurchaserOnAfterInsertEvent(SetRunSalespersonPurchaserOnAfterInsertEvent: Boolean)
    begin
        RunSalespersonPurchaserOnAfterInsertEvent := SetRunSalespersonPurchaserOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunSalespersonPurchaserOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunSalespersonPurchaserOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunCampaignOnAfterInsertEvent(SetRunCampaignOnAfterInsertEvent: Boolean)
    begin
        RunCampaignOnAfterInsertEvent := SetRunCampaignOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunCampaignOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunCampaignOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunCashFlowManualExpenseOnAfterInsertEvent(SetRunCashFlowManualExpenseOnAfterInsertEvent: Boolean)
    begin
        RunCashFlowManualExpenseOnAfterInsertEvent := SetRunCashFlowManualExpenseOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunCashFlowManualExpenseOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunCashFlowManualExpenseOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunCashFlowManualRevenueOnAfterInsertEvent(SetRunCashFlowManualRevenueOnAfterInsertEvent: Boolean)
    begin
        RunCashFlowManualRevenueOnAfterInsertEvent := SetRunCashFlowManualRevenueOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunCashFlowManualRevenueOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunCashFlowManualRevenueOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunVendorTemplOnAfterInsertEvent(SetRunVendorTemplOnAfterInsertEvent: Boolean)
    begin
        RunVendorTemplOnAfterInsertEvent := SetRunVendorTemplOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunVendorTemplOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunVendorTemplOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunCustomerTemplOnAfterInsertEvent(SetRunCustomerTemplOnAfterInsertEvent: Boolean)
    begin
        RunCustomerTemplOnAfterInsertEvent := SetRunCustomerTemplOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunCustomerTemplOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunCustomerTemplOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunItemTemplOnAfterInsertEvent(SetRunItemTemplOnAfterInsertEvent: Boolean)
    begin
        RunItemTemplOnAfterInsertEvent := SetRunItemTemplOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunItemTemplOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunItemTemplOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunEmployeeTemplOnAfterInsertEvent(SetRunEmployeeTemplOnAfterInsertEvent: Boolean)
    begin
        RunEmployeeTemplOnAfterInsertEvent := SetRunEmployeeTemplOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunEmployeeTemplOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunEmployeeTemplOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunWorkCenterOnAfterInsertEvent(SetRunWorkCenterOnAfterInsertEvent: Boolean)
    begin
        RunWorkCenterOnAfterInsertEvent := SetRunWorkCenterOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunWorkCenterOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunWorkCenterOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunItemChargeOnAfterInsertEvent(SetRunItemChargeOnAfterInsertEvent: Boolean)
    begin
        RunItemChargeOnAfterInsertEvent := SetRunItemChargeOnAfterInsertEvent;
    end;

    internal procedure IsRequestRunItemChargeOnAfterInsertEventDefaultDim(): Boolean
    begin
        exit(RunItemchargeOnAfterInsertEvent);
    end;

    internal procedure SetRequestRunEmployeeOnAfterRenameEvent(SetRunEmployeeOnAfterRenameEvent: Boolean)
    begin
        RunEmployeeOnAfterRenameEvent := SetRunEmployeeOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunEmployeeOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunEmployeeOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunCustomerOnAfterRenameEvent(SetRunCustomerOnAfterRenameEvent: Boolean)
    begin
        RunCustomerOnAfterRenameEvent := SetRunCustomerOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunCustomerOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunCustomerOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunVendorOnAfterRenameEvent(SetRunVendorOnAfterRenameEvent: Boolean)
    begin
        RunVendorOnAfterRenameEvent := SetRunVendorOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunVendorOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunVendorOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunItemOnAfterRenameEvent(SetRunItemOnAfterRenameEvent: Boolean)
    begin
        RunItemOnAfterRenameEvent := SetRunItemOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunItemOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunItemOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunGLAccountOnAfterRenameEvent(SetRunGLAccountOnAfterRenameEvent: Boolean)
    begin
        RunGLAccountOnAfterRenameEvent := SetRunGLAccountOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunGLAccountOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunGLAccountOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunResourceOnAfterRenameEvent(SetRunResourceOnAfterRenameEvent: Boolean)
    begin
        RunResourceOnAfterRenameEvent := SetRunResourceOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunResourceOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunResourceOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunResourceGroupOnAfterRenameEvent(SetRunResourceGroupOnAfterRenameEvent: Boolean)
    begin
        RunResourceGroupOnAfterRenameEvent := SetRunResourceGroupOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunResourceGroupOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunResourceGroupOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunJobOnAfterRenameEvent(SetRunJobOnAfterRenameEvent: Boolean)
    begin
        RunJobOnAfterRenameEvent := SetRunJobOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunJobOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunJobOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunBankAccountOnAfterRenameEvent(SetRunBankAccountOnAfterRenameEvent: Boolean)
    begin
        RunBankAccountOnAfterRenameEvent := SetRunBankAccountOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunBankAccountOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunBankAccountOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunFixedAssetOnAfterRenameEvent(SetRunFixedAssetOnAfterRenameEvent: Boolean)
    begin
        RunFixedAssetOnAfterRenameEvent := SetRunFixedAssetOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunFixedAssetOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunFixedAssetOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunInsuranceOnAfterRenameEvent(SetRunInsuranceOnAfterRenameEvent: Boolean)
    begin
        RunInsuranceOnAfterRenameEvent := SetRunInsuranceOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunInsuranceOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunInsuranceOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunResponsibilityCenterOnAfterRenameEvent(SetRunResponsibilityCenterOnAfterRenameEvent: Boolean)
    begin
        RunResponsibilityCenterOnAfterRenameEvent := SetRunResponsibilityCenterOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunResponsibilityCenterOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunResponsibilityCenterOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunSalespersonPurchaserOnAfterRenameEvent(SetRunSalespersonPurchaserOnAfterRenameEvent: Boolean)
    begin
        RunSalespersonPurchaserOnAfterRenameEvent := SetRunSalespersonPurchaserOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunSalespersonPurchaserOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunSalespersonPurchaserOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunCampaignOnAfterRenameEvent(SetRunCampaignOnAfterRenameEvent: Boolean)
    begin
        RunCampaignOnAfterRenameEvent := SetRunCampaignOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunCampaignOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunCampaignOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunCashFlowManualExpenseOnAfterRenameEvent(SetRunCashFlowManualExpenseOnAfterRenameEvent: Boolean)
    begin
        RunCashFlowManualExpenseOnAfterRenameEvent := SetRunCashFlowManualExpenseOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunCashFlowManualExpenseOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunCashFlowManualExpenseOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunCashFlowManualRevenueOnAfterRenameEvent(SetRunCashFlowManualRevenueOnAfterRenameEvent: Boolean)
    begin
        RunCashFlowManualRevenueOnAfterRenameEvent := SetRunCashFlowManualRevenueOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunCashFlowManualRevenueOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunCashFlowManualRevenueOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunVendorTemplOnAfterRenameEvent(SetRunVendorTemplOnAfterRenameEvent: Boolean)
    begin
        RunVendorTemplOnAfterRenameEvent := SetRunVendorTemplOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunVendorTemplOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunVendorTemplOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunCustomerTemplOnAfterRenameEvent(SetRunCustomerTemplOnAfterRenameEvent: Boolean)
    begin
        RunCustomerTemplOnAfterRenameEvent := SetRunCustomerTemplOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunCustomerTemplOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunCustomerTemplOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunItemTemplOnAfterRenameEvent(SetRunItemTemplOnAfterRenameEvent: Boolean)
    begin
        RunItemTemplOnAfterRenameEvent := SetRunItemTemplOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunItemTemplOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunItemTemplOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunEmployeeTemplOnAfterRenameEvent(SetRunEmployeeTemplOnAfterRenameEvent: Boolean)
    begin
        RunEmployeeTemplOnAfterRenameEvent := SetRunEmployeeTemplOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunEmployeeTemplOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunEmployeeTemplOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunWorkCenterOnAfterRenameEvent(SetRunWorkCenterOnAfterRenameEvent: Boolean)
    begin
        RunWorkCenterOnAfterRenameEvent := SetRunWorkCenterOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunWorkCenterOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunWorkCenterOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunItemChargeOnAfterRenameEvent(SetRunItemChargeOnAfterRenameEvent: Boolean)
    begin
        RunItemChargeOnAfterRenameEvent := SetRunItemChargeOnAfterRenameEvent;
    end;

    internal procedure IsRequestRunItemChargeOnAfterRenameEventDefaultDim(): Boolean
    begin
        exit(RunItemChargeOnAfterRenameEvent);
    end;

    internal procedure SetRequestRunOnAfterRenameEventByTable(TableID: Integer; RenameRequest: Boolean)
    begin
        case TableID of
            Database::Item:
                SetRequestRunItemOnAfterRenameEvent(RenameRequest);
            Database::Customer:
                SetRequestRunCustomerOnAfterRenameEvent(RenameRequest);
            Database::Vendor:
                SetRequestRunVendorOnAfterRenameEvent(RenameRequest);
            Database::Employee:
                SetRequestRunEmployeeOnAfterRenameEvent(RenameRequest);
            Database::"G/L Account":
                SetRequestRunGLAccountOnAfterRenameEvent(RenameRequest);
            Database::"Resource Group":
                SetRequestRunResourceGroupOnAfterRenameEvent(RenameRequest);
            Database::Resource:
                SetRequestRunResourceOnAfterRenameEvent(RenameRequest);
            Database::Job:
                SetRequestRunJobOnAfterRenameEvent(RenameRequest);
            Database::"Bank Account":
                SetRequestRunBankAccountOnAfterRenameEvent(RenameRequest);
            Database::"Fixed Asset":
                SetRequestRunFixedAssetOnAfterRenameEvent(RenameRequest);
            Database::Insurance:
                SetRequestRunInsuranceOnAfterRenameEvent(RenameRequest);
            Database::"Responsibility Center":
                SetRequestRunResponsibilityCenterOnAfterRenameEvent(RenameRequest);
            Database::"Salesperson/Purchaser":
                SetRequestRunSalespersonPurchaserOnAfterRenameEvent(RenameRequest);
            Database::Campaign:
                SetRequestRunCampaignOnAfterRenameEvent(RenameRequest);
            Database::"Cash Flow Manual Expense":
                SetRequestRunCashFlowManualExpenseOnAfterRenameEvent(RenameRequest);
            Database::"Cash Flow Manual Revenue":
                SetRequestRunCashFlowManualRevenueOnAfterRenameEvent(RenameRequest);
            Database::"Vendor Templ.":
                SetRequestRunVendorTemplOnAfterRenameEvent(RenameRequest);
            Database::"Customer Templ.":
                SetRequestRunCustomerTemplOnAfterRenameEvent(RenameRequest);
            Database::"Item Templ.":
                SetRequestRunItemTemplOnAfterRenameEvent(RenameRequest);
            Database::"Employee Templ.":
                SetRequestRunEmployeeTemplOnAfterRenameEvent(RenameRequest);
            Database::"Work Center":
                SetRequestRunWorkCenterOnAfterRenameEvent(RenameRequest);
            Database::"Item Charge":
                SetRequestRunItemChargeOnAfterRenameEvent(RenameRequest);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenameLinkedDimensionValues(var RecRef: RecordRef; var xRecRef: RecordRef; OldNo: Text; NewNo: Text; var SkipRenameLinkedMasterRecord: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenameLinkedMasterRecord(DimensionCode: Code[20]; OldNo: Text; NewNo: Text; var SkipRenameLinkedMasterRecord: Boolean; var IsHandled: Boolean)
    begin
    end;
}
