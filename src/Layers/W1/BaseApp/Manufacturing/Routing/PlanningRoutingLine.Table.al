// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;

table 99000830 "Planning Routing Line"
{
    Caption = 'Planning Routing Line';
    DrillDownPageID = "Planning Routing";
    LookupPageID = "Planning Routing";
    Permissions = TableData "Prod. Order Capacity Need" = rmd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            Editable = false;
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Worksheet Batch Name"; Code[10])
        {
            Caption = 'Worksheet Batch Name';
            TableRelation = if ("Worksheet Template Name" = filter(<> '')) "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(3; "Worksheet Line No."; Integer)
        {
            Caption = 'Worksheet Line No.';
            TableRelation = "Requisition Line"."Line No." where("Worksheet Template Name" = field("Worksheet Template Name"),
                                                                 "Journal Batch Name" = field("Worksheet Batch Name"));
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                SetRecalcStatus();

                GetLine();
                "Starting Time" := ReqLine."Starting Time";
                "Ending Time" := ReqLine."Ending Time";
                "Starting Date" := ReqLine."Starting Date";
                "Ending Date" := ReqLine."Ending Date";
            end;
        }
        field(5; "Next Operation No."; Code[30])
        {
            Caption = 'Next Operation No.';

            trigger OnValidate()
            begin
                SetRecalcStatus();

                GetLine();
                ReqLine.TestField("Routing Type", ReqLine."Routing Type"::Serial);
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
        field(7; Type; Enum "Capacity Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                "No." := '';
                "Work Center No." := '';
                "Work Center Group Code" := '';

                ModifyCapNeedEntries();
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
                            WorkCenterTransferfields();
                        end;
                    Type::"Machine Center":
                        begin
                            MachineCenter.Get("No.");
                            MachineCenter.TestField(Blocked, false);
                            MachineCtrTransferfields();
                        end;
                end;
                GetLine();
                if ReqLine."Routing Type" = ReqLine."Routing Type"::Serial then
                    CalcStartingEndingDates();
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

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(13; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(14; "Wait Time"; Decimal)
        {
            Caption = 'Wait Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(15; "Move Time"; Decimal)
        {
            Caption = 'Move Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
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

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
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

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(20; "Run Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Run Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(21; "Wait Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Wait Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(22; "Move Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Move Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
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

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
        }
        field(31; "Send-Ahead Quantity"; Decimal)
        {
            Caption = 'Send-Ahead Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates();
            end;
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
            begin
                if "Standard Task Code" = '' then
                    exit;

                StandardTask.Get("Standard Task Code");
                Description := StandardTask.Description;
            end;
        }
        field(40; "Unit Cost per"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost per';
            MinValue = 0;
        }
        field(41; Recalculate; Boolean)
        {
            Caption = 'Recalculate';
            Editable = false;
        }
        field(50; "Sequence No.(Forward)"; Integer)
        {
            Caption = 'Sequence No.(Forward)';
            Editable = false;
        }
        field(51; "Sequence No.(Backward)"; Integer)
        {
            Caption = 'Sequence No.(Backward)';
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
        field(55; "Sequence No. (Actual)"; Integer)
        {
            Caption = 'Sequence No. (Actual)';
            Editable = false;
        }
        field(56; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(57; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                GetGLSetup();
                "Unit Cost per" :=
                  Round("Direct Unit Cost" * (1 + "Indirect Cost %" / 100) + "Overhead Rate", GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(58; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(61; "Output Quantity"; Decimal)
        {
            Caption = 'Output Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                Modify();

                PlanningRtngLine.Get(
                  "Worksheet Template Name",
                  "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");

                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 0, ReqLine);
                PlanningRtngLine.SetCurrentKey(
                  "Worksheet Template Name",
                  "Worksheet Batch Name",
                  "Worksheet Line No.", "Sequence No. (Actual)");

                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 0, false, false);

                CalculateRoutingBack();
                CalculateRoutingForward();

                Get(
                  "Worksheet Template Name",
                  "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");

                UpdateDatetime();
            end;
        }
        field(71; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                Validate("Starting Time");
            end;
        }
        field(72; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            begin
                Modify();

                PlanningRtngLine.Get(
                  "Worksheet Template Name",
                  "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");

                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 1, ReqLine);
                PlanningRtngLine.SetCurrentKey(
                  "Worksheet Template Name",
                  "Worksheet Batch Name",
                  "Worksheet Line No.", "Sequence No. (Actual)");
                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 1, false, false);

                CalculateRoutingBack();
                CalculateRoutingForward();

                Get(
                  "Worksheet Template Name",
                  "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");
            end;
        }
        field(73; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Ending Time");
            end;
        }
        field(76; "Unit Cost Calculation"; Enum "Unit Cost Calculation Type")
        {
            Caption = 'Unit Cost Calculation';
        }
        field(77; "Input Quantity"; Decimal)
        {
            Caption = 'Input Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(78; "Critical Path"; Boolean)
        {
            Caption = 'Critical Path';
            Editable = false;
        }
        field(98; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(99; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");
                Validate("Ending Time");
            end;
        }
        field(99000909; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
        }
        field(99000910; "Expected Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Capacity Ovhd. Cost';
            Editable = false;
        }
        field(99000911; "Expected Capacity Need"; Decimal)
        {
            Caption = 'Expected Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Operation No.")
        {
            Clustered = true;
        }
        key(Key2; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Sequence No.(Forward)")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Sequence No.(Backward)")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Sequence No. (Actual)")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "Worksheet Template Name", "Worksheet Batch Name", Type, "No.", "Starting Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Work Center No.")
        {
        }
        key(Key7; Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ProdOrderCapNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        ProdOrderCapNeed.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "Next Operation No." = '' then
            SetNextOperations();
    end;

    trigger OnRename()
    begin
        SetRecalcStatus();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        MachineCenter: Record "Machine Center";
        ReqLine: Record "Requisition Line";
        PlanningRtngLine: Record "Planning Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        WorkCenter: Record "Work Center";
        PlanningRoutingManagement: Codeunit PlanningRoutingManagement;
        UOMMgt: Codeunit "Unit of Measure Management";
        HasGLSetup: Boolean;

#pragma warning disable AA0074
        Text000: Label 'This routing line cannot be moved because of critical work centers in previous operations';
        Text001: Label 'This routing line cannot be moved because of critical work centers in next operations';
#pragma warning restore AA0074

    procedure Caption(): Text
    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
    begin
        if GetFilters = '' then
            exit('');

        if not ReqWkshName.Get("Worksheet Template Name", "Worksheet Batch Name") then
            exit('');

        if not ReqLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.") then
            Clear(ReqLine);

        exit(
          StrSubstNo('%1 %2 %3 %4 %5',
            "Worksheet Batch Name", ReqWkshName.Description, ReqLine.Type, ReqLine."No.", ReqLine.Description));
    end;

    local procedure GetLine()
    begin
        if (ReqLine."Worksheet Template Name" <> "Worksheet Template Name") or
           (ReqLine."Journal Batch Name" <> "Worksheet Batch Name") or
           (ReqLine."Line No." <> "Worksheet Line No.")
        then
            ReqLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
    end;

    local procedure WorkCenterTransferfields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWorkCenterTransferFields(Rec, xRec, WorkCenter, IsHandled);
        if not IsHandled then begin
            "Work Center No." := WorkCenter."No.";
            "Work Center Group Code" := WorkCenter."Work Center Group Code";
            "Setup Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Run Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Wait Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Move Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            Description := WorkCenter.Name;
            "Unit Cost per" := WorkCenter."Unit Cost";
            "Direct Unit Cost" := WorkCenter."Direct Unit Cost";
            "Indirect Cost %" := WorkCenter."Indirect Cost %";
            "Overhead Rate" := WorkCenter."Overhead Rate";
        end;
        OnAfterWorkCenterTransferFields(Rec, WorkCenter);
    end;

    local procedure MachineCtrTransferfields()
    var
        IsHandled: Boolean;
    begin
        WorkCenter.Get(MachineCenter."Work Center No.");
        WorkCenterTransferfields();

        IsHandled := false;
        OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(Rec, xRec, WorkCenter, MachineCenter, IsHandled);
        if not IsHandled then begin
            Description := MachineCenter.Name;
            "Setup Time" := MachineCenter."Setup Time";
            "Wait Time" := MachineCenter."Wait Time";
            "Move Time" := MachineCenter."Move Time";
            "Fixed Scrap Quantity" := MachineCenter."Fixed Scrap Quantity";
            "Scrap Factor %" := MachineCenter."Scrap %";
            "Minimum Process Time" := MachineCenter."Minimum Process Time";
            "Maximum Process Time" := MachineCenter."Maximum Process Time";
            "Concurrent Capacities" := MachineCenter."Concurrent Capacities";
            "Send-Ahead Quantity" := MachineCenter."Send-Ahead Quantity";
            "Setup Time Unit of Meas. Code" := MachineCenter."Setup Time Unit of Meas. Code";
            "Wait Time Unit of Meas. Code" := MachineCenter."Wait Time Unit of Meas. Code";
            "Move Time Unit of Meas. Code" := MachineCenter."Move Time Unit of Meas. Code";
            "Unit Cost per" := MachineCenter."Unit Cost";
            "Direct Unit Cost" := MachineCenter."Direct Unit Cost";
            "Indirect Cost %" := MachineCenter."Indirect Cost %";
            "Overhead Rate" := MachineCenter."Overhead Rate";
        end;
        OnAfterMachineCtrTransferFields(Rec, WorkCenter, MachineCenter);
    end;

    procedure SetRecalcStatus()
    begin
        Recalculate := true;
    end;

    procedure RunTimePer(): Decimal
    begin
        if "Lot Size" = 0 then
            "Lot Size" := 1;

        exit(Round("Run Time" / "Lot Size", UOMMgt.TimeRndPrecision()));
    end;

    procedure CalcStartingEndingDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStartingEndingDates(Rec, IsHandled);
        if IsHandled then
            exit;

        Modify();

        PlanningRtngLine.Get(
          "Worksheet Template Name",
          "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");

        PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 0, ReqLine);
        PlanningRtngLine.SetCurrentKey(
          "Worksheet Template Name",
          "Worksheet Batch Name",
          "Worksheet Line No.", "Sequence No. (Actual)");

        PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 0, false, false);

        CalculateRoutingBack();
        CalculateRoutingForward();

        Get(
          "Worksheet Template Name",
          "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");
    end;

    local procedure CalculateRoutingBack()
    begin
        GetLine();

        if "Previous Operation No." <> '' then begin
            PlanningRtngLine.Reset();
            PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
            PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
            PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
            PlanningRtngLine.SetFilter("Operation No.", "Previous Operation No.");

            if PlanningRtngLine.Find('-') then
                repeat
                    PlanningRtngLine.SetCurrentKey(
                      "Worksheet Template Name",
                      "Worksheet Batch Name",
                      "Worksheet Line No.", "Sequence No. (Actual)");
                    WorkCenter.Get(PlanningRtngLine."Work Center No.");

                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 1, ReqLine);
                                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 1, true, false);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (PlanningRtngLine."Ending Date" > "Starting Date") or
                               ((PlanningRtngLine."Ending Date" = "Starting Date") and
                                (PlanningRtngLine."Ending Time" > "Starting Time"))
                            then begin
                                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 1, ReqLine);
                                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 1, true, false);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            if (PlanningRtngLine."Ending Date" > "Starting Date") or
                                ((PlanningRtngLine."Ending Date" = "Starting Date") and
                                (PlanningRtngLine."Ending Time" > "Starting Time"))
                            then
                                Error(Text000);
                    end;
                    PlanningRtngLine.SetCurrentKey(
                      "Worksheet Template Name",
                      "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");
                until PlanningRtngLine.Next() = 0;
        end;

        PlanningRoutingManagement.CalculatePlanningLineDates(ReqLine);
        AdjustComponents(ReqLine);
    end;

    local procedure CalculateRoutingForward()
    begin
        GetLine();

        if "Next Operation No." <> '' then begin
            PlanningRtngLine.Reset();
            PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
            PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
            PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
            PlanningRtngLine.SetFilter("Operation No.", "Next Operation No.");

            if PlanningRtngLine.Find('-') then
                repeat
                    PlanningRtngLine.SetCurrentKey(
                      "Worksheet Template Name",
                      "Worksheet Batch Name",
                      "Worksheet Line No.", "Sequence No. (Actual)");
                    WorkCenter.Get(PlanningRtngLine."Work Center No.");
                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 0, ReqLine);
                                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 0, true, false);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (PlanningRtngLine."Starting Date" < "Ending Date") or
                               ((PlanningRtngLine."Starting Date" = "Ending Date") and
                                (PlanningRtngLine."Starting Time" < "Ending Time"))
                            then begin
                                PlanningRoutingManagement.CalcSequenceFromActual(PlanningRtngLine, 0, ReqLine);
                                PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, 0, true, false);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            if (PlanningRtngLine."Starting Date" < "Ending Date") or
                                ((PlanningRtngLine."Starting Date" = "Ending Date") and
                                (PlanningRtngLine."Starting Time" < "Ending Time"))
                            then
                                Error(Text001);
                    end;
                    PlanningRtngLine.SetCurrentKey(
                      "Worksheet Template Name",
                      "Worksheet Batch Name", "Worksheet Line No.", "Operation No.");
                until PlanningRtngLine.Next() = 0;
        end;

        PlanningRoutingManagement.CalculatePlanningLineDates(ReqLine);
        AdjustComponents(ReqLine);
    end;

    local procedure ModifyCapNeedEntries()
    begin
        ProdOrderCapNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", "Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        if ProdOrderCapNeed.Find('-') then
            repeat
                ProdOrderCapNeed."No." := "No.";
                ProdOrderCapNeed."Work Center No." := "Work Center No.";
                ProdOrderCapNeed."Work Center Group Code" := "Work Center Group Code";
                ProdOrderCapNeed.Modify();
            until ProdOrderCapNeed.Next() = 0;
    end;

    local procedure AdjustComponents(var ReqLine: Record "Requisition Line")
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");

        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent.Validate("Routing Link Code");
                PlanningComponent.Modify();
            until PlanningComponent.Next() = 0;
    end;

    procedure TransferFromProdOrderRouting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderRoutingLine.TestField(Recalculate, false);
        "Operation No." := ProdOrderRoutingLine."Operation No.";
        "Next Operation No." := ProdOrderRoutingLine."Next Operation No.";
        "Previous Operation No." := ProdOrderRoutingLine."Previous Operation No.";
        Type := ProdOrderRoutingLine.Type;
        "No." := ProdOrderRoutingLine."No.";
        Description := ProdOrderRoutingLine.Description;
        "Work Center No." := ProdOrderRoutingLine."Work Center No.";
        "Work Center Group Code" := ProdOrderRoutingLine."Work Center Group Code";
        "Setup Time" := ProdOrderRoutingLine."Setup Time";
        "Run Time" := ProdOrderRoutingLine."Run Time";
        "Wait Time" := ProdOrderRoutingLine."Wait Time";
        "Move Time" := ProdOrderRoutingLine."Move Time";
        "Fixed Scrap Quantity" := ProdOrderRoutingLine."Fixed Scrap Quantity";
        "Lot Size" := ProdOrderRoutingLine."Lot Size";
        "Scrap Factor %" := ProdOrderRoutingLine."Scrap Factor %";
        "Setup Time Unit of Meas. Code" := ProdOrderRoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := ProdOrderRoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := ProdOrderRoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := ProdOrderRoutingLine."Move Time Unit of Meas. Code";
        "Minimum Process Time" := ProdOrderRoutingLine."Minimum Process Time";
        "Maximum Process Time" := ProdOrderRoutingLine."Maximum Process Time";
        "Concurrent Capacities" := ProdOrderRoutingLine."Concurrent Capacities";
        "Send-Ahead Quantity" := ProdOrderRoutingLine."Send-Ahead Quantity";
        "Direct Unit Cost" := ProdOrderRoutingLine."Direct Unit Cost";
        "Unit Cost per" := ProdOrderRoutingLine."Unit Cost per";
        "Unit Cost Calculation" := ProdOrderRoutingLine."Unit Cost Calculation";
        "Indirect Cost %" := ProdOrderRoutingLine."Indirect Cost %";
        "Overhead Rate" := ProdOrderRoutingLine."Overhead Rate";
        Validate("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        "Standard Task Code" := ProdOrderRoutingLine."Standard Task Code";
        "Sequence No.(Forward)" := ProdOrderRoutingLine."Sequence No. (Forward)";
        "Sequence No.(Backward)" := ProdOrderRoutingLine."Sequence No. (Backward)";
        "Fixed Scrap Qty. (Accum.)" := ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := ProdOrderRoutingLine."Scrap Factor % (Accumulated)";
        "Starting Time" := ProdOrderRoutingLine."Starting Time";
        "Starting Date" := ProdOrderRoutingLine."Starting Date";
        "Ending Time" := ProdOrderRoutingLine."Ending Time";
        "Ending Date" := ProdOrderRoutingLine."Ending Date";
        UpdateDatetime();
        Validate("Unit Cost per");

        OnAfterTransferFromProdOrderRouting(Rec, ProdOrderRoutingLine);
    end;

    [Scope('OnPrem')]
    procedure TransferFromReqLine(ReqLine: Record "Requisition Line")
    begin
        "Worksheet Template Name" := ReqLine."Worksheet Template Name";
        "Worksheet Batch Name" := ReqLine."Journal Batch Name";
        "Worksheet Line No." := ReqLine."Line No.";
        "Output Quantity" := ReqLine.Quantity;
        "Starting Date" := ReqLine."Starting Date";
        "Starting Time" := ReqLine."Starting Time";
        "Ending Date" := ReqLine."Ending Date";
        "Ending Time" := ReqLine."Ending Time";
        "Input Quantity" := ReqLine.Quantity;

        OnAfterTransferFromReqLine(Rec, ReqLine);
    end;

    [Scope('OnPrem')]
    procedure TransferFromRoutingLine(RoutingLine: Record "Routing Line")
    begin
        "Operation No." := RoutingLine."Operation No.";
        "Next Operation No." := RoutingLine."Next Operation No.";
        "Previous Operation No." := RoutingLine."Previous Operation No.";
        Type := RoutingLine.Type;
        "No." := RoutingLine."No.";
        "Work Center No." := RoutingLine."Work Center No.";
        "Work Center Group Code" := RoutingLine."Work Center Group Code";
        Description := RoutingLine.Description;
        "Setup Time" := RoutingLine."Setup Time";
        "Run Time" := RoutingLine."Run Time";
        "Wait Time" := RoutingLine."Wait Time";
        "Move Time" := RoutingLine."Move Time";
        "Fixed Scrap Quantity" := RoutingLine."Fixed Scrap Quantity";
        "Lot Size" := RoutingLine."Lot Size";
        "Scrap Factor %" := RoutingLine."Scrap Factor %";
        "Setup Time Unit of Meas. Code" := RoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := RoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := RoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := RoutingLine."Move Time Unit of Meas. Code";
        "Minimum Process Time" := RoutingLine."Minimum Process Time";
        "Maximum Process Time" := RoutingLine."Maximum Process Time";
        "Concurrent Capacities" := RoutingLine."Concurrent Capacities";
        if "Concurrent Capacities" = 0 then
            "Concurrent Capacities" := 1;
        "Send-Ahead Quantity" := RoutingLine."Send-Ahead Quantity";
        "Routing Link Code" := RoutingLine."Routing Link Code";
        "Standard Task Code" := RoutingLine."Standard Task Code";
        "Unit Cost per" := RoutingLine."Unit Cost per";
        "Sequence No.(Forward)" := RoutingLine."Sequence No. (Forward)";
        "Sequence No.(Backward)" := RoutingLine."Sequence No. (Backward)";
        "Fixed Scrap Qty. (Accum.)" := RoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := RoutingLine."Scrap Factor % (Accumulated)";

        OnAfterTransferFromRoutingLine(Rec, RoutingLine);
    end;

    procedure UpdateDatetime()
    begin
        "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time");
        "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time");
        OnAfterUpdateDatetime(Rec, xRec, CurrFieldNo);
    end;

    procedure SetNextOperations()
    var
        PlanningRtngLine2: Record "Planning Routing Line";
    begin
        PlanningRtngLine2.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningRtngLine2.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        PlanningRtngLine2.SetRange("Worksheet Line No.", "Worksheet Line No.");
        PlanningRtngLine2.SetFilter("Operation No.", '>%1', "Operation No.");

        if PlanningRtngLine2.FindFirst() then
            "Next Operation No." := PlanningRtngLine2."Operation No."
        else begin
            PlanningRtngLine2.SetFilter("Operation No.", '');
            PlanningRtngLine2.SetRange("Next Operation No.", '');
            if PlanningRtngLine2.FindFirst() then begin
                PlanningRtngLine2."Next Operation No." := "Operation No.";
                PlanningRtngLine2.Modify();
            end;
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not HasGLSetup then begin
            HasGLSetup := true;
            GLSetup.Get();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPreviousAndNext()
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        if PlanningRoutingLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Previous Operation No.") then begin
            PlanningRoutingLine."Next Operation No." := "Next Operation No.";
            PlanningRoutingLine.Modify();
        end;
        if PlanningRoutingLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Next Operation No.") then begin
            PlanningRoutingLine."Previous Operation No." := "Previous Operation No.";
            PlanningRoutingLine.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure IsSerial(): Boolean
    begin
        GetLine();
        exit(ReqLine."Routing Type" = ReqLine."Routing Type"::Serial)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWorkCenterTransferFields(var PlanningRoutingLine: Record "Planning Routing Line"; var WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMachineCtrTransferFields(var PlanningRoutingLine: Record "Planning Routing Line"; var WorkCenter: Record "Work Center"; var MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrderRouting(var PlanningRoutingLine: Record "Planning Routing Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; var RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLine(var PlanningRoutingLine: Record "Planning Routing Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDatetime(var PlanningRoutingLine: Record "Planning Routing Line"; xPlanningRoutingLine: Record "Planning Routing Line"; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartingEndingDates(var PlanningRoutingLine: Record "Planning Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(var PlanningRoutingLine: Record "Planning Routing Line"; xPlanningRoutingLine: Record "Planning Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWorkCenterTransferFields(var PlanningRoutingLine: Record "Planning Routing Line"; xPlanningRoutingLine: Record "Planning Routing Line"; WorkCenter: Record "Work Center"; var IsHandled: Boolean)
    begin
    end;
}

