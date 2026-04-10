// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

using System.Utilities;

codeunit 1383 "Batch Processing Mgt. Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempBatchProcessingArtifact: Record "Batch Processing Artifact" temporary;

    procedure AddArtifact(ArtifactType: enum "Batch Processing Artifact Type"; ArtifactName: Text[1024]; var TempBlobArtivactValue: Codeunit "Temp Blob")
    var
        RecRef: RecordRef;
    begin
        if TempBatchProcessingArtifact.FindLast() then;

        TempBatchProcessingArtifact.Init();
        TempBatchProcessingArtifact.Id += 1;
        TempBatchProcessingArtifact."Artifact Type" := ArtifactType;
        TempBatchProcessingArtifact."Artifact Name" := ArtifactName;
        if TempBlobArtivactValue.HasValue() then begin
            RecRef.GetTable(TempBatchProcessingArtifact);
            TempBlobArtivactValue.ToRecordRef(RecRef, TempBatchProcessingArtifact.FieldNo("Artifact Value"));
            RecRef.SetTable(TempBatchProcessingArtifact);
        end;
        TempBatchProcessingArtifact.Insert();
    end;

    local procedure HasArtifacts(ArtifactType: enum "Batch Processing Artifact Type") Result: Boolean
    begin
        TempBatchProcessingArtifact.SetRange("Artifact Type", ArtifactType);
        Result := not TempBatchProcessingArtifact.IsEmpty();
        TempBatchProcessingArtifact.SetRange("Artifact Type");
    end;

    local procedure GetArtifacts(ArtifactType: Enum "Batch Processing Artifact Type"; var TempBatchProcessingArtifactResult: Record "Batch Processing Artifact" temporary): Boolean
    begin
        TempBatchProcessingArtifactResult.Reset();
        TempBatchProcessingArtifactResult.DeleteAll();

        TempBatchProcessingArtifact.SetRange("Artifact Type", ArtifactType);
        if TempBatchProcessingArtifact.FindSet() then
            repeat
                TempBatchProcessingArtifactResult.TransferFields(TempBatchProcessingArtifact);
                TempBatchProcessingArtifact.CalcFields("Artifact Value");
                TempBatchProcessingArtifactResult."Artifact Value" := TempBatchProcessingArtifact."Artifact Value";
                TempBatchProcessingArtifactResult.Insert();
            until TempBatchProcessingArtifact.Next() = 0;
        TempBatchProcessingArtifact.SetRange("Artifact Type");

        exit(not TempBatchProcessingArtifactResult.IsEmpty());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnSystemSetBatchProcessingActive', '', false, false)]
    local procedure SetTrueOnSystemSetBatchProcessingActive(var Result: Boolean)
    begin
        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnAddArtifact', '', false, false)]
    local procedure HandleOnAddArtifact(ArtifactType: enum "Batch Processing Artifact Type"; ArtifactName: Text[1024]; var TempBlobArtifactValue: Codeunit "Temp Blob")
    begin
        AddArtifact(ArtifactType, ArtifactName, TempBlobArtifactValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnHasArtifacts', '', false, false)]
    local procedure HandleOnHasArtifacts(ArtifactType: enum "Batch Processing Artifact Type"; var Result: Boolean)
    begin
        Result := HasArtifacts(ArtifactType);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnGetArtifacts', '', false, false)]
    local procedure HandleOnGetArtifacts(ArtifactType: Enum "Batch Processing Artifact Type"; var TempBatchProcessingArtifactResult: Record "Batch Processing Artifact" temporary; var Result: Boolean)
    begin
        Result := GetArtifacts(ArtifactType, TempBatchProcessingArtifactResult);
    end;
}

