// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;
using System.IO;

codeunit 5397 "CDS Transformation Rule Mgt."
{
    var
        TransformationRuleInUseErr: Label '%1 cannot be deleted because it is in use.', Comment = '%1 - the name of the transformation rule';

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnBeforeDeleteEvent', '', false, false)]
    procedure OnDeleteTransformationRule(var Rec: Record "Transformation Rule"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if IsTransformationRuleInUse(Rec) then
            Error(TransformationRuleInUseErr, Rec.Code);
    end;

    local procedure IsTransformationRuleInUse(Rec: Record "Transformation Rule"): Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.ReadIsolation := IsolationLevel::ReadCommitted;
        IntegrationFieldMapping.SetRange("Transformation Rule", Rec.Code);
        exit(not IntegrationFieldMapping.IsEmpty());
    end;

    procedure ApplyTransformations(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping")
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        TransformationRule: Record "Transformation Rule";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
#if not CLEAN25
        if IntegrationTableMapping.Name = '' then
            IntegrationFieldMapping.SetFilter("Integration Table Mapping Name", '%1|%2|%3|%4', GetIntegrationTableMappingName(SourceRecordRef), GetIntegrationTableMappingName(DestinationRecordRef), GetSourceDestCode(SourceRecordRef, DestinationRecordRef), GetSourceDestCode(DestinationRecordRef, SourceRecordRef))
        else
#endif
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetFilter("Transformation Rule", '<>%1', ' ');

#if not CLEAN25
        if IntegrationFieldMapping.FindSet() then begin
            if IntegrationTableMapping.Name = '' then
                IntegrationTableMapping.Get(IntegrationFieldMapping."Integration Table Mapping Name");
#else
        if IntegrationFieldMapping.FindSet() then
#endif
            repeat
                if TransformationRule.Get(IntegrationFieldMapping."Transformation Rule") then
                    case IntegrationFieldMapping."Transformation Direction" of
                        IntegrationFieldMapping."Transformation Direction"::FromIntegrationTable:
                            if IntegrationTableMapping."Integration Table ID" = SourceRecordRef.Number() then
                                CRMSynchHelper.TransformValue(SourceRecordRef, DestinationRecordRef, TransformationRule, IntegrationFieldMapping."Integration Table Field No.", IntegrationFieldMapping."Field No.");
                        IntegrationFieldMapping."Transformation Direction"::ToIntegrationTable:
                            if IntegrationTableMapping."Table ID" = SourceRecordRef.Number() then
                                CRMSynchHelper.TransformValue(SourceRecordRef, DestinationRecordRef, TransformationRule, IntegrationFieldMapping."Field No.", IntegrationFieldMapping."Integration Table Field No.");
                    end;
            until IntegrationFieldMapping.Next() = 0;
#if not CLEAN25
        end;
#endif
    end;

#if not CLEAN25
    [Obsolete('Use ApplyTransformations(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; IntegrationTableMapping: Record "Integration Table Mapping") instead.', '25.0')]
    procedure ApplyTransformations(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        ApplyTransformations(SourceRecordRef, DestinationRecordRef, IntegrationTableMapping);
    end;

    [Obsolete('This procedure is not used.', '25.0')]
    procedure GetIntegrationTableMappingName(RecRef: RecordRef): Text
    begin
        if RecRef.Number() <> 0 then
            exit(CopyStr(UpperCase(RecRef.Name()), 1, 20));
        exit('');
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(CopyStr(StrSubstNo('%1-%2', UpperCase(SourceRecordRef.Name().Replace('CRM', '')), UpperCase(DestinationRecordRef.Name().Replace('CRM ', ''))), 1, 20));
        exit('');
    end;
#endif
}