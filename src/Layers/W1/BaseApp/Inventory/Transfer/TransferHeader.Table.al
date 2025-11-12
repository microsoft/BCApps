// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Warehouse.Request;
using System.Security.User;
using System.Text;
using System.Utilities;

table 5740 "Transfer Header"
{
    Caption = 'Transfer Header';
    DataCaptionFields = "No.";
    LookupPageID = "Transfer Orders";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetInventorySetup();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateTransferFromCode(Rec, xRec, IsHandled, HideValidationDialog);
                if IsHandled then
                    exit;

                if "Transfer-from Code" <> '' then
                    CheckTransferFromAndToCodesNotTheSame();

                if "Direct Transfer" then
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");

                if xRec."Transfer-from Code" <> "Transfer-from Code" then begin
                    if HideValidationDialog or
                       (xRec."Transfer-from Code" = '')
                    then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-from Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-from Code") then begin
                            InitFromTransferFromLocation(Location);
                            if not "Direct Transfer" then begin
                                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                CalcReceiptDate();
                            end;
                            TransLine.LockTable();
                            TransLine.SetRange("Document No.", "No.");
                        end;
                        OnValidateTransferFromCodeOnBeforeUpdateTransLines(Rec);
                        UpdateTransLines(Rec, FieldNo("Transfer-from Code"));
                    end else
                        "Transfer-from Code" := xRec."Transfer-from Code";
                end;

                CreateDimFromDefaultDim(FieldNo("Transfer-from Code"));
            end;
        }
        field(3; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
        }
        field(4; "Transfer-from Name 2"; Text[50])
        {
            Caption = 'Transfer-from Name 2';
        }
        field(5; "Transfer-from Address"; Text[100])
        {
            Caption = 'Transfer-from Address';
        }
        field(6; "Transfer-from Address 2"; Text[50])
        {
            Caption = 'Transfer-from Address 2';
        }
        field(7; "Transfer-from Post Code"; Code[20])
        {
            Caption = 'Transfer-from Post Code';
            TableRelation = if ("Trsf.-from Country/Region Code" = const('')) "Post Code"
            else
            if ("Trsf.-from Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Trsf.-from Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferFromPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Transfer-from City", "Transfer-from Post Code",
                        "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Transfer-from City"; Text[30])
        {
            Caption = 'Transfer-from City';
            TableRelation = if ("Trsf.-from Country/Region Code" = const('')) "Post Code".City
            else
            if ("Trsf.-from Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Trsf.-from Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County", "Trsf.-from Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferFromCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Transfer-from City", "Transfer-from Post Code",
                        "Transfer-from County", "Trsf.-from Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Transfer-from County"; Text[30])
        {
            CaptionClass = '5,7,' + "Trsf.-from Country/Region Code";
            Caption = 'Transfer-from County';
        }
        field(10; "Trsf.-from Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-from Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-from City", "Transfer-from Post Code", "Transfer-from County",
                  "Trsf.-from Country/Region Code", xRec."Trsf.-from Country/Region Code");
            end;
        }
        field(11; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                Location: Record Location;
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnBeforeValidateTransferToCode(Rec, xRec, IsHandled, HideValidationDialog);
                if IsHandled then
                    exit;

                if "Transfer-to Code" <> '' then
                    CheckTransferFromAndToCodesNotTheSame();

                if "Direct Transfer" then
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");

                if xRec."Transfer-to Code" <> "Transfer-to Code" then begin
                    if HideValidationDialog or (xRec."Transfer-to Code" = '') then
                        Confirmed := true
                    else
                        Confirmed := Confirm(Text002, false, FieldCaption("Transfer-to Code"));
                    if Confirmed then begin
                        if Location.Get("Transfer-to Code") then begin
                            InitFromTransferToLocation(Location);
                            if not "Direct Transfer" then begin
                                "Inbound Whse. Handling Time" := Location."Inbound Whse. Handling Time";
                                TransferRoute.GetTransferRoute(
                                  "Transfer-from Code", "Transfer-to Code", "In-Transit Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code");
                                OnAfterGetTransferRoute(Rec, TransferRoute);
                                TransferRoute.GetShippingTime(
                                  "Transfer-from Code", "Transfer-to Code",
                                  "Shipping Agent Code", "Shipping Agent Service Code",
                                  "Shipping Time");
                                CalcReceiptDate();
                            end;
                            TransLine.LockTable();
                            TransLine.SetRange("Document No.", "No.");
                        end;
                        UpdateTransLines(Rec, FieldNo("Transfer-to Code"));
                    end else
                        "Transfer-to Code" := xRec."Transfer-to Code";
                end;

                CreateDimFromDefaultDim(FieldNo("Transfer-to Code"));
            end;
        }
        field(12; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
        }
        field(13; "Transfer-to Name 2"; Text[50])
        {
            Caption = 'Transfer-to Name 2';
        }
        field(14; "Transfer-to Address"; Text[100])
        {
            Caption = 'Transfer-to Address';
        }
        field(15; "Transfer-to Address 2"; Text[50])
        {
            Caption = 'Transfer-to Address 2';
        }
        field(16; "Transfer-to Post Code"; Code[20])
        {
            Caption = 'Transfer-to Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferToPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                        "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(17; "Transfer-to City"; Text[30])
        {
            Caption = 'Transfer-to City';
            TableRelation = if ("Trsf.-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Trsf.-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Trsf.-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County", "Trsf.-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTransferToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                        "Trsf.-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Transfer-to County"; Text[30])
        {
            CaptionClass = '5,8,' + "Trsf.-to Country/Region Code";
            Caption = 'Transfer-to County';
        }
        field(19; "Trsf.-to Country/Region Code"; Code[10])
        {
            Caption = 'Trsf.-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(
                  "Transfer-to City", "Transfer-to Post Code", "Transfer-to County",
                  "Trsf.-to Country/Region Code", xRec."Trsf.-to Country/Region Code");
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnValidateShipmentDateOnBeforeCalcReceiptDate(IsHandled, Rec);
                if not IsHandled then
                    CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipment Date"));
            end;
        }
        field(22; "Receipt Date"; Date)
        {
            Caption = 'Receipt Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                IsHandled := false;
                OnValidateReceiptDateOnBeforeCalcShipmentDate(IsHandled, Rec);
                if not IsHandled then
                    CalcShipmentDate();

                UpdateTransLines(Rec, FieldNo("Receipt Date"));
            end;
        }
        field(23; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;

            trigger OnValidate()
            begin
                UpdateTransLines(Rec, FieldNo(Status));
            end;
        }
        field(24; Comment; Boolean)
        {
            CalcFormula = exist("Inventory Comment Line" where("Document Type" = const("Transfer Order"),
                                                                "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Shortcut Dimension 1 Code"; Code[20])
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
        field(26; "Shortcut Dimension 2 Code"; Code[20])
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
        field(27; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location where("Use As In-Transit" = const(true));

            trigger OnValidate()
            begin
                TestStatusOpen();
                UpdateTransLines(Rec, FieldNo("In-Transit Code"));
            end;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(29; "Last Shipment No."; Code[20])
        {
            Caption = 'Last Shipment No.';
            Editable = false;
            TableRelation = "Transfer Shipment Header";
        }
        field(30; "Last Receipt No."; Code[20])
        {
            Caption = 'Last Receipt No.';
            Editable = false;
            TableRelation = "Transfer Receipt Header";
        }
        field(31; "Transfer-from Contact"; Text[100])
        {
            Caption = 'Transfer-from Contact';
        }
        field(32; "Transfer-to Contact"; Text[100])
        {
            Caption = 'Transfer-to Contact';
        }
        field(33; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
                WhseTransferRelease: Codeunit "Whse.-Transfer Release";
            begin
                if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) then
                    WhseTransferRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(34; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
                UpdateTransLines(Rec, FieldNo("Shipping Agent Code"));
            end;
        }
        field(35; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            begin
                TestStatusOpen();
                TransferRoute.GetShippingTime(
                  "Transfer-from Code", "Transfer-to Code",
                  "Shipping Agent Code", "Shipping Agent Service Code",
                  "Shipping Time");
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipping Agent Service Code"));
            end;
        }
        field(36; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Shipping Time"));
            end;
        }
        field(37; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";
        }
        field(48; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";
        }
        field(49; "Partner VAT ID"; Code[20])
        {
            Caption = 'Partner VAT ID';
        }
        field(59; "Entry/Exit Point"; Code[10])
        {
            Caption = 'Entry/Exit Point';
            TableRelation = "Entry/Exit Point";
        }
        field(63; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(64; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";
        }
        field(70; "Direct Transfer"; Boolean)
        {
            Caption = 'Direct Transfer';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Direct Transfer" then begin
                    VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
                    VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
                    OnValidateDirectTransferOnBeforeValidateInTransitCode(Rec, IsHandled);
                    if not IsHandled then
                        Validate("In-Transit Code", '');
                end;

                Modify(true);
                UpdateTransLines(Rec, FieldNo("Direct Transfer"));
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';

            trigger OnValidate()
            var
                TransferWarehouseMgt: Codeunit "Transfer Warehouse Mgt.";
            begin
                if "Shipping Advice" <> xRec."Shipping Advice" then begin
                    TestStatusOpen();
                    TransferWarehouseMgt.TransHeaderVerifyChange(Rec, xRec);
                end;
            end;
        }
        field(5751; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("Transfer Line"."Completely Shipped" where("Document No." = field("No."),
                                                                          "Shipment Date" = field("Date Filter"),
                                                                          "Transfer-from Code" = field("Location Filter"),
                                                                          "Derived From Line No." = const(0)));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Completely Received"; Boolean)
        {
            CalcFormula = min("Transfer Line"."Completely Received" where("Document No." = field("No."),
                                                                           "Receipt Date" = field("Date Filter"),
                                                                           "Transfer-to Code" = field("Location Filter"),
                                                                           "Derived From Line No." = const(0)));
            Caption = 'Completely Received';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Outbound Whse. Handling Time"));
            end;
        }
        field(5794; "Inbound Whse. Handling Time"; DateFormula)
        {
            Caption = 'Inbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                CalcReceiptDate();

                UpdateTransLines(Rec, FieldNo("Inbound Whse. Handling Time"));
            end;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(8000; "Has Shipped Lines"; Boolean)
        {
            CalcFormula = exist("Transfer Line" where("Document No." = field("No."),
                                                       "Quantity Shipped" = filter(> 0)));
            Caption = 'Has Shipped Lines';
            FieldClass = FlowField;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transfer-from Code", "Transfer-to Code", "Shipment Date", Status)
        {
        }
    }

    trigger OnDelete()
    var
        InvtCommentLine: Record "Inventory Comment Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        TestField(Status, Status::Open);

        WhseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);

        ReservMgt.DeleteDocumentReservation(DATABASE::"Transfer Line", 0, "No.", HideValidationDialog);

        DeleteTransferLines();

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        GetInventorySetup();
        InitInsert();
        Validate("Shipment Date", WorkDate());
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        TransferRoute: Record "Transfer Route";
        TransHeader: Record "Transfer Header";
        TransLine: Record "Transfer Line";
        PostCode: Record "Post Code";
        InvtSetup: Record "Inventory Setup";
        WhseRequest: Record "Warehouse Request";
        DimMgt: Codeunit DimensionManagement;
        ErrorMessageMgt: Codeunit "Error Message Management";
        HasInventorySetup: Boolean;
        CalledFromWhse: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '%1 and %2 cannot be the same in %3 %4.';
        Text002: Label 'Do you want to change %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SameLocationErr: Label 'Transfer order %1 cannot be posted because %2 and %3 are the same.', Comment = '%1 - order number, %2 - location from, %3 - location to';
#pragma warning disable AA0074
        TransferOrderPostedMsg1: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = transfer order number e.g. Transfer order 1003 was successfully posted and is now deleted ';
        Text007: Label 'You may have changed a dimension.\\Do you want to update the lines?';
#pragma warning restore AA0074
        CheckTransferLineMsg: Label 'Check transfer document line.';

    protected var
        HideValidationDialog: Boolean;

    procedure InitRecord()
    begin
        if "Posting Date" = 0D then
            Validate("Posting Date", WorkDate());

        OnAfterInitRecord(Rec);
    end;

    local procedure InitFromTransferToLocation(Location: Record Location)
    begin
        "Transfer-to Name" := Location.Name;
        "Transfer-to Name 2" := Location."Name 2";
        "Transfer-to Address" := Location.Address;
        "Transfer-to Address 2" := Location."Address 2";
        "Transfer-to Post Code" := Location."Post Code";
        "Transfer-to City" := Location.City;
        "Transfer-to County" := Location.County;
        "Trsf.-to Country/Region Code" := Location."Country/Region Code";
        "Transfer-to Contact" := Location.Contact;

        OnAfterInitFromTransferToLocation(Rec, Location);
    end;

    local procedure InitFromTransferFromLocation(Location: Record Location)
    begin
        "Transfer-from Name" := Location.Name;
        "Transfer-from Name 2" := Location."Name 2";
        "Transfer-from Address" := Location.Address;
        "Transfer-from Address 2" := Location."Address 2";
        "Transfer-from Post Code" := Location."Post Code";
        "Transfer-from City" := Location.City;
        "Transfer-from County" := Location.County;
        "Trsf.-from Country/Region Code" := Location."Country/Region Code";
        "Transfer-from Contact" := Location.Contact;

        OnAfterInitFromTransferFromLocation(Rec, Location);
    end;

    procedure AssistEdit(OldTransHeader: Record "Transfer Header"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        TransHeader := Rec;
        GetInventorySetup();
        TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(GetNoSeriesCode(), OldTransHeader."No. Series", TransHeader."No. Series") then begin
            TransHeader."No." := NoSeries.GetNextNo(TransHeader."No. Series");
            Rec := TransHeader;
            exit(true);
        end;
    end;

    local procedure CalcReceiptDate()
    begin
        TransferRoute.CalcReceiptDate(
            "Shipment Date",
            "Receipt Date",
            "Shipping Time",
            "Outbound Whse. Handling Time",
            "Inbound Whse. Handling Time",
            "Transfer-from Code",
            "Transfer-to Code",
            "Shipping Agent Code",
            "Shipping Agent Service Code");
    end;

    local procedure CalcShipmentDate()
    begin
        TransferRoute.CalcShipmentDate(
            "Shipment Date",
            "Receipt Date",
            "Shipping Time",
            "Outbound Whse. Handling Time",
            "Inbound Whse. Handling Time",
            "Transfer-from Code",
            "Transfer-to Code",
            "Shipping Agent Code",
            "Shipping Agent Service Code");
    end;

    local procedure DeleteTransferLines()
    var
        TransLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteTransferLines(IsHandled, Rec);
        if IsHandled then
            exit;

        TransLine.SetRange("Document No.", "No.");
        TransLine.DeleteAll(true);
    end;

    local procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetInventorySetup();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, InvtSetup, IsHandled);
        if IsHandled then
            exit;

        InvtSetup.TestField("Transfer Order Nos.");
    end;

    local procedure GetNoSeriesCode(): Code[20]
    var
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetInventorySetup();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, InvtSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        NoSeriesCode := InvtSetup."Transfer Order Nos.";
        OnAfterGetNoSeriesCode(Rec, NoSeriesCode);
        exit(NoSeriesCode);
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TransferLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure GetInventorySetup()
    begin
        if not HasInventorySetup then begin
            InvtSetup.Get();
            HasInventorySetup := true;
        end;
    end;

    procedure UpdateTransLines(TransferHeader: Record "Transfer Header"; FieldID: Integer)
    var
        TransferLine: Record "Transfer Line";
        TempTransferLine: Record "Transfer Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTransLines(TransferHeader, FieldID, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        if TransferLine.FindSet() then begin
            TransferLine.LockTable();
            repeat
                case FieldID of
                    FieldNo("In-Transit Code"):
                        TransferLine.Validate("In-Transit Code", TransferHeader."In-Transit Code");
                    FieldNo("Transfer-from Code"):
                        begin
                            TransferLine.Validate("Transfer-from Code", TransferHeader."Transfer-from Code");
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                        end;
                    FieldNo("Transfer-to Code"):
                        begin
                            TransferLine.Validate("Transfer-to Code", TransferHeader."Transfer-to Code");
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                        end;
                    FieldNo("Shipping Agent Code"):
                        begin
                            TransferLine.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            OnUpdateTransLinesOnShippingAgentCodeOnBeforeBlockDynamicTracking(TransferLine, TransferHeader);
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck();
                        end;
                    FieldNo("Shipping Agent Service Code"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Agent Service Code", TransferHeader."Shipping Agent Service Code");
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck();
                        end;
                    FieldNo("Shipment Date"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipment Date", TransferHeader."Shipment Date");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck();
                        end;
                    FieldNo("Receipt Date"), FieldNo("Shipping Time"):
                        begin
                            TransferLine.BlockDynamicTracking(true);
                            TransferLine.Validate("Shipping Time", TransferHeader."Shipping Time");
                            TransferLine.Validate("Receipt Date", TransferHeader."Receipt Date");
                            TransferLine.BlockDynamicTracking(false);
                            TransferLine.DateConflictCheck();
                        end;
                    FieldNo("Outbound Whse. Handling Time"):
                        TransferLine.Validate("Outbound Whse. Handling Time", TransferHeader."Outbound Whse. Handling Time");
                    FieldNo("Inbound Whse. Handling Time"):
                        TransferLine.Validate("Inbound Whse. Handling Time", TransferHeader."Inbound Whse. Handling Time");
                    FieldNo(Status):
                        TransferLine.Validate(Status, TransferHeader.Status);
                    FieldNo("Direct Transfer"):
                        begin
                            TransferLine.Validate("In-Transit Code", TransferHeader."In-Transit Code");
                            TempTransferLine := TransferLine;
                            TransferLine.Validate("Item No.", TempTransferLine."Item No.");
                            TransferLine.Validate("Variant Code", TempTransferLine."Variant Code");
                            TransferLine.Validate("Dimension Set ID", TempTransferLine."Dimension Set ID");
                        end;
                    else
                        OnUpdateTransLines(TransferLine, TransferHeader, FieldID);
                end;
                OnUpdateTransLinesOnBeforeModifyTransferLine(TransferHeader, TransferLine);
                TransferLine.Modify(true);
                OnUpdateTransLinesOnAfterModifyTransferLine(TransferHeader, TransferLine);
            until TransferLine.Next() = 0;
        end;
    end;

    procedure ShouldDeleteOneTransferOrder(var TransLine2: Record "Transfer Line"): Boolean
    var
        IsHandled: Boolean;
        ShouldDelete: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldDeleteOneTransferOrder(TransLine2, ShouldDelete, IsHandled);
        if IsHandled then
            exit(ShouldDelete);

        if TransLine2.Find('-') then
            repeat
                if (TransLine2.Quantity <> TransLine2."Quantity Shipped") or
                   (TransLine2.Quantity <> TransLine2."Quantity Received") or
                   (TransLine2."Quantity (Base)" <> TransLine2."Qty. Shipped (Base)") or
                   (TransLine2."Quantity (Base)" <> TransLine2."Qty. Received (Base)") or
                   (TransLine2."Quantity Shipped" <> TransLine2."Quantity Received") or
                   (TransLine2."Qty. Shipped (Base)" <> TransLine2."Qty. Received (Base)")
                then
                    exit(false);
            until TransLine2.Next() = 0;

        exit(true);
    end;

    procedure DeleteOneTransferOrder(var TransHeader2: Record "Transfer Header"; var TransLine2: Record "Transfer Line")
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        WhseRequest: Record "Warehouse Request";
        InvtCommentLine: Record "Inventory Comment Line";
        No: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteOneTransferOrder(TransHeader2, TransLine2, IsHandled);
        if IsHandled then
            exit;

        No := TransHeader2."No.";

        WhseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRequest.SetRange("Source No.", No);
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);

        InvtCommentLine.SetRange("Document Type", InvtCommentLine."Document Type"::"Transfer Order");
        InvtCommentLine.SetRange("No.", No);
        InvtCommentLine.DeleteAll();

        ItemChargeAssgntPurch.SetCurrentKey(
          "Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. Type", ItemChargeAssgntPurch."Applies-to Doc. Type"::"Transfer Receipt");
        ItemChargeAssgntPurch.SetRange("Applies-to Doc. No.", TransLine2."Document No.");
        ItemChargeAssgntPurch.DeleteAll();

        OnBeforeTransLineDeleteAll(TransHeader2, TransLine2);

        if TransLine2.Find('-') then
            TransLine2.DeleteAll();

        OnDeleteOneTransferOrderOnBeforeTransHeaderDelete(TransHeader2, HideValidationDialog);
        TransHeader2.Delete();
        if not HideValidationDialog then
            Message(TransferOrderPostedMsg1, No);
    end;

    procedure TestStatusOpen()
    begin
        if not CalledFromWhse then
            TestField(Status, Status::Open);
    end;

    internal procedure PerformManualRelease()
    var
        IsHandled: Boolean;
    begin
        OnBeforePerformManualRelease(Rec, IsHandled);
        if not IsHandled then
            if Rec.Status <> Rec.Status::Released then begin
                CODEUNIT.Run(CODEUNIT::"Release Transfer Document", Rec);
                Commit();
            end;
    end;

    procedure CalledFromWarehouse(CalledFromWhse2: Boolean)
    begin
        CalledFromWhse := CalledFromWhse2;
    end;

    procedure CreateInvtPutAwayPick()
    var
        WhseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetFilter(
          "Source Document", '%1|%2',
          WhseRequest."Source Document"::"Inbound Transfer",
          WhseRequest."Source Document"::"Outbound Transfer");
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCreateDimFromDefaultDimOnBeforeCreateDim(Rec, FieldNo, IsHandled);
        if IsHandled then
            exit;

        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Transfer-from Code", FieldNo = Rec.FieldNo("Transfer-from Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Transfer-to Code", FieldNo = Rec.FieldNo("Transfer-to Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Transfer, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) then
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource);

        if (OldDimSetID <> "Dimension Set ID") and TransferLinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDocDimOnAfterAssignDimensionSetID(Rec);

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if TransferLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure TransferLinesExist(): Boolean
    begin
        TransLine.Reset();
        TransLine.SetRange("Document No.", "No.");
        exit(TransLine.FindFirst());
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        ShippedLineDimChangeConfirmed: Boolean;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;

        if not HideValidationDialog and GuiAllowed then
            if not ConfirmManagement.GetResponseOrDefault(Text007, true) then
                exit;

        TransLine.Reset();
        TransLine.SetRange("Document No.", "No.");
        TransLine.LockTable();
        if TransLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(TransLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if TransLine."Dimension Set ID" <> NewDimSetID then begin
                    TransLine."Dimension Set ID" := NewDimSetID;

                    VerifyShippedLineDimChange(ShippedLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      TransLine."Dimension Set ID", TransLine."Shortcut Dimension 1 Code", TransLine."Shortcut Dimension 2 Code");
                    OnUpdateAllLineDimOnBeforeTransLineModify(TransLine);
                    TransLine.Modify();
                end;
            until TransLine.Next() = 0;
    end;

    local procedure VerifyShippedLineDimChange(var ShippedLineDimChangeConfirmed: Boolean)
    begin
        if TransLine.IsShippedDimChanged() then
            if not ShippedLineDimChangeConfirmed then
                ShippedLineDimChangeConfirmed := TransLine.ConfirmShippedDimChange();
    end;

    procedure CheckBeforePost()
    begin
        TestField("Transfer-from Code");
        TestField("Transfer-to Code");
        CheckTransferFromAndToCodesNotTheSame();

        if not "Direct Transfer" then
            TestField("In-Transit Code")
        else begin
            VerifyNoOutboundWhseHandlingOnLocation("Transfer-from Code");
            VerifyNoInboundWhseHandlingOnLocation("Transfer-to Code");
        end;
        TestField(Status, Status::Released);
        TestField("Posting Date");

        OnAfterCheckBeforePost(Rec);
    end;

    procedure CheckBeforeTransferPost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBeforeTransferPost(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Transfer-from Code");
        TestField("Transfer-to Code");
        TestField("Direct Transfer");
        if ("Transfer-from Code" <> '') and
           ("Transfer-from Code" = "Transfer-to Code")
        then
            Error(
              SameLocationErr,
              "No.", FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"));
        TestField("In-Transit Code", '');
        TestField(Status, Status::Released);
        TestField("Posting Date");

        OnAfterCheckBeforeTransferPost(Rec);
    end;

    local procedure CheckTransferFromAndToCodesNotTheSame()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferFromAndToCodesNotTheSame(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Transfer-from Code" = "Transfer-to Code" then
            Error(
              Text001,
              FieldCaption("Transfer-from Code"), FieldCaption("Transfer-to Code"),
              TableCaption, "No.");
    end;

    procedure CheckInvtPostingSetup()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvtPostingSetup(Rec, IsHandled);
        if IsHandled then
            exit;

        InventoryPostingSetup.SetRange("Location Code", "Transfer-from Code");
        InventoryPostingSetup.FindFirst();
        InventoryPostingSetup.SetRange("Location Code", "Transfer-to Code");
        InventoryPostingSetup.FindFirst();
    end;

    procedure HasShippedItems(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        TransferLine.SetFilter("Quantity Shipped", '>%1', 0);
        exit(not TransferLine.IsEmpty);
    end;

    procedure HasTransferLines(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        TransferLine.SetFilter("Item No.", '<>%1', '');
        exit(not TransferLine.IsEmpty);
    end;

    procedure GetReceiptLines()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary;
        PostedPurchaseReceipts: Page "Posted Purchase Receipts";
    begin
        FindPurchRcptHeader(PurchRcptHeader);
        PostedPurchaseReceipts.SetTableView(PurchRcptHeader);
        PostedPurchaseReceipts.LookupMode := true;
        if PostedPurchaseReceipts.RunModal() = ACTION::LookupOK then begin
            PostedPurchaseReceipts.GetSelectedRecords(TempPurchRcptHeader);
            CreateTransferLinesFromSelectedPurchReceipts(TempPurchRcptHeader);
        end;
    end;

    local procedure CreateTransferLinesFromSelectedPurchReceipts(var TempPurchRcptHeader: Record "Purch. Rcpt. Header" temporary)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempPurchRcptLine: Record "Purch. Rcpt. Line" temporary;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        PostedPurchaseReceiptLines: Page "Posted Purchase Receipt Lines";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempPurchRcptHeader);
        PurchRcptLine.SetFilter(
          "Document No.",
          SelectionFilterManagement.GetSelectionFilter(RecRef, TempPurchRcptHeader.FieldNo("No.")));
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("Location Code", "Transfer-from Code");
        PostedPurchaseReceiptLines.SetTableView(PurchRcptLine);
        PostedPurchaseReceiptLines.LookupMode := true;
        if PostedPurchaseReceiptLines.RunModal() = ACTION::LookupOK then begin
            PostedPurchaseReceiptLines.GetSelectedRecords(TempPurchRcptLine);
            CreateTransferLinesFromSelectedReceiptLines(TempPurchRcptLine);
        end;
    end;

    local procedure CreateTransferLinesFromSelectedReceiptLines(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        TransferLine.SetRange("Document No.", "No.");
        if TransferLine.FindLast() then;
        LineNo := TransferLine."Line No.";

        if PurchRcptLine.FindSet() then begin
            OnBeforeCreateTransferLinesFromSelectedReceiptLines(PurchRcptLine, LineNo, Rec);
            repeat
                LineNo := LineNo + 10000;
                AddTransferLineFromReceiptLine(PurchRcptLine, LineNo);
            until PurchRcptLine.Next() = 0;
            OnAfterCreateTransferLinesFromSelectedReceiptLines(PurchRcptLine, LineNo, Rec);
        end;
    end;

    local procedure AddTransferLineFromReceiptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        OnBeforeAddTransferLineFromReceiptLine(TransferLine, PurchRcptLine, Rec);

        TransferLine."Document No." := "No.";
        TransferLine."Line No." := LineNo;
        TransferLine.Validate("Item No.", PurchRcptLine."No.");
        TransferLine.Validate("Variant Code", PurchRcptLine."Variant Code");
        TransferLine.Validate(Quantity, PurchRcptLine.Quantity);
        TransferLine.Validate("Unit of Measure Code", PurchRcptLine."Unit of Measure Code");
        TransferLine."Shortcut Dimension 1 Code" := PurchRcptLine."Shortcut Dimension 1 Code";
        TransferLine."Shortcut Dimension 2 Code" := PurchRcptLine."Shortcut Dimension 2 Code";
        TransferLine."Dimension Set ID" := PurchRcptLine."Dimension Set ID";
        OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(TransferLine, PurchRcptLine, Rec);
        TransferLine.Insert(true);

        PurchRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgerEntry);
        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempItemLedgerEntry, ItemLedgerEntry);
        ItemTrackingMgt.CopyItemLedgEntryTrkgToTransferLine(TempItemLedgerEntry, TransferLine);
        TransferLine."Appl.-to Item Entry" := ItemLedgerEntry."Entry No.";
        TransferLine.Modify(true);

        OnAfterAddTransferLineFromReceiptLine(TransferLine, PurchRcptLine, TempItemLedgerEntry, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTransLines(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; FieldID: Integer)
    begin
    end;

    procedure VerifyNoOutboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyNoOutboundWhseHandlingOnLocation(LocationCode, IsHandled);
        if IsHandled then
            exit;

        if not Location.Get(LocationCode) then
            exit;

        GetInventorySetup();
        if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer" then
            exit;

        Location.TestField("Require Pick", false);
        Location.TestField("Require Shipment", false);
    end;

    procedure VerifyNoInboundWhseHandlingOnLocation(LocationCode: Code[10])
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyNoInboundWhseHandlingOnLocation(LocationCode, IsHandled);
        if IsHandled then
            exit;

        if not Location.Get(LocationCode) then
            exit;

        Location.TestField("Directed Put-away and Pick", false);

        GetInventorySetup();
        if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer" then
            exit;

        Location.TestField("Require Put-away", false);
        Location.TestField("Require Receive", false);
    end;

    local procedure InitInsert()
    var
        TransferHeader: Record "Transfer Header";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitInsertOnBeforeInitSeries(xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                if NoSeries.AreRelated(GetNoSeriesCode(), xRec."No. Series") then
                    "No. Series" := xRec."No. Series"
                else
                    "No. Series" := GetNoSeriesCode();
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
                TransferHeader.ReadIsolation(IsolationLevel::ReadUncommitted);
                TransferHeader.SetLoadFields("No.");
                while TransferHeader.Get("No.") do
                    "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
            end;

        OnInitInsertOnBeforeInitRecord(xRec);
        InitRecord();
    end;

    procedure TransferLinesEditable() IsEditable: Boolean;
    begin
        if not "Direct Transfer" then
            IsEditable := ("Transfer-from Code" <> '') and ("Transfer-to Code" <> '') and ("In-Transit Code" <> '')
        else
            IsEditable := ("Transfer-from Code" <> '') and ("Transfer-to Code" <> '');

        OnAfterTransferLinesEditable(Rec, IsEditable);
    end;

    procedure CheckTransferLines(Ship: Boolean)
    var
        TransferLine: Record "Transfer Line";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        TransferLine.SetRange("Document No.", Rec."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        if TransferLine.FindSet() then
            repeat
                ErrorMessageMgt.PushContext(ErrorContextElement, TransferLine.RecordId(), 0, CheckTransferLineMsg);
                TestTransferLine(TransferLine, Ship);
            until TransferLine.Next() = 0;
        ErrorMessageMgt.PopContext(ErrorContextElement);
    end;

    procedure TestTransferLine(TransferLine: Record "Transfer Line"; Ship: Boolean)
    var
        DummyTrackingSpecification: Record "Tracking Specification";
    begin
        if Ship then
            DummyTrackingSpecification.CheckItemTrackingQuantity(Database::"Transfer Line", 0, "No.", TransferLine."Line No.",
                TransferLine."Qty. to Ship (Base)", TransferLine."Qty. to Ship (Base)", true, false)
        else
            DummyTrackingSpecification.CheckItemTrackingQuantity(Database::"Transfer Line", 1, "No.", GetSourceRefNo(TransferLine),
                TransferLine."Qty. to Receive (Base)", TransferLine."Qty. to Receive (Base)", true, false);
    end;

    local procedure GetSourceRefNo(TransferLine: Record "Transfer Line"): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetLoadFields("Source Ref. No.");
        ReservationEntry.SetSourceFilter(Database::"Transfer Line", 1, TransferLine."Document No.", 0, true);
        ReservationEntry.SetRange("Item No.", TransferLine."Item No.");
        ReservationEntry.SetRange("Source Prod. Order Line", TransferLine."Line No.");
        if ReservationEntry.FindFirst() then
            exit(ReservationEntry."Source Ref. No.");
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := TransferLineReserve.GetReservedQtyFromInventory(Rec);
        if QtyReservedFromStock = 0 then
            exit(Result::None);

        if QtyReservedFromStock = CalculateReservableOutstandingQuantityBase() then
            exit(Result::Full);

        exit(Result::Partial);
    end;

    local procedure CalculateReservableOutstandingQuantityBase() OutstandingQtyBase: Decimal
    var
        RemQtyBaseInvtItemTransferLine: Query RemQtyBaseInvtItemTransferLine;
    begin
        RemQtyBaseInvtItemTransferLine.SetTransferLineFilter(Rec);
        if RemQtyBaseInvtItemTransferLine.Open() then
            if RemQtyBaseInvtItemTransferLine.Read() then
                OutstandingQtyBase := RemQtyBaseInvtItemTransferLine.Outstanding_Qty___Base_;
        RemQtyBaseInvtItemTransferLine.Close();
    end;

    local procedure FindPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DocumentNo: Code[20];
    begin
        PurchRcptLine.SetLoadFields("Document No.", "Location Code");
        PurchRcptLine.SetCurrentKey("Document No.");
        PurchRcptLine.SetRange("Location Code", "Transfer-from Code");
        if PurchRcptLine.FindSet() then
            repeat
                GetPurchRcptHeader(PurchRcptHeader, PurchRcptLine, DocumentNo);
            until PurchRcptLine.Next() = 0;
        PurchRcptHeader.MarkedOnly(true);
    end;

    local procedure GetPurchRcptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchRcptLine: Record "Purch. Rcpt. Line"; var DocumentNo: Code[20])
    begin
        if PurchRcptLine."Document No." = DocumentNo then
            exit;

        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        PurchRcptHeader.Mark(true);
        DocumentNo := PurchRcptLine."Document No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTransferLineFromReceiptLineOnBeforeTransferLineInsert(var TransferLine: Record "Transfer Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddTransferLineFromReceiptLine(var TransferLine: Record "Transfer Line"; var PurchRcptLine: Record "Purch. Rcpt. Line"; var TempItemLedgerEntry: Record "Item Ledger Entry"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBeforePost(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBeforeTransferPost(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var TransferHeader: Record "Transfer Header"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetTransferRoute(var TransferHeader: Record "Transfer Header"; TransferRoute: Record "Transfer Route");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTransferToLocation(var TransferHeader: Record "Transfer Header"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTransferFromLocation(var TransferHeader: Record "Transfer Header"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferLinesEditable(TransferHeader: Record "Transfer Header"; var IsEditable: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvtPostingSetup(TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferFromAndToCodesNotTheSame(TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteTransferLines(var IsHandled: Boolean; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var TransferHeader: Record "Transfer Header"; InventorySetup: Record "Inventory Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldDeleteOneTransferOrder(var TransferLine: record "Transfer Line"; var ShouldDelete: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(TransferHeader: Record "Transfer Header"; InvtSetup: Record "Inventory Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLineDeleteAll(TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTransLines(TransferHeader: Record "Transfer Header"; FieldID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferFromCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; var IsHandled: Boolean; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToCode(var TransferHeader: Record "Transfer Header"; var xTransferHeader: Record "Transfer Header"; var IsHandled: Boolean; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyNoOutboundWhseHandlingOnLocation(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOneTransferOrderOnBeforeTransHeaderDelete(var TransferHeader: Record "Transfer Header"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnAfterAssignDimensionSetID(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeTransLineModify(var TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReceiptDateOnBeforeCalcShipmentDate(var IsHandled: Boolean; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipmentDateOnBeforeCalcReceiptDate(var IsHandled: Boolean; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitSeries(var xTransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var xTransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOneTransferOrder(var TransHeader2: Record "Transfer Header"; var TransLine2: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTransLinesOnShippingAgentCodeOnBeforeBlockDynamicTracking(var TransferLine: record "Transfer Line"; var TransferHeader: record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTransLinesOnBeforeModifyTransferLine(TransferHeader: Record "Transfer Header"; var TransferLine: record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTransLinesOnAfterModifyTransferLine(TransferHeader: Record "Transfer Header"; var TransferLine: record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDirectTransferOnBeforeValidateInTransitCode(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferFromCity(var TransferHeader: Record "Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferFromPostCode(var TransferHeader: Record "Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToCity(var TransferHeader: Record "Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTransferToPostCode(var TransferHeader: Record "Transfer Header"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTransferFromCodeOnBeforeUpdateTransLines(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimFromDefaultDimOnBeforeCreateDim(var TransferHeader: Record "Transfer Header"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var TransferHeader: Record "Transfer Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBeforeTransferPost(TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyNoInboundWhseHandlingOnLocation(LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentCode(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddTransferLineFromReceiptLine(var TransferLine: Record "Transfer Line"; PurchRcptLine: Record "Purch. Rcpt. Line"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTransferLinesFromSelectedReceiptLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; var LineNo: Integer; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferLinesFromSelectedReceiptLines(var PurchRcptLine: Record "Purch. Rcpt. Line"; LineNo: Integer; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var TransferHeader: Record "Transfer Header"; xTransferHeader: Record "Transfer Header"; CurrentFieldNo: Integer; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;
}
