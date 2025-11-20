// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Depreciation;

table 5647 "FA Matrix Posting Type"
{
    Caption = 'FA Matrix Posting Type';
    LookupPageID = "FA Matrix Posting Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "FA Posting Type Name"; Text[50])
        {
            Caption = 'FA Posting Type Name';
        }
    }

    keys
    {
        key(Key1; "Entry No.", "FA Posting Type Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateTypes()
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        if not FindSet() then begin
            InsertRec(1, FADepreciationBook.FieldCaption("Book Value"));
            InsertRec(2, FADepreciationBook.FieldCaption("Acquisition Cost"));
            InsertRec(3, FADepreciationBook.FieldCaption(Depreciation));
            InsertRec(4, FADepreciationBook.FieldCaption("Write-Down"));
            InsertRec(5, FADepreciationBook.FieldCaption(Appreciation));
            InsertRec(6, FADepreciationBook.FieldCaption("Custom 1"));
            InsertRec(7, FADepreciationBook.FieldCaption("Custom 2"));
            InsertRec(8, FADepreciationBook.FieldCaption("Proceeds on Disposal"));
            InsertRec(9, FADepreciationBook.FieldCaption("Gain/Loss"));
            InsertRec(10, FADepreciationBook.FieldCaption("Depreciable Basis"));
            InsertRec(11, FADepreciationBook.FieldCaption("Salvage Value"));
        end else
            repeat
                if "Entry No." = 1 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Book Value") then begin
                        Delete();
                        InsertRec(1, FADepreciationBook.FieldCaption("Book Value"));
                    end;
                if "Entry No." = 2 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Acquisition Cost") then begin
                        Delete();
                        InsertRec(2, FADepreciationBook.FieldCaption("Acquisition Cost"));
                    end;
                if "Entry No." = 3 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption(Depreciation) then begin
                        Delete();
                        InsertRec(3, FADepreciationBook.FieldCaption(Depreciation));
                    end;
                if "Entry No." = 4 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Write-Down") then begin
                        Delete();
                        InsertRec(4, FADepreciationBook.FieldCaption("Write-Down"));
                    end;
                if "Entry No." = 5 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption(Appreciation) then begin
                        Delete();
                        InsertRec(5, FADepreciationBook.FieldCaption(Appreciation));
                    end;
                if "Entry No." = 6 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Custom 1") then begin
                        Delete();
                        InsertRec(6, FADepreciationBook.FieldCaption("Custom 1"));
                    end;
                if "Entry No." = 7 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Custom 2") then begin
                        Delete();
                        InsertRec(7, FADepreciationBook.FieldCaption("Custom 2"));
                    end;
                if "Entry No." = 8 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Proceeds on Disposal") then begin
                        Delete();
                        InsertRec(8, FADepreciationBook.FieldCaption("Proceeds on Disposal"));
                    end;
                if "Entry No." = 9 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Gain/Loss") then begin
                        Delete();
                        InsertRec(9, FADepreciationBook.FieldCaption("Gain/Loss"));
                    end;
                if "Entry No." = 10 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Depreciable Basis") then begin
                        Delete();
                        InsertRec(10, FADepreciationBook.FieldCaption("Depreciable Basis"));
                    end;
                if "Entry No." = 11 then
                    if "FA Posting Type Name" <> FADepreciationBook.FieldCaption("Salvage Value") then begin
                        Delete();
                        InsertRec(11, FADepreciationBook.FieldCaption("Salvage Value"));
                    end;
            until Next() = 0;
        OnAfterCreateTypes(Rec);
    end;

    procedure InsertRec(EntryNo: Integer; FAPostingTypeName: Text)
    begin
        "Entry No." := EntryNo;
        "FA Posting Type Name" := CopyStr(FAPostingTypeName, 1, MaxStrLen("FA Posting Type Name"));
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTypes(var FAMatrixPostingType: Record "FA Matrix Posting Type")
    begin
    end;
}

