// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Depreciation;

table 5644 "FA Posting Type"
{
    Caption = 'FA Posting Type';
    LookupPageID = "FA Posting Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA Posting Type No."; Integer)
        {
            Caption = 'FA Posting Type No.';
        }
        field(2; "FA Posting Type Name"; Text[50])
        {
            Caption = 'FA Posting Type Name';
        }
        field(3; "FA Entry"; Boolean)
        {
            Caption = 'FA Entry';
        }
        field(4; "G/L Entry"; Boolean)
        {
            Caption = 'G/L Entry';
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "FA Posting Type No.", "FA Posting Type Name")
        {
            Clustered = true;
        }
        key(Key2; "Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateTypes()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LockTable();
        if not Find('-') then begin
            "FA Entry" := true;
            "G/L Entry" := true;
            InsertRec(1, FADepreciationBook.FieldNo("Acquisition Cost"), FADepreciationBook.FieldCaption("Acquisition Cost"));
            InsertRec(2, FADepreciationBook.FieldNo(Depreciation), FADepreciationBook.FieldCaption(Depreciation));
            InsertRec(3, FADepreciationBook.FieldNo("Write-Down"), FADepreciationBook.FieldCaption("Write-Down"));
            InsertRec(4, FADepreciationBook.FieldNo(Appreciation), FADepreciationBook.FieldCaption(Appreciation));
            InsertRec(5, FADepreciationBook.FieldNo("Custom 1"), FADepreciationBook.FieldCaption("Custom 1"));
            InsertRec(6, FADepreciationBook.FieldNo("Custom 2"), FADepreciationBook.FieldCaption("Custom 2"));
            InsertRec(7, FADepreciationBook.FieldNo("Proceeds on Disposal"), FADepreciationBook.FieldCaption("Proceeds on Disposal"));
            InsertRec(8, FADepreciationBook.FieldNo("Gain/Loss"), FADepreciationBook.FieldCaption("Gain/Loss"));
            "FA Entry" := true;
            "G/L Entry" := false;
            InsertRec(9, FADepreciationBook.FieldNo("Book Value"), FADepreciationBook.FieldCaption("Book Value"));
            InsertRec(10, FADepreciationBook.FieldNo("Depreciable Basis"), FADepreciationBook.FieldCaption("Depreciable Basis"));
            InsertRec(11, FADepreciationBook.FieldNo("Salvage Value"), FADepreciationBook.FieldCaption("Salvage Value"));
            "FA Entry" := false;
            "G/L Entry" := true;
            InsertRec(12, FADepreciationBook.FieldNo("Book Value on Disposal"), FADepreciationBook.FieldCaption("Book Value on Disposal"));
        end else begin
            SetCurrentKey("Entry No.");
            Find('-');
            repeat
                if "Entry No." = 1 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Acquisition Cost")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Acquisition Cost"))
                    then begin
                        Delete();
                        InsertRec(1, FADepreciationBook.FieldNo("Acquisition Cost"), FADepreciationBook.FieldCaption("Acquisition Cost"));
                    end;
                if "Entry No." = 2 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo(Depreciation)) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption(Depreciation))
                    then begin
                        Delete();
                        InsertRec(2, FADepreciationBook.FieldNo(Depreciation), FADepreciationBook.FieldCaption(Depreciation));
                    end;
                if "Entry No." = 3 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Write-Down")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Write-Down"))
                    then begin
                        Delete();
                        InsertRec(3, FADepreciationBook.FieldNo("Write-Down"), FADepreciationBook.FieldCaption("Write-Down"));
                    end;
                if "Entry No." = 4 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo(Appreciation)) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption(Appreciation))
                    then begin
                        Delete();
                        InsertRec(4, FADepreciationBook.FieldNo(Appreciation), FADepreciationBook.FieldCaption(Appreciation));
                    end;
                if "Entry No." = 5 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Custom 1")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Custom 1"))
                    then begin
                        Delete();
                        InsertRec(5, FADepreciationBook.FieldNo("Custom 1"), FADepreciationBook.FieldCaption("Custom 1"));
                    end;
                if "Entry No." = 6 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Custom 2")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Custom 2"))
                    then begin
                        Delete();
                        InsertRec(6, FADepreciationBook.FieldNo("Custom 2"), FADepreciationBook.FieldCaption("Custom 2"));
                    end;
                if "Entry No." = 7 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Proceeds on Disposal")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Proceeds on Disposal"))
                    then begin
                        Delete();
                        InsertRec(7, FADepreciationBook.FieldNo("Proceeds on Disposal"), FADepreciationBook.FieldCaption("Proceeds on Disposal"));
                    end;
                if "Entry No." = 8 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Gain/Loss")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Gain/Loss"))
                    then begin
                        Delete();
                        InsertRec(8, FADepreciationBook.FieldNo("Gain/Loss"), FADepreciationBook.FieldCaption("Gain/Loss"));
                    end;
                if "Entry No." = 9 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Book Value")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Book Value"))
                    then begin
                        Delete();
                        InsertRec(9, FADepreciationBook.FieldNo("Book Value"), FADepreciationBook.FieldCaption("Book Value"));
                    end;
                if "Entry No." = 10 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Depreciable Basis")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Depreciable Basis"))
                    then begin
                        Delete();
                        InsertRec(10, FADepreciationBook.FieldNo("Depreciable Basis"), FADepreciationBook.FieldCaption("Depreciable Basis"));
                    end;
                if "Entry No." = 11 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Salvage Value")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Salvage Value"))
                    then begin
                        Delete();
                        InsertRec(11, FADepreciationBook.FieldNo("Salvage Value"), FADepreciationBook.FieldCaption("Salvage Value"));
                    end;
                if "Entry No." = 12 then
                    if ("FA Posting Type No." <> FADepreciationBook.FieldNo("Book Value on Disposal")) or
                       ("FA Posting Type Name" <> FADepreciationBook.FieldCaption("Book Value on Disposal"))
                    then begin
                        Delete();
                        InsertRec(12, FADepreciationBook.FieldNo("Book Value on Disposal"), FADepreciationBook.FieldCaption("Book Value on Disposal"));
                    end;
            until Next() = 0;
        end;
        OnAfterCreateTypes(Rec);
    end;

    procedure InsertRec(EntryNo: Integer; FAPostingTypeNo: Integer; FAPostingTypeName: Text)
    begin
        "Entry No." := EntryNo;
        "FA Posting Type No." := FAPostingTypeNo;
        "FA Posting Type Name" := CopyStr(FAPostingTypeName, 1, MaxStrLen("FA Posting Type Name"));
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTypes(var FAPostingType: Record "FA Posting Type")
    begin
    end;
}

