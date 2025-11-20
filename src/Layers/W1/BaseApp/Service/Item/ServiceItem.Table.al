// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Utilities;
using Microsoft.Integration.Dataverse;

table 5940 "Service Item"
{
    Caption = 'Service Item';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Service Item List";
    LookupPageID = "Service Item List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServMgtSetup.Get();
                    NoSeries.TestManual(ServMgtSetup."Service Item Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSerialNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Serial No." <> xRec."Serial No." then
                    MessageIfServItemLinesExist(FieldCaption("Serial No."));

                if "Serial No." <> '' then begin
                    ServItem.Reset();
                    ServItem.SetCurrentKey("Item No.", "Serial No.");
                    ServItem.SetRange("Item No.", "Item No.");
                    ServItem.SetRange("Serial No.", "Serial No.");
                    ServItem.SetFilter("No.", '<>%1', "No.");
                    if ServItem.FindFirst() then begin
                        if "Item No." <> '' then
                            Error(
                              Text003,
                              FieldCaption("Serial No."), "Serial No.", TableCaption(), ServItem."No.");
                        Message(
                          Text003,
                          FieldCaption("Serial No."), "Serial No.", TableCaption(), ServItem."No.")
                    end;
                end;

                if "Serial No." <> xRec."Serial No." then
                    ServLogMgt.ServItemSerialNoChange(Rec, xRec);
            end;
        }
        field(3; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";

            trigger OnValidate()
            begin
                if xRec."Service Item Group Code" = "Service Item Group Code" then begin
                    if not CancelResSkillAssignment then
                        ResSkillMgt.RevalidateResSkillRelation(
                          ResSkill.Type::"Service Item",
                          "No.",
                          ResSkill.Type::"Service Item Group",
                          "Service Item Group Code")
                end else begin
                    if not CancelResSkillAssignment then begin
                        if CancelResSkillChanges then
                            ResSkillMgt.SkipValidationDialogs();

                        if not ResSkillMgt.ChangeResSkillRelationWithGroup(
                             ResSkill.Type::"Service Item",
                             "No.",
                             ResSkill.Type::"Service Item Group",
                             "Service Item Group Code",
                             xRec."Service Item Group Code")
                        then
                            Error('');

                        if CancelResSkillChanges then begin
                            ResSkillMgt.DropGlobals();
                            CancelResSkillChanges := false;
                        end else
                            CancelResSkillChanges := true;
                    end;

                    if "Service Item Group Code" <> '' then begin
                        ServItemGr.Get("Service Item Group Code");
                        "Default Contract Discount %" := ServItemGr."Default Contract Discount %";
                        if "Service Price Group Code" = '' then
                            "Service Price Group Code" := ServItemGr."Default Serv. Price Group Code";
                        if (xRec."Service Item Group Code" <> "Service Item Group Code") and
                           (ServItemGr."Default Response Time (Hours)" <> 0)
                        then
                            "Response Time (Hours)" := ServItemGr."Default Response Time (Hours)";
                    end;
                end;
                if not IsNullGuid(Rec.SystemId) then
                    Modify();
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            OptimizeForTextSearch = true;
        }
        field(6; Status; Enum "Service Item Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            begin
                if Status <> xRec.Status then begin
                    if (Status = Status::Installed) and ("Installation Date" = 0D) then
                        "Installation Date" := WorkDate();
                    ServLogMgt.ServItemStatusChange(Rec, xRec);
                end;
            end;
        }
        field(7; Priority; Enum "Service Priority")
        {
            Caption = 'Priority';
        }
        field(8; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
            ValidateTableRelation = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
                ShouldConfirmChange: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCustomerNo(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Customer No." <> xRec."Customer No." then begin
                    if CheckifActiveServContLineExist() then
                        Error(Text004, FieldCaption("Customer No."), "Customer No.", TableCaption(), "No.");
                    ServItemLinesExistErr(FieldCaption("Customer No."));
                    ShouldConfirmChange := ServLedgEntryExist();
                    OnValidateCustomerNoOnAfterCalcShouldConfirmChange(Rec, CurrFieldNo, ShouldConfirmChange);
                    if ShouldConfirmChange then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text017, TableCaption(), FieldCaption("Customer No.")), true)
                        then begin
                            "Customer No." := xRec."Customer No.";
                            exit;
                        end;
                    "Ship-to Code" := '';
                    if ("Customer No." <> '') and
                       (xRec."Customer No." = '')
                    then
                        Status := Status::Installed;
                    ServLogMgt.ServItemCustChange(Rec, xRec);
                    ServLogMgt.ServItemShipToCodeChange(Rec, xRec);
                end;
            end;
        }
        field(9; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                ShouldConfirmChange: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShiptoCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Ship-to Code" <> xRec."Ship-to Code" then begin
                    if CheckifActiveServContLineExist() then
                        Error(
                          Text004,
                          FieldCaption("Ship-to Code"), "Ship-to Code", TableCaption(), "No.");
                    ServItemLinesExistErr(FieldCaption("Ship-to Code"));
                    ShouldConfirmChange := ServLedgEntryExist();
                    OnValidateShiptoCodeOnAfterCalcShouldConfirmChange(Rec, CurrFieldNo, ShouldConfirmChange);
                    if ShouldConfirmChange then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text017, TableCaption(), FieldCaption("Ship-to Code")), true)
                        then begin
                            "Ship-to Code" := xRec."Ship-to Code";
                            exit;
                        end;
                    ServLogMgt.ServItemShipToCodeChange(Rec, xRec);
                end;
            end;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No." where(Blocked = const(false), "Service Blocked" = const(false));

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateItemNo(Rec, xRec, CancelResSkillAssignment, CancelResSkillChanges, ResSkill, IsHandled);
                if IsHandled then
                    exit;

                if "Item No." <> xRec."Item No." then begin
                    if "Item No." <> '' then begin
                        CalcFields("Service Item Components");
                        if "Service Item Components" then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(
                                   ChangeItemQst, FieldCaption("Item No."),
                                   FieldCaption("Service Item Components")), true)
                            then begin
                                "Item No." := xRec."Item No.";
                                exit;
                            end;
                    end;
                    if not CancelResSkillAssignment then begin
                        if CancelResSkillChanges then
                            ResSkillMgt.SkipValidationDialogs();
                        if not ResSkillMgt.ChangeResSkillRelationWithItem(
                             ResSkill.Type::"Service Item",
                             "No.",
                             ResSkill.Type::Item,
                             "Item No.",
                             xRec."Item No.",
                             xRec."Service Item Group Code")
                        then
                            Error('');
                        if CancelResSkillChanges then begin
                            ResSkillMgt.DropGlobals();
                            CancelResSkillChanges := false;
                        end else
                            CancelResSkillChanges := true;
                    end;
                    if "Item No." <> '' then begin
                        Item.Get("Item No.");
                        Validate("Service Item Group Code", Item."Service Item Group");
                        Validate("Serial No.");
                        Validate("Sales Unit Cost", Item."Unit Cost");
                        Validate("Sales Unit Price", Item."Unit Price");
                        "Variant Code" := '';
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                        if Description = '' then
                            Validate(Description, Item.Description);
                        OnAfterAssignItemValues(Rec, xRec, Item, CurrFieldNo);
                        if "Service Item Components" then begin
                            DeleteServItemComponents();
                            CalcFields("Service Item Components");
                        end;
                    end else begin
                        "Serial No." := '';
                        Validate("Sales Unit Price", 0);
                        Validate("Sales Unit Cost", 0);
                        "Variant Code" := '';
                        "Service Item Group Code" := '';
                        "Unit of Measure Code" := '';
                    end;
                    MessageIfServItemLinesExist(FieldCaption("Item No."));
                end else begin
                    OnValidateItemNoOnBeforeCheckCancelResSkillAssignment(Rec, ResSkillMgt);
                    if not CancelResSkillAssignment then
                        ResSkillMgt.RevalidateResSkillRelation(
                          ResSkill.Type::"Service Item",
                          "No.",
                          ResSkill.Type::Item,
                          "Item No.");
                end;

                ServLogMgt.ServItemItemNoChange(Rec, xRec);
                if not IsNullGuid(Rec.SystemId) then
                    Modify();
            end;
        }
        field(11; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if ("Item No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("Item No."))
            else
            "Unit of Measure";
        }
        field(12; "Location of Service Item"; Text[30])
        {
            Caption = 'Location of Service Item';
            OptimizeForTextSearch = true;
        }
        field(13; "Sales Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Sales Unit Price';

            trigger OnValidate()
            begin
                ServMgtSetup.Get();
                Currency.InitRoundingPrecision();
                if (ServMgtSetup."Contract Value Calc. Method" =
                    ServMgtSetup."Contract Value Calc. Method"::"Based on Unit Price") and
                   ("Sales Unit Price" <> xRec."Sales Unit Price")
                then
                    "Default Contract Value" :=
                      Round("Sales Unit Price" * ServMgtSetup."Contract Value %" / 100,
                        Currency."Unit-Amount Rounding Precision");
            end;
        }
        field(14; "Sales Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Sales Unit Cost';

            trigger OnValidate()
            begin
                ServMgtSetup.Get();
                Currency.InitRoundingPrecision();
                "Default Contract Cost" :=
                  Round("Sales Unit Cost" * ServMgtSetup."Contract Value %" / 100,
                    Currency."Unit-Amount Rounding Precision");
                if (ServMgtSetup."Contract Value Calc. Method" =
                    ServMgtSetup."Contract Value Calc. Method"::"Based on Unit Cost") and
                   ("Sales Unit Cost" <> xRec."Sales Unit Cost")
                then
                    "Default Contract Value" := "Default Contract Cost";
            end;
        }
        field(15; "Warranty Starting Date (Labor)"; Date)
        {
            Caption = 'Warranty Starting Date (Labor)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyStartingDateLabor(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Warranty Starting Date (Labor)" <> xRec."Warranty Starting Date (Labor)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty Starting Date (Labor)"));

                ServMgtSetup.Get();
                ServMgtSetup.TestField("Default Warranty Duration");
                if "Warranty Starting Date (Labor)" <> xRec."Warranty Starting Date (Labor)" then
                    if "Warranty Starting Date (Labor)" <> 0D then
                        Validate("Warranty Ending Date (Labor)", CalcDate(ServMgtSetup."Default Warranty Duration", "Warranty Starting Date (Labor)"))
                    else
                        "Warranty Ending Date (Labor)" := 0D;

                if "Warranty Starting Date (Labor)" <> 0D then
                    if "Warranty Starting Date (Parts)" = 0D then
                        Validate("Warranty Starting Date (Parts)", "Warranty Starting Date (Labor)");
            end;
        }
        field(16; "Warranty Ending Date (Labor)"; Date)
        {
            Caption = 'Warranty Ending Date (Labor)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyEndingDateLabor(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Warranty Ending Date (Labor)" <> xRec."Warranty Ending Date (Labor)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty Ending Date (Labor)"));

                if "Warranty Ending Date (Labor)" < "Warranty Starting Date (Labor)" then
                    Error(
                      Text007,
                      FieldCaption("Warranty Starting Date (Labor)"), FieldCaption("Warranty Ending Date (Labor)"));

                ServMgtSetup.Get();
                if "Warranty % (Labor)" = 0 then
                    "Warranty % (Labor)" := ServMgtSetup."Warranty Disc. % (Labor)";
            end;
        }
        field(17; "Warranty Starting Date (Parts)"; Date)
        {
            Caption = 'Warranty Starting Date (Parts)';

            trigger OnValidate()
            var
                ItemTrackingCode: Record "Item Tracking Code";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyStartingDateParts(Rec, xRec, Item, IsHandled);
                if IsHandled then
                    exit;

                if "Warranty Starting Date (Parts)" <> xRec."Warranty Starting Date (Parts)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty Starting Date (Parts)"));

                if "Warranty Starting Date (Parts)" <> xRec."Warranty Starting Date (Parts)" then
                    if "Warranty Starting Date (Parts)" <> 0D then begin
                        if Item.Get("Item No.") and (Item."Item Tracking Code" <> '') and
                           ItemTrackingCode.Get(Item."Item Tracking Code") and
                           (Format(ItemTrackingCode."Warranty Date Formula") <> '')
                        then
                            Validate(
                              "Warranty Ending Date (Parts)",
                              CalcDate(ItemTrackingCode."Warranty Date Formula",
                                "Warranty Starting Date (Parts)"))
                        else begin
                            ServMgtSetup.Get();
                            ServMgtSetup.TestField("Default Warranty Duration");
                            Validate(
                              "Warranty Ending Date (Parts)",
                              CalcDate(ServMgtSetup."Default Warranty Duration",
                                "Warranty Starting Date (Parts)"));
                        end;
                    end else
                        "Warranty Ending Date (Parts)" := 0D;

                if "Warranty Starting Date (Parts)" <> 0D then
                    if "Warranty Starting Date (Labor)" = 0D then
                        Validate("Warranty Starting Date (Labor)", "Warranty Starting Date (Parts)");
            end;
        }
        field(18; "Warranty Ending Date (Parts)"; Date)
        {
            Caption = 'Warranty Ending Date (Parts)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyEndingDateParts(Rec, xRec, Item, IsHandled);
                if IsHandled then
                    exit;

                if "Warranty Ending Date (Parts)" < "Warranty Starting Date (Parts)" then
                    Error(
                      Text007,
                      FieldCaption("Warranty Starting Date (Parts)"), FieldCaption("Warranty Ending Date (Parts)"));

                if "Warranty Ending Date (Parts)" <> xRec."Warranty Ending Date (Parts)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty Ending Date (Parts)"));

                ServMgtSetup.Get();
                if "Warranty % (Parts)" = 0 then
                    "Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
            end;
        }
        field(19; "Warranty % (Parts)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Warranty % (Parts)" <> xRec."Warranty % (Parts)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty % (Parts)"));
            end;
        }
        field(20; "Warranty % (Labor)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Warranty % (Labor)" <> xRec."Warranty % (Labor)" then
                    MessageIfServItemLinesExist(FieldCaption("Warranty % (Labor)"));
            end;
        }
        field(21; "Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(22; "Installation Date"; Date)
        {
            Caption = 'Installation Date';
        }
        field(23; "Sales Date"; Date)
        {
            Caption = 'Sales Date';

            trigger OnValidate()
            begin
                if "Sales Date" > 0D then begin
                    if "Warranty Starting Date (Parts)" = 0D then
                        Validate("Warranty Starting Date (Parts)", "Sales Date");
                    if "Warranty Starting Date (Labor)" = 0D then
                        Validate("Warranty Starting Date (Labor)", "Sales Date");
                end;
            end;
        }
        field(24; "Last Service Date"; Date)
        {
            Caption = 'Last Service Date';
        }
        field(25; "Default Contract Value"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Default Contract Value';
        }
        field(26; "Default Contract Discount %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Default Contract Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(28; "No. of Active Contracts"; Integer)
        {
            CalcFormula = count("Service Contract Line" where("Service Item No." = field("No."),
                                                               "Contract Status" = filter(<> Cancelled)));
            Caption = 'No. of Active Contracts';
            FieldClass = FlowField;
        }
        field(33; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(34; "Vendor Item No."; Code[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(40; Blocked; Enum "Service Item Blocked")
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Blocked <> xRec.Blocked then
                    ServLogMgt.ServItemBlockedChange(Rec, xRec);
            end;
        }
        field(47; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(48; "Item Description"; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Item Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(49; Name; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; Address; Text[100])
        {
            CalcFormula = lookup(Customer.Address where("No." = field("Customer No.")));
            Caption = 'Address';
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Address 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Address 2" where("No." = field("Customer No.")));
            Caption = 'Address 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Post Code"; Code[20])
        {
            CalcFormula = lookup(Customer."Post Code" where("No." = field("Customer No.")));
            Caption = 'Post Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; City; Text[30])
        {
            CalcFormula = lookup(Customer.City where("No." = field("Customer No.")));
            Caption = 'City';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(54; Contact; Text[100])
        {
            CalcFormula = lookup(Customer.Contact where("No." = field("Customer No.")));
            Caption = 'Contact';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Phone No."; Text[30])
        {
            CalcFormula = lookup(Customer."Phone No." where("No." = field("Customer No.")));
            Caption = 'Phone No.';
            Editable = false;
            ExtendedDatatype = PhoneNo;
            FieldClass = FlowField;
        }
        field(56; "Ship-to Name"; Text[100])
        {
            CalcFormula = lookup("Ship-to Address".Name where("Customer No." = field("Customer No."),
                                                               Code = field("Ship-to Code")));
            Caption = 'Ship-to Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; "Ship-to Address"; Text[100])
        {
            CalcFormula = lookup("Ship-to Address".Address where("Customer No." = field("Customer No."),
                                                                  Code = field("Ship-to Code")));
            Caption = 'Ship-to Address';
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "Ship-to Address 2"; Text[50])
        {
            CalcFormula = lookup("Ship-to Address"."Address 2" where("Customer No." = field("Customer No."),
                                                                      Code = field("Ship-to Code")));
            Caption = 'Ship-to Address 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Ship-to Post Code"; Code[20])
        {
            CalcFormula = lookup("Ship-to Address"."Post Code" where("Customer No." = field("Customer No."),
                                                                      Code = field("Ship-to Code")));
            Caption = 'Ship-to Post Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Ship-to City"; Text[30])
        {
            CalcFormula = lookup("Ship-to Address".City where("Customer No." = field("Customer No."),
                                                               Code = field("Ship-to Code")));
            Caption = 'Ship-to City';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(61; "Ship-to Contact"; Text[100])
        {
            CalcFormula = lookup("Ship-to Address".Contact where("Customer No." = field("Customer No."),
                                                                  Code = field("Ship-to Code")));
            Caption = 'Ship-to Contact';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Ship-to Phone No."; Text[30])
        {
            CalcFormula = lookup("Ship-to Address"."Phone No." where("Customer No." = field("Customer No."),
                                                                      Code = field("Ship-to Code")));
            Caption = 'Ship-to Phone No.';
            Editable = false;
            ExtendedDatatype = PhoneNo;
            FieldClass = FlowField;
        }
        field(63; "Usage (Cost)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Service Ledger Entry"."Cost Amount" where("Entry Type" = const(Usage),
                                                                          "Service Item No. (Serviced)" = field("No."),
                                                                          "Service Contract No." = field("Contract Filter"),
                                                                          "Service Order No." = field("Service Order Filter"),
                                                                          Type = field("Type Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(64; "Usage (Amount)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Service Ledger Entry"."Amount (LCY)" where("Entry Type" = const(Usage),
                                                                           "Service Item No. (Serviced)" = field("No."),
                                                                           "Service Contract No." = field("Contract Filter"),
                                                                           "Service Order No." = field("Service Order Filter"),
                                                                           Type = field("Type Filter"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Usage (Amount)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Invoiced Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Amount (LCY)" where("Entry Type" = const(Sale),
                                                                            "Moved from Prepaid Acc." = const(true),
                                                                            "Service Item No. (Serviced)" = field("No."),
                                                                            "Service Contract No." = field("Contract Filter"),
                                                                            "Service Order No." = field("Service Order Filter"),
                                                                            Type = field("Type Filter"),
                                                                            "Posting Date" = field("Date Filter"),
                                                                            Open = const(false)));
            Caption = 'Invoiced Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Total Quantity"; Decimal)
        {
            CalcFormula = sum("Service Ledger Entry".Quantity where("Entry Type" = const(Usage),
                                                                     "Service Item No. (Serviced)" = field("No."),
                                                                     "Service Contract No." = field("Contract Filter"),
                                                                     "Service Order No." = field("Service Order Filter"),
                                                                     Type = field("Type Filter"),
                                                                     "Posting Date" = field("Date Filter")));
            Caption = 'Total Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(67; "Total Qty. Invoiced"; Decimal)
        {
            CalcFormula = - sum("Service Ledger Entry"."Charged Qty." where("Entry Type" = const(Sale),
                                                                            "Service Item No. (Serviced)" = field("No."),
                                                                            "Service Contract No." = field("Contract Filter"),
                                                                            "Service Order No." = field("Service Order Filter"),
                                                                            Type = field("Type Filter"),
                                                                            "Posting Date" = field("Date Filter")));
            Caption = 'Total Qty. Invoiced';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(68; "Resources Used"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Cost Amount" where("Service Item No. (Serviced)" = field("No."),
                                                                           "Entry Type" = const(Sale),
                                                                           Type = const(Resource),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Resources Used';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Parts Used"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Cost Amount" where("Service Item No. (Serviced)" = field("No."),
                                                                           "Entry Type" = const(Sale),
                                                                           Type = const(Item),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Parts Used';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Cost Used"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Cost Amount" where("Service Item No. (Serviced)" = field("No."),
                                                                           "Entry Type" = const(Sale),
                                                                           Type = const("Service Cost"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Cost Used';
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Vendor Name"; Text[100])
        {
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Caption = 'Vendor Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Vendor Item Name"; Text[100])
        {
            Caption = 'Vendor Item Name';
            OptimizeForTextSearch = true;
        }
        field(73; Comment; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Item"),
                                                              "Table Subtype" = const("0"),
                                                              "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(74; "Service Item Components"; Boolean)
        {
            CalcFormula = exist("Service Item Component" where("Parent Service Item No." = field("No."),
                                                                Active = const(true)));
            Caption = 'Service Item Components';
            Editable = false;
            FieldClass = FlowField;
        }
        field(75; "Preferred Resource"; Code[20])
        {
            Caption = 'Preferred Resource';
            TableRelation = Resource."No.";

            trigger OnLookup()
            var
                Resource: Record Resource;
                SkilledResourceList: Page "Skilled Resource List";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePreferredResource(Rec, IsHandled);
                if not IsHandled then begin
                    SkilledResourceList.Initialize(ResSkill.Type::"Service Item", "No.", Description);
                    SkilledResourceList.LookupMode(true);
                    if Resource.Get("Preferred Resource") then
                        SkilledResourceList.SetRecord(Resource);
                    if SkilledResourceList.RunModal() = ACTION::LookupOK then begin
                        SkilledResourceList.GetRecord(Resource);
                        "Preferred Resource" := Resource."No.";
                    end;
                end;
                OnAfterValidatePreferredResource(Rec, ServItem);
            end;
        }
        field(76; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false), "Service Blocked" = const(false));

            trigger OnValidate()
            begin
                if "Variant Code" <> xRec."Variant Code" then
                    MessageIfServItemLinesExist(FieldCaption("Variant Code"));
            end;
        }
        field(77; County; Text[30])
        {
            CalcFormula = lookup(Customer.County where("No." = field("Customer No.")));
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; "Ship-to County"; Text[30])
        {
            CalcFormula = lookup("Ship-to Address".County where("Customer No." = field("Customer No."),
                                                                 Code = field("Ship-to Code")));
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            Editable = false;
            FieldClass = FlowField;
        }
        field(79; "Contract Cost"; Decimal)
        {
            CalcFormula = - sum("Service Ledger Entry"."Cost Amount" where("Entry Type" = const(Sale),
                                                                           "Service Item No. (Serviced)" = field("No."),
                                                                           "Service Contract No." = field("Contract Filter"),
                                                                           "Service Order No." = field("Service Order Filter"),
                                                                           Type = const("Service Contract"),
                                                                           "Posting Date" = field("Date Filter")));
            Caption = 'Contract Cost';
            FieldClass = FlowField;
        }
        field(81; "Country/Region Code"; Code[10])
        {
            CalcFormula = lookup(Customer."Country/Region Code" where("No." = field("Customer No.")));
            Caption = 'Country/Region Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(82; "Ship-to Country/Region Code"; Code[10])
        {
            CalcFormula = lookup("Ship-to Address"."Country/Region Code" where("Customer No." = field("Customer No."),
                                                                                Code = field("Ship-to Code")));
            Caption = 'Ship-to Country/Region Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "Name 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Name 2" where("No." = field("Customer No.")));
            Caption = 'Name 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Ship-to Name 2"; Text[50])
        {
            CalcFormula = lookup("Ship-to Address"."Name 2" where("Customer No." = field("Customer No."),
                                                                   Code = field("Ship-to Code")));
            Caption = 'Ship-to Name 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";
        }
        field(86; "Default Contract Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Default Contract Cost';
        }
        field(87; "Prepaid Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Amount (LCY)" where("Entry Type" = const(Sale),
                                                                            "Moved from Prepaid Acc." = const(false),
                                                                            "Service Item No. (Serviced)" = field("No."),
                                                                            "Service Contract No." = field("Contract Filter"),
                                                                            "Service Order No." = field("Service Order Filter"),
                                                                            Type = field("Type Filter"),
                                                                            "Posting Date" = field("Date Filter"),
                                                                            Open = const(false)));
            Caption = 'Prepaid Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(88; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            OptimizeForTextSearch = true;
        }
        field(89; "Service Contracts"; Boolean)
        {
            CalcFormula = exist("Service Contract Line" where("Service Item No." = field("No.")));
            Caption = 'Service Contracts';
            Editable = false;
            FieldClass = FlowField;
        }
        field(90; "Total Qty. Consumed"; Decimal)
        {
            CalcFormula = - sum("Service Ledger Entry".Quantity where("Entry Type" = const(Consume),
                                                                      "Service Item No. (Serviced)" = field("No."),
                                                                      "Service Contract No." = field("Contract Filter"),
                                                                      "Service Order No." = field("Service Order Filter"),
                                                                      Type = field("Type Filter"),
                                                                      "Posting Date" = field("Date Filter")));
            Caption = 'Total Qty. Consumed';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(100; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(101; "Type Filter"; Enum "Service Ledger Entry Type")
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
        }
        field(102; "Contract Filter"; Code[20])
        {
            Caption = 'Contract Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(103; "Service Order Filter"; Code[20])
        {
            Caption = 'Service Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Header"."No.";
        }
        field(104; "Sales/Serv. Shpt. Document No."; Code[20])
        {
            Caption = 'Sales/Serv. Shpt. Document No.';
            OptimizeForTextSearch = true;
            TableRelation = if ("Shipment Type" = const(Sales)) "Sales Shipment Line"."Document No."
            else
            if ("Shipment Type" = const(Service)) "Service Shipment Line"."Document No.";
        }
        field(105; "Sales/Serv. Shpt. Line No."; Integer)
        {
            Caption = 'Sales/Serv. Shpt. Line No.';
            TableRelation = if ("Shipment Type" = const(Sales)) "Sales Shipment Line"."Line No." where("Document No." = field("Sales/Serv. Shpt. Document No."))
            else
            if ("Shipment Type" = const(Service)) "Service Shipment Line"."Line No." where("Document No." = field("Sales/Serv. Shpt. Document No."));
        }
        field(106; "Shipment Type"; Enum "Service Item Shipment Type")
        {
            Caption = 'Shipment Type';
        }
        field(211; "Ship-to E-Mail"; Text[80])
        {
            CalcFormula = lookup("Ship-to Address"."E-Mail" where("Customer No." = field("Customer No."), Code = field("Ship-to Code")));
            Caption = 'Ship-to Email';
            ExtendedDatatype = EMail;
            Editable = false;
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA28
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Service Item")));
            ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
#if not CLEAN25
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif
        }
#endif
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Serial No.")
        {
        }
        key(Key3; "Customer No.", "Ship-to Code", "Item No.", "Serial No.")
        {
        }
        key(Key4; "Warranty Ending Date (Parts)", "Customer No.", "Ship-to Code")
        {
        }
        key(Key5; "Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.")
        {
        }
        key(Key6; "Service Item Group Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status, Blocked, "Item No.", "Service Contracts")
        {
        }
        fieldgroup(Brick; "No.", Description, "Item No.", "Customer No.", "Name")
        { }
    }

    trigger OnDelete()
    var
        ResultDescription: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteServiceItem(Rec, ServItem, IsHandled);
        if IsHandled then
            exit;

        ServMoveEntries.MoveServiceItemLedgerEntries(Rec);

        ResultDescription := CheckIfCanBeDeleted();
        if ResultDescription <> '' then
            Error(ResultDescription);

        DeleteServItemComponents();

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Item");
        ServCommentLine.SetRange("Table Subtype", 0);
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.DeleteAll();

        ResSkillMgt.DeleteServItemResSkills("No.");
        ServLogMgt.ServItemDeleted("No.");

        DimMgt.DeleteDefaultDim(DATABASE::"Service Item", "No.");
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeinsertServiceItem(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        ServMgtSetup.Get();
        if "No." = '' then begin
            ServMgtSetup.TestField("Service Item Nos.");
            "No. Series" := ServMgtSetup."Service Item Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
        end;
        "Response Time (Hours)" := ServMgtSetup."Default Response Time (Hours)";

        ServLogMgt.ServItemCreated(Rec);
    end;

    trigger OnRename()
    begin
        if "No." <> xRec."No." then begin
            DimMgt.RenameDefaultDim(DATABASE::"Service Item", xRec."No.", "No.");
            ServLogMgt.ServItemNoChange(Rec, xRec);
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
            ServContractLine.SetRange("Service Item No.", xRec."No.");
            ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
            if ServContractLine.Find('-') then
                repeat
                    ContractChangeLog.LogContractChange(
                      ServContractLine."Contract No.", 1,
                      ServContractLine.FieldCaption("Service Item No."), 3,
                      xRec."No.", "No.", "No.", 0);
                until ServContractLine.Next() = 0;
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServItem: Record "Service Item";
        ServItemGr: Record "Service Item Group";
        ServContract: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServCommentLine: Record "Service Comment Line";
        Item: Record Item;
        ContractChangeLog: Record "Contract Change Log";
        ServLedgEntry: Record "Service Ledger Entry";
        ServItemLine: Record "Service Item Line";
        ServItemComponent: Record "Service Item Component";
        ResSkill: Record "Resource Skill";
        Currency: Record Currency;
        NoSeries: Codeunit "No. Series";
        ServLogMgt: Codeunit ServLogManagement;
        ServMoveEntries: Codeunit "Serv. Move Entries";
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        DimMgt: Codeunit DimensionManagement;
        CancelResSkillChanges: Boolean;
        CancelResSkillAssignment: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete %1 %2,because it is attached to a service order.';
        Text001: Label 'You cannot delete %1 %2, because it is used as %3 for %1 %4.';
        Text002: Label 'You cannot delete %1 %2, because it belongs to one or more contracts.';
        Text003: Label '%1 %2 already exists in %3 %4.';
        Text004: Label 'You cannot change %1 %2 because the %3 %4 belongs to one or more contracts.';
        Text007: Label '%1 cannot be later than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FieldUpdateConfirmQst: Label 'You have changed %1 on the service item, but it has not been changed on the associated service orders/quotes.\You must update them manually.', Comment = '%1 = field name';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text017: Label 'Service ledger entries exist for this %1\\ Do you want to change the %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ChgCustomerErr: Label 'You cannot change the %1 in the service item because of the following outstanding service order line:\\ Order %2, line %3, service item number %4, serial number %5, customer %6, ship-to code %7.', Comment = '%1 - Field Caption; %2 - Service Order No.;%3 - Serice Line No.;%4 - Service Item No.;%5 - Serial No.;%6 - Customer No.;%7 - Ship to Code.';
        ChangeItemQst: Label 'Changing the %1 will delete the existing %2 on the %2 list.\\Do you want to change the %1?', Comment = '%1 - Field Caption, %2 - Field Caption';

    procedure AssistEdit(OldServItem: Record "Service Item"): Boolean
    begin
        ServItem := Rec;
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Service Item Nos.");
        if NoSeries.LookupRelatedNoSeries(ServMgtSetup."Service Item Nos.", OldServItem."No. Series", ServItem."No. Series") then begin
            ServItem."No." := NoSeries.GetNextNo(ServItem."No. Series");
            Rec := ServItem;
            exit(true);
        end;
    end;

    procedure ServItemLinesExist() Result: Boolean
    begin
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Service Item No.");
        ServItemLine.SetRange("Service Item No.", "No.");
        Result := ServItemLine.FindFirst();

        OnAfterServItemLinesExist(Rec, ServItemLine, CurrFieldNo, Result);
    end;

    procedure MessageIfServItemLinesExist(ChangedFieldName: Text)
    var
        MessageText: Text;
        ShowMessage, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeMsgIfServItemLinesExist(CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        ShowMessage := ServItemLinesExist();
        MessageText := StrSubstNo(FieldUpdateConfirmQst, ChangedFieldName);
        OnBeforeMessageIfServItemLinesExist(Rec, CopyStr(ChangedFieldName, 1, 100), MessageText, ShowMessage);
        if ShowMessage then
            Message(MessageText);
    end;

    local procedure DeleteServItemComponents()
    begin
        ServItemComponent.Reset();
        ServItemComponent.SetRange("Parent Service Item No.", "No.");
        ServItemComponent.DeleteAll();

        OnAfterDeleteServItemComponents(Rec);
    end;

    local procedure ServItemLinesExistErr(ChangedFieldName: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServItemLinesExistErr(Rec, CopyStr(ChangedFieldName, 1, 100), IsHandled);
        if IsHandled then
            exit;

        if IsNullGuid(Rec.SystemId) then
            exit;

        if ServItemLinesExist() then
            Error(
              ChgCustomerErr,
              ChangedFieldName,
              ServItemLine."Document No.", ServItemLine."Line No.", ServItemLine."Service Item No.",
              ServItemLine."Serial No.", ServItemLine."Customer No.", ServItemLine."Ship-to Code");
    end;

    local procedure ServLedgEntryExist(): Boolean
    begin
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey(
          "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.",
          Type, "Posting Date", Open);
        ServLedgEntry.SetRange("Service Item No. (Serviced)", "No.");
        exit(ServLedgEntry.FindFirst());
    end;

    local procedure CheckifActiveServContLineExist(): Boolean
    begin
        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
        ServContractLine.SetRange("Service Item No.", "No.");
        ServContractLine.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
        OnCheckifActiveServContLineExistOnAfterSetFilters(ServContractLine);
        exit(ServContractLine.Find('-'));
    end;

    procedure CheckIfCanBeDeleted() Result: Text
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfCanBeDeleted(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ServItemLinesExist() then
            exit(
              StrSubstNo(
                Text000,
                TableCaption, "No."));

        ServItemComponent.Reset();
        ServItemComponent.SetCurrentKey(Type, "No.", Active);
        ServItemComponent.SetRange(Type, ServItemComponent.Type::"Service Item");
        ServItemComponent.SetRange("No.", "No.");
        if ServItemComponent.FindFirst() then
            exit(
              StrSubstNo(
                Text001,
                TableCaption, "No.", ServItemComponent.TableCaption(), ServItemComponent."Parent Service Item No."));

        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
        ServContractLine.SetRange("Service Item No.", "No.");
        ServContractLine.SetFilter("Contract Status", '<>%1', ServContractLine."Contract Status"::Cancelled);
        if ServContractLine.Find('-') then
            if ServContract.Get(ServContractLine."Contract Type", ServContractLine."Contract No.") then
                exit(
                  StrSubstNo(Text002, TableCaption(), "No."));

        exit(ServMoveEntries.CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, "No."));
    end;

    procedure OmitAssignResSkills(IsSetOmitted: Boolean)
    begin
        CancelResSkillAssignment := IsSetOmitted;
    end;

    # region Service Item Blocked checks
    internal procedure ErrorIfBlockedForServiceContract()
    begin
        TestField(Blocked, Blocked::" ");
    end;

    internal procedure ErrorIfBlockedForAll()
    begin
        if Blocked = Blocked::All then
            FieldError(Blocked);
    end;
    #endregion Service Item Blocked checks

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; Item: Record Item; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteServItemComponents(var ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePreferredResource(var ServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePreferredResource(var ServiceItem: Record "Service Item"; var ServiceItemGlobal: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMessageIfServItemLinesExist(ServiceItem: Record "Service Item"; ChangedFieldName: Text[100]; var MessageText: Text; var ShowMessage: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServItemLinesExistErr(var ServiceItem: Record "Service Item"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfCanBeDeleted(var ServiceItem: Record "Service Item"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSerialNo(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNo(var ServiceItem: Record "Service Item"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckifActiveServContLineExistOnAfterSetFilters(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnAfterCalcShouldConfirmChange(var ServiceItem: Record "Service Item"; CurrFieldNo: Integer; var ShouldConfirmChange: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShiptoCodeOnAfterCalcShouldConfirmChange(var ServiceItem: Record "Service Item"; CurrFieldNo: Integer; var ShouldConfirmChange: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyStartingDateLabor(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyEndingDateLabor(var ServiceItem: Record "Service Item"; xServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShiptoCode(var ServiceItem: Record "Service Item"; xServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeCheckCancelResSkillAssignment(var ServiceItem: Record "Service Item"; var ResourceSkillMgt: Codeunit "Resource Skill Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyStartingDateParts(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceItem(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServiceItem(var ServiceItem: Record "Service Item"; var ServItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemNo(var ServiceItem: Record "Service Item"; var xServiceItem: Record "Service Item"; var CancelResSkillAssignment: Boolean; var CancelResSkillChanges: Boolean; var ResourceSkill: Record "Resource Skill"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMsgIfServItemLinesExist(CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyEndingDateParts(var ServiceItem: Record "Service Item"; xServiceItem: Record "Service Item"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServItemLinesExist(var ServiceItem: Record "Service Item"; var ServiceItemLine: Record "Service Item Line"; CurrFieldNo: Integer; var Result: Boolean)
    begin
    end;
}
