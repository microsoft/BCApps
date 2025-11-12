// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Utilities;
using System.Utilities;
using System.Environment.Configuration;

table 37 "Sales Line"
{
    Caption = 'Sales Line';
    DrillDownPageID = "Sales Lines";
    LookupPageID = "Sales Lines";
    Permissions = TableData "Sales Line" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of document that you are about to create.';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer.';
            Editable = false;
            TableRelation = Customer;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
            TableRelation = "Sales Header"."No." where("Document Type" = field("Document Type"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number.';
        }
        field(5; Type; Enum "Sales Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of entity that will be posted for this sales line, such as Item, Resource, or G/L Account. The type that you enter in this field determines what you can select in the No. field.';

            trigger OnValidate()
            var
                TempSalesLine: Record "Sales Line" temporary;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateType(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestJobPlanningLine();
                TestStatusOpen();
                GetSalesHeader();

                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                TestField("Return Qty. Rcd. Not Invd.", 0);
                TestField("Return Qty. Received", 0);
                TestField("Return Receipt No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                CheckAssocPurchOrder(FieldCaption(Type));

                if Type <> xRec.Type then begin
                    case xRec.Type of
                        Type::Item:
                            begin
                                ATOLink.DeleteAsmFromSalesLine(Rec);
                                if Quantity <> 0 then begin
                                    SalesHeader.TestField(Status, SalesHeader.Status::Open);
                                    CalcFields("Reserved Qty. (Base)");
                                    TestField("Reserved Qty. (Base)", 0);
                                    VerifyChangeForSalesLineReserve(FieldNo(Type));
                                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                                    OnValidateTypeOnAfterCheckItem(Rec, xRec);
                                end;
                            end;
                        Type::"Fixed Asset":
                            if Quantity <> 0 then
                                SalesHeader.TestField(Status, SalesHeader.Status::Open);
                        Type::"Charge (Item)":
                            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                        Type::" ":
                            if ("Attached to Line No." <> 0) and (Quantity = 0) then
                                Error(ChangeExtendedTextErr, FieldCaption(Type));
                    end;
                    if xRec."Deferral Code" <> '' then
                        DeferralUtilities.RemoveOrSetDeferralSchedule('',
                          Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                          xRec."Document Type".AsInteger(), xRec."Document No.", xRec."Line No.",
                          xRec.GetDeferralAmount(), xRec."Posting Date", '', xRec."Currency Code", true);

                    OnValidateTypeOnAfterVerifyChange(Rec, xRec);
                end;
                CheckReceiptOrderStatus();

                OnValidateTypeOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempSalesLine := Rec;
                Init();
                SystemId := TempSalesLine.SystemId;
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := xRec."Allow Invoice Disc.";

                Type := TempSalesLine.Type;
                "System-Created Entry" := TempSalesLine."System-Created Entry";
                "Currency Code" := SalesHeader."Currency Code";

                OnValidateTypeOnCopyFromTempSalesLine(Rec, TempSalesLine);

                if Type = Type::Item then
                    "Allow Item Charge Assignment" := true
                else
                    "Allow Item Charge Assignment" := false;
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
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const("Allocation Account")) "Allocation Account"
            else
            if (Type = const(Item)) Item;

            trigger OnValidate()
            var
                TempSalesLine: Record "Sales Line" temporary;
                IsHandled: Boolean;
                ShouldStopValidation: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetSalesSetup();
                Rec."No." := FindOrCreateRecordByNo(Rec."No.");

                TestJobPlanningLine();
                TestStatusOpen();
                CheckItemAvailable(FieldNo("No."));

                if (xRec."No." <> "No.") and (Quantity <> 0) then begin
                    TestField("Qty. to Asm. to Order (Base)", 0);
                    CalcFields("Reserved Qty. (Base)");
                    TestField("Reserved Qty. (Base)", 0);
                    if Type = Type::Item then
                        SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                    OnValidateNoOnAfterVerifyChange(Rec, xRec);
                    if CurrFieldNo = Rec.FieldNo("No.") then
                        CheckWarehouse(false);
                end;

                TestField("Qty. Shipped Not Invoiced", 0);
                TestField("Quantity Shipped", 0);
                TestField("Shipment No.", '');

                TestField("Prepmt. Amt. Inv.", 0);

                TestField("Return Qty. Rcd. Not Invd.", 0);
                TestField("Return Qty. Received", 0);
                TestField("Return Receipt No.", '');

                if "No." = '' then
                    ATOLink.DeleteAsmFromSalesLine(Rec);
                CheckAssocPurchOrder(FieldCaption("No."));
                CheckReceiptOrderStatus();

                OnValidateNoOnBeforeInitRec(Rec, xRec, CurrFieldNo);
                TempSalesLine := Rec;
                Init();
                SystemId := TempSalesLine.SystemId;
                if xRec."Line Amount" <> 0 then
                    "Recalculate Invoice Disc." := xRec."Allow Invoice Disc.";
                Type := TempSalesLine.Type;
                "No." := TempSalesLine."No.";
                OnValidateNoOnCopyFromTempSalesLine(Rec, TempSalesLine, xRec, CurrFieldNo);
                ShouldStopValidation := "No." = '';
                OnValidateNoOnAfterCalcShouldStopValidation(Rec, xRec, CurrFieldNo, ShouldStopValidation);
                if ShouldStopValidation then
                    exit;

                if HasTypeToFillMandatoryFields() then begin
                    Quantity := TempSalesLine.Quantity;
                    "Outstanding Qty. (Base)" := TempSalesLine."Outstanding Qty. (Base)";
                end;

                "System-Created Entry" := TempSalesLine."System-Created Entry";
                GetSalesHeader();
                OnValidateNoOnBeforeInitHeaderDefaults(SalesHeader, Rec, TempSalesLine);
                InitHeaderDefaults(SalesHeader);
                OnValidateNoOnAfterInitHeaderDefaults(SalesHeader, TempSalesLine, Rec);

                CalcFields("Substitution Available");

                "Promised Delivery Date" := SalesHeader."Promised Delivery Date";
                "Requested Delivery Date" := SalesHeader."Requested Delivery Date";

                IsHandled := false;
                OnValidateNoOnBeforeCalcShipmentDateForLocation(IsHandled, Rec);
                if not IsHandled then
                    CalcShipmentDateForLocation();

                IsHandled := false;
                OnValidateNoOnBeforeUpdateDates(Rec, xRec, SalesHeader, CurrFieldNo, IsHandled, TempSalesLine);
                if not IsHandled then
                    UpdateDates();

                OnAfterAssignHeaderValues(Rec, SalesHeader);

                case Type of
                    Type::" ":
                        CopyFromStandardText();
                    Type::"G/L Account":
                        CopyFromGLAccount(TempSalesLine);
                    Type::Item:
                        CopyFromItem();
                    Type::Resource:
                        CopyFromResource();
                    Type::"Fixed Asset":
                        CopyFromFixedAsset();
                    Type::"Charge (Item)":
                        CopyFromItemCharge();
                end;

                OnAfterAssignFieldsForNo(Rec, xRec, SalesHeader);

                IsHandled := false;
                OnValidateNoOnBeforeCheckPostingSetups(Rec, IsHandled);
                if not IsHandled then
                    if Type <> Type::" " then
                        if not IsTemporary() then begin
                            PostingSetupMgt.CheckGenPostingSetupSalesAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                            PostingSetupMgt.CheckGenPostingSetupCOGSAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                            PostingSetupMgt.CheckVATPostingSetupSalesAccount("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                        end;

                if HasTypeToFillMandatoryFields() and (Type <> Type::"Fixed Asset") then
                    ValidateVATProdPostingGroup();

                UpdatePrepmtSetupFields();

                if HasTypeToFillMandatoryFields() then begin
                    PlanPriceCalcByField(FieldNo("No."));
                    ValidateUnitOfMeasureCodeFromNo();
                    if Quantity <> 0 then begin
                        OnValidateNoOnBeforeInitOutstanding(Rec, xRec);
                        InitOutstanding();
                        if IsCreditDocType() then
                            InitQtyToReceive()
                        else
                            InitQtyToShip();
                        InitQtyToAsm();
                        UpdateWithWarehouseShip();
                    end;
                end;

                IsHandled := false;
                OnValidateNoOnBeforeCreateDimFromDefaultDim(Rec, IsHandled, TempSalesLine);
                if not IsHandled then
                    CreateDimFromDefaultDim(Rec.FieldNo("No."));

                OnValidateNoOnAfterCreateDimFromDefaultDim(Rec, xRec, SalesHeader, CurrFieldNo);

                if "No." <> xRec."No." then begin
                    if Type = Type::Item then begin
                        if (Quantity <> 0) and ItemExists(xRec."No.") then begin
                            VerifyChangeForSalesLineReserve(FieldNo("No."));
                            SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                        end;
                        CheckItemCanBeAddedToSalesLine();
                    end;

                    GetDefaultBin();
                    Rec.AutoAsmToOrder();
                    DeleteItemChargeAssignment("Document Type", "Document No.", "Line No.");
                    if Type = Type::"Charge (Item)" then
                        DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");
                end;

                UpdateItemReference(FieldNo("No."));

                UpdateUnitPriceByField(FieldNo("No."));

                OnValidateNoOnAfterUpdateUnitPrice(Rec, xRec, TempSalesLine);
            end;
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the inventory location from which the items sold should be picked and where the inventory decrease is registered.';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestJobPlanningLine();
                TestStatusOpen();
                CheckAssocPurchOrder(FieldCaption("Location Code"));
                OnValidateLocationCodeOnAfterCheckAssocPurchOrder(Rec);
                if xRec."Location Code" <> "Location Code" then begin
                    if not FullQtyIsForAsmToOrder() then begin
                        CalcFields("Reserved Qty. (Base)");
                        IsHandled := false;
                        OnValidateLocationCodeOnBeforeTestReservedQtyBase(Rec, IsHandled);
                        if not IsHandled then
                            TestField("Reserved Qty. (Base)", "Qty. to Asm. to Order (Base)");
                    end;
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');
                    TestField("Return Qty. Rcd. Not Invd.", 0);
                    TestField("Return Receipt No.", '');
                end;

                GetSalesHeader();
                IsHandled := false;
                OnValidateLocationCodeOnBeforeSetShipmentDate(Rec, IsHandled);
                if not IsHandled then
                    CalcShipmentDateForLocation();

                CheckItemAvailable(FieldNo("Location Code"));

                if not "Drop Shipment" then begin
                    if "Location Code" = '' then begin
                        if InvtSetup.Get() then
                            "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                    end else
                        if Location.Get("Location Code") then
                            "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                end else
                    Evaluate("Outbound Whse. Handling Time", '<0D>');

                OnValidateLocationCodeOnAfterSetOutboundWhseHandlingTime(Rec);

                if "Location Code" <> xRec."Location Code" then begin
                    InitItemAppl(true);
                    GetDefaultBin();
                    InitQtyToAsm();
                    Rec.AutoAsmToOrder();
                    if Quantity <> 0 then begin
                        if not "Drop Shipment" then
                            UpdateWithWarehouseShip();
                        if not FullReservedQtyIsForAsmToOrder() then
                            VerifyChangeForSalesLineReserve(FieldNo("Location Code"));
                        SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                    end;
                    if IsInventoriableItem() then
                        PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");
                end;

                UpdateDates();

                if (Type = Type::Item) and ("No." <> '') then
                    GetUnitCost();

                CheckWMS();

                if "Document Type" = "Document Type"::"Return Order" then
                    ValidateReturnReasonCode(FieldNo("Location Code"));

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
        field(10; "Shipment Date"; Date)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
                DoCheckReceiptOrderStatus: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentDate(IsHandled, Rec, xRec, CurrFieldNo);
                if IsHandled then
                    exit;

                TestStatusOpen();
                SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                DoCheckReceiptOrderStatus := CurrFieldNo <> 0;
                OnValidateShipmentDateOnAfterSalesLineVerifyChange(Rec, CurrFieldNo, DoCheckReceiptOrderStatus);
                if DoCheckReceiptOrderStatus then
                    CheckReceiptOrderStatus();

                if "Shipment Date" <> 0D then begin
                    if CurrFieldNo in [
                                       FieldNo("Planned Shipment Date"),
                                       FieldNo("Planned Delivery Date"),
                                       FieldNo("Shipment Date"),
                                       FieldNo("Shipping Time"),
                                       FieldNo("Outbound Whse. Handling Time"),
                                       FieldNo("Requested Delivery Date")]
                    then
                        CheckItemAvailable(FieldNo("Shipment Date"));

                    CheckShipmentDateBeforeWorkDate();
                end;

                Rec.AutoAsmToOrder();
                if (xRec."Shipment Date" <> "Shipment Date") and
                   (Quantity <> 0) and
                   not StatusCheckSuspended
                then
                    CheckDateConflict.SalesLineCheck(Rec, CurrFieldNo <> 0);

                if not PlannedShipmentDateCalculated then
                    "Planned Shipment Date" := CalcPlannedShptDate(FieldNo("Shipment Date"));
                if not PlannedDeliveryDateCalculated then
                    "Planned Delivery Date" := CalcPlannedDeliveryDate(FieldNo("Shipment Date"));
            end;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry of the product to be sold. To add a non-transactional text line, fill in the Description field only.';
            TableRelation = if (Type = const("G/L Account"), "System-Created Entry" = const(false)) "G/L Account".Name where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else
            if (Type = const("G/L Account"), "System-Created Entry" = const(true)) "G/L Account".Name
            else
            if (Type = const(Item)) Item.Description
            else
            if (Type = const(Resource)) Resource.Name
            else
            if (Type = const("Fixed Asset")) "Fixed Asset".Description
            else
            if (Type = const("Allocation Account")) "Allocation Account".Name
            else
            if (Type = const("Charge (Item)")) "Item Charge".Description;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Item: Record Item;
                ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
                FindRecordMgt: Codeunit "Find Record Management";
                ReturnValue: Text[100];
                DescriptionIsNo: Boolean;
                DefaultCreate: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDescription(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if not HasTypeToFillMandatoryFields() then
                    exit;

                if "No." <> '' then
                    exit;

                case Type of
                    Type::Item:
                        begin
                            if StrLen(Description) <= MaxStrLen(Item."No.") then
                                DescriptionIsNo := Item.Get(Description)
                            else
                                DescriptionIsNo := false;

                            if not DescriptionIsNo then begin
                                Item.SetRange(Blocked, false);
                                if not IsCreditDocType() then
                                    Item.SetRange("Sales Blocked", false);

                                // looking for an item with exact description
                                Item.SetRange(Description, Description);
                                if Item.FindFirst() then begin
                                    Validate("No.", Item."No.");
                                    exit;
                                end;

                                // looking for an item with similar description
                                Item.SetFilter(Description, '''@' + ConvertStr(Description, '''', '?') + '''');
                                if Item.FindFirst() then begin
                                    Validate("No.", Item."No.");
                                    exit;
                                end;
                            end;

                            GetSalesSetup();
                            DefaultCreate := ("No." = '') and SalesSetup."Create Item from Description";
                            if Item.TryGetItemNoOpenCard(
                                 ReturnValue, Description, DefaultCreate, not GetHideValidationDialog(), true)
                            then
                                case ReturnValue of
                                    '':
                                        begin
                                            LookupRequested := true;
                                            Description := xRec.Description;
                                        end;
                                    "No.":
                                        Description := xRec.Description;
                                    else begin
                                        CurrFieldNo := FieldNo("No.");
                                        Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen(Item."No.")));
                                    end;
                                end;
                        end;
                    else begin
                        IsHandled := false;
                        OnBeforeFindNoByDescription(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then begin
                            ReturnValue := FindRecordMgt.FindNoByDescription(Type.AsInteger(), Description, true);
                            if ReturnValue <> '' then begin
                                CurrFieldNo := FieldNo("No.");
                                Validate("No.", CopyStr(ReturnValue, 1, MaxStrLen("No.")));
                            end;
                        end;
                    end;
                end;

                IsHandled := false;
                OnValidateDescriptionOnBeforeCannotFindDescrError(Rec, xRec, IsHandled);
                if not IsHandled then
                    if ("No." = '') and GuiAllowed then
                        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
                            if "Document Type" in
                            ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote, "Document Type"::"Credit Memo"]
                            then
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
            TableRelation = if (Type = filter(<> " ")) "Unit of Measure".Description;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if CurrFieldNo = Rec.FieldNo("Unit of Measure") then
                    CheckWarehouse(false);
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies how many units are being sold.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                Item: Record Item;
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
                ShouldCalcWithReturnQtyReceived: Boolean;
                ShouldVerifyQtyForItem: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                TestJobPlanningLine();
                TestStatusOpen();

                OnValidateQuantityOnBeforeCheckAssocPurchOrder(Rec, CurrFieldNo);
                CheckAssocPurchOrder(FieldCaption(Quantity));

                if "Shipment No." <> '' then
                    CheckShipmentRelation()
                else
                    if "Return Receipt No." <> '' then
                        CheckRetRcptRelation();

                if CurrFieldNo = Rec.FieldNo(Quantity) then
                    CheckWarehouse(false);

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec);

                ShouldCalcWithReturnQtyReceived := IsCreditDocType();
                OnValidateQuantityOnAfterCalcShouldCalcWithReturnQtyReceived(Rec, ShouldCalcWithReturnQtyReceived);
                if ShouldCalcWithReturnQtyReceived then begin
                    if (Quantity * "Return Qty. Received" < 0) or
                       ((Abs(Quantity) < Abs("Return Qty. Received")) and ("Return Receipt No." = ''))
                    then
                        FieldError(Quantity, StrSubstNo(Text003, FieldCaption("Return Qty. Received")));
                    if ("Quantity (Base)" * "Return Qty. Received (Base)" < 0) or
                       ((Abs("Quantity (Base)") < Abs("Return Qty. Received (Base)")) and ("Return Receipt No." = ''))
                    then
                        FieldError("Quantity (Base)", StrSubstNo(Text003, FieldCaption("Return Qty. Received (Base)")));
                end else begin
                    IsHandled := false;
                    OnValidateQuantityOnBeforeCalcWithQuantityShipped(Rec, IsHandled);
                    if not IsHandled then begin
                        if (Quantity * "Quantity Shipped" < 0) or
                            ((Abs(Quantity) < Abs("Quantity Shipped")) and ("Shipment No." = ''))
                        then
                            FieldError(Quantity, StrSubstNo(Text003, FieldCaption("Quantity Shipped")));
                        if ("Quantity (Base)" * "Qty. Shipped (Base)" < 0) or
                            ((Abs("Quantity (Base)") < Abs("Qty. Shipped (Base)")) and ("Shipment No." = ''))
                        then
                            FieldError("Quantity (Base)", StrSubstNo(Text003, FieldCaption("Qty. Shipped (Base)")));
                    end;
                end;

                if (Type = Type::"Charge (Item)") and (CurrFieldNo <> 0) then begin
                    if (Quantity = 0) and ("Qty. to Assign" <> 0) then
                        FieldError("Qty. to Assign", StrSubstNo(Text009, FieldCaption(Quantity), Quantity));
                    if (Quantity * "Qty. Assigned" < 0) or (Abs(Quantity) < Abs("Qty. Assigned")) then
                        FieldError(Quantity, StrSubstNo(Text003, FieldCaption("Qty. Assigned")));
                end;

                IsHandled := false;
                OnValidateQuantityOnBeforeCheckReceiptOrderStatus(Rec, StatusCheckSuspended, IsHandled);
                if not IsHandled then
                    CheckReceiptOrderStatus();

                InitQty();

                IsHandled := false;
                OnValidateQuantityOnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    CheckItemAvailable(FieldNo(Quantity));

                    if (Quantity * xRec.Quantity < 0) or (Quantity = 0) then
                        InitItemAppl(false);

                    OnValidateQuantityOnBeforeCheckQuantityChangeForPriceCalc(Rec, xRec, CurrFieldNo);

                    if (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)") then
                        PlanPriceCalcByField(FieldNo(Quantity));

                    if Type = Type::Item then begin
                        ShouldVerifyQtyForItem := (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)"); // <-- NEW VARIABLE
                        OnValidateQuantityOnAfterCalcShouldVerifyQtyForItem(Rec, ShouldVerifyQtyForItem, xRec);
                        if ShouldVerifyQtyForItem then begin
                            OnBeforeVerifyReservedQty(Rec, xRec, FieldNo(Quantity));
                            SalesLineReserve.VerifyQuantity(Rec, xRec);
                            if not "Drop Shipment" then
                                UpdateWithWarehouseShip();

                            IsHandled := false;
                            OnValidateQuantityOnBeforeSalesLineVerifyChange(Rec, StatusCheckSuspended, IsHandled);
                            if not IsHandled then
                                SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                            if ("Quantity (Base)" * xRec."Quantity (Base)" <= 0) and ("No." <> '') then begin
                                GetItem(Item);
                                OnValidateQuantityOnBeforeGetUnitCost(Rec, Item);
                                if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment() then
                                    GetUnitCost();
                            end;
                        end;
                        IsHandled := false;
                        OnValidateQuantityOnBeforeValidateQtyToAssembleToOrder(Rec, StatusCheckSuspended, IsHandled);
                        if not IsHandled then
                            Validate("Qty. to Assemble to Order");
                        if (Quantity = "Quantity Invoiced") and (CurrFieldNo <> 0) then
                            CheckItemChargeAssgnt();
                        CheckApplFromItemLedgEntry(ItemLedgEntry);
                    end else
                        Validate("Line Discount %");

                    IsHandled := false;
                    OnValidateQuantityOnBeforeResetAmounts(Rec, xRec, IsHandled);
                    if not IsHandled then
                        if (xRec.Quantity <> Quantity) and (Quantity = 0) and
                           ((Amount <> 0) or ("Amount Including VAT" <> 0) or ("VAT Base Amount" <> 0))
                        then begin
                            Amount := 0;
                            "Amount Including VAT" := 0;
                            "VAT Base Amount" := 0;
                            OnValidateQuantityOnAfterInitializeAmounts(Rec)
                        end;

                    UpdateUnitPriceByField(FieldNo(Quantity));
                    UpdatePrePaymentAmounts();

                    CheckWMS();

                    UpdatePlanned();
                    if "Document Type" = "Document Type"::"Return Order" then
                        ValidateReturnReasonCode(FieldNo(Quantity));
                end;
            end;
        }
        field(16; "Outstanding Quantity"; Decimal)
        {
            Caption = 'Outstanding Quantity';
            ToolTip = 'Specifies how many units on the order line have not yet been shipped.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(17; "Qty. to Invoice"; Decimal)
        {
            Caption = 'Qty. to Invoice';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. to Invoice" := UOMMgt.RoundAndValidateQty("Qty. to Invoice", "Qty. Rounding Precision", FieldCaption("Qty. to Invoice"));
                if "Qty. to Invoice" = MaxQtyToInvoice() then
                    InitQtyToInvoice()
                else begin
                    "Qty. to Invoice (Base)" := CalcBaseQty("Qty. to Invoice", FieldCaption("Qty. to Invoice"), FieldCaption("Qty. to Invoice (Base)"));
                    if ("Quantity (Base)" = ("Qty. Invoiced (Base)" + "Qty. to Invoice (Base)")) and ("Qty. to Invoice" > 0) then
                        Error(QuantityImbalanceErr, ItemUOMForCaption.FieldCaption("Qty. Rounding Precision"), Type::Item, "No.", FieldCaption("Qty. to Invoice"), FieldCaption("Qty. to Invoice (Base)"));
                end;

                if ("Qty. to Invoice" * Quantity < 0) or
                   (Abs("Qty. to Invoice") > Abs(MaxQtyToInvoice()))
                then
                    Error(CannotInvoiceErrorInfo());

                if ("Qty. to Invoice (Base)" * "Quantity (Base)" < 0) or
                   (Abs("Qty. to Invoice (Base)") > Abs(MaxQtyToInvoiceBase()))
                then
                    Error(Text006, MaxQtyToInvoiceBase());

                GetSalesSetup();
                if not SalesSetup."Allow VAT Difference" then
                    ClearVATDifference();

                OnValidateQtyToInvoiceOnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
                CalcInvDiscToInvoice();
                CalcPrepaymentToDeduct();
            end;
        }
        field(18; "Qty. to Ship"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Qty. to Ship';
            ToolTip = 'Specifies the quantity of items that remain to be shipped.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                "Qty. to Ship" := UOMMgt.RoundAndValidateQty("Qty. to Ship", "Qty. Rounding Precision", FieldCaption("Qty. to Ship"));

                GetLocation("Location Code");
                CheckWarehouseForQtyToShip();
                OnValidateQtyToShipOnAfterCheck(Rec, CurrFieldNo);

                if "Qty. to Ship" = "Outstanding Quantity" then
                    InitQtyToShip()
                else begin
                    "Qty. to Ship (Base)" := CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)"));
                    if ("Quantity (Base)" = ("Qty. Shipped (Base)" + "Qty. to Ship (Base)")) and ("Qty. to Ship" > 0) then
                        Error(QuantityImbalanceErr, ItemUOMForCaption.FieldCaption("Qty. Rounding Precision"), Type::Item, "No.", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)"));

                    CheckServItemCreation();
                    InitQtyToInvoice();
                end;

                IsHandled := false;
                OnValidateQtyToShipAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if not CanShipQty() then
                        Error(CannotShipErrorInfo());

                    if not CanShipBaseQty() then
                        Error(Text008, "Outstanding Qty. (Base)");
                end;
                OnValidateQtyToShipOnAfterCheckQuantity(Rec, CurrFieldNo);

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Qty. to Ship" < 0) then
                    CheckApplFromItemLedgEntry(ItemLedgEntry);

                UpdateQtyToAsmFromSalesLineQtyToShip();
            end;
        }
        field(22; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            CaptionClass = GetCaptionClass(FieldNo("Unit Price"));
            Caption = 'Unit Price';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitPrice(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    Validate("Line Discount %");
            end;
        }
        field(23; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';

            trigger OnValidate()
            var
                Item: Record Item;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitCostLCY(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                   ("Unit Cost (LCY)" <> xRec."Unit Cost (LCY)")
                then
                    CheckAssocPurchOrder(FieldCaption("Unit Cost (LCY)"));

                if (CurrFieldNo = FieldNo("Unit Cost (LCY)")) and
                   (Type = Type::Item) and ("No." <> '') and ("Quantity (Base)" <> 0)
                then begin
                    TestJobPlanningLine();
                    GetItem(Item);
                    if (Item."Costing Method" = Item."Costing Method"::Standard) and not IsShipment() then begin
                        if IsCreditDocType() then
                            Error(
                              Text037,
                              FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                              Item."Costing Method", FieldCaption(Quantity));
                        Error(
                          Text038,
                          FieldCaption("Unit Cost (LCY)"), Item.FieldCaption("Costing Method"),
                          Item."Costing Method", FieldCaption(Quantity));
                    end;
                end;

                GetSalesHeader();
                if SalesHeader."Currency Code" <> '' then begin
                    Currency.TestField("Unit-Amount Rounding Precision");
                    "Unit Cost" :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                          GetDate(), SalesHeader."Currency Code",
                          "Unit Cost (LCY)", SalesHeader."Currency Factor"),
                        Currency."Unit-Amount Rounding Precision")
                end else
                    "Unit Cost" := "Unit Cost (LCY)";
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
            var
                DropInvoiceDiscountAmount: Boolean;
            begin
                DropInvoiceDiscountAmount := true;
                OnValidateLineDiscountPercentOnBeforeValidateLineDiscountPercent(Rec, xRec, DropInvoiceDiscountAmount);
                ValidateLineDiscountPercent(DropInvoiceDiscountAmount);

                NotifyOnMissingSetup(FieldNo("Line Discount Amount"));
            end;
        }
        field(28; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';

            trigger OnValidate()
            begin
                GetSalesHeader();
                "Line Discount Amount" := Round("Line Discount Amount", Currency."Amount Rounding Precision");
                TestJobPlanningLine();
                TestStatusOpen();
                TestQtyFromLindDiscountAmount();
                if xRec."Line Discount Amount" <> "Line Discount Amount" then
                    UpdateLineDiscPct();
                "Inv. Discount Amount" := 0;
                "Inv. Disc. Amount to Invoice" := 0;
                UpdateAmounts();
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
                Amount := Round(Amount, Currency."Amount Rounding Precision");
                OnValidateAmountOnAfterAssignAmount(Rec, Currency);

                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(SalesHeader) / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Round(Amount + "VAT Base Amount" * GetVATPct() / 100, Currency."Amount Rounding Precision");
                            OnValidateAmountOnAfterCalculateNormalVAT(Rec, SalesHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        if Amount <> 0 then
                            FieldError(Amount,
                              StrSubstNo(
                                Text009, FieldCaption("VAT Calculation Type"),
                                "VAT Calculation Type"));
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            SalesHeader.TestField("VAT Base Discount %", 0);
                            "VAT Base Amount" := Round(Amount, Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              Amount +
                              SalesTaxCalculate.CalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                "VAT Base Amount", "Quantity (Base)", SalesHeader."Currency Factor");
                            OnAfterSalesTaxCalculate(Rec, SalesHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                            "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                        end;
                end;

                InitOutstandingAmount();
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
                "Amount Including VAT" := Round("Amount Including VAT", Currency."Amount Rounding Precision");
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount :=
                              Round(
                                "Amount Including VAT" /
                                (1 + (1 - GetVatBaseDiscountPct(SalesHeader) / 100) * GetVATPct() / 100),
                                Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(SalesHeader) / 100), Currency."Amount Rounding Precision");
                            OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(Rec, SalesHeader, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            SalesHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                "Amount Including VAT", "Quantity (Base)", SalesHeader."Currency Factor");
                            OnAfterSalesTaxCalculateReverse(Rec, SalesHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end;
                OnValidateAmountIncludingVATOnAfterAssignAmounts(Rec, Currency);

                InitOutstandingAmount();
            end;
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
                SelectItemEntry(FieldNo("Appl.-to Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                if "Appl.-to Item Entry" <> 0 then begin
                    CheckReceiptOrderStatus();

                    TestField(Type, Type::Item);
                    TestField(Quantity);
                    CheckQuantitySign();
                    ItemLedgEntry.Get("Appl.-to Item Entry");
                    ItemLedgEntry.TestField(Positive, true);
                    ItemLedgEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-to Item Entry"));
                    if Abs("Qty. to Ship (Base)") > ItemLedgEntry.Quantity then
                        Error(ShippingMoreUnitsThanReceivedErr, ItemLedgEntry.Quantity, ItemLedgEntry."Document No.");

                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));

                    "Location Code" := ItemLedgEntry."Location Code";

                    IsHandled := false;
                    OnApplToItemEntryValidateOnBeforeMessage(Rec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        if not ItemLedgEntry.Open then
                            Message(Text042, "Appl.-to Item Entry");
                end;
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
                ATOLink.UpdateAsmDimFromSalesLine(Rec);
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
                ATOLink.UpdateAsmDimFromSalesLine(Rec);
            end;
        }
        field(42; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            Editable = false;
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    if "Customer Price Group" <> xRec."Customer Price Group" then
                        PlanPriceCalcByField(FieldNo("Customer Price Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Price Group"));
                end;
            end;
        }
        field(45; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project. If you fill in this field and the Project Task No. field, then a project ledger entry will be posted together with the sales line.';
            Editable = false;
            TableRelation = Job;
        }
        field(52; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to when the sale is related to a project.';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                WorkType: Record "Work Type";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWorkTypeCode(xRec, IsHandled, Rec);
                if IsHandled then
                    exit;

                if Type = Type::Resource then begin
                    TestStatusOpen();
                    if WorkType.Get("Work Type Code") then
                        Validate("Unit of Measure Code", WorkType."Unit of Measure Code");
                    if "Work Type Code" <> xRec."Work Type Code" then
                        PlanPriceCalcByField(FieldNo("Work Type Code"));
                    UpdateUnitPriceByField(FieldNo("Work Type Code"));
                    ApplyResUnitCost(FieldNo("Work Type Code"));
                end;
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
                GetSalesHeader();
                Currency2.InitRoundingPrecision();
                if SalesHeader."Currency Code" <> '' then
                    "Outstanding Amount (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Outstanding Amount", SalesHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Outstanding Amount (LCY)" :=
                      Round("Outstanding Amount", Currency2."Amount Rounding Precision");
            end;
        }
        field(58; "Qty. Shipped Not Invoiced"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "Shipped Not Invoiced"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetSalesHeader();
                Currency2.InitRoundingPrecision();
                if SalesHeader."Currency Code" <> '' then
                    "Shipped Not Invoiced (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Shipped Not Invoiced", SalesHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Shipped Not Invoiced (LCY)" :=
                      Round("Shipped Not Invoiced", Currency2."Amount Rounding Precision");

                CalculateNotShippedInvExlcVatLCY();
            end;
        }
        field(60; "Quantity Shipped"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Quantity Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Quantity Invoiced"; Decimal)
        {
            Caption = 'Quantity Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(63; "Shipment No."; Code[20])
        {
            Caption = 'Shipment No.';
            Editable = false;
        }
        field(64; "Shipment Line No."; Integer)
        {
            Caption = 'Shipment Line No.';
            Editable = false;
        }
        field(67; "Profit %"; Decimal)
        {
            Caption = 'Profit %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(68; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            Editable = false;
            TableRelation = Customer;
        }
        field(69; "Inv. Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CaptionClass = GetCaptionClass(FieldNo("Inv. Discount Amount"));
            Caption = 'Inv. Discount Amount';
            Editable = false;

            trigger OnValidate()
            begin
                CalcInvDiscToInvoice();
                UpdateAmounts();
            end;
        }
        field(71; "Purchase Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Purchase Order No.';
            Editable = false;
            TableRelation = if ("Drop Shipment" = const(true)) "Purchase Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                if (xRec."Purchase Order No." <> "Purchase Order No.") and (Quantity <> 0) then begin
                    VerifyChangeForSalesLineReserve(FieldNo("Purchase Order No."));
                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(72; "Purch. Order Line No."; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Purch. Order Line No.';
            Editable = false;
            TableRelation = if ("Drop Shipment" = const(true)) "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                                                               "Document No." = field("Purchase Order No."));

            trigger OnValidate()
            begin
                if (xRec."Purch. Order Line No." <> "Purch. Order Line No.") and (Quantity <> 0) then begin
                    VerifyChangeForSalesLineReserve(FieldNo("Purch. Order Line No."));
                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(73; "Drop Shipment"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Drop Shipment';
            Editable = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDropShipment(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Document Type", "Document Type"::Order);
                TestField(Type, Type::Item);
                TestField("Quantity Shipped", 0);

                IsHandled := false;
                OnValidateDropShipmentOnBeforeTestJobNo(Rec, IsHandled, CurrFieldNo);
                if not IsHandled then
                    TestField("Job No.", '');
                TestField("Qty. to Asm. to Order (Base)", 0);

                if "Drop Shipment" then
                    TestField("Special Order", false);

                CheckAssocPurchOrder(FieldCaption("Drop Shipment"));

                if "Special Order" then
                    Reserve := Reserve::Never
                else
                    if "Drop Shipment" then begin
                        Reserve := Reserve::Never;
                        Evaluate("Outbound Whse. Handling Time", '<0D>');
                        Evaluate("Shipping Time", '<0D>');
                        UpdateDates();
                        "Bin Code" := '';
                    end else
                        SetReserveWithoutPurchasingCode();

                CheckItemAvailable(FieldNo("Drop Shipment"));

                CheckReceiptOrderStatus();

                if (xRec."Drop Shipment" <> "Drop Shipment") and (Quantity <> 0) then begin
                    if not "Drop Shipment" then begin
                        InitQtyToAsm();
                        Rec.AutoAsmToOrder();
                        UpdateWithWarehouseShip();
                    end else
                        InitQtyToShip();
                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                    if not FullReservedQtyIsForAsmToOrder() then
                        VerifyChangeForSalesLineReserve(FieldNo("Drop Shipment"));
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
                OnGenProdPostingGroupOnBeforeValidate(Rec, xRec, GenProdPostingGrp, IsHandled);
                if not IsHandled then begin
                    TestJobPlanningLine();
                    TestStatusOpen();
                    if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                        if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                            Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
                end;
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
            TableRelation = "Sales Line"."Line No." where("Document Type" = field("Document Type"),
                                                           "Document No." = field("Document No."));
        }
        field(81; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
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
        field(84; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
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
                ValidateTaxGroupCode();
                UpdateAmounts();
            end;
        }
        field(88; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            TableRelation = "VAT Clause";
        }
        field(89; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                ValidateVATProdPostingGroup();
            end;
        }
        field(90; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATProdPostingGroupTrigger(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                CheckPrepmtAmtInvEmpty();

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeVATPostingSetupGet(Rec, xRec, IsHandled, VATPostingSetup);
                if not IsHandled then
                    VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group");
                ClearVATDifference();

                GetSalesHeader();
                CopyFromVATPostingSetup(VATPostingSetup);

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(Rec, VATPostingSetup, IsHandled);
                if not IsHandled then
                    case "VAT Calculation Type" of
                        "VAT Calculation Type"::"Reverse Charge VAT",
                        "VAT Calculation Type"::"Sales Tax":
                            ClearVATPct();
                        "VAT Calculation Type"::"Full VAT":
                            begin
                                TestField(Type, Type::"G/L Account");
                                TestField("No.", VATPostingSetup.GetSalesAccount(false));
                            end;
                    end;

                IsHandled := false;
                OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(Rec, VATPostingSetup, IsHandled, xRec, SalesHeader, Currency);
                if not IsHandled then
                    if SalesHeader."Prices Including VAT" and (Type in [Type::Item, Type::Resource]) then
                        Validate("Unit Price",
                            Round(
                                "Unit Price" * (100 + GetVATPct()) / (100 + xRec.GetVATPct()),
                        Currency."Unit-Amount Rounding Precision"));

                OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(Rec, xRec, SalesHeader, Currency);
                UpdateAmounts();
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
            Editable = false;
        }
        field(93; "Shipped Not Invoiced (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Shipped Not Invoiced (LCY) Incl. VAT';
            Editable = false;
        }
        field(94; "Shipped Not Inv. (LCY) No VAT"; Decimal)
        {
            Caption = 'Shipped Not Invoiced (LCY)';
            Editable = false;
            FieldClass = Normal;
        }
        field(95; "Reserved Quantity"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Document No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(37),
#pragma warning disable AL0603
                                                                   "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
            ToolTip = 'Specifies whether a reservation can be made for items on this line.';

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Reserve <> Reserve::Never then begin
                    TestField(Type, Type::Item);
                    TestField("No.");
                    GetItem(Item);
                    if IsNonInventoriableItem() then
                        Error(NonInvReserveTypeErr, Item."No.", Reserve);
                end;

                CalcFields("Reserved Qty. (Base)");
                if (Reserve = Reserve::Never) and ("Reserved Qty. (Base)" > 0) then
                    TestField("Reserved Qty. (Base)", 0);

                if "Drop Shipment" or "Special Order" then
                    TestField(Reserve, Reserve::Never);
                if xRec.Reserve = Reserve::Always then begin
                    GetItem(Item);
                    if Item.Reserve = Item.Reserve::Always then
                        TestField(Reserve, Reserve::Always);
                end;
            end;
        }
        field(97; "Blanket Order No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Blanket Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const("Blanket Order"));

            trigger OnLookup()
            begin
                BlanketOrderLookup();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBlanketOrderNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Quantity Shipped", 0);
                if "Blanket Order No." = '' then
                    "Blanket Order Line No." := 0
                else
                    Validate("Blanket Order Line No.");
            end;
        }
        field(98; "Blanket Order Line No."; Integer)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Blanket Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const("Blanket Order"),
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
                OnBeforeValidateBlanketOrderLineNo(IsHandled, Rec);
                if IsHandled then
                    exit;

                TestField("Quantity Shipped", 0);
                if "Blanket Order Line No." <> 0 then begin
                    SalesLine2.Get("Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.");
                    SalesLine2.TestField(Type, Type);
                    SalesLine2.TestField("No.", "No.");
                    SalesLine2.TestField("Bill-to Customer No.", "Bill-to Customer No.");
                    SalesLine2.TestField("Sell-to Customer No.", "Sell-to Customer No.");
                    if "Drop Shipment" or "Special Order" then begin
                        SalesLine2.TestField("Variant Code", "Variant Code");
                        SalesLine2.TestField("Location Code", "Location Code");
                        SalesLine2.TestField("Unit of Measure Code", "Unit of Measure Code");
                    end else begin
                        Validate("Variant Code", SalesLine2."Variant Code");
                        Validate("Location Code", SalesLine2."Location Code");
                        Validate("Unit of Measure Code", SalesLine2."Unit of Measure Code");
                    end;
                    Validate("Unit Price", SalesLine2."Unit Price");
                    Validate("Line Discount %", SalesLine2."Line Discount %");

                    OnAfterValidateBlanketOrderLineNo(Rec, SalesLine2);
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
                IsHandled := false;
                OnValidateLineAmountOnbeforeTestUnitPrice(Rec, IsHandled, CurrFieldNo);
                if not IsHandled then
                    TestField("Unit Price");

                GetSalesHeader();

                "Line Amount" := Round("Line Amount", Currency."Amount Rounding Precision");
                MaxLineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision");
                CheckLineAmount(MaxLineAmount);

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
                        else
                            OnLookUpICPartnerReferenceTypeCaseElse();
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
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnValidatePrepaymentPercentageOnBeforeUpdatePrepmtSetupFields(Rec, IsHandled);
                if IsHandled then
                    exit;

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
                OnBeforeValidatePrepmtLineAmount(Rec, PrePaymentLineAmountEntered, IsHandled, CurrFieldNo);
                if IsHandled then
                    exit;

                TestStatusOpen();
                PrePaymentLineAmountEntered := true;
                TestField("Line Amount");
                if "Prepmt. Line Amount" < "Prepmt. Amt. Inv." then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text044, "Prepmt. Amt. Inv."));
                if "Prepmt. Line Amount" > "Line Amount" then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045, "Line Amount"));
                if "System-Created Entry" and not IsServiceChargeLine() then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045, 0));
                Validate("Prepayment %", "Prepmt. Line Amount" * 100 / Round(CalculateOutstandingAmountExclTax(), Currency."Amount Rounding Precision"));
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
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtAmttoDeduct(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Prepmt Amt to Deduct" > "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text045, "Prepmt. Amt. Inv." - "Prepmt Amt Deducted"));

                if "Prepmt Amt to Deduct" > "Qty. to Invoice" * "Unit Price" then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text045, "Qty. to Invoice" * "Unit Price"));

                if ("Prepmt. Amt. Inv." - "Prepmt Amt to Deduct" - "Prepmt Amt Deducted") >
                   (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Unit Price"
                then
                    FieldError(
                      "Prepmt Amt to Deduct",
                      StrSubstNo(Text044,
                        "Prepmt. Amt. Inv." - "Prepmt Amt Deducted" - (Quantity - "Qty. to Invoice" - "Quantity Invoiced") * "Unit Price"));
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
                    GetSalesHeader();
                    SalesHeader.TestField("Sell-to IC Partner Code", '');
                    SalesHeader.TestField("Bill-to IC Partner Code", '');
                    Validate("IC Partner Ref. Type", "IC Partner Ref. Type"::"G/L Account");
                end;
            end;
        }
        field(132; "Prepmt. VAT Amount Inv. (LCY)"; Decimal)
        {
            Caption = 'Prepmt. VAT Amount Inv. (LCY)';
            Editable = false;
            AutoFormatType = 1;
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
            begin
                if "No." <> '' then
                    case "IC Partner Ref. Type" of
                        "IC Partner Ref. Type"::"Cross Reference":
                            begin
                                ItemReference.Reset();
                                ItemReference.SetCurrentKey("Reference Type", "Reference Type No.");
                                ItemReference.SetFilter("Reference Type", '%1|%2', "Item Reference Type"::Customer, "Item Reference Type"::" ");
                                ItemReference.SetFilter("Reference Type No.", '%1|%2', "Sell-to Customer No.", '');
                                if PAGE.RunModal(PAGE::"Item Reference List", ItemReference) = ACTION::LookupOK then
                                    Validate("IC Item Reference No.", ItemReference."Reference No.");
                            end;
                    end;
            end;
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
        field(180; "Line Discount Calculation"; Option)
        {
            Caption = 'Line Discount Calculation';
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
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
        field(900; "Qty. to Assemble to Order"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Qty. to Assemble to Order';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                SalesLineReserve: Codeunit "Sales Line-Reserve";
                IsHandled: Boolean;
            begin
                "Qty. to Assemble to Order" := UOMMgt.RoundAndValidateQty("Qty. to Assemble to Order", "Qty. Rounding Precision", FieldCaption("Qty. to Assemble to Order"));
                IsHandled := false;
                OnValidateQuantityOnBeforeSalesLineVerifyChange(Rec, StatusCheckSuspended, IsHandled);
                if not IsHandled then
                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);

                "Qty. to Asm. to Order (Base)" := CalcBaseQty("Qty. to Assemble to Order", FieldCaption("Qty. to Assemble to Order"), FieldCaption("Qty. to Asm. to Order (Base)"));
                if Rec."Qty. to Asm. to Order (Base)" <> 0 then begin
                    TestField("Drop Shipment", false);
                    TestField("Special Order", false);
                    if "Qty. to Asm. to Order (Base)" < 0 then
                        FieldError("Qty. to Assemble to Order", StrSubstNo(Text009, FieldCaption("Quantity (Base)"), "Quantity (Base)"));
                    TestField("Appl.-to Item Entry", 0);

                    case "Document Type" of
                        "Document Type"::"Blanket Order",
                      "Document Type"::Quote:
                            if ("Quantity (Base)" = 0) or ("Qty. to Asm. to Order (Base)" <= 0) or SalesLineReserve.ReservEntryExist(Rec) then
                                TestField("Qty. to Asm. to Order (Base)", 0)
                            else
                                if "Quantity (Base)" <> "Qty. to Asm. to Order (Base)" then
                                    FieldError("Qty. to Assemble to Order", StrSubstNo(Text031, 0, "Quantity (Base)"));
                        "Document Type"::Order:
                            ;
                        else begin
                            IsHandled := false;
                            OnValidateQtyToAssembleToOrderOnOtherDocTypeBeforeTestField(Rec, IsHandled);
                            if not IsHandled then
                                TestField("Qty. to Asm. to Order (Base)", 0);
                        end;
                    end;
                end;

                CheckItemAvailable(FieldNo("Qty. to Assemble to Order"));
                if not (CurrFieldNo in [FieldNo(Quantity), FieldNo("Qty. to Assemble to Order")]) then
                    GetDefaultBin();

                IsHandled := false;
                OnValidateQtyToAssembleToOrderOnBeforeAutoAsmToOrder(Rec, IsHandled);
                if not IsHandled then
                    Rec.AutoAsmToOrder();
            end;
        }
        field(901; "Qty. to Asm. to Order (Base)"; Decimal)
        {
            Caption = 'Qty. to Asm. to Order (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtytoAsmtoOrderBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Assemble to Order", "Qty. to Asm. to Order (Base)");
            end;
        }
        field(902; "ATO Whse. Outstanding Qty."; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding" where("Source Type" = const(37),
#pragma warning disable AL0603
                                                                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                  "Source No." = field("Document No."),
                                                                                  "Source Line No." = field("Line No."),
                                                                                  "Assemble to Order" = filter(true)));
            Caption = 'ATO Whse. Outstanding Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(903; "ATO Whse. Outstd. Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData "BOM Component" = R;
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Source Type" = const(37),
#pragma warning disable AL0603
                                                                                         "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                         "Source No." = field("Document No."),
                                                                                         "Source Line No." = field("Line No."),
                                                                                         "Assemble to Order" = filter(true)));
            Caption = 'ATO Whse. Outstd. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(1001; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1002; "Job Contract Entry No."; Integer)
        {
            AccessByPermission = TableData Job = R;
            Caption = 'Project Contract Entry No.';
            Editable = false;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                IsHandled: Boolean;
                DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
            begin
                IsHandled := false;
                OnBeforeValidateJobContractEntryNo(xRec, IsHandled);
                if IsHandled then
                    exit;

                JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                JobPlanningLine.SetRange("Job Contract Entry No.", "Job Contract Entry No.");
                JobPlanningLine.FindFirst();
                InitDefaultDimensionSources(DefaultDimSource, JobPlanningLine."Job No.", Rec.FieldNo("Job Contract Entry No."));
                CreateDim(DefaultDimSource);
            end;
        }
        field(1300; "Posting Date"; Date)
        {
            CalcFormula = lookup("Sales Header"."Posting Date" where("Document Type" = field("Document Type"),
                                                                      "No." = field("Document No.")));
            Caption = 'Posting Date';
            FieldClass = FlowField;
        }
        field(1700; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            var
                DeferralPostDate: Date;
            begin
                GetSalesHeader();
                OnGetDeferralPostDate(SalesHeader, DeferralPostDate, Rec);
                if DeferralPostDate = 0D then
                    DeferralPostDate := SalesHeader."Posting Date";

                DeferralUtilities.DeferralCodeOnValidate(
                    "Deferral Code", Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                    "Document Type".AsInteger(), "Document No.", "Line No.",
                    GetDeferralAmount(), DeferralPostDate,
                    Description, SalesHeader."Currency Code");

                if "Document Type" = "Document Type"::"Return Order" then
                    "Returns Deferral Start Date" :=
                        DeferralUtilities.GetDeferralStartDate(
                            Enum::"Deferral Document Type"::Sales.AsInteger(), "Document Type".AsInteger(),
                            "Document No.", "Line No.", "Deferral Code", SalesHeader."Posting Date");
            end;
        }
        field(1702; "Returns Deferral Start Date"; Date)
        {
            Caption = 'Returns Deferral Start Date';

            trigger OnValidate()
            var
                DeferralHeader: Record "Deferral Header";
            begin
                GetSalesHeader();
                if DeferralHeader.Get(Enum::"Deferral Document Type"::Sales, '', '', "Document Type", "Document No.", "Line No.") then
                    DeferralUtilities.CreateDeferralSchedule(
                        "Deferral Code", Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                        "Document Type".AsInteger(), "Document No.", "Line No.", GetDeferralAmount(),
                        DeferralHeader."Calc. Method", "Returns Deferral Start Date",
                        DeferralHeader."No. of Periods", true,
                        DeferralHeader."Schedule Description", false,
                        SalesHeader."Currency Code");
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
            CalcFormula = exist("Alloc. Acc. Manual Override" where("Parent System Id" = field(SystemId), "Parent Table Id" = const(Database::"Sales Line")));
        }
        field(2678; "Allocation Account No."; Code[20])
        {
            Caption = 'Posting Allocation Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Allocation Account";
        }
        field(2679; "Alloc. Sales Line SystemId"; Guid)
        {
            Caption = 'Allocation Sales Line SystemId';
            DataClassification = SystemMetadata;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item), "Document Type" = filter(<> "Credit Memo" & <> "Return Order")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false), "Sales Blocked" = const(false))
            else
            if (Type = const(Item), "Document Type" = filter("Credit Memo" | "Return Order")) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                TestJobPlanningLine();
                if "Variant Code" <> '' then begin
                    Rec.TestField(Type, Rec.Type::Item);

                    IsHandled := false;
                    OnValidateVariantCodeBeforeCheckBlocked(Rec, IsHandled);
                    if not IsHandled then begin
                        ItemVariant.SetLoadFields("Sales Blocked");
                        ItemVariant.Get(Rec."No.", Rec."Variant Code");
                        if ItemVariant."Sales Blocked" then
                            if IsCreditDocType() then
                                SendBlockedItemVariantNotification();
                    end;
                end;
                TestStatusOpen();
                CheckAssocPurchOrder(FieldCaption("Variant Code"));

                if xRec."Variant Code" <> "Variant Code" then begin
                    TestField("Qty. Shipped Not Invoiced", 0);
                    TestField("Shipment No.", '');

                    TestField("Return Qty. Rcd. Not Invd.", 0);
                    TestField("Return Receipt No.", '');

                    InitItemAppl(false);
                end;

                OnValidateVariantCodeOnAfterChecks(Rec, xRec, CurrFieldNo);

                CheckItemAvailable(FieldNo("Variant Code"));

                if Type = Type::Item then begin
                    GetUnitCost();
                    if "Document Type" = "Document Type"::"Return Order" then
                        ValidateReturnReasonCode(FieldNo("Variant Code"));
                    if "Variant Code" <> xRec."Variant Code" then
                        PlanPriceCalcByField(FieldNo("Variant Code"));
                end;

                GetDefaultBin();
                InitQtyToAsm();
                Rec.AutoAsmToOrder();
                if (xRec."Variant Code" <> "Variant Code") and (Quantity <> 0) then begin
                    if not FullReservedQtyIsForAsmToOrder() then
                        VerifyChangeForSalesLineReserve(FieldNo("Variant Code"));
                    SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                end;

                UpdateItemReference(FieldNo("Variant Code"));

                UpdateUnitPriceByField(FieldNo("Variant Code"));
            end;
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Document Type" = filter(Order | Invoice),
                                Quantity = filter(>= 0),
                                "Qty. to Asm. to Order (Base)" = const(0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                         "Item No." = field("No."),
                                                                                                         "Variant Code" = field("Variant Code"))
            else
            if ("Document Type" = filter("Return Order" | "Credit Memo"),
                                                                                                                  Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                       "Item No." = field("No."),
                                                                                                                                                                       "Variant Code" = field("Variant Code"))
            else
            Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
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
                IsHandled: Boolean;
            begin
                if "Bin Code" <> '' then
                    CheckBinCodeRelation();

                if "Drop Shipment" then
                    CheckAssocPurchOrder(FieldCaption("Bin Code"));

                IsHandled := false;
                OnValidateBinCodeOnBeforeTestFields(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Type, Type::Item);
                TestField("Location Code");

                GetItem(Item);
                Item.TestField(Type, Item.Type::Inventory);

                if (Type = Type::Item) and ("Bin Code" <> '') then begin
                    TestField("Drop Shipment", false);
                    GetLocation("Location Code");
                    Location.TestField("Bin Mandatory");
                    CheckWarehouse(true);
                end;
                ATOLink.UpdateAsmBinCodeFromSalesLine(Rec);
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5405; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5406; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5408; "Qty. Rounding Precision (Base)"; Decimal)
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
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item),
                                "No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource),
                                         "No." = filter(<> '')) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            if (Type = filter("Charge (Item)" | "Fixed Asset" | "G/L Account")) "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                UnitOfMeasureTranslation: Record "Unit of Measure Translation";
                ShouldPlanPriceCalc: Boolean;
            begin
                TestJobPlanningLine();
                TestStatusOpen();
                TestQuantityFieldsOnValidateUnitOfMeasure();
                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then begin
                    TestField("Shipment No.", '');
                    TestField("Return Receipt No.", '');
                end;

                CheckAssocPurchOrder(FieldCaption("Unit of Measure Code"));

                if "Unit of Measure Code" = '' then
                    "Unit of Measure" := ''
                else begin
                    OnValidateUnitOfMeasureCodeOnBeforeGetUnitOfMeasure(Rec, xRec, SalesHeader, CurrFieldNo);
                    if not UnitOfMeasure.Get("Unit of Measure Code") then
                        UnitOfMeasure.Init();
                    "Unit of Measure" := UnitOfMeasure.Description;
                    GetSalesHeader();
                    if SalesHeader."Language Code" <> '' then begin
                        UnitOfMeasureTranslation.SetRange(Code, "Unit of Measure Code");
                        UnitOfMeasureTranslation.SetRange("Language Code", SalesHeader."Language Code");
                        if UnitOfMeasureTranslation.FindFirst() then
                            "Unit of Measure" := UnitOfMeasureTranslation.Description;
                    end;
                end;
                OnValidateUnitOfMeasureCodeOnAfterGetUnitOfMeasure(Rec, SalesHeader);

                ItemReferenceMgt.EnterSalesItemReference(Rec);
                OnValidateUnitOfMeasureCodeOnAfterEnterSalesItemReference(Rec);

                case Type of
                    Type::Item:
                        begin
                            GetItem(Item);
                            GetUnitCost();
                            ShouldPlanPriceCalc := "Unit of Measure Code" <> xRec."Unit of Measure Code";
                            OnValidateUnitOfMeasureCodeOnAfterCalcShouldPlanPriceCalc(Rec, ShouldPlanPriceCalc);
                            if ShouldPlanPriceCalc then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            CheckItemAvailable(FieldNo("Unit of Measure Code"));
                            "Gross Weight" := Item."Gross Weight" * "Qty. per Unit of Measure";
                            "Net Weight" := Item."Net Weight" * "Qty. per Unit of Measure";
                            "Unit Volume" := Item."Unit Volume" * "Qty. per Unit of Measure";
                            "Units per Parcel" :=
                              Round(Item."Units per Parcel" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                            "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                            "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                            OnAfterAssignItemUOM(Rec, Item, CurrFieldNo, xRec);
                            if (xRec."Unit of Measure Code" <> "Unit of Measure Code") and (Quantity <> 0) then
                                SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
                            if "Qty. per Unit of Measure" > xRec."Qty. per Unit of Measure" then
                                InitItemAppl(false);
                            OnValidateUnitOfMeasureCodeOnAfterGetItemData(Rec, xRec, Item);
                        end;
                    Type::Resource:
                        begin
                            if "Unit of Measure Code" = '' then begin
                                GetResource();
                                "Unit of Measure Code" := Resource."Base Unit of Measure";
                            end;
                            AssignResourceUoM();
                            if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                                PlanPriceCalcByField(FieldNo("Unit of Measure Code"));
                            ApplyResUnitCost(FieldNo("Unit of Measure Code"));
                        end;
                    Type::"G/L Account", Type::"Fixed Asset",
                    Type::"Charge (Item)", Type::" ":
                        "Qty. per Unit of Measure" := 1;
                end;
                UpdateQuantityFromUOMCode();
                UpdateUnitPriceByField(FieldNo("Unit of Measure Code"));
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

                TestJobPlanningLine();
                TestField("Qty. per Unit of Measure", 1);
                if "Quantity (Base)" <> xRec."Quantity (Base)" then
                    PlanPriceCalcByField(FieldNo("Quantity (Base)"));
                Validate(Quantity, "Quantity (Base)");
                UpdateUnitPriceByField(FieldNo("Quantity (Base)"));
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
        field(5418; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtytoShipBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Ship", "Qty. to Ship (Base)");
            end;
        }
        field(5458; "Qty. Shipped Not Invd. (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped Not Invd. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5460; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
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
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Document No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(37),
#pragma warning disable AL0603
                                                                            "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            ToolTip = 'Specifies the value in the Reserved Quantity field, expressed in the base unit of measure.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5600; "FA Posting Date"; Date)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Date';
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
        field(5605; "Depr. until FA Posting Date"; Boolean)
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'Depr. until FA Posting Date';
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
        field(5701; "Out-of-Stock Substitution"; Boolean)
        {
            Caption = 'Out-of-Stock Substitution';
            Editable = false;
        }
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "No." = field("No."),
                                                           "Substitute Type" = const(Item)));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5703; "Originally Ordered No."; Code[20])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered No.';
            TableRelation = if (Type = const(Item)) Item;
        }
        field(5704; "Originally Ordered Var. Code"; Code[10])
        {
            AccessByPermission = TableData "Item Substitution" = R;
            Caption = 'Originally Ordered Var. Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("Originally Ordered No."));
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
            Editable = false;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Purchasing Code';
            TableRelation = Purchasing;

            trigger OnValidate()
            var
                PurchasingCode: Record Purchasing;
                IsHandled: Boolean;
                ShouldAssignValuesFromPurchasingCode: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePurchasingCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField(Type, Type::Item);
                CheckAssocPurchOrder(FieldCaption("Purchasing Code"));

                ShouldAssignValuesFromPurchasingCode := PurchasingCode.Get("Purchasing Code");
                OnValidatePurchasingCodeOnAfterCalcShouldAssignValuesFromPurchasingCode(Rec, ShouldAssignValuesFromPurchasingCode);
                if ShouldAssignValuesFromPurchasingCode then begin
                    "Drop Shipment" := PurchasingCode."Drop Shipment";
                    "Special Order" := PurchasingCode."Special Order";
                    IsHandled := false;
                    OnValidatePurchasingCodeOnAfterAssignPurchasingFields(Rec, PurchasingCode, IsHandled);
                    if not IsHandled then
                        if "Drop Shipment" or "Special Order" then begin
                            TestField("Qty. to Asm. to Order (Base)", 0);
                            CalcFields("Reserved Qty. (Base)");
                            TestField("Reserved Qty. (Base)", 0);
                            VerifyChangeForSalesLineReserve(FieldNo("Purchasing Code"));

                            if (Quantity <> 0) and (Quantity = "Quantity Shipped") then
                                Error(SalesLineCompletelyShippedErr);
                            Reserve := Reserve::Never;
                            if "Drop Shipment" then begin
                                Evaluate("Outbound Whse. Handling Time", '<0D>');
                                Evaluate("Shipping Time", '<0D>');
                                UpdateDates();
                                "Bin Code" := '';
                            end;
                        end else
                            SetReserveWithoutPurchasingCode();
                end else begin
                    "Drop Shipment" := false;
                    "Special Order" := false;
                    OnValidatePurchasingCodeOnAfterResetPurchasingFields(Rec, xRec);
                    SetReserveWithoutPurchasingCode();
                end;

                OnValidatePurchasingCodeOnAfterSetReserveWithoutPurchasingCode(Rec, CurrFieldNo, xRec);

                if ("Purchasing Code" <> xRec."Purchasing Code") and
                   (not "Drop Shipment") and
                   ("Drop Shipment" <> xRec."Drop Shipment")
                then begin
                    if "Location Code" = '' then begin
                        if InvtSetup.Get() then
                            "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
                    end else
                        if Location.Get("Location Code") then
                            "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                    GetShippingTime();
                    UpdateDates();
                end;
            end;
        }
        field(5713; "Special Order"; Boolean)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order';
            Editable = false;
        }
        field(5714; "Special Order Purchase No."; Code[20])
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Purchase No.';
            TableRelation = if ("Special Order" = const(true)) "Purchase Header"."No." where("Document Type" = const(Order));
        }
        field(5715; "Special Order Purch. Line No."; Integer)
        {
            AccessByPermission = TableData "Drop Shpt. Post. Buffer" = R;
            Caption = 'Special Order Purch. Line No.';
            TableRelation = if ("Special Order" = const(true)) "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                                                               "Document No." = field("Special Order Purchase No."));
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                GetSalesHeader();
                ItemReferenceMgt.SalesReferenceNoLookUp(Rec, SalesHeader);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                GetSalesHeader();
                "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                ItemReferenceMgt.ValidateSalesReferenceNo(Rec, SalesHeader, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Reference Unit of Measure';
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
        field(5749; "Whse. Outstanding Qty."; Decimal)
        {
            AccessByPermission = TableData Location = R;
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding" where("Source Type" = const(37),
#pragma warning disable AL0603
                                                                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                  "Source No." = field("Document No."),
                                                                                  "Source Line No." = field("Line No.")));
            Caption = 'Whse. Outstanding Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5750; "Whse. Outstanding Qty. (Base)"; Decimal)
        {
            AccessByPermission = TableData Location = R;
            BlankZero = true;
            CalcFormula = sum("Warehouse Shipment Line"."Qty. Outstanding (Base)" where("Source Type" = const(37),
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
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            Editable = false;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateRequestedDeliveryDate(Rec, IsHandled);
                if IsHandled then
                    exit;

                CheckPromisedDeliveryDate();

                if "Requested Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", CalcPlannedDeliveryDate(FieldNo("Requested Delivery Date")))
                else begin
                    GetSalesHeader();
                    Validate("Shipment Date", SalesHeader."Shipment Date");
                end;
            end;
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Promised Delivery Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidatePromisedDeliveryDate(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Promised Delivery Date" <> 0D then
                    Validate("Planned Delivery Date", "Promised Delivery Date")
                else
                    Validate("Requested Delivery Date");
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Drop Shipment" then
                    DateFormularZero("Shipping Time", FieldNo("Shipping Time"), FieldCaption("Shipping Time"));
                UpdateDates();
            end;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Drop Shipment" then
                    DateFormularZero("Outbound Whse. Handling Time",
                      FieldNo("Outbound Whse. Handling Time"), FieldCaption("Outbound Whse. Handling Time"));
                UpdateDates();
            end;
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlannedDeliveryDate(IsHandled, Rec);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Planned Delivery Date" <> 0D then begin
                    PlannedDeliveryDateCalculated := true;

                    Validate("Planned Shipment Date", CalcPlannedDate());

                    if "Planned Shipment Date" > "Planned Delivery Date" then
                        "Planned Delivery Date" := "Planned Shipment Date";
                end;
            end;
        }
        field(5795; "Planned Shipment Date"; Date)
        {
            AccessByPermission = TableData "Order Promising Line" = R;
            Caption = 'Planned Shipment Date';

            trigger OnValidate()
            var
                IsHandled: boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePlannedShipmentDate(IsHandled, Rec);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Planned Shipment Date" <> 0D then begin
                    PlannedShipmentDateCalculated := true;

                    Validate("Shipment Date", CalcShipmentDate());
                end;
            end;
        }
        field(5796; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(5797; "Shipping Agent Service Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentServiceCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                GetShippingTime();

                if "Shipping Time" <> xRec."Shipping Time" then
                    Validate("Shipping Time");
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
            CalcFormula = sum("Item Charge Assignment (Sales)"."Qty. to Assign" where("Document Type" = field("Document Type"),
                                                                                       "Document No." = field("Document No."),
                                                                                       "Document Line No." = field("Line No.")));
            Caption = 'Qty. to Assign';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5802; "Qty. Assigned"; Decimal)
        {
            CalcFormula = sum("Item Charge Assignment (Sales)"."Qty. Assigned" where("Document Type" = field("Document Type"),
                                                                                      "Document No." = field("Document No."),
                                                                                      "Document Line No." = field("Line No.")));
            Caption = 'Qty. Assigned';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5803; "Return Qty. to Receive"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Qty. to Receive';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                IsHandled: Boolean;
            begin
                if (CurrFieldNo <> 0) and
                   (Type = Type::Item) and
                   ("Return Qty. to Receive" <> 0) and
                   (not "Drop Shipment")
                then
                    CheckWarehouse(true);

                "Return Qty. to Receive" := UOMMgt.RoundAndValidateQty("Return Qty. to Receive", "Qty. Rounding Precision", FieldCaption("Return Qty. to Receive"));

                OnValidateReturnQtyToReceiveOnAfterCheck(Rec, CurrFieldNo);

                if "Return Qty. to Receive" = Quantity - "Return Qty. Received" then
                    InitQtyToReceive()
                else begin
                    "Return Qty. to Receive (Base)" := CalcBaseQty("Return Qty. to Receive", FieldCaption("Return Qty. to Receive"), FieldCaption("Return Qty. to Receive (Base)"));
                    if ("Quantity (Base)" = ("Return Qty. Received (Base)" + "Return Qty. to Receive (Base)")) and ("Return Qty. to Receive" > 0) then
                        Error(QuantityImbalanceErr, ItemUOMForCaption.FieldCaption("Qty. Rounding Precision"), Type::Item, "No.", FieldCaption("Return Qty. to Receive"), FieldCaption("Return Qty. to Receive (Base)"));

                    InitQtyToInvoice();
                end;

                IsHandled := false;
                OnValidateQtyToReturnAfterInitQty(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    if ("Return Qty. to Receive" * Quantity < 0) or
                       (Abs("Return Qty. to Receive") > Abs("Outstanding Quantity")) or
                       (Quantity * "Outstanding Quantity" < 0)
                    then
                        Error(Text020, "Outstanding Quantity");
                    if ("Return Qty. to Receive (Base)" * "Quantity (Base)" < 0) or
                       (Abs("Return Qty. to Receive (Base)") > Abs("Outstanding Qty. (Base)")) or
                       ("Quantity (Base)" * "Outstanding Qty. (Base)" < 0)
                    then
                        Error(Text021, "Outstanding Qty. (Base)");
                end;

                if (CurrFieldNo <> 0) and (Type = Type::Item) and ("Return Qty. to Receive" > 0) then
                    CheckApplFromItemLedgEntry(ItemLedgEntry);
            end;
        }
        field(5804; "Return Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Return Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReturnQtytoReceiveBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Return Qty. to Receive", "Return Qty. to Receive (Base)");
            end;
        }
        field(5805; "Return Qty. Rcd. Not Invd."; Decimal)
        {
            Caption = 'Return Qty. Rcd. Not Invd.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5806; "Ret. Qty. Rcd. Not Invd.(Base)"; Decimal)
        {
            Caption = 'Ret. Qty. Rcd. Not Invd.(Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5807; "Return Rcd. Not Invd."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Return Rcd. Not Invd.';
            Editable = false;

            trigger OnValidate()
            var
                Currency2: Record Currency;
            begin
                GetSalesHeader();
                Currency2.InitRoundingPrecision();
                if SalesHeader."Currency Code" <> '' then
                    "Return Rcd. Not Invd. (LCY)" :=
                      Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          GetDate(), "Currency Code",
                          "Return Rcd. Not Invd.", SalesHeader."Currency Factor"),
                        Currency2."Amount Rounding Precision")
                else
                    "Return Rcd. Not Invd. (LCY)" :=
                      Round("Return Rcd. Not Invd.", Currency2."Amount Rounding Precision");
            end;
        }
        field(5808; "Return Rcd. Not Invd. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Return Rcd. Not Invd. (LCY)';
            Editable = false;
        }
        field(5809; "Return Qty. Received"; Decimal)
        {
            AccessByPermission = TableData "Return Receipt Header" = R;
            Caption = 'Return Qty. Received';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5810; "Return Qty. Received (Base)"; Decimal)
        {
            Caption = 'Return Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5811; "Appl.-from Item Entry"; Integer)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Appl.-from Item Entry';
            MinValue = 0;

            trigger OnLookup()
            begin
                SelectItemEntry(FieldNo("Appl.-from Item Entry"));
            end;

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                if "Appl.-from Item Entry" <> 0 then begin
                    CheckApplFromItemLedgEntry(ItemLedgEntry);
                    Validate("Unit Cost (LCY)", CalcUnitCost(ItemLedgEntry));
                end;
            end;
        }
        field(5812; "Item Charge Qty. to Handle"; Decimal)
        {
            CalcFormula = sum("Item Charge Assignment (Sales)"."Qty. to Handle" where("Document Type" = field("Document Type"),
                                                                                       "Document No." = field("Document No."),
                                                                                       "Document Line No." = field("Line No.")));
            Caption = 'Item Charge Qty. to Handle';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5909; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
        }
        field(6600; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
            Editable = false;
        }
        field(6601; "Return Receipt Line No."; Integer)
        {
            Caption = 'Return Receipt Line No.';
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
        field(6610; "Copied From Posted Doc."; Boolean)
        {
            Caption = 'Copied From Posted Doc.';
            DataClassification = SystemMetadata;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
        }
        field(7002; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                if Type = Type::Item then begin
                    if "Customer Disc. Group" <> xRec."Customer Disc. Group" then
                        PlanPriceCalcByField(FieldNo("Customer Disc. Group"));
                    UpdateUnitPriceByField(FieldNo("Customer Disc. Group"));
                end;
            end;
        }
        field(7003; Subtype; Option)
        {
            Caption = 'Subtype';
            OptionCaption = ' ,Item - Inventory,Item - Service,Comment';
            OptionMembers = " ","Item - Inventory","Item - Service",Comment;
        }
        field(7004; "Price description"; Text[80])
        {
            Caption = 'Price description';
        }
        field(7010; "Attached Doc Count"; Integer)
        {
            BlankNumbers = DontBlank;
            CalcFormula = count("Document Attachment" where("Table ID" = const(37),
                                                             "No." = field("Document No."),
                                                             "Document Type" = field("Document Type"),
                                                             "Line No." = field("Line No.")));
            Caption = 'Attached Doc Count';
            FieldClass = FlowField;
            InitValue = 0;
        }
        field(7011; "Attached Lines Count"; Integer)
        {
            CalcFormula = count("Sales Line" where("Document Type" = field("Document Type"),
                                                    "Document No." = field("Document No."),
                                                    "Attached to Line No." = field("Line No."),
                                                    Quantity = filter(<> 0)));
            Caption = 'Attached Lines Count';
            Editable = false;
            FieldClass = FlowField;
            BlankZero = true;
        }
        field(7012; "Sell-to Customer Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Sell-to Customer No.")));
            Caption = 'Sell-to Customer Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key3; "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date")
        {
            IncludedFields = "Outstanding Qty. (Base)";
        }
        key(Key4; "Document Type", "Bill-to Customer No.", "Currency Code", "Document No.")
        {
            IncludedFields = "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)", "Return Rcd. Not Invd. (LCY)", "Prepmt. Amount Inv. (LCY)", "Prepmt. VAT Amount Inv. (LCY)", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "VAT %";
        }
        key(Key7; "Document Type", "Blanket Order No.", "Blanket Order Line No.")
        {
        }
        key(Key8; "Document Type", "Document No.", "Location Code")
        {
            IncludedFields = Amount, "Amount Including VAT", "Outstanding Amount", "Shipped Not Invoiced", "Outstanding Amount (LCY)", "Shipped Not Invoiced (LCY)";
        }
        key(Key9; "Document Type", "Shipment No.", "Shipment Line No.")
        {
        }
        key(Key10; Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Document Type", "Shipment Date")
        {
        }
        key(Key11; "Document Type", "Sell-to Customer No.", "Shipment No.", "Document No.")
        {
            IncludedFields = "Outstanding Amount (LCY)";
        }
        key(Key12; "Job Contract Entry No.")
        {
        }
        key(Key15; "Recalculate Invoice Disc.")
        {
        }
        key(Key16; "Qty. Shipped Not Invoiced")
        {
        }
        key(Key17; "Qty. Shipped (Base)")
        {
        }
        key(Key18; "Shipment Date", "Outstanding Quantity")
        {
        }
        key(Key19; SystemModifiedAt)
        {
        }
        key(Key20; "Completely Shipped")
        {
        }
        key(Key21; "Document Type", "Document No.", Type, "No.", "System-Created Entry")
        {
            IncludedFields = Quantity, "Outstanding Qty. (Base)";
        }
        key(Key22; "Document No.", Type, "No.")
        {
            IncludedFields = Quantity;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code", "Price description")
        {
        }
        fieldgroup(Brick; "No.", Description, "Line Amount", Quantity, "Unit of Measure Code", "Price description")
        {
        }
    }

    trigger OnDelete()
    var
        SalesCommentLine: Record "Sales Comment Line";
        CapableToPromise: Codeunit "Capable to Promise";
        JobCreateInvoice: Codeunit "Job Create-Invoice";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnDeleteOnBeforeTestStatusOpen(Rec, IsHandled);
        if not IsHandled then
            TestStatusOpen();

        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            SalesLineReserve.DeleteLine(Rec);
            CheckReservedQtyBase();
            CheckNotInvoicedQty();
            SalesWarehouseMgt.SalesLineDelete(Rec);
        end;

        if ("Document Type" = "Document Type"::Order) and (Quantity <> "Quantity Invoiced") then
            TestField("Prepmt. Amt. Inv.", "Prepmt Amt Deducted");

        CleanDropShipmentFields();
        CleanSpecialOrderFieldsAndCheckAssocPurchOrder();
        CatalogItemMgt.DelNonStockSales(Rec);

        CheckLinkedBlanketOrderLineOnDelete();

        if Type = Type::Item then begin
            ATOLink.DeleteAsmFromSalesLine(Rec);
            DeleteItemChargeAssignment("Document Type", "Document No.", "Line No.");
        end;

        if ("Document Type" = "Document Type"::Order) then
            CapableToPromise.RemoveReqLines("Document No.", "Line No.", 0, false);

        if "Line No." <> 0 then begin
            SalesLine2.Reset();
            SalesLine2.SetRange("Document Type", "Document Type");
            SalesLine2.SetRange("Document No.", "Document No.");
            SalesLine2.SetRange("Attached to Line No.", "Line No.");
            SalesLine2.SetFilter("Line No.", '<>%1', "Line No.");
            OnDeleteOnAfterSetSalesLineFilters(SalesLine2);
            SalesLine2.DeleteAll(true);

            OnDeleteOnAfterSalesLine2DeleteAll(Rec, SalesLine2);
        end;

        if "Job Contract Entry No." <> 0 then
            JobCreateInvoice.DeleteSalesLine(Rec);

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "Document No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        if not SalesCommentLine.IsEmpty() then
            SalesCommentLine.DeleteAll();

        // In case we have roundings on VAT or Sales Tax, we should update some other line
        if (Type <> Type::" ") and ("Line No." <> 0) and not IsExtendedText() and ("Job Contract Entry No." = 0) and
           (Quantity <> 0) and (Amount <> 0) and (Amount <> "Amount Including VAT") and not StatusCheckSuspended
        then begin
            Quantity := 0;
            "Quantity (Base)" := 0;
            "Qty. to Invoice" := 0;
            "Qty. to Invoice (Base)" := 0;
            "Line Discount Amount" := 0;
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
            UpdateAmounts();
        end;

        if Type = Type::"Charge (Item)" then
            DeleteChargeChargeAssgnt("Document Type", "Document No.", "Line No.");

        if "Deferral Code" <> '' then
            DeferralUtilities.DeferralCodeOnDelete(
                Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                "Document Type".AsInteger(), "Document No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();
        if not HasSalesHeader then
            Error(CannotInsertSalesLineWithoutHeaderErr);

        if Quantity <> 0 then begin
            OnBeforeVerifyReservedQty(Rec, xRec, 0);
            SalesLineReserve.VerifyQuantity(Rec, xRec);
        end;
        LockTable();
        SalesHeader."No." := '';
        if (Type = Type::Item) and ("No." <> '') then
            CheckInventoryPickConflict();
        OnInsertOnAfterCheckInventoryConflict(Rec, xRec, SalesLine2);
        if ("Deferral Code" <> '') and (GetDeferralAmount() <> 0) then
            UpdateDeferralAmounts();
        OnAfterInsertOnAfterUpdateDeferralAmounts(Rec, CurrFieldNo);
    end;

    trigger OnModify()
    begin
        if ("Document Type" = "Document Type"::"Blanket Order") and
           ((Type <> xRec.Type) or ("No." <> xRec."No."))
        then begin
            SalesLine2.Reset();
            SalesLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            SalesLine2.SetRange("Blanket Order No.", "Document No.");
            SalesLine2.SetRange("Blanket Order Line No.", "Line No.");
            OnModifyOnAfterSetFilters(Rec, SalesLine2);
            if SalesLine2.FindSet() then
                repeat
                    SalesLine2.TestField(Type, Type);
                    SalesLine2.TestField("No.", "No.");
                until SalesLine2.Next() = 0;
        end;

        if ((Quantity <> 0) or (xRec.Quantity <> 0)) and ItemExists(xRec."No.") and not FullReservedQtyIsForAsmToOrder() then
            VerifyChangeForSalesLineReserve(0);
        OnAfterModifyOnAfterVerifyChangeForSalesLineReserve(Rec, CurrFieldNo);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        ItemUOMForCaption: Record "Item Unit of Measure";
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        GLAcc: Record "G/L Account";
        Resource: Record Resource;
        Currency: Record Currency;
        Res: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        NonstockItem: Record "Nonstock Item";
        SKU: Record "Stockkeeping Unit";
        ItemCharge: Record "Item Charge";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        ATOLink: Record "Assemble-to-Order Link";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        CalChange: Record "Customized Calendar Change";
        TempErrorMessage: Record "Error Message" temporary;
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        ItemSubstitutionMgt: Codeunit "Item Subst.";
        ItemReferenceMgt: Codeunit "Item Reference Management";
        CatalogItemMgt: Codeunit "Catalog Item Management";
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        DeferralUtilities: Codeunit "Deferral Utilities";
        CalendarMgmt: Codeunit "Calendar Management";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        PriceType: Enum "Price Type";
        FieldCausedPriceCalculation: Integer;
        FullAutoReservation: Boolean;
        HasBeenShown: Boolean;
        PlannedShipmentDateCalculated: Boolean;
        PlannedDeliveryDateCalculated: Boolean;
        HasSalesHeader: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete the order line because it is associated with purchase order %1 line %2.';
        Text001: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
        Text002: Label 'You can''t change %1 because the order line is associated with purchase order %2 line %3.', Comment = '%1=field name, %2=Document No., %3=Line No.';
#pragma warning disable AA0470
        Text003: Label 'must not be less than %1';
        Text005: Label 'You cannot invoice more than %1 units.';
        Text006: Label 'You cannot invoice more than %1 base units.';
        Text007: Label 'You cannot ship more than %1 units.';
        Text008: Label 'You cannot ship more than %1 base units.';
        Text009: Label ' must be 0 when %1 is %2';
        Text014: Label '%1 %2 is before work date %3';
        Text016: Label '%1 is required for %2 = %3.';
        Text020: Label 'You cannot return more than %1 units.';
        Text021: Label 'You cannot return more than %1 base units.';
        Text026: Label 'You cannot change %1 if the item charge has already been posted.';
        Text028: Label 'You cannot change the %1 when the %2 has been filled in.';
#pragma warning restore AA0470
        Text029: Label 'must be positive';
        Text030: Label 'must be negative';
#pragma warning disable AA0470
        Text031: Label 'You must either specify %1 or %2.';
#pragma warning restore AA0470
        Text035: Label 'Warehouse ';
        Text036: Label 'Inventory ';
#pragma warning disable AA0470
        Text037: Label 'You cannot change %1 when %2 is %3 and %4 is positive.';
        Text038: Label 'You cannot change %1 when %2 is %3 and %4 is negative.';
        Text039: Label '%1 units for %2 %3 have already been returned. Therefore, only %4 units can be returned.';
        Text042: Label 'When posting the Applied to Ledger Entry %1 will be opened first';
        Text044: Label 'cannot be less than %1';
        Text045: Label 'cannot be more than %1';
        Text046: Label 'You cannot return more than the %1 units that you have shipped for %2 %3.';
        Text047: Label 'must be positive when %1 is not 0.';
        Text048: Label 'You cannot use item tracking on a %1 created from a %2.';
        Text049: Label 'cannot be %1.';
        Text051: Label 'You cannot use %1 in a %2.';
        Text053: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
#pragma warning restore AA0470
        Text054: Label 'Cancelled.';
#pragma warning disable AA0470
        Text055: Label '%1 must not be greater than the sum of %2 and %3.', Comment = 'Quantity Invoiced must not be greater than the sum of Qty. Assigned and Qty. to Assign.';
#pragma warning restore AA0470
        Text057: Label 'must have the same sign as the shipment';
#pragma warning disable AA0470
        Text058: Label 'The quantity that you are trying to invoice is greater than the quantity in shipment %1.';
#pragma warning restore AA0470
        Text059: Label 'must have the same sign as the return receipt';
#pragma warning disable AA0470
        Text060: Label 'The quantity that you are trying to invoice is greater than the quantity in return receipt %1.';
#pragma warning restore AA0074
        ShippingMoreUnitsThanReceivedErr: Label 'You cannot ship more than the %1 units that you have received for document no. %2.';
#pragma warning restore AA0470
        WhseRequirementMsg: Label '%1 is required for this line. The entered information may be disregarded by warehouse activities.', Comment = '%1=Document';
        ShowOrderLbl: Label 'Show PO-%1', Comment = '%1=Document No.';
        ManualReserveQst: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
        QtyShipNotValidTitleLbl: Label 'Qty. to Ship isn''t valid';
        QtyShipActionLbl: Label 'Set value to %1', comment = '%1=Qty. to Ship';
        QtyShipActionDescriptionLbl: Label 'Corrects %1 value to %2', Comment = '%1 - Qty. to Ship field caption, %2 - Quantity';
        QtyInvoiceNotValidTitleLbl: Label 'Qty. to Invoice isn''t valid';
        QtyInvoiceActionLbl: Label 'Set value to %1', Comment = '%1 - Qty. to Invoice';
        QtyInvoiceActionDescriptionLbl: Label 'Corrects %1 value to %2', Comment = '%1 - Qty. to Invoice field caption, %2 - Quantity';
        QuantityImbalanceErr: Label '%1 on %2-%3 causes the %4 and %5 to be out of balance.', Comment = '%1 - field name, %2 - table name, %3 - primary key value, %4 - field name, %5 - field name';
        CanNotAddItemWhsShipmentExistErr: Label 'You cannot add an item line because an open warehouse shipment exists for the sales header and Shipping Advice is %1.\\You must add items as new lines to the existing warehouse shipment or change Shipping Advice to Partial.', Comment = '%1- Shipping Advice';
        CanNotAddItemPickExistErr: Label 'You cannot add an item line because an open inventory pick exists for the Sales Header and because Shipping Advice is %1.\\You must first post or delete the inventory pick or change Shipping Advice to Partial.', Comment = '%1- Shipping Advice';
        ItemChargeAssignmentErr: Label 'You can only assign Item Charges for Line Types of Charge (Item).';
        SalesLineCompletelyShippedErr: Label 'You cannot change the purchasing code for a sales line that has been completely shipped.';
        SalesSetupRead: Boolean;
        LookupRequested: Boolean;
        FreightLineDescriptionTxt: Label 'Freight Amount';
        CannotFindDescErr: Label 'Cannot find %1 with Description %2.\\Make sure to use the correct type.', Comment = '%1 = Type caption %2 = Description';
        PriceDescriptionTxt: Label 'x%1 (%2%3/%4)', Locked = true;
        PriceDescriptionWithLineDiscountTxt: Label 'x%1 (%2%3/%4) - %5%', Locked = true;
        SelectNonstockItemErr: Label 'You can only select a catalog item for an empty line.';
        CommentLbl: Label 'Comment';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        SalesBlockedErr: Label 'You cannot sell %1 %2 because the %3 check box is selected on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption';
        CannotChangePrepaidServiceChargeErr: Label 'You cannot change the line because it will affect service charges that are already invoiced as part of a prepayment.';
        LineAmountInvalidErr: Label 'You have set the line amount to a value that results in a discount that is not valid. Consider increasing the unit price instead.';
        LineInvoiceDiscountAmountResetTok: Label 'The value in the Inv. Discount Amount field in %1 has been cleared.', Comment = '%1 - Record ID';
        UnitPriceChangedMsg: Label 'The unit price for %1 %2 that was copied from the posted document has been changed.', Comment = '%1 = Type caption %2 = No.';
        BlockedItemNotificationMsg: Label 'Item %1 is blocked, but it is allowed on this type of document.', Comment = '%1 is Item No.';
        BlockedItemVariantNotificationMsg: Label 'Item Variant %1 for Item %2 is blocked, but it is allowed on this type of document.', Comment = '%1 - Item Variant Code, %2 - Item No.';
        InvDiscForPrepmtExceededErr: Label 'You cannot enter an invoice discount for sales document %1.\\You must cancel the prepayment invoice first and then you will be able to update the invoice discount.', Comment = '%1 - document number';
        CannotAllowInvDiscountErr: Label 'The value of the %1 field is not valid when the VAT Calculation Type field is set to "Full VAT".', Comment = '%1 is the name of not valid field';
        CannotChangeVATGroupWithPrepmInvErr: Label 'You cannot change the VAT product posting group because prepayment invoices have been posted.\\You need to post the prepayment credit memo to be able to change the VAT product posting group.';
        CannotChangePrepmtAmtDiffVAtPctErr: Label 'You cannot change the prepayment amount because the prepayment invoice has been posted with a different VAT percentage. Please check the settings on the prepayment G/L account.';
        NonInvReserveTypeErr: Label 'Non-inventory and service items must have the reserve type Never. The current reserve type for item %1 is %2.', Comment = '%1 is Item No., %2 is Reserve';
        ChangeExtendedTextErr: Label 'You cannot change %1 for Extended Text Line.', Comment = '%1= Field Caption';
        CannotInsertSalesLineWithoutHeaderErr: Label 'You cannot insert a sales line without a sales header.';

    protected var
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;
        PrePaymentLineAmountEntered: Boolean;
        SkipTaxCalculation: Boolean;

    /// <summary>
    /// Updates outstanding quantities and amounts to reflect changes in posted quantities and amounts.
    /// </summary>
    procedure InitOutstanding()
    begin
        if IsCreditDocType() then begin
            "Outstanding Quantity" := Quantity - "Return Qty. Received";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Return Qty. Received (Base)";
            "Return Qty. Rcd. Not Invd." := "Return Qty. Received" - "Quantity Invoiced";
            "Ret. Qty. Rcd. Not Invd.(Base)" := "Return Qty. Received (Base)" - "Qty. Invoiced (Base)";
        end else begin
            "Outstanding Quantity" := Quantity - "Quantity Shipped";
            "Outstanding Qty. (Base)" := "Quantity (Base)" - "Qty. Shipped (Base)";
            "Qty. Shipped Not Invoiced" := "Quantity Shipped" - "Quantity Invoiced";
            "Qty. Shipped Not Invd. (Base)" := "Qty. Shipped (Base)" - "Qty. Invoiced (Base)";
        end;
        OnAfterInitOutstandingQty(Rec);
        UpdatePlanned();
        "Completely Shipped" := (Quantity <> 0) and ("Outstanding Quantity" = 0);
        InitOutstandingAmount();

        OnAfterInitOutstanding(Rec);
    end;


    /// <summary>
    /// Updates outstanding amounts to reflect changes in quantity.
    /// </summary>
    procedure InitOutstandingAmount()
    var
        AmountInclVAT: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingAmount(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Quantity = 0 then begin
            "Outstanding Amount" := 0;
            "Outstanding Amount (LCY)" := 0;
            "Shipped Not Invoiced" := 0;
            "Shipped Not Invoiced (LCY)" := 0;
            "Return Rcd. Not Invd." := 0;
            "Return Rcd. Not Invd. (LCY)" := 0;
        end else begin
            GetSalesHeader();
            AmountInclVAT := "Amount Including VAT";
            Validate(
              "Outstanding Amount",
              Round(
                AmountInclVAT * "Outstanding Quantity" / Quantity,
                Currency."Amount Rounding Precision"));
            if IsCreditDocType() then
                Validate(
                  "Return Rcd. Not Invd.",
                  Round(
                    AmountInclVAT * "Return Qty. Rcd. Not Invd." / Quantity,
                    Currency."Amount Rounding Precision"))
            else
                Validate(
                  "Shipped Not Invoiced",
                  Round(
                    AmountInclVAT * "Qty. Shipped Not Invoiced" / Quantity,
                    Currency."Amount Rounding Precision"));
        end;

        OnAfterInitOutstandingAmount(Rec, SalesHeader, Currency);
    end;

    /// <summary>
    /// Updates quantity to ship and quantity to invoice based on the outstanding quantities
    /// </summary>
    procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Remainder) or
           ("Document Type" = "Document Type"::Invoice)
        then begin
            "Qty. to Ship" := "Outstanding Quantity";
            "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Qty. to Ship" <> 0 then
                "Qty. to Ship (Base)" :=
                  MaxQtyToShipBase(CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)")));
        OnInitQtyToShipOnBeforeCheckServItemCreation(Rec);
        CheckServItemCreation();

        OnAfterInitQtyToShip(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    /// <summary>
    /// Updates quantity to receive and quantity to invoice based on the outstanding quantity and document type.
    /// </summary>
    procedure InitQtyToReceive()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToReceive(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if (SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Remainder) or
           ("Document Type" = "Document Type"::"Credit Memo")
        then begin
            "Return Qty. to Receive" := "Outstanding Quantity";
            "Return Qty. to Receive (Base)" := "Outstanding Qty. (Base)";
        end else
            if "Return Qty. to Receive" <> 0 then
                "Return Qty. to Receive (Base)" := CalcBaseQty("Return Qty. to Receive", FieldCaption("Return Qty. to Receive"), FieldCaption("Return Qty. to Receive (Base)"));
        OnAfterInitQtyToReceive(Rec, CurrFieldNo);

        InitQtyToInvoice();
    end;

    /// <summary>
    /// Prepares the sales line for the next invoice posting by setting the quantities and amounts to be invoiced.
    /// </summary>
    procedure InitQtyToInvoice()
    begin
        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();

        GetSalesSetup();
        if not SalesSetup."Allow VAT Difference" then
            ClearVATDifference();

        OnBeforeCalcInvDiscToInvoice(Rec, CurrFieldNo);
        CalcInvDiscToInvoice();
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then
            CalcPrepaymentToDeduct();

        OnAfterInitQtyToInvoice(Rec, CurrFieldNo);
    end;

    local procedure InitItemAppl(OnlyApplTo: Boolean)
    begin
        "Appl.-to Item Entry" := 0;
        if not OnlyApplTo then
            "Appl.-from Item Entry" := 0;
    end;

    /// <summary>
    /// Determines the maximum quantity that can be invoiced for the current sales line.
    /// </summary>
    /// <returns>The maximum quantity that can be invoiced.</returns>
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
            exit("Return Qty. Received" + "Return Qty. to Receive" - "Quantity Invoiced");

        if "Document Type" = "Document Type"::"Blanket Order" then
            exit(Quantity - "Quantity Invoiced");
        exit("Quantity Shipped" + "Qty. to Ship" - "Quantity Invoiced");
    end;

    /// <summary>
    /// Determines the maximum quantity (base) that can be invoiced for the current sales line.
    /// </summary>
    /// <returns>The maximum quantity (base) that can be invoiced.</returns>
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
            exit("Return Qty. Received (Base)" + "Return Qty. to Receive (Base)" - "Qty. Invoiced (Base)");
        if "Document Type" = "Document Type"::"Blanket Order" then
            exit("Quantity (Base)" - "Qty. Invoiced (Base)");
        exit("Qty. Shipped (Base)" + "Qty. to Ship (Base)" - "Qty. Invoiced (Base)");
    end;

    /// <summary>
    /// Ensures that the quantity to ship does not exceed the outstanding quantity.
    /// </summary>
    /// <param name="QtyToShipBase">The quantity to ship to be checked.</param>
    /// <returns>The maximum quantity that can be shipped.</returns>
    procedure MaxQtyToShipBase(QtyToShipBase: Decimal): Decimal
    begin
        if Abs(QtyToShipBase) > Abs("Outstanding Qty. (Base)") then
            exit("Outstanding Qty. (Base)");

        exit(QtyToShipBase);
    end;

    /// <summary>
    /// Calculates the net line amount after applying the invoice discount.
    /// </summary>
    /// <returns>The calculated line amount.</returns>
    procedure CalcLineAmount() LineAmount: Decimal
    begin
        LineAmount := "Line Amount" - "Inv. Discount Amount";

        OnAfterCalcLineAmount(Rec, LineAmount);
    end;

    local procedure CanShipQty(): Boolean
    begin
        if Abs("Qty. to Ship") > Abs("Outstanding Quantity") then
            exit(false);

        if ("Qty. to Ship" < 0) and (Quantity > 0) or
           ("Qty. to Ship" > 0) and (Quantity < 0)
        then
            exit(false);

        if ("Outstanding Quantity" < 0) and (Quantity > 0) or
           ("Outstanding Quantity" > 0) and (Quantity < 0)
        then
            exit(false);

        exit(true);
    end;

    local procedure CanShipBaseQty(): Boolean
    begin
        if Abs("Qty. to Ship (Base)") > Abs("Outstanding Qty. (Base)") then
            exit(false);

        if ("Qty. to Ship (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Qty. to Ship (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        if ("Outstanding Qty. (Base)" < 0) and ("Quantity (Base)" > 0) or
           ("Outstanding Qty. (Base)" > 0) and ("Quantity (Base)" < 0)
        then
            exit(false);

        exit(true);
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
        OnAfterAssignStdTxtValues(Rec, StandardText, SalesHeader);
    end;

    /// <summary>
    /// Updates the shipment date based on the location's customized calendar.
    /// </summary>
    procedure CalcShipmentDateForLocation()
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcShipmentDateForLocation(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
        "Shipment Date" := CalendarMgmt.CalcDateBOC('', SalesHeader."Shipment Date", CustomCalendarChange, false);
    end;

    local procedure CopyFromGLAccount(var TempSalesLine: Record "Sales Line" temporary)
    begin
        GLAcc.Get("No.");
        GLAcc.CheckGLAcc();
        TestDirectPosting();
        Description := GLAcc.Name;
        "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "Tax Group Code" := GLAcc."Tax Group Code";
        "Allow Invoice Disc." := false;
        "Allow Item Charge Assignment" := false;
        InitDeferralCode();
        SetDefaultGLAccountQuantity();
        OnAfterAssignGLAccountValues(Rec, GLAcc, SalesHeader, TempSalesLine);
    end;

    local procedure TestDirectPosting()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestDirectPosting(Rec, GLAcc, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not "System-Created Entry" then
            GLAcc.TestField("Direct Posting", true);
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        GetItem(Item);
        IsHandled := false;
        OnBeforeCopyFromItem(Rec, Item, IsHandled);
        if not IsHandled then begin
            Item.TestField(Blocked, false);
            Item.TestField("Gen. Prod. Posting Group");
            if Item."Sales Blocked" then
                if IsCreditDocType() then
                    SendBlockedItemNotification()
                else
                    Error(SalesBlockedErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Sales Blocked"));
            if Item.Type = Item.Type::Inventory then begin
                Item.TestField("Inventory Posting Group");
                "Posting Group" := Item."Inventory Posting Group";
            end;
        end;

        OnCopyFromItemOnAfterCheck(Rec, Item);

        Description := Item.Description;
        "Description 2" := Item."Description 2";
        GetUnitCost();
        "Allow Invoice Disc." := Item."Allow Invoice Disc.";
        "Units per Parcel" := Item."Units per Parcel";
        "Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        "Tax Group Code" := Item."Tax Group Code";
        "Item Category Code" := Item."Item Category Code";
        Nonstock := Item."Created From Nonstock Item";
        "Profit %" := Item."Profit %";
        "Allow Item Charge Assignment" := true;
        PrepaymentMgt.SetSalesPrepaymentPct(Rec, SalesHeader."Posting Date");
        if IsInventoriableItem() then
            PostingSetupMgt.CheckInvtPostingSetupInventoryAccount("Location Code", "Posting Group");
        OnCopyFromItemOnAfterCheckInvtPostingSetupInventoryAccount(Rec, Item);

        if SalesHeader."Language Code" <> '' then
            GetItemTranslation();

        if Item.Reserve = Item.Reserve::Optional then
            Reserve := SalesHeader.Reserve
        else
            Reserve := Item.Reserve;

        if Item."Sales Unit of Measure" <> '' then
            "Unit of Measure Code" := Item."Sales Unit of Measure"
        else
            "Unit of Measure Code" := Item."Base Unit of Measure";

        if "Document Type" in ["Document Type"::Quote, "Document Type"::Order, "Document Type"::"Blanket Order"] then
            Validate("Purchasing Code", Item."Purchasing Code");
        OnAfterCopyFromItem(Rec, Item, CurrFieldNo, xRec);

        InitDeferralCode();
        SetDefaultItemQuantity();
        OnAfterAssignItemValues(Rec, Item, SalesHeader, xRec, CurrFieldNo);
    end;

    local procedure CopyFromResource()
    var
        IsHandled: Boolean;
    begin
        Res.Get("No.");
        Res.CheckResourcePrivacyBlocked(false);
        IsHandled := false;
        OnCopyFromResourceOnBeforeTestBlocked(Res, IsHandled, Rec);
        if not IsHandled then
            Res.TestField(Blocked, false);
        Res.TestField("Gen. Prod. Posting Group");
        Description := Res.Name;
        "Description 2" := Res."Name 2";
        "Unit of Measure Code" := Res."Base Unit of Measure";
        "Unit Cost (LCY)" := Res."Unit Cost";
        "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
        "VAT Prod. Posting Group" := Res."VAT Prod. Posting Group";
        "Tax Group Code" := Res."Tax Group Code";
        "Allow Item Charge Assignment" := false;
        OnCopyFromResourceOnBeforeApplyResUnitCost(Rec, Res, SalesHeader);
        ApplyResUnitCost(FieldNo("No."));
        InitDeferralCode();
        OnAfterAssignResourceValues(Rec, Res, SalesHeader);
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
        OnAfterAssignFixedAssetValues(Rec, FixedAsset, SalesHeader);
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
        OnAfterAssignItemChargeValues(Rec, ItemCharge, SalesHeader);
    end;

    /// <summary>
    /// Copies values from a specified sales line to the current sales line.
    /// </summary>
    /// <param name="FromSalesLine">The sales line to copy from.</param>
    [Scope('OnPrem')]
    procedure CopyFromSalesLine(FromSalesLine: Record "Sales Line")
    begin
        "No." := FromSalesLine."No.";
        "Variant Code" := FromSalesLine."Variant Code";
        "Location Code" := FromSalesLine."Location Code";
        "Bin Code" := FromSalesLine."Bin Code";
        "Unit of Measure Code" := FromSalesLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromSalesLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromSalesLine.Quantity;
        "Qty. to Assemble to Order" := 0;
        "Drop Shipment" := FromSalesLine."Drop Shipment";
        OnAfterCopyFromSalesLine(Rec, FromSalesLine);
    end;

    /// <summary>
    /// Copies values from a specified sales shipment line to the current sales line.
    /// </summary>
    /// <param name="FromSalesShptLine">The sales shipment line to copy from.</param>
    [Scope('OnPrem')]
    procedure CopyFromSalesShptLine(FromSalesShptLine: Record "Sales Shipment Line")
    begin
        "No." := FromSalesShptLine."No.";
        "Variant Code" := FromSalesShptLine."Variant Code";
        "Location Code" := FromSalesShptLine."Location Code";
        "Bin Code" := FromSalesShptLine."Bin Code";
        "Unit of Measure Code" := FromSalesShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromSalesShptLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromSalesShptLine.Quantity;
        "Qty. to Assemble to Order" := 0;
        "Drop Shipment" := FromSalesShptLine."Drop Shipment";

        OnAfterCopyFromSalesShptLine(Rec, FromSalesShptLine);
    end;

    /// <summary>
    /// Copies values from a specified sales invoice line to the current sales line.
    /// </summary>
    /// <param name="FromSalesInvLine">The sales invoice line to copy from.</param>
    [Scope('OnPrem')]
    procedure CopyFromSalesInvLine(FromSalesInvLine: Record "Sales Invoice Line")
    begin
        "No." := FromSalesInvLine."No.";
        "Variant Code" := FromSalesInvLine."Variant Code";
        "Location Code" := FromSalesInvLine."Location Code";
        "Bin Code" := FromSalesInvLine."Bin Code";
        "Unit of Measure Code" := FromSalesInvLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromSalesInvLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromSalesInvLine.Quantity;
        "Drop Shipment" := FromSalesInvLine."Drop Shipment";
    end;

    /// <summary>
    /// Copies values from a specified return receipt line to the current sales line.
    /// </summary>
    /// <param name="FromReturnRcptLine">The return receipt line to copy from.</param>
    [Scope('OnPrem')]
    procedure CopyFromReturnRcptLine(FromReturnRcptLine: Record "Return Receipt Line")
    begin
        "No." := FromReturnRcptLine."No.";
        "Variant Code" := FromReturnRcptLine."Variant Code";
        "Location Code" := FromReturnRcptLine."Location Code";
        "Bin Code" := FromReturnRcptLine."Bin Code";
        "Unit of Measure Code" := FromReturnRcptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromReturnRcptLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromReturnRcptLine.Quantity;
        "Drop Shipment" := false;
    end;

    /// <summary>
    /// Copies values from a specified sales cr. memo line to the current sales line.
    /// </summary>
    /// <param name="FromSalesCrMemoLine">The sales cr. memo line to copy from.</param>
    [Scope('OnPrem')]
    procedure CopyFromSalesCrMemoLine(FromSalesCrMemoLine: Record "Sales Cr.Memo Line")
    begin
        "No." := FromSalesCrMemoLine."No.";
        "Variant Code" := FromSalesCrMemoLine."Variant Code";
        "Location Code" := FromSalesCrMemoLine."Location Code";
        "Bin Code" := FromSalesCrMemoLine."Bin Code";
        "Unit of Measure Code" := FromSalesCrMemoLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := FromSalesCrMemoLine."Qty. per Unit of Measure";
        "Outstanding Quantity" := FromSalesCrMemoLine.Quantity;
        "Drop Shipment" := false;
    end;

    local procedure SelectItemEntry(CurrentFieldNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine3: Record "Sales Line";
    begin
        ItemLedgEntry.SetRange("Item No.", "No.");
        if "Location Code" <> '' then
            ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");

        if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then begin
            ItemLedgEntry.SetCurrentKey("Item No.", Open);
            ItemLedgEntry.SetRange(Positive, true);
            ItemLedgEntry.SetRange(Open, true);
        end else begin
            ItemLedgEntry.SetCurrentKey("Item No.", Positive);
            ItemLedgEntry.SetRange(Positive, false);
            ItemLedgEntry.SetFilter("Shipped Qty. Not Returned", '<0');
        end;
        OnSelectItemEntryOnAfterSetFilters(ItemLedgEntry, Rec, CurrFieldNo);
        if PAGE.RunModal(PAGE::"Item Ledger Entries", ItemLedgEntry) = ACTION::LookupOK then begin
            SalesLine3 := Rec;
            if CurrentFieldNo = FieldNo("Appl.-to Item Entry") then
                SalesLine3.Validate("Appl.-to Item Entry", ItemLedgEntry."Entry No.")
            else
                SalesLine3.Validate("Appl.-from Item Entry", ItemLedgEntry."Entry No.");
            CheckItemAvailable(CurrentFieldNo);
            Rec := SalesLine3;
        end;
    end;

    /// <summary>
    /// Returns the value of global SkipTaxCalculation flag. The flag is unused in the object.
    /// </summary>
    /// <returns>The value of global SkipTaxCalculation flag.</returns>
    procedure GetSkipTaxCalculation(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;

    /// <summary>
    /// Sets the value of global SkipTaxCalculation flag. The flag is unused in the object.
    /// </summary>
    /// <param name="Skip">The value to set.</param>
    procedure SetSkipTaxCalulation(Skip: Boolean)
    begin
        SkipTaxCalculation := Skip;
    end;

    /// <summary>
    /// Updates the global SalesHeader variable and initializes the currency based on the new sales header.
    /// </summary>
    /// <remarks>
    /// The global SalesHeader is used whenever data from the sales header is used in other procedures on the object.
    /// </remarks>
    /// <param name="NewSalesHeader">The sales header to set.</param>
    procedure SetSalesHeader(NewSalesHeader: Record "Sales Header")
    begin
        SalesHeader := NewSalesHeader;
        HasSalesHeader := true;
        OnBeforeSetSalesHeader(SalesHeader);

        if SalesHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            SalesHeader.TestField("Currency Factor");
            Currency.Get(SalesHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;

        OnAfterSetSalesHeader(Rec, SalesHeader, Currency);
    end;

    /// <summary>
    /// Gets the sales header associated with the sales line.
    /// Ensures the global SalesHeader variable is correctly set.
    /// </summary>
    /// <returns>The sales header of the current line.</returns>
    procedure GetSalesHeader(): Record "Sales Header"
    begin
        GetSalesHeader(SalesHeader, Currency);
        exit(SalesHeader);
    end;

    /// <summary>
    /// Gets the sales header and the currency associated with the sales line.
    /// Ensures that the global SalesHeader variable and the currency are correctly set.
    /// </summary>
    /// <param name="OutSalesHeader">Return value: The sales header of the current line.</param>
    /// <param name="OutCurrency">Return value: The currency of the current line.</param>
    procedure GetSalesHeader(var OutSalesHeader: Record "Sales Header"; var OutCurrency: Record Currency)
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetSalesHeader(Rec, SalesHeader, IsHandled, Currency);
        if IsHandled then
            exit;

        TestField("Document No.");
        if ("Document Type" <> SalesHeader."Document Type") or ("Document No." <> SalesHeader."No.") then
            if SalesHeader.Get("Document Type", "Document No.") then begin
                HasSalesHeader := true;
                if SalesHeader."Currency Code" = '' then
                    Currency.InitRoundingPrecision()
                else begin
                    SalesHeader.TestField("Currency Factor");
                    Currency.Get(SalesHeader."Currency Code");
                    Currency.TestField("Amount Rounding Precision");
                end
            end else
                Clear(SalesHeader);

        OnAfterGetSalesHeader(Rec, SalesHeader, Currency);
        OutSalesHeader := SalesHeader;
        OutCurrency := Currency;
    end;

    /// <summary>
    /// Gets the item record from the item number on the sales line.
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

    /// <summary>
    /// Gets the item record from the the item number on the sales line.
    /// </summary>
    /// <param name="Item">Return value: The item record.</param>
    procedure GetItem(var Item: Record Item)
    begin
        TestField("No.");
        Item.Get("No.");
    end;

    /// <summary>
    /// Gets the resource record from the resource number on the sales line.
    /// The global Resource variable is updated with the retrieved resource.
    /// </summary>
    /// <returns>The resource record.</returns>
    procedure GetResource(): Record Resource
    begin
        TestField("No.");
        if "No." <> Resource."No." then
            Resource.Get("No.");
        exit(Resource);
    end;

    /// <summary>
    /// Calculates the quantity and quantity (base) that remain unreserved on the sales line.
    /// </summary>
    /// <param name="RemainingQty">Return value: The remaining unreserved quantity.</param>
    /// <param name="RemainingQtyBase">Return value: The remaining unreserved quantity (base).</param>
    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Outstanding Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Outstanding Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    /// <summary>
    /// Gets the quantities related to reservations for the sales line.
    /// </summary>
    /// <param name="QtyReserved">Return value: The reserved quantity.</param>
    /// <param name="QtyReservedBase">Return value: The reserved quantity (base).</param>
    /// <param name="QtyToReserve">Return value: The quantity to reserve.</param>
    /// <param name="QtyToReserveBase">Return value: The quantity to reserve (base).</param>
    /// <returns>The quantity per unit of measure.</returns>
    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetReservationQty(Rec, QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

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

        OnAfterGetReservationQty(Rec, QtyToReserve, QtyToReserveBase, Result);
    end;

    /// <summary>
    /// Returns a caption containing the document type, document number and line number separated by spaces for the sales line.
    /// </summary>
    /// <returns>The formatted text.</returns>
    procedure GetSourceCaption(): Text
    begin
        exit(StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "No."));
    end;

    /// <summary>
    /// Initializes the reservation entry with information from the sales line.
    /// </summary>
    /// <param name="ReservEntry">Return value: The initialized reservation entry.</param>
    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", '', 0);
        ReservEntry.SetItemData("No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        if Type <> Type::Item then
            ReservEntry."Item No." := '';
        ReservEntry."Expected Receipt Date" := "Shipment Date";
        ReservEntry."Shipment Date" := "Shipment Date";

        OnAfterSetReservationEntry(ReservEntry, Rec);
    end;

    /// <summary>
    /// Filters the reservation entries for the sales line.
    /// </summary>
    /// <param name="ReservEntry">The reservation entry to filter.</param>
    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    /// <summary>
    /// Checks if a reservation entry exists for the sales line.
    /// </summary>
    /// <returns>True if a reservation entry exists, otherwise false.</returns>
    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    /// <summary>
    /// Checks if the price calculation was triggered by a specific field.
    /// </summary>
    /// <param name="CurrPriceFieldNo">The field number of the field that triggered the price calculation.</param>
    /// <returns>True if the invoking field no. is the same as the planned field no., otherwise false.</returns>
    procedure IsPriceCalcCalledByField(CurrPriceFieldNo: Integer): Boolean;
    begin
        exit(FieldCausedPriceCalculation = CurrPriceFieldNo);
    end;

    /// <summary>
    /// Plans for a price calculation triggered by a specific field, ensuring that the calculation is performed only once.
    /// </summary>
    /// <remarks>
    /// This field no. is checked in IsPriceCalcCalledByField to determine if price calculation should be performed .
    /// </remarks>
    /// <param name="CurrPriceFieldNo">The field number of the field that can cause price calculation.</param>
    procedure PlanPriceCalcByField(CurrPriceFieldNo: Integer)
    begin
        if FieldCausedPriceCalculation = 0 then
            FieldCausedPriceCalculation := CurrPriceFieldNo;
    end;

    /// <summary>
    /// Resets the tracking of the field that is planned to trigger a price calculation.
    /// </summary>
    procedure ClearFieldCausedPriceCalculation()
    begin
        FieldCausedPriceCalculation := 0;
    end;

    local procedure UpdateQuantityFromUOMCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuantityFromUOMCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate(Quantity);
    end;

    /// <summary>
    /// Updates the unit price on the sales line.
    /// </summary>
    /// <param name="CalledByFieldNo">The field number of the field that triggered the price calculation.</param>
    procedure UpdateUnitPrice(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPriceProcedure(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ClearFieldCausedPriceCalculation();
        PlanPriceCalcByField(CalledByFieldNo);
        UpdateUnitPriceByField(CalledByFieldNo);
    end;

    /// <summary>
    /// Updates the unit price on the sales line.
    /// The calculation is only performed if the field number of the field that triggered the price calculation is the same as the planned field no.
    /// </summary>
    /// <param name="CalledByFieldNo">The field number of the field that triggered the price calculation.</param>
    procedure UpdateUnitPriceByField(CalledByFieldNo: Integer)
    var
        BlanketOrderSalesLine: Record "Sales Line";
        IsHandled: Boolean;
        PriceCalculation: Interface "Price Calculation";
    begin
        if not IsPriceCalcCalledByField(CalledByFieldNo) then
            exit;

        IsHandled := false;
        OnBeforeUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetSalesHeader();
        TestField("Qty. per Unit of Measure");

        case Type of
            Type::"G/L Account",
            Type::Item,
            Type::Resource:
                begin
                    IsHandled := false;
                    OnUpdateUnitPriceOnBeforeFindPrice(SalesHeader, Rec, CalledByFieldNo, CurrFieldNo, IsHandled, xRec);
                    if not IsHandled then
                        if not BlanketOrderIsRelated(BlanketOrderSalesLine) then begin
                            GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
                            if not ("Copied From Posted Doc." and IsCreditDocType()) then begin
                                PriceCalculation.ApplyDiscount();
                                ApplyPrice(CalledByFieldNo, PriceCalculation);
                            end else
                                CalcUnitPriceUsingUOMCoef();
                        end else
                            CopyUnitPriceAndLineDiscountPct(BlanketOrderSalesLine, CalledByFieldNo);
                    OnUpdateUnitPriceByFieldOnAfterFindPrice(SalesHeader, Rec, CalledByFieldNo, CurrFieldNo);
                end;
        end;

        ShowUnitPriceChangedMsg();

        IsHandled := false;
        OnUpdateUnitPriceByFieldOnBeforeValidateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        if not IsHandled then
            Validate("Unit Price");

        ClearFieldCausedPriceCalculation();
        OnAfterUpdateUnitPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    internal procedure BlanketOrderIsRelated(var BlanketOrderSalesLine: Record "Sales Line"): Boolean
    var
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeBlanketOrderIsRelated(Rec, BlanketOrderSalesLine, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if "Blanket Order Line No." = 0 then exit;
        BlanketOrderSalesLine.SetLoadFields("Unit Price", "Line Discount %");
        OnBlanketOrderIsRelatedOnAfterSetLoadFields(BlanketOrderSalesLine);
        if BlanketOrderSalesLine.Get("Document Type"::"Blanket Order", "Blanket Order No.", "Blanket Order Line No.") then
            exit(true);
    end;

    procedure CopyUnitPriceAndLineDiscountPct(BlanketOrderSalesLine: Record "Sales Line"; CalledByFieldNo: Integer)
    begin
        Validate("Unit Price", BlanketOrderSalesLine."Unit Price");
        Validate("Line Discount %", BlanketOrderSalesLine."Line Discount %");
        OnAfterCopyUnitPriceAndLineDiscountPct(Rec, BlanketOrderSalesLine, CalledByFieldNo, SalesHeader);
    end;

    procedure ShowUnitPriceChangedMsg()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowUnitPriceChangedMsg(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if "Copied From Posted Doc." and IsCreditDocType() and ("Appl.-from Item Entry" <> 0) then
            if xRec."Unit Price" <> "Unit Price" then
                if GuiAllowed then
                    ShowMessageOnce(StrSubstNo(UnitPriceChangedMsg, Type, "No."));
    end;

    local procedure GetLineWithCalculatedPrice(var PriceCalculation: Interface "Price Calculation")
    var
        Line: Variant;
    begin
        PriceCalculation.GetLine(Line);
        Rec := Line;
    end;

    /// <summary>
    /// Gets the "Price Calculation" implementation for the sales line.
    /// </summary>
    /// <param name="PriceType">The type of price calculation to get.</param>
    /// <param name="SalesHeader">The sales header used for getting the price calculation.</param>
    /// <param name="PriceCalculation">Return value: The "Price Calculation" implementation.</param>
    procedure GetPriceCalculationHandler(PriceType: Enum "Price Type"; SalesHeader: Record "Sales Header"; var PriceCalculation: Interface "Price Calculation")
    var
        PriceCalculationMgt: codeunit "Price Calculation Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        if (SalesHeader."No." = '') and ("Document No." <> '') then
            SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        GetLineWithPrice(LineWithPrice);
        LineWithPrice.SetLine(PriceType, SalesHeader, Rec);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
    end;


    /// <summary>
    /// Returns a default "Line With Price" implementation if not overridden.
    /// </summary>
    /// <param name="LineWithPrice">Return value: The default or overridden "Line With Price" implementation.</param>
    procedure GetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    var
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        LineWithPrice := SalesLinePrice;
        OnAfterGetLineWithPrice(LineWithPrice);
    end;

    /// <summary>
    /// Applies the discount and assigns the calculated amount to the sales line.
    /// </summary>
    /// <param name="PriceCalculation">The "Price Calculation" implementation to use.</param>
    procedure ApplyDiscount(var PriceCalculation: Interface "Price Calculation")
    begin
        PriceCalculation.ApplyDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);
    end;

    /// <summary>
    /// Applies the price and assigns the calculated amount to the sales line.
    /// </summary>
    /// <param name="CalledByFieldNo">The field number of the field that triggered the price calculation.</param>
    /// <param name="PriceCalculation">The "Price Calculation" implementation to use.</param>
    procedure ApplyPrice(CalledByFieldNo: Integer; var PriceCalculation: Interface "Price Calculation")
    begin
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);
        OnAfterApplyPrice(Rec, xRec, CalledByFieldNo, CurrFieldNo);
    end;

    local procedure ApplyResUnitCost(CalledByFieldNo: Integer)
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Purchase, SalesHeader, PriceCalculation);
        PriceCalculation.ApplyPrice(CalledByFieldNo);
        GetLineWithCalculatedPrice(PriceCalculation);
        Validate("Unit Cost (LCY)");
    end;

    /// <summary>
    /// Wrapper for price calculation method CountDiscount.
    /// Returns the number of price list lines with discounts that fit the sales line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>The number of price list lines with discounts.</returns>
    procedure CountDiscount(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        exit(PriceCalculation.CountDiscount(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method CountPrice.
    /// Returns the number of price list lines with prices that fit the sales line.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>The number of price list lines with prices.</returns>
    procedure CountPrice(ShowAll: Boolean): Integer;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        exit(PriceCalculation.CountPrice(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method DiscountExists.
    /// Returns true if any price list line with discount that fit the sales line exist.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>True if any price list line is found, otherwise false.</returns>
    procedure DiscountExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        exit(PriceCalculation.IsDiscountExists(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method PriceExists.
    /// Returns true if any price list line with price or cost that fit the sales line exist.
    /// </summary>
    /// <param name="ShowAll">If true it widens the filters set to the price list line.</param>
    /// <returns>True if any price list line is found, otherwise false.</returns>
    procedure PriceExists(ShowAll: Boolean): Boolean;
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        if Rec.Type = Rec.Type::" " then
            exit(false);
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        exit(PriceCalculation.IsPriceExists(ShowAll));
    end;

    /// <summary>
    /// Wrapper for price calculation method PickDiscount.
    /// Opens a price list selection to pick from lines with discount that fit the sales line.
    /// After the selection the amounts are assigned to the sales line.
    /// </summary>
    procedure PickDiscount()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        PriceCalculation.PickDiscount();
        GetLineWithCalculatedPrice(PriceCalculation);

        OnAfterPickDiscount(Rec, PriceCalculation);
    end;

    /// <summary>
    /// Wrapper for price calculation method PickPrice.
    /// Opens a price list selection to pick from lines with price or cost that fit the sales line.
    /// After the selection the amounts are assigned to the sales line.
    /// </summary>
    procedure PickPrice()
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetSalesHeader();
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        PriceCalculation.PickPrice();
        GetLineWithCalculatedPrice(PriceCalculation);

        OnAfterPickPrice(Rec, PriceCalculation);
    end;

    /// <summary>
    /// Applies the discount and price for "Item Reference No." field and assigns the calculated amount to the sales line.
    /// </summary>
    procedure UpdateReferencePriceAndDiscount();
    var
        PriceCalculation: Interface "Price Calculation";
    begin
        GetPriceCalculationHandler(PriceType::Sale, SalesHeader, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        ApplyPrice(FieldNo("Item Reference No."), PriceCalculation);
    end;

    local procedure ShowMessageOnce(MessageText: Text)
    begin
        TempErrorMessage.SetContext(Rec);
        if TempErrorMessage.FindRecord(RecordId, 0, TempErrorMessage."Message Type"::Warning, MessageText) = 0 then begin
            TempErrorMessage.LogMessage(Rec, 0, TempErrorMessage."Message Type"::Warning, MessageText);
            Message(MessageText);
        end;
    end;

    procedure FindResUnitCost()
    var
        ResCost: Record "Resource Cost";
    begin
        ResCost.Init();
        OnFindResUnitCostOnAfterInitResCost(Rec, ResCost);
        ResCost.Code := "No.";
        ResCost."Work Type Code" := "Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        OnAfterFindResUnitCost(Rec, ResCost);
        Validate("Unit Cost (LCY)", ResCost."Unit Cost" * "Qty. per Unit of Measure");
    end;

    procedure FindResUnitCostOnAfterInitResCost(var ResourceCost: Record "Resource Cost")
    begin
        OnFindResUnitCostOnAfterInitResCost(Rec, ResourceCost);
    end;

    procedure AfterFindResUnitCost(var ResourceCost: Record "Resource Cost")
    begin
        OnAfterFindResUnitCost(Rec, ResourceCost);
    end;

    /// <summary>
    /// Updates the prepayment VAT fields on the sales line based on the VAT posting setup
    /// to account for updates on the prepayment sales line.
    /// </summary>
    procedure UpdatePrepmtSetupFields()
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtSetupFields(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if ("Prepayment %" <> 0) and (Type <> Type::" ") then begin
            if not ("Document Type" in ["Document Type"::Order, "Document Type"::Quote]) then
                FieldError("Document Type");
            TestField("No.");
            if CurrFieldNo = FieldNo("Prepayment %") then
                if "System-Created Entry" and not IsServiceChargeLine() then
                    FieldError("Prepmt. Line Amount", StrSubstNo(Text045, 0));
            if "System-Created Entry" and not IsServiceChargeLine() then
                "Prepayment %" := 0;
            GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
            if GenPostingSetup."Sales Prepayments Account" <> '' then begin
                GLAcc.Get(GenPostingSetup."Sales Prepayments Account");
                VATPostingSetup.Get("VAT Bus. Posting Group", GLAcc."VAT Prod. Posting Group");
                VATPostingSetup.TestField("VAT Calculation Type", "VAT Calculation Type");
            end else
                Clear(VATPostingSetup);
            if ("Prepayment VAT %" <> 0) and ("Prepayment VAT %" <> VATPostingSetup."VAT %") and ("Prepmt. Amt. Inv." <> 0) then
                Error(CannotChangePrepmtAmtDiffVAtPctErr);
            CopyPrepaymentFromVATPostingSetup(VATPostingSetup);
            "Prepayment Tax Group Code" := GLAcc."Tax Group Code";
        end;
    end;

    /// <summary>
    /// Updates the prepayment amounts on the sales line to reflect changes in the outstanding amount.
    /// </summary>
    protected procedure UpdatePrepmtAmounts()
    var
        OutstandingAmountExclTax: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrepmtAmounts(Rec, SalesHeader, IsHandled, xRec, CurrFieldNo);
        if IsHandled then
            exit;

        if (Rec.Quantity <> 0) and (Rec."Outstanding Quantity" = 0) and (Rec."Qty. Shipped Not Invoiced" = 0) then
            if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then
                exit;

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then begin
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

    procedure CalculateOutstandingAmountExclTax(): Decimal
    var
        OutstandingAmount: Decimal;
        QuantityNotInvoiced: Decimal;
    begin
        if Rec.Quantity = 0 then
            exit(0);
        QuantityNotInvoiced := (Rec.Quantity - Rec."Quantity Invoiced");
        OutstandingAmount := (Rec."Line Amount" - Rec."Inv. Discount Amount") * QuantityNotInvoiced / Rec.Quantity;
        exit(OutstandingAmount);
    end;

    local procedure CheckLineAmount(MaxLineAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLineAmount(Rec, MaxLineAmount, IsHandled);
        if IsHandled then
            exit;

        if "Line Amount" < 0 then
            if "Line Amount" < MaxLineAmount then
                Error(LineAmountInvalidErr);

        if "Line Amount" > 0 then
            if "Line Amount" > MaxLineAmount then
                Error(LineAmountInvalidErr);
    end;

    procedure CheckPrepmtAmounts()
    var
        RemLineAmountToInvoice: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtAmounts(Rec, IsHandled, xRec, CurrFieldNo, SalesHeader);
        if IsHandled then
            exit;

        if "Prepayment %" <> 0 then begin
            if "System-Created Entry" then
                if Type = Type::"G/L Account" then
                    if not IsServiceChargeLine() then
                        exit;
            if Quantity < 0 then
                FieldError(Quantity, StrSubstNo(Text047, FieldCaption("Prepayment %")));
            if "Unit Price" < 0 then
                FieldError("Unit Price", StrSubstNo(Text047, FieldCaption("Prepayment %")));
        end;
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then begin
            if (("Prepmt. Line Amount" + Currency."Amount Rounding Precision") < "Prepmt. Amt. Inv.") and (SalesHeader.Status <> SalesHeader.Status::Released) then begin
                if IsServiceChargeLine() then
                    Error(CannotChangePrepaidServiceChargeErr);
                if "Inv. Discount Amount" <> 0 then
                    Error(InvDiscForPrepmtExceededErr, "Document No.");
                ThrowWrongAmountError();
            end;
            if "Prepmt. Line Amount" <> 0 then begin
                RemLineAmountToInvoice := GetLineAmountToHandleInclPrepmt(Quantity - "Quantity Invoiced");
                if RemLineAmountToInvoice < ("Prepmt Amt to Deduct" - "Prepmt Amt Deducted") then
                    FieldError("Prepmt Amt to Deduct", StrSubstNo(Text045, RemLineAmountToInvoice + "Prepmt Amt Deducted"));
            end;
        end else
            if (CurrFieldNo <> 0) and ("Line Amount" <> xRec."Line Amount") and
               ("Prepmt. Amt. Inv." <> 0) and ("Prepayment %" = 100)
            then begin
                if "Line Amount" < xRec."Line Amount" then
                    FieldError("Line Amount", StrSubstNo(Text044, xRec."Line Amount"));
                FieldError("Line Amount", StrSubstNo(Text045, xRec."Line Amount"));
            end;
    end;

    procedure ThrowWrongAmountError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeThrowWrongAmountError(Rec, IsHandled);
        if IsHandled then
            exit;

        FieldError("Prepmt. Line Amount", StrSubstNo(Text049, "Prepmt. Amt. Inv."));
    end;

    local procedure CheckPrepmtAmtInvEmpty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtAmtInvEmpty(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Prepmt. Amt. Inv." <> 0) and (Rec."VAT Prod. Posting Group" <> xRec."VAT Prod. Posting Group") then
            Error(CannotChangeVATGroupWithPrepmInvErr);
    end;

    local procedure CheckLinkedBlanketOrderLineOnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLinkedBlanketOrderLineOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Blanket Order" then begin
            SalesLine2.Reset();
            SalesLine2.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
            SalesLine2.SetRange("Blanket Order No.", "Document No.");
            SalesLine2.SetRange("Blanket Order Line No.", "Line No.");
            if SalesLine2.FindFirst() then
                SalesLine2.TestField("Blanket Order Line No.", 0);
        end;
    end;

    /// <summary>
    /// Updates line, prepayment, deferral, and VAT amounts for the sales line
    /// to account for any changes of the sales line that affect the amounts.
    /// </summary>
    procedure UpdateAmounts()
    var
        VATBaseAmount: Decimal;
        LineAmount: Decimal;
        LineAmountChanged: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::" " then
            exit;

        GetSalesHeader();
        VATBaseAmount := "VAT Base Amount";
        "Recalculate Invoice Disc." := "Allow Invoice Disc.";

        IsHandled := false;
        OnUpdateAmountsOnBeforeCheckLineAmount(IsHandled, Rec, xRec);
        if not IsHandled then
            if Rec."Line Amount" <> xRec."Line Amount" then begin
                "VAT Difference" := 0;
                LineAmountChanged := true;
            end;

        LineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") - "Line Discount Amount";
        OnUpdateAmountsOnAfterCalcLineAmount(Rec, LineAmount);
        if "Line Amount" <> LineAmount then begin
            "Line Amount" := LineAmount;
            LineAmountChanged := true;
            ClearVATDifference();
        end;

        if not "Prepayment Line" then
            UpdatePrepmtAmounts();

        OnAfterUpdateAmounts(Rec, xRec, CurrFieldNo);

        UpdateVATAmounts();
        UpdateVATRoundingFromVATAmountLines();
        InitOutstandingAmount();

        CheckCreditLimit();

        if Type = Type::"Charge (Item)" then
            UpdateItemChargeAssgnt();

        CalcPrepaymentToDeduct();
        if VATBaseAmount <> "VAT Base Amount" then
            LineAmountChanged := true;

        if LineAmountChanged then begin
            UpdateDeferralAmounts();
            LineAmountChanged := false;
        end;

        OnAfterUpdateAmountsDone(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// Updates the VAT amounts on the sales line based on the VAT calculation type and other line details
    /// to reflect changes in fields that affect them, like line amount, VAT %, and others.
    /// </summary>
    procedure UpdateVATAmounts()
    var
        SalesLine2: Record "Sales Line";
        TotalLineAmount: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalVATDifference: Decimal;
        TotalQuantityBase: Decimal;
        TotalVATBaseAmount: Decimal;
        IsHandled: Boolean;
        LineIsInvDiscountAmount: Boolean;
    begin
        OnBeforeUpdateVATAmounts(Rec);

        GetSalesHeader();
        SalesLine2.SetRange("Document Type", "Document Type");
        SalesLine2.SetRange("Document No.", "Document No.");
        SalesLine2.SetFilter("Line No.", '<>%1', "Line No.");
        SalesLine2.SetRange("VAT Identifier", "VAT Identifier");
        SalesLine2.SetRange("Tax Group Code", "Tax Group Code");
        SalesLine2.SetRange("Tax Area Code", "Tax Area Code");

        IsHandled := false;
        OnUpdateVATAmountsOnAfterSetSalesLineFilters(Rec, SalesLine2, IsHandled);
        if IsHandled then
            exit;

        LineIsInvDiscountAmount := "Line Amount" = "Inv. Discount Amount";
        OnUpdateVATAmountsOnBeforeIfLineIsInvDiscountAmount(Rec, LineIsInvDiscountAmount);
        if LineIsInvDiscountAmount then begin
            Amount := 0;
            "VAT Base Amount" := 0;
            "Amount Including VAT" := 0;
            OnUpdateVATAmountOnAfterSetZeroAmointIfLineIsInvDiscountAmount(Rec);
            if (Quantity = 0) and (xRec.Quantity <> 0) and (xRec.Amount <> 0) then begin
                if "Line No." <> 0 then
                    Modify();
                SalesLine2.SetFilter(Amount, '<>0');
                if SalesLine2.Find('<>') then begin
                    OnUpdateVATAmountsOnBeforeValidateLineDiscountPercent(SalesLine2, StatusCheckSuspended);
                    SalesLine2.ValidateLineDiscountPercent(false);
                    SalesLine2.Modify();
                end;
            end;
        end else begin
            TotalLineAmount := 0;
            TotalInvDiscAmount := 0;
            TotalAmount := 0;
            TotalAmountInclVAT := 0;
            TotalQuantityBase := 0;
            TotalVATBaseAmount := 0;
            if ("VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax") or
               (("VAT Calculation Type" in
                 ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"]) and ("VAT %" <> 0))
            then begin
                SalesLine2.SetFilter("VAT %", '<>0');
                if not SalesLine2.IsEmpty() then begin
                    SalesLine2.CalcSums("Line Amount", "Inv. Discount Amount", Amount, "Amount Including VAT", "Quantity (Base)", "VAT Difference", "VAT Base Amount");
                    TotalLineAmount := SalesLine2."Line Amount";
                    TotalInvDiscAmount := SalesLine2."Inv. Discount Amount";
                    TotalAmount := SalesLine2.Amount;
                    TotalAmountInclVAT := SalesLine2."Amount Including VAT";
                    TotalVATDifference := SalesLine2."VAT Difference";
                    TotalQuantityBase := SalesLine2."Quantity (Base)";
                    TotalVATBaseAmount := SalesLine2."VAT Base Amount";
                    OnAfterUpdateTotalAmounts(Rec, SalesLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount);
                end;
            end;

            OnUpdateVATAmountsOnBeforeCalcAmounts(
                Rec, SalesLine2, TotalAmount, TotalAmountInclVAT, TotalLineAmount, TotalInvDiscAmount, TotalVATBaseAmount, TotalQuantityBase, IsHandled, TotalVATDifference);
            if IsHandled then
                exit;

            if SalesHeader."Prices Including VAT" then
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
                                Amount * (1 - GetVatBaseDiscountPct(SalesHeader) / 100),
                                Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalLineAmount + "Line Amount" -
                              Round(
                                (TotalAmount + Amount) * (GetVatBaseDiscountPct(SalesHeader) / 100) * GetVATPct() / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT - TotalInvDiscAmount - "Inv. Discount Amount";
                            OnUpdatePricesIncludingVATAmountsOnAfterCalculateNormalVAT(Rec, Currency);
                        end;
                    "VAT Calculation Type"::"Full VAT":
                        begin
                            Amount := 0;
                            "VAT Base Amount" := 0;
                            "Amount Including VAT" := ROUND(CalcLineAmount(), Currency."Amount Rounding Precision");
                        end;
                    "VAT Calculation Type"::"Sales Tax":
                        begin
                            SalesHeader.TestField("VAT Base Discount %", 0);
                            Amount :=
                              SalesTaxCalculate.ReverseCalculateTax(
                                "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                TotalAmountInclVAT + "Amount Including VAT", TotalQuantityBase + "Quantity (Base)",
                                SalesHeader."Currency Factor") -
                              TotalAmount;
                            OnAfterSalesTaxCalculateReverse(Rec, SalesHeader, Currency);
                            UpdateVATPercent(Amount, "Amount Including VAT" - Amount);
                            Amount := Round(Amount, Currency."Amount Rounding Precision");
                            "VAT Base Amount" := Amount;
                        end;
                end
            else
                case "VAT Calculation Type" of
                    "VAT Calculation Type"::"Normal VAT",
                    "VAT Calculation Type"::"Reverse Charge VAT":
                        begin
                            Amount := Round(CalcLineAmount(), Currency."Amount Rounding Precision");
                            "VAT Base Amount" :=
                              Round(Amount * (1 - GetVatBaseDiscountPct(SalesHeader) / 100), Currency."Amount Rounding Precision");
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                (TotalAmount + Amount) * (1 - GetVatBaseDiscountPct(SalesHeader) / 100) * GetVATPct() / 100,
                                Currency."Amount Rounding Precision", Currency.VATRoundingDirection()) -
                              TotalAmountInclVAT + TotalVATDifference;
                            OnUpdateVATAmountsOnAfterCalculateNormalVAT(Rec, Currency);
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
                            "Amount Including VAT" :=
                              TotalAmount + Amount +
                              Round(
                                SalesTaxCalculate.CalculateTax(
                                  "Tax Area Code", "Tax Group Code", "Tax Liable", SalesHeader."Posting Date",
                                  TotalAmount + Amount, TotalQuantityBase + "Quantity (Base)",
                                  SalesHeader."Currency Factor"), Currency."Amount Rounding Precision") -
                              TotalAmountInclVAT;
                            OnAfterSalesTaxCalculate(Rec, SalesHeader, Currency);
                            UpdateVATPercent("VAT Base Amount", "Amount Including VAT" - "VAT Base Amount");
                        end;
                end;
        end;

        OnAfterUpdateVATAmounts(Rec, Currency);
    end;

    local procedure InitQty()
    var
        IsHandled: Boolean;
        ShouldInitQty: Boolean;
    begin
        IsHandled := false;
        ShouldInitQty := (xRec.Quantity <> Quantity) or (xRec."Quantity (Base)" <> "Quantity (Base)");
        OnBeforeInitQty(Rec, xRec, IsAsmToOrderAllowed(), IsAsmToOrderRequired(), IsHandled, ShouldInitQty);
        if IsHandled then
            exit;

        if ShouldInitQty then begin
            InitOutstanding();
            if IsCreditDocType() then
                InitQtyToReceive()
            else
                InitQtyToShip();
            InitQtyToAsm();
            SetDefaultQuantity();
        end;
    end;

    /// <summary>
    /// Verifies the availability of the item on the shipment date.
    /// If the item is not available, a notification is shown and an error is raised to stop the update.
    /// </summary>
    /// <remarks>
    /// The check is only performed if CalledByFieldNo matches the field that initated the call stack (CurrFieldNo).
    /// If the shipment date is empty, it's set from either the header or the current work date.
    /// </remarks>
    /// <param name="CalledByFieldNo">The field no. of the field that initiated the check.</param>
    procedure CheckItemAvailable(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailable(Rec, CalledByFieldNo, IsHandled, CurrFieldNo, xRec, SalesHeader);
        if IsHandled then
            exit;

        if "Shipment Date" = 0D then begin
            GetSalesHeader();
            if SalesHeader."Shipment Date" <> 0D then
                Validate("Shipment Date", SalesHeader."Shipment Date")
            else
                Validate("Shipment Date", WorkDate());
        end;

        if ((CalledByFieldNo = CurrFieldNo) or (CalledByFieldNo = FieldNo("Shipment Date"))) and GuiAllowed and
           ("Document Type" in ["Document Type"::Order, "Document Type"::Invoice]) and
           (Type = Type::Item) and ("No." <> '') and
           ("Outstanding Quantity" > 0) and
           ("Job Contract Entry No." = 0) and
           not "Special Order"
        then begin
            IsHandled := false;
            OnCheckItemAvailableOnBeforeSalesLineCheck(Rec, CalledByFieldNo, CurrFieldNo, xRec, IsHandled);
            if not IsHandled then
                if ItemCheckAvail.SalesLineCheck(Rec) then
                    ItemCheckAvail.RaiseUpdateInterruptedError();
        end;

        OnAfterCheckItemAvailable(Rec, CalledByFieldNo, HideValidationDialog);
    end;

    local procedure CheckCreditLimit()
    var
        IsHandled: Boolean;
    begin
        if (CurrFieldNo <> 0) and
           not ((Type = Type::Item) and (CurrFieldNo = FieldNo("No.")) and (Quantity <> 0) and
                ("Qty. per Unit of Measure" <> xRec."Qty. per Unit of Measure")) and
           CheckCreditLimitCondition() and
           (("Outstanding Amount" + "Shipped Not Invoiced") > 0) and
           (CurrFieldNo <> FieldNo("Blanket Order No.")) and
           (CurrFieldNo <> FieldNo("Blanket Order Line No."))
        then begin
            IsHandled := false;
            OnUpdateAmountOnBeforeCheckCreditLimit(Rec, IsHandled, CurrFieldNo);
            if not IsHandled then
                CustCheckCreditLimit.SalesLineCheck(Rec);
        end;
    end;

    local procedure CheckBinCodeRelation()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeRelation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not IsInbound() and ("Quantity (Base)" <> 0) and ("Qty. to Asm. to Order (Base)" = 0) then
            WMSManagement.FindBinContent("Location Code", "Bin Code", "No.", "Variant Code", '')
        else
            WMSManagement.FindBin("Location Code", "Bin Code", '');
    end;

    local procedure CheckCreditLimitCondition(): Boolean
    var
        RunCheck: Boolean;
    begin
        RunCheck := "Document Type".AsInteger() <= "Document Type"::Invoice.AsInteger();
        OnAfterCheckCreditLimitCondition(Rec, RunCheck);
        exit(RunCheck);
    end;

    /// <summary>
    /// Opens a Order Tracking summary page for the current sales line.
    /// </summary>
    procedure ShowOrderTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Outstanding Qty. (Base)", Rec."Shipment Date", Rec."Shipment Date");
        OrderTracking.RunModal();
    end;

    /// <summary>
    /// Opens a reservation summary page for the current sales line.
    /// After the page closes, updates the planned status of the line.
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
        TestField("No.");
        TestField(Reserve);
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
        UpdatePlanned();
    end;

    /// <summary>
    /// Opens a reservation entries page for the current sales line.
    /// </summary>
    /// <param name="Modal">If true, execution is paused until the page is closed.</param>
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

    /// <summary>
    /// Attempts to automatically reserve the quantity of the current sales line based on the item availability.
    /// If the quantity cannot be reserved automatically, a message is shown and the user is prompted to reserve manually.
    /// </summary>
    procedure AutoReserve()
    begin
        AutoReserve(true);
    end;

    /// <summary>
    /// Attempts to automatically reserve the quantity of the current sales line based on the item availability.
    /// </summary>
    /// <param name="ShowReservationForm">If true, when the quantity cannot be reserved automatically, a message is shown and the user is prompted to reserve manually.</param>
    procedure AutoReserve(ShowReservationForm: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        ReservMgt: Codeunit "Reservation Management";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(Rec, IsHandled, xRec, FullAutoReservation, SalesLineReserve);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        GetItem(Item);
        if IsNonInventoriableItem() and (Reserve = Reserve::Never) then
            Error(NonInvReserveTypeErr, Item."No.", Reserve);

        SalesLineReserve.ReservQuantity(Rec, QtyToReserve, QtyToReserveBase);
        if QtyToReserveBase <> 0 then begin
            TestField("Shipment Date");
            ReservMgt.SetReservSource(Rec);
            ReservMgt.AutoReserve(FullAutoReservation, '', "Shipment Date", QtyToReserve, QtyToReserveBase);
            CalcFields("Reserved Quantity");
            Find();
            SalesSetup.Get();
            if (not FullAutoReservation) and (not SalesSetup."Skip Manual Reservation") and ShowReservationForm then begin
                Commit();
                if ConfirmManagement.GetResponse(ManualReserveQst, true) then begin
                    Rec.ShowReservation();
                    Find();
                end;
            end;
        end;

        OnAfterAutoReserve(Rec);
    end;

    /// <summary>
    /// Creates or updates the assembly order associated with the sales line to reflect the current line details.
    /// </summary>
    procedure AutoAsmToOrder()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoAsmToOrder(Rec, IsHandled, CurrFieldNo, ATOLink);
        if IsHandled then
            exit;

        ATOLink.UpdateAsmFromSalesLine(Rec);

        OnAfterAutoAsmToOrder(Rec);
    end;

    /// <summary>
    /// Retrieves the date to be used for operations on the sales line, which is the associated sales header's posting date or the work date if the posting date is not set.
    /// </summary>
    /// <returns>The date to be used for operations on the sales line.</returns>
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

        GetSalesHeader();
        if SalesHeader."Posting Date" <> 0D then
            exit(SalesHeader."Posting Date");
        exit(WorkDate());
    end;

    /// <summary>
    /// Calculates the planned delivery date based on the shipping agent, planned shipment date
    /// and the field that initiated the calculation.
    /// </summary>
    /// <param name="CurrFieldNo">The field number of the field that initiated the calculation.</param>
    /// <returns>The calculated planned delivery date.</returns>
    procedure CalcPlannedDeliveryDate(CurrFieldNo: Integer) PlannedDeliveryDate: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        PlannedDeliveryDate := "Planned Delivery Date";
        OnBeforeCalcPlannedDeliveryDate(Rec, PlannedDeliveryDate, CurrFieldNo, IsHandled);
        if IsHandled then
            exit(PlannedDeliveryDate);

        if CurrFieldNo = FieldNo("Requested Delivery Date") then
            exit("Requested Delivery Date");

        if ("Shipment Date" = 0D) and (CurrFieldNo <> FieldNo("Planned Delivery Date")) then
            exit("Planned Delivery Date");

        CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        case CurrFieldNo of
            FieldNo("Shipment Date"):
                begin
                    if CheckCustomerBaseCalendarCodeExist() then
                        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Customer, "Sell-to Customer No.", '', '')
                    else
                        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format("Shipping Time"), "Planned Shipment Date", CustomCalendarChange, true));
                end;
            FieldNo("Planned Delivery Date"):
                begin
                    CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    exit(CalendarMgmt.CalcDateBOC2(Format("Shipping Time"), "Planned Delivery Date", CustomCalendarChange, true));
                end;
        end;
    end;

    procedure CheckCustomerBaseCalendarCodeExist(): Boolean
    var
        Customer: Record customer;
    begin
        if "Sell-to Customer No." = '' then
            exit(false);

        Customer.SetLoadFields("Base Calendar Code");
        if Customer.Get("Sell-to Customer No.") then
            exit(Customer."Base Calendar Code" <> '');
    end;

    /// <summary>
    /// Calculates the planned shipment date based on the shipping agent and the field that initiated the calculation.
    /// </summary>
    /// <param name="CurrFieldNo">The field number of the field that initiated the calculation.</param>
    /// <returns>The calculated planned shipment date.</returns>
    procedure CalcPlannedShptDate(CurrFieldNo: Integer) PlannedShipmentDate: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        IsHandled: Boolean;
    begin
        OnBeforeCalcPlannedShptDate(Rec, PlannedShipmentDate, CurrFieldNo, IsHandled);
        if IsHandled then
            exit(PlannedShipmentDate);

        if "Shipment Date" = 0D then
            exit("Planned Shipment Date");

        CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        case CurrFieldNo of
            FieldNo("Shipment Date"):
                begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format("Outbound Whse. Handling Time"), "Shipment Date", CustomCalendarChange, true));
                end;
            FieldNo("Planned Delivery Date"):
                begin
                    CustomCalendarChange[1].SetSource(CalChange."Source Type"::Customer, "Sell-to Customer No.", '', '');
                    exit(CalendarMgmt.CalcDateBOC(Format(''), "Planned Delivery Date", CustomCalendarChange, true));
                end;
        end;
    end;

    /// <summary>
    /// Calculates the shipment date based on the shipping agent, location and planned shipment date.
    /// </summary>
    /// <returns>The calculated shipment date.</returns>
    procedure CalcShipmentDate(): Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        ShipmentDate: Date;
        IsHandled: Boolean;
    begin
        if "Planned Shipment Date" = 0D then
            exit("Shipment Date");

        IsHandled := false;
        OnCalcShipmentDateOnPlannedShipmentDate(Rec, ShipmentDate, IsHandled);
        if IsHandled then
            exit(ShipmentDate);

        if Format("Outbound Whse. Handling Time") <> '' then begin
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
            exit(CalendarMgmt.CalcDateBOC2(Format("Outbound Whse. Handling Time"), "Planned Shipment Date", CustomCalendarChange, false));
        end;

        CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", "Shipping Agent Code", "Shipping Agent Service Code", '');
        CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, "Location Code", '', '');
        exit(CalendarMgmt.CalcDateBOC(Format(Format('')), "Planned Shipment Date", CustomCalendarChange, false));
    end;

    /// <summary>
    /// Adjusts the sign of the provided value based on the document type of the sales line.
    /// </summary>
    /// <param name="Value">The value to adjust the sign of.</param>
    /// <returns>The value with its sign adjusted based on the document type.</returns>
    procedure SignedXX(Value: Decimal): Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSignedXX(Rec, Value, IsHandled);
        if IsHandled then
            exit(Value);

        case "Document Type" of
            "Document Type"::Quote,
          "Document Type"::Order,
          "Document Type"::Invoice,
          "Document Type"::"Blanket Order":
                exit(-Value);
            "Document Type"::"Return Order",
          "Document Type"::"Credit Memo":
                exit(Value);
        end;
    end;

    local procedure BlanketOrderLookup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBlanketOrderLookup(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine2.Reset();
        SalesLine2.SetCurrentKey("Document Type", Type, "No.");
        SalesLine2.SetRange("Document Type", "Document Type"::"Blanket Order");
        SalesLine2.SetRange(Type, Type);
        SalesLine2.SetRange("No.", "No.");
        SalesLine2.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
        SalesLine2.SetRange("Sell-to Customer No.", "Sell-to Customer No.");
        if PAGE.RunModal(PAGE::"Sales Lines", SalesLine2) = ACTION::LookupOK then begin
            SalesLine2.TestField("Document Type", "Document Type"::"Blanket Order");
            "Blanket Order No." := SalesLine2."Document No.";
            Validate("Blanket Order Line No.", SalesLine2."Line No.");
        end;

        OnAfterBlanketOrderLookup(Rec);
    end;

    /// <summary>
    /// Opens a page for editing dimensions for the sale line.
    /// After the page closes, updates the dimensions on the sales line and assembly orders.
    /// </summary>
    /// <remarks>
    /// If the dimensions are changed for a line that is already shipped, a confirmation is raised.
    /// If not confirmed, and error is raised to stop the update.
    /// </remarks>
    /// <returns>True if the dimensions were changed, otherwise, false.</returns>
    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, xRec, IsHandled, IsChanged);
        if IsHandled then
            exit(IsChanged);

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."));
        OnShowDimensionsOnAfterEditDimensionSet(Rec, OldDimSetID);

        VerifyItemLineDim();
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        ATOLink.UpdateAsmDimFromSalesLine(Rec);
        IsChanged := OldDimSetID <> "Dimension Set ID";

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Opens a page for editing item tracking lines for the sale line.
    /// </summary>
    procedure OpenItemTrackingLines()
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        TestField("Quantity (Base)");
        if "Job Contract Entry No." <> 0 then
            Error(Text048, TableCaption(), Job.TableCaption());

        IsHandled := false;
        OnBeforeCallItemTracking(Rec, IsHandled);
        if not IsHandled then
            SalesLineReserve.CallItemTracking(Rec);

        OnAfterOpenItemTrackingLines(Rec);
    end;

    /// <summary>
    /// Initializes dimensions on the sales line for the provided list of default dimension sources.
    /// </summary>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(IsHandled, Rec, CurrFieldNo, DefaultDimSource);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetSalesHeader();
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Sales,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", SalesHeader."Dimension Set ID", Database::Customer);

        OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(Rec);
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        ATOLink.UpdateAsmDimFromSalesLine(Rec);

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, DefaultDimSource);
    end;

    /// <summary>
    /// Checks if the provided shortcut dimension code and value are valid.
    /// </summary>
    /// <remarks>
    /// Checks include if the dimension or value are blocked or if the value is allowed.
    /// </remarks>
    /// <param name="FieldNumber">The number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">The value of the shortcut dimension.</param>
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

    /// <summary>
    /// Opens a page for looking up a shortcut dimension code value.
    /// </summary>
    /// <remarks>
    /// If the dimensions are changed for a line that is already shipped, a confirmation is raised.
    /// If not confirmed, and error is raised to stop the update.
    /// </remarks>
    /// <param name="FieldNumber">The number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Return value: The value of the shortcut dimension.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Gets an array of shortcut dimension values from the dimensions of the sales line.
    /// </summary>
    /// <param name="ShortcutDimCode">Return value: The array of shortcut dimension values.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Opens a page for selecting multiple items to add to the document.
    /// Selected items are added to the document.
    /// </summary>
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
            SelectionFilter := ItemListPage.SelectActiveItemsForSale();
        if SelectionFilter <> '' then
            AddItems(SelectionFilter);

        OnAfterSelectMultipleItems(Rec);
    end;

    /// <summary>
    /// Adds items to the document based on the provided selection filter.
    /// </summary>
    /// <param name="SelectionFilter">The filter to use for selecting items.</param>
    procedure AddItems(SelectionFilter: Text)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddItems(Rec, SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        InitNewLine(SalesLine);
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet() then
            repeat
                AddItem(SalesLine, Item."No.");
            until Item.Next() = 0;
    end;

    /// <summary>
    /// Adds an item to the document.
    /// </summary>
    /// <remarks>
    /// After the line is added, assembly order is automatically created if required.
    /// If the item has extended text, the text is added as a line.
    /// </remarks>
    /// <param name="SalesLine">Return value: The added sales line. Sales line must have the document type and number set.</param>
    /// <param name="ItemNo">Return value: The number of the item to add.</param>
    procedure AddItem(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.Init();
        SalesLine."Line No." += 10000;
        SalesLine.Validate(Type, Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Insert(true);

        ProcessSalesLine(SalesLine);
    end;

    /// <summary>
    /// Creates or updates assembly orders if assemble-to-order is required.
    /// Creates extended text lines applicable to the provided sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to process.</param>
    procedure ProcessSalesLine(var SalesLine: Record "Sales Line")
    var
        LastSalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessSalesLine(SalesLine, IsHandled);
        if not IsHandled then begin
            if SalesLine.IsAsmToOrderRequired() then
                SalesLine.AutoAsmToOrder();

            if TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false) then begin
                TransferExtendedText.InsertSalesExtTextRetLast(SalesLine, LastSalesLine);
                SalesLine."Line No." := LastSalesLine."Line No."
            end;
        end;

        OnAfterAddItem(SalesLine, LastSalesLine);
    end;

    /// <summary>
    /// Initializes a new sales line based on the current sales line.
    /// </summary>
    /// <param name="NewSalesLine">Return value: The new sales line.</param>
    procedure InitNewLine(var NewSalesLine: Record "Sales Line")
    var
        SalesLine: Record "Sales Line";
    begin
        NewSalesLine.Copy(Rec);
        SalesLine.SetRange("Document Type", NewSalesLine."Document Type");
        SalesLine.SetRange("Document No.", NewSalesLine."Document No.");
        if SalesLine.FindLast() then
            NewSalesLine."Line No." := SalesLine."Line No."
        else
            NewSalesLine."Line No." := 0;
    end;

    /// <summary>
    /// Opens a page for looking up item substitutions for the current item on the sales line.
    /// If substitution is selected, the item is replaced with the selected item.
    /// </summary>
    /// <remarks>
    /// If item is substituted, it also adds any extended text for the new item.
    /// </remarks>
    procedure ShowItemSub()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemSub(Rec, IsHandled);
        if IsHandled then
            exit;

        Clear(SalesHeader);
        TestStatusOpen();
        if ItemSubstitutionMgt.ItemSubstGet(Rec) then begin
            Rec.Validate("Location Code");
            if TransferExtendedText.SalesCheckIfAnyExtText(Rec, false) then
                TransferExtendedText.InsertSalesExtText(Rec);
        end;
        OnAfterShowItemSub(Rec);
    end;

    /// <summary>
    /// Opens a page for selecting a nonstock item to add to the document.
    /// If a nonstock item is selected, it is added to the document and the unit price is updated.
    /// </summary>
    procedure ShowNonstock()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowNonStock(Rec, NonstockItem, IsHandled);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        if "No." <> '' then
            Error(SelectNonstockItemErr);

        OnShowNonstockOnBeforeOpenCatalogItemList(Rec, NonstockItem);
        if PAGE.RunModal(PAGE::"Catalog Item List", NonstockItem) = ACTION::LookupOK then begin
            CheckNonstockItemTemplate(NonstockItem);

            "No." := NonstockItem."Entry No.";
            CatalogItemMgt.NonStockSales(Rec);
            Validate("No.", "No.");
            UpdateUnitPriceFromNonstockItem();

            OnAfterShowNonStock(Rec, NonstockItem);
        end;
    end;

    local procedure UpdateUnitPriceFromNonstockItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitPriceFromNonstockItem(Rec, NonstockItem, IsHandled);
        if IsHandled then
            exit;

        Validate("Unit Price", NonstockItem."Unit Price");
    end;

    local procedure GetSalesSetup()
    begin
        if not SalesSetupRead then
            SalesSetup.Get();
        SalesSetupRead := true;

        OnAfterGetSalesSetup(Rec, SalesSetup);
    end;

    /// <summary>
    /// Sets tax and posting groups codes for a fixed asset sales line.
    /// </summary>
    procedure GetFAPostingGroup()
    var
        LocalGLAcc: Record "G/L Account";
        FAPostingGr: Record "FA Posting Group";
        FADeprBook: Record "FA Depreciation Book";
        ShouldExit: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFAPostingGroup(Rec, IsHandled);
        if IsHandled then
            exit;

        if (Type <> Type::"Fixed Asset") or ("No." = '') then
            exit;

        if "Depreciation Book Code" = '' then begin
            "Depreciation Book Code" := GetFADeprBook("No.");
            ShouldExit := "Depreciation Book Code" = '';
            OnGetGetFAPostingGroupOnBeforeExit(Rec, ShouldExit);
            if ShouldExit then
                exit;
        end;

        FADeprBook.Get("No.", "Depreciation Book Code");
        FADeprBook.TestField("FA Posting Group");
        FAPostingGr.GetPostingGroup(FADeprBook."FA Posting Group", FADeprBook."Depreciation Book Code");
        LocalGLAcc.Get(FAPostingGr.GetAcquisitionCostAccountOnDisposal());
        LocalGLAcc.CheckGLAcc();
        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            LocalGLAcc.TestField("Gen. Prod. Posting Group");
        "Posting Group" := FADeprBook."FA Posting Group";
        "Gen. Prod. Posting Group" := LocalGLAcc."Gen. Prod. Posting Group";
        "Tax Group Code" := LocalGLAcc."Tax Group Code";
        Validate("VAT Prod. Posting Group", LocalGLAcc."VAT Prod. Posting Group");

        OnAfterGetFAPostingGroup(Rec, LocalGLAcc);
    end;

    /// <summary>
    /// Gets a caption class for a field.
    /// </summary>
    /// <param name="FieldNumber">The number of the field to get the caption class for.</param>
    /// <returns>The caption class of a field.</returns>
    procedure GetCaptionClass(FieldNumber: Integer): Text[80]
    var
        SalesLineCaptionClassMgmt: Codeunit "Sales Line CaptionClass Mgmt";
    begin
        exit(SalesLineCaptionClassMgmt.GetSalesLineCaptionClass(Rec, FieldNumber));
    end;

    /// <summary>
    /// Gets a stockkeeping unit for the current sales line and saves it in a global variable SKU.
    /// </summary>
    /// <returns>True if a stockkeeping unit was found, otherwise, false.</returns>
    procedure GetSKU() Result: Boolean
    begin
        exit(GetSKU(SKU));
    end;

    /// <summary>
    /// Gets a stockkeeping unit for the current sales line.
    /// </summary>
    /// <param name="StockkeepingUnit">Return value: The stockkeeping unit for the current sales line.</param>
    /// <returns>True if a stockkeeping unit was found, otherwise, false.</returns>
    procedure GetSKU(var StockkeepingUnit: Record "Stockkeeping Unit") Result: Boolean
    begin
        if (StockkeepingUnit."Location Code" = "Location Code") and
           (StockkeepingUnit."Item No." = "No.") and
           (StockkeepingUnit."Variant Code" = "Variant Code")
        then
            exit(true);

        if StockkeepingUnit.Get("Location Code", "No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result, StockkeepingUnit);
    end;

    /// <summary>
    /// Finds and assigns the unit cost for the item specified on the sales line.
    /// </summary>
    procedure GetUnitCost()
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUnitCost(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        TestField(Type, Type::Item);
        TestField("No.");
        GetItem(Item);
        "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        ValidateUnitCostLCYOnGetUnitCost(Item);

        OnAfterGetUnitCost(Rec, Item);
    end;

    local procedure CalcUnitCost(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ValueEntry: Record "Value Entry";
        UnitCost: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if IsNonInventoriableItem() then begin
            ValueEntry.CalcSums("Cost Amount (Non-Invtbl.)");
            UnitCost := ValueEntry."Cost Amount (Non-Invtbl.)" / ItemLedgEntry.Quantity;
        end else begin
            ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
            UnitCost :=
              (ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)") / ItemLedgEntry.Quantity;
        end;

        exit(Abs(UnitCost * "Qty. per Unit of Measure"));
    end;

    /// <summary>
    /// Opens a page for editing item charge assignment for the item charge sales line.
    /// If assignments don't exist for the item charge, new assignments are created and committed before opening the page.
    /// </summary>
    procedure ShowItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        AssignItemChargeSales: Codeunit "Item Charge Assgnt. (Sales)";
        ItemChargeAssgnts: Page "Item Charge Assignment (Sales)";
        ItemChargeAssgntLineAmt: Decimal;
        IsHandled: Boolean;
        DoCreateDocChargeAssgnForReturnReceiptNo: Boolean;
    begin
        Get("Document Type", "Document No.", "Line No.");
        TestField("No.");
        TestField(Quantity);

        if Type <> Type::"Charge (Item)" then begin
            Message(ItemChargeAssignmentErr);
            exit;
        end;

        GetSalesHeader();
        Currency.Initialize(SalesHeader."Currency Code");
        OnShowItemChargeAssgntOnAfterCurrencyInitialize(Rec, SalesHeader, Currency);
        if ("Inv. Discount Amount" = 0) and ("Line Discount Amount" = 0) and
           (not SalesHeader."Prices Including VAT")
        then
            ItemChargeAssgntLineAmt := "Line Amount"
        else
            if SalesHeader."Prices Including VAT" then
                ItemChargeAssgntLineAmt :=
                  Round(CalcLineAmount() / (1 + GetVATPct() / 100), Currency."Amount Rounding Precision")
            else
                ItemChargeAssgntLineAmt := CalcLineAmount();

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntSales.SetRange("Item Charge No.", "No.");
        if not ItemChargeAssgntSales.FindLast() then begin
            ItemChargeAssgntSales."Document Type" := "Document Type";
            ItemChargeAssgntSales."Document No." := "Document No.";
            ItemChargeAssgntSales."Document Line No." := "Line No.";
            ItemChargeAssgntSales."Item Charge No." := "No.";
            ItemChargeAssgntSales."Unit Cost" :=
              Round(ItemChargeAssgntLineAmt / Quantity, Currency."Unit-Amount Rounding Precision");
        end;

        IsHandled := false;
        OnShowItemChargeAssgntOnBeforeCalcItemCharge(Rec, ItemChargeAssgntLineAmt, Currency, IsHandled, ItemChargeAssgntSales);
        if not IsHandled then
            ItemChargeAssgntLineAmt :=
              Round(ItemChargeAssgntLineAmt * ("Qty. to Invoice" / Quantity), Currency."Amount Rounding Precision");

        DoCreateDocChargeAssgnForReturnReceiptNo := IsCreditDocType();
        OnShowItemChargeAssgntOnBeforeCreateDocChargeAssgn(Rec, DoCreateDocChargeAssgnForReturnReceiptNo);
        if DoCreateDocChargeAssgnForReturnReceiptNo then
            AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales, "Return Receipt No.")
        else
            AssignItemChargeSales.CreateDocChargeAssgn(ItemChargeAssgntSales, "Shipment No.");
        Clear(AssignItemChargeSales);
        Commit();

        ItemChargeAssgnts.Initialize(Rec, ItemChargeAssgntLineAmt);
        ItemChargeAssgnts.RunModal();
        CalcFields("Qty. to Assign");

        OnAfterShowItemChargeAssgnt(Rec, ItemChargeAssgntSales);
    end;

    /// <summary>
    /// Updates amounts on item charge assignments for the current sales line.
    /// </summary>
    procedure UpdateItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        ShareOfVAT: Decimal;
        TotalQtyToAssign: Decimal;
        TotalAmtToAssign: Decimal;
        TotalQtyToHandle: Decimal;
        TotalAmtToHandle: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemChargeAssgnt(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Blanket Order" then
            exit;

        CalcFields("Qty. Assigned", "Qty. to Assign", "Item Charge Qty. to Handle");
        if Abs("Quantity Invoiced") > Abs(("Qty. Assigned" + "Qty. to Assign")) then
            Error(Text055, FieldCaption("Quantity Invoiced"), FieldCaption("Qty. Assigned"), FieldCaption("Qty. to Assign"));

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        ItemChargeAssgntSales.SetRange("Document Line No.", "Line No.");
        ItemChargeAssgntSales.CalcSums("Qty. to Assign", "Qty. to Handle");
        TotalQtyToAssign := ItemChargeAssgntSales."Qty. to Assign";
        TotalQtyToHandle := ItemChargeAssgntSales."Qty. to Handle";
        if (CurrFieldNo <> 0) and (Amount <> xRec.Amount) and
           not ((Quantity <> xRec.Quantity) and (TotalQtyToAssign = 0))
        then begin
            ItemChargeAssgntSales.SetFilter("Qty. Assigned", '<>0');
            if not ItemChargeAssgntSales.IsEmpty() then
                Error(Text026, FieldCaption(Amount));
            ItemChargeAssgntSales.SetRange("Qty. Assigned");
        end;

        if ItemChargeAssgntSales.FindSet(true) and (Quantity <> 0) then begin
            GetSalesHeader();
            TotalAmtToAssign := CalcTotalAmtToAssign(TotalQtyToAssign);
            TotalAmtToHandle := CalcTotalAmtToAssign(TotalQtyToHandle);
            repeat
                ShareOfVAT := 1;
                if SalesHeader."Prices Including VAT" then
                    ShareOfVAT := 1 + "VAT %" / 100;
                if Quantity <> 0 then
                    if ItemChargeAssgntSales."Unit Cost" <>
                       Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision")
                    then
                        ItemChargeAssgntSales."Unit Cost" :=
                          Round(CalcLineAmount() / Quantity / ShareOfVAT, Currency."Unit-Amount Rounding Precision");
                if TotalQtyToAssign <> 0 then begin
                    ItemChargeAssgntSales."Amount to Assign" :=
                        Round(ItemChargeAssgntSales."Qty. to Assign" / TotalQtyToAssign * TotalAmtToAssign,
                            Currency."Amount Rounding Precision");
                    TotalQtyToAssign -= ItemChargeAssgntSales."Qty. to Assign";
                    TotalAmtToAssign -= ItemChargeAssgntSales."Amount to Assign";
                    if TotalQtyToHandle <> 0 then begin
                        ItemChargeAssgntSales."Amount to Handle" :=
                            Round(ItemChargeAssgntSales."Qty. to Handle" / TotalQtyToHandle * TotalAmtToHandle,
                                Currency."Amount Rounding Precision");
                        TotalQtyToHandle -= ItemChargeAssgntSales."Qty. to Handle";
                        TotalAmtToHandle -= ItemChargeAssgntSales."Amount to Handle";
                    end;
                end;
                ItemChargeAssgntSales.Modify();
            until ItemChargeAssgntSales.Next() = 0;
            CalcFields("Qty. to Assign", "Item Charge Qty. to Handle");
        end;
    end;

    /// <summary>
    /// Deletes item charge assignments applied to a sales document line.
    /// </summary>
    /// <param name="DocType">Document type of the applied-to document.</param>
    /// <param name="DocNo">Document number of the applied-to document.</param>
    /// <param name="DocLineNo">Line number of the applied-to document.</param>
    procedure DeleteItemChargeAssignment(DocType: Enum "Sales Document Type"; DocNo: Code[20];
                                                      DocLineNo: Integer)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteItemChargeAssignment(DocType, DocNo, DocLineNo, IsHandled, CurrFieldNo);
        if not IsHandled then begin
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Type", DocType);
            ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", DocNo);
            ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", DocLineNo);
            if not ItemChargeAssgntSales.IsEmpty() then
                ItemChargeAssgntSales.DeleteAll(true);
        end;
        OnAfterDeleteItemChargeAssignment(Rec, xRec, CurrFieldNo, DocType, DocNo, DocLineNo);
    end;

    /// <summary>
    /// Deletes item charge assignments associated with a sales line.
    /// </summary>
    /// <param name="DocType">Document type of the sales line.</param>
    /// <param name="DocNo">Document number of the sales line.</param>
    /// <param name="DocLineNo">Document line number of the sales line.</param>
    protected procedure DeleteChargeChargeAssgnt(DocType: Enum "Sales Document Type"; DocNo: Code[20];
                                                              DocLineNo: Integer)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteChargeChargeAssgnt(DocType, DocNo, DocLineNo, Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if DocType <> "Document Type"::"Blanket Order" then
            if "Quantity Invoiced" <> 0 then begin
                CalcFields("Qty. Assigned");
                TestField("Qty. Assigned", "Quantity Invoiced");
            end;

        ItemChargeAssgntSales.Reset();
        ItemChargeAssgntSales.SetRange("Document Type", DocType);
        ItemChargeAssgntSales.SetRange("Document No.", DocNo);
        ItemChargeAssgntSales.SetRange("Document Line No.", DocLineNo);
        if not ItemChargeAssgntSales.IsEmpty() then
            ItemChargeAssgntSales.DeleteAll();

        OnAfterDeleteChargeChargeAssgnt(Rec, xRec, CurrFieldNo);
    end;

    local procedure CheckItemChargeAssgnt()
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. No.", "Document No.");
        ItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", "Line No.");
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "Document No.");
        if ItemChargeAssgntSales.FindSet() then begin
            TestField("Allow Item Charge Assignment");
            repeat
                ItemChargeAssgntSales.TestField("Qty. to Assign", 0);
            until ItemChargeAssgntSales.Next() = 0;
        end;
    end;

    /// <summary>
    /// Tests if sales header of the line is open.
    /// </summary>
    /// <remarks>
    /// Check is executed only for non-system created lines, type changes, and lines with non-blank type.
    /// </remarks>
    procedure TestStatusOpen()
    var
        IsHandled: Boolean;
    begin
        GetSalesHeader();
        IsHandled := false;
        OnBeforeTestStatusOpen(Rec, SalesHeader, IsHandled, xRec, CurrFieldNo, StatusCheckSuspended);
        if IsHandled then
            exit;

        if StatusCheckSuspended then
            exit;

        if not "System-Created Entry" then
            if (xRec.Type <> Type) or HasTypeToFillMandatoryFields() then
                SalesHeader.TestField(Status, SalesHeader.Status::Open);

        OnAfterTestStatusOpen(Rec, SalesHeader);
    end;

    local procedure TestQtyFromLindDiscountAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQtyFromLindDiscountAmount(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField(Quantity);
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
    /// <remarks>
    /// Suspends several checks like testing for status open on sales header, sales line check on shipment date validate, and amount updates on delete.
    /// </remarks>
    /// <param name="Suspend">The new value to set.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    /// <summary>
    /// Toggles the filter for lines with errors between displaying all lines and only lines with errors.
    /// </summary>
    /// <param name="ShowAllLinesEnabled">Return value: A toggle for showing all lines or just lines with errors. After switching the filter, the toggle is returned with the opposite value.</param>
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
    /// Recalculates and updates line and VAT amounts on all lines of the document.
    /// </summary>
    /// <remarks>
    /// QtyType::Shipping exits the function without updating the lines.
    /// QtyType::Invoicing doesn't update line and VAT amounts, only invoice discount amount to invoice and VAT difference.
    /// </remarks>
    /// <param name="QtyType">The type of quantity to consider for the update (Qty, QtyToInvoice, QtyToShip).</param>
    /// <param name="SalesHeader">The sales header of the document. The sales lines are filtered for this document.</param>
    /// <param name="SalesLine">The sales line record set that is looped through. Pre-existing filters will narrow down the lines to consider.</param>
    /// <param name="VATAmountLine">VAT amount line record set used in VAT calculations. The line used is retrieved from this set for each sales line.</param>
    /// <returns>True if any line was modified; otherwise, false.</returns>
    procedure UpdateVATOnLines(QtyType: Option General,Invoicing,Shipping; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line") LineWasModified: Boolean
    var
        TempVATAmountLineRemainder: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        NewAmount: Decimal;
        NewAmountIncludingVAT: Decimal;
        NewVATBaseAmount: Decimal;
        VATAmount: Decimal;
        VATDifference: Decimal;
        InvDiscAmount: Decimal;
        LineAmountToInvoice: Decimal;
        LineAmountToInvoiceDiscounted: Decimal;
        DeferralAmount: Decimal;
    begin
        if IsUpdateVATOnLinesHandled(SalesHeader, SalesLine, VATAmountLine, QtyType, LineWasModified) then
            exit(LineWasModified);

        LineWasModified := false;
        if QtyType = QtyType::Shipping then
            exit;

        Currency.Initialize(SalesHeader."Currency Code");
        OnUpdateVATOnLinesOnAfterCurrencyInitialize(Rec, SalesHeader, Currency);

        TempVATAmountLineRemainder.DeleteAll();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SetLoadFieldsForInvDiscoundCalculation(SalesLine);
        OnUpdateVATOnLinesOnAfterSalesLineSetFilter(SalesLine);
        SalesLine.LockTable();
        if SalesLine.FindSet() then
            repeat
                if not SalesLine.ZeroAmountLine(QtyType) then begin
                    OnCalcVATAmountLinesOnBeforeGetDeferralAmount(SalesLine);
                    DeferralAmount := SalesLine.GetDeferralAmount();
                    FindVATAmountLine(SalesLine, VATAmountLine);
                    if VATAmountLine.Modified then begin
                        if not FindVATAmountLine(SalesLine, TempVATAmountLineRemainder) then begin
                            TempVATAmountLineRemainder := VATAmountLine;
                            TempVATAmountLineRemainder.Init();
                            TempVATAmountLineRemainder.Insert();
                        end;

                        if QtyType = QtyType::General then
                            LineAmountToInvoice := SalesLine."Line Amount"
                        else
                            LineAmountToInvoice :=
                              Round(SalesLine."Line Amount" * SalesLine."Qty. to Invoice" / SalesLine.Quantity, Currency."Amount Rounding Precision");

                        if SalesLine."Allow Invoice Disc." then begin
                            if (VATAmountLine."Inv. Disc. Base Amount" = 0) or (LineAmountToInvoice = 0) then
                                InvDiscAmount := 0
                            else begin
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
                            if QtyType = QtyType::General then begin
                                SalesLine."Inv. Discount Amount" := InvDiscAmount;
                                SalesLine.CalcInvDiscToInvoice();
                            end else
                                SalesLine."Inv. Disc. Amount to Invoice" := InvDiscAmount;
                        end else
                            InvDiscAmount := 0;

                        OnUpdateVATOnLinesOnBeforeCalculateAmounts(SalesLine, SalesHeader);
                        if QtyType = QtyType::General then begin
                            if SalesHeader."Prices Including VAT" then begin
                                if (VATAmountLine.CalcLineAmount() = 0) or (SalesLine."Line Amount" = 0) then begin
                                    VATAmount := 0;
                                    NewAmountIncludingVAT := 0;
                                end else begin
                                    VATAmount :=
                                      TempVATAmountLineRemainder."VAT Amount" +
                                      VATAmountLine."VAT Amount" * SalesLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                    NewAmountIncludingVAT :=
                                      TempVATAmountLineRemainder."Amount Including VAT" +
                                      VATAmountLine."Amount Including VAT" * SalesLine.CalcLineAmount() / VATAmountLine.CalcLineAmount();
                                end;
                                OnUpdateVATOnLinesOnBeforeCalculateNewAmount(
                                  Rec, SalesHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmountIncludingVAT, VATAmount);
                                NewAmount :=
                                  Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision") -
                                  Round(VATAmount, Currency."Amount Rounding Precision");
                                NewVATBaseAmount :=
                                  Round(
                                    NewAmount * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100), Currency."Amount Rounding Precision");
                            end else begin
                                if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then begin
                                    VATAmount := SalesLine.CalcLineAmount();
                                    NewAmount := 0;
                                    NewVATBaseAmount := 0;
                                end else begin
                                    NewAmount := SalesLine.CalcLineAmount();
                                    NewVATBaseAmount :=
                                      Round(
                                        NewAmount * (1 - SalesLine.GetVatBaseDiscountPct(SalesHeader) / 100), Currency."Amount Rounding Precision");
                                    if VATAmountLine."VAT Base" = 0 then
                                        VATAmount := 0
                                    else
                                        VATAmount :=
                                          TempVATAmountLineRemainder."VAT Amount" +
                                          VATAmountLine."VAT Amount" * NewAmount / VATAmountLine."VAT Base";
                                end;
                                OnUpdateVATOnLinesOnBeforeCalculateNewAmount(
                                  Rec, SalesHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmount, VATAmount);
                                NewAmountIncludingVAT := NewAmount + Round(VATAmount, Currency."Amount Rounding Precision");
                            end;
                            OnUpdateVATOnLinesOnAfterCalculateNewAmount(
                              Rec, SalesHeader, VATAmountLine, TempVATAmountLineRemainder, NewAmountIncludingVAT, VATAmount,
                              NewAmount, NewVATBaseAmount);
                        end else begin
                            if VATAmountLine.CalcLineAmount() = 0 then
                                ClearVATDifference()
                            else
                                VATDifference :=
                                  TempVATAmountLineRemainder."VAT Difference" +
                                  VATAmountLine."VAT Difference" * (LineAmountToInvoice - InvDiscAmount) / VATAmountLine.CalcLineAmount();
                            if LineAmountToInvoice = 0 then
                                SalesLine.ClearVATDifference()
                            else
                                SalesLine."VAT Difference" := Round(VATDifference, Currency."Amount Rounding Precision");
                        end;
                        OnUpdateVATOnLinesOnAfterCalculateAmounts(SalesLine, SalesHeader);

                        if QtyType = QtyType::General then begin
                            if not SalesLine."Prepayment Line" then
                                SalesLine.UpdatePrepmtAmounts();
                            UpdateBaseAmounts(NewAmount, Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision"), NewVATBaseAmount);
                            OnUpdateVATOnLinesOnAfterUpdateBaseAmounts(SalesHeader, SalesLine, TempVATAmountLineRemainder, VATAmountLine, Currency);
                        end;
                        SalesLine.InitOutstanding();
                        if SalesLine.Type = SalesLine.Type::"Charge (Item)" then
                            SalesLine.UpdateItemChargeAssgnt();
                        OnUpdateVATOnLinesOnBeforeModifySalesLine(SalesLine, VATAmount);
                        SalesLine.Modify();
                        LineWasModified := true;

                        if (SalesLine."Deferral Code" <> '') and (DeferralAmount <> SalesLine.GetDeferralAmount()) then
                            SalesLine.UpdateDeferralAmounts();

                        TempVATAmountLineRemainder."Amount Including VAT" :=
                          NewAmountIncludingVAT - Round(NewAmountIncludingVAT, Currency."Amount Rounding Precision");
                        TempVATAmountLineRemainder."VAT Amount" := VATAmount - NewAmountIncludingVAT + NewAmount;
                        TempVATAmountLineRemainder."VAT Difference" := VATDifference - SalesLine."VAT Difference";
                        OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(Rec, TempVATAmountLineRemainder, VATAmount, NewVATBaseAmount);
                        TempVATAmountLineRemainder.Modify();
                    end;
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();
        SalesLine.SetLoadFields();

        OnAfterUpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, QtyType);
    end;

    local procedure IsUpdateVATOnLinesHandled(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Integer; var LineWasModified: Boolean) IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeUpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, IsHandled, QtyType, LineWasModified, xRec, CurrFieldNo, PrepaymentLineAmountEntered);
        exit(IsHandled);
    end;

    /// <summary>
    /// Creates VAT amount lines for all applicable sales lines in the document.
    /// An overload that sets IncludePrepayments to true.
    /// </summary>
    /// <remarks>
    /// VATAmountLine parameter must be temporary as DeleteAll is called on it.
    /// </remarks>
    /// <param name="QtyType">The type of quantity to consider for the calculation (Qty, QtyToInvoice, QtyToShip).</param>
    /// <param name="SalesHeader">The sales header of the document. The sales lines are filtered for this document.</param>
    /// <param name="SalesLine">The sales line record set that is looped through. Pre-existing filters will narrow down the lines to consider.</param>
    /// <param name="VATAmountLine">Return value: VAT amount line set where records are inserted. This must be a temporary variable as DeleteAll is called on it.</param>
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        CalcVATAmountLines(QtyType, SalesHeader, SalesLine, VATAmountLine, true);
    end;

    /// <summary>
    /// Creates VAT amount lines for all applicable sales lines in the document.
    /// </summary>
    /// <remarks>
    /// VATAmountLine parameter must be temporary as DeleteAll is called on it.
    /// IncludePrepayments is only applicable to Invoicing and Shipping QtyTypes.
    /// </remarks>
    /// <param name="QtyType">The type of quantity to consider for the calculation (Qty, QtyToInvoice, QtyToShip).</param>
    /// <param name="SalesHeader">The sales header of the document. The sales lines are filtered for this document.</param>
    /// <param name="SalesLine">The sales line record set that is looped through. Pre-existing filters will narrow down the lines to consider.</param>
    /// <param name="VATAmountLine">Return value: VAT amount line set where records are inserted. This must be a temporary variable as DeleteAll is called on it.</param>
    /// <param name="IncludePrepayments">A flag indicating whether amount used in calculation should include prepayment amount</param>
    procedure CalcVATAmountLines(QtyType: Option General,Invoicing,Shipping; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; IncludePrepayments: Boolean)
    var
        TotalVATAmount: Decimal;
        QtyToHandle: Decimal;
        AmtToHandle: Decimal;
        RoundingLineInserted: Boolean;
        ShouldProcessRounding: Boolean;
        IsHandled: Boolean;
    begin
        if IsCalcVATAmountLinesHandled(SalesHeader, SalesLine, VATAmountLine, QtyType, IncludePrepayments) then
            exit;

        Currency.Initialize(SalesHeader."Currency Code");
        OnCalcVATAmountLinesOnAfterCurrencyInitialize(Rec, SalesHeader, Currency);

        VATAmountLine.DeleteAll();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter(Quantity, '<>0');
        SalesLine.SetFilter("Unit Price", '<>0');
        SetLoadFieldsForInvDiscoundCalculation(SalesLine);
        OnCalcVATAmountLinesOnAfterSetFilters(SalesLine, SalesHeader);
        if SalesLine.FindSet() then
            repeat
                if not SalesLine.ZeroAmountLine(QtyType) then begin
                    OnCalcVATAmountLinesOnBeforeProcessSalesLine(SalesLine);
                    if (SalesLine.Type = SalesLine.Type::"G/L Account") and not SalesLine."Prepayment Line" and SalesLine."System-Created Entry" and not RoundingLineInserted then
                        RoundingLineInserted := (SalesLine."No." = SalesLine.GetCPGInvRoundAcc(SalesHeader));
                    if SalesLine."VAT Calculation Type" in
                       [SalesLine."VAT Calculation Type"::"Reverse Charge VAT", SalesLine."VAT Calculation Type"::"Sales Tax"]
                    then
                        SalesLine.ClearVATPct();

                    if not FindVATAmountLine(SalesLine, VATAmountLine) then begin
                        InsertVATAmountLine(SalesLine, VATAmountLine);
                        OnCalcVATAmountLinesOnAfterInsertNewVATAmountLine(SalesLine, VATAmountLine);
                    end;

                    OnCalcVATAmountLinesOnBeforeQtyTypeCase(VATAmountLine, SalesLine, SalesHeader);
                    case QtyType of
                        QtyType::General:
                            begin
                                OnCalcVATAmountLinesOnBeforeQtyTypeGeneralCase(SalesHeader, SalesLine, VATAmountLine, IncludePrepayments, QtyType, QtyToHandle, AmtToHandle);
                                VATAmountLine.Quantity += SalesLine."Quantity (Base)";
                                SumVATAmountLine(SalesHeader, SalesLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                        QtyType::Invoicing:
                            begin
                                IsHandled := false;
                                OnCalcVATAmountLinesOnBeforeAssignQuantities(SalesHeader, SalesLine, VATAmountLine, QtyToHandle, IsHandled);
                                if not IsHandled then
                                    case true of
                                        (SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice]) and
                                        (not SalesHeader.Ship) and SalesHeader.Invoice and (not SalesLine."Prepayment Line"):
                                            if SalesLine."Shipment No." = '' then begin
                                                QtyToHandle := SalesLine.GetAbsMin(SalesLine."Qty. to Invoice", SalesLine."Qty. Shipped Not Invoiced");
                                                VATAmountLine.Quantity += SalesLine.GetAbsMin(SalesLine."Qty. to Invoice (Base)", SalesLine."Qty. Shipped Not Invd. (Base)");
                                            end else begin
                                                QtyToHandle := SalesLine."Qty. to Invoice";
                                                VATAmountLine.Quantity += SalesLine."Qty. to Invoice (Base)";
                                            end;
                                        SalesLine.IsCreditDocType() and (not SalesHeader.Receive) and SalesHeader.Invoice:
                                            if SalesLine."Return Receipt No." = '' then begin
                                                QtyToHandle := SalesLine.GetAbsMin(SalesLine."Qty. to Invoice", SalesLine."Return Qty. Rcd. Not Invd.");
                                                VATAmountLine.Quantity += SalesLine.GetAbsMin(SalesLine."Qty. to Invoice (Base)", SalesLine."Ret. Qty. Rcd. Not Invd.(Base)");
                                            end else begin
                                                QtyToHandle := SalesLine."Qty. to Invoice";
                                                VATAmountLine.Quantity += SalesLine."Qty. to Invoice (Base)";
                                            end;
                                        else begin
                                            QtyToHandle := SalesLine."Qty. to Invoice";
                                            VATAmountLine.Quantity += SalesLine."Qty. to Invoice (Base)";
                                        end;
                                    end;

                                OnCalcVATAmountLinesOnBeforeAssignAmtToHandle(SalesHeader, SalesLine, VATAmountLine, IncludePrepayments, QtyType, QtyToHandle, AmtToHandle);
                                if IncludePrepayments then
                                    AmtToHandle := SalesLine.GetLineAmountToHandleInclPrepmt(QtyToHandle)
                                else
                                    AmtToHandle := SalesLine.GetLineAmountToHandle(QtyToHandle);
                                SumVATAmountLine(SalesHeader, SalesLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                        QtyType::Shipping:
                            begin
                                if SalesLine."Document Type" in
                                   [SalesLine."Document Type"::"Return Order", SalesLine."Document Type"::"Credit Memo"]
                                then begin
                                    QtyToHandle := SalesLine."Return Qty. to Receive";
                                    VATAmountLine.Quantity += SalesLine."Return Qty. to Receive (Base)";
                                end else begin
                                    QtyToHandle := SalesLine."Qty. to Ship";
                                    VATAmountLine.Quantity += SalesLine."Qty. to Ship (Base)";
                                end;
                                if IncludePrepayments then
                                    AmtToHandle := SalesLine.GetLineAmountToHandleInclPrepmt(QtyToHandle)
                                else
                                    AmtToHandle := SalesLine.GetLineAmountToHandle(QtyToHandle);
                                SumVATAmountLine(SalesHeader, SalesLine, VATAmountLine, QtyType, AmtToHandle, QtyToHandle);
                            end;
                    end;
                    TotalVATAmount += SalesLine."Amount Including VAT" - SalesLine.Amount;
                    OnCalcVATAmountLinesOnAfterCalcLineTotals(VATAmountLine, SalesHeader, SalesLine, Currency, QtyType, TotalVATAmount, QtyToHandle);
                end;
            until SalesLine.Next() = 0;
        VATAmountLine.Reset();
        SalesLine.SetRange(Type);
        SalesLine.SetRange(Quantity);
        SalesLine.SetRange("Unit Price");
        SalesLine.SetLoadFields();

        IsHandled := false;
        OnCalcVATAmountLinesOnBeforeVATAmountLineUpdateLines(SalesLine, IsHandled, VATAmountLine, TotalVATAmount);
        if not IsHandled then
            VATAmountLine.UpdateLines(
              TotalVATAmount, Currency, SalesHeader."Currency Factor", SalesHeader."Prices Including VAT",
              SalesHeader."VAT Base Discount %", SalesHeader."Tax Area Code", SalesHeader."Tax Liable", SalesHeader."Posting Date");

        ShouldProcessRounding := RoundingLineInserted and (TotalVATAmount <> 0);
        OnCalcVATAmountLinesOnAfterCalcShouldProcessRounding(VATAmountLine, Currency, ShouldProcessRounding, SalesLine, TotalVATAmount);
        if ShouldProcessRounding then
            if GetVATAmountLineOfMaxAmt(VATAmountLine, SalesLine) then begin
                VATAmountLine."VAT Amount" += TotalVATAmount;
                VATAmountLine."Amount Including VAT" += TotalVATAmount;
                VATAmountLine."Calculated VAT Amount" += TotalVATAmount;
                VATAmountLine.Modify();
            end;

        OnAfterCalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, QtyType);
    end;

    local procedure FindVATAmountLine(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line" temporary): Boolean
    begin
        VATAmountLine.Reset();
        VATAmountLine.SetRange("VAT Identifier", SalesLine."VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", SalesLine."VAT Calculation Type");
        VATAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        VATAmountLine.SetRange("Use Tax", false);
        VATAmountLine.SetRange(Positive, SalesLine."Line Amount" >= 0);
        OnFindVATAmountLineOnAfterSetFilters(SalesLine, VATAmountLine);
        exit(VATAmountLine.FindFirst());
    end;

    local procedure InsertVATAmountLine(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine.Init();
        VATAmountLine."VAT Identifier" := SalesLine."VAT Identifier";
        VATAmountLine."VAT Calculation Type" := SalesLine."VAT Calculation Type";
        VATAmountLine."Tax Group Code" := SalesLine."Tax Group Code";
        VATAmountLine."Use Tax" := false;
        VATAmountLine."VAT %" := SalesLine."VAT %";
        VATAmountLine.Modified := true;
        VATAmountLine.Positive := SalesLine."Line Amount" >= 0;
        VATAmountLine."Includes Prepayment" := false;
        VATAmountLine."Non-Deductible VAT %" := 0;
        OnInsertVATAmountOnBeforeInsert(SalesLine, VATAmountLine);
        VATAmountLine.Insert();
    end;

    local procedure SumVATAmountLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping; AmtToHandle: Decimal; QtyToHandle: Decimal)
    begin
        case QtyType of
            QtyType::General:
                begin
                    VATAmountLine."Line Amount" += SalesLine."Line Amount";
                    if SalesLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += SalesLine."Line Amount";
                    VATAmountLine."Invoice Discount Amount" += SalesLine."Inv. Discount Amount";
                end;
            QtyType::Invoicing:
                if SalesHeader."Invoice Discount Calculation" <> SalesHeader."Invoice Discount Calculation"::Amount then begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if SalesLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += Round(SalesLine."Inv. Discount Amount" * QtyToHandle / SalesLine.Quantity, Currency."Amount Rounding Precision");
                end else begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if SalesLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += SalesLine."Inv. Disc. Amount to Invoice";
                end;
            QtyType::Shipping:
                begin
                    VATAmountLine."Line Amount" += AmtToHandle;
                    if SalesLine."Allow Invoice Disc." then
                        VATAmountLine."Inv. Disc. Base Amount" += AmtToHandle;
                    VATAmountLine."Invoice Discount Amount" += Round(SalesLine."Inv. Discount Amount" * QtyToHandle / SalesLine.Quantity, Currency."Amount Rounding Precision");
                end;
        end;
        VATAmountLine."VAT Difference" += SalesLine."VAT Difference";
        if SalesLine."Prepayment Line" then
            VATAmountLine."Includes Prepayment" := true;
        OnSumVATAmountLineOnBeforeModify(SalesLine, VATAmountLine);
        VATAmountLine.Modify();
    end;

    /// <summary>
    /// Gets the account number to use for invoice rounding from the customer posting group. If invoice rounding is disabled, returns blank
    /// </summary>
    /// <param name="SalesHeader">The sales header of the document.</param>
    /// <returns>The invoice rounding account number</returns>
    procedure GetCPGInvRoundAcc(var SalesHeader: Record "Sales Header") AccountNo: Code[20]
    var
        Cust: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCPGInvRoundAcc(SalesHeader, Cust, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        GetSalesSetup();
        if SalesSetup."Invoice Rounding" then
            if Cust.Get(SalesHeader."Bill-to Customer No.") then
                CustPostingGroup.Get(Cust."Customer Posting Group")
            else
                GetCustomerPostingGroupFromTemplate(CustPostingGroup, SalesHeader);

        exit(CustPostingGroup."Invoice Rounding Account");
    end;

    local procedure GetCustomerPostingGroupFromTemplate(var CustPostingGroup: Record "Customer Posting Group"; SalesHeader: Record "Sales Header")
    var
        CustomerTempl: Record "Customer Templ.";
    begin
        if CustomerTempl.Get(SalesHeader."Sell-to Customer Templ. Code") then
            CustPostingGroup.Get(CustomerTempl."Customer Posting Group");
    end;

    /// <summary>
    /// Gets the VAT amount line for the sales line with the maximum absolute amount from the VAT amount line set.
    /// </summary>
    /// <param name="VATAmountLine">Return value: The VAT amount line with the maximum absolute amount. The search is performed on the record set passed in this parameter.</param>
    /// <param name="SalesLine">The sales line record to filter the VAT amount line set.</param>
    /// <returns>True if a VAT amount line was found, otherwise, false.</returns>
    procedure GetVATAmountLineOfMaxAmt(var VATAmountLine: Record "VAT Amount Line"; SalesLine: Record "Sales Line") Found: Boolean
    var
        VATAmount1: Decimal;
        VATAmount2: Decimal;
        IsPositive1: Boolean;
        IsPositive2: Boolean;
    begin
        VATAmountLine.SetRange("VAT Identifier", SalesLine."VAT Identifier");
        VATAmountLine.SetRange("VAT Calculation Type", SalesLine."VAT Calculation Type");
        VATAmountLine.SetRange("Tax Group Code", SalesLine."Tax Group Code");
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

    internal procedure GetVatBaseDiscountPct(SalesHeader: Record "Sales Header") Result: Decimal
    begin
        Result := SalesHeader."VAT Base Discount %";
        OnAfterGetVatBaseDiscountPct(Rec, SalesHeader, Result);
    end;

    /// <summary>
    /// Updates the invoice discount amount to invoice based on the current quantity and quantity to invoice.
    /// </summary>
    procedure CalcInvDiscToInvoice()
    var
        OldInvDiscAmtToInv: Decimal;
    begin
        GetSalesHeader();
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
        end;
        NotifyOnMissingSetup(FieldNo("Inv. Discount Amount"));

        OnAfterCalcInvDiscToInvoice(Rec, OldInvDiscAmtToInv);
    end;

    /// <summary>
    /// Updates the quantities to ship or receive based on the document type, quantity, and location/warehouse requirements.
    /// </summary>
    /// <remarks>
    /// If the default quantity to ship in sales setup is set to blank,
    /// the quantity to ship, recieve and invoice are always set to zero.
    /// </remarks>
    procedure UpdateWithWarehouseShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWithWarehouseShip(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsInventoriableItem() then
            case true of
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity >= 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Qty. to Ship", 0)
                    else
                        Validate("Qty. to Ship", "Outstanding Quantity");
                ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and (Quantity < 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Qty. to Ship", 0)
                    else
                        Validate("Qty. to Ship", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0):
                    if Location.RequireReceive("Location Code") then
                        Validate("Return Qty. to Receive", 0)
                    else
                        Validate("Return Qty. to Receive", "Outstanding Quantity");
                ("Document Type" = "Document Type"::"Return Order") and (Quantity < 0):
                    if Location.RequireShipment("Location Code") then
                        Validate("Return Qty. to Receive", 0)
                    else
                        Validate("Return Qty. to Receive", "Outstanding Quantity");
            end;

        SetDefaultQuantity();

        OnAfterUpdateWithWarehouseShip(SalesHeader, Rec);
    end;

    /// <summary>
    /// Checks that the warehouse requirements for the sales line, such as shipment, pick, receive, and put-away
    /// are met based on the location and document type.
    /// </summary>
    /// <remarks>
    /// If a dialog message is shown, it will either be a message or an error depending on the warehouse requirements and the document type.
    /// </remarks>
    /// <param name="ShowDialogMessage">Determines whether to show a dialog message if the warehouse requirements are not met.</param>
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
            DialogText := Text035;
            if ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"]) and
               Location2."Directed Put-away and Pick"
            then begin
                ShowDialog := ShowDialog::Error;
                if (("Document Type" = "Document Type"::Order) and (Quantity >= 0)) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0))
                then
                    DialogText :=
                      CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment")), 1, MaxStrLen(DialogText))
                else
                    DialogText :=
                      CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive")), 1, MaxStrLen(DialogText));
            end else begin
                if (("Document Type" = "Document Type"::Order) and (Quantity >= 0) and
                    (Location2."Require Shipment" or Location2."Require Pick")) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity < 0) and
                    (Location2."Require Shipment" or Location2."Require Pick"))
                then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Shipment" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Shipment" then
                        DialogText :=
                          CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Shipment")), 1, MaxStrLen(DialogText))
                    else begin
                        DialogText := Text036;
                        DialogText :=
                          CopyStr(DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Pick")), 1, MaxStrLen(DialogText));
                    end;
                end;

                if (("Document Type" = "Document Type"::Order) and (Quantity < 0) and
                    (Location2."Require Receive" or Location2."Require Put-away")) or
                   (("Document Type" = "Document Type"::"Return Order") and (Quantity >= 0) and
                    (Location2."Require Receive" or Location2."Require Put-away"))
                then begin
                    if WhseValidateSourceLine.WhseLinesExist(
                         DATABASE::"Sales Line", "Document Type".AsInteger(), "Document No.", "Line No.", 0, Quantity)
                    then
                        ShowDialog := ShowDialog::Error
                    else
                        if Location2."Require Receive" then
                            ShowDialog := ShowDialog::Message;
                    if Location2."Require Receive" then
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Receive"))
                    else begin
                        DialogText := Text036;
                        DialogText :=
                          DialogText + Location2.GetRequirementText(Location2.FieldNo("Require Put-away"));
                    end;
                end;
            end;

            OnCheckWarehouseOnBeforeShowDialog(Rec, Location2, ShowDialog, DialogText);

            case ShowDialog of
                ShowDialog::Message:
                    Message(WhseRequirementMsg, DialogText);
                ShowDialog::Error:
                    Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
            end;
        end;

        HandleDedicatedBin(true);
    end;

    /// <summary>
    /// Checks the warehouse requirements for the quantity to be shipped.
    /// </summary>
    procedure CheckWarehouseForQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarehouseForQtyToShip(Rec, CurrFieldNo, IsHandled, xRec);
        if IsHandled then
            exit;

        if (CurrFieldNo <> 0) and IsInventoriableItem() and (not "Drop Shipment") then begin
            if Location."Require Shipment" and ("Qty. to Ship" <> 0) then
                CheckWarehouse(true);
            SalesWarehouseMgt.SalesLineVerifyChange(Rec, xRec);
        end;
    end;

    /// <summary>
    /// Updates the shipment and delivery dates for the sales line.
    /// </summary>
    procedure UpdateDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDates(Rec, IsHandled, PlannedShipmentDateCalculated, PlannedDeliveryDateCalculated);
        if IsHandled then
            exit;

        if CurrFieldNo = 0 then begin
            PlannedShipmentDateCalculated := false;
            PlannedDeliveryDateCalculated := false;
        end;
        if "Promised Delivery Date" <> 0D then
            Validate("Promised Delivery Date")
        else
            if "Requested Delivery Date" <> 0D then
                Validate("Requested Delivery Date")
            else
                Validate("Shipment Date");

        OnAfterUpdateDates(Rec);
    end;

    /// <summary>
    /// Retrieves the item translation for the language of the document and updates the descriptions on the sales line.
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

        GetSalesHeader();
        if ItemTranslation.Get("No.", "Variant Code", SalesHeader."Language Code") then begin
            Description := ItemTranslation.Description;
            "Description 2" := ItemTranslation."Description 2";
            OnAfterGetItemTranslation(Rec, SalesHeader, ItemTranslation);
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(Rec, xRec, Location, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    /// <summary>
    /// Returns true if any price list line with price or cost that fit the sales line exist.
    /// This is an overload that sets ShowAll to true.
    /// </summary>
    /// <returns>True if any price list line is found, otherwise false.</returns>
    procedure PriceExists(): Boolean
    begin
        if "Document No." <> '' then
            exit(PriceExists(true));
        exit(false);
    end;

    /// <summary>
    /// Returns true if any price list line with discount that fit the sales line exist.
    /// This is an overload that sets ShowAll to true.
    /// </summary>
    /// <returns>True if any price list line is found, otherwise false.</returns>
    procedure LineDiscExists(): Boolean
    begin
        if "Document No." <> '' then
            exit(DiscountExists(true));
        exit(false);
    end;

    /// <summary>
    /// Creates a unique row identifier for the sales line used for item tracking.
    /// </summary>
    /// <returns>The unique row identifier.</returns>
    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ComposeRowID(DATABASE::"Sales Line", "Document Type".AsInteger(),
            "Document No.", '', 0, "Line No."));
    end;

    local procedure UpdateItemReference(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemReference(Rec, xRec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        ItemReferenceMgt.EnterSalesItemReference(Rec);
        UpdateICPartner();

        OnAfterUpdateItemReference(Rec);
    end;

    /// <summary>
    /// Gets the default bin for the sales line item based on the requriments of the location.
    /// </summary>
    procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, IsHandled, CurrFieldNo);
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
                if ("Qty. to Assemble to Order" > 0) or IsAsmToOrderRequired() then
                    if GetATOBin(Location, "Bin Code") then
                        exit;

                if not IsShipmentBinOverridesDefaultBin(Location) then begin
                    WMSManagement.GetDefaultBin("No.", "Variant Code", "Location Code", "Bin Code");
                    OnGetDefaultBinOnAfterWMSGetDefaultBin(Rec);
                    HandleDedicatedBin(false);
                end;
            end;
        end;

        OnAfterGetDefaultBin(Rec);
    end;

    /// <summary>
    /// Retrieves the Assembly-to-Order (ATO) bin for a given location.
    /// </summary>
    /// <param name="Location">The location record to retrieve the ATO bin for.</param>
    /// <param name="BinCode">Return value: The ATO bin code.</param>
    /// <returns>True if the ATO bin was found, otherwise false.</returns>
    procedure GetATOBin(Location: Record Location; var BinCode: Code[20]) Result: Boolean
    var
        AsmHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetATOBin(Rec, Location, BinCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not Location."Require Shipment" then
            BinCode := Location."Asm.-to-Order Shpt. Bin Code";
        if BinCode <> '' then
            exit(true);

        if AsmHeader.GetFromAssemblyBin(Location, BinCode) then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// Determines if the sales document this line belongs to is an inbound document.
    /// </summary>
    /// <returns>True if the document is inbound, otherwise false.</returns>
    procedure IsInbound(): Boolean
    var
        IsInboundDocument: Boolean;
    begin
        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote, "Document Type"::"Blanket Order":
                exit("Quantity (Base)" < 0);
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                exit("Quantity (Base)" > 0);
        end;

        IsInboundDocument := false;
        OnAfterIsInbound(Rec, IsInboundDocument);
        exit(IsInboundDocument);
    end;

    local procedure HandleDedicatedBin(IssueWarning: Boolean)
    var
        WhseIntegrationMgt: Codeunit "Whse. Integration Management";
    begin
        if IsInbound() or ("Quantity (Base)" = 0) or ("Document Type" = "Document Type"::"Blanket Order") then
            exit;

        WhseIntegrationMgt.CheckIfBinDedicatedOnSrcDoc("Location Code", "Bin Code", IssueWarning);
    end;

    /// <summary>
    /// Raises an error if the sales line is associated with a purchase order to ensure no changes are made to the line.
    /// </summary>
    /// <param name="TheFieldCaption">
    /// The caption of the field that is being changed.
    /// Used to determine if the check is executed for a field change or a line deletion.
    /// </param>
    procedure CheckAssocPurchOrder(TheFieldCaption: Text[250])
    var
        PurchaseHeader: Record "Purchase Header";
        IsHandled: Boolean;
        ChangeNotAllowedErrorInfo: ErrorInfo;
    begin
        IsHandled := false;
        OnBeforeCheckAssocPurchOrder(Rec, TheFieldCaption, IsHandled, xRec);
        if IsHandled then
            exit;

        if TheFieldCaption = '' then begin // If sales line is being deleted
            if "Purch. Order Line No." <> 0 then
                Error(Text000, "Purchase Order No.", "Purch. Order Line No.");
            if "Special Order Purch. Line No." <> 0 then
                CheckPurchOrderLineDeleted("Special Order Purchase No.", "Special Order Purch. Line No.");
        end else begin

            if "Purch. Order Line No." <> 0 then begin
                ChangeNotAllowedErrorInfo.Message(StrSubstNo(Text002, TheFieldCaption, "Purchase Order No.", "Purch. Order Line No."));
                PurchaseHeader.SetLoadFields("No.");
                PurchaseHeader.SetRange("No.", "Purchase Order No.");
                if (PurchaseHeader.FindFirst()) then begin
                    ChangeNotAllowedErrorInfo.RecordId(PurchaseHeader.RecordId());
                    ChangeNotAllowedErrorInfo.AddNavigationAction(StrSubstNo(ShowOrderLbl, "Purchase Order No."));
                    ChangeNotAllowedErrorInfo.PageNo(PAGE::"Purchase Order");
                end;
                Error(ChangeNotAllowedErrorInfo);
            end;

            if "Special Order Purch. Line No." <> 0 then
                Error(Text002, TheFieldCaption, "Special Order Purchase No.", "Special Order Purch. Line No.");

        end;
    end;

    local procedure CheckPurchOrderLineDeleted(PurchaseOrderNo: Code[20]; PurchaseLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseOrderNo, PurchaseLineNo) then
            Error(Text000, PurchaseOrderNo, PurchaseLineNo);
    end;

    /// <summary>
    /// Ensures that items that create a service item are not shipped in fractional quantities.
    /// </summary>
    procedure CheckServItemCreation()
    begin
        if CurrFieldNo = 0 then
            exit;
        if Type <> Type::Item then
            exit;

        OnCheckServItemCreation(Rec);
    end;

    /// <summary>
    /// Determines if the provided item number exists.
    /// </summary>
    /// <remarks>
    ///  If the line type is not item, the function returns true.
    /// </remarks>
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
    /// Finds or creates a record by a given number and returns the number of the found
    /// </summary>
    /// <param name="SourceNo">A record number to find.</param>
    /// <returns>Number of the found record.</returns>
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

        if (SourceNo = '') then
            exit('');
        if Type = Type::Item then
            exit(Item.GetFirstItemNoFromLookup(SourceNo))
        else
            exit(FindRecordManagement.FindNoFromTypedValue(Type.AsInteger(), "No.", not "System-Created Entry"));
    end;

    /// <summary>
    /// Determines if the sales line represents a shipment.
    /// </summary>
    /// <returns>True if the line represents a shipment, otherwise false.</returns>
    procedure IsShipment(): Boolean
    begin
        exit(SignedXX("Quantity (Base)") < 0);
    end;

    /// <summary>
    /// Retrieves the absolute minimum between the quantity to handle and the quantity handled.
    /// </summary>
    /// <param name="QtyToHandle">The quantity to handle.</param>
    /// <param name="QtyHandled">The quantity handled.</param>
    /// <returns>The absolute minimum quantity.</returns>
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

    /// <summary>
    /// Sets the global HideValidationDialog flag.
    /// </summary>
    /// <remarks>
    /// The flag is unused in the object.
    /// </remarks>
    /// <param name="NewHideValidationDialog">The new value of the flag.</param>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
        OnAfterSetHideValidationDialog(Rec, NewHideValidationDialog);
    end;

    /// <summary>
    /// Gets the global HideValidationDialog flag.
    /// </summary>
    /// <returns>The value of the flag.</returns>
    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    local procedure CheckApplFromItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        QtyNotReturned: Decimal;
        QtyReturned: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplFromItemLedgEntry(Rec, xRec, ItemLedgEntry, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Appl.-from Item Entry" = 0 then
            exit;

        if "Shipment No." <> '' then
            exit;

        OnCheckApplFromItemLedgEntryOnBeforeTestFieldType(Rec);
        TestField(Type, Type::Item);
        TestField(Quantity);
        CheckQuantitySignOnApplicationFrom();

        ItemLedgEntry.Get("Appl.-from Item Entry");
        ItemLedgEntry.TestField(Positive, false);
        ItemLedgEntry.TestField("Item No.", "No.");
        ItemLedgEntry.TestField("Variant Code", "Variant Code");
        ItemLedgEntry.CheckTrackingDoesNotExist(RecordId, FieldCaption("Appl.-from Item Entry"));

        if Abs("Quantity (Base)") > -ItemLedgEntry.Quantity then
            Error(
              Text046,
              -ItemLedgEntry.Quantity, ItemLedgEntry.FieldCaption("Document No."),
              ItemLedgEntry."Document No.");

        if IsCreditDocType() then
            if Abs("Outstanding Qty. (Base)") > -ItemLedgEntry."Shipped Qty. Not Returned" then begin
                QtyNotReturned := ItemLedgEntry."Shipped Qty. Not Returned";
                QtyReturned := ItemLedgEntry.Quantity - ItemLedgEntry."Shipped Qty. Not Returned";
                if "Qty. per Unit of Measure" <> 0 then begin
                    QtyNotReturned :=
                      Round(ItemLedgEntry."Shipped Qty. Not Returned" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    QtyReturned :=
                      Round(
                        (ItemLedgEntry.Quantity - ItemLedgEntry."Shipped Qty. Not Returned") /
                        "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;
                ShowReturnedUnitsError(ItemLedgEntry, QtyReturned, QtyNotReturned);
            end;
    end;

    /// <summary>
    /// Updates the prepayment amount to deduct with the next posting.
    /// </summary>
    procedure CalcPrepaymentToDeduct()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcPrepmtToDeduct(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Qty. to Invoice" <> 0) and ("Prepmt. Amt. Inv." <> 0) then begin
            GetSalesHeader();
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

    local procedure CheckQuantitySignOnApplicationFrom()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantitySignOnApplicationFrom(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then begin
            if Quantity < 0 then
                FieldError(Quantity, Text029);
        end else
            if Quantity > 0 then
                FieldError(Quantity, Text030);
    end;

    /// <summary>
    /// Determines if the line will be fully invoiced after posting.
    /// </summary>
    /// <returns>True if the line will be fully invoiced, otherwise false.</returns>
    procedure IsFinalInvoice(): Boolean
    begin
        exit("Qty. to Invoice" = Quantity - "Quantity Invoiced");
    end;

    /// <summary>
    /// Calculates the net line amount for the specified quantity to handle.
    /// </summary>
    /// <param name="QtyToHandle">The quantity to handle.</param>
    /// <returns>The net line amount.</returns>
    procedure GetLineAmountToHandle(QtyToHandle: Decimal): Decimal
    var
        LineAmount: Decimal;
        LineDiscAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLineAmountToHandle(QtyToHandle, Rec, Currency, IsHandled);
        if IsHandled then
            exit(QtyToHandle);

        if "Line Discount %" = 100 then
            exit(0);

        GetSalesHeader();

        if "Prepmt Amt to Deduct" = 0 then
            LineAmount := Round(QtyToHandle * "Unit Price", Currency."Amount Rounding Precision")
        else
            if Quantity <> 0 then begin
                LineAmount := Round(Quantity * "Unit Price", Currency."Amount Rounding Precision");
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
    /// Calculates the net line amount for the specified quantity to handle.
    /// If line must be fully prepaid then the line amount is calculated with the prepayment amount to deduct.
    /// </summary>
    /// <param name="QtyToHandle">The quantity to handle.</param>
    /// <returns>The net line amount.</returns>
    procedure GetLineAmountToHandleInclPrepmt(QtyToHandle: Decimal): Decimal
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocType: Option Invoice,"Credit Memo",Statistic;
    begin
        if "Line Discount %" = 100 then
            exit(0);

        if IsCreditDocType() then
            DocType := DocType::"Credit Memo"
        else
            DocType := DocType::Invoice;

        if ("Prepayment %" = 100) and not "Prepayment Line" and ("Prepmt Amt to Deduct" <> 0) then
            if SalesPostPrepayments.PrepmtAmount(Rec, DocType) <= 0 then
                exit("Prepmt Amt to Deduct" + "Inv. Disc. Amount to Invoice");

        exit(GetLineAmountToHandle(QtyToHandle));
    end;

    /// <summary>
    /// Calculates the line amount excluding VAT.
    /// </summary>
    /// <returns>The line amount excluding VAT.</returns>
    procedure GetLineAmountExclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetSalesHeader();
        if not SalesHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" / (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Calculates the line amount including VAT.
    /// </summary>
    /// <returns>The line amount including VAT.</returns>
    procedure GetLineAmountInclVAT(): Decimal
    begin
        if "Document No." = '' then
            exit(0);
        GetSalesHeader();
        if SalesHeader."Prices Including VAT" then
            exit("Line Amount");

        exit(Round("Line Amount" * (1 + "VAT %" / 100), Currency."Amount Rounding Precision"));
    end;

    /// <summary>
    /// Sets a flag to prevent showing a message if shipment date is before work date.
    /// </summary>
    procedure SetHasBeenShown()
    begin
        HasBeenShown := true;
    end;

    /// <summary>
    /// Ensures that a sales line that is associated with a job task has not been changed.
    /// </summary>
    procedure TestJobPlanningLine()
    var
        JobPostLine: Codeunit "Job Post-Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobPlanningLine(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if "Job Contract Entry No." = 0 then
            exit;

        if CurrFieldNo = 0 then
            exit;

        JobPostLine.TestSalesLine(Rec);
    end;

    /// <summary>
    /// Sets the blocking state for dynamic tracking of reservations on quantity change.
    /// </summary>
    /// <param name="SetBlock">The new blocking state.</param>
    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        SalesLineReserve.Block(SetBlock);
    end;

    /// <summary>
    /// Initializes the quantity to ship and invoice to reflect changes after the sales line has been (partially) posted.
    /// Additionally, reclaculates the proportional invoice discount and prepayment amounts for next posting.
    /// </summary>
    procedure InitQtyToShip2()
    begin
        "Qty. to Ship" := "Outstanding Quantity";
        "Qty. to Ship (Base)" := "Outstanding Qty. (Base)";

        OnAfterInitQtyToShip2(Rec, CurrFieldNo);

        ATOLink.UpdateQtyToAsmFromSalesLine(Rec);

        CheckServItemCreation();

        "Qty. to Invoice" := MaxQtyToInvoice();
        "Qty. to Invoice (Base)" := MaxQtyToInvoiceBase();

        GetSalesSetup();
        if not SalesSetup."Allow VAT Difference" then
            "VAT Difference" := 0;

        OnInitQtyToShip2OnBeforeCalcInvDiscToInvoice(Rec, xRec);

        CalcInvDiscToInvoice();

        CalcPrepaymentToDeduct();
    end;

    local procedure UpdateQtyToAsmFromSalesLineQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToAsmFromSalesLineQtyToShip(Rec, IsHandled);
        if IsHandled then
            exit;

        ATOLink.UpdateQtyToAsmFromSalesLine(Rec);
    end;

    /// <summary>
    /// Opens a page to show comments for the sales line.
    /// </summary>
    procedure ShowLineComments()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentSheet: Page "Sales Comment Sheet";
    begin
        TestField("Document No.");
        TestField("Line No.");
        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "Document No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        OnShowLineCommentsOnAfterSetFilters(SalesCommentLine);
        SalesCommentSheet.SetTableView(SalesCommentLine);
        SalesCommentSheet.RunModal();
    end;

    /// <summary>
    /// Resets quantities to ship/return and invoice to zero based on the sales setup setting for default shipping quantity.
    /// </summary>
    procedure SetDefaultQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then begin
            if ("Document Type" = "Document Type"::Order) or ("Document Type" = "Document Type"::Quote) then begin
                "Qty. to Ship" := 0;
                "Qty. to Ship (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Return Qty. to Receive" := 0;
                "Return Qty. to Receive (Base)" := 0;
                "Qty. to Invoice" := 0;
                "Qty. to Invoice (Base)" := 0;
            end;
        end;

        OnAfterSetDefaultQuantity(Rec, xRec);
    end;

    /// <summary>
    /// Sets the reservation method for the sales line from the item.
    /// If item's reservation method is optional, the sales header's reservation method is used.
    /// </summary>
    protected procedure SetReserveWithoutPurchasingCode()
    var
        Item: Record Item;
    begin
        GetItem(Item);
        if Item.Reserve = Item.Reserve::Optional then begin
            GetSalesHeader();
            Reserve := SalesHeader.Reserve;
        end else
            Reserve := Item.Reserve;

        OnAfterSetReserveWithoutPurchasingCode(Rec, SalesHeader, Item);
    end;

    procedure SetReserveToOptional()
    begin
        if Reserve = Reserve::Never then begin
            Reserve := Reserve::Optional;
            Modify();
        end;
    end;

    local procedure SetDefaultGLAccountQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultGLAccountQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if SalesSetup."Default G/L Account Quantity" then
            Validate(Quantity, 1);
    end;

    local procedure SetDefaultItemQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultItemQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if SalesSetup."Default Item Quantity" then begin
            Validate(Quantity, 1);
            CheckItemAvailable(CurrFieldNo);
        end;
    end;

    /// <summary>
    /// Recalculates prepayment amounts to reflect changes in quantity.
    /// </summary>
    procedure UpdatePrePaymentAmounts()
    var
        ShipmentLine: Record "Sales Shipment Line";
        SalesOrderLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePrePaymentAmounts(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Document Type" <> "Document Type"::Invoice) or ("Prepayment %" = 0) then
            exit;

        if not ShipmentLine.Get("Shipment No.", "Shipment Line No.") then begin
            "Prepmt Amt to Deduct" := 0;
            "Prepmt VAT Diff. to Deduct" := 0;
        end else
            if SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, ShipmentLine."Order No.", ShipmentLine."Order Line No.") then begin
                if ("Prepayment %" = 100) and (Quantity <> SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced") and (SalesOrderLine."Inv. Discount Amount" = 0) then
                    "Prepmt Amt to Deduct" := "Line Amount"
                else
                    "Prepmt Amt to Deduct" :=
                      Round((SalesOrderLine."Prepmt. Amt. Inv." - SalesOrderLine."Prepmt Amt Deducted") *
                        Quantity / (SalesOrderLine.Quantity - SalesOrderLine."Quantity Invoiced"), Currency."Amount Rounding Precision");
                "Prepmt VAT Diff. to Deduct" := "Prepayment VAT Difference" - "Prepmt VAT Diff. Deducted";
                SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, SalesOrderLine."Document No.");
            end else begin
                "Prepmt Amt to Deduct" := 0;
                "Prepmt VAT Diff. to Deduct" := 0;
            end;

        GetSalesHeader();
        IsHandled := false;
        OnUpdatePrePaymentAmountsOnBeforeTestFieldPriceIncludingVAT(Rec, SalesHeader, SalesOrderHeader, IsHandled);
        if not IsHandled then
            SalesHeader.TestField("Prices Including VAT", SalesOrderHeader."Prices Including VAT");
        if SalesHeader."Prices Including VAT" then begin
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

        if not HasTypeToFillMandatoryFields() then
            exit(true);
        if Quantity = 0 then
            exit(true);
        if "Unit Price" = 0 then
            exit(true);
        if QtyType = QtyType::Invoicing then
            if "Qty. to Invoice" = 0 then
                exit(true);
        exit(false);
    end;

    /// <summary>
    /// Sets filters on the sales line for item lines, a specified document type, and various flow filters set in the provided item record.
    /// </summary>
    /// <param name="Item">Item record to filter the sales lines with.</param>
    /// <param name="DocumentType">The document type to filter the sales lines with.</param>
    procedure FilterLinesWithItemToPlan(var Item: Record Item; DocumentType: Enum "Sales Document Type")
    begin
        Reset();
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Shipment Date", Item.GetFilter("Date Filter"));
        SetFilter("Outstanding Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));

        OnAfterFilterLinesWithItemToPlan(Rec, Item, DocumentType.AsInteger());
    end;

    /// <summary>
    /// Retrieves a record set of item sales lines that match the provided document type and various filters set on the item.
    /// </summary>
    /// <param name="Item">Item record to filter the sales lines with.</param>
    /// <param name="DocumentType">The document type to filter the sales lines with.</param>
    /// <returns>True if any sales line was found, otherwise false.</returns>
    procedure FindLinesWithItemToPlan(var Item: Record Item; DocumentType: Enum "Sales Document Type"): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(Find('-'));
    end;

    /// <summary>
    /// Determines if any sales lines exist that match the provided document type and various flow filters set on the item.
    /// </summary>
    /// <param name="Item">Item record to filter the sales lines with.</param>
    /// <param name="DocumentType">The document type to filter the sales lines with.</param>
    /// <returns>True if any sales lines exist, otherwise false.</returns>
    procedure LinesWithItemToPlanExist(var Item: Record Item; DocumentType: Enum "Sales Document Type"): Boolean
    begin
        FilterLinesWithItemToPlan(Item, DocumentType);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Sets filters on the sales line for item lines that match the provided reservation entry.
    /// </summary>
    /// <param name="ReservationEntry">Reservation entry to filter the sales lines with.</param>
    /// <param name="DocumentType">The document type to filter the sales lines with.</param>
    /// <param name="AvailabilityFilter">Date filter to apply to the shipment date field.</param>
    /// <param name="Positive">A flag to determine if the quantity filter should be positive or negative.</param>
    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; DocumentType: Enum "Sales Document Type"; AvailabilityFilter: Text;
                                                                                                        Positive: Boolean)
    begin
        Reset();
        SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SetRange("Document Type", DocumentType);
        SetRange(Type, Type::Item);
        SetRange("No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Drop Shipment", false);
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Shipment Date", AvailabilityFilter);
        if DocumentType = "Document Type"::"Return Order" then
            if Positive then
                SetFilter("Quantity (Base)", '>0')
            else
                SetFilter("Quantity (Base)", '<0')
        else
            if Positive then
                SetFilter("Quantity (Base)", '<0')
            else
                SetFilter("Quantity (Base)", '>0');
        SetRange("Job No.", ' ');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, DocumentType, AvailabilityFilter, Positive);
    end;

    local procedure DateFormularZero(var DateFormularValue: DateFormula; CalledByFieldNo: Integer; CalledByFieldCaption: Text[250])
    var
        DateFormularZero: DateFormula;
    begin
        Evaluate(DateFormularZero, '<0D>');
        if (DateFormularValue <> DateFormularZero) and (CalledByFieldNo = CurrFieldNo) then
            Error(Text051, CalledByFieldCaption, FieldCaption("Drop Shipment"));
        Evaluate(DateFormularValue, '<0D>');
    end;

    /// <summary>
    /// Initializes quantities to assemble to order for the sales line.
    /// </summary>
    procedure InitQtyToAsm()
    var
        ShouldUpdateQtyToAsm: Boolean;
    begin
        OnBeforeInitQtyToAsm(Rec, CurrFieldNo);

        if not IsAsmToOrderAllowed() then begin
            "Qty. to Assemble to Order" := 0;
            "Qty. to Asm. to Order (Base)" := 0;
            exit;
        end;

        ShouldUpdateQtyToAsm := ((xRec."Qty. to Asm. to Order (Base)" = 0) and IsAsmToOrderRequired() and ("Qty. Shipped (Base)" = 0)) or
           ((xRec."Qty. to Asm. to Order (Base)" <> 0) and
            (xRec."Qty. to Asm. to Order (Base)" = xRec."Quantity (Base)")) or
           ("Qty. to Asm. to Order (Base)" > "Quantity (Base)");
        OnInitQtyToAsmOnAfterCalcShouldUpdateQtyToAsm(Rec, CurrFieldNo, xRec, ShouldUpdateQtyToAsm);
        if ShouldUpdateQtyToAsm then begin
            "Qty. to Assemble to Order" := Quantity;
            "Qty. to Asm. to Order (Base)" := "Quantity (Base)";
        end;

        OnAfterInitQtyToAsm(Rec, CurrFieldNo, xRec, ShouldUpdateQtyToAsm);
    end;

    /// <summary>
    /// Determines if assembly order exists for the sales line and retrieves the assembly header.
    /// </summary>
    /// <param name="AsmHeader">Return value: The assembly header record asociated with the sales line.</param>
    /// <returns>True if the assembly order exists, otherwise false.</returns>
    procedure AsmToOrderExists(var AsmHeader: Record "Assembly Header"): Boolean
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        if not ATOLink.AsmExistsForSalesLine(Rec) then
            exit(false);
        exit(AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No."));
    end;

    /// <summary>
    /// Determines if the full quantity is for assembly to order.
    /// </summary>
    /// <returns>True if the full quantity is for assembly to order, otherwise false.</returns>
    procedure FullQtyIsForAsmToOrder(): Boolean
    begin
        if "Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        exit("Quantity (Base)" = "Qty. to Asm. to Order (Base)");
    end;

    local procedure FullReservedQtyIsForAsmToOrder(): Boolean
    begin
        if "Qty. to Asm. to Order (Base)" = 0 then
            exit(false);
        CalcFields("Reserved Qty. (Base)");
        exit("Reserved Qty. (Base)" = "Qty. to Asm. to Order (Base)");
    end;

    /// <summary>
    /// Returns the quantity (base) from the associated assembly order, if it doesn't exist, returns zero.
    /// </summary>
    /// <returns>The quantity (base) from the associated assembly order or zero.</returns>
    procedure QtyBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        AsmHeader.SetLoadFields("Quantity (Base)");
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Quantity (Base)");
        exit(0);
    end;

    /// <summary>
    /// Returns the remaining quantity (base) from the associated assembly order, if it doesn't exist, returns zero.
    /// </summary>
    /// <returns>The remaining quantity (base) from the associated assembly order or zero.</returns>
    procedure QtyAsmRemainingBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Remaining Quantity (Base)");
        exit(0);
    end;

    /// <summary>
    /// Returns the quantity to assemble (base) from the associated assembly order, if it doesn't exist, returns zero.
    /// </summary>
    /// <returns>The quantity to assemble (base) from the associated assembly order or zero.</returns>
    procedure QtyToAsmBaseOnATO(): Decimal
    var
        AsmHeader: Record "Assembly Header";
    begin
        if AsmToOrderExists(AsmHeader) then
            exit(AsmHeader."Quantity to Assemble (Base)");
        exit(0);
    end;

    /// <summary>
    /// Determines if the sales line is allowed to be assembled to order.
    /// </summary>
    /// <returns>True if the sales line is allowed to be assembled to order, otherwise false.</returns>
    procedure IsAsmToOrderAllowed() Result: Boolean
    begin
        Result := true;

        if not ("Document Type" in ["Document Type"::Quote, "Document Type"::"Blanket Order", "Document Type"::Order]) then
            Result := false;
        if Quantity < 0 then
            Result := false;
        if Type <> Type::Item then
            Result := false;
        if "No." = '' then
            Result := false;
        if "Drop Shipment" or "Special Order" then
            Result := false;
        OnAfterIsAsmToOrderAllowed(Rec, Result);
    end;

    /// <summary>
    /// Determines if the sales line is required to be assembled to order.
    /// </summary>
    /// <returns>True if the sales line is required to be assembled to order, otherwise false.</returns>
    procedure IsAsmToOrderRequired(): Boolean
    var
        Item: Record Item;
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeIsAsmToOrderRequired(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (Type <> Type::Item) or ("No." = '') then
            exit(false);
        GetItem(Item);
        if GetSKU() then
            exit(SKU."Assembly Policy" = SKU."Assembly Policy"::"Assemble-to-Order");
        exit(Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order");
    end;

    /// <summary>
    /// Checks that sales line fields match the provided assembly order.
    /// </summary>
    /// <param name="AsmHeader">The assembly header to check value against.</param>
    procedure CheckAsmToOrder(AsmHeader: Record "Assembly Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAsmToOrder(Rec, AsmHeader, IsHandled);
        if IsHandled then
            exit;

        TestField("Qty. to Assemble to Order", AsmHeader.Quantity);
        TestField("Document Type", AsmHeader."Document Type");
        TestField(Type, Type::Item);
        TestField("No.", AsmHeader."Item No.");
        TestField("Location Code", AsmHeader."Location Code");
        TestField("Unit of Measure Code", AsmHeader."Unit of Measure Code");
        TestField("Variant Code", AsmHeader."Variant Code");
        TestField("Shipment Date", AsmHeader."Due Date");
        if "Document Type" = "Document Type"::Order then begin
            AsmHeader.CalcFields("Reserved Qty. (Base)");
            AsmHeader.TestField("Reserved Qty. (Base)", AsmHeader."Remaining Quantity (Base)");
        end;
        TestField("Qty. to Asm. to Order (Base)", AsmHeader."Quantity (Base)");
        if "Outstanding Qty. (Base)" < AsmHeader."Remaining Quantity (Base)" then
            AsmHeader.FieldError("Remaining Quantity (Base)", StrSubstNo(Text045, AsmHeader."Remaining Quantity (Base)"));
    end;

    /// <summary>
    /// Opens a page with assembly lines for the document of the sales line. The page is only opened if any lines exist.
    /// </summary>
    procedure ShowAsmToOrderLines()
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        ATOLink.ShowAsmToOrderLines(Rec);
    end;

    /// <summary>
    /// Finds the first open item ledger entry number for posted assembly that matches the sales line and the provided item tracking setup.
    /// </summary>
    /// <param name="ItemTrackingSetup">The item tracking setup to filter the item ledger entry with.</param>
    /// <returns>The item ledger entry no. if found, otherwise zero.</returns>
    procedure FindOpenATOEntry(ItemTrackingSetup: Record "Item Tracking Setup"): Integer
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TestField("Document Type", "Document Type"::Order);
        if PostedATOLink.FindLinksFromSalesLine(Rec) then
            repeat
                ItemLedgEntry.SetRange("Document Type", ItemLedgEntry."Document Type"::"Posted Assembly");
                ItemLedgEntry.SetRange("Document No.", PostedATOLink."Assembly Document No.");
                ItemLedgEntry.SetRange("Document Line No.", 0);
                ItemLedgEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);
                ItemLedgEntry.SetRange(Open, true);
                if ItemLedgEntry.FindFirst() then
                    exit(ItemLedgEntry."Entry No.");
            until PostedATOLink.Next() = 0;
    end;

    /// <summary>
    /// Sums up costs from assembly components and updates the unit cost on the sales line.
    /// </summary>
    procedure RollUpAsmCost()
    begin
        ATOLink.RollUpCost(Rec);
    end;

    /// <summary>
    /// Sums up prices from assembly components and updates the unit price on the sales line.
    /// </summary>
    procedure RollupAsmPrice()
    begin
        GetSalesHeader();
        ATOLink.RollUpPrice(SalesHeader, Rec);
    end;

    /// <summary>
    /// Updates the intercompany partner information on the sales line for outgoing intercompany documents.
    /// </summary>
    procedure UpdateICPartner()
    var
        ICPartner: Record "IC Partner";
        ShouldUpdateICPartner: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDoUpdateICPartner(Rec, SalesHeader, IsHandled);
        if not IsHandled then begin
            ShouldUpdateICPartner :=
                SalesHeader."Send IC Document" and (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing) and
                (SalesHeader."Bill-to IC Partner Code" <> '');
            OnBeforeUpdateICPartner(SalesHeader, Rec, ShouldUpdateICPartner);
            if ShouldUpdateICPartner then
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
                            if SalesHeader."Sell-to IC Partner Code" <> '' then
                                ICPartner.Get(SalesHeader."Sell-to IC Partner Code")
                            else
                                ICPartner.Get(SalesHeader."Bill-to IC Partner Code");
                            case ICPartner."Outbound Sales Item No. Type" of
                                ICPartner."Outbound Sales Item No. Type"::"Common Item No.":
                                    SetICPartnerRefType(Rec."IC Partner Ref. Type"::"Common Item No.");
                                ICPartner."Outbound Sales Item No. Type"::"Internal No.":
                                    begin
                                        SetICPartnerRefType(Rec."IC Partner Ref. Type"::Item);
                                        "IC Partner Reference" := "No.";
                                    end;
                                ICPartner."Outbound Sales Item No. Type"::"Cross Reference":
                                    begin
                                        SetICPartnerRefType(Rec."IC Partner Ref. Type"::"Cross Reference");
                                        UpdateICPartnerItemReference();
                                    end;
                            end;
                        end;
                    Type::"Fixed Asset":
                        begin
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::" ";
                            "IC Partner Reference" := '';
                        end;
                    Type::Resource:
                        begin
                            Resource.Get("No.");
                            "IC Partner Ref. Type" := "IC Partner Ref. Type"::"G/L Account";
                            "IC Partner Reference" := Resource."IC Partner Purch. G/L Acc. No.";
                        end;
                end;
        end;

        OnAfterUpdateICPartner(Rec, SalesHeader);
    end;

    local procedure SetICPartnerRefType(NewType: Enum "IC Partner Reference Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetICPartnerRefType(Rec, NewType, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Rec.Validate("IC Partner Ref. Type", NewType);
    end;

    local procedure UpdateICPartnerItemReference()
    var
        ItemReference: Record "Item Reference";
        ToDate: Date;
    begin
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", "Sell-to Customer No.");
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

    /// <summary>
    /// Calculates the outstanding invoice amount from shipments for a specified customer.
    /// </summary>
    /// <param name="SellToCustomerNo">The sell-to customer number to calculate the outstanding invoice amount for.</param>
    /// <returns>The outstanding invoice amount.</returns>
    procedure OutstandingInvoiceAmountFromShipment(SellToCustomerNo: Code[20]): Decimal
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetCurrentKey("Document Type", "Sell-to Customer No.", "Shipment No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesLine.SetFilter("Shipment No.", '<>%1', '');
        OnOutstandingInvoiceAmountFromShipmentOnAfterSetFilter(SalesLine);
        SalesLine.CalcSums("Outstanding Amount (LCY)");
        exit(SalesLine."Outstanding Amount (LCY)");
    end;

    local procedure CheckShipmentRelation()
    var
        SalesShptLine: Record "Sales Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipmentRelation(IsHandled, Rec, CurrFieldNo);
        if IsHandled then
            exit;

        SalesShptLine.Get("Shipment No.", "Shipment Line No.");
        if (Quantity * SalesShptLine."Qty. Shipped Not Invoiced") < 0 then
            FieldError("Qty. to Invoice", Text057);
        if Abs(Quantity) > Abs(SalesShptLine."Qty. Shipped Not Invoiced") then
            Error(Text058, SalesShptLine."Document No.");

        OnAfterCheckShipmentRelation(Rec, SalesShptLine);
    end;

    procedure CheckShipmentDateBeforeWorkDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipmentDateBeforeWorkDate(Rec, xRec, HasBeenShown, IsHandled);
        if IsHandled then
            exit;

        if ("Shipment Date" < WorkDate()) and HasTypeToFillMandatoryFields() then
            if not (GetHideValidationDialog() or HasBeenShown) and GuiAllowed then begin
                Message(
                  Text014,
                  FieldCaption("Shipment Date"), "Shipment Date", WorkDate());
                HasBeenShown := true;
            end;
    end;

    local procedure CheckRetRcptRelation()
    var
        ReturnRcptLine: Record "Return Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRetRcptRelation(IsHandled, Rec);
        if IsHandled then
            exit;

        ReturnRcptLine.Get("Return Receipt No.", "Return Receipt Line No.");
        if (Quantity * (ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced")) < 0 then
            FieldError("Qty. to Invoice", Text059);
        if Abs(Quantity) > Abs(ReturnRcptLine.Quantity - ReturnRcptLine."Quantity Invoiced") then
            Error(Text060, ReturnRcptLine."Document No.");

        OnAfterCheckRetRcptRelation(Rec, ReturnRcptLine);
    end;

    /// <summary>
    /// Checks if dimensions have changed on an already shipped or received item line and prompts the user to confirm the change.
    /// </summary>
    procedure VerifyItemLineDim()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyItemLineDim(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsShippedReceivedItemDimChanged() then
            ConfirmShippedReceivedItemDimChange();
    end;

    /// <summary>
    /// Determines if the dimensions have changed on an already shipped or received item line.
    /// </summary>
    /// <returns>True if the dimensions have changed, otherwise false.</returns>
    procedure IsShippedReceivedItemDimChanged(): Boolean
    begin
        exit(("Dimension Set ID" <> xRec."Dimension Set ID") and (Type = Type::Item) and
          (("Qty. Shipped Not Invoiced" <> 0) or ("Return Rcd. Not Invd." <> 0)));
    end;

    /// <summary>
    /// Determines if the line is a service charge line.
    /// </summary>
    /// <returns>True if the line is a service charge line, otherwise false.</returns>
    procedure IsServiceChargeLine(): Boolean
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if Type <> Type::"G/L Account" then
            exit(false);

        GetSalesHeader();
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        exit(CustomerPostingGroup."Service Charge Acc." = "No.");
    end;

    /// <summary>
    /// Raises a confirmation dialog to confirm the change of dimensions on an already shipped or received item line.
    /// </summary>
    /// <returns>True if the user confirms the change, otherwise an error is thrown.</returns>
    procedure ConfirmShippedReceivedItemDimChange(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text053, TableCaption), true) then
            Error(Text054);

        exit(true);
    end;

    /// <summary>
    /// Initializes the type of a new sales line.
    /// </summary>
    /// <remarks>
    /// It keeps the type of the previous line, unless the document is released and the line type is item or fixed asset.
    /// In that case, the type is reset to blank.
    /// </remarks>
    procedure InitType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitType(Rec, xRec, IsHandled, SalesHeader);
        if IsHandled then
            exit;

        if "Document No." <> '' then begin
            if not SalesHeader.Get("Document Type", "Document No.") then
                exit;
            if (SalesHeader.Status = SalesHeader.Status::Released) and
               (xRec.Type in [xRec.Type::Item, xRec.Type::"Fixed Asset"])
            then
                Type := Type::" "
            else
                Type := xRec.Type;
        end;

        OnAfterInitType(Rec, xRec, SalesHeader);
    end;

    /// <summary>
    /// Gets the default line type from the sales setup if it is set.
    /// </summary>
    /// <returns>The default line type from the sales setup, otherwise blank.</returns>
    procedure GetDefaultLineType(): Enum "Sales Line Type"
    begin
        GetSalesSetup();
        if SalesSetup."Document Default Line Type" <> SalesSetup."Document Default Line Type"::" " then
            exit(SalesSetup."Document Default Line Type");
    end;

    local procedure CheckWMS()
    begin
        if (CurrFieldNo <> 0) or (SalesHeader."VAT Bus. Posting Group" <> Rec."VAT Bus. Posting Group") then
            CheckLocationOnWMS();
    end;

    /// <summary>
    /// Checks if shipment or receipt is required for item sales line and throws an error if it's missing.
    /// </summary>
    procedure CheckLocationOnWMS()
    var
        DialogText: Text;
        IsHandled: Boolean;
    begin
        if (Type = Type::Item) and IsInventoriableItem() then begin
            DialogText := Text035;
            if "Quantity (Base)" <> 0 then begin
                IsHandled := false;
                OnCheckLocationOnWMSOnBeforeCaseDocumentType(Rec, DialogText, IsHandled);
                if not IsHandled then
                    case "Document Type" of
                        "Document Type"::Invoice:
                            if "Shipment No." = '' then
                                if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                    DialogText += Location.GetRequirementText(Location.FieldNo("Require Shipment"));
                                    Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                                end;
                        "Document Type"::"Credit Memo":
                            if "Return Receipt No." = '' then
                                if Location.Get("Location Code") and Location."Directed Put-away and Pick" then begin
                                    DialogText += Location.GetRequirementText(Location.FieldNo("Require Receive"));
                                    Error(Text016, DialogText, FieldCaption("Line No."), "Line No.");
                                end;
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

    /// <summary>
    /// Gets the journal template name to use when posting the document if the template name is mandatory for posting.
    /// </summary>
    /// <returns>The journal template name for the document if it is mandatory, otherwise blank.</returns>
    procedure GetJnlTemplateName(): Code[10]
    begin
        GLSetup.Get();
        if not GLSetup."Journal Templ. Name Mandatory" then
            exit('');

        if "IC Partner Code" = '' then begin
            GetSalesHeader();
            exit(SalesHeader."Journal Templ. Name");
        end;

        GetSalesSetup();
        if IsCreditDocType() then begin
            SalesSetup.TestField("IC Sales Cr. Memo Templ. Name");
            exit(SalesSetup."IC Sales Cr. Memo Templ. Name");
        end;
        SalesSetup.TestField("IC Sales Invoice Template Name");
        exit(SalesSetup."IC Sales Invoice Template Name");
    end;

    /// <summary>
    /// Updates the cost, price and location for return order line.
    /// </summary>
    /// <remarks>
    /// if CallingFieldNo is 0, no updates occur.
    /// </remarks>
    /// <param name="CallingFieldNo">The field number that initiated the update.</param>
    procedure ValidateReturnReasonCode(CallingFieldNo: Integer)
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
        if "Return Reason Code" = '' then begin
            if (Type = Type::Item) and ("No." <> '') then
                GetUnitCost();
            PlanPriceCalcByField(CallingFieldNo);
        end;

        if ReturnReason.Get("Return Reason Code") then begin
            if (CallingFieldNo <> FieldNo("Location Code")) and (ReturnReason."Default Location Code" <> '') then
                Validate("Location Code", ReturnReason."Default Location Code");
            if ReturnReason."Inventory Value Zero" then
                Validate("Unit Cost (LCY)", 0)
            else
                if "Unit Price" = 0 then
                    PlanPriceCalcByField(CallingFieldNo);
        end;
        UpdateUnitPriceByField(CallingFieldNo);

        OnAfterValidateReturnReasonCode(Rec, CallingFieldNo);
    end;

    /// <summary>
    /// Recalculates line discount amount and updates other line amounts.
    /// Additionally, if specified, removes the invoice discount amount from the line
    /// and reduces the invoice discount on the header for the same amount.
    /// </summary>
    /// <param name="DropInvoiceDiscountAmount">
    /// True if the invoice discount amount should be removed from the line and reduced on the header, otherwise false.
    /// </param>
    procedure ValidateLineDiscountPercent(DropInvoiceDiscountAmount: Boolean)
    var
        InvDiscountAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnValidateLineDiscountPercentOnBeforeTestJobPlanningLine(Rec, xRec, IsHandled);
        if not IsHandled then
            TestJobPlanningLine();
        TestStatusOpen();
        OnValidateLineDiscountPercentOnAfterTestStatusOpen(Rec, xRec, CurrFieldNo);
        "Line Discount Amount" :=
          Round(
            Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") *
            "Line Discount %" / 100, Currency."Amount Rounding Precision");
        if DropInvoiceDiscountAmount then begin
            InvDiscountAmount := "Inv. Discount Amount";
            "Inv. Discount Amount" := 0;
            "Inv. Disc. Amount to Invoice" := 0;
            if InvDiscountAmount <> 0 then
                ReduceInvoiceDiscValueOnHeader(InvDiscountAmount);
        end;
        OnValidateLineDiscountPercentOnBeforeUpdateAmounts(Rec, CurrFieldNo);
        UpdateAmounts();

        OnAfterValidateLineDiscountPercent(Rec, CurrFieldNo);
    end;

    local procedure ReduceInvoiceDiscValueOnHeader(InvDiscountAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReduceInvoiceDiscValueOnHeader(SalesHeader, InvDiscountAmount, IsHandled);
        if IsHandled then
            exit;

        if IsNullGuid(SalesHeader.SystemId) then
            exit;
        if SalesHeader."Invoice Discount Value" = 0 then
            exit;
        if SalesHeader."Invoice Discount Calculation" = SalesHeader."Invoice Discount Calculation"::"%" then
            exit;
        SalesHeader."Invoice Discount Value" -= InvDiscountAmount;
        SalesHeader.Modify(true);
    end;

    local procedure ValidateVATProdPostingGroup()
    var
        IsHandled: boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVATProdPostingGroup(IsHandled, Rec);
        if IsHandled then
            exit;

        Validate("VAT Prod. Posting Group");
    end;

    local procedure ValidateUnitOfMeasureCodeFromNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateUnitOfMeasureCodeFromNo(Rec, xRec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        Validate("Unit of Measure Code");
    end;

    local procedure NotifyOnMissingSetup(FieldNumber: Integer)
    var
        DiscountNotificationMgt: Codeunit "Discount Notification Mgt.";
    begin
        if CurrFieldNo = 0 then
            exit;
        GetSalesSetup();
        DiscountNotificationMgt.RecallNotification(SalesSetup.RecordId);
        if (FieldNumber = FieldNo("Line Discount Amount")) and ("Line Discount Amount" = 0) then
            exit;
        DiscountNotificationMgt.NotifyAboutMissingSetup(
          SalesSetup.RecordId, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group",
          SalesSetup."Discount Posting", SalesSetup."Discount Posting"::"Invoice Discounts");
    end;

    /// <summary>
    /// Determines if mandatory fields have to be filled in for the line based on the line type.
    /// By default, only empty type is not considered mandatory, but can be overridden by the event.
    /// </summary>
    /// <returns>True if mandatory fields have to be filled in, otherwise false.</returns>
    procedure HasTypeToFillMandatoryFields() ReturnValue: Boolean
    begin
        ReturnValue := Type <> Type::" ";

        OnAfterHasTypeToFillMandatoryFields(Rec, ReturnValue);
    end;

    /// <summary>
    /// Gets the defferal amount for the sales line to be used in deferral schedules.
    /// </summary>
    /// <returns>The deferral amount.</returns>
    procedure GetDeferralAmount() DeferralAmount: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDeferralAmount(Rec, IsHandled, DeferralAmount);
        if IsHandled then
            exit;

        if "VAT Base Amount" <> 0 then
            DeferralAmount := "VAT Base Amount"
        else
            DeferralAmount := CalcLineAmount();
    end;

    /// <summary>
    /// Removes or updates the deferral schedule for the sales line to reflect changes in the deferral amount and posting date.
    /// </summary>
    procedure UpdateDeferralAmounts()
    var
        AdjustStartDate: Boolean;
        IsHandled: Boolean;
        DeferralPostDate: Date;
    begin
        IsHandled := false;
        OnBeforeUpdateDeferralAmounts(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesHeader();
        OnGetDeferralPostDate(SalesHeader, DeferralPostDate, Rec);
        if DeferralPostDate = 0D then
            DeferralPostDate := SalesHeader."Posting Date";
        AdjustStartDate := true;
        if "Document Type" = "Document Type"::"Return Order" then begin
            if "Returns Deferral Start Date" = 0D then
                "Returns Deferral Start Date" := SalesHeader."Posting Date";
            DeferralPostDate := "Returns Deferral Start Date";
            AdjustStartDate := false;
        end;

        DeferralUtilities.RemoveOrSetDeferralSchedule(
            "Deferral Code", Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
            "Document Type".AsInteger(), "Document No.", "Line No.",
            GetDeferralAmount(), DeferralPostDate, Description, SalesHeader."Currency Code", AdjustStartDate);
    end;

    /// <summary>
    /// Formats the price description for the sales line based on the line type and line discount.
    /// </summary>
    /// <remarks>
    /// This procedure is only used in Microsoft Invoicing objects which have been discontinoued and will be removed in a future version.
    /// </remarks>
    procedure UpdatePriceDescription()
    var
        Currency: Record Currency;
    begin
        "Price description" := '';
        if Type in [Type::"Charge (Item)", Type::"Fixed Asset", Type::Item, Type::Resource] then
            if "Line Discount %" = 0 then
                "Price description" := StrSubstNo(
                    PriceDescriptionTxt, Quantity, Currency.ResolveGLCurrencySymbol("Currency Code"),
                    "Unit Price", "Unit of Measure")
            else
                "Price description" := StrSubstNo(
                    PriceDescriptionWithLineDiscountTxt, Quantity, Currency.ResolveGLCurrencySymbol("Currency Code"),
                    "Unit Price", "Unit of Measure", "Line Discount %");
    end;

    local procedure UpdateVATPercent(BaseAmount: Decimal; VATAmount: Decimal)
    begin
        if BaseAmount <> 0 then
            "VAT %" := Round(100 * VATAmount / BaseAmount, 0.00001)
        else
            ClearVATPct();
        OnAfterUpdateVATPercent(Rec);
    end;

    /// <summary>
    /// Opens a page with deferral schedule for the sales line.
    /// </summary>
    /// <remarks>
    /// If the deferral schedule doesn't exist yet, a new one is created and commited before the page is opened.
    /// </remarks>
    /// <param name="PostingDate">Posting date to calculate the schedule from if a new deferral schedule is created.</param>
    /// <param name="CurrencyCode">Currency code to use for a new deferral schedule.</param>
    /// <returns>True if deferral schedule was changed, otherwise false.</returns>
    procedure ShowDeferrals(PostingDate: Date; CurrencyCode: Code[10]) ReturnValue: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDeferrals(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(
            DeferralUtilities.OpenLineScheduleEdit(
                "Deferral Code", Enum::"Deferral Document Type"::Sales.AsInteger(), '', '',
                "Document Type".AsInteger(), "Document No.", "Line No.",
                GetDeferralAmount(), PostingDate, Description, CurrencyCode));
    end;

    /// <summary>
    /// Initializes the default values for the sales line based on the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header to initialize the default values from.</param>
    procedure InitHeaderDefaults(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin

        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            CheckQuoteCustomerTemplateCode(SalesHeader)
        else begin
            IsHandled := false;
            OnInitHeaderDefaultsOnBeforeTestSellToCustomerNo(Rec, SalesHeader, IsHandled);
            if not IsHandled then
                SalesHeader.TestField("Sell-to Customer No.");
        end;

        "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        "Currency Code" := SalesHeader."Currency Code";
        InitHeaderLocactionCode(SalesHeader);
        "Customer Price Group" := SalesHeader."Customer Price Group";
        Validate("Customer Disc. Group", SalesHeader."Customer Disc. Group");
        "Allow Line Disc." := SalesHeader."Allow Line Disc.";
        "Transaction Type" := SalesHeader."Transaction Type";
        "Transport Method" := SalesHeader."Transport Method";
        "Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        "Price Calculation Method" := SalesHeader."Price Calculation Method";
        "Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SalesHeader."VAT Bus. Posting Group";
        "Exit Point" := SalesHeader."Exit Point";
        Area := SalesHeader.Area;
        "Transaction Specification" := SalesHeader."Transaction Specification";
        "Tax Area Code" := SalesHeader."Tax Area Code";
        "Tax Liable" := SalesHeader."Tax Liable";
        if not "System-Created Entry" and ("Document Type" in ["Document Type"::Order, "Document Type"::Quote]) and HasTypeToFillMandatoryFields() or
           IsServiceChargeLine()
        then
            "Prepayment %" := SalesHeader."Prepayment %";
        "Prepayment Tax Area Code" := SalesHeader."Tax Area Code";
        "Prepayment Tax Liable" := SalesHeader."Tax Liable";
        "Responsibility Center" := SalesHeader."Responsibility Center";

        "Shipping Agent Code" := SalesHeader."Shipping Agent Code";
        "Shipping Agent Service Code" := SalesHeader."Shipping Agent Service Code";
        "Outbound Whse. Handling Time" := SalesHeader."Outbound Whse. Handling Time";
        "Shipping Time" := SalesHeader."Shipping Time";

        "Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesHeader."Dimension Set ID";

        OnAfterInitHeaderDefaults(Rec, SalesHeader, xRec);
    end;

    local procedure InitHeaderLocactionCode(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitHeaderLocactionCode(Rec, IsHandled);
        if IsHandled then
            exit;
        "Location Code" := SalesHeader."Location Code";
    end;

    local procedure InitDeferralCode()
    var
        Item: Record Item;
        IsHandled: Boolean;
        ShouldUpdateDeferralCode: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitDeferralCode(Rec, IsHandled);
        if IsHandled then
            exit;

        ShouldUpdateDeferralCode := "Document Type" in ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::"Credit Memo", "Document Type"::"Return Order"];
        OnInitDeferralCodeOnBeforeUpdateDeferralCode(Rec, ShouldUpdateDeferralCode);
        if ShouldUpdateDeferralCode then
            case Type of
                Type::"G/L Account":
                    Validate("Deferral Code", GLAcc."Default Deferral Template Code");
                Type::Item:
                    begin
                        GetItem(Item);
                        Validate("Deferral Code", Item."Default Deferral Template Code");
                    end;
                Type::Resource:
                    Validate("Deferral Code", Res."Default Deferral Template Code");
            end;
    end;

    /// <summary>
    /// Updates the deferral code to the default deferral template code specified on the associated item, resource or g/l account.
    /// </summary>
    /// <remarks>
    /// The deferral code is not set for lines of blanket orders and quotes.
    /// </remarks>
    procedure DefaultDeferralCode()
    var
        Item: Record Item;
    begin
        case Type of
            Type::"G/L Account":
                begin
                    GLAcc.Get("No.");
                    InitDeferralCode();
                end;
            Type::Item:
                begin
                    GetItem(Item);
                    InitDeferralCode();
                end;
            Type::Resource:
                begin
                    Res.Get("No.");
                    InitDeferralCode();
                end;
        end;
    end;

    /// <summary>
    /// Determines if the document type of the line is a credit document type.
    /// </summary>
    /// <returns>True if the document type is a credit document type, otherwise false.</returns>
    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnAfterIsCreditDocType(Rec, CreditDocType);
    end;

    local procedure IsFullyInvoiced(): Boolean
    begin
        exit(("Qty. Shipped Not Invd. (Base)" = 0) and ("Qty. Shipped (Base)" = "Quantity (Base)"))
    end;

    local procedure CleanDropShipmentFields()
    begin
        if ("Purch. Order Line No." <> 0) and IsFullyInvoiced() then
            if CleanPurchaseLineDropShipmentFields() then begin
                "Purchase Order No." := '';
                "Purch. Order Line No." := 0;
            end;
    end;

    local procedure CleanSpecialOrderFieldsAndCheckAssocPurchOrder()
    begin
        OnBeforeCleanSpecialOrderFieldsAndCheckAssocPurchOrder(Rec);

        if ("Special Order Purch. Line No." <> 0) and IsFullyInvoiced() then
            if CleanPurchaseLineSpecialOrderFields() then begin
                "Special Order Purchase No." := '';
                "Special Order Purch. Line No." := 0;
            end;

        CheckAssocPurchOrder('');
    end;

    local procedure CleanPurchaseLineDropShipmentFields(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Purchase Order No.", "Purch. Order Line No.") then begin
            if PurchaseLine."Qty. Received (Base)" < "Qty. Shipped (Base)" then
                exit(false);

            PurchaseLine."Sales Order No." := '';
            PurchaseLine."Sales Order Line No." := 0;
            PurchaseLine.Modify();
        end;

        exit(true);
    end;

    local procedure CleanPurchaseLineSpecialOrderFields() Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCleanPurchaseLineSpecialOrderFields(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Special Order Purchase No.", "Special Order Purch. Line No.") then begin
            if PurchaseLine."Qty. Received (Base)" < "Qty. Shipped (Base)" then
                exit(false);

            PurchaseLine."Special Order" := false;
            PurchaseLine."Special Order Sales No." := '';
            PurchaseLine."Special Order Sales Line No." := 0;
            PurchaseLine.Modify();
        end;

        exit(true);
    end;

    /// <summary>
    /// Determines if item unit of measure code can be edited.
    /// </summary>
    /// <remarks>
    /// If this is not an item line or if item is not selected the procedure always return true.
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

    local procedure ValidateTaxGroupCode()
    var
        TaxDetail: Record "Tax Detail";
    begin
        if ("Tax Area Code" <> '') and ("Tax Group Code" <> '') then
            TaxDetail.ValidateTaxSetup("Tax Area Code", "Tax Group Code", "Posting Date");
    end;

    /// <summary>
    /// Creates or updates a sales line for freight for a specified freight amount.
    /// </summary>
    /// <remarks>
    /// If the freight amount is negative, it's set to 0 and no line is created or updated.
    /// The current sales line does not point to the freight line after the procedure is executed.
    /// </remarks>
    /// <param name="FreightAmount">The new unit price of created or updated line.</param>
    procedure InsertFreightLine(var FreightAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        FreightAmountQuantity: Integer;
    begin
        if FreightAmount <= 0 then begin
            FreightAmount := 0;
            exit;
        end;

        FreightAmountQuantity := 1;

        SalesSetup.Get();
        SalesSetup.TestField("Freight G/L Acc. No.");

        TestField("Document No.");
        OnInsertFreightLineOnAfterCheckDocumentNo(SalesLine, Rec);

        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "Document No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", SalesSetup."Freight G/L Acc. No.");
        // "Quantity Shipped" will be equal to 0 until FreightAmount line successfully shipped
        SalesLine.SetRange("Quantity Shipped", 0);
        if SalesLine.FindFirst() then begin
            SalesLine.Validate(Quantity, FreightAmountQuantity);
            SalesLine.Validate("Unit Price", FreightAmount);
            SalesLine.Modify();
        end else begin
            SalesLine.SetRange(Type);
            SalesLine.SetRange("No.");
            SalesLine.SetRange("Quantity Shipped");
            SalesLine.FindLast();
            SalesLine."Line No." += 10000;
            SalesLine.Init();
            SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
            SalesLine.Validate("No.", SalesSetup."Freight G/L Acc. No.");
            SalesLine.Validate(Description, FreightLineDescriptionTxt);
            SalesLine.Validate(Quantity, FreightAmountQuantity);
            SalesLine.Validate("Unit Price", FreightAmount);
            SalesLine.Insert();
        end;
    end;

    local procedure CalcTotalAmtToAssign(TotalQtyToAssign: Decimal) TotalAmtToAssign: Decimal
    begin
        TotalAmtToAssign := CalcLineAmount() * TotalQtyToAssign / Quantity;
        if SalesHeader."Prices Including VAT" then
            TotalAmtToAssign := TotalAmtToAssign / (1 + "VAT %" / 100) - "VAT Difference";

        TotalAmtToAssign := Round(TotalAmtToAssign, Currency."Amount Rounding Precision");
    end;

    /// <summary>
    /// Determines if additional lookup for item description is required.
    /// Used for integration purposes when the default item description lookup is not sufficient.
    /// </summary>
    /// <remarks>
    /// This is currently only used in Microsoft Invoicing functionality which has been discontinued and will be removed in a future version.
    /// </remarks>
    /// <returns>True if additional lookup for item description is required, otherwise false.</returns>
    procedure IsLookupRequested() Result: Boolean
    begin
        Result := LookupRequested;
        LookupRequested := false;
    end;

    /// <summary>
    /// Verifies that item related fields on the item sales line match the provided values.
    /// If the values do not match, an error is thrown.
    /// </summary>
    /// <param name="ItemNo">The item number to verify.</param>
    /// <param name="VariantCode">The variant code to verify.</param>
    /// <param name="LocationCode">The location code to verify.</param>
    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField(Type, Type::Item);
        TestField("No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    /// <summary>
    /// Calculates and sets the shipped not invoiced amount excluding VAT in LCY.
    /// </summary>
    procedure CalculateNotShippedInvExlcVatLCY()
    var
        Currency2: Record Currency;
    begin
        Currency2.InitRoundingPrecision();
        if Rec."VAT Calculation Type" = Rec."VAT Calculation Type"::"Full VAT" then
            Rec."Shipped Not Inv. (LCY) No VAT" := 0
        else
            Rec."Shipped Not Inv. (LCY) No VAT" := Round("Shipped Not Invoiced (LCY)" / (1 + "VAT %" / 100), Currency2."Amount Rounding Precision");
    end;

    /// <summary>
    /// Resets the global SalesHeader variable.
    /// </summary>
    procedure ClearSalesHeader()
    begin
        Clear(SalesHeader);
    end;

    local procedure GetBlockedItemNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8EC');
    end;

    procedure SendBlockedItemNotification()
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
    /// Sends a notification if the line invoice discount amount is reset.
    /// </summary>
    procedure SendLineInvoiceDiscountResetNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        if ("Inv. Discount Amount" = 0) and (xRec."Inv. Discount Amount" <> 0) and ("Line Amount" <> 0) then begin
            NotificationToSend.Id := SalesHeader.GetLineInvoiceDiscountResetNotificationId();
            NotificationToSend.Message := StrSubstNo(LineInvoiceDiscountAmountResetTok, RecordId);

            NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId);
        end;
    end;

    /// <summary>
    /// Gets the text representation of the document type for the sales line.
    /// </summary>
    /// <returns>The text representation of the document type.</returns>
    procedure GetDocumentTypeDescription(): Text
    begin
        exit(Format("Document Type"));
    end;

    /// <summary>
    /// Gets the text representation of the line type for the sales line.
    /// </summary>
    /// <remarks>
    /// Blank line type is represented by the comment label.
    /// </remarks>
    /// <returns>The text representation of the line type.</returns>
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
    /// Renames all sales lines for the specified line type and number to a new number. Used when related entities are renamed.
    /// </summary>
    /// <param name="LineType">The line type of lines to rename.</param>
    /// <param name="OldNo">The old number to rename from.</param>
    /// <param name="NewNo">The new number to rename to.</param>
    procedure RenameNo(LineType: Enum "Sales Line Type"; OldNo: Code[20];
                                     NewNo: Code[20])
    begin
        Reset();
        SetRange(Type, LineType);
        SetRange("No.", OldNo);
        if not Rec.IsEmpty() then
            ModifyAll("No.", NewNo, true);
    end;

    /// <summary>
    /// Updates the 'planned' status of a sales line, depending if all the outstanding quantity is reserved or not.
    /// </summary>
    /// <returns>True if the 'planned' status was updated, otherwise false.</returns>
    procedure UpdatePlanned() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePlanned(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TestField("Qty. per Unit of Measure");
        CalcFields("Reserved Quantity");
        if Planned = ("Reserved Quantity" = "Outstanding Quantity") then
            exit(false);
        Planned := not Planned;
        exit(true);
    end;

    /// <summary>
    /// Determines if the line is a charge item line that has been at least partially assigned.
    /// </summary>
    /// <returns>True if the line is a charge item line that has been at least partially assigned, otherwise false.</returns>
    procedure AssignedItemCharge(): Boolean
    begin
        exit((Type = Type::"Charge (Item)") and ("No." <> '') and ("Qty. to Assign" < Quantity));
    end;

    local procedure UpdateLineDiscPct()
    var
        LineDiscountPct: Decimal;
        IsHandled: Boolean;
        IsOutOfStandardDiscPctRange: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLineDiscPct(Rec, IsHandled, Currency);
        if IsHandled then
            exit;

        if Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") <> 0 then begin
            LineDiscountPct := Round(
                "Line Discount Amount" / Round(Quantity * "Unit Price", Currency."Amount Rounding Precision") * 100,
                0.00001);
            IsOutOfStandardDiscPctRange := not (LineDiscountPct in [0 .. 100]);
            OnUpdateLineDiscPctOnAfterCalcIsOutOfStandardDiscPctRange(Rec, IsOutOfStandardDiscPctRange);
            if IsOutOfStandardDiscPctRange then
                Error(LineDiscountPctErr);
            "Line Discount %" := LineDiscountPct;
        end else
            "Line Discount %" := 0;

        OnAfterUpdateLineDiscPct(Rec);
    end;

    procedure UpdateBaseAmounts(NewAmount: Decimal; NewAmountIncludingVAT: Decimal; NewVATBaseAmount: Decimal)
    begin
        Amount := NewAmount;
        "Amount Including VAT" := NewAmountIncludingVAT;
        "VAT Base Amount" := NewVATBaseAmount;

        OnAfterUpdateBaseAmounts(Rec, xRec, CurrFieldNo);
    end;

    /// <summary>
    /// Calculates the planned delivery if shippment time is specified, otherwise the planned shipment date.
    /// </summary>
    /// <returns>The calculated planned delivery date or planned shipment date.</returns>
    procedure CalcPlannedDate(): Date
    begin
        if Format("Shipping Time") <> '' then
            exit(CalcPlannedDeliveryDate(FieldNo("Planned Delivery Date")));

        exit(CalcPlannedShptDate(FieldNo("Planned Delivery Date")));
    end;

    local procedure IsCalcVATAmountLinesHandled(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping; IncludePrepayments: Boolean) IsHandled: Boolean
    begin
        IsHandled := false;
        OnBeforeCalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, IsHandled, QtyType, IncludePrepayments);
        exit(IsHandled);
    end;

    /// <summary>
    /// Updates the unit cost in LCY based on the quantity per unit of measure and unit cost from either the item or it's SKU.
    /// </summary>
    /// <param name="Item">The item record to update the unit cost from.</param>
    procedure ValidateUnitCostLCYOnGetUnitCost(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateUnitCostLCYOnGetUnitCost(IsHandled, Rec, Item);
        if IsHandled then
            exit;

        if GetSKU() then
            Validate("Unit Cost (LCY)", SKU."Unit Cost" * "Qty. per Unit of Measure")
        else
            Validate("Unit Cost (LCY)", Item."Unit Cost" * "Qty. per Unit of Measure");
    end;

    local procedure AssignResourceUoM()
    var
        ResUnitofMeasure: Record "Resource Unit of Measure";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignResourceUoM(ResUnitofMeasure, IsHandled);
        if IsHandled then
            exit;

        ResUnitofMeasure.Get("No.", "Unit of Measure Code");
        "Qty. per Unit of Measure" := ResUnitofMeasure."Qty. per Unit of Measure";

        OnAfterAssignResourceUOM(Rec, Resource, ResUnitofMeasure);
    end;

    /// <summary>
    /// Throws an error if requested delivery date was changed after the promised delivery date is set.
    /// </summary>
    procedure CheckPromisedDeliveryDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPromisedDeliveryDate(SalesHeader, IsHandled, Rec, xRec);
        if IsHandled then
            exit;

        if ("Requested Delivery Date" <> xRec."Requested Delivery Date") and ("Promised Delivery Date" <> 0D) then
            Error(Text028, FieldCaption("Requested Delivery Date"), FieldCaption("Promised Delivery Date"));
    end;

    /// <summary>
    /// Checks the changes to the sales line and adjusts the reservation for the line accordingly.
    /// </summary>
    /// <param name="CallingFieldNo">The field number that initiated the check.</param>
    protected procedure VerifyChangeForSalesLineReserve(CallingFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyChangeForSalesLineReserve(Rec, xRec, CallingFieldNo, IsHandled);
        if IsHandled then
            exit;

        SalesLineReserve.VerifyChange(Rec, xRec);
    end;

    local procedure CheckReservedQtyBase()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReservedQtyBase(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    local procedure CheckNotInvoicedQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNotInvoicedQty(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Shipment No." = '' then
            TestField("Qty. Shipped Not Invoiced", 0);
        if "Return Receipt No." = '' then
            TestField("Return Qty. Rcd. Not Invd.", 0);
    end;

    local procedure CheckInventoryPickConflict()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInventoryPickConflict(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsInventoriableItem() then
            if SalesHeader.InventoryPickConflict("Document Type", "Document No.", SalesHeader."Shipping Advice") then
                Error(CanNotAddItemPickExistErr, SalesHeader."Shipping Advice");
    end;

    local procedure CheckQuantitySign()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantitySign(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsCreditDocType() then begin
            if Quantity > 0 then
                FieldError(Quantity, Text030);
        end else
            if Quantity < 0 then
                FieldError(Quantity, Text029);
    end;

    local procedure ShowReturnedUnitsError(var ItemLedgEntry: Record "Item Ledger Entry"; QtyReturned: Decimal; QtyNotReturned: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReturnedUnitsError(Rec, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        Error(Text039, -QtyReturned, ItemLedgEntry.FieldCaption("Document No."), ItemLedgEntry."Document No.", -QtyNotReturned);
    end;

    /// <summary>
    /// Open a page with the sales lines related to the blanket order line.
    /// </summary>
    /// <param name="DocumentType">The document type of the sales lines to show.</param>
    procedure ShowBlanketOrderSalesLines(DocumentType: Enum "Sales Document Type")
    var
        RelatedSalesLine: Record "Sales Line";
    begin
        RelatedSalesLine.Reset();
        RelatedSalesLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
        RelatedSalesLine.SetRange("Document Type", DocumentType);
        RelatedSalesLine.SetRange("Blanket Order No.", Rec."Document No.");
        RelatedSalesLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Sales Lines", RelatedSalesLine);
    end;

    /// <summary>
    /// Open a page with the posted sales shipment lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedShipmentLines()
    var
        SaleShptLine: Record "Sales Shipment Line";
    begin
        SaleShptLine.Reset();
        SaleShptLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        SaleShptLine.SetRange("Blanket Order No.", Rec."Document No.");
        SaleShptLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Sales Shipment Lines", SaleShptLine);
    end;

    /// <summary>
    /// Open a page with the posted sales invoice lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedInvoiceLines()
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        SalesInvLine.SetRange("Blanket Order No.", Rec."Document No.");
        SalesInvLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Sales Invoice Lines", SalesInvLine);
    end;

    /// <summary>
    /// Open a page with the posted return receipt lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedReturnReceiptLines()
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        ReturnRcptLine.Reset();
        ReturnRcptLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        ReturnRcptLine.SetRange("Blanket Order No.", Rec."Document No.");
        ReturnRcptLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Return Receipt Lines", ReturnRcptLine);
    end;

    /// <summary>
    /// Open a page with the posted sales credit memo lines related to the blanket order line.
    /// </summary>
    procedure ShowBlanketOrderPostedCreditMemoLines()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetCurrentKey("Blanket Order No.", "Blanket Order Line No.");
        SalesCrMemoLine.SetRange("Blanket Order No.", Rec."Document No.");
        SalesCrMemoLine.SetRange("Blanket Order Line No.", Rec."Line No.");
        PAGE.RunModal(PAGE::"Posted Sales Credit Memo Lines", SalesCrMemoLine);
    end;

    /// <summary>
    /// Opens a page with deferral schedule for the sales line.
    /// </summary>
    /// <remarks>
    /// If the deferral schedule doesn't exist yet, a new one is created and commited before the page is opened.
    /// The posting date and currency code for the new schedule are taken from the sales header.
    /// </remarks>
    procedure ShowDeferralSchedule()
    begin
        GetSalesHeader();
        ShowDeferrals(SalesHeader."Posting Date", SalesHeader."Currency Code");
    end;

    local procedure CheckNonstockItemTemplate(NonstockItem: Record "Nonstock Item")
    var
        ItemTempl: Record "Item Templ.";
    begin
        ItemTempl.Get(NonstockItem."Item Templ. Code");
        ItemTempl.TestField("Gen. Prod. Posting Group");
        if ItemTempl.Type = ItemTempl.Type::Inventory then
            ItemTempl.TestField("Inventory Posting Group");
    end;

    local procedure CheckQuoteCustomerTemplateCode(SalesHeader: Record "Sales Header")
    begin
        if (SalesHeader."Sell-to Customer No." = '') and
           (SalesHeader."Sell-to Customer Templ. Code" = '')
        then
            Error(
              Text031,
              SalesHeader.FieldCaption("Sell-to Customer No."),
              SalesHeader.FieldCaption("Sell-to Customer Templ. Code"));
        if (SalesHeader."Bill-to Customer No." = '') and
           (SalesHeader."Bill-to Customer Templ. Code" = '')
        then
            Error(
              Text031,
              SalesHeader.FieldCaption("Bill-to Customer No."),
              SalesHeader.FieldCaption("Bill-to Customer Templ. Code"));
    end;

    /// <summary>
    /// Converts the specified quantity to the quantity in the base unit of measure.
    /// </summary>
    /// <param name="Qty">The quantity to convert.</param>
    /// <param name="FromFieldName">Caption of the field containing the quantity to convert.</param>
    /// <param name="ToFieldName">Caption of the field containing the converted quantity.</param>
    /// <returns>The quantity in the base unit of measure.</returns>
    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);
        exit(UOMMgt.CalcBaseQty(
            "No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure IsShipmentBinOverridesDefaultBin(Location: Record Location): Boolean
    var
        Bin: Record Bin;
        ShipmentBinAvailable: Boolean;
    begin
        ShipmentBinAvailable := Bin.Get(Location.Code, Location."Shipment Bin Code");
        exit(Location."Require Shipment" and ShipmentBinAvailable);
    end;

    /// <summary>
    /// Initializes the dimensions for the sales line if default dimensions are defined for the specified field.
    /// </summary>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        ShouldCreateDim: Boolean;
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        ShouldCreateDim := DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo));
        OnCreateDimFromDefaultDimOnBeforeCreateDim(Rec, SalesHeader, ShouldCreateDim);
        if ShouldCreateDim then
            CreateDim(DefaultDimSource);
        OnAfterCreateDimFromDefaultDim(Rec, xRec, SalesHeader, CurrFieldNo, FieldNo);
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitTableValuePair(TableValuePair, FieldNo, IsHandled, Rec);
        if IsHandled then
            exit;

        case true of
            FieldNo = Rec.FieldNo("No."):
                TableValuePair.Add(DimMgt.SalesLineTypeToTableID(Type), Rec."No.");
            FieldNo = Rec.FieldNo("Responsibility Center"):
                TableValuePair.Add(Database::"Responsibility Center", Rec."Responsibility Center");
            FieldNo = Rec.FieldNo("Job No."):
                TableValuePair.Add(Database::Job, Rec."Job No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;
        OnAfterInitTableValuePair(TableValuePair, FieldNo, Rec);
    end;

    /// <summary>
    /// Collects default dimension sources for the sales line
    /// with the dimension source for the specified field added in the first place.
    /// </summary>
    /// <param name="DefaultDimSource">Return value: The list of default dimension sources.</param>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.SalesLineTypeToTableID(Type), Rec."No.", FieldNo = Rec.FieldNo("No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    /// <summary>
    /// Collects default dimension sources for the sales line.
    /// </summary>
    /// <remarks>
    /// The FieldNo is only used on the event publisher.
    /// </remarks>
    /// <param name="DefaultDimSource">Return value: The list of default dimension sources.</param>
    /// <param name="JobNo">The job number to add to the dimension sources.</param>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; JobNo: Code[20]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.SalesLineTypeToTableID(Type), Rec."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, JobNo);
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

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
        Resource2: Record Resource;
        FixedAsset: Record "Fixed Asset";
        ItemCharge2: Record "Item Charge";
        AllocationAccount: Record "Allocation Account";
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
                    SelectedRecordRef.SetTable(Resource2);
                    RecVariant := Resource2;
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

    /// <summary>
    /// Opens a page with inventory item lines and attaches the selected line
    /// to all non-inventoriable sales lines in the passed SelectedSalesLine record set.
    /// </summary>
    /// <param name="SelectedSalesLine">The record set of sales lines to attach the inventory item line to.</param>
    procedure AttachToInventoryItemLine(var SelectedSalesLine: Record "Sales Line")
    var
        InvtItemSalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAttachToInventoryItemLine(SelectedSalesLine, IsHandled);
        if IsHandled then
            exit;

        SelectedSalesLine.SetFilter(Type, '>%1', SelectedSalesLine.Type::" ");
        SelectedSalesLine.SetFilter(Quantity, '<>0');
        if not SelectedSalesLine.FindSet() then
            exit;

        InvtItemSalesLine.SetRange("Document Type", SelectedSalesLine."Document Type");
        InvtItemSalesLine.SetRange("Document No.", SelectedSalesLine."Document No.");
        InvtItemSalesLine.SetRange(Type, SelectedSalesLine.Type::Item);
        InvtItemSalesLine.SetRange("Attached to Line No.", 0);
        if InvtItemSalesLine.FindSet() then
            repeat
                if InvtItemSalesLine.IsInventoriableItem() then begin
                    TempSalesLine := InvtItemSalesLine;
                    TempSalesLine.Insert();
                end;
            until InvtItemSalesLine.Next() = 0;

        if PAGE.RunModal(PAGE::"Sales Lines", TempSalesLine) = ACTION::LookupOK then
            if TempSalesLine."Line No." <> 0 then
                repeat
                    if not SelectedSalesLine.IsInventoriableItem() then begin
                        SelectedSalesLine."Attached to Line No." := TempSalesLine."Line No.";
                        SelectedSalesLine.Modify();
                    end;
                until SelectedSalesLine.Next() = 0;
    end;

    /// <summary>
    /// Restores the selected record from the lookup state manager to the sales line.
    /// </summary>
    procedure RestoreLookupSelection()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Resource2: Record Resource;
        FixedAsset: Record "Fixed Asset";
        ItemCharge2: Record "Item Charge";
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
    begin
        if LookupStateManager.IsRecordSaved() then begin
            case Rec.Type of
                Rec.Type::Item:
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        Item := RecVariant;
                        Rec.Validate("No.", Item."No.");
                    end;
                Rec.Type::"G/L Account":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        GLAccount := RecVariant;
                        Rec.Validate("No.", GLAccount."No.");
                    end;
                Rec.Type::Resource:
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        Resource2 := RecVariant;
                        Rec.Validate("No.", Resource2."No.");
                    end;
                Rec.Type::"Fixed Asset":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        FixedAsset := RecVariant;
                        Rec.Validate("No.", FixedAsset."No.");
                    end;
                Rec.Type::"Charge (Item)":
                    begin
                        RecVariant := LookupStateManager.GetSavedRecord();
                        ItemCharge2 := RecVariant;
                        Rec.Validate("No.", ItemCharge2."No.");
                    end;
            end;
            LookupStateManager.ClearSavedRecord();
        end;
    end;

    local procedure UpdateVATRoundingFromVATAmountLines()
    var
        TempSalesHeader: Record "Sales Header" temporary;
        TempSalesLine: Record "Sales Line" temporary;
        SalesDoc: Codeunit "Release Sales Document";
    begin
        GetSalesHeader();

        if not SalesHeader."Prices Including VAT" then
            exit;

        TempSalesHeader.Init();
        TempSalesHeader := SalesHeader;
        TempSalesHeader.Insert();

        TempSalesLine.Init();
        TempSalesLine.Copy(Rec);
        TempSalesLine.Insert();

        if SalesDoc.CalcAndUpdateVATOnLines(TempSalesHeader, TempSalesLine) then
            if Abs(Amount) < Abs(TempSalesLine.Amount) then begin
                Amount := TempSalesLine.Amount;
                "VAT Base Amount" := TempSalesLine."VAT Base Amount";
                "VAT Difference" := TempSalesLine."VAT Difference";
                "Amount Including VAT" := TempSalesLine."Amount Including VAT";
            end;
    end;

    /// <summary>
    /// Gets the date to use in calculations for the sales line. Used in finding item references and price calculations.
    /// </summary>
    /// <returns>The date for calculations.</returns>
    procedure GetDateForCalculations() CalculationDate: Date;
    var
        FromSalesHeader: Record "Sales Header";
    begin
        if Rec."Document No." <> '' then
            FromSalesHeader := Rec.GetSalesHeader();
        CalculationDate := GetDateForCalculations(FromSalesHeader);
    end;

    /// <summary>
    /// Gets the date to use in calculations for the sales line. Used in finding item references and price calculations.
    /// </summary>
    /// <param name="FromSalesHeader">The sales header to get the date from.</param>
    /// <returns>The date for calculations.</returns>
    procedure GetDateForCalculations(FromSalesHeader: Record "Sales Header") CalculationDate: Date;
    begin
        if Rec."Document No." = '' then
            CalculationDate := Rec."Posting Date"
        else
            if FromSalesHeader."Document Type" in [FromSalesHeader."Document Type"::Invoice, FromSalesHeader."Document Type"::"Credit Memo"] then
                CalculationDate := FromSalesHeader."Posting Date"
            else
                CalculationDate := FromSalesHeader."Order Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    /// <summary>
    /// Updates the shipping time on the sales line.
    /// </summary>
    procedure GetShippingTime()
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShippingTime(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Shipping Agent Service Code" <> xRec."Shipping Agent Service Code" then
            Evaluate(Rec."Shipping Time", '<>');

        if Rec."Drop Shipment" then begin
            Evaluate(Rec."Shipping Time", '<0D>');
            Rec.UpdateDates();
        end else
            if ShippingAgentServices.Get(Rec."Shipping Agent Code", Rec."Shipping Agent Service Code") then
                Rec."Shipping Time" := ShippingAgentServices."Shipping Time"
            else begin
                Rec.GetSalesHeader();
                Rec."Shipping Time" := SalesHeader."Shipping Time";
            end;
    end;

    local procedure CheckItemCanBeAddedToSalesLine()
    begin
        if Type = Type::Item then
            if "No." <> '' then
                if IsInventoriableItem() then begin
                    if SalesHeader.InventoryPickConflict("Document Type", "Document No.", SalesHeader."Shipping Advice") then
                        Error(CanNotAddItemPickExistErr, SalesHeader."Shipping Advice");
                    if SalesHeader.WhseShipmentConflict("Document Type", "Document No.", SalesHeader."Shipping Advice") then
                        Error(CanNotAddItemWhsShipmentExistErr, SalesHeader."Shipping Advice");
                end;
    end;

    local procedure SetLoadFieldsForInvDiscoundCalculation(var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetLoadFields(
            "Document Type", "Document No.", Type, "No.", "Shipment No.", "Return Receipt No.", "Deferral Code",
            Quantity, "Quantity (Base)", "Qty. to Invoice", "Qty. to Invoice (Base)", "Qty. Shipped Not Invoiced", "Qty. Shipped Not Invd. (Base)", "Ret. Qty. Rcd. Not Invd.(Base)", "Return Qty. Received (Base)",
            "Return Qty. Rcd. Not Invd.", "Qty. to Ship", "Qty. to Ship (Base)", "Return Qty. to Receive", "Return Qty. to Receive (Base)", "Return Qty. Received", "Outstanding Quantity", "Outstanding Qty. (Base)",
            "Quantity Invoiced", "Qty. Invoiced (Base)", "Quantity Shipped", "Qty. Shipped (Base)", "Qty. per Unit of Measure", "Reserved Quantity",
            "Unit Price", "Amount Including VAT", Amount, "Line Amount", "Inv. Discount Amount", "Inv. Disc. Amount to Invoice", "VAT Difference", "VAT Base Amount",
            "Outstanding Amount", "Outstanding Amount (LCY)", "Shipped Not Invoiced", "Shipped Not Invoiced (LCY)", "Return Rcd. Not Invd.", "Return Rcd. Not Invd. (LCY)",
            "System-Created Entry", "VAT Identifier", "VAT Calculation Type", "Tax Group Code", "VAT %", "Allow Invoice Disc.", "Prepayment Line", "Completely Shipped", Planned);
    end;

    /// <summary>
    /// Determines if the reserved quantity on sales line meets the reserved from stock setting based on the quantity to post.
    /// </summary>
    /// <param name="QtyToPost">The quantity to post.</param>
    /// <param name="ReservedFromStock">The reserved from stock setting.</param>
    /// <returns>True if the reserved quantity meets the reserved from stock setting, otherwise false.</returns>
    procedure CheckIfSalesLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if not Rec.IsInventoriableItem() then
            exit(false);

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        QtyReservedFromStock := SalesLineReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfSalesLineMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    local procedure GetFADeprBook(FANo: Code[20]) DepreciationBookCode: Code[10]
    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        DefaultFADeprBook: Record "FA Depreciation Book";
        SetFADeprBook: Record "FA Depreciation Book";
    begin
        FASetup.Get();

        DefaultFADeprBook.SetRange("FA No.", FANo);
        DefaultFADeprBook.SetRange("Default FA Depreciation Book", true);

        SetFADeprBook.SetRange("FA No.", FANo);

        case true of
            SetFADeprBook.Count = 1:
                begin
                    SetFADeprBook.FindFirst();
                    DepreciationBookCode := SetFADeprBook."Depreciation Book Code";
                end;
            DefaultFADeprBook.FindFirst():
                DepreciationBookCode := DefaultFADeprBook."Depreciation Book Code";
            FADeprBook.Get("No.", FASetup."Default Depr. Book"):
                DepreciationBookCode := FASetup."Default Depr. Book"
            else
                DepreciationBookCode := '';
        end;
    end;

    procedure CalcUnitPriceUsingUOMCoef()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GetSalesInvoiceLine(SalesInvoiceLine);

        if SalesInvoiceLine."Line No." = 0 then
            exit;

        "Unit Price" := ("Qty. per Unit of Measure" * SalesInvoiceLine."Unit Price") / SalesInvoiceLine."Qty. per Unit of Measure";

        OnAfterCalcUnitPriceUsingUOMCoef(Rec, SalesInvoiceLine);
    end;

    local procedure GetSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        CheckApplFromItemLedgEntry(ItemLedgerEntry);
        ValueEntry.SetLoadFields("Document No.", "Document Line No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntry."Entry Type");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
        if ValueEntry.FindFirst() then
            SalesInvoiceLine.Get(ValueEntry."Document No.", ValueEntry."Document Line No.");
    end;

    local procedure CannotInvoiceErrorInfo(): ErrorInfo
    var
        ErrorMesageManagement: Codeunit "Error Message Management";
    begin
        exit(ErrorMesageManagement.BuildActionableErrorInfo(
            QtyInvoiceNotValidTitleLbl,
            StrSubstNo(Text005, MaxQtyToInvoice()),
            Rec.RecordId,
            StrSubstNo(QtyInvoiceActionLbl, MaxQtyToInvoice()),
            Codeunit::"Sales Line-Reserve",
            'SetSalesQtyInvoice',
            StrSubstNo(QtyInvoiceActionDescriptionLbl, Rec.FieldCaption("Qty. to Invoice"), Rec.Quantity)));
    end;

    local procedure CannotShipErrorInfo(): ErrorInfo
    var
        ErrorMesageManagement: Codeunit "Error Message Management";
    begin
        exit(ErrorMesageManagement.BuildActionableErrorInfo(
            QtyShipNotValidTitleLbl,
            StrSubstNo(Text007, "Outstanding Quantity"),
            Rec.RecordId,
            StrSubstNo(QtyShipActionLbl, "Outstanding Quantity"),
            Codeunit::"Sales Line-Reserve",
            'SetSaleShipQty',
            StrSubstNo(QtyShipActionDescriptionLbl, Rec.FieldCaption("Qty. to Ship"), Rec.Quantity)));
    end;

    local procedure TestQuantityFieldsOnValidateUnitOfMeasure()
    var
        IsHandled: Boolean;
    begin
        OnBeforeTestQuantityFieldsOnValidateUnitOfMeasure(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Quantity Shipped", 0);
        TestField("Qty. Shipped (Base)", 0);
        TestField("Return Qty. Received", 0);
        TestField("Return Qty. Received (Base)", 0);
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
        "VAT %" := VATPostingSetupFrom."VAT %";
        "VAT Calculation Type" := VATPostingSetupFrom."VAT Calculation Type";
        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
            Validate("Allow Invoice Disc.", false);
        "VAT Identifier" := VATPostingSetupFrom."VAT Identifier";
        "VAT Clause Code" := VATPostingSetupFrom."VAT Clause Code";

        OnAfterCopyFromVATPostingSetup(Rec, VATPostingSetupFrom);
    end;

    internal procedure CopyPrepaymentFromVATPostingSetup(var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        "Prepayment VAT %" := VATPostingSetupFrom."VAT %";
        "Prepmt. VAT Calc. Type" := VATPostingSetupFrom."VAT Calculation Type";
        "Prepayment VAT Identifier" := VATPostingSetupFrom."VAT Identifier";
        if "Prepmt. VAT Calc. Type" in ["Prepmt. VAT Calc. Type"::"Reverse Charge VAT", "Prepmt. VAT Calc. Type"::"Sales Tax"] then
            ClearPrepaymentVATPct();

        OnAfterCopyPrepaymentFromVATPostingSetup(Rec, VATPostingSetupFrom);
    end;

    local procedure CheckReceiptOrderStatus()
    begin
        OnCheckReceiptOrderStatus(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var SalesLine: Record "Sales Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFieldsForNo(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPrice(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignHeaderValues(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignStdTxtValues(var SalesLine: Record "Sales Line"; StandardText: Record "Standard Text"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGLAccountValues(var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account"; SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var SalesLine: Record "Sales Line"; Item: Record Item; SalesHeader: Record "Sales Header"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemChargeValues(var SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceValues(var SalesLine: Record "Sales Line"; Resource: Record Resource; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignFixedAssetValues(var SalesLine: Record "Sales Line"; FixedAsset: Record "Fixed Asset"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemUOM(var SalesLine: Record "Sales Line"; Item: Record Item; CurrentFieldNo: Integer; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignResourceUOM(var SalesLine: Record "Sales Line"; Resource: Record Resource; ResourceUOM: Record "Resource Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemAvailable(var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckShipmentRelation(SalesLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckRetRcptRelation(SalesLine: Record "Sales Line"; ReturnReceiptLine: Record "Return Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimFromDefaultDim(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; CurrFieldNo: Integer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var SalesLine: Record "Sales Line"; Item: Record Item; CurrentFieldNo: Integer; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesLine(var SalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromSalesShptLine(var SalesLine: Record "Sales Line"; FromSalesShipmentLine: Record "Sales Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyUnitPriceAndLineDiscountPct(var SalesLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteChargeChargeAssgnt(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteItemChargeAssignment(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; DocType: Enum "Sales Document Type"; DocNo: Code[20];
                                                                                                                                                                 DocLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var SalesLine: Record "Sales Line"; var Item: Record Item; DocumentType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var SalesLine: Record "Sales Line"; ReservationEntry: Record "Reservation Entry"; DocumentType: Enum "Sales Document Type"; AvailabilityFilter: Text;
                                                                                                                                                         Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResUnitCost(var SalesLine: Record "Sales Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFAPostingGroup(var SalesLine: Record "Sales Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVatBaseDiscountPct(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemTranslation(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemTranslation: Record "Item Translation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesHeader(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDefaultBin(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasTypeToFillMandatoryFields(var SalesLine: Record "Sales Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToAsm(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer; xSalesLine: Record "Sales Line"; ShouldUpdateQtyToAsm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesSetup(var SalesLine: Record "Sales Line"; var SalesSetup: Record "Sales & Receivables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAsmToOrderAllowed(SalesLine: Record "Sales Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCreditDocType(SalesLine: Record "Sales Line"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenItemTrackingLines(SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickDiscount(var SalesLine: Record "Sales Line"; var PriceCalculation: Interface "Price Calculation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickPrice(var SalesLine: Record "Sales Line"; var PriceCalculation: Interface "Price Calculation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesHeader(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowNonStock(var SalesLine: Record "Sales Line"; NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowItemChargeAssgnt(var SalesLine: Record "Sales Line"; var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateLineDiscPct(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePrePaymentAmounts(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATPercent(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceByFieldOnBeforeValidateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddItem(var SalesLine: Record "Sales Line"; LastSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddItems(var SalesLine: Record "Sales Line"; SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; xSalesLine: Record "Sales Line"; FullAutoReservation: Boolean; var ReserveSalesLine: Codeunit "Sales Line-Reserve")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var SalesLine: Record "Sales Line"; Qty: Decimal; FromFieldName: Text; ToFieldName: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscToInvoice(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPlannedShptDate(var SalesLine: Record "Sales Line"; var PlannedShipmentDate: Date; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPrepmtToDeduct(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVATAmountLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; QtyType: Option General,Invoicing,Shipping; IncludePrepayments: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallItemTracking(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAssocPurchOrder(var SalesLine: Record "Sales Line"; TheFieldCaption: Text[250]; var IsHandled: Boolean; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAsmToOrder(var SalesLine: Record "Sales Line"; AsmHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtAmounts(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; xSalesLine: Record "Sales Line"; CurrFieldNo: Integer; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplFromItemLedgEntry(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeRelation(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailable(var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLinkedBlanketOrderLineOnDelete(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanSpecialOrderFieldsAndCheckAssocPurchOrder(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCleanPurchaseLineSpecialOrderFields(SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromItem(var SalesLine: Record "Sales Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNoByDescription(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindOrCreateRecordByNo(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatType(SalesLine: Record "Sales Line"; var FormattedType: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCPGInvRoundAcc(SalesHeader: Record "Sales Header"; Customer: Record Customer; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAbsMin(SalesLine: Record "Sales Line"; QtyToHandle: Decimal; QtyHandled: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFAPostingGroup(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemTranslation(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesHeader(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var IsHanded: Boolean; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetUnitCost(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDeferralAmount(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var DeferralAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReservationQty(var SalesLine: Record "Sales Line"; var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitHeaderLocactionCode(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingAmount(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQty(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; IsAsmToOrderAlwd: Boolean; IsAsmToOrderRqd: Boolean; var IsHandled: Boolean; var ShouldInitQty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToAsm(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToReceive(var SalesLine: Record "Sales Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var SalesLine: Record "Sales Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitType(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsAsmToOrderRequired(SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShortcutDimCode(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoice(SalesLine: Record "Sales Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMaxQtyToInvoiceBase(SalesLine: Record "Sales Line"; var MaxQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectMultipleItems(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultGLAccountQuantity(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultItemQuantity(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultQuantity(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetICPartnerRefType(var SalesLine: Record "Sales Line"; NewType: Enum "IC Partner Reference Type"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalesHeader(SalesHeader: record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean; var IsChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSignedXX(var SalesLine: Record "Sales Line"; var Value: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemSub(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservationEntries(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobPlanningLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusOpen(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var StatusCheckSuspended: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQtyFromLindDiscountAmount(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowWrongAmountError(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDates(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var PlannedShipmentDateCalculated: Boolean; var PlannedDeliveryDateCalculated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtAmounts(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesLine: Record "Sales Line"; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrepmtSetupFields(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLineDiscPct(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPriceProcedure(var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmounts(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATAmounts(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATOnLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean; QtyType: Integer; var LineWasModified: Boolean; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var PrepaymentLineAmountEntered: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithWarehouseShip(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuantityFromUOMCode(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToAsmFromSalesLineQtyToShip(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDropShipment(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReasonCode(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePurchasingCode(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitOfMeasureCodeFromNo(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLineAmount(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtAmttoDeduct(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtLineAmount(var SalesLine: Record "Sales Line"; PrePaymentLineAmountEntered: Boolean; var IsHandled: Boolean; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBlanketOrderNo(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateType(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtytoAsmtoOrderBase(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToInvoiceBase(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToShipBase(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnQtyToReceiveBase(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReservedQty(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeZeroAmountLine(var SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing,Shipping; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBlanketOrderIsRelatedOnAfterSetLoadFields(var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeAssignAmtToHandle(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; IncludePrepayments: Boolean; QtyType: Option; var QtyToHandle: Decimal; var AmtToHandle: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeQtyTypeGeneralCase(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; IncludePrepayments: Boolean; QtyType: Option; var QtyToHandle: Decimal; var AmtToHandle: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeAssignQuantities(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: record "VAT Amount Line"; var QtyToHandle: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeQtyTypeCase(var VATAmountLine: Record "VAT Amount Line"; var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitHeaderDefaults(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstanding(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingQty(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitOutstandingAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToInvoice(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip2(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitType(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineAmount(var SalesLine: Record "Sales Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvDiscToInvoice(var SalesLine: Record "Sales Line"; OldInvDiscAmtToInv: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVATAmountLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLineAmountToHandle(SalesLine: Record "Sales Line"; QtyToHandle: Decimal; var LineAmount: Decimal; var LineDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetLineWithPrice(var LineWithPrice: Interface "Line With Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(SalesLine: Record "Sales Line"; var Result: Boolean; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculate(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesTaxCalculateReverse(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReserveWithoutPurchasingCode(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmounts(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAmountsDone(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBaseAmounts(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDates(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemReference(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemReference(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATAmounts(var SalesLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVATOnLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line"; QtyType: Option General,Invoicing,Shipping)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWithWarehouseShip(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer; xSalesLine: Record "Sales Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowItemSub(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateICPartner(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateReturnReasonCode(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterCheckInventoryConflict(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFreightLineOnAfterCheckDocumentNo(var SalesLine: Record "Sales Line"; var SalesLineRec: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShip2OnBeforeCalcInvDiscToInvoice(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToAsmOnAfterCalcShouldUpdateQtyToAsm(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer; xSalesLine: Record "Sales Line"; var ShouldUpdateQtyToAsm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowLineCommentsOnAfterSetFilters(var SalesCommentLine: Record "Sales Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemChargeAssgntOnBeforeCalcItemCharge(var SalesLine: Record "Sales Line"; var ItemChargeAssgntLineAmt: Decimal; Currency: Record Currency; var IsHandled: Boolean; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemChargeAssgntOnAfterCurrencyInitialize(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterVerifyChange(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateLineDiscPctOnAfterCalcIsOutOfStandardDiscPctRange(var SalesLine: Record "Sales Line"; var IsOutOfStandardDiscPctRange: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceByFieldOnAfterFindPrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitPriceOnBeforeFindPrice(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeSetShipmentDate(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterCheckItem(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnCopyFromTempSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterInitHeaderDefaults(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterCalcShouldStopValidation(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var ShouldStopValidation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterVerifyChange(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnCopyFromTempSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitHeaderDefaults(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitRec(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateNoOnBeforeCalcShipmentDateForLocation(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeUpdateDates(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CallingFieldNo: Integer; var IsHandled: Boolean; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckQuantityChangeForPriceCalc(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetUnitCost(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeResetAmounts(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipAfterInitQty(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipOnAfterCheck(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReturnAfterInitQty(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReturnQtyToReceiveOnAfterCheck(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipmentDateOnAfterSalesLineVerifyChange(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var DoCheckReceiptOrderStatus: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterChecks(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeCheckVATCalcType(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateUnitPrice(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestStatusOpen(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelectMultipleItems(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultQuantity(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTotalAmounts(var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnAfterSetLocation2(var SalesLine: Record "Sales Line"; var Location2: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarehouseOnBeforeShowDialog(var SalesLine: Record "Sales Line"; Location: Record Location; var ShowDialog: Option " ",Message,Error; var DialogText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcShipmentDateOnPlannedShipmentDate(SalesLine: Record "Sales Line"; var ShipmentDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterCheck(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromItemOnAfterCheckInvtPostingSetupInventoryAccount(var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceOnBeforeTestBlocked(var Resoiurce: Record Resource; var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromResourceOnBeforeApplyResUnitCost(var SalesLine: Record "Sales Line"; Resource: Record Resource; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateGlobalDimFromDimSetID(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDeferralPostDate(SalesHeader: Record "Sales Header"; var DeferralPostingDate: Date; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoAsmToOrder(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoAsmToOrder(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer; var ATOLink: Record "Assemble-to-Order Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBlanketOrderLookup(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderLookup(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPlannedDeliveryDate(var SalesLine: Record "Sales Line"; var PlannedDeliveryDate: Date; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGetFAPostingGroupOnBeforeExit(var SalesLine: Record "Sales Line"; var ShouldExit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditLimitCondition(SalesLine: Record "Sales Line"; var RunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemChargeAssgnt(var SalesLine: Record "Sales Line"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitPriceFromNonstockItem(var SalesLine: Record "Sales Line"; NonstockItem: Record "Nonstock Item"; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDescription(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var InHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePlannedDeliveryDate(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidatePlannedShipmentDate(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyItemLineDim(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateAmountsOnAfterCalcLineAmount(var SalesLine: Record "Sales Line"; var LineAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmountOnBeforeCheckCreditLimit(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateAmountsOnBeforeCheckLineAmount(var IsHandled: Boolean; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateNewAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATAmountLine: Record "VAT Amount Line"; VATAmountLineReminder: Record "VAT Amount Line"; var NewAmount: Decimal; var VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateAmounts(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCalculateNewAmount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATAmountLine: Record "VAT Amount Line"; VATAmountLineReminder: Record "VAT Amount Line"; var NewAmountIncludingVAT: Decimal; VATAmount: Decimal; var NewAmount: Decimal; var NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterSalesLineSetFilter(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeCalculateAmounts(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnBeforeTempVATAmountLineRemainderModify(SalesLine: Record "Sales Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line"; VATAmount: Decimal; NewVATBaseAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterCurrencyInitialize(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDescriptionOnBeforeCannotFindDescrError(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnAfterSetOutboundWhseHandlingTime(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcLineTotals(var VATAmountLine: Record "VAT Amount Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Currency: Record Currency; QtyType: Option General,Invoicing,Shipping; var TotalVATAmount: Decimal; QtyToHandle: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCalcShouldProcessRounding(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeVATAmountLineUpdateLines(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var VATAmountLine: Record "VAT Amount Line"; var TotalVATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterCurrencyInitialize(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeTestStatusOpen(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindResUnitCostOnAfterInitResCost(var SalesLine: Record "Sales Line"; var ResourceCost: Record "Resource Cost")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnLookUpICPartnerReferenceTypeCaseElse()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnAfterSetFilters(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeValidateLineDiscountPercent(var SalesLine: Record "Sales Line"; var StatusCheckSuspended: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeCalcAmounts(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; var TotalAmount: Decimal; TotalAmountInclVAT: Decimal; var TotalLineAmount: Decimal; var TotalInvDiscAmount: Decimal; var TotalVATBaseAmount: Decimal; var TotalQuantityBase: Decimal; var IsHandled: Boolean; TotalVATDifference: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSelectItemEntryOnAfterSetFilters(var ItemLedgEntry: Record "Item Ledger Entry"; SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterAssignAmounts(var SalesLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineAmountOnbeforeTestUnitPrice(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepaymentPercentageOnBeforeUpdatePrepmtSetupFields(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckAssocPurchOrder(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCheckReceiptOrderStatus(var SalesLine: Record "Sales Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeSalesLineVerifyChange(var SalesLine: Record "Sales Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeValidateQtyToAssembleToOrder(var SalesLine: Record "Sales Line"; StatusCheckSuspended: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterAssignPurchasingFields(var SalesLine: Record "Sales Line"; PurchasingCode: Record Purchasing; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterSetReserveWithoutPurchasingCode(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterResetPurchasingFields(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeUpdateAmounts(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeferrals(SalesLine: Record "Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouse(SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ShowDialogMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarehouseForQtyToShip(SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateDim(var IsHandled: Boolean; var SalesLine: Record "Sales Line"; FieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowUnitPriceChangedMsg(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateUnitCostLCYOnGetUnitCost(var IsHandled: Boolean; var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateWorkTypeCode(var xSalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateJobContractEntryNo(xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateShipmentDate(var IsHandled: Boolean; var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateVATProdPostingGroup(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateVATProdPostingGroupTrigger(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAssignResourceUoM(var ResUnitofMeasure: Record "Resource Unit of Measure"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPromisedDeliveryDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtAmtInvEmpty(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeValidateBlanketOrderLineNo(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckShipmentRelation(var IsHandled: Boolean; var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckShipmentDateBeforeWorkDate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var HasBeenShown: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRetRcptRelation(var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitQtyToShipOnBeforeCheckServItemCreation(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyChangeForSalesLineReserve(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInventoryPickConflict(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckApplFromItemLedgEntryOnBeforeTestFieldType(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantitySign(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantitySignOnApplicationFrom(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedQtyBase(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNotInvoicedQty(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReturnedUnitsError(var SalesLine: Record "Sales Line"; var ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestDirectPosting(var SalesLine: Record "Sales Line"; var GLAccount: Record "G/L Account"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateLineDiscountPercent(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnBeforeUpdateAmounts(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnAfterTestStatusOpen(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowNonStock(var SalesLine: Record "Sales Line"; var NonstockItem: Record "Nonstock Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowNonstockOnBeforeOpenCatalogItemList(var SalesLine: Record "Sales Line"; var NonstockItem: Record "Nonstock Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnAfterCheckAssocPurchOrder(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnBeforeInitRec(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationEntry(var ReservEntry: Record "Reservation Entry"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDropShipmentOnBeforeTestJobNo(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetReservationQty(var SalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCostLCY(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateICPartner(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ShouldUpdateICPartner: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateBlanketOrderLineNo(var SalesLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateLocationCode(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var Location: Record "Location"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailableOnBeforeSalesLineCheck(var SalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrentFieldNo: Integer; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRequestedDeliveryDate(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePromisedDeliveryDate(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnAfterCalculateNormalVAT(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountIncludingVATOnAfterCalculateNormalVAT(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitHeaderDefaultsOnBeforeTestSellToCustomerNo(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePrePaymentAmountsOnBeforeTestFieldPriceIncludingVAT(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeInitOutstanding(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountOnAfterSetZeroAmointIfLineIsInvDiscountAmount(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATProdPostingGroupOnBeforeVATPostingSetupGet(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean; var VATPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeCreateDimFromDefaultDim(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnGenProdPostingGroupOnBeforeValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var GenProdPostingGroup: Record "Gen. Product Posting Group"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnValidateAmountOnAfterAssignAmount(var SalesLine: Record "Sales Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLineAmount(var SalesLine: Record "Sales Line"; MaxLineAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToAssembleToOrderOnBeforeAutoAsmToOrder(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeGetUnitOfMeasure(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterGetItemData(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSalesLine2DeleteAll(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterInitQty(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterGetUnitOfMeasure(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterEnterSalesItemReference(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterCalcShouldPlanPriceCalc(var SalesLine: Record "Sales Line"; var ShouldPlanPriceCalc: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToAssembleToOrderOnOtherDocTypeBeforeTestField(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToShipOnAfterCheckQuantity(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToInvoiceOnBeforeCalcInvDiscToInvoice(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcShouldCalcWithReturnQtyReceived(var SalesLine: Record "Sales Line"; var ShouldCalcWithReturnQtyReceived: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcShouldVerifyQtyForItem(var SalesLine: Record "Sales Line"; var ShouldVerifyQtyForItem: Boolean; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePurchasingCodeOnAfterCalcShouldAssignValuesFromPurchasingCode(var SalesLine: Record "Sales Line"; var ShouldAssignValuesFromPurchasingCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeCalcWithQuantityShipped(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnBeforeIfLineIsInvDiscountAmount(var SalesLine: Record "Sales Line"; var LineIsInvDiscountAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultBinOnAfterWMSGetDefaultBin(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDeferralCode(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDate(var ResultDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePrePaymentAmounts(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnAfterCreateDimFromDefaultDim(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsInbound(SalesLine: Record "Sales Line"; var IsInboundDocument: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBlanketOrderIsRelated(var CurrentSalesLine: Record "Sales Line"; var BlanketOrderSalesLine: Record "Sales Line"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfSalesLineMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetATOBin(SalesLine: record "Sales Line"; Location: Record Location; var BinCode: Code[20]; var BinCodeNotEmpty: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimFromDefaultDimOnBeforeCreateDim(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var ShouldCreateDim: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAttachToInventoryItemLine(var SelectedSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePricesIncludingVATAmountsOnAfterCalculateNormalVAT(var SalesLine: Record "Sales Line"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATAmountsOnAfterCalculateNormalVAT(var SalesLine: Record "Sales Line"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOutstandingInvoiceAmountFromShipmentOnAfterSetFilter(var SalesLineCopy: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHideValidationDialog(var SalesLine: Record "Sales Line"; NewHideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLineAmountToHandle(var QtyToHandle: Decimal; var SalesLine: Record "Sales Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNoOnBeforeCheckPostingSetups(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReduceInvoiceDiscValueOnHeader(var SalesHeader: Record "Sales Header"; InvDiscountAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteChargeChargeAssgnt(SalesDocumentType: Enum "Sales Document Type"; DocNo: Code[20];
                                                                            DocLineNo: Integer; var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeBeforeCheckBlocked(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterInitializeAmounts(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnBeforeTestFields(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplToItemEntryValidateOnBeforeMessage(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessSalesLine(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePlanned(var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteItemChargeAssignment(DocType: Enum "Sales Document Type"; DocNo: Code[20];
                                                                    DocLineNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemChargeAssgntOnBeforeCreateDocChargeAssgn(SalesLine: Record "Sales Line"; var DoCreateDocChargeAssgnForReturnReceiptNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeferralAmounts(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnAfterEditDimensionSet(var SalesLine: Record "Sales Line"; OldDimensionSet: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoUpdateICPartner(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentServiceCode(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeTestReservedQtyBase(SalesLine: Record "Sales Line"; var IsHanlded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitPrice(var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLocationOnWMSOnBeforeCaseDocumentType(var SalesLine: Record "Sales Line"; DialogText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServItemCreation(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShippingTime(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeProcessSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnAfterInsertNewVATAmountLine(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVATOnLinesOnAfterUpdateBaseAmounts(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumVATAmountLineOnBeforeModify(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVATAmountOnBeforeInsert(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindVATAmountLineOnAfterSetFilters(var SalesLine: Record "Sales Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcShipmentDateForLocation(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQuantityFieldsOnValidateUnitOfMeasure(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATPct(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearPrepaymentVATPct(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearVATDifference(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVATPct(var SalesLine: Record "Sales Line"; var VATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentVATPct(var SalesLine: Record "Sales Line"; var PrepaymentVATPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVATPostingSetup(var SalesLine: Record "Sales Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPrepaymentFromVATPostingSetup(var SalesLine: Record "Sales Line"; var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLineDiscountPercentOnBeforeValidateLineDiscountPercent(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var DropInvoiceDiscountAmount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitPriceUsingUOMCoef(var SalesLine: Record "Sales Line"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitDeferralCodeOnBeforeUpdateDeferralCode(var SalesLine: Record "Sales Line"; var ShouldUpdateDeferralCode: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateLineDiscountPercentOnBeforeTestJobPlanningLine(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOnAfterUpdateDeferralAmounts(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyOnAfterVerifyChangeForSalesLineReserve(var SalesLine: Record "Sales Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVATAmountLinesOnBeforeGetDeferralAmount(var SalesLine: Record "Sales Line")
    begin
    end;
}
