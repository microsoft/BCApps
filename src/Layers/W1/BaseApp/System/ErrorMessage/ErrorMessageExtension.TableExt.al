namespace System.Utilities;

using Microsoft.Finance.Dimension;
using Microsoft.Utilities;

tableextension 705 "Error Message Extension" extends "Error Message"
{
    var
        ErrorContextNotFoundErr: Label 'Error context not found: %1', Comment = '%1 - Record Id';

    procedure HandleDrillDown(SourceFieldNo: Integer)
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnDrillDownSource(Rec, SourceFieldNo, IsHandled);
        if not IsHandled then
            case SourceFieldNo of
                FieldNo(Rec."Context Record ID"):
                    begin
                        if not RecRef.Get(Rec."Context Record ID") then
                            error(ErrorContextNotFoundErr, Format(Rec."Context Record ID"));
                        PageManagement.PageRunAtField(Rec."Context Record ID", Rec."Context Field Number", false);
                    end;
                FieldNo(Rec."Record ID"):
                    if IsDimSetEntryInconsistency() then
                        RunDimSetEntriesPage()
                    else
                        PageManagement.PageRunAtField(Rec."Record ID", Rec."Field Number", false);
            end
    end;

    local procedure IsDimSetEntryInconsistency(): Boolean
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        RecId: RecordId;
    begin
        RecId := "Record ID";
        exit((RecId.TableNo() = Database::"Dimension Set Entry") and (Rec."Field Number" = DimensionSetEntry.FieldNo("Global Dimension No.")));
    end;

    local procedure RunDimSetEntriesPage()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetEntries: Page "Dimension Set Entries";
    begin
        DimensionSetEntry.Get(Rec."Record ID");
        DimensionSetEntries.SetRecord(DimensionSetEntry);
        DimensionSetEntries.SetUpdDimSetGlblDimNoVisible();
        DimensionSetEntries.Run();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownSource(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}