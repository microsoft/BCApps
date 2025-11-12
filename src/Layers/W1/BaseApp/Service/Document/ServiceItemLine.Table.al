// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using System.Security.User;
using System.Utilities;

table 5901 "Service Item Line"
{
    Caption = 'Service Item Line';
    DrillDownPageID = "Service Item Lines";
    LookupPageID = "Service Item Lines";
    Permissions = TableData "Loaner Entry" = rimd,
                  TableData "Service Order Allocation" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            TableRelation = "Service Header"."No." where("Document Type" = field("Document Type"));

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(0);
            end;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = if ("Document Type" = filter(<> "Credit Memo")) "Service Item"."No." where(Blocked = filter(<> All))
            else
            if ("Document Type" = filter("Credit Memo")) "Service Item"."No.";

            trigger OnValidate()
            var
                Cust: Record Customer;
                ConfirmManagement: Codeunit "Confirm Management";
                ServContractList: Page "Serv. Contr. List (Serv. Item)";
                IsHandled: Boolean;
                ShouldFindServContractLine: Boolean;
                DoExit: Boolean;
            begin
                if "Loaner No." <> '' then
                    Error(Text055, FieldCaption("Service Item No."),
                      FieldCaption("Loaner No."), "Loaner No.");

                IsHandled := false;
                DoExit := false;
                OnValidateServiceItemNoOnBeforeCheckXRecServiceItemNo(Rec, xRec, ServLine, ServItem, IsHandled, DoExit);
                if not IsHandled then
                    if "Service Item No." <> xRec."Service Item No." then begin
                        if CheckServLineExist() then
                            Error(
                              Text011,
                              FieldCaption("Service Item No."), TableCaption(), ServLine.TableCaption());
                    end else begin
                        CreateDimFromDefaultDim(0);

                        if ServItem.Get("Service Item No.") then begin
                            SetServItemInfo(ServItem);
                            if "Contract No." = '' then
                                Validate("Service Price Group Code", ServItem."Service Price Group Code");
                            "Service Item Group Code" := ServItem."Service Item Group Code";
                        end;

                        exit;
                    end;

                if DoExit then
                    exit;

                if "Service Item No." = '' then begin
                    if xRec."Service Item No." <> "Service Item No." then begin
                        Validate("Warranty Starting Date (Parts)", 0D);
                        Validate("Warranty Starting Date (Labor)", 0D);
                        Validate("Contract No.", '');
                        Validate("Serial No.", '');
                    end;
                    exit;
                end;

                OnValidateServiceItemNoOnAfterValidateWarrantyPartsLaborDates(Rec);

                ServContractExist := false;
                ServHeader.Get(Rec."Document Type", Rec."Document No.");
                if ServItem.Get("Service Item No.") then begin
                    CheckServItemCustomer(ServHeader, ServItem);

                    if ServHeader."Contract No." <> '' then begin
                        ServHeader.TestField("Order Date");
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                        ServContractLine.SetRange("Contract No.", ServHeader."Contract No.");
                        ServContractLine.SetRange("Service Item No.", "Service Item No.");

                        OnValidateServiceItemNoOnAfterSetFilterServContractLine(Rec, ServContractLine);

                        if not ServContractLine.FindFirst() then
                            Error(Text050, ServHeader."Contract No.", "Service Item No.");
                        IsHandled := false;
                        OnValidateServiceItemNoOnBeforeValidateServicePeriod(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            ServContractLine.ValidateServicePeriod(ServHeader."Order Date");
                        IsHandled := false;
                        OnBeforeSetServContractExistTrue(ServContractLine, ServHeader, IsHandled);
                        if not IsHandled then
                            ServContractExist := true;
                    end;

                    ShouldFindServContractLine := ServHeader."Contract No." = '';
                    OnValidateServiceItemNoOnBeforeEmptyContractNoFindServContractLine(Rec, ServHeader, ServItem, ShouldFindServContractLine, ServContractExist, ServContractLine);

                    if ShouldFindServContractLine then begin
                        ServContractLine.Reset();
                        ServContractLine.FilterGroup(2);
                        ServContractLine.SetCurrentKey("Service Item No.", "Contract Status");
                        ServContractLine.SetRange("Service Item No.", ServItem."No.");
                        ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                        ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                        ServContractLine.SetRange("Customer No.", ServHeader."Customer No.");
                        ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                        ServContractLine.SetFilter("Contract Expiration Date", '>=%1 | =%2', ServHeader."Order Date", 0D);
                        ServContractLine.FilterGroup(0);

                        if ServContractLine.Find('-') then
                            if ServContractLine.Next() > 0 then begin
                                if ConfirmManagement.GetResponse(
                                     StrSubstNo(Text047, "Service Item No."), true)
                                then begin
                                    ServContractList.SetTableView(ServContractLine);
                                    ServContractList.LookupMode(true);
                                    if ServContractList.RunModal() = ACTION::LookupOK then begin
                                        ServContractList.GetRecord(ServContractLine);
                                        ServContractExist := true;
                                    end;
                                end;
                            end else begin
                                ServContractLine.FindFirst();
                                ServContractExist := true;
                            end;
                    end;

                    IsHandled := false;
                    OnBeforeCheckShipToCode(Rec, ServItem, ServHeader, IsHandled);
                    if not IsHandled then
                        if (ServItem."Ship-to Code" <> ServHeader."Ship-to Code") and not HideDialogBox then
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(
                                   Text040, ServItem.TableCaption(),
                                   FieldCaption("Ship-to Code"), Cust.TableCaption()), true)
                            then begin
                                "Service Item No." := xRec."Service Item No.";
                                exit;
                            end;
                    "Ship-to Code" := ServItem."Ship-to Code";
                    SetServItemInfo(ServItem);

                    IsHandled := false;
                    OnValidateServiceItemNoOnBeforeCheckServContractExist(ServContractLine, ServItem, ServHeader, ServContractExist, Rec, IsHandled);
                    if not IsHandled then
                        if ServContractExist then
                            Validate("Contract No.", ServContractLine."Contract No.")
                        else
                            Validate("Contract No.", '');

                    if "Contract No." = '' then
                        Validate("Service Price Group Code", ServItem."Service Price Group Code");
                    Validate("Service Item Group Code", ServItem."Service Item Group Code");
                    OnValidateServiceItemNoOnAfterValidateServiceItemGroupCode(Rec);
                end;

                if ServItemLine.Get("Document Type", "Document No.", "Line No.") then begin
                    UseServItemLineAsxRec := true;
                    Modify(true);
                end;

                if Rec."Repair Status Code" <> '' then
                    Validate("Repair Status Code", Rec."Repair Status Code");

                OnAfterValidateServiceItemNoOnBeforeUpdateResponseTimeHours(Rec, xRec);
                UpdateResponseTimeHours();
                CreateDimFromDefaultDim(0);
            end;
        }
        field(4; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group".Code;

            trigger OnValidate()
            begin
                if "Service Item Group Code" <> xRec."Service Item Group Code" then begin
                    if "Service Item No." <> '' then begin
                        ServItem.Get("Service Item No.");
                        TestField("Service Item Group Code", ServItem."Service Item Group Code");
                    end;
                    if ServItemGr.Get("Service Item Group Code") then begin
                        if ("Item No." = '') and (Description = '') then
                            Description := ServItemGr.Description;
                        if ServItem."Service Price Group Code" = '' then
                            if "Contract No." = '' then
                                Validate("Service Price Group Code", ServItemGr."Default Serv. Price Group Code");
                    end;
                end;
                UpdateResponseTimeHours();

                CreateDimFromDefaultDim(Rec.FieldNo("Service Item Group Code"));
            end;
        }
        field(5; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = if ("Document Type" = filter(<> "Credit Memo")) Item."No." where(Blocked = const(false), "Service Blocked" = const(false))
            else
            if ("Document Type" = filter("Credit Memo")) Item."No." where(Blocked = const(false));

            trigger OnValidate()
            begin
                if "Service Item No." <> '' then
                    Error(Text016,
                      FieldCaption("Item No."), FieldCaption("Service Item No."));

                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                if "Item No." <> '' then begin
                    Item.Get("Item No.");
                    Validate("Service Item Group Code", Item."Service Item Group");
                    GetServHeader();
                    if (ServHeader."Language Code" = '') or not GetItemTranslation() then begin
                        Description := Item.Description;
                        "Description 2" := Item."Description 2";
                    end;
                    OnAfterAssignItemValues(Rec, xRec, Item, ServHeader, CurrFieldNo);
                end else begin
                    Description := '';
                    "Description 2" := '';
                end;
                UpdateResponseTimeHours();
            end;
        }
        field(6; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSerialNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Serial No." <> xRec."Serial No." then
                    if "Service Item No." <> '' then
                        Error(
                          Text016,
                          FieldCaption("Serial No."), FieldCaption("Service Item No."));
                UpdateResponseTimeHours();

                if "Serial No." = '' then
                    exit;

                GetServHeader();
                ServItem.Reset();
                ServItem.SetCurrentKey("Customer No.", "Ship-to Code", "Item No.", "Serial No.");
                ServItem.SetRange("Customer No.", ServHeader."Customer No.");
                ServItem.SetRange("Ship-to Code", ServHeader."Ship-to Code");
                ServItem.SetRange("Item No.", "Item No.");
                ServItem.SetRange("Serial No.", "Serial No.");
                NoOfRec := ServItem.Count();
                case true of
                    NoOfRec = 1:
                        begin
                            ServItem.FindFirst();
                            Validate("Service Item No.", ServItem."No.");
                        end;
                    NoOfRec > 1:
                        if PAGE.RunModal(0, ServItem) = ACTION::LookupOK then
                            Validate("Service Item No.", ServItem."No.");
                end;
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                UpdateResponseTimeHours();
                Validate("Document No.");
            end;
        }
        field(8; "Description 2"; Text[50])
        {
            Caption = 'Description 2';

            trigger OnValidate()
            begin
                UpdateResponseTimeHours();
            end;
        }
        field(9; "Repair Status Code"; Code[10])
        {
            Caption = 'Repair Status Code';
            TableRelation = "Repair Status";

            trigger OnValidate()
            var
                RepairStatusInProgress: Boolean;
                IsHandled: Boolean;
            begin
                UpdateResponseTimeHours();
                if "Repair Status Code" <> '' then begin
                    RepairStatus.Get("Repair Status Code");
                    if RepairStatus2.Get(xRec."Repair Status Code") then
                        if (not RepairStatus.Finished and RepairStatus2.Finished) or
                           (not RepairStatus."Quote Finished" and RepairStatus2."Quote Finished")
                        then begin
                            "Finishing Date" := 0D;
                            "Finishing Time" := 0T;
                        end;

                    if ("Document Type" = "Document Type"::Order) and
                       RepairStatus."Quote Finished"
                    then
                        Error(Text035, RepairStatus.TableCaption(), RepairStatus.Code);

                    if ("Document Type" = "Document Type"::Quote) and
                       RepairStatus.Finished
                    then
                        Error(Text036, RepairStatus.TableCaption(), RepairStatus.Code);
                    if RepairStatus.Initial then begin
                        "Starting Date" := 0D;
                        "Starting Time" := 0T;
                        "Finishing Date" := 0D;
                        "Finishing Time" := 0T;
                        UpdateStartFinishDateTime(
                            "Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                            "Finishing Date", "Finishing Time", false);
                        IsHandled := false;
                        OnValidateRepairStatusCodeInitialOnBeforeServOrderAllocModify(Rec, IsHandled);
                        if not IsHandled then begin
                            ServOrderAlloc.SetFilters(Rec);
                            ServOrderAlloc.ModifyAll("Service Started", false, false);
                        end;
                    end;

                    RepairStatusInProgress := RepairStatus."In Process";
                    OnRepairStatusCodeValidateOnAfterSetRepairStatusInProgress(Rec, RepairStatusInProgress);
                    if RepairStatusInProgress then begin
                        GetServHeader();
                        IsHandled := false;
                        OnValidateRepairStatusCodeOnBeforeCheckOrderDateRepairStatusInProgress(ServOrderAlloc, Rec, IsHandled);
                        if not IsHandled then
                            if ServHeader."Order Date" > WorkDate() then begin
                                "Starting Date" := ServHeader."Order Date";
                                Validate("Starting Time", ServHeader."Order Time");
                            end else begin
                                "Starting Date" := WorkDate();
                                if (ServHeader."Order Date" = "Starting Date") and (ServHeader."Order Time" > Time) then
                                    Validate("Starting Time", ServHeader."Order Time")
                                else
                                    Validate("Starting Time", Time);
                            end;
                        IsHandled := false;
                        OnValidateRepairStatusCodeInProgressOnBeforeServOrderAllocModify(Rec, IsHandled);
                        if not IsHandled then begin
                            ServOrderAlloc.SetFilters(Rec);
                            ServOrderAlloc.ModifyAll("Service Started", true, false);
                        end;
                    end;

                    if RepairStatus.Finished then begin
                        ServMgtSetup.Get();
                        if ServMgtSetup."Fault Reason Code Mandatory" then
                            TestField("Fault Reason Code");
                        GetServHeader();
                        IsHandled := false;
                        OnValidateRepairStatusCodeFinishedOnBeforeServOrderAllocModify(Rec, IsHandled);
                        if not IsHandled then begin
                            CalculateDates();
                            ServOrderAlloc.SetFilters(Rec);
                            ServOrderAlloc.ModifyAll(Status, ServOrderAlloc.Status::Finished, false);
                        end;
                    end;

                    if RepairStatus."Quote Finished" then begin
                        GetServHeader();
                        CalculateDates();
                    end;

                    if RepairStatus."Partly Serviced" or RepairStatus.Referred then begin
                        ServOrderAlloc.SetFilters(Rec);
                        if ServOrderAlloc.Find('-') then
                            repeat
                                if RepairStatus.Referred and RepairStatus2.Initial then
                                    ServOrderAlloc."Service Started" := false;
                                ServOrderAlloc.Status := ServOrderAlloc.Status::"Reallocation Needed";
                                ServOrderAlloc."Reason Code" := '';
                                ServOrderAlloc.Modify();
                            until ServOrderAlloc.Next() = 0;
                    end;

                    RepairStatusPriority := RepairStatus.Priority;
                    UseLineNo := "Line No.";
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "Document No.");
                    ServItemLine.SetFilter("Line No.", '<>%1', "Line No.");
                    ServItemLine.SetFilter("Repair Status Code", '<>%1', '');
                    if ServItemLine.Find('-') then
                        repeat
                            RepairStatus2.Get(ServItemLine."Repair Status Code");
                            if RepairStatus2.Priority < RepairStatusPriority then begin
                                RepairStatusPriority := RepairStatus2.Priority;
                                UseLineNo := ServItemLine."Line No.";
                            end;
                        until ServItemLine.Next() = 0;
                    if "Line No." <> UseLineNo then begin
                        ServItemLine.Get("Document Type", "Document No.", UseLineNo);
                        RepairStatus.Get(ServItemLine."Repair Status Code");
                    end else
                        RepairStatus.Get("Repair Status Code");
                    ServHeader2.Get(Rec."Document Type", Rec."Document No.");
                    ServHeader3 := ServHeader2;
                    if ServHeader2.Status <> RepairStatus."Service Order Status" then begin
                        ServHeader2.SetValidatingFromLines(true);
                        if ServHeader2."Finishing Date" = 0D then
                            ServHeader2.Validate("Finishing Date", "Finishing Date");

                        OnValidateRepairStatusCodeOnBeforeValidateStatus(Rec, ServHeader2);

                        ServHeader2.Validate(Status, RepairStatus."Service Order Status");
                        if not (ServHeader2.Status = ServHeader2.Status::Finished) then begin
                            ServHeader2."Finishing Date" := 0D;
                            ServHeader2."Finishing Time" := 0T;
                            ServHeader2."Service Time (Hours)" := 0;
                        end;
                        ServHeader2.UpdateServiceOrderChangeLog(ServHeader3);
                        ServHeader2.Modify();
                        if ServHeader2.Status = ServHeader2.Status::Finished then
                            UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                              "Finishing Date", "Finishing Time", false);
                    end;
                end;
            end;
        }
        field(10; Priority; Enum "Service Priority")
        {
            Caption = 'Priority';
        }
        field(11; "Response Time (Hours)"; Decimal)
        {
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if ("Response Time (Hours)" <> xRec."Response Time (Hours)") or ("Response Time (Hours)" = 0) then begin
                    SkipResponseTimeHrsUpdate := true;
                    GetServHeader();
                    CalculateResponseDateTime(ServHeader."Order Date", ServHeader."Order Time");
                end else
                    UpdateResponseTimeHours();
            end;
        }
        field(12; "Response Date"; Date)
        {
            Caption = 'Response Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                SkipResponseTimeHrsUpdate := true;
                if "Response Date" <> xRec."Response Date" then begin
                    GetServHeader();
                    IsHandled := false;
                    OnValidateResponseDateOnBeforeCheckResponseDate(Rec, IsHandled);
                    if not IsHandled then
                        if "Response Date" <> 0D then begin
                            if "Response Date" < ServHeader."Order Date" then
                                Error(
                                    Text022,
                                    FieldCaption("Response Date"), ServHeader.TableCaption(),
                                    ServHeader.FieldCaption("Order Date"));
                            if "Response Date" = ServHeader."Order Date" then
                                if Time < ServHeader."Order Time" then
                                    "Response Time" := ServHeader."Order Time"
                                else
                                    "Response Time" := Time;
                        end else
                            "Response Time" := 0T;

                    "Response Time (Hours)" := 0;
                end;
            end;
        }
        field(13; "Response Time"; Time)
        {
            Caption = 'Response Time';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                SkipResponseTimeHrsUpdate := true;
                if "Response Time" <> xRec."Response Time" then begin
                    GetServHeader();
                    IsHandled := false;
                    OnValidateResponseTimeOnBeforeCheckResponseTime(Rec, IsHandled);
                    if not IsHandled then
                        if ("Response Date" = ServHeader."Order Date") and ("Response Time" < ServHeader."Order Time") then
                            Error(
                                Text022,
                                FieldCaption("Response Time"), ServHeader.TableCaption(),
                                ServHeader.FieldCaption("Order Time"));

                    "Response Time (Hours)" := 0;
                end;
            end;
        }
        field(14; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                SkipResponseTimeHrsUpdate := true;
                GetServHeader();
                if "Starting Date" <> 0D then begin
                    IsHandled := false;
                    OnValidateStartingDateOnBeforeCheckIfLessThanOrderDate(Rec, IsHandled);
                    if not IsHandled then
                        if "Starting Date" < ServHeader."Order Date" then
                            Error(
                                Text022,
                                FieldCaption("Starting Date"), ServHeader.TableCaption(),
                                ServHeader.FieldCaption("Order Date"));

                    if ("Starting Date" > ServHeader."Finishing Date") and
                       (ServHeader."Finishing Date" <> 0D)
                    then
                        Error(
                          Text018,
                          FieldCaption("Starting Date"),
                          ServHeader.TableCaption(),
                          ServHeader.FieldCaption("Finishing Date"));

                    if "Starting Date" <> xRec."Starting Date" then begin
                        "Finishing Date" := 0D;
                        "Finishing Time" := 0T;
                    end;

                    IsHandled := false;
                    OnValidateStartingDateOnBeforeValidateStartingTime(Rec, IsHandled);
                    if not IsHandled then
                        if ("Starting Date" = ServHeader."Order Date") and (Time < ServHeader."Order Time") then
                            Validate("Starting Time", ServHeader."Order Time")
                        else
                            Validate("Starting Time", Time);
                end else begin
                    "Starting Time" := 0T;
                    Validate("Finishing Date", 0D);
                end;
            end;
        }
        field(15; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            begin
                SkipResponseTimeHrsUpdate := true;
                TestField("Starting Date");
                if "Starting Time" <> 0T then begin
                    GetServHeader();
                    EnsureCorrectStartingFinishingTimes();

                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date",
                      "Starting Time", "Finishing Date", "Finishing Time", false);
                end else begin
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(16; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                SkipResponseTimeHrsUpdate := true;
                GetServHeader();
                if "Finishing Date" <> 0D then begin
                    if "Finishing Date" < ServHeader."Order Date" then begin
                        IsHandled := false;
                        OnValidateFinishingDateOnBeforeCheckIfLessThanOrderDate(Rec, IsHandled);
                        if not IsHandled then
                            Error(
                                Text022,
                                FieldCaption("Finishing Date"), ServHeader.TableCaption(),
                                ServHeader.FieldCaption("Order Date"));
                    end;
                    if "Finishing Date" < "Starting Date" then
                        Error(
                          Text019,
                          FieldCaption("Finishing Date"), FieldCaption("Starting Date"));

                    IsHandled := false;
                    OnValidateFinishingDateOnBeforeValidateFinishingTime(Rec, IsHandled);
                    if not IsHandled then
                        if ("Starting Date" = "Finishing Date") and ("Starting Time" > Time) then
                            Validate("Finishing Time", "Starting Time")
                        else
                            Validate("Finishing Time", Time);
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end else begin
                    "Finishing Time" := 0T;
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(17; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                SkipResponseTimeHrsUpdate := true;
                TestField("Finishing Date");
                GetServHeader();
                if "Finishing Time" <> 0T then begin
                    IsHandled := false;
                    OnBeforeCheckFinishingTime(Rec, IsHandled);
                    if not IsHandled then
                        if ("Finishing Date" = "Starting Date") and ("Finishing Time" < "Starting Time") then
                            Error(Text022, FieldCaption("Finishing Time"), FieldCaption("Starting Time"));
                    UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", "Starting Date", "Starting Time",
                      "Finishing Date", "Finishing Time", false);
                end;
            end;
        }
        field(18; "Service Shelf No."; Code[10])
        {
            Caption = 'Service Shelf No.';
            TableRelation = "Service Shelf";
        }
        field(19; "Warranty Starting Date (Parts)"; Date)
        {
            Caption = 'Warranty Starting Date (Parts)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyStartingDateParts(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Starting Date (Parts)" <> ServItem."Warranty Starting Date (Parts)" then
                        Error(Text023, ServItem.TableCaption());
                end;

                if "Warranty Starting Date (Parts)" <> 0D then begin
                    ServMgtSetup.Get();
                    "Warranty Ending Date (Parts)" := CalcDate(ServMgtSetup."Default Warranty Duration", "Warranty Starting Date (Parts)");
                    "Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
                end else begin
                    "Warranty Ending Date (Parts)" := 0D;
                    "Warranty % (Parts)" := 0;
                end;
            end;
        }
        field(20; "Warranty Ending Date (Parts)"; Date)
        {
            Caption = 'Warranty Ending Date (Parts)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyEndingDateParts(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Ending Date (Parts)" <> ServItem."Warranty Ending Date (Parts)" then
                        Error(Text023, ServItem.TableCaption());
                end;
            end;
        }
        field(21; Warranty; Boolean)
        {
            Caption = 'Warranty';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarranty(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." = '' then begin
                    GetServHeader();
                    if Warranty then begin
                        if ConfirmManagement.GetResponseOrDefault(Text024, true) then begin
                            Validate("Warranty Starting Date (Parts)", ServHeader."Order Date");
                            Validate("Warranty Starting Date (Labor)", ServHeader."Order Date");
                            Warranty := true;
                        end else
                            Warranty := false;
                    end else
                        if ConfirmManagement.GetResponseOrDefault(Text025, true) then begin
                            Validate("Warranty Starting Date (Parts)", 0D);
                            Validate("Warranty Starting Date (Labor)", 0D);
                            Warranty := false;
                        end else
                            Warranty := true;
                    if ServItemLine.Get("Document Type", "Document No.", "Line No.") then
                        Modify();
                    CheckWarranty(ServHeader."Order Date");
                end else
                    Error(Text023, ServItem.TableCaption());
            end;
        }
        field(22; "Warranty % (Parts)"; Decimal)
        {
            Caption = 'Warranty % (Parts)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyParts(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then
                    Error(Text023, ServItem.TableCaption());

                if ("Service Item No." = '') and ("Warranty % (Parts)" <> xRec."Warranty % (Parts)") then begin
                    ServLine.Reset();
                    ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "Document No.");
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetRange(Type, ServLine.Type::Item);
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Validate("Warranty Disc. %", "Warranty % (Parts)");
                            ServLine.Modify();
                        until ServLine.Next() = 0;
                end;
            end;
        }
        field(23; "Warranty % (Labor)"; Decimal)
        {
            Caption = 'Warranty % (Labor)';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyLabor(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then
                    Error(Text023, ServItem.TableCaption());

                if ("Service Item No." = '') and ("Warranty % (Labor)" <> xRec."Warranty % (Labor)") then begin
                    ServLine.Reset();
                    ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "Document No.");
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetRange(Type, ServLine.Type::Resource);
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Validate("Warranty Disc. %", "Warranty % (Labor)");
                            ServLine.Modify();
                        until ServLine.Next() = 0;
                end;
            end;
        }
        field(24; "Warranty Starting Date (Labor)"; Date)
        {
            Caption = 'Warranty Starting Date (Labor)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyStartingDateLabor(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Starting Date (Labor)" <> ServItem."Warranty Starting Date (Labor)" then
                        Error(Text023, ServItem.TableCaption());
                end;

                if "Warranty Starting Date (Labor)" <> 0D then begin
                    ServMgtSetup.Get();
                    "Warranty Ending Date (Labor)" := CalcDate(ServMgtSetup."Default Warranty Duration", "Warranty Starting Date (Labor)");
                    "Warranty % (Parts)" := ServMgtSetup."Warranty Disc. % (Parts)";
                    "Warranty % (Labor)" := ServMgtSetup."Warranty Disc. % (Labor)";
                end else begin
                    "Warranty Ending Date (Labor)" := 0D;
                    "Warranty % (Labor)" := 0;
                end;
            end;
        }
        field(25; "Warranty Ending Date (Labor)"; Date)
        {
            Caption = 'Warranty Ending Date (Labor)';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWarrantyEndingDateLabor(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Service Item No." <> '' then begin
                    ServItem.Get("Service Item No.");
                    if "Warranty Ending Date (Labor)" <> ServItem."Warranty Ending Date (Labor)" then
                        Error(Text023, ServItem.TableCaption());
                end;
            end;
        }
        field(26; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));

            trigger OnLookup()
            var
                ServHeader: Record "Service Header";
                ServContractLine: Record "Service Contract Line";
                ServContractList: Page "Serv. Contr. List (Serv. Item)";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateContractNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ServHeader.Get(Rec."Document Type", Rec."Document No.");
                if "Contract No." <> '' then begin
                    ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    if ServContractLine.FindFirst() then
                        ServContractList.SetRecord(ServContractLine);
                    ServContractLine.Reset();
                end;
                ServContractLine.FilterGroup(2);
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Customer No.", ServHeader."Customer No.");
                ServContractLine.SetRange("Service Item No.", "Service Item No.");
                ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                ServContractLine.SetFilter("Contract Expiration Date", '>=%1 | =%2', ServHeader."Order Date", 0D);
                ServContractLine.FilterGroup(0);
                OnLookupContractNoOnAfterServContractLineSetFilters(ServContractLine, Rec);
                ServContractList.SetTableView(ServContractLine);
                ServContractList.LookupMode(true);
                if ServContractList.RunModal() = ACTION::LookupOK then begin
                    ServContractList.GetRecord(ServContractLine);
                    Validate("Contract No.", ServContractLine."Contract No.");
                end;
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                ServHeader.Get(Rec."Document Type", Rec."Document No.");
                if (ServHeader."Contract No." <> '') and
                   ("Contract No." <> ServHeader."Contract No.")
                then
                    Error(Text048, FieldCaption("Contract No."));

                if ("Service Price Group Code" <> '') and ("Contract No." <> '') then
                    Error(Text033);

                ServLine.Reset();
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                if "Line No." <> 0 then begin
                    ServLine.SetRange("Service Item Line No.", "Line No.");
                    ServLine.SetFilter("Quantity Invoiced", '>0');
                    if ServLine.Find('-') then
                        Error(Text053);
                end;

                if "Contract No." <> '' then begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("Service Item No.", "Service Item No.");
                    OnValidateContractNoOnBeforeFindServiceContractLine(ServContractLine, Rec);
                    if not ServContractLine.FindFirst() then
                        Error(Text049, "Contract No.", "Service Item No.");
                    if ServContractLine."Customer No." <> ServHeader."Customer No." then
                        Error(Text051, "Contract No.");

                    IsHandled := false;
                    OnValidateContractNoOnBeforeCheckCOntractStatusSigned(ServContractLine, IsHandled);
                    if not IsHandled then
                        if ServContractLine."Contract Status" <> ServContractLine."Contract Status"::Signed then
                            Error(Text052, "Contract No.");
                    ServHeader.TestField("Order Date");
                    IsHandled := false;
                    OnValidateContractNoOnBeforeValidateServicePeriod(Rec, xRec, CurrFieldNo, IsHandled, ServHeader);
                    if not IsHandled then
                        ServContractLine.ValidateServicePeriod(ServHeader."Order Date");
                    "Contract Line No." := ServContractLine."Line No.";
                end else
                    "Contract Line No." := 0;
                ServLine.SetRange("Quantity Invoiced", 0);

                CheckRecreateServLines();
                UpdateResponseTimeHours();
            end;
        }
        field(27; "Location of Service Item"; Text[30])
        {
            CalcFormula = lookup("Service Item"."Location of Service Item" where("No." = field("Service Item No.")));
            Caption = 'Location of Service Item';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Loaner No."; Code[20])
        {
            Caption = 'Loaner No.';
            TableRelation = Loaner."No.";

            trigger OnValidate()
            var
                LoanerEntry: Record "Loaner Entry";
            begin
                if ("Loaner No." = '') and (xRec."Loaner No." <> '') then begin
                    Loaner.Get(xRec."Loaner No.");
                    LoanerEntry.SetRange("Document Type", LoanerEntry.GetDocTypeFromServDocType("Document Type"));
                    LoanerEntry.SetRange("Document No.", "Document No.");
                    LoanerEntry.SetRange("Loaner No.", xRec."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty() then
                        Error(
                          Text026,
                          FieldCaption("Loaner No."))
                end;

                if "Loaner No." <> xRec."Loaner No." then begin
                    LoanerEntry.Reset();
                    LoanerEntry.SetRange("Document Type", LoanerEntry.GetDocTypeFromServDocType("Document Type"));
                    LoanerEntry.SetRange("Document No.", "Document No.");
                    LoanerEntry.SetRange("Loaner No.", xRec."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty() then begin
                        GetServHeader();
                        Error(
                          Text028,
                          FieldCaption("Loaner No."), Format(ServHeader."Document Type"),
                          ServHeader.FieldCaption("No."), ServHeader."No.");
                    end;

                    CheckIfLoanerOnServOrder();
                    if Rec."Line No." <> 0 then
                        LendLoanerWithConfirmation(false);
                end;
            end;
        }
        field(29; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(30; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(31; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            TableRelation = "Fault Reason Code";

            trigger OnValidate()
            begin
                ServLine.Reset();
                ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                ServLine.SetRange("Service Item Line No.", "Line No.");
                SetFilterForType();
                if ServLine.Find('-') then
                    repeat
                        ServLine.SetCalledFromServiceItemLine(true);
                        ServLine.Validate("Fault Reason Code", "Fault Reason Code");
                        ServLine.Modify();
                    until ServLine.Next() = 0;
            end;
        }
        field(32; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            TableRelation = "Service Price Group";

            trigger OnValidate()
            var
                ServPriceGrSetup: Record "Serv. Price Group Setup";
                ServPriceMgmt: Codeunit "Service Price Management";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateServicePriceGroupCode(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                GetServHeader();
                if ("Service Price Group Code" <> '') and
                   (("Contract No." <> '') or (ServHeader."Contract No." <> ''))
                then
                    Error(Text033);

                ServLine.Reset();
                ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "Document No.");
                ServLine.SetRange("Service Item Line No.", "Line No.");

                if "Service Price Group Code" <> xRec."Service Price Group Code" then begin
                    ServLine.SetFilter("Quantity Invoiced", '>0');
                    if ServLine.Find('-') then
                        Error(Text037, FieldCaption("Service Price Group Code"));
                end;

                if CurrFieldNo = FieldNo("Service Price Group Code") then
                    if CheckServLineExist() then begin
                        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::Adjusted);
                        if ServLine.Find('-') then begin
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text038, ServLine.TableCaption()), true)
                            then
                                Error(Text039);
                            ServPriceMgmt.ResetAdjustedLines(ServLine);
                        end;
                        ServLine.SetRange("Price Adjmt. Status");
                    end;

                if "Service Price Group Code" <> '' then begin
                    ServPriceMgmt.GetServPriceGrSetup(ServPriceGrSetup, ServHeader, Rec);
                    "Serv. Price Adjmt. Gr. Code" := ServPriceGrSetup."Serv. Price Adjmt. Gr. Code";
                    "Adjustment Type" := ServPriceGrSetup."Adjustment Type";
                    "Base Amount to Adjust" := ServPriceGrSetup.Amount;
                end else begin
                    "Serv. Price Adjmt. Gr. Code" := '';
                    Clear("Adjustment Type");
                    "Base Amount to Adjust" := 0;
                end;

                if ServLine.Find('-') then
                    repeat
                        ServLine."Service Price Group Code" := "Service Price Group Code";
                        ServLine."Serv. Price Adjmt. Gr. Code" := "Serv. Price Adjmt. Gr. Code";
                        ServLine.Modify();
                    until ServLine.Next() = 0;
            end;
        }
        field(33; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";

            trigger OnValidate()
            var
                ServPriceMgmt: Codeunit "Service Price Management";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if (CurrFieldNo = FieldNo("Fault Area Code")) and
                   ("Fault Area Code" <> xRec."Fault Area Code")
                then begin
                    if CheckServLineExist() and ("Service Price Group Code" <> '') then begin
                        ServLine.Reset();
                        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "Document No.");
                        ServLine.SetRange("Service Item Line No.", "Line No.");
                        ServLine.SetRange("Price Adjmt. Status", ServLine."Price Adjmt. Status"::Adjusted);
                        if ServLine.Find('-') then begin
                            if not ConfirmManagement.GetResponseOrDefault(
                                 StrSubstNo(Text038, ServLine.TableCaption()), true)
                            then
                                Error(Text039);
                            ServPriceMgmt.ResetAdjustedLines(ServLine);
                        end;
                    end;
                    Validate("Service Price Group Code");
                    "Fault Code" := '';
                end;
            end;
        }
        field(34; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code";

            trigger OnValidate()
            begin
                if "Symptom Code" <> xRec."Symptom Code" then
                    "Fault Code" := '';
            end;
        }
        field(35; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(36; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            TableRelation = "Resolution Code";
        }
        field(37; "Fault Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Header"),
                                                              "Table Subtype" = field("Document Type"),
                                                              "No." = field("Document No."),
                                                              Type = const(Fault),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Fault Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Resolution Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Header"),
                                                              "Table Subtype" = field("Document Type"),
                                                              "No." = field("Document No."),
                                                              Type = const(Resolution),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Resolution Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if ("Document Type" = filter(<> "Credit Memo")) "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false), "Service Blocked" = const(false))
            else
            if ("Document Type" = filter("Credit Memo")) "Item Variant".Code where("Item No." = field("Item No."), Blocked = const(false));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Service Item No." <> '' then
                    Error(
                      Text016,
                      FieldCaption("Variant Code"), FieldCaption("Service Item No."));

                if Rec."Variant Code" = xRec."Variant Code" then
                    exit;

                if Rec."Variant Code" <> '' then begin
                    ItemVariant.SetLoadFields(Description, "Description 2");
                    ItemVariant.Get(Rec."Item No.", Rec."Variant Code");
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end;
            end;
        }
        field(41; "Service Item Loaner Comment"; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Header"),
                                                              "Table Subtype" = field("Document Type"),
                                                              "No." = field("Document No."),
                                                              Type = const("Service Item Loaner"),
                                                              "Table Line No." = field("Line No.")));
            Caption = 'Service Item Loaner Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(43; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(44; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            Editable = false;
            TableRelation = "Service Price Adjustment Group";
        }
        field(45; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            Editable = false;
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(46; "Base Amount to Adjust"; Decimal)
        {
            Caption = 'Base Amount to Adjust';
            Editable = false;
        }
        field(60; "No. of Active/Finished Allocs"; Integer)
        {
            CalcFormula = count("Service Order Allocation" where("Document Type" = field("Document Type"),
                                                                  "Document No." = field("Document No."),
                                                                  "Service Item Line No." = field("Line No."),
                                                                  "Resource No." = field("Resource Filter"),
                                                                  "Resource Group No." = field("Resource Group Filter"),
                                                                  "Allocation Date" = field("Allocation Date Filter"),
                                                                  Status = filter(Active | Finished)));
            Caption = 'No. of Active/Finished Allocs';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "No. of Allocations"; Integer)
        {
            CalcFormula = count("Service Order Allocation" where(Status = field("Allocation Status Filter"),
                                                                  "Resource No." = field("Resource Filter"),
                                                                  "Resource Group No." = field("Resource Group Filter"),
                                                                  "Document Type" = field("Document Type"),
                                                                  "Document No." = field("Document No."),
                                                                  "Service Item Line No." = field("Line No.")));
            Caption = 'No. of Allocations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "No. of Previous Services"; Integer)
        {
            CalcFormula = count("Service Shipment Item Line" where("Item No." = field("Item No."),
                                                                    "Serial No." = field("Serial No.")));
            Caption = 'No. of Previous Services';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Contract Line No."; Integer)
        {
            Caption = 'Contract Line No.';
            TableRelation = "Service Contract Line"."Line No." where("Contract Type" = const(Contract),
                                                                      "Contract No." = field("Contract No."));
        }
        field(64; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            Editable = false;
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(65; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            Editable = false;
            TableRelation = Customer."No.";
        }
        field(91; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(92; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(93; "Allocation Date Filter"; Date)
        {
            Caption = 'Allocation Date Filter';
            FieldClass = FlowFilter;
        }
        field(94; "Repair Status Code Filter"; Code[10])
        {
            Caption = 'Repair Status Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Repair Status".Code;
        }
        field(96; "Allocation Status Filter"; Option)
        {
            Caption = 'Allocation Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Nonactive,Active,Finished,Canceled,Reallocation Needed';
            OptionMembers = Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        }
        field(97; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            Editable = false;
            TableRelation = "Responsibility Center";
        }
        field(98; "Service Order Filter"; Code[20])
        {
            Caption = 'Service Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Header"."No.";
        }
        field(99; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(100; "Shortcut Dimension 1 Code"; Code[20])
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
        field(101; "Shortcut Dimension 2 Code"; Code[20])
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
        field(130; "Release Status"; Enum "Service Doc. Release Status")
        {
            Caption = 'Release Status';
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
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Line No.", "Document Type")
        {
        }
        key(Key3; "Document Type", "Document No.", "Service Item No.", "Contract No.", "Contract Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Service Item No.")
        {
        }
        key(Key5; "Document Type", "Document No.", "Response Date", "Response Time")
        {
        }
        key(Key6; "Response Date", "Response Time", Priority)
        {
        }
        key(Key7; "Loaner No.")
        {
        }
        key(Key8; "Document Type", "Document No.", "Starting Date", "Starting Time")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Document Type", "Document No.", "Finishing Date", "Finishing Time")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Fault Reason Code")
        {
        }
        key(Key11; "Contract No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Service Item No.", Description, "Serial No.")
        {
        }
        fieldgroup(Brick; "Item No.", Description, "Service Item No.", "Serial No.", "Repair Status Code")
        { }
    }

    trigger OnDelete()
    var
        LoanerEntry: Record "Loaner Entry";
    begin
        if "Loaner No." <> '' then begin
            Loaner.Get("Loaner No.");
            LoanerEntry.SetRange("Document Type", LoanerEntry.GetDocTypeFromServDocType("Document Type"));
            LoanerEntry.SetRange("Document No.", "Document No.");
            LoanerEntry.SetRange("Loaner No.", "Loaner No.");
            LoanerEntry.SetRange(Lent, true);
            if not LoanerEntry.IsEmpty() then
                Error(
                  Text006,
                  TableCaption, "Document No.", "Line No.", FieldCaption("Loaner No."), "Loaner No.");
            LoanerEntry.SetRange(Lent, true);
            LoanerEntry.DeleteAll();
        end;

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        if ServLine.Find('-') then
            Error(
              Text008,
              TableCaption, "Document No.", "Line No.", ServLine.TableCaption());

        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServOrderAlloc.SetRange("Document Type", "Document Type");
        ServOrderAlloc.SetRange("Document No.", "Document No.");
        ServOrderAlloc.SetRange("Service Item Line No.", "Line No.");
        ServOrderAlloc.SetFilter(Status, '%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::Finished);
        if ServOrderAlloc.Find('-') then
            Error(
              Text008,
              TableCaption, "Document No.", "Line No.", ServOrderAlloc.TableCaption());
        ServOrderAlloc.SetRange(Status);
        ServOrderAlloc.DeleteAll();

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "Document No.");
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        ServCommentLine.DeleteAll();

        Clear(ServLogMgt);
        ServLogMgt.ServItemOffServOrder(Rec);

        ServOrderMgt.UpdateResponseDateTime(Rec, true);
        UpdateStartFinishDateTime("Document Type", "Document No.", "Line No.", CalcDate('<CY+1D-1Y>', WorkDate()), 0T, 0D, 0T, true);
        ServOrderMgt.UpdatePriority(Rec, true);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertOnBeforeCheckFirstServItemLine(Rec, IsHandled);
        if not IsHandled then begin
            ServMgtSetup.Get();
            ServItemLine.Reset();
            ServItemLine.SetRange("Document Type", "Document Type");
            ServItemLine.SetRange("Document No.", "Document No.");
            FirstServItemLine := not ServItemLine.Find('-');
            if ServMgtSetup."One Service Item Line/Order" then
                if not FirstServItemLine then
                    Error(Text000, ServMgtSetup.TableCaption(), ServItemLine.TableCaption(), ServHeader.TableCaption());
        end;

        GetServHeader();
        OnInsertOnAfterGetServHeader(Rec, ServHeader);
        CheckCustomerNo();

        "Responsibility Center" := ServHeader."Responsibility Center";
        "Customer No." := ServHeader."Customer No.";
        IsHandled := false;
        OnInsertOnBeforeSetContractNo(Rec, ServHeader, IsHandled);
        if not IsHandled then
            if ServHeader."Contract No." <> '' then
                if "Service Item No." = '' then
                    "Contract No." := ServHeader."Contract No."
                else begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                    ServContractLine.SetRange("Contract No.", ServHeader."Contract No.");
                    ServContractLine.SetRange("Service Item No.", "Service Item No.");
                    ServContractLine.SetRange("Contract Status", ServContractLine."Contract Status"::Signed);
                    ServContractLine.SetFilter("Starting Date", '<=%1', ServHeader."Order Date");
                    ServContractLine.SetFilter("Contract Expiration Date", '>%1 | =%2', ServHeader."Order Date", 0D);
                    if ServContractLine.FindFirst() then
                        "Contract No." := ServHeader."Contract No.";
                end;
        if ("Contract No." <> '') and ("Service Price Group Code" <> '') then
            Validate("Service Price Group Code", '');

        IsHandled := false;
        OnInsertOnBeforeCreateAllocationEntry(Rec, ServHeader, IsHandled);
        if not IsHandled then
            ServOrderAllocMgt.CreateAllocationEntry(
              "Document Type".AsInteger(), "Document No.", "Line No.", "Service Item No.", "Serial No.");

        Clear(ServLogMgt);
        ServLogMgt.ServItemToServOrder(Rec);

        if (ServHeader."Quote No." = '') and ("Response Time (Hours)" = 0) then
            UpdateResponseTimeHours();
        ServOrderMgt.UpdateResponseDateTime(Rec, false);
        IsHandled := false;
        OnInsertOnBeforeUpdatePriority(Rec, IsHandled);
        if not IsHandled then
            ServOrderMgt.UpdatePriority(Rec, false);

        if "Line No." = 0 then
            LendLoanerWithConfirmation(false);

        if "Service Item No." = '' then
            "Ship-to Code" := ServHeader."Ship-to Code";
        if FirstServItemLine and
           ("Document Type" = "Document Type"::Order)
        then begin
            Clear(SegManagement);
            if ServHeader."Bill-to Contact No." <> '' then
                SegManagement.LogDocument(
                  9, "Document No.", 0, 0, Database::Contact, ServHeader."Bill-to Contact No.",
                  ServHeader."Salesperson Code", '', ServHeader.Description, '')
            else
                SegManagement.LogDocument(
                  9, "Document No.", 0, 0, Database::Customer, ServHeader."Bill-to Customer No.",
                  ServHeader."Salesperson Code", '', ServHeader.Description, '');
        end;
    end;

    trigger OnModify()
    begin
        if UseServItemLineAsxRec then begin
            xRec := ServItemLine;
            UseServItemLineAsxRec := false;
        end;

        OnBeforeOnModify(Rec, xRec);

        if ("Service Item No." <> xRec."Service Item No.") or ("Serial No." <> xRec."Serial No.") then begin
            ServLine.Reset();
            ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "Document No.");
            ServLine.SetRange("Service Item Line No.", "Line No.");
            if ServLine.Find('-') then
                repeat
                    ServLine."Service Item No." := "Service Item No.";
                    ServLine."Service Item Serial No." := "Serial No.";
                    ServLine.Modify(true);
                until ServLine.Next() = 0;

            ServOrderAlloc.Reset();
            ServOrderAlloc.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
            ServOrderAlloc.SetRange("Document Type", "Document Type");
            ServOrderAlloc.SetRange("Document No.", "Document No.");
            ServOrderAlloc.SetRange("Service Item Line No.", "Line No.");
            if ServOrderAlloc.Find('-') then
                repeat
                    ServOrderAlloc."Service Item No." := "Service Item No.";
                    ServOrderAlloc."Service Item Serial No." := "Serial No.";
                    ServOrderAlloc.Modify(true);
                until ServOrderAlloc.Next() = 0;
        end;

        ShowUpdateExistingServiceLinesMessage();

        if "Service Item No." <> xRec."Service Item No." then begin
            Clear(ServLogMgt);
            ServLogMgt.ServItemOffServOrder(xRec);
            ServLogMgt.ServItemToServOrder(Rec);
        end;

        ServOrderMgt.UpdateResponseDateTime(Rec, false);
        ServOrderMgt.UpdatePriority(Rec, false);
        UpdateServiceOrderChangeLog(xRec);
    end;

    trigger OnRename()
    begin
        Error(Text010, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The %1 allows only one %2 in each %3.';
        Text001: Label 'You cannot insert %1, because %2 is missing in %3 %4.\\You can create a customer by clicking Functions,Create Customer.';
        Text002: Label 'You cannot insert %1, because %2 is missing in %3 %4.';
        Text003: Label 'You have changed one of the fault reporting codes on the %1, but it has not been changed on the existing service lines. You must update the existing service lines manually.';
        Text006: Label 'You cannot delete %1 %2,%3, because %4 %5 has not been received.';
        Text008: Label 'You cannot delete %1 %2,%3, because %4 is attached to it.';
        Text010: Label 'You cannot rename a %1.';
        Text011: Label 'You cannot change the %1 on the %2, because %3 is attached to it.';
        Text012: Label '%1 %2 does not belong to %3 %4.';
        Text016: Label 'You cannot change the %1 field because it is linked to the %2 specified on the line.';
        Text018: Label 'The %1 cannot be greater than the %2 %3.';
        Text019: Label 'The %1 cannot be earlier than the %2.';
        Text020: Label 'The %1 cannot be greater than the %2.';
        Text022: Label 'The %1 cannot be earlier than the %2 %3.';
        Text023: Label 'You cannot change the warranty information because %1 is selected.';
#pragma warning restore AA0470
        Text024: Label 'Do you want to activate a warranty for this service item line?';
        Text025: Label 'Do you want to deactivate the warranty for this service item line?';
#pragma warning disable AA0470
        Text026: Label 'You cannot reset the %1 field.\You can receive it by clicking Functions, Receive Loaner.';
        Text028: Label 'You cannot change the %1, because it has been lent in connection with %2 %3 %4.\\You can receive it by clicking Functions, Receive Loaner.', Comment = '1%=FIELDCAPTION("Loaner No."); 2%=FORMAT(ServHeader."Document Type"); 3%=ServHeader.FIELDCAPTION("No."); 4%=ServHeader."No.");';
        Text029: Label 'Do you want to lend %1 %2?';
        Text030: Label '%1 %2 has already been lent within %3 %4 %5.', Comment = '1%=TempServItemLine.FIELDCAPTION("Loaner No."); 2%=TempServItemLine."Loaner No."; 3%=FORMAT(ServHeader."Document Type"); 4%=ServHeader.FIELDCAPTION("No."); 5%=ServHeader."No.");';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServMgtSetup: Record "Service Mgt. Setup";
        ServOrderAlloc: Record "Service Order Allocation";
        ServItem: Record "Service Item";
        ServContract: Record "Service Contract Header";
        ServLine: Record "Service Line";
        ServItemLine: Record "Service Item Line";
        ServHour: Record "Service Hour";
        ServHour2: Record "Service Hour";
        ServHeader: Record "Service Header";
        ServHeader2: Record "Service Header";
        ServHeader3: Record "Service Header";
        ServCommentLine: Record "Service Comment Line";
        ServItemGr: Record "Service Item Group";
        RepairStatus: Record "Repair Status";
        RepairStatus2: Record "Repair Status";
        Loaner: Record Loaner;
        ServContractLine: Record "Service Contract Line";
        Item: Record Item;
        ServLogMgt: Codeunit ServLogManagement;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        ServOrderMgt: Codeunit ServOrderManagement;
        SegManagement: Codeunit SegManagement;
        ServLoanerMgt: Codeunit ServLoanerManagement;
        DimMgt: Codeunit DimensionManagement;
        NoOfRec: Integer;
        TempDay: Integer;
        FirstServItemLine: Boolean;
        TempDate: Date;
#pragma warning disable AA0074
        Text033: Label 'A service item line cannot belong to a service contract and to a service price group at the same time.';
#pragma warning disable AA0470
        Text035: Label 'The %1 %2 cannot be used in service orders.';
        Text036: Label 'The %1 %2 cannot be used in service quotes.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RepairStatusPriority: Integer;
        UseLineNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text037: Label 'It is not possible to select %1 because some linked service lines have been posted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LoanerLent: Boolean;
        ServContractExist: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text038: Label 'Price adjustment on each existing %1 will be cancelled. Continue?';
#pragma warning restore AA0470
        Text039: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074
        HideDialogBox: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text040: Label 'The selected %1 has a different %2 for this %3.\\Do you want to continue?';
        Text041: Label 'You must specify %1 on %2 in the %3 window for the %4 %5.', Comment = '1%=ServHour.FIELDCAPTION("Starting Time"); 2%=ServHour.Day; 3%=Text058=''Service Hours''; %4=ServHour.FIELDCAPTION("Service Contract No.");%5="Contract No.");';
        Text042: Label 'You must specify %1 on %2 in the %3 window.';
        Text043: Label 'You must specify %1 on %2, %3 %4 in the %5 window for the %6 %7.', Comment = '3%=FIELDCAPTION("Starting Date"); 4%=ServHour."Starting Date"; 6%=ServHour.FIELDCAPTION("Service Contract No."); 7%="Contract No.");';
        Text044: Label 'You must specify %1 on %2, %3 %4 in the %5 window.', Comment = '1%=ServHour.FIELDCAPTION("Starting Time"); 2%=ServHour.Day; 3%=ServHour.FIELDCAPTION("Starting Date"); 4%=ServHour."Starting Date"; 5%=Text057=''Default Service Hours'';';
        Text045: Label 'The %1 for this %2 occurs in more than 1 year. Please verify the setting for service hours and the %3 for the %4.';
        Text047: Label 'Service item %1 is included in more than one contract.\\Do you want to assign a contract number to the service order line?';
        Text048: Label 'You cannot change the %1 because it has already been set on the header.';
        Text049: Label 'Contract %1 does not include service item %2.';
        Text050: Label 'Service contract %1 specified on the service order header does not include service item %2.';
        Text051: Label 'You cannot select contract %1 because it is owned by another customer.';
        Text052: Label 'Contract %1 is not signed.';
#pragma warning restore AA0470
        Text053: Label 'You cannot change the contract number because some of the service lines have already been posted.';
        Text054: Label 'If you change the contract number, the existing service lines for this order line will be re-created.\Do you want to continue?';
#pragma warning restore AA0074
        UseServItemLineAsxRec: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text055: Label 'You cannot change the %1 because %2 %3 has not been received.', Comment = '2%=FIELDCAPTION("Loaner No."); 3%="Loaner No.";';
        Text056: Label 'One or more service lines of %6 %7 and/or %8 exist for %1, %2 %3, %4 %5. There is a check mark in the %9 field of %10 %11, therefore %10 %11 cannot be applied to service line of %6 %7 and/or %8.\\ Do you want to apply it for other service lines?';
#pragma warning restore AA0470
        Text057: Label 'Default Service Hours';
        Text058: Label 'Service Hours';
        Text059: Label 'Default warranty duration is negative. The warranty cannot be activated.';
        Text060: Label 'You may have changed a dimension.\\Do you want to update the lines?';
#pragma warning restore AA0074

    protected var
        SkipResponseTimeHrsUpdate: Boolean;

    procedure SetUpNewLine()
    begin
        if ServHeader.Get("Document Type", "Document No.") then begin
            "Document Type" := ServHeader."Document Type";
            RepairStatus.Reset();
            RepairStatus.Initial := true;
            "Repair Status Code" := RepairStatus.ReturnStatusCode(RepairStatus);
        end;

        OnAfterSetUpNewLine(Rec);
    end;

    local procedure ShowUpdateExistingServiceLinesMessage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowUpdateExistingServiceLinesMessage(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if (("Fault Area Code" <> xRec."Fault Area Code") or
            ("Symptom Code" <> xRec."Symptom Code") or
            ("Fault Code" <> xRec."Fault Code") or
            ("Resolution Code" <> xRec."Resolution Code")) and
           CheckServLineExist()
        then
            Message(
              Text003,
              TableCaption());
    end;

    procedure SetServHeader(var NewServHeader: Record "Service Header")
    begin
        ServHeader := NewServHeader;
    end;

    local procedure GetServHeader()
    begin
        if ServHeader."No." <> "Document No." then
            ServHeader.Get(Rec."Document Type", Rec."Document No.");
    end;

    local procedure CheckCustomerNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBefoerCheckCustomerNo(ServHeader, Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ServHeader."Customer No." = '' then begin
            if (ServHeader.Name <> '') and (ServHeader.Address <> '') and (ServHeader.City <> '') then
                Error(
                  Text001,
                  TableCaption, ServHeader.FieldCaption("Customer No."), ServHeader.TableCaption(), ServHeader."No.");
            Error(
              Text002,
              TableCaption, ServHeader.FieldCaption("Customer No."), ServHeader.TableCaption(), ServHeader."No.");
        end;
    end;

    procedure CheckWarranty(Date: Date)
    var
        WarrantyLabor: Boolean;
        WarrantyParts, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWarranty(Rec, xRec, Date, IsHandled);
        if IsHandled then
            exit;

        if "Warranty Starting Date (Parts)" > "Warranty Ending Date (Parts)" then begin
            Validate("Warranty Starting Date (Parts)", 0D);
            Validate("Warranty Starting Date (Labor)", 0D);
            Error(Text059);
        end;

        if ((Date >= "Warranty Starting Date (Parts)") and (Date <= "Warranty Ending Date (Parts)")) or
           ((Date >= "Warranty Starting Date (Labor)") and (Date <= "Warranty Ending Date (Labor)"))
        then
            Warranty := true
        else
            Warranty := false;

        IsHandled := false;
        OnCheckWarrantyOnAfterSetWarranty(Rec, IsHandled, Date);
        if IsHandled then
            exit;

        WarrantyParts := (Date >= "Warranty Starting Date (Parts)") and (Date <= "Warranty Ending Date (Parts)");
        WarrantyLabor := (Date >= "Warranty Starting Date (Labor)") and (Date <= "Warranty Ending Date (Labor)");

        OnCheckWarrantyOnAfterSetWarrantyPartsLabor(Rec, Date, WarrantyParts, WarrantyLabor);

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.");
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        ServLine.SetFilter("Quantity Invoiced", '=0');
        ServLine.SetServiceItemLine(Rec);
        if ServLine.Find('-') then
            repeat
                if ServLine.Type = ServLine.Type::Item then begin
                    if ServLine."Warranty Disc. %" <> "Warranty % (Parts)" then
                        ServLine.Validate("Warranty Disc. %", "Warranty % (Parts)");
                    if WarrantyParts then begin
                        ServLine.Warranty := WarrantyParts;
                        ServLine.Validate("Fault Reason Code");
                        ServLine.Validate(Warranty);
                    end else begin
                        ServLine.Warranty := false;
                        ServLine."Exclude Warranty" := false;
                    end;
                end;
                if ServLine.Type = ServLine.Type::Resource then begin
                    if ServLine."Warranty Disc. %" <> "Warranty % (Labor)" then
                        ServLine.Validate("Warranty Disc. %", "Warranty % (Labor)");
                    if WarrantyLabor then begin
                        ServLine.Warranty := WarrantyLabor;
                        ServLine.Validate("Fault Reason Code");
                        ServLine.Validate(Warranty);
                    end else begin
                        ServLine.Warranty := false;
                        ServLine."Exclude Warranty" := false;
                    end;
                end;
                ServLine.Modify();
            until ServLine.Next() = 0;

        OnAfterCheckWarranty(Rec, xRec, Date);
    end;

    local procedure CheckIfLoanerOnServOrder()
    var
        ServItemLine: Record "Service Item Line";
    begin
        LoanerLent := false;
        if "Loaner No." <> '' then begin
            ServItemLine.Reset();
            ServItemLine.SetCurrentKey("Loaner No.");
            ServItemLine.SetRange("Loaner No.", "Loaner No.");
            if ServItemLine.Find('-') then
                if (ServItemLine."Document Type" <> "Document Type") or
                   (ServItemLine."Document No." <> "Document No.") or
                   (ServItemLine."Line No." <> "Line No.")
                then
                    LoanerLent := true
                else
                    if ServItemLine.Next() <> 0 then
                        LoanerLent := true;

            if LoanerLent then begin
                ServHeader.Get(
                  ServItemLine."Document Type", ServItemLine."Document No.");

                Error(
                  Text030,
                  ServItemLine.FieldCaption("Loaner No."), ServItemLine."Loaner No.",
                  Format(ServHeader."Document Type"), ServHeader.FieldCaption("No."),
                  ServHeader."No.");
            end;
        end;
    end;

    procedure CalculateResponseDateTime(OrderDate: Date; OrderTime: Time)
    var
        CalChange: Record "Customized Calendar Change";
        CalendarMgmt: Codeunit "Calendar Management";
        TotTime: Decimal;
        LastTotTime: Decimal;
        HoursLeft: Decimal;
        HoursOnLastDay: Decimal;
        Holiday: Boolean;
        ContractServHourExist: Boolean;
        ErrorDate: Date;
        WholeResponseDays: Integer;
        StartingTime: Time;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateResponseDateTime(Rec, OrderDate, OrderTime, IsHandled);
        if IsHandled then
            exit;

        ServMgtSetup.Get();
        ServMgtSetup.TestField("Base Calendar Code");
        CalendarMgmt.SetSource(ServMgtSetup, CalChange);

        ServHour.Reset();
        if "Contract No." <> '' then begin
            if CheckIfServHourExist("Contract No.") then begin
                ContractServHourExist := true;
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
                ServHour.SetRange("Service Contract No.", "Contract No.")
            end else begin
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::" ");
                ServHour.SetRange("Service Contract No.", '')
            end;
        end else
            ServHour.SetRange("Service Contract No.", '');

        HoursLeft := "Response Time (Hours)";

        if not ServHour.FindFirst() then begin
            WholeResponseDays := HoursLeft div 24;
            HoursOnLastDay := HoursLeft - WholeResponseDays * 24;
            if CalendarMgmt.CalcTimeDelta(OrderTime, 000000T) / 3600000 + HoursOnLastDay >= 24 then begin
                WholeResponseDays := WholeResponseDays + 1;
                HoursOnLastDay := HoursOnLastDay - 24;
            end;
            "Response Date" := OrderDate + WholeResponseDays;
            "Response Time" := OrderTime + HoursOnLastDay * 3600000;
            exit;
        end;
        if OrderDate = 0D then
            exit;
        TotTime := 0;
        LastTotTime := 0;
        TempDate := OrderDate;
        ErrorDate := OrderDate + 365;
        HoursLeft := HoursLeft * 3600000;

        repeat
            TempDay := Date2DWY(TempDate, 1) - 1;
            HoursOnLastDay := 0;
            ServHour.SetFilter("Starting Date", '<=%1', TempDate);
            ServHour.SetRange(Day, TempDay);
            if ServHour.FindLast() then begin
                if ServHour."Valid on Holidays" then
                    Holiday := false
                else
                    Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CalChange);
                if not Holiday then begin
                    if TempDate = OrderDate then begin
                        if OrderTime < ServHour."Ending Time" then begin
                            if OrderTime >= ServHour."Starting Time" then
                                StartingTime := OrderTime
                            else
                                StartingTime := ServHour."Starting Time";

                            if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime) then begin
                                TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime);
                                HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", StartingTime);
                            end else begin
                                TotTime := TotTime + HoursLeft;
                                HoursOnLastDay := HoursLeft;
                            end;
                        end;
                    end else begin
                        if ServHour."Starting Time" = 0T then begin
                            if ("Contract No." <> '') and ContractServHourExist then begin
                                if ServHour."Starting Date" <> 0D then
                                    Error(
                                      Text043,
                                      FieldCaption("Starting Time"),
                                      ServHour.Day,
                                      FieldCaption("Starting Date"),
                                      ServHour."Starting Date",
                                      Text058,
                                      ServHour.FieldCaption("Service Contract No."),
                                      "Contract No.");

                                Error(
                                  Text041,
                                  ServHour.FieldCaption("Starting Time"),
                                  ServHour.Day,
                                  Text058,
                                  ServHour.FieldCaption("Service Contract No."),
                                  "Contract No.");
                            end;
                            if ServHour."Starting Date" <> 0D then
                                Error(
                                  Text044,
                                  ServHour.FieldCaption("Starting Time"),
                                  ServHour.Day,
                                  ServHour.FieldCaption("Starting Date"),
                                  ServHour."Starting Date",
                                  Text057);

                            Error(
                              Text042,
                              FieldCaption("Starting Time"),
                              ServHour.Day,
                              Text057)
                            ;
                        end;

                        if ServHour."Ending Time" = 0T then begin
                            if ("Contract No." <> '') and ContractServHourExist then begin
                                if ServHour."Starting Date" <> 0D then
                                    Error(
                                      Text043,
                                      ServHour.FieldCaption("Ending Time"),
                                      ServHour.Day,
                                      ServHour.FieldCaption("Starting Date"),
                                      ServHour."Starting Date",
                                      Text058,
                                      ServHour.FieldCaption("Service Contract No."),
                                      "Contract No.");

                                Error(
                                  Text041,
                                  ServHour.FieldCaption("Ending Time"),
                                  ServHour.Day,
                                  Text058,
                                  ServHour.FieldCaption("Service Contract No."),
                                  "Contract No.");
                            end;
                            CheckServHourStartingDate(ServHour);
                            Error(
                              Text042,
                              ServHour.FieldCaption("Ending Time"),
                              ServHour.Day,
                              Text057)
                            ;
                        end;

                        if HoursLeft > CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time") then begin
                            TotTime := TotTime + CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                            HoursOnLastDay := CalendarMgmt.CalcTimeDelta(ServHour."Ending Time", ServHour."Starting Time");
                        end else begin
                            TotTime := TotTime + HoursLeft;
                            HoursOnLastDay := HoursLeft;
                        end;
                    end;
                    if LastTotTime < TotTime then begin
                        HoursLeft := HoursLeft - (TotTime - LastTotTime);
                        LastTotTime := TotTime;
                    end;
                end;
            end;
            TempDate := TempDate + 1;
        until (HoursLeft <= 0) or (TempDate > ErrorDate);

        CheckTempDateErrorDate(TempDate, ErrorDate, ServItem.FieldCaption("Response Time (Hours)"), ServItem.TableCaption());

        if TotTime > 0 then begin
            "Response Date" := TempDate - 1;
            if ("Response Date" = OrderDate) and (OrderTime > ServHour."Starting Time") then
                "Response Time" := OrderTime + HoursOnLastDay
            else
                "Response Time" := ServHour."Starting Time" + HoursOnLastDay;
        end else begin
            "Response Date" := OrderDate;
            "Response Time" := OrderTime;
        end;
    end;

    local procedure CheckServItemCustomer(ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item");
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServItemCustomer(ServiceHeader, ServiceItem, IsHandled);
        if IsHandled then
            exit;

        if ServiceHeader."Customer No." <> ServiceItem."Customer No." then
            Error(
              Text012,
              ServiceItem.TableCaption(), "Service Item No.", ServiceHeader.FieldCaption("Customer No."), ServiceHeader."Customer No.");
    end;

    procedure CheckServLineExist(): Boolean
    begin
        if "Line No." = 0 then
            exit(false);

        ServLine.Reset();
        ServLine.SetCurrentKey("Document Type", "Document No.", "Service Item Line No.", Type);
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.SetRange("Service Item Line No.", "Line No.");
        exit(ServLine.Find('-'));
    end;

    procedure CheckIfServHourExist(ContractNo: Code[20]): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfServHourExist(Rec, ContractNo, IsHandled);
        if IsHandled then
            exit;

        if ContractNo = '' then
            exit(false);

        ServHour2.Reset();
        ServHour2.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
        ServHour2.SetRange("Service Contract No.", ContractNo);
        OnCheckIfServHourexistOnBeforeFindServHour(ServHour);
        exit(ServHour2.FindFirst())
    end;

    local procedure EnsureCorrectStartingFinishingTimes()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureCorrectStartingFinishingTimes(Rec, ServHeader, IsHandled);
        if IsHandled then
            exit;

        if ("Starting Date" = ServHeader."Order Date") and ("Starting Time" < ServHeader."Order Time") then
            Error(Text022, FieldCaption("Starting Time"), ServHeader.TableCaption(), ServHeader.FieldCaption("Order Time"));

        if ("Starting Time" > "Finishing Time") and ("Finishing Time" <> 0T) and ("Starting Date" = "Finishing Date") then
            Error(Text020, FieldCaption("Starting Time"), FieldCaption("Finishing Time"));
    end;

    procedure UpdateStartFinishDateTime(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20];
                                                                LineNo: Integer;
                                                                StartingDate: Date;
                                                                StartingTime: Time;
                                                                FinishingDate: Date;
                                                                FinishingTime: Time;
                                                                Erasing: Boolean)
    var
        ServOrderMgt: Codeunit ServOrderManagement;
        GoOut: Boolean;
        Modifyheader: Boolean;
        IsHandled: Boolean;
        ShouldSetStartTime: Boolean;
        ShouldSetFinishingTime: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateStartFinishDateTime(Rec, ServMgtSetup, IsHandled);
        if IsHandled then
            exit;

        if not ServHeader3.Get(DocumentType, DocumentNo) then
            exit;

        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
        ServItemLine.SetRange("Document Type", ServHeader3."Document Type");
        ServItemLine.SetRange("Document No.", ServHeader3."No.");
        ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
        ServItemLine.SetFilter("Line No.", '<> %1', LineNo);
        if ServItemLine.Find('-') then begin
            if Erasing then begin
                StartingDate := ServItemLine."Starting Date";
                StartingTime := ServItemLine."Starting Time";
            end;
            repeat
                if ServItemLine."Starting Date" < StartingDate then begin
                    StartingDate := ServItemLine."Starting Date";
                    StartingTime := ServItemLine."Starting Time";
                end else
                    if (ServItemLine."Starting Date" = StartingDate) and
                       (ServItemLine."Starting Time" < StartingTime)
                    then
                        StartingTime := ServItemLine."Starting Time";
            until ServItemLine.Next() = 0
        end else
            GoOut := true;

        if not GoOut then begin
            ServItemLine.Reset();
            ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
            ServItemLine.Ascending(false);
            ServItemLine.SetRange("Document Type", ServHeader3."Document Type");
            ServItemLine.SetRange("Document No.", ServHeader3."No.");
            ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
            ServItemLine.SetFilter("Line No.", '<> %1', LineNo);
            if ServItemLine.Find('-') then
                repeat
                    if ServItemLine."Finishing Date" > FinishingDate then begin
                        FinishingDate := ServItemLine."Finishing Date";
                        FinishingTime := ServItemLine."Finishing Time";
                    end else
                        if (ServItemLine."Finishing Date" = FinishingDate) and
                           (ServItemLine."Finishing Time" > FinishingTime)
                        then
                            FinishingTime := ServItemLine."Finishing Time";
                until ServItemLine.Next() = 0;
        end else
            if Erasing then begin
                StartingDate := 0D;
                StartingTime := 0T;
                FinishingDate := 0D;
                FinishingTime := 0T;
            end;

        Modifyheader := false;
        ServHeader3.CalcFields("Contract Serv. Hours Exist");
        ShouldSetStartTime := (ServHeader3."Starting Date" <> StartingDate) or ((ServHeader3."Starting Date" = StartingDate) and (ServHeader3."Starting Time" <> StartingTime));
        OnUpdateStartFinishDateTimeOnAfterCalcShouldSetStartTime(Rec, ServHeader3, ShouldSetStartTime);
        if ShouldSetStartTime then begin
            ServHeader3."Starting Date" := StartingDate;
            ServHeader3."Starting Time" := StartingTime;
            if StartingDate <> 0D then
                ServHeader3."Actual Response Time (Hours)" :=
                  ServOrderMgt.CalcServTime(
                    ServHeader3."Order Date", ServHeader3."Order Time", StartingDate, StartingTime,
                    ServHeader3."Contract No.", ServHeader3."Contract Serv. Hours Exist")
            else
                ServHeader3."Actual Response Time (Hours)" := 0;
            Modifyheader := true;
        end;

        ShouldSetFinishingTime := ((ServHeader3.Status = ServHeader3.Status::Finished) or GoOut) and ((ServHeader3."Finishing Date" <> FinishingDate) or
                                   ((ServHeader3."Finishing Date" = FinishingDate) and (ServHeader3."Finishing Time" <> FinishingTime)));
        OnUpdateStartFinishDateTimeOnAfterCalcShouldSetFinishingTime(Rec, ServHeader3, ShouldSetFinishingTime);
        if ShouldSetFinishingTime then begin
            ServHeader3."Finishing Date" := FinishingDate;
            ServHeader3."Finishing Time" := FinishingTime;
            ServHeader3."Service Time (Hours)" :=
              ServOrderMgt.CalcServTime(
                StartingDate, StartingTime, FinishingDate, FinishingTime,
                ServHeader3."Contract No.", ServHeader3."Contract Serv. Hours Exist");
            Modifyheader := true;
        end;

        if Modifyheader then
            ServHeader3.Modify();
    end;

    procedure AssistEditSerialNo()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        Clear(ItemLedgEntry);
        GetServHeader();
        ItemLedgEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Variant Code");
        ItemLedgEntry.SetRange("Source Type", ItemLedgEntry."Source Type"::Customer);
        ItemLedgEntry.SetRange("Source No.", ServHeader."Customer No.");
        if "Item No." <> '' then
            ItemLedgEntry.SetRange("Item No.", "Item No.");
        if "Variant Code" <> '' then
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
        if PAGE.RunModal(0, ItemLedgEntry) = ACTION::LookupOK then begin
            if "Item No." = '' then begin
                if Description + "Description 2" = '' then begin
                    Item.Get(ItemLedgEntry."Item No.");
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                end;
                Validate("Item No.", ItemLedgEntry."Item No.");
            end;
            Validate("Serial No.", ItemLedgEntry."Serial No.");
        end;
    end;

    procedure GetHideDialogBox(): Boolean
    begin
        exit(HideDialogBox);
    end;

    procedure SetHideDialogBox(DialogBoxVar: Boolean)
    begin
        HideDialogBox := DialogBoxVar;
        OnAfterSetHideDialogBox(HideDialogBox);
    end;

    local procedure GetItemTranslation(): Boolean
    var
        ItemTranslation: Record "Item Translation";
    begin
        GetServHeader();
        if not ItemTranslation.Get("Item No.", "Variant Code", ServHeader."Language Code") then
            exit(false);

        Description := ItemTranslation.Description;
        "Description 2" := ItemTranslation."Description 2";

        exit(true);
    end;

#if not CLEAN27
    [Obsolete('Replaced by namesake procedure with Enum parameter', '27.0')]
    procedure ShowComments(Type: Option General,Fault,Resolution,Accessory,Internal,"Service Item Loaner")
    begin
        ShowComments("Service Comment Line Type".FromInteger(Type));
    end;
#endif

    procedure ShowComments(ServiceCommentLineType: Enum "Service Comment Line Type")
    begin
        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        ServHeader.TestField("Customer No.");
        TestField("Line No.");

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "Document No.");
        case ServiceCommentLineType of
            ServiceCommentLineType::Fault:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Fault);
            ServiceCommentLineType::Resolution:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Resolution);
            ServiceCommentLineType::Accessory:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Accessory);
            ServiceCommentLineType::Internal:
                ServCommentLine.SetRange(Type, ServCommentLine.Type::Internal);
            ServiceCommentLineType::"Service Item Loaner":
                ServCommentLine.SetRange(Type, ServCommentLine.Type::"Service Item Loaner");
            else
                OnShowCommentsOnCaseElse(ServCommentLine, ServiceCommentLineType);
        end;
        ServCommentLine.SetRange("Table Line No.", "Line No.");
        OnShowCommentsOnBeforeRunPageServiceCommentSheet(Rec, ServCommentLine);
        Page.RunModal(Page::"Service Comment Sheet", ServCommentLine);
    end;

    local procedure CheckRecreateServLines()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRecreateServLines(Rec, xRec, ServLine, IsHandled);
        if IsHandled then
            exit;

        if ServLine.Find('-') and ("Line No." <> 0) then
            if ConfirmManagement.GetResponseOrDefault(Text054, true) then begin
                Modify(true);
                RecreateServLines(ServLine);
            end else
                "Contract No." := xRec."Contract No.";
    end;

    local procedure RecreateServLines(var ServLine2: Record "Service Line")
    var
        TempServLine: Record "Service Line" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTempServLine(Rec, xRec, ServLine2, IsHandled);
        if IsHandled then
            exit;

        if ServLine2.Find('-') then begin
            ServLine2.LockTable();
            repeat
                TempServLine := ServLine2;
                TempServLine.Insert();
            until ServLine2.Next() = 0;

            TempServLine.Find('-');

            repeat
                ServLine2.Get(TempServLine."Document Type", TempServLine."Document No.", TempServLine."Line No.");
                ServLine2.SetHideReplacementDialog(true);
                if TempServLine."No." <> '' then begin
                    ServLine.SetHideCostWarning(true);
                    ServLine2.Validate("No.", TempServLine."No.");
                    ServLine2."Spare Part Action" := TempServLine."Spare Part Action";
                    ServLine2."Component Line No." := TempServLine."Component Line No.";
                    ServLine2."Replaced Item No." := TempServLine."Replaced Item No.";
                    if TempServLine.Quantity <> 0 then
                        ServLine2.Validate(Quantity, TempServLine.Quantity);
                    ServLine2."Location Code" := TempServLine."Location Code";
                    if ServLine2.Type <> ServLine2.Type::" " then begin
                        if ServLine2.Type = ServLine2.Type::Item then begin
                            ServLine2.Validate("Variant Code", TempServLine."Variant Code");
                            if ServLine2."Location Code" <> '' then
                                ServLine2."Bin Code" := TempServLine."Bin Code";
                        end;
                        ServLine2.Validate("Unit of Measure Code", TempServLine."Unit of Measure Code");
                        ServLine2."Fault Reason Code" := TempServLine."Fault Reason Code";
                        ServLine2."Exclude Warranty" := TempServLine."Exclude Warranty";
                        ServLine2."Exclude Contract Discount" := TempServLine."Exclude Contract Discount";
                        ServLine2.Validate(Warranty, TempServLine.Warranty);
                    end;
                    ServLine2.Description := TempServLine.Description;
                    ServLine2."Description 2" := TempServLine."Description 2";
                    OnRecreateServLine(ServLine2, TempServLine);
                end;
                ServLine2.Modify(true);
            until TempServLine.Next() = 0;
            TempServLine.DeleteAll();
        end;
    end;

    local procedure CalculateDates()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateDates(Rec, IsHandled);
        if IsHandled then
            exit;

        if ServHeader."Order Date" > WorkDate() then begin
            if "Starting Date" = 0D then begin
                "Starting Date" := ServHeader."Order Date";
                "Starting Time" := ServHeader."Order Time";
            end;
            "Finishing Date" := "Starting Date";
            Validate("Finishing Time", "Starting Time");
        end else begin
            if "Starting Date" = 0D then begin
                "Starting Date" := WorkDate();
                "Starting Time" := Time;
            end;
            if WorkDate() < "Starting Date" then begin
                "Finishing Date" := "Starting Date";
                Validate("Finishing Time", "Starting Time");
            end else begin
                "Finishing Date" := WorkDate();
                if ("Starting Date" = "Finishing Date") and ("Starting Time" > Time) then
                    Validate("Finishing Time", "Starting Time")
                else
                    Validate("Finishing Time", Time);
            end;
        end;
    end;

    procedure CalculateResponseTimeHours(): Decimal
    var
        IsHandled: Boolean;
        ResponseTimeHours: Decimal;
    begin
        ResponseTimeHours := 0;
        IsHandled := false;
        OnBeforeCalculateResponseTimeHours(Rec, ResponseTimeHours, IsHandled);
        if IsHandled then
            exit(ResponseTimeHours);

        if "Contract No." <> '' then begin
            if "Service Item No." <> '' then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractLine."Contract Type"::Contract);
                ServContractLine.SetRange("Contract No.", "Contract No.");
                ServContractLine.SetRange("Service Item No.", "Service Item No.");
                if ServContractLine.FindFirst() then
                    if ServContractLine."Response Time (Hours)" > 0 then
                        exit(ServContractLine."Response Time (Hours)");
            end;

            if ServContract.Get(ServContract."Contract Type"::Contract, "Contract No.") then
                if ServContract."Response Time (Hours)" > 0 then
                    exit(ServContract."Response Time (Hours)");
        end;

        if "Service Item No." <> '' then
            if ServItem.Get("Service Item No.") then
                if ServItem."Response Time (Hours)" > 0 then
                    exit(ServItem."Response Time (Hours)");

        if "Service Item Group Code" <> '' then
            if ServItemGr.Get("Service Item Group Code") then
                if ServItemGr."Default Response Time (Hours)" <> 0 then
                    exit(ServItemGr."Default Response Time (Hours)");

        ServMgtSetup.Get();
        exit(ServMgtSetup."Default Response Time (Hours)");
    end;

    procedure UpdateResponseTimeHours()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResponseTimeHours(Rec, xRec, SkipResponseTimeHrsUpdate, IsHandled);
        if IsHandled then
            exit;

        if not SkipResponseTimeHrsUpdate then begin
            if "Response Time (Hours)" <> xRec."Response Time (Hours)" then
                Validate("Response Time (Hours)", CalculateResponseTimeHours())
            else
                if "Response Date" = 0D then
                    Validate("Response Time (Hours)", CalculateResponseTimeHours())
                else
                    "Response Time (Hours)" := CalculateResponseTimeHours();
            SkipResponseTimeHrsUpdate := false
        end;

        OnAfterUpdateResponseTimeHours(Rec);
    end;

    procedure UpdateServiceOrderChangeLog(var OldServItemLine: Record "Service Item Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateServiceOrderChangeLog(Rec, OldServItemLine, IsHandled);
        if IsHandled then
            exit;

        if "Response Date" <> OldServItemLine."Response Date" then
            ServLogMgt.ServItemLineResponseDateChange(Rec, OldServItemLine);

        if "Response Time" <> OldServItemLine."Response Time" then
            ServLogMgt.ServItemLineResponseTimeChange(Rec, OldServItemLine);

        if "Repair Status Code" <> OldServItemLine."Repair Status Code" then
            ServLogMgt.ServHeaderRepairStatusChange(Rec, OldServItemLine);

        OnAfterUpdateServiceOrderChangeLog(Rec, OldServItemLine);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        if "Document No." = '' then
            exit;

        GetServHeader();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ServHeader."Dimension Set ID", Database::"Service Header");
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, CurrFieldNo, xRec, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowDimensions()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";

        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            OnShowDimensionsOnBeforeServiceItemLineModify(Rec, xRec);
            Modify();
            if ServLineExists() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure SetFilterForType()
    var
        FaultReasonCode: Record "Fault Reason Code";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFilterForType(Rec, ServLine, IsHandled);
        if IsHandled then
            exit;


        if FaultReasonCode.Get("Fault Reason Code") then
            if FaultReasonCode."Exclude Warranty Discount" then begin
                ServLine.SetFilter(Type, '%1|%2', ServLine.Type::Cost, ServLine.Type::"G/L Account");
                if ServLine.Find('-') then
                    if not ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(
                           Text056,
                           TableCaption,
                           FieldCaption("Document No."), "Document No.",
                           FieldCaption("Line No."), "Line No.",
                           ServLine.FieldCaption(Type),
                           ServLine.Type::"G/L Account",
                           ServLine.Type::Cost,
                           FaultReasonCode.FieldCaption("Exclude Warranty Discount"),
                           FaultReasonCode.TableCaption(), FaultReasonCode.Code),
                         true)
                    then
                        Error('');
                ServLine.SetRange(Type, ServLine.Type::Item, ServLine.Type::Resource);
            end else
                ServLine.SetRange(Type, ServLine.Type::Item, ServLine.Type::"G/L Account");
    end;

    local procedure ServLineExists(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        exit(ServLine.Find('-'));
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        IsHandled: Boolean;
    begin
        // Update all lines with changed dimensions.

        if NewParentDimSetID = OldParentDimSetID then
            exit;

        IsHandled := false;
        OnUpdateAllLineDimOnBeforeGetResponse(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled);
        if not IsHandled then
            if not HideDialogBox and GuiAllowed then
                if not ConfirmManagement.GetResponseOrDefault(Text060, true) then
                    exit;

        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "Document No.");
        ServLine.LockTable();
        if ServLine.Find('-') then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServLine."Dimension Set ID" <> NewDimSetID then begin
                    ServLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServLine."Dimension Set ID", ServLine."Shortcut Dimension 1 Code", ServLine."Shortcut Dimension 2 Code");
                    ServLine.Modify();
                end;
            until ServLine.Next() = 0;
    end;

    procedure SetServItemInfo(ServItem: Record "Service Item")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetServItemInfo(Rec, ServItem, IsHandled);
        if IsHandled then
            exit;

        ServItem.ErrorIfBlockedForAll();

        "Item No." := ServItem."Item No.";
        "Serial No." := ServItem."Serial No.";
        "Variant Code" := ServItem."Variant Code";
        ServOrderMgt.CheckItemServiceBlocked(Rec);
        "Warranty Starting Date (Parts)" := ServItem."Warranty Starting Date (Parts)";
        "Warranty Ending Date (Parts)" := ServItem."Warranty Ending Date (Parts)";
        "Warranty Starting Date (Labor)" := ServItem."Warranty Starting Date (Labor)";
        "Warranty Ending Date (Labor)" := ServItem."Warranty Ending Date (Labor)";
        "Warranty % (Parts)" := ServItem."Warranty % (Parts)";
        "Warranty % (Labor)" := ServItem."Warranty % (Labor)";
        Description := ServItem.Description;
        "Description 2" := ServItem."Description 2";
        Priority := ServItem.Priority;
        "Vendor No." := ServItem."Vendor No.";
        "Vendor Item No." := ServItem."Vendor Item No.";
        CheckWarranty(ServHeader."Order Date");

        OnAfterSetServItemInfo(Rec, xRec, ServItem);
    end;

    procedure CheckTempDateErrorDate(Tempdate: Date; ErrorDate: Date; Caption1: Text[30]; Caption2: Text[30])
    begin
        if Tempdate > ErrorDate then
            Error(Text045, FieldCaption("Response Date"), TableCaption(), Caption1, Caption2);
    end;

    local procedure CheckServHourStartingDate(ServiceHour: Record "Service Hour")
    begin
        if ServiceHour."Starting Date" <> 0D then
            Error(
              Text044,
              ServiceHour.FieldCaption("Ending Time"),
              ServiceHour.Day,
              ServiceHour.FieldCaption("Starting Date"),
              ServiceHour."Starting Date",
              Text057);
    end;

    internal procedure LendLoanerWithConfirmation(errorOnDeny: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLendLoanerWithConfirmation(Rec, errorOnDeny, IsHandled);
        if IsHandled then
            exit;

        if "Loaner No." = '' then
            exit;
        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text029, Loaner.TableCaption(), "Loaner No."), true)
        then
            ServLoanerMgt.LendLoaner(Rec)
        else
            if errorOnDeny then
                Error('')
            else
                "Loaner No." := '';
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        UserSetupMgt: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetServiceFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetServiceFilter());
            FilterGroup(0);
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate());
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        if DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            CreateDim(DefaultDimSource);
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
            FieldNo = Rec.FieldNo("Service Item No."):
                TableValuePair.Add(Database::"Service Item", Rec."Service Item No.");
            FieldNo = Rec.FieldNo("Service Item Group Code"):
                TableValuePair.Add(Database::"Service Item Group", Rec."Service Item Group Code");
            FieldNo = Rec.FieldNo("Responsibility Center"):
                TableValuePair.Add(Database::"Responsibility Center", Rec."Responsibility Center");
        end;
        OnAfterInitTableValuePair(TableValuePair, FieldNo, Rec);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Item", Rec."Service Item No.", FieldNo = Rec.FieldNo("Service Item No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Item Group", Rec."Service Item Group Code", FieldNo = Rec.FieldNo("Service Item Group Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ServiceItemLine: Record "Service Item Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignItemValues(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; Item: Record Item; ServiceHeader: Record "Service Header"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetHideDialogBox(var HideDialogBox: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServItemInfo(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; ServiceItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServiceOrderChangeLog(ServiceItemLine: Record "Service Item Line"; var OldServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRecreateServLines(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; var ServLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureCorrectStartingFinishingTimes(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLendLoanerWithConfirmation(var ServiceItemLine: Record "Service Item Line"; errorOnDeny: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStartFinishDateTime(var ServiceItemLine: Record "Service Item Line"; ServiceMgtSetup: Record "Service Mgt. Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServItemCustomer(ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBefoerCheckCustomerNo(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempServLine(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; var ServLine2: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowUpdateExistingServiceLinesMessage(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFilterForType(var ServiceItemLine: Record "Service Item Line"; var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResponseTimeHours(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; SkipResponseTimeHrsUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSerialNo(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarranty(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyParts(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyLabor(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarrantyOnAfterSetWarranty(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean; Date: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWarrantyOnAfterSetWarrantyPartsLabor(var ServiceItemLine: Record "Service Item Line"; Date: Date; var WarrantyParts: Boolean; var WarrantyLabor: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupContractNoOnAfterServContractLineSetFilters(var ServiceContractLine: Record "Service Contract Line"; ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLine(var ServiceLine: Record "Service Line"; TempServiceLine: Record "Service Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRepairStatusCodeValidateOnAfterSetRepairStatusInProgress(var ServiceItemLine: Record "Service Item Line"; var RepairStatusInProgress: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCommentsOnBeforeRunPageServiceCommentSheet(var ServiceItemLine: Record "Service Item Line"; var ServCommentLine: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStartFinishDateTimeOnAfterCalcShouldSetStartTime(var ServiceItemLine: Record "Service Item Line"; var ServiceHeader: Record "Service Header"; var ShouldSetStartTime: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStartFinishDateTimeOnAfterCalcShouldSetFinishingTime(var ServiceItemLine: Record "Service Item Line"; var ServiceHeader: Record "Service Header"; var ShouldSetFinishingTime: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeValidateServicePeriod(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnAfterValidateServiceItemGroupCode(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeCheckXRecServiceItemNo(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; var ServLine: Record "Service Line"; var ServItem: Record "Service Item"; var IsHandled: Boolean; var DoExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeValidateServicePeriod(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeEmptyContractNoFindServContractLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item"; var ShouldFindServContractLine: Boolean; var ServContractExist: Boolean; var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipToCode(var ServiceItemLine: Record "Service Item Line"; ServItem: Record "Service Item"; ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var IsHandled: Boolean; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFinishingDateOnBeforeCheckIfLessThanOrderDate(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingDateOnBeforeCheckIfLessThanOrderDate(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateResponseTimeOnBeforeCheckResponseTime(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateResponseDateOnBeforeCheckResponseDate(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeCheckCOntractStatusSigned(var ServiceContractLine: Record "Service Contract Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingDateOnBeforeValidateStartingTime(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFinishingDateOnBeforeValidateFinishingTime(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRepairStatusCodeOnBeforeCheckOrderDateRepairStatusInProgress(var ServiceOrderAllocation: Record "Service Order Allocation"; var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRepairStatusCodeInitialOnBeforeServOrderAllocModify(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRepairStatusCodeInProgressOnBeforeServOrderAllocModify(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRepairStatusCodeFinishedOnBeforeServOrderAllocModify(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateResponseTimeHours(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateDates(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfServHourExist(var ServiceItemLine: Record "Service Item Line"; var ContractNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateResponseDateTime(var ServiceItemLine: Record "Service Item Line"; OrderDate: Date; OrderTime: Time; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfServHourexistOnBeforeFindServHour(var ServiceHour: Record "Service Hour")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetServContractExistTrue(var ServiceContractLine: Record "Service Contract Line"; var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnBeforeCheckServContractExist(var ServiceContractLine: Record "Service Contract Line"; ServiceItem: Record "Service Item"; ServiceHeader: Record "Service Header"; var ServContractExist: Boolean; var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnBeforeServiceItemLineModify(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFinishingTime(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetResponse(var ServiceItemLine: Record "Service Item Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeCheckFirstServItemLine(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnAfterGetServHeader(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeSetContractNo(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeCreateAllocationEntry(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeUpdatePriority(var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnAfterValidateWarrantyPartsLaborDates(var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceItemNoOnAfterSetFilterServContractLine(var ServiceItemLine: Record "Service Item Line"; var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateServiceItemNoOnBeforeUpdateResponseTimeHours(var ServiceItemLine: Record "Service Item Line"; xServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRepairStatusCodeOnBeforeValidateStatus(var ServiceItemLine: Record "Service Item Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyStartingDateParts(var ServiceItemLine: Record "Service Item Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyEndingDateParts(var ServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyStartingDateLabor(var ServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWarrantyEndingDateLabor(var ServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateServicePriceGroupCode(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWarranty(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; Date: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateServiceOrderChangeLog(var ServiceItemLine: Record "Service Item Line"; var OldServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetServItemInfo(var ServiceItemLine: Record "Service Item Line"; ServiceItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateContractNo(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateResponseTimeHours(var ServiceItemLine: Record "Service Item Line"; var ResponseTimeHours: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ServiceItemLine: Record "Service Item Line"; CallingFieldNo: Integer; xServiceItemLine: Record "Service Item Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWarranty(var ServiceItemLine: Record "Service Item Line"; var xServiceItemLine: Record "Service Item Line"; Date: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCommentsOnCaseElse(var ServiceCommentLine: Record "Service Comment Line"; ServiceCommentLineType: Enum "Service Comment Line Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateContractNoOnBeforeFindServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;
}
