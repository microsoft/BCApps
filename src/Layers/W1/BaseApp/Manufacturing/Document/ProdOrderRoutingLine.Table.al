// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Request;
using System.Utilities;

table 5409 "Prod. Order Routing Line"
{
    Caption = 'Prod. Order Routing Line';
    DrillDownPageID = "Prod. Order Routing";
    LookupPageID = "Prod. Order Routing";
    Permissions = TableData "Prod. Order Capacity Need" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header";
        }
        field(3; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            Editable = false;
        }
        field(4; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            NotBlank = true;

            trigger OnValidate()
            begin
                SetRecalcStatus();

                GetProdOrderLine();
                "Starting Time" := ProdOrderLine."Starting Time";
                "Ending Time" := ProdOrderLine."Ending Time";
                "Starting Date" := ProdOrderLine."Starting Date";
                "Ending Date" := ProdOrderLine."Ending Date";
            end;
        }
        field(5; "Next Operation No."; Code[30])
        {
            Caption = 'Next Operation No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GetProdOrderLine();
                OnBeforeTerminationProcessesErr(IsHandled, Rec, xRec);
                if not IsHandled then
                    if (xRec."Next Operation No." = '') and ("Next Operation No." <> '') and NoTerminationProcessesExist() then
                        Error(NoTerminationProcessesErr);

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
        field(7; Type; Enum "Capacity Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                SetRecalcStatus();

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
                if ("No." <> xRec."No.") and (xRec."No." <> '') then
                    if SubcontractingPurchOrderExist() then
                        Error(
                          Text007,
                          FieldCaption("No."), PurchLine.TableCaption(), Status, TableCaption(), "Operation No.");

                SetRecalcStatus();

                if ("No." = '') and ("Routing Status" = "Routing Status"::Finished) then
                    FieldError("Routing Status");

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
                ModifyCapNeedEntries();

                GetProdOrderLine();
                if (ProdOrderLine."Routing Type" = ProdOrderLine."Routing Type"::Serial) or (xRec."No." <> '') then
                    CalcStartingEndingDates(Direction::Forward);

                OnAfterValidateNo(Rec, xRec, ProdOrderLine);
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
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(13; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(14; "Wait Time"; Decimal)
        {
            Caption = 'Wait Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(15; "Move Time"; Decimal)
        {
            Caption = 'Move Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
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
                CalcStartingEndingDates(Direction::Forward);
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
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(20; "Run Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Run Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(21; "Wait Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Wait Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(22; "Move Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Move Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
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
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(31; "Send-Ahead Quantity"; Decimal)
        {
            Caption = 'Send-Ahead Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(34; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode: Record "Prod. Order Routing Line";
            begin
                ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode := Rec;
                ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode.SetRecFilter();
                ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode.SetRange("Operation No.");
                ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode.SetRange("Routing Link Code", "Routing Link Code");
                if not ProdOrderRoutingLineToCheckDuplicateRoutingLinkCode.IsEmpty() then
                    if not Confirm(DuplicateRoutingLinkCodeLbl, false, FieldCaption("Routing Link Code"), "Routing Link Code") then
                        Error(CancelledUpdateLbl);

                AdjustProdOrderComponentForRoutingLinkCode(Rec, xRec);
            end;
        }
        field(35; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";

            trigger OnValidate()
            var
                StandardTask: Record "Standard Task";
                StdTaskTool: Record "Standard Task Tool";
                StdTaskPersonnel: Record "Standard Task Personnel";
                StdTaskQltyMeasure: Record "Standard Task Quality Measure";
                StdTaskComment: Record "Standard Task Description";
                ProdOrderRoutingTool: Record "Prod. Order Routing Tool";
                ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel";
                ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
                ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
            begin
                if "Standard Task Code" = '' then
                    exit;

                StandardTask.Get("Standard Task Code");
                Description := StandardTask.Description;

                DeleteRelations();

                StdTaskTool.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskTool.Find('-') then
                    repeat
                        ProdOrderRoutingTool.Status := Status;
                        ProdOrderRoutingTool."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRoutingTool."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRoutingTool."Routing No." := "Routing No.";
                        ProdOrderRoutingTool."Operation No." := "Operation No.";
                        ProdOrderRoutingTool."Line No." := StdTaskTool."Line No.";
                        ProdOrderRoutingTool."No." := StdTaskTool."No.";
                        ProdOrderRoutingTool.Description := StdTaskTool.Description;
                        ProdOrderRoutingTool.Insert();
                        OnAfterTransferFromStdTaskTool(ProdOrderRoutingTool, StdTaskTool);
                    until StdTaskTool.Next() = 0;

                StdTaskPersonnel.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskPersonnel.Find('-') then
                    repeat
                        ProdOrderRoutingPersonnel.Status := Status;
                        ProdOrderRoutingPersonnel."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRoutingPersonnel."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRoutingPersonnel."Routing No." := "Routing No.";
                        ProdOrderRoutingPersonnel."Operation No." := "Operation No.";
                        ProdOrderRoutingPersonnel."Line No." := StdTaskPersonnel."Line No.";
                        ProdOrderRoutingPersonnel."No." := StdTaskPersonnel."No.";
                        ProdOrderRoutingPersonnel.Description := StdTaskPersonnel.Description;
                        ProdOrderRoutingPersonnel.Insert();
                        OnAfterTransferFromStdTaskPersonnel(ProdOrderRoutingPersonnel, StdTaskPersonnel);
                    until StdTaskPersonnel.Next() = 0;

                StdTaskQltyMeasure.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskQltyMeasure.Find('-') then
                    repeat
                        ProdOrderRtngQltyMeas.Status := Status;
                        ProdOrderRtngQltyMeas."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRtngQltyMeas."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRtngQltyMeas."Routing No." := "Routing No.";
                        ProdOrderRtngQltyMeas."Operation No." := "Operation No.";
                        ProdOrderRtngQltyMeas."Line No." := StdTaskQltyMeasure."Line No.";
                        ProdOrderRtngQltyMeas."Qlty Measure Code" := StdTaskQltyMeasure."Qlty Measure Code";
                        ProdOrderRtngQltyMeas.Description := StdTaskQltyMeasure.Description;
                        ProdOrderRtngQltyMeas."Min. Value" := StdTaskQltyMeasure."Min. Value";
                        ProdOrderRtngQltyMeas."Max. Value" := StdTaskQltyMeasure."Max. Value";
                        ProdOrderRtngQltyMeas."Mean Tolerance" := StdTaskQltyMeasure."Mean Tolerance";
                        ProdOrderRtngQltyMeas.Insert();
                        OnAfterTransferFromStdTaskQltyMeasure(ProdOrderRtngQltyMeas, StdTaskQltyMeasure);
                    until StdTaskQltyMeasure.Next() = 0;

                StdTaskComment.SetRange("Standard Task Code", "Standard Task Code");
                if StdTaskComment.Find('-') then
                    repeat
                        ProdOrderRtngCommentLine.Status := Status;
                        ProdOrderRtngCommentLine."Prod. Order No." := "Prod. Order No.";
                        ProdOrderRtngCommentLine."Routing Reference No." := "Routing Reference No.";
                        ProdOrderRtngCommentLine."Routing No." := "Routing No.";
                        ProdOrderRtngCommentLine."Operation No." := "Operation No.";
                        ProdOrderRtngCommentLine."Line No." := StdTaskComment."Line No.";
                        ProdOrderRtngCommentLine.Comment := StdTaskComment.Text;
                        OnValidateStandardTaskCodeOnBeforeProdOrderRtngCommentLineInsert(ProdOrderRtngCommentLine, StdTaskComment);
                        ProdOrderRtngCommentLine.Insert();
                        OnAfterTransferFromStdTaskComment(ProdOrderRtngCommentLine, StdTaskComment);
                    until StdTaskComment.Next() = 0;
            end;
        }
        field(40; "Unit Cost per"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost per';
            MinValue = 0;

            trigger OnValidate()
            begin
                GLSetup.Get();
                "Direct Unit Cost" :=
                  Round(
                    ("Unit Cost per" - "Overhead Rate") /
                    (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");

                CalcStartingEndingDates(Direction::Forward);
            end;
        }
        field(41; Recalculate; Boolean)
        {
            Caption = 'Recalculate';
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
                GLSetup.Get();
                "Unit Cost per" :=
                  Round(
                    "Direct Unit Cost" * (1 + "Indirect Cost %" / 100) + "Overhead Rate",
                    GLSetup."Unit-Amount Rounding Precision");
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
        field(70; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                CalcStartingEndingDates(Direction::Forward);
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
                CalcStartingEndingDates(Direction::Backward);
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
        field(74; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(75; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            Editable = false;
            NotBlank = true;
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(76; "Unit Cost Calculation"; Enum "Unit Cost Calculation Type")
        {
            Caption = 'Unit Cost Calculation';
        }
        field(77; "Input Quantity"; Decimal)
        {
            Caption = 'Input Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(78; "Critical Path"; Boolean)
        {
            Caption = 'Critical Path';
            Editable = false;
        }
        field(79; "Routing Status"; Enum "Prod. Order Routing Status")
        {
            Caption = 'Routing Status';

            trigger OnValidate()
            var
                ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
                IsHandled: Boolean;
            begin
                if (xRec."Routing Status" = xRec."Routing Status"::Finished) and (xRec."Routing Status" <> "Routing Status") then
                    Error(Text008, FieldCaption("Routing Status"), xRec."Routing Status", "Routing Status");

                if ("Routing Status" = "Routing Status"::Finished) and (xRec."Routing Status" <> "Routing Status") then begin
                    IsHandled := false;
                    OnValidateRoutingStatusOnBeforeConfirm(Rec, IsHandled);
                    if IsHandled then
                        exit;

                    if not HideValidationDialog then
                        if not ConfirmManagement.GetResponse(StrSubstNo(Text009, FieldCaption("Routing Status"), "Routing Status"), false) then
                            Error('');

                    ProdOrderCapacityNeed.SetCurrentKey(
                      Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.", "Line No.");
                    ProdOrderCapacityNeed.SetRange(Status, Status);
                    ProdOrderCapacityNeed.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderCapacityNeed.SetRange("Requested Only", false);
                    ProdOrderCapacityNeed.SetRange("Routing No.", "Routing No.");
                    ProdOrderCapacityNeed.SetRange("Routing Reference No.", "Routing Reference No.");
                    ProdOrderCapacityNeed.SetRange("Operation No.", "Operation No.");
                    ProdOrderCapacityNeed.ModifyAll("Allocated Time", 0);
                end;
            end;
        }
        field(81; "Flushing Method"; Enum "Flushing Method Routing")
        {
            Caption = 'Flushing Method';
            ToolTip = 'Specifies the method to use to calculate and handle output at the work or machine center. Manual: Output must be posted manually by using the output journal. Forward: Output is automatically calculated and posted when you change the status of a simulated, planned (or firm planned) production order to Released. You can still post output manually from the output journal. Backward: Output is automatically calculated and posted when you change the status of a released production order to Finished. You can still post output manually from the output journal.';
        }
        field(90; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
        }
        field(91; "Expected Capacity Need"; Decimal)
        {
            Caption = 'Expected Capacity Need';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
        }
        field(96; "Expected Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Capacity Ovhd. Cost';
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
        field(100; "Schedule Manually"; Boolean)
        {
            Caption = 'Schedule Manually';
        }
        field(101; "Location Code"; Code[10])
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Location Code';
            Editable = false;
        }
        field(7301; "Open Shop Floor Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Open Shop Floor Bin Code';
            Editable = false;
        }
        field(7302; "To-Production Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'To-Production Bin Code';
            Editable = false;
        }
        field(7303; "From-Production Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'From-Production Bin Code';
            Editable = false;
        }
        field(7304; "Posted Output Quantity"; Decimal)
        {
            Caption = 'Posted Output Quantity';
            ToolTip = 'Specifies the total output quantity that has been posted to the capacity ledger. Value expressed in base unit of measure.';
            FieldClass = FlowField;
            CalcFormula = sum("Capacity Ledger Entry"."Output Quantity" where("Routing No." = field("Routing No."),
                                                                              "Order No." = field("Prod. Order No."),
                                                                              "Operation No." = field("Operation No."),
                                                                              "Order Type" = const(Production),
                                                                              "Routing Reference No." = field("Routing Reference No.")));
            Editable = false;
        }
        field(7305; "Posted Scrap Quantity"; Decimal)
        {
            Caption = 'Posted Scrap Quantity';
            ToolTip = 'Specifies the total scrap quantity that has been posted to the capacity ledger. Value expressed in base unit of measure.';
            FieldClass = FlowField;
            CalcFormula = sum("Capacity Ledger Entry"."Scrap Quantity" where("Routing No." = field("Routing No."),
                                                                             "Order No." = field("Prod. Order No."),
                                                                             "Operation No." = field("Operation No."),
                                                                             "Order Type" = const(Production),
                                                                             "Routing Reference No." = field("Routing Reference No.")));
            Editable = false;
        }
        field(7306; "Posted Run Time"; Decimal)
        {
            Caption = 'Posted Run Time';
            ToolTip = 'Specifies the total run time that has been posted to the capacity ledger.';
            FieldClass = FlowField;
            CalcFormula = sum("Capacity Ledger Entry"."Run Time" where("Routing No." = field("Routing No."),
                                                                       "Order No." = field("Prod. Order No."),
                                                                       "Operation No." = field("Operation No."),
                                                                       "Order Type" = const(Production),
                                                                       "Routing Reference No." = field("Routing Reference No.")));
            Editable = false;
        }
        field(7307; "Posted Setup Time"; Decimal)
        {
            Caption = 'Posted Setup Time';
            ToolTip = 'Specifies the total set up time that has been posted to the capacity ledger.';
            FieldClass = FlowField;
            CalcFormula = sum("Capacity Ledger Entry"."Setup Time" where("Routing No." = field("Routing No."),
                                                                         "Order No." = field("Prod. Order No."),
                                                                         "Operation No." = field("Operation No."),
                                                                         "Order Type" = const(Production),
                                                                         "Routing Reference No." = field("Routing Reference No.")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Routing Reference No.", Status, "Routing No.", "Operation No.")
        {
        }
        key(Key3; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Forward)")
        {
        }
        key(Key4; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Backward)")
        {
        }
        key(Key5; Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Actual)")
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key6; "Work Center No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key7; Type, "No.", "Starting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key8; Status, "Work Center No.")
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
        key(Key9; "Prod. Order No.", Status, "Flushing Method")
        {
        }
        key(Key10; "Starting Date", "Starting Time", "Routing Status")
        {
        }
        key(Key11; "Ending Date", "Ending Time", "Routing Status")
        {
        }
        key(Key12; Type, "No.", Status)
        {
            SumIndexFields = "Expected Operation Cost Amt.";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        if Status = Status::Released then begin
            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
            CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
            CapLedgEntry.SetRange("Routing Reference No.", "Routing Reference No.");
            CapLedgEntry.SetRange("Routing No.", "Routing No.");
            CapLedgEntry.SetRange("Operation No.", "Operation No.");
            if not CapLedgEntry.IsEmpty() then
                Error(
                  Text000,
                  Status, TableCaption(), "Operation No.", CapLedgEntry.TableCaption());
        end;

        CheckIfSubcontractingPurchOrderExist();

        DeleteRelations();

        UpdateComponentsBin(2); // from trigger = delete
    end;

    trigger OnInsert()
    begin
        CheckRoutingNoNotBlank();
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        if "Next Operation No." = '' then
            SetNextOperations(Rec);

        UpdateComponentsBin(0); // from trigger = insert
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text006, Status, TableCaption);

        UpdateComponentsBin(1); // from trigger = modify
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete %1 %2 %3 because there is at least one %4 associated with it.', Comment = '%1 = Document status; %2 = Table Caption; %3 = Field Value; %4 = Table Caption';
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
        Text002: Label 'This routing line cannot be moved because of critical work centers in previous operations';
        Text003: Label 'This routing line cannot be moved because of critical work centers in next operations';
#pragma warning restore AA0074
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        GLSetup: Record "General Ledger Setup";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
        PurchLine: Record "Purchase Line";
        TempErrorMessage: Record "Error Message" temporary;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        ConfirmManagement: Codeunit "Confirm Management";
        ProdOrderRouteMgt: Codeunit "Prod. Order Route Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Some routing lines are referring to the operation just deleted. The references are\in the fields %1 and %2.\\This may have to be corrected as a routing line referring to a non-existent\operation will lead to serious errors in capacity planning.\\Do you want to see a list of the lines in question?\(Access the columns Next Operation No. and Previous Operation No.)';
        Text005: Label 'Routing Lines referring to deleted Operation No. %1';
        Text006: Label 'A %1 %2 can not be inserted, modified, or deleted.';
        Text007: Label 'You cannot change %1, because there is at least one %2 associated with %3 %4 %5.';
        Text008: Label 'You cannot change the %1 from %2 to %3.';
        Text009: Label 'If you change the %1 to %2, then all related allocated capacity will be deleted, and you will not be able to change the %1 of the operation again.\\Are you sure that you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SkipUpdateOfCompBinCodes: Boolean;
        ProdOrderLineRead: Boolean;
        TimeShiftedOnParentLineMsg: Label 'The production starting date-time of the end item has been moved forward because a subassembly is taking longer than planned.';
        NoTerminationProcessesErr: Label 'On the last operation, the Next Operation No. field must be empty.';
        DuplicateRoutingLinkCodeLbl: Label '%1 %2 is used more than once on this Routing. Do you want to update it anyway?', Comment = '%1 = Field Caption; %2 = Field Value';
        CancelledUpdateLbl: Label 'Update cancelled.';

    protected var
        Direction: Option Forward,Backward;
        HideValidationDialog: Boolean;

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        exit(
          StrSubstNo('%1 %2 %3',
            "Prod. Order No.", ProdOrder.Description, "Routing No."));
    end;

    local procedure GetProdOrderLine()
    begin
        if ProdOrderLineRead then
            exit;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.Find('-');
        ProdOrderLineRead := true;
    end;

    procedure CopyFromPlanningRoutingLine(PlanningRoutingLine: Record "Planning Routing Line")
    begin
        "Operation No." := PlanningRoutingLine."Operation No.";
        "Next Operation No." := PlanningRoutingLine."Next Operation No.";
        "Previous Operation No." := PlanningRoutingLine."Previous Operation No.";
        Type := PlanningRoutingLine.Type;
        "No." := PlanningRoutingLine."No.";
        "Work Center No." := PlanningRoutingLine."Work Center No.";
        "Work Center Group Code" := PlanningRoutingLine."Work Center Group Code";
        Description := PlanningRoutingLine.Description;
        "Setup Time" := PlanningRoutingLine."Setup Time";
        "Run Time" := PlanningRoutingLine."Run Time";
        "Wait Time" := PlanningRoutingLine."Wait Time";
        "Move Time" := PlanningRoutingLine."Move Time";
        "Fixed Scrap Quantity" := PlanningRoutingLine."Fixed Scrap Quantity";
        "Lot Size" := PlanningRoutingLine."Lot Size";
        "Scrap Factor %" := PlanningRoutingLine."Scrap Factor %";
        "Setup Time Unit of Meas. Code" := PlanningRoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := PlanningRoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := PlanningRoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := PlanningRoutingLine."Move Time Unit of Meas. Code";
        "Minimum Process Time" := PlanningRoutingLine."Minimum Process Time";
        "Maximum Process Time" := PlanningRoutingLine."Maximum Process Time";
        "Concurrent Capacities" := PlanningRoutingLine."Concurrent Capacities";
        "Send-Ahead Quantity" := PlanningRoutingLine."Send-Ahead Quantity";
        "Routing Link Code" := PlanningRoutingLine."Routing Link Code";
        "Standard Task Code" := PlanningRoutingLine."Standard Task Code";
        "Unit Cost per" := PlanningRoutingLine."Unit Cost per";
        Recalculate := PlanningRoutingLine.Recalculate;
        "Sequence No. (Forward)" := PlanningRoutingLine."Sequence No.(Forward)";
        "Sequence No. (Backward)" := PlanningRoutingLine."Sequence No.(Backward)";
        "Fixed Scrap Qty. (Accum.)" := PlanningRoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := PlanningRoutingLine."Scrap Factor % (Accumulated)";
        "Sequence No. (Actual)" := PlanningRoutingLine."Sequence No. (Actual)";
        "Starting Time" := PlanningRoutingLine."Starting Time";
        "Starting Date" := PlanningRoutingLine."Starting Date";
        "Ending Time" := PlanningRoutingLine."Ending Time";
        "Ending Date" := PlanningRoutingLine."Ending Date";
        "Unit Cost Calculation" := PlanningRoutingLine."Unit Cost Calculation";
        "Input Quantity" := PlanningRoutingLine."Input Quantity";
        "Critical Path" := PlanningRoutingLine."Critical Path";
        "Direct Unit Cost" := PlanningRoutingLine."Direct Unit Cost";
        "Indirect Cost %" := PlanningRoutingLine."Indirect Cost %";
        "Overhead Rate" := PlanningRoutingLine."Overhead Rate";
        "Expected Operation Cost Amt." := PlanningRoutingLine."Expected Operation Cost Amt.";
        "Expected Capacity Ovhd. Cost" := PlanningRoutingLine."Expected Capacity Ovhd. Cost";
        "Expected Capacity Need" := PlanningRoutingLine."Expected Capacity Need";

        OnAfterCopyFromPlanningRoutingLine(Rec, PlanningRoutingLine);
    end;

    procedure CopyFromRoutingLine(RoutingLine: Record "Routing Line")
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
        "Minimum Process Time" := RoutingLine."Minimum Process Time";
        "Maximum Process Time" := RoutingLine."Maximum Process Time";
        "Concurrent Capacities" := RoutingLine."Concurrent Capacities";
        if "Concurrent Capacities" = 0 then
            "Concurrent Capacities" := 1;
        "Send-Ahead Quantity" := RoutingLine."Send-Ahead Quantity";
        "Setup Time Unit of Meas. Code" := RoutingLine."Setup Time Unit of Meas. Code";
        "Run Time Unit of Meas. Code" := RoutingLine."Run Time Unit of Meas. Code";
        "Wait Time Unit of Meas. Code" := RoutingLine."Wait Time Unit of Meas. Code";
        "Move Time Unit of Meas. Code" := RoutingLine."Move Time Unit of Meas. Code";
        "Routing Link Code" := RoutingLine."Routing Link Code";
        "Standard Task Code" := RoutingLine."Standard Task Code";
        "Sequence No. (Forward)" := RoutingLine."Sequence No. (Forward)";
        "Sequence No. (Backward)" := RoutingLine."Sequence No. (Backward)";
        "Fixed Scrap Qty. (Accum.)" := RoutingLine."Fixed Scrap Qty. (Accum.)";
        "Scrap Factor % (Accumulated)" := RoutingLine."Scrap Factor % (Accumulated)";
        "Unit Cost per" := RoutingLine."Unit Cost per";
        FillDefaultLocationAndBins();

        OnAfterCopyFromRoutingLine(Rec, RoutingLine);
    end;

    local procedure DeleteRelations()
    var
        ProdOrderRoutingTool: Record "Prod. Order Routing Tool";
        ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel";
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderRoutingTool.SetRange(Status, Status);
        ProdOrderRoutingTool.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingTool.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingTool.SetRange("Routing No.", "Routing No.");
        ProdOrderRoutingTool.SetRange("Operation No.", "Operation No.");
        ProdOrderRoutingTool.DeleteAll();

        ProdOrderRoutingPersonnel.SetRange(Status, Status);
        ProdOrderRoutingPersonnel.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingPersonnel.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingPersonnel.SetRange("Routing No.", "Routing No.");
        ProdOrderRoutingPersonnel.SetRange("Operation No.", "Operation No.");
        ProdOrderRoutingPersonnel.DeleteAll();

        ProdOrderRtngQltyMeas.SetRange(Status, Status);
        ProdOrderRtngQltyMeas.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngQltyMeas.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngQltyMeas.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngQltyMeas.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngQltyMeas.DeleteAll();

        ProdOrderRtngCommentLine.SetRange(Status, Status);
        ProdOrderRtngCommentLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngCommentLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRtngCommentLine.SetRange("Routing No.", "Routing No.");
        ProdOrderRtngCommentLine.SetRange("Operation No.", "Operation No.");
        ProdOrderRtngCommentLine.DeleteAll();

        ProdOrderCapNeed.SetRange(Status, Status);
        ProdOrderCapNeed.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderCapNeed.SetRange("Routing No.", "Routing No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        ProdOrderCapNeed.DeleteAll();

        OnAfterDeleteRelations(Rec, SkipUpdateOfCompBinCodes);
    end;

    local procedure WorkCenterTransferFields()
    var
        IsHandled, SkipUpdateDescription : Boolean;
    begin
        IsHandled := false;
        OnBeforeWorkCenterTransferFields(Rec, WorkCenter, SkipUpdateDescription, xRec, IsHandled);
        if not IsHandled then begin
            "Work Center No." := WorkCenter."No.";
            "Work Center Group Code" := WorkCenter."Work Center Group Code";
            "Setup Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Run Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Wait Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            "Move Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
            if (not SkipUpdateDescription) and ("Standard Task Code" = '') then
                Description := WorkCenter.Name;
            "Flushing Method" := WorkCenter."Flushing Method";
            "Unit Cost per" := WorkCenter."Unit Cost";
            "Direct Unit Cost" := WorkCenter."Direct Unit Cost";
            "Indirect Cost %" := WorkCenter."Indirect Cost %";
            "Overhead Rate" := WorkCenter."Overhead Rate";
            "Unit Cost Calculation" := WorkCenter."Unit Cost Calculation";
            FillDefaultLocationAndBins();
        end;
        OnAfterWorkCenterTransferFields(Rec, WorkCenter);
    end;

    local procedure MachineCtrTransferFields()
    var
        IsHandled, SkipUpdateDescription : Boolean;
    begin
        WorkCenter.Get(MachineCenter."Work Center No.");
        WorkCenterTransferFields();

        IsHandled := false;
        SkipUpdateDescription := false;
        OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(Rec, WorkCenter, MachineCenter, SkipUpdateDescription, xRec, IsHandled);
        if not IsHandled then begin
            if not SkipUpdateDescription then
                Description := MachineCenter.Name;
            "Setup Time" := MachineCenter."Setup Time";
            "Wait Time" := MachineCenter."Wait Time";
            "Move Time" := MachineCenter."Move Time";
            "Fixed Scrap Quantity" := MachineCenter."Fixed Scrap Quantity";
            "Scrap Factor %" := MachineCenter."Scrap %";
            "Minimum Process Time" := MachineCenter."Minimum Process Time";
            "Maximum Process Time" := MachineCenter."Maximum Process Time";
            "Concurrent Capacities" := MachineCenter."Concurrent Capacities";
            if "Concurrent Capacities" = 0 then
                "Concurrent Capacities" := 1;
            "Send-Ahead Quantity" := MachineCenter."Send-Ahead Quantity";
            "Setup Time Unit of Meas. Code" := MachineCenter."Setup Time Unit of Meas. Code";
            "Wait Time Unit of Meas. Code" := MachineCenter."Wait Time Unit of Meas. Code";
            "Move Time Unit of Meas. Code" := MachineCenter."Move Time Unit of Meas. Code";
            "Flushing Method" := MachineCenter."Flushing Method";
            "Unit Cost per" := MachineCenter."Unit Cost";
            "Direct Unit Cost" := MachineCenter."Direct Unit Cost";
            "Indirect Cost %" := MachineCenter."Indirect Cost %";
            "Overhead Rate" := MachineCenter."Overhead Rate";
            "Unit Cost Calculation" := "Unit Cost Calculation"::Time;
            FillDefaultLocationAndBins();
        end;
        OnAfterMachineCtrTransferFields(Rec, WorkCenter, MachineCenter);
    end;

    procedure FillDefaultLocationAndBins()
    begin
        OnBeforeFillDefaultLocationAndBins(Rec);

        GetProdOrderLine();
        "Location Code" := ProdOrderLine."Location Code";
        "From-Production Bin Code" := '';
        if "Next Operation No." = '' then
            "From-Production Bin Code" := ProdOrderLine."Bin Code";

        case Type of
            Type::"Work Center":
                begin
                    if WorkCenter."No." <> "No." then
                        WorkCenter.Get("No.");
                    if WorkCenter."Location Code" = "Location Code" then begin
                        "Open Shop Floor Bin Code" := WorkCenter."Open Shop Floor Bin Code";
                        "To-Production Bin Code" := WorkCenter."To-Production Bin Code";
                        if "From-Production Bin Code" = '' then
                            "From-Production Bin Code" := WorkCenter."From-Production Bin Code";
                    end;
                end;
            Type::"Machine Center":
                begin
                    if MachineCenter."No." <> "No." then
                        MachineCenter.Get("No.");
                    if MachineCenter."Location Code" = "Location Code" then begin
                        "Open Shop Floor Bin Code" := MachineCenter."Open Shop Floor Bin Code";
                        "To-Production Bin Code" := MachineCenter."To-Production Bin Code";
                        if "From-Production Bin Code" = '' then
                            "From-Production Bin Code" := MachineCenter."From-Production Bin Code";
                    end;
                    if WorkCenter."No." <> MachineCenter."Work Center No." then
                        WorkCenter.Get(MachineCenter."Work Center No.");
                    if WorkCenter."Location Code" = "Location Code" then begin
                        if "Open Shop Floor Bin Code" = '' then
                            "Open Shop Floor Bin Code" := WorkCenter."Open Shop Floor Bin Code";
                        if "To-Production Bin Code" = '' then
                            "To-Production Bin Code" := WorkCenter."To-Production Bin Code";
                        if "From-Production Bin Code" = '' then
                            "From-Production Bin Code" := WorkCenter."From-Production Bin Code";
                    end;
                end;
        end;

        OnAfterFillDefaultLocationAndBins(Rec);
    end;

    procedure CalcStartingEndingDates(PlanningDirection: Option Forward,Backward)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgReserveCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcStartingEndingDates(Rec, PlanningDirection, IsHandled);
        if IsHandled then
            exit;

        if "Routing Status" = "Routing Status"::Finished then
            FieldError("Routing Status");

        Modify(true);

        ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");

        ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRoutingLine, PlanningDirection);
        ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRoutingLine.SetCurrentKey(
          Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Actual)");
        CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, PlanningDirection, false);

        IsHandled := false;
        OnCalcStartingEndingDatesOnBeforeCalculateRouting(ProdOrderRoutingLine, IsHandled);
        if not IsHandled then begin
            CalculateRoutingBack();
            CalculateRoutingForward();
        end;

        if Rec."Schedule Manually" then begin
            ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
            CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, PlanningDirection, false);
        end;

        Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        GetProdOrderLine();
        if PlanningDirection = PlanningDirection::Forward then
            ShiftTimeForwardOnParentProdOrderLines(ProdOrderLine);

        MfgReserveCheckDateConfl.ProdOrderLineCheck(ProdOrderLine, true);

        OnAfterCalcStartingEndingDates(Rec, xRec, ProdOrderLine, CurrFieldNo);
    end;

    procedure SetRecalcStatus()
    begin
        Recalculate := true;

        OnAfterSetRecalcStatus(Rec, ProdOrderLine);
    end;

    procedure RunTimePer() Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunTimePer(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if "Lot Size" = 0 then
            "Lot Size" := 1;

        exit("Run Time" / "Lot Size");
    end;

    local procedure CalculateRoutingBack()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if "Previous Operation No." <> '' then begin
            ProdOrderRoutingLine.SetRange(Status, Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRoutingLine.SetFilter("Operation No.", "Previous Operation No.");
            ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);

            if ProdOrderRoutingLine.Find('-') then
                repeat
                    ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Sequence No. (Actual)");
                    WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRoutingLine, Direction::Backward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, Direction::Backward, true);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (ProdOrderRoutingLine."Ending Date" > "Starting Date") or
                               ((ProdOrderRoutingLine."Ending Date" = "Starting Date") and
                                (ProdOrderRoutingLine."Ending Time" > "Starting Time"))
                            then begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRoutingLine, Direction::Backward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, Direction::Backward, true);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            if (ProdOrderRoutingLine."Ending Date" > "Starting Date") or
                                ((ProdOrderRoutingLine."Ending Date" = "Starting Date") and
                                (ProdOrderRoutingLine."Ending Time" > "Starting Time"))
                            then
                                Error(Text002);
                    end;
                    ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Operation No.");
                until ProdOrderRoutingLine.Next() = 0;
        end;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                CalcProdOrder.CalculateProdOrderDates(ProdOrderLine, true);
                OnCalculateRoutingBackOnAfterCalculateProdOrderDates(Rec, ProdOrderLine);
                AdjustComponents(ProdOrderLine);
            until ProdOrderLine.Next() = 0;
    end;

    local procedure CalculateRoutingForward()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if "Next Operation No." <> '' then begin
            ProdOrderRoutingLine.SetRange(Status, Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRoutingLine.SetFilter("Operation No.", "Next Operation No.");
            ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);

            if ProdOrderRoutingLine.Find('-') then
                repeat
                    ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Sequence No. (Actual)");
                    WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
                    case WorkCenter."Simulation Type" of
                        WorkCenter."Simulation Type"::Moves:
                            begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRoutingLine, Direction::Forward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, Direction::Forward, true);
                            end;
                        WorkCenter."Simulation Type"::"Moves When Necessary":
                            if (ProdOrderRoutingLine."Starting Date" < "Ending Date") or
                               ((ProdOrderRoutingLine."Starting Date" = "Ending Date") and
                                (ProdOrderRoutingLine."Starting Time" < "Ending Time"))
                            then begin
                                ProdOrderRouteMgt.CalcSequenceFromActual(ProdOrderRoutingLine, Direction::Forward);
                                CalcProdOrder.CalculateRoutingFromActual(ProdOrderRoutingLine, Direction::Forward, true);
                            end;
                        WorkCenter."Simulation Type"::Critical:
                            if (ProdOrderRoutingLine."Starting Date" < "Ending Date") or
                                ((ProdOrderRoutingLine."Starting Date" = "Ending Date") and
                                (ProdOrderRoutingLine."Starting Time" < "Ending Time"))
                            then
                                Error(Text003);
                    end;
                    ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
                      "Routing No.", "Operation No.");
                until ProdOrderRoutingLine.Next() = 0;
        end;

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                CalcProdOrder.CalculateProdOrderDates(ProdOrderLine, true);
                OnCalculateRoutingForwardOnAfterCalculateProdOrderDates(Rec, ProdOrderLine);
                AdjustComponents(ProdOrderLine);
            until ProdOrderLine.Next() = 0;
        CalcProdOrder.CalculateComponents();
    end;

    local procedure ModifyCapNeedEntries()
    begin
        ProdOrderCapNeed.SetRange(Status, Status);
        ProdOrderCapNeed.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderCapNeed.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderCapNeed.SetRange("Routing No.", "Routing No.");
        ProdOrderCapNeed.SetRange("Operation No.", "Operation No.");
        ProdOrderCapNeed.SetRange("Requested Only", false);
        if ProdOrderCapNeed.Find('-') then
            repeat
                ProdOrderCapNeed."No." := "No.";
                ProdOrderCapNeed."Work Center No." := "Work Center No.";
                ProdOrderCapNeed."Work Center Group Code" := "Work Center Group Code";
                ProdOrderCapNeed.Modify();
            until ProdOrderCapNeed.Next() = 0;
    end;

    local procedure AdjustComponents(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        OnBeforeAdjustComponents(ProdOrderComp);
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        if ProdOrderComp.Find('-') then
            repeat
                ProdOrderComp.Validate("Routing Link Code");
                ProdOrderComp.Modify();
            until ProdOrderComp.Next() = 0;
    end;

    procedure UpdateDatetime()
    begin
        if ("Starting Date" <> 0D) and ("Starting Time" <> 0T) then
            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time")
        else
            "Starting Date-Time" := 0DT;

        if ("Ending Date" <> 0D) and ("Ending Time" <> 0T) then
            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time")
        else
            "Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

    procedure CheckPreviousAndNext()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempDeletedProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        TempRemainingProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrderRoutingPage: Page "Prod. Order Routing";
        ErrorOnNext: Boolean;
        ErrorOnPrevious: Boolean;
    begin
        if IsSerial() then
            SetPreviousAndNext()
        else begin
            TempDeletedProdOrderRoutingLine := Rec;
            TempDeletedProdOrderRoutingLine.Insert();

            ProdOrderRoutingLine.SetRange(Status, Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
            ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
            ProdOrderRoutingLine.SetFilter("Operation No.", '<>%1', "Operation No.");
            ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);
            if ProdOrderRoutingLine.Find('-') then
                repeat
                    if ProdOrderRoutingLine."Next Operation No." <> '' then begin
                        TempDeletedProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Next Operation No.");
                        ErrorOnNext := TempDeletedProdOrderRoutingLine.FindFirst();
                    end else
                        ErrorOnNext := false;

                    if ProdOrderRoutingLine."Previous Operation No." <> '' then begin
                        TempDeletedProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Previous Operation No.");
                        ErrorOnPrevious := TempDeletedProdOrderRoutingLine.FindFirst();
                    end else
                        ErrorOnPrevious := false;

                    OnCheckPreviousAndNextOnBeforeInsertTempRemainingProdOrderRtngLine(Rec, ProdOrderRoutingLine, TempDeletedProdOrderRoutingLine, ErrorOnNext, ErrorOnPrevious);

                    if ErrorOnNext or ErrorOnPrevious then begin
                        TempRemainingProdOrderRoutingLine := ProdOrderRoutingLine;
                        TempRemainingProdOrderRoutingLine.Insert();
                    end
                until ProdOrderRoutingLine.Next() = 0;

            if TempRemainingProdOrderRoutingLine.Find('-') then begin
                Commit();
                if not HideValidationDialog then
                    if not ConfirmManagement.GetResponse(
                        StrSubstNo(Text004, FieldCaption("Next Operation No."), FieldCaption("Previous Operation No.")), true)
                    then
                        exit;
                ProdOrderRoutingPage.Initialize(StrSubstNo(Text005, "Operation No."));
                repeat
                    TempRemainingProdOrderRoutingLine.Mark(true);
                until TempRemainingProdOrderRoutingLine.Next() = 0;
                TempRemainingProdOrderRoutingLine.MarkedOnly(true);
                ProdOrderRoutingPage.SetTableView(TempRemainingProdOrderRoutingLine);
                ProdOrderRoutingPage.RunModal();
                OnCheckPreviousAndNextOnAfterProdOrderRoutingPageRunModal(TempRemainingProdOrderRoutingLine);
                Clear(ProdOrderRoutingPage);
            end;
        end;
    end;

    local procedure CheckRoutingNoNotBlank()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRoutingNoNotBlank(Rec, IsHandled);
        if not IsHandled then
            TestField("Routing No.");
    end;

    local procedure SetPreviousAndNext()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Previous Operation No.") then begin
            ProdOrderRoutingLine."Next Operation No." := "Next Operation No.";
            ProdOrderRoutingLine.Modify();
        end;
        if ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Next Operation No.") then begin
            ProdOrderRoutingLine."Previous Operation No." := "Previous Operation No.";
            ProdOrderRoutingLine.Modify();
        end;
    end;

    procedure SetNextOperations(var RtngLine: Record "Prod. Order Routing Line")
    var
        RtngLine2: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetNextOperations(RtngLine, IsHandled);
        if IsHandled then
            exit;

        RtngLine2.SetRange(Status, RtngLine.Status);
        RtngLine2.SetRange("Prod. Order No.", RtngLine."Prod. Order No.");
        RtngLine2.SetRange("Routing Reference No.", RtngLine."Routing Reference No.");
        RtngLine2.SetRange("Routing No.", RtngLine."Routing No.");
        RtngLine2.SetFilter("Operation No.", '>%1', RtngLine."Operation No.");

        if RtngLine2.FindFirst() then
            RtngLine."Next Operation No." := RtngLine2."Operation No."
        else begin
            RtngLine2.SetFilter("Operation No.", '');
            RtngLine2.SetRange("Next Operation No.", '');
            if RtngLine2.FindFirst() then begin
                RtngLine2."Next Operation No." := RtngLine."Operation No.";
                RtngLine2.Modify();
            end;
        end;
    end;

    procedure SubcontractingPurchOrderExist(): Boolean
    begin
        if Status <> Status::Released then
            exit(false);

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                PurchLine.SetCurrentKey(
                  "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                PurchLine.SetRange("Operation No.", "Operation No.");
                if not PurchLine.IsEmpty() then
                    exit(true);
            until ProdOrderLine.Next() = 0;

        exit(false);
    end;

    local procedure CheckIfSubcontractingPurchOrderExist()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfSubcontractingPurchOrderExist(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if SubcontractingPurchOrderExist() then
            Error(
              Text000,
              Status, TableCaption(), "Operation No.", PurchLine.TableCaption());
    end;

    procedure UpdateComponentsBin(FromTrigger: Option Insert,Modify,Delete)
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if SkipUpdateOfCompBinCodes then
            exit;

        if not UpdateOfComponentsBinRequired(FromTrigger) then
            exit;

        PopulateNewRoutingLineSet(TempProdOrderRoutingLine, FromTrigger);
        if ProdOrderRoutingLine.Get(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.") and ProdOrderRoutingLine.Recalculate then
            ProdOrderRouteMgt.UpdateComponentsBin(TempProdOrderRoutingLine, false);

        OnAfterUpdateComponentsBin(TempProdOrderRoutingLine, FromTrigger);
    end;

    local procedure UpdateOfComponentsBinRequired(FromTrigger: Option Insert,Modify,Delete) Result: Boolean
    begin
        if ("No." = '') and (xRec."No." = "No.") then // bin codes are and were empty
            exit(false);

        case FromTrigger of
            FromTrigger::Insert, FromTrigger::Delete:
                exit(("Previous Operation No." = '') or ("Routing Link Code" <> ''));
            FromTrigger::Modify:
                exit(
                  ((xRec."Previous Operation No." = '') and ("Previous Operation No." <> '')) or
                  ((xRec."Previous Operation No." <> '') and ("Previous Operation No." = '')) or
                  (xRec."Routing Link Code" <> "Routing Link Code") or
                  ((("Previous Operation No." = '') or ("Routing Link Code" <> '')) and
                   ((xRec."To-Production Bin Code" <> "To-Production Bin Code") or
                    (xRec."Open Shop Floor Bin Code" <> "Open Shop Floor Bin Code"))));
        end;

        OnAfterUpdateOfComponentsBinRequired(Rec, FromTrigger, Result);
    end;

    local procedure PopulateNewRoutingLineSet(var ProdOrderRoutingLineTmp: Record "Prod. Order Routing Line"; FromTrigger: Option Insert,Modify,Delete)
    var
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
    begin
        // copy existing routings for this prod. order to temporary table
        ProdOrderRoutingLineTmp.DeleteAll();
        ProdOrderRoutingLine2.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRoutingLine2.SetRange(Status, Status);
        ProdOrderRoutingLine2.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingLine2.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingLine2.SetRange("Routing No.", "Routing No.");
        if ProdOrderRoutingLine2.FindSet(false) then
            repeat
                ProdOrderRoutingLineTmp := ProdOrderRoutingLine2;
                ProdOrderRoutingLineTmp.Insert();
            until ProdOrderRoutingLine2.Next() = 0;

        // update the recordset with the current change
        ProdOrderRoutingLineTmp := Rec;
        case FromTrigger of
            FromTrigger::Insert:
                ProdOrderRoutingLineTmp.Insert();
            FromTrigger::Modify:
                ProdOrderRoutingLineTmp.Modify();
            FromTrigger::Delete:
                ProdOrderRoutingLineTmp.Delete();
        end;
    end;

    procedure SetSkipUpdateOfCompBinCodes(Setting: Boolean)
    begin
        SkipUpdateOfCompBinCodes := Setting;
    end;

    local procedure ShiftTimeForwardOnParentProdOrderLines(var ChildProdOrderLine: Record "Prod. Order Line")
    var
        ParentProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        MfgReservCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
    begin
        ParentProdOrderLine.SetRange(Status, ChildProdOrderLine.Status);
        ParentProdOrderLine.SetRange("Prod. Order No.", ChildProdOrderLine."Prod. Order No.");
        ParentProdOrderLine.SetRange("Planning Level Code", ChildProdOrderLine."Planning Level Code" - 1);
        ParentProdOrderLine.SetFilter("Starting Date-Time", '<%1', ChildProdOrderLine."Ending Date-Time");
        if ParentProdOrderLine.FindSet() then
            repeat
                ProdOrderComponent.SetRange(Status, ParentProdOrderLine.Status);
                ProdOrderComponent.SetRange("Prod. Order No.", ParentProdOrderLine."Prod. Order No.");
                ProdOrderComponent.SetRange("Prod. Order Line No.", ParentProdOrderLine."Line No.");
                ProdOrderComponent.SetRange("Supplied-by Line No.", ChildProdOrderLine."Line No.");
                if not ProdOrderComponent.IsEmpty() then begin
                    if GuiAllowed then
                        ShowMessage(TimeShiftedOnParentLineMsg);
                    ParentProdOrderLine.Validate("Starting Date-Time", ChildProdOrderLine."Ending Date-Time");
                    if ParentProdOrderLine."Planning Level Code" = 0 then
                        MfgReservCheckDateConfl.ProdOrderLineCheck(ParentProdOrderLine, true);

                    if ParentProdOrderLine."Ending Date-Time" < ParentProdOrderLine."Starting Date-Time" then
                        ParentProdOrderLine."Ending Date-Time" := ParentProdOrderLine."Starting Date-Time";
                    ParentProdOrderLine.Modify(true);
                    ShiftTimeForwardOnParentProdOrderLines(ParentProdOrderLine);
                end;
            until ParentProdOrderLine.Next() = 0;
    end;

    local procedure ShowMessage(MessageText: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowMessage(Rec, MessageText, IsHandled);
        if IsHandled then
            exit;

        TempErrorMessage.SetContext(Rec);
        if TempErrorMessage.FindRecord(RecordId, 0, TempErrorMessage."Message Type"::Warning, MessageText) = 0 then begin
            TempErrorMessage.LogMessage(Rec, 0, TempErrorMessage."Message Type"::Warning, MessageText);
            Message(MessageText);
        end;
    end;

    local procedure NoTerminationProcessesExist(): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");
        ProdOrderRoutingLine.SetRange("Next Operation No.", '');
        ProdOrderRoutingLine.SetFilter("Operation No.", '<>%1', "Operation No.");
        exit(ProdOrderRoutingLine.IsEmpty);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure IsSerial(): Boolean
    begin
        GetProdOrderLine();
        exit(ProdOrderLine."Routing Type" = ProdOrderLine."Routing Type"::Serial)
    end;

    procedure GetStartingEndingDateAndTime(var StartingTime: Time; var StartingDate: Date; var EndingTime: Time; var EndingDate: Date)
    begin
        StartingTime := DT2Time("Starting Date-Time");
        StartingDate := DT2Date("Starting Date-Time");
        EndingTime := DT2Time("Ending Date-Time");
        EndingDate := DT2Date("Ending Date-Time");
    end;

    local procedure AdjustProdOrderComponentForRoutingLinkCode(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; xProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetFilter("Routing Link Code", '%1|%2', ProdOrderRoutingLine."Routing Link Code", xProdOrderRoutingLine."Routing Link Code");
        if ProdOrderComponent.FindSet() then
            repeat
                UpdateDueDateTimeAndBinCodeInProdOrderComponent(ProdOrderComponent, ProdOrderRoutingLine);
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure UpdateDueDateTimeAndBinCodeInProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"): DateTime
    begin
        GetProdOrderLine();

        ProdOrderComponent."Due Date" := ProdOrderLine."Starting Date";
        ProdOrderComponent."Due Time" := ProdOrderLine."Starting Time";

        UpdateProdOrderComponentFromRoutingLine(ProdOrderComponent, ProdOrderRoutingLine);

        if Format(ProdOrderComponent."Lead-Time Offset") <> '' then begin
            ProdOrderComponent."Due Date" := ProdOrderComponent."Due Date" - (CalcDate(ProdOrderComponent."Lead-Time Offset", WorkDate()) - WorkDate());
            ProdOrderComponent."Due Time" := 0T;
        end;

        ProdOrderComponent.Validate("Due Date");
        ProdOrderComponent.GetDefaultBin();
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateProdOrderComponentFromRoutingLine(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        ExistingProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;

        if ProdOrderLine."Routing No." <> ProdOrderRoutingLine."Routing No." then
            exit;

        if ProdOrderLine."Routing Reference No." <> ProdOrderRoutingLine."Routing Reference No." then
            exit;

        if FindEarliestProdOrderRoutingLine(ExistingProdOrderRoutingLine, ProdOrderRoutingLine, ProdOrderComponent) then
            UpdateProdOrderComponentDueDateTime(ProdOrderComponent, ExistingProdOrderRoutingLine)
        else
            if ProdOrderRoutingLine."Routing Link Code" = ProdOrderComponent."Routing Link Code" then
                if ProdOrderRoutingLine."Routing Link Code" <> '' then
                    UpdateProdOrderComponentDueDateTime(ProdOrderComponent, ProdOrderRoutingLine);
    end;

    local procedure FindEarliestProdOrderRoutingLine(var ExistingProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderComponent: Record "Prod. Order Component"): Boolean
    begin
        ExistingProdOrderRoutingLine.SetCurrentKey("Starting Date", "Starting Time", "Routing Status");
        ExistingProdOrderRoutingLine.SetRange(Status, ProdOrderComponent.Status);
        ExistingProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ExistingProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ExistingProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ExistingProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        ExistingProdOrderRoutingLine.SetFilter("Operation No.", '<>%1', ProdOrderRoutingLine."Operation No.");
        if ExistingProdOrderRoutingLine.FindFirst() then
            if (ProdOrderRoutingLine."Routing Link Code" <> '') and (ProdOrderRoutingLine."Routing Link Code" = ExistingProdOrderRoutingLine."Routing Link Code") then
                exit(ExistingProdOrderRoutingLine."Starting Date-Time" < ProdOrderRoutingLine."Starting Date-Time")
            else
                exit(true);
    end;

    local procedure UpdateProdOrderComponentDueDateTime(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderComponent."Due Date" := ProdOrderRoutingLine."Starting Date";
        ProdOrderComponent."Due Time" := ProdOrderRoutingLine."Starting Time";
    end;

    procedure NextOperationExist(): Boolean
    begin
        OnBeforeNextOperationExist(Rec);
        exit("Next Operation No." <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcStartingEndingDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; SkipUpdateOfCompBinCodes: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDefaultLocationAndBins(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMachineCtrTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecalcStatus(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskTool(var ProdOrderRoutingTool: Record "Prod. Order Routing Tool"; StandardTaskTool: Record "Standard Task Tool")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskPersonnel(var ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel"; StandardTaskPersonnel: Record "Standard Task Personnel")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskQltyMeasure(var ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas."; StandardTaskQualityMeasure: Record "Standard Task Quality Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromStdTaskComment(var ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line"; StandardTaskDescription: Record "Standard Task Description")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNo(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustComponents(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStartingEndingDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var Direction: Option Forward,Backward; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRoutingNoNotBlank(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfSubcontractingPurchOrderExist(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillDefaultLocationAndBins(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetNextOperations(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTerminationProcessesErr(var IsHandled: Boolean; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; xProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcStartingEndingDatesOnBeforeCalculateRouting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPreviousAndNextOnAfterProdOrderRoutingPageRunModal(var TempRemainingProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingStatusOnBeforeConfirm(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPlanningRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStandardTaskCodeOnBeforeProdOrderRtngCommentLineInsert(var ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line"; StdTaskComment: Record "Standard Task Description")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateComponentsBin(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line"; FromTrigger: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOfComponentsBinRequired(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; FromTrigger: Option; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingBackOnAfterCalculateProdOrderDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingForwardOnAfterCalculateProdOrderDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunTimePer(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMachineCtrTransferFieldsOnAfterWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; MachineCenter: Record "Machine Center"; var SkipUpdateDescription: Boolean; xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWorkCenterTransferFields(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; var SkipUpdateDescription: Boolean; xProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMessage(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var MessageText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextOperationExist(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPreviousAndNextOnBeforeInsertTempRemainingProdOrderRtngLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderRoutingLineFiltered: Record "Prod. Order Routing Line"; var TempDeletedProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; var ErrorOnNext: Boolean; var ErrorOnPrevious: Boolean)
    begin
    end;
}

