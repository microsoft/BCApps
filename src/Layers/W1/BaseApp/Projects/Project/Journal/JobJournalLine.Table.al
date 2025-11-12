// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using System.Utilities;

table 210 "Job Journal Line"
{
    Caption = 'Project Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Job Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;

            trigger OnValidate()
            var
                JobSetup: Record "Jobs Setup";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobNo(Rec, Cust, DimMgt, IsHandled);
                if IsHandled then
                    exit;

                if "Job No." = '' then begin
                    Validate("Currency Code", '');
                    Validate("Job Task No.", '');
                    CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
                    exit;
                end;

                GetJob();
                Job.TestBlocked();
                IsHandled := false;
                OnValidateJobNoOnBeforeCheckJob(Rec, xRec, Cust, IsHandled);
                if not IsHandled then begin
                    Job.TestField("Bill-to Customer No.");
                    Cust.Get(Job."Bill-to Customer No.");
                    Validate("Job Task No.", '');
                end;
                "Customer Price Group" := Job."Customer Price Group";
                Validate("Currency Code", Job."Currency Code");
                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
                SetCountryRegionCodeFromJob(Job);
                "Price Calculation Method" := Job.GetPriceCalculationMethod();
                "Cost Calculation Method" := Job.GetCostCalculationMethod();
                JobSetup.Get();
                if JobSetup."Document No. Is Job No." and ("Document No." = '') then
                    Validate("Document No.", Rec."Job No.");
            end;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                CheckPostingDateNotEmpty();
                Validate("Document Date", "Posting Date");
                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor();
                    UpdateAllAmounts();
                end
            end;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(6; Type; Enum "Job Journal Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                Validate("No.", '');
                if Type = Type::Item then
                    CheckDirectedPutawayandPickIsFalse(Rec.FieldNo(Type));
            end;
        }
        field(8; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const(Item)) Item where(Blocked = const(false))
            else
            if (Type = const("G/L Account")) "G/L Account";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("No." = '') or ("No." <> xRec."No.") then begin
                    Description := '';
                    "Unit of Measure Code" := '';
                    "Qty. per Unit of Measure" := 1;
                    "Variant Code" := '';
                    "Work Type Code" := '';
                    DeleteAmounts();
                    "Cost Factor" := 0;
                    "Applies-to Entry" := 0;
                    "Applies-from Entry" := 0;
                    CheckedAvailability := false;
                    "Job Planning Line No." := 0;
                    if Type = Type::Item then begin
                        "Bin Code" := '';
                        if ("No." <> '') and ("Location Code" <> '') then begin
                            InitLocation();
                            GetLocation("Location Code");
                            GetItem();
                            if IsDefaultBin() and Item.IsInventoriableType() and ("Bin Code" = '') then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                        end;
                    end;
                    if "No." = '' then begin
                        UpdateDimensions();
                        exit;
                    end;
                end;

                case Type of
                    Type::Resource:
                        CopyFromResource();
                    Type::Item:
                        CopyFromItem();
                    Type::"G/L Account":
                        CopyFromGLAccount();
                end;

                IsHandled := false;
                OnValidateNoOnBeforeValidateQuantity(Rec, IsHandled);
                if not IsHandled then
                    Validate(Quantity);
                UpdateDimensions();
            end;
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                UpdateAllAmounts();

                WhseValidateSourceLine.JobJnlLineVerifyChangeForWhsePick(Rec, xRec);

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");

                CheckItemAvailable();
                if Type = Type::Item then
                    if Item."Item Tracking Code" <> '' then
                        ReserveJobJnlLine.VerifyQuantity(Rec, xRec);
            end;
        }
        field(12; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';
            MinValue = 0;
        }
        field(13; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if (Type = Type::Item) and
                   Item.Get("No.") and
                   (Item."Costing Method" = Item."Costing Method"::Standard)
                then
                    UpdateAllAmounts()
                else begin
                    InitRoundingPrecisions();
                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                    OnValidateUnitCostLCYOnAfterConvertAmountToFCY(Rec);
                    UpdateAllAmounts();
                end;
            end;
        }
        field(14; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(15; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions();
                "Unit Price" := ConvertAmountToFCY("Unit Price (LCY)", UnitAmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(16; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(17; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Resource Group No."));
            end;
        }
        field(18; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            var
                Resource: Record Resource;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitofMeasureCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetGLSetup();
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                            OnAfterAssignItemUoM(Rec, Item);
                        end;
                    Type::Resource:
                        begin
                            if CurrFieldNo <> FieldNo("Work Type Code") then
                                if "Work Type Code" <> '' then begin
                                    WorkType.Get("Work Type Code");
                                    if WorkType."Unit of Measure Code" <> '' then
                                        TestUnitOfMeasureCode(WorkType);
                                end else
                                    TestField("Work Type Code", '');
                            if "Unit of Measure Code" = '' then begin
                                Resource.Get("No.");
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                            end;
                            ResUnitofMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                            "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                            OnAfterAssignResourceUoM(Rec, Res);
                        end;
                    Type::"G/L Account":
                        begin
                            "Qty. per Unit of Measure" := 1;
                            OnAfterAssignGLAccountUoM(Rec);
                        end;
                end;
                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeOnBeforeValidateQuantity(Rec, IsHandled);
                if not IsHandled then
                    Validate(Quantity);
            end;
        }
        field(19; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(20; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(21; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                "Bin Code" := '';
                OnValidateLocationCodeOnBeforeGetLocation(Rec);
                CheckDirectedPutawayandPickIsFalse(Rec.FieldNo("Location Code"));
                Validate(Quantity);
                if (Type = Type::Item) and ("Location Code" <> xRec."Location Code") then
                    if ("Location Code" <> '') and ("No." <> '') then begin
                        GetItem();
                        if IsDefaultBin() and Item.IsInventoriableType() then
                            if not FindBin() then
                                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                    end;
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
                UpdateDimensions();
            end;
        }
        field(22; Chargeable; Boolean)
        {
            Caption = 'Chargeable';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateChargeable();
            end;
        }
        field(30; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group";
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(33; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                IsHandled: Boolean;
                IsLineDiscountHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(Rec, xRec, IsLineDiscountHandled, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::Resource);
                if not IsLineDiscountHandled then
                    Validate("Line Discount %", 0);
                if ("Work Type Code" = '') and (xRec."Work Type Code" <> '') then begin
                    Res.Get("No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure";
                    Validate("Unit of Measure Code");
                end;
                if WorkType.Get("Work Type Code") then
                    if WorkType."Unit of Measure Code" <> '' then begin
                        "Unit of Measure Code" := WorkType."Unit of Measure Code";
                        if ResUnitofMeasure.Get("No.", "Unit of Measure Code") then
                            "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";
                    end else begin
                        Res.Get("No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                        Validate("Unit of Measure Code");
                    end;
                OnBeforeValidateWorkTypeCodeQty(Rec, xRec, Res, WorkType);
                Validate(Quantity);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if (Type = Type::Item) and ("No." <> '') then
                    UpdateAllAmounts();
            end;
        }
        field(37; "Applies-to Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Applies-to Entry';

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-to Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                InitRoundingPrecisions();
                TestField(Type, Type::Item);
                if "Applies-to Entry" <> 0 then begin
                    ItemLedgEntry.Get("Applies-to Entry");
                    TestField(Quantity);
                    if Quantity < 0 then
                        FieldError(Quantity, Text002);
                    ItemLedgEntry.TestField(Open, true);
                    ItemLedgEntry.TestField(Positive, true);
                    "Location Code" := ItemLedgEntry."Location Code";
                    "Variant Code" := ItemLedgEntry."Variant Code";
                    GetItem();
                    if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                        "Unit Cost" := ConvertAmountToFCY(CalcUnitCost(ItemLedgEntry), UnitAmountRoundingPrecisionFCY);
                        UpdateAllAmounts();
                    end;
                end;
            end;
        }
        field(40; "Shpt. Method Code"; Code[10])
        {
            Caption = 'Shpt. Method Code';
            TableRelation = "Shipment Method";
        }
        field(61; "Entry Type"; Enum "Job Journal Line Entry Type")
        {
            Caption = 'Entry Type';
            Editable = false;
        }
        field(62; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(73; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(74; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(75; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(76; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(77; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(79; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(80; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(81; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(82; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(83; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(86; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(87; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(88; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(89; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(90; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(91; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                TestField(Type, Type::Item);
                SelectItemEntry(FieldNo("Serial No."));
            end;
        }
        field(92; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(93; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(94; "Source Currency Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Total Cost';
            Editable = false;
        }
        field(95; "Source Currency Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Total Price';
            Editable = false;
        }
        field(96; "Source Currency Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Source Currency Line Amount';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(902; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." where("Time Sheet No." = field("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date where("Time Sheet No." = field("Time Sheet No."),
                                                            "Time Sheet Line No." = field("Time Sheet Line No."));
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Job Task No." = '') or (("Job Task No." <> xRec."Job Task No.") and (xRec."Job Task No." <> '')) then begin
                    Validate("No.", '');
                    exit;
                end;

                TestField("Job No.");
                JobTask.Get("Job No.", "Job Task No.");
                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                OnValidateJobTaskNoOnAfterTestJobTaskType(Rec, xRec, JobTask);
                UpdateDimensions();
            end;
        }
        field(1001; "Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            Editable = false;
        }
        field(1002; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateAllAmounts();
            end;
        }
        field(1003; "Line Type"; Enum "Job Line Type")
        {
            Caption = 'Line Type';

            trigger OnValidate()
            begin
                if "Job Planning Line No." <> 0 then
                    Error(Text006, FieldCaption("Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1004; "Applies-from Entry"; Integer)
        {
            Caption = 'Applies-from Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Applies-from Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                InitRoundingPrecisions();
                TestField(Type, Type::Item);
                if "Applies-from Entry" <> 0 then begin
                    TestField(Quantity);
                    if Quantity > 0 then
                        FieldError(Quantity, Text003);
                    ItemLedgEntry.Get("Applies-from Entry");
                    ItemLedgEntry.TestField(Positive, false);
                    if Item."Costing Method" <> Item."Costing Method"::Standard then begin
                        "Unit Cost" := ConvertAmountToFCY(CalcUnitCostFrom(ItemLedgEntry), UnitAmountRoundingPrecisionFCY);
                        UpdateAllAmounts();
                    end;
                end;
            end;
        }
        field(1005; "Job Posting Only"; Boolean)
        {
            Caption = 'Project Posting Only';
        }
        field(1006; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateAllAmounts();
            end;
        }
        field(1007; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                UpdateAllAmounts();
            end;
        }
        field(1008; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyFactor();
            end;
        }
        field(1009; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                UpdateAllAmounts();
            end;
        }
        field(1010; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text001, FieldCaption("Currency Code")));
                UpdateAllAmounts();
            end;
        }
        field(1011; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                UpdateAllAmounts();
            end;
        }
        field(1012; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions();
                "Line Amount" := ConvertAmountToFCY("Line Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(1013; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                InitRoundingPrecisions();
                "Line Discount Amount" := ConvertAmountToFCY("Line Discount Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(1014; "Total Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            Editable = false;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            Caption = 'Cost Factor';
            Editable = false;
        }
        field(1016; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(1017; "Ledger Entry Type"; Enum "Job Ledger Entry Type")
        {
            Caption = 'Ledger Entry Type';
        }
        field(1018; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = if ("Ledger Entry Type" = const(Resource)) "Res. Ledger Entry"
            else
            if ("Ledger Entry Type" = const(Item)) "Item Ledger Entry"
            else
            if ("Ledger Entry Type" = const("G/L Account")) "G/L Entry";
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
                Resource: Record Resource;
                "Filter": Text;
            begin
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                JobPlanningLine.SetRange(Type, Type);
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);
                if Type = Type::Resource then begin
                    Filter := Resource.GetUnitOfMeasureFilter("No.", "Unit of Measure Code");
                    JobPlanningLine.SetFilter("Unit of Measure Code", Filter);
                end;

                if Page.RunModal(0, JobPlanningLine) = Action::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
            begin
                if "Job Planning Line No." <> 0 then begin
                    ValidateJobPlanningLineLink();
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");

                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    JobPlanningLine.TestField(Type, Type);
                    JobPlanningLine.TestField("No.", "No.");
                    JobPlanningLine.TestField("Usage Link", true);
                    JobPlanningLine.TestField("System-Created Entry", false);

                    "Line Type" := JobPlanningLine.ConvertToJobLineType();

                    if (JobPlanningLine."Location Code" <> '') and (CurrFieldNo = FieldNo("Job Planning Line No.")) then
                        "Location Code" := JobPlanningLine."Location Code";
                    if (JobPlanningLine."Bin Code" <> '') and (CurrFieldNo = FieldNo("Job Planning Line No.")) then
                        "Bin Code" := JobPlanningLine."Bin Code";

                    Validate("Remaining Qty.", CalcQtyFromBaseQty(JobPlanningLine."Remaining Qty. (Base)" - "Quantity (Base)"));

                    "Assemble to Order" := JobPlanningLine."Assemble to Order";

                    if Quantity > 0 then
                        WhseValidateSourceLine.JobJnlLineVerifyChangeForWhsePick(Rec, xRec);
                end else
                    Validate("Remaining Qty.", 0);
            end;
        }
        field(1030; "Remaining Qty."; Decimal)
        {
            Caption = 'Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text004, FieldCaption("Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Remaining Qty." < 0 then
                            "Remaining Qty." := 0;
                    end else
                        if "Remaining Qty." > 0 then
                            "Remaining Qty." := 0;

                    "Remaining Qty. (Base)" := CalcBaseQtyForJobPlanningLine("Remaining Qty.", FieldCaption("Remaining Qty."), FieldCaption("Remaining Qty. (Base)"), JobPlanningLine);
                end else
                    "Remaining Qty. (Base)" := CalcBaseQty("Remaining Qty.", FieldCaption("Remaining Qty."), FieldCaption("Remaining Qty. (Base)"));

                CheckItemAvailable();
            end;
        }
        field(1031; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';

            trigger OnValidate()
            begin
                Validate("Remaining Qty.", CalcQtyFromBaseQty("Remaining Qty. (Base)"));
            end;
        }
        field(1081; "Qty. to Transfer to Invoice"; Decimal)
        {
            Caption = 'Qty. to Transfer to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVariantCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Rec."Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                        GetItemTranslation();
                    end;
                    exit;
                end;

                TestField(Type, Type::Item);
                ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                ItemVariant.Get("No.", "Variant Code");
                ItemVariant.TestField(Blocked, false);
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";

                IsHandled := false;
                OnValidateVariantCodeOnBeforeValidateQuantity(Rec, xRec, IsHandled);
                if not IsHandled then
                    Validate(Quantity);
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Code';

            trigger OnLookup()
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);
                BinContentLookUp();
            end;

            trigger OnValidate()
            begin
                TestField("Location Code");
                if "Bin Code" <> '' then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                end;
                TestField(Type, Type::Item);
                GetItem();
                Item.TestField(Type, Item.Type::Inventory);
                CheckItemAvailable();
                FindBinContent();
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5410; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate(Quantity, CalcQtyFromBaseQty("Quantity (Base)"));
            end;
        }
        field(5468; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Journal Template Name"),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Source Type" = const(210),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Entry Type"),
#pragma warning restore
                                                                           "Source Batch Name" = field("Journal Batch Name"),
                                                                           "Source Prod. Order Line" = const(0),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Template Name", "Journal Batch Name", Type, "No.", "Unit of Measure Code", "Work Type Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; Type, "No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, Quantity, "Document No.", "Document Date")
        { }
    }

    trigger OnDelete()
    begin
        if Type = Type::Item then
            ReserveJobJnlLine.DeleteLine(Rec);
    end;

    trigger OnInsert()
    begin
        LockTable();

        if ("Journal Template Name" <> '') then begin
            JobJnlTemplate.Get("Journal Template Name");
            JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        end;

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        if (Type = Type::Item) and (xRec.Type = Type::Item) then
            ReserveJobJnlLine.VerifyChange(Rec, xRec)
        else
            if (Type <> Type::Item) and (xRec.Type = Type::Item) then
                ReserveJobJnlLine.DeleteLine(xRec);
    end;

    trigger OnRename()
    begin
        ReserveJobJnlLine.RenameLine(Rec, xRec);
    end;

    var
        Location: Record Location;
        Item: Record Item;
        Res: Record Resource;
        Cust: Record Customer;
        ItemJnlLine: Record "Item Journal Line";
        GLAcc: Record "G/L Account";
        Job: Record Job;
        WorkType: Record "Work Type";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlLine: Record "Job Journal Line";
        ResUnitofMeasure: Record "Resource Unit of Measure";
        ItemTranslation: Record "Item Translation";
        CurrExchRate: Record "Currency Exchange Rate";
        SKU: Record "Stockkeeping Unit";
        GLSetup: Record "General Ledger Setup";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        ReserveJobJnlLine: Codeunit "Job Jnl. Line-Reserve";
        WMSManagement: Codeunit "WMS Management";
        DontCheckStandardCost: Boolean;
        HasGotGLSetup: Boolean;
        CurrencyDate: Date;
        CheckedAvailability: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot change %1 when %2 is %3.';
        Text001: Label 'cannot be specified without %1';
#pragma warning restore AA0470
        Text002: Label 'must be positive';
        Text003: Label 'must be negative';
#pragma warning disable AA0470
        Text004: Label '%1 is only editable when a %2 is defined.';
        Text006: Label '%1 cannot be changed when %2 is set.';
        Text007: Label '%1 %2 is already linked to %3 %4. Hence %5 cannot be calculated correctly. Posting the line may update the linked %3 unexpectedly. Do you want to continue?', Comment = 'Project Journal Line project DEFAULT 30000 is already linked to Project Planning Line  DEERFIELD, 8 WP 1120 10000. Hence Remaining Qty. cannot be calculated correctly. Posting the line may update the linked %3 unexpectedly. Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        RenumberDocNoQst: Label 'If you have many documents it can take time to sort them, and %1 might perform slowly during the process. In those cases we suggest that you sort them during non-working hours. Do you want to continue?', Comment = '%1= Business Central';

    protected var
        JobJnlTemplate: Record "Job Journal Template";
        DimMgt: Codeunit DimensionManagement;
        UnitAmountRoundingPrecision: Decimal;
        AmountRoundingPrecision: Decimal;
        UnitAmountRoundingPrecisionFCY: Decimal;
        AmountRoundingPrecisionFCY: Decimal;

    local procedure CalcQtyFromBaseQty(BaseQty: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(BaseQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    local procedure CopyFromResource()
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromResource(Rec, Resource, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            Resource.Get("No.");
            CheckResource(Resource);
            OnCopyFromResourceOnAfterCheckResource(Rec, Resource, CurrFieldNo);

            Description := Resource.Name;
            "Description 2" := Resource."Name 2";
            "Resource Group No." := Resource."Resource Group No.";
            "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
            Validate("Unit of Measure Code", Resource."Base Unit of Measure");
        end;

        OnAfterAssignResourceValues(Rec, Resource, CurrFieldNo);
    end;

    local procedure CheckResource(Resource: Record Resource)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckResource(Rec, Resource, IsHandled);
        if IsHandled then
            exit;

        Resource.CheckResourcePrivacyBlocked(false);
        Resource.TestField(Blocked, false);
        if "Time Sheet No." = '' then
            Resource.TestField("Use Time Sheet", false);
    end;

    local procedure CheckPostingDateNotEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDateNotEmpty(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsTemporary() then
            TestField("Posting Date");
    end;

    local procedure CheckDirectedPutawayandPickIsFalse(CallingFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        GetLocation(Rec."Location Code");
        IsHandled := false;
        OnCheckDirectedPutawayandPickIsFalseOnBeforeTestField(Location, CallingFieldNo, IsHandled);
        if not IsHandled then
            if CurrFieldNo <> 0 then
                Location.TestField("Directed Put-away and Pick", false);
    end;

    local procedure CopyFromItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, Item, IsHandled);
        if not IsHandled then begin
            GetItem();
            Item.TestField(Blocked, false);
            OnCopyFromItemOnAfterCheckItem(Rec, Item);
            Description := Item.Description;
            "Description 2" := Item."Description 2";
            GetJob();
            if Job."Language Code" <> '' then
                GetItemTranslation();
            "Posting Group" := Item."Inventory Posting Group";
            "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
            OnCopyFromItemOnBeforeValidateUoMCode(Rec, Item, IsHandled);
            if not IsHandled then
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
        end;

        OnAfterAssignItemValues(Rec, Item);
    end;

    local procedure CopyFromGLAccount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromGLAccount(Rec, GLAcc, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            GLAcc.Get("No.");
            GLAcc.CheckGLAcc();
            CheckDirectPosting(GLAcc);
            Description := GLAcc.Name;
            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "Unit of Measure Code" := '';
            "Direct Unit Cost (LCY)" := 0;
            "Unit Cost (LCY)" := 0;
            "Unit Price" := 0;
        end;

        OnAfterAssignGLAccountValues(Rec, GLAcc);
    end;

    local procedure CheckDirectPosting(var GLAccount: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDirectPosting(Rec, GLAccount, IsHandled);
        if IsHandled then
            exit;

        GLAccount.TestField("Direct Posting", true);
    end;

    procedure CheckItemAvailable()
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        OnBeforeCheckItemAvailable(Rec, ItemJnlLine, CheckedAvailability);

        if (CurrFieldNo <> 0) and (Type = Type::Item) and (Quantity > 0) and not CheckedAvailability then begin
            ItemJnlLine."Item No." := "No.";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            ItemJnlLine."Location Code" := "Location Code";
            ItemJnlLine."Variant Code" := "Variant Code";
            ItemJnlLine."Bin Code" := "Bin Code";
            ItemJnlLine."Unit of Measure Code" := "Unit of Measure Code";
            ItemJnlLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";

            IsHandled := false;
            OnCheckItemAvailableOnBeforeAssignQuantity(Rec, ItemJnlLine, IsHandled);
            if not IsHandled then
                if "Job Planning Line No." = 0 then
                    ItemJnlLine.Quantity := Quantity
                else begin
                    JobPlanningLine.SetLoadFields("Remaining Qty.");
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine."Remaining Qty." < (Quantity + "Remaining Qty.") then
                        ItemJnlLine.Quantity := (Quantity + "Remaining Qty.") - JobPlanningLine."Remaining Qty."
                    else
                        exit;
                end;
            if ItemCheckAvail.ItemJnlCheckLine(ItemJnlLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();
            CheckedAvailability := true;
        end;
    end;

    procedure EmptyLine(): Boolean
    var
        LineIsEmpty: Boolean;
    begin
        LineIsEmpty := ("Job No." = '') and ("No." = '') and (Quantity = 0);
        OnBeforeEmptyLine(Rec, LineIsEmpty);
        exit(LineIsEmpty);
    end;

    procedure SetUpNewLine(LastJobJnlLine: Record "Job Journal Line")
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUpNewLine(Rec, xRec, LastJobJnlLine, IsHandled);
        if IsHandled then
            exit;

        JobsSetup.Get();
        JobJnlTemplate.Get("Journal Template Name");
        JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        JobJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if JobJnlLine.FindFirst() then begin
            "Posting Date" := LastJobJnlLine."Posting Date";
            "Document Date" := LastJobJnlLine."Posting Date";
            if JobsSetup."Document No. Is Job No." and (LastJobJnlLine."Document No." = '') then
                "Document No." := Rec."Job No."
            else
                "Document No." := LastJobJnlLine."Document No.";
            Type := LastJobJnlLine.Type;
            Validate("Line Type", LastJobJnlLine."Line Type");
        end else begin
            OnSetUpNewLineOnNewLine(JobJnlLine, JobJnlTemplate, JobJnlBatch);
            "Posting Date" := WorkDate();
            "Document Date" := WorkDate();
            if JobsSetup."Document No. Is Job No." then begin
                if "Document No." = '' then
                    "Document No." := Rec."Job No.";
            end else
                if JobJnlBatch."No. Series" <> '' then
                    "Document No." := NoSeries.PeekNextNo(JobJnlBatch."No. Series", "Posting Date");
        end;
        "Recurring Method" := LastJobJnlLine."Recurring Method";
        "Entry Type" := "Entry Type"::Usage;
        "Source Code" := JobJnlTemplate."Source Code";
        "Reason Code" := JobJnlBatch."Reason Code";
        "Posting No. Series" := JobJnlBatch."Posting No. Series";
        "Price Calculation Method" := Job.GetPriceCalculationMethod();
        "Cost Calculation Method" := Job.GetCostCalculationMethod();

        OnAfterSetUpNewLine(Rec, LastJobJnlLine, JobJnlTemplate, JobJnlBatch);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, OldDimSetID, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(Rec, Location, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetJob()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJob(Rec, Job, IsHandled);
        if IsHandled then
            exit;

        TestField("Job No.");
        if "Job No." <> Job."No." then
            Job.Get("Job No.");
    end;

    procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            if "Posting Date" = 0D then
                CurrencyDate := WorkDate()
            else
                CurrencyDate := "Posting Date";
            OnUpdateCurrencyFactorOnBeforeGetExchangeRate(Rec, CurrExchRate);
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
    end;

    local procedure GetItem()
    begin
        TestField("No.");
        if "No." <> Item."No." then
            Item.Get("No.");
    end;

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);

        if SKU.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    procedure IsInbound(): Boolean
    begin
        if "Entry Type" in ["Entry Type"::Usage, "Entry Type"::Sale] then
            exit("Quantity (Base)" < 0);

        exit(false);
    end;

    procedure OpenItemTrackingLines(IsReclass: Boolean)
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReserveJobJnlLine.CallItemTracking(Rec, IsReclass);
    end;

    procedure InitRoundingPrecisions()
    var
        Currency: Record Currency;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitRoundingPrecisions(Rec, AmountRoundingPrecision, UnitAmountRoundingPrecision, AmountRoundingPrecisionFCY, UnitAmountRoundingPrecisionFCY, IsHandled);
        if IsHandled then
            exit;

        if (AmountRoundingPrecision = 0) or
           (UnitAmountRoundingPrecision = 0) or
           (AmountRoundingPrecisionFCY = 0) or
           (UnitAmountRoundingPrecisionFCY = 0)
        then begin
            Clear(Currency);
            Currency.InitRoundingPrecision();
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";

            if "Currency Code" <> '' then begin
                Currency.Get("Currency Code");
                Currency.TestField("Amount Rounding Precision");
                Currency.TestField("Unit-Amount Rounding Precision");
            end;

            AmountRoundingPrecisionFCY := Currency."Amount Rounding Precision";
            UnitAmountRoundingPrecisionFCY := Currency."Unit-Amount Rounding Precision";
        end;
    end;

    procedure DontCheckStdCost()
    begin
        DontCheckStandardCost := true;
    end;

    local procedure CalcUnitCost(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        UnitCost :=
          (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgerEntry.Quantity;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    local procedure CalcUnitCostFrom(ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(
          (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)") /
          ItemLedgerEntry.Quantity * "Qty. per Unit of Measure");
    end;

    local procedure SetCountryRegionCodeFromJob(Job2: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCountryRegionCodeFromJob(Rec, Job2, IsHandled);
        if IsHandled then
            exit;

        Validate(Rec."Country/Region Code", Job."Bill-to Country/Region Code");
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobJournalLine2: Record "Job Journal Line";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code");
        ItemLedgerEntry.SetRange("Item No.", "No.");
        ItemLedgerEntry.SetRange(Correction, false);

        if "Location Code" <> '' then
            ItemLedgerEntry.SetRange("Location Code", "Location Code");

        if CurrentFieldNo = FieldNo("Applies-to Entry") then begin
            ItemLedgerEntry.SetRange(Positive, true);
            ItemLedgerEntry.SetRange(Open, true);
        end else
            ItemLedgerEntry.SetRange(Positive, false);
        OnSelectItemEntryOnAfterSetItemLedgerEntryFilters(ItemLedgerEntry, CurrentFieldNo, Rec);

        if Page.RunModal(Page::"Item Ledger Entries", ItemLedgerEntry) = Action::LookupOK then begin
            JobJournalLine2 := Rec;
            if CurrentFieldNo = FieldNo("Applies-to Entry") then
                JobJournalLine2.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.")
            else
                JobJournalLine2.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
            Rec := JobJournalLine2;
        end;
    end;

    procedure DeleteAmounts()
    begin
        Quantity := 0;
        "Quantity (Base)" := 0;
        "Direct Unit Cost (LCY)" := 0;
        "Unit Cost (LCY)" := 0;
        "Unit Cost" := 0;
        "Total Cost (LCY)" := 0;
        "Total Cost" := 0;
        "Unit Price (LCY)" := 0;
        "Unit Price" := 0;
        "Total Price (LCY)" := 0;
        "Total Price" := 0;
        "Line Amount (LCY)" := 0;
        "Line Amount" := 0;
        "Line Discount %" := 0;
        "Line Discount Amount (LCY)" := 0;
        "Line Discount Amount" := 0;
        "Remaining Qty." := 0;
        "Remaining Qty. (Base)" := 0;

        OnAfterDeleteAmounts(Rec);
    end;

    procedure SetCurrencyFactor(Factor: Decimal)
    begin
        "Currency Factor" := Factor;
    end;

    procedure GetItemTranslation()
    begin
        GetJob();
        if ItemTranslation.Get("No.", "Variant Code", Job."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
        end;
    end;

    local procedure GetGLSetup()
    begin
        if HasGotGLSetup then
            exit;
        GLSetup.Get();
        HasGotGLSetup := true;
    end;

    procedure SetReservationEntry(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetSource(Database::"Job Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", "Journal Batch Name", 0);
        ReservationEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservationEntry."Expected Receipt Date" := "Posting Date";
        ReservationEntry."Shipment Date" := "Posting Date";
    end;

    procedure SetReservationFilters(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetSourceFilter(Database::"Job Journal Line", "Entry Type".AsInteger(), "Journal Template Name", "Line No.", false);
        ReservationEntry.SetSourceFilter("Journal Batch Name", 0);

        OnAfterSetReservationFilters(ReservationEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        exit(not ReservationEntry.IsEmpty());
    end;

    procedure UpdateAllAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;
        InitRoundingPrecisions();

        UpdateUnitCost();
        FindPriceAndDiscount(CurrFieldNo);
        UpdateTotalCost();
        HandleCostFactor();
        UpdateUnitPrice();
        UpdateTotalPrice();
        UpdateAmountsAndDiscounts();

        OnAfterUpdateAllAmounts(Rec, xRec);
    end;

    procedure UpdateUnitCost()
    var
        RetrievedCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if (Type = Type::Item) and Item.Get("No.") then begin
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                if not DontCheckStandardCost then
                    // Prevent manual change of unit cost on items with standard cost
                    if (("Unit Cost" <> xRec."Unit Cost") or ("Unit Cost (LCY)" <> xRec."Unit Cost (LCY)")) and
                       (("No." = xRec."No.") and ("Location Code" = xRec."Location Code") and
                        ("Variant Code" = xRec."Variant Code") and ("Unit of Measure Code" = xRec."Unit of Measure Code"))
                    then
                        Error(
                          Text000,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                if RetrieveCostPrice(CurrFieldNo) then begin
                    if GetSKU() then
                        "Unit Cost (LCY)" := Round(SKU."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost (LCY)" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);
                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                end else
                    if "Unit Cost" <> xRec."Unit Cost" then
                        "Unit Cost (LCY)" := ConvertAmountToLCY("Unit Cost", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
            end else
                if RetrieveCostPrice(CurrFieldNo) then begin
                    if GetSKU() then
                        RetrievedCost := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        RetrievedCost := Item."Unit Cost" * "Qty. per Unit of Measure";
                    "Unit Cost" := ConvertAmountToFCY(RetrievedCost, UnitAmountRoundingPrecisionFCY);
                    "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                end else
                    "Unit Cost (LCY)" := ConvertAmountToLCY("Unit Cost", UnitAmountRoundingPrecision);
        end else
            if (Type = Type::Resource) and ("Posting Date" <> xRec."Posting Date") and ("Currency Code" <> '') then
                "Unit Cost (LCY)" := "Unit Cost (LCY)"
            else
                "Unit Cost (LCY)" := ConvertAmountToLCY("Unit Cost", UnitAmountRoundingPrecision);

        OnAfterUpdateUnitCost(Rec, UnitAmountRoundingPrecision, CurrFieldNo);
    end;

    local procedure ValidateChargeable()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateChargeable(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if Chargeable <> xRec.Chargeable then
            if not Chargeable then
                Validate("Unit Price", 0)
            else
                Validate("No.");
    end;

    local procedure TestUnitOfMeasureCode(LocalWorkType: Record "Work Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestUnitOfMeasureCode(Rec, LocalWorkType, IsHandled);
        if IsHandled then
            exit;

        TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    local procedure RetrieveCostPrice(CalledByFieldNo: Integer) Result: Boolean
    var
        ShouldRetrieveCostPrice: Boolean;
    begin
        Result := true;
        OnBeforeRetrieveCostPrice(Rec, xRec, ShouldRetrieveCostPrice, Result, CalledByFieldNo);
        if ShouldRetrieveCostPrice then
            exit(Result);

        if CalledByFieldNo <> 0 then
            case Type of
                Type::Item:
                    if not (CalledByFieldNo in
                            [FieldNo("No."), FieldNo(Quantity), FieldNo("Location Code"),
                            FieldNo("Variant Code"), FieldNo("Unit of Measure Code")])
                    then
                        exit(false);
                Type::Resource:
                    if not (CalledByFieldNo in
                         [FieldNo("No."), FieldNo(Quantity), FieldNo("Work Type Code"), FieldNo("Unit of Measure Code"), FieldNo("Posting Date")])
                    then
                        exit(false);
                Type::"G/L Account":
                    if not (CalledByFieldNo in [FieldNo("No."), FieldNo(Quantity)]) then
                        exit(false);
            end;

        case Type of
            Type::Item:
                if ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                   ("Location Code" <> xRec."Location Code") or
                   ("Variant Code" <> xRec."Variant Code") or
                   (Quantity <> xRec.Quantity) or
                   ("Unit of Measure Code" <> xRec."Unit of Measure Code") and
                   (("Applies-to Entry" = 0) and ("Applies-from Entry" = 0))
                then
                    exit(true);
            Type::Resource:
                if ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                   ("Work Type Code" <> xRec."Work Type Code") or
                   ("Unit of Measure Code" <> xRec."Unit of Measure Code") or
                   (("Posting Date" <> xRec."Posting Date") and ("Currency Code" <> ''))
                then
                    exit(true);
            Type::"G/L Account":
                if ("No." <> xRec."No.") or IsQuantityChangedForPrice() then
                    exit(true);
            else
                exit(false);
        end;
        exit(false);
    end;

    local procedure IsQuantityChangedForPrice(): Boolean;
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if Quantity = xRec.Quantity then
            exit(false);
        exit(PriceCalculationMgt.IsExtendedPriceCalculationEnabled());
    end;

    procedure UpdateTotalCost()
    begin
        "Total Cost" := Round("Unit Cost" * Quantity, AmountRoundingPrecisionFCY);
        "Total Cost (LCY)" := ConvertAmountToLCY("Total Cost", AmountRoundingPrecision);
        OnAfterUpdateTotalCost(Rec, AmountRoundingPrecision, AmountRoundingPrecisionFCY);
    end;

    local procedure ConvertAmountToFCY(AmountLCY: Decimal; Precision: Decimal) AmountFCY: Decimal;
    begin
        AmountFCY :=
            Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                    "Posting Date", "Currency Code", AmountLCY, "Currency Factor"),
                Precision);
    end;

    local procedure ConvertAmountToLCY(AmountFCY: Decimal; Precision: Decimal) AmountLCY: Decimal;
    begin
        AmountLCY :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    "Posting Date", "Currency Code", AmountFCY, "Currency Factor"),
                Precision);
    end;

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        JobJournalErrorsMgt: Codeunit "Job Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            JobJournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    local procedure FindPriceAndDiscount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPriceAndDiscount(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if RetrieveCostPrice(CalledByFieldNo) and ("No." <> '') then begin
            ApplyPrice(PriceType::Sale, CalledByFieldNo);
            ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            if Type = Type::Resource then begin
                "Unit Cost (LCY)" := ConvertAmountToLCY("Unit Cost", UnitAmountRoundingPrecision);
                "Direct Unit Cost (LCY)" := ConvertAmountToLCY("Direct Unit Cost (LCY)", UnitAmountRoundingPrecision);
            end;
        end;
    end;

    procedure AfterResourceFindCost(var ResourceCost: Record "Resource Cost")
    begin
        OnAfterResourceFindCost(Rec, ResourceCost);
    end;

    procedure ApplyPrice(PriceType: enum "Price Type"; CalledByFieldNo: Integer)
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceCalculation: Interface "Price Calculation";
        Line: Variant;
    begin
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        if PriceType = PriceType::Sale then
            PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
    begin
        LineWithPrice := JobJournalLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    local procedure FindBinContent()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinContent(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
    end;

    local procedure BinContentLookUp()
    var
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBinContentLookUp(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code");
        if BinCode <> '' then
            Validate("Bin Code", BinCode);
    end;

    local procedure HandleCostFactor()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleCostFactor(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        if ("Cost Factor" <> 0) and
           ((("Unit Cost" <> xRec."Unit Cost") or ("Cost Factor" <> xRec."Cost Factor")) or
            ((Quantity <> xRec.Quantity) or ("Location Code" <> xRec."Location Code")))
        then
            "Unit Price" := Round("Unit Cost" * "Cost Factor", UnitAmountRoundingPrecisionFCY)
        else
            if (Item."Price/Profit Calculation" = Item."Price/Profit Calculation"::"Price=Cost+Profit") and
               (Item."Profit %" < 100) and
               ("Unit Cost" <> xRec."Unit Cost")
            then
                "Unit Price" := Round("Unit Cost" / (1 - Item."Profit %" / 100), UnitAmountRoundingPrecisionFCY);
    end;

    local procedure UpdateUnitPrice()
    begin
        "Unit Price (LCY)" := ConvertAmountToLCY("Unit Price", UnitAmountRoundingPrecision);
        OnAfterUpdateUnitPrice(Rec, xRec, AmountRoundingPrecision, AmountRoundingPrecisionFCY);
    end;

    local procedure UpdateTotalPrice()
    begin
        "Total Price" := Round(Quantity * "Unit Price", AmountRoundingPrecisionFCY);
        "Total Price (LCY)" := ConvertAmountToLCY("Total Price", AmountRoundingPrecision);
        OnAfterUpdateTotalPrice(Rec);
    end;

    local procedure UpdateAmountsAndDiscounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsAndDiscounts(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        // Patch for fixing Edit-in-Excel issues due to dependency on xRec. 
        if not GuiAllowed() then
            if xRec.Get(xRec.RecordId()) then;

        if "Total Price" <> 0 then begin
            if ("Line Amount" <> xRec."Line Amount") and ("Line Discount Amount" = xRec."Line Discount Amount") then begin
                "Line Amount" := Round("Line Amount", AmountRoundingPrecisionFCY);
                "Line Discount Amount" := "Total Price" - "Line Amount";
                "Line Amount (LCY)" := ConvertAmountToLCY("Line Amount", AmountRoundingPrecision);
                "Line Discount Amount (LCY)" := "Total Price (LCY)" - "Line Amount (LCY)";
                "Line Discount %" := Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
            end else
                if ("Line Discount Amount" <> xRec."Line Discount Amount") and ("Line Amount" = xRec."Line Amount") then begin
                    "Line Discount Amount" := Round("Line Discount Amount", AmountRoundingPrecisionFCY);
                    "Line Amount" := "Total Price" - "Line Discount Amount";
                    "Line Discount Amount (LCY)" := Round("Line Discount Amount (LCY)", AmountRoundingPrecision);
                    "Line Amount (LCY)" := "Total Price (LCY)" - "Line Discount Amount (LCY)";
                    "Line Discount %" := Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
                end else
                    if ("Line Discount Amount" <> xRec."Line Discount Amount") or ("Line Amount" <> xRec."Line Amount") or
                       ("Total Price" <> xRec."Total Price") or ("Line Discount %" <> xRec."Line Discount %")
                    then begin
                        "Line Discount Amount" := Round("Total Price" * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
                        "Line Amount" := "Total Price" - "Line Discount Amount";
                        "Line Discount Amount (LCY)" := Round("Total Price (LCY)" * "Line Discount %" / 100, AmountRoundingPrecision);
                        "Line Amount (LCY)" := "Total Price (LCY)" - "Line Discount Amount (LCY)";
                    end;
        end else begin
            "Line Amount" := 0;
            "Line Discount Amount" := 0;
            "Line Amount (LCY)" := 0;
            "Line Discount Amount (LCY)" := 0;
        end;

        OnAfterUpdateAmountsAndDiscounts(Rec);
    end;

    local procedure ValidateJobPlanningLineLink()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobJournalLine: Record "Job Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateJobPlanningLineLink(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        JobJournalLine.SetRange("Job No.", "Job No.");
        JobJournalLine.SetRange("Job Task No.", "Job Task No.");
        JobJournalLine.SetRange("Job Planning Line No.", "Job Planning Line No.");

        if JobJournalLine.FindFirst() then
            if ("Journal Template Name" <> JobJournalLine."Journal Template Name") or
               ("Journal Batch Name" <> JobJournalLine."Journal Batch Name") or
               ("Line No." <> JobJournalLine."Line No.")
            then begin
                JobPlanningLine.SetLoadFields("Job No.", "Job Task No.", "Line No.");
                JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                if not Confirm(Text007, false,
                     TableCaption,
                     StrSubstNo('%1, %2, %3', "Journal Template Name", "Journal Batch Name", "Line No."),
                     JobPlanningLine.TableCaption(),
                     StrSubstNo('%1, %2, %3', JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."),
                     FieldCaption("Remaining Qty."))
                then
                    Error('');
            end;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    procedure UpdateDimensions()
    var
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDimensions(Rec, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            CreateDimFromDefaultDim(0);
            if "Job Task No." <> '' then begin
                DimensionSetIDArr[1] := "Dimension Set ID";
                DimensionSetIDArr[2] :=
                DimMgt.CreateDimSetFromJobTaskDim("Job No.",
                    "Job Task No.", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
                DimMgt.CreateDimForJobJournalLineWithHigherPriorities(
                Rec, CurrFieldNo, DimensionSetIDArr[3], "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Source Code", Database::Job);
                "Dimension Set ID" :=
                DimMgt.GetCombinedDimensionSetID(
                    DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        end;

        OnAfterUpdateDimensions(Rec, DimensionSetIDArr);
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        JobJournalBatch: Record "Job Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                JobJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            JobJournalBatch.SetFilter(Name, BatchFilter);
            JobJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    procedure IsNonInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem();
        exit(Item.IsNonInventoriableType());
    end;

    procedure IsInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem();
        exit(Item.IsInventoriableType());
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::"Job Journal Line", "Entry Type".AsInteger(),
            "Journal Template Name", "Journal Batch Name", 0, "Line No."));
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        "Serial No." := JobPlanningLine."Serial No.";
        "Lot No." := JobPlanningLine."Lot No.";

        OnAfterCopyTrackingFromJobPlanningLine(rec, JobPlanningLine);
    end;

    local procedure IsDefaultBin() Result: Boolean
    begin
        Result := Location."Bin Mandatory" and not Location."Directed Put-away and Pick";
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if not DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("No."):
                TableValuePair.Add(DimMgt.TypeToTableID2(Rec.Type.AsInteger()), Rec."No.");
            FieldNo = Rec.FieldNo("Job No."):
                TableValuePair.Add(Database::Job, Rec."Job No.");
            FieldNo = Rec.FieldNo("Resource Group No."):
                TableValuePair.Add(Database::"Resource Group", Rec."Resource Group No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;

        OnAfterInitTableValuePair(Rec, TableValuePair, FieldNo);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID2(Rec.Type.AsInteger()), Rec."No.", FieldNo = Rec.FieldNo("No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Resource Group", Rec."Resource Group No.", FieldNo = Rec.FieldNo("Resource Group No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    local procedure InitLocation()
    var
        JobTask: Record "Job Task";
    begin
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") and (JobTask."Location Code" <> '') then
            Validate("Location Code", JobTask."Location Code");
    end;

    local procedure FindBin(): Boolean
    var
        JobTask: Record "Job Task";
    begin
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") and (JobTask."Bin Code" <> '') then begin
            if ("Location Code" <> '') and (JobTask."Location Code" <> "Location Code") then
                exit(false);
            if WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", JobTask."Bin Code") then begin
                "Bin Code" := JobTask."Bin Code";
                exit(true);
            end;
        end;
    end;

    /// <summary>
    /// Renumbers the document number of the current job journal line based on the number series specified in the 
    /// associated job journal batch.
    /// </summary>
    /// <remarks>
    /// An error will be raised if there is an active filter on the document number field.
    /// A commit is used during renumbering.
    /// </remarks>
    procedure RenumberDocumentNo()
    var
        JobJnlLine2: Record "Job Journal Line";
        NoSeries: Codeunit "No. Series";
        DocNo: Code[20];
        FirstDocNo: Code[20];
        FirstTempDocNo: Code[20];
        LastTempDocNo: Code[20];
    begin
        if SkipRenumberDocumentNo() then
            exit;

        JobJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        JobJnlBatch.TestField("No. Series");

        if GetFilter("Document No.") <> '' then
            Error(DocNoFilterErr);
        FirstDocNo := NoSeries.PeekNextNo(JobJnlBatch."No. Series", "Posting Date");
        FirstTempDocNo := GetTempRenumberDocumentNo();
        // step1 - renumber to non-existing document number
        DocNo := FirstTempDocNo;
        JobJnlLine2 := Rec;
        JobJnlLine2.Reset();
        RenumberDocNoOnLines(DocNo, JobJnlLine2);
        LastTempDocNo := DocNo;

        // step2 - renumber to real document number (within Filter)
        DocNo := FirstDocNo;
        JobJnlLine2.CopyFilters(Rec);
        JobJnlLine2 := Rec;
        RenumberDocNoOnLines(DocNo, JobJnlLine2);

        // step3 - renumber to real document number (outside filter)
        DocNo := IncStr(DocNo);
        JobJnlLine2.Reset();
        JobJnlLine2.SetRange("Document No.", FirstTempDocNo, LastTempDocNo);
        RenumberDocNoOnLines(DocNo, JobJnlLine2);

        if Get("Journal Template Name", "Journal Batch Name", "Line No.") then;
    end;

    local procedure RenumberDocNoOnLines(var DocNo: Code[20]; var JobJnlLine2: Record "Job Journal Line")
    var
        LastJobJnlLine: Record "Job Journal Line";
        JobJnlLine3: Record "Job Journal Line";
        NoSeries: Codeunit "No. Series";
        PrevDocNo: Code[20];
        FirstDocNo: Code[20];
        TempFirstDocNo: Code[20];
        First: Boolean;
        IsHandled: Boolean;
        PrevPostingDate: Date;
    begin
        IsHandled := false;
        OnBeforeRenumberDocNoOnLines(DocNo, JobJnlLine2, IsHandled);
        if IsHandled then
            exit;

        FirstDocNo := DocNo;
        JobJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.");
        JobJnlLine2.SetRange("Journal Template Name", JobJnlLine2."Journal Template Name");
        JobJnlLine2.SetRange("Journal Batch Name", JobJnlLine2."Journal Batch Name");
        LastJobJnlLine.Init();
        First := true;
        if JobJnlLine2.FindSet() then
            repeat
                if ((FirstDocNo <> GetTempRenumberDocumentNo()) and (JobJnlLine2.GetFilter("Document No.") = '')) then begin
                    Commit();
                    JobJnlBatch.Get(JobJnlLine2."Journal Template Name", JobJnlLine2."Journal Batch Name");
                    TempFirstDocNo := NoSeries.PeekNextNo(JobJnlBatch."No. Series", JobJnlLine2."Posting Date");
                    if (FirstDocNo <> TempFirstDocNo) and (FirstDocNo <> IncStr(TempFirstDocNo)) then begin
                        DocNo := TempFirstDocNo;
                        FirstDocNo := DocNo;
                        First := true;
                    end;
                end;
                if JobJnlLine2."Document No." = FirstDocNo then
                    exit;
                if not First and
                    ((JobJnlLine2."Posting Date" <> PrevPostingDate) or
                    (JobJnlLine2."Document No." = '')) and
                    not LastJobJnlLine.EmptyLine()
                then
                    DocNo := IncStr(DocNo);
                PrevDocNo := JobJnlLine2."Document No.";
                PrevPostingDate := JobJnlLine2."Posting Date";
                JobJnlLine3.Get(JobJnlLine2."Journal Template Name", JobJnlLine2."Journal Batch Name", JobJnlLine2."Line No.");
                JobJnlLine3."Document No." := DocNo;
                JobJnlLine3.Modify();
                First := false;
                LastJobJnlLine := JobJnlLine2;
            until JobJnlLine2.Next() = 0;

        OnAfterRenumberDocNoOnLines(DocNo, JobJnlLine2);
    end;

    local procedure SkipRenumberDocumentNo() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipRenumberDocumentNo(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GuiAllowed() and not Dialog.Confirm(StrSubstNo(RenumberDocNoQst, ProductName.Short()), true));
    end;

    local procedure GetTempRenumberDocumentNo(): Code[20]
    begin
        exit('RENUMBERED-000000001');
    end;

    local procedure CalcBaseQtyForJobPlanningLine(Qty: Decimal; FromFieldName: Text; ToFieldName: Text; JobPlanningLine: Record "Job Planning Line"): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code", Qty, JobPlanningLine."Qty. per Unit of Measure", JobPlanningLine."Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var JobJournalLine: Record "Job Journal Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var JobJournalLine: Record "Job Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var JobJournalLine: Record "Job Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemUoM(var JobJournalLine: Record "Job Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUoM(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountUoM(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var JobJournalLine: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAmounts(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(JobJournalLine: Record "Job Journal Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResourceFindCost(var JobJournalLine: Record "Job Journal Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var JobJournalLine: Record "Job Journal Line"; LastJobJournalLine: Record "Job Journal Line"; JobJournalTemplate: Record "Job Journal Template"; JobJournalBatch: Record "Job Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensions(var JobJournalLine: Record "Job Journal Line"; var DimensionSetIDArr: array[10] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalCost(var JobJournalLine: Record "Job Journal Line"; AmountRoundingPrecision: Decimal; AmountRoundingPrecisionFCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalPrice(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsAndDiscounts(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var AmountRoundingPrecision: Decimal; var AmountRoundingPrecisionFCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var JobJournalLine: Record "Job Journal Line"; UnitAmountRoundingPrecision: Decimal; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectPosting(JobJournalLine: Record "Job Journal Line"; var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var JobJournalLine: Record "Job Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var CheckedAvailability: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDateNotEmpty(var JobJournalLine: Record "Job Journal Line"; var LineIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindPriceAndDiscount(var JobJournalLine: Record "Job Journal Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJob(var JobJournalLine: Record "Job Journal Line"; var Job: Record Job; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var JobJournalLine: Record "Job Journal Line"; var Location: Record Location; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCostFactor(var JobJournalLine: Record "Job Journal Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRoundingPrecisions(var JobJournalLine: Record "Job Journal Line"; var AmountRoundingPrecision: Decimal; var UnitAmountRoundingPrecision: Decimal; var AmountRoundingPrecisionFCY: Decimal; var UnitAmountRoundingPrecisionFCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmptyLine(var JobJournalLine: Record "Job Journal Line"; var LineIsEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPrice(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; var ShouldRetrieveCostPrice: Boolean; var Result: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUpNewLine(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; LastJobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCountryRegionCodeFromJob(var JobJournalLine: Record "Job Journal Line"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCodeQty(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; Resource: Record Resource; WorkType: Record "Work Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingDate(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVariantCode(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitofMeasureCode(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobNo(var JobJournalLine: Record "Job Journal Line"; var Customer: Record Customer; var DimensionManagement: Codeunit DimensionManagement; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateAllAmounts(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var JobJounralLine: Record "Job Journal Line"; var IsHandled: Boolean; xJobJounralLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; JobJournalLine: Record "Job Journal Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateAllAmounts(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckResource(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinContent(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinContentLookUp(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestUnitOfMeasureCode(var JobJournalLine: Record "Job Journal Line"; WorkType: Record "Work Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsAndDiscounts(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateChargeable(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean; xJobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCode(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; var IsLineDiscountHandled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailableOnBeforeAssignQuantity(var JobJournalLine: Record "Job Journal Line"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDirectedPutawayandPickIsFalseOnBeforeTestField(var Location: Record Location; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterCheckItem(var JobJournalLine: Record "Job Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceOnAfterCheckResource(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnAfterSetItemLedgerEntryFilters(var ItemLedgEntry: Record "Item Ledger Entry"; CurrentFieldNo: Integer; var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCurrencyFactorOnBeforeGetExchangeRate(JobJournalLine: Record "Job Journal Line"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobNoOnBeforeCheckJob(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobTaskNoOnAfterTestJobTaskType(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobTaskNo(var JobJournalLine: Record "Job Journal Line"; var xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromGLAccount(var JobJournalLine: Record "Job Journal Line"; GLAccount: Record "G/L Account"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var JobJournalLine: Record "Job Journal Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromResource(var JobJournalLine: Record "Job Journal Line"; Resource: Record Resource; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeGetLocation(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeValidateQuantity(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var JobJournalLine: Record "Job Journal Line"; CurrFieldNo: Integer; xJobJournalLine: Record "Job Journal Line"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeOnBeforeValidateQuantity(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeValidateQuantity(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitCostLCYOnAfterConvertAmountToFCY(var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDimensions(var JobJournalLine: Record "Job Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnNewLine(var JobJournalLine: Record "Job Journal Line"; var JobJournalTemplate: Record "Job Journal Template"; var JobJournalBatch: Record "Job Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnBeforeValidateUoMCode(var JobJournalLine: Record "Job Journal Line"; Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var JobJournalLine: Record "Job Journal Line"; var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSkipRenumberDocumentNo(JobJournalLine: Record "Job Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenumberDocNoOnLines(var DocNo: Code[20]; var JobJnlLine2: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenumberDocNoOnLines(var DocNo: Code[20]; var JobJnlLine2: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateJobPlanningLineLink(var JobJournalLine: Record "Job Journal Line"; xJobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean);
    begin
    end;
}