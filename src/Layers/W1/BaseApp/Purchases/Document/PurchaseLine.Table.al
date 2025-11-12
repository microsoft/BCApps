// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Utilities;
using System.Environment.Configuration;

table 39 "Purchase Line"
{
    Caption = 'Purchase Line';
    DrillDownPageID = "Purchase Lines";
    LookupPageID = "Purchase Lines";
    Permissions = TableData "Purchase Line" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Purchase Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of document that you are about to create.';
        }
        field(2; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            ToolTip = 'Specifies the name of the vendor who delivered the items.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Purchase Header"."No." where("Document Type" = field("Document Type"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line''s number.';
        }
        field(5; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the line type.';

            trigger OnValidate()
            var
                TempPurchLine: Record "Purchase Line" temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateType(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetPurchHeader();
                TestStatusOpen();

                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Quantity Received", 0);
                TestField("Receipt No.", '');

                TestField("Return Qty. Shipped Not Invd.", 0);
                TestField("Return Qty. Shipped", 0);
                TestField("Return Shipment No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                CheckAssociatedSalesOrder();
                CheckAssociatedProdOrder();

                if Type <> xRec.Type then begin
                    case xRec.Type of
                        Type::Item:
                            if Quantity <> 0 then begin
                                PurchHeader.TestField(Status, PurchHeader.Status::Open);
                                PurchLineReserve.VerifyChange(Rec, xRec);
                                CalcFields("Reserved Qty. (Base)");
                                TestField("Reserved Qty. (Base)", 0);
                                PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                                OnValidateTypeOnAfterCheckItem(Rec, xRec);
                            end;
                        Type::"Fixed Asset":
                            if Quantity <> 0 then
                                PurchHeader.TestField(Status, PurchHeader.Status::Open);
                        Type::"Charge (Item)":
                            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                        Type::" ":
                            if ("Attached to Line No." <> 0) and (Quantity = 0) then
                                Error(ChangeExtendedTextErr, FieldCaption(Type));
                    end;
                    if xRec."Deferral Code" <> '' then
                        DeferralUtilities.RemoveOrSetDeferralSchedule('',
                          Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
                          xRec."Document Type".AsInteger(), xRec."Document No.", xRec."Line No.",
                          xRec.GetDeferralAmount(), PurchHeader."Posting Date", '', xRec."Currency Code", true);
                end;
                OnValidateTypeOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempPurchLine := Rec;
                Init();
                SystemId := TempPurchLine.SystemId;

                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := xRec."Allow Invoice Disc.";

                Type := TempPurchLine.Type;
                "System-Created Entry" := TempPurchLine."System-Created Entry";
                OnValidateTypeOnCopyFromTempPurchLine(Rec, TempPurchLine, xRec);
                Validate("FA Posting Type");

                if Type = Type::Item then
                    "Allow Item Charge Assignment" := true
                else
                    "Allow Item Charge Assignment" := false;

                OnAfterValidateTypePurchaseLine(Rec, xRec, TempPurchLine);
            end;
        }
        field(6; "No."; Code[20])
        {
            CaptionClass = GetCaptionClass(FieldNo("No."));
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            ValidateTableRelation = false;
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(false)) "G/L Account" where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(true)) "G/L Account"
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Allocation Account")) "Allocation Account"
            else
            if (Type = const(Resource)) Resource;

            trigger OnValidate()
            var
                TempPurchLine: Record "Purchase Line" temporary;
                IsHandled: Boolean;
                ShouldAssignQuantityFromXRec: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetPurchSetup();
                Rec."No." := FindOrCreateRecordByNo(Rec."No.");

                TestStatusOpen();
                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Quantity Received", 0);

                IsHandled := false;
                OnValidateNoOnBeforeCheckReceiptNo(Rec, xRec, IsHandled);
                if not IsHandled then
                    TestField("Receipt No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                TestReturnFieldsZero();

                CheckAssociatedSalesOrder();
                CheckAssociatedProdOrder();

                OnValidateNoOnAfterChecks(Rec, xRec, CurrFieldNo);

                if "No." <> xRec."No." then begin
                    if (Quantity <> 0) and ItemExists(xRec."No.") then begin
                        PurchLineReserve.VerifyChange(Rec, xRec);
                        CalcFields("Reserved Qty. (Base)");
                        TestField("Reserved Qty. (Base)", 0);
                        if Type = Type::Item then
                            PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                        OnValidateNoOnAfterVerifyChange(Rec, xRec);
                        if CurrFieldNo = Rec.FieldNo("No.") then
                            CheckWarehouse(false);
                    end;
                    if Type = Type::Item then
                        DeleteItemChargeAssignment("Document Type", "Document No.", "Line No.");
                    if Type = Type::"Charge (Item)" then
                        DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                end;

                OnValidateNoOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempPurchLine := Rec;
                Init();
                SystemId := TempPurchLine.SystemId;
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := xRec."Allow Invoice Disc.";
                Type := TempPurchLine.Type;
                "No." := TempPurchLine."No.";
                IsHandled := false;
                OnValidateNoOnCopyFromTempPurchLine(Rec, TempPurchLine, xRec, IsHandled);
                if IsHandled then
                    exit;
                if "No." = '' then
                    exit;

                if HasTypeToFillMandatoryFields() then begin
                    Quantity := TempPurchLine.Quantity;
                    "Outstanding Qty. (Base)" := TempPurchLine."Outstanding Qty. (Base)";
                end;

                "System-Created Entry" := TempPurchLine."System-Created Entry";

                OnBeforeAssignHeaderValues(Rec, PurchHeader);

                GetPurchHeader();
                InitHeaderDefaults(PurchHeader, TempPurchLine);
                UpdateLeadTimeFields();
                UpdateDates();

                OnAfterAssignHeaderValues(Rec, PurchHeader);

                case Type of
                    Type::" ":
                        CopyFromStandardText();
                    Type::"G/L Account":
                        CopyFromGLAccount(TempPurchLine);
                    Type::Item:
                        CopyFromItem();
                    Type::Resource:
                        CopyFromResource();
                    Type::"Fixed Asset":
                        CopyFromFixedAsset();
                    Type::"Charge (Item)":
                        CopyFromItemCharge();
                end;

                OnAfterAssignFieldsForNo(Rec, xRec, PurchHeader);

                if Type <> Type::" " then begin
                    PostingSetupMgt.CheckGenPostingSetupPurchAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    PostingSetupMgt.CheckVATPostingSetupPurchAccount("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                end;

                IsHandled := false;
                OnBeforeValidateVATProdPostingGroup(Rec, xRec, IsHandled);
                if not IsHandled then
                    if HasTypeToFillMandatoryFields() and not (Type = Type::"Fixed Asset") then
                        Validate("VAT Prod. Posting Group");

                UpdatePrepmtSetupFields();

                if HasTypeToFillMandatoryFields() then begin
                    PlanPriceCalcByField(FieldNo("No."));
                    IsHandled := false;
                    OnValidateNoOnBeforeAssignQtyFromXRec(Rec, xRec, IsHandled);
                    ShouldAssignQuantityFromXRec := (not IsHandled) and (not QuantityDefaultedFromGLAccount());
                    if ShouldAssignQuantityFromXRec then
                        Quantity := xRec.Quantity;
                    OnValidateNoOnAfterAssignQtyFromXRec(Rec, TempPurchLine);
                    Validate("Unit of Measure Code");
                    InitOutstandingAndQtyToShipReceive(TempPurchLine);
                    UpdateWithWarehouseReceive();
                    UpdateJobFields();
                end;

                CreateDimFromDefaultDim(Rec.FieldNo("No."));

                GetPurchHeader();
                UpdateItemReference();
                UpdateDirectUnitCostByField(FieldNo("No."));

                GetDefaultBin();

                IsHandled := false;
                OnValidateNoOnBeforeJobTaskIsSet(PurchHeader, Rec, xRec, TempPurchLine, IsHandled);
                if not IsHandled then
                    if JobTaskIsSet() then begin
                        CreateTempJobJnlLine(true);
                        UpdateJobPrices();
                        UpdateDimensionsFromJobTask();
                    end;

                OnAfterValidateNoPurchaseLine(Rec, xRec, TempPurchLine, PurchHeader);
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies the code for the location where the items on the line will be located.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled, ShouldExit : Boolean;
            begin
                TestStatusOpen();
                IsHandled := false;
                ShouldExit := false;
                OnValidateLocationCodeOnAfterTestStatusOpen(Rec, xRec, IsHandled, ShouldExit);
                if ShouldExit then
                    exit;

                if xRec."Location Code" <> "Location Code" then begin
                    if ("Prepmt. Amt. Inv." <> 0) and (not IsHandled) then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text046, FieldCaption("Direct Unit Cost"), FieldCaption("Location Code"), PRODUCTNAME.Full()), true)
                        then begin
                            "Location Code" := xRec."Location Code";
                            exit;
                        end;
                    CheckLineNotShippedOrReceived();
                end;

                IsHandled := false;
                OnValidateLocationCodeOnBeforeDropShipmentError(Rec, IsHandled, xRec);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Location Code"), "Sales Order No.");

                IsHandled := false;
                OnValidateLocationCodeOnBeforeSpecialOrderError(Rec, IsHandled, CurrFieldNo, xRec);
                if not IsHandled then
                    if "Special Order" then
                        Error(Text001, FieldCaption("Location Code"), "Special Order Sales No.");

                if "Location Code" <> xRec."Location Code" then begin
                    InitItemAppl();
                    if IsInventoriableItem() then
                        PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");
                end;

                if (xRec."Location Code" <> "Location Code") and (Quantity <> 0) then begin
                    PurchLineReserve.VerifyChange(Rec, xRec);
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                    UpdateWithWarehouseReceive();
                end;
                "Bin Code" := '';

                if Type = Type::Item then
                    if "Location Code" <> xRec."Location Code" then
                        PlanPriceCalcByField(FieldNo("Location Code"));

                IsHandled := false;
                OnValidateLocationCodeOnBeforeSetInboundWhseHandlingTime(CurrFieldNo, Rec, xRec, IsHandled);
                if not IsHandled then
                    if "Location Code" = '' then begin
                        if InvtSetup.Get() then
                            "Inbound Whse. Handling Time" := InvtSetup."Inbound Whse. Handling Time";
                    end else
                        if Location.Get("Location Code") then
                            "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";

                UpdateLeadTimeFields();
                UpdateDates();

                GetDefaultBin();
                CheckWMS();

                if "Document Type" = "Document Type"::"Return Order" then
                    ValidateReturnReasonCode(FieldNo("Location Code"));

                UpdateDirectUnitCostByField(FieldNo("Location Code"));
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
                OnAfterValidateLocationCode(Rec, xRec);
            end;
        }
        field(8; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if (Type = const(Item)) "Inventory Posting Group"
            else
            if (Type = const("Fixed Asset")) "FA Posting Group";
        }
        field(10; "Expected Receipt Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date that you expect the items to be available in your warehouse.';

            trigger OnValidate()
            var
                CustomCalendarChange: array[2] of Record "Customized Calendar Change";
                IsHandled: Boolean;
            begin
                if not TrackingBlocked then begin
                    IsHandled := false;
                    OnValidateExpectedReceiptDateOnBeforeCheckDateConflict(Rec, IsHandled);
                    if not IsHandled then
                        CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
                end;

                if "Expected Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    ValidatePlannedReceiptDateWithCustomCalendarChange(CustomCalendarChange);
                end else
                    Validate("Planned Receipt Date", "Expected Receipt Date");
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry of the product to be purchased. To add a non-transactional text line, fill in the Description field only.';
            TableRelation = if (Type = const("G/L Account"), "System-Created Entry" = const(false)) "G/L Account".Name where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(true)) "G/L Account".Name
            else
            if (Type = const(Item)) Item.Description
            else
            if (Type = const("Fixed Asset")) "Fixed Asset".Description
            else
            if (Type = const("Charge (Item)")) "Item Charge".Description
            else
            if (Type = const("Allocation Account")) "Allocation Account".Name
            else
            if (Type = const(Resource)) Resource.Name;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                FindRecordMgt: Codeunit "Find Record Management";
                ReturnValue: Text[50];
                IsHandled: Boolean;
                ShouldErrorForFindDescription: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Type = Type::" " then
                    exit;

                if "No." <> '' then
                    exit;

                case Type of
                    Type::Item:
                        ValidateItemDescription();
                    else begin
                        ReturnValue := FindRecordMgt.FindNoByDescription(Type.AsInteger(), Description, true);
                        if ReturnValue <> '' then begin
                            CurrFieldNo := FieldNo("No.");
                            Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen("No.")));
                        end;
                    end;
                end;

                ShouldErrorForFindDescription := ("No." = '') and GuiAllowed();
                OnValidateDescriptionOnAfterCalcShouldErrorForFindDescription(Rec, xRec, ShouldErrorForFindDescription);
                if ShouldErrorForFindDescription then
                    Error(CannotFindDescErr, Type, Description);
            end;
        }
        field(12; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description.';
        }
        field(13; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';

            trigger OnValidate()
            begin
                if CurrFieldNo = Rec.FieldNo("Unit of Measure") then
                    CheckWarehouse(false);
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the number of units of the item specified on the line.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
                DoInitOutstanding: Boolean;
                ShouldCheckWithReturnQtyShipped: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                IsHandled := false;
                OnValidateQuantityOnBeforeDropShptCheck(Rec, xRec, CurrFieldNo, IsHandled);

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                if not IsHandled then
                    if "Drop Shipment" and ("Document Type" <> "Document Type"::Invoice) then
                        Error(
                          Text001, FieldCaption(Quantity), "Sales Order No.");

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec);

                if CurrFieldNo = Rec.FieldNo(Quantity) then
                    CheckWarehouse(false);

                ShouldCheckWithReturnQtyShipped := IsCreditDocType();
                OnValidateQuantityOnAfterShouldCheckWithReturnQtyShipped(Rec, ShouldCheckWithReturnQtyShipped);
                if ShouldCheckWithReturnQtyShipped then begin
                    if (Quantity * "Return Qty. Shipped" < 0) or
                       ((Abs(Quantity) < Abs("Return Qty. Shipped")) and ("Return Shipment No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Return Qty. Shipped")));
                    if ("Quantity (Base)" * "Return Qty. Shipped (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Return Qty. Shipped (Base)")) and ("Return Shipment No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text004, FieldCaption("Return Qty. Shipped (Base)")));
                end else begin
                    IsHandled := false;
                    OnValidateQuantityOnBeforeCheckWithQuantityReceived(Rec, IsHandled);
                    if not IsHandled then begin
                        if (Quantity * "Quantity Received" < 0) or
                        ((Abs(Quantity) < Abs("Quantity Received")) and ("Receipt No." = ''))
                        then
                            FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Quantity Received")));
                        if ("Quantity (Base)" * "Qty. Received (Base)" < 0) or
                        ((Abs("Quantity (Base)") < Abs("Qty. Received (Base)")) and ("Receipt No." = ''))
                        then
                            FieldError("Quantity (Base)", StrSubstNo(Text004, FieldCaption("Qty. Received (Base)")));
                    end;
                end;

                if (Type = Type::"Charge (Item)") and (CurrFieldNo <> 0) then begin
                    if (Quantity = 0) and ("Qty. to Assign" <> 0) then
                        FieldError("Qty. to Assign", StrSubstNo(Text011, FieldCaption(Quantity), Quantity));
                    if (Quantity * "Qty. Assigned" < 0) or (Abs(Quantity) < Abs("Qty. Assigned")) then
                        FieldError(Quantity, StrSubstNo(Text004, FieldCaption("Qty. Assigned")));
                end;

                OnValidateQuantityOnBeforeCheckRcptRetShptRelation(Rec, CurrFieldNo);
                if "Receipt No." <> '' then
                    CheckReceiptRelation()
                else
                    if "Return Shipment No." <> '' then
                        CheckRetShptRelation();

                DoInitOutstanding := (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") or ("No." = xRec."No.");
                OnValidateQuantityOnAfterCalcDoInitOutstanding(Rec, xRec, CurrFieldNo, DoInitOutstanding);
                if DoInitOutstanding then begin
                    InitOutstanding();
                    if IsCreditDocType() then
                        InitQtyToShip()
                    else begin
                        IsHandled := false;
                        OnValidateQuantityOnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            InitQtyToReceive();
                    end;
                    OnValidateQuantityOnAfterInitQty(Rec, CurrFieldNo);
                end;
                if (Quantity * xRec.Quantity < 0) or (Quantity = 0) then
                    InitItemAppl();

                if Quantity <> xRec.Quantity then
                    PlanPriceCalcByField(FieldNo(Quantity));
                ValidateLineDiscountPctForNotItemType();

                OnValidateQuantityOnAfterPlanPriceCalcByField(Rec, xRec);

                if Type = Type::"Charge (Item)" then
                    "Line Discount %" := 0;

                UpdateWithWarehouseReceive();
                if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then begin
                    OnBeforeVerifyReservedQty(Rec, xRec, FieldNo(Quantity));
                    PurchLineReserve.VerifyQuantity(Rec, xRec);
                    IsHandled := false;
                    OnValidateQuantityOnBeforePurchaseLineVerifyChange(Rec, StatusCheckSuspended, IsHandled, xRec);
                    if not IsHandled then
                        PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                    CheckApplToItemLedgEntry();
                end;

                OnValidateQuantityOnBeforeResetAmounts(Rec, xRec);
                if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                   ((Amount <> 0) or ("Amount Including VAT" <> 0) or ("VAT Base Amount" <> 0))
                then begin
                    Amount := 0;
                    "Amount Including VAT" := 0;
                    "VAT Base Amount" := 0;
                    NonDeductibleVAT.ClearNonDeductibleVAT(Rec);
                end;

                UpdateDirectUnitCostByField(FieldNo(Quantity));
                UpdatePrePaymentAmounts();

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices();
                end;

                IsHandled := false;
                OnValidateQuantityOnBeforeCheckWMS(Rec, IsHandled);
                if not IsHandled then
                    CheckWMS();
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            ToolTip = 'Specifies how many units on the order line have not yet been received.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToInvoice(Rec, IsHandled);
                if IsHandled then
                    exit;

                "Qty. to Invoice" := UOMMgt.RoundAndValidateQty("Qty. to Invoice", "Qty. Rounding Precision", FieldCaption("Qty. to Invoice"));

                if "Qty. to Invoice" = MaxQtyToInvoice() then
                    InitQtyToInvoice()
                else begin
                    "Qty. to Invoice (Base)" := CalcBaseQty("Qty. to Invoice", FieldCaption("Qty. to Invoice"), FieldCaption("Qty. to Invoice (Base)"));
                    if ("Qty. per Unit of Measure" <> 0) and not IsSubcontractingCreditMemo() then
                        ValidateQuantityInvIsBalanced();
                end;
                if ("Qty. to Invoice" * Quantity < 0) or (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice())) then
                    Error(CannotInvoiceErrorInfo());

                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase())) then
                    Error(
                      Text007,
                      MaxQtyToInvoiceBase());
                "VAT Difference" := 0;
                NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
                CalcInvDiscToInvoice();
                CalcPrepaymentToDeduct();

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");
            end;
        }
        field(18; "Qty. to Receive"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
                ShouldCheckLocationRequireReceive: Boolean;
            begin
                "Qty. to Receive" := UOMMgt.RoundAndValidateQty("Qty. to Receive", "Qty. Rounding Precision", FieldCaption("Qty. to Receive"));
                ShouldCheckLocationRequireReceive := "Qty. to Receive" <> 0;
                OnValidateQtyToReceiveOnAfterCalcShouldCheckLocationRequireReceive(Rec, ShouldCheckLocationRequireReceive);
                if ShouldCheckLocationRequireReceive then
                    CheckLocationRequireReceive();

                IsHandled := false;
                OnValidateQtyToReceiveOnAfterCheck(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if "Qty. to Receive" = Quantity - "Quantity Received" then begin
                        IsHandled := false;
                        OnValidateQtyToReceiveOnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            InitQtyToReceive();
                    end else begin
                        "Qty. to Receive (Base)" := CalcBaseQty("Qty. to Receive", FieldCaption("Qty. to Receive"), FieldCaption("Qty. to Receive (Base)"));
                        if "Qty. per Unit of Measure" <> 0 then
                            ValidateQuantityReceiveIsBalanced();
                        OnValidateQtyToReceiveOnAfterCalcQtyToReceiveBase(Rec, CurrFieldNo);
                        InitQtyToInvoice();
                    end;

                IsHandled := false;
                OnValidateQtyToReceiveOnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not OverReceiptProcessing() then
                    if not IsHandled then begin
                        if not CanReceiveQty() then
                            Error(CannotReceiveErrorInfo());

                        if not CanReceiveBaseQty() then
                            Error(Text009, "Outstanding Qty. (Base)");
                    end;

                OnValidateQtyToReceiveOnAfterCheckQty(Rec, CurrFieldNo);

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Qty. to Receive" < 0) then
                    CheckApplToItemLedgEntry();

                if "Job Planning Line No." <> 0 then
                    Validate("Job Planning Line No.");
            end;
        }
        field(22; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Direct Unit Cost"));
            Caption = 'Direct Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the selected item or resource.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateDirectUnitCostOnBeforeValidateLineDiscPct(Rec, IsHandled);
                if not IsHandled then
                    Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                TestStatusOpen();
                TestField("No.");
                TestFieldQuantity(FieldNo("Unit Cost (LCY)"));

                if IsProdOrder() then
                    Error(
                      Text99000000,
                      FieldCaption("Unit Cost (LCY)"));

                if CurrFieldNo = FieldNo("Unit Cost (LCY)") then
                    if Type = Type::Item then begin
                        GetItem(Item);
                        if Item."Costing Method" = Item."Costing Method"::Standard then
                            Error(
                              Text010,
                              FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    end;

                UnitCostCurrency := "Unit Cost (LCY)";
                GetPurchHeader();
                if PurchHeader."Currency Code" <> '' then begin
                    PurchHeader.TestField("Currency Factor");
                    GetGLSetup();
                    UnitCostCurrency :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate(), "Currency Code",
                          "Unit Cost (LCY)", PurchHeader."Currency Factor"),
                        GLSetup."Unit-Amount Rounding Precision");
                end;

                OnValidateUnitCostLCYOnAfterUpdateUnitCostCurrency(Rec, UnitCostCurrency);

                "Indirect Cost %" := 0;
                CalcIndirectCostPercent();

                UpdateSalesCostFromUnitCostLCY();

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");
                    UpdateJobPrices();
                end
            end;
        }
        field(25; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateLineDiscountPercent(true);
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLineDiscountAmount(Rec, IsHandled);
                if IsHandled then
                    exit;

                GetPurchHeader();
                "Line Discount Amount" := Round("Line Discount Amount", Currency."Amount Rounding Precision");
                TestStatusOpen();
                TestField(Quantity);
                if xRec."Line Discount Amount" <> "Line Discount Amount" then
                    UpdateLineDiscPct();
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                OnLineDiscountAmountOnValidateOnBeforeUpdateAmounts(Rec);
                UpdateAmounts();
                UpdateUnitCost();
                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(29; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader();
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * GetVATPct() / 100, Currency."Amount Rounding Precision");
                            OnValidateAmountOnAfterCalculateNormalVAT(Rec, PurchHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text011, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Amount;
                            if "Use Tax" then
                                "Amount Including VAT" := "VAT Base Amount"
                            else begin
                                "Amount Including VAT" :=
                                  Amount +
                                  Round(
                                    SalesTaxCalculate.CalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      "VAT Base Amount", "Quantity (Base)", PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculate(Rec, PurchHeader, Currency);
                                if "VAT Base Amount" <> 0 then
                                    "VAT %" :=
                                      Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                                else
                                    ClearVATpct();
                            end;
                        end;
                end;

                InitOutstandingAmount();
                UpdateUnitCost();
            end;
        }
        field(30; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            Editable = false;

            trigger OnValidate()
            begin
                GetPurchHeader();
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - GetVatBaseDiscountPct(PurchHeader) / 100) * GetVATPct() / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100), Currency."Amount Rounding Precision");
                            OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(Rec, PurchHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            if "Use Tax" then begin
                                Amount := "Amount Including VAT";
                                "VAT Base Amount" := Amount;
                            end else begin
                                Amount :=
                                  Round(
                                    SalesTaxCalculate.ReverseCalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      "Amount Including VAT", "Quantity (Base)", PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision");
                                OnAfterSalesTaxCalculateReverse(Rec, PurchHeader, Currency);
                                "VAT Base Amount" := Amount;
                                if "VAT Base Amount" <> 0 then
                                    "VAT %" :=
                                      Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                                else
                                    ClearVATPct();
                            end;
                        end;
                end;

                InitOutstandingAmount();
                UpdateUnitCost();
            end;
        }
        field(31; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price (LCY)';
            ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        field(32; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            InitValue = true;

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("VAT Calculation Type" = "VAT Calculation Type"::"Full VAT") and "Allow Invoice Disc." then
                    Error(CannotAllowInvDiscountErr, FieldCaption("Allow Invoice Disc."));

                if "Allow Invoice Disc." <> xRec."Allow Invoice Disc." then begin
                    if not "Allow Invoice Disc." then begin
                        "Inv. Discount Amount" := 0;
                        "Inv. Disc. Amount to Invoice" := 0;
                    end;
                    UpdateAmounts();
                    UpdateUnitCost();
                end;
            end;
        }
        field(34; "Gross Weight"; Decimal)
        {
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Units per Parcel"; Decimal)
        {
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Appl.-to Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-to Item Entry';

            trigger OnLookup()
            begin
                SelectItemEntry();
            end;

            trigger OnValidate()
            begin
                if "Appl.-to Item Entry" <> 0 then
                    "Location Code" := CheckApplToItemLedgEntry();
            end;
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(41; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project. If you fill in this field and the Project Task No. field, then a project ledger entry will be posted together with the purchase line.';
            TableRelation = Job;

            trigger OnValidate()
            var
                Job: Record Job;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField("Drop Shipment", false);
                TestField("Special Order", false);
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if CheckReservationForJobNo() then
                    TestField("Job No.", '');

                if (xRec."Job No." <> "Job No.") and (Quantity <> 0) then
                    if Type = Type::Item then
                        PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);

                PlanPriceCalcByField(FieldNo("Job No."));
                InitJobFields();

                if "Job No." = '' then begin
                    CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
                    exit;
                end;

                VerifyLineTypeForJob();
                CheckWMS();

                IsHandled := false;
                OnValidateJobNoOnBeforeGetJob(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                Job.Get("Job No.");
                Job.TestBlocked();
                "Job Currency Code" := Job."Currency Code";

                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));

                UpdateDirectUnitCostByField(FieldNo("Job No."));

                if (xRec."Line Discount %" <> "Line Discount %") and ("Line Discount Amount" <> 0) then
                    UpdateLineDiscPct();
            end;
        }
        field(54; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                Item: Record Item;
                ShouldCheckCostingMethod: Boolean;
            begin
                TestField("No.");
                TestStatusOpen();

                CheckLineTypeOnIndirectCostPercentUpdate();

                ShouldCheckCostingMethod := (Type = Type::Item) and (not IsProdOrder());
                OnValidateIndirectCostOnAfterCalcShouldCheckCostingMethod(Rec, ShouldCheckCostingMethod);
                if ShouldCheckCostingMethod then begin
                    GetItem(Item);
                    Item.TestField(Type, Item.Type::Inventory);
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        Error(
                          Text010,
                          FieldCaption("Indirect Cost %"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                end;

                UpdateUnitCost();
            end;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
        }
        field(57; "Outstanding Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Outstanding Amount';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader();
                Currency2.InitRoundingPrecision();
                if PurchHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Outstanding Amount", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");

                "Outstanding Amt. Ex. VAT (LCY)" :=
                  Round("Outstanding Amount (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Rcd. Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader();
                Currency2.InitRoundingPrecision();
                if PurchHeader."Currency Code" <> '' then
                    "Amt. Rcd. Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Amt. Rcd. Not Invoiced", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Amt. Rcd. Not Invoiced (LCY)" :=
                      Round("Amt. Rcd. Not Invoiced", Currency2."Amount Rounding Precision");

                "A. Rcd. Not Inv. Ex. VAT (LCY)" :=
                  Round("Amt. Rcd. Not Invoiced (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
            end;
        }
        field(60; "Quantity Received"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Quantity Received';
            DecimalPlaces = 0 : 5;
            Editable = false;
            ToolTip = 'Specifies how many units of the item on the line have been posted as received.';

        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(63; "Receipt No."; Code[20])
        {
            Caption = 'Receipt No.';
            Editable = false;
        }
        field(64; "Receipt Line No."; Integer)
        {
            Caption = 'Receipt Line No.';
            Editable = false;
        }
        field(65; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the order number this line is associated with.';
        }
        field(66; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(67; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(68; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            Editable = false;
            TableRelation = Vendor;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Discount Amount';
            Editable = false;
            ToolTip = 'Specifies the total calculated invoice discount amount for the line.';

            trigger OnValidate()
            begin
                UpdateAmounts();
                UpdateUnitCost();
                CalcInvDiscToInvoice();
            end;
        }
        field(70; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';

            trigger OnValidate()
            begin
                if PurchHeader."Send IC Document" and
                   ("IC Partner Ref. Type" = "IC Partner Ref. Type"::"Vendor Item No.")
                then
                    "IC Partner Reference" := "Vendor Item No.";
            end;
        }
        field(71; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            Editable = false;
            TableRelation = if ("Drop Shipment" = const(true)) "Sales Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                if (xRec."Sales Order No." <> "Sales Order No.") and (Quantity <> 0) then begin
                    PurchLineReserve.VerifyChange(Rec, xRec);
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(72; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            Editable = false;
            TableRelation = if ("Drop Shipment" = const(true)) "Sales Line"."Line No." where("Document Type" = const(Order),
                                                                                            "Document No." = field("Sales Order No."));

            trigger OnValidate()
            begin
                if (xRec."Sales Order Line No." <> "Sales Order Line No.") and (Quantity <> 0) then begin
                    PurchLineReserve.VerifyChange(Rec, xRec);
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = false;

            trigger OnValidate()
            begin
                if (xRec."Drop Shipment" <> "Drop Shipment") and (Quantity <> 0) then begin
                    PurchLineReserve.VerifyChange(Rec, xRec);
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                end;
                if "Drop Shipment" then begin
                    "Bin Code" := '';
                    Evaluate("Inbound Whse. Handling Time", '<0D>');
                    Validate("Inbound Whse. Handling Time");
                    Evaluate("Safety Lead Time", '<0D>');
                    Validate("Safety Lead Time");
                    InitOutstanding();
                    InitQtyToReceive();
                end;
            end;
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(75; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateGenProdPostingGroup(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(78; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(79; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(80; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            Editable = false;
            TableRelation = "Purchase Line"."Line No." where("Document Type" = field("Document Type"),
                                                              "Document No." = field("Document No."));
        }
        field(81; "Entry Point"; Code[10])
        {
            Caption = 'Entry Point';
            TableRelation = "Entry/Exit Point";
        }
        field(82; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(83; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(85; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(86; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(87; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmounts();
            end;
        }
        field(88; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
                ShouldUpdateUnitCost: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnValidateVATProdPostingGroupOnAfterTestStatusOpen(Rec, IsHandled, xRec);
                if not IsHandled then begin
                    CheckPrepmtAmtInvEmpty();
                    IsHandled := false;
                    OnValidateVATProdPostingGroupOnBeforeGetVATPostingSetup(Rec, VATPostingSetup, IsHandled, xRec);
                    if not IsHandled then
                        VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                    OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(VATPostingSetup);
                    ClearVATDifference();
                    NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
                    GetPurchHeader();
                    CopyFromVATPostingSetup(VATPostingSetup);
                    NonDeductibleVAT.SetNonDeductiblePct(Rec);

                    IsHandled := false;
                    OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(Rec, VATPostingSetup, IsHandled, CurrFieldNo);
                    if not IsHandled then
                        case "VAT Calculation Type" of
                            "VAT Calculation Type"::"Reverse Charge VAT",
                            "VAT Calculation Type"::"Sales Tax":
                                ClearVATPct();
                            "VAT Calculation Type"::"Full VAT":
                                begin
                                    TestField(Type, Type::"G/L Account");
                                    TestField("No.", VATPostingSetup.GetPurchAccount(false));
                                end;
                        end;
                    ShouldUpdateUnitCost := PurchHeader."Prices Including VAT" and (Rec.Type in [Rec.Type::Item, Rec.Type::Resource]);
                    OnValidateVATProdPostingGroupOnAfterCalcShouldUpdateUnitCost(Rec, VATPostingSetup, ShouldUpdateUnitCost);
                    if ShouldUpdateUnitCost then
                        Validate("Direct Unit Cost",
                        Round(
                            "Direct Unit Cost" * (100 + GetVATPct()) / (100 + xRec.GetVATPct()),
                            Currency."Unit-Amount Rounding Precision"));
                    UpdateAmounts();
                end;
            end;
        }
        field(91; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(92; "Outstanding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Outstanding Amount (LCY)';
            ToolTip = 'Specifies the amount for the items on the order that have not yet been received in LCY.';
            Editable = false;
        }
        field(93; "Amt. Rcd. Not Invoiced (LCY)"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            AutoFormatType = 1;
            Caption = 'Amt. Rcd. Not Invoiced (LCY)';
            ToolTip = 'Specifies the sum, in LCY, for items that have been received but have not yet been invoiced. The value in the Amt. Rcd. Not Invoiced (LCY) field is used for entries in the Purchase Line table of document type Order to calculate and update the contents of this field.';
            Editable = false;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                  "Source Ref. No." = field("Line No."),
                                                                  "Source Type" = const(39),
#pragma warning disable AL0603
                                                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = const("Blanket Order"));

            trigger OnLookup()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupBlanketOrderNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Received", 0);
                BlanketOrderLookup();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestField("Quantity Received", 0);

                IsHandled := false;
                OnValidateBlanketOrderNoOnAfterCheck(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Blanket Order No." = '' then
                    "Blanket Order Line No." := 0
                else
                    Validate("Blanket Order Line No.");
            end;
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Blanket Order Line No.';
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const("Blanket Order"),
                                                              "Document No." = field("Blanket Order No."));

            trigger OnLookup()
            begin
                BlanketOrderLookup();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBlanketOrderLineNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Received", 0);
                if "Blanket Order Line No." <> 0 then begin
                    PurchLine2.Get("Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.");
                    PurchLine2.TestField(Type, Type);
                    PurchLine2.TestField("No.", "No.");
                    PurchLine2.TestField("Pay-to Vendor No.", "Pay-to Vendor No.");
                    PurchLine2.TestField("Buy-from Vendor No.", "Buy-from Vendor No.");
                    if "Drop Shipment" or "Special Order" then begin
                        PurchLine2.TestField("Variant Code", "Variant Code");
                        PurchLine2.TestField("Location Code", "Location Code");
                        PurchLine2.TestField("Unit of Measure Code", "Unit of Measure Code");
                    end else begin
                        Validate("Variant Code", PurchLine2."Variant Code");
                        Validate("Location Code", PurchLine2."Location Code");
                        Validate("Unit of Measure Code", PurchLine2."Unit of Measure Code");
                    end;
                    Validate("Direct Unit Cost", PurchLine2."Direct Unit Cost");
                    Validate("Line Discount %", PurchLine2."Line Discount %");
                    OnAfterValidateBlanketOrderLineNo(Rec, PurchLine2);
                end;
            end;
        }
        field(99; "VAT Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Base Amount';
            Editable = false;
        }
        field(100; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(101; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(103; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Line Amount"));
            Caption = 'Line Amount';
            ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';

            trigger OnValidate()
            var
                MaxLineAmount: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLineAmount(Rec, xRec, CurrFieldNo, IsHandled, Currency);
                if IsHandled then
                    exit;

                TestField(Type);
                TestField(Quantity);
                CheckDirectUnitCost();

                GetPurchHeader();
                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                MaxLineAmount := Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision");
                OnValidateLineAmountOnAfterCalcMaxLineAmount(Rec, MaxLineAmount, Currency);

                CheckLineAmount(MaxLineAmount);

                IsHandled := false;
                OnValidateLineAmountBeforeValidateLineDiscountAmount(Rec, Currency, IsHandled, CurrFieldNo);
                if not IsHandled then
                    Validate("Line Discount Amount", MaxLineAmount - "Line Amount");
            end;
        }
        field(104; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(105; "Inv. Disc. Amount to Invoice"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Inv. Disc. Amount to Invoice';
            Editable = false;
        }
        field(106; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
        }
        field(107; "IC Partner Ref. Type"; Enum "IC Partner Reference Type")
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Partner Ref. Type';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "IC Partner Code" <> '' then
                    "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                if "IC Partner Ref. Type" <> xRec."IC Partner Ref. Type" then
                    "IC Partner Reference" := '';
                if "IC Partner Ref. Type" = "IC Partner Ref. Type"::"Common Item No." then begin
                    GetItem(Item);
                    Item.TestField("Common Item No.");
                    "IC Partner Reference" := Item."Common Item No.";
                end;
            end;
        }
        field(108; "IC Partner Reference"; Code[20])
        {
            AccessByPermission = TableData "IC G/L Account" = R;
            Caption = 'IC Partner Reference';

            trigger OnLookup()
            var
                ICGLAccount: Record "IC G/L Account";
                Item: Record Item;
                ItemVendorCatalog: Record "Item Vendor";
            begin
                if "No." <> '' then
                    case "IC Partner Ref. Type" of
                        "IC Partner Ref. Type"::"G/L Account":
                            begin
                                if ICGLAccount.Get("IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"IC G/L Account List", ICGLAccount) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", ICGLAccount."No.");
                            end;
                        "IC Partner Ref. Type"::Item:
                            begin
                                if Item.Get("IC Partner Reference") then;
                                if PAGE.RunModal(PAGE::"Item List", Item) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", Item."No.");
                            end;
                        "IC Partner Ref. Type"::"Vendor Item No.":
                            begin
                                GetPurchHeader();
                                ItemVendorCatalog.SetCurrentKey("Vendor No.");
                                ItemVendorCatalog.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
                                if PAGE.RunModal(PAGE::"Vendor Item Catalog", ItemVendorCatalog) = ACTION::LookupOK then
                                    Validate("IC Partner Reference", ItemVendorCatalog."Vendor Item No.");
                            end;
                    end;
            end;
        }
        field(109; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdatePrepmtSetupFields();

                if HasTypeToFillMandatoryFields() then
                    UpdateAmounts();
                UpdateBaseAmounts(Amount, "Amount Including VAT", "VAT Base Amount");
            end;
        }
        field(110; "Prepmt. Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Line Amount"));
            Caption = 'Prepmt. Line Amount';
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtLineAmount(Rec, PrePaymentLineAmountEntered, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                PrePaymentLineAmountEntered := true;
                TestField("Line Amount");
                if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text038, "Prepmt. Amt. Inv."));
                if "Prepmt. Line Amount" > "Line Amount" then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text039, "Line Amount"));
                Validate("Prepayment %", "Prepmt. Line Amount" * 100 / "Line Amount");
            end;
        }
        field(111; "Prepmt. Amt. Inv."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt. Amt. Inv."));
            Caption = 'Prepmt. Amt. Inv.';
            Editable = false;
        }
        field(112; "Prepmt. Amt. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amt. Incl. VAT';
            Editable = false;
        }
        field(113; "Prepayment Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment Amount';
            Editable = false;
        }
        field(114; "Prepmt. VAT Base Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. VAT Base Amt.';
            Editable = false;
        }
        field(115; "Prepayment VAT %"; Decimal)
        {
            Caption = 'Prepayment VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(116; "Prepmt. VAT Calc. Type"; Enum "Tax Calculation Type")
        {
            Caption = 'Prepmt. VAT Calc. Type';
            Editable = false;
        }
        field(117; "Prepayment VAT Identifier"; Code[20])
        {
            Caption = 'Prepayment VAT Identifier';
            Editable = false;
        }
        field(118; "Prepayment Tax Area Code"; Code[20])
        {
            Caption = 'Prepayment Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(119; "Prepayment Tax Liable"; Boolean)
        {
            Caption = 'Prepayment Tax Liable';

            trigger OnValidate()
            begin
                UpdateAmounts();
            end;
        }
        field(120; "Prepayment Tax Group Code"; Code[20])
        {
            Caption = 'Prepayment Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateAmounts();
            end;
        }
        field(121; "Prepmt Amt to Deduct"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt to Deduct"));
            Caption = 'Prepmt Amt to Deduct';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Prepmt Amt to Deduct" > "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text039, "Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                if "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Direct Unit Cost" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text039, "Qty. to Invoice" * "Direct Unit Cost"));
                if ("Prepmt. Amt. Inv." - "Prepmt Amt to Deduct" - "Prepmt Amt Deducted") >
                   (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Direct Unit Cost"
                then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text038,
                        "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" -
                        (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Direct Unit Cost"));
            end;
        }
        field(122; "Prepmt Amt Deducted"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Prepmt Amt Deducted"));
            Caption = 'Prepmt Amt Deducted';
            Editable = false;
        }
        field(123; "Prepayment Line"; Boolean)
        {
            Caption = 'Prepayment Line';
            Editable = false;
        }
        field(124; "Prepmt. Amount Inv. Incl. VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. Incl. VAT';
            Editable = false;
        }
        field(129; "Prepmt. Amount Inv. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Prepmt. Amount Inv. (LCY)';
            Editable = false;
        }
        field(130; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";

            trigger OnValidate()
            begin
                if "IC Partner Code" <> '' then begin
                    TestField(Type, Type::"G/L Account");
                    GetPurchHeader();
                    PurchHeader.TestField("Buy-from IC Partner Code", '');
                    PurchHeader.TestField("Pay-to IC Partner Code", '');
                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"G/L Account");
                end;
            end;
        }
        field(132; "Prepmt. VAT Amount Inv. (LCY)"; Decimal)
        {
            Caption = 'Prepmt. VAT Amount Inv. (LCY)';
            Editable = false;
        }
        field(135; "Prepayment VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepayment VAT Difference';
            Editable = false;
        }
        field(136; "Prepmt VAT Diff. to Deduct"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. to Deduct';
            Editable = false;
        }
        field(137; "Prepmt VAT Diff. Deducted"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt VAT Diff. Deducted';
            Editable = false;
        }
        field(138; "IC Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'IC Item Reference No.';

            trigger OnLookup()
            var
                ItemReference: Record "Item Reference";
                ItemVendorCatalog: Record "Item Vendor";
            begin
                if "No." <> '' then
                    case "IC Partner Ref. Type" of
                        "IC Partner Ref. Type"::"Cross Reference":
                            begin
                                GetPurchHeader();
                                ItemReference.Reset();
                                ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
                                ItemReference.SetFilter(
                                    "Reference Type", '%1|%2',
                                    ItemReference."Reference Type"::Vendor, ItemReference."Reference Type"::" ");
                                ItemReference.SetFilter("Reference Type No.", '%1|%2', PurchHeader."Buy-from Vendor No.", '');
                                if PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK then
                                    Validate("IC Item Reference No.", ItemReference."Reference No.");
                            end;
                        "IC Partner Ref. Type"::"Vendor Item No.":
                            begin
                                GetPurchHeader();
                                ItemVendorCatalog.SetCurrentKey("Vendor No.");
                                ItemVendorCatalog.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
                                if PAGE.RunModal(PAGE::"Vendor Item Catalog", ItemVendorCatalog) = ACTION::LookupOK then
                                    Validate("IC Item Reference No.", ItemVendorCatalog."Vendor Item No.");
                            end;
                    end;
            end;
        }
        field(140; "Outstanding Amt. Ex. VAT (LCY)"; Decimal)
        {
            Caption = 'Outstanding Amt. Ex. VAT (LCY)';
        }
        field(141; "A. Rcd. Not Inv. Ex. VAT (LCY)"; Decimal)
        {
            Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)';
        }
        field(145; "Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Pmt. Discount Amount';

            trigger OnValidate()
            begin
                TestField(Quantity);
                UpdateAmounts();
            end;
        }
        field(146; "Prepmt. Pmt. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Prepmt. Pmt. Discount Amount';
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
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(xRec, IsHandled, CurrFieldNo, TempJobJnlLine);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField("Receipt No.", '');

                if "Job Task No." <> xRec."Job Task No." then begin
                    Validate("Job Planning Line No.", 0);
                    if "Document Type" = "Document Type"::Order then
                        TestField("Quantity Received", 0);
                    if (Type = Type::Item) and (Quantity <> 0) then
                        PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                    PlanPriceCalcByField(FieldNo("Job Task No."));
                end;

                if "Job Task No." = '' then begin
                    Clear(TempJobJnlLine);
                    "Job Line Type" := "Job Line Type"::" ";
                    UpdateJobPrices();
                    CreateDimFromDefaultDim(0);
                    exit;
                end;

                JobSetCurrencyFactor();
                UpdateDirectUnitCostByField(FieldNo("Job Task No."));
                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices();
                end;
                UpdateDimensionsFromJobTask();

                if (xRec."Line Discount %" <> "Line Discount %") and
                   (xRec."Job Task No." <> "Job Task No.") and
                   ("Line Discount Amount" <> 0)
                then
                    UpdateLineDiscPct();
            end;
        }
        field(1002; "Job Line Type"; Enum "Job Line Type")
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Line Type';
            ToolTip = 'Specifies a Project Planning Line together with the posting of a project ledger entry.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobLineType(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if "Job Planning Line No." <> 0 then
                    Error(Text048, FieldCaption("Job Line Type"), FieldCaption("Job Planning Line No."));
            end;
        }
        field(1003; "Job Unit Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Unit Price';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobUnitPrice(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Price", "Job Unit Price");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1004; "Job Total Price"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Total Price';
            Editable = false;
        }
        field(1005; "Job Line Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                OnBeforeValidateJobLineAmount(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Amount", "Job Line Amount");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1006; "Job Line Discount Amount"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatExpression = "Job Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Discount Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobLineDiscountAmount(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount Amount", "Job Line Discount Amount");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1007; "Job Line Discount %"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Line Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobLineDiscountPercent(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount %", "Job Line Discount %");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1008; "Job Unit Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Unit Price (LCY)';
            Editable = false;
            AutoFormatType = 2;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobUnitPriceLCY(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Unit Price (LCY)", "Job Unit Price (LCY)");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1009; "Job Total Price (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Total Price (LCY)';
            Editable = false;
            AutoFormatType = 1;
        }
        field(1010; "Job Line Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobLineAmountLCY(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Amount (LCY)", "Job Line Amount (LCY)");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1011; "Job Line Disc. Amount (LCY)"; Decimal)
        {
            AccessByPermission = TableData Job = R;
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Project Line Disc. Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobLineDiscAmountLCY(Rec, TempJobJnlLine, IsHandled);
                if IsHandled then
                    exit;

                TestField("Receipt No.", '');
                if "Document Type" = "Document Type"::Order then
                    TestField("Quantity Received", 0);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(false);
                    TempJobJnlLine.Validate("Line Discount Amount (LCY)", "Job Line Disc. Amount (LCY)");
                    UpdateJobPrices();
                end;
            end;
        }
        field(1012; "Job Currency Factor"; Decimal)
        {
            BlankZero = true;
            Caption = 'Project Currency Factor';
        }
        field(1013; "Job Currency Code"; Code[20])
        {
            Caption = 'Project Currency Code';
        }
        field(1019; "Job Planning Line No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            BlankZero = true;
            Caption = 'Project Planning Line No.';

            trigger OnLookup()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobPlanningLineNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
                case Type of
                    Type::"G/L Account":
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::"G/L Account");
                    Type::Item:
                        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
                end;
                JobPlanningLine.SetRange("No.", "No.");
                JobPlanningLine.SetRange("Usage Link", true);
                JobPlanningLine.SetRange("System-Created Entry", false);

                if PAGE.RunModal(0, JobPlanningLine) = ACTION::LookupOK then
                    Validate("Job Planning Line No.", JobPlanningLine."Line No.");
            end;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
            begin
                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    JobPlanningLine.TestField("Job No.", "Job No.");
                    JobPlanningLine.TestField("Job Task No.", "Job Task No.");
                    case Type of
                        Type::"G/L Account":
                            begin
                                IsHandled := false;
                                OnValidateJobPlanningLineNoOnBeforeGLAccountTest(Rec, JobPlanningLine, IsHandled);
                                if not IsHandled then
                                    JobPlanningLine.TestField(Type, JobPlanningLine.Type::"G/L Account");
                            end;
                        Type::Item:
                            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                    end;

                    IsHandled := false;
                    OnValidateJobPlanningLineNoOnBeforeTestFields(Rec, JobPlanningLine, IsHandled);
                    if not IsHandled then begin
                        JobPlanningLine.TestField("No.", "No.");
                        JobPlanningLine.TestField("Usage Link", true);
                        JobPlanningLine.TestField("System-Created Entry", false);
                    end;
                    "Job Line Type" := JobPlanningLine.ConvertToJobLineType();
                    Validate(
                        "Job Remaining Qty.",
                        JobPlanningLine."Remaining Qty." - UOMMgt.CalcQtyFromBase("Qty. to Invoice (Base)", JobPlanningLine."Qty. per Unit of Measure"))
                end else
                    Validate("Job Remaining Qty.", 0);
            end;
        }
        field(1030; "Job Remaining Qty."; Decimal)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Remaining Qty.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                if ("Job Remaining Qty." <> 0) and ("Job Planning Line No." = 0) then
                    Error(Text047, FieldCaption("Job Remaining Qty."), FieldCaption("Job Planning Line No."));

                if "Job Planning Line No." <> 0 then begin
                    JobPlanningLine.SetLoadFields("No.", "Variant Code", Quantity, "Unit of Measure Code", "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)");
                    JobPlanningLine.Get("Job No.", "Job Task No.", "Job Planning Line No.");
                    if JobPlanningLine.Quantity >= 0 then begin
                        if "Job Remaining Qty." < 0 then
                            "Job Remaining Qty." := 0;
                    end else
                        if "Job Remaining Qty." > 0 then
                            "Job Remaining Qty." := 0;
                end;
                "Job Remaining Qty." := UOMMgt.RoundAndValidateQty("Job Remaining Qty.", "Qty. Rounding Precision", FieldCaption("Job Remaining Qty."));
                "Job Remaining Qty. (Base)" := CalcBaseQtyForJobPlanningLine("Job Remaining Qty.", FieldCaption("Job Remaining Qty."), FieldCaption("Job Remaining Qty. (Base)"), JobPlanningLine);
            end;
        }
        field(1031; "Job Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Project Remaining Qty. (Base)';
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                DeferralPostDate: Date;
            begin
                GetPurchHeader();
                DeferralPostDate := GetDeferralPostDate(PurchHeader);

                DeferralUtilities.DeferralCodeOnValidate(
                  "Deferral Code", Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
                  "Document Type".AsInteger(), "Document No.", "Line No.",
                  GetDeferralAmount(), DeferralPostDate,
                  Description, PurchHeader."Currency Code");

                if "Document Type" = "Document Type"::"Return Order" then
                    "Returns Deferral Start Date" :=
                      DeferralUtilities.GetDeferralStartDate(
                          Enum::"Deferral Document Type"::Purchase.AsInteger(),
                          "Document Type".AsInteger(), "Document No.", "Line No.", "Deferral Code", PurchHeader."Posting Date");
            end;
        }
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';

            trigger OnValidate()
            var
                DeferralHeader: Record "Deferral Header";
                DeferralUtilities: Codeunit "Deferral Utilities";
            begin
                GetPurchHeader();
                if DeferralHeader.Get(
                    Enum::"Deferral Document Type"::Purchase, '', '', "Document Type", "Document No.", "Line No.")
                then
                    DeferralUtilities.CreateDeferralSchedule(
                        "Deferral Code", Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
                        "Document Type".AsInteger(), "Document No.", "Line No.", GetDeferralAmount(),
                        DeferralHeader."Calc. Method", "Returns Deferral Start Date",
                        DeferralHeader."No. of Periods", true,
                        DeferralHeader."Schedule Description", false,
                        PurchHeader."Currency Code");
            end;
        }
        field(2675; "Selected Alloc. Account No."; Code[20])
        {
            Caption = 'Allocation Account No.';
            ToolTip = 'Specifies the allocation account number that will be used to distribute the amounts during the posting process.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2677; "Alloc. Acc. Modified by User"; Boolean)
        {
            Caption = 'Allocation Account Distributions Modified';
            FieldClass = FlowField;
            CalcFormula = exist(Microsoft.Finance.AllocationAccount."Alloc. Acc. Manual Override" where("Parent System Id" = field(SystemId), "Parent Table Id" = const(Database::"Purchase Line")));
        }
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Posting Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2679; "Alloc. Purch. Line SystemId"; Guid)
        {
            Caption = 'Allocation Purchase Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item), "Document Type" = filter(<> "Credit Memo" & <> "Return Order")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false), "Purchasing Blocked" = const(false))
            else
            if (Type = const(Item), "Document Type" = filter("Credit Memo" | "Return Order")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                if "Variant Code" <> '' then begin
                    Rec.TestField(Type, Rec.Type::Item);

                    IsHandled := false;
                    OnValidateVariantCodeBeforeCheckBlocked(Rec, IsHandled);
                    if not IsHandled then begin
                        ItemVariant.SetLoadFields("Purchasing Blocked");
                        ItemVariant.Get(Rec."No.", Rec."Variant Code");
                        if ItemVariant."Purchasing Blocked" then
                            if IsCreditDocType() then
                                SendBlockedItemVariantNotification();
                    end;
                end;
                TestStatusOpen();

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Rcd. Not Invoiced", 0);
                    TestField("Receipt No.", '');
                    TestField("Return Qty. Shipped Not Invd.", 0);
                    TestField("Return Shipment No.", '');
                end;

                IsHandled := false;
                OnValidateVariantCodeOnBeforeDropShipmentError(Rec, IsHandled);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Variant Code"), "Sales Order No.");

                OnValidateVariantCodeOnAfterValidationChecks(Rec, xRec, CurrFieldNo);

                if Type = Type::Item then
                    if "Variant Code" <> xRec."Variant Code" then
                        PlanPriceCalcByField(FieldNo("Variant Code"));

                if (xRec."Variant Code" <> "Variant Code") and (Quantity <> 0) then begin
                    PurchLineReserve.VerifyChange(Rec, xRec);
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                    InitItemAppl();
                end;

                UpdateLeadTimeFields();
                UpdateDates();
                GetDefaultBin();
                IsHandled := false;
                OnValidateVariantCodeOnBeforeUpdateItemReference(Rec, IsHandled);
                if not IsHandled then
                    if Type = Type::Item then
                        UpdateItemReference();

                OnValidateVariantCodeOnAfterUpdateItemReference(Rec, CurrFieldNo);

                if JobTaskIsSet() then begin
                    CreateTempJobJnlLine(true);
                    UpdateJobPrices();
                end;
                UpdateDirectUnitCostByField(FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Document Type" = filter(Order | Invoice),
                                Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                     "Item No." = field("No."),
                                                                                     "Variant Code" = field("Variant Code"))
            else
            if ("Document Type" = filter("Return Order" | "Credit Memo"),
                                                                                              Quantity = filter(>= 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                    "Item No." = field("No."),
                                                                                                                                                    "Variant Code" = field("Variant Code"))
            else
            Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupBinCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if not IsInbound() and ("Quantity (Base)" <> 0) then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                Item: Record Item;
                WMSManagement: Codeunit "WMS Management";
            begin
                if "Bin Code" <> '' then
                    if not IsInbound() and ("Quantity (Base)" <> 0) then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
                    else
                        WMSManagement.FindBin("Location Code", "Bin Code", '');

                if "Drop Shipment" then
                    ShowBinCodeCannotBeChangedError();

                TestField(Type, Type::Item);
                TestField("Location Code");

                GetItem(Item);
                Item.TestField(Type, Item.Type::Inventory);

                if "Bin Code" <> '' then begin
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    CheckWarehouse(true);
                end;
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5405; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5406; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item),
                                "No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource), "No." = filter(<> '')) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            if (Type = filter("Charge (Item)" | "Fixed Asset" | "G/L Account")) "Unit of Measure";
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

            trigger OnValidate()
            var
                Item: Record Item;
                Resource: Record Resource;
                IsHandled: Boolean;
                ShouldUpdateItemReference, ShouldUpdateNonSubcontractingDocument : Boolean;
            begin
                TestStatusOpen();
                TestField("Quantity Received", 0);
                TestField("Qty. Received (Base)", 0);
                TestField("Qty. Rcd. Not Invoiced", 0);
                TestField("Return Qty. Shipped", 0);
                TestField("Return Qty. Shipped (Base)", 0);
                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then begin
                    TestField("Receipt No.", '');
                    TestField("Return Shipment No.", '');
                end;

                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeDropShipmentError(Rec, IsHandled, xRec, CurrFieldNo);
                if not IsHandled then
                    if "Drop Shipment" then
                        Error(Text001, FieldCaption("Unit of Measure Code"), "Sales Order No.");

                if (xRec."Unit of Measure Code" <> "Unit of Measure Code") and (Quantity <> 0) then begin
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
                    PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                end;
                SetUnitOfMeasure();
                ShouldUpdateItemReference := Type = Type::Item;
                ShouldUpdateNonSubcontractingDocument := not IsProdOrder();
                OnValidateUnitOfMeasureCodeOnAfterCalcShouldUpdateItemReference(Rec, ShouldUpdateItemReference, ShouldUpdateNonSubcontractingDocument);
                if ShouldUpdateItemReference then
                    UpdateItemReference();
                if ShouldUpdateNonSubcontractingDocument then
                    case Type of
                        Type::Item:
                            begin
                                GetItem(Item);
                                AssignFieldsForQtyPerUOM(Item, CurrFieldNo);

                                OnAfterAssignItemUOM(Rec, Item, CurrFieldNo);
                                if "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" then
                                    InitItemAppl();

                                UpdateUOMQtyPerStockQty();
                            end;
                        Type::Resource:
                            begin
                                GetResource(Resource);
                                "Qty. per Unit of Measure" := UoMMgt.GetResQtyPerUnitOfMeasure(Resource, "Unit of Measure Code");
                                OnAfterAssignResourceUOM(Rec, Resource, CurrFieldNo);
                                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                    PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            end;
                        Type::" ",
                        Type::"Charge (Item)",
                        Type::"Fixed Asset",
                        Type::"G/L Account":
                            "Qty. per Unit of Measure" := 1;
                    end
                else
                    "Qty. per Unit of Measure" := 0;

                OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(Rec, xRec, Item);
                Validate(Quantity);
                UpdateDirectUnitCostByField(FieldNo("Unit of Measure Code"));
            end;
        }
        field(5415; "Quantity (Base)"; Decimal)
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
                if "Quantity (Base)" <> xRec."Quantity (Base)" then
                    PlanPriceCalcByField(FieldNo("Quantity (Base)"));
                Validate(Quantity, "Quantity (Base)");
                UpdateDirectUnitCostByField(FieldNo("Quantity (Base)"));
            end;
        }
        field(5416; "Outstanding Qty. (Base)"; Decimal)
        {
            Caption = 'Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5417; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtytoInvoiceBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Invoice", "Qty. to Invoice (Base)");
            end;
        }
        field(5418; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtytoReceiveBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(5458; "Qty. Rcd. Not Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Rcd. Not Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5461; "Qty. Invoiced (Base)"; Decimal)
        {
            Caption = 'Qty. Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5495; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source Type" = const(39),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                           "Source ID" = field("Document No."),
                                                                           "Source Ref. No." = field("Line No."),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            ToolTip = 'Specifies the value in the Reserved Quantity field, expressed in the base unit of measure.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600; "FA Posting Date"; Date)
        {
            Caption = 'FA Posting Date';
        }
        field(5601; "FA Posting Type"; Enum "Purchase FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';

            trigger OnValidate()
            begin
                if Type = Type::"Fixed Asset" then begin
                    TestField("Job No.", '');
                    if "FA Posting Type" = "FA Posting Type"::" " then
                        "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
                    GetFAPostingGroup();
                end else begin
                    "Depreciation Book Code" := '';
                    "FA Posting Date" := 0D;
                    "Salvage Value" := 0;
                    "Depr. until FA Posting Date" := false;
                    "Depr. Acquisition Cost" := false;
                    "Maintenance Code" := '';
                    "Insurance No." := '';
                    "Budgeted FA No." := '';
                    "Duplicate in Depreciation Book" := '';
                    "Use Duplication List" := false;
                end;
            end;
        }
        field(5602; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                GetFAPostingGroup();
            end;
        }
        field(5603; "Salvage Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Salvage Value';
        }
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
        }
        field(5606; "Depr. Acquisition Cost"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. Acquisition Cost';
        }
        field(5609; "Maintenance Code"; Code[10])
        {
            Caption = 'Maintenance Code';
            TableRelation = Maintenance;
        }
        field(5610; "Insurance No."; Code[20])
        {
            Caption = 'Insurance No.';
            TableRelation = Insurance;
        }
        field(5611; "Budgeted FA No."; Code[20])
        {
            Caption = 'Budgeted FA No.';
            TableRelation = "Fixed Asset";

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
            begin
                if "Budgeted FA No." <> '' then begin
                    FixedAsset.Get("Budgeted FA No.");
                    FixedAsset.TestField("Budgeted Asset", true);
                end;
            end;
        }
        field(5612; "Duplicate in Depreciation Book"; Code[10])
        {
            Caption = 'Duplicate in Depreciation Book';
            TableRelation = "Depreciation Book";

            trigger OnValidate()
            begin
                "Use Duplication List" := false;
            end;
        }
        field(5613; "Use Duplication List"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Use Duplication List';

            trigger OnValidate()
            begin
                "Duplicate in Depreciation Book" := '';
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));
            end;
        }
        field(5709; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5710; Nonstock; Boolean)
        {
            AccessByPermission = TableData "Nonstock Item" = R;
            Caption = 'Catalog';
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            Editable = false;
            TableRelation = Purchasing;

            trigger OnValidate()
            var
                PurchasingCode: Record Purchasing;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePurchasingCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if PurchasingCode.Get("Purchasing Code") then begin
                    "Drop Shipment" := PurchasingCode."Drop Shipment";
                    "Special Order" := PurchasingCode."Special Order";
                    OnValidatePurchasingCodeOnAfterAssignFields(Rec, PurchasingCode);
                end else
                    "Drop Shipment" := false;

                Validate("Drop Shipment", "Drop Shipment");
            end;
        }
        field(5713; "Special Order"; Boolean)
        {
            Caption = 'Special Order';

            trigger OnValidate()
            begin
                if (xRec."Special Order" <> "Special Order") and (Quantity <> 0) then
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5714; "Special Order Sales No."; Code[20])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Sales No.';
            TableRelation = if ("Special Order" = const(true)) "Sales Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                if (xRec."Special Order Sales No." <> "Special Order Sales No.") and (Quantity <> 0) then
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5715; "Special Order Sales Line No."; Integer)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Sales Line No.';
            TableRelation = if ("Special Order" = const(true)) "Sales Line"."Line No." where("Document Type" = const(Order),
                                                                                            "Document No." = field("Special Order Sales No."));

            trigger OnValidate()
            begin
                if (xRec."Special Order Sales Line No." <> "Special Order Sales Line No.") and (Quantity <> 0) then
                    PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
            end;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                GetPurchHeader();
                ItemReferenceMgt.PurchaseReferenceNoLookUp(Rec, PurchHeader);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                GetPurchHeader();
                "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                ItemReferenceMgt.ValidatePurchaseReferenceNo(Rec, PurchHeader, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference Unit of Measure';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Location = R;
            BlankZero = true;
            CalcFormula = sum("Warehouse Receipt Line"."Qty. Outstanding (Base)" where("Source Type" = const(39),
#pragma warning disable AL0603
                                                                                        "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                        "Source No." = field("Document No."),
                                                                                        "Source Line No." = field("Line No.")));
            Caption = 'Whse. Outstanding Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Received"; Boolean)
        {
            Caption = 'Completely Received';
            Editable = false;
        }
        field(5790; "Requested Receipt Date"; Date)
        {
            Caption = 'Requested Receipt Date';
            ToolTip = 'Specifies the date that you want the vendor to deliver to the ship-to address. The value in the field is used to calculate the latest date you can order the items to have them delivered on the requested receipt date. If you do not need delivery on a specific date, you can leave the field blank.';

            trigger OnValidate()
            var
                CustomCalendarChange: array[2] of Record "Customized Calendar Change";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateRequestedReceiptDate(Rec, xRec, CustomCalendarChange, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if (CurrFieldNo <> 0) and
                   ("Promised Receipt Date" <> 0D)
                then
                    Error(
                      Text023,
                      FieldCaption("Requested Receipt Date"),
                      FieldCaption("Promised Receipt Date"));

                if "Requested Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    UpdateOrderDateFromRequestedReceiptDate(CustomCalendarChange);
                end else
                    if "Requested Receipt Date" <> xRec."Requested Receipt Date" then
                        GetUpdateBasicDates();
            end;
        }
        field(5791; "Promised Receipt Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Receipt Date';
            ToolTip = 'Specifies the date that the vendor has promised to deliver the order.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePromisedReceiptDate(Rec, CurrFieldNo, IsHandled, xRec);
                if IsHandled then
                    exit;

                if CurrFieldNo <> 0 then
                    if "Promised Receipt Date" <> 0D then
                        Validate("Planned Receipt Date", "Promised Receipt Date")
                    else
                        Validate("Requested Receipt Date")
                else
                    Validate("Planned Receipt Date", "Promised Receipt Date");
            end;
        }
        field(5792; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLeadTimeCalculation(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                LeadTimeMgt.CheckLeadTimeIsNotNegative("Lead Time Calculation");

                if "Requested Receipt Date" <> 0D then
                    Validate("Planned Receipt Date")
                else
                    GetUpdateBasicDates();
            end;
        }
        field(5793; "Inbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                if ("Promised Receipt Date" <> 0D) or
                   ("Requested Receipt Date" <> 0D)
                then
                    Validate("Planned Receipt Date")
                else
                    Validate("Expected Receipt Date");
            end;
        }
        field(5794; "Planned Receipt Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Receipt Date';

            trigger OnValidate()
            var
                CustomCalendarChange: array[2] of Record "Customized Calendar Change";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlannedReceiptDate(Rec, xRec, CurrFieldNo, TrackingBlocked, IsHandled);
                if IsHandled then
                    exit;

                if "Promised Receipt Date" <> 0D then begin
                    if "Planned Receipt Date" <> 0D then begin
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        "Expected Receipt Date" :=
                          CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                    end else
                        "Expected Receipt Date" := "Planned Receipt Date";
                end else
                    if "Planned Receipt Date" <> 0D then begin
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        UpdateOrderDateFromPlannedReceiptDate(CustomCalendarChange);
                        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                        "Expected Receipt Date" :=
                          CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                    end else
                        if "Requested Receipt Date" <> 0D then
                            Validate("Requested Receipt Date")
                        else
                            GetUpdateBasicDates();

                if not TrackingBlocked then
                    CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
            end;
        }
        field(5795; "Order Date"; Date)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Order Date';

            trigger OnValidate()
            var
                CustomCalendarChange: array[2] of Record "Customized Calendar Change";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateOrderDate(Rec, xRec, CurrFieldNo, TrackingBlocked, IsHandled);
                if IsHandled then
                    exit;

                if (CurrFieldNo <> 0) and
                   ("Document Type" = "Document Type"::Order) and
                   ("Order Date" < WorkDate()) and
                   ("Order Date" <> 0D)
                then
                    ShowEarlyOrderDateMessage();

                if "Order Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, "Buy-from Vendor No.", '', '');
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    UpdatePlannedReceiptDateFromOrderDate(CustomCalendarChange);
                end;

                if "Planned Receipt Date" <> 0D then begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    "Expected Receipt Date" :=
                      CalendarMgmt.CalcDateBOC(InternalLeadTimeDays("Planned Receipt Date"), "Planned Receipt Date", CustomCalendarChange, false)
                end else
                    "Expected Receipt Date" := "Planned Receipt Date";

                if not TrackingBlocked then begin
                    IsHandled := false;
                    OnValidateOrderDateOnBeforeCheckDateConflict(Rec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        CheckDateConflict.PurchLineCheck(Rec, CurrFieldNo <> 0);
                end;


                OnAfterValidateOrderDate(Rec, xRec, CurrFieldNo);
            end;
        }
        field(5800; "Allow Item Charge Assignment"; Boolean)
        {
            AccessByPermission = TableData "Item Charge" = R;
            Caption = 'Allow Item Charge Assignment';
            InitValue = true;

            trigger OnValidate()
            begin
                CheckItemChargeAssgnt();
            end;
        }
        field(5801; "Qty. to Assign"; Decimal)
        {
            CalcFormula = sum("Item Charge Assignment (Purch)"."Qty. to Assign" where("Document Type" = field("Document Type"),
                                                                                       "Document No." = field("Document No."),
                                                                                       "Document Line No." = field("Line No.")));
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5802; "Qty. Assigned"; Decimal)
        {
            CalcFormula = sum("Item Charge Assignment (Purch)"."Qty. Assigned" where("Document Type" = field("Document Type"),
                                                                                      "Document No." = field("Document No."),
                                                                                      "Document Line No." = field("Line No.")));
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5803; "Return Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Qty. to Ship';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if (CurrFieldNo <> 0) and
                   IsInventoriableItem() and
                   ("Return Qty. to Ship" <> 0) and
                   (not "Drop Shipment")
                then
                    CheckWarehouse(true);

                "Return Qty. to Ship" := UOMMgt.RoundAndValidateQty("Return Qty. to Ship", "Qty. Rounding Precision", FieldCaption("Return Qty. to Ship"));

                OnValidateReturnQtyToShipOnAfterCheck(Rec, CurrFieldNo);

                if "Return Qty. to Ship" = Quantity - "Return Qty. Shipped" then
                    InitQtyToShip()
                else begin
                    "Return Qty. to Ship (Base)" := CalcBaseQty("Return Qty. to Ship", FieldCaption("Return Qty. to Ship"), FieldCaption("Return Qty. to Ship (Base)"));
                    if "Qty. per Unit of Measure" <> 0 then
                        ValidateQuantityReturnIsBalanced();
                    InitQtyToInvoice();
                end;

                IsHandled := false;
                OnValidateReturnQtyToShipOnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ("Return Qty. to Ship" * Quantity < 0) or
                       (Abs("Return Qty. to Ship") > Abs("Outstanding Quantity")) or
                       (Quantity * "Outstanding Quantity" < 0)
                    then
                        Error(Text020, "Outstanding Quantity");
                    if ("Return Qty. to Ship (Base)" * "Quantity (Base)" < 0) or
                       (Abs("Return Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)")) or
                       ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                    then
                        Error(Text021, "Outstanding Qty. (Base)");
                end;

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Return Qty. to Ship" > 0) then
                    CheckApplToItemLedgEntry();
            end;
        }
        field(5804; "Return Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Return Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReturnQtytoShipBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Return Qty. to Ship", "Return Qty. to Ship (Base)");
            end;
        }
        field(5805; "Return Qty. Shipped Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Shipped Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5806; "Ret. Qty. Shpd Not Invd.(Base)"; Decimal)
        {
            Caption = 'Ret. Qty. Shpd Not Invd.(Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5807; "Return Shpd. Not Invd."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd.';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetPurchHeader();
                Currency2.InitRoundingPrecision();
                if PurchHeader."Currency Code" <> '' then
                    "Return Shpd. Not Invd. (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Return Shpd. Not Invd.", PurchHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Return Shpd. Not Invd. (LCY)" :=
                      Round("Return Shpd. Not Invd.", Currency2."Amount Rounding Precision");
            end;
        }
        field(5808; "Return Shpd. Not Invd. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Return Shpd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809; "Return Qty. Shipped"; Decimal)
        {
            AccessByPermission = TableData "Return Shipment Header" = R;
            Caption = 'Return Qty. Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5810; "Return Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Return Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5812; "Item Charge Qty. to Handle"; Decimal)
        {
            CalcFormula = sum("Item Charge Assignment (Purch)"."Qty. to Handle" where("Document Type" = field("Document Type"),
                                                                                       "Document No." = field("Document No."),
                                                                                       "Document Line No." = field("Line No.")));
            Caption = 'Item Charge Qty. to Handle';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            Caption = 'Non-Deductible VAT %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                NonDeductibleVAT.CheckPrepmtWithNonDeductubleVATInPurchaseLine(Rec);
                NonDeductibleVAT.CheckNonDeductibleVATPctIsAllowed(Rec);
                UpdateAmounts();
            end;
        }
        field(6201; "Non-Deductible VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Base';
            Editable = false;
        }
        field(6202; "Non-Deductible VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Non-Deductible VAT Amount';
            Editable = false;
        }
        field(6203; "Non-Deductible VAT Diff."; Decimal)
        {
            Caption = 'Non-Deductible VAT Difference';
            Editable = false;
        }
        field(6204; "Prepmt. Non-Deduct. VAT Base"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Prepmt.  Non-Deductible VAT Base';
            Editable = false;
        }
        field(6205; "Prepmt. Non-Deduct. VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Prepmt. on-Deductible VAT Amount';
            Editable = false;
        }
        field(6600; "Return Shipment No."; Code[20])
        {
            Caption = 'Return Shipment No.';
            Editable = false;
        }
        field(6601; "Return Shipment Line No."; Integer)
        {
            Caption = 'Return Shipment Line No.';
            Editable = false;
        }
        field(6608; "Return Reason Code"; Code[10])
        {
            Caption = 'Return Reason Code';
            TableRelation = "Return Reason";

            trigger OnValidate()
            begin
                ValidateReturnReasonCode(FieldNo("Return Reason Code"));
            end;
        }
        field(6609; Subtype; Option)
        {
            Caption = 'Subtype';
            OptionCaption = ' ,Item - Inventory,Item - Service,Comment';
            OptionMembers = " ","Item - Inventory","Item - Service",Comment;
        }
        field(6610; "Copied From Posted Doc."; Boolean)
        {
            Caption = 'Copied From Posted Doc.';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7010; "Attached Doc Count"; Integer)
        {
            BlankNumbers = DontBlank;
            CalcFormula = count("Document Attachment" where("Table ID" = const(39),
                                                             "No." = field("Document No."),
                                                             "Document Type" = field("Document Type"),
                                                             "Line No." = field("Line No.")));
            Caption = 'Attached Doc Count';
            FieldClass = FlowField;
            InitValue = 0;
        }
        field(7011; "Attached Lines Count"; Integer)
        {
            CalcFormula = count("Purchase Line" where("Document Type" = field("Document Type"),
                                                       "Document No." = field("Document No."),
                                                       "Attached to Line No." = field("Line No."),
                                                       Quantity = filter(<> 0)));
            Caption = 'Attached Lines Count';
            Editable = false;
            FieldClass = FlowField;
            BlankZero = true;
        }
        field(8509; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                OverReceiptCode: Record "Over-Receipt Code";
                PurchaseHeader: Record "Purchase Header";
                OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
                Handled: Boolean;
            begin
                OnValidateOverReceiptQuantity(Rec, xRec, CurrFieldNo, Handled);
                if Handled then
                    exit;
                if not OverReceiptMgt.IsOverReceiptAllowed() then begin
                    "Over-Receipt Quantity" := 0;
                    "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::" ";
                    exit;
                end;

                if xRec."Over-Receipt Quantity" = "Over-Receipt Quantity" then
                    exit;
                PurchaseHeader.Get(Rec."Document Type", Rec."Document No.");
                PurchaseHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
                PurchaseHeader.TestField(Status, PurchHeader.Status::Released);
                TestField(Type, Type::Item);
                TestField("No.");
                if "Over-Receipt Quantity" <> 0 then begin
                    if "Over-Receipt Code" = '' then
                        "Over-Receipt Code" := OverReceiptMgt.GetDefaultOverReceiptCode(Rec);
                    TestField("Over-Receipt Code");
                end;
                if "Over-Receipt Quantity" <> 0 then
                    CheckLocationRequireReceive();

                if ("Over-Receipt Code" <> '') then begin
                    OverReceiptMgt.VerifyOverReceiptQuantity(Rec, xRec);
                    OverReceiptCode.Get("Over-Receipt Code");
                    if OverReceiptCode."Required Approval" then
                        "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::Pending;
                end;

                SuspendStatusCheck(true);
                Validate(Quantity, Quantity - xRec."Over-Receipt Quantity" + "Over-Receipt Quantity");
                Validate("Direct Unit Cost");
                if "Over-Receipt Quantity" = 0 then begin
                    "Over-Receipt Approval Status" := "Over-Receipt Approval Status"::" ";
                    OverReceiptMgt.RecallOverReceiptNotification(PurchaseHeader.RecordId());
                end else
                    OverReceiptMgt.ShowOverReceiptNotificationFromLine(PurchaseHeader."No.");
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";

            trigger OnValidate()
            begin
                if ((Rec."Over-Receipt Code" = '') and (xRec."Over-Receipt Code" <> '')) then
                    Validate("Over-Receipt Quantity", 0);
            end;
        }
        field(8511; "Over-Receipt Approval Status"; Enum "Over-Receipt Approval Status")
        {
            Caption = 'Over-Receipt Approval Status';
        }
        field(8512; "Buy-from Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Buy-from Vendor No.")));
            Caption = 'Buy-from Vendor Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12100; "No. of Fixed Asset Cards"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Fixed Asset Cards';
            ToolTip = 'Specifies the number of fixed assets that is being purchased.';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "No. of Fixed Asset Cards" <> 0 then begin
                    TestField(Type, Type::"Fixed Asset");
                    CheckAcquisitionCost();
                    if not ("Document Type" in ["Purchase Document Type"::Invoice, "Purchase Document Type"::Order]) then
                        Error(InvoiceOrOrderDocTypeErr, FieldCaption("Document Type"), "Purchase Document Type"::Invoice, "Purchase Document Type"::Order);
                end;
            end;
        }
        field(99000755; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(99000756; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000757; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    PurchLineReserve.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000758; "Safety Lead Time"; DateFormula)
        {
            Caption = 'Safety Lead Time';

            trigger OnValidate()
            begin
                Validate("Inbound Whse. Handling Time");
            end;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date")
        {
            IncludedFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Document Type", "Pay-to Vendor No.", "Currency Code", "Document No.")
        {
#pragma warning disable AS0038
            IncludedFields = "Outstanding Amount", "Amt. Rcd. Not Invoiced", "Outstanding Amount (LCY)", "Amt. Rcd. Not Invoiced (LCY)", "Prepmt. Amount Inv. (LCY)", "Prepmt. VAT Amount Inv. (LCY)";
#pragma warning RESTORE AS0038
        }
        key(Key7; "Document Type", "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key9; "Document Type", "Document No.", "Location Code")
        {
            IncludedFields = Amount, "Amount Including VAT", "VAT Base Amount";
        }
        key(Key10; "Document Type", "Receipt No.", "Receipt Line No.")
        {
            IncludedFields = Quantity;
        }
        key(Key11; Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Expected Receipt Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key12; "Document Type", "Buy-from Vendor No.")
        {
        }
        key(Key13; "Document Type", "Job No.", "Job Task No.", "Document No.")
        {
            IncludedFields = "Outstanding Amt. Ex. VAT (LCY)", "A. Rcd. Not Inv. Ex. VAT (LCY)";
        }
        key(Key16; "Recalculate Invoice Disc.")
        {
        }
        key(Key18; "Location Code", "Quantity Invoiced")
        {
        }
        key(Key19; "Completely Received")
        {
            IncludedFields = Type, "Location Code";
        }
        key(Key20; "Document Type", "Document No.", "Drop Shipment")
        {
            IncludedFields = Quantity;
        }
        key(Key21; "Document Type", "Document No.", Type, "No.", "System-Created Entry")
        {
            IncludedFields = Quantity, "Outstanding Quantity", "Return Qty. Shipped", "Quantity Received", "Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount";
        }
        key(Key22; "Document Type", "Document No.", "VAT Identifier", "Line No.")
        {
            IncludedFields = "VAT %", "Tax Area Code", "Tax Group Code", "VAT Calculation Type", "Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)", "VAT Difference";
        }
        key(Key23; "Attached to Line No.")
        {
        }
        key(Key24; "No.", Type)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code")
        {
        }
    }

    trigger OnDelete()
    var
        PurchCommentLine: Record "Purch. Comment Line";
        SalesOrderLine: Record "Sales Line";
        IsHandled: Boolean;
        ShouldModifySalesOrderLine: Boolean;
    begin
        IsHandled := false;
        OnDeleteOnBeforeTestStatusOpen(Rec, IsHandled);
        if not IsHandled then
            TestStatusOpen();

        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            PurchLineReserve.DeleteLine(Rec);
            IsHandled := false;
            OnDeleteOnBeforeCheckQtyNotInvoiced(Rec, IsHandled);
            if not IsHandled then begin
                if "Receipt No." = '' then
                    TestField("Qty. Rcd. Not Invoiced", 0);
                if "Return Shipment No." = '' then
                    TestField("Return Qty. Shipped Not Invd.", 0);
            end;

            IsHandled := false;
            OnDeleteOnBeforePurchaseLineDelete(Rec, IsHandled);
            if not IsHandled then begin
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                PurchasesWarehouseMgt.PurchaseLineDelete(Rec);
            end;
        end;

        if ("Document Type" = "Document Type"::Order) and (Quantity <> "Quantity Invoiced") then
            TestField("Prepmt. Amt. Inv.", "Prepmt Amt Deducted");

        ShouldModifySalesOrderLine := "Sales Order Line No." <> 0;
        OnDeleteOnAfterCalcShouldModifySalesOrderLine(Rec, ShouldModifySalesOrderLine);
        if ShouldModifySalesOrderLine then begin
            LockTable();
            SalesOrderLine.LockTable();
            SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
            SalesOrderLine."Purchase Order No." := '';
            SalesOrderLine."Purch. Order Line No." := 0;
            SalesOrderLine.Modify();
        end;

        UpdateSpecialSalesOrderLineFromOnDelete(SalesOrderLine);

        CatalogItemMgt.DelNonStockPurch(Rec);

        if "Document Type" = "Document Type"::"Blanket Order" then begin
            PurchLine2.Reset();
            PurchLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchLine2.SetRange("Blanket Order No.", "Document No.");
            PurchLine2.SetRange("Blanket Order Line No.", "Line No.");
            OnDeleteOnAfterSetPurchLineFilters(PurchLine2);
            if PurchLine2.FindFirst() then
                PurchLine2.TestField("Blanket Order Line No.", 0);
        end;

        if Type = Type::Item then
            DeleteItemChargeAssignment("Document Type", "Document No.", "Line No.");

        if Type = Type::"Charge (Item)" then
            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");

        if "Line No." <> 0 then begin
            PurchLine2.Reset();
            PurchLine2.SetRange("Document Type", "Document Type");
            PurchLine2.SetRange("Document No.", "Document No.");
            PurchLine2.SetRange("Attached to Line No.", "Line No.");
            PurchLine2.SetFilter("Line No.", '<>%1', "Line No.");
            OnDeleteOnBeforePurchLineDeleteAll(PurchLine2);
            PurchLine2.DeleteAll(true);
            OnDeleteOnAfterPurchLineDeleteAll(Rec, PurchLine2);
        end;

        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "Document No.");
        PurchCommentLine.SetRange("Document Line No.", "Line No.");
        if not PurchCommentLine.IsEmpty() then
            PurchCommentLine.DeleteAll();

        // In case we have roundings on VAT or Sales Tax, we should update some other line
        if (Type <> Type::" ") and ("Line No." <> 0) and not IsExtendedText() and
           (Quantity <> 0) and (Amount <> 0) and (Amount <> "Amount Including VAT") and not StatusCheckSuspended
        then begin
            Quantity := 0;
            "Quantity (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Line Discount Amount" := 0;
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
            OnDeleteOnBeforeUpdateAmounts(Rec);
            UpdateAmounts();
            OnDeleteOnAfterUpdateAmounts(Rec);
        end;

        if "Deferral Code" <> '' then
            DeferralUtilities.DeferralCodeOnDelete(
                Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
                "Document Type".AsInteger(), "Document No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
        if not HasPurchHeader then
            Error(CannotInsertPurchLineWithoutHeaderErr);

        if Quantity <> 0 then begin
            OnBeforeVerifyReservedQty(Rec, xRec, 0);
            PurchLineReserve.VerifyQuantity(Rec, xRec);
        end;
        LockTable();
        OnInsertOnAfterLockTable(Rec, CurrFieldNo);
        if ("Deferral Code" <> '') and (GetDeferralAmount() <> 0) then
            UpdateDeferralAmounts();
        PurchHeader."No." := '';
    end;

    trigger OnModify()
    begin
        if ("Document Type" = "Document Type"::"Blanket Order") and
           ((Type <> xRec.Type) or ("No." <> xRec."No."))
        then begin
            PurchLine2.Reset();
            PurchLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            PurchLine2.SetRange("Blanket Order No.", "Document No.");
            PurchLine2.SetRange("Blanket Order Line No.", "Line No.");
            OnModifyOnAfterSetFilters(Rec, PurchLine2);
            if PurchLine2.FindSet() then
                repeat
                    PurchLine2.TestField(Type, Type);
                    PurchLine2.TestField("No.", "No.");
                until PurchLine2.Next() = 0;
        end;

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") then
            PurchLineReserve.VerifyChange(Rec, xRec);
        OnAfterModifyOnAfterVerifyChange(Rec, CurrFieldNo);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        PurchHeader: Record "Purchase Header";
        PurchLine2: Record "Purchase Line";
        GLAcc: Record "G/L Account";
        CurrExchRate: Record "Currency Exchange Rate";
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ItemCharge: Record "Item Charge";
        SKU: Record "Stockkeeping Unit";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        GLSetup: Record "General Ledger Setup";
        CalChange: Record "Customized Calendar Change";
        TempJobJnlLine: Record "Job Journal Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        PurchasesWarehouseMgt: Codeunit "Purchases Warehouse Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        ItemReferenceMgt: Codeunit "Item Reference Management";
        CatalogItemMgt: Codeunit "Catalog Item Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CalendarMgmt: Codeunit "Calendar Management";
        CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
        DeferralUtilities: Codeunit "Deferral Utilities";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        FieldCausedPriceCalculation: Integer;
        GLSetupRead: Boolean;
        UnitCostCurrency: Decimal;
        UpdateFromVAT: Boolean;
        HasBeenShown: Boolean;
        PrePaymentLineAmountEntered: Boolean;
        PurchSetupRead: Boolean;
        HasPurchHeader: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change %1 because the order line is associated with sales order %2.';
        Text002: Label 'Prices including VAT cannot be calculated when %1 is %2.';
        Text004: Label 'must not be less than %1';
#pragma warning restore AA0470
        Text006: Label 'You can''t invoice more than %1 units.', Comment = '%1 - the field value';
#pragma warning disable AA0470
        Text007: Label 'You cannot invoice more than %1 base units.';
        Text008: Label 'You cannot receive more than %1 units.';
        Text009: Label 'You cannot receive more than %1 base units.';
        Text010: Label 'You cannot change %1 when %2 is %3.';
        Text011: Label ' must be 0 when %1 is %2';
        Text016: Label '%1 is required for %2 = %3.';
        Text018: Label '%1 %2 is earlier than the work date %3.';
        Text020: Label 'You cannot return more than %1 units.';
        Text021: Label 'You cannot return more than %1 base units.';
        Text022: Label 'You cannot change %1, if item charge is already posted.';
        Text023: Label 'You cannot change the %1 when the %2 has been filled in.';
#pragma warning restore AA0470
        Text029: Label 'must be positive.';
        Text030: Label 'must be negative.';
#pragma warning disable AA0470
        Text032: Label '%1 must not be greater than the sum of %2 and %3.';
#pragma warning restore AA0470
        Text033: Label 'Warehouse ';
        Text034: Label 'Inventory ';
#pragma warning disable AA0470
        Text035: Label '%1 units for %2 %3 have already been returned or transferred. Therefore, only %4 units can be returned.';
        Text037: Label 'cannot be %1.';
        Text038: Label 'cannot be less than %1.';
        Text039: Label 'cannot be more than %1.';
        Text042: Label 'You cannot return more than the %1 units that you have received for %2 %3.';
        Text043: Label 'must be positive when %1 is not 0.';
        Text046: Label '%3 will not update %1 when changing %2 because a prepayment invoice has been posted. Do you want to continue?', Comment = '%1 - product name';
        Text047: Label '%1 can only be set when %2 is set.';
        Text048: Label '%1 cannot be changed when %2 is set.';
        Text049: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
#pragma warning restore AA0470
        Text050: Label 'Cancelled.';
        Text051: Label 'must have the same sign as the receipt';
#pragma warning disable AA0470
        Text052: Label 'The quantity that you are trying to invoice is greater than the quantity in receipt %1.';
#pragma warning restore AA0470
        Text053: Label 'must have the same sign as the return shipment';
#pragma warning disable AA0470
        Text054: Label 'The quantity that you are trying to invoice is greater than the quantity in return shipment %1.';
        Text99000000: Label 'You cannot change %1 when the purchase order is associated to a production order.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MustNotBeSpecifiedErr: Label 'must not be specified when %1 = %2', Comment = '%1 - the field name, %2 - the field value';
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1=Document';
        QtyInvoiceNotValidTitleLbl: Label 'Qty. to Invoice isn''t valid';
        QtyInvoiceActionLbl: Label 'Set value to %1', Comment = '%1 - Qty. to Invoice';
        QtyInvoiceActionDescriptionLbl: Label 'Corrects %1 value to %2', Comment = '%1 - Qty. to Invoice field caption, %2 - Quantity';
        QtyReceiveNotValidTitleLbl: Label 'Qty. to Receive isn''t valid';
        QtyReceiveActionLbl: Label 'Set value to %1', comment = '%1=Qty. to Receive';
        QtyReceiveActionDescriptionLbl: Label 'Corrects %1 value to %2', Comment = '%1 - Qty. to Receive field caption, %2 - Quantity';
        ItemChargeAssignmentErr: Label 'You can only assign Item Charges for Line Types of Charge (Item).';
        CannotFindDescErr: Label 'Cannot find %1 with Description %2.\\Make sure to use the correct type.', Comment = '%1 = Type caption %2 = Description';
        CommentLbl: Label 'Comment';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        PurchasingBlockedErr: Label 'You cannot purchase %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption';
        CannotChangePrepaidServiceChargeErr: Label 'You cannot change the line because it will affect service charges that are already invoiced as part of a prepayment.';
        LineInvoiceDiscountAmountResetTok: Label 'The value in the Inv. Discount Amount field in %1 has been cleared.', Comment = '%1 - Record ID';
        BlockedItemNotificationMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 is Item No.';
        BlockedItemVariantNotificationMsg: Label 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item Variant Code, %2 - Item No.';
        InvDiscForPrepmtExceededErr: Label 'You cannot enter an invoice discount for purchase document %1.\\You must cancel the prepayment invoice first and then you will be able to update the invoice discount.', Comment = '%1 - document number';
        CannotAllowInvDiscountErr: Label 'The value of the %1 field is not valid when the VAT Calculation Type field is set to "Full VAT".', Comment = '%1 is the name of not valid field';
        CannotChangeVATGroupWithPrepmInvErr: Label 'You cannot change the VAT product posting group because prepayment invoices have been posted.\\You need to post the prepayment credit memo to be able to change the VAT product posting group.';
        CannotChangePrepmtAmtDiffVAtPctErr: Label 'You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage. Please check the settings on the prepayment G/L account.';
        LineAmountInvalidErr: Label 'You have set the line amount to a value that results in a discount that is not valid. Consider increasing the unit cost instead.';
        ChangeExtendedTextErr: Label 'You cannot change %1 for Extended Text Line.', Comment = '%1= Field Caption';
        InvoiceOrOrderDocTypeErr: Label '%1 must be either %2 or %3.', Comment = '%1 - Document Type; %2, %3 - Purchase Document Type, Invoice or Order';
        CannotInsertPurchLineWithoutHeaderErr: Label 'You cannot insert a purchase line without a purchase header.';
        MustSpecifyErr: Label 'You must either specify %1 or %2.', Comment = '%1 = Field Caption; %2 = Field Caption';

    protected var
        Currency: Record Currency;
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;
        SkipTaxCalculation: Boolean;
        TrackingBlocked: Boolean;

    /// <summary>
    /// Initializes outstanding quantities and amounts of the purchase line.
    /// </summary>
    procedure InitOutstanding()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstanding(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then begin
            "Outstanding Quantity" := Quantity - "Return Qty. Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Shipped (Base)";
            "Return Qty. Shipped Not Invd." := "Return Qty. Shipped" - "Quantity Invoiced";
            "Ret. Qty. Shpd Not Invd.(Base)" := "Return Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Received";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Received (Base)";
            "Qty. Rcd. Not Invoiced" := "Quantity Received" - "Quantity Invoiced";
            "Qty. Rcd. Not Invoiced (Base)" := "Qty. Received (Base)" - "Qty. Invoiced (Base)";
        end;

        OnAfterInitOutstandingQty(Rec, xRec);
        "Completely Received" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        OnInitOutstandingOnBeforeInitOutstandingAmount(Rec, xRec);
        InitOutstandingAmount();
    end;

    /// <summary>
    /// Initializes the outstanding amounts of the purchase line.
    /// </summary>
    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
    begin
        if Quantity = 0 then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Outstanding Amt. Ex. VAT (LCY)" := 0;
            "Amt. Rcd. Not Invoiced" := 0;
            "Amt. Rcd. Not Invoiced (LCY)" := 0;
            "Return Shpd. Not Invd." := 0;
            "Return Shpd. Not Invd. (LCY)" := 0;
        end else begin
            GetPurchHeader();
            AmountInclVAT := "Amount Including VAT";
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if IsCreditDocType() then
                Validate(
                  "Return Shpd. Not Invd.",
                  Round(
                    AmountInclVAT * "Return Qty. Shipped Not Invd." / Quantity,
                    Currency."Amount Rounding Precision"))
            else
                Validate(
                  "Amt. Rcd. Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Rcd. Not Invoiced" / Quantity,
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, xRec, PurchHeader, Currency);
    end;

    /// <summary>
    /// Initializes the quantity to receive and quantity to invoice of the purchase line.
    /// </summary>
    procedure InitQtyToReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if (PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Remainder) or
           ("Document Type" = "Document Type"::Invoice)
        then begin
            "Qty. to Receive" := "Outstanding Quantity";
            "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Qty. to Receive" <> 0 then
                "Qty. to Receive (Base)" :=
                  MaxQtyToReceiveBase(CalcBaseQty("Qty. to Receive", FieldCaption("Qty. to Receive"), FieldCaption("Qty. to Receive (Base)")));
        OnAfterInitQtyToReceive(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    /// <summary>
    /// Initializes the return quantity to ship and quantity to invoice of the purchase line.
    /// </summary>
    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if (PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Remainder) or
           ("Document Type" = "Document Type"::"Credit Memo")
        then begin
            "Return Qty. to Ship" := "Outstanding Quantity";
            "Return Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Return Qty. to Ship" <> 0 then
                "Return Qty. to Ship (Base)" := CalcBaseQty("Return Qty. to Ship", FieldCaption("Return Qty. to Ship"), FieldCaption("Return Qty. to Ship (Base)"));
        OnAfterInitQtyToShip(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    /// <summary>
    /// Initializes the quantity to invoice and vat of the purchase line.
    /// Calculates invoice disc. amount to invoice.
    /// </summary>
    /// <remarks>
    /// If document type is not an invoice, prepayment amount to deduct is calculated.
    /// </remarks>
    procedure InitQtyToInvoice()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToInvoice(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();
        "VAT Difference" := 0;
        NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);

        OnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        CalcInvDiscToInvoice();
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then
            CalcPrepaymentToDeduct();

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    local procedure InitOutstandingAndQtyToShipReceive(var TempPurchLine: Record "Purchase Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingAndQtyToShipReceive(Rec, TempPurchLine, IsHandled, xRec);
        if IsHandled then
            exit;

        if Quantity <> 0 then begin
            InitOutstanding();
            if IsCreditDocType() then
                InitQtyToShip()
            else
                InitQtyToReceive();
        end;
    end;

    local procedure InitItemAppl()
    begin
        "Appl.-to Item Entry" := 0;
    end;

    procedure InitHeaderDefaults(PurchHeader: Record "Purchase Header"; var TempPurchLine: Record "Purchase Line" temporary)
    var
        IsHandled: Boolean;
    begin
        CheckBuyFromVendorNo(PurchHeader);

        "Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
        "Currency Code" := PurchHeader."Currency Code";
        "Expected Receipt Date" := PurchHeader."Expected Receipt Date";
        "Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PurchHeader."Dimension Set ID";
        "Location Code" := PurchHeader."Location Code";
        "Transaction Type" := PurchHeader."Transaction Type";
        "Transport Method" := PurchHeader."Transport Method";
        "Pay-to Vendor No." := PurchHeader."Pay-to Vendor No.";
        "Price Calculation Method" := PurchHeader."Price Calculation Method";
        "Gen. Bus. Posting Group" := PurchHeader."Gen. Bus. Posting Group";
        IsHandled := false;
        OnInitHeaderDefaultsOnBeforeSetVATBusPostingGroup(Rec, IsHandled);
        if not IsHandled then
            "VAT Bus. Posting Group" := PurchHeader."VAT Bus. Posting Group";
        "Entry Point" := PurchHeader."Entry Point";
        Area := PurchHeader.Area;
        "Transaction Specification" := PurchHeader."Transaction Specification";
        "Tax Area Code" := PurchHeader."Tax Area Code";
        "Tax Liable" := PurchHeader."Tax Liable";
        if not "System-Created Entry" and ("Document Type" = "Document Type"::Order) and HasTypeToFillMandatoryFields() or
           IsServiceCharge()
        then
            "Prepayment %" := PurchHeader."Prepayment %";
        "Prepayment Tax Area Code" := PurchHeader."Tax Area Code";
        "Prepayment Tax Liable" := PurchHeader."Tax Liable";
        "Responsibility Center" := PurchHeader."Responsibility Center";
        "Requested Receipt Date" := PurchHeader."Requested Receipt Date";
        "Promised Receipt Date" := PurchHeader."Promised Receipt Date";
        "Inbound Whse. Handling Time" := PurchHeader."Inbound Whse. Handling Time";
        "Order Date" := PurchHeader."Order Date";

        OnAfterInitHeaderDefaults(Rec, PurchHeader, TempPurchLine);
    end;

    local procedure InitJobFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitJobFields(Rec, xRec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Job No." <> xRec."Job No." then begin
            Validate("Job Task No.", '');
            Validate("Job Planning Line No.", 0);
        end;
    end;

    /// <summary>
    /// Calculates maximum quantity that can be invoiced for the purchase line.
    /// </summary>
    /// <returns>Maximum quantity that can be invoiced.</returns>
    procedure MaxQtyToInvoice(): Decimal
    var
        MaxQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoice(Rec, MaxQty, IsHandled);
        if IsHandled then
            exit(MaxQty);

        if "Prepayment Line" then
            exit(1);

        if IsCreditDocType() then
            exit("Return Qty. Shipped" + "Return Qty. to Ship" - "Quantity Invoiced");
        if "Document Type" = "Document Type"::"Blanket Order" then
            exit(Quantity - "Quantity Invoiced");
        exit("Quantity Received" + "Qty. to Receive" - "Quantity Invoiced");
    end;

    /// <summary>
    /// Calculates maximum quantity (base) that can be invoiced for the purchase line.
    /// </summary>
    /// <returns>Maximum quantity (base) that can be invoiced.</returns>
    procedure MaxQtyToInvoiceBase(): Decimal
    var
        MaxQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMaxQtyToInvoiceBase(Rec, MaxQtyBase, IsHandled);
        if IsHandled then
            exit(MaxQtyBase);

        if IsCreditDocType() then
            exit("Return Qty. Shipped (Base)" + "Return Qty. to Ship (Base)" - "Qty. Invoiced (Base)");
        if "Document Type" = "Document Type"::"Blanket Order" then
            exit("Quantity (Base)" - "Qty. Invoiced (Base)");
        exit("Qty. Received (Base)" + "Qty. to Receive (Base)" - "Qty. Invoiced (Base)");
    end;

    /// <summary>
    /// Returns the maximum quantity (base) that can be received for a given quantity.
    /// </summary>
    /// <param name="QtyToReceiveBase">Quantity (base).</param>
    /// <returns>The maximum quantity (base) thant can be received.</returns>
    procedure MaxQtyToReceiveBase(QtyToReceiveBase: Decimal): Decimal
    begin
        if Abs(QtyToReceiveBase) > Abs("Outstanding Qty. (Base)") then
            exit("Outstanding Qty. (Base)");

        exit(QtyToReceiveBase);
    end;

    internal procedure GetVatBaseDiscountPct(PurchaseHeader: Record "Purchase Header") Result: Decimal
    begin
        Result := PurchaseHeader."VAT Base Discount %";
        OnAfterGetVatBaseDiscountPct(Rec, PurchaseHeader, Result);
    end;

    /// <summary>
    /// Calculates and sets the invoices discount amount to invoice and updates vat.
    /// </summary>
    procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvDiscToInvoiceProcedure(Rec, Currency, IsHandled);
        if not IsHandled then begin
            GetPurchHeader();
            OldInvDiscAmtToInv := "Inv. Disc. Amount to Invoice";
            if Quantity = 0 then
                Validate("Inv. Disc. Amount to Invoice", 0)
            else
                Validate(
                  "Inv. Disc. Amount to Invoice",
                  Round(
                    "Inv. Discount Amount" * "Qty. to Invoice" / Quantity,
                    Currency."Amount Rounding Precision"));

            if OldInvDiscAmtToInv <> "Inv. Disc. Amount to Invoice" then begin
                "Amount Including VAT" := "Amount Including VAT" - "VAT Difference";
                ClearVATDifference();
                NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
            end;
            NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));

        end;
        OnAfterCalcInvDiscToInvoice(Rec, OldInvDiscAmtToInv);
    end;

    /// <summary>
    /// Calculates the line amount minus inv. discount amount for the purchase line.
    /// </summary>
    /// <returns>Line amount minus inv. discount amount.</returns>
    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    local procedure CanReceiveQty(): Boolean
    begin
        if Abs("Qty. to Receive") > Abs("Outstanding Quantity") then
            exit(false);

        if ("Qty. to Receive" < 0) and (Quantity > 0) or
           ("Qty. to Receive" > 0) and (Quantity < 0)
        then
            exit(false);

        if ("Outstanding Quantity" < 0) and (Quantity > 0) or
           ("Outstanding Quantity" > 0) and (Quantity < 0)
        then
            exit(false);

        exit(true);
    end;

    local procedure CanReceiveBaseQty(): Boolean
    begin
        if Abs("Qty. to Receive (Base)") > Abs("Outstanding Qty. (Base)") then
            exit(false);

        if ("Qty. to Receive (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Qty. to Receive (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        if ("Outstanding Qty. (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Outstanding Qty. (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        exit(true);
    end;

    procedure CheckLineAmount(MaxLineAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLineAmount(Rec, MaxLineAmount, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Line Amount" < 0 then
            if "Line Amount" < MaxLineAmount then
                Error(LineAmountInvalidErr);

        if "Line Amount" > 0 then
            if "Line Amount" > MaxLineAmount then
                Error(LineAmountInvalidErr);
    end;

    procedure CheckLineTypeOnIndirectCostPercentUpdate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLineTypeOnIndirectCostPercentUpdate(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::Item then
            TestField("Indirect Cost %", 0);
    end;

    local procedure CalcQtyPerUnitOfMeasure(Item: Record Item)
    begin
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        OnAfterCalcQtyPerUnitOfMeasure(Rec, Item, CurrfieldNo);
    end;

    local procedure CalcIndirectCostPercent()
    var
        IndirectCostPercent: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcIndirectCostPercent(Rec, UnitCostCurrency, IsHandled);
        if IsHandled then
            exit;

        if ("Direct Unit Cost" <> 0) and
           ("Direct Unit Cost" <> ("Line Discount Amount" / Quantity))
        then begin
            IndirectCostPercent :=
              Round(
                (UnitCostCurrency - "Direct Unit Cost" + "Line Discount Amount" / Quantity) /
                ("Direct Unit Cost" - "Line Discount Amount" / Quantity) * 100, 0.00001);
            if IndirectCostPercent >= 0 then begin
                "Indirect Cost %" := IndirectCostPercent;
                CheckLineTypeOnIndirectCostPercentUpdate();
            end;
        end;
    end;

    local procedure CopyFromStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        "Tax Area Code" := '';
        "Tax Liable" := false;
        StandardText.Get("No.");
        Description := StandardText.Description;
        "Allow Item Charge Assignment" := false;
        OnAfterAssignStdTxtValues(Rec, StandardText);
    end;

    local procedure CopyFromGLAccount(var TempPurchaseLine: Record "Purchase Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyFromGLAccount(Rec, xRec, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            GLAcc.Get("No.");
            GLAcc.CheckGLAcc();
            if not "System-Created Entry" then
                GLAcc.TestField("Direct Posting", true);
            Description := GLAcc.Name;
            "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
            "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
            "Tax Group Code" := GLAcc."Tax Group Code";
            "Allow Invoice Disc." := false;
            "Allow Item Charge Assignment" := false;
            OnNotHandledCopyFromGLAccount(Rec, GLAcc);
            InitDeferralCode();
            SetDefaultGLAccountQuantity();
        end;
        OnAfterAssignGLAccountValues(Rec, GLAcc, PurchHeader, xRec, TempPurchaseLine);
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        GetItem(Item);
        GetGLSetup();
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, Item, IsHandled);
        if not IsHandled then begin
            Item.TestField(Blocked, false);
            Item.TestField("Gen. Prod. Posting Group");
            if Item."Purchasing Blocked" then
                if IsCreditDocType() then
                    SendBlockedItemNotification()
                else
                    Error(PurchasingBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Purchasing Blocked"));
            if Item.Type = Item.Type::Inventory then begin
                Item.TestField("Inventory Posting Group");
                "Posting Group" := Item."Inventory Posting Group";
            end;
        end;

        OnCopyFromItemOnAfterCheck(Rec, Item, CurrFieldNo);

        Description := Item.Description;
        "Description 2" := Item."Description 2";
        UpdateUnitPriceLCYFromItem(Item);
        "Units per Parcel" := Item."Units per Parcel";
        "Indirect Cost %" := Item."Indirect Cost %";
        "Overhead Rate" := Item."Overhead Rate";
        "Allow Invoice Disc." := Item."Allow Invoice Disc.";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        "Tax Group Code" := Item."Tax Group Code";
        Nonstock := Item."Created From Nonstock Item";
        "Item Category Code" := Item."Item Category Code";
        "Allow Item Charge Assignment" := true;
        PrepaymentMgt.SetPurchPrepaymentPct(Rec, PurchHeader."Posting Date");
        if IsInventoriableItem() then
            PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");

        if Item."Price Includes VAT" then begin
            if not VATPostingSetup.Get(Item."VAT Bus. Posting Gr. (Price)", Item."VAT Prod. Posting Group") then
                VATPostingSetup.Init();
            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(
                      Text002,
                      VATPostingSetup.FieldCaption("VAT Calculation Type"),
                      VATPostingSetup."VAT Calculation Type");
            end;
            IsHandled := false;
            OnCopyFromItemOnBeforeAssignUnitPriceLCY(Rec, GLSetup, VATPostingSetup, IsHandled);
            if not IsHandled then
                "Unit Price (LCY)" :=
                  Round("Unit Price (LCY)" / (1 + VATPostingSetup."VAT %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");
        end;

        if PurchHeader."Language Code" <> '' then
            GetItemTranslation();

        OnCopyFromItemOnAfterGetItemTranslation(Rec, Item);

        if Item."Purch. Unit of Measure" <> '' then
            "Unit of Measure Code" := Item."Purch. Unit of Measure"
        else
            "Unit of Measure Code" := Item."Base Unit of Measure";
        InitDeferralCode();
        OnAfterAssignItemValues(Rec, Item, CurrFieldNo, PurchHeader);
    end;

    local procedure UpdateUnitPriceLCYFromItem(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPriceLCYFromItem(Rec, Item, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Unit Price (LCY)" := Item."Unit Price";
    end;

    local procedure UpdateOrderDateFromRequestedReceiptDate(CustomCalendarChange: array[2] of Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderDateFromRequestedReceiptDate(Rec, CustomCalendarChange, IsHandled);
        if IsHandled then
            exit;

        Validate("Order Date",
          CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"), "Requested Receipt Date", CustomCalendarChange, true));
    end;

    local procedure UpdatePlannedReceiptDateFromOrderDate(CustomCalendarChange: array[2] of Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePlannedReceiptDateFromOrderDate(Rec, CustomCalendarChange, IsHandled);
        if IsHandled then
            exit;

        "Planned Receipt Date" :=
            CalendarMgmt.CalcDateBOC(AdjustDateFormula("Lead Time Calculation"), "Order Date", CustomCalendarChange, true);
    end;

    local procedure UpdateOrderDateFromPlannedReceiptDate(CustomCalendarChange: array[2] of Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOrderDateFromPlannedReceiptDate(Rec, CustomCalendarChange, IsHandled);
        if IsHandled then
            exit;

        "Order Date" :=
            CalendarMgmt.CalcDateBOC2(AdjustDateFormula("Lead Time Calculation"), "Planned Receipt Date", CustomCalendarChange, true);
    end;

    local procedure CopyFromFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get("No.");
        FixedAsset.TestField(Inactive, false);
        FixedAsset.TestField(Blocked, false);
        GetFAPostingGroup();
        Description := FixedAsset.Description;
        "Description 2" := FixedAsset."Description 2";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        OnAfterAssignFixedAssetValues(Rec, FixedAsset, PurchHeader);
    end;

    local procedure CopyFromItemCharge()
    begin
        ItemCharge.Get("No.");
        Description := ItemCharge.Description;
        "Gen. Prod. Posting Group" := ItemCharge."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := ItemCharge."VAT Prod. Posting Group";
        "Tax Group Code" := ItemCharge."Tax Group Code";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        "Indirect Cost %" := 0;
        "Overhead Rate" := 0;
        OnAfterAssignItemChargeValues(Rec, ItemCharge, PurchHeader);
    end;

    local procedure SelectItemEntry()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TestProdOrderNo();
        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange("Item No.", "No.");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange(Positive, true);
        OnSelectItemEntryOnBeforeSetRangeLocationCode(Rec, ItemLedgEntry);
        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        OnSelectItemEntryOnAfterItemLedgEntrySetFilters(Rec, ItemLedgEntry);

        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then
            Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.");
    end;

    /// <summary>
    /// Assigns given purchase header to the global variable and initializes the currency variable.
    /// </summary>
    /// <param name="NewPurchHeader">Purchase header to be set.</param>
    procedure SetPurchHeader(NewPurchHeader: Record "Purchase Header")
    begin
        PurchHeader := NewPurchHeader;
        HasPurchHeader := true;

        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            PurchHeader.TestField("Currency Factor");
            Currency.Get(PurchHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;

    /// <summary>
    /// Retrieves the global purchase header for the current purchase line.
    /// </summary>
    /// <returns>Purchase header of the current purchase line.</returns>
    procedure GetPurchHeader(): Record "Purchase Header"
    begin
        GetPurchHeader(PurchHeader, Currency);
        exit(PurchHeader);
    end;

    /// <summary>
    /// Gets the purchase header and currency for the current purchase line.
    /// </summary>
    /// <param name="OutPurchHeader">Return value: Purchase header of the purchase line.</param>
    /// <param name="OutCurrency">Return value: Currency of the purchase line.</param>
    procedure GetPurchHeader(var OutPurchHeader: Record "Purchase Header"; var OutCurrency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchHeader(Rec, PurchHeader, IsHandled, Currency);
        if IsHandled then
            exit;

        TestField("Document No.");
        if ("Document Type" <> PurchHeader."Document Type") or ("Document No." <> PurchHeader."No.") then
            if PurchHeader.Get(Rec."Document Type", Rec."Document No.") then begin
                HasPurchHeader := true;
                if PurchHeader."Currency Code" = '' then
                    Currency.InitRoundingPrecision()
                else begin
                    PurchHeader.TestField("Currency Factor");
                    Currency.Get(PurchHeader."Currency Code");
                    Currency.TestField("Amount Rounding Precision");
                end
            end else
                Clear(PurchHeader);

        OnAfterGetPurchHeader(Rec, PurchHeader, Currency);
        OutPurchHeader := PurchHeader;
        OutCurrency := Currency;
    end;

    /// <summary>
    /// Returns the item record.
    /// </summary>
    /// <returns>The item record.</returns>
    procedure GetItem(): Record Item
    var
        Item: Record Item;
    begin
        TestField("No.");
        Item.Get("No.");
        exit(Item);
    end;

    local procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");

        OnAfterGetItem(Item, Rec);
    end;

    /// <summary>
    /// Returns remaining unreserved quantity and quantity (base) of the purchase line.
    /// </summary>
    /// <param name="RemainingQty">Return value: Remaining unreserved quantity.</param>
    /// <param name="RemainingQtyBase">Return value: Remaining unreserved quantity (base).</param>
    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    /// <summary>
    /// Returns reservation quantities.
    /// </summary>
    /// <param name="QtyReserved">Return value: Reserved quantity.</param>
    /// <param name="QtyReservedBase">Return value: Reserved quantity (base).</param>
    /// <param name="QtyToReserve">Return value: Quantity to reserve.</param>
    /// <param name="QtyToReserveBase">Return value: Quantity to reserve (base).</param>
    /// <returns>Qty per unit of measure.</returns>
    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReservationQty(Rec, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Result, IsHandled);
        if not IsHandled then begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Reserved Quantity" := -"Reserved Quantity";
                "Reserved Qty. (Base)" := -"Reserved Qty. (Base)";
            end;
            QtyReserved := "Reserved Quantity";
            QtyReservedBase := "Reserved Qty. (Base)";
            QtyToReserve := "Outstanding Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)";
            Result := "Qty. per Unit of Measure";
        end;
        OnAfterGetReservationQty(Rec, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Result);
    end;

    /// <summary>
    /// Returns a text that consists of the document type, document no. and line number separated by a space.
    /// </summary>
    /// <returns>Formated text.</returns>
    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "No."));
    end;

    /// <summary>
    /// Initializes the reservation entries from the purchase line.
    /// </summary>
    /// <param name="ReservEntry">Return value: Initialized reservation entry.</param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Purchase Line", "Document Type".AsInteger(), "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Expected Receipt Date";
        ReservEntry."Shipment Date" := "Expected Receipt Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";

        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    /// <summary>
    /// Filters reservation entry from the purchase line.
    /// </summary>
    /// <param name="ReservEntry">Return value: Filtered reservation entry.</param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(Database::"Purchase Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    /// <summary>
    /// Checks if reservation entry exists for the purchase line.
    /// </summary>
    /// <returns>True if reservation entry exists, otherwise false</returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    /// <summary>
    /// Returns line amount excluding VAT for the purchase line.
    /// </summary>
    /// <remarks>
    /// If the prices includes VAT in its prices, it calculates the line amount excluding VAT.
    /// </remarks>
    /// <returns>Line amount excluding VAT.</returns>
    procedure GetLineAmountExclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetPurchHeader();
        if not PurchHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Returns line amount including VAT for the purchase line.
    /// </summary>
    /// <remarks>
    /// If the prices does not include VAT in its prices, it calculates the line amount including VAT.
    /// </remarks>
    /// <returns>Line amount including VAT.</returns>
    procedure GetLineAmountInclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetPurchHeader();
        if PurchHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Sets the global flag HasBeenShown to true.
    /// </summary>
    /// <remarks>
    /// The global flag is used to determine if the message which states that the order date is earlier than the work date has been shown.
    /// </remarks>
    procedure SetHasBeenShown()
    begin
        HasBeenShown := true;
    end;

    /// <summary>
    /// Checks if the procedure has been called from the field that was previously planned.
    /// </summary>
    /// <param name="CurrPriceFieldNo">Field that called the price calculation.</param>
    /// <returns>True if the if the calculation is triggered by the planned field, otherwise false.</returns>
    procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;

    /// <summary>
    /// Sets the field that initiates the price calculation if it is not already set.
    /// </summary>
    /// <param name="CurrPriceFieldNo">Field number that cause price calculation.</param>
    procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    /// <summary>
    /// Clears the field number that is planned to initiate the price calculation.
    /// </summary>
    procedure ClearFieldCausedPriceCalculation()
    begin
        FieldCausedPriceCalculation := 0;
    end;

    /// <summary>
    /// Updates the direct unit cost of the purchase line.
    /// </summary>
    /// <param name="CalledByFieldNo">Field number that called direct unit cost calculation.</param>
    procedure UpdateDirectUnitCost(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDirectUnitCostProcedure(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ClearFieldCausedPriceCalculation();
        PlanPriceCalcByField(CalledByFieldNo);
        UpdateDirectUnitCostByField(CalledByFieldNo);
    end;

    local procedure UpdateDirectUnitCostByField(CalledByFieldNo: Integer)
    var
        BlanketOrderPurchaseLine: Record "Purchase Line";
        PriceCalculation: Interface "Price Calculation";
        IsHandled: Boolean;
        ShouldExit: Boolean;
    begin
        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateDirectUnitCost(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and IsProdOrder() then
            UpdateAmounts();

        ShouldExit := ((CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0)) or IsProdOrder();
        OnUpdateDirectUnitCostByFieldOnAfterCalcShouldExit(Rec, xRec, CalledByFieldNo, CurrFieldNo, ShouldExit);
        if ShouldExit then
            exit;

        case Type of
            Type::"G/L Account",
            Type::Item,
            Type::Resource:
                begin
                    GetPurchHeader();
                    IsHandled := false;
                    OnUpdateDirectUnitCostOnBeforeFindPrice(PurchHeader, Rec, CalledByFieldNo, CurrFieldNo, IsHandled, xRec);
                    if not IsHandled then
                        if not BlanketOrderIsRelated(BlanketOrderPurchaseLine) then begin
                            GetPriceCalculationHandler(PurchHeader, PriceCalculation);
                            if not ("Copied From Posted Doc." and IsCreditDocType()) then begin
                                PriceCalculation.ApplyPrice(CalledByFieldNo);
                                PriceCalculation.ApplyDiscount();
                            end;
                            GetLineWithCalculatedPrice(PriceCalculation);
                        end else begin
                            Validate("Direct Unit Cost", BlanketOrderPurchaseLine."Direct Unit Cost");
                            Validate("Line Discount %", BlanketOrderPurchaseLine."Line Discount %");

                            OnUpdateDirectUnitCostByFieldOnAfterSetBlanketOrderPriceFields(PurchHeader, BlanketOrderPurchaseLine, Rec, CalledByFieldNo, CurrFieldNo);
                        end;
                    if (xRec."Direct Unit Cost" <> Rec."Direct Unit Cost") or not (CalledByFieldNo in [FieldNo("Job Task No."), FieldNo("Job No.")]) then
                        Validate("Direct Unit Cost");
                end;
        end;

        OnUpdateDirectUnitCostByFieldOnBeforeUpdateItemReference(Rec, CalledByFieldNo);
        if Type = Type::Item then
            if CalledByFieldNo in [FieldNo("No."), FieldNo("Variant Code")] then
                UpdateItemReference();

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateDirectUnitCost(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    local procedure BlanketOrderIsRelated(var BlanketOrderPurchaseLine: Record "Purchase Line"): Boolean
    var
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeBlanketOrderIsRelated(Rec, BlanketOrderPurchaseLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if "Blanket Order Line No." = 0 then exit;
        BlanketOrderPurchaseLine.SetLoadFields("Direct Unit Cost", "Line Discount %");
        OnBlanketOrderIsRelatedOnAfterSetLoadFields(BlanketOrderPurchaseLine);
        if BlanketOrderPurchaseLine.Get("Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.") then
            exit(true);
    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    /// <summary>
    /// Gets price calculation interface implementation for the purchase line.
    /// </summary>
    /// <param name="PurchaseHeader">Purchase header that is used to get price calculation implementation.</param>
    /// <param name="PriceCalculation">Return value: Price calculation interface inplementation.</param>
    procedure GetPriceCalculationHandler(PurchaseHeader: Record "Purchase Header"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
        PriceType: Enum "Price Type";
    begin
        if (PurchaseHeader."No." = '') and ("Document No." <> '') then
            PurchaseHeader.Get(Rec."Document Type", Rec."Document No.");
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType::Purchase, PurchaseHeader, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;

    /// <summary>
    /// Gets the default or overridden line with price interface implementation.
    /// </summary>
    /// <param name="LineWithPrice">Return value: line with price implementation.</param>
    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        LineWithPrice := PurchaseLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    /// <summary>
    /// Wrapper for price calculation method CountDiscount.
    /// Returns the count of price list lines containing discounts suitable for the purchase line.
    /// </summary>
    /// <param name="ShowAll">If true, it expands the filter criteria applied to the price list line.</param>
    /// <returns>The number of price list lines with discounts.</returns>
    procedure CountDiscount(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.CountDiscount(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method CountPrice.
    /// Returns the count of price list lines containing prices suitable for the purchase line.
    /// </summary>
    /// <param name="ShowAll">If true, it expands the filter criteria applied to the price list line.</param>
    /// <returns>The number of price list lines with prices.</returns>
    procedure CountPrice(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.CountPrice(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method IsDiscountExists.
    /// Returns true if there are any price list lines containing discounts that are applicable to the purchase line.
    /// </summary>
    /// <param name="ShowAll">If true, it expands the filter criteria applied to the price list line.</param>
    /// <returns>Returns true if at least one price list line is found, otherwise false.</returns>
    procedure DiscountExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.IsDiscountExists(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method IsPriceExists.
    /// Returns true if there are any price list lines containing prices that are applicable to the purchase line.
    /// </summary>
    /// <param name="ShowAll">If true, it expands the filter criteria applied to the price list line.</param>
    /// <returns>Returns true if at least one price list line is found, otherwise false.</returns>
    procedure PriceExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        exit(PriceCalculation.IsPriceExists(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method PickDiscount.
    /// Opens a price list selection to choose discounts suitable for the purchase line.
    /// The discounts are assigned to the purchase line after selection.
    /// </summary>
    procedure PickDiscount()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        PriceCalculation.PickDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// Wrapper for price calculation method PickPrice.
    /// Opens a price list selection to choose prices suitable for the purchase line.
    /// The prices are assigned to the purchase line after selection.
    /// </summary>
    procedure PickPrice()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        PriceCalculation.PickPrice();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// Updates the purchase line's price and discount based on the item reference number.
    /// </summary>
    procedure UpdateReferencePriceAndDiscount();
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PurchHeader, PriceCalculation);
        PriceCalculation.ApplyPrice(FieldNo("Item Reference No."));
        PriceCalculation.ApplyDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// Updates the unit cost of the purchase line.
    /// </summary>
    procedure UpdateUnitCost()
    var
        Item: Record Item;
        DiscountAmountPerQty: Decimal;
        ShouldCalcStandardUnitCostLCY: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader();
        GetGLSetup();
        if Quantity = 0 then
            DiscountAmountPerQty := 0
        else
            DiscountAmountPerQty :=
              Round(("Line Discount Amount" + "Inv. Discount Amount") / Quantity,
                GLSetup."Unit-Amount Rounding Precision");
        OnUpdateUnitCostOnAfterCalcDiscountAmountPerQty(Rec, DiscountAmountPerQty);

        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
            "Unit Cost" := 0
        else
            if PurchHeader."Prices Including VAT" then
                "Unit Cost" :=
                  ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) / (1 + GetVATPct() / 100) +
                  GetOverheadRateFCY() - "VAT Difference"
            else
                "Unit Cost" :=
                  ("Direct Unit Cost" - DiscountAmountPerQty) * (1 + "Indirect Cost %" / 100) +
                  GetOverheadRateFCY();

        OnUpdateUnitCostOnBeforeUpdateUnitCostLCY(Rec, xRec, PurchHeader, CurrFieldNo, Item, SKU, Currency, GLSetup);

        if PurchHeader."Currency Code" <> '' then begin
            PurchHeader.TestField("Currency Factor");
            "Unit Cost (LCY)" :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                GetDate(), "Currency Code",
                "Unit Cost", PurchHeader."Currency Factor");
        end else
            "Unit Cost (LCY)" := "Unit Cost";

        ShouldCalcStandardUnitCostLCY := (Type = Type::Item) and (not IsProdOrder());
        OnUpdateUnitCostOnBeforeCalcStandardUnitCostLCY(Rec, ShouldCalcStandardUnitCostLCY);
        if ShouldCalcStandardUnitCostLCY then begin
            GetItem(Item);
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                if GetSKU() then
                    "Unit Cost (LCY)" := SKU."Unit Cost" * "Qty. per Unit of Measure"
                else
                    "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
                OnUpdateUnitCostOnAfterCalcStandardUnitCostLCY(Rec);
            end;
        end;

        "Unit Cost (LCY)" := Round("Unit Cost (LCY)", GLSetup."Unit-Amount Rounding Precision");
        if PurchHeader."Currency Code" <> '' then
            Currency.TestField("Unit-Amount Rounding Precision");
        "Unit Cost" := Round("Unit Cost", Currency."Unit-Amount Rounding Precision");

        OnAfterUpdateUnitCost(Rec, xRec, PurchHeader, Item, SKU, Currency, GLSetup);

        UpdateSalesCost();

        if JobTaskIsSet() and not UpdateFromVAT and not "Prepayment Line" then begin
            CreateTempJobJnlLine(false);
            TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");
            UpdateJobPrices();
        end;
    end;

    /// <summary>
    /// Updates line, vat, prepayment and deferral amounts of the purchase line.
    /// Initializes outstanding amounts.
    /// </summary>
    /// <remarks>
    /// If purchase line type is charge (item), it updates item charge assignment.
    /// </remarks>
    procedure UpdateAmounts()
    var
        VATBaseAmount: Decimal;
        NonDeductAmount: Decimal;
        LineAmountChanged: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::" " then
            exit;

        GetPurchHeader();

        VATBaseAmount := "VAT Base Amount";
        NonDeductAmount := NonDeductibleVAT.GetNonDeductibleVATAmount(Rec);
        "Recalculate Invoice Disc." := "Allow Invoice Disc.";

        UpdateLineAmount(LineAmountChanged);

        if not "Prepayment Line" then
            UpdatePrepmtAmounts();

        OnAfterUpdateAmounts(Rec, xRec, CurrFieldNo);

        UpdateVATAmounts();
        if VATBaseAmount <> "VAT Base Amount" then
            LineAmountChanged := true;
        LineAmountChanged := LineAmountChanged or (NonDeductAmount <> NonDeductibleVAT.GetNonDeductibleVATAmount(Rec));

        if LineAmountChanged then begin
            UpdateDeferralAmounts();
            LineAmountChanged := false;
        end;

        InitOutstandingAmount();

        if Type = Type::"Charge (Item)" then
            UpdateItemChargeAssgnt();

        CalcPrepaymentToDeduct();

        OnAfterUpdateAmountsDone(Rec, xRec, CurrFieldNo);
    end;

    local procedure UpdateJobFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobFields(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if xRec."Job No." <> '' then
            Validate("Job No.", xRec."Job No.");
        "Job Line Type" := xRec."Job Line Type";
        if xRec."Job Task No." <> '' then begin
            Validate("Job Task No.", xRec."Job Task No.");
            if "No." = xRec."No." then
                Validate("Job Planning Line No.", xRec."Job Planning Line No.");
        end;
    end;

    local procedure UpdateSpecialSalesOrderLineFromOnDelete(SalesOrderLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSpecialSalesOrderLineFromOnDelete(Rec, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        if ("Special Order Sales Line No." <> 0) and ("Quantity Invoiced" = 0) then begin
            LockTable();
            SalesOrderLine.LockTable();
            if SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::Order, "Special Order Sales No.", "Special Order Sales Line No.")
            then begin
                SalesOrderLine."Special Order Purchase No." := '';
                SalesOrderLine."Special Order Purch. Line No." := 0;
                SalesOrderLine.Modify();
            end;
        end;
    end;

    /// <summary>
    /// Updates amounts, vat amounts and vat procentage of the purchase line.
    /// </summary>
    procedure UpdateVATAmounts()
    var
        PurchLine2: Record "Purchase Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalVATDifference: Decimal;
        TotalQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVATAmounts(Rec, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader();
        PurchLine2.SetRange("Document Type", "Document Type");
        PurchLine2.SetRange("Document No.", "Document No.");
        PurchLine2.SetFilter("Line No.", '<>%1', "Line No.");
        PurchLine2.SetRange("VAT Identifier", "VAT Identifier");
        PurchLine2.SetRange("Tax Group Code", "Tax Group Code");
        PurchLine2.SetRange("Tax Area Code", "Tax Area Code");
        OnUpdateVATAmountsOnAfterSetFilters(Rec, PurchLine2);

        if "Line Amount" = "Inv. Discount Amount" then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
            NonDeductibleVAT.ClearNonDeductibleVAT(Rec);
            OnUpdateVATAmountsOnBeforePurchLineModify(Rec, PurchLine2);
            if (Quantity = 0) and (xRec.Quantity <> 0) and (xRec.Amount <> 0) then begin
                if "Line No." <> 0 then
                    Modify();
                PurchLine2.SetFilter(Amount, '<>0');
                if PurchLine2.Find('<>') then begin
                    OnUpdateVATAmountsOnBeforeValidateLineDiscountPercent(Rec, PurchLine2);
                    PurchLine2.ValidateLineDiscountPercent(false);
                    PurchLine2.Modify();
                end;
            end;
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"]) and ("VAT %" <> 0))
            then begin
                PurchLine2.SetFilter("VAT %", '<>0');
                if not PurchLine2.IsEmpty() then begin
                    PurchLine2.CalcSums("Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)", "VAT Difference");
                    TotalLineAmount := PurchLine2."Line Amount";
                    TotalInvDiscAmount := PurchLine2."Inv. Discount Amount";
                    TotalAmount := PurchLine2.Amount;
                    TotalAmountInclVAT := PurchLine2."Amount Including VAT";
                    TotalVATDifference := PurchLine2."VAT Difference";
                    TotalQuantityBase := PurchLine2."Quantity (Base)";
                    OnAfterUpdateTotalAmounts(Rec, PurchLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount);
                end;
            end;

            OnUpdateVATAmountsOnBeforeCalcAmounts(
                Rec, PurchLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount, TotalQuantityBase, TotalVATDifference, IsHandled);
            if IsHandled then
                exit;

            if PurchHeader."Prices Including VAT" then
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                (TotalLineAmount - TotalInvDiscAmount + CalcLineAmount()) / (1 + GetVATPct() / 100),
                                Currency."Amount Rounding Precision") -
                              TotalAmount;
                            "VAT Base Amount" :=
                              Round(
                                Amount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100),
                                Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalLineAmount + "Line Amount" -
                              Round(
                                (TotalAmount + Amount) * (GetVatBaseDiscountPct(PurchHeader) / 100) * GetVATPct() / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT - TotalInvDiscAmount - "Inv. Discount Amount";
                            NonDeductibleVAT.Update(Rec, Currency);
                            OnUpdateVATAmountsOnAfterCalcNormalVATAmountsForPricesIncludingVAT(Rec, PurchHeader, Currency, TotalAmount, TotalAmountInclVAT, PurchLine2);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := ROUND(CalcLineAmount(), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            PurchHeader.TestField("VAT Base Discount %", 0);
                            "Amount Including VAT" :=
                              Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            if "Use Tax" then
                                Amount := "Amount Including VAT"
                            else
                                Amount :=
                                  Round(
                                    SalesTaxCalculate.ReverseCalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                      PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision") -
                                  TotalAmount;
                            OnAfterSalesTaxCalculateReverse(Rec, PurchHeader, Currency);
                            "VAT Base Amount" := Amount;
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                ClearVATPct();
                        end;
                end
            else
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                (TotalAmount + Amount) * (1 - GetVatBaseDiscountPct(PurchHeader) / 100) * GetVATPct() / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT + TotalVATDifference;
                            NonDeductibleVAT.Update(Rec, Currency);
                            OnUpdateVATAmountsOnAfterCalcNormalVATAmountsForPricesExcludingVAT(Rec, PurchHeader, Currency, TotalAmount, TotalAmountInclVAT, PurchLine2);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := CalcLineAmount();
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                            if "Use Tax" then
                                "Amount Including VAT" := Amount
                            else
                                "Amount Including VAT" :=
                                  TotalAmount + Amount +
                                  Round(
                                    SalesTaxCalculate.CalculateTax(
                                      "Tax Area Code", "Tax Group Code", "Tax Liable", PurchHeader."Posting Date",
                                      TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                      PurchHeader."Currency Factor"),
                                    Currency."Amount Rounding Precision") -
                                  TotalAmountInclVAT;
                            OnAfterSalesTaxCalculate(Rec, PurchHeader, Currency);
                            if "VAT Base Amount" <> 0 then
                                "VAT %" :=
                                  Round(100 * ("Amount Including VAT" - "VAT Base Amount") / "VAT Base Amount", 0.00001)
                            else
                                ClearVATPct();
                        end;
                end;
        end;

        OnAfterUpdateVATAmounts(Rec, TotalLineAmount, TotalInvDiscAmount, TotalAmount, TotalAmountInclVAT, TotalVATDifference, TotalQuantityBase);
    end;

    /// <summary>
    /// Checks prepayment setups and assigns prepayment fields to the purchase line.
    /// </summary>
    procedure UpdatePrepmtSetupFields()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtSetupFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Prepayment %" <> 0) and HasTypeToFillMandatoryFields() then begin
            TestField("Document Type", "Document Type"::Order);
            TestField("No.");
            NonDeductibleVAT.CheckPrepmtWithNonDeductubleVATInPurchaseLine(Rec);
            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
            if GenPostingSetup."Purch. Prepayments Account" <> '' then begin
                GLAcc.Get(GenPostingSetup."Purch. Prepayments Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                VATPostingSetup.TestField("VAT Calculation Type", "VAT Calculation Type");
                NonDeductibleVAT.CheckPrepmtVATPostingSetup(VATPostingSetup);
            end else
                Clear(VATPostingSetup);
            OnAfterGetPostingSetup(Rec, VATPostingSetup);
            if ("Prepayment VAT %" <> 0) and ("Prepayment VAT %" <> VATPostingSetup."VAT %") and ("Prepmt. Amt. Inv." <> 0) then
                Error(CannotChangePrepmtAmtDiffVAtPctErr);
            CopyPrepaymentFromVATPostingSetup(VATPostingSetup);
            "Prepayment Tax Group Code" := GLAcc."Tax Group Code";
        end;
    end;

    local procedure UpdateSalesCostFromUnitCostLCY()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesCostFromUnitCostLCY(Rec, IsHandled);
        if IsHandled then
            exit;

        UpdateSalesCost();
    end;

    /// <summary>
    /// Updates unit costs of the purchase line.
    /// </summary>
    procedure UpdateSalesCost()
    var
        SalesOrderLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnUpdateSalesCostOnBeforeGetSalesOrderLine(Rec, IsHandled);
        if IsHandled then
            exit;

        case true of
            "Sales Order Line No." <> 0: // Drop Shipment
                SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Sales Order No.", "Sales Order Line No.");
            "Special Order Sales Line No." <> 0: // Special Order
                if not
                    SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, "Special Order Sales No.", "Special Order Sales Line No.")
                then
                    exit;
            else
                exit;
        end;

        IsHandled := false;
        OnBeforeUpdateSalesCost(Rec, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        SalesOrderLine."Unit Cost (LCY)" := "Unit Cost (LCY)" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine."Unit Cost" := "Unit Cost" * SalesOrderLine."Qty. per Unit of Measure" / "Qty. per Unit of Measure";
        SalesOrderLine.Validate("Unit Cost (LCY)");
        SalesOrderLine.Modify();

        OnAfterUpdateSalesCost(Rec, SalesOrderLine);
    end;

    local procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FADeprBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFAPostingGroup(Rec, IsHandled);
        if IsHandled then
            exit;

        if (Type <> Type::"Fixed Asset") or ("No." = '') then
            exit;
        if "Depreciation Book Code" = '' then
            if not FindDefaultFADeprBook() then
                exit;

        if "FA Posting Type" = "FA Posting Type"::" " then
            "FA Posting Type" := "FA Posting Type"::"Acquisition Cost";
        FADeprBook.Get("No.", "Depreciation Book Code");
        FADeprBook.TestField("FA Posting Group");
        FAPostingGr.GetPostingGroup(FADeprBook."FA Posting Group", FADeprBook."Depreciation Book Code");
        IsHandled := false;
        OnGetFAPostingGroupOnBeforeLocalGLAccGet(Rec, FAPostingGr, LocalGLAcc, IsHandled);
        if not IsHandled then
            case "FA Posting Type" of
                "FA Posting Type"::"Acquisition Cost":
                    LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccount());
                "FA Posting Type"::Appreciation:
                    LocalGLAcc.Get(FAPostingGr.GetAppreciationAccount());
                "FA Posting Type"::Maintenance:
                    LocalGLAcc.Get(FAPostingGr.GetMaintenanceExpenseAccount());
            end;

        IsHandled := false;
        OnGetFAPostingGroupOnBeforeCheckGLAcc(Rec, LocalGLAcc, FADeprBook, IsHandled);
        if not IsHandled then begin
            LocalGLAcc.CheckGLAcc();
            if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
                LocalGLAcc.TestField("Gen. Prod. Posting Group");
            "Posting Group" := FADeprBook."FA Posting Group";
            "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
            "Tax Group Code" := LocalGLAcc."Tax Group Code";
        end;
        ValidateVATProdPostingGroupFromGLAcc(LocalGLAcc);

        OnAfterGetFAPostingGroup(Rec, LocalGLAcc);
    end;

    local procedure ValidateVATProdPostingGroupFromGLAcc(GLAccount: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVATProdPostingGroupFromGLAcc(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
    end;

    local procedure FindDefaultFADeprBook() Result: Boolean
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        DefaultFADeprBook: Record "FA Depreciation Book";
        SetFADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();

        DefaultFADeprBook.SetRange("FA No.", "No.");
        DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

        SetFADeprBook.SetRange("FA No.", "No.");

        case true of
            SetFADeprBook.Count = 1:
                begin
                    SetFADeprBook.FindFirst();
                    "Depreciation Book Code" := SetFADeprBook."Depreciation Book Code";
                end;
            DefaultFADeprBook.FindFirst():
                "Depreciation Book Code" := DefaultFADeprBook."Depreciation Book Code";
            FADeprBook.Get("No.", FASetup."Default Depr. Book"):
                "Depreciation Book Code" := FASetup."Default Depr. Book"
            else
                "Depreciation Book Code" := '';
        end;
        Result := "Depreciation Book Code" <> '';

        OnAfterFindDefaultFADeprBook(Rec, Result);
    end;

    /// <summary>
    /// Updates unit cost, unit price and direct unit cost for the purchase line.
    /// </summary>
    procedure UpdateUOMQtyPerStockQty()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUOMQtyPerStockQty(Rec, xRec, Item, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetItem(Item);
        "Unit Cost (LCY)" := Item."Unit Cost" * "Qty. per Unit of Measure";
        "Unit Price (LCY)" := Item."Unit Price" * "Qty. per Unit of Measure";
        GetPurchHeader();
        if PurchHeader."Currency Code" <> '' then
            "Unit Cost" :=
              CurrExchRate.ExchangeAmtLCYToFCY(
                GetDate(), PurchHeader."Currency Code",
                "Unit Cost (LCY)", PurchHeader."Currency Factor")
        else
            "Unit Cost" := "Unit Cost (LCY)";
        if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
            PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
        UpdateDirectUnitCostByField(FieldNo("Unit of Measure Code"));
    end;

    /// <summary>
    /// Opens a selection of items page. After that, selected items are added to purchase lines.
    /// </summary>
    /// <remarks>
    /// If document type is not return order or credit memo, selection shows only items that have purchasing blocked field set to false.
    /// </remarks>
    procedure SelectMultipleItems()
    var
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectMultipleItems(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then
            SelectionFilter := ItemListPage.SelectActiveItems()
        else
            SelectionFilter := ItemListPage.SelectActiveItemsForPurchase();
        if SelectionFilter <> '' then
            AddItems(SelectionFilter);

        OnAfterSelectMultipleItems(Rec);
    end;

    /// <summary>
    /// Adds items to the purchase lines based on a selection filter.
    /// </summary>
    /// <param name="SelectionFilter">Filter text of the selected items.</param>
    procedure AddItems(SelectionFilter: Text)
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        InitNewLine(PurchLine);
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet() then
            repeat
                AddItem(PurchLine, Item."No.");
            until Item.Next() = 0;
    end;

    /// <summary>
    /// Inserts an item to the purchase line.
    /// </summary>
    /// <remarks>
    /// If purchase line has automatic ext. texts enabled, it inserts extended texts to purchase line.
    /// </remarks>
    /// <param name="PurchLine">Return value: Inserted purchase line.</param>
    /// <param name="ItemNo">Item number to be inserted.</param>
    procedure AddItem(var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        LastPurchLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        PurchLine.Init();
        PurchLine."Line No." += 10000;
        PurchLine.Validate(Type, Type::Item);
        PurchLine.Validate("No.", ItemNo);
        OnAddItemOnBeforeInsert(PurchLine);
        PurchLine.Insert(true);
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, false) then begin
            TransferExtendedText.InsertPurchExtTextRetLast(PurchLine, LastPurchLine);
            PurchLine."Line No." := LastPurchLine."Line No."
        end;
        OnAfterAddItem(PurchLine, LastPurchLine);
    end;

    /// <summary>
    /// Initializes a new purchase line based on the current purchase line.
    /// </summary>
    /// <param name="NewPurchLine">Return value: Initialized purchase line.</param>
    procedure InitNewLine(var NewPurchLine: Record "Purchase Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        NewPurchLine.Copy(Rec);
        PurchLine.SetRange("Document Type", NewPurchLine."Document Type");
        PurchLine.SetRange("Document No.", NewPurchLine."Document No.");
        if PurchLine.FindLast() then
            NewPurchLine."Line No." := PurchLine."Line No."
        else
            NewPurchLine."Line No." := 0;
    end;

    procedure ShowOrderTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Outstanding Qty. (Base)", Rec."Expected Receipt Date", Rec."Expected Receipt Date");
        OrderTracking.RunModal();
    end;


    /// <summary>
    /// Opens the reservation page for an item in a purchase line.
    /// </summary>
    procedure ShowReservation()
    var
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestProdOrderNo();
        TestField("No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    /// <summary>
    /// Opens a reservation entries page for the current purchase line.
    /// </summary>
    /// <param name="Modal">If true, execution is halted until the page is closed.</param>
    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservationEntries(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    local procedure ShowBinCodeCannotBeChangedError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowBinCodeCannotBeChangedError(Rec, IsHandled);
        if IsHandled then
            exit;

        Error(Text001, FieldCaption("Bin Code"), "Sales Order No.");
    end;

    local procedure ShowEarlyOrderDateMessage()
    var
        ShowMessage: Boolean;
    begin
        ShowMessage := not (HideValidationDialog or HasBeenShown) and GuiAllowed;
        OnShowEarlyOrderDateMessageOnAfterCalcShowMessage(Rec, ShowMessage);
        if ShowMessage then begin
            Message(Text018, FieldCaption("Order Date"), "Order Date", WorkDate());
            HasBeenShown := true;
        end;
    end;

    /// <summary>
    /// Returns the posting date from the related purchase header if it's available, otherwise it returns the current work date.
    /// </summary>
    /// <returns>Document's posting date or work date.</returns>
    procedure GetDate(): Date
    var
        ResultDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ResultDate := 0D;
        OnBeforeGetDate(ResultDate, IsHandled);
        if IsHandled then
            exit(ResultDate);

        GetPurchHeader();
        if PurchHeader."Posting Date" <> 0D then
            exit(PurchHeader."Posting Date");
        exit(WorkDate());
    end;

    /// <summary>
    /// Returns a signed decimal value based on the document type of the purchase line.
    /// </summary>
    /// <param name="Value">The value to sign.</param>
    /// <returns>Signed value.</returns>
    procedure Signed(Value: Decimal): Decimal
    var
        Result: Decimal;
    begin
        case "Document Type" of
            "Document Type"::Quote,
            "Document Type"::Order,
            "Document Type"::Invoice,
            "Document Type"::"Blanket Order":
                exit(Value);
            "Document Type"::"Return Order",
            "Document Type"::"Credit Memo":
                exit(-Value);
            else begin
                Result := 0;
                OnGetSignedValue(Rec, Value, Result);
                exit(Result);
            end;

        end;
    end;

    /// <summary>
    /// Opens a page to select blanket order line for the current purchase line.
    /// Selected blanket order line information is assigned to the purchase line.
    /// </summary>
    procedure BlanketOrderLookup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlanketOrderLookup(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        PurchLine2.Reset();
        PurchLine2.SetCurrentKey("Document Type", Type, "No.");
        PurchLine2.SetRange("Document Type", "Document Type"::"Blanket Order");
        PurchLine2.SetRange(Type, Type);
        PurchLine2.SetRange("No.", "No.");
        PurchLine2.SetRange("Pay-to Vendor No.", "Pay-to Vendor No.");
        PurchLine2.SetRange("Buy-from Vendor No.", "Buy-from Vendor No.");
        if PAGE.RunModal(PAGE::"Purchase Lines", PurchLine2) = ACTION::LookupOK then begin
            PurchLine2.TestField("Document Type", "Document Type"::"Blanket Order");
            "Blanket Order No." := PurchLine2."Document No.";
            Validate("Blanket Order Line No.", PurchLine2."Line No.");
        end;

        OnAfterBlanketOrderLookup(Rec);
    end;

    /// <summary>
    /// Sets TrackingBlocked flag to the given value. Also sets global Blocked flag of purchase line reserve codeunit.
    /// </summary>
    /// <remarks>
    /// This flag is used to disallow changes to existing reservation entries for the purchase line.
    /// </remarks>
    /// <param name="SetBlock">Flag value to set.</param>
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        TrackingBlocked := SetBlock;
        PurchLineReserve.Block(SetBlock);
    end;

    /// <summary>
    /// Opens a page for editing dimensions for the purchase line.
    /// Upon closing the page, it updates the dimensions on the purcahse line.
    /// </summary>
    /// <returns>True if the dimensions were changed, otherwise false.</returns>
    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
        OnShowDimensionsOnAfterEditDimensionSet(Rec, OldDimSetID);
        VerifyItemLineDim();
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Opens a page for editing item tracking lines for the purchase line.
    /// </summary>
    procedure OpenItemTrackingLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        OnOpenItemTrackingLinesOnAfterCheck(Rec);

        TestField("Quantity (Base)");

        PurchLineReserve.CallItemTracking(Rec);
    end;

    /// <summary>
    /// Creates dimensions for the purchase line based on the provided default dimension sources.
    /// </summary>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo, DefaultDimSource);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetPurchHeader();
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Purchases,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", PurchHeader."Dimension Set ID", Database::Vendor);
        OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(Rec);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, CurrFieldNo, xRec);
    end;

    local procedure ValidateItemDescription()
    var
        Item: Record Item;
        ReturnValue: Text[50];
        DescriptionIsNo: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemDescription(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsReceivedFromOcr() then
            exit;

        if StrLen(Description) <= MaxStrLen(Item."No.") then
            DescriptionIsNo := Item.Get(Description)
        else
            DescriptionIsNo := false;

        if not DescriptionIsNo then begin
            Item.SetRange(Blocked, false);
            if not IsCreditDocType() then
                Item.SetRange("Purchasing Blocked", false);

            // looking for an item with exact description
            Item.SetRange(Description, Description);
            if Item.FindFirst() then begin
                CurrFieldNo := FieldNo("No.");
                Validate("No.", Item."No.");
                exit;
            end;

            // looking for an item with similar description
            Item.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
            if Item.FindFirst() then begin
                CurrFieldNo := FieldNo("No.");
                Validate("No.", Item."No.");
                exit;
            end;
        end;

        if Item.TryGetItemNoOpenCard(ReturnValue, Description, false, false, false) then
            case ReturnValue of
                '', "No.":
                    Description := xRec.Description;
                else begin
                    CurrFieldNo := FieldNo("No.");
                    Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen(Item."No.")));
                end;
            end;
    end;

    /// <summary>
    /// Verifies whether the provided shortcut dimension code and value are valid.
    /// </summary>
    /// <remarks>
    /// If the dimensions of a received or shipped item have changed in a purchase line, the confirmation is shown.
    /// </remarks>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Value of the shortcut dimension.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        VerifyItemLineDim();

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure ValidateLineDiscountPctForNotItemType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLineDiscountPctForNotItemType(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type <> Type::Item then
            Validate("Line Discount %");
    end;

    local procedure ValidateQuantityInvIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityInvIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Invoice", "Qty. to Invoice (Base)", "Quantity Invoiced", "Qty. Invoiced (Base)");
    end;

    local procedure ValidateQuantityReceiveIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityReceiveIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Qty. to Receive", "Qty. to Receive (Base)", "Quantity Received", "Qty. Received (Base)");
    end;

    local procedure ValidateQuantityReturnIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityReturnIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Quantity (Base)", "Return Qty. to Ship", "Return Qty. to Ship (Base)", "Return Qty. Shipped", "Return Qty. Shipped (Base)");
    end;

    local procedure AssignFieldsForQtyPerUOM(Item: Record Item; FieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignFieldsForQtyPerUOM(Rec, Item, FieldNo, IsHandled, xRec);
        if IsHandled then
            exit;

        CalcQtyPerUnitOfMeasure(Item);
        "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
        "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
        "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
        "Units per Parcel" := Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
        "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
    end;

    local procedure ValidatePlannedReceiptDateWithCustomCalendarChange(CustomCalendarChange: array[2] of Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePlannedReceiptDateWithCustomCalendarChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Validate(
            "Planned Receipt Date",
            CalendarMgmt.CalcDateBOC2(ReversedInternalLeadTimeDays("Expected Receipt Date"), "Expected Receipt Date", CustomCalendarChange, false))
    end;

    /// <summary>
    /// Opens a page for selecting a dimension code, then assigns the selected value to the presented number of the shortcut dimension.
    /// </summary>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Return value: Value of the selected shortcut dimension.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Gets an array of shortcut dimension values from the dimensions of the purchase line.
    /// </summary>
    /// <param name="ShortcutDimCode">Return value: The array of shortcut dimension values.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    local procedure GetSKU() Result: Boolean
    begin
        TestField("No.");
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

    /// <summary>
    /// Opens item charge assignment page, where receipt lines can be selected and additional cost is passed to the selected items.
    /// </summary>
    /// <remarks>
    /// If the purchase line type is not an item (charge), a message is displayed, and the procedure is ended.
    /// </remarks>
    procedure ShowItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        AssignItemChargePurch: Codeunit "Item Charge Assgnt. (Purch.)";
        ItemChargeAssgnts: Page "Item Charge Assignment (Purch)";
        ItemChargeAssgntLineAmt: Decimal;
        IsHandled: Boolean;
    begin
        Get("Document Type", "Document No.", "Line No.");
        CheckNoAndQuantityForItemChargeAssgnt();

        if Type <> Type::"Charge (Item)" then begin
            Message(ItemChargeAssignmentErr);
            exit;
        end;

        GetPurchHeader();
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchHeader."Currency Code");
        if ("Inv. Discount Amount" = 0) and
           ("Line Discount Amount" = 0) and
           (not PurchHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := "Line Amount" + NonDeductibleVAT.GetNonDeductibleVATAmountForItemCost(Rec)
        else
            if PurchHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round(CalcLineAmount() / (1 + GetVATPct() / 100), Currency."Amount Rounding Precision") + NonDeductibleVAT.GetNonDeductibleVATAmountForItemCost(Rec)
            else
                ItemChargeAssgntLineAmt := CalcLineAmount();

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntPurch.SetRange("Item Charge No.", "No.");
        if not ItemChargeAssgntPurch.FindLast() then begin
            ItemChargeAssgntPurch."Document Type" := "Document Type";
            ItemChargeAssgntPurch."Document No." := "Document No.";
            ItemChargeAssgntPurch."Document Line No." := "Line No.";
            ItemChargeAssgntPurch."Item Charge No." := "No.";
            ItemChargeAssgntPurch."Unit Cost" :=
              Round(ItemChargeAssgntLineAmt / Quantity,
                Currency."Unit-Amount Rounding Precision");
        end;

        IsHandled := false;
        OnShowItemChargeAssgntOnBeforeCalcItemCharge(Rec, ItemChargeAssgntLineAmt, Currency, IsHandled, ItemChargeAssgntPurch);
        if not IsHandled then
            ItemChargeAssgntLineAmt :=
                Round(ItemChargeAssgntLineAmt * ("Qty. to Invoice" / Quantity), Currency."Amount Rounding Precision");

        if IsCreditDocType() then
            AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch, "Return Shipment No.")
        else
            AssignItemChargePurch.CreateDocChargeAssgnt(ItemChargeAssgntPurch, "Receipt No.");
        Clear(AssignItemChargePurch);
        Commit();

        ItemChargeAssgnts.Initialize(Rec, ItemChargeAssgntLineAmt);
        ItemChargeAssgnts.RunModal();

        CalcFields("Qty. to Assign");
        OnAfterShowItemChargeAssgnt(Rec, ItemChargeAssgntPurch, ItemChargeAssgnts);
    end;

    /// <summary>
    /// Updates item chage assignment amounts and unit cost for the pruchase line.
    /// </summary>
    /// <remarks>
    /// If the document type is a blanket order, the procedure is ended.
    /// If the quantity invoiced is greater than the sum of the quantity assigned and the quantity to assign, an error message is displayed.
    /// </remarks>
    procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        ShareOfVAT: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
        TotalQtyToHandle: Decimal;
        TotalAmtToHandle: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemChargeAssgnt(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Blanket Order" then
            exit;

        CalcFields("Qty. Assigned", "Qty. to Assign", "Item Charge Qty. to Handle");
        if Abs("Quantity Invoiced") > Abs(("Qty. Assigned" + "Qty. to Assign")) then
            Error(Text032, FieldCaption("Quantity Invoiced"), FieldCaption("Qty. Assigned"), FieldCaption("Qty. to Assign"));

        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntPurch.CalcSums("Qty. to Assign", "Qty. to Handle");
        TotalQtyToAssign := ItemChargeAssgntPurch."Qty. to Assign";
        TotalQtyToHandle := ItemChargeAssgntPurch."Qty. to Handle";
        if (CurrFieldNo <> 0) and ("Unit Cost" <> xRec."Unit Cost") then begin
            ItemChargeAssgntPurch.SetFilter("Qty. Assigned", '<>0');
            if not ItemChargeAssgntPurch.IsEmpty() then
                Error(Text022,
                  FieldCaption("Unit Cost"));
            ItemChargeAssgntPurch.SetRange("Qty. Assigned");
        end;

        if (CurrFieldNo <> 0) and (Quantity <> xRec.Quantity) then begin
            ItemChargeAssgntPurch.SetFilter("Qty. Assigned", '<>0');
            if not ItemChargeAssgntPurch.IsEmpty() then
                Error(Text022,
                  FieldCaption(Quantity));
            ItemChargeAssgntPurch.SetRange("Qty. Assigned");
        end;

        if ItemChargeAssgntPurch.FindSet(true) and (Quantity <> 0) then begin
            GetPurchHeader();
            TotalAmtToAssign := CalcTotalAmtToAssign(TotalQtyToAssign);
            TotalAmtToHandle := CalcTotalAmtToAssign(TotalQtyToHandle);
            repeat
                ShareOfVAT := 1;
                if PurchHeader."Prices Including VAT" then
                    ShareOfVAT := 1 + "VAT %" / 100;
                if ItemChargeAssgntPurch."Unit Cost" <>
                   Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision")
                then
                    ItemChargeAssgntPurch."Unit Cost" :=
                      Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssgntPurch."Amount to Assign" :=
                      Round(ItemChargeAssgntPurch."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                        Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= ItemChargeAssgntPurch."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssgntPurch."Amount to Assign";
                    if TotalQtyToHandle <> 0 then begin
                        ItemChargeAssgntPurch."Amount to Handle" :=
                            Round(ItemChargeAssgntPurch."Qty. to Handle" / TotalQtyToHandle * TotalAmtToHandle,
                                Currency."Amount Rounding Precision");
                        TotalQtyToHandle -= ItemChargeAssgntPurch."Qty. to Handle";
                        TotalAmtToHandle -= ItemChargeAssgntPurch."Amount to Handle";
                    end;
                end;
                OnUpdateItemChargeAssgntOnBeforeItemChargeAssignmentPurchModify(Rec, ItemChargeAssgntPurch);
                ItemChargeAssgntPurch.Modify();
            until ItemChargeAssgntPurch.Next() = 0;
            CalcFields("Qty. to Assign", "Item Charge Qty. to Handle");
        end;
    end;

    /// <summary>
    /// Deletes item charge assignments that are applied to purchase document line.
    /// The provided parameters filter out item charge assignments to delete.
    /// </summary>
    /// <param name="DocType">Purchase document type.</param>
    /// <param name="DocNo">Purchase document no.</param>
    /// <param name="DocLineNo">Purchase document line no.</param>
    procedure DeleteItemChargeAssignment(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; DocLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", DocType);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", DocNo);
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", DocLineNo);
        if not ItemChargeAssgntPurch.IsEmpty() then
            ItemChargeAssgntPurch.DeleteAll(true);
        OnAfterDeleteItemChargeAssignment(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// Deletes item charge assignments for a purchase document line.
    /// The provided parameters filter out item charge assignments to delete.
    /// </summary>
    /// <remarks>
    /// If document type is not a blanket order and quantity invoiced is not 0,
    /// the procedure tests if qty. assigned and quantity invoiced are not zero.
    ///</remarks>
    /// <param name="DocType">Purchase document type.</param>
    /// <param name="DocNo">Purchase document no.</param>
    /// <param name="DocLineNo">Purchase document line no.</param>
    procedure DeleteChargeChargeAssgnt(DocType: Enum "Purchase Document Type"; DocNo: Code[20]; DocLineNo: Integer)
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        if DocType <> "Document Type"::"Blanket Order" then
            if "Quantity Invoiced" <> 0 then begin
                CalcFields("Qty. Assigned");
                TestField("Qty. Assigned", "Quantity Invoiced");
            end;

        ItemChargeAssgntPurch.Reset();
        ItemChargeAssgntPurch.SetRange("Document Type", DocType);
        ItemChargeAssgntPurch.SetRange("Document No.", DocNo);
        ItemChargeAssgntPurch.SetRange("Document Line No.", DocLineNo);
        if not ItemChargeAssgntPurch.IsEmpty() then
            ItemChargeAssgntPurch.DeleteAll();

        OnAfterDeleteChargeChargeAssgntProcedure(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// Checks if there are any item charge assignments assigned for the purchase line.
    /// If so, it checks if item charge assignment is allowed and if the quantity to assign is zero.
    /// </summary>
    procedure CheckItemChargeAssgnt()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", "Document No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Line No.", "Line No.");
        ItemChargeAssgntPurch.SetRange("Document Type", "Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", "Document No.");
        if ItemChargeAssgntPurch.FindSet() then begin
            TestField("Allow Item Charge Assignment");
            repeat
                ItemChargeAssgntPurch.TestField("Qty. to Assign", 0);
            until ItemChargeAssgntPurch.Next() = 0;
        end;
    end;

    procedure CheckAssociatedSalesOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssosiatedSalesOrder(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Drop Shipment" then
            Error(Text001, FieldCaption("No."), "Sales Order No.");
        if "Special Order" then
            Error(Text001, FieldCaption("No."), "Special Order Sales No.");
    end;

    local procedure CheckAssociatedProdOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAssosiatedProdOrder(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        OnAfterCheckAssosiatedProdOrder(Rec);
    end;

    local procedure CheckLineNotShippedOrReceived()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLineNotShippedOrReceived(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Qty. Rcd. Not Invoiced", 0);
        TestField("Receipt No.", '');

        TestField("Return Qty. Shipped Not Invd.", 0);
        TestField("Return Shipment No.", '');
    end;

    local procedure CheckNoAndQuantityForItemChargeAssgnt()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoAndQuantityForItemChargeAssgnt(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        TestField(Quantity);
    end;

    /// <summary>
    /// Returns the value of global SkipTaxCalculation flag.
    /// </summary>
    /// <returns>The value of global SkipTaxCalculation flag.</returns>
    procedure GetSkipTaxCalculation(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;

    /// <summary>
    /// Sets the global flag SkipTaxCalculation value.
    /// </summary>
    /// <param name="Skip">The value to set.</param>
    procedure SetSkipTaxCalulation(Skip: Boolean)
    begin
        SkipTaxCalculation := Skip;
    end;

    /// <summary>
    /// Gets a caption class for a field.
    /// </summary>
    /// <param name="FieldNumber">The number of the field to get the caption class for.</param>
    /// <returns>The caption class of a field.</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        PurchLineCaptionClassMgmt: Codeunit "Purch. Line CaptionClass Mgmt";
    begin
        exit(PurchLineCaptionClassMgmt.GetPurchaseLineCaptionClass(Rec, FieldNumber));
    end;

    /// <summary>
    /// Checks whether the purchase header of the line is open.
    /// </summary>
    /// <remarks>
    /// The check is performed exclusively for non-system generated lines, type changes, and lines with non-blank type.
    /// </remarks>
    procedure TestStatusOpen()
    var
        IsHandled: Boolean;
    begin
        GetPurchHeader();
        IsHandled := false;
        OnBeforeTestStatusOpen(Rec, PurchHeader, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if StatusCheckSuspended then
            exit;

        if not "System-Created Entry" then
            if (xRec.Type <> Type) or HasTypeToFillMandatoryFields() then
                PurchHeader.TestField(Status, PurchHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, PurchHeader);
    end;

    /// <summary>
    /// Returns the value of the global variable StatusCheckSuspended.
    /// </summary>
    /// <returns>The value of the global variable StatusCheckSuspended.</returns>
    procedure GetSuspendedStatusCheck(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    /// <summary>
    /// Sets the value of the global variable StatusCheckSuspended.
    /// </summary>
    /// <param name="Suspend">The new value to set.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    /// <summary>
    /// Updates Lead Time fields based on the item, location, variant, and vendor for the purchase line.
    /// </summary>
    /// <remarks>
    /// If the purchase line type is not item, the procedure is ended.
    /// </remarks>
    procedure UpdateLeadTimeFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLeadTimeFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Item then begin
            GetPurchHeader();

            Evaluate("Lead Time Calculation",
              LeadTimeMgt.PurchaseLeadTime(
                "No.", "Location Code", "Variant Code",
                "Buy-from Vendor No."));
            if Format("Lead Time Calculation") = '' then
                "Lead Time Calculation" := PurchHeader."Lead Time Calculation";
            Evaluate("Safety Lead Time", LeadTimeMgt.SafetyLeadTime("No.", "Location Code", "Variant Code"));
        end;
    end;

    /// <summary>
    /// Updates the expected receipt date or order date of a purchase line with the corresponding date in the purchase header.
    /// </summary>
    procedure GetUpdateBasicDates()
    begin
        GetPurchHeader();
        if PurchHeader."Expected Receipt Date" <> 0D then
            Validate("Expected Receipt Date", PurchHeader."Expected Receipt Date")
        else
            Validate("Order Date", PurchHeader."Order Date");
    end;

    /// <summary>
    /// Updates purchase line dates based on the promised receipt date or requested receipt date.
    /// If both dates are empty, the procedure updates the expected receipt date or oreder date of a purchase line
    /// with the corresponding date in the purchase header.
    /// </summary>
    procedure UpdateDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDates(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Promised Receipt Date" <> 0D then
            Validate("Promised Receipt Date")
        else
            if "Requested Receipt Date" <> 0D then
                Validate("Requested Receipt Date")
            else
                GetUpdateBasicDates();

        OnAfterUpdateDates(Rec);
    end;

    /// <summary>
    /// Returns the total lead time in days for a purchase line, taking into account the safety lead time and inbound whse. handling time.
    /// Used to calculate expected receipt date for the purchase line.
    /// </summary>
    /// <param name="PurchDate">Planned receipt date of the purchase line.</param>
    /// <returns>Total lead time in days.</returns>
    procedure InternalLeadTimeDays(PurchDate: Date): Text[30]
    var
        TotalDays: DateFormula;
    begin
        Evaluate(
          TotalDays, '<' + Format(CalcDate("Safety Lead Time", CalcDate("Inbound Whse. Handling Time", PurchDate)) - PurchDate) + 'D>');
        OnAfterInternalLeadTimeDays(Rec, PurchDate, TotalDays);
        exit(Format(TotalDays));
    end;

    local procedure ReversedInternalLeadTimeDays(PurchDate: Date): Text[30]
    var
        TotalDays: DateFormula;
        ReversedSafetyLeadTime: DateFormula;
        ReversedWhseHandlingTime: DateFormula;
    begin
        CalendarMgmt.ReverseDateFormula(ReversedSafetyLeadTime, "Safety Lead Time");
        CalendarMgmt.ReverseDateFormula(ReversedWhseHandlingTime, "Inbound Whse. Handling Time");
        Evaluate(
          TotalDays, '<' + Format(PurchDate - CalcDate(ReversedWhseHandlingTime, CalcDate(ReversedSafetyLeadTime, PurchDate))) + 'D>');

        OnAfterReversedInternalLeadTimeDays(Rec, PurchDate, ReversedWhseHandlingTime, TotalDays);
        exit(Format(TotalDays));
    end;

    /// <summary>
    /// Updates VAT and related amounts on all lines of the document.
    /// </summary>
    /// <remarks>
    /// If parameter QtyType is Shipping procedure is ended without updating the lines.
    /// </remarks>
    /// <param name="QtyType">The type of quantity to consider for the update (Qty, QtyToInvoice, QtyToReceive).</param>
    /// <param name="PurchHeader">The purchase header of the document. The purchase lines are filtered based on this document.</param>
    /// <param name="PurchLine">Purhcase line record that will be iterated through. Any existing filters on this record will narrow down the lines to consider.</param>
    /// <param name="VATAmountLine">Calculated VAT amount set. For each purchase line, the corresponding VAT amount line will be extracted from this collection.</param>
    /// <returns>True if any line was modified, otherwise false.</returns>
    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line") LineWasModified: Boolean
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        NonDedVATAmount: Decimal;
        VATDifference: Decimal;
        NonDedVATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
        LineAmountToInvoiceDiscounted: Decimal;
        DeferralAmount: Decimal;
        IsHandled: Boolean;
        IsLineAmountToInvoiceSimple: Boolean;
    begin
        LineWasModified := false;
        if QtyType = QtyType::Shipping then
            exit;
        if PurchHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(PurchHeader."Currency Code");

        TempVATAmountLineRemainder.DeleteAll();

        IsHandled := false;
        OnUpdateVATOnLinesOnBeforeProcessPurchLines(Rec, xRec, PurchHeader, VATAmountLine, TempVATAmountLineRemainder, LineWasModified, IsHandled, QtyType);
        if IsHandled then
            exit(LineWasModified);

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        SetLoadFieldsForInvDiscoundCalculation(PurchLine);
        OnUpdateVATOnLinesOnAfterSetFilters(PurchLine, PurchHeader);
        PurchLine.LockTable();
        if PurchLine.FindSet() then
            repeat
                if not PurchLine.ZeroAmountLine(QtyType) then begin
                    OnUpdateVATOnLinesOnBeforeProcessPurchLine(PurchLine, PurchHeader, VATAmountLine, QtyType);
                    DeferralAmount := PurchLine.GetDeferralAmount();
                    FindVATAmountLine(PurchLine, VATAmountLine);
                    if VATAmountLine.Modified then begin
                        if not FindVATAmountLine(PurchLine, TempVATAmountLineRemainder) then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        IsLineAmountToInvoiceSimple := QtyType = QtyType::General;

                        if not IsLineAmountToInvoiceSimple then
                            OnAfterCheckIsLineAmountToInvoiceSimple(PurchHeader, IsLineAmountToInvoiceSimple);

                        if IsLineAmountToInvoiceSimple then
                            LineAmountToInvoice := PurchLine."Line Amount"
                        else
                            LineAmountToInvoice :=
                              Round(PurchLine."Line Amount" * PurchLine."Qty. to Invoice" / PurchLine.Quantity, Currency."Amount Rounding Precision");

                        if PurchLine."Allow Invoice Disc." then begin
                            if (VATAmountLine."Inv. Disc. Base Amount" = 0) or (LineAmountToInvoice = 0) then
                                InvDiscAmount := 0
                            else begin
                                if IsLineAmountToInvoiceSimple then
                                    LineAmountToInvoice := PurchLine."Line Amount"
                                else
                                    LineAmountToInvoice :=
                                      Round(PurchLine."Line Amount" * PurchLine."Qty. to Invoice" / PurchLine.Quantity, Currency."Amount Rounding Precision");
                                LineAmountToInvoiceDiscounted :=
                                  VATAmountLine."Invoice Discount Amount" * LineAmountToInvoice /
                                  VATAmountLine."Inv. Disc. Base Amount";
                                TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                  TempVATAmountLineRemainder."Invoice Discount Amount" + LineAmountToInvoiceDiscounted;
                                InvDiscAmount :=
                                  Round(
                                    TempVATAmountLineRemainder."Invoice Discount Amount", Currency."Amount Rounding Precision");
                                TempVATAmountLineRemainder."Invoice Discount Amount" :=
                                  TempVATAmountLineRemainder."Invoice Discount Amount" - InvDiscAmount;
                            end;
                            if IsLineAmountToInvoiceSimple then begin
                                PurchLine."Inv. Discount Amount" := InvDiscAmount;
                                PurchLine.CalcInvDiscToInvoice();
                            end else
                                PurchLine."Inv. Disc. Amount to Invoice" := InvDiscAmount;
                        end else
                            InvDiscAmount := 0;

                        OnUpdateVATOnLinesOnBeforeCalculateAmounts(PurchLine, PurchHeader);
                        if QtyType = QtyType::General then begin
                            if PurchHeader."Prices Including VAT" then begin
                                if (VATAmountLine.CalcLineAmount() = 0) or (PurchLine."Line Amount" = 0) then begin
                                    VATAmount := 0;
                                    NonDedVATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * PurchLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                    NonDedVATAmount :=
                                        NonDeductibleVAT.GetNonDedVATAmountFromVATAmountLine(TempVATAmountLineRemainder, VATAmountLine, Currency, PurchLine.CalcLineAmount(), VATAmountLine.CalcLineAmount());
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * PurchLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                end;
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                  Round(VATAmount, Currency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100),
                                    Currency."Amount Rounding Precision");
                            end else begin
                                if PurchLine."VAT Calculation Type" = PurchLine."VAT Calculation Type"::"Full VAT" then begin
                                    VATAmount := PurchLine.CalcLineAmount();
                                    NewAmount := 0;
                                    NewVATBaseAmount := 0;
                                end else begin
                                    NewAmount := PurchLine.CalcLineAmount();
                                    NewVATBaseAmount :=
                                      Round(
                                        NewAmount * (1 - GetVatBaseDiscountPct(PurchHeader) / 100),
                                        Currency."Amount Rounding Precision");
                                    IsHandled := false;
                                    OnUpdateVATOnLinesOnBeforeCalcNotFullVATAmount(Rec, PurchHeader, Currency, VATAmountLine, TempVATAmountLineRemainder, NewVATBaseAmount, VATAmount, IsHandled);
                                    if not IsHandled then
                                        if VATAmountLine."VAT Base" = 0 then begin
                                            VATAmount := 0;
                                            NonDedVATAmount := 0;
                                        end else begin
                                            VATAmount :=
                                              TempVATAmountLineRemainder."VAT Amount" +
                                              VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                            NonDedVATAmount :=
                                                NonDeductibleVAT.GetNonDedVATAmountFromVATAmountLine(TempVATAmountLineRemainder, VATAmountLine, Currency, NewAmount, VATAmountLine."VAT Base");
                                        end;
                                end;
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end;
                            OnUpdateVATOnLinesOnAfterCalculateNewAmount(
                                Rec, PurchHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmountIncludingVAT, VATAmount,
                                NewAmount, NewVATBaseAmount, PurchLine);
                        end else begin
                            if VATAmountLine.CalcLineAmount() = 0 then
                                ClearVATDifference()
                            else
                                VATDifference :=
                                  TempVATAmountLineRemainder."VAT Difference" +
                                  VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) / VATAmountLine.CalcLineAmount();
                            if LineAmountToInvoice = 0 then begin
                                PurchLine.ClearVATDifference();
                                NonDedVATAmount := 0;
                                NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
                            end else begin
                                PurchLine."VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                                NonDedVATAmount :=
                                    NonDeductibleVAT.GetNonDedVATAmountFromVATAmountLine(
                                        TempVATAmountLineRemainder, VATAmountLine, Currency, LineAmountToInvoice - InvDiscAmount, VATAmountLine.CalcLineAmount());
                                NonDeductibleVAT.SetNonDedVATAmountDiffInPurchLine(
                                    PurchLine, TempVATAmountLineRemainder, NonDedVATDifference, VATAmountLine, Currency,
                                    LineAmountToInvoice - InvDiscAmount, VATAmountLine.CalcLineAmount());
                            end;
                            OnUpdateVATOnLinesOnAfterCalculateVATDifference(
                                Rec, PurchHeader, VATAmountLine, TempVATAmountLineRemainder, QtyType, PurchLine, LineAmountToInvoice, InvDiscAmount);
                        end;
                        OnUpdateVATOnLinesOnAfterCalculateAmounts(PurchLine, PurchHeader);

                        if QtyType = QtyType::General then begin
                            if not PurchLine."Prepayment Line" then
                                PurchLine.UpdatePrepmtAmounts();
                            PurchLine.UpdateBaseAmounts(NewAmount, Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision"), NewVATBaseAmount);
                            NonDeductibleVAT.SetNonDedVATAmountInPurchLine(PurchLine, NonDedVATAmount);
                            OnUpdateVATOnLinesOnAfterUpdateBaseAmounts(PurchHeader, PurchLine, TempVATAmountLineRemainder, VATAmountLine, Currency);
                        end;
                        OnUpdateVATOnLinesOnBeforeInitOutstanding(Rec, QtyType);
                        PurchLine.InitOutstanding();
                        if not ((PurchLine.Type = PurchLine.Type::"Charge (Item)") and (PurchLine."Quantity Invoiced" <> PurchLine."Qty. Assigned")) then begin
                            PurchLine.SetUpdateFromVAT(true);
                            PurchLine.UpdateUnitCost();
                        end;
                        if PurchLine.Type = PurchLine.Type::"Charge (Item)" then
                            PurchLine.UpdateItemChargeAssgnt();
                        OnUpdateVATOnLinesOnBeforeModifyPurchLine(PurchLine, VATAmount);
                        PurchLine.Modify();
                        LineWasModified := true;

                        if (PurchLine."Deferral Code" <> '') and (DeferralAmount <> PurchLine.GetDeferralAmount()) then
                            PurchLine.UpdateDeferralAmounts();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - PurchLine."VAT Difference";
                        OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(Rec, TempVATAmountLineRemainder, VATAmount, NewVATBaseAmount, PurchLine);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until PurchLine.Next() = 0;
        VATAmountLine.Reset();
        PurchLine.SetLoadFields();

        OnAfterUpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, QtyType);
    end;

    /// <summary>
    /// Calculates the VAT amounts for purchase lines based on the quantity type, and updates the VAT amount lines accordingly.
    /// </summary>
    /// <remarks>
    /// VATAmountLine parameter must be temporary, because DeleteAll is called for it.
    /// </remarks>
    /// <param name="QtyType">The type of quantity to consider for the update (Qty, QtyToInvoice, QtyToReceive).</param>
    /// <param name="PurchHeader">The purchase header of the document. The purchase lines are filtered based on this document.</param>
    /// <param name="PurchLine">Purhcase line record that will be iterated through. Any existing filters on this record will narrow down the lines to consider.</param>
    /// <param name="VATAmountLine">Return value: Calculated and inserted VAT amount lines.</param>
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        TotalVATAmount: Decimal;
        QtyToHandle: Decimal;
        AmtToHandle: Decimal;
        RoundingLineInserted: Boolean;
        IsHandled: Boolean;
        ShouldProcessRounding: Boolean;
    begin
        if IsCalcVATAmountLinesHandled(PurchHeader, PurchLine, VATAmountLine, QtyType) then
            exit;

        Currency.Initialize(PurchHeader."Currency Code");

        VATAmountLine.DeleteAll();

        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        SetLoadFieldsForInvDiscoundCalculation(PurchLine);
        OnCalcVATAmountLinesOnAfterSetFilters(PurchLine, PurchHeader);
        if PurchLine.FindSet() then
            repeat
                if not PurchLine.ZeroAmountLine(QtyType) then begin
                    OnCalcVATAmountLinesOnBeforeProcessPurchLine(PurchLine, PurchHeader, VATAmountLine, QtyType);
                    if (PurchLine.Type = PurchLine.Type::"G/L Account") and not PurchLine."Prepayment Line" then
                        RoundingLineInserted := ((PurchLine."No." = PurchLine.GetVPGInvRoundAcc(PurchHeader)) and PurchLine."System-Created Entry") or RoundingLineInserted;
                    if PurchLine."VAT Calculation Type" in
                       [PurchLine."VAT Calculation Type"::"Reverse Charge VAT", PurchLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        PurchLine.ClearVATPct();

                    if not FindVATAmountLine(PurchLine, VATAmountLine) then begin
                        InsertVATAmountLine(PurchLine, VATAmountLine);
                        OnCalcVATAmountLinesAfterVATAmountLineInsertNewLine(PurchLine, VATAmountLine);
                    end;

                    case QtyType of
                        QtyType::General:
                            begin
                                VATAmountLine.Quantity += PurchLine."Quantity (Base)";
                                NonDeductibleVAT.AddNonDedAmountsOfPurchLineToVATAmountLine(VATAmountLine, TempVATAmountLineRemainder, PurchLine, Currency, 1, 1);
                                OnCalcVATAmountLinesOnBeforeVATAmountLineSumLine(Rec, VATAmountLine, QtyType, PurchLine);
                                SumVATAmountLine(PurchHeader, PurchLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                        QtyType::Invoicing:
                            begin
                                IsHandled := false;
                                OnCalcVATAmountLinesOnBeforeAssignQuantities(PurchHeader, PurchLine, VATAmountLine, QtyToHandle, IsHandled);
                                if not IsHandled then
                                    case true of
                                        (PurchLine."Document Type" in [PurchLine."Document Type"::Order, PurchLine."Document Type"::Invoice]) and
                                    (not PurchHeader.Receive) and PurchHeader.Invoice and (not PurchLine."Prepayment Line"):
                                            if PurchLine."Receipt No." = '' then begin
                                                QtyToHandle := PurchLine.GetAbsMin(PurchLine."Qty. to Invoice", PurchLine."Qty. Rcd. Not Invoiced");
                                                VATAmountLine.Quantity += PurchLine.GetAbsMin(PurchLine."Qty. to Invoice (Base)", PurchLine."Qty. Rcd. Not Invoiced (Base)");
                                            end else begin
                                                QtyToHandle := PurchLine."Qty. to Invoice";
                                                VATAmountLine.Quantity += PurchLine."Qty. to Invoice (Base)";
                                            end;
                                        PurchLine.IsCreditDocType() and (not PurchHeader.Ship) and PurchHeader.Invoice:
                                            if PurchLine."Return Shipment No." = '' then begin
                                                QtyToHandle := PurchLine.GetAbsMin(PurchLine."Qty. to Invoice", PurchLine."Return Qty. Shipped Not Invd.");
                                                VATAmountLine.Quantity += PurchLine.GetAbsMin(PurchLine."Qty. to Invoice (Base)", PurchLine."Ret. Qty. Shpd Not Invd.(Base)");
                                            end else begin
                                                QtyToHandle := PurchLine."Qty. to Invoice";
                                                VATAmountLine.Quantity += PurchLine."Qty. to Invoice (Base)";
                                            end;
                                        else begin
                                            QtyToHandle := PurchLine."Qty. to Invoice";
                                            VATAmountLine.Quantity += PurchLine."Qty. to Invoice (Base)";
                                        end;
                                    end;
                                OnCalcVATAmountLinesOnQtyTypeInvoicingOnBeforeCalcAmtToHandle(PurchLine, PurchHeader, QtyToHandle, VATAmountLine);
                                AmtToHandle := PurchLine.GetLineAmountToHandleInclPrepmt(QtyToHandle);
                                NonDeductibleVAT.AddNonDedAmountsOfPurchLineToVATAmountLine(VATAmountLine, TempVATAmountLineRemainder, PurchLine, Currency, QtyToHandle, PurchLine.Quantity);
                                OnCalcVATAmountLinesOnBeforeVATAmountLineSumLine(Rec, VATAmountLine, QtyType, PurchLine);
                                SumVATAmountLine(PurchHeader, PurchLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                        QtyType::Shipping:
                            begin
                                IsHandled := false;
                                OnCalcVATAmountLinesOnBeforeAssignShippingQuantities(PurchHeader, PurchLine, VATAmountLine, QtyToHandle, IsHandled);
                                if not IsHandled then
                                    if PurchLine.IsCreditDocType() then begin
                                        QtyToHandle := PurchLine."Return Qty. to Ship";
                                        VATAmountLine.Quantity += PurchLine."Return Qty. to Ship (Base)";
                                    end else begin
                                        QtyToHandle := PurchLine."Qty. to Receive";
                                        VATAmountLine.Quantity += PurchLine."Qty. to Receive (Base)";
                                    end;
                                OnCalcVATAmountLinesOnQtyTypeShippingOnBeforeCalcAmtToHandle(PurchLine, PurchHeader, QtyToHandle, VATAmountLine);
                                AmtToHandle := PurchLine.GetLineAmountToHandleInclPrepmt(QtyToHandle);
                                OnCalcVATAmountLinesOnBeforeVATAmountLineSumLine(Rec, VATAmountLine, QtyType, PurchLine);
                                SumVATAmountLine(PurchHeader, PurchLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                    end;
                    TotalVATAmount += PurchLine."Amount Including VAT" - PurchLine.Amount;
                    OnCalcVATAmountLinesOnAfterCalcLineTotals(VATAmountLine, PurchHeader, PurchLine, Currency, QtyType, TotalVATAmount);
                end;
            until PurchLine.Next() = 0;
        VATAmountLine.Reset();
        PurchLine.SetLoadFields();

        OnCalcVATAmountLinesOnBeforeVATAmountLineUpdateLines(PurchLine, VATAmountLine, TotalVATAmount);
        VATAmountLine.UpdateLines(
          TotalVATAmount, Currency, PurchHeader."Currency Factor", PurchHeader."Prices Including VAT",
          PurchHeader."VAT Base Discount %", PurchHeader."Tax Area Code", PurchHeader."Tax Liable", PurchHeader."Posting Date");

        ShouldProcessRounding := RoundingLineInserted and (TotalVATAmount <> 0);
        OnCalcVATAmountLinesOnAfterCalcShouldProcessRounding(PurchLine, VATAmountLine, TotalVATAmount, Currency, ShouldProcessRounding);
        if ShouldProcessRounding then
            if GetVATAmountLineOfMaxAmt(VATAmountLine, PurchLine) then begin
                VATAmountLine."VAT Amount" += TotalVATAmount;
                VATAmountLine."Amount Including VAT" += TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" += TotalVATAmount;
                VATAmountLine.Modify();
            end;

        OnAfterCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, QtyType);
    end;

    local procedure FindVATAmountLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line" temporary): Boolean
    begin
        VATAmountLine.Reset();
        VATAmountLine.SetRange("VAT Identifier", PurchaseLine."VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", PurchaseLine."VAT Calculation Type");
        VATAmountLine.SetRange("Tax Group Code", PurchaseLine."Tax Group Code");
        VATAmountLine.SetRange("Use Tax", PurchaseLine."Use Tax");
        VATAmountLine.SetRange(Positive, PurchaseLine."Line Amount" >= 0);
        OnFindVATAmountLineOnAfterSetFilters(PurchaseLine, VATAmountLine);
        exit(VATAmountLine.FindFirst());
    end;

    local procedure InsertVATAmountLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := PurchaseLine."VAT Identifier";
        VATAmountLine."VAT Calculation Type" := PurchaseLine."VAT Calculation Type";
        VATAmountLine."Tax Group Code" := PurchaseLine."Tax Group Code";
        VATAmountLine."Use Tax" := PurchaseLine."Use Tax";
        VATAmountLine."VAT %" := PurchaseLine."VAT %";
        VATAmountLine.Modified := true;
        VATAmountLine.Positive := PurchaseLine."Line Amount" >= 0;
        VATAmountLine."Includes Prepayment" := false;
        VATAmountLine."Non-Deductible VAT %" := PurchaseLine."Non-Deductible VAT %";
        OnInsertVATAmountOnBeforeInsert(PurchaseLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    local procedure SumVATAmountLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping; AmtToHandle: Decimal; QtyToHandle: Decimal)
    begin
        case QtyType of
            QtyType::General:
                begin
                    VATAmountLine."Line Amount" += PurchaseLine."Line Amount";
                    if PurchaseLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += PurchaseLine."Line Amount";
                    VATAmountLine."Invoice Discount Amount" += PurchaseLine."Inv. Discount Amount";
                end;
            QtyType::Invoicing:
                if PurchaseHeader."Invoice Discount Calculation" <> PurchaseHeader."Invoice Discount Calculation"::Amount then begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if PurchaseLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += Round(PurchaseLine."Inv. Discount Amount" * QtyToHandle / PurchaseLine.Quantity, Currency."Amount Rounding Precision");
                end else begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if PurchaseLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += PurchaseLine."Inv. Disc. Amount to Invoice";
                end;
            QtyType::Shipping:
                begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if PurchaseLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += Round(PurchaseLine."Inv. Discount Amount" * QtyToHandle / PurchaseLine.Quantity, Currency."Amount Rounding Precision");
                end;
        end;
        VATAmountLine."VAT Difference" += PurchaseLine."VAT Difference";
        if PurchaseLine."Prepayment Line" then
            VATAmountLine."Includes Prepayment" := true;
        OnSumVATAmountLineOnBeforeModify(PurchaseLine, VATAmountLine);
        VATAmountLine.Modify();
    end;

    /// <summary>
    /// Retrieves the VAT amount line corresponding to the purchase line with the highest absolute amount from the set of VAT amount lines.
    /// </summary>
    /// <param name="VATAmountLine">Return value: The VAT amount line with the maximum absolute amount.</param>
    /// <param name="PurchaseLine">The purchase line record to filter the VAT amount line set.</param>
    /// <returns>True if a VAT amount line was found, otherwise false.</returns>
    procedure GetVATAmountLineOfMaxAmt(var VATAmountLine: Record "VAT Amount Line"; PurchaseLine: Record "Purchase Line") Found: Boolean
    var
        VATAmount1: Decimal;
        VATAmount2: Decimal;
        IsPositive1: Boolean;
        IsPositive2: Boolean;
    begin
        VATAmountLine.SetRange("VAT Identifier", PurchaseLine."VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", PurchaseLine."VAT Calculation Type");
        VATAmountLine.SetRange("Tax Group Code", PurchaseLine."Tax Group Code");
        VATAmountLine.SetRange("Use Tax", false);
        VATAmountLine.SetRange(Positive, false);
        if VATAmountLine.FindFirst() then begin
            VATAmount1 := VATAmountLine."VAT Amount";
            IsPositive1 := VATAmountLine.Positive;
        end;
        VATAmountLine.SetRange(Positive, true);
        if VATAmountLine.FindFirst() then begin
            VATAmount2 := VATAmountLine."VAT Amount";
            IsPositive2 := VATAmountLine.Positive;
        end;
        if Abs(VATAmount1) >= Abs(VATAmount2) then begin
            VATAmountLine.SetRange(Positive, IsPositive1);
            exit(VATAmountLine.FindFirst());
        end;
        VATAmountLine.SetRange(Positive, IsPositive2);
        Found := VATAmountLine.FindFirst();
        VATAmountLine.Reset();
    end;

    /// <summary>
    /// Updates the quantities to receive or return for a purchase line based on the document type, quantity, and the location.
    /// </summary>
    procedure UpdateWithWarehouseReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWithWarehouseReceive(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsInventoriableItem() then
            case true of
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity >= 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Qty. to Receive", 0)
                    else
                        Validate("Qty. to Receive", "Outstanding Quantity");
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity < 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Qty. to Receive", 0)
                    else
                        Validate("Qty. to Receive", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Return Qty. to Ship", 0)
                    else
                        Validate("Return Qty. to Ship", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity < 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Return Qty. to Ship", 0)
                    else
                        Validate("Return Qty. to Ship", "Outstanding Quantity");
            end;

        GetPurchHeader();
        OnAfterUpdateWithWarehouseReceive(PurchHeader, Rec);

        SetDefaultQuantity();
    end;

    /// <summary>
    /// Checks warehouse requirements for a purchase line.
    /// </summary>
    /// <remarks>
    /// The check is only conducted under the condition that the purchase line is inbound, the item in the purchase line has an inventory type, and the location has a mandatory bin.
    /// </remarks>
    /// <param name="ShowDialogMessage">If true, then error or message is shown to inform the user about the requirements or issues.</param>
    procedure CheckWarehouse(ShowDialogMessage: Boolean)
    var
        Location2: Record Location;
        WarehouseSetup: Record "Warehouse Setup";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WMSManagement: Codeunit "WMS Management";
        ShowDialog: Option " ",Message,Error;
        DialogText: Text[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouse(Rec, IsHandled, ShowDialogMessage);
        if IsHandled then
            exit;

        if IsProdOrder() then
            exit;

        GetLocation("Location Code");
        if "Location Code" = '' then begin
            WarehouseSetup.SetLoadFields("Require Pick", "Require Put-away", "Require Receive", "Require Shipment");
            WarehouseSetup.Get();
            Location2."Require Shipment" := WarehouseSetup."Require Shipment";
            Location2."Require Pick" := WarehouseSetup."Require Pick";
            Location2."Require Receive" := WarehouseSetup."Require Receive";
            Location2."Require Put-away" := WarehouseSetup."Require Put-away";
        end else
            Location2 := Location;

        OnCheckWarehouseOnAfterSetLocation2(Rec, Location2);

        if IsInbound() and IsInventoriableItem() and Location2."Bin Mandatory" then
            WMSManagement.CheckWarehouse(Location2.Code, Rec."Bin Code", Rec."No.", Rec."Variant Code", Rec."Unit of Measure Code", Quantity);

        if ShowDialogMessage then begin
            DialogText := Text033;
            if ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"]) and
               Location2."Directed Put-away and Pick"
            then begin
                ShowDialog := ShowDialog::Error;
                if (("Document Type" = "Document Type"::Order) and (Quantity >= 0)) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0))
                then
                    DialogText :=
                      CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive")), 1, MaxStrLen(DialogText))
                else
                    DialogText :=
                      CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment")), 1, MaxStrLen(DialogText));
            end else begin
                if (("Document Type" = "Document Type"::Order) and (Quantity >= 0) and
                    (Location2."Require Receive" or Location2."Require Put-away")) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0) and
                    (Location2."Require Receive" or Location2."Require Put-away"))
                then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Purchase Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Receive" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Receive" then
                        DialogText :=
                          CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive")), 1, MaxStrLen(DialogText))
                    else begin
                        DialogText := Text034;
                        DialogText :=
                          CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Put-away")), 1, MaxStrLen(DialogText));
                    end;
                end;

                if (("Document Type" = "Document Type"::Order) and (Quantity < 0) and
                    (Location2."Require Shipment" or Location2."Require Pick")) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0) and
                    (Location2."Require Shipment" or Location2."Require Pick"))
                then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         Database::"Purchase Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Shipment" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Shipment" then
                        DialogText :=
                         CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment")), 1, MaxStrLen(DialogText))
                    else begin
                        DialogText := Text034;
                        DialogText :=
                          CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick")), 1, MaxStrLen(DialogText));
                    end;
                end;
            end;

            OnCheckWarehouseOnBeforeShowDialog(Rec, Location2, ShowDialog, DialogText);
            case ShowDialog of
                ShowDialog::Message:
                    Message(WhseRequirementMsg, DialogText);
                ShowDialog::Error:
                    Error(Text016, DialogText, FieldCaption("Line No."), "Line No.")
            end;
        end;

        HandleDedicatedBin(true);
    end;

    /// <summary>
    /// Calculates the overhead rate in foreign currency for the purchase line.
    /// </summary>
    /// <returns>Overhead rate in foreign currency.</returns>
    protected procedure GetOverheadRateFCY() Result: Decimal
    var
        Item: Record Item;
        QtyPerUOM: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOverheadRateFCY(Rec, QtyPerUOM, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not IsProdOrder() then
            QtyPerUOM := "Qty. per Unit of Measure"
        else begin
            GetItem(Item);
            QtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        end;
        OnAfterGetQtyPerUOM(QtyPerUOM);

        exit(
          CurrExchRate.ExchangeAmtLCYToFCY(
            GetDate(), "Currency Code", "Overhead Rate" * QtyPerUOM, PurchHeader."Currency Factor"));
    end;

    /// <summary>
    /// Gets the translation of an item's description based on the language code of the purchase header
    /// and updates the description fields of the purchase line.
    /// </summary>
    procedure GetItemTranslation()
    var
        ItemTranslation: Record "Item Translation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemTranslation(Rec, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader();
        if ItemTranslation.Get("No.", "Variant Code", PurchHeader."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
            OnAfterGetItemTranslation(Rec, PurchHeader, ItemTranslation);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetPurchSetup()
    begin
        if not PurchSetupRead then
            PurchSetup.Get();
        PurchSetupRead := true;

        OnAfterGetPurchSetup(Rec, PurchSetup);
    end;

    /// <summary>
    /// Formats a date formula parameter and returns it as a text.
    /// </summary>
    /// <param name="DateFormulatoAdjust">Date formula to adjust.</param>
    /// <returns>Formated date formula as text.</returns>
    procedure AdjustDateFormula(DateFormulatoAdjust: DateFormula): Text[30]
    begin
        if Format(DateFormulatoAdjust) <> '' then
            exit(Format(DateFormulatoAdjust));
        Evaluate(DateFormulatoAdjust, '<0D>');
        exit(Format(DateFormulatoAdjust));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    /// <summary>
    /// Generates a unique identifier text for a purchase line record which is used for item tracking or drop shipment creation.
    /// </summary>
    /// <returns>Generated text</returns>
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
            ItemTrackingMgt.ComposeRowID(
                Database::"Purchase Line", "Document Type".AsInteger(), "Document No.", '', 0, "Line No."));
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if (Type <> Type::Item) or IsNonInventoriableItem() then
            exit;

        "Bin Code" := '';
        if "Drop Shipment" then
            exit;

        if ("Location Code" <> '') and ("No." <> '') then begin
            GetLocation("Location Code");
            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then begin
                WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                HandleDedicatedBin(false);
            end;
        end;

        OnAfterGetDefaultBin(Rec);
    end;

    /// <summary>
    /// Determines if a purchase line is inbound based on the document type and quantity.
    /// </summary>
    /// <returns>True if purchase line is inbound, otherwise false.</returns>
    procedure IsInbound(): Boolean
    var
        IsInboundDocument: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote, "Document Type"::"Blanket Order":
                exit("Quantity (Base)" > 0);
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                exit("Quantity (Base)" < 0);
        end;

        IsInboundDocument := false;
        OnAfterIsInbound(Rec, IsInboundDocument);
        exit(IsInboundDocument);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        OnBeforeHandleDedicatedBin(Rec, xRec, IssueWarning);
        if not IsInbound() and ("Quantity (Base)" <> 0) then
            WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    local procedure VerifyLineTypeForJob()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyLineTypeForJob(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if not (Type in [Type::Item, Type::"G/L Account"]) then
            FieldError("Job No.", StrSubstNo(MustNotBeSpecifiedErr, FieldCaption(Type), Type));
    end;

    /// <summary>
    /// Checks if an item with a given item number exists in the Item table, but only if the type of the purchase line is item.
    /// </summary>
    /// <param name="ItemNo">Item number to check.</param>
    /// <returns>True if the item exists, otherwise false.</returns>
    procedure ItemExists(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if Type = Type::Item then
            if not Item2.Get(ItemNo) then
                exit(false);
        exit(true);
    end;

    /// <summary>
    /// Finds or creates a record by a given number and returns the number of the found or created record.
    /// </summary>
    /// <param name="SourceNo">A record number to find or create.</param>
    /// <returns>Number of the found or newly created record.</returns>
    procedure FindOrCreateRecordByNo(SourceNo: Code[20]): Code[20]
    var
        Item: Record Item;
        FindRecordManagement: Codeunit "Find Record Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindOrCreateRecordByNo(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit("No.");

        GetPurchSetup();

        if (SourceNo = '') then
            exit('');
        if Type = Type::Item then
            exit(Item.GetFirstItemNoFromLookup(SourceNo))
        else
            exit(FindRecordManagement.FindNoFromTypedValue(Type.AsInteger(), "No.", not "System-Created Entry"));

        exit(SourceNo);
    end;

    /// <summary>
    /// Returns smaller absolute value between QtyToHandle and QtyHandled to ensure that the quantity being handled
    /// does not exceed the quantity that is available to handle.
    /// </summary>
    /// <param name="QtyToHandle">Quantity to handle value.</param>
    /// <param name="QtyHandled">Quantity handled value.</param>
    /// <returns>Smaller absolute value.</returns>
    procedure GetAbsMin(QtyToHandle: Decimal; QtyHandled: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetAbsMin(Rec, QtyToHandle, QtyHandled, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Abs(QtyHandled) < Abs(QtyToHandle) then
            exit(QtyHandled);

        exit(QtyToHandle);
    end;

    local procedure CheckApplToItemLedgEntry() Result: Code[10]
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ApplyRec: Record "Item Application Entry";
        ReturnedQty: Decimal;
        RemainingtobeReturnedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplToItemLedgEntry(Rec, ItemLedgEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Appl.-to Item Entry" = 0 then
            exit;

        if "Receipt No." <> '' then
            exit;

        TestField(Type, Type::Item);
        TestField(Quantity);
        if Signed(Quantity) > 0 then
            TestProdOrderNo();
        if IsCreditDocType() then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029);
        end else
            if Quantity > 0 then
                FieldError(Quantity, Text030);
        ItemLedgEntry.Get("Appl.-to Item Entry");
        ItemLedgEntry.TestField(Positive, true);
        ItemLedgEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-to Item Entry"));

        ItemLedgEntry.TestField("Item No.", "No.");
        ItemLedgEntry.TestField("Variant Code", "Variant Code");

        // Track qty in both alternative and base UOM for better error checking and reporting
        if Abs("Quantity (Base)") > ItemLedgEntry.Quantity then
            Error(
              Text042,
              ItemLedgEntry.Quantity, ItemLedgEntry.FieldCaption("Document No."),
              ItemLedgEntry."Document No.");

        if IsCreditDocType() then
            if Abs("Outstanding Qty. (Base)") > ItemLedgEntry."Remaining Quantity" then begin
                ReturnedQty := ApplyRec.Returned(ItemLedgEntry."Entry No.");
                RemainingtobeReturnedQty := ItemLedgEntry.Quantity - ReturnedQty;
                if not ("Qty. per Unit of Measure" = 0) then begin
                    ReturnedQty := Round(ReturnedQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    RemainingtobeReturnedQty := Round(RemainingtobeReturnedQty / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;

                if ((("Qty. per Unit of Measure" = 0) and (RemainingtobeReturnedQty < Abs("Outstanding Qty. (Base)"))) or
                    (("Qty. per Unit of Measure" <> 0) and (RemainingtobeReturnedQty < Abs("Outstanding Quantity"))))
                then
                    Error(
                      Text035,
                      ReturnedQty, ItemLedgEntry.FieldCaption("Document No."),
                      ItemLedgEntry."Document No.", RemainingtobeReturnedQty);
            end;

        exit(ItemLedgEntry."Location Code");
    end;

    /// <summary>
    /// Updates prepayment amount to deduct of the purchase line.
    /// </summary>
    procedure CalcPrepaymentToDeduct()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPrepaymentToDeduct(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Qty. to Invoice" <> 0) and ("Prepmt. Amt. Inv." <> 0) then begin
            GetPurchHeader();
            if ("Prepayment %" = 100) and not IsFinalInvoice() then
                "Prepmt Amt to Deduct" := GetLineAmountToHandle("Qty. to Invoice") - "Inv. Disc. Amount to Invoice"
            else
                "Prepmt Amt to Deduct" :=
                  Round(
                    ("Prepmt. Amt. Inv." - "Prepmt Amt Deducted") *
                    "Qty. to Invoice" / (Quantity - "Quantity Invoiced"), Currency."Amount Rounding Precision")
        end else
            "Prepmt Amt to Deduct" := 0
    end;

    /// <summary>
    /// Determines if the current purchase line is the final invoice based on the quantity and quantity to invoice.
    /// </summary>
    /// <returns>True if it is a final invoice, otherwise false.</returns>
    procedure IsFinalInvoice(): Boolean
    begin
        exit("Qty. to Invoice" = Quantity - "Quantity Invoiced");
    end;

    /// <summary>
    /// Calculates the line amount to handle for a purchase line based on the quantity to handle.
    /// </summary>
    /// <remarks>
    /// Calculated line amount includes the line discount amount.
    /// </remarks>
    /// <param name="QtyToHandle">Quantity to handle.</param>
    /// <returns>Calculated line amount to handle.</returns>
    procedure GetLineAmountToHandle(QtyToHandle: Decimal): Decimal
    var
        LineAmount: Decimal;
        LineDiscAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLineAmountToHandle(Rec, Currency, QtyToHandle, LineAmount, LineDiscAmount, IsHandled);
        if IsHandled then
            exit(LineAmount - LineDiscAmount);

        if "Line Discount %" = 100 then
            exit(0);

        GetPurchHeader();

        if "Prepmt Amt to Deduct" = 0 then
            LineAmount := Round(QtyToHandle * "Direct Unit Cost", Currency."Amount Rounding Precision")
        else
            if Quantity <> 0 then begin
                LineAmount := Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision");
                LineAmount := Round(QtyToHandle * LineAmount / Quantity, Currency."Amount Rounding Precision");
            end else
                LineAmount := 0;

        if QtyToHandle <> Quantity then
            LineDiscAmount := Round(LineAmount * "Line Discount %" / 100, Currency."Amount Rounding Precision")
        else
            LineDiscAmount := "Line Discount Amount";

        OnAfterGetLineAmountToHandle(Rec, QtyToHandle, LineAmount, LineDiscAmount);
        exit(LineAmount - LineDiscAmount);
    end;

    /// <summary>
    /// Returns the line amount to handle for a purchase line, including prepayment.
    /// </summary>
    /// <remarks>
    /// Prepayment amounts are included in the calculations only if purchase line has to be fully prepaid.
    /// </remarks>
    /// <param name="QtyToHandle">Quantity to handle.</param>
    /// <returns>Calculated line amount to handle.</returns>
    procedure GetLineAmountToHandleInclPrepmt(QtyToHandle: Decimal): Decimal
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocType: Option Invoice,"Credit Memo",Statistic;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        if IsCreditDocType() then
            DocType := DocType::"Credit Memo"
        else
            DocType := DocType::Invoice;

        if ("Prepayment %" = 100) and not "Prepayment Line" and ("Prepmt Amt to Deduct" <> 0) then
            if PurchasePostPrepayments.PrepmtAmount(Rec, DocType) <= 0 then
                exit("Prepmt Amt to Deduct" + "Inv. Disc. Amount to Invoice");
        exit(GetLineAmountToHandle(QtyToHandle));
    end;

    /// <summary>
    /// Determines if the purchase line has a job task set.
    /// </summary>
    /// <remarks>
    /// If job task is set, then journal lines can be created.
    /// </remarks>
    /// <returns>True if the job task is set, otherwise false.</returns>
    procedure JobTaskIsSet(): Boolean
    var
        JobTaskSet: Boolean;
    begin
        JobTaskSet := ("Job No." <> '') and ("Job Task No." <> '') and (Type in [Type::"G/L Account", Type::Item]);
        OnBeforeJobTaskIsSet(Rec, JobTaskSet);
        exit(JobTaskSet);
    end;

    /// <summary>
    /// Creates a temporary global job journal line based on the purchase line.
    /// </summary>
    /// <param name="GetPrices">
    /// If true, it recalculates amounts from unit cost of the purchase line,
    /// otherwise it sets the amounts directly from the purchase line.
    /// </param>
    procedure CreateTempJobJnlLine(GetPrices: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, GetPrices, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader();
        Clear(TempJobJnlLine);
        TempJobJnlLine.DontCheckStdCost();
        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        TempJobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
        TempJobJnlLine.SetCurrencyFactor("Job Currency Factor");
        if Type = Type::"G/L Account" then
            TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::"G/L Account")
        else
            TempJobJnlLine.Validate(Type, TempJobJnlLine.Type::Item);
        OnCreateTempJobJnlLineOnBeforeTempJobJnlLineValidateNo(TempJobJnlLine, Rec);
        TempJobJnlLine.Validate("No.", "No.");
        TempJobJnlLine.Validate(Quantity, Quantity);
        TempJobJnlLine.Validate("Variant Code", "Variant Code");
        TempJobJnlLine.Validate("Unit of Measure Code", "Unit of Measure Code");

        if not GetPrices then begin
            if xRec."Line No." <> 0 then begin
                TempJobJnlLine."Unit Cost" := xRec."Unit Cost";
                TempJobJnlLine."Unit Cost (LCY)" := xRec."Unit Cost (LCY)";
                TempJobJnlLine."Unit Price" := xRec."Job Unit Price";
                TempJobJnlLine."Line Amount" := xRec."Job Line Amount";
                TempJobJnlLine."Line Discount %" := xRec."Job Line Discount %";
                TempJobJnlLine."Line Discount Amount" := xRec."Job Line Discount Amount";
            end else begin
                TempJobJnlLine."Unit Cost" := "Unit Cost";
                TempJobJnlLine."Unit Cost (LCY)" := "Unit Cost (LCY)";
                TempJobJnlLine."Unit Price" := "Job Unit Price";
                TempJobJnlLine."Line Amount" := "Job Line Amount";
                TempJobJnlLine."Line Discount %" := "Job Line Discount %";
                TempJobJnlLine."Line Discount Amount" := "Job Line Discount Amount";
            end;
            TempJobJnlLine.Validate("Unit Price");
        end else
            TempJobJnlLine.Validate("Unit Cost (LCY)", "Unit Cost (LCY)");

        OnAfterCreateTempJobJnlLine(TempJobJnlLine, Rec, xRec, GetPrices, CurrFieldNo);
    end;

    /// <summary>
    /// Updates the job prices in the purchase line record based on the purchase receipt line,
    /// or the global job journal line if receipt line doesn't exist.
    /// </summary>
    procedure UpdateJobPrices()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobPrices(Rec, TempJobJnlLine, PurchRcptLine, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if "Receipt No." = '' then begin
            "Job Unit Price" := TempJobJnlLine."Unit Price";
            "Job Total Price" := TempJobJnlLine."Total Price";
            "Job Unit Price (LCY)" := TempJobJnlLine."Unit Price (LCY)";
            "Job Total Price (LCY)" := TempJobJnlLine."Total Price (LCY)";
            "Job Line Amount (LCY)" := TempJobJnlLine."Line Amount (LCY)";
            "Job Line Disc. Amount (LCY)" := TempJobJnlLine."Line Discount Amount (LCY)";
            "Job Line Amount" := TempJobJnlLine."Line Amount";
            "Job Line Discount %" := TempJobJnlLine."Line Discount %";
            "Job Line Discount Amount" := TempJobJnlLine."Line Discount Amount";
        end else begin
            PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
            "Job Unit Price" := PurchRcptLine."Job Unit Price";
            "Job Total Price" := PurchRcptLine."Job Total Price";
            "Job Unit Price (LCY)" := PurchRcptLine."Job Unit Price (LCY)";
            "Job Total Price (LCY)" := PurchRcptLine."Job Total Price (LCY)";
            "Job Line Amount (LCY)" := PurchRcptLine."Job Line Amount (LCY)";
            "Job Line Disc. Amount (LCY)" := PurchRcptLine."Job Line Disc. Amount (LCY)";
            "Job Line Amount" := PurchRcptLine."Job Line Amount";
            "Job Line Discount %" := PurchRcptLine."Job Line Discount %";
            "Job Line Discount Amount" := PurchRcptLine."Job Line Discount Amount";
        end;

        OnAfterUpdateJobPrices(Rec, TempJobJnlLine, PurchRcptLine);
    end;

    /// <summary>
    /// Updates the job currency factor from the temporary global job journal line.
    /// </summary>
    procedure JobSetCurrencyFactor()
    var
        IsHandled: Boolean;
    begin
        GetPurchHeader();
        IsHandled := false;
        OnBeforeJobSetCurrencyFactor(Rec, IsHandled);
        if IsHandled then
            exit;

        Clear(TempJobJnlLine);
        TempJobJnlLine.Validate("Job No.", "Job No.");
        TempJobJnlLine.Validate("Job Task No.", "Job Task No.");
        TempJobJnlLine.Validate("Posting Date", PurchHeader."Posting Date");
        "Job Currency Factor" := TempJobJnlLine."Currency Factor";
    end;

    /// <summary>
    /// Sets the value of the global variable UpdateFromVAT.
    /// </summary>
    /// <param name="UpdateFromVAT2">The new value to set.</param>
    procedure SetUpdateFromVAT(UpdateFromVAT2: Boolean)
    begin
        UpdateFromVAT := UpdateFromVAT2;
    end;

    /// <summary>
    /// Initializes the quantity to receive and invoice.
    /// Additionally, claculates the invoice discount and prepayment amounts.
    /// </summary>
    procedure InitQtyToReceive2()
    begin
        "Qty. to Receive" := "Outstanding Quantity";
        "Qty. to Receive (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToReceive2(Rec, CurrFieldNo);

        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();
        "VAT Difference" := 0;
        NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);

        OnInitQtyToReceive2OnBeforeCalcInvDiscToInvoice(Rec, xRec);

        CalcInvDiscToInvoice();

        CalcPrepaymentToDeduct();

        if "Job Planning Line No." <> 0 then
            Validate("Job Planning Line No.");

        OnAfterInitQtyToReceive2Procedure(Rec);
    end;

    /// <summary>
    /// Toggles the filter for lines with errors between displaying all lines and only lines with errors.
    /// </summary>
    /// <param name="ShowAllLinesEnabled">
    /// Return value: A toggle for showing all lines or just lines with errors. After switching the filter,
    /// the toggle is returned with the opposite value.
    /// </param>
    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            DocumentErrorsMgt.GetErrorMessages(TempLineErrorMessage);
            if TempLineErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempLineErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempLineErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;

    /// <summary>
    /// Resets qty. to receive values to zero if the document type is an order and the purchase setup has default qty. to receive blank.
    /// </summary>
    procedure ClearQtyIfBlank()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearQtyIfBlank(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            GetPurchSetup();
            if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then begin
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
            end;
        end;
        OnAfterClearQtyIfBlank(Rec, xRec, PurchSetup);
    end;

    /// <summary>
    /// Opens a page to show comments for the purchase line.
    /// </summary>
    procedure ShowLineComments()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        TestField("Document No.");
        TestField("Line No.");
        PurchCommentLine.ShowComments("Document Type".AsInteger(), "Document No.", "Line No.");
    end;

    /// <summary>
    /// Resets quantities to receive/return and invoice to zero based on the purchase setup setting for default qty. to receive.
    /// </summary>
    procedure SetDefaultQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultQuantity(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then begin
            if (("Document Type" = "Document Type"::Order) and ("Over-Receipt Quantity" = 0)) or ("Document Type" = "Document Type"::Quote) then begin
                "Qty. to Receive" := 0;
                "Qty. to Receive (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Return Qty. to Ship" := 0;
                "Return Qty. to Ship (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
        end;

        OnAfterSetDefaultQuantity(Rec, xRec);
    end;

    local procedure SetDefaultGLAccountQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultGLAccountQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        GetPurchSetup();
        if PurchSetup."Default G/L Account Quantity" then
            Validate(Quantity, 1);
    end;

    local procedure QuantityDefaultedFromGLAccount(): Boolean
    begin
        if Rec.Type <> Rec.Type::"G/L Account" then
            exit(false);
        GetPurchSetup();
        exit(PurchSetup."Default G/L Account Quantity");
    end;

    /// <summary>
    /// Recalculates prepayment amounts to reflect changes in quantity.
    /// </summary>
    /// <remarks>
    /// If the document type in not an invoice or the prepayment percentage is 0, the prepayment amounts are not updated.
    /// </remarks>
    procedure UpdatePrePaymentAmounts()
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
        PurchOrderLine: Record "Purchase Line";
        PurchOrderHeader: Record "Purchase Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmounts(Rec, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if ("Document Type" <> "Document Type"::Invoice) or ("Prepayment %" = 0) then
            exit;

        if not ReceiptLine.Get("Receipt No.", "Receipt Line No.") then begin
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
        end else
            if PurchOrderLine.Get(PurchOrderLine."Document Type"::Order, ReceiptLine."Order No.", ReceiptLine."Order Line No.") then begin
                if ("Prepayment %" = 100) and (Quantity <> PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced") then
                    "Prepmt Amt to Deduct" := GetLineAmountToHandle(Quantity) - "Inv. Disc. Amount to Invoice"
                else
                    "Prepmt Amt to Deduct" :=
                      Round((PurchOrderLine."Prepmt. Amt. Inv." - PurchOrderLine."Prepmt Amt Deducted") *
                        Quantity / (PurchOrderLine.Quantity - PurchOrderLine."Quantity Invoiced"), Currency."Amount Rounding Precision");
                "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
                PurchOrderHeader.Get(PurchOrderHeader."Document Type"::Order, PurchOrderLine."Document No.");
            end else begin
                "Prepmt Amt to Deduct" := 0;
                "Prepmt VAT Diff. to Deduct" := 0;
            end;

        GetPurchHeader();
        PurchHeader.TestField("Prices Including VAT", PurchOrderHeader."Prices Including VAT");
        if PurchHeader."Prices Including VAT" then begin
            "Prepmt. Amt. Incl. VAT" := "Prepmt Amt to Deduct";
            "Prepayment Amount" :=
              Round(
                "Prepmt Amt to Deduct" / (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
        end else begin
            "Prepmt. Amt. Incl. VAT" :=
              Round(
                "Prepmt Amt to Deduct" * (1 + ("Prepayment VAT %" / 100)),
                Currency."Amount Rounding Precision");
            "Prepayment Amount" := "Prepmt Amt to Deduct";
        end;
        "Prepmt. Line Amount" := "Prepmt Amt to Deduct";
        "Prepmt. Amt. Inv." := "Prepmt. Line Amount";
        "Prepmt. VAT Base Amt." := "Prepayment Amount";
        "Prepmt. Amount Inv. Incl. VAT" := "Prepmt. Amt. Incl. VAT";
        "Prepmt Amt Deducted" := 0;

        OnAfterUpdatePrePaymentAmounts(Rec);
    end;

    local procedure SetUnitOfMeasure()
    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetUnitOfMeasure(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Unit of Measure Code" = '' then
            "Unit of Measure" := ''
        else begin
            UnitOfMeasure.Get("Unit of Measure Code");
            "Unit of Measure" := UnitOfMeasure.Description;
            GetPurchHeader();
            if PurchHeader."Language Code" <> '' then begin
                UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                UnitOfMeasureTranslation.SetRange("Language Code", PurchHeader."Language Code");
                if UnitOfMeasureTranslation.FindFirst() then
                    "Unit of Measure" := UnitOfMeasureTranslation.Description;
            end;
        end;
    end;

    /// <summary>
    /// Sets the vendor item number for the purchase line.
    /// </summary>
    procedure SetVendorItemNo()
    var
        Item: Record Item;
        ItemVend: Record "Item Vendor";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetVendorItemNo(Rec, IsHandled);
        if IsHandled then
            exit;

        GetItem(Item);
        ItemVend.Init();
        ItemVend."Vendor No." := "Buy-from Vendor No.";
        ItemVend."Variant Code" := "Variant Code";
        Item.FindItemVend(ItemVend, "Location Code");
        Validate("Vendor Item No.", ItemVend."Vendor Item No.");
        OnAfterSetVendorItemNo(Rec, ItemVend, Item);
    end;

    /// <summary>
    /// Determines if the line has a zero amount. It always returns true for a line with a blank type.
    /// </summary>
    /// <param name="QtyType">
    /// The type of quantity to check.
    /// Only Invoicing option makes a difference by checking if quantity to invoice is zero, other options are ignored.
    /// </param>
    /// <returns>True if the line has a zero amount, otherwise false.</returns>
    procedure ZeroAmountLine(QtyType: Option General,Invoicing,Shipping) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeZeroAmountLine(Rec, QtyType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Type = Type::" " then
            exit(true);
        if Quantity = 0 then
            exit(true);
        if "Direct Unit Cost" = 0 then
            exit(true);
        if QtyType = QtyType::Invoicing then
            if "Qty. to Invoice" = 0 then
                exit(true);
        exit(false);
    end;

    /// <summary>
    /// Sets filters on the purchase line for item lines, a specified document type, and various flow filters set in the provided item record.
    /// </summary>
    /// <param name="Item">Item record to filter the purchase lines with.</param>
    /// <param name="DocumentType">The document type to filter the purchase lines with.</param>
    procedure FilterLinesWithItemToPlan(var Item: Record Item; DocumentType: Enum "Purchase Document Type")
    begin
        Reset();
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, DocumentType.AsInteger());
    end;

    /// <summary>
    /// Retrieves a record set of item purchase lines that match the provided document type and various filters set on the item.
    /// </summary>
    /// <param name="Item">Item record to filter the purchase lines with.</param>
    /// <param name="DocumentType">The document type to filter the purchase lines with.</param>
    /// <returns>True if any purchase line was found, otherwise false.</returns>
    procedure FindLinesWithItemToPlan(var Item: Record Item; DocumentType: Enum "Purchase Document Type"): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(Find('-'));
    end;

    /// <summary>
    /// Determines if any purchase lines exist that match the provided document type and various flow filters set on the item.
    /// </summary>
    /// <param name="Item">Item record to filter the purchase lines with.</param>
    /// <param name="DocumentType">The document type to filter the purchase lines with.</param>
    /// <returns>True if any purchase lines exist, otherwise false.</returns>
    procedure LinesWithItemToPlanExist(var Item: Record Item; DocumentType: Enum "Purchase Document Type"): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Sets filters on the purchase line for item lines that match the provided reservation entry.
    /// </summary>
    /// <param name="ReservationEntry">Reservation entry to filter the purchase lines with.</param>
    /// <param name="DocumentType">The document type to filter the purchase lines with.</param>
    /// <param name="AvailabilityFilter">Date filter to apply to the expected receipt date field.</param>
    /// <param name="Positive">A flag to determine if the quantity (base) filter should be positive or negative.</param>
    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Enum "Purchase Document Type"; AvailabilityFilter: Text; Positive: Boolean)
    var
        IsHandled: Boolean;
    begin
        Reset();
        SetCurrentKey(
          "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        IsHandled := false;
        OnFilterLinesForReservationOnBeforeSetFilterVariantCode(Rec, ReservationEntry, Positive, IsHandled);
        if not IsHandled then
            SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Drop Shipment", false);
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Expected Receipt Date", AvailabilityFilter);
        if Positive and (DocumentType <> "Document Type"::"Return Order") then
            SetFilter("Quantity (Base)", '>0')
        else
            SetFilter("Quantity (Base)", '<0');
        SetRange("Job No.", ' ');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    /// <summary>
    /// Retrieves the invoice rounding account number from the vendor posting group associated with the purchase header.
    /// </summary>
    /// <param name="PurchHeader">Purchase header to filter from.</param>
    /// <returns>Invoice rounding account number from the vendor posting group.</returns>
    procedure GetVPGInvRoundAcc(var PurchHeader: Record "Purchase Header") AccountNo: Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVPGInvRoundAcc(PurchHeader, Vendor, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        GetPurchSetup();
        if PurchSetup."Invoice Rounding" then
            if Vendor.Get(PurchHeader."Pay-to Vendor No.") then
                VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        exit(VendorPostingGroup."Invoice Rounding Account");
    end;

    local procedure CheckReceiptRelation()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReceiptRelation(Rec, IsHandled);
        if IsHandled then
            exit;

        PurchRcptLine.Get("Receipt No.", "Receipt Line No.");
        if (Quantity * PurchRcptLine."Qty. Rcd. Not Invoiced") < 0 then
            FieldError("Qty. to Invoice", Text051);
        if Abs(Quantity) > Abs(PurchRcptLine."Qty. Rcd. Not Invoiced") then
            Error(Text052, PurchRcptLine."Document No.");

        OnAfterCheckReceiptRelation(Rec, PurchRcptLine);
    end;

    local procedure CheckRetShptRelation()
    var
        ReturnShptLine: Record "Return Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRetShptRelation(Rec, IsHandled);
        if IsHandled then
            exit;

        ReturnShptLine.Get("Return Shipment No.", "Return Shipment Line No.");
        if (Quantity * (ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced")) < 0 then
            FieldError("Qty. to Invoice", Text053);
        if Abs(Quantity) > Abs(ReturnShptLine.Quantity - ReturnShptLine."Quantity Invoiced") then
            Error(Text054, ReturnShptLine."Document No.");

        OnAfterCheckRetShptRelation(Rec, ReturnShptLine);
    end;

    local procedure VerifyItemLineDim()
    begin
        if IsReceivedShippedItemDimChanged() then
            ConfirmReceivedShippedItemDimChange();
    end;

    /// <summary>
    /// Determines if the dimensions have changed on an already received or shipped item line.
    /// </summary>
    /// <returns>True if the dimensions have changed, otherwise false.</returns>
    procedure IsReceivedShippedItemDimChanged(): Boolean
    begin
        exit(("Dimension Set ID" <> xRec."Dimension Set ID") and (Type = Type::Item) and
          (("Qty. Rcd. Not Invoiced" <> 0) or ("Return Qty. Shipped Not Invd." <> 0)));
    end;

    /// <summary>
    /// Checks if the purchase line is a service charge.
    /// </summary>
    /// <returns>True if the line is a service charge line, otherwise false.</returns>
    procedure IsServiceCharge(): Boolean
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if Type <> Type::"G/L Account" then
            exit(false);

        GetPurchHeader();
        VendorPostingGroup.Get(PurchHeader."Vendor Posting Group");
        exit(VendorPostingGroup."Service Charge Acc." = "No.");
    end;

    /// <summary>
    /// Raises a confirmation dialog to confirm the change of dimensions on an already received or shipped item line.
    /// </summary>
    /// <returns>True if the user confirms the change, otherwise an error is thrown.</returns>
    procedure ConfirmReceivedShippedItemDimChange() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmReceivedShippedItemDimChange(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text049, TableCaption), true) then
            Error(Text050);

        exit(true);
    end;

    /// <summary>
    /// Initializes the type of the purchase line.
    /// </summary>
    procedure InitType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitType(Rec, xRec, PurchHeader, IsHandled);
        if IsHandled then
            exit;

        if "Document No." <> '' then begin
            if not PurchHeader.Get("Document Type", "Document No.") then
                exit;
            if (PurchHeader.Status = PurchHeader.Status::Released) and
               (xRec.Type in [xRec.Type::Item, xRec.Type::"Fixed Asset"])
            then
                Type := Type::" "
            else
                Type := xRec.Type;
        end;

        OnAfterInitType(rec, xRec, PurchHeader);
    end;

    /// <summary>
    /// Returns the default document line type from the purchase setup if it is not blank.
    /// </summary>
    /// <returns>The document default line type from the purchase setup, otherwise blank.</returns>
    procedure GetDefaultLineType(): Enum "Purchase Line Type"
    begin
        GetPurchSetup();
        if PurchSetup."Document Default Line Type" <> PurchSetup."Document Default Line Type"::" " then
            exit(PurchSetup."Document Default Line Type");
    end;

    local procedure CheckWMS()
    begin
        if CurrFieldNo <> 0 then
            CheckLocationOnWMS();
        if "Document Type" = "Document Type"::"Return Order" then
            if ("Job No." <> '') and (Type = Type::Item) then
                if Location.Get("Location Code") then
                    EnsureDirectedPutawayandPickFalse(Location);
    end;

    local procedure EnsureDirectedPutawayandPickFalse(var Location: Record Location)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureDirectedPutawayandPickFalse(Rec, Location, IsHandled);
        if IsHandled then
            exit;

        Location.TestField("Directed Put-away and Pick", false);
    end;

    /// <summary>
    /// Checks if the line has receipt/shipment when it's mandatory by the location, but only performs this check
    /// if the item in the line is inventoriable.
    /// </summary>
    procedure CheckLocationOnWMS()
    var
        DialogText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLocationOnWMS(Rec, IsHandled);
        if IsHandled then
            exit;

        if (Type = Type::Item) and IsInventoriableItem() then begin
            DialogText := Text033;
            if "Quantity (Base)" <> 0 then
                case "Document Type" of
                    "Document Type"::Invoice:
                        if "Receipt No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Receive"));
                                Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                    "Document Type"::"Credit Memo":
                        if "Return Shipment No." = '' then
                            if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                DialogText += Location.GetRequirementText(Location.FieldNo("Require Shipment"));
                                Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                            end;
                end;
        end;
    end;

    /// <summary>
    /// Determines if the line is a non-inventoriable item line.
    /// </summary>
    /// <returns>True if the line is a non-inventoriable item line, otherwise false.</returns>
    procedure IsNonInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        Item.SetLoadFields(Type);
        GetItem(Item);
        exit(Item.IsNonInventoriableType());
    end;

    /// <summary>
    /// Determines if the line is an inventoriable item line.
    /// </summary>
    /// <returns>True if the line is an inventoriable item line, otherwise false.</returns>
    procedure IsInventoriableItem(): Boolean
    var
        Item: Record Item;
    begin
        if Type <> Type::Item then
            exit(false);
        if "No." = '' then
            exit(false);
        Item.SetLoadFields(Type);
        GetItem(Item);
        exit(Item.IsInventoriableType());
    end;

    /// <summary>
    /// Determines if the line is an extended text line.
    /// </summary>
    /// <returns>True if the line is an extended text line, otherwise false.</returns>
    procedure IsExtendedText(): Boolean
    begin
        exit((Type = Type::" ") and ("Attached to Line No." <> 0) and (Quantity = 0));
    end;

    procedure IsSubcontractingCreditMemo() Result: Boolean
    begin
        OnIsSubcontractingCreditMemo(Rec, Result);
    end;

    /// <summary>
    /// Retrieves the journal template name if g/l setup has a journal template name mandatory field set to true.
    /// </summary>
    /// <returns>Journal template name if g/l setup has a journal template name mandatory field set to true.</returns>
    procedure GetJnlTemplateName(): Code[10]
    begin
        GLSetup.Get();
        if not GLSetup."Journal Templ. Name Mandatory" then
            exit('');

        if "IC Partner Code" = '' then begin
            GetPurchHeader();
            exit(PurchHeader."Journal Templ. Name");
        end;

        GetPurchSetup();
        if IsCreditDocType() then begin
            PurchSetup.TestField("IC Purch. Cr. Memo Templ. Name");
            exit(PurchSetup."IC Purch. Cr. Memo Templ. Name");
        end;
        PurchSetup.TestField("IC Purch. Invoice Templ. Name");
        exit(PurchSetup."IC Purch. Invoice Templ. Name");
    end;

    local procedure CheckReservationForJobNo(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        SetReservationFilters(ReservEntry);
        ReservEntry.SetRange(
          "Reservation Status", ReservEntry."Reservation Status"::Reservation, ReservEntry."Reservation Status"::Tracking);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure ValidateReturnReasonCode(CallingFieldNo: Integer)
    var
        ReturnReason: Record "Return Reason";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateReturnReasonCode(Rec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;

        if CallingFieldNo = 0 then
            exit;
        if "Return Reason Code" = '' then
            PlanPriceCalcByField(CallingFieldNo);

        if ReturnReason.Get("Return Reason Code") then begin
            if (CallingFieldNo <> FieldNo("Location Code")) and (ReturnReason."Default Location Code" <> '') then
                Validate("Location Code", ReturnReason."Default Location Code");
            if ReturnReason."Inventory Value Zero" then
                Validate("Direct Unit Cost", 0)
            else
                PlanPriceCalcByField(CallingFieldNo);
        end;
        UpdateDirectUnitCostByField(CallingFieldNo);
    end;

    /// <summary>
    /// Updates the line discount percentage for the purchase line.
    /// Additionally, updates line, vat, prepayment and deferral amounts, initializes outstanding amounts and updates the unit cost.
    /// </summary>
    /// <param name="DropInvoiceDiscountAmount">If true, invoice discount amounts will be set to 0.</param>
    procedure ValidateLineDiscountPercent(DropInvoiceDiscountAmount: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateLineDiscountPercent(Rec, DropInvoiceDiscountAmount, IsHandled);
        if IsHandled then
            exit;

        TestStatusOpen();
        IsHandled := false;
        OnValidateLineDiscountPercentOnAfterTestStatusOpen(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetPurchHeader();
        "Line Discount Amount" :=
          Round(
            Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") *
            "Line Discount %" / 100,
            Currency."Amount Rounding Precision");
        if DropInvoiceDiscountAmount then begin
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
        end;
        OnValidateLineDiscountPercentOnBeforeUpdateAmounts(Rec);
        UpdateAmounts();
        UpdateUnitCost();
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        GetPurchSetup();
        DiscountNotificationMgt.RecallNotification(PurchSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          PurchSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          PurchSetup."Discount Posting", PurchSetup."Discount Posting"::"Invoice Discounts");
    end;

    local procedure UpdateDimensionsFromJobTask()
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimSetArrID: array[10] of Integer;
        DimValue1: Code[20];
        DimValue2: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDimensionsFromJobTask(Rec, CurrFieldNo, IsHandled);
        if not IsHandled then begin
            SourceCodeSetup.Get();
            DimSetArrID[1] := "Dimension Set ID";
            DimSetArrID[2] :=
                DimMgt.CreateDimSetFromJobTaskDim("Job No.",
                "Job Task No.", DimValue1, DimValue2);
            DimMgt.CreateDimForPurchLineWithHigherPriorities(
                Rec, CurrFieldNo, DimSetArrID[3], DimValue1, DimValue2, SourceCodeSetup.Purchases, Database::Job);

            "Dimension Set ID" :=
                DimMgt.GetCombinedDimensionSetID(
                DimSetArrID, DimValue1, DimValue2);

            "Shortcut Dimension 1 Code" := DimValue1;
            "Shortcut Dimension 2 Code" := DimValue2;
        end;
        OnAfterUpdateDimensionsFromJobTask(Rec);
    end;

    local procedure UpdateItemReference()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemReference(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        ItemReferenceMgt.EnterPurchaseItemReference(Rec);

        UpdateICPartner();

        if Type <> Type::Item then
            exit;

        UpdateVendorItemNoFromItemReference();
    end;

    local procedure UpdateVendorItemNoFromItemReference()
    begin
        if "Item Reference No." = '' then
            SetVendorItemNo()
        else
            Validate("Vendor Item No.", "Item Reference No.");
        OnAfterUpdateVendorItemNoFromItemReference(Rec, xRec);
    end;

    /// <summary>
    /// Updates the intercompany partner information on the purchase line if the purchase header has outgoing intercompany direction.
    /// </summary>
    procedure UpdateICPartner()
    var
        ICPartner: Record "IC Partner";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateICPartner(Rec, GLAcc, PurchHeader, IsHandled);
        if not IsHandled then
            if PurchHeader."Send IC Document" and (PurchHeader."IC Direction" = PurchHeader."IC Direction"::Outgoing) then
                case Type of
                    Type::" ", Type::"Charge (Item)":
                        begin
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := "No.";
                        end;
                    Type::"G/L Account":
                        begin
                            "IC Partner Ref. Type" := Type;
                            "IC Partner Reference" := GLAcc."Default IC Partner G/L Acc. No";
                        end;
                    Type::Item:
                        begin
                            ICPartner.Get(PurchHeader."Buy-from IC Partner Code");
                            case ICPartner."Outbound Purch. Item No. Type" of
                                ICPartner."Outbound Purch. Item No. Type"::"Common Item No.":
                                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Common Item No.");
                                ICPartner."Outbound Purch. Item No. Type"::"Internal No.":
                                    begin
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::Item);
                                        "IC Partner Reference" := "No.";
                                    end;
                                ICPartner."Outbound Purch. Item No. Type"::"Cross Reference":
                                    begin
                                        Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"Cross Reference");
                                        UpdateICPartnerItemReference();
                                    end;
                                ICPartner."Outbound Purch. Item No. Type"::"Vendor Item No.":
                                    begin
                                        "IC Partner Ref. Type" := "IC Partner Ref. Type"::"Vendor Item No.";
                                        "IC Item Reference No." := "Vendor Item No.";
                                    end;
                            end;
                        end;
                    Type::"Fixed Asset":
                        begin
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                            "IC Partner Reference" := '';
                        end;
                end;

        OnAfterUpdateICPartner(Rec, PurchHeader);
    end;

    local procedure UpdateICPartnerItemReference()
    var
        ItemReference: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference.SetRange("Reference Type", "Item Reference Type"::Vendor);
        ItemReference.SetRange("Reference Type No.", "Buy-from Vendor No.");
        ItemReference.SetRange("Item No.", "No.");
        ItemReference.SetRange("Variant Code", "Variant Code");
        ItemReference.SetRange("Unit of Measure", "Unit of Measure Code");
        ToDate := Rec.GetDateForCalculations();
        if ToDate <> 0D then begin
            ItemReference.SetFilter("Starting Date", '<=%1', ToDate);
            ItemReference.SetFilter("Ending Date", '>=%1|%2', ToDate, 0D);
        end;
        if ItemReference.FindFirst() then
            "IC Item Reference No." := ItemReference."Reference No."
        else
            "IC Partner Reference" := "No.";
    end;

    local procedure CalcTotalAmtToAssign(TotalQtyToAssign: Decimal) TotalAmtToAssign: Decimal
    begin
        TotalAmtToAssign := CalcLineAmount() * TotalQtyToAssign / Quantity;

        if PurchHeader."Prices Including VAT" then
            TotalAmtToAssign := TotalAmtToAssign / (1 + "VAT %" / 100) - "VAT Difference";

        TotalAmtToAssign := Round(TotalAmtToAssign, Currency."Amount Rounding Precision");

        OnAfterCalcTotalAmtToAssign(Rec, PurchHeader, Currency, TotalQtyToAssign, TotalAmtToAssign);
    end;

    /// <summary>
    /// Checks if the current purchase line record has a type that requires mandatory fields to be filled.
    /// </summary>
    /// <remarks>
    /// By default, only the blank type will return false, but this behavior can be altered by an event subscriber.
    /// </remarks>
    /// <returns>True if purchase line has a type that requires mandatory fields to be filled, otherwise false.</returns>
    procedure HasTypeToFillMandatoryFields() ReturnValue: Boolean
    begin
        ReturnValue := Type <> Type::" ";

        OnAfterHasTypeToFillMandatoryFields(Rec, ReturnValue);
    end;

    /// <summary>
    /// Gets the defferal amount for the purchase line to be used in deferral schedules.
    /// </summary>
    /// <returns>The deferral amount.</returns>
    procedure GetDeferralAmount() DeferralAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralAmount(Rec, DeferralAmount, IsHandled);
        if IsHandled then
            exit;

        if "VAT Base Amount" <> 0 then
            DeferralAmount := "VAT Base Amount"
        else
            DeferralAmount := CalcLineAmount();

        OnAfterGetDeferralAmount(Rec, DeferralAmount);
    end;

    local procedure GetDeferralPostDate(PurchaseHeader: Record "Purchase Header") DeferralPostDate: Date
    begin
        DeferralPostDate := PurchaseHeader."Posting Date";
        OnAfterGetDeferralPostDate(Rec, PurchaseHeader, DeferralPostDate);
    end;

    /// <summary>
    /// Removes or updates the deferral schedule for the purchase line.
    /// </summary>
    procedure UpdateDeferralAmounts()
    var
        DeferralPostDate: Date;
        AdjustStartDate: Boolean;
    begin
        GetPurchHeader();
        OnUpdateDeferralAmountsOnBeforeSetDeferralPostDate(PurchHeader, Rec, DeferralPostDate);
        if DeferralPostDate = 0D then
            DeferralPostDate := PurchHeader."Posting Date";
        AdjustStartDate := true;
        if "Document Type" = "Document Type"::"Return Order" then begin
            if "Returns Deferral Start Date" = 0D then
                "Returns Deferral Start Date" := PurchHeader."Posting Date";
            DeferralPostDate := "Returns Deferral Start Date";
            AdjustStartDate := false;
        end;

        DeferralUtilities.RemoveOrSetDeferralSchedule(
            "Deferral Code", Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
            "Document Type".AsInteger(), "Document No.", "Line No.",
            GetDeferralAmount(), DeferralPostDate, Description, PurchHeader."Currency Code", AdjustStartDate);
    end;

    /// <summary>
    /// Opens a page with deferral schedule for the purchase line.
    /// </summary>
    /// <remarks>
    /// If the deferral schedule doesn't exist yet, a new one is created and commited before the page is opened.
    /// </remarks>
    /// <param name="PostingDate">Posting date which is used as a start date on the deferral schedule if it needs to be created.</param>
    /// <param name="CurrencyCode">Currency code to use for a new deferral schedule.</param>
    /// <returns>True if deferral schedule was changed, otherwise false.</returns>
    procedure ShowDeferrals(PostingDate: Date; CurrencyCode: Code[10]): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(
            DeferralUtilities.OpenLineScheduleEdit(
                "Deferral Code", Enum::"Deferral Document Type"::Purchase.AsInteger(), '', '',
                "Document Type".AsInteger(), "Document No.", "Line No.",
                GetDeferralAmount(), PostingDate, Description, CurrencyCode));
    end;

    /// <summary>
    /// Initializes the deferral code for the purchase line based on its type.
    /// </summary>
    procedure InitDeferralCode()
    var
        Item: Record Item;
        Resource: Record Resource;
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitDeferralCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" in
           ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::"Credit Memo", "Document Type"::"Return Order"]
        then
            case Type of
                Type::"G/L Account":
                    begin
                        GLAccount.Get("No.");
                        Validate("Deferral Code", GLAccount."Default Deferral Template Code");
                    end;
                Type::Item:
                    begin
                        GetItem(Item);
                        Validate("Deferral Code", Item."Default Deferral Template Code");
                    end;
                Type::Resource:
                    begin
                        GetResource(Resource);
                        Validate("Deferral Code", Resource."Default Deferral Template Code");
                    end;
            end;
    end;

    /// <summary>
    /// Initializes the deferral code for the purchase if the type is g/l account, item or resource.
    /// </summary>
    procedure DefaultDeferralCode()
    begin
        if Type in [Type::"G/L Account", Type::Item, Type::Resource] then
            InitDeferralCode();
    end;

    /// <summary>
    /// Determines if the document type is a credit document.
    /// </summary>
    /// <returns>True if the document type is return order or credit memo, otherwise false.</returns>
    procedure IsCreditDocType() Result: Boolean
    begin
        Result := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnAfterIsCreditDocType(Rec, Result);
    end;

    /// <summary>
    /// Determines if the document type of the line is order or invoice.
    /// </summary>
    /// <returns>True if the document type is order or invoice, otherwise false.</returns>
    procedure IsInvoiceDocType(): Boolean
    begin
        exit("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]);
    end;

    /// <summary>
    /// Determines if incoming document came from OCR.
    /// </summary>
    /// <remarks>
    /// If there's no incoming document associated with the purchase document, the procedure returns false.
    /// </remarks>
    /// <returns>True, if incoming document has ocr status success, otherwise false.</returns>
    procedure IsReceivedFromOcr(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        GetPurchHeader();
        if not IncomingDocument.Get(PurchHeader."Incoming Document Entry No.") then
            exit(false);
        exit(IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success);
    end;

    local procedure TestReturnFieldsZero()
    begin
        TestField("Return Qty. Shipped Not Invd.", 0);
        TestField("Return Qty. Shipped", 0);
        TestField("Return Shipment No.", '');
    end;

    /// <summary>
    /// Checks if item unit of measure code can be edited.
    /// </summary>
    /// <remarks>
    /// If this is not an item line or if item is not selected the procedure always returns true.
    /// </remarks>
    /// <returns>True if item unit of measure code can be edited, otherwise false.</returns>
    procedure CanEditUnitOfMeasureCode(): Boolean
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if (Type = Type::Item) and ("No." <> '') then begin
            ItemUnitOfMeasure.SetRange("Item No.", "No.");
            exit(ItemUnitOfMeasure.Count > 1);
        end;
        exit(true);
    end;

    /// <summary>
    /// Verifies that the pruchase line is an item line and the fields match the provided values.
    /// If the values do not match, an error is thrown.
    /// </summary>
    /// <param name="ItemNo">The item number to match.</param>
    /// <param name="VariantCode">The variant code to match.</param>
    /// <param name="LocationCode">The location code to match.</param>
    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    /// <summary>
    /// Clears global PurchHeader variable.
    /// </summary>
    procedure ClearPurchaseHeader()
    begin
        Clear(PurchHeader);
    end;

    local procedure GetBlockedItemNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8EC');
    end;

    local procedure SendBlockedItemNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedItemNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := StrSubstNo(BlockedItemNotificationMsg, "No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
    end;

    local procedure GetBlockedItemVariantNotificationID(): Guid
    begin
        exit('1113AAF8-EC5B-4F80-BB38-09A770130E59');
    end;

    local procedure SendBlockedItemVariantNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        NotificationToSend.Id := GetBlockedItemVariantNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := StrSubstNo(BlockedItemVariantNotificationMsg, Rec."Variant Code", Rec."No.");
        NotificationLifecycleMgt.SendNotification(NotificationToSend, Rec.RecordId());
    end;

    /// <summary>
    /// Sends a notification when the invoice discount amount for the purchase line record has been reset.
    /// </summary>
    procedure SendLineInvoiceDiscountResetNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendLineInvoiceDiscountResetNotification(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Inv. Discount Amount" = 0) and (xRec."Inv. Discount Amount" <> 0) and ("Line Amount" <> 0) then begin
            NotificationToSend.Id := PurchHeader.GetLineInvoiceDiscountResetNotificationId();
            NotificationToSend.Message := StrSubstNo(LineInvoiceDiscountAmountResetTok, RecordId);

            NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
        end;
    end;

    /// <summary>
    /// Gets the formated text of the line type for the purchase line.
    /// </summary>
    /// <remarks>
    /// If line type is blank, comment label is returned.
    /// </remarks>
    /// <returns>Formated text of the line type.</returns>
    procedure FormatType() FormattedType: Text[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatType(Rec, FormattedType, IsHandled);
        if IsHandled then
            exit(FormattedType);

        if Type = Type::" " then
            exit(CommentLbl);

        exit(Format(Type));
    end;

    /// <summary>
    /// Renames the number of all purchase lines corresponding to the specified line type and number.
    /// </summary>
    /// <remarks>
    /// Used when related entities are renamed.
    /// </remarks>
    /// <param name="LineType">Filter lines based on this line type.</param>
    /// <param name="OldNo">The old number to rename from.</param>
    /// <param name="NewNo">The new number to rename to.</param>
    procedure RenameNo(LineType: Enum "Purchase Document Type"; OldNo: Code[20]; NewNo: Code[20])
    begin
        Reset();
        SetRange(Type, LineType);
        SetRange("No.", OldNo);
        if not Rec.IsEmpty() then
            ModifyAll("No.", NewNo, true);
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, Currency, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") <> 0 then begin
            LineDiscountPct := Round(
                "Line Discount Amount" / Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") * 100,
                0.00001);
            if not (LineDiscountPct in [0 .. 100]) then
                Error(LineDiscountPctErr);
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;

        OnAfterUpdateLineDiscPct(Rec);
    end;

    /// <summary>
    /// Updates the base amounts for the purchase line.
    /// </summary>
    /// <param name="NewAmount">Value to which amount will be updated.</param>
    /// <param name="NewAmountIncludingVAT">Value to which amount including VAT will be uptaded.</param>
    /// <param name="NewVATBaseAmount">Value to which VAT base amount will be uptaded.</param>
    procedure UpdateBaseAmounts(NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
        Amount := NewAmount;
        "Amount Including VAT" := NewAmountIncludingVAT;
        "VAT Base Amount" := NewVATBaseAmount;

        OnAfterUpdateBaseAmounts(Rec, xRec, CurrFieldNo, NewAmount, NewAmountIncludingVAT, NewVATBaseAmount);
    end;

    /// <summary>
    /// Updates the prepayment amounts for the purchase line.
    /// </summary>
    procedure UpdatePrepmtAmounts()
    var
        OutstandingAmountExclTax: Decimal;
    begin
        if (Rec.Quantity <> 0) and (Rec."Outstanding Quantity" = 0) and (Rec."Qty. Rcd. Not Invoiced" = 0) then
            if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then
                exit;

        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then begin
            OutstandingAmountExclTax := CalculateOutstandingAmountExclTax();
            "Prepayment VAT Difference" := 0;
            if not PrePaymentLineAmountEntered then begin
                "Prepmt. Line Amount" := Round((OutstandingAmountExclTax) * "Prepayment %" / 100, Currency."Amount Rounding Precision");
                "Prepmt. Line Amount" := "Prepmt. Line Amount" + "Prepmt Amt Deducted";
            end;
            PrePaymentLineAmountEntered := false;
        end;

        if not IsTemporary() then
            CheckPrepmtAmounts();
    end;

    local procedure CalculateOutstandingAmountExclTax(): Decimal
    var
        OutstandingAmount: Decimal;
        QuantityNotInvoiced: Decimal;
    begin
        if Rec.Quantity = 0 then
            exit(0);
        QuantityNotInvoiced := (Rec.Quantity - Rec."Quantity Invoiced");
        OutstandingAmount := round(((Rec."Line Amount" - Rec."Inv. Discount Amount") * QuantityNotInvoiced) / Rec.Quantity, Currency."Amount Rounding Precision");
        exit(OutstandingAmount);
    end;

    local procedure CheckPrepmtAmounts()
    var
        RemLineAmountToInvoice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtAmounts(Rec, PurchHeader, CurrFieldNo, IsHandled, xRec);
        if IsHandled then
            exit;

        if "Prepayment %" <> 0 then begin
            if "System-Created Entry" then
                if Type = Type::"G/L Account" then
                    if not IsServiceCharge() then
                        exit;
            if Quantity < 0 then
                FieldError(Quantity, StrSubstNo(Text043, FieldCaption("Prepayment %")));
            if "Direct Unit Cost" < 0 then
                FieldError("Direct Unit Cost", StrSubstNo(Text043, FieldCaption("Prepayment %")));
        end;
        if PurchHeader."Document Type" <> PurchHeader."Document Type"::Invoice then begin
            if (("Prepmt. Line Amount" + Currency."Amount Rounding Precision") < "Prepmt. Amt. Inv.") and (PurchHeader.Status <> PurchHeader.Status::Released) then begin
                if IsServiceCharge() then
                    Error(CannotChangePrepaidServiceChargeErr);
                if "Inv. Discount Amount" <> 0 then
                    Error(InvDiscForPrepmtExceededErr, "Document No.");
                FieldError("Prepmt. Line Amount", StrSubstNo(Text037, "Prepmt. Amt. Inv."));
            end;
            if "Prepmt. Line Amount" <> 0 then begin
                RemLineAmountToInvoice :=
                  Round("Line Amount" * (Quantity - "Quantity Invoiced") / Quantity, Currency."Amount Rounding Precision");
                if RemLineAmountToInvoice < ("Prepmt Amt to Deduct" - "Prepmt Amt Deducted") then
                    FieldError("Prepmt Amt to Deduct", StrSubstNo(Text039, RemLineAmountToInvoice + "Prepmt Amt Deducted"));
            end;
        end else
            if (CurrFieldNo <> 0) and ("Line Amount" <> xRec."Line Amount") and
               ("Prepmt. Amt. Inv." <> 0) and ("Prepayment %" = 100)
            then begin
                if "Line Amount" < xRec."Line Amount" then
                    FieldError("Line Amount", StrSubstNo(Text038, xRec."Line Amount"));
                FieldError("Line Amount", StrSubstNo(Text039, xRec."Line Amount"));
            end;
    end;

    local procedure CheckPrepmtAmtInvEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtAmtInvEmpty(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if ("Prepmt. Amt. Inv." <> 0) and (Rec."VAT Prod. Posting Group" <> xRec."VAT Prod. Posting Group") then
            Error(CannotChangeVATGroupWithPrepmInvErr);
    end;

    local procedure IsCalcVATAmountLinesHandled(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping) IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, IsHandled, QtyType);
        exit(IsHandled);
    end;

    local procedure OverReceiptProcessing() Result: Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOverReceiptProcessing(Rec, xRec, CurrFieldNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not OverReceiptMgt.IsOverReceiptAllowed() or (Abs("Qty. to Receive") <= Abs("Outstanding Quantity")) then
            exit(false);

        if (Rec."Over-Receipt Code" = '') and (OverReceiptMgt.GetDefaultOverReceiptCode(Rec) = '') then
            exit(false);

        Validate("Over-Receipt Quantity", "Qty. to Receive" - Quantity + "Quantity Received" + "Over-Receipt Quantity");
        exit(true);
    end;

    /// <summary>
    /// Returns resource record from the resource number on the purchase line.
    /// </summary>
    /// <returns>Resource record.</returns>
    procedure GetResource(): Record Resource
    var
        Resource: Record Resource;
    begin
        TestField("No.");
        Resource.Get("No.");
        exit(Resource);
    end;

    local procedure GetResource(var Resource: Record Resource)
    begin
        TestField("No.");
        Resource.Get("No.")
    end;

    local procedure CopyFromResource()
    var
        Resource: Record Resource;
    begin
        GetResource(Resource);
        Resource.CheckResourcePrivacyBlocked(false);
        Resource.TestField(Blocked, false);
        Resource.TestField("Gen. Prod. Posting Group");
        Description := Resource.Name;
        "Description 2" := Resource."Name 2";
        "Unit of Measure Code" := Resource."Base Unit of Measure";
        "Gen. Prod. Posting Group" := Resource."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";
        "Tax Group Code" := Resource."Tax Group Code";
        "Allow Item Charge Assignment" := false;
        "Direct Unit Cost" := Resource."Direct Unit Cost";
        InitDeferralCode();

        OnAfterAssignResourceValues(Rec, Resource);
    end;

    local procedure CheckBuyFromVendorNo(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBuyFromVendorNo(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote then
            CheckQuoteVendorTemplateCode(PurchaseHeader)
        else
            PurchaseHeader.TestField("Buy-from Vendor No.");
    end;

    local procedure UpdateLineAmount(var LineAmountChanged: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineAmount(Rec, xRec, Currency, LineAmountChanged, IsHandled);
        if IsHandled then
            exit;

        if Rec."Line Amount" <> xRec."Line Amount" then begin
            ClearVATDifference();
            NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
            LineAmountChanged := true;
        end;
        if "Line Amount" <> Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") - "Line Discount Amount" then begin
            "Line Amount" :=
              Round(Quantity * "Direct Unit Cost", Currency."Amount Rounding Precision") - "Line Discount Amount";
            ClearVATDifference();
            NonDeductibleVAT.InitNonDeductibleVATDiff(Rec);
            LineAmountChanged := true;
        end;
        OnAfterUpdateLineAmount(Rec, xRec, Currency, LineAmountChanged);
    end;

    local procedure CheckLocationRequireReceive();
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLocationRequireReceive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if (CurrFieldNo <> 0) and IsInventoriableItem() and (not "Drop Shipment") then begin
            if Location."Require Receive" then
                CheckWarehouse(true);
            IsHandled := false;
            OnCheckLocationRequireReceiveOnBeforePurchaseLineVerifyChange(Rec, xRec, IsHandled);
            if not IsHandled then
                PurchasesWarehouseMgt.PurchaseLineVerifyChange(Rec, xRec);
        end;
    end;

    local procedure CheckDirectUnitCost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDirectUnitCost(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Direct Unit Cost");
    end;

    /// <summary>
    /// Open a page with the purchase lines related to the blanket order line.
    /// </summary>
    /// <param name="DocumentType">The document type of the purchase lines to show.</param>
    procedure ShowBlanketOrderPurchaseLines(DocumentType: Enum "Purchase Document Type")
    var
        RelatedPurchLine: Record "Purchase Line";
    begin
        RelatedPurchLine.Reset();
        RelatedPurchLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
        RelatedPurchLine.SetRange("Document Type", DocumentType);
        RelatedPurchLine.SetRange("Blanket Order No.", Rec."Document No.");
        RelatedPurchLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Purchase Lines", RelatedPurchLine);
    end;

    /// <summary>
    /// Open a page with the posted purchase receipt lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedReceiptLines()
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.Reset();
        PurchRcptLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        PurchRcptLine.SetRange("Blanket Order No.", Rec."Document No.");
        PurchRcptLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Purchase Receipt Lines", PurchRcptLine);
    end;

    /// <summary>
    /// Open a page with the posted purchase invoice lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedInvoiceLines()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        PurchInvLine.SetRange("Blanket Order No.", Rec."Document No.");
        PurchInvLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Purchase Invoice Lines", PurchInvLine);
    end;

    /// <summary>
    /// Open a page with the posted return shipment lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedReturnReceiptLines()
    var
        ReturnShptLine: Record "Return Shipment Line";
    begin
        ReturnShptLine.Reset();
        ReturnShptLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        ReturnShptLine.SetRange("Blanket Order No.", Rec."Document No.");
        ReturnShptLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Return Shipment Lines", ReturnShptLine);
    end;

    /// <summary>
    /// Open a page with the posted purchase credit memo lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedCreditMemoLines()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.Reset();
        PurchCrMemoLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        PurchCrMemoLine.SetRange("Blanket Order No.", Rec."Document No.");
        PurchCrMemoLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Purchase Cr. Memo Lines", PurchCrMemoLine);
    end;

    local procedure TestFieldQuantity(CurrentFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldQuantity(Rec, CurrentFieldNo, IsHandled);
        if not IsHandled then
            TestField(Quantity);
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure CalcBaseQtyForJobPlanningLine(Qty: Decimal; FromFieldName: Text; ToFieldName: Text; JobPlanningLine: Record "Job Planning Line"): Decimal
    begin
        exit(UOMMgt.CalcBaseQty(
            JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code", Qty, JobPlanningLine."Qty. per Unit of Measure", JobPlanningLine."Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    /// <summary>
    /// Initializes the dimensions for the purchase line if default dimensions are defined for the related entry.
    /// </summary>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        IsHandled: Boolean;
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);

        IsHandled := false;
        OnCreateDimFromDefaultDimOnBeforeCreateDim(Rec, DefaultDimSource, FieldNo, IsHandled);
        if not IsHandled then
            if DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
                CreateDim(DefaultDimSource);

        OnAfterCreateDimFromDefaultDim(Rec, DefaultDimSource, FieldNo);
    end;

    /// <summary>
    /// Returns a dictionary mapping table IDs to field values for the purchase line for a specified field no.
    /// </summary>
    /// <param name="FieldNo">Field number to map.</param>
    /// <returns>Dictionary which has mapped provided field value with its corresponding table id.</returns>
    procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitTableValuePair(TableValuePair, FieldNo, IsHandled, Rec);
        if IsHandled then
            exit;

        case true of
            FieldNo = Rec.FieldNo("No."):
                TableValuePair.Add(DimMgt.PurchLineTypeToTableID(Type), Rec."No.");
            FieldNo = Rec.FieldNo("Responsibility Center"):
                TableValuePair.Add(Database::"Responsibility Center", Rec."Responsibility Center");
            FieldNo = Rec.FieldNo("Job No."):
                TableValuePair.Add(Database::Job, Rec."Job No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;
        OnAfterInitTableValuePair(TableValuePair, FieldNo, Rec);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.PurchLineTypeToTableID(Rec.Type), Rec."No.", FieldNo = Rec.FieldNo("No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    /// <summary>
    /// Saves the selected record from the lookup to the lookup state manager.
    /// </summary>
    /// <param name="SelectedRecordRef">The reference to the selected record from the lookup.</param>
    procedure SaveLookupSelection(SelectedRecordRef: RecordRef)
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        FixedAsset: Record "Fixed Asset";
        AllocationAccount: Record "Allocation Account";
        ItemCharge2: Record "Item Charge";
        LookupStateManager: Codeunit "Lookup State Manager";
        NewNo: Code[20];
        RecVariant: Variant;
    begin
        case Rec.Type of
            Rec.Type::Item:
                begin
                    SelectedRecordRef.SetTable(Item);
                    RecVariant := Item;
                    NewNo := Item."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
            Rec.Type::"G/L Account":
                begin
                    SelectedRecordRef.SetTable(GLAccount);
                    RecVariant := GLAccount;
                    NewNo := GLAccount."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
            Rec.Type::Resource:
                begin
                    SelectedRecordRef.SetTable(Resource);
                    RecVariant := Resource;
                    NewNo := Resource."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
            Rec.Type::"Fixed Asset":
                begin
                    SelectedRecordRef.SetTable(FixedAsset);
                    RecVariant := FixedAsset;
                    NewNo := FixedAsset."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
            Rec.Type::"Charge (Item)":
                begin
                    SelectedRecordRef.SetTable(ItemCharge2);
                    RecVariant := ItemCharge2;
                    NewNo := ItemCharge2."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
            Rec.Type::"Allocation Account":
                begin
                    SelectedRecordRef.SetTable(AllocationAccount);
                    RecVariant := AllocationAccount;
                    NewNo := AllocationAccount."No.";
                    LookupStateManager.SaveRecord(RecVariant);
                end;
        end;
        if (Rec."No." = '') and (NewNo <> '') then
            Rec.Validate("No.", NewNo);
    end;

    procedure AttachToInventoryItemLine(var SelectedPurchLine: Record "Purchase Line")
    var
        InvtItemPurchLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAttachToInventoryItemLine(SelectedPurchLine, IsHandled);
        if IsHandled then
            exit;

        SelectedPurchLine.SetFilter(Type, '>%1', SelectedPurchLine.Type::" ");
        SelectedPurchLine.SetFilter(Quantity, '<>0');
        if not SelectedPurchLine.FindSet() then
            exit;

        InvtItemPurchLine.SetRange("Document Type", SelectedPurchLine."Document Type");
        InvtItemPurchLine.SetRange("Document No.", SelectedPurchLine."Document No.");
        InvtItemPurchLine.SetRange(Type, SelectedPurchLine.Type::Item);
        InvtItemPurchLine.SetRange("Attached to Line No.", 0);
        if InvtItemPurchLine.FindSet() then
            repeat
                if InvtItemPurchLine.IsInventoriableItem() then begin
                    TempPurchaseLine := InvtItemPurchLine;
                    TempPurchaseLine.Insert();
                end;
            until InvtItemPurchLine.Next() = 0;

        if PAGE.RunModal(PAGE::"Purchase Lines", TempPurchaseLine) = ACTION::LookupOK then
            if TempPurchaseLine."Line No." <> 0 then
                repeat
                    if not SelectedPurchLine.IsInventoriableItem() then begin
                        SelectedPurchLine."Attached to Line No." := TempPurchaseLine."Line No.";
                        SelectedPurchLine.Modify();
                    end;
                until SelectedPurchLine.Next() = 0;
    end;

    /// <summary>
    /// Restores the selected record from the lookup state manager to the purchase line.
    /// </summary>
    procedure RestoreLookupSelection()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        FixedAsset: Record "Fixed Asset";
        ItemCharge2: Record "Item Charge";
        LookupStateManager: Codeunit "Lookup State Manager";
        RecRef: RecordRef;
        RecVariant: Variant;
    begin
        if LookupStateManager.IsRecordSaved() then begin
            case Rec.Type of
                Rec.Type::Item:
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        RecRef.GetTable(RecVariant);
                        if RecRef.Number = Database::Item then begin
                            Item := RecVariant;
                            Rec.Validate("No.", Item."No.");
                        end;
                    end;
                Rec.Type::"G/L Account":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        RecRef.GetTable(RecVariant);
                        if RecRef.Number = Database::"G/L Account" then begin
                            GLAccount := RecVariant;
                            Rec.Validate("No.", GLAccount."No.");
                        end;
                    end;
                Rec.Type::Resource:
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        RecRef.GetTable(RecVariant);
                        if RecRef.Number = Database::Resource then begin
                            Resource := RecVariant;
                            Rec.Validate("No.", Resource."No.");
                        end;
                    end;
                Rec.Type::"Fixed Asset":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        RecRef.GetTable(RecVariant);
                        if RecRef.Number = Database::"Fixed Asset" then begin
                            FixedAsset := RecVariant;
                            Rec.Validate("No.", FixedAsset."No.");
                        end;
                    end;
                Rec.Type::"Charge (Item)":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        RecRef.GetTable(RecVariant);
                        if RecRef.Number = Database::"Item Charge" then begin
                            ItemCharge2 := RecVariant;
                            Rec.Validate("No.", ItemCharge2."No.");
                        end;
                    end;
            end;
            LookupStateManager.ClearSavedRecord();
        end;
    end;

    /// <summary>
    /// Gets the date required for purchase line calculations.
    /// </summary>
    /// <returns>The date for calculations.</returns>
    procedure GetDateForCalculations() CalculationDate: Date;
    var
        FromPurchaseHeader: Record "Purchase Header";
    begin
        if Rec."Document No." <> '' then
            FromPurchaseHeader := Rec.GetPurchHeader();
        CalculationDate := GetDateForCalculations(FromPurchaseHeader);
    end;

    /// <summary>
    /// Gets the date required for purchase line calculations.
    /// </summary>
    /// <param name="FromPurchaseHeader">The purchase header to get the date from.</param>
    /// <returns>The date for calculations.</returns>
    procedure GetDateForCalculations(FromPurchaseHeader: Record "Purchase Header") CalculationDate: Date;
    begin
        if FromPurchaseHeader."Document Type" in [FromPurchaseHeader."Document Type"::Invoice, FromPurchaseHeader."Document Type"::"Credit Memo"] then
            CalculationDate := FromPurchaseHeader."Posting Date"
        else
            CalculationDate := FromPurchaseHeader."Order Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    local procedure SetLoadFieldsForInvDiscoundCalculation(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetLoadFields(
            "Document Type", "Document No.", Type, "No.", "Receipt No.", "Return Shipment No.", "Deferral Code",
            Quantity, "Quantity (Base)", "Qty. to Invoice", "Qty. to Invoice (Base)", "Qty. Rcd. Not Invoiced", "Qty. Rcd. Not Invoiced (Base)", "Ret. Qty. Shpd Not Invd.(Base)", "Return Qty. Shipped (Base)",
            "Return Qty. Shipped Not Invd.", "Qty. to Receive", "Qty. to Receive (Base)", "Return Qty. to Ship", "Return Qty. to Ship (Base)", "Return Qty. Shipped", "Outstanding Quantity", "Outstanding Qty. (Base)",
            "Quantity Invoiced", "Qty. Invoiced (Base)", "Quantity Received", "Qty. Received (Base)", "Qty. per Unit of Measure", "Reserved Quantity",
            "Unit Cost", "Amount Including VAT", Amount, "Line Amount", "Inv. Discount Amount", "Inv. Disc. Amount to Invoice", "VAT Difference", "VAT Base Amount",
            "Outstanding Amount", "Outstanding Amount (LCY)", "Amt. Rcd. Not Invoiced", "Amt. Rcd. Not Invoiced (LCY)", "Return Shpd. Not Invd.", "Return Shpd. Not Invd. (LCY)",
            "System-Created Entry", "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "VAT %", "Allow Invoice Disc.", "Prepayment Line", "Completely Received");
    end;

    /// <summary>
    /// Checks if the quantity to post for the purchase line meets the specified quantity in the reservation entries.
    /// </summary>
    /// <param name="QtyToPost">Quantity that will be posted.</param>
    /// <param name="ReservedFromStock">Reservation from stock type.</param>
    /// <returns>True if the reserved quantity meets the quantity in the reservation entries, otherwise false.</returns>
    procedure CheckIfPurchaseLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if not Rec.IsInventoriableItem() then
            exit(true);

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := PurchLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfPurchaseLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    local procedure CannotInvoiceErrorInfo(): ErrorInfo
    var
        ErrorMesageManagement: Codeunit "Error Message Management";
    begin
        exit(ErrorMesageManagement.BuildActionableErrorInfo(
            QtyInvoiceNotValidTitleLbl,
            StrSubstNo(Text006, MaxQtyToInvoice()),
            Rec.RecordId,
            StrSubstNo(QtyInvoiceActionLbl, MaxQtyToInvoice()),
            Codeunit::"Purchase Line - Price",
            'SetPurchaseQtyInvoice',
            StrSubstNo(QtyInvoiceActionDescriptionLbl, Rec.FieldCaption("Qty. to Invoice"), Rec.Quantity)));
    end;

    local procedure CannotReceiveErrorInfo(): ErrorInfo
    var
        ErrorMesageManagement: Codeunit "Error Message Management";
    begin
        exit(ErrorMesageManagement.BuildActionableErrorInfo(
            QtyReceiveNotValidTitleLbl,
            StrSubstNo(Text008, "Outstanding Quantity"),
            Rec.RecordId,
            StrSubstNo(QtyReceiveActionLbl, "Outstanding Quantity"),
            Codeunit::"Purchase Line - Price",
            'SetPurchaseReceiveQty',
            StrSubstNo(QtyReceiveActionDescriptionLbl, Rec.FieldCaption("Qty. to Receive"), Rec.Quantity)));
    end;

    local procedure CheckQuoteVendorTemplateCode(PurchaseHeader: Record "Purchase Header")
    begin
        if (PurchaseHeader."Buy-from Vendor No." = '') and
           (PurchaseHeader."Buy-from Vendor Templ. Code" = '')
        then
            Error(
              MustSpecifyErr,
              PurchaseHeader.FieldCaption("Buy-from Vendor No."),
              PurchaseHeader.FieldCaption("Buy-from Vendor Templ. Code"));

        if (PurchaseHeader."Pay-to Vendor No." = '') and
           (PurchaseHeader."Pay-to Vendor Templ. Code" = '')
        then
            Error(
              MustSpecifyErr,
              PurchaseHeader.FieldCaption("Pay-to Vendor No."),
              PurchaseHeader.FieldCaption("Pay-to Vendor Templ. Code"));
    end;

    procedure IsProdOrder() Result: Boolean
    begin
        OnIsProdOrder(Rec, Result);
    end;

    procedure IsWorkCenter() Result: Boolean
    begin
        OnIsWorkCenter(Rec, Result);
    end;

    procedure TestProdOrderNo()
    begin
        OnTestProdOrderNo(Rec);
    end;

    procedure TestWorkCenterNo()
    begin
        OnTestWorkCenterNo(Rec);
    end;

    internal procedure ClearVATPct()
    begin
        "VAT %" := 0;
        OnAfterClearVATPct(Rec);
    end;

    internal procedure ClearPrepaymentVATPct()
    begin
        "Prepayment VAT %" := 0;
        OnAfterClearPrepaymentVATPct(Rec);
    end;

    internal procedure ClearVATDifference()
    begin
        "VAT Difference" := 0;
        OnAfterClearVATDifference(Rec);
    end;

    procedure GetVATPct() VATPct: Decimal
    begin
        VATPct := "VAT %";
        OnAfterGetVATPct(Rec, VATPct);
    end;

    internal procedure GetPrepaymentVATPct() PrepaymentVATPct: Decimal
    begin
        PrepaymentVATPct := "Prepayment VAT %";
        OnAfterGetPrepaymentVATPct(Rec, PrepaymentVATPct);
    end;

    internal procedure CopyFromVATPostingSetup(var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        "VAT %" := VATPostingSetup."VAT %";
        "VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
            Validate("Allow Invoice Disc.", false);
        "VAT Identifier" := VATPostingSetup."VAT Identifier";

        OnAfterCopyFromVATPostingSetup(Rec, VATPostingSetupFrom);
    end;

    internal procedure CopyPrepaymentFromVATPostingSetup(var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        "Prepayment VAT %" := VATPostingSetup."VAT %";
        "Prepmt. VAT Calc. Type" := VATPostingSetup."VAT Calculation Type";
        "Prepayment VAT Identifier" := VATPostingSetup."VAT Identifier";
        if "Prepmt. VAT Calc. Type" in ["Prepmt. VAT Calc. Type"::"Reverse Charge VAT", "Prepmt. VAT Calc. Type"::"Sales Tax"] then
            ClearPrepaymentVATPct();

        OnAfterCopyPrepaymentFromVATPostingSetup(Rec, VATPostingSetupFrom);
    end;

    internal procedure TestPurchaseJobFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchaseJobFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Job No." = '' then
            exit;

        Rec.TestField("Job Task No.");
    end;

    local procedure CheckAcquisitionCost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAcquisitionCost(Rec, IsHandled);
        if IsHandled then
            exit;
        TestField("FA Posting Type", "FA Posting Type"::"Acquisition Cost");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var PurchaseLine: Record "Purchase Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddItem(var PurchaseLine: Record "Purchase Line"; LastPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFieldsForNo(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var PurchLine: Record "Purchase Line"; StandardText: Record "Standard Text")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var PurchLine: Record "Purchase Line"; GLAccount: Record "G/L Account"; PurchHeader: Record "Purchase Header"; xPurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item; CurrentFieldNo: Integer; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemChargeValues(var PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFixedAssetValues(var PurchLine: Record "Purchase Line"; FixedAsset: Record "Fixed Asset"; PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemUOM(var PurchLine: Record "Purchase Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlanketOrderLookup(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteChargeChargeAssgntProcedure(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeferralAmount(PurchaseLine: Record "Purchase Line"; var DeferralAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var Item: Record Item; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTranslation(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchHeader(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchSetup(var PurchaseLine: Record "Purchase Line"; var PurchSetup: Record "Purchases & Payables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFAPostingGroup(var PurchaseLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetReservationQty(var PurchLine: Record "Purchase Line"; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var PurchaseLine: Record "Purchase Line"; var Item: Record Item; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var PurchaseLine: Record "Purchase Line"; ReservationEntry: Record "Reservation Entry"; DocumentType: Enum "Purchase Document Type"; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindDefaultFADeprBook(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasTypeToFillMandatoryFields(var PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitType(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLineDiscPct(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignFieldsForQtyPerUOM(var PurchaseLine: Record "Purchase Line"; Item: Record Item; FieldNo: Integer; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleDedicatedBin(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; IssueWarning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAbsMin(PurchaseLine: Record "Purchase Line"; QtyToHandle: Decimal; QtyHandled: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemReference(var Rec: Record "Purchase Line"; xRec: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemChargeAssgnt(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDirectUnitCostProcedure(var PurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderDateFromPlannedReceiptDate(var PurchaseLine: Record "Purchase Line"; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePlannedReceiptDateFromOrderDate(var PurchaseLine: Record "Purchase Line"; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOrderDateFromRequestedReceiptDate(var PurchaseLine: Record "Purchase Line"; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitHeaderDefaults(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; var TempPurchLine: record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var PurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive2(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive2Procedure(var PurchLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultQuantity(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultGLAccountQuantity(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvDiscToInvoice(var PurchaseLine: Record "Purchase Line"; OldInvDiscAmtToInv: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var PurchaseLine: Record "Purchase Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyPerUnitOfMeasure(var PurchaseLine: Record "Purchase Line"; Item: Record Item; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalAmtToAssign(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Currency: Record Currency; TotalQtyToAssign: Decimal; var TotalAmtToAssign: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReceiptRelation(PurchaseLine: Record "Purchase Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRetShptRelation(var PurchaseLine: Record "Purchase Line"; ReturnShipmentLine: Record "Return Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var PurchLine: Record "Purchase Line"; CallingFieldNo: Integer; xPurchLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDeferralPostDate(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; var DeferralPostDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineAmountToHandle(PurchLine: Record "Purchase Line"; QtyToHandle: Decimal; var LineAmount: Decimal; var LineDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetQtyPerUOM(var QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculate(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverse(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleItems(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowItemChargeAssgnt(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssgnmtPurch: Record "Item Charge Assignment (Purch)"; var ItemChargeAssignmentPurchPage: Page "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDates(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsDone(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBaseAmounts(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; CurrFieldNo: Integer; NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit"; Currency: Record Currency; GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateICPartner(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateJobPrices(var PurchLine: Record "Purchase Line"; JobJnlLine: Record "Job Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseReceive(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var PurchaseLine: Record "Purchase Line"; TotalLineAmount: Decimal; TotalInvDiscAmount: Decimal; TotalAmount: Decimal; TotalAmountInclVAT: Decimal; TotalVATDifference: Decimal; TotalQuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesCost(var PurchaseLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var PurchaseLine: Record "Purchase Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignHeaderValues(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var PurchaseLine: Record "Purchase Line"; Qty: Decimal; FromFieldName: Text; ToFieldName: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoiceProcedure(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcIndirectCostPercent(var PurchaseLine: Record "Purchase Line"; UnitCostCurrency: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPrepaymentToDeduct(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearQtyIfBlank(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssosiatedSalesOrder(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssosiatedProdOrder(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtAmounts(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; CurrentFieldNo: Integer; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtAmtInvEmpty(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var ShowDialogMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocationOnWMS(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoAndQuantityForItemChargeAssgnt(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var PurchaseLine: Record "Purchase Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromGLAccount(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNotHandledCopyFromGLAccount(var PurchaseLine: Record "Purchase Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; CurrentFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderLookup(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoice(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDirectUnitCost(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempJobJnlLine(var TempJobJournalLine: Record "Job Journal Line" temporary; PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; GetPrices: Boolean; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; xPurchaseLine: record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var PurchaseLine: Record "Purchase Line"; var DeferralAmount: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemTranslation(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFAPostingGroup(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureDirectedPutawayandPickFalse(var PurchaseLine: Record "Purchase Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOrCreateRecordByNo(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatType(PurchaseLine: Record "Purchase Line"; var FormattedType: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVPGInvRoundAcc(PurchHeader: Record "Purchase Header"; Vendor: Record Vendor; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReservationQty(var PurchaseLine: Record "Purchase Line"; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitJobFields(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDeferralCode(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToInvoice(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingAndQtyToShipReceive(var PurchaseLine: Record "Purchase Line"; var TempPurchLine: Record "Purchase Line" temporary; var IsHandled: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobSetCurrencyFactor(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskIsSet(PurchLine: Record "Purchase Line"; var IsJobLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBinCode(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBlanketOrderNo(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoice(PurchaseLine: Record "Purchase Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoiceBase(PurchaseLine: Record "Purchase Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleItems(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetUnitOfMeasure(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetVendorItemNo(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(PurchaseLine: Record "Purchase Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservationEntries(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowBinCodeCannotBeChangedError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowEarlyOrderDateMessageOnAfterCalcShowMessage(PurchaseLine: Record "Purchase Line"; var ShowMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDates(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobFields(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobPrices(var PurchLine: Record "Purchase Line"; JobJnlLine: Record "Job Journal Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLeadTimeFields(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency; var IsHandled: Boolean; CurrentFiledNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmounts(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtSetupFields(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesCost(var PurchaseLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSpecialSalesOrderLineFromOnDelete(var PurchaseLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesCostOnBeforeGetSalesOrderLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesCostFromUnitCostLCY(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPriceLCYFromItem(var PurchaseLine: Record "Purchase Line"; Item: Record "Item"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUOMQtyPerStockQty(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var Item: Record Item; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseReceive(var PurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBlanketOrderLineNo(var PurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateGenProdPostingGroup(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobPlanningLineNo(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateOrderDate(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; TrackingBlocked: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATProdPostingGroupFromGLAcc(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLeadTimeCalculation(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePlannedReceiptDate(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; TrackingBlocked: Boolean; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemDescription(var PurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineDiscountAmount(var PurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePlannedReceiptDateWithCustomCalendarChange(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtLineAmount(var PurchaseLine: Record "Purchase Line"; PrePaymentLineAmountEntered: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePromisedReceiptDate(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineDiscountPctForNotItemType(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityInvIsBalanced(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityReceiveIsBalanced(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityReturnIsBalanced(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReasonCode(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateType(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtytoInvoiceBase(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtytoReceiveBase(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnQtytoShipBase(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLineAmount(var PurchaseLine: Record "Purchase Line"; MaxLineAmount: Decimal; var IsHandled: Boolean; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLineTypeOnIndirectCostPercentUpdate(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyLineTypeForJob(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTempJobJnlLine(var JobJournalLine: Record "Job Journal Line"; PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; GetPrices: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateLocationCode(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcLineTotals(var VATAmountLine: Record "VAT Amount Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Currency: Record Currency; QtyType: Option General,Invoicing,Shipping; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesAfterVATAmountLineInsertNewLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineSumLine(PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping; var PurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeProcessPurchLine(var PurchaseLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnQtyTypeInvoicingOnBeforeCalcAmtToHandle(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var QtyToHandle: Decimal; var VATAmountLine: record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLocationRequireReceiveOnBeforePurchaseLineVerifyChange(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnBeforeShowDialog(var PurchLine: Record "Purchase Line"; Location2: Record Location; var ShowDialog: Option " ",Message,Error; var DialogText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterCheck(var PurchaseLine: Record "Purchase Line"; Item: Record Item; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempJobJnlLineOnBeforeTempJobJnlLineValidateNo(var TempJobJnlLine: Record "Job Journal Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforePurchLineDeleteAll(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAPostingGroupOnBeforeLocalGLAccGet(PurchaseLine: Record "Purchase Line"; FAPostingGroup: Record "FA Posting Group"; var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendLineInvoiceDiscountResetNotification(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterLinesForReservationOnBeforeSetFilterVariantCode(var PurchaseLine: Record "Purchase Line"; var ReservationEntry: Record "Reservation Entry"; var Positive: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToReceive2OnBeforeCalcInvDiscToInvoice(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitOutstandingOnBeforeInitOutstandingAmount(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemChargeAssgntOnBeforeCalcItemCharge(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssgntLineAmt: Decimal; Currency: Record Currency; var IsHandled: Boolean; var ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectUnitCostOnBeforeFindPrice(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDeferralAmountsOnBeforeSetDeferralPostDate(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var DeferralPostDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateUnitCostLCY(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; CurrentFieldNo: Integer; Item: Record Item; SKU: Record "Stockkeeping Unit"; Currency: Record Currency; GLSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateNewAmount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATAmountLine: Record "VAT Amount Line"; VATAmountLineReminder: Record "VAT Amount Line"; var NewAmountIncludingVAT: Decimal; VATAmount: Decimal; var NewAmount: Decimal; var NewVATBaseAmount: Decimal; var CurrentPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateVATDifference(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineReminder: Record "VAT Amount Line" temporary; QtyType: Option General,Invoicing,Shipping; var CurrentPurchaseLine: Record "Purchase Line"; LineAmountToInvoice: Decimal; InvDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeInitOutstanding(var PurchaseLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; VATAmount: Decimal; NewVATBaseAmount: Decimal; var CurrentPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalcNotFullVATAmount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; var Currency: record Currency; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; NewVATBaseAmount: decimal; VATAmount: decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobNoOnBeforeGetJob(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDescriptionOnAfterCalcShouldErrorForFindDescription(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var ShouldErrorForFindDescription: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedReceiptDateOnBeforeCheckDateConflict(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineAmountOnAfterCalcMaxLineAmount(var PurchaseLine: Record "Purchase Line"; var MaxLineAmount: Decimal; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnAfterTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnBeforeUpdateAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeDropShipmentError(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeSpecialOrderError(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; CurrFieldNo: Integer; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterCheckItem(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnBeforeInitRec(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnCopyFromTempPurchLine(var PurchLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnCopyFromTempPurchLine(var PurchLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary; xPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterAssignQtyFromXRec(var PurchaseLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterChecks(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterVerifyChange(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitRec(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterAssignFields(var PurchaseLine: Record "Purchase Line"; Purchasing: Record Purchasing)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterCheck(var PurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterInitQty(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterCalcQtyToReceiveBase(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterCalcShouldCheckLocationRequireReceive(var PurchaseLine: Record "Purchase Line"; var ShouldCheckLocationRequireReceive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeDropShptCheck(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeInitQtyToReceive(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforePurchaseLineVerifyChange(var PurchaseLine: Record "Purchase Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean; var xPurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnQtyToShipOnAfterCheck(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnQtyToShipOnAfterInitQty(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitCostLCYOnAfterUpdateUnitCostCurrency(var PurchaseLine: Record "Purchase Line"; var UnitCostCurrency: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterCalcShouldUpdateItemReference(var PurchaseLine: Record "Purchase Line"; var ShouldUpdateItemReference: Boolean; var ShouldUpdateNonSubcontractingDocument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterValidationChecks(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterCalcShouldUpdateUnitCost(var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; var ShouldUpdateUnitCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(var PurchaseLine: Record "Purchase Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOverReceiptQuantity(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Determines if the line is a charge item line that has been at least partially assigned.
    /// </summary>
    /// <returns>True if the line is a charge item line that has been at least partially assigned, otherwise false.</returns>
    procedure AssignedItemCharge(): Boolean
    begin
        exit((Type = Type::"Charge (Item)") and ("No." <> '') and ("Qty. to Assign" < Quantity));
    end;

    /// <summary>
    /// Opens a page with deferral schedule for the purchase line.
    /// </summary>
    /// <remarks>
    /// If the deferral schedule doesn't exist yet, a new one is created and commited before the page is opened.
    /// </remarks>
    procedure ShowDeferralSchedule()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(Rec."Document Type", Rec."Document No.");
        ShowDeferrals(PurchaseHeader."Posting Date", PurchaseHeader."Currency Code");
    end;

    procedure RecalculateAmounts(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ExcludeLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetFilter("Line No.", '<>%1', ExcludeLineNo);
        PurchaseLine.SetFilter("Direct Unit Cost", '<>%1', 0);
        if PurchaseLine.FindSet(true) then
            repeat
                PurchaseLine.UpdateAmounts();
                PurchaseLine.Modify(true);
            until PurchaseLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var PurchaseLine: Record "Purchase Line"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUOM(var PurchaseLine: Record "Purchase Line"; Resource: Record Resource; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVendorItemNoFromItemReference(var Rec: Record "Purchase Line"; xRec: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBlanketOrderNoOnAfterCheck(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBuyFromVendorNo(PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInternalLeadTimeDays(PurchaseLine: Record "Purchase Line"; PurchDate: Date; var TotalDays: DateFormula);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchHeader(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateLineAmount(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; Currency: Record Currency; var LineAmountChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateJobTaskNo(xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; CurrentFieldNo: Integer; var TempJobJournalLine: Record "Job Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckLocationRequireReceive(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckLineNotShippedOrReceived(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreditDocType(PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckRcptRetShptRelation(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcDoInitOutstanding(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var DoInitOutstanding: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterPlanPriceCalcByField(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToInvoice(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeUpdateItemReference(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterUpdateItemReference(var PurchaseLine: Record "Purchase Line"; CallingFeildNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRequestedReceiptDate(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var CustomCalendarChange: array[2] of Record "Customized Calendar Change"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplToItemLedgEntry(var PurchaseLine: Record "Purchase Line"; ItemLedgEntry: Record "Item Ledger Entry"; var Result: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptRelation(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRetShptRelation(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOverheadRateFCY(var PurchaseLine: Record "Purchase Line"; var QtyPerUOM: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforePurchaseLineDelete(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeCheckQtyNotInvoiced(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnBeforeAssignUnitPriceLCY(var PurchaseLine: Record "Purchase Line"; var GLSetup: Record "General Ledger Setup"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnBeforeSetRangeLocationCode(var PurchaseLine: Record "Purchase Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnAfterItemLedgEntrySetFilters(var PurchaseLine: Record "Purchase Line"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectUnitCostByFieldOnBeforeUpdateItemReference(var PurchaseLine: Record "Purchase Line"; var CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterCalcNormalVATAmountsForPricesIncludingVAT(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Currency: Record Currency; TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var PurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterCalcNormalVATAmountsForPricesExcludingVAT(var PurchaseLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; Currency: Record Currency; TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var PurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforePurchLineModify(var PurchaseLine: Record "Purchase Line"; var PurchLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeProcessPurchLines(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var VATAmountLine: Record "VAT Amount Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var LineWasModified: Boolean; var IsHandled: Boolean; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeProcessPurchLine(var PurchaseLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitType(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOverReceiptProcessing(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldQuantity(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineDiscountPercent(var PurchaseLine: Record "Purchase Line"; DropInvoiceDiscountAmount: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnAfterTestStatusOpen(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDimensionsFromJobTask(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitHeaderDefaultsOnBeforeSetVATBusPostingGroup(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeAssignQtyFromXRec(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddItemOnBeforeInsert(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnAfterTestStatusOpen(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservEntry: Record "Reservation Entry"; var PurchaseLine: Record "Purchase Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultQuantity(var PurchLine: Record "Purchase Line"; var xPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateICPartner(var PurchLine: Record "Purchase Line"; GLAcc: Record "G/L Account"; var PurchHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchasingCode(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineAmountBeforeValidateLineDiscountAmount(var PurchLine: Record "Purchase Line"; Currency: Record Currency; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstanding(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateOrderDate(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnAfterCalculateNormalVAT(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckWithQuantityReceived(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterShouldCheckWithReturnQtyShipped(var PurchaseLine: Record "Purchase Line"; var ShouldCalcWithReturnQtyShipped: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckWMS(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterInitQty(var PurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeValidateLineDiscountPercent(PurchaseLine: Record "Purchase Line"; var PurchLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterCalcShouldModifySalesOrderLine(var PurchaseLine: Record "Purchase Line"; var ShouldModifySalesOrderLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLineAmountToHandle(PurchaseLine: Record "Purchase Line"; var Currency: Record Currency; QtyToHandle: Decimal; var LineAmount: Decimal; var LineDiscAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnAfterCalcDiscountAmountPerQty(var PurchaseLine: Record "Purchase Line"; var DiscountAmountPerQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterPurchLineDeleteAll(var PurchaseLine: Record "Purchase Line"; var PurchLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnAfterCalcStandardUnitCostLCY(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnAfterCheckQty(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeGetVATPostingSetup(var PurchaseLine: Record "Purchase Line"; var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; var xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeResetAmounts(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineDiscAmountLCY(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineType(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobUnitPrice(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobNo(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineDiscountPercent(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineDiscountAmount(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobUnitPriceLCY(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineAmount(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobLineAmountLCY(var PurchaseLine: Record "Purchase Line"; var TempJobJnlLine: Record "Job Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLineDiscountAmountOnValidateOnBeforeUpdateAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterUpdateBaseAmounts(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeCheckReceiptNo(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterUpdateAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeUpdateAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnAfterSetLocation2(var PurchaseLine: Record "Purchase Line"; var Location2: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeZeroAmountLine(var PurchaseLine: Record "Purchase Line"; QtyType: Option General,Invoicing,Shipping; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeAssignQuantities(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: record "VAT Amount Line"; var QtyToHandle: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimFromDefaultDimOnBeforeCreateDim(PurchaseLine: Record "Purchase Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimFromDefaultDim(var PurchaseLine: Record "Purchase Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultBin(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeCalcAmounts(var PurchaseLine: Record "Purchase Line"; var PurchaseLine2: Record "Purchase Line"; var TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal; var TotalQuantityBase: Decimal; TotalVATDifference: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDate(var ResultDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSignedValue(var PurchaseLine: Record "Purchase Line"; Value: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateTypePurchaseLine(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNoPurchaseLine(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttachToInventoryItemLine(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobPlanningLineNoOnBeforeGLAccountTest(var PurchaseLine: Record "Purchase Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateJobPlanningLineNoOnBeforeTestFields(var PurchaseLine: Record "Purchase Line"; var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsInbound(PurchaseLine: Record "Purchase Line"; var IsInboundDocument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderIsRelated(var CurrentPurchaseLine: Record "Purchase Line"; var BlanketOrderPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBlanketOrderIsRelatedOnAfterSetLoadFields(var BlanketOrderPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectUnitCostByFieldOnAfterSetBlanketOrderPriceFields(PurchaseHeader: Record "Purchase Header"; BlanketOrderPurchaseLine: Record "Purchase Line"; var CurrentPurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrePaymentAmounts(var PurchaseLine: Record "Purchase Line")
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(true, false)]
    local procedure OnValidateNoOnBeforeJobTaskIsSet(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; TempPurchaseLine: Record "Purchase Line" temporary; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeBeforeCheckBlocked(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateBlanketOrderLineNo(var PurchaseLine: Record "Purchase Line"; BlanketOrderPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfPurchaseLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcShouldProcessRounding(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalVATAmount: Decimal; Currency: Record Currency; var ShouldProcessRounding: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineUpdateLines(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line"; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVendorItemNo(var PurchaseLine: Record "Purchase Line"; ItemVendor: Record "Item Vendor"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnAfterEditDimensionSet(var PurchaseLine: Record "Purchase Line"; OldDimensionSetId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterGetItemTranslation(var PurchaseLine: Record "Purchase Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDirectUnitCostOnBeforeValidateLineDiscPct(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmReceivedShippedItemDimChange(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVatBaseDiscountPct(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDirectUnitCostByFieldOnAfterCalcShouldExit(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensionsFromJobTask(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearQtyIfBlank(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; PurchasePayablesSetup: Record "Purchases & Payables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestProdOrderNo(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestWorkCenterNo(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumVATAmountLineOnBeforeModify(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsProdOrder(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsWorkCenter(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsSubcontractingCreditMemo(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLinesOnAfterCheck(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAssosiatedProdOrder(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReversedInternalLeadTimeDays(PurchaseLine: Record "Purchase Line"; PurchDate: Date; ReversedWhseHandlingTime: DateFormula; var TotalDays: DateFormula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingSetup(var PurchaseLine: Record "Purchase Line"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATPct(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearPrepaymentVATPct(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATDifference(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var PurchaseLine: Record "Purchase Line"; var VATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentVATPct(var PurchaseLine: Record "Purchase Line"; var PrepaymentVATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVATPostingSetup(var PurchaseLine: Record "Purchase Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPrepaymentFromVATPostingSetup(var PurchaseLine: Record "Purchase Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFAPostingGroupOnBeforeCheckGLAcc(var PurchaseLine: Record "Purchase Line"; var GLAccount: Record "G/L Account"; FADeprBook: Record "FA Depreciation Book"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateLineAmount(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; Currency: Record Currency; var LineAmountChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeSetInboundWhseHandlingTime(CurrFieldNo: Integer; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateOrderDateOnBeforeCheckDateConflict(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeCalcStandardUnitCostLCY(var PurchaseLine: Record "Purchase Line"; var ShouldCalcStandardUnitCostLCY: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateIndirectCostOnAfterCalcShouldCheckCostingMethod(var PurchaseLine: Record "Purchase Line"; var ShouldCheckCostingMethod: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeModifyPurchLine(var PurchaseLine: Record "Purchase Line"; VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchaseJobFields(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterLockTable(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyOnAfterVerifyChange(var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemChargeAssgntOnBeforeItemChargeAssignmentPurchModify(var PurchaseLine: Record "Purchase Line"; var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAcquisitionCost(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckIsLineAmountToInvoiceSimple(PurchHeader: Record "Purchase Header"; var IsLineAmountToInvoiceSimple: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeAssignShippingQuantities(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmountLine: record "VAT Amount Line"; var QtyToHandle: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnQtyTypeShippingOnBeforeCalcAmtToHandle(var PurchLine: Record "Purchase Line"; var PurchHeader: Record "Purchase Header"; var QtyToHandle: Decimal; var VATAmountLine: record "VAT Amount Line")
    begin
    end;
}
