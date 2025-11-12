// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using System.Utilities;

table 5950 "Service Order Allocation"
{
    Caption = 'Service Order Allocation';
    DrillDownPageID = "Service Order Allocations";
    LookupPageID = "Service Order Allocations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Nonactive,Active,Finished,Canceled,Reallocation Needed';
            OptionMembers = Nonactive,Active,Finished,Canceled,"Reallocation Needed";

            trigger OnValidate()
            begin
                case Status of
                    Status::Canceled:
                        begin
                            Clear(ServLogMgt);
                            ServLogMgt.ServHeaderCancelAllocation("Resource No.", "Document Type".AsInteger(), "Document No.", "Service Item Line No.");
                        end;
                    Status::Active:
                        begin
                            Clear(ServLogMgt);
                            ServLogMgt.ServHeaderAllocation("Resource No.", "Document Type".AsInteger(), "Document No.", "Service Item Line No.");
                        end;
                    Status::"Reallocation Needed":
                        begin
                            Clear(ServLogMgt);
                            ServLogMgt.ServHeaderReallocationNeeded("Resource No.", "Document Type".AsInteger(), "Document No.", "Service Item Line No.");
                        end;
                end;
            end;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;

            trigger OnLookup()
            var
                ServOrderNo: Code[20];
            begin
                ServOrderNo := "Document No.";
                Clear(ServOrderMgt);
                ServOrderMgt.ServHeaderLookup("Document Type".AsInteger(), ServOrderNo);
            end;
        }
        field(4; "Allocation Date"; Date)
        {
            Caption = 'Allocation Date';

            trigger OnValidate()
            begin
                if "Allocation Date" = 0D then
                    if Status <> Status::Nonactive then
                        Error(Text001, FieldCaption("Allocation Date"), FieldCaption(Status), Status);

                if "Allocation Date" < WorkDate() then
                    Message(Text002, FieldCaption("Allocation Date"), "Allocation Date");
            end;
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if "Resource No." <> '' then begin
                    ServmgtSetup.Get();
                    Res.Get("Resource No.");
                    "Resource Group No." := Res."Resource Group No.";
                    if ServmgtSetup."Resource Skills Option" = ServmgtSetup."Resource Skills Option"::"Warning Displayed"
                    then
                        if "Service Item Line No." <> 0 then begin
                            ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                            if not
                               ServOrderAllocMgt.QualifiedForServiceItemLine(ServItemLine, "Resource No.")
                            then
                                Error(Text003, FieldCaption("Resource No."), "Resource No.");
                        end;

                    if ServmgtSetup."Service Zones Option" = ServmgtSetup."Service Zones Option"::"Warning Displayed"
                    then begin
                        ServHeader.Get(Rec."Document Type", Rec."Document No.");
                        Res."Service Zone Filter" := ServHeader."Service Zone Code";
                        Res.CalcFields("In Customer Zone");

                        if not Res."In Customer Zone" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(
                                   Text004,
                                   FieldCaption("Resource No."),
                                   "Resource No.",
                                   ServHeader.FieldCaption("Service Zone Code"),
                                   ServHeader."Service Zone Code"), true)
                            then
                                Error('');
                    end;

                    if (Status = Status::"Reallocation Needed") or (Status = Status::Active) then
                        CreateReallocationEntry();
                end;
            end;
        }
        field(6; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                if ("Resource Group No." <> '') and
                   ("Resource Group No." <> xRec."Resource Group No.")
                then begin
                    if Res.Get("Resource No.") then
                        if "Resource Group No." <> Res."Resource Group No." then
                            "Resource No." := '';
                    if (Status = Status::"Reallocation Needed") or (Status = Status::Active) then
                        CreateReallocationEntry();
                end;
            end;
        }
        field(7; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            TableRelation = "Service Item Line"."Line No." where("Document Type" = field("Document Type"),
                                                                  "Document No." = field("Document No."));

            trigger OnValidate()
            var
                ServOrderManagement: Codeunit ServOrderManagement;
            begin
                if not HideDialog and ServHeader.Get("Document Type", "Document No.") then
                    ServOrderAllocMgt.CheckServiceItemLineFinished(ServHeader, "Service Item Line No.");
                if ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.") then begin
                    ServOrderManagement.CheckServiceItemBlockedForAll(ServItemLine);
                    "Service Item No." := ServItemLine."Service Item No.";
                    "Service Item Serial No." := ServItemLine."Serial No.";
                end else begin
                    "Service Item No." := '';
                    "Service Item Serial No." := '';
                end;

                CalcFields("Service Item Description");
            end;
        }
        field(8; "Allocated Hours"; Decimal)
        {
            Caption = 'Allocated Hours';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Allocated Hours" = 0 then
                    if Status <> Status::Nonactive then
                        Error(
                          Text005,
                          FieldCaption("Allocated Hours"), FieldCaption(Status), Status);
            end;
        }
        field(9; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                ValidateStartEndTime();
            end;
        }
        field(10; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';

            trigger OnValidate()
            begin
                ValidateStartEndTime();
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(13; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = if ("Document Type" = filter(<> "Credit Memo")) "Service Item"."No." where(Blocked = filter(<> All))
            else
            if ("Document Type" = filter("Credit Memo")) "Service Item"."No.";

            trigger OnLookup()
            begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "Document No.");
                ServItemLine."Service Item No." := "Service Item No.";
                if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                    Validate("Service Item Line No.", ServItemLine."Line No.");
            end;

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then begin
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Service Item No.", "Service Item No.");
                    ServItemLine.FindFirst();
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;
            end;
        }
        field(14; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(15; "Service Item Description"; Text[100])
        {
            CalcFormula = lookup("Service Item Line".Description where("Document Type" = field("Document Type"),
                                                                        "Document No." = field("Document No."),
                                                                        "Line No." = field("Service Item Line No.")));
            Caption = 'Service Item Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';

            trigger OnLookup()
            begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "Document No.");
                ServItemLine."Serial No." := "Service Item Serial No.";
                if PAGE.RunModal(0, ServItemLine) = ACTION::LookupOK then
                    Validate("Service Item Line No.", ServItemLine."Line No.");
            end;

            trigger OnValidate()
            begin
                if "Service Item Serial No." <> '' then begin
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetRange("Serial No.", "Service Item Serial No.");
                    ServItemLine.FindFirst();
                    Validate("Service Item Line No.", ServItemLine."Line No.");
                end;
            end;
        }
        field(17; "Repair Status"; Code[20])
        {
            CalcFormula = lookup("Service Item Line"."Repair Status Code" where("Document Type" = field("Document Type"),
                                                                                 "Document No." = field("Document No."),
                                                                                 "Line No." = field("Service Item Line No.")));
            Caption = 'Repair Status';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Service Started"; Boolean)
        {
            Caption = 'Service Started';
        }
        field(19; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Status, "Document Type", "Document No.", "Service Item Line No.", "Allocation Date", "Starting Time", Posted)
        {
            SumIndexFields = "Allocated Hours";
        }
        key(Key3; "Document Type", "Document No.", Status, "Resource Group No.", "Allocation Date", "Starting Time", Posted)
        {
            SumIndexFields = "Allocated Hours";
        }
        key(Key4; Status, "Document Type", "Document No.", "Service Item Line No.", "Resource No.", "Allocation Date", "Starting Time", Posted)
        {
            SumIndexFields = "Allocated Hours";
        }
        key(Key5; "Document Type", "Document No.", "Service Item Line No.", "Allocation Date", "Starting Time", Posted)
        {
            SumIndexFields = "Allocated Hours";
        }
        key(Key6; "Resource No.", "Document Type", "Allocation Date", Status, Posted)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if not HideDialog and ServHeader.Get("Document Type", "Document No.") then
            ServOrderAllocMgt.CheckServiceItemLineFinished(ServHeader, "Service Item Line No.");
    end;

    trigger OnInsert()
    begin
        ServOrderAlloc.Reset();
        if ServOrderAlloc.Find('+') then
            "Entry No." := ServOrderAlloc."Entry No." + 1
        else
            "Entry No." := 1;
        TestField("Document No.");

        if ("Service Item Line No." <> 0) and
           ("Resource No." <> '')
        then begin
            CheckAllocationEntry();
            if not HideDialog and ServHeader.Get("Document Type", "Document No.") then
                ServOrderAllocMgt.CheckServiceItemLineFinished(ServHeader, "Service Item Line No.");
        end;

        if Status = Status::Nonactive then begin
            if ("Resource No." <> '') or
               ("Resource Group No." <> '')
            then
                CheckAllocationEntry();

            if ("Allocation Date" <> 0D) and
               (("Resource No." <> '') or ("Resource Group No." <> ''))
            then
                Validate(Status, Status::Active);
        end;
    end;

    trigger OnModify()
    begin
        TestField("Service Item Line No.");
        if not HideDialog and ServHeader.Get("Document Type", "Document No.") then begin
            ServOrderAllocMgt.CheckServiceItemLineFinished(ServHeader, xRec."Service Item Line No.");
            ServOrderAllocMgt.CheckServiceItemLineFinished(ServHeader, "Service Item Line No.");
        end;
        if Status = Status::Active then
            if ("Resource No." = '') and
               ("Resource Group No." = '')
            then
                Error(Text008, FieldCaption("Resource No."), FieldCaption("Resource Group No."));
        CheckAllocationEntry();

        if Status = Status::Nonactive then
            if ("Allocation Date" <> 0D) and
               (("Resource No." <> '') or ("Resource Group No." <> ''))
            then
                Validate(Status, Status::Active);
    end;

    var
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServmgtSetup: Record "Service Mgt. Setup";
        ServOrderAlloc: Record "Service Order Allocation";
        ServOrderAlloc2: Record "Service Order Allocation";
        Res: Record Resource;
        ResGr: Record "Resource Group";
        RepairStatus: Record "Repair Status";
        RepairStatus2: Record "Repair Status";
        ServOrderMgt: Codeunit ServOrderManagement;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        ServLogMgt: Codeunit ServLogManagement;
        ReallocEntryReasons: Page "Reallocation Entry Reasons";
        ChangeServItemLine: Boolean;
        HideDialog: Boolean;
        RepairStatusCode: Code[10];
        Flag: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Only one %1 can be allocated to a %2.';
        Text001: Label '%1 must be filled in when the %2 is %3.';
        Text002: Label 'The %1 %2 has expired.';
        Text003: Label '%1 %2 is not qualified to carry out the service.';
        Text004: Label '%1 %2 is not working in %3 %4.';
        Text005: Label '%1 must be greater than 0 when the %2 is %3.';
        Text006: Label '%1 cannot be greater than %2.';
        Text007: Label '%1 with the field %2 selected cannot be found.';
        Text008: Label '%1 and %2 cannot be blank at the same time.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateStartEndTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateStartEndTime(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Starting Time" = 0T then
            exit;
        if "Finishing Time" = 0T then
            exit;
        if "Starting Time" > "Finishing Time" then
            Error(Text006, FieldCaption("Starting Time"), FieldCaption("Finishing Time"));
    end;

    local procedure CreateReallocationEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReallocationEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        RepairStatus2.Reset();
        RepairStatus2.SetRange(Initial, true);
        if RepairStatus2.FindFirst() then
            RepairStatusCode := RepairStatus2.Code;

        ChangeServItemLine := false;

        Clear(ReallocEntryReasons);
        ReallocEntryReasons.SetRecord(Rec);
        ReallocEntryReasons.SetTableView(Rec);
        ReallocEntryReasons.SetNewResource("Resource No.", "Resource Group No.");

        Flag := false;
        if not HideDialog then
            Flag := ReallocEntryReasons.RunModal() = ACTION::Yes
        else
            Flag := true;
        if Flag then begin
            "Reason Code" := ReallocEntryReasons.ReturnReasonCode();
            ServOrderAlloc2 := Rec;
            ServOrderAlloc.Reset();
            if ServOrderAlloc.Find('+') then
                ServOrderAlloc2."Entry No." := ServOrderAlloc."Entry No." + 1;
            CalcFields("Repair Status");
            RepairStatus.Get("Repair Status");
            if Status = Status::Active then begin
                OnCreateReallocationEntryOnBeforeResetRepairStatus(Rec);
                if RepairStatus.Initial then begin
                    RepairStatus2.Reset();
                    RepairStatus2.SetRange(Referred, true);
                    if RepairStatus2.FindFirst() then begin
                        ChangeServItemLine := true;
                        RepairStatusCode := RepairStatus2.Code;
                        Validate(Status, Status::Active);
                        ServOrderAlloc2."Resource No." := xRec."Resource No.";
                        ServOrderAlloc2."Resource Group No." := xRec."Resource Group No.";
                        ServOrderAlloc2."Reason Code" := xRec."Reason Code";
                        if "Service Started" then
                            ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Finished)
                        else
                            ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Canceled);
                        ServOrderAlloc2.Insert();
                    end else
                        Error(
                          Text007,
                          RepairStatus.TableCaption(), RepairStatus.FieldCaption(Referred));
                end else
                    if RepairStatus."In Process" then begin
                        RepairStatus2.Reset();
                        RepairStatus2.SetRange("Partly Serviced", true);
                        if RepairStatus2.FindFirst() then begin
                            RepairStatusCode := RepairStatus2.Code;
                            ChangeServItemLine := true;
                            Validate(Status, Status::Active);
                            ServOrderAlloc2."Resource No." := xRec."Resource No.";
                            ServOrderAlloc2."Resource Group No." := xRec."Resource Group No.";
                            ServOrderAlloc2."Reason Code" := xRec."Reason Code";
                            if "Service Started" then
                                ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Finished)
                            else
                                ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Canceled);
                            ServOrderAlloc2.Insert();
                        end else
                            Error(
                              Text007,
                              RepairStatus.TableCaption(), RepairStatus.FieldCaption("Partly Serviced"));
                    end else begin
                        Validate(Status, Status::Active);
                        ServOrderAlloc2."Resource No." := xRec."Resource No.";
                        ServOrderAlloc2."Resource Group No." := xRec."Resource Group No.";
                        ServOrderAlloc2."Reason Code" := xRec."Reason Code";
                        if "Service Started" then
                            ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Finished)
                        else
                            ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Canceled);
                        ServOrderAlloc2.Insert();
                    end;
            end else begin
                Validate(Status, Status::Active);
                ServOrderAlloc2."Resource No." := xRec."Resource No.";
                ServOrderAlloc2."Resource Group No." := xRec."Resource Group No.";
                ServOrderAlloc2."Reason Code" := xRec."Reason Code";
                if "Service Started" then
                    ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Finished)
                else
                    ServOrderAlloc2.Validate(Status, ServOrderAlloc2.Status::Canceled);
                ServOrderAlloc2.Insert();
            end;
            if ChangeServItemLine then begin
                TestField("Service Item Line No.");
                ServItemLine.Get("Document Type", "Document No.", "Service Item Line No.");
                ServItemLine."Repair Status Code" := RepairStatusCode;
                ServItemLine.Modify(true);
            end;
        end else begin
            "Resource No." := xRec."Resource No.";
            "Resource Group No." := xRec."Resource Group No.";
            exit;
        end;
    end;

    procedure GetHideDialog(): Boolean
    begin
        exit(HideDialog);
    end;

    procedure SetHideDialog(HideDialog1: Boolean)
    begin
        HideDialog := HideDialog1;
    end;

    local procedure CheckAllocationEntry()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAllocationEntry(Rec, IsHandled);
        if IsHandled then
            exit;

        if not HideDialog then begin
            ServOrderAlloc.Reset();
            ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServOrderAlloc.SetRange("Document Type", "Document Type");
            ServOrderAlloc.SetRange("Document No.", "Document No.");
            ServOrderAlloc.SetRange("Service Item Line No.", "Service Item Line No.");
            ServOrderAlloc.SetFilter("Entry No.", '<>%1', "Entry No.");
            ServOrderAlloc.SetFilter(Status, '%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::"Reallocation Needed");
            if ServOrderAlloc.Find('-') then
                repeat
                    if ("Resource No." <> '') and
                       (ServOrderAlloc."Resource No." <> '') and
                       (ServOrderAlloc."Resource No." <> "Resource No.")
                    then
                        Error(Text000, Res.TableCaption(), ServItemLine.TableCaption());

                    if ("Resource Group No." <> '') and
                       (ServOrderAlloc."Resource Group No." <> '') and
                       (ServOrderAlloc."Resource Group No." <> "Resource Group No.")
                    then
                        Error(Text000, ResGr.TableCaption(), ServItemLine.TableCaption());
                until ServOrderAlloc.Next() = 0;
        end;
    end;

    procedure SetFilters(ServiceItemLine: Record "Service Item Line")
    begin
        Reset();
        SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        SetRange("Document Type", ServiceItemLine."Document Type");
        SetRange("Document No.", ServiceItemLine."Document No.");
        SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        SetRange(Status, ServOrderAlloc.Status::Active);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAllocationEntry(var ServiceOrderAllocation: Record "Service Order Allocation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReallocationEntry(var ServiceOrderAllocation: Record "Service Order Allocation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartEndTime(var ServiceOrderAllocation: Record "Service Order Allocation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReallocationEntryOnBeforeResetRepairStatus(var ServiceOrderAllocation: Record "Service Order Allocation")
    begin
    end;
}

