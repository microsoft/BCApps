// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 1003 "Job Planning Line"
{
    Caption = 'Project Planning Line';
    DrillDownPageID = "Job Planning Lines";
    LookupPageID = "Job Planning Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            NotBlank = true;
            TableRelation = Job;
        }
        field(3; "Planning Date"; Date)
        {
            Caption = 'Planning Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlanningDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ValidateModification(xRec."Planning Date" <> "Planning Date", Rec.FieldNo("Planning Date"));

                Validate("Document Date", "Planning Date");
                if ("Currency Date" = 0D) or ("Currency Date" = xRec."Planning Date") then
                    Validate("Currency Date", "Planning Date");
                if (Type <> Type::Text) and ("No." <> '') then
                    UpdateAllAmounts();
                if "Planning Date" <> 0D then
                    CheckItemAvailable(FieldNo("Planning Date"));
                if CurrFieldNo = FieldNo("Planned Delivery Date") then
                    UpdateReservation(CurrFieldNo)
                else
                    UpdateReservation(FieldNo("Planning Date"));
                "Planned Delivery Date" := "Planning Date";

                UpdatePlannedDueDate();
            end;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Document No." <> "Document No.", Rec.FieldNo("Document No."));
            end;
        }
        field(5; Type; Enum "Job Planning Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                ValidateModification(xRec.Type <> Type, Rec.FieldNo(Type));

                UpdateReservation(FieldNo(Type));

                Validate("No.", '');
            end;
        }
        field(7; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Text)) "Standard Text";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                "No." := FindOrCreateRecordByNo("No.");
                ValidateModification(xRec."No." <> "No.", Rec.FieldNo("No."));

                CheckUsageLinkRelations();

                UpdateReservation(FieldNo("No."));

                UpdateDescription();

                if ("No." = '') or ("No." <> xRec."No.") then begin
                    "Unit of Measure Code" := '';
                    "Qty. per Unit of Measure" := 1;
                    "Variant Code" := '';
                    "Work Type Code" := '';
                    "Gen. Bus. Posting Group" := '';
                    "Gen. Prod. Posting Group" := '';
                    DeleteAmounts();
                    "Cost Factor" := 0;
                    if Type = Type::Item then begin
                        "Bin Code" := '';
                        if "No." <> '' then
                            InitLocation();
                        if "Bin Code" = '' then
                            SetDefaultBin();
                        JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("No."));
                    end;
                    if "No." = '' then
                        exit;
                end;

                CopyFieldsFromJob();

                case Type of
                    Type::Resource:
                        CopyFromResource();
                    Type::Item:
                        CopyFromItem();
                    Type::"G/L Account":
                        CopyFromGLAccount();
                    Type::Text:
                        CopyFromStandardText();
                end;

                InitQtyToAsm();

                OnValidateNoOnAfterCopyFromAccount(Rec, xRec, Job);

                if Type <> Type::Text then
                    Validate(Quantity);
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                ValidateModification(xRec.Description <> Description, Rec.FieldNo(Description));
            end;
        }
        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if (Quantity <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                CheckQuantityPosted();

                CalcFields("Qty. Transferred to Invoice");
                if ("Qty. Transferred to Invoice" > 0) and (Quantity < "Qty. Transferred to Invoice") then
                    Error(QtyLessErr, FieldCaption(Quantity), FieldCaption("Qty. Transferred to Invoice"));
                if ("Qty. Transferred to Invoice" < 0) and (Quantity > "Qty. Transferred to Invoice") then
                    Error(QtyGreaterErr, FieldCaption(Quantity), FieldCaption("Qty. Transferred to Invoice"));

                case Type of
                    Type::Item:
                        if not Item.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, Item.FieldCaption("No."));
                    Type::Resource:
                        if not Res.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, Res.FieldCaption("No."));
                    Type::"G/L Account":
                        if not GLAcc.Get("No.") then
                            Error(MissingItemResourceGLErr, Type, GLAcc.FieldCaption("No."));
                end;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                CalcQuantityBase();

                "Completely Picked" := "Qty. Picked" >= Quantity;

                UpdateRemainingQuantity();

                UpdateQtyToTransfer();
                UpdateQtyToInvoice();

                CheckItemAvailable(FieldNo(Quantity));
                UpdateReservation(FieldNo(Quantity));

                UpdateAllAmounts();

                InitQtyToAsm();
                if "Line Type" in ["Line Type"::"Both Budget and Billable", "Line Type"::Budget] then
                    Validate("Qty. to Assemble");

                if not BypassQtyValidation then
                    JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo(Quantity));

                BypassQtyValidation := false;
            end;
        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost (LCY)';

            trigger OnValidate()
            begin
                if ("Direct Unit Cost (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
            end;
        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Cost (LCY)" <> "Unit Cost (LCY)", Rec.FieldNo("Unit Cost (LCY)"));

                if ("Unit Cost (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                if (Type = Type::Item) and
                   Item.Get("No.") and
                   (Item."Costing Method" = Item."Costing Method"::Standard)
                then
                    UpdateAllAmounts()
                else begin
                    InitRoundingPrecisions();
                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                    UpdateAllAmounts();
                end;
            end;
        }
        field(13; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(14; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Price (LCY)" <> "Unit Price (LCY)", Rec.FieldNo("Unit Price (LCY)"));
                if ("Unit Price (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                InitRoundingPrecisions();
                "Unit Price" := ConvertAmountToFCY("Unit Price (LCY)", UnitAmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(15; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(16; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";
        }
        field(17; "Unit of Measure Code"; Code[10])
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
            begin
                ValidateModification(xRec."Unit of Measure Code" <> "Unit of Measure Code", Rec.FieldNo("Unit of Measure Code"));

                GetGLSetup();
                case Type of
                    Type::Item:
                        begin
                            Item.Get("No.");
                            "Qty. per Unit of Measure" :=
                              UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                            JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Unit of Measure Code"));
                        end;
                    Type::Resource:
                        begin
                            if CurrFieldNo <> FieldNo("Work Type Code") then
                                if "Work Type Code" <> '' then begin
                                    WorkType.Get("Work Type Code");
                                    if WorkType."Unit of Measure Code" <> '' then
                                        TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
                                end else
                                    TestField("Work Type Code", '');
                            if "Unit of Measure Code" = '' then begin
                                Resource.Get("No.");
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                            end;
                            ResourceUnitOfMeasure.Get("No.", "Unit of Measure Code");
                            "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";
                            "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                        end;
                    Type::"G/L Account":
                        "Qty. per Unit of Measure" := 1;
                end;
                CheckItemAvailable(FieldNo("Unit of Measure Code"));
                UpdateReservation(FieldNo("Unit of Measure Code"));
                Validate(Quantity);
            end;
        }
        field(18; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(19; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                SkipValidateQuantity: Boolean;
            begin
                ValidateModification(xRec."Location Code" <> "Location Code", Rec.FieldNo("Location Code"));

                "Bin Code" := '';
                if Type = Type::Item then begin
                    GetLocation("Location Code");
                    CheckItemAvailable(FieldNo("Location Code"));
                    UpdateReservation(FieldNo("Location Code"));
                    OnBeforeValidateQuantity(Rec, xRec, SkipValidateQuantity);
                    if not SkipValidateQuantity then
                        Validate(Quantity);
                    SetDefaultBin();
                    JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Location Code"));
                    InitQtyToAsm();
                    ATOLink.UpdateAsmFromJobPlanningLine(Rec);

                    DeleteWarehouseRequest(xRec);
                    CreateWarehouseRequest();
                end;
            end;
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(32; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ValidateModification(xRec."Work Type Code" <> "Work Type Code", Rec.FieldNo("Work Type Code"));
                TestField(Type, Type::Resource);

                Validate("Line Discount %", 0);
                if ("Work Type Code" = '') and (xRec."Work Type Code" <> '') then begin
                    Res.Get("No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure";
                    Validate("Unit of Measure Code");
                end;
                if WorkType.Get("Work Type Code") then
                    if WorkType."Unit of Measure Code" <> '' then begin
                        "Unit of Measure Code" := WorkType."Unit of Measure Code";
                        if ResourceUnitOfMeasure.Get("No.", "Unit of Measure Code") then
                            "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";
                    end else begin
                        Res.Get("No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                        Validate("Unit of Measure Code");
                    end;
                Validate(Quantity);
            end;
        }
        field(33; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if (Type = Type::Item) and ("No." <> '') then
                    UpdateAllAmounts();
            end;
        }
        field(79; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";
        }
        field(80; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(81; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(83; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(84; "Planning Due Date"; Date)
        {
            Caption = 'Planning Due Date';

            trigger OnValidate()
            begin
                JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Planning Due Date"));
            end;
        }
        field(900; "Qty. to Assemble"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Qty. to Assemble';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Line Type" = "Line Type"::Billable then
                    FieldError("Line Type");

                if (not "Usage Link") and ("Qty. to Assemble" <> 0) then
                    FieldError("Usage Link");

                if ("Qty. to Assemble" <> Quantity) and ("Qty. to Assemble" <> 0) and WhsePickReqForLocation() then
                    FieldError("Qty. to Assemble", StrSubstNo(DifferentQtyToAssembleErr, FieldCaption(Quantity)));

                "Qty. to Assemble" := UOMMgt.RoundAndValidateQty("Qty. to Assemble", "Qty. Rounding Precision", FieldCaption("Qty. to Assemble"));
                "Qty. to Assemble (Base)" := CalcBaseQty("Qty. to Assemble", FieldCaption("Qty. to Assemble"), FieldCaption("Qty. to Assemble (Base)"));

                if "Qty. to Assemble (Base)" < 0 then
                    FieldError("Qty. to Assemble", NegativeQtyToAssembleErr);

                CheckItemAvailable(FieldNo("Qty. to Assemble"));
                ATOLink.UpdateAsmFromJobPlanningLine(Rec);
            end;
        }
        field(901; "Qty. to Assemble (Base)"; Decimal)
        {
            Caption = 'Qty. to Assemble (Base)';
            DecimalPlaces = 0 : 5;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Assemble", "Qty. to Assemble (Base)");
            end;
        }
        field(902; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(903; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
            DataClassification = CustomerContent;
        }
        field(904; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            DataClassification = CustomerContent;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."),
                                                           "Job Task No." = field("Job Task No."));
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1001; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Amount (LCY)" <> "Line Amount (LCY)", Rec.FieldNo("Line Amount (LCY)"));
                if ("Line Amount (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

                InitRoundingPrecisions();
                "Line Amount" := ConvertAmountToFCY("Line Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(1002; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Cost" <> "Unit Cost", Rec.FieldNo("Unit Cost"));
                if ("Unit Cost" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
            end;
        }
        field(1003; "Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            Editable = false;
        }
        field(1004; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Unit Price" <> "Unit Price", Rec.FieldNo("Unit Price"));
                if ("Unit Price" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
            end;
        }
        field(1005; "Total Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            Editable = false;
        }
        field(1006; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Amount" <> "Line Amount", Rec.FieldNo("Line Amount"));
                if ("Line Amount" <> 0) and (Type = Type::Text) then
                    FieldError(Type);

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
                ValidateModification(xRec."Line Discount Amount" <> "Line Discount Amount", Rec.FieldNo("Line Discount Amount"));
                if ("Line Discount Amount" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
            end;
        }
        field(1008; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Discount Amount (LCY)" <> "Line Discount Amount (LCY)", Rec.FieldNo("Line Discount Amount (LCY)"));
                if ("Line Discount Amount (LCY)" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                InitRoundingPrecisions();
                "Line Discount Amount" :=
                    ConvertAmountToFCY("Line Discount Amount (LCY)", AmountRoundingPrecisionFCY);
                UpdateAllAmounts();
            end;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            Caption = 'Cost Factor';
            Editable = false;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Cost Factor" <> "Cost Factor", Rec.FieldNo("Cost Factor"));

                UpdateAllAmounts();
            end;
        }
        field(1019; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
        }
        field(1020; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(1021; "Line Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Line Discount %" <> "Line Discount %", Rec.FieldNo("Line Discount %"));
                if ("Line Discount %" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
                UpdateAllAmounts();
            end;
        }
        field(1022; "Line Type"; Enum "Job Planning Line Line Type")
        {
            Caption = 'Line Type';

            trigger OnValidate()
            begin
                "Schedule Line" := true;
                "Contract Line" := true;
                if "Line Type" = "Line Type"::Budget then
                    "Contract Line" := false;
                if "Line Type" = "Line Type"::Billable then
                    "Schedule Line" := false;

                if not "Contract Line" and (("Qty. Transferred to Invoice" <> 0) or ("Qty. Invoiced" <> 0)) then
                    Error(LineTypeErr, TableCaption(), FieldCaption("Line Type"), "Line Type");

                ControlUsageLink();
            end;
        }
        field(1023; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Code" <> "Currency Code", Rec.FieldNo("Currency Code"));

                UpdateCurrencyFactor();
                UpdateAllAmounts();
            end;
        }
        field(1024; "Currency Date"; Date)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Date';

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Date" <> "Currency Date", Rec.FieldNo("Currency Date"));

                UpdateCurrencyFactor();
                if (CurrFieldNo <> FieldNo("Planning Date")) and (Type <> Type::Text) and ("No." <> '') then
                    UpdateFromCurrency();
            end;
        }
        field(1025; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateModification(xRec."Currency Factor" <> "Currency Factor", Rec.FieldNo("Currency Factor"));

                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(CurrencyFactorErr, FieldCaption("Currency Code")));
                UpdateAllAmounts();
            end;
        }
        field(1026; "Schedule Line"; Boolean)
        {
            Caption = 'Budget Line';
            Editable = false;
            InitValue = true;
        }
        field(1027; "Contract Line"; Boolean)
        {
            Caption = 'Billable Line';
            Editable = false;
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            Editable = false;
        }
        field(1035; "Invoiced Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line Invoice"."Invoiced Amount (LCY)" where("Job No." = field("Job No."),
                                                                                         "Job Task No." = field("Job Task No."),
                                                                                         "Job Planning Line No." = field("Line No.")));
            Caption = 'Invoiced Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 1;
        }
        field(1036; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            CalcFormula = sum("Job Planning Line Invoice"."Invoiced Cost Amount (LCY)" where("Job No." = field("Job No."),
                                                                                              "Job Task No." = field("Job Task No."),
                                                                                              "Job Planning Line No." = field("Line No.")));
            Caption = 'Invoiced Cost Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 1;
        }
        field(1037; "VAT Unit Price"; Decimal)
        {
            Caption = 'VAT Unit Price';
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1038; "VAT Line Discount Amount"; Decimal)
        {
            Caption = 'VAT Line Discount Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1039; "VAT Line Amount"; Decimal)
        {
            Caption = 'VAT Line Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1041; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(1042; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(1043; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Ledger Entry No.';
            Editable = false;
            TableRelation = "Job Ledger Entry";
        }
        field(1048; Status; Enum "Job Planning Line Status")
        {
            Caption = 'Status';
            Editable = false;
            InitValue = "Order";

            trigger OnValidate()
            begin
                JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo(Status));
            end;
        }
        field(1050; "Ledger Entry Type"; Enum "Job Ledger Entry Type")
        {
            Caption = 'Ledger Entry Type';
        }
        field(1051; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            TableRelation = if ("Ledger Entry Type" = const(Resource)) "Res. Ledger Entry"
            else
            if ("Ledger Entry Type" = const(Item)) "Item Ledger Entry"
            else
            if ("Ledger Entry Type" = const("G/L Account")) "G/L Entry";
        }
        field(1052; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
        }
        field(1053; "Usage Link"; Boolean)
        {
            Caption = 'Usage Link';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUsageLink(Rec, xRec, IsHandled);
                if not IsHandled then
                    if "Usage Link" and ("Line Type" = "Line Type"::Billable) then
                        Error(UsageLinkErr, FieldCaption("Usage Link"), TableCaption(), FieldCaption("Line Type"), "Line Type");

                ControlUsageLink();

                CheckItemAvailable(FieldNo("Usage Link"));
                UpdateReservation(FieldNo("Usage Link"));
            end;
        }
        field(1060; "Remaining Qty."; Decimal)
        {
            Caption = 'Remaining Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Remaining Qty. (Base)", CalcBaseQty("Remaining Qty.", FieldCaption("Remaining Qty."), FieldCaption("Remaining Qty. (Base)")));
            end;
        }
        field(1061; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1062; "Remaining Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Total Cost';
            Editable = false;
        }
        field(1063; "Remaining Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Total Cost (LCY)';
            Editable = false;
        }
        field(1064; "Remaining Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Line Amount';
            Editable = false;
        }
        field(1065; "Remaining Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Remaining Line Amount (LCY)';
            Editable = false;
        }
        field(1070; "Qty. Posted"; Decimal)
        {
            Caption = 'Qty. Posted';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1071; "Qty. to Transfer to Journal"; Decimal)
        {
            Caption = 'Qty. to Transfer to Journal';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Qty. to Transfer to Journal" <> 0) and (Type = Type::Text) then
                    FieldError(Type);
            end;
        }
        field(1072; "Posted Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Total Cost';
            Editable = false;
        }
        field(1073; "Posted Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Posted Total Cost (LCY)';
            Editable = false;
        }
        field(1074; "Posted Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Line Amount';
            Editable = false;
        }
        field(1075; "Posted Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Posted Line Amount (LCY)';
            Editable = false;
        }
        field(1080; "Qty. Transferred to Invoice"; Decimal)
        {
            CalcFormula = sum("Job Planning Line Invoice"."Quantity Transferred" where("Job No." = field("Job No."),
                                                                                        "Job Task No." = field("Job Task No."),
                                                                                        "Job Planning Line No." = field("Line No.")));
            Caption = 'Qty. Transferred to Invoice';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1081; "Qty. to Transfer to Invoice"; Decimal)
        {
            Caption = 'Qty. to Transfer to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToTransferToInvoice(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Qty. to Transfer to Invoice" = 0 then
                    exit;

                if Type = Type::Text then
                    FieldError(Type);

                if "Contract Line" then begin
                    if Quantity = "Qty. Transferred to Invoice" then
                        Error(QtyAlreadyTransferredErr, TableCaption);

                    if Quantity > 0 then begin
                        if ("Qty. to Transfer to Invoice" > 0) and ("Qty. to Transfer to Invoice" > (Quantity - "Qty. Transferred to Invoice")) or
                           ("Qty. to Transfer to Invoice" < 0)
                        then
                            Error(QtyToTransferToInvoiceErr, FieldCaption("Qty. to Transfer to Invoice"), 0, Quantity - "Qty. Transferred to Invoice");
                    end else
                        if ("Qty. to Transfer to Invoice" > 0) or
                           ("Qty. to Transfer to Invoice" < 0) and ("Qty. to Transfer to Invoice" < (Quantity - "Qty. Transferred to Invoice"))
                        then
                            Error(QtyToTransferToInvoiceErr, FieldCaption("Qty. to Transfer to Invoice"), Quantity - "Qty. Transferred to Invoice", 0);
                end else
                    Error(NoContractLineErr, FieldCaption("Qty. to Transfer to Invoice"), TableCaption(), "Line Type");
            end;
        }
        field(1090; "Qty. Invoiced"; Decimal)
        {
            CalcFormula = sum("Job Planning Line Invoice"."Quantity Transferred" where("Job No." = field("Job No."),
                                                                                        "Job Task No." = field("Job Task No."),
                                                                                        "Job Planning Line No." = field("Line No."),
                                                                                        "Document Type" = filter("Posted Invoice" | "Posted Credit Memo")));
            Caption = 'Qty. Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1091; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1100; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = - sum("Reservation Entry".Quantity where("Source Type" = const(1003),
#pragma warning disable AL0603
                                                                   "Source Subtype" = field(Status),
#pragma warning restore
                                                                   "Source ID" = field("Job No."),
                                                                   "Source Ref. No." = field("Job Contract Entry No."),
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1101; "Reserved Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Item = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source Type" = const(1003),
#pragma warning disable AL0603
                                                                            "Source Subtype" = field(Status),
#pragma warning restore
                                                                            "Source ID" = field("Job No."),
                                                                            "Source Ref. No." = field("Job Contract Entry No."),
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure");
                UpdatePlanned();
            end;
        }
        field(1102; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';

            trigger OnValidate()
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                    TestField("Usage Link");
                end;
                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if xRec.Reserve = Reserve::Always then begin
                    GetItem();
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(1103; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                ValidateModification(xRec."Variant Code" <> "Variant Code", Rec.FieldNo("Variant Code"));

                if Rec."Variant Code" = '' then begin
                    if Type = Type::Item then begin
                        Item.Get("No.");
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end
                end else begin
                    TestField(Type, Type::Item);
                    ItemVariant.SetLoadFields(Description, "Description 2", Blocked);
                    ItemVariant.Get("No.", "Variant Code");
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;
                GetItemTranslation();
                Validate(Quantity);
                CheckItemAvailable(FieldNo("Variant Code"));
                UpdateReservation(FieldNo("Variant Code"));
                InitQtyToAsm();
                ATOLink.UpdateAsmFromJobPlanningLine(Rec);
                JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                BinCodeCaption: Text[30];
            begin
                ValidateModification(xRec."Bin Code" <> "Bin Code", Rec.FieldNo("Bin Code"));
                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    GetLocation("Location Code");
                    TestField(Type, Type::Item);
                    GetItem();
                    Item.TestField(Type, Item.Type::Inventory);
                    CheckItemAvailable(FieldNo("Bin Code"));
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    BinCodeCaption := CopyStr(FieldCaption("Bin Code"), 1, 30);
                    WhseIntegrationMgt.CheckBinTypeAndCode(
                        Database::"Job Planning Line", BinCodeCaption, "Location Code", "Bin Code", 0);
                    CheckBin();
                end;

                UpdateReservation(FieldNo("Bin Code"));
                JobWarehouseMgt.JobPlanningLineVerifyChange(Rec, xRec, FieldNo("Bin Code"));
                ATOLink.UpdateAsmBinCodeFromJobPlanningLine(Rec);
            end;

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                TestField("Location Code");
                TestField(Type, Type::Item);

                if Item.Get(Rec."No.") then
                    if BinCode <> '' then
                        Item.TestField(Type, Item.Type::Inventory);

                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and
                   ("Promised Delivery Date" <> 0D)
                then
                    Error(
                      RequestedDeliveryDateErr,
                      FieldCaption("Requested Delivery Date"),
                      FieldCaption("Promised Delivery Date"));

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Requested Delivery Date")
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            begin
                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                Validate("Planning Date", "Planned Delivery Date");
            end;
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
        field(7300; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = filter(<> "Put-away"),
                                                                                  "Source Type" = const(167),
                                                                                  "Source No." = field("Job No."),
                                                                                  "Source Line No." = field("Job Contract Entry No."),
                                                                                  "Source Subline No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7301; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");

                "Completely Picked" := "Qty. Picked" >= Quantity;
            end;
        }
        field(7302; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7303; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7304; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter(<> "Put-away"),
                                                                                         "Source Type" = const(167),
                                                                                         "Source No." = field("Job No."),
                                                                                         "Source Line No." = field("Job Contract Entry No."),
                                                                                         "Source Subline No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7305; "Qty. on Journal"; Decimal)
        {
            CalcFormula = sum("Job Journal Line"."Quantity (Base)" where("Job No." = field("Job No."),
                                                                  "Job Task No." = field("Job Task No."),
                                                                  "Job Planning Line No." = field("Line No."),
                                                                  Type = field(Type),
                                                                  "No." = field("No.")));
            Caption = 'Qty. on Journal';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", "Job Task No.", "Schedule Line", "Planning Date")
        {
            SumIndexFields = "Total Price (LCY)", "Total Cost (LCY)", "Line Amount (LCY)", "Remaining Total Cost (LCY)", "Remaining Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key3; "Job No.", "Job Task No.", "Contract Line", "Planning Date")
        {
            SumIndexFields = "Total Price (LCY)", "Total Cost (LCY)", "Line Amount (LCY)", "Remaining Total Cost (LCY)", "Remaining Line Amount (LCY)", "Total Cost", "Line Amount";
        }
        key(Key4; "Job No.", "Job Task No.", "Schedule Line", "Currency Date")
        {
        }
        key(Key5; "Job No.", "Job Task No.", "Contract Line", "Currency Date")
        {
        }
        key(Key6; "Job No.", "Schedule Line", Type, "No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key7; "Job No.", "Schedule Line", Type, "Resource Group No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key8; Status, "Schedule Line", Type, "No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key9; Status, "Schedule Line", Type, "Resource Group No.", "Planning Date")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key10; "Job No.", "Contract Line")
        {
        }
        key(Key11; "Job Contract Entry No.")
        {
        }
        key(Key12; Type, "No.", "Job No.", "Job Task No.", "Usage Link", "System-Created Entry")
        {
        }
        key(Key13; Status, Type, "No.", "Variant Code", "Location Code", "Planning Date")
        {
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key14; "Job No.", "Planning Date", "Document No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobUsageLink: Record "Job Usage Link";
        IsHandled: Boolean;
    begin
        ConfirmDeletion();

        PreventDeleteIfPurchaseExists(Rec);

        ValidateModification(true, 0);
        CheckRelatedJobPlanningLineInvoice();

        if "Usage Link" then begin
            JobUsageLink.SetRange("Job No.", "Job No.");
            JobUsageLink.SetRange("Job Task No.", "Job Task No.");
            JobUsageLink.SetRange("Line No.", "Line No.");
            IsHandled := false;
            OnDeleteOnAfterSetFilterOnJobUsageLink(Rec, JobUsageLink, IsHandled);
            if not IsHandled then
                if not JobUsageLink.IsEmpty() then
                    Error(JobUsageLinkErr, TableCaption);
        end;

        if (Rec.Quantity <> 0) and ItemExists(Rec."No.") then begin
            JobPlanningLineReserve.DeleteLine(Rec);
            CalcFields("Reserved Qty. (Base)");
            TestField("Reserved Qty. (Base)", 0);
        end;

        DeleteAttachedJobPlanningLines();

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");

        JobWarehouseMgt.JobPlanningLineDelete(Rec);

        if Rec.Type = Rec.Type::Item then
            ATOLink.DeleteAsmFromJobPlanningLine(Rec);

        DeleteWarehouseRequest(Rec);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        GetJob();
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        JobTask.Get("Job No.", "Job Task No.");
        JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
        InitJobPlanningLine();
        if Quantity <> 0 then
            UpdateReservation(0);

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");

        CreateWarehouseRequest();
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") then
            UpdateReservation(0);

        if "Schedule Line" then
            Job.UpdateOverBudgetValue("Job No.", false, "Total Cost (LCY)");

        if xRec."Location Code" <> Rec."Location Code" then begin
            DeleteWarehouseRequest(xRec);
            CreateWarehouseRequest();
        end;
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRename(Rec, IsHandled);
        if IsHandled then
            exit;

        Error(RecordRenameErr, FieldCaption("Job No."), FieldCaption("Job Task No."), TableCaption);
    end;

    var
        GLAcc: Record "G/L Account";
        Location: Record Location;
        Item: Record Item;
        JobTask: Record "Job Task";
        Res: Record Resource;
        WorkType: Record "Work Type";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CurrExchRate: Record "Currency Exchange Rate";
        SKU: Record "Stockkeeping Unit";
        StandardText: Record "Standard Text";
        ItemTranslation: Record "Item Translation";
        GLSetup: Record "General Ledger Setup";
        ATOLink: Record "Assemble-to-Order Link";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        JobWarehouseMgt: Codeunit "Job Warehouse Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        CurrencyFactorErr: Label 'cannot be specified without %1', Comment = '%1 = Currency Code field name';
        RecordRenameErr: Label 'You cannot change the %1 or %2 of this %3.', Comment = '%1 = Project Number field name; %2 = Project Task Number field name; %3 = Project Planning Line table name';
        CurrencyDate: Date;
        MissingItemResourceGLErr: Label 'You must specify %1 %2 in planning line.', Comment = '%1 = Document Type (Item, Resoure, or G/L); %2 = Field name';
        HasGotGLSetup: Boolean;
        QtyLessErr: Label '%1 cannot be less than %2.', Comment = '%1 = Name of first field to compare; %2 = Name of second field to compare';
        ControlUsageLinkErr: Label 'The %1 must be a %2 and %3 must be enabled, because linked Project Ledger Entries exist.', Comment = '%1 = Project Planning Line table name; %2 = Caption for field Schedule Line; %3 = Captiion for field Usage Link';
        JobUsageLinkErr: Label 'This %1 cannot be deleted because linked project ledger entries exist.', Comment = '%1 = Project Planning Line table name';
        BypassQtyValidation: Boolean;
        SkipCheckForMultipleJobsOnSalesLine: Boolean;
        CalledFromHeader: Boolean;
        LinkedJobLedgerErr: Label 'You cannot change this value because linked project ledger entries exist.';
#pragma warning disable AA0470
        LineTypeErr: Label 'The %1 cannot be of %2 %3 because it is transferred to an invoice.', Comment = 'The Project Planning Line cannot be of Line Type Schedule, because it is transferred to an invoice.';
#pragma warning restore AA0470
        QtyToTransferToInvoiceErr: Label '%1 may not be lower than %2 and may not exceed %3.', Comment = '%1 = Qty. to Transfer to Invoice field name; %2 = First value in comparison; %3 = Second value in comparison';
        AutoReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        NoContractLineErr: Label '%1 cannot be set on a %2 of type %3.', Comment = '%1 = Qty. to Transfer to Invoice field name; %2 = Project Planning Line table name; %3 = The project''s line type';
        QtyAlreadyTransferredErr: Label 'The %1 has already been completely transferred.', Comment = '%1 = Project Planning Line table name';
#pragma warning disable AA0470
        UsageLinkErr: Label '%1 cannot be enabled on a %2 with %3 %4.', Comment = 'Usage Link cannot be enabled on a Project Planning Line with Line Type Schedule';
#pragma warning restore AA0470
        QtyGreaterErr: Label '%1 cannot be higher than %2.', Comment = '%1 = Caption for field Quantity; %2 = Captiion for field Qty. Transferred to Invoice';
        RequestedDeliveryDateErr: Label 'You cannot change the %1 when the %2 has been filled in.', Comment = '%1 = Caption for field Requested Delivery Date; %2 = Captiion for field Promised Delivery Date';
        NotPossibleJobPlanningLineErr: Label 'It is not possible to deleted project planning line transferred to an invoice.';
        NegativeQtyToAssembleErr: Label ' must be positive.', Comment = 'Qty. to Assemble can''t be negative';
        DifferentQtyToAssembleErr: Label ' must be equal to %1.', Comment = 'Qty. to Assemble must be equal to Quantity, %1 = Quantity';
        CannotBeMoreErr: Label 'cannot be more than %1', Comment = '%1 = Quantity';
        ConfirmDeleteQst: Label '%1 = %2 is greater than %3 = %4. If you delete the %5, the items will remain in the operation area until you put them away.\Any related item tracking information defined during the pick process will be deleted.\Do you still want to delete the %5?', Comment = '%1 = FieldCaption("Qty. Picked"), %2 = "Qty. Picked", %3 = FieldCaption("Qty. Posted"), %4 = "Qty. Posted", %5 = TableCaption';
        PurchRcptLineExistErr: Label 'You cannot delete this Project Planning Line because a Purchase Receipt %1 exists for it.', Comment = 'Purchase Receipt Line already exist for the Job Planning Line';

    protected var
        Job: Record Job;
        UnitAmountRoundingPrecision: Decimal;
        AmountRoundingPrecision: Decimal;
        UnitAmountRoundingPrecisionFCY: Decimal;
        AmountRoundingPrecisionFCY: Decimal;

    internal procedure OpenItemTrackingLines()
    begin
        JobPlanningLineReserve.CallItemTracking(Rec);
    end;

    internal procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" < 0);
    end;

    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    begin
        if CurrFieldNo <> CalledByFieldNo then
            exit;
        if (Type <> Type::Item) or ("No." = '') then
            exit;
        if Quantity <= 0 then
            exit;
        if not (Status in [Status::Order]) then
            exit;

        if ItemCheckAvail.JobPlanningLineCheck(Rec) then
            ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if not Location."Check Whse. Class" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckWhseClass(false) then
                    "Bin Code" := '';
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckWhseClass("No.", false) then
                    "Bin Code" := '';
            end;
        end;
    end;

    local procedure DeleteAttachedJobPlanningLines()
    var
        AttachedJobPlanningLine: Record "Job Planning Line";
    begin
        if Rec."Line No." = 0 then
            exit;
        AttachedJobPlanningLine.SetRange("Job No.", Rec."Job No.");
        AttachedJobPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
        AttachedJobPlanningLine.SetRange("Attached to Line No.", Rec."Line No.");
        AttachedJobPlanningLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if not AttachedJobPlanningLine.IsEmpty() then
            AttachedJobPlanningLine.DeleteAll(true);
    end;

    /// <summary>
    /// Use this method to set the global Job variable.
    /// This is useful for passing unsaved job record changes.
    /// </summary>
    /// <param name="NewJob">The job record</param>
    procedure SetJob(NewJob: Record Job)
    begin
        Job := NewJob;
    end;

    procedure CopyFieldsFromJob()
    begin
        GetJob();
        Rec."Customer Price Group" := Job."Customer Price Group";
        Rec."Price Calculation Method" := Job.GetPriceCalculationMethod();
        Rec."Cost Calculation Method" := Job.GetCostCalculationMethod();

        OnAfterCopyFieldsFromJob(Rec, xRec, Job);
    end;

    /// <summary>
    /// Renames all Job Planning Line "No." values for the specified LineType and OldNo to NewNo.
    /// </summary>
    /// <param name="LineType">The type of the job planning line.</param>
    /// <param name="OldNo">The old number to be replaced.</param>
    /// <param name="NewNo">The new number to set.</param>
    procedure RenameNo(LineType: Enum "Job Planning Line Type"; OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset();
        SetRange(Type, LineType);
        SetRange("No.", OldNo);
        if not Rec.IsEmpty() then
            ModifyAll("No.", NewNo, true);
    end;

    local procedure CheckQuantityPosted()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantityPosted(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Usage Link" then
            if not BypassQtyValidation then begin
                if ("Qty. Posted" > 0) and (Quantity < "Qty. Posted") then
                    Error(QtyLessErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
                if ("Qty. Posted" < 0) and (Quantity > "Qty. Posted") then
                    Error(QtyGreaterErr, FieldCaption(Quantity), FieldCaption("Qty. Posted"));
            end;
    end;

    local procedure CopyFromResource()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromResource(Rec, xRec, IsHandled);
        if not IsHandled then begin
            Res.Get("No.");
            Res.CheckResourcePrivacyBlocked(false);
            Res.TestField(Blocked, false);
            Res.TestField("Gen. Prod. Posting Group");
            if Description = '' then
                Description := Res.Name;
            if "Description 2" = '' then
                "Description 2" := Res."Name 2";
            "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
            "Resource Group No." := Res."Resource Group No.";
            Validate("Unit of Measure Code", Res."Base Unit of Measure");
        end;
        OnAfterCopyFromResource(Rec, Job, Res);
    end;

    local procedure CopyFromItem()
    begin
        GetItem();
        Item.TestField(Blocked, false);
        Item.TestField("Gen. Prod. Posting Group");
        Description := Item.Description;
        "Description 2" := Item."Description 2";
        if Job."Language Code" <> '' then
            GetItemTranslation();
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
        if "Usage Link" then
            if Item.Reserve = Item.Reserve::Optional then
                Reserve := Job.Reserve
            else
                Reserve := Item.Reserve;
        OnAfterCopyFromItem(Rec, Job, Item);
    end;

    local procedure CopyFromGLAccount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromGLAccount(Rec, IsHandled, Job);
        if not IsHandled then begin
            GLAcc.Get("No.");
            GLAcc.CheckGLAcc();
            GLAcc.TestField("Direct Posting", true);
            GLAcc.TestField("Gen. Prod. Posting Group");
            Description := GLAcc.Name;
            "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "Unit of Measure Code" := '';
            "Direct Unit Cost (LCY)" := 0;
            "Unit Cost (LCY)" := 0;
            "Unit Price" := 0;
        end;

        OnAfterCopyFromGLAccount(Rec, Job, GLAcc);
    end;

    local procedure CopyFromStandardText()
    begin
        StandardText.Get("No.");
        Description := StandardText.Description;
    end;

    local procedure CalcQuantityBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetJob()
    begin
        if ("Job No." <> Job."No.") and ("Job No." <> '') then
            Job.Get("Job No.");
        OnAfterGetJob(Rec, Job);
    end;

    procedure UpdateCurrencyFactor()
    begin
        if "Currency Code" <> '' then begin
            if "Currency Date" = 0D then
                CurrencyDate := WorkDate()
            else
                CurrencyDate := "Currency Date";
            OnUpdateCurrencyFactorOnBeforeGetExchangeRate(Rec, CurrExchRate);
            "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
        end else
            "Currency Factor" := 0;
        OnAfterUpdateCurrencyFactor(Rec);
    end;

    local procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    local procedure GetItem()
    begin
        if "No." <> Item."No." then
            if not Item.Get("No.") then
                Clear(Item);
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

    procedure Caption(): Text
    var
        JobForCaption: Record Job;
        JobTaskForCaption: Record "Job Task";
        Result: Text;
        IsHandled: Boolean;
    begin
        Result := '';
        IsHandled := false;
        OnBeforeCaption(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        JobForCaption.SetLoadFields("No.", Description);
        if not JobForCaption.Get("Job No.") then
            exit('');
        JobTaskForCaption.SetLoadFields("Job No.", "Job Task No.", Description);
        if not JobTaskForCaption.Get("Job No.", "Job Task No.") then
            exit('');
        exit(StrSubstNo('%1 %2 %3 %4',
            JobForCaption."No.",
            JobForCaption.Description,
            JobTaskForCaption."Job Task No.",
            JobTaskForCaption.Description));
    end;

    procedure SetUpNewLine(LastJobPlanningLine: Record "Job Planning Line")
    begin
        "Document Date" := LastJobPlanningLine."Planning Date";
        "Document No." := LastJobPlanningLine."Document No.";
        Type := LastJobPlanningLine.Type;
        Validate("Line Type", LastJobPlanningLine."Line Type");
        GetJob();
        "Currency Code" := Job."Currency Code";
        UpdateCurrencyFactor();
        if LastJobPlanningLine."Planning Date" <> 0D then
            Validate("Planning Date", LastJobPlanningLine."Planning Date");
        "Price Calculation Method" := Job.GetPriceCalculationMethod();
        "Cost Calculation Method" := Job.GetCostCalculationMethod();

        OnAfterSetupNewLine(Rec, LastJobPlanningLine);
    end;

    procedure InitJobPlanningLine()
    var
        JobJnlManagement: Codeunit JobJnlManagement;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitJobPlanningLine(Rec, Job, IsHandled);
        if not IsHandled then begin
            GetJob();
            if "Planning Date" = 0D then
                Validate("Planning Date", WorkDate());
            "Currency Code" := Job."Currency Code";
            UpdateCurrencyFactor();
            "VAT Unit Price" := 0;
            "VAT Line Discount Amount" := 0;
            "VAT Line Amount" := 0;
            "VAT %" := 0;
            "Job Contract Entry No." := JobJnlManagement.GetNextEntryNo();
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
            "Last Date Modified" := 0D;
            Status := Job.Status;
            ControlUsageLink();
            "Country/Region Code" := Job."Bill-to Country/Region Code";
        end;
        OnAfterInitJobPlanningLine(Rec);
    end;

    local procedure DeleteAmounts()
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
        "Remaining Total Cost" := 0;
        "Remaining Total Cost (LCY)" := 0;
        "Remaining Line Amount" := 0;
        "Remaining Line Amount (LCY)" := 0;

        "Qty. Posted" := 0;
        "Qty. to Transfer to Journal" := 0;
        "Posted Total Cost" := 0;
        "Posted Total Cost (LCY)" := 0;
        "Posted Line Amount" := 0;
        "Posted Line Amount (LCY)" := 0;

        "Qty. to Transfer to Invoice" := 0;
        "Qty. to Invoice" := 0;

        OnAfterDeleteAmounts(Rec);
    end;

    local procedure UpdateFromCurrency()
    begin
        UpdateAllAmounts();
    end;

    local procedure GetItemTranslation()
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

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Qty." - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Qty. (Base)" - Abs("Reserved Qty. (Base)");
        OnAfterGetRemainingQty(Rec, RemainingQty, RemainingQtyBase);
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Qty.";
        QtyToReserveBase := "Remaining Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', Status, "Job No.", "No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Job Planning Line", Status.AsInteger(), "Job No.", "Job Contract Entry No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Planning Date";
        ReservEntry."Shipment Date" := "Planning Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(Database::"Job Planning Line", Status.AsInteger(), "Job No.", "Job Contract Entry No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    procedure UpdateAllAmounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllAmounts(Rec, xRec, IsHandled, CurrFieldNo);
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
        UpdateRemainingCostsAndAmounts("Currency Date", "Currency Factor");

        OnAfterUpdateAllAmounts(Rec, xRec);
    end;

    local procedure UpdateUnitCost()
    var
        RetrievedCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        GetJob();
        if (Type = Type::Item) and Item.Get("No.") then
            if Item."Costing Method" = Item."Costing Method"::Standard then
                if RetrieveCostPrice(CurrFieldNo) then begin
                    if GetSKU() then
                        "Unit Cost (LCY)" := Round(SKU."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision)
                    else
                        "Unit Cost (LCY)" := Round(Item."Unit Cost" * "Qty. per Unit of Measure", UnitAmountRoundingPrecision);

                    "Unit Cost" := ConvertAmountToFCY("Unit Cost (LCY)", UnitAmountRoundingPrecisionFCY);
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)")
            else
                if RetrieveCostPrice(CurrFieldNo) or (CurrFieldNo = FieldNo("Unit Price")) then begin
                    CalculateRetrievedCost(RetrievedCost);
                    if not (CurrFieldNo = FieldNo("Unit Price")) then begin
                        "Unit Cost" := ConvertAmountToFCY(RetrievedCost, UnitAmountRoundingPrecisionFCY);
                        "Unit Cost (LCY)" := Round(RetrievedCost, UnitAmountRoundingPrecision);
                    end;
                end else
                    RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)")
        else
            RecalculateAmounts(Job."Exch. Calculation (Cost)", xRec."Unit Cost", "Unit Cost", "Unit Cost (LCY)");
    end;

    local procedure CalculateRetrievedCost(var RetrievedCost: Decimal)
    var
        FullyInvoiced: Boolean;
    begin
        CalcFields("Qty. Invoiced", "Invoiced Cost Amount (LCY)");
        FullyInvoiced := (Quantity = "Qty. Invoiced") and ("Qty. Invoiced" <> 0);
        if FullyInvoiced then
            RetrievedCost := "Invoiced Cost Amount (LCY)" / "Qty. Invoiced"
        else
            if GetSKU() then
                RetrievedCost := SKU."Unit Cost" * Rec."Qty. per Unit of Measure"
            else
                RetrievedCost := Item."Unit Cost" * Rec."Qty. per Unit of Measure";
        OnAfterCalculateRetrievedCost(Rec, xRec, SKU, Item, RetrievedCost);
    end;

    procedure AfterResourceFindCost(var ResourceCost: Record "Resource Cost");
    begin
        OnAfterResourceFindCost(Rec, ResourceCost);
    end;

    protected procedure RetrieveCostPrice(CalledByFieldNo: Integer): Boolean
    var
        ShouldRetrieveCostPrice: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ShouldRetrieveCostPrice := false;
        OnBeforeRetrieveCostPrice(Rec, xRec, ShouldRetrieveCostPrice, IsHandled, CalledByFieldNo);
        if IsHandled then
            exit(ShouldRetrieveCostPrice);

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
                         [FieldNo("No."), FieldNo(Quantity), FieldNo("Work Type Code"), FieldNo("Unit of Measure Code")])
                    then
                        exit(false);
                Type::"G/L Account":
                    if not (CalledByFieldNo in [FieldNo("No."), FieldNo(Quantity)]) then
                        exit(false);
            end;

        case Type of
            Type::Item:
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                    ("Location Code" <> xRec."Location Code") or
                    ("Variant Code" <> xRec."Variant Code") or
                    (not BypassQtyValidation and (Quantity <> xRec.Quantity)) or
                    ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::Resource:
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice() or
                    ("Work Type Code" <> xRec."Work Type Code") or
                    ("Unit of Measure Code" <> xRec."Unit of Measure Code");
            Type::"G/L Account":
                ShouldRetrieveCostPrice :=
                    ("No." <> xRec."No.") or
                    IsQuantityChangedForPrice();
            else
                exit(false);
        end;
        exit(ShouldRetrieveCostPrice);
    end;

    local procedure IsQuantityChangedForPrice(): Boolean;
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        if Quantity = xRec.Quantity then
            exit(false);
        exit(PriceCalculationMgt.IsExtendedPriceCalculationEnabled());
    end;

    local procedure UpdateTotalCost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTotalCost(Rec, AmountRoundingPrecisionFCY, AmountRoundingPrecision, IsHandled);
        if IsHandled then
            exit;

        "Total Cost" := Round("Unit Cost" * Quantity, AmountRoundingPrecisionFCY);
        "Total Cost (LCY)" := ConvertAmountToLCY("Total Cost", AmountRoundingPrecision);
    end;

    procedure FindPriceAndDiscount(CalledByFieldNo: Integer)
    var
        PriceType: Enum "Price Type";
        IsHandled: Boolean;
    begin
        if RetrieveCostPrice(CalledByFieldNo) and ("No." <> '') then begin
            IsHandled := false;
            OnBeforeFindPriceAndDiscount(CalledByFieldNo, IsHandled, Rec, xRec);
            if IsHandled then
                exit;

            ApplyPrice(PriceType::Sale, CalledByFieldNo);
            ApplyPrice(PriceType::Purchase, CalledByFieldNo);
            if Type = Type::Resource then begin
                "Unit Cost (LCY)" := ConvertAmountToLCY("Unit Cost", UnitAmountRoundingPrecision);
                "Direct Unit Cost (LCY)" := ConvertAmountToLCY("Direct Unit Cost (LCY)", UnitAmountRoundingPrecision);
            end;
            OnAfterFindPriceAndDiscount(Rec, xRec, CalledByFieldNo);
        end;
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
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
    begin
        LineWithPrice := JobPlanningLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    local procedure HandleCostFactor()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleCostFactor(Rec, xRec, IsHandled);
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

        OnAfterHandleCostFactor(Rec, xRec, Item);
    end;

    local procedure UpdateUnitPrice()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPrice(Rec, xRec, IsHandled);
        if not IsHandled then begin
            GetJob();
            RecalculateAmounts(Job."Exch. Calculation (Price)", xRec."Unit Price", "Unit Price", "Unit Price (LCY)");
        end;
        OnAfterUpdateUnitPrice(Rec, xRec, AmountRoundingPrecision, AmountRoundingPrecisionFCY);
    end;

    procedure RecalculateAmounts(JobExchCalculation: Option "Fixed FCY","Fixed LCY"; xAmount: Decimal; var Amount: Decimal; var AmountLCY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateAmounts(Rec, xRec, AmountLCY, IsHandled, Amount);
        if IsHandled then
            exit;

        if (xRec."Currency Factor" <> "Currency Factor") and
           (Amount = xAmount) and (JobExchCalculation = JobExchCalculation::"Fixed LCY")
        then begin
            Amount := ConvertAmountToFCY(AmountLCY, UnitAmountRoundingPrecisionFCY);
            exit;
        end;

        if (Amount <> xAmount) then
            AmountLCY := ConvertAmountToLCY(Amount, UnitAmountRoundingPrecision);
    end;

    local procedure ConvertAmountToFCY(AmountLCY: Decimal; Precision: Decimal) AmountFCY: Decimal;
    begin
        AmountFCY :=
            Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                    "Currency Date", "Currency Code", AmountLCY, "Currency Factor"),
                Precision);
    end;

    local procedure ConvertAmountToLCY(AmountFCY: Decimal; Precision: Decimal): Decimal;
    begin
        exit(ConvertAmountToLCY("Currency Date", AmountFCY, "Currency Factor", Precision));
    end;

    local procedure ConvertAmountToLCY(PostingDate: Date; AmountFCY: Decimal; CurrencyFactor: Decimal; Precision: Decimal) AmountLCY: Decimal;
    begin
        AmountLCY :=
            Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    PostingDate, "Currency Code", AmountFCY, CurrencyFactor),
                Precision);
    end;

    local procedure UpdateTotalPrice()
    begin
        "Total Price" := Round(Quantity * "Unit Price", AmountRoundingPrecisionFCY);
        "Total Price (LCY)" := ConvertAmountToLCY("Total Price", AmountRoundingPrecision);
        OnAfterUpdateTotalPrice(Rec);
    end;

    procedure UpdateAmountsAndDiscounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmountsAndDiscounts(Rec, xRec, IsHandled);
        if not IsHandled then begin
            // Patch for fixing Edit-in-Excel issues due to dependency on xRec.
            if not GuiAllowed() then
                if xRec.Get(xRec.RecordId()) then;

            if "Total Price" = 0 then begin
                "Line Amount" := 0;
                "Line Discount Amount" := 0;
            end else
                if ("Line Amount" <> xRec."Line Amount") and ("Line Discount Amount" = xRec."Line Discount Amount") then begin
                    "Line Amount" := Round("Line Amount", AmountRoundingPrecisionFCY);
                    "Line Discount Amount" := "Total Price" - "Line Amount";
                    "Line Discount %" :=
                      Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
                end else
                    if ("Line Discount Amount" <> xRec."Line Discount Amount") and ("Line Amount" = xRec."Line Amount") then begin
                        "Line Discount Amount" := Round("Line Discount Amount", AmountRoundingPrecisionFCY);
                        "Line Amount" := "Total Price" - "Line Discount Amount";
                        "Line Discount %" :=
                          Round("Line Discount Amount" / "Total Price" * 100, 0.00001);
                    end else
                        if ("Line Discount Amount" = xRec."Line Discount Amount") and
                           (("Line Amount" <> xRec."Line Amount") or ("Line Discount %" <> xRec."Line Discount %") or
                            ("Total Price" <> xRec."Total Price"))
                        then begin
                            "Line Discount Amount" :=
                              Round("Total Price" * "Line Discount %" / 100, AmountRoundingPrecisionFCY);
                            "Line Amount" := "Total Price" - "Line Discount Amount";
                        end;

            "Line Amount (LCY)" := ConvertAmountToLCY("Line Amount", AmountRoundingPrecision);
            "Line Discount Amount (LCY)" := ConvertAmountToLCY("Line Discount Amount", AmountRoundingPrecision);
        end;
        OnAfterUpdateAmountsAndDiscounts(Rec, xRec);
    end;

    procedure Use(PostedQty: Decimal; PostedTotalCost: Decimal; PostedLineAmount: Decimal; PostingDate: Date; CurrencyFactor: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions();
            // Update Quantity Posted
            Validate("Qty. Posted", "Qty. Posted" + PostedQty);

            // Update Posted Costs and Amounts.
            "Posted Total Cost" += Round(PostedTotalCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Posted Total Cost", CurrencyFactor, AmountRoundingPrecision);

            "Posted Line Amount" += Round(PostedLineAmount, AmountRoundingPrecisionFCY);
            "Posted Line Amount (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Posted Line Amount", CurrencyFactor, AmountRoundingPrecision);

            // Update Remaining Quantity
            UpdateRemainingQuantityFromUse(PostedQty);

            // Update Remaining Costs and Amounts
            UpdateRemainingCostsAndAmounts(PostingDate, CurrencyFactor);

            // Update Quantity to Post
            Validate("Qty. to Transfer to Journal", "Remaining Qty.");

            // Update Qty. Pick for location with optional warehouse pick.
            UpdateQtyPickedForOptionalWhsePick("Qty. Posted");

        end else
            ClearValues();

        OnUseOnBeforeModify(Rec, xRec, AmountRoundingPrecision, UnitAmountRoundingPrecision, AmountRoundingPrecisionFCY, UnitAmountRoundingPrecisionFCY);
        Modify(true);
    end;

    local procedure UpdateQtyPickedForOptionalWhsePick(QtyPosted: Decimal)
    begin
        GetLocation("Location Code");
        if Location."Job Consump. Whse. Handling" <> Location."Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            if ("Qty. Picked" < QtyPosted) then
                Validate("Qty. Picked", QtyPosted);
    end;

    local procedure UpdateRemainingQuantityFromUse(PostedQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingQuantityFromUse(Rec, xRec, PostedQty, IsHandled);
        if IsHandled then
            exit;

        if (PostedQty >= 0) = ("Remaining Qty." >= 0) then
            if Abs(PostedQty) <= Abs("Remaining Qty.") then
                Validate("Remaining Qty.", "Remaining Qty." - PostedQty)
            else begin
                Validate(Quantity, Quantity + PostedQty - "Remaining Qty.");
                Validate("Remaining Qty.", 0);
            end
        else
            Validate("Remaining Qty.", "Remaining Qty." - PostedQty);
    end;

    local procedure UpdateRemainingCostsAndAmounts(PostingDate: Date; CurrencyFactor: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingCostsAndAmounts(Rec, PostingDate, CurrencyFactor, AmountRoundingPrecisionFCY, AmountRoundingPrecision, IsHandled);
        if IsHandled then
            exit;

        if "Usage Link" then begin
            InitRoundingPrecisions();
            "Remaining Total Cost" := Round("Unit Cost" * "Remaining Qty.", AmountRoundingPrecisionFCY);
            "Remaining Total Cost (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Remaining Total Cost", CurrencyFactor, AmountRoundingPrecision);
            "Remaining Line Amount" := CalcLineAmount("Remaining Qty.");
            "Remaining Line Amount (LCY)" :=
                ConvertAmountToLCY(
                    PostingDate, "Remaining Line Amount", CurrencyFactor, AmountRoundingPrecision);
        end else
            ClearValues();
    end;

    local procedure UpdateRemainingQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingQuantity(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "Usage Link" then
            ControlUsageLink();
    end;

    procedure UpdateQtyToTransfer()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToTransfer(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Contract Line" then begin
            CalcFields("Qty. Transferred to Invoice");
            Validate("Qty. to Transfer to Invoice", Quantity - "Qty. Transferred to Invoice");
        end else
            Validate("Qty. to Transfer to Invoice", 0);
    end;

    procedure UpdateQtyToInvoice()
    begin
        if "Contract Line" then begin
            CalcFields("Qty. Invoiced");
            Validate("Qty. to Invoice", Quantity - "Qty. Invoiced")
        end else
            Validate("Qty. to Invoice", 0);
    end;

    procedure UpdatePostedTotalCost(AdjustJobCost: Decimal; AdjustJobCostLCY: Decimal)
    begin
        if "Usage Link" then begin
            InitRoundingPrecisions();
            "Posted Total Cost" += Round(AdjustJobCost, AmountRoundingPrecisionFCY);
            "Posted Total Cost (LCY)" += Round(AdjustJobCostLCY, AmountRoundingPrecision);
        end;
    end;

    procedure ValidateModification(FieldChanged: Boolean; FieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateModification(Rec, IsHandled, xRec, FieldNo);
        if IsHandled then
            exit;

        if FieldChanged then begin
            CalcFields("Qty. Transferred to Invoice");
            TestField("Qty. Transferred to Invoice", 0);
        end;

        OnAfterValidateModification(Rec, FieldChanged, FieldNo);
    end;

    local procedure CheckUsageLinkRelations()
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        JobUsageLink.SetRange("Job No.", "Job No.");
        JobUsageLink.SetRange("Job Task No.", "Job Task No.");
        JobUsageLink.SetRange("Line No.", "Line No.");
        if not JobUsageLink.IsEmpty() then
            Error(LinkedJobLedgerErr);
    end;

    local procedure ControlUsageLink()
    var
        JobUsageLink: Record "Job Usage Link";
        IsHandled: Boolean;
    begin
        GetJob();

        IsHandled := false;
        OnControlUsageLinkOnAfterGetJob(Rec, Job, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Job."Apply Usage Link" then begin
            if "Schedule Line" then
                "Usage Link" := true
            else
                "Usage Link" := false;
        end else
            if not "Schedule Line" then
                "Usage Link" := false;

        JobUsageLink.SetRange("Job No.", "Job No.");
        JobUsageLink.SetRange("Job Task No.", "Job Task No.");
        JobUsageLink.SetRange("Line No.", "Line No.");
        IsHandled := false;
        OnControlUsageLinkOnAfterSetFilterJobUsageLink(Rec, JobUsageLink, Job, CurrFieldNo, IsHandled);
        if not IsHandled then
            if not JobUsageLink.IsEmpty() and not "Usage Link" then
                Error(ControlUsageLinkErr, TableCaption(), FieldCaption("Schedule Line"), FieldCaption("Usage Link"));

        Validate("Remaining Qty.", Quantity - "Qty. Posted");
        Validate("Qty. to Transfer to Journal", Quantity - "Qty. Posted");
        UpdateRemainingCostsAndAmounts("Currency Date", "Currency Factor");

        UpdateQtyToTransfer();
        UpdateQtyToInvoice();

        OnAfterControlUsageLink(Rec, Job, CurrFieldNo);
    end;

    local procedure CalcLineAmount(Qty: Decimal): Decimal
    var
        TotalPrice: Decimal;
    begin
        InitRoundingPrecisions();
        TotalPrice := Round(Qty * "Unit Price", AmountRoundingPrecisionFCY);
        exit(TotalPrice - Round(TotalPrice * "Line Discount %" / 100, AmountRoundingPrecisionFCY));
    end;

    procedure Overdue(): Boolean
    begin
        if ("Planning Date" < WorkDate()) and ("Remaining Qty." > 0) then
            exit(true);
        exit(false);
    end;

    procedure SetBypassQtyValidation(Bypass: Boolean)
    begin
        BypassQtyValidation := Bypass;
    end;

    procedure UpdateReservation(CalledByFieldNo: Integer)
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReservation(Rec, xRec, CalledByFieldNo, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if (CurrFieldNo <> CalledByFieldNo) and (CurrFieldNo <> 0) then
            exit;

        case CalledByFieldNo of
            FieldNo("Planning Date"), FieldNo("Planned Delivery Date"):
                if (xRec."Planning Date" <> "Planning Date") and
                   (Quantity <> 0) and
                   (Reserve <> Reserve::Never)
                then
                    ReservationCheckDateConfl.JobPlanningLineCheck(Rec, true);
            FieldNo(Quantity):
                JobPlanningLineReserve.VerifyQuantity(Rec, xRec);
            FieldNo("Usage Link"):
                if (Type = Type::Item) and "Usage Link" then begin
                    GetItem();
                    if Item.Reserve = Item.Reserve::Optional then begin
                        GetJob();
                        Reserve := Job.Reserve
                    end else
                        Reserve := Item.Reserve;
                end else
                    Reserve := Reserve::Never;
        end;
        JobPlanningLineReserve.VerifyChange(Rec, xRec);
        UpdatePlanned();
    end;

    local procedure UpdateDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDescription(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if (xRec.Type = xRec.Type::Resource) and (xRec."No." <> '') then begin
            Res.Get(xRec."No.");
            if Description = Res.Name then
                Description := '';
            if "Description 2" = Res."Name 2" then
                "Description 2" := '';
        end;
    end;

    procedure ShowReservation()
    var
        Reservation: Page Reservation;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        TestField(Reserve);
        TestField("Usage Link");
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            Page.RunModal(Page::"Reservation Entries", ReservEntry)
        else
            Page.Run(Page::"Reservation Entries", ReservEntry);
    end;

    procedure AutoReserve()
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        TestField(Type, Type::Item);
        TestField("No.");
        if Reserve = Reserve::Never then
            FieldError(Reserve);
        JobPlanningLineReserve.ReservQuantity(Rec, QtyToReserve, QtyToReserveBase);
        if QtyToReserveBase <> 0 then begin
            TestField("Planning Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Planning Date", QtyToReserve, QtyToReserveBase);
            Find();
            if not FullAutoReservation then begin
                Commit();
                if Confirm(AutoReserveQst, true) then begin
                    Rec.ShowReservation();
                    Find();
                end;
            end;
            UpdatePlanned();
        end;
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Remaining Qty. (Base)", Rec."Planning Date", Rec."Planning Date");
        OrderTracking.RunModal();
    end;

    procedure ShowOrderPromisingLine()
    var
        OrderPromisingLine: Record "Order Promising Line";
        OrderPromisingLines: Page "Order Promising Lines";
    begin
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::Job);
        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::Job);
        OrderPromisingLine.SetRange("Source ID", "Job No.");
        OrderPromisingLine.SetRange("Source Line No.", "Job Contract Entry No.");

        OrderPromisingLines.SetSource(OrderPromisingLine."Source Type"::Job);
        OrderPromisingLines.SetTableView(OrderPromisingLine);
        OrderPromisingLines.RunModal();
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset();
        SetCurrentKey(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");
        SetRange(Status, Status::Order);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Planning Date", Item.GetFilter("Date Filter"));
        SetFilter("Remaining Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item2: Record Item): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeLinesWithItemToPlanExist(Item2, Result, IsHandled);
        if IsHandled then
            exit(Result);

        FilterLinesWithItemToPlan(Item2);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");
        SetRange(Status, NewStatus);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Planning Date", AvailabilityFilter);
        if Positive then
            SetFilter("Quantity (Base)", '<0')
        else
            SetFilter("Quantity (Base)", '>0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewStatus, AvailabilityFilter, Positive);
    end;

    procedure DrillDownJobInvoices()
    var
        JobInvoices: Page "Job Invoices";
    begin
        JobInvoices.SetShowDetails(false);
        JobInvoices.SetPrJobPlanningLine(Rec);
        JobInvoices.Run();
    end;

    local procedure CheckRelatedJobPlanningLineInvoice()
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRelatedJobPlanningLineInvoice(Rec, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLineInvoice.SetRange("Job No.", "Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", "Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", "Line No.");
        if not JobPlanningLineInvoice.IsEmpty() then
            Error(NotPossibleJobPlanningLineErr);
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::"Job Planning Line", Status.AsInteger(),
            "Job No.", '', 0, "Job Contract Entry No."));
    end;

    internal procedure RowID2(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::Job, 0, "Job No.", '', 0, "Job Contract Entry No."));
    end;

    procedure UpdatePlanned(): Boolean
    begin
        CalcFields("Reserved Quantity");
        if Planned = ("Reserved Quantity" = "Remaining Qty.") then
            exit(false);
        Planned := not Planned;
        exit(true);
    end;

    procedure UpdatePlannedDueDate() Changed: Boolean;
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DueDateCalculation: DateFormula;
        xPlanningDueDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePlannedDueDate(Rec, Changed, IsHandled);
        if IsHandled then
            exit(Changed);

        xPlanningDueDate := "Planning Due Date";
        if "Planning Date" = 0D then
            exit(false);
        "Planning Due Date" := "Planning Date";
        GetJob();
        if Job."No." = '' then
            exit(false);
        Customer.SetLoadFields("Payment Terms Code");
        if not Customer.Get(Job."Bill-to Customer No.") then
            exit(false);
        PaymentTerms.SetLoadFields("Due Date Calculation");
        if PaymentTerms.Get(Customer."Payment Terms Code") then begin
            PaymentTerms.GetDueDateCalculation(DueDateCalculation);
            "Planning Due Date" := CalcDate(DueDateCalculation, "Planning Date");
        end;
        exit("Planning Due Date" <> xPlanningDueDate);
    end;

    procedure ClearValues()
    begin
        Validate("Remaining Qty.", 0);
        "Remaining Total Cost" := 0;
        "Remaining Total Cost (LCY)" := 0;
        "Remaining Line Amount" := 0;
        "Remaining Line Amount (LCY)" := 0;
        Validate("Qty. Posted", 0);
        Validate("Qty. to Transfer to Journal", 0);
        "Posted Total Cost" := 0;
        "Posted Total Cost (LCY)" := 0;
        "Posted Line Amount" := 0;
        "Posted Line Amount (LCY)" := 0;

        OnAfterClearValues(Rec);
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';

        OnAfterClearTracking(Rec);
    end;

    procedure InitFromJobPlanningLine(FromJobPlanningLine: Record "Job Planning Line"; NewQuantity: Decimal)
    var
        ToJobPlanningLine: Record "Job Planning Line";
        JobJnlManagement: Codeunit JobJnlManagement;
    begin
        ToJobPlanningLine := Rec;

        ToJobPlanningLine.Init();
        ToJobPlanningLine.TransferFields(FromJobPlanningLine);
        ToJobPlanningLine."Line No." := GetNextJobLineNo(FromJobPlanningLine);
        ToJobPlanningLine.Validate("Line Type", "Line Type"::Billable);
        ToJobPlanningLine.ClearValues();
        ToJobPlanningLine."Job Contract Entry No." := JobJnlManagement.GetNextEntryNo();
        if ToJobPlanningLine.Type <> ToJobPlanningLine.Type::Text then begin
            ToJobPlanningLine.Validate(Quantity, NewQuantity);
            ToJobPlanningLine.Validate("Currency Code", FromJobPlanningLine."Currency Code");
            ToJobPlanningLine.Validate("Currency Date", FromJobPlanningLine."Currency Date");
            ToJobPlanningLine.Validate("Currency Factor", FromJobPlanningLine."Currency Factor");
            ToJobPlanningLine.Validate("Unit Cost", FromJobPlanningLine."Unit Cost");
            ToJobPlanningLine.Validate("Unit Price", FromJobPlanningLine."Unit Price");
            if FromJobPlanningLine."Line Discount %" <> 0 then
                ToJobPlanningLine.Validate("Line Discount %", FromJobPlanningLine."Line Discount %");
        end;

        OnAfterInitFromJobPlanningLine(ToJobPlanningLine, FromJobPlanningLine);
        Rec := ToJobPlanningLine;
    end;

    protected procedure GetNextJobLineNo(FromJobPlanningLine: Record "Job Planning Line"): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", FromJobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", FromJobPlanningLine."Job Task No.");
        if JobPlanningLine.FindLast() then;
        exit(JobPlanningLine."Line No." + 10000);
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

    procedure IsNonInventoriableItem(): Boolean
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        GetItem();
        exit(Item.IsNonInventoriableType());
    end;

    procedure ConvertToJobLineType() JobLineType: Enum "Job Line Type"
    begin
        JobLineType := Enum::"Job Line Type".FromInteger("Line Type".AsInteger() + 1);

        OnAfterConvertToJobLineType(Rec, JobLineType);
    end;

    procedure ConvertFromJobLineType(JobLineType: Enum "Job Line Type") JobPlanningLineLineType: Enum "Job Planning Line Line Type"
    begin
        JobPlanningLineLineType := Enum::"Job Planning Line Line Type".FromInteger(JobLineType.AsInteger() - 1);

        OnAfterConvertFromJobLineType(Rec, JobLineType, JobPlanningLineLineType);
    end;

    procedure CopyTrackingFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Serial No." := JobJnlLine."Serial No.";
        "Lot No." := JobJnlLine."Lot No.";

        OnAfterCopyTrackingFromJobJnlLine(Rec, JobJnlLine);
    end;

    procedure CopyTrackingFromJobLedgEntry(JobLedgEntry: Record "Job Ledger Entry")
    begin
        "Serial No." := JobLedgEntry."Serial No.";
        "Lot No." := JobLedgEntry."Lot No.";

        OnAfterCopyTrackingFromJobLedgEntry(Rec, JobLedgEntry);
    end;

    local procedure SetDefaultBin()
    begin
        if (Rec."No." <> '') then begin
            GetItem();
            if Item.IsInventoriableType() then
                Validate("Bin Code", FindBin());
        end;
    end;

    local procedure FindBin() NewBinCode: Code[20]
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBin(Rec, NewBinCode, IsHandled);
        if IsHandled then
            exit(NewBinCode);

        if (Rec."No." <> '') and (Rec."Location Code" <> '') then begin
            if FindBinFromJobTask(NewBinCode) then
                exit(NewBinCode);
            GetLocation(Rec."Location Code");
            if Location."To-Job Bin Code" <> '' then
                NewBinCode := Location."To-Job Bin Code"
            else
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    WMSManagement.GetDefaultBin(Rec."No.", Rec."Variant Code", Rec."Location Code", NewBinCode);
        end;
    end;

    local procedure FindBinFromJobTask(var NewBinCode: Code[20]): Boolean
    begin
        JobTask.SetLoadFields("Location Code", "Bin Code");
        if not JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            exit(false);

        if ("Location Code" = JobTask."Location Code") and (JobTask."Bin Code" <> '') then begin
            NewBinCode := JobTask."Bin Code";
            exit(true);
        end;
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure DeleteWarehouseRequest(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLine2: Record "Job Planning Line";
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        JobPlanningLine2.SetFilter("Job Contract Entry No.", '<>%1', JobPlanningLine."Job Contract Entry No.");
        JobPlanningLine2.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine2.SetRange("Location Code", JobPlanningLine."Location Code");

        if JobPlanningLine2.IsEmpty() then
            if WarehouseRequest.Get(Enum::"Warehouse Request Type"::Outbound, JobPlanningLine."Location Code", Database::Job, 0, JobPlanningLine."Job No.") then
                WarehouseRequest.Delete(true)
            else
                if WhsePickRequest.Get(WhsePickRequest."Document Type"::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Location Code") then
                    WhsePickRequest.Delete(true);
    end;

    internal procedure CreateWarehouseRequest()
    var
        WhsePickRequest: Record "Whse. Pick Request";
        WarehouseRequest: Record "Warehouse Request";
    begin
        if Rec."Location Code" = '' then
            exit;

        GetLocation(Rec."Location Code");

        case Location."Job Consump. Whse. Handling" of
            Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)",
            Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (optional)":
                if not WhsePickRequest.Get(WhsePickRequest."Document Type"::Job, 0, Rec."Job No.", Rec."Location Code") then begin
                    WhsePickRequest.Init();
                    WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Job;
                    WhsePickRequest."Document Subtype" := 0;
                    WhsePickRequest."Document No." := Rec."Job No.";
                    WhsePickRequest.Status := WhsePickRequest.Status::Released;
                    WhsePickRequest."Location Code" := Location.Code;
                    if WhsePickRequest.Insert() then;
                end;
            Enum::"Job Consump. Whse. Handling"::"Inventory Pick":
                if not GetWarehouseRequest(WarehouseRequest) then begin
                    WarehouseRequest.Init();
                    WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
                    WarehouseRequest."Location Code" := Rec."Location Code";
                    WarehouseRequest."Source Type" := Database::Job;
                    WarehouseRequest."Source No." := Rec."Job No.";
                    WarehouseRequest."Source Subtype" := 0;
                    WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Job Usage";
                    WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
                    if WarehouseRequest.Insert() then;
                end;
        end;
    end;

    local procedure GetWarehouseRequest(var WarehouseRequest: Record "Warehouse Request"): Boolean
    begin
        if WarehouseRequest.Get(WarehouseRequest.Type::Outbound, Rec."Location Code", Database::Job, 0, Rec."Job No.") then
            if (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Job Usage") and (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released) then
                exit(true);
    end;

    procedure TestStatusOpen()
    begin
        TestField(Status, Status::Order);
        GetJob();
        Job.TestField(Status, Job.Status::Open);
    end;

    procedure CheckIfJobPlngLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if not Rec.IsInventoriableItem() then
            exit(true);

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := JobPlanningLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfJobPlngLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    procedure IsAsmToOrderAllowed() Result: Boolean
    begin
        Result := true;

        if Quantity < 0 then
            Result := false;
        if Type <> Type::Item then
            Result := false;
        if "No." = '' then
            Result := false;
        if "Line Type" = "Line Type"::Billable then
            Result := false;
    end;

    procedure QtyToAsmBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Quantity to Assemble (Base)");
        exit(0);
    end;

    procedure ShowAsmToJobPlanningLines()
    begin
        ATOLink.ShowAsmToJobPlanningLines(Rec);
    end;

    procedure CheckAsmToOrder(AsmHeader: Record "Assembly Header")
    begin
        TestField("Qty. to Assemble", AsmHeader.Quantity);
        TestField(Type, Type::Item);
        TestField("No.", AsmHeader."Item No.");
        TestField("Location Code", AsmHeader."Location Code");
        TestField("Unit of Measure Code", AsmHeader."Unit of Measure Code");
        TestField("Variant Code", AsmHeader."Variant Code");
        GetJob();
        if Job.Status = Job.Status::Open then begin
            AsmHeader.CalcFields("Reserved Qty. (Base)");
            AsmHeader.TestField("Reserved Qty. (Base)", AsmHeader."Remaining Quantity (Base)");
        end;
        TestField("Qty. to Assemble (Base)", AsmHeader."Quantity (Base)");
        if "Remaining Qty. (Base)" < AsmHeader."Remaining Quantity (Base)" then
            AsmHeader.FieldError("Remaining Quantity (Base)", StrSubstNo(CannotBeMoreErr, "Remaining Qty. (Base)"));
    end;

    procedure AsmToOrderExists(var AsmHeader: Record "Assembly Header"): Boolean
    begin
        if not ATOLink.AsmExistsForJobPlanningLine(Rec) then
            exit(false);
        exit(AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No."));
    end;

    protected procedure InitQtyToAsm()
    var
        Qty, QtyBase : Decimal;
    begin
        if not IsAsmToOrderAllowed() then begin
            "Qty. to Assemble" := 0;
            "Qty. to Assemble (Base)" := 0;
            exit;
        end;

        if ((xRec."Qty. to Assemble (Base)" = 0) and IsAsmToOrderRequired()) or
           ((xRec."Qty. to Assemble (Base)" <> 0) and (xRec."Qty. to Assemble (Base)" = xRec."Quantity (Base)")) or
           ("Qty. to Assemble (Base)" > "Quantity (Base)")
        then begin
            Qty := 0;
            QtyBase := 0;
            AssembledQuantity(Qty, QtyBase);
            "Qty. to Assemble" := Quantity - Qty;
            "Qty. to Assemble (Base)" := "Quantity (Base)" - QtyBase;
        end;
    end;

    procedure AssembledQuantity(var Qty: Decimal; var QtyBase: Decimal)
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        PostedATOLink.SetCurrentKey("Job No.", "Job Task No.", "Document Line No.");
        PostedATOLink.SetRange("Job No.", Rec."Job No.");
        PostedATOLink.SetRange("Job Task No.", Rec."Job Task No.");
        PostedATOLink.SetRange("Document Line No.", Rec."Line No.");
        if PostedATOLink.FindSet() then
            repeat
                Qty += PostedATOLink."Assembled Quantity";
                QtyBase += PostedATOLink."Assembled Quantity (Base)";
            until PostedATOLink.Next() = 0;
    end;

    procedure IsAsmToOrderRequired(): Boolean
    begin
        if (Type <> Type::Item) or ("No." = '') then
            exit(false);
        GetItem();
        if GetSKU() then
            exit(SKU."Assembly Policy" = SKU."Assembly Policy"::"Assemble-to-Order");
        exit(Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order");
    end;

    procedure SelectMultipleItems()
    var
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
    begin
        OnBeforeSelectMultipleItems(Rec);

        SelectionFilter := ItemListPage.SelectActiveItems();

        if SelectionFilter <> '' then
            AddItems(SelectionFilter);

        OnAfterSelectMultipleItems(Rec);
    end;

    local procedure AddItems(SelectionFilter: Text)
    var
        Item: Record "Item";
        NewJobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        InitNewLine(NewJobPlanningLine);
        Item.SetLoadFields("No.");
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet() then
            repeat
                AddItem(NewJobPlanningLine, Item."No.");
            until Item.Next() = 0;
    end;

    procedure GetATOBin(Location: Record Location; var BinCode: Code[20]) Result: Boolean
    var
        AsmHeader: Record "Assembly Header";
    begin
        if not Location."Require Shipment" then
            BinCode := Location."Asm.-to-Order Shpt. Bin Code";
        if BinCode <> '' then
            exit(true);

        if AsmHeader.GetFromAssemblyBin(Location, BinCode) then
            exit(true);

        exit(false);
    end;

    local procedure AddItem(var NewJobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        NewJobPlanningLine."Line No." += 10000;
        NewJobPlanningLine.Validate(Type, NewJobPlanningLine.Type::Item);
        NewJobPlanningLine.Validate("No.", ItemNo);
        NewJobPlanningLine.Insert(true);

        if TransferExtendedText.JobCheckIfAnyExtText(NewJobPlanningLine, false) then
            TransferExtendedText.InsertJobExtText(NewJobPlanningLine);
    end;

    local procedure InitNewLine(var NewJobPlanningLine: Record "Job Planning Line")
    var
        ExistingJobPlanningLine: Record "Job Planning Line";
    begin
        NewJobPlanningLine.Copy(Rec);
        ExistingJobPlanningLine.SetRange("Job No.", NewJobPlanningLine."Job No.");
        ExistingJobPlanningLine.SetRange("Job Task No.", NewJobPlanningLine."Job Task No.");
        if ExistingJobPlanningLine.FindLast() then
            NewJobPlanningLine."Line No." := ExistingJobPlanningLine."Line No."
        else
            NewJobPlanningLine."Line No." := 0;
    end;

    procedure IsExtendedText(): Boolean
    begin
        exit((Type = Type::Text) and ("Attached to Line No." <> 0) and (Quantity = 0));
    end;

    local procedure WhsePickReqForLocation(): Boolean
    begin
        if Rec."Location Code" = '' then
            exit(false);

        GetLocation(Rec."Location Code");
        if Location."Job Consump. Whse. Handling" = Enum::"Job Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            exit(true);
    end;

    local procedure InitLocation()
    begin
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") and (JobTask."Location Code" <> '') then
            Validate("Location Code", JobTask."Location Code");
    end;

    procedure SetSkipCheckForMultipleJobsOnSalesLine(Skip: Boolean)
    begin
        SkipCheckForMultipleJobsOnSalesLine := Skip;
    end;

    procedure GetSkipCheckForMultipleJobsOnSalesLine(): Boolean
    begin
        exit(SkipCheckForMultipleJobsOnSalesLine);
    end;

    local procedure ConfirmDeletion()
    begin
        if CalledFromHeader then
            exit;

        if "Qty. Posted" < "Qty. Picked" then begin
            if "Location Code" <> '' then begin
                GetLocation("Location Code");
                if Location."Job Consump. Whse. Handling" = Location."Job Consump. Whse. Handling"::"No Warehouse Handling" then
                    exit;
            end;

            if not Confirm(
                StrSubstNo(
                    ConfirmDeleteQst,
                    FieldCaption("Qty. Picked"),
                    "Qty. Picked",
                    FieldCaption("Qty. Posted"),
                    "Qty. Posted",
                    TableCaption),
                false)
            then
                Error('');
        end;
    end;

    procedure SuspendDeletionCheck(Suspend: Boolean)
    begin
        CalledFromHeader := Suspend;
    end;

    procedure SetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetCurrentKey("Document Type", "Job No.", "Job Task No.", "Job Planning Line No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Job No.", "Job No.");
        PurchaseLine.SetRange("Job Task No.", "Job Task No.");
        PurchaseLine.SetRange("Job Planning Line No.", "Line No.");
    end;

    local procedure PreventDeleteIfPurchaseExists(var JobPlanningLine: Record "Job Planning Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Check if any Purchase Receipt Line exists for this Project Planning Line
        PurchRcptLine.SetLoadFields("Document No.");
        PurchRcptLine.SetCurrentKey("Job No.", "Job Task No.", "Job Planning Line No.");
        PurchRcptLine.SetRange("Job No.", JobPlanningLine."Job No.");
        PurchRcptLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        PurchRcptLine.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        if PurchRcptLine.FindFirst() then
            Error(PurchRcptLineExistErr, PurchRcptLine."Document No.");
    end;

    local procedure FindOrCreateRecordByNo(SourceNo: Code[20]): Code[20]
    var
        Item2: Record Item;
        FindRecordManagement: Codeunit "Find Record Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindOrCreateRecordByNo(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit("No.");

        if (SourceNo = '') then
            exit('');
        if Type = Type::Item then
            exit(Item2.GetFirstItemNoFromLookup(SourceNo))
        else
            exit(FindRecordManagement.FindNoFromTypedValue(GetType(Type), "No.", false));

        exit(SourceNo);
    end;

    local procedure GetType(JobPlanningLineType: Enum "Job Planning Line Type") Result: Integer
    begin
        case JobPlanningLineType of
            JobPlanningLineType::Text:
                exit(0);
            JobPlanningLineType::"G/L Account":
                exit(1);
            JobPlanningLineType::Item:
                exit(2);
            JobPlanningLineType::Resource:
                exit(3);
            else
                OnGetType(JobPlanningLineType, Result);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateRetrievedCost(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; var RetrievedCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGLAccount(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFieldsFromJob(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobJnlLine(var JobPlanningLine: Record "Job Planning Line"; JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertToJobLineType(var JobPlanningLine: Record "Job Planning Line"; var JobLineType: Enum "Job Line Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertFromJobLineType(var JobPlanningLine: Record "Job Planning Line"; var JobLineType: Enum "Job Line Type"; var JobPlanningLineLineType: Enum "Job Planning Line Line Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobLedgEntry(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAmounts(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetJob(var JobPlanningLine: Record "Job Planning Line"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(JobPlanningLine: Record "Job Planning Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemainingQty(JobPlanningLine: Record "Job Planning Line"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var JobPlanningLine: Record "Job Planning Line"; var Item: Record Item);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFilterLinesForReservation(var JobPlaningLine: Record "Job Planning Line"; ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleCostFactor(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitJobPlanningLine(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var ToJobPlanningLine: Record "Job Planning Line"; FromJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResourceFindCost(var JobPlanningLine: Record "Job Planning Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var JobPlanningLine: Record "Job Planning Line"; LastJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCurrencyFactor(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalPrice(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var AmountRoundingPrecision: Decimal; var AmountRoundingPrecisionFCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsAndDiscounts(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateModification(var JobPlanningLine: Record "Job Planning Line"; FieldChanged: Boolean; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQuantityBase(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantityPosted(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRelatedJobPlanningLineInvoice(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromResource(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Event no longer used as procedure EnsureDirectedPutawayandPickFalse is deleted.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureDirectedPutawayandPickFalse(var JobPlanningLine: Record "Job Planning Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFindPriceAndDiscount(CalledByFieldNo: Integer; var IsHandled: Boolean; var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCostFactor(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRoundingPrecisions(JobPlanningLine: Record "Job Planning Line"; var AmountRoundingPrecision: Decimal; var UnitAmountRoundingPrecision: Decimal; var AmountRoundingPrecisionFCY: Decimal; var UnitAmountRoundingPrecisionFCY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var AmountLCY: Decimal; var IsHandled: Boolean; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePlannedDueDate(var JobPlanningLine: Record "Job Planning Line"; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmountsAndDiscounts(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDescription(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateModification(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; xJobPlanningLine: Record "Job Planning Line"; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePlanningDate(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWorkTypeCode(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPrice(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var ShouldRetrieveCostPrice: Boolean; var IsHandled: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingQuantity(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingQuantityFromUse(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; PostedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllAmounts(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; xJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReservation(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToTransferToInvoice(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnControlUsageLinkOnAfterGetJob(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; CallingFieldNo: Integer; var IsHandling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCurrencyFactorOnBeforeGetExchangeRate(JobPlanningLine: Record "Job Planning Line"; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUseOnBeforeModify(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; AmountRoundingPrecision: Decimal; UnitAmountRoundingPrecision: Decimal; AmountRoundingPrecisionFCY: Decimal; UnitAmountRoundingPrecisionFCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterCopyFromAccount(var JobPlanningLine: Record "Job Planning Line"; var xJobPlanningLine: Record "Job Planning Line"; var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLinesWithItemToPlanExist(var Item: Record Item; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUsageLink(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetFilterOnJobUsageLink(JobPlanningLine: Record "Job Planning Line"; var JobUsageLink: Record "Job Usage Link"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRename(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnControlUsageLinkOnAfterSetFilterJobUsageLink(var JobPlanningLine: Record "Job Planning Line"; var JobUsageLink: Record "Job Usage Link"; Job: Record Job; CallingFieldNo: Integer; var IsHandling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBin(var JobPlanningLine: Record "Job Planning Line"; var NewBinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindPriceAndDiscount(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfJobPlngLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingCostsAndAmounts(var JobPlanningLine: Record "Job Planning Line"; PostingDate: Date; CurrencyFactor: Decimal; AmountRoundingPrecisionFCY: Decimal; AmountRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalCost(var JobPlanningLine: Record "Job Planning Line"; AmountRoundingPrecisionFCY: Decimal; AmountRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearValues(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterControlUsageLink(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyFromGLAccount(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleItems(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleItems(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var JobPlanningLine: Record "Job Planning Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromResource(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToTransfer(var JobPlanningLine: Record "Job Planning Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; var SkipValidateQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOrCreateRecordByNo(var JobPlanningLine: Record "Job Planning Line"; xJobPlanningLine: Record "Job Planning Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetType(JobPlanningLineType: Enum "Job Planning Line Type"; var Result: Integer)
    begin
    end;
}
