// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using System;
using System.Telemetry;
using System.Reflection;
using Microsoft.Integration.SyncEngine;
using Microsoft.Integration.D365Sales;

codeunit 7202 "Synthetic Relations"
{
    var
        VSolutionPrefixTok: Label 'dyn365bc', Locked = true;
        DefaultV2VTLogicalNameTok: Label 'dyn365bc_%1_v2_0', Locked = true;
        FeatureTelemetryNameTok: Label 'Dataverse - Synthetic Relations', Locked = true;

    internal procedure GetFeatureTelemetryName(): Text
    begin
        exit(FeatureTelemetryNameTok);
    end;

    internal procedure CreateSyntheticRelation(SynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary; NativeTableKey: Text[100])
    var
        CDSBCTableRelation: Record "CDS BC Table Relation";
        CRMOrganization: Record "CRM Organization";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CustomDimensions: Dictionary of [Text, Text];
        CrmHelper: DotNet CrmHelper;
        NativeFields: array[3] of Text[100];
        ConnectionName: Text;
        KeyName: Text[100];
        LanguageCode: Integer;
    begin
        FeatureTelemetry.LogUptake('0000MQ3', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000MQ4', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
        ConnectionName := CDSIntegrationImpl.RegisterConfiguredConnection(CrmHelper);
        CRMOrganization.FindFirst();
        LanguageCode := CRMOrganization.LanguageCode;
        NativeFields[1] := SynthRelationMappingBuffer."Syncd. Field 1 External Name";
        NativeFields[2] := SynthRelationMappingBuffer."Syncd. Field 2 External Name";
        NativeFields[3] := SynthRelationMappingBuffer."Syncd. Field 3 External Name";

        if NativeTableKey <> '' then
            KeyName := NativeTableKey
        else
            KeyName := VerifyKeyForTableAndColumnsExist(CRMHelper, SynthRelationMappingBuffer."Syncd. Table External Name", NativeFields, LanguageCode);
        CDSBCTableRelation.dyn365bc_nativeentity := CopyStr(SynthRelationMappingBuffer."Syncd. Table External Name", 1, 100);
        CDSBCTableRelation.dyn365bc_virtualentity := SynthRelationMappingBuffer."Virtual Table Logical Name";
        CDSBCTableRelation.name := GetRelationName(CDSBCTableRelation.dyn365bc_nativeentity, CDSBCTableRelation.dyn365bc_virtualentity);
        CDSBCTableRelation.dyn365bc_referencedattribname1 := SynthRelationMappingBuffer."Syncd. Field 1 External Name";
        CDSBCTableRelation.dyn365bc_referencedattribname2 := SynthRelationMappingBuffer."Syncd. Field 2 External Name";
        CDSBCTableRelation.dyn365bc_referencedattribname3 := SynthRelationMappingBuffer."Syncd. Field 3 External Name";
        CDSBCTableRelation.dyn365bc_referencingattribname1 := SynthRelationMappingBuffer."Virtual Table Column 1 Name";
        CDSBCTableRelation.dyn365bc_referencingattribname2 := SynthRelationMappingBuffer."Virtual Table Column 2 Name";
        CDSBCTableRelation.dyn365bc_referencingattribname3 := SynthRelationMappingBuffer."Virtual Table Column 3 Name";
        CDSBCTableRelation.dyn365bc_nativeentitykey := KeyName;
        InsertSyntheticRelationWithRetry(CDSBCTableRelation);
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);
        CustomDimensions.Add('Native Table', CDSBCTableRelation.dyn365bc_nativeentity);
        CustomDimensions.Add('Virtual Table', CDSBCTableRelation.dyn365bc_virtualentity);
        CustomDimensions.Add('Native Fields', CDSBCTableRelation.dyn365bc_referencedattribname1 + ', ' + CDSBCTableRelation.dyn365bc_referencedattribname2 + ', ' + CDSBCTableRelation.dyn365bc_referencedattribname3);
        CustomDimensions.Add('Virtual Fields', CDSBCTableRelation.dyn365bc_referencingattribname1 + ', ' + CDSBCTableRelation.dyn365bc_referencingattribname2 + ', ' + CDSBCTableRelation.dyn365bc_referencingattribname3);
        FeatureTelemetry.LogUsage('0000MQ5', GetFeatureTelemetryName(), 'Created Synthetic Relation through BC wizard.', CustomDimensions)
    end;

    internal procedure LoadExistingBCTableRelations(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        CDSBCTableRelation: Record "CDS BC Table Relation";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMHelper: DotNet CrmHelper;
        ConnectionName: Text;
    begin
        ConnectionName := CDSIntegrationImpl.RegisterConfiguredConnection(CrmHelper);
        TempSynthRelationMappingBuffer.Reset();
        TempSynthRelationMappingBuffer.DeleteAll();
        if not CDSBCTableRelation.FindSet() then
            exit;
        repeat
            TempSynthRelationMappingBuffer."Synth. Relation Name" := CDSBCTableRelation.name;
            TempSynthRelationMappingBuffer."Rel. Native Entity Name" := CDSBCTableRelation.dyn365bc_nativeentity;
            TempSynthRelationMappingBuffer."Rel. Virtual Entity Name" := CDSBCTableRelation.dyn365bc_virtualentity;
            TempSynthRelationMappingBuffer."Syncd. Field 1 External Name" := CDSBCTableRelation.dyn365bc_referencedattribname1;
            TempSynthRelationMappingBuffer."Virtual Table Column 1 Name" := CDSBCTableRelation.dyn365bc_referencingattribname1;
            TempSynthRelationMappingBuffer."Syncd. Field 2 External Name" := CDSBCTableRelation.dyn365bc_referencedattribname2;
            TempSynthRelationMappingBuffer."Virtual Table Column 2 Name" := CDSBCTableRelation.dyn365bc_referencingattribname2;
            TempSynthRelationMappingBuffer."Syncd. Field 3 External Name" := CDSBCTableRelation.dyn365bc_referencedattribname3;
            TempSynthRelationMappingBuffer."Virtual Table Column 3 Name" := CDSBCTableRelation.dyn365bc_referencingattribname3;
            TempSynthRelationMappingBuffer."Relation Id" := CDSBCTableRelation.dyn365bc_syntheticrelationId;
            TempSynthRelationMappingBuffer.Insert();
        until CDSBCTableRelation.Next() = 0;
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);
    end;

    internal procedure GetLogicalNameFromAPIPhysicalName(PhysicalName: Text): Text[100]
    begin
        exit(CopyStr(VSolutionPrefixTok + '_' + LowerCase(PhysicalName), 1, 100));
    end;

    internal procedure GetVirtualTableFields(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary; TempSyntheticRelationToCreate: Record "Synth. Relation Mapping Buffer" temporary)
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, TempSyntheticRelationToCreate."Virtual Table API Page Id");
        if not PageControlField.FindSet() then
            exit;
        repeat
            TempSynthRelationMappingBuffer."Virtual Table Column 1 Name" := CopyStr(PageControlField.ControlName, 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Column 1 Name"));
            TempSynthRelationMappingBuffer."Virtual Table Column 1 Caption" := PageControlField.ControlName;
            TempSynthRelationMappingBuffer.Insert();
        until PageControlField.Next() = 0;
    end;

    internal procedure LoadVisibleVirtualTables(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        TempCDSAvVirtualTableBuffer: Record "CDS Av. Virtual Table Buffer" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        CDSIntegrationImpl.LoadAvailableVirtualTables(TempCDSAvVirtualTableBuffer, true);
        if not TempCDSAvVirtualTableBuffer.FindSet() then
            exit;
        repeat
            TempSynthRelationMappingBuffer."Virtual Table Caption" := TempCDSAvVirtualTableBuffer."Display Name";
            TempSynthRelationMappingBuffer."Virtual Table Logical Name" := CopyStr(VSolutionPrefixTok + '_' + TempCDSAvVirtualTableBuffer."CDS Entity Logical Name", 1, 100);
            TempSynthRelationMappingBuffer."Virtual Table Phys. Name" := TempCDSAvVirtualTableBuffer."Phsyical Name";
            TempSynthRelationMappingBuffer.Insert();
        until TempCDSAvVirtualTableBuffer.Next() = 0;
    end;

    internal procedure GetAllAPIPages(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        if not PageMetadata.FindSet() then
            exit;
        repeat
            TempSynthRelationMappingBuffer."Virtual Table Phys. Name" := CopyStr(PageMetadata.EntityName, 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Phys. Name"));
            TempSynthRelationMappingBuffer."Virtual Table API Page Id" := PageMetadata.ID;
            TempSynthRelationMappingBuffer."Syncd. Table Id" := PageMetadata.ID;
            TempSynthRelationMappingBuffer.Insert();
        until PageMetadata.Next() = 0;
    end;

    internal procedure TryToGetVirtualTableAPIPageId(VirtualTableSelected: Record "Synth. Relation Mapping Buffer"): Integer
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetRange(EntityName, VirtualTableSelected."Virtual Table Phys. Name");
        if not PageMetadata.FindFirst() then
            exit(0);
        exit(PageMetadata.ID);
    end;

    internal procedure GetSynchedIntegrationTables(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TableMetadata: Record "Table Metadata";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        if not IntegrationTableMapping.FindSet() then
            exit;
        repeat
            TempSynthRelationMappingBuffer.SetRange("Syncd. Table Id", IntegrationTableMapping."Integration Table ID");
            if not TempSynthRelationMappingBuffer.FindSet() then begin
                TableMetadata.Get(IntegrationTableMapping."Integration Table ID");
                TableMetadata.TestField(TableType, TableMetadata.TableType::CRM);
                TempSynthRelationMappingBuffer."Syncd. Table Name" := TableMetadata.Name;
                TempSynthRelationMappingBuffer."Syncd. Table External Name" := TableMetadata.ExternalName;
                TempSynthRelationMappingBuffer."Syncd. Table Id" := IntegrationTableMapping."Integration Table ID";
                TempSynthRelationMappingBuffer.Insert();
            end;
        until IntegrationTableMapping.Next() = 0;
        TempSynthRelationMappingBuffer.Reset();
    end;

    internal procedure GetSynchedIntegrationFields(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary; NativeDataverseTableSelected: Record "Synth. Relation Mapping Buffer")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Field: Record Field;
    begin
        IntegrationTableMapping.SetRange("Integration Table ID", NativeDataverseTableSelected."Syncd. Table Id");
        if not IntegrationTableMapping.FindSet() then
            exit;
        repeat
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
            IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
            IntegrationFieldMapping.SetFilter("Integration Table Field No.", '<>%1', 0);
            if IntegrationFieldMapping.FindSet() then
                repeat
                    TempSynthRelationMappingBuffer.SetRange("Syncd. Field 1 Id", IntegrationFieldMapping."Integration Table Field No.");
                    if not TempSynthRelationMappingBuffer.FindSet() then begin
                        Field.Get(NativeDataverseTableSelected."Syncd. Table Id", IntegrationFieldMapping."Integration Table Field No.");
                        TempSynthRelationMappingBuffer."Syncd. Field 1 Name" := Field."Field Caption";
                        TempSynthRelationMappingBuffer."Syncd. Field 1 External Name" := Field.ExternalName;
                        TempSynthRelationMappingBuffer."Syncd. Field 1 Id" := IntegrationFieldMapping."Integration Table Field No.";
                        TempSynthRelationMappingBuffer.Insert();
                    end;
                until IntegrationFieldMapping.Next() = 0;
        until IntegrationTableMapping.Next() = 0;
        TempSynthRelationMappingBuffer.Reset();
    end;

    internal procedure DeleteSyntheticRelation(SynthRelationMapping: Record "Synth. Relation Mapping Buffer")
    var
        CDSBCTableRelation: Record "CDS BC Table Relation";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CrmHelper: DotNet CrmHelper;
        ConnectionName: Text;
    begin
        ConnectionName := CDSIntegrationImpl.RegisterConfiguredConnection(CrmHelper);
        CDSBCTableRelation.Get(SynthRelationMapping."Relation Id");
        CDSBCTableRelation.Delete();
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);
    end;

    internal procedure GetDefaultSyntheticRelations(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        TempCRMAccount: Record "CRM Account" temporary;
    begin
        GetNativeTableDetails(Database::"CRM Account", TempCRMAccount.FieldNo(AccountNumber), TempSynthRelationMappingBuffer);
        GetVirtualTableDetails('salesOrder', 'customerNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('salesShipment', 'customerNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('salesInvoice', 'customerNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('salesCreditMemo', 'customerNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('customerPayment', 'customerNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('customerFinancialDetail', 'number', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('purchaseReceipt', 'vendorNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('purchaseInvoice', 'vendorNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
        GetVirtualTableDetails('vendorPayment', 'vendorNumber', TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer.Insert();
    end;

    internal procedure GetExistingAlternateKeyName(NativeEntity: Text[248]; var NativeFields: array[3] of Text[100]; var KeyName: Text[100]; var KeyNames: List of [Text]) Result: Boolean
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionName: Text;
        CrmHelper: DotNet CrmHelper;
    begin
        ConnectionName := CDSIntegrationImpl.RegisterConfiguredConnection(CrmHelper);
        Result := GetExistingAlternateKeyName(CrmHelper, NativeEntity, NativeFields, KeyName, KeyNames);
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);
    end;

    internal procedure CreateAlternateKeyForColumns(NativeEntity: Text[248]; NativeFields: array[3] of Text[100]; var ExistingKeyNames: List of [Text])
    var
        CRMOrganization: Record "CRM Organization";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConnectionName: Text;
        LanguageCode: Integer;
        CrmHelper: DotNet CrmHelper;
    begin
        ConnectionName := CDSIntegrationImpl.RegisterConfiguredConnection(CrmHelper);
        CRMOrganization.FindFirst();
        LanguageCode := CRMOrganization.LanguageCode;
        CreateAlternateKeyForColumns(CrmHelper, NativeEntity, NativeFields, ExistingKeyNames, LanguageCode);
        UnregisterTableConnection(TableConnectionType::CRM, ConnectionName);
    end;

    internal procedure DoesSynthethicRelationExist(var TempExistingBCTablesRelations: Record "Synth. Relation Mapping Buffer" temporary; TempRelationToFind: Record "Synth. Relation Mapping Buffer" temporary) Exists: Boolean
    begin
        TempExistingBCTablesRelations.Reset();
        TempExistingBCTablesRelations.SetRange("Rel. Native Entity Name", TempRelationToFind."Rel. Native Entity Name");
        TempExistingBCTablesRelations.SetRange("Rel. Virtual Entity Name", TempRelationToFind."Rel. Virtual Entity Name");
        TempExistingBCTablesRelations.SetRange("Syncd. Field 1 External Name", TempRelationToFind."Syncd. Field 1 External Name");
        Exists := not TempExistingBCTablesRelations.IsEmpty();
        TempExistingBCTablesRelations.Reset();
    end;

    local procedure GetNativeTableDetails(TableId: Integer; FieldId: Integer; var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    begin
        TempSynthRelationMappingBuffer."Syncd. Table Id" := TableId;
        GetTableDetailsFromTableId(TempSynthRelationMappingBuffer);
        TempSynthRelationMappingBuffer."Syncd. Field 1 Id" := FieldId;
        GetFieldDetailsFromFieldId(TempSynthRelationMappingBuffer);
    end;

    local procedure GetVirtualTableDetails(EntityName: Text; FieldName: Text; var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    begin
        TempSynthRelationMappingBuffer."Virtual Table Logical Name" := CopyStr(StrSubstNo(DefaultV2VTLogicalNameTok, LowerCase(EntityName)), 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Logical Name"));
        TempSynthRelationMappingBuffer."Virtual Table Caption" := CopyStr(EntityName, 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Caption"));
        TempSynthRelationMappingBuffer."Virtual Table Column 1 Name" := CopyStr(VSolutionPrefixTok + '_' + LowerCase(FieldName), 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Column 1 Name"));
        TempSynthRelationMappingBuffer."Virtual Table Column 1 Caption" := CopyStr(FieldName, 1, MaxStrLen(TempSynthRelationMappingBuffer."Virtual Table Column 1 Caption"));
        TempSynthRelationMappingBuffer."Rel. Virtual Entity Name" := TempSynthRelationMappingBuffer."Virtual Table Logical Name";
    end;

    local procedure GetFieldDetailsFromFieldId(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        Field: Record Field;
    begin
        Field.Get(TempSynthRelationMappingBuffer."Syncd. Table Id", TempSynthRelationMappingBuffer."Syncd. Field 1 Id");
        TempSynthRelationMappingBuffer."Syncd. Field 1 Name" := Field.FieldName;
        TempSynthRelationMappingBuffer."Syncd. Field 1 External Name" := Field.ExternalName;
    end;

    local procedure GetTableDetailsFromTableId(var TempSynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer" temporary)
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.Get(TempSynthRelationMappingBuffer."Syncd. Table Id");
        TempSynthRelationMappingBuffer."Syncd. Table Name" := TableMetadata.Name;
        TempSynthRelationMappingBuffer."Syncd. Table External Name" := TableMetadata.ExternalName;
        TempSynthRelationMappingBuffer."Rel. Native Entity Name" := CopyStr(TableMetadata.ExternalName, 1, MaxStrLen(TempSynthRelationMappingBuffer."Rel. Native Entity Name"));
    end;

    local procedure GetExistingAlternateKeyName(var CRMHelper: DotNet CrmHelper; NativeEntity: Text[248]; var NativeFields: array[3] of Text[100]; var KeyName: Text[100]; var KeyNames: List of [Text]): Boolean
    var
        ExistingAlternateKeys: DotNet GenericDictionary2;
        Columns: DotNet GenericIEnumerable1;
        ExistingKeyName: Text[100];
    begin
        ExistingAlternateKeys := CRMHelper.RetrieveEntityAlternateKeys(NativeEntity);
        foreach ExistingKeyName in ExistingAlternateKeys.Keys() do begin
            KeyNames.Add(ExistingKeyName);
            Columns := ExistingAlternateKeys.Item(ExistingKeyName);
            if ColumnsInKeyMatchNativeFields(Columns, NativeFields) then begin
                KeyName := ExistingKeyName;
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure GetRelationName(NativeEntity: Text[100]; VirtualEntity: Text[100]): Text[100]
    var
        Suffix: Text;
    begin
        Suffix := CreateGuid();
        Suffix := Suffix.Substring(2, 4);
        exit(NativeEntity.Substring(1, 4) + VirtualEntity.Substring(StrLen(VSolutionPrefixTok) + 2, 4) + Suffix);
    end;

    local procedure VerifyKeyForTableAndColumnsExist(var CRMHelper: DotNet CrmHelper; NativeEntity: Text[248]; var NativeFields: array[3] of Text[100]; LanguageCode: Integer): Text[100]
    var
        KeyNames: List of [Text];
        KeyName: Text[100];
    begin
        if GetExistingAlternateKeyName(CRMHelper, NativeEntity, NativeFields, KeyName, KeyNames) then
            exit(KeyName);
        exit(CreateAlternateKeyForColumns(CRMHelper, NativeEntity, NativeFields, KeyNames, LanguageCode));
    end;

    local procedure ColumnsInKeyMatchNativeFields(var Columns: DotNet GenericIEnumerable1; var NativeFields: array[3] of Text[100]): Boolean
    var
        Matched: array[3] of Boolean;
        FieldName: Text;
        Index: Integer;
        ColsRemainingToMatch: Boolean;
    begin
        for Index := 1 to 3 do
            Matched[Index] := NativeFields[Index] = '';
        foreach FieldName in Columns do begin
            ColsRemainingToMatch := false;
            for Index := 1 to 3 do
                if not Matched[Index] then begin
                    ColsRemainingToMatch := true;
                    if FieldName = NativeFields[Index] then
                        Matched[Index] := true;
                end;
            if not ColsRemainingToMatch then
                exit(true);
        end;
        for Index := 1 to 3 do
            if not Matched[Index] then
                exit(false);
        exit(true);
    end;

    local procedure CreateAlternateKeyForColumns(var CRMHelper: DotNet CrmHelper; NativeEntity: Text[248]; NativeFields: array[3] of Text[100]; var ExistingKeyNames: List of [Text]; LanguageCode: Integer): Text[100]
    var
        NewKeyName: Text[100];
        Columns: DotNet Array;
        Index, ColIndex, NColumns : Integer;
    begin
        for Index := 1 to 3 do
            if NativeFields[Index] <> '' then
                NColumns := NColumns + 1;
        GetNewDotNetStringArrayInstance(NColumns, Columns);
        ColIndex := 0;
        for Index := 1 to 3 do
            if NativeFields[Index] <> '' then begin
                Columns.SetValue(NativeFields[Index], ColIndex);
                ColIndex := ColIndex + 1;
            end;
        NewKeyName := GetNewKeyName(ExistingKeyNames, NativeEntity);
        if LanguageCode <> 0 then
            CRMHelper.CreateEntityAlternateKey(NewKeyName, Columns, NativeEntity, LanguageCode)
        else
            CRMHelper.CreateEntityAlternateKey(NewKeyName, Columns, NativeEntity);
        Sleep(5000);
        exit(NewKeyName);
    end;

    local procedure GetNewDotNetStringArrayInstance(Length: Integer; var NewArray: DotNet Array)
    var
        DummyString: DotNet String;
    begin
        DummyString := '';
        NewArray := NewArray.CreateInstance(DummyString.GetType(), Length);
    end;

    local procedure GetNewKeyName(ExistingKeyNames: List of [Text]; EntityName: Text): Text[100]
    var
        NewKeyName: Text[100];
    begin
        NewKeyName := GenerateRandomAlternateKeyName(EntityName);
        while ExistingKeyNames.Contains(NewKeyName) do
            NewKeyName := GenerateRandomAlternateKeyName(EntityName);
        exit(NewKeyName);
    end;

    local procedure GenerateRandomAlternateKeyName(EntityName: Text): Text[100]
    var
        Suffix: Text;
    begin
        Suffix := CreateGuid();
        exit(EntityName.SubString(1, 4) + '_' + Suffix.Substring(2, 4));
    end;

    local procedure InsertSyntheticRelationWithRetry(var CDSBCTableRelation: Record "CDS BC Table Relation")
    begin
        if TryInsertingSyntheticRelation(CDSBCTableRelation) then
            exit;
        Sleep(5000);
        CDSBCTableRelation.Insert();
    end;

    [TryFunction()]
    local procedure TryInsertingSyntheticRelation(var CDSBCTableRelation: Record "CDS BC Table Relation")
    begin
        CDSBCTableRelation.Insert()
    end;

}
