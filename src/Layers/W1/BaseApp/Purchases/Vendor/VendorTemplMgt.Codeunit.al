// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 1385 "Vendor Templ. Mgt."
{
    EventSubscriberInstance = StaticAutomatic;

    trigger OnRun()
    begin
    end;

    var
        UpdateExistingValuesQst: Label 'You are about to apply the template to selected records. Data from the template will replace data for the records in fields that do not already contain data. Do you want to continue?';
        OpenBlankCardQst: Label 'Do you want to open the blank vendor card?';

    procedure CreateVendorFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean) Result: Boolean
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateVendorFromTemplate(Vendor, Result, IsHandled);
        if IsHandled then
            exit(Result);

        IsHandled := true;

        OnCreateVendorFromTemplateOnBeforeSelectVendorTemplate(Vendor, VendorTempl);
        if not SelectVendorTemplate(VendorTempl) then
            exit(false);

        Vendor.SetInsertFromTemplate(true);
        Vendor.Init();
        OnCreateVendorFromTemplateOnBeforeInitVendorNo(Vendor);
        InitVendorNo(Vendor, VendorTempl);
        Vendor.Insert(true);
        Vendor.SetInsertFromTemplate(false);

        ApplyVendorTemplate(Vendor, VendorTempl);

        OnAfterCreateVendorFromTemplate(Vendor, VendorTempl);
        exit(true);
    end;

    procedure ApplyVendorTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
        ApplyVendorTemplate(Vendor, VendorTempl, false);
    end;

    procedure ApplyVendorTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ."; UpdateExistingValues: Boolean)
    begin
        ApplyTemplate(Vendor, VendorTempl, UpdateExistingValues);
        InsertDimensions(Vendor."No.", VendorTempl.Code, Database::Vendor, Database::"Vendor Templ.");
        Vendor.Get(Vendor."No.");
        OnAfterApplyVendorTemplate(Vendor, VendorTempl);
    end;

    local procedure ApplyTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ."; UpdateExistingValues: Boolean)
    var
        VendorRecRef: RecordRef;
        EmptyVendorRecRef: RecordRef;
        VendorTemplRecRef: RecordRef;
        EmptyVendorTemplRecRef: RecordRef;
        VendorFldRef: FieldRef;
        EmptyVendorFldRef: FieldRef;
        VendorTemplFldRef: FieldRef;
        EmptyVendorTemplFldRef: FieldRef;
        i: Integer;
        FieldExclusionList: List of [Integer];
    begin
        VendorRecRef.GetTable(Vendor);
        EmptyVendorRecRef.Open(Database::Vendor);
        EmptyVendorRecRef.Init();
        VendorTemplRecRef.GetTable(VendorTempl);
        EmptyVendorTemplRecRef.Open(Database::"Vendor Templ.");
        EmptyVendorTemplRecRef.Init();

        FillFieldExclusionList(FieldExclusionList);

        for i := 3 to VendorTemplRecRef.FieldCount do begin
            VendorTemplFldRef := VendorTemplRecRef.FieldIndex(i);
            if TemplateFieldCanBeProcessed(VendorTemplFldRef.Number, FieldExclusionList) then begin
                VendorFldRef := VendorRecRef.Field(VendorTemplFldRef.Number);
                EmptyVendorFldRef := EmptyVendorRecRef.Field(VendorTemplFldRef.Number);
                EmptyVendorTemplFldRef := EmptyVendorTemplRecRef.Field(VendorTemplFldRef.Number);
                if (not UpdateExistingValues and (VendorFldRef.Value = EmptyVendorFldRef.Value) and (VendorTemplFldRef.Value <> EmptyVendorTemplFldRef.Value)) or
                   (UpdateExistingValues and (VendorTemplFldRef.Value <> EmptyVendorTemplFldRef.Value))
                then
                    VendorFldRef.Value := VendorTemplFldRef.Value();
            end;
        end;
        VendorRecRef.SetTable(Vendor);
        if VendorTempl."Invoice Disc. Code" <> '' then
            Vendor."Invoice Disc. Code" := VendorTempl."Invoice Disc. Code";
        OnApplyTemplateOnBeforeVendorModify(Vendor, VendorTempl, UpdateExistingValues);
        Vendor.Modify(true);
    end;

    procedure SelectVendorTemplateFromContact(var VendorTempl: Record "Vendor Templ."; Contact: Record Contact): Boolean
    begin
        OnBeforeSelectVendorTemplateFromContact(VendorTempl, Contact);

        VendorTempl.SetRange("Contact Type", Contact.Type);
        exit(SelectVendorTemplate(VendorTempl));
    end;

    local procedure SelectVendorTemplate(var VendorTempl: Record "Vendor Templ."): Boolean
    var
        SelectVendorTemplList: Page "Select Vendor Templ. List";
    begin
        if VendorTempl.Count = 1 then begin
            VendorTempl.FindFirst();
            exit(true);
        end;

        if (VendorTempl.Count > 1) and GuiAllowed then begin
            SelectVendorTemplList.SetTableView(VendorTempl);
            SelectVendorTemplList.LookupMode(true);
            if SelectVendorTemplList.RunModal() = Action::LookupOK then begin
                SelectVendorTemplList.GetRecord(VendorTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if (SourceDefaultDimension."Value Posting" = SourceDefaultDimension."Value Posting"::"Code Mandatory") and (SourceDefaultDimension."Allowed Values Filter" <> '') then
                    DestDefaultDimension.Validate("Allowed Values Filter", SourceDefaultDimension."Allowed Values Filter");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure VendorTemplatesAreNotEmpty(var IsHandled: Boolean): Boolean
    var
        VendorTempl: Record "Vendor Templ.";
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        if not TemplateFeatureMgt.IsEnabled() then
            exit(false);

        IsHandled := true;
        exit(not VendorTempl.IsEmpty);
    end;

    procedure InsertVendorFromTemplate(var Vendor: Record Vendor) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnInsertVendorFromTemplate(Vendor, Result, IsHandled);
    end;

    procedure TemplatesAreNotEmpty() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnTemplatesAreNotEmpty(Result, IsHandled);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure UpdateVendorFromTemplate(var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnUpdateVendorFromTemplate(Vendor, IsHandled);
    end;

    local procedure UpdateFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplate(Vendor, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(VendorTempl, IsHandled) then
            exit;

        if not GetUpdateExistingValuesParam() then
            exit;

        ApplyVendorTemplate(Vendor, VendorTempl, true);
    end;

    procedure UpdateVendorsFromTemplate(var Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnUpdateVendorsFromTemplate(Vendor, IsHandled);
    end;

    local procedure UpdateMultipleFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        IsHandled := false;
        OnBeforeUpdateMultipleFromTemplate(Vendor, IsHandled);
        if IsHandled then
            exit;

        if not CanBeUpdatedFromTemplate(VendorTempl, IsHandled) then
            exit;

        if Vendor.FindSet() then
            repeat
                ApplyVendorTemplate(Vendor, VendorTempl, GetUpdateExistingValuesParam());
            until Vendor.Next() = 0;
    end;

    local procedure CanBeUpdatedFromTemplate(var VendorTempl: Record "Vendor Templ."; var IsHandled: Boolean): Boolean
    begin
        IsHandled := true;

        if not SelectVendorTemplate(VendorTempl) then
            exit(false);

        exit(true);
    end;

    procedure SaveAsTemplate(Vendor: Record Vendor)
    var
        IsHandled: Boolean;
    begin
        OnSaveAsTemplate(Vendor, IsHandled);
    end;

    procedure CreateTemplateFromVendor(Vendor: Record Vendor; var IsHandled: Boolean)
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        IsHandled := false;
        OnBeforeCreateTemplateFromVendor(Vendor, IsHandled);
        if IsHandled then
            exit;

        IsHandled := true;

        InsertTemplateFromVendor(VendorTempl, Vendor);
        InsertDimensions(VendorTempl.Code, Vendor."No.", Database::"Vendor Templ.", Database::Vendor);
        VendorTempl.Get(VendorTempl.Code);
        ShowVendorTemplCard(VendorTempl);
    end;

    local procedure InsertTemplateFromVendor(var VendorTempl: Record "Vendor Templ."; Vendor: Record Vendor)
    var
        SavedVendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.Init();
        VendorTempl.Code := GetVendorTemplCode();
        SavedVendorTempl := VendorTempl;
        VendorTempl.TransferFields(Vendor);
        VendorTempl.Code := SavedVendorTempl.Code;
        VendorTempl.Description := SavedVendorTempl.Description;
        OnInsertTemplateFromVendorOnBeforeVendorTemplInsert(VendorTempl, Vendor);
        VendorTempl.Insert();
    end;

    local procedure GetVendorTemplCode() VendorTemplCode: Code[20]
    var
        Vendor: Record Vendor;
        VendorTempl: Record "Vendor Templ.";
    begin
        if VendorTempl.FindLast() and (IncStr(VendorTempl.Code) <> '') then
            VendorTemplCode := VendorTempl.Code
        else
            VendorTemplCode := CopyStr(Vendor.TableCaption(), 1, 4) + '000001';

        while VendorTempl.Get(VendorTemplCode) do
            VendorTemplCode := IncStr(VendorTemplCode);
    end;

    local procedure ShowVendorTemplCard(VendorTempl: Record "Vendor Templ.")
    var
        VendorTemplCard: Page "Vendor Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        VendorTemplCard.SetRecord(VendorTempl);
        VendorTemplCard.LookupMode := true;
        if VendorTemplCard.RunModal() = Action::LookupCancel then begin
            VendorTempl.Get(VendorTempl.Code);
            VendorTempl.Delete(true);
        end;
    end;

    procedure ShowTemplates()
    var
        IsHandled: Boolean;
    begin
        OnShowTemplates(IsHandled);
    end;

    local procedure ShowVendorTemplList(var IsHandled: Boolean)
    begin
        IsHandled := true;
        Page.Run(Page::"Vendor Templ. List");
    end;

    procedure InitVendorNo(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitVendorNo(Vendor, VendorTempl, IsHandled);
        if IsHandled then
            exit;

        if VendorTempl."No. Series" = '' then
            exit;

        Vendor."No. Series" := VendorTempl."No. Series";
        if Vendor."No." <> '' then begin
            NoSeries.TestManual(Vendor."No. Series");
            exit;
        end;

        NoSeries.TestAutomatic(Vendor."No. Series");
        Vendor."No." := NoSeries.GetNextNo(Vendor."No. Series");
    end;

    local procedure TemplateFieldCanBeProcessed(FieldNumber: Integer; FieldExclusionList: List of [Integer]): Boolean
    var
        VendorField: Record Field;
        VendorTemplateField: Record Field;
    begin
        if FieldExclusionList.Contains(FieldNumber) or (FieldNumber > 2000000000) then
            exit(false);

        if not (VendorField.Get(Database::Vendor, FieldNumber) and VendorTemplateField.Get(Database::"Vendor Templ.", FieldNumber)) then
            exit(false);

        if (VendorField.Class <> VendorField.Class::Normal) or (VendorTemplateField.Class <> VendorTemplateField.Class::Normal) or
            (VendorField.Type <> VendorTemplateField.Type) or (VendorField.FieldName <> VendorTemplateField.FieldName) or
            (VendorField.Len <> VendorTemplateField.Len) or
            (VendorField.ObsoleteState = VendorField.ObsoleteState::Removed) or
            (VendorTemplateField.ObsoleteState = VendorTemplateField.ObsoleteState::Removed)
        then
            exit(false);

        exit(true);
    end;

    local procedure FillFieldExclusionList(var FieldExclusionList: List of [Integer])
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        FieldExclusionList.Add(VendorTempl.FieldNo("Invoice Disc. Code"));
        FieldExclusionList.Add(VendorTempl.FieldNo("No. Series"));
        FieldExclusionList.Add(VendorTempl.FieldNo("Contact Type"));

        OnAfterFillFieldExclusionList(FieldExclusionList);
    end;

    local procedure GetUpdateExistingValuesParam() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateExistingValuesParam(Result, IsHandled);
        if not IsHandled then
            Result := ConfirmManagement.GetResponseOrDefault(UpdateExistingValuesQst, false);
    end;

    procedure IsOpenBlankCardConfirmed() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsOpenBlankCardConfirmed(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ConfirmManagement.GetResponse(OpenBlankCardQst, false));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyVendorTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeVendorModify(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ."; UpdateExistingValues: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectVendorTemplateFromContact(var VendorTempl: Record "Vendor Templ."; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeSelectVendorTemplate(Vendor: Record Vendor; var VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVendorFromTemplate(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateFromVendorOnBeforeVendorTemplInsert(var VendorTempl: Record "Vendor Templ."; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplatesAreNotEmpty(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendorsFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsTemplate(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTemplates(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendorFromTemplate(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFieldExclusionList(var FieldExclusionList: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendorFromTemplate(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateMultipleFromTemplate(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTemplateFromVendor(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnInsertVendorFromTemplate', '', false, false)]
    local procedure OnInsertVendorFromTemplateHandler(var Vendor: Record Vendor; var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := CreateVendorFromTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnTemplatesAreNotEmpty', '', false, false)]
    local procedure OnTemplatesAreNotEmptyHandler(var Result: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        Result := VendorTemplatesAreNotEmpty(IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnUpdateVendorFromTemplate', '', false, false)]
    local procedure OnUpdateVendorFromTemplateHandler(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateFromTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnUpdateVendorsFromTemplate', '', false, false)]
    local procedure OnUpdateVendorsFromTemplateHandler(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        UpdateMultipleFromTemplate(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnSaveAsTemplate', '', false, false)]
    local procedure OnSaveAsTemplateHandler(Vendor: Record Vendor; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        CreateTemplateFromVendor(Vendor, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Vendor Templ. Mgt.", 'OnShowTemplates', '', false, false)]
    local procedure OnShowTemplatesHandler(var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        ShowVendorTemplList(IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateExistingValuesParam(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsOpenBlankCardConfirmed(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitVendorNo(var Vendor: Record Vendor; VendorTempl: Record "Vendor Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeInitVendorNo(var Vendor: Record Vendor)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. Template Management", 'OnBeforeInsertRecordWithKeyFields', '', false, false)]
    local procedure OnBeforeInsertRecordWithKeyFieldsHandler(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    begin
        FillVendorKeyFromInitSeries(RecRef, ConfigTemplateHeader);
    end;

    procedure FillVendorKeyFromInitSeries(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    var
        Vendor: Record Vendor;
        NoSeries: Codeunit "No. Series";
        FldRef: FieldRef;
    begin
        if RecRef.Number = Database::Vendor then begin
            if ConfigTemplateHeader."Instance No. Series" = '' then
                exit;

            NoSeries.TestAutomatic(ConfigTemplateHeader."Instance No. Series");

            FldRef := RecRef.Field(Vendor.FieldNo("No."));
            FldRef.Value := NoSeries.GetNextNo(ConfigTemplateHeader."Instance No. Series");
            FldRef := RecRef.Field(Vendor.FieldNo("No. Series"));
            FldRef.Value := ConfigTemplateHeader."Instance No. Series";
        end;
    end;
}
