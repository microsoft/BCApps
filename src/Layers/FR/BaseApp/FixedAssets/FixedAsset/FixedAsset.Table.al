// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Telemetry;

table 5600 "Fixed Asset"
{
    Caption = 'Fixed Asset';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Fixed Asset List";
    LookupPageID = "Fixed Asset List";
    Permissions = TableData "Ins. Coverage Ledger Entry" = r,
                  TableData Employee = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    FASetup.Get();
                    NoSeries.TestManual(FASetup."Fixed Asset Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the fixed asset.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
                if Description <> xRec.Description then begin
                    FADeprBook.SetCurrentKey("FA No.");
                    FADeprBook.SetRange("FA No.", "No.");
                    FADeprBook.ModifyAll(Description, Description);
                end;
            end;
        }
        field(3; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            OptimizeForTextSearch = true;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(5; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateFAClassCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Subclass Code" = '' then
                    exit;

                FASubclass.Get("FA Subclass Code");
                if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                    "FA Subclass Code" := '';
            end;
        }
        field(6; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateFASubclassCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Subclass Code" = '' then begin
                    Validate("FA Posting Group", '');
                    exit;
                end;

                FASubclass.Get("FA Subclass Code");
                if "FA Class Code" <> '' then begin
                    if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                        Error(UnexpctedSubclassErr);
                end else
                    Validate("FA Class Code", FASubclass."FA Class Code");

                if "FA Posting Group" = '' then
                    Validate("FA Posting Group", FASubclass."Default FA Posting Group");
            end;
        }
        field(7; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(8; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(10; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";

            trigger OnValidate()
            begin
                UpdateFALocationId();
            end;
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(12; "Main Asset/Component"; Enum "FA Component Type")
        {
            Caption = 'Main Asset/Component';
            Editable = false;
        }
        field(13; "Component of Main Asset"; Code[20])
        {
            Caption = 'Component of Main Asset';
            Editable = false;
            TableRelation = "Fixed Asset";
        }
        field(14; "Budgeted Asset"; Boolean)
        {
            Caption = 'Budgeted Asset';

            trigger OnValidate()
            begin
                FAMoveEntries.ChangeBudget(Rec);
            end;
        }
        field(15; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(16; "Responsible Employee"; Code[20])
        {
            Caption = 'Responsible Employee';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                UpdateResponsibleEmployeeId();
            end;
        }
        field(17; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
            OptimizeForTextSearch = true;
        }
        field(18; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(19; Insured; Boolean)
        {
            CalcFormula = exist("Ins. Coverage Ledger Entry" where("FA No." = field("No."),
                                                                    "Disposed FA" = const(false)));
            Caption = 'Insured';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("Fixed Asset"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(23; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            TableRelation = Vendor;
        }
        field(24; "Under Maintenance"; Boolean)
        {
            Caption = 'Under Maintenance';
        }
        field(25; "Next Service Date"; Date)
        {
            Caption = 'Next Service Date';
        }
        field(26; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
        field(27; "FA Posting Date Filter"; Date)
        {
            Caption = 'FA Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(29; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";

            trigger OnValidate()
            var
                FALedgerEntry: Record "FA Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFAPostingGroup(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "FA Posting Group" <> xRec."FA Posting Group" then begin
                    FALedgerEntry.SetRange("FA No.", "No.");
                    if not FALedgerEntry.IsEmpty() then
                        Error(FoundFALedgerEntriesErr);
                end;
            end;
        }
        field(30; Acquired; Boolean)
        {
            CalcFormula = exist("FA Depreciation Book" where("FA No." = field("No."),
                                                              "Acquisition Date" = filter(<> 0D)));
            Caption = 'Acquired';
            FieldClass = FlowField;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(9001; "FA Location Id"; Guid)
        {
            Caption = 'FA Location Id';
            DataClassification = SystemMetadata;
            TableRelation = "FA Location".SystemId;

            trigger OnValidate()
            begin
                UpdateFALocationCode();
            end;
        }
        field(9002; "Responsible Employee Id"; Guid)
        {
            Caption = 'Responsible Employee';
            DataClassification = SystemMetadata;
            TableRelation = Employee.SystemId;


            trigger OnValidate()
            begin
                UpdateResponsibleEmployeeCode();
            end;
        }
        field(10810; "Professional Tax"; Option)
        {
            Caption = 'Professional Tax';
            OptionCaption = 'No Tax,Fixed Asset for more than 30 years 1,Fixed Asset for more than 30 years 2,Fixed Asset less than 30 years';
            OptionMembers = "No Tax","Fixed Asset for more than 30 years 1","Fixed Asset for more than 30 years 2","Fixed Asset less than 30 years";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "FA Class Code")
        {
        }
        key(Key4; "FA Subclass Code")
        {
        }
        key(Key5; "Component of Main Asset", "Main Asset/Component")
        {
        }
        key(Key6; "FA Location Code")
        {
        }
        key(Key7; "Global Dimension 1 Code")
        {
        }
        key(Key8; "Global Dimension 2 Code")
        {
        }
        key(Key9; "FA Posting Group")
        {
        }
        key(Key10; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "FA Class Code")
        {
        }
        fieldgroup(Brick; "No.", Description, "FA Class Code", Image)
        {
        }
    }

    trigger OnDelete()
    var
        FADeprBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        MainAssetComp.LockTable();
        InsCoverageLedgEntry.LockTable();
        if "Main Asset/Component" = "Main Asset/Component"::"Main Asset" then
            Error(Text000);
        FAMoveEntries.MoveFAInsuranceEntries("No.");
        FADeprBook.SetRange("FA No.", "No.");
        FADeprBook.DeleteAll(true);
        if not FADeprBook.IsEmpty() then
            Error(Text001, TableCaption(), "No.");

        MainAssetComp.SetCurrentKey("FA No.");
        MainAssetComp.SetRange("FA No.", "No.");
        MainAssetComp.DeleteAll();
        if "Main Asset/Component" = "Main Asset/Component"::Component then begin
            MainAssetComp.Reset();
            MainAssetComp.SetRange("Main Asset No.", "Component of Main Asset");
            MainAssetComp.SetRange("FA No.", '');
            MainAssetComp.DeleteAll();
            MainAssetComp.SetRange("FA No.");
            if not MainAssetComp.FindFirst() then begin
                FA.Get("Component of Main Asset");
                FA."Main Asset/Component" := FA."Main Asset/Component"::" ";
                FA."Component of Main Asset" := '';
                FA.Modify();
            end;
        end;

        MaintenanceRegistration.SetRange("FA No.", "No.");
        MaintenanceRegistration.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Fixed Asset");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"Fixed Asset", "No.");
    end;

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000H4G', 'Fixed Asset', Enum::"Feature Uptake Status"::"Set up");
        InitFANo();

        "Main Asset/Component" := "Main Asset/Component"::" ";
        "Component of Main Asset" := '';

        DimMgt.UpdateDefaultDim(
          DATABASE::"Fixed Asset", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");

        UpdateFALocationId();
        UpdateResponsibleEmployeeId();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"Fixed Asset", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"Fixed Asset", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"Fixed Asset", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Fixed Asset", xRec."No.", "No.");

        "Last Date Modified" := Today;
    end;

    var
        CommentLine: Record "Comment Line";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        MaintenanceRegistration: Record "Maintenance Registration";
        MainAssetComp: Record "Main Asset Component";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FAMoveEntries: Codeunit "FA MoveEntries";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;

#pragma warning disable AA0074
        Text000: Label 'A main asset cannot be deleted.';
#pragma warning disable AA0470
        Text001: Label 'You cannot delete %1 %2 because it has associated depreciation books.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UnexpctedSubclassErr: Label 'This fixed asset subclass belongs to a different fixed asset class.';
        DontAskAgainActionTxt: Label 'Don''t ask again';
        NotificationNameTxt: Label 'Fixed Asset Acquisition Wizard';
        NotificationDescriptionTxt: Label 'Notify when ready to acquire the fixed asset.';
        ReadyToAcquireMsg: Label 'You are ready to acquire the fixed asset.';
        AcquireActionTxt: Label 'Acquire';
        FoundFALedgerEntriesErr: Label 'You cannot change the FA posting group because posted FA ledger entries use the existing posting group.';

    procedure AssistEdit(OldFA: Record "Fixed Asset") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(FASetup, FA, Rec, Result, IsHandled, OldFA);
        if IsHandled then
            exit(Result);

        FA := Rec;
        FASetup.Get();
        FASetup.TestField("Fixed Asset Nos.");
        if NoSeries.LookupRelatedNoSeries(FASetup."Fixed Asset Nos.", OldFA."No. Series", FA."No. Series") then begin
            FA."No." := NoSeries.GetNextNo(FA."No. Series");
            Rec := FA;
            exit(true);
        end;
    end;

    local procedure InitFANo()
    var
        FixedAsset: Record "Fixed Asset";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFANo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            FASetup.Get();
            FASetup.TestField("Fixed Asset Nos.");
            if NoSeries.AreRelated(FASetup."Fixed Asset Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := FASetup."Fixed Asset Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            FixedAsset.ReadIsolation(IsolationLevel::ReadUncommitted);
            FixedAsset.SetLoadFields("No.");
            while FixedAsset.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if not IsHandled then begin
            DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
            if not IsTemporary then begin
                DimMgt.SaveDefaultDim(DATABASE::"Fixed Asset", "No.", FieldNumber, ShortcutDimCode);
                Modify(true);
            end;
        end;
        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure FieldsForAcquitionInGeneralGroupAreCompleted(): Boolean
    begin
        exit(("No." <> '') and (Description <> '') and ("FA Subclass Code" <> ''));
    end;

    procedure ShowAcquireWizardNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        FAAcquireWizardNotification: Notification;
    begin
        if IsNotificationEnabledForCurrentUser() then begin
            FAAcquireWizardNotification.Id(GetNotificationID());
            FAAcquireWizardNotification.Message(ReadyToAcquireMsg);
            FAAcquireWizardNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            FAAcquireWizardNotification.AddAction(
              AcquireActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'RunAcquisitionWizardFromNotification');
            FAAcquireWizardNotification.AddAction(
              DontAskAgainActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'HideNotificationForCurrentUser');
            FAAcquireWizardNotification.SetData(FixedAssetAcquisitionWizard.GetNotificationFANoDataItemID(), "No.");
            NotificationLifecycleMgt.SendNotification(FAAcquireWizardNotification, RecordId);
        end
    end;

    local procedure UpdateFALocationId()
    var
        FALocation: Record "FA Location";
    begin
        if "FA Location Code" = '' then begin
            Clear("FA Location Id");
            exit;
        end;

        if not FALocation.Get("FA Location Code") then
            exit;

        "FA Location Id" := FALocation.SystemId;
    end;

    local procedure UpdateFALocationCode()
    var
        FALocation: Record "FA Location";
    begin
        if not IsNullGuid("FA Location Id") then
            FALocation.GetBySystemId("FA Location Id");

        "FA Location Code" := FALocation.Code;
    end;

    local procedure UpdateResponsibleEmployeeId()
    var
        Employee: Record Employee;
    begin
        if "Responsible Employee" = '' then begin
            Clear("Responsible Employee Id");
            exit;
        end;

        if not Employee.Get("Responsible Employee") then
            exit;

        "Responsible Employee Id" := Employee.SystemId;
    end;

    local procedure UpdateResponsibleEmployeeCode()
    var
        Employee: Record Employee;
    begin
        if not IsNullGuid("Responsible Employee Id") then
            Employee.GetBySystemId("Responsible Employee Id");

        "Responsible Employee" := Employee."No.";
    end;

    procedure GetNotificationID(): Guid
    begin
        exit('3d5c2f86-cfb9-4407-97c3-9df74c7696c9');
    end;

    procedure SetNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetNotificationID(), NotificationNameTxt, NotificationDescriptionTxt, true);
    end;

    local procedure IsNotificationEnabledForCurrentUser(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationID()));
    end;

    procedure DontNotifyCurrentUserAgain()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationID()) then
            MyNotifications.InsertDefault(GetNotificationID(), NotificationNameTxt, NotificationDescriptionTxt, false);
    end;

    procedure RecallNotificationForCurrentUser()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordId, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var FASetup: Record "FA Setup"; var FixedAsset: Record "Fixed Asset"; var Rec: Record "Fixed Asset"; var Result: Boolean; var IsHandled: Boolean; OldFixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFANo(var FixedAsset: Record "Fixed Asset"; xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var FixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateFASubclassCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnValidateFAClassCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFAPostingGroup(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;
}