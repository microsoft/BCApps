// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

table 5645 "FA Date Type"
{
    Caption = 'FA Date Type';
    LookupPageID = "FA Date Types";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA Date Type No."; Integer)
        {
            Caption = 'FA Date Type No.';
        }
        field(2; "FA Date Type Name"; Text[50])
        {
            Caption = 'FA Date Type Name';
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
        key(Key1; "FA Date Type No.", "FA Date Type Name")
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
            InsertRec(1, FADepreciationBook.FieldNo("Last Acquisition Cost Date"), FADepreciationBook.FieldCaption("Last Acquisition Cost Date"));
            InsertRec(2, FADepreciationBook.FieldNo("Last Depreciation Date"), FADepreciationBook.FieldCaption("Last Depreciation Date"));
            InsertRec(3, FADepreciationBook.FieldNo("Last Write-Down Date"), FADepreciationBook.FieldCaption("Last Write-Down Date"));
            InsertRec(4, FADepreciationBook.FieldNo("Last Appreciation Date"), FADepreciationBook.FieldCaption("Last Appreciation Date"));
            InsertRec(5, FADepreciationBook.FieldNo("Last Custom 1 Date"), FADepreciationBook.FieldCaption("Last Custom 1 Date"));
            InsertRec(6, FADepreciationBook.FieldNo("Last Custom 2 Date"), FADepreciationBook.FieldCaption("Last Custom 2 Date"));
            InsertRec(7, FADepreciationBook.FieldNo("Disposal Date"), FADepreciationBook.FieldCaption("Disposal Date"));
            InsertRec(8, FADepreciationBook.FieldNo("Last Salvage Value Date"), FADepreciationBook.FieldCaption("Last Salvage Value Date"));
            "G/L Entry" := false;
            InsertRec(9, FADepreciationBook.FieldNo("Acquisition Date"), FADepreciationBook.FieldCaption("Acquisition Date"));
            "FA Entry" := false;
            "G/L Entry" := true;
            InsertRec(10, FADepreciationBook.FieldNo("G/L Acquisition Date"), FADepreciationBook.FieldCaption("G/L Acquisition Date"));
        end else begin
            SetCurrentKey("Entry No.");
            Find('-');
            repeat
                if "Entry No." = 1 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Acquisition Cost Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Acquisition Cost Date"))
                    then begin
                        Delete();
                        InsertRec(1, FADepreciationBook.FieldNo("Last Acquisition Cost Date"), FADepreciationBook.FieldCaption("Last Acquisition Cost Date"));
                    end;
                if "Entry No." = 2 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Depreciation Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Depreciation Date"))
                    then begin
                        Delete();
                        InsertRec(2, FADepreciationBook.FieldNo("Last Depreciation Date"), FADepreciationBook.FieldCaption("Last Depreciation Date"));
                    end;
                if "Entry No." = 3 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Write-Down Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Write-Down Date"))
                    then begin
                        Delete();
                        InsertRec(3, FADepreciationBook.FieldNo("Last Write-Down Date"), FADepreciationBook.FieldCaption("Last Write-Down Date"));
                    end;
                if "Entry No." = 4 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Appreciation Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Appreciation Date"))
                    then begin
                        Delete();
                        InsertRec(4, FADepreciationBook.FieldNo("Last Appreciation Date"), FADepreciationBook.FieldCaption("Last Appreciation Date"));
                    end;
                if "Entry No." = 5 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Custom 1 Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Custom 1 Date"))
                    then begin
                        Delete();
                        InsertRec(5, FADepreciationBook.FieldNo("Last Custom 1 Date"), FADepreciationBook.FieldCaption("Last Custom 1 Date"));
                    end;
                if "Entry No." = 6 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Custom 2 Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Custom 2 Date"))
                    then begin
                        Delete();
                        InsertRec(6, FADepreciationBook.FieldNo("Last Custom 2 Date"), FADepreciationBook.FieldCaption("Last Custom 2 Date"));
                    end;
                if "Entry No." = 7 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Disposal Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Disposal Date"))
                    then begin
                        Delete();
                        InsertRec(7, FADepreciationBook.FieldNo("Disposal Date"), FADepreciationBook.FieldCaption("Disposal Date"));
                    end;
                if "Entry No." = 8 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Last Salvage Value Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Last Salvage Value Date"))
                    then begin
                        Delete();
                        InsertRec(8, FADepreciationBook.FieldNo("Last Salvage Value Date"), FADepreciationBook.FieldCaption("Last Salvage Value Date"));
                    end;
                if "Entry No." = 9 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("Acquisition Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("Acquisition Date"))
                    then begin
                        Delete();
                        InsertRec(9, FADepreciationBook.FieldNo("Acquisition Date"), FADepreciationBook.FieldCaption("Acquisition Date"));
                    end;
                if "Entry No." = 10 then
                    if ("FA Date Type No." <> FADepreciationBook.FieldNo("G/L Acquisition Date")) or
                       ("FA Date Type Name" <> FADepreciationBook.FieldCaption("G/L Acquisition Date"))
                    then begin
                        Delete();
                        InsertRec(10, FADepreciationBook.FieldNo("G/L Acquisition Date"), FADepreciationBook.FieldCaption("G/L Acquisition Date"));
                    end;
            until Next() = 0;
        end;

        OnAfterCreateTypes(Rec);
    end;

    procedure InsertRec(FAEntryNo: Integer; FADateTypeNo: Integer; FADateTypeName: Text)
    begin
        "Entry No." := FAEntryNo;
        "FA Date Type No." := FADateTypeNo;
        "FA Date Type Name" := CopyStr(FADateTypeName, 1, MaxStrLen("FA Date Type Name"));
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTypes(var FADateType: Record "FA Date Type")
    begin
    end;
}

