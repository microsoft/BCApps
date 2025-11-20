// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.FixedAssets.Depreciation;

table 5640 "Main Asset Component"
{
    Caption = 'Main Asset Component';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Main Asset No."; Code[20])
        {
            Caption = 'Main Asset No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Fixed Asset";
        }
        field(3; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            NotBlank = true;
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFANo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if ("FA No." = '') or ("Main Asset No." = '') then
                    exit;
                LockFixedAsset();
                FA.Get("FA No.");
                if "FA No." = "Main Asset No." then
                    CreateError("FA No.", 1);
                Description := FA.Description;
                MainAssetComp.SetRange("Main Asset No.", "FA No.");
                if MainAssetComp.FindFirst() then
                    CreateError("FA No.", 1);
                MainAssetComp.SetRange("Main Asset No.");
                MainAssetComp.SetCurrentKey("FA No.");
                MainAssetComp.SetRange("FA No.", "FA No.");
                if MainAssetComp.FindFirst() then
                    CreateError("FA No.", 2);
                MainAssetComp.SetRange("FA No.", "Main Asset No.");
                if MainAssetComp.FindFirst() then
                    CreateError("Main Asset No.", 1);
                UpdateMainAsset(FA, 2);
                FA.Get("Main Asset No.");
                if FA."Main Asset/Component" <> FA."Main Asset/Component"::"Main Asset" then begin
                    FA."Main Asset/Component" := FA."Main Asset/Component"::"Main Asset";
                    Error(
                      Text001,
                      DepreciationCalc.FAName(FA, ''), FA."Main Asset/Component");
                end;
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Main Asset No.", "FA No.")
        {
            Clustered = true;
        }
        key(Key2; "FA No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        LockFixedAsset();
        if "FA No." <> '' then begin
            FA.Get("FA No.");
            UpdateMainAsset(FA, 0);
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 is not a %2.';
        Text002: Label '%1 is a %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        MainAssetComp: Record "Main Asset Component";
        DepreciationCalc: Codeunit "Depreciation Calculation";
#pragma warning disable AA0074
        Text003: Label 'Main Asset,Component';
#pragma warning restore AA0074

    local procedure LockFixedAsset()
    begin
        FA.LockTable();
        FADeprBook.LockTable();
    end;

    local procedure UpdateMainAsset(var FA: Record "Fixed Asset"; ComponentType: Option " ","Main Asset",Component)
    var
        FA2: Record "Fixed Asset";
    begin
        if ComponentType = ComponentType::" " then begin
            FA."Main Asset/Component" := FA."Main Asset/Component"::" ";
            FA."Component of Main Asset" := '';
        end;
        if ComponentType = ComponentType::Component then begin
            FA."Component of Main Asset" := "Main Asset No.";
            FA."Main Asset/Component" := FA."Main Asset/Component"::Component;
        end;
        FA.Modify(true);
        UpdateFADeprBooks(FA);

        FA.Reset();
        FA.SetCurrentKey("Component of Main Asset");
        FA.SetRange("Component of Main Asset", "Main Asset No.");
        FA.SetRange("Main Asset/Component", FA2."Main Asset/Component"::Component);
        FA2.Get("Main Asset No.");
        if FA.Find('=><') then begin
            if FA2."Main Asset/Component" <> FA2."Main Asset/Component"::"Main Asset" then begin
                FA2."Main Asset/Component" := FA2."Main Asset/Component"::"Main Asset";
                FA2."Component of Main Asset" := FA2."No.";
                FA2.Modify(true);
                UpdateFADeprBooks(FA2);
            end;
        end else begin
            FA2."Main Asset/Component" := FA2."Main Asset/Component"::" ";
            FA2."Component of Main Asset" := '';
            FA2.Modify(true);
            UpdateFADeprBooks(FA2);
        end;
    end;

    local procedure UpdateFADeprBooks(var FA: Record "Fixed Asset")
    begin
        FADeprBook.SetCurrentKey("FA No.");
        FADeprBook.SetRange("FA No.", FA."No.");
        if FADeprBook.Find('-') then
            repeat
                FADeprBook."Main Asset/Component" := FA."Main Asset/Component";
                FADeprBook."Component of Main Asset" := FA."Component of Main Asset";
                FADeprBook.Modify(true);
            until FADeprBook.Next() = 0;
    end;

    local procedure CreateError(FANo: Code[20]; MainAssetComponent: Option " ","Main Asset",Component)
    begin
        FA."No." := FANo;
        Error(
          Text002,
          DepreciationCalc.FAName(FA, ''), SelectStr(MainAssetComponent, Text003));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var MainAssetComponent: Record "Main Asset Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFANo(var MainAssetComponent: Record "Main Asset Component"; var IsHandled: Boolean)
    begin
    end;
}

