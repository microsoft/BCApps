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
        BlobSkippedByKey: Dictionary of [Text, Boolean];
        MalformedMediaErr: Label 'The source returned media content that could not be decoded.', Locked = true;

    procedure Reset()
    begin
        Clear(ContentByKey);
        Clear(NameByKey);
        Clear(MimeByKey);
        Clear(ClearedByKey);
        Clear(BlobSkippedByKey);
    end;

    procedure Put(SystemId: Guid; FieldNo: Integer; FileName: Text; MimeType: Text; ContentBase64: Text)
    var
        MediaKey: Text;
    begin
        MediaKey := MakeKey(SystemId, FieldNo);
        ContentByKey.Set(MediaKey, ContentBase64);
        NameByKey.Set(MediaKey, FileName);
        MimeByKey.Set(MediaKey, MimeType);
        // Same (SystemId, field) can arrive twice across pages; drop a stale cleared marker so the newest state (content) wins.
        ClearedByKey.Remove(MediaKey);
    end;

    // The source reported the media field empty (cleared): record it so the transfer clears the destination media
    // instead of leaving stale bytes. Distinct from an absent entry, which means "not projected / leave untouched".
    procedure PutCleared(SystemId: Guid; FieldNo: Integer)
    var
        MediaKey: Text;
    begin
        MediaKey := MakeKey(SystemId, FieldNo);
        // Same (SystemId, field) can arrive twice across pages; drop cached content so the newest state (cleared) wins.
        ContentByKey.Remove(MediaKey);
        NameByKey.Remove(MediaKey);
        MimeByKey.Remove(MediaKey);
        ClearedByKey.Set(MediaKey, true);
    end;

    procedure IsCleared(SystemId: Guid; FieldNo: Integer): Boolean
    begin
        exit(ClearedByKey.ContainsKey(MakeKey(SystemId, FieldNo)));
    end;

    // The source reported the Blob field over the inline cap and skipped it: record it so the transfer keeps the
    // existing destination blob. Unlike media (out-of-band cache), blobs travel in-band on the temp record, so an
    // absent value would otherwise clear the destination.
    procedure PutBlobSkipped(SystemId: Guid; FieldNo: Integer)
    begin
        BlobSkippedByKey.Set(MakeKey(SystemId, FieldNo), true);
    end;

    // A real content or cleared result for the same (SystemId, field) supersedes an earlier skip so the newest state wins.
    procedure ClearBlobSkipped(SystemId: Guid; FieldNo: Integer)
    begin
        BlobSkippedByKey.Remove(MakeKey(SystemId, FieldNo));
    end;

    procedure IsBlobSkipped(SystemId: Guid; FieldNo: Integer): Boolean
    begin
        exit(BlobSkippedByKey.ContainsKey(MakeKey(SystemId, FieldNo)));
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
