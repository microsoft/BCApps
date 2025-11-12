// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Structure;

table 99000758 "Machine Center"
{
    Caption = 'Machine Center';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Machine Center List";
    LookupPageID = "Machine Center List";
    Permissions = TableData "Prod. Order Capacity Need" = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                "Search Name" := Name;
            end;
        }
        field(4; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(14; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center";

            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
                ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                PlanningRtngLine: Record "Planning Routing Line";
                SkipValidateLocationCode: Boolean;
            begin
                if "Work Center No." = xRec."Work Center No." then
                    exit;

                if "Work Center No." <> '' then begin
                    WorkCenter.Get("Work Center No.");
                    WorkCenter.TestField("Unit of Measure Code");
                    "Queue Time Unit of Meas. Code" := WorkCenter."Queue Time Unit of Meas. Code";
                    "Setup Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
                    "Wait Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
                    "Move Time Unit of Meas. Code" := WorkCenter."Unit of Measure Code";
                    OnWorkCenterNoOnValidateOnAfterCopyFromWorkCenter(Rec, WorkCenter);
                end;
                SkipValidateLocationCode := false;
                OnValidateWorkCenterNoOnBeforeValidateLocationCode(Rec, WorkCenter, SkipValidateLocationCode);
                if not SkipValidateLocationCode then
                    Validate("Location Code", WorkCenter."Location Code");

                CalendarEntry.SetCurrentKey("Capacity Type", "No.");
                CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
                CalendarEntry.SetRange("No.", "No.");
                if not CalendarEntry.Find('-') then
                    exit;

                if CurrFieldNo <> 0 then
                    if not Confirm(Text001, false, FieldCaption("Work Center No."))
                    then begin
                        "Work Center No." := xRec."Work Center No.";
                        exit;
                    end;

                Window.Open(
                  Text002 +
                  Text003 +
                  Text004 +
                  Text006);

                i := 0;
                NoOfRecords := CalendarEntry.Count();
                if CalendarEntry.Find('-') then
                    repeat
                        i := i + 1;
                        Window.Update(1, i);
                        Window.Update(2, Round(i / NoOfRecords * 10000, 1));
                        CalendarEntry.Validate("Work Center No.", "Work Center No.");
                        CalendarEntry.Modify();
                    until CalendarEntry.Next() = 0;

                i := 0;
                CalAbsentEntry.SetCurrentKey("Capacity Type", "No.");
                CalAbsentEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
                CalAbsentEntry.SetRange("No.", "No.");
                NoOfRecords := CalAbsentEntry.Count();
                if CalAbsentEntry.Find('-') then
                    repeat
                        i := i + 1;
                        Window.Update(3, i);
                        Window.Update(4, Round(i / NoOfRecords * 10000, 1));
                        CalAbsentEntry.Validate("Work Center No.", "Work Center No.");
                        CalAbsentEntry.Modify();
                    until CalAbsentEntry.Next() = 0;

                i := 0;
                ProdOrderCapNeed.SetCurrentKey(Type, "No.");
                ProdOrderCapNeed.SetRange(Type, ProdOrderCapNeed.Type::"Machine Center");
                ProdOrderCapNeed.SetRange("No.", "No.");
                NoOfRecords := ProdOrderCapNeed.Count();
                if ProdOrderCapNeed.Find('-') then
                    repeat
                        i := i + 1;
                        Window.Update(7, i);
                        Window.Update(8, Round(i / NoOfRecords * 10000, 1));
                        ProdOrderCapNeed.Validate("Work Center No.", "Work Center No.");
                        ProdOrderCapNeed.Modify();
                    until ProdOrderCapNeed.Next() = 0;

                OnValidateWorkCenterNoBeforeModify(Rec, xRec, CurrFieldNo);
                Modify();

                RtngLine.SetCurrentKey(Type, "No.");
                RtngLine.SetRange(Type, RtngLine.Type::"Machine Center");
                RtngLine.SetRange("No.", "No.");
                if RtngLine.Find('-') then
                    repeat
                        RtngLine.Validate("Work Center No.", "Work Center No.");
                        RtngLine.Modify();
                    until RtngLine.Next() = 0;

                PlanningRtngLine.SetCurrentKey(Type, "No.");
                PlanningRtngLine.SetRange(Type, PlanningRtngLine.Type::"Machine Center");
                PlanningRtngLine.SetRange("No.", "No.");
                if PlanningRtngLine.Find('-') then
                    repeat
                        PlanningRtngLine.Validate("Work Center No.", "Work Center No.");
                        PlanningRtngLine.Modify();
                    until PlanningRtngLine.Next() = 0;

                ProdOrderRtngLine.SetCurrentKey(Type, "No.");
                ProdOrderRtngLine.SetRange(Type, PlanningRtngLine.Type::"Machine Center");
                ProdOrderRtngLine.SetRange("No.", "No.");
                if ProdOrderRtngLine.Find('-') then
                    repeat
                        ProdOrderRtngLine.Validate("Work Center No.", "Work Center No.");
                        ProdOrderRtngLine.Modify();
                    until ProdOrderRtngLine.Next() = 0;

                Window.Close();
            end;
        }
        field(19; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(20; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetGLSetup();
                "Unit Cost" :=
                  Round(
                    "Direct Unit Cost" * (1 + "Indirect Cost %" / 100) + "Overhead Rate",
                    GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(21; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                GetGLSetup();
                "Direct Unit Cost" :=
                  Round(("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(22; "Queue Time"; Decimal)
        {
            Caption = 'Queue Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(23; "Queue Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Queue Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(27; Comment; Boolean)
        {
            CalcFormula = exist("Manufacturing Comment Line" where("Table Name" = const("Machine Center"),
                                                                    "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(32; Efficiency; Decimal)
        {
            Caption = 'Efficiency';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
            MinValue = 0;
        }
        field(33; "Maximum Efficiency"; Decimal)
        {
            Caption = 'Maximum Efficiency';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(34; "Minimum Efficiency"; Decimal)
        {
            Caption = 'Minimum Efficiency';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(38; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether the machine center is blocked from being posted in transactions, for example, if the machine center is out of order.';
        }
        field(39; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(40; "Work Shift Filter"; Code[10])
        {
            Caption = 'Work Shift Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Shift";
        }
        field(41; "Capacity (Total)"; Decimal)
        {
            CalcFormula = sum("Calendar Entry"."Capacity (Total)" where("Capacity Type" = const("Machine Center"),
                                                                         "No." = field("No."),
                                                                         "Work Shift Code" = field("Work Shift Filter"),
                                                                         Date = field("Date Filter")));
            Caption = 'Capacity (Total)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Capacity (Effective)"; Decimal)
        {
            CalcFormula = sum("Calendar Entry"."Capacity (Effective)" where("Capacity Type" = const("Machine Center"),
                                                                             "No." = field("No."),
                                                                             "Work Shift Code" = field("Work Shift Filter"),
                                                                             Date = field("Date Filter")));
            Caption = 'Capacity (Effective)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(44; "Prod. Order Need (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where(Type = const("Machine Center"),
                                                                                  "No." = field("No."),
                                                                                  Status = field("Prod. Order Status Filter"),
                                                                                  Date = field("Date Filter"),
                                                                                  "Requested Only" = const(false)));
            Caption = 'Prod. Order Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Prod. Order Need Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Routing Line"."Expected Operation Cost Amt." where(Type = const("Machine Center"),
                                                                                               "No." = field("No."),
                                                                                               Status = field("Prod. Order Status Filter")));
            Caption = 'Prod. Order Need Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Prod. Order Status Filter"; Enum "Production Order Status")
        {
            Caption = 'Prod. Order Status Filter';
            FieldClass = FlowFilter;
        }
        field(50; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(52; "Wait Time"; Decimal)
        {
            Caption = 'Wait Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(53; "Move Time"; Decimal)
        {
            Caption = 'Move Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(54; "Fixed Scrap Quantity"; Decimal)
        {
            Caption = 'Fixed Scrap Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(55; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(56; "Setup Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Setup Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(57; "Wait Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Wait Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(58; "Send-Ahead Quantity"; Decimal)
        {
            Caption = 'Send-Ahead Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(59; "Move Time Unit of Meas. Code"; Code[10])
        {
            Caption = 'Move Time Unit of Meas. Code';
            TableRelation = "Capacity Unit of Measure";
        }
        field(60; "Flushing Method"; Enum "Flushing Method Routing")
        {
            Caption = 'Flushing Method';
            ToolTip = 'Specifies the method to use to calculate and handle output at the machine center. Manual: Output must be posted manually by using the output journal. Forward: Output is automatically calculated and posted when you change the status of a simulated, planned (or firm planned) production order to Released. You can still post output manually from the output journal. Backward: Output is automatically calculated and posted when you change the status of a released production order to Finished. You can still post output manually from the output journal. The setting you make in this field is copied to the Flushing Method field on the production order routing line according to the machine/work center of the master routing, but you can change the field for an individual production order to allow a different output posting of that order.';
        }
        field(62; "Minimum Process Time"; Decimal)
        {
            Caption = 'Minimum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(63; "Maximum Process Time"; Decimal)
        {
            Caption = 'Maximum Process Time';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(64; "Concurrent Capacities"; Decimal)
        {
            Caption = 'Concurrent Capacities';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(65; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
            TableRelation = Item;
        }
        field(66; "Stop Code Filter"; Code[10])
        {
            Caption = 'Stop Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Stop;
        }
        field(67; "Scrap Code Filter"; Code[10])
        {
            Caption = 'Scrap Code Filter';
            FieldClass = FlowFilter;
            TableRelation = Scrap;
        }
        field(80; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(81; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(82; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(83; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(84; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(7300; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location.Code where("Use As In-Transit" = const(false),
                                                 "Bin Mandatory" = const(true));

            trigger OnValidate()
            var
                WorkCenter: Record "Work Center";
                AutoUpdate: Boolean;
            begin
                if "Location Code" <> xRec."Location Code" then begin
                    if ("Work Center No." = '') and ("Location Code" <> '') then
                        Error(Text008, FieldCaption("Location Code"), TableCaption(), WorkCenter.TableCaption());

                    if "Open Shop Floor Bin Code" <> '' then
                        if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                            Validate("Open Shop Floor Bin Code", '')
                        else
                            TestField("Open Shop Floor Bin Code", '');
                    if "To-Production Bin Code" <> '' then
                        if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                            Validate("To-Production Bin Code", '')
                        else
                            TestField("To-Production Bin Code", '');
                    if "From-Production Bin Code" <> '' then
                        if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                            Validate("From-Production Bin Code", '')
                        else
                            TestField("From-Production Bin Code", '');
                end;
            end;
        }
        field(7301; "Open Shop Floor Bin Code"; Code[20])
        {
            Caption = 'Open Shop Floor Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                CheckBinCode("Location Code", "Open Shop Floor Bin Code", FieldCaption("Open Shop Floor Bin Code"), "No.");
            end;
        }
        field(7302; "To-Production Bin Code"; Code[20])
        {
            Caption = 'To-Production Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                CheckBinCode("Location Code", "To-Production Bin Code", FieldCaption("To-Production Bin Code"), "No.");
            end;
        }
        field(7303; "From-Production Bin Code"; Code[20])
        {
            Caption = 'From-Production Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                CheckBinCode("Location Code", "From-Production Bin Code", FieldCaption("From-Production Bin Code"), "No.");
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Work Center No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name)
        {
        }
    }

    trigger OnDelete()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        StdCostWksh: Record "Standard Cost Worksheet";
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.SetRange(Type, CapLedgEntry.Type::"Machine Center");
        CapLedgEntry.SetRange("No.", "No.");
        if not CapLedgEntry.IsEmpty() then
            Error(Text007, TableCaption(), "No.", CapLedgEntry.TableCaption());

        CheckRoutingWithMachineCenterExists();

        StdCostWksh.Reset();
        StdCostWksh.SetRange(Type, StdCostWksh.Type::"Machine Center");
        StdCostWksh.SetRange("No.", "No.");
        if not StdCostWksh.IsEmpty() then
            Error(Text007, TableCaption(), "No.", StdCostWksh.TableCaption());

        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
        CalendarEntry.SetRange("No.", "No.");
        CalendarEntry.DeleteAll();

        CalAbsentEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
        CalAbsentEntry.SetRange("No.", "No.");
        CalAbsentEntry.DeleteAll();

        MfgCommentLine.SetRange("Table Name", MfgCommentLine."Table Name"::"Machine Center");
        MfgCommentLine.SetRange("No.", "No.");
        MfgCommentLine.DeleteAll();

        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Machine Center");
        ProdOrderRtngLine.SetRange("No.", "No.");
        if not ProdOrderRtngLine.IsEmpty() then
            Error(Text000);
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        MfgSetup.Get();
        if "No." = '' then begin
            MfgSetup.TestField("Machine Center Nos.");
            if NoSeries.AreRelated(MfgSetup."Machine Center Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := MfgSetup."Machine Center Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        PostCode: Record "Post Code";
        MfgSetup: Record "Manufacturing Setup";
        MachineCenter: Record "Machine Center";
        CalendarEntry: Record "Calendar Entry";
        CalAbsentEntry: Record "Calendar Absence Entry";
        MfgCommentLine: Record "Manufacturing Comment Line";
        RtngLine: Record "Routing Line";
        GLSetup: Record "General Ledger Setup";
        Window: Dialog;
        i: Integer;
        NoOfRecords: Integer;
        GLSetupRead: Boolean;

#pragma warning disable AA0074
        Text000: Label 'The Machine Center is being used on production orders.';
#pragma warning disable AA0470
        Text001: Label 'Do you want to change %1?';
#pragma warning restore AA0470
        Text002: Label 'Work Center No. is corrected on\\';
#pragma warning disable AA0470
        Text003: Label 'Calendar Entry    #1###### @2@@@@@@@@@@@@@\';
        Text004: Label 'Calendar Absent.  #3###### @4@@@@@@@@@@@@@\';
        Text006: Label 'Prod. Order Need  #7###### @8@@@@@@@@@@@@@';
#pragma warning restore AA0470
        Text007: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Table caption; %2 = Field Value; %3 = Table Caption';
#pragma warning disable AA0470
        Text008: Label 'You cannot change the %1 on %2 unless it is linked to a %3.';
        Text009: Label 'If you change the %1, then all bin codes on the %2 will be removed. Are you sure that you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        LocationMustBeBinMandatoryErr: Label 'Location %1 must be set up with Bin Mandatory if the Machine Center %2 uses it.', Comment = '%2 = Machine Center No.';
#pragma warning restore AA0470

    procedure AssistEdit(OldMachineCenter: Record "Machine Center"): Boolean
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldMachineCenter, IsHandled);
        if IsHandled then
            exit;

        MachineCenter := Rec;
        MfgSetup.Get();
        MfgSetup.TestField("Machine Center Nos.");
        if NoSeries.LookupRelatedNoSeries(MfgSetup."Machine Center Nos.", OldMachineCenter."No. Series", MachineCenter."No. Series") then begin
            MachineCenter."No." := NoSeries.GetNextNo(MachineCenter."No. Series");
            Rec := MachineCenter;
            exit(true);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure ConfirmAutoRemovalOfBinCode(var AutoUpdate: Boolean): Boolean
    begin
        if AutoUpdate then
            exit(true);

        if Confirm(Text009, false, FieldCaption("Location Code"), TableCaption) then
            AutoUpdate := true;

        exit(AutoUpdate);
    end;

    procedure GetBinCodeForFlushingMethod(UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method") Result: Code[20]
#if not CLEAN26
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
        if not UseFlushingMethod then
            exit("From-Production Bin Code");

#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            case FlushingMethod of
                FlushingMethod::Manual,
                FlushingMethod::"Pick + Manual",
                FlushingMethod::"Pick + Forward",
                FlushingMethod::"Pick + Backward":
                    exit("To-Production Bin Code");
                FlushingMethod::Forward,
                FlushingMethod::Backward:
                    exit("Open Shop Floor Bin Code");
            end
        else
#endif
            case FlushingMethod of
                FlushingMethod::"Pick + Manual",
                FlushingMethod::"Pick + Forward",
                FlushingMethod::"Pick + Backward":
                    exit("To-Production Bin Code");
                FlushingMethod::Manual,
                FlushingMethod::Forward,
                FlushingMethod::Backward:
                    exit("Open Shop Floor Bin Code");
            end;

        OnAfterGetBinCodeForFlushingMethod(Rec, FlushingMethod, Result);
    end;

    local procedure CheckRoutingWithMachineCenterExists()
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange(Type, RoutingLine.Type::"Machine Center");
        RoutingLine.SetRange("No.", "No.");
        if not RoutingLine.IsEmpty() then
            Error(Text007, TableCaption(), "No.", RoutingLine.TableCaption());
    end;

    procedure CheckBinCode(LocationCode: Code[10]; BinCode: Code[20]; BinCaption: Text; MachineCenterNo: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if BinCode <> '' then begin
            Location.Get(LocationCode);
            if not Location."Bin Mandatory" then
                Error(LocationMustBeBinMandatoryErr, Location.Code, MachineCenterNo);
            Bin.Get(LocationCode, BinCode);
            WhseIntegrationMgt.CheckBinTypeAndCode(Database::"Machine Center", BinCaption, LocationCode, BinCode, 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBinCodeForFlushingMethod(MachineCenter: Record "Machine Center"; FlushingMethod: Enum "Flushing Method"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var MachineCenter: Record "Machine Center"; OldMachineCenter: Record "Machine Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateWorkCenterNoBeforeModify(var MachineCenter: Record "Machine Center"; xMachineCenter: Record "Machine Center"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWorkCenterNoOnValidateOnAfterCopyFromWorkCenter(var MachineCenter: Record "Machine Center"; WorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var MachineCenter: Record "Machine Center"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var MachineCenter: Record "Machine Center"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateWorkCenterNoOnBeforeValidateLocationCode(var MachineCenter: Record "Machine Center"; WorkCenter: Record "Work Center"; var SkipValidateLocationCode: Boolean)
    begin
    end;
}
