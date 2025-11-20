// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
#if not CLEAN27
using Microsoft.Foundation.Calendar;
#endif
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using System.Telemetry;
using System.Utilities;

table 99000765 "Manufacturing Setup"
{
    Caption = 'Manufacturing Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Manufacturing Setup";
    LookupPageID = "Manufacturing Setup";
    InherentEntitlements = R;
    InherentPermissions = r;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            Editable = false;
        }
        field(7; "Normal Starting Time"; Time)
        {
            Caption = 'Normal Starting Time';
        }
        field(8; "Normal Ending Time"; Time)
        {
            Caption = 'Normal Ending Time';
        }
        field(9; "Doc. No. Is Prod. Order No."; Boolean)
        {
            Caption = 'Doc. No. Is Prod. Order No.';
            InitValue = true;
        }
        field(11; "Cost Incl. Setup"; Boolean)
        {
            Caption = 'Cost Incl. Setup';
        }
        field(12; "Dynamic Low-Level Code"; Boolean)
        {
            Caption = 'Dynamic Low-Level Code';

            trigger OnValidate()
            var
                LowLevelCodeCalculator: Codeunit "Low-Level Code Calculator";
            begin
                if xRec."Dynamic Low-Level Code" and (not "Dynamic Low-Level Code") then
                    LowLevelCodeCalculator.SuggestToRunAsBackgroundJob();
            end;
        }
        field(18; "Planning Warning"; Boolean)
        {
            Caption = 'Planning Warning';
        }
        field(20; "Simulated Order Nos."; Code[20])
        {
            Caption = 'Simulated Order Nos.';
            TableRelation = "No. Series";
        }
        field(21; "Planned Order Nos."; Code[20])
        {
            Caption = 'Planned Order Nos.';
            TableRelation = "No. Series";
        }
        field(22; "Firm Planned Order Nos."; Code[20])
        {
            Caption = 'Firm Planned Order Nos.';
            TableRelation = "No. Series";
        }
        field(23; "Released Order Nos."; Code[20])
        {
            Caption = 'Released Order Nos.';
            TableRelation = "No. Series";
        }
        field(29; "Work Center Nos."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Work Center Nos.';
            TableRelation = "No. Series";
        }
        field(30; "Machine Center Nos."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Machine Center Nos.';
            TableRelation = "No. Series";
        }
        field(31; "Production BOM Nos."; Code[20])
        {
            AccessByPermission = TableData "Production BOM Header" = R;
            Caption = 'Production BOM Nos.';
            TableRelation = "No. Series";
        }
        field(32; "Routing Nos."; Code[20])
        {
            AccessByPermission = TableData "Calendar Absence Entry" = R;
            Caption = 'Routing Nos.';
            TableRelation = "No. Series";
        }
        field(35; "Current Production Forecast"; Code[10])
        {
            Caption = 'Current Demand Forecast';
            TableRelation = "Production Forecast Name".Name;
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(36; "Use Forecast on Variants"; Boolean)
        {
            Caption = 'Use forecast on variants';
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(37; "Use Forecast on Locations"; Boolean)
        {
            Caption = 'Use forecast on locations';
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(38; "Combined MPS/MRP Calculation"; Boolean)
        {
            AccessByPermission = TableData "Planning Component" = R;
            Caption = 'Combined MPS/MRP Calculation';
            InitValue = true;
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(39; "Components at Location"; Code[10])
        {
            Caption = 'Components at Location';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(40; "Default Dampener Period"; DateFormula)
        {
            Caption = 'Default Dampener Period';
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
#if not CLEAN27
            trigger OnValidate()
            var
                CalendarMgt: Codeunit "Calendar Management";
            begin
                CalendarMgt.CheckDateFormulaPositive("Default Dampener Period");
            end;
#endif
        }
        field(41; "Default Dampener %"; Decimal)
        {
            Caption = 'Default Dampener %';
            DecimalPlaces = 1 : 1;
            MinValue = 0;
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(42; "Default Safety Lead Time"; DateFormula)
        {
            Caption = 'Default Safety Lead Time';
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(43; "Blank Overflow Level"; Option)
        {
            Caption = 'Blank Overflow Level';
            OptionCaption = 'Allow Default Calculation,Use Item/SKU Values Only';
            OptionMembers = "Allow Default Calculation","Use Item/SKU Values Only";
            ObsoleteReason = 'Field moved to same field in table Inventory Setup';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(50; "Show Capacity In"; Code[10])
        {
            Caption = 'Show Capacity In';
            TableRelation = "Capacity Unit of Measure".Code;
        }
        field(55; "Default Consum. Calc. Based on"; Option)
        {
            Caption = 'Default Consumption Calculation Based on';
            InitValue = "Expected Output";
            ToolTip = 'Specifies default calculation based on, used for consumption calculation. Whether the calculation of the quantity to consume is based on the actual output or on the expected output (the quantity of finished goods that you expect to produce).';
            OptionCaption = 'Actual Output,Expected Output';
            OptionMembers = "Actual Output","Expected Output";
        }
        field(210; "Finish Order without Output"; Boolean)
        {
            Caption = 'Allow Finishing Prod. Order with no Output';

            trigger OnValidate()
            begin
                CheckAndConfirmFinishOrderWithoutOutput();
            end;
        }
        field(250; "Inc. Non. Inv. Cost To Prod"; Boolean)
        {
            Caption = 'Include Non-Inventory Items to Produced Items';
            ToolTip = 'Specifies whether to include the cost of non-inventory items in the cost of produced items.';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                FeatureTelemetry.LogUptake('0000OMR', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
                if (Rec."Inc. Non. Inv. Cost To Prod") and (not xRec."Inc. Non. Inv. Cost To Prod") then
                    FeatureTelemetry.LogUsage('0000OMS', GetFeatureTelemetryName(), StrSubstNo(FieldValueIsChangedToLbl, Rec.FieldCaption("Inc. Non. Inv. Cost To Prod"), Rec."Inc. Non. Inv. Cost To Prod"));
            end;
        }
        field(260; "Load SKU Cost on Manufacturing"; Boolean)
        {
            Caption = 'Load SKU Cost on Manufacturing';
            ToolTip = 'Specifies if you want to load SKU Cost in the item at the time of manufacturing.';

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                FeatureTelemetry.LogUptake('0000OMP', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);
                if (Rec."Load SKU Cost on Manufacturing") and (not xRec."Load SKU Cost on Manufacturing") then
                    FeatureTelemetry.LogUsage('0000OMQ', GetFeatureTelemetryName(), StrSubstNo(FieldValueIsChangedToLbl, Rec.FieldCaption("Load SKU Cost on Manufacturing"), Rec."Load SKU Cost on Manufacturing"));
            end;
        }
        field(270; "Manual Scheduling"; Boolean)
        {
            Caption = 'Manual Scheduling';
            ToolTip = 'Specifies that the End/Due Dates on the production have been scheduled manually.';
        }
        field(271; "Safety Lead Time for Man. Sch."; DateFormula)
        {
            Caption = 'Safety Lead Time for Manual Scheduling';
            ToolTip = 'Specifies the time that will be added to the End date to calculate the Due Date when the production order is manually scheduled.';
        }
        field(280; "Default Gen. Bus. Post. Group"; Code[20])
        {
            Caption = 'Default General Business Posting Group';
            ToolTip = 'Specifies the default general business posting group for production orders.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(300; "Default Flushing Method"; Enum "Flushing Method")
        {
            Caption = 'Default Flushing Method';
            InitValue = "Pick + Manual";
            ToolTip = 'Specifies default flushing method assigned to new items. A different flushing method on item cards will override this default.';
        }
        field(5500; "Preset Output Quantity"; Option)
        {
            Caption = 'Preset Output Quantity';
            OptionCaption = 'Expected Quantity,Zero on All Operations,Zero on Last Operation';
            OptionMembers = "Expected Quantity","Zero on All Operations","Zero on Last Operation";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordHasBeenRead: Boolean;
        FinishOrderWithoutOutputQst: Label 'You will not be able to disable %1 once you have enabled it.\\Do you want to continue?', Comment = '%1 = Field Caption';
        NotAllowedDisableFinishOrderWithoutOutputErr: Label 'You are not allowed to disable %1 once you have enabled it.', Comment = '%1 = Field Caption';
        ManufacturingSetupFeatureTelemetryNameLbl: Label 'Manufacturing Setup', Locked = true;
        FieldValueIsChangedToLbl: Label '%1 is changed to %2.', Comment = '%1 = Field Caption , %2 = Field Value';

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    local procedure CheckAndConfirmFinishOrderWithoutOutput()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if (xRec."Finish Order without Output") and (not Rec."Finish Order without Output") then
            Error(NotAllowedDisableFinishOrderWithoutOutputErr, Rec.FieldCaption("Finish Order without Output"));

        if not ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(FinishOrderWithoutOutputQst, Rec.FieldCaption("Finish Order without Output")),
            false)
        then
            Error('');
    end;

    local procedure GetFeatureTelemetryName(): Text
    begin
        exit(ManufacturingSetupFeatureTelemetryNameLbl);
    end;

#if not CLEAN26
#pragma warning disable AS0072
    [Obsolete('Feature ''Manual Flushing Method without requiring pick'' will be enabled by default in version 29.0.', '26.0')]
    procedure IsFeatureKeyFlushingMethodManualWithoutPickEnabled(): Boolean
    var
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
    begin
        exit(FeatureKeyManagement.IsManufacturingFlushingMethodActivateManualWithoutPickEnabled());
    end;
#pragma warning restore AS0072
#endif
}
