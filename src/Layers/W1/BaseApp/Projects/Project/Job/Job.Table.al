// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Assembly.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Projects.Project.Archive;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Email;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Utilities;

table 167 Job
{
    Caption = 'Project';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Job List";
    LookupPageID = "Job List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "No." <> xRec."No." then begin
                    JobsSetup.Get();
                    NoSeries.TestManual(JobsSetup."Job Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
            end;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToCustomerNo(Rec, IsHandled, xRec, CurrFieldNo);
                if IsHandled then
                    exit;
                BillToCustomerNoUpdated(Rec, xRec);
            end;
        }
        field(12; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(13; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(14; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        field(19; Status; Enum "Job Status")
        {
            Caption = 'Status';
            InitValue = Open;

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                ATOLink: Record "Assemble-to-Order Link";
                JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
                ConfirmManagement: Codeunit "Confirm Management";
                JobArchiveManagement: Codeunit "Job Archive Management";
                IsHandled: Boolean;
                UndidCompleteStatus: Boolean;
                ShouldDeleteReservationEntries: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStatus(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if xRec.Status <> Status then begin
                    if Status = Status::Completed then
                        Validate(Complete, true);
                    if xRec.Status = xRec.Status::Completed then begin
                        IsHandled := false;
                        OnValidateStatusOnBeforeConfirm(Rec, xRec, UndidCompleteStatus, IsHandled);
                        if not IsHandled then
                            if ConfirmManagement.GetResponseOrDefault(StatusChangeQst, true) then begin
                                Validate(Complete, false);
                                UndidCompleteStatus := true;
                            end else
                                Status := xRec.Status;
                    end;
                    Modify();

                    ATOLink.CheckIfAssembleToOrderLinkExist(Rec);
                    CheckIfTimeSheetLineLinkExist();

                    JobPlanningLine.SetCurrentKey("Job No.");
                    JobPlanningLine.SetRange("Job No.", "No.");
                    if JobPlanningLine.FindSet() then begin
                        ShouldDeleteReservationEntries := CheckReservationEntries();
                        repeat
                            if ShouldDeleteReservationEntries then
                                JobPlanningLineReserve.DeleteLineInternal(JobPlanningLine, false);
                            UpdateReservationEntries();
                            ATOLink.MakeAsmOrderLinkedToJobPlanningOrderLine(JobPlanningLine);
                            JobPlanningLine.Validate(Status, Status);
                            JobPlanningLine.Modify();
                        until JobPlanningLine.Next() = 0;
                        PerformAutoReserve(JobPlanningLine);
                        if UndidCompleteStatus then
                            JobPlanningLine.CreateWarehouseRequest();
                    end;
                    JobArchiveManagement.AutoArchiveJob(Rec);
                end;
            end;
        }
        field(20; "Person Responsible"; Code[20])
        {
            Caption = 'Person Responsible';
            TableRelation = Resource where(Type = const(Person));
        }
        field(21; "Global Dimension 1 Code"; Code[20])
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
        field(22; "Global Dimension 2 Code"; Code[20])
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
        field(23; "Job Posting Group"; Code[20])
        {
            Caption = 'Project Posting Group';
            TableRelation = "Job Posting Group";
        }
        field(24; Blocked; Enum "Job Blocked")
        {
            Caption = 'Blocked';
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(30; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const(Job),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
        }
        field(32; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(35; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Location Code" <> xRec."Location Code") then
                    MessageIfJobTaskExist(FieldCaption("Location Code"));

                SetDefaultBin();
            end;
        }
        field(36; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Bin Code" <> xRec."Bin Code") then
                    MessageIfJobTaskExist(FieldCaption("Bin Code"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(49; "Scheduled Res. Qty."; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where("Job No." = field("No."),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "No." = field("Resource Filter"),
                                                                           "Planning Date" = field("Planning Date Filter")));
            Caption = 'Scheduled Res. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(51; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(55; "Resource Gr. Filter"; Code[20])
        {
            Caption = 'Resource Gr. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(56; "Scheduled Res. Gr. Qty."; Decimal)
        {
            CalcFormula = sum("Job Planning Line"."Quantity (Base)" where("Job No." = field("No."),
                                                                           "Schedule Line" = const(true),
                                                                           Type = const(Resource),
                                                                           "Resource Group No." = field("Resource Gr. Filter"),
                                                                           "Planning Date" = field("Planning Date Filter")));
            Caption = 'Scheduled Res. Gr. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                Customer: Record Customer;
            begin
                if "Bill-to Customer No." <> '' then
                    Customer.Get("Bill-to Customer No.");

                if Customer.SelectCustomer(Customer) then begin
                    xRec := Rec;
                    "Bill-to Name" := Customer.Name;
                    Validate("Bill-to Customer No.", Customer."No.");
                end;
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if ShouldSearchForCustomerByName("Bill-to Customer No.") then
                    Validate("Bill-to Customer No.", Customer.GetCustNo("Bill-to Name"));
            end;
        }
        field(59; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(60; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(61; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code",
                        (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(63; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(64; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code",
                        (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(67; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            Editable = true;
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
#pragma warning disable AA0139
                PostCode.CheckClearPostCodeCityCounty(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", xRec."Bill-to Country/Region Code");
#pragma warning restore AA0139
            end;
        }
        field(68; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who pays for the project.';
        }
        field(80; "Task Billing Method"; Enum "Task Billing Method")
        {
            Caption = 'Task Billing Method';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                RecRef: RecordRef;
                FldRef: FieldRef;
            begin
                JobTask.SetRange("Job No.", "No.");
                if JobTask.IsEmpty() then
                    exit;

                if ("Task Billing Method" = "Task Billing Method"::"One customer") and
                    (xRec."Task Billing Method" = XRec."Task Billing Method"::"Multiple customers") then begin
                    RecRef.GetTable(Rec);
                    FldRef := RecRef.Field(Rec.FieldNo("Task Billing Method"));
                    Error(UpdateBillingMethodErr, FldRef.GetEnumValueCaption(Rec."Task Billing Method".AsInteger() + 1), FieldCaption("Task Billing Method"), TableCaption());
                end;

                if "Task Billing Method" = "Task Billing Method"::"Multiple customers" then
                    if not Confirm(UpdateBillingMethodQst, true) then
                        Error('');

                InitCustomerOnJobTasks();
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(1000; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            TableRelation = "Job WIP Method".Code where(Valid = const(true));

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                JobWIPMethod: Record "Job WIP Method";
                ConfirmManagement: Codeunit "Confirm Management";
                NewWIPMethod: Code[20];
            begin
                if "WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobWIPMethod.Get("WIP Method");
                    if not JobWIPMethod."WIP Cost" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Cost"));
                    if not JobWIPMethod."WIP Sales" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Sales"));
                end;

                JobTask.SetRange("Job No.", "No.");
                JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
                if JobTask.FindFirst() then
                    if ConfirmManagement.GetResponseOrDefault(StrSubstNo(WIPMethodQst, JobTask.FieldCaption("WIP Method"), JobTask.TableCaption(), JobTask."WIP-Total"), true) then begin
                        JobTask.ModifyAll("WIP Method", "WIP Method", true);
                        // An additional FIND call requires since JobTask.MODIFYALL changes the Job's information
                        NewWIPMethod := "WIP Method";
                        Find();
                        "WIP Method" := NewWIPMethod;
                    end;
            end;
        }
        field(1001; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCurrencyCode(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Currency Code" <> xRec."Currency Code" then
                    if not JobLedgEntryExist() then begin
                        CurrencyUpdatePlanningLines();
                        CurrencyUpdatePurchLines();
                    end else
                        Error(AssociatedEntriesExistErr, FieldCaption("Currency Code"), TableCaption);
                if "Currency Code" <> '' then begin
                    Validate("Invoice Currency Code", '');
                    ClearInvCurrencyCodeOnJobTasks();
                end;
            end;
        }
        field(1002; "Bill-to Contact No."; Code[20])
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact."No.";

            trigger OnLookup()
            begin
                BilltoContactLookup();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToContactNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then
                    if ("Bill-to Contact No." = '') and ("Bill-to Customer No." = '') then begin
                        Init();
                        "No. Series" := xRec."No. Series";
                        Validate(Description, xRec.Description);
                    end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then begin
                    Cont.Get("Bill-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                        if ContBusinessRelation."Contact No." <> Cont."Company No." then
                            Error(ContactBusRelDiffCompErr, Cont."No.", Cont.Name, "Bill-to Customer No.");
                end;
                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(1003; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(1004; "Planning Date Filter"; Date)
        {
            Caption = 'Planning Date Filter';
            FieldClass = FlowFilter;
        }
        field(1005; "Total WIP Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                         "Job Complete" = const(false),
                                                                         Type = filter("Accrued Costs" | "Applied Costs" | "Recognized Costs")));
            Caption = 'Total WIP Cost Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1006; "Total WIP Cost G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                             Reversed = const(false),
                                                                             "Job Complete" = const(false),
                                                                             Type = filter("Accrued Costs" | "Applied Costs" | "Recognized Costs")));
            Caption = 'Total WIP Cost G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1007; "WIP Entries Exist"; Boolean)
        {
            CalcFormula = exist("Job WIP Entry" where("Job No." = field("No.")));
            Caption = 'WIP Entries Exist';
            FieldClass = FlowField;
        }
        field(1008; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            Editable = false;
        }
        field(1009; "WIP G/L Posting Date"; Date)
        {
            CalcFormula = min("Job WIP G/L Entry"."WIP Posting Date" where(Reversed = const(false),
                                                                            "Job No." = field("No.")));
            Caption = 'WIP G/L Posting Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1011; "Invoice Currency Code"; Code[10])
        {
            Caption = 'Invoice Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if ("Invoice Currency Code" <> xRec."Invoice Currency Code") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers")
                    and ("Invoice Currency Code" <> '') then
                    MessageIfJobTaskExist(FieldCaption("Invoice Currency Code"));

                if "Invoice Currency Code" <> '' then
                    Validate("Currency Code", '');
            end;
        }
        field(1012; "Exch. Calculation (Cost)"; Option)
        {
            Caption = 'Exch. Calculation (Cost)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1013; "Exch. Calculation (Price)"; Option)
        {
            Caption = 'Exch. Calculation (Price)';
            OptionCaption = 'Fixed FCY,Fixed LCY';
            OptionMembers = "Fixed FCY","Fixed LCY";
        }
        field(1014; "Allow Schedule/Contract Lines"; Boolean)
        {
            Caption = 'Allow Budget/Billable Lines';
        }
        field(1015; Complete; Boolean)
        {
            Caption = 'Complete';

            trigger OnValidate()
            begin
                if Complete <> xRec.Complete then
                    ChangeJobCompletionStatus();
            end;
        }
        field(1017; "Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                         Type = filter("Recognized Sales")));
            Caption = 'Recog. Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1018; "Recog. Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                             Reversed = const(false),
                                                                             Type = filter("Recognized Sales")));
            Caption = 'Recog. Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1019; "Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job WIP Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                        Type = filter("Recognized Costs")));
            Caption = 'Recog. Costs Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1020; "Recog. Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                            Reversed = const(false),
                                                                            Type = filter("Recognized Costs")));
            Caption = 'Recog. Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1021; "Total WIP Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job WIP Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                        "Job Complete" = const(false),
                                                                        Type = filter("Accrued Sales" | "Applied Sales" | "Recognized Sales")));
            Caption = 'Total WIP Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1022; "Total WIP Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                            Reversed = const(false),
                                                                            "Job Complete" = const(false),
                                                                            Type = filter("Accrued Sales" | "Applied Sales" | "Recognized Sales")));
            Caption = 'Total WIP Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1023; "WIP Completion Calculated"; Boolean)
        {
            CalcFormula = exist("Job WIP Entry" where("Job No." = field("No."),
                                                       "Job Complete" = const(true)));
            Caption = 'WIP Completion Calculated';
            FieldClass = FlowField;
        }
        field(1024; "Next Invoice Date"; Date)
        {
            CalcFormula = min("Job Planning Line"."Planning Date" where("Job No." = field("No."),
                                                                         "Contract Line" = const(true),
                                                                         "Qty. to Invoice" = filter(<> 0)));
            Caption = 'Next Invoice Date';
            FieldClass = FlowField;
        }
        field(1025; "Apply Usage Link"; Boolean)
        {
            Caption = 'Apply Usage Link';

            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
                JobLedgerEntry: Record "Job Ledger Entry";
                JobUsageLink: Record "Job Usage Link";
                NewApplyUsageLink: Boolean;
            begin
                if "Apply Usage Link" then begin
                    JobLedgerEntry.SetCurrentKey("Job No.");
                    JobLedgerEntry.SetRange("Job No.", "No.");
                    JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
                    JobLedgerEntry.SetLoadFields("Job No.", "Entry No.");
                    if JobLedgerEntry.FindFirst() then begin
                        JobUsageLink.SetRange("Entry No.", JobLedgerEntry."Entry No.");
                        if JobUsageLink.IsEmpty() then
                            Error(ApplyUsageLinkErr, TableCaption);
                    end;

                    JobPlanningLine.SetCurrentKey("Job No.");
                    JobPlanningLine.SetRange("Job No.", "No.");
                    JobPlanningLine.SetRange("Schedule Line", true);
                    if JobPlanningLine.FindSet() then begin
                        repeat
                            JobPlanningLine.Validate("Usage Link", true);
                            if JobPlanningLine."Planning Date" = 0D then
                                JobPlanningLine.Validate("Planning Date", WorkDate());
                            JobPlanningLine.Modify(true);
                        until JobPlanningLine.Next() = 0;

                        NewApplyUsageLink := "Apply Usage Link";
                        RefreshModifiedRec();
                        "Apply Usage Link" := NewApplyUsageLink;
                    end;
                end;
            end;
        }
        field(1026; "WIP Warnings"; Boolean)
        {
            CalcFormula = exist("Job WIP Warning" where("Job No." = field("No.")));
            Caption = 'WIP Warnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1027; "WIP Posting Method"; Option)
        {
            Caption = 'WIP Posting Method';
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";

            trigger OnValidate()
            var
                JobLedgerEntry: Record "Job Ledger Entry";
                JobWIPEntry: Record "Job WIP Entry";
                JobWIPMethod: Record "Job WIP Method";
            begin
                if xRec."WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobLedgerEntry.SetRange("Job No.", "No.");
                    JobLedgerEntry.SetFilter("Amt. Posted to G/L", '<>%1', 0);
                    if not JobLedgerEntry.IsEmpty() then
                        Error(WIPAlreadyPostedErr, FieldCaption("WIP Posting Method"), xRec."WIP Posting Method");
                end;

                JobWIPEntry.SetRange("Job No.", "No.");
                if not JobWIPEntry.IsEmpty() then
                    Error(WIPAlreadyAssociatedErr, FieldCaption("WIP Posting Method"));

                if "WIP Posting Method" = "WIP Posting Method"::"Per Job Ledger Entry" then begin
                    JobWIPMethod.Get("WIP Method");
                    if not JobWIPMethod."WIP Cost" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Cost"));
                    if not JobWIPMethod."WIP Sales" then
                        Error(WIPPostMethodErr, FieldCaption("WIP Posting Method"), FieldCaption("WIP Method"), JobWIPMethod.FieldCaption("WIP Sales"));
                end;
            end;
        }
        field(1028; "Applied Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                             Reverse = const(false),
                                                                             "Job Complete" = const(false),
                                                                             Type = filter("Applied Costs")));
            Caption = 'Applied Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1029; "Applied Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Job WIP G/L Entry"."WIP Entry Amount" where("Job No." = field("No."),
                                                                             Reverse = const(false),
                                                                             "Job Complete" = const(false),
                                                                             Type = filter("Applied Sales")));
            Caption = 'Applied Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1030; "Calc. Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job Task"."Recognized Sales Amount" where("Job No." = field("No.")));
            Caption = 'Calc. Recog. Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1031; "Calc. Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job Task"."Recognized Costs Amount" where("Job No." = field("No.")));
            Caption = 'Calc. Recog. Costs Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1032; "Calc. Recog. Sales G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job Task"."Recognized Sales G/L Amount" where("Job No." = field("No.")));
            Caption = 'Calc. Recog. Sales G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1033; "Calc. Recog. Costs G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Job Task"."Recognized Costs G/L Amount" where("Job No." = field("No.")));
            Caption = 'Calc. Recog. Costs G/L Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(1034; "WIP Completion Posted"; Boolean)
        {
            CalcFormula = exist("Job WIP G/L Entry" where("Job No." = field("No."),
                                                           "Job Complete" = const(true)));
            Caption = 'WIP Completion Posted';
            FieldClass = FlowField;
        }
        field(1035; "Over Budget"; Boolean)
        {
            Caption = 'Over Budget';
        }
        field(1036; "Project Manager"; Code[50])
        {
            Caption = 'Project Manager';
            TableRelation = "User Setup";
        }
        field(2000; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                SellToCustomerNoUpdated(Rec, xRec);
            end;
        }
        field(2001; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                CustomerName: Text;
            begin
                CustomerName := "Sell-to Customer Name";
                LookupSellToCustomerName(CustomerName);
                "Sell-to Customer Name" := CopyStr(CustomerName, 1, MaxStrLen("Sell-to Customer Name"));
            end;

            trigger OnValidate()
            var
                Customer: Record Customer;
                LookupStateManager: Codeunit "Lookup State Manager";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToCustomerName(Rec, Customer, IsHandled);
                if IsHandled then begin
                    if LookupStateManager.IsRecordSaved() then
                        LookupStateManager.ClearSavedRecord();
                    exit;
                end;

                if LookupStateManager.IsRecordSaved() then begin
                    Customer := LookupStateManager.GetSavedRecord();
                    if Customer."No." <> '' then begin
                        LookupStateManager.ClearSavedRecord();
                        Validate("Sell-to Customer No.", Customer."No.");

                        exit;
                    end;
                end;

                if ShouldSearchForCustomerByName("Sell-to Customer No.") then
                    Validate("Sell-to Customer No.", Customer.GetCustNo("Sell-to Customer Name"));
            end;
        }
        field(2002; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        field(2003; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
        }
        field(2004; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
        }
        field(2005; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code",
                        (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(2006; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
        }
        field(2007; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(2008; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
        }
        field(2009; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(2010; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(2011; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "Sell-to E-Mail" = '' then
                    exit;
                MailManagement.CheckValidEmailAddresses("Sell-to E-Mail");
            end;
        }
        field(2012; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            begin
                SelltoContactLookup();
            end;

            trigger OnValidate()
            var
                Contact: Record Contact;
                ContactBusinessRelation: Record "Contact Business Relation";
            begin
                if ("Sell-to Contact No." <> xRec."Sell-to Contact No.") and
                   (xRec."Sell-to Contact No." <> '')
                then
                    if ("Sell-to Contact No." = '') and ("Sell-to Customer No." = '') then begin
                        Init();
                        "No. Series" := xRec."No. Series";
                        Validate(Description, xRec.Description);
                    end;

                if ("Sell-to Customer No." <> '') and ("Sell-to Contact No." <> '') then begin
                    Contact.SetLoadFields(Name, "Company No.");
                    Contact.Get("Sell-to Contact No.");
                    if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, "Sell-to Customer No.") then
                        if ContactBusinessRelation."Contact No." <> Contact."Company No." then
                            Error(ContactBusRelDiffCompErr, Contact."No.", Contact.Name, "Sell-to Customer No.");
                end;
                if ("Sell-to Contact No." <> xRec."Sell-to Contact No.") then
                    UpdateSellToCust("Sell-to Contact No.");

                UpdateShipToContact();
            end;
        }
        field(3000; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));

            trigger OnValidate()
            begin
                if ("Ship-to Code" <> xRec."Ship-to Code") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers") then
                    MessageIfJobTaskExist(FieldCaption("Ship-to Code"));

                ShipToCodeValidate();
            end;
        }
        field(3001; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(3002; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(3003; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(3004; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(3005; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code",
                        (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(3006; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(3007; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                    "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(3008; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(3009; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(3997; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Job Archive"."Version No." where("No." = field("No.")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4000; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            begin
                if ("External Document No." <> xRec."External Document No.") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers") then
                    MessageIfJobTaskExist(FieldCaption("External Document No."));
            end;
        }
        field(4001; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            begin
                if ("Payment Method Code" <> xRec."Payment Method Code") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers") then
                    MessageIfJobTaskExist(FieldCaption("Payment Method Code"));
            end;
        }
        field(4002; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                if ("Payment Terms Code" <> xRec."Payment Terms Code") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers") then
                    MessageIfJobTaskExist(FieldCaption("Payment Terms Code"));
            end;
        }
        field(4003; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';

            trigger OnValidate()
            begin
                if ("Your Reference" <> xRec."Your Reference") and ("Task Billing Method" = "Task Billing Method"::"Multiple customers") then
                    MessageIfJobTaskExist(FieldCaption("Your Reference"));
            end;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Cost Calculation Method" <> "Cost Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Cost Calculation Method", PriceType::Purchase);
            end;
        }
        field(7300; "Completely Picked"; Boolean)
        {
            CalcFormula = min("Job Planning Line"."Completely Picked" where("Job No." = field("No.")));
            Caption = 'Completely Picked';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "Bill-to Customer No.")
        {
        }
        key(Key4; Description)
        {
        }
        key(Key5; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Bill-to Customer No.", "Starting Date", Status)
        {
        }
        fieldgroup(Brick; "No.", Description, "Bill-to Customer No.", "Starting Date", Status, Image)
        {
        }
    }

    trigger OnDelete()
    var
        WarehouseRequest: Record "Warehouse Request";
        CommentLine: Record "Comment Line";
        MoveEntries: Codeunit MoveEntries;
        JobArchiveManagement: Codeunit "Job Archive Management";
    begin
        ConfirmDeletion();

        MoveEntries.MoveJobEntries(Rec);

        JobArchiveManagement.AutoArchiveJob(Rec);

        DeleteRelatedJobTasks();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Job);
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(Database::Job, "No.");

        if "Project Manager" <> '' then
            RemoveFromMyJobs();

        // Delete all warehouse requests and warehouse pick requests associated with the Job
        WarehouseRequest.DeleteRequest(Database::Job, 0, "No.");
        DeleteWhsePickRelation();
    end;

    trigger OnInsert()
    begin
        JobsSetup.Get();

        InitJobNo();
        InitBillToCustomerNo();

        if not "Apply Usage Link" then
            Validate("Apply Usage Link", JobsSetup."Apply Usage Link by Default");
        if not "Allow Schedule/Contract Lines" then
            Validate("Allow Schedule/Contract Lines", JobsSetup."Allow Sched/Contract Lines Def");
        if "WIP Method" = '' then
            Validate("WIP Method", JobsSetup."Default WIP Method");
        InitDefaultJobPostingGroup();
        Validate("WIP Posting Method", JobsSetup."Default WIP Posting Method");
        "Task Billing Method" := JobsSetup."Default Task Billing Method";

        InitGlobalDimFromDefalutDim();
        InitWIPFields();

        "Creation Date" := Today;
        "Last Date Modified" := "Creation Date";

        if ("Project Manager" <> '') and (Status = Status::Open) then
            AddToMyJobs("Project Manager");

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        CheckRemoveFromMyJobsFromModify();

        if ("Project Manager" <> '') and (xRec."Project Manager" <> "Project Manager") then
            if Status = Status::Open then
                AddToMyJobs("Project Manager");
    end;

    trigger OnRename()
    var
        CommentLine: Record "Comment Line";
    begin
        UpdateJobNoInReservationEntries();
        DimMgt.RenameDefaultDim(Database::Job, xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::Job, xRec."No.", "No.");
        "Last Date Modified" := Today;
    end;

    var
        JobsSetup: Record "Jobs Setup";
        PostCode: Record "Post Code";
        Job: Record Job;
        Cont: Record Contact;
        ContBusinessRelation: Record "Contact Business Relation";
        Location: Record Location;
        HideValidationDialog: Boolean;

        AssociatedEntriesExistErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = Name of field used in the error; %2 = The name of the Project table';
        StatusChangeQst: Label 'This will delete any unposted WIP entries for this project and allow you to reverse the completion postings for this project.\\Do you wish to continue?';
        ContactBusRelDiffCompErr: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job';
        ContactBusRelErr: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job';
        ContactBusRelMissingErr: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1 = The contact number; %2 = The contact''s name';
        TestBlockedErr: Label '%1 %2 must not be blocked with type %3.', Comment = '%1 = The Project table name; %2 = The Project number; %3 = The value of the Blocked field';
        ReverseCompletionEntriesMsg: Label 'You must run the %1 function to reverse the completion entries that have already been posted for this project.', Comment = '%1 = The name of the Project Post WIP to G/L report';
        CheckDateErr: Label '%1 must be equal to or earlier than %2.', Comment = '%1 = The project''s starting date; %2 = The project''s ending date';
        ApplyUsageLinkErr: Label 'A usage link cannot be enabled for the entire %1 because usage without the usage link already has been posted.', Comment = '%1 = The name of the Project table';
        WIPMethodQst: Label 'Do you want to set the %1 on every %2 of type %3?', Comment = '%1 = The WIP Method field name; %2 = The name of the Project Task table; %3 = The current project task''s WIP Total type';
        WIPAlreadyPostedErr: Label '%1 must be %2 because project WIP general ledger entries already were posted with this setting.', Comment = '%1 = The name of the WIP Posting Method field; %2 = The previous WIP Posting Method value of this project';
        WIPAlreadyAssociatedErr: Label '%1 cannot be modified because the project has associated project WIP entries.', Comment = '%1 = The name of the WIP Posting Method field';
        WIPPostMethodErr: Label 'The selected %1 requires the %2 to have %3 enabled.', Comment = '%1 = The name of the WIP Posting Method field; %2 = The name of the WIP Method field; %3 = The field caption represented by the value of this project''s WIP method';
        EndingDateChangedMsg: Label '%1 is set to %2.', Comment = '%1 = The name of the Ending Date field; %2 = This project''s Ending Date value';
        UpdateJobTaskDimQst: Label 'You have changed a dimension.\\Do you want to update the lines?';
        RunWIPFunctionsQst: Label 'You must run the Project Calculate WIP function to create completion entries for this project. \Do you want to run this function now?';
        ReservEntriesItemTrackLinesDeleteQst: Label 'All reservation entries and item tracking lines for this project will be deleted. \Do you want to continue?';
        ReservEntriesItemTrackLinesExistErr: Label 'You cannot set the status to %1 because the project has reservations or item tracking lines on the project planning lines.', Comment = '%1=The project status name';
        AutoReserveNotPossibleMsg: Label 'Automatic reservation is not possible for one or more project planning lines. \Please reserve manually.';
        WhseCompletelyPickedErr: Label 'All of the items on the project planning lines are completely picked.';
        WhseNoItemsToPickErr: Label 'There are no items to pick on the project planning lines.';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        SellToCustomerTxt: Label 'Sell-to Customer';
        BillToCustomerTxt: Label 'Bill-to Customer';
        StatusCompletedErr: Label 'You cannot select Project No.: %1 as it is already completed.', Comment = '%1= The Project No.';
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the project, %2, will be deleted. Do you want to continue?', Comment = '%1 - Contact No., %2 - Email';
        TasksNotUpdatedMsg: Label 'You have changed %1 on the project, but it has not been changed on the existing project tasks.', Comment = '%1 = a Field Caption like Location Code';
        UpdateTasksManuallyMsg: Label 'You must update the existing project tasks manually.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        UpdateBillingMethodQst: Label 'This change will make a difference to how project tasks are billed. This is irreversible. Do you want to continue?';
        UpdateBillingMethodErr: Label 'You cannot select %1 in %2, because one or more Project Tasks exist for this %3.', Comment = '%1 = Caption of the Task Billing Method field value; %2 = Caption of the Task Billing Method field; %3 = Caption of the Project table';
        UpdateCostPricesOnRelatedLinesQst: Label 'You have changed a customer. Prices and costs needs to be updated on a related lines.\\Do you want to update related lines?';
        ConfirmDeleteQst: Label 'The items have been picked. If you delete the Job, then the items will remain in the operation area until you put them away.\Related item tracking information that is defined during the pick will be deleted.\Are you sure that you want to delete the Job?';

    protected var
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;
        SkipSellToContact: Boolean;

    procedure AssistEdit(OldJob: Record Job) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldJob, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Job := Rec;
        JobsSetup.Get();
        JobsSetup.TestField("Job Nos.");
        if NoSeries.LookupRelatedNoSeries(JobsSetup."Job Nos.", OldJob."No. Series", Job."No. Series") then begin
            Job."No." := NoSeries.GetNextNo(Job."No. Series");
            Rec := Job;
            exit(true);
        end;
    end;

    procedure GetCostCalculationMethod() Method: Enum "Price Calculation Method";
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        if "Cost Calculation Method" <> Method::" " then
            Method := "Cost Calculation Method"
        else begin
            PurchasesPayablesSetup.Get();
            Method := PurchasesPayablesSetup."Price Calculation Method";
        end;
    end;

    procedure GetPriceCalculationMethod() Method: Enum "Price Calculation Method";
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if "Price Calculation Method" <> Method::" " then
            Method := "Price Calculation Method"
        else begin
            Method := GetCustomerPriceGroupPriceCalcMethod();
            if Method = Method::" " then begin
                SalesReceivablesSetup.Get();
                Method := SalesReceivablesSetup."Price Calculation Method";
            end;
        end;
    end;

    local procedure GetCustomerPriceGroupPriceCalcMethod(): Enum "Price Calculation Method";
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        if "Customer Price Group" <> '' then
            if CustomerPriceGroup.Get("Customer Price Group") then
                exit(CustomerPriceGroup."Price Calculation Method");
    end;

    local procedure CheckRemoveFromMyJobsFromModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRemoveFromMyJobsFromModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if (("Project Manager" <> xRec."Project Manager") and (xRec."Project Manager" <> '')) or (Status <> Status::Open) then
            RemoveFromMyJobs();
    end;

    local procedure InitJobNo()
    var
        Job2: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitJobNo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            JobsSetup.TestField("Job Nos.");
            "No. Series" := JobsSetup."Job Nos.";
            OnInitJobNoOnAfterAssignNoSeries(Rec, xRec, JobsSetup);
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series");
            Job2.ReadIsolation(IsolationLevel::ReadUncommitted);
            Job2.SetLoadFields("No.");
            while Job2.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    local procedure InitBillToCustomerNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitBillToCustomerNo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if GetFilter("Bill-to Customer No.") <> '' then
            if GetRangeMin("Bill-to Customer No.") = GetRangeMax("Bill-to Customer No.") then begin
                Validate("Bill-to Customer No.", GetRangeMin("Bill-to Customer No."));
                if "Sell-to Customer No." = '' then
                    Validate("Sell-to Customer No.", "Bill-to Customer No.");
            end;
    end;

    local procedure AsPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Source Type" := PriceSource."Source Type"::Job;
        PriceSource."Source No." := "No.";
    end;

    procedure ShowPriceListLines(PriceType: Enum "Price Type"; AssetType: Enum "Price Asset Type";
                                                AmountType: Enum "Price Amount Type")
    var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";
        PriceUXManagement: Codeunit "Price UX Management";
    begin
        PriceAsset.InitAsset();
        PriceAsset.Validate("Asset Type", AssetType);
        AsPriceSource(PriceSource);
        PriceSource."Price Type" := PriceType;
        PriceUXManagement.ShowPriceListLines(PriceSource, PriceAsset, AmountType);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::Job, "No.", FieldNumber, ShortcutDimCode);
            UpdateJobTaskDimension(FieldNumber, ShortcutDimCode);
            Modify();
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure UpdateBillToContact(CustomerNo: Code[20])
    begin
        GetCustomerContact(CustomerNo, Rec."Bill-to Contact No.", Rec."Bill-to Contact");

        OnAfterUpdateBillToContact(Rec, xRec);
    end;

    protected procedure UpdateSellToContact(CustomerNo: Code[20])
    begin
        GetCustomerContact(CustomerNo, Rec."Sell-to Contact No.", Rec."Sell-to Contact");
    end;

    local procedure GetCustomerContact(CustomerNo: Code[20]; var ContactNo: Code[20]; var Contact: Text[100])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("Primary Contact No.", Contact);
        if Customer.Get(CustomerNo) then begin
            if Customer."Primary Contact No." <> '' then
                ContactNo := Customer."Primary Contact No."
            else begin
                ContactBusinessRelation.SetCurrentKey("Link to Table", "No.");
                ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
                ContactBusinessRelation.SetRange("No.", CustomerNo);
                ContactBusinessRelation.SetLoadFields("Contact No.");
                if ContactBusinessRelation.FindFirst() then
                    ContactNo := ContactBusinessRelation."Contact No.";
            end;
            Contact := Customer.Contact;
        end;
    end;

    procedure JobLedgEntryExist() Result: Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetCurrentKey("Job No.");
        JobLedgerEntry.SetRange("Job No.", "No.");
        Result := not JobLedgerEntry.IsEmpty();
        OnAfterJobLedgEntryExist(JobLedgerEntry, Result);
    end;

    procedure SalesJobLedgEntryExist() Result: Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", "No.");
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);
        Result := not JobLedgerEntry.IsEmpty();
    end;

    procedure SalesLineExist() Result: Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if "No." = '' then
            exit(false);

        SalesLine.SetRange("Job No.", "No.");
        Result := not SalesLine.IsEmpty();
    end;

    procedure JobPlanningLineExist() Result: Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.SetRange("Job No.", "No.");
        Result := not JobPlanningLine.IsEmpty();
        OnAfterJobPlanningLineExist(JobPlanningLine, Result);
    end;

    procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        if Contact.Get(ContactNo) then begin
            "Bill-to Contact No." := Contact."No.";
            if Contact.Type = Contact.Type::Person then
                "Bill-to Contact" := Contact.Name
            else
                if Customer.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Customer.Contact
                else
                    "Bill-to Contact" := '';
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        OnUpdateBillToCustOnAfterAssignBillToContact(Rec, Contact);

        if ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Contact."Company No.") then begin
            if "Bill-to Customer No." = '' then
                Validate("Bill-to Customer No.", ContactBusinessRelation."No.")
            else
                CheckContactBillToCustomerBusRelation();
        end else
            ShowContactBillToCustomerBusRelationMissingError();
    end;

    local procedure CheckContactBillToCustomerBusRelation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactBillToCustomerBusRelation(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if "Bill-to Customer No." <> ContBusinessRelation."No." then
            Error(ContactBusRelErr, Cont."No.", Cont.Name, "Bill-to Customer No.");
    end;

    local procedure ShowContactBillToCustomerBusRelationMissingError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowContactBillToCustomerBusRelationMissingError(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Error(ContactBusRelMissingErr, Cont."No.", Cont.Name);
    end;

    procedure SelltoCustomerNoOnAfterValidate(var JobRec: Record "Job"; var xJobRec: Record "Job")
    begin
        if JobRec.GetFilter("Sell-to Customer No.") = xJobRec."Sell-to Customer No." then
            if JobRec."Sell-to Customer No." <> xJobRec."Sell-to Customer No." then
                JobRec.SetRange("Sell-to Customer No.");
    end;

    procedure LookupSellToCustomerName(var CustomerName: Text): Boolean
    var
        Customer: Record Customer;
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
        SearchCustomerName: Text;
    begin
        SearchCustomerName := CustomerName;
        Customer.SetFilter("Date Filter", GetFilter("Posting Date Filter"));
        if "Sell-to Customer No." <> '' then
            Customer.Get("Sell-to Customer No.");

        if Customer.SelectCustomer(Customer) then begin
            if Rec."Sell-to Customer Name" = Customer.Name then
                CustomerName := SearchCustomerName
            else
                CustomerName := Customer.Name;
            RecVariant := Customer;
            LookupStateManager.SaveRecord(RecVariant);
            exit(true);
        end;
    end;

    procedure InitWIPFields()
    begin
        "WIP Posting Date" := 0D;
        "WIP G/L Posting Date" := 0D;
    end;

    local procedure InitGlobalDimFromDefalutDim()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitGlobalDimFromDefalutDim(Rec, IsHandled);
        if IsHandled then
            exit;

        DimMgt.UpdateDefaultDim(
            Database::Job, "No.",
            "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    procedure TestBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestBlocked(Rec, IsHandled);
        if IsHandled then
            exit;

        if Blocked = Blocked::" " then
            exit;
        Error(TestBlockedErr, TableCaption(), "No.", Blocked);
    end;

    procedure CurrencyUpdatePlanningLines()
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCurrencyUpdatePlanningLines(Rec, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.SetRange("Job No.", "No.");
        JobPlanningLine.SetAutoCalcFields("Qty. Transferred to Invoice");
        JobPlanningLine.LockTable();
        if JobPlanningLine.Find('-') then
            repeat
                OnCurrencyUpdatePlanningLinesOnBeforeUpdateJobPlanningLine(Job, JobPlanningLine);
                if JobPlanningLine."Qty. Transferred to Invoice" <> 0 then
                    Error(AssociatedEntriesExistErr, FieldCaption("Currency Code"), TableCaption);
                JobPlanningLine.Validate("Currency Code", "Currency Code");
                JobPlanningLine.Validate("Currency Date");
                JobPlanningLine.Modify();
            until JobPlanningLine.Next() = 0;
    end;

    procedure TestStatusCompleted()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestStatusCompleted(Rec, IsHandled);
        if IsHandled then
            exit;

        if not (Status = Status::Completed) then
            exit;
        Error(StatusCompletedErr, "No.");
    end;

    local procedure CurrencyUpdatePurchLines()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Modify();
        PurchaseLine.SetRange("Job No.", "No.");
        if PurchaseLine.FindSet(true) then
            repeat
                PurchaseLine.Validate("Job Currency Code", "Currency Code");
                PurchaseLine.Validate("Job Task No.");
                PurchaseLine.Modify();
            until PurchaseLine.Next() = 0;
    end;

    local procedure ChangeJobCompletionStatus()
    var
        WarehouseRequest: Record "Warehouse Request";
        JobCalcWIP: Codeunit "Job Calculate WIP";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeJobCompletionStatus(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Complete then begin
            Validate("Ending Date", CalcEndingDate());
            Message(EndingDateChangedMsg, FieldCaption("Ending Date"), "Ending Date");

            WarehouseRequest.DeleteRequest(Database::Job, 0, "No.");
            DeleteWhsePickRelation();
        end else begin
            JobCalcWIP.ReOpenJob("No.");
            "WIP Posting Date" := 0D;
            Message(ReverseCompletionEntriesMsg, GetReportCaption(Report::"Job Post WIP to G/L"));
        end;

        OnAfterChangeJobCompletionStatus(Rec, xRec);
    end;

    procedure CreateInvtPutAwayPick()
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        TestField(Status, Status::Open);

        WarehouseRequest.SetCurrentKey("Source Document", "Source No.");
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Job Usage");
        WarehouseRequest.SetRange("Source Type", Database::Job);
        WarehouseRequest.SetRange("Source No.", "No.");
        Report.RunModal(Report::"Create Invt Put-away/Pick/Mvmt", true, false, WarehouseRequest);
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Job, GetPosition());
    end;

    procedure GetQuantityAvailable(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; InEntryType: Option Usage,Sale,Both; Direction: Option Positive,Negative,Both): Decimal
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetCurrentKey("Job No.", "Entry Type", Type, "No.");
        JobLedgerEntry.SetRange("Job No.", "No.");
        if not (InEntryType = InEntryType::Both) then
            JobLedgerEntry.SetRange("Entry Type", InEntryType);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", ItemNo);
        case Direction of
            Direction::Both:
                begin
                    JobLedgerEntry.SetRange("Location Code", LocationCode);
                    JobLedgerEntry.SetRange("Variant Code", VariantCode);
                end;
            Direction::Positive:
                JobLedgerEntry.SetFilter("Quantity (Base)", '>0');
            Direction::Negative:
                JobLedgerEntry.SetFilter("Quantity (Base)", '<0');
        end;
        OnGetQuantityAvailableOnAfterSetFiltersOnJobLedgerEntry(ItemNo, LocationCode, VariantCode, InEntryType, Direction, JobLedgerEntry);
        JobLedgerEntry.CalcSums("Quantity (Base)");
        exit(JobLedgerEntry."Quantity (Base)");
    end;

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(CheckDateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;

    procedure CalcAccWIPCostsAmount(): Decimal
    begin
        exit("Total WIP Cost Amount" + "Applied Costs G/L Amount");
    end;

    procedure CalcAccWIPSalesAmount(): Decimal
    begin
        exit("Total WIP Sales Amount" - "Applied Sales G/L Amount");
    end;

    procedure CalcRecognizedProfitAmount() Result: Decimal
    begin
        CalcFields("Calc. Recog. Sales Amount", "Calc. Recog. Costs Amount");
        Result := "Calc. Recog. Sales Amount" - "Calc. Recog. Costs Amount";
        OnAfterCalcRecognizedProfitAmount(Result);
    end;

    procedure CalcRecognizedProfitPercentage(): Decimal
    begin
        if "Calc. Recog. Sales Amount" <> 0 then
            exit((CalcRecognizedProfitAmount() / "Calc. Recog. Sales Amount") * 100);
        exit(0);
    end;

    procedure CalcRecognizedProfitGLAmount(): Decimal
    begin
        CalcFields("Calc. Recog. Sales G/L Amount", "Calc. Recog. Costs G/L Amount");
        exit("Calc. Recog. Sales G/L Amount" - "Calc. Recog. Costs G/L Amount");
    end;

    procedure CalcRecognProfitGLPercentage(): Decimal
    begin
        if "Calc. Recog. Sales G/L Amount" <> 0 then
            exit((CalcRecognizedProfitGLAmount() / "Calc. Recog. Sales G/L Amount") * 100);
        exit(0);
    end;

    procedure CopyDefaultDimensionsFromCustomer()
    var
        CustDefaultDimension: Record "Default Dimension";
        JobDefaultDimension: Record "Default Dimension";
        Job2: Record Job;
        IsHandled: Boolean;
        JobExistsInDB: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDefaultDimensionsFromCustomer(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        Job2.SetRange("No.", Rec."No.");
        JobExistsInDB := not Job2.IsEmpty();
        if JobExistsInDB then
            Rec.Modify();

        DimMgt.SetSkipUpdateDimensions(Rec."Task Billing Method" = Rec."Task Billing Method"::"Multiple customers");

        JobDefaultDimension.SetRange("Table ID", Database::Job);
        JobDefaultDimension.SetRange("No.", "No.");
        if JobDefaultDimension.FindSet() then
            repeat
                DimMgt.DefaultDimOnDelete(JobDefaultDimension);
                DimMgt.SetSkipChangeDimensionsQst(true);
                JobDefaultDimension.Delete();
            until JobDefaultDimension.Next() = 0;
        if JobExistsInDB then
            Rec.Get(Rec."No.");

        CustDefaultDimension.SetRange("Table ID", Database::Customer);
        CustDefaultDimension.SetRange("No.", "Bill-to Customer No.");
        if CustDefaultDimension.FindSet() then
            repeat
                JobDefaultDimension.Init();
                JobDefaultDimension.TransferFields(CustDefaultDimension);
                JobDefaultDimension."Table ID" := Database::Job;
                JobDefaultDimension."No." := "No.";
                JobDefaultDimension.Insert();
                DimMgt.DefaultDimOnInsert(JobDefaultDimension);
            until CustDefaultDimension.Next() = 0;

        OnCopyDefaultDimensionsFromCustomerOnBeforeUpdateDefaultDim(Rec, CurrFieldNo);
        DimMgt.UpdateDefaultDim(Database::Job, "No.", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    procedure PercentCompleted() Result: Decimal
    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        CL: array[16] of Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePercentCompleted(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYCostAmounts(CL);
        if CL[4] <> 0 then
            exit((CL[8] / CL[4]) * 100);
        exit(0);
    end;

    procedure PercentInvoiced() Result: Decimal
    var
        JobCalcStatistics: Codeunit "Job Calculate Statistics";
        PL: array[16] of Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePercentInvoiced(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        JobCalcStatistics.JobCalculateCommonFilters(Rec);
        JobCalcStatistics.CalculateAmounts();
        JobCalcStatistics.GetLCYPriceAmounts(PL);
        if PL[12] <> 0 then
            exit((PL[16] / PL[12]) * 100);
        exit(0);
    end;

    procedure PercentOverdue() Result: Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
        QtyOverdue: Decimal;
        QtyTotal: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePercentOverdue(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        JobPlanningLine.SetRange("Job No.", "No.");
        QtyTotal := JobPlanningLine.Count();
        if QtyTotal = 0 then
            exit(0);
        JobPlanningLine.SetFilter("Planning Date", '<%1', WorkDate());
        JobPlanningLine.SetFilter("Remaining Qty.", '>%1', 0);
        QtyOverdue := JobPlanningLine.Count();
        exit((QtyOverdue / QtyTotal) * 100);
    end;

    local procedure UpdateJobNoInReservationEntries()
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetFilter("Source Type", '%1|%2', Database::"Job Planning Line", Database::"Job Journal Line");
        ReservEntry.SetRange("Source ID", xRec."No.");
        ReservEntry.ModifyAll("Source ID", "No.", true);
    end;

    procedure CheckReservationEntries(): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        ReservationToDeleteExists: Boolean;
    begin
        ReservationToDeleteExists := false;

        if Status <> Status::Open then begin
            ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
            ReservationEntry.SetRange("Source ID", "No.");
            ReservationToDeleteExists := not ReservationEntry.IsEmpty();
            if ReservationToDeleteExists then
                if not ConfirmManagement.GetResponseOrDefault(ReservEntriesItemTrackLinesDeleteQst, false) then
                    Error(ReservEntriesItemTrackLinesExistErr, Status);
        end;

        exit(ReservationToDeleteExists);
    end;

    procedure PerformAutoReserve(var JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
        FullAutoReservation: Boolean;
        AutoReservePossible: Boolean;
    begin
        JobPlanningLine.SetRange(Status, JobPlanningLine.Status::Order);
        JobPlanningLine.SetRange(Reserve, JobPlanningLine.Reserve::Always);
        JobPlanningLine.SetFilter("Remaining Qty. (Base)", '<>%1', 0);
        AutoReservePossible := JobPlanningLine.FindSet();
        if AutoReservePossible then begin
            repeat
                JobPlanningLineReserve.ReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
                ReservationManagement.SetReservSource(JobPlanningLine);
                ReservationManagement.AutoReserve(FullAutoReservation, '', JobPlanningLine."Planning Date", QtyToReserve, QtyToReserveBase);
                AutoReservePossible := AutoReservePossible and FullAutoReservation;
                JobPlanningLine.UpdatePlanned();
            until JobPlanningLine.Next() = 0;
            if not AutoReservePossible then
                Message(AutoReserveNotPossibleMsg);
        end;
    end;

    local procedure UpdateJobTaskDimension(FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobTaskDimension(Rec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed() and (not GetHideValidationDialog()) then
            if not Confirm(UpdateJobTaskDimQst, false) then
                exit;

        JobTask.SetRange("Job No.", "No.");
        if JobTask.FindSet(true) then
            repeat
                case FieldNumber of
                    1:
                        JobTask.Validate("Global Dimension 1 Code", ShortcutDimCode);
                    2:
                        JobTask.Validate("Global Dimension 2 Code", ShortcutDimCode);
                end;
                JobTask.Modify();
            until JobTask.Next() = 0;
    end;

    procedure UpdateOverBudgetValue(JobNo: Code[20]; Usage: Boolean; Cost: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        UsageCost: Decimal;
        ScheduleCost: Decimal;
        NewOverBudget: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateOverBudgetValue(Rec, JobNo, Usage, Cost, IsHandled);
        if IsHandled then
            exit;

        if "No." <> JobNo then
            if not Get(JobNo) then
                exit;

        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.CalcSums("Total Cost (LCY)");
        if JobLedgerEntry."Total Cost (LCY)" = 0 then
            exit;

        UsageCost := JobLedgerEntry."Total Cost (LCY)";

        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.CalcSums("Total Cost (LCY)");
        ScheduleCost := JobPlanningLine."Total Cost (LCY)";

        if Usage then
            UsageCost += Cost
        else
            ScheduleCost += Cost;
        NewOverBudget := UsageCost > ScheduleCost;
        if NewOverBudget <> "Over Budget" then begin
            "Over Budget" := NewOverBudget;
            Modify();
        end;
    end;

    local procedure AddToMyJobs(ProjectManager: Code[50])
    var
        MyJob: Record "My Job";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddToMyJobs(Rec, MyJob, ProjectManager, IsHandled);
        if IsHandled then
            exit;

        if Status <> Status::Open then
            exit;

        if MyJob.Get(ProjectManager, "No.") then begin
            MyJob.Description := Description;
            MyJob."Bill-to Name" := "Bill-to Name";
            MyJob."Percent Completed" := PercentCompleted();
            MyJob."Percent Invoiced" := PercentInvoiced();
            MyJob.Modify();
        end else begin
            MyJob.Init();
            MyJob."User ID" := ProjectManager;
            MyJob."Job No." := "No.";
            MyJob.Description := Description;
            MyJob.Status := Status;
            MyJob."Bill-to Name" := "Bill-to Name";
            MyJob."Percent Completed" := PercentCompleted();
            MyJob."Percent Invoiced" := PercentInvoiced();
            MyJob."Exclude from Business Chart" := false;
            MyJob.Insert();
        end;
    end;

    local procedure RemoveFromMyJobs()
    var
        MyJob: Record "My Job";
    begin
        MyJob.SetFilter("Job No.", '=%1', "No.");
        if MyJob.FindSet() then
            repeat
                MyJob.Delete();
            until MyJob.Next() = 0;
    end;

    local procedure DeleteWhsePickRelation()
    var
        WhsePickRequest: Record "Whse. Pick Request";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
        WhsePickRequest.SetRange("Document No.", Rec."No.");
        WhsePickRequest.DeleteAll(true);

        ItemTrackingManagement.DeleteWhseItemTrkgLines(Database::Job, 0, Rec."No.", '', 0, 0, '', false);
    end;

    local procedure DeleteRelatedJobTasks()
    var
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteRelatedJobTasks(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        JobTask.SetCurrentKey("Job No.");
        JobTask.SetRange("Job No.", "No.");
        JobTask.SuspendDeletionCheck(true);
        JobTask.DeleteAll(true);
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source"; PriceType: Enum "Price Type")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceType;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Job);
        PriceSource.Validate("Source No.", "No.");
    end;

    procedure SetJobDiffBuff(var TempJobDifferenceBuffer: Record "Job Difference Buffer" temporary; JobNo: Code[20]; JobTaskNo: Code[20]; JobTaskType: Option Posting,Heading,Total,"Begin-Total","End-Total"; Type: Option Resource,Item,"G/L Account",Text; No: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; UnitofMeasureCode: Code[10]; WorkTypeCode: Code[10])
    begin
        TempJobDifferenceBuffer.Init();
        TempJobDifferenceBuffer."Job No." := JobNo;
        TempJobDifferenceBuffer."Job Task No." := JobTaskNo;
        if JobTaskType = JobTaskType::Posting then begin
            TempJobDifferenceBuffer.Type := "Job Planning Line Type".FromInteger(Type);
            TempJobDifferenceBuffer."No." := No;
            TempJobDifferenceBuffer."Location Code" := LocationCode;
            TempJobDifferenceBuffer."Variant Code" := VariantCode;
            TempJobDifferenceBuffer."Unit of Measure code" := UnitofMeasureCode;
            TempJobDifferenceBuffer."Work Type Code" := WorkTypeCode;
        end;
    end;

    [Scope('OnPrem')]
    procedure SendRecords()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.SendCustomerRecords(
          DummyReportSelections.Usage::JQ.AsInteger(), Rec, ReportDistributionMgt.GetFullDocumentTypeText(Rec),
          "Bill-to Customer No.", "No.", FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportSelections: Record "Report Selections";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.Send(
          ReportSelections.Usage::JQ.AsInteger(), Rec, "No.", "Bill-to Customer No.",
          ReportDistributionManagement.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), FieldNo("No."));
    end;

    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
    begin
        DocumentSendingProfile.TrySendToPrinter(
          ReportSelections.Usage::JQ.AsInteger(), Rec, FieldNo("Bill-to Customer No."), ShowRequestForm);
    end;

    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        ReportSelections: Record "Report Selections";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.TrySendToEMail(
          ReportSelections.Usage::JQ.AsInteger(), Rec, FieldNo("No."),
          ReportDistributionManagement.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), ShowDialog);
    end;

    procedure RecalculateJobWIP()
    var
        Job: Record Job;
        JobCalculateWIP: Report "Job Calculate WIP";
        ConfirmManagement: Codeunit "Confirm Management";
        Confirmed: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeRecalculateJobWIP(Rec, IsHandled);
        if IsHandled then
            exit;

        Job.Get("No.");
        if Job."WIP Method" = '' then
            exit;

        Job.SetRecFilter();
        Confirmed := ConfirmManagement.GetResponseOrDefault(RunWIPFunctionsQst, true);
        Commit();
        if Confirmed then begin
            JobCalculateWIP.UseRequestPage(false);
            JobCalculateWIP.SetTableView(Job);
            JobCalculateWIP.Run();
        end;
    end;

    local procedure GetReportCaption(ReportID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Report, ReportID);
        exit(AllObjWithCaption."Object Caption");
    end;

    local procedure CalcEndingDate() EndingDate: Date
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        if "Ending Date" = 0D then
            EndingDate := WorkDate()
        else
            EndingDate := "Ending Date";

        JobLedgerEntry.SetRange("Job No.", "No.");
        JobLedgerEntry.SetCurrentKey("Job No.", "Posting Date");
        JobLedgerEntry.SetLoadFields("Job No.", "Posting Date");
        if JobLedgerEntry.FindLast() then
            if JobLedgerEntry."Posting Date" > EndingDate then
                EndingDate := JobLedgerEntry."Posting Date";

        if "Ending Date" >= EndingDate then
            EndingDate := "Ending Date";
    end;

    procedure UpdateReferencedIds()
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        if IsTemporary() then
            exit;

        if not GraphMgtGeneralTools.IsApiEnabled() then
            exit;

        TimeSheetLine.SetCurrentKey(Type, "Job No.");
        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", "No.");
        if not TimeSheetLine.IsEmpty() then
            TimeSheetLine.ModifyAll("Job Id", SystemId);

        TimeSheetDetail.SetCurrentKey(Type, "Job No.");
        TimeSheetDetail.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetDetail.SetRange("Job No.", "No.");
        if not TimeSheetDetail.IsEmpty() then
            TimeSheetDetail.ModifyAll("Job Id", SystemId);
    end;

    procedure BilltoContactLookup(): Boolean
    var
        ContactNo: Code[20];
    begin
        ContactNo := ContactLookup("Bill-to Customer No.", "Bill-to Contact No.");
        if ContactNo <> '' then
            Validate("Bill-to Contact No.", ContactNo);
        exit(ContactNo <> '');
    end;

    procedure SelltoContactLookup(): Boolean
    var
        ContactNo: Code[20];
    begin
        ContactNo := ContactLookup("Sell-to Customer No.", "Sell-to Contact No.");
        if ContactNo <> '' then
            Validate("Sell-to Contact No.", ContactNo);
        exit(ContactNo <> '');
    end;

    local procedure ContactLookup(CustomerNo: Code[20]; ContactNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        if (CustomerNo <> '') and Cont.Get(ContactNo) then
            Cont.SetRange("Company No.", Cont."Company No.")
        else
            if Customer.Get(CustomerNo) then begin
                if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, CustomerNo) then
                    Cont.SetRange("Company No.", ContBusinessRelation."Contact No.");
            end else
                Cont.SetFilter("Company No.", '<>%1', '''');

        if ContactNo <> '' then
            if Cont.Get(ContactNo) then;
        if Page.RunModal(0, Cont) = Action::LookupOK then
            exit(Cont."No.");
        exit('');
    end;

    procedure CalcJobTaskLinesEditable() IsEditable: Boolean;
    begin
        IsEditable := "Bill-to Customer No." <> '';

        OnAfterCalcJobTaskLinesEditable(Rec, IsEditable);
    end;

    procedure ShipToAddressEqualsSellToAddress() Result: Boolean
    begin
        Result :=
          ("Sell-to Address" = "Ship-to Address") and
          ("Sell-to Address 2" = "Ship-to Address 2") and
          ("Sell-to City" = "Ship-to City") and
          ("Sell-to County" = "Ship-to County") and
          ("Sell-to Post Code" = "Ship-to Post Code") and
          ("Sell-to Country/Region Code" = "Ship-to Country/Region Code") and
          ("Sell-to Contact" = "Ship-to Contact") and
          ("Sell-to Phone No." = "Ship-to Phone No.");

        OnAfterShipToAddressEqualsSellToAddress(Rec, Result);
    end;

    procedure BillToAddressEqualsSellToAddress(): Boolean
    begin
        if ("Sell-to Address" = "Bill-to Address") and
           ("Sell-to Address 2" = "Bill-to Address 2") and
           ("Sell-to City" = "Bill-to City") and
           ("Sell-to County" = "Bill-to County") and
           ("Sell-to Post Code" = "Bill-to Post Code") and
           ("Sell-to Country/Region Code" = "Bill-to Country/Region Code") and
           ("Sell-to Contact No." = "Bill-to Contact No.") and
           ("Sell-to Contact" = "Bill-to Contact")
        then
            exit(true);
        exit(false);
    end;

    procedure SyncShipToWithSellTo()
    begin
        Rec."Ship-to Name" := Rec."Sell-to Customer Name";
        Rec."Ship-to Name 2" := Rec."Sell-to Customer Name 2";
        Rec."Ship-to Address" := Rec."Sell-to Address";
        Rec."Ship-to Address 2" := Rec."Sell-to Address 2";
        Rec."Ship-to City" := Rec."Sell-to City";
        Rec."Ship-to County" := Rec."Sell-to County";
        Rec."Ship-to Post Code" := Rec."Sell-to Post Code";
        Rec."Ship-to Country/Region Code" := Rec."Sell-to Country/Region Code";
        Rec."Ship-to Phone No." := Rec."Sell-to Phone No.";
        Rec."Ship-to Contact" := Rec."Sell-to Contact";
        Rec."Ship-to Code" := '';

        OnAfterSyncShipToWithSellTo(Rec);
    end;

    procedure ShipToNameEqualsSellToName(): Boolean
    begin
        exit(
            (Rec."Ship-to Name" = Rec."Sell-to Customer Name") and
            (Rec."Ship-to Name 2" = Rec."Sell-to Customer Name 2")
        );
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SellToCustomerNoUpdated(var Job: Record Job; var xJob: Record Job)
    var
        SellToCustomer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSellToCustomerNoUpdated(Job, xJob, CurrFieldNo, IsHandled, SkipSellToContact);
        if IsHandled then
            exit;
        if Job."Sell-to Customer No." <> '' then begin
            SellToCustomer.Get(Job."Sell-to Customer No.");
            IsHandled := false;
            OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, SellToCustomer, IsHandled);
            if not IsHandled then
                SellToCustomer.CheckBlockedCustOnDocs(SellToCustomer, Enum::"Sales Document Type"::Order, false, false);
        end;

        CheckSellToCustomerAssosEntriesExist(Job, xJob);

        if (xJob."Sell-to Customer No." <> '') and (xJob."Sell-to Customer No." <> Job."Sell-to Customer No.") and (not GetHideValidationDialog()) and GuiAllowed() then
            if not Confirm(ConfirmChangeQst, false, SellToCustomerTxt) then begin
                Job."Sell-to Customer No." := xJob."Sell-to Customer No.";
                Job."Sell-to Customer Name" := xJob."Sell-to Customer Name";
                exit;
            end;

        if Job."Sell-to Customer No." <> '' then begin
            SellToCustomer.Get(Job."Sell-to Customer No.");
            Job."Sell-to Customer Name" := SellToCustomer.Name;
            Job."Sell-to Customer Name 2" := SellToCustomer."Name 2";
            Job."Sell-to Phone No." := SellToCustomer."Phone No.";
            Job."Sell-to E-Mail" := SellToCustomer."E-Mail";
            Job."Sell-to Address" := SellToCustomer.Address;
            Job."Sell-to Address 2" := SellToCustomer."Address 2";
            Job."Sell-to City" := SellToCustomer.City;
            Job."Sell-to Post Code" := SellToCustomer."Post Code";
            Job."Sell-to County" := SellToCustomer.County;
            Job."Sell-to Country/Region Code" := SellToCustomer."Country/Region Code";
            Job.Reserve := SellToCustomer.Reserve;
            if not SkipSellToContact then
                UpdateSellToContact(Job."Sell-to Customer No.");
        end else begin
            Job."Sell-to Customer Name" := '';
            Job."Sell-to Customer Name 2" := '';
            Job."Sell-to Phone No." := '';
            Job."Sell-to E-Mail" := '';
            Job."Sell-to Address" := '';
            Job."Sell-to Address 2" := '';
            Job."Sell-to City" := '';
            Job."Sell-to Post Code" := '';
            Job."Sell-to County" := '';
            Job."Sell-to Country/Region Code" := '';
            Job.Reserve := Job.Reserve::Never;
            Job."Sell-to Contact" := '';
            Job."Sell-to Contact No." := '';
        end;
        OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust(Job, xJob, SellToCustomer);

        if SellToCustomer."Bill-to Customer No." <> '' then
            Job.Validate("Bill-to Customer No.", SellToCustomer."Bill-to Customer No.")
        else
            Job.Validate("Bill-to Customer No.", Rec."Sell-to Customer No.");

        if
            (xJob.ShipToNameEqualsSellToName() and xJob.ShipToAddressEqualsSellToAddress()) or
            ((xJob."Ship-to Code" <> '') and (xJob."Sell-to Customer No." <> Job."Sell-to Customer No."))
        then
            Job.SyncShipToWithSellTo();

        OnAfterSellToCustomerNoUpdated(Job, xJob, SellToCustomer);
    end;

    local procedure CheckSellToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSellToCustomerAssosEntriesExist(Job, xJob, IsHandled);
        if not IsHandled then
            if (Job."Sell-to Customer No." = '') or (Job."Sell-to Customer No." <> xJob."Sell-to Customer No.") then
                if Job.SalesJobLedgEntryExist() then
                    ThrowAssociatedEntriesExistError(Job, xJob, Job.FieldNo("Sell-to Customer No."), Job.FieldCaption("Sell-to Customer No."));
    end;

    local procedure BillToCustomerNoUpdated(var Job: Record Job; var xJob: Record Job)
    var
        BillToCustomer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBillToCustomerNoUpdated(Job, xJob, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        CheckBillToCustomerAssosEntriesExist(Job, xJob);

        if (xJob."Bill-to Customer No." <> '') and (xJob."Bill-to Customer No." <> Job."Bill-to Customer No.") and (not GetHideValidationDialog()) and GuiAllowed() then
            if not Confirm(ConfirmChangeQst, false, BillToCustomerTxt) then begin
                Job."Bill-to Customer No." := xJob."Bill-to Customer No.";
                Job."Bill-to Name" := xJob."Bill-to Name";
                exit;
            end;

        // Set sell-to first if it hasn't been set yet.
        if (Job."Sell-to Customer No." = '') and (Job."Bill-to Customer No." <> '') then
            Validate("Sell-to Customer No.", Job."Bill-to Customer No.");

        if Job."Bill-to Customer No." <> '' then begin
            BillToCustomer.Get(Job."Bill-to Customer No.");
            Job."Bill-to Name" := BillToCustomer.Name;
            Job."Bill-to Name 2" := BillToCustomer."Name 2";
            Job."Bill-to Address" := BillToCustomer.Address;
            Job."Bill-to Address 2" := BillToCustomer."Address 2";
            Job."Bill-to City" := BillToCustomer.City;
            Job."Bill-to Post Code" := BillToCustomer."Post Code";
            Job."Bill-to County" := BillToCustomer.County;
            Job."Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
            Job."Payment Method Code" := BillToCustomer."Payment Method Code";
            Job."Payment Terms Code" := BillToCustomer."Payment Terms Code";

            IsHandled := false;
            OnUpdateCustOnBeforeAssignIncoiceCurrencyCode(Job, xJob, BillToCustomer, IsHandled);
            if not IsHandled then
                "Invoice Currency Code" := BillToCustomer."Currency Code";

            IsHandled := false;
            OnBillToCustomerNoUpdatedOnBeforeAssignCurrencyCode(Job, xJob, BillToCustomer, IsHandled);
            if not IsHandled then
                if "Invoice Currency Code" <> '' then
                    Validate("Currency Code", '');

            Job."Customer Disc. Group" := BillToCustomer."Customer Disc. Group";
            Job."Customer Price Group" := BillToCustomer."Customer Price Group";
            Job."Language Code" := BillToCustomer."Language Code";
            IsHandled := false;
            OnBillToCustomerNoUpdatedOnBeforeUpdateBillToContact(Job, xJob, BillToCustomer, IsHandled);
            if not IsHandled then
                UpdateBillToContact(Job."Bill-to Customer No.");

            Job.CopyDefaultDimensionsFromCustomer();
        end else begin
            Job."Bill-to Name" := '';
            Job."Bill-to Name 2" := '';
            Job."Bill-to Address" := '';
            Job."Bill-to Address 2" := '';
            Job."Bill-to City" := '';
            Job."Bill-to Post Code" := '';
            Job."Bill-to County" := '';
            Job."Bill-to Country/Region Code" := '';
            Job."Invoice Currency Code" := '';
            Job."Customer Disc. Group" := '';
            Job."Customer Price Group" := '';
            Job."Language Code" := '';
            Job."Bill-to Contact" := '';
            Job."Bill-to Contact No." := '';
            Job."Payment Method Code" := '';
            Job."Payment Terms Code" := '';
        end;

        if (xJob."Bill-to Customer No." <> '') and (Job."Bill-to Customer No." <> xJob."Bill-to Customer No.") then
            UpdateCostPricesOnRelatedJobPlanningLines(Job);

        OnAfterBillToCustomerNoUpdated(Job, xJob, BillToCustomer, CurrFieldNo);
    end;

    local procedure UpdateCostPricesOnRelatedJobPlanningLines(var Job: Record Job)
    var
        JobPlanningLine: Record "Job Planning Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmResult: Boolean;
        IsHandled: Boolean;
    begin
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);
        JobPlanningLine.SetFilter("No.", '<>%1', '');
        if JobPlanningLine.IsEmpty() then
            exit;

        IsHandled := false;
        OnUpdateCostPricesOnRelatedJobPlanningLinesOnBeforeConfirmUpdate(Job, ConfirmResult, IsHandled);
        if not IsHandled then begin
            ConfirmResult := Job.GetHideValidationDialog();
            if not ConfirmResult then
                ConfirmResult := ConfirmManagement.GetResponseOrDefault(UpdateCostPricesOnRelatedLinesQst, true);
        end;
        if not ConfirmResult then
            exit;

        JobPlanningLine.FindSet(true);
        repeat
            JobPlanningLine."Line Amount" := 0;
            JobPlanningLine.SetJob(Job);
            JobPlanningLine.CopyFieldsFromJob();
            JobPlanningLine.UpdateAllAmounts();
            JobPlanningLine.Modify(true);
        until JobPlanningLine.Next() = 0;

        OnAfterUpdateCostPricesOnRelatedJobPlanningLines(Job);
    end;

    local procedure CheckBillToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBillToCustomerAssosEntriesExist(Job, xJob, IsHandled);
        if not IsHandled then
            if (Job."Bill-to Customer No." = '') or (Job."Bill-to Customer No." <> xJob."Bill-to Customer No.") then begin
                if Job.SalesJobLedgEntryExist() then
                    ThrowAssociatedEntriesExistError(Job, xJob, Job.FieldNo("Bill-to Customer No."), Job.FieldCaption("Bill-to Customer No."));
                if Job.SalesLineExist() then
                    ThrowAssociatedEntriesExistError(Job, xJob, Job.FieldNo("Bill-to Customer No."), Job.FieldCaption("Bill-to Customer No."));
            end;
    end;

    local procedure ThrowAssociatedEntriesExistError(var Job: Record Job; xJob: Record Job; CallingFieldNo: Integer; FieldCaption: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeThrowAssociatedEntriesExistError(Job, xJob, CallingFieldNo, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Error(AssociatedEntriesExistErr, FieldCaption, TableCaption);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowAssociatedEntriesExistError(var Job: Record Job; xJob: Record Job; CallingFieldNo: Integer; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    local procedure ShipToCodeValidate()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if (xRec."Ship-to Code" <> Rec."Ship-to Code") and (Rec."Ship-to Code" <> '') then
            if ShipToAddress.Get(Rec."Sell-to Customer No.", Rec."Ship-to Code") then begin
                Rec."Ship-to Name" := ShipToAddress.Name;
                Rec."Ship-to Name 2" := ShipToAddress."Name 2";
                Rec."Ship-to Address" := ShipToAddress.Address;
                Rec."Ship-to Address 2" := ShipToAddress."Address 2";
                Rec."Ship-to City" := ShipToAddress.City;
                Rec."Ship-to County" := ShipToAddress.County;
                Rec."Ship-to Post Code" := ShipToAddress."Post Code";
                Rec."Ship-to Country/Region Code" := ShipToAddress."Country/Region Code";
                Rec."Ship-to Phone No." := ShipToAddress."Phone No.";
                Rec."Ship-to Contact" := ShipToAddress.Contact;
            end;

        OnAfterShipToCodeValidate(Rec, ShipToAddress);
    end;

    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        Customer.SetLoadFields("Disable Search by Name");
        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    procedure CreateWarehousePick()
    var
        JobPlanningLine: Record "Job Planning Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        TestField(Status, Status::Open);
        CalcFields("Completely Picked");
        if "Completely Picked" then
            Error(WhseCompletelyPickedErr);

        JobPlanningLine.SetRange("Job No.", "No.");
        JobPlanningLine.SetFilter("Line Type", '<>%1', JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Quantity", '>0');
        JobPlanningLine.SetLoadFields(JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.");

        if JobPlanningLine.FindSet() then begin
            repeat
                ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(Enum::"Warehouse Worksheet Document Type"::Job, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.");
            until JobPlanningLine.Next() = 0;
            Commit();
            RunCreatePickFromWhseSource()
        end
        else
            Error(WhseNoItemsToPickErr);
    end;

    local procedure RunCreatePickFromWhseSource()
    var
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
    begin
        CreatePickFromWhseSource.SetJob(Rec);
        CreatePickFromWhseSource.SetHideValidationDialog(false);
        CreatePickFromWhseSource.UseRequestPage(true);
        CreatePickFromWhseSource.RunModal();
        CreatePickFromWhseSource.GetResultMessage(Enum::"Warehouse Activity Type"::Pick.AsInteger());
    end;

    local procedure InitDefaultJobPostingGroup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitDefaultJobPostingGroup(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Job Posting Group" = '' then
            Validate("Job Posting Group", JobsSetup."Default Job Posting Group");
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := JobPlanningLineReserve.GetReservedQtyFromInventory(Rec);
        if QtyReservedFromStock = 0 then
            exit(Result::None);

        if QtyReservedFromStock = CalculateReservableRemainingQuantityBase() then
            exit(Result::Full);

        exit(Result::Partial);
    end;

    local procedure CalculateReservableRemainingQuantityBase() RemainingQtyBase: Decimal
    var
        RemQtyBaseInvtItemJobPlannLine: Query RemQtyBaseInvtItemJobPlannLine;
    begin
        RemQtyBaseInvtItemJobPlannLine.SetJobPlanningLineFilter(Rec);
        if RemQtyBaseInvtItemJobPlannLine.Open() then
            if RemQtyBaseInvtItemJobPlannLine.Read() then
                RemainingQtyBase := RemQtyBaseInvtItemJobPlannLine.Remaining_Qty___Base_;
        RemQtyBaseInvtItemJobPlannLine.Close();
    end;

    local procedure UpdateSellToCust(ContactNo: Code[20])
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSellToCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if not Contact.Get(ContactNo) then begin
            "Sell-to Contact" := '';
            exit;
        end;
        "Sell-to Contact No." := Contact."No.";

        if Contact.Type = Contact.Type::Person then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Contact."No.");
        if not ContactBusinessRelationFound then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Contact."Company No.");

        if not ContactBusinessRelationFound then
            ShowSellToContactBusinessRelationNotFoundError(Contact);

        CheckCustomerContactRelation(Contact, "Sell-to Customer No.", ContactBusinessRelation."No.");

        if "Sell-to Customer No." = '' then begin
            SkipSellToContact := true;
            Validate("Sell-to Customer No.", ContactBusinessRelation."No.");
            SkipSellToContact := false;
        end;

        UpdateSellToEmail(Contact);
        Validate("Sell-to Phone No.", Contact."Phone No.");

        UpdateSellToCustomerContact(Customer, Contact);

        if ("Sell-to Customer No." = "Bill-to Customer No.") or ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Sell-to Contact No.");
    end;

    local procedure CheckCustomerContactRelation(Contact: Record Contact; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    begin
        if (CustomerNo <> '') and (CustomerNo <> ContBusinessRelationNo) then
            Error(ContactBusRelErr, Contact."No.", Contact.Name, CustomerNo);
    end;

    local procedure ShowSellToContactBusinessRelationNotFoundError(Contact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSellToContactBusinessRelationNotFoundError(Rec, Contact, IsHandled);
        if IsHandled then
            exit;

        Error(ContactBusRelMissingErr, Contact."No.", Contact.Name);
    end;

    local procedure UpdateSellToEmail(Contact: Record Contact)
    begin
        if (Contact."E-Mail" = '') and ("Sell-to E-Mail" <> '') and GuiAllowed and (not GetHideValidationDialog()) then begin
            if Confirm(ConfirmEmptyEmailQst, false, Contact."No.", "Sell-to E-Mail") then
                Validate("Sell-to E-Mail", Contact."E-Mail");
        end else
            Validate("Sell-to E-Mail", Contact."E-Mail");
    end;

    local procedure UpdateSellToCustomerContact(Customer: Record Customer; Contact: Record Contact)
    begin
        if not SkipSellToContact then
            if (Contact.Type = Contact.Type::Company) and Customer.Get("Sell-to Customer No.") then
                "Sell-to Contact" := Customer.Contact
            else
                if Contact.Type = Contact.Type::Company then
                    "Sell-to Contact" := ''
                else
                    "Sell-to Contact" := Contact.Name;
    end;

    local procedure UpdateShipToContact()
    begin
        if not (CurrFieldNo in [FieldNo("Sell-to Contact"), FieldNo("Sell-to Contact No.")]) then
            exit;

        Validate("Ship-to Contact", "Sell-to Contact");
    end;

    local procedure RefreshModifiedRec()
    begin
        Rec.Find('=');
    end;

    local procedure SetDefaultBin()
    begin
        "Bin Code" := '';

        if "Location Code" = '' then
            exit;

        GetLocation("Location Code");
        if not Location."Bin Mandatory" then
            exit;

        if Location."To-Job Bin Code" <> '' then
            "Bin Code" := Location."To-Job Bin Code";
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure MessageIfJobTaskExist(ChangedFieldName: Text)
    var
        MessageText: Text;
    begin
        if JobTaskExist() and not GetHideValidationDialog() then begin
            MessageText := StrSubstNo(TasksNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdateTasksManuallyMsg);
            Message(MessageText);
        end;
    end;

    procedure JobTaskExist(): Boolean
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetRange("Job No.", "No.");
        exit(not JobTask.IsEmpty());
    end;

    local procedure InitCustomerOnJobTasks()
    var
        JobTask: Record "Job Task";
    begin
        if "Sell-to Customer No." = '' then
            exit;

        JobTask.SetRange("Job No.", "No.");
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetFilter("Sell-to Customer No.", '%1', '');
        if JobTask.FindSet(true) then
            repeat
                JobTask.Validate("Sell-to Customer No.", "Sell-to Customer No.");
                if "Bill-to Customer No." <> "Sell-to Customer No." then begin
                    JobTask.SetHideValidationDialog(true);
                    JobTask.Validate("Bill-to Customer No.", "Bill-to Customer No.");
                end;
                JobTask.Modify(true);
            until JobTask.Next() = 0;
    end;

    local procedure ClearInvCurrencyCodeOnJobTasks()
    var
        JobTask: Record "Job Task";
    begin
        JobTask.SetLoadFields("Invoice Currency Code");
        JobTask.SetRange("Job No.", "No.");
        JobTask.SetFilter("Invoice Currency Code", '<>%1', '');
        if JobTask.IsEmpty() then
            exit;

        JobTask.ModifyAll("Invoice Currency Code", '');
    end;

    local procedure ConfirmDeletion()
    var
        JobPlanningLine: Record "Job Planning Line";
        Confirmed: Boolean;
    begin
        JobPlanningLine.SetRange("Job No.", "No.");
        JobPlanningLine.SetLoadFields("Qty. Posted", "Qty. Picked");
        if JobPlanningLine.FindSet() then
            repeat
                if JobPlanningLine."Qty. Posted" < JobPlanningLine."Qty. Picked" then begin
                    if not Confirm(ConfirmDeleteQst) then
                        Error('');
                    Confirmed := true;
                end;
            until (JobPlanningLine.Next() = 0) or Confirmed;
    end;

    procedure SetPurchLineFilters(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetCurrentKey("Document Type", "Job No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Job No.", "No.");
    end;

    local procedure CheckIfTimeSheetLineLinkExist()
    var
        TimeSheetLine: Record "Time Sheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTimeSheetLineLinkExist(Rec, IsHandled);
        if IsHandled then
            exit;

        TimeSheetLine.CheckIfTimeSheetLineLinkExist(Rec);
    end;

    local procedure UpdateReservationEntries()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if Status <> Status::Open then
            exit;

        ReservationEntry.ReadIsolation(IsolationLevel::UpdLock);
        ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
        ReservationEntry.SetRange("Source ID", "No.");
        if ReservationEntry.FindSet(true) then begin
            ReservationEntry.ModifyAll("Source Subtype", 2);
            ReservationEntry.ModifyAll("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcRecognizedProfitAmount(var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcJobTaskLinesEditable(var Job: Record Job; var IsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBillToCustomerNoUpdated(var Job: Record Job; var xJob: Record Job; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBillToCustomerNoUpdated(var Job: Record Job; xJob: Record Job; BillToCustomer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobLedgEntryExist(var JobLedgerEntry: Record "Job Ledger Entry"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineExist(var JobPlanningLine: Record "Job Planning Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var Job: Record Job; var xJob: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var Job: Record Job; var xJob: Record Job; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangeJobCompletionStatus(var Job: Record Job; var xJob: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipToCodeValidate(var Job: Record Job; ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToContact(var Job: Record Job; xJob: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeJobCompletionStatus(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Job: Record Job; var OldJob: Record Job; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactBillToCustomerBusRelation(var Job: Record Job; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowContactBillToCustomerBusRelationMissingError(var Job: Record Job; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRemoveFromMyJobsFromModify(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDefaultDimensionsFromCustomer(var Job: Record Job; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePercentCompleted(var Job: Record Job; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePercentInvoiced(var Job: Record Job; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePercentOverdue(var Job: Record Job; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedJobTasks(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitJobNo(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGlobalDimFromDefalutDim(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitBillToCustomerNo(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateJobWIP(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestBlocked(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobTaskDimension(var Job: Record Job; FieldNumber: Integer; ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerNo(var Job: Record Job; var IsHandled: Boolean; xJob: Record Job; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCurrencyCode(var Job: Record Job; xJob: Record Job; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToContactNo(var Job: Record Job; xJob: Record Job; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var Job: Record Job; var xJob: Record Job; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStatus(var Job: Record Job; xJob: Record Job; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOverBudgetValue(var Job: Record Job; JobNo: Code[20]; Usage: Boolean; Cost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSellToCustomerNoUpdated(var Job: Record Job; var xJob: Record Job; CallingFieldNo: Integer; var IsHandled: Boolean; var SkipSellToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSellToCustomerNoUpdated(var Job: Record Job; xJob: Record Job; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    protected procedure OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust(var Job: Record Job; xJob: Record Job; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetQuantityAvailableOnAfterSetFiltersOnJobLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; InEntryType: Option; Direction: Option; var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterAssignBillToContact(var Job: Record Job; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustOnBeforeAssignIncoiceCurrencyCode(var Job: Record Job; xJob: Record Job; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCity(var Job: Record Job; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToPostCode(var Job: Record Job; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCity(var Job: Record Job; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCity(var Job: Record Job; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSellToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBillToCustomerAssosEntriesExist(var Job: Record Job; var xJob: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestStatusCompleted(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyDefaultDimensionsFromCustomerOnBeforeUpdateDefaultDim(var Job: Record Job; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(var Job: Record Job; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDefaultJobPostingGroup(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusOnBeforeConfirm(var Job: Record "Job"; xJob: Record "Job"; var UndidCompleteStatus: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCurrencyUpdatePlanningLines(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBillToCustomerNoUpdatedOnBeforeAssignCurrencyCode(var Job: Record Job; xJob: Record Job; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBillToCustomerNoUpdatedOnBeforeUpdateBillToContact(var Job: Record Job; xJob: Record Job; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCurrencyUpdatePlanningLinesOnBeforeUpdateJobPlanningLine(var Job: Record Job; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCustomerName(var Job: Record "Job"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSellToContactBusinessRelationNotFoundError(var Job: Record Job; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSyncShipToWithSellTo(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipToAddressEqualsSellToAddress(var Job: Record Job; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCostPricesOnRelatedJobPlanningLines(var Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCust(var Job: Record Job; var ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostPricesOnRelatedJobPlanningLinesOnBeforeConfirmUpdate(var Job: Record Job; var ConfirmResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTimeSheetLineLinkExist(var Job: Record Job; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitJobNoOnAfterAssignNoSeries(var Job: Record Job; var xJob: Record Job; var JobsSetup: Record "Jobs Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddToMyJobs(var Job: Record Job; var MyJob: Record "My Job"; ProjectManager: Code[50]; var IsHandled: Boolean)
    begin
    end;
}