// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;

table 99000764 "Routing Line"
{
    Caption = 'Routing Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            NotBlank = true;
            TableRelation = "Routing Header";
        }
        field(2; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                TestStatus();

                SetRecalcStatus();
            end;
        }
        field(5; "Next Operation No."; Code[30])
        {
            Caption = 'Next Operation No.';

            trigger OnValidate()
            begin
                SetRecalcStatus();
            end;
        }
        field(6; "Previous Operation No."; Code[30])
        {
            Caption = 'Previous Operation No.';

            trigger OnValidate()
            begin
                SetRecalcStatus();
            end;
        }
        field(7; Type; Enum "Capacity Type Routing")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                SetRecalcStatus();

                "No." := '';
                "Work Center No." := '';
                "Work Center Group Code" := '';
            end;
        }
        field(8; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Work Center")) "Work Center"
            else
            if (Type = const("Machine Center")) "Machine Center";

            trigger OnValidate()
            begin
                SetRecalcStatus();

                if "No." = '' then
                    exit;

                case Type of
                    Type::"Work Center":
                        begin
                            WorkCenter.Get("No.");
                            WorkCenter.TestField(Blocked, false);
                            WorkCenterTransferFields();
                        end;
                    Type::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField(Blocked, false);
                            MachineCtrTransferFields();
                        end;
                end;

                "Unit Cost per" := 0;
            end;
        }
        field(9; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            Editable = false;
            TableRelation = "Work Center";
        }
        field(10; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            Editable = false;
            TableRelation = "Work Center Group";
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(13; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(14; "Wait Time"; Decimal)
        {
            Caption = 'Wait Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Move Time"; Decimal)
        {
            Caption = 'Move Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Fixed Scrap Quantity"; Decimal)
        {
            Caption = 'Fixed Scrap Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                SetRecalcStatus();
            end;
        }
        field(17; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Scrap Factor %"; Decimal)
        {
            Caption = 'Scrap Factor %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                SetRecalcStatus();
            end;
        }
        field(19; "Setup Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Setup Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(20; "Run Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Run Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(21; "Wait Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Wait Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(22; "Move Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Move Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(27; "Minimum Process Time"; Decimal)
        {
            Caption = 'Minimum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(28; "Maximum Process Time"; Decimal)
        {
            Caption = 'Maximum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(30; "Concurrent Capacities"; Decimal)
        {
            Caption = 'Concurrent Capacities';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            MinValue = 0;
        }
        field(31; "Send-Ahead Quantity"; Decimal)
        {
            Caption = 'Send-Ahead Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(34; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";
        }
        field(35; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";

            trigger OnValidate()
            var
                StandardTask: Record "Standard Task";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStandardTaskCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Standard Task Code" = '' then
                    if "Standard Task Code" <> xRec."Standard Task Code" then begin
                        DeleteRelations();
                        exit;
                    end;

                StandardTask.Get("Standard Task Code");
                Description := StandardTask.Description;

                DeleteRelations();

                StdTaskTool.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskTool.Find('-') then
                    repeat
                        RtngTool.Init();
                        RtngTool."Routing No." := "Routing No.";
                        RtngTool."Version Code" := "Version Code";
                        RtngTool."Operation No." := "Operation No.";
                        RtngTool."Line No." := StdTaskTool."Line No.";
                        RtngTool."No." := StdTaskTool."No.";
                        RtngTool.Description := StdTaskTool.Description;
                        OnValidateStandardTaskCodeOnBeforeRtngToolInsert(RtngTool, StdTaskTool);
                        RtngTool.Insert();
                    until StdTaskTool.Next() = 0;

                StdTaskPersonnel.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskPersonnel.Find('-') then
                    repeat
                        RtngPersonnel.Init();
                        RtngPersonnel."Routing No." := "Routing No.";
                        RtngPersonnel."Version Code" := "Version Code";
                        RtngPersonnel."Operation No." := "Operation No.";
                        RtngPersonnel."Line No." := StdTaskPersonnel."Line No.";
                        RtngPersonnel."No." := StdTaskPersonnel."No.";
                        RtngPersonnel.Description := StdTaskPersonnel.Description;
                        OnValidateStandardTaskCodeOnBeforeRtngPersonnelInsert(RtngPersonnel, StdTaskPersonnel);
                        RtngPersonnel.Insert();
                    until StdTaskPersonnel.Next() = 0;

                StdTaskQltyMeasure.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskQltyMeasure.Find('-') then
                    repeat
                        RtngQltyMeasure.Init();
                        RtngQltyMeasure."Routing No." := "Routing No.";
                        RtngQltyMeasure."Version Code" := "Version Code";
                        RtngQltyMeasure."Operation No." := "Operation No.";
                        RtngQltyMeasure."Line No." := StdTaskQltyMeasure."Line No.";
                        RtngQltyMeasure."Qlty Measure Code" := StdTaskQltyMeasure."Qlty Measure Code";
                        RtngQltyMeasure.Description := StdTaskQltyMeasure.Description;
                        RtngQltyMeasure."Min. Value" := StdTaskQltyMeasure."Min. Value";
                        RtngQltyMeasure."Max. Value" := StdTaskQltyMeasure."Max. Value";
                        RtngQltyMeasure."Mean Tolerance" := StdTaskQltyMeasure."Mean Tolerance";
                        OnValidateStandardTaskCodeOnBeforeRtngQltyMeasureInsert(RtngQltyMeasure, StdTaskQltyMeasure);
                        RtngQltyMeasure.Insert();
                    until StdTaskQltyMeasure.Next() = 0;

                StdTaskComment.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskComment.Find('-') then
                    repeat
                        RtngComment."Routing No." := "Routing No.";
                        RtngComment."Version Code" := "Version Code";
                        RtngComment."Operation No." := "Operation No.";
                        RtngComment."Line No." := StdTaskComment."Line No.";
                        RtngComment.Comment := StdTaskComment.Text;
                        OnValidateStandardTaskCodeOnBeforeRtngCommentLineInsert(RtngComment, StdTaskComment);
                        RtngComment.Insert();
                    until StdTaskComment.Next() = 0;
            end;
        }
        field(40; "Unit Cost per"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost per';
            MinValue = 0;
        }
        field(41; Recalculate; Boolean)
        {
            Caption = 'Recalculate';
            Editable = false;
        }
        field(45; Comment; Boolean)
        {
            CalcFormula = exist("Routing Comment Line" where("Routing No." = field("Routing No."),
                                                              "Version Code" = field("Version Code"),
                                                              "Operation No." = field("Operation No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Sequence No. (Forward)"; Integer)
        {
            Caption = 'Sequence No. (Forward)';
            Editable = false;
        }
        field(51; "Sequence No. (Backward)"; Integer)
        {
            Caption = 'Sequence No. (Backward)';
            Editable = false;
        }
        field(52; "Fixed Scrap Qty. (Accum.)"; Decimal)
        {
            Caption = 'Fixed Scrap Qty. (Accum.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Scrap Factor % (Accumulated)"; Decimal)
        {
            Caption = 'Scrap Factor % (Accumulated)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Routing No.", "Version Code", "Operation No.")
        {
            Clustered = true;
        }
        key(Key2; "Routing No.", "Version Code", "Sequence No. (Forward)")
        {
        }
        key(Key3; "Routing No.", "Version Code", "Sequence No. (Backward)")
        {
        }
        key(Key4; "Work Center No.")
        {
        }
        key(Key5; Type, "No.")
        {
        }
        key(Key6; "Routing Link Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatus();

        DeleteRelations();
    end;

    trigger OnInsert()
    begin
        TestStatus();
    end;

    trigger OnModify()
    begin
        TestStatus();
    end;

    trigger OnRename()
    begin
        TestStatus();

        SetRecalcStatus();
    end;

    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RtngTool: Record "Routing Tool";
        RtngPersonnel: Record "Routing Personnel";
        RtngQltyMeasure: Record "Routing Quality Measure";
        RtngComment: Record "Routing Comment Line";
        StdTaskTool: Record "Standard Task Tool";
        StdTaskPersonnel: Record "Standard Task Personnel";
        StdTaskQltyMeasure: Record "Standard Task Quality Measure";
        StdTaskComment: Record "Standard Task Description";
        CannotDeleteCertifiedRoutingExistsErr: Label 'You cannot delete %1 %2 because there is at least one certified routing associated with it.', Comment = '%1 = Routing Line Type option; %2 = No.';
        CannotDeleteCertifiedRoutingVersionExistsErr: Label 'You cannot delete %1 %2 because there is at least one certified routing version associated with it.', Comment = '%1 = Routing Line Type option; %2 = No.';

    procedure TestStatus()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        IsHandled: Boolean;
    begin
        if IsTemporary then
            exit;

        IsHandled := false;
        OnBeforeTestStatus(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Version Code" = '' then begin
            RoutingHeader.Get("Routing No.");
            if RoutingHeader.Status = RoutingHeader.Status::Certified then
                RoutingHeader.FieldError(Status);
        end else begin
            RoutingVersion.Get("Routing No.", "Version Code");
            if RoutingVersion.Status = RoutingVersion.Status::Certified then
                RoutingVersion.FieldError(Status);
        end;
    end;

    procedure DeleteRelations()
    begin
        RtngTool.SetRange("Routing No.", "Routing No.");
        RtngTool.SetRange("Version Code", "Version Code");
        RtngTool.SetRange("Operation No.", "Operation No.");
        RtngTool.DeleteAll();

        RtngPersonnel.SetRange("Routing No.", "Routing No.");
        RtngPersonnel.SetRange("Version Code", "Version Code");
        RtngPersonnel.SetRange("Operation No.", "Operation No.");
        RtngPersonnel.DeleteAll();

        RtngQltyMeasure.SetRange("Routing No.", "Routing No.");
        RtngQltyMeasure.SetRange("Version Code", "Version Code");
        RtngQltyMeasure.SetRange("Operation No.", "Operation No.");
        RtngQltyMeasure.DeleteAll();

        RtngComment.SetRange("Routing No.", "Routing No.");
        RtngComment.SetRange("Version Code", "Version Code");
        RtngComment.SetRange("Operation No.", "Operation No.");
        RtngComment.DeleteAll();

        OnAfterDeleteRelations(Rec);
    end;

    local procedure WorkCenterTransferFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWorkCenterTransferFields(Rec, xRec, WorkCenter, IsHandled);
        if not IsHandled then begin
            "Work Center No." := WorkCenter."No.";
            "Work Center Group Code" := WorkCenter."Work Center Group Code";
            if "Setup Time Unit of Meas. Code" = '' then
                "Setup Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            if "Run Time Unit of Meas. Code" = '' then
                "Run Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            if "Wait Time Unit of Meas. Code" = '' then
                "Wait Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            if "Move Time Unit of Meas. Code" = '' then
                "Move Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            if "Standard Task Code" = '' then
                Description := WorkCenter.Name;
        end;
        OnAfterWorkCenterTransferFields(Rec, WorkCenter);
    end;

    local procedure MachineCtrTransferFields()
    var
        IsHandled: Boolean;
    begin
        WorkCenter.Get(MachineCenter."Work Center No.");
        WorkCenterTransferFields();

        IsHandled := false;
        OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(Rec, xRec, WorkCenter, MachineCenter, IsHandled);
        if not IsHandled then begin
            Description := MachineCenter.Name;
            "Setup Time" := MachineCenter."Setup Time";
            "Wait Time" := MachineCenter."Wait Time";
            "Move Time" := MachineCenter."Move Time";
            if "Setup Time Unit of Meas. Code" = '' then
                "Setup Time Unit of Meas. Code" := MachineCenter."Setup Time Unit of Meas. Code";
            if "Wait Time Unit of Meas. Code" = '' then
                "Wait Time Unit of Meas. Code" := MachineCenter."Wait Time Unit of Meas. Code";
            if "Move Time Unit of Meas. Code" = '' then
                "Move Time Unit of Meas. Code" := MachineCenter."Move Time Unit of Meas. Code";
            "Fixed Scrap Quantity" := MachineCenter."Fixed Scrap Quantity";
            "Scrap Factor %" := MachineCenter."Scrap %";
            "Minimum Process Time" := MachineCenter."Minimum Process Time";
            "Maximum Process Time" := MachineCenter."Maximum Process Time";
            "Concurrent Capacities" := MachineCenter."Concurrent Capacities";
            "Send-Ahead Quantity" := MachineCenter."Send-Ahead Quantity";
        end;
        OnAfterMachineCtrTransferFields(Rec, WorkCenter, MachineCenter);
    end;

    procedure SetRecalcStatus()
    begin
        Recalculate := true;
    end;

    procedure CertifiedRoutingVersionExists(RtngHeaderNo: Code[20]; CalculationDate: Date): Boolean
    var
        RtngHeader: Record "Routing Header";
        VersionMgt: Codeunit VersionManagement;
        CheckRoutingLines: Codeunit "Check Routing Lines";
        RtngVersionCode: Code[20];
        IsHandled: Boolean;
    begin
        if RtngHeaderNo = '' then
            exit(false);

        RtngHeader.Get(RtngHeaderNo);
        RtngVersionCode := VersionMgt.GetRtngVersion(RtngHeaderNo, CalculationDate, true);

        IsHandled := false;
        OnCertifiedRoutingVersionExistsOnBeforeCalculate(RtngVersionCode, RtngHeaderNo, CalculationDate, IsHandled);
        if not IsHandled then
            if CheckRoutingLines.NeedsCalculation(RtngHeader, RtngVersionCode) then
                CheckRoutingLines.Calculate(RtngHeader, RtngVersionCode);

        SetRange("Routing No.", RtngHeaderNo);
        SetRange("Version Code", RtngVersionCode);
        exit(FindSet());
    end;

    procedure CheckIfRoutingCertified(RoutingLineType: Enum "Capacity Type Routing"; No: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        SetRange(Type, RoutingLineType);
        SetRange("No.", No);
        if Find('-') then
            repeat
                if RoutingHeader.Get("Routing No.") and
                   (RoutingHeader.Status = RoutingHeader.Status::Certified)
                then
                    Error(CannotDeleteCertifiedRoutingExistsErr, Type, "No.");
                if RoutingVersion.Get("Routing No.", "Version Code") and
                   (RoutingVersion.Status = RoutingVersion.Status::Certified)
                then
                    Error(CannotDeleteCertifiedRoutingVersionExistsErr, Type, "No.");
            until Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWorkCenterTransferFields(var RoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMachineCtrTransferFields(var RoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatus(var RoutingLine: Record "Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCertifiedRoutingVersionExistsOnBeforeCalculate(var RtngVersionCode: Code[20]; var RtngHeaderNo: Code[20]; CalculationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStandardTaskCodeOnBeforeRtngQltyMeasureInsert(var RoutingQualityMeasure: Record "Routing Quality Measure"; StandardTaskQualityMeasure: Record "Standard Task Quality Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStandardTaskCodeOnBeforeRtngPersonnelInsert(var RoutingPersonnel: Record "Routing Personnel"; StandardTaskPersonnel: Record "Standard Task Personnel")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStandardTaskCodeOnBeforeRtngToolInsert(var RoutingTool: Record "Routing Tool"; StandardTaskTool: Record "Standard Task Tool")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStandardTaskCodeOnBeforeRtngCommentLineInsert(var RoutingCommentLine: Record "Routing Comment Line"; StdTaskComment: Record "Standard Task Description")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(var RoutingLine: Record "Routing Line"; xRoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWorkCenterTransferFields(var RoutingLine: Record "Routing Line"; xRoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStandardTaskCode(var RoutingLine: Record "Routing Line"; xRoutingLine: Record "Routing Line"; var IsHandled: Boolean)
    begin
    end;
}

