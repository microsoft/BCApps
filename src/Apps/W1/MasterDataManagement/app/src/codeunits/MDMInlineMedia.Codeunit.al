namespace Microsoft.Integration.MDM;

using System.Text;
using System.Utilities;

/// <summary>
/// Per-batch cache of inline Media bytes carried in a cross-environment GetRecords response. The materializer
/// stashes the decoded content keyed by the source record's SystemId and the Media field number; the field
/// transfer subscriber (UpdateMedia, cross-environment branch) reads it to build the destination Tenant Media.
/// A Media field only holds a Tenant Media GUID, which is meaningless in the subsidiary, so the bytes travel
/// here instead of on the temporary source record. Single instance so the value survives from materialization
/// through the synchronization write; Reset() clears it between batches.
/// </summary>
codeunit 7232 "MDM Inline Media"
{
    Access = Internal;
    SingleInstance = true;

    var
        ContentByKey: Dictionary of [Text, Text];
        NameByKey: Dictionary of [Text, Text];
        MimeByKey: Dictionary of [Text, Text];
        ClearedByKey: Dictionary of [Text, Boolean];
        MalformedMediaErr: Label 'The source returned media content that could not be decoded.', Locked = true;

    procedure Reset()
    begin
        Clear(ContentByKey);
        Clear(NameByKey);
        Clear(MimeByKey);
        Clear(ClearedByKey);
    end;

    procedure Put(SystemId: Guid; FieldNo: Integer; FileName: Text; MimeType: Text; ContentBase64: Text)
    var
        MediaKey: Text;
    begin
        MediaKey := MakeKey(SystemId, FieldNo);
        ContentByKey.Set(MediaKey, ContentBase64);
        NameByKey.Set(MediaKey, FileName);
        MimeByKey.Set(MediaKey, MimeType);
    end;

    // The source reported the media field empty (cleared): record it so the transfer clears the destination media
    // instead of leaving stale bytes. Distinct from an absent entry, which means "not projected / leave untouched".
    procedure PutCleared(SystemId: Guid; FieldNo: Integer)
    begin
        ClearedByKey.Set(MakeKey(SystemId, FieldNo), true);
    end;

    procedure IsCleared(SystemId: Guid; FieldNo: Integer): Boolean
    begin
        exit(ClearedByKey.ContainsKey(MakeKey(SystemId, FieldNo)));
    end;

    procedure Contains(SystemId: Guid; FieldNo: Integer): Boolean
    begin
        exit(ContentByKey.ContainsKey(MakeKey(SystemId, FieldNo)));
    end;

    procedure TryGet(SystemId: Guid; FieldNo: Integer; var FileName: Text; var MimeType: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        MediaKey: Text;
        ContentBase64: Text;
    begin
        MediaKey := MakeKey(SystemId, FieldNo);
        if not ContentByKey.Get(MediaKey, ContentBase64) then
            exit(false);
        NameByKey.Get(MediaKey, FileName);
        MimeByKey.Get(MediaKey, MimeType);
        if not TryDecodeContent(ContentBase64, TempBlob) then // undecodable media content is a broken record entry from the source
            Error(MalformedMediaContent());
        exit(true);
    end;

    [TryFunction]
    local procedure TryDecodeContent(ContentBase64: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
        ContentOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(ContentOutStream);
        Base64Convert.FromBase64(ContentBase64, ContentOutStream);
    end;

    local procedure MalformedMediaContent(): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MalformedMediaErr;
        ErrInfo.DataClassification := DataClassification::SystemMetadata; // Message is emitted to telemetry
        ErrInfo.ErrorType := ErrorType::Internal;
        exit(ErrInfo);
    end;

    local procedure MakeKey(SystemId: Guid; FieldNo: Integer): Text
    begin
        exit(Format(SystemId, 0, 4) + '|' + Format(FieldNo));
    end;
}
