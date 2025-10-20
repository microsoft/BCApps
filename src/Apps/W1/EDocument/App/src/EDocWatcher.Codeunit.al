// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.IO;

using System.Environment;
using Microsoft.eServices.EDocument.OrderMatch;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.eServices.EDocument;
using System.Utilities;
using System.Reflection;
codeunit 6199 "E-Doc Watcher"
{
    SingleInstance = true;

    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        WriteStreamInTempBlobInitialized: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure GetDatabaseTableTriggerSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        OnDatabaseInsert :=
            TableId in [Database::"E-Document", Database::"E-Document Service Status", Database::"E-Document Purchase Header", Database::"E-Document Purchase Line",
            Database::"E-Doc. Purchase Line History", Database::"E-Doc. Data Storage", Database::"E-Doc. Record Link", Database::"E-Doc. Imported Line", Database::"E-Doc. Vendor Assign. History", Database::"E-Document Header Mapping", Database::"E-Document Line - Field", Database::"E-Document Line Mapping"];
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure WriteDownChangesOnDatabaseInsert(RecRef: RecordRef)
    var
        FldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if DoesFieldRefContainValue(FldRef) then
                if IsNormalField(FldRef) then
                    WriteDownChanges(RecRef, FldRef);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyClose', '', false, false)]
    local procedure OnCompanyClose()
    var
        EDocWatch: Record "E-Doc Watch";
        InStream: InStream;
        FileOutStream: OutStream;
        ExportID: Integer;
    begin
        TempBlob.CreateInStream(InStream);
        if InStream.Length() = 0 then
            exit;
        if EDocWatch.FindLast() then
            ExportId := EDocWatch."Export ID";
        Clear(EDocWatch);
        EDocWatch."Export ID" := ExportID + 1;
        EDocWatch."File Content".CreateOutStream(FileOutStream);
        CopyStream(FileOutStream, Instream);
        EDocWatch.Insert();
    end;

    local procedure DoesFieldRefContainValue(FldRef: FieldRef): Boolean
    var
        HasValue: Boolean;
        Int: Integer;
        Dec: Decimal;
        D: Date;
        T: Time;
    begin
        case FldRef.Type of
            FieldType::Boolean:
                HasValue := FldRef.Value();
            FieldType::Option:
                HasValue := true;
            FieldType::Integer:
                begin
                    Int := FldRef.Value();
                    HasValue := Int <> 0;
                end;
            FieldType::Decimal:
                begin
                    Dec := FldRef.Value();
                    HasValue := Dec <> 0;
                end;
            FieldType::Date:
                begin
                    D := FldRef.Value();
                    HasValue := D <> 0D;
                end;
            FieldType::Time:
                begin
                    T := FldRef.Value();
                    HasValue := T <> 0T;
                end;
            FieldType::BLOB:
                HasValue := false;
            else
                HasValue := Format(FldRef.Value) <> '';
        end;

        exit(HasValue);
    end;

    local procedure IsNormalField(FieldRef: FieldRef): Boolean
    begin
        exit(FieldRef.Class = FieldClass::Normal)
    end;

    local procedure WriteDownChanges(RecRef: RecordRef; FldRef: FieldRef)
    var
        TypeHelper: Codeunit "Type Helper";
        TextToWrite: Text;
    begin
        if not WriteStreamInTempBlobInitialized then begin
            TempBlob.CreateOutStream(OutStream);
            WriteStreamInTempBlobInitialized := true;
        end;
        TextToWrite := RecRef.Name() + ';' + FldRef.Name() + ' = ' + Format(FldRef.Value) + TypeHelper.CRLFSeparator();
        OutStream.WriteText(TextToWrite);
    end;
}