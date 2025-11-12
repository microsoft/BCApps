// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using System.Reflection;

table 7006 "Price Calculation Setup"
{
    Caption = 'Price Calculation Setup';
    LookupPageID = "Price Calculation Setup";
    DrillDownPageID = "Price Calculation Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Method; Enum "Price Calculation Method")
        {
            DataClassification = CustomerContent;
        }
        field(3; Type; Enum "Price Type")
        {
            DataClassification = CustomerContent;
        }
        field(4; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = CustomerContent;
        }
        field(5; Details; Integer)
        {
            Caption = 'Exceptions';
            FieldClass = FlowField;
            CalcFormula = count("Dtld. Price Calculation Setup" where("Setup Code" = field(Code)));
            Editable = false;
        }
        field(9; "Group Id"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(10; Implementation; Enum "Price Calculation Handler")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, Implementation.AsInteger());
            end;
        }
        field(12; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(13; Default; Boolean)
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "Price Calculation Setup";
            begin
                if not Default and xRec.Default then begin
                    Default := true;
                    exit; // cannot remove Default flag, pick another record to become Default
                end;

                if Default then begin
                    if PriceCalculationSetup.FindDefault("Group Id") then
                        PriceCalculationSetup.ModifyAll(Default, false);
                    RemoveExceptions();
                end;
            end;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Key2; "Group Id", Default, Enabled)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; Type, "Asset Type", Method, Implementation)
        {
        }
    }

    trigger OnInsert()
    begin
        DefineCode();
    end;

    local procedure DefineCode()
    begin
        "Group Id" := CopyStr(GetUID(), 1, MaxStrLen("Group Id"));
        Code := CopyStr(StrSubstNo('[%1]-%2', "Group Id", Implementation.AsInteger()), 1, MaxStrLen(Code));
        OnAfterDefineCode();
    end;

    procedure GetUID(): Text;
    begin
        exit(StrSubstNo('%1-%2-%3', Method.AsInteger(), Type.AsInteger(), "Asset Type".AsInteger()));
    end;

    [Scope('OnPrem')]
    procedure CopyDefaultFlagTo(var ToRec: Record "Price Calculation Setup")
    begin
        Reset();
        SetRange(Default, true);
        if FindSet() then
            repeat
                if ToRec.Get(Code) then begin
                    ToRec.Validate(Default, true);
                    ToRec.Modify();
                end;
            until Next() = 0;
    end;

    procedure CountEnabledExeptions() Result: Integer;
    var
        PriceCalculationSetup: Record "Price Calculation Setup";
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        PriceCalculationSetup.SetRange("Group Id", "Group Id");
        PriceCalculationSetup.SetRange(Default, false);
        PriceCalculationSetup.SetRange(Enabled, true);
        if PriceCalculationSetup.FindSet() then
            repeat
                DtldPriceCalculationSetup.SetRange("Setup Code", PriceCalculationSetup.Code);
                DtldPriceCalculationSetup.SetRange(Enabled, true);
                Result += DtldPriceCalculationSetup.Count();
            until PriceCalculationSetup.Next() = 0;
    end;

    procedure FindDefault(CalculationMethod: enum "Price Calculation Method"; PriceType: Enum "Price Type"): Boolean;
    begin
        Reset();
        SetRange(Method, CalculationMethod);
        SetRange(Type, PriceType);
        SetRange(Default, true);
        exit(FindFirst());
    end;

    procedure FindDefault(GroupId: Text): Boolean;
    begin
        Reset();
        SetCurrentKey("Group Id", Default);
        SetRange("Group Id", GroupId);
        SetRange(Default, true);
        exit(FindFirst());
    end;

    procedure MoveFrom(var TempPriceCalculationSetup: Record "Price Calculation Setup" temporary) Inserted: Boolean;
    var
        DefaultPriceCalculationSetup: Record "Price Calculation Setup";
    begin
        if TempPriceCalculationSetup.FindSet() then
            repeat
                Rec := TempPriceCalculationSetup;
                if Default then
                    if DefaultPriceCalculationSetup.FindDefault("Group Id") then
                        Default := false;
                Insert(true);
                Inserted := true;
            until TempPriceCalculationSetup.Next() = 0;
        TempPriceCalculationSetup.DeleteAll();
    end;

    local procedure RemoveExceptions()
    var
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        DtldPriceCalculationSetup.SetRange("Setup Code", Code);
        if not DtldPriceCalculationSetup.IsEmpty() then
            DtldPriceCalculationSetup.DeleteAll();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDefineCode()
    begin
    end;
}

