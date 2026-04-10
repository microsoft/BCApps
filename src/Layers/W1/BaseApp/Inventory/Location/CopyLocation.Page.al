// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

page 5711 "Copy Location"
{
    Caption = 'Copy Location';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Copy Location Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(SourceLocationCode; Rec."Source Location Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Source Location Code';
                    Editable = false;
                    Lookup = true;
                    TableRelation = Location;
                    ToolTip = 'Specifies the code of the location that you want to copy the data from.';
                }
                field(TargetLocationCode; Rec."Target Location Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Target Location Code';
                    ToolTip = 'Specifies the code of the new location that you want to copy the data to.';

                    trigger OnValidate()
                    begin
                        ValidateTargetLocationCode();
                    end;
                }
                field(CopyAllInformation; ShouldCopyAllInformation)
                {
                    ApplicationArea = Location;
                    Caption = 'Copy All Information';
                    ToolTip = 'Specifies if all information is copied from the source location to the new location.';

                    trigger OnValidate()
                    begin
                        ValidateShouldCopyAllInformation();
                    end;
                }
                field(ShowCreatedLocation; Rec."Show Created Location")
                {
                    ApplicationArea = Location;
                    Caption = 'Show Created Location';
                    ToolTip = 'Specifies if the copied location is shown after it is created.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                Visible = not ShouldCopyAllInformation;
                field(Zones; Rec.Zones)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Zones';
                    ToolTip = 'Specifies if zones are also copied to the new location.';

                    trigger OnValidate()
                    begin
                        ValidateZones();
                    end;
                }
                field(Bins; Rec.Bins)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bins';
                    Enabled = BinsEnabled;
                    ToolTip = 'Specifies if bins are also copied to the new location. Bins can only be copied if zones are also being copied.';
                }
                field(WarehouseEmployees; Rec."Warehouse Employees")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Employees';
                    ToolTip = 'Specifies if warehouse employees are also copied to the new location.';
                }
                field(InventoryPostingSetup; Rec."Inventory Posting Setup")
                {
                    ApplicationArea = Location;
                    Caption = 'Inventory Posting Setup';
                    ToolTip = 'Specifies if inventory posting setup is also copied to the new location.';
                }
                field(Dimensions; Rec.Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    ToolTip = 'Specifies if dimensions are also copied to the new location.';
                }
                field(TransferRoutes; Rec."Transfer Routes")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Routes';
                    ToolTip = 'Specifies if transfer routes are also copied to the new location.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        InitCopyLocationBuffer();
        ShouldCopyAllInformation := true;
        OnBeforeValidateShouldCopyAllInformation(ShouldCopyAllInformation);
        if ShouldCopyAllInformation then
            ValidateShouldCopyAllInformation();
        UpdateBinsEnabled();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateUserInput();
    end;

    var
        TempLocation: Record Location temporary;
        SpecifyTargetLocationCodeErr: Label 'You must specify the target location code.';
        TargetLocationAlreadyExistsErr: Label 'Location %1 already exists. Please specify a different code.', Comment = '%1 = Location Code.';
        ShouldCopyAllInformation: Boolean;
        BinsEnabled: Boolean;

    procedure GetParameters(var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
        CopyLocationBuffer := Rec;
    end;

    local procedure InitCopyLocationBuffer()
    begin
        Rec.Init();
        // Default to copying all information
        Rec.Zones := true;
        Rec.Bins := true;
        Rec."Warehouse Employees" := true;
        Rec."Inventory Posting Setup" := true;
        Rec.Dimensions := true;
        Rec."Transfer Routes" := true;
        Rec."Source Location Code" := TempLocation.Code;
        Rec.Insert();

        OnAfterInitCopyLocationBuffer(Rec);
    end;

    local procedure ValidateUserInput()
    var
        TargetLocation: Record Location;
    begin
        if Rec."Target Location Code" = '' then
            Error(SpecifyTargetLocationCodeErr);

        if TargetLocation.Get(Rec."Target Location Code") then
            Error(TargetLocationAlreadyExistsErr, Rec."Target Location Code");

        OnAfterValidateUserInput(Rec);
    end;

    procedure SetLocation(var Location2: Record Location)
    begin
        TempLocation := Location2;
    end;

    local procedure ValidateShouldCopyAllInformation()
    var
        InfoFieldRef: FieldRef;
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(Rec);
        for i := 11 to 99 do
            if RecRef.FieldExist(i) then begin
                InfoFieldRef := RecRef.Field(i);
                if InfoFieldRef.Type() = FieldType::Boolean then
                    InfoFieldRef.Value := ShouldCopyAllInformation;
            end;
        RecRef.Modify();
        RecRef.SetTable(Rec);

        UpdateBinsEnabled();

        OnAfterValidateShouldCopyAllInformation(Rec, ShouldCopyAllInformation);
    end;

    local procedure ValidateTargetLocationCode()
    var
        Location: Record Location;
    begin
        if Rec."Target Location Code" <> '' then
            if Location.Get(Rec."Target Location Code") then
                Error(TargetLocationAlreadyExistsErr, Rec."Target Location Code");
    end;

    local procedure ValidateZones()
    begin
        UpdateBinsEnabled();

        // If zones are disabled, also disable bins
        if not Rec.Zones then
            Rec.Bins := false;
    end;

    local procedure UpdateBinsEnabled()
    begin
        BinsEnabled := Rec.Zones;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCopyLocationBuffer(var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateUserInput(var CopyLocationBuffer: Record "Copy Location Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShouldCopyAllInformation(var CopyLocationBuffer: Record "Copy Location Buffer"; ShouldCopyAllInfo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShouldCopyAllInformation(var CopyAllInformation: Boolean);
    begin
    end;
}
