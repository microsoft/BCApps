// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Structure;

table 99000754 "Work Center"
{
    Caption = 'Work Center';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Work Center List";
    LookupPageID = "Work Center List";
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
        field(12; "Alternate Work Center"; Code[20])
        {
            Caption = 'Alternate Work Center';
            TableRelation = "Work Center";
        }
        field(14; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            TableRelation = "Work Center Group";

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
                ProdOrderCapNeedEntry: Record "Prod. Order Capacity Need";
                PlanningRtngLine: Record "Planning Routing Line";
            begin
                if "Work Center Group Code" = xRec."Work Center Group Code" then
                    exit;

                CalendarEntry.SetCurrentKey("Work Center No.");
                CalendarEntry.SetRange("Work Center No.", "No.");
                if not CalendarEntry.Find('-') then
                    exit;

                if CurrFieldNo <> 0 then
                    if not Confirm(Text001, false, FieldCaption("Work Center Group Code"))
                    then begin
                        "Work Center Group Code" := xRec."Work Center Group Code";
                        exit;
                    end;

                Window.Open(
                  Text002 +
                  Text003 +
                  Text004 +
                  Text006);

                // Capacity Calendar
                EntryCounter := 0;
                NoOfRecords := CalendarEntry.Count();
                if CalendarEntry.Find('-') then
                    repeat
                        EntryCounter := EntryCounter + 1;
                        Window.Update(1, EntryCounter);
                        Window.Update(2, Round(EntryCounter / NoOfRecords * 10000, 1));
                        CalendarEntry."Work Center Group Code" := "Work Center Group Code";
                        CalendarEntry.Modify();
                    until CalendarEntry.Next() = 0;

                // Capacity Absence
                EntryCounter := 0;
                CalAbsentEntry.SetCurrentKey("Work Center No.");
                CalAbsentEntry.SetRange("Work Center No.", "No.");
                NoOfRecords := CalAbsentEntry.Count();
                if CalAbsentEntry.Find('-') then
                    repeat
                        EntryCounter := EntryCounter + 1;
                        Window.Update(3, EntryCounter);
                        Window.Update(4, Round(EntryCounter / NoOfRecords * 10000, 1));
                        CalAbsentEntry."Work Center Group Code" := "Work Center Group Code";
                        CalAbsentEntry.Modify();
                    until CalAbsentEntry.Next() = 0;

                EntryCounter := 0;

                ProdOrderCapNeedEntry.SetCurrentKey("Work Center No.");
                ProdOrderCapNeedEntry.SetRange("Work Center No.", "No.");
                NoOfRecords := ProdOrderCapNeedEntry.Count();
                if ProdOrderCapNeedEntry.Find('-') then
                    repeat
                        EntryCounter := EntryCounter + 1;
                        Window.Update(7, EntryCounter);
                        Window.Update(8, Round(EntryCounter / NoOfRecords * 10000, 1));
                        ProdOrderCapNeedEntry."Work Center Group Code" := "Work Center Group Code";
                        ProdOrderCapNeedEntry.Modify();
                    until ProdOrderCapNeedEntry.Next() = 0;

                OnValidateWorkCenterGroupCodeBeforeModify(Rec, xRec);
                Modify();

                RtngLine.SetCurrentKey("Work Center No.");
                RtngLine.SetRange("Work Center No.", "No.");
                RtngLine.ModifyAll("Work Center Group Code", "Work Center Group Code");

                PlanningRtngLine.SetCurrentKey("Work Center No.");
                PlanningRtngLine.SetRange("Work Center No.", "No.");
                PlanningRtngLine.ModifyAll("Work Center Group Code", "Work Center Group Code");

                ProdOrderRtngLine.SetCurrentKey("Work Center No.");
                ProdOrderRtngLine.SetRange("Work Center No.", "No.");
                ProdOrderRtngLine.ModifyAll("Work Center Group Code", "Work Center Group Code");

                Window.Close();
            end;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
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
        field(17; "Global Dimension 2 Code"; Code[20])
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
        field(18; "Subcontractor No."; Code[20])
        {
            Caption = 'Subcontractor No.';
            TableRelation = Vendor;
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
            CalcFormula = exist("Manufacturing Comment Line" where("Table Name" = const("Work Center"),
                                                                    "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Capacity Unit of Measure";

            trigger OnValidate()
            begin
                if "Unit of Measure Code" = xRec."Unit of Measure Code" then
                    exit;

                CalcFields("Prod. Order Need (Qty.)");
                if "Prod. Order Need (Qty.)" <> 0 then
                    Error(Text007, FieldCaption("Unit of Measure Code"));

                if xRec."Unit of Measure Code" <> '' then
                    if CurrFieldNo <> 0 then
                        if not Confirm(Text001, false, FieldCaption("Unit of Measure Code"))
                        then begin
                            "Unit of Measure Code" := xRec."Unit of Measure Code";
                            exit;
                        end;

                Window.Open(
                  Text008 +
                  Text009);

                Modify();

                // Capacity Calendar
                EntryCounter := 0;
                CalendarEntry.SetCurrentKey("Work Center No.");
                CalendarEntry.SetRange("Work Center No.", "No.");
                NoOfRecords := CalendarEntry.Count();
                if CalendarEntry.Find('-') then
                    repeat
                        EntryCounter := EntryCounter + 1;
                        Window.Update(1, EntryCounter);
                        Window.Update(2, Round(EntryCounter / NoOfRecords * 10000, 1));
                        CalendarEntry.Validate("Ending Time");
                        CalendarEntry.Modify();
                    until CalendarEntry.Next() = 0;

                Window.Close();
            end;
        }
        field(31; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
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
        field(35; "Calendar Rounding Precision"; Decimal)
        {
            Caption = 'Calendar Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 0.00001;
            MinValue = 0.00001;
            NotBlank = true;
        }
        field(36; "Simulation Type"; Option)
        {
            Caption = 'Simulation Type';
            OptionCaption = 'Moves,Moves When Necessary,Critical';
            OptionMembers = Moves,"Moves When Necessary",Critical;
        }
        field(37; "Shop Calendar Code"; Code[10])
        {
            Caption = 'Shop Calendar Code';
            TableRelation = "Shop Calendar";
        }
        field(38; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether the work center is blocked from being posted in transactions, for example, if the machine center is out of order.';
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
            CalcFormula = sum("Calendar Entry"."Capacity (Total)" where("Capacity Type" = const("Work Center"),
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
            CalcFormula = sum("Calendar Entry"."Capacity (Effective)" where("Capacity Type" = const("Work Center"),
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
            CalcFormula = sum("Prod. Order Capacity Need"."Allocated Time" where("Work Center No." = field("No."),
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
            CalcFormula = sum("Prod. Order Routing Line"."Expected Operation Cost Amt." where("Work Center No." = field("No."),
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
        field(50; "Unit Cost Calculation"; Enum "Unit Cost Calculation Type")
        {
            Caption = 'Unit Cost Calculation';
        }
        field(51; "Specific Unit Cost"; Boolean)
        {
            Caption = 'Specific Unit Cost';
        }
        field(52; "Consolidated Calendar"; Boolean)
        {
            Caption = 'Consolidated Calendar';
        }
        field(53; "Flushing Method"; Enum "Flushing Method Routing")
        {
            Caption = 'Flushing Method';
            ToolTip = 'Specifies the method to use to calculate and handle output at the work center. Manual: Output must be posted manually by using the output journal. Forward: Output is automatically calculated and posted when you change the status of a simulated, planned (or firm planned) production order to Released. You can still post output manually from the output journal. Backward: Output is automatically calculated and posted when you change the status of a released production order to Finished or when the last operation is finished. You can still post output manually from the output journal. The setting you make in this field is copied to the Flushing Method field on the production order routing line according to the machine/work center of the master routing, but you can change the field for an individual production order to allow a different output (or consumption) posting of that order.';
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
            TableRelation = Location.Code where("Use As In-Transit" = const(false),
                                                 "Bin Mandatory" = const(true));

            trigger OnValidate()
            var
                Location: Record Location;
                MachineCenter: Record "Machine Center";
                AutoUpdate: Boolean;
            begin
                if "Location Code" <> xRec."Location Code" then begin
                    if "Location Code" <> '' then begin
                        Location.Get("Location Code");
                        if not Location."Bin Mandatory" then
                            Error(LocationMustBeBinMandatoryErr, Location.Code, "No.");
                    end;

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
                    MachineCenter.SetCurrentKey("Work Center No.");
                    MachineCenter.SetRange("Work Center No.", "No.");
                    if MachineCenter.FindSet(true) then
                        repeat
                            MachineCenter."Location Code" := "Location Code";
                            if MachineCenter."Open Shop Floor Bin Code" <> '' then
                                if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                                    MachineCenter.Validate("Open Shop Floor Bin Code", '')
                                else
                                    MachineCenter.TestField("Open Shop Floor Bin Code", '');
                            if MachineCenter."To-Production Bin Code" <> '' then
                                if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                                    MachineCenter.Validate("To-Production Bin Code", '')
                                else
                                    MachineCenter.TestField("To-Production Bin Code", '');
                            if MachineCenter."From-Production Bin Code" <> '' then
                                if ConfirmAutoRemovalOfBinCode(AutoUpdate) then
                                    MachineCenter.Validate("From-Production Bin Code", '')
                                else
                                    MachineCenter.TestField("From-Production Bin Code", '');
                            MachineCenter.Modify(true);
                        until MachineCenter.Next() = 0;
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
        key(Key3; "Work Center Group Code")
        {
        }
        key(Key4; "Subcontractor No.")
        {
        }
        key(Key5; Name)
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
        CapLedgEntry.SetRange("Work Center No.", "No.");
        if not CapLedgEntry.IsEmpty() then
            Error(Text010, TableCaption(), "No.", CapLedgEntry.TableCaption());

        CheckRoutingWithWorkCenterExists();

        StdCostWksh.Reset();
        StdCostWksh.SetRange(Type, StdCostWksh.Type::"Work Center");
        StdCostWksh.SetRange("No.", "No.");
        if not StdCostWksh.IsEmpty() then
            Error(Text010, TableCaption(), "No.", StdCostWksh.TableCaption());

        CalendarEntry.SetCurrentKey("Capacity Type", "No.");
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalendarEntry.SetRange("No.", "No.");
        CalendarEntry.DeleteAll();

        CalAbsentEntry.SetCurrentKey("Capacity Type", "No.");
        CalAbsentEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
        CalAbsentEntry.SetRange("No.", "No.");
        CalAbsentEntry.DeleteAll();

        MfgCommentLine.SetRange("Table Name", MfgCommentLine."Table Name"::"Work Center");
        MfgCommentLine.SetRange("No.", "No.");
        MfgCommentLine.DeleteAll();

        ProdOrderRtngLine.SetRange("Work Center No.", "No.");
        if not ProdOrderRtngLine.IsEmpty() then
            Error(Text000);

        DimMgt.DeleteDefaultDim(Database::"Work Center", "No.");

        Validate("Location Code", ''); // to clean up the default bins
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        MfgSetup.Get();
        if "No." = '' then begin
            MfgSetup.TestField("Work Center Nos.");
                "No. Series" := MfgSetup."Work Center Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
        DimMgt.UpdateDefaultDim(
          Database::"Work Center", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(Database::"Work Center", xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        PostCode: Record "Post Code";
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        CalendarEntry: Record "Calendar Entry";
        CalAbsentEntry: Record "Calendar Absence Entry";
        MfgCommentLine: Record "Manufacturing Comment Line";
        RtngLine: Record "Routing Line";
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        EntryCounter: Integer;
        NoOfRecords: Integer;
        GLSetupRead: Boolean;

#pragma warning disable AA0074
        Text000: Label 'The Work Center is being used on production orders.';
#pragma warning disable AA0470
        Text001: Label 'Do you want to change %1?';
#pragma warning restore AA0470
        Text002: Label 'Work Center Group Code is changed...\\';
#pragma warning disable AA0470
        Text003: Label 'Calendar Entry    #1###### @2@@@@@@@@@@@@@\';
        Text004: Label 'Calendar Absent.  #3###### @4@@@@@@@@@@@@@\';
        Text006: Label 'Prod. Order Need  #7###### @8@@@@@@@@@@@@@';
        Text007: Label '%1 cannot be changed for scheduled work centers.';
#pragma warning restore AA0470
        Text008: Label 'Capacity Unit of Time is corrected on\\';
#pragma warning disable AA0470
        Text009: Label 'Calendar Entry    #1###### @2@@@@@@@@@@@@@';
#pragma warning restore AA0470
        Text010: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Table caption; %2 = Field Value; %3 = Table Caption';
#pragma warning disable AA0470
        Text011: Label 'If you change the %1, then all bin codes on the %2 and related %3 will be removed. Are you sure that you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        LocationMustBeBinMandatoryErr: Label 'Location %1 must be set up with Bin Mandatory if the Work Center %2 uses it.', Comment = '%2 = Work Center No.';
#pragma warning restore AA0470

    procedure AssistEdit(OldWorkCenter: Record "Work Center"): Boolean
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldWorkCenter, IsHandled);
        if IsHandled then
            exit;

        WorkCenter := Rec;
        MfgSetup.Get();
        MfgSetup.TestField("Work Center Nos.");
        if NoSeries.LookupRelatedNoSeries(MfgSetup."Work Center Nos.", OldWorkCenter."No. Series", WorkCenter."No. Series") then begin
            WorkCenter."No." := NoSeries.GetNextNo(WorkCenter."No. Series");
            Rec := WorkCenter;
            exit(true);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Work Center", "No.", FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure ConfirmAutoRemovalOfBinCode(var AutoUpdate: Boolean): Boolean
    var
        MachineCenter: Record "Machine Center";
    begin
        if AutoUpdate then
            exit(true);

        if Confirm(Text011, false, FieldCaption("Location Code"), TableCaption(), MachineCenter.TableCaption()) then
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

    local procedure CheckRoutingWithWorkCenterExists()
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", "No.");
        if not RoutingLine.IsEmpty() then
            Error(Text010, TableCaption(), "No.", RoutingLine.TableCaption());
    end;

    procedure CheckBinCode(LocationCode: Code[10]; BinCode: Code[20]; BinCaption: Text; WorkCenterNo: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if BinCode <> '' then begin
            Location.Get(LocationCode);
            if not Location."Bin Mandatory" then
                Error(LocationMustBeBinMandatoryErr, Location.Code, WorkCenterNo);
            Bin.Get(LocationCode, BinCode);
            WhseIntegrationMgt.CheckBinTypeAndCode(Database::"Work Center", BinCaption, LocationCode, BinCode, 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBinCodeForFlushingMethod(WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var WorkCenter: Record "Work Center"; var xWorkCenter: Record "Work Center"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var WorkCenter: Record "Work Center"; OldWorkCenter: Record "Work Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var WorkCenter: Record "Work Center"; var xWorkCenter: Record "Work Center"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateWorkCenterGroupCodeBeforeModify(var WorkCenter: Record "Work Center"; var xWorkCenter: Record "Work Center")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var WorkCenter: Record "Work Center"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var WorkCenter: Record "Work Center"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}
