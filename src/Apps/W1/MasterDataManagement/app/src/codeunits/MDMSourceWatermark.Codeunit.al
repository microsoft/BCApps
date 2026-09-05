namespace Microsoft.Integration.MDM;

/// <summary>
/// Per-batch cache of the source SystemModifiedAt watermark carried in a cross-environment GetRecords response.
/// The materializer stashes it keyed by the source record's SystemId; the synchronization engine reads it back
/// (GetRowLastModifiedOn) to obtain the real source change time. The platform does not let a temporary record
/// hold SystemModifiedAt (writes are ignored), so the watermark travels here instead of on the temp source row.
/// Single instance so the value survives from materialization through the synchronization write; Reset() clears
/// it between batches.
/// </summary>
codeunit 7239 "MDM Source Watermark"
{
    Access = Internal;
    SingleInstance = true;

    var
        ModifiedAtByKey: Dictionary of [Text, DateTime];

    procedure Reset()
    begin
        Clear(ModifiedAtByKey);
    end;

    procedure Put(SystemId: Guid; ModifiedAt: DateTime)
    begin
        ModifiedAtByKey.Set(MakeKey(SystemId), ModifiedAt);
    end;

    procedure TryGet(SystemId: Guid; var ModifiedAt: DateTime): Boolean
    begin
        exit(ModifiedAtByKey.Get(MakeKey(SystemId), ModifiedAt));
    end;

    local procedure MakeKey(SystemId: Guid): Text
    begin
        exit(Format(SystemId, 0, 4));
    end;
}
