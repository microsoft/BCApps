// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Globalization;
using System.Utilities;
using Microsoft.Integration.Dataverse;

table 1001 "Job Task"
{
    Caption = 'Project Task';
    DrillDownPageID = "Job Task Lines";
    LookupPageID = "Job Task Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            NotBlank = true;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            NotBlank = true;

            trigger OnValidate()
            var
                Job: Record Job;
                Customer: Record Customer;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobTaskNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Job Task No." = '' then
                    exit;
                Job.Get("Job No.");
                Job.TestField("Bill-to Customer No.");
                Customer.Get(Job."Bill-to Customer No.");
                "Job Posting Group" := Job."Job Posting Group";
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Job Task Type"; Enum "Job Task Type")
        {
            Caption = 'Project Task Type';

            trigger OnValidate()
            begin
                if (xRec."Job Task Type" = "Job Task Type"::Posting) and
                   ("Job Task Type" <> "Job Task Type"::Posting)
                then begin
                    if JobLedgEntriesExist() then
                        Error(CannotChangeAssociatedEntriesErr, FieldCaption("Job Task Type"), TableCaption);
                    if JobPlanningLinesExist() then
                        Error(CannotChangeAssociatedEntriesErr, FieldCaption("Job Task Type"), TableCaption);
                    ClearCustomerData();
                end;

                if "Job Task Type" <> "Job Task Type"::Posting then begin
                    "Job Posting Group" := '';
                    if "WIP-Total" = "WIP-Total"::Excluded then
                        "WIP-Total" := "WIP-Total"::" ";
                end;

                Totaling := '';

                if (xRec."Job Task Type" <> "Job Task Type"::Posting) and ("Job Task Type" = "Job Task Type"::Posting) then
                    InitCustomer();
            end;
        }
        field(6; "WIP-Total"; Option)
        {
            Caption = 'WIP-Total';
            OptionCaption = ' ,Total,Excluded';
            OptionMembers = " ",Total,Excluded;

            trigger OnValidate()
            var
                Job: Record Job;
            begin
                case "WIP-Total" of
                    "WIP-Total"::Total:
                        begin
                            Job.Get("Job No.");
                            "WIP Method" := Job."WIP Method";
                        end;
                    "WIP-Total"::Excluded:
                        begin
                            TestField("Job Task Type", "Job Task Type"::Posting);
                            "WIP Method" := ''
                        end;
                    else
                        "WIP Method" := ''
                end;
            end;
        }
        field(7; "Job Posting Group"; Code[20])
        {
            Caption = 'Project Posting Group';
            TableRelation = "Job Posting Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateJobPostingGroup(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Job Posting Group" <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);
            end;
        }
        field(9; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            TableRelation = "Job WIP Method".Code where(Valid = const(true));

            trigger OnValidate()
            begin
                if "WIP Method" <> '' then
                    TestField("WIP-Total", "WIP-Total"::Total);
            end;
        }
        field(10; "Schedule (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                            "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling)),
                                                                            "Schedule Line" = const(true),
                                                                            "Planning Date" = field("Planning Date Filter")));
            Caption = 'Budget (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Schedule (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Line Amount (LCY)" where("Job No." = field("Job No."),
                                                                             "Job Task No." = field("Job Task No."),
                                                                             "Job Task No." = field(filter(Totaling)),
                                                                             "Schedule Line" = const(true),
                                                                             "Planning Date" = field("Planning Date Filter")));
            Caption = 'Budget (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Usage (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Ledger Entry"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                           "Job Task No." = field("Job Task No."),
                                                                           "Job Task No." = field(filter(Totaling)),
                                                                           "Entry Type" = const(Usage),
                                                                           "Posting Date" = field("Posting Date Filter")));
            Caption = 'Actual (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Usage (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Ledger Entry"."Line Amount (LCY)" where("Job No." = field("Job No."),
                                                                            "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling)),
                                                                            "Entry Type" = const(Usage),
                                                                            "Posting Date" = field("Posting Date Filter")));
            Caption = 'Actual (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Contract (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                            "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling)),
                                                                            "Contract Line" = const(true),
                                                                            "Planning Date" = field("Planning Date Filter")));
            Caption = 'Billable (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Contract (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Line Amount (LCY)" where("Job No." = field("Job No."),
                                                                             "Job Task No." = field("Job Task No."),
                                                                             "Job Task No." = field(filter(Totaling)),
                                                                             "Contract Line" = const(true),
                                                                             "Planning Date" = field("Planning Date Filter")));
            Caption = 'Billable (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Contract (Invoiced Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = - sum("Job Ledger Entry"."Line Amount (LCY)" where("Job No." = field("Job No."),
                                                                             "Job Task No." = field("Job Task No."),
                                                                             "Job Task No." = field(filter(Totaling)),
                                                                             "Entry Type" = const(Sale),
                                                                             "Posting Date" = field("Posting Date Filter")));
            Caption = 'Invoiced (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Contract (Invoiced Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = - sum("Job Ledger Entry"."Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                            "Job Task No." = field("Job Task No."),
                                                                            "Job Task No." = field(filter(Totaling)),
                                                                            "Entry Type" = const(Sale),
                                                                            "Posting Date" = field("Posting Date Filter")));
            Caption = 'Invoiced (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Posting Date Filter"; Date)
        {
            Caption = 'Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Planning Date Filter"; Date)
        {
            Caption = 'Planning Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if Totaling <> '' then
                    if not ("Job Task Type" in ["Job Task Type"::Total, "Job Task Type"::"End-Total"]) then
                        FieldError("Job Task Type");
                Validate("WIP-Total");
                CalcFields(
                  "Schedule (Total Cost)",
                  "Schedule (Total Price)",
                  "Usage (Total Cost)",
                  "Usage (Total Price)",
                  "Contract (Total Cost)",
                  "Contract (Total Price)",
                  "Contract (Invoiced Price)",
                  "Contract (Invoiced Cost)");
            end;
        }
        field(22; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(23; "No. of Blank Lines"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(24; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Location Code" <> xRec."Location Code") then
                    MessageIfJobPlanningLineExist(FieldCaption("Location Code"));

                SetDefaultBin();
            end;
        }
        field(31; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Bin Code" <> xRec."Bin Code") then
                    MessageIfJobPlanningLineExist(FieldCaption("Bin Code"));
            end;
        }
        field(34; "Recognized Sales Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Sales Amount';
            Editable = false;
        }
        field(37; "Recognized Costs Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Costs Amount';
            Editable = false;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            DataClassification = CustomerContent;
        }
        field(56; "Recognized Sales G/L Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Sales G/L Amount';
            Editable = false;
        }
        field(57; "Recognized Costs G/L Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Recognized Costs G/L Amount';
            Editable = false;
        }
        field(60; "Global Dimension 1 Code"; Code[20])
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
        field(61; "Global Dimension 2 Code"; Code[20])
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
        field(62; "Outstanding Orders"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Purchase Line"."Outstanding Amt. Ex. VAT (LCY)" where("Document Type" = const(Order),
                                                                                      "Job No." = field("Job No."),
                                                                                      "Job Task No." = field("Job Task No."),
                                                                                      "Job Task No." = field(filter(Totaling))));
            Caption = 'Outstanding Orders';
            FieldClass = FlowField;
        }
        field(63; "Amt. Rcd. Not Invoiced"; Decimal)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            CalcFormula = sum("Purchase Line"."A. Rcd. Not Inv. Ex. VAT (LCY)" where("Document Type" = const(Order),
                                                                                      "Job No." = field("Job No."),
                                                                                      "Job Task No." = field("Job Task No."),
                                                                                      "Job Task No." = field(filter(Totaling))));
            Caption = 'Amt. Rcd. Not Invoiced';
            FieldClass = FlowField;
        }
        field(64; "Remaining (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Remaining Total Cost (LCY)" where("Job No." = field("Job No."),
                                                                                      "Job Task No." = field("Job Task No."),
                                                                                      "Job Task No." = field(filter(Totaling)),
                                                                                      "Schedule Line" = const(true),
                                                                                      "Planning Date" = field("Planning Date Filter")));
            Caption = 'Remaining (Total Cost)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Remaining (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Job Planning Line"."Remaining Line Amount (LCY)" where("Job No." = field("Job No."),
                                                                                       "Job Task No." = field("Job Task No."),
                                                                                       "Job Task No." = field(filter(Totaling)),
                                                                                       "Schedule Line" = const(true),
                                                                                       "Planning Date" = field("Planning Date Filter")));
            Caption = 'Remaining (Total Price)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Start Date"; Date)
        {
            CalcFormula = min("Job Planning Line"."Planning Date" where("Job No." = field("Job No."),
                                                                         "Job Task No." = field("Job Task No.")));
            Caption = 'Start Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(67; "End Date"; Date)
        {
            CalcFormula = max("Job Planning Line"."Planning Date" where("Job No." = field("Job No."),
                                                                         "Job Task No." = field("Job Task No.")));
            Caption = 'End Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Bill-to Customer No." <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);

                BillToCustomerNoUpdated(Rec, xRec);
            end;
        }
        field(71; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

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
        field(72; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            DataClassification = CustomerContent;
        }
        field(73; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            DataClassification = CustomerContent;
        }
        field(74; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = CustomerContent;
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
            begin
                PostCode.ValidateCity(
                    "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(75; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            DataClassification = CustomerContent;
        }
        field(76; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                    "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(77; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            Editable = true;
            TableRelation = "Country/Region";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
#pragma warning disable AA0139
                PostCode.CheckClearPostCodeCityCounty(
                  "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", xRec."Bill-to Country/Region Code");
#pragma warning restore AA0139
            end;
        }
        field(78; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an additional part of the name of the customer who pays for the project.';
        }
        field(79; "Bill-to Contact No."; Code[20])
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Bill-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact."No.";

            trigger OnLookup()
            begin
                BilltoContactLookup();
            end;

            trigger OnValidate()
            begin
                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then
                    if ("Bill-to Contact No." = '') and ("Bill-to Customer No." = '') then begin
                        Init();
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
        field(80; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            DataClassification = CustomerContent;
        }
        field(90; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sell-to Customer No." <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);

                SellToCustomerNoUpdated(Rec, xRec);
            end;
        }
        field(91; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

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
            begin
                if LookupStateManager.IsRecordSaved() then
                    LookupStateManager.ClearSavedRecord();

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
        field(92; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        field(93; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
            DataClassification = CustomerContent;
        }
        field(94; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            DataClassification = CustomerContent;
        }
        field(95; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                    "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(96; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            DataClassification = CustomerContent;
        }
        field(97; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
            DataClassification = CustomerContent;
        }
        field(98; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            DataClassification = CustomerContent;
        }
        field(99; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = CustomerContent;
        }
        field(100; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;
            DataClassification = CustomerContent;

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
        field(110; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ShipToCodeValidate();
            end;
        }
        field(111; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            DataClassification = CustomerContent;
        }
        field(112; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            DataClassification = CustomerContent;
        }
        field(113; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            DataClassification = CustomerContent;
        }
        field(114; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            DataClassification = CustomerContent;
        }
        field(115; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

            trigger OnLookup()
            begin
#pragma warning disable AA0139
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
#pragma warning restore AA0139
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                    "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(116; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
            DataClassification = CustomerContent;
        }
        field(117; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                    "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code",
                    (CurrFieldNo <> 0) and GuiAllowed() and (not GetHideValidationDialog()));
            end;
        }
        field(118; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            DataClassification = CustomerContent;
        }
        field(119; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = CustomerContent;
        }
        field(130; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "External Document No." <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);
            end;
        }
        field(131; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
            DataClassification = CustomerContent;
        }
        field(132; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
            DataClassification = CustomerContent;
        }
        field(133; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Your Reference" <> '' then
                    TestField("Job Task Type", "Job Task Type"::Posting);
            end;
        }
        field(134; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Sale);
            end;
        }
        field(140; "Invoice Currency Code"; Code[10])
        {
            Caption = 'Invoice Currency Code';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA28
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Field Service';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Job Task")));
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
        key(Key1; "Job No.", "Job Task No.")
        {
            Clustered = true;
        }
        key(Key2; "Job Task No.")
        {
        }
        key(Key3; SystemCreatedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Job No.", "Job Task No.", Description, "Job Task Type")
        {
        }
        fieldgroup(Brick; "Job Task No.", Description)
        {
        }
    }

    trigger OnDelete()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobWIPTotal: Record "Job WIP Total";
        JobTaskDim: Record "Job Task Dimension";
    begin
        if JobLedgEntriesExist() then
            Error(CannotDeleteAssociatedEntriesErr, TableCaption);

        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        if CalledFromHeader then
            JobPlanningLine.SuspendDeletionCheck(true);
        JobPlanningLine.DeleteAll(true);

        JobWIPTotal.DeleteEntriesForJobTask(Rec);

        JobTaskDim.SetRange("Job No.", "Job No.");
        JobTaskDim.SetRange("Job Task No.", "Job Task No.");
        if not JobTaskDim.IsEmpty() then
            JobTaskDim.DeleteAll();

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");
    end;

    trigger OnInsert()
    var
        Job: Record Job;
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        Job.Get("Job No.");
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        Job.TestField("Bill-to Customer No.");
        Customer.Get(Job."Bill-to Customer No.");

        DimMgt.InsertJobTaskDim("Job No.", "Job Task No.", "Global Dimension 1 Code", "Global Dimension 2 Code");

        InitCustomer();
        InitLocation(Job);

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");

        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        CalcFields("Schedule (Total Cost)", "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", true, "Usage (Total Cost)");
        Job.UpdateOverBudgetValue("Job No.", false, "Schedule (Total Cost)");
    end;

    var
        Job: Record Job;
        Location: Record Location;
        PostCode: Record "Post Code";
        Cust: Record Customer;
        Cont: Record Contact;
        ContBusinessRelation: Record "Contact Business Relation";
        DimMgt: Codeunit DimensionManagement;
        HideValidationDialog: Boolean;
        CalledFromHeader: Boolean;

        CannotDeleteAssociatedEntriesErr: Label 'You cannot delete %1 because one or more entries are associated.', Comment = '%1=The project task table name.';
        CannotChangeAssociatedEntriesErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = The field name you are trying to change; %2 = The project task table name.';
        PlanningLinesNotUpdatedMsg: Label 'You have changed %1 on the project task, but it has not been changed on the existing project planning lines.', Comment = '%1 = a Field Caption like Location Code';
        AssociatedEntriesExistErr: Label 'You cannot change %1 because one or more entries are associated with this %2.', Comment = '%1 = Name of field used in the error; %2 = The name of the Project Task table';
        ContactBusRelErr: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job task';
        ContactBusRelMissingErr: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1 = The contact number; %2 = The contact''s name';
        ContactBusRelDiffCompErr: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1 = The contact number; %2 = The contact''s name; %3 = The Bill-To Customer Number associated with this job task';
        UpdatePlanningLinesManuallyMsg: Label 'You must update the existing project planning lines manually.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        BillToCustomerTxt: Label 'Bill-to Customer';
        SellToCustomerTxt: Label 'Sell-to Customer';
        UpdateCostPricesOnRelatedLinesQst: Label 'You have changed a customer. Prices and costs needs to be updated on a related lines.\\Do you want to update related lines?';

    procedure CalcEACTotalCost(): Decimal
    begin
        if "Job No." <> Job."No." then
            if not Job.Get("Job No.") then
                exit(0);

        if Job."Apply Usage Link" then
            exit("Usage (Total Cost)" + "Remaining (Total Cost)");

        exit(0);
    end;

    procedure CalcEACTotalPrice(): Decimal
    begin
        if "Job No." <> Job."No." then
            if not Job.Get("Job No.") then
                exit(0);

        if Job."Apply Usage Link" then
            exit("Usage (Total Price)" + "Remaining (Total Price)");

        exit(0);
    end;

    local procedure JobLedgEntriesExist() Result: Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetCurrentKey("Job No.", "Job Task No.");
        JobLedgerEntry.SetRange("Job No.", "Job No.");
        JobLedgerEntry.SetRange("Job Task No.", "Job Task No.");
        OnJobLedgEntriesExistOnAfterSetFilter(Rec, JobLedgerEntry);
        Result := not JobLedgerEntry.IsEmpty();
    end;

    local procedure JobPlanningLinesExist() Result: Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        Result := not JobPlanningLine.IsEmpty();
    end;

    procedure Caption(): Text
    var
        JobForCaption: Record Job;
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
        exit(StrSubstNo('%1 %2 %3 %4',
            JobForCaption."No.",
            JobForCaption.Description,
            "Job Task No.",
            Description));
    end;

    procedure InitWIPFields()
    var
        JobWIPTotal: Record "Job WIP Total";
    begin
        JobWIPTotal.SetRange("Job No.", "Job No.");
        JobWIPTotal.SetRange("Job Task No.", "Job Task No.");
        JobWIPTotal.SetRange("Posted to G/L", false);
        JobWIPTotal.DeleteAll(true);

        "Recognized Sales Amount" := 0;
        "Recognized Costs Amount" := 0;

        OnInitWIPFieldsOnBeforeModify(Rec);
        Modify();
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source"; PriceType: Enum "Price Type")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceType;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::"Job Task");
        PriceSource.Validate("Parent Source No.", "Job No.");
        PriceSource.Validate("Source No.", "Job Task No.");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        JobTask2: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, JobTask2, IsHandled);
        if not IsHandled then begin
            DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
            if JobTask2.Get("Job No.", "Job Task No.") then begin
                DimMgt.SaveJobTaskDim("Job No.", "Job Task No.", FieldNumber, ShortcutDimCode);
                Modify();
            end else
                DimMgt.SaveJobTaskTempDim(FieldNumber, ShortcutDimCode);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ClearTempDim()
    begin
        DimMgt.DeleteJobTaskTempDim();
    end;

    procedure ApplyPurchaseLineFilters(var PurchLine: Record "Purchase Line"; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        PurchLine.SetCurrentKey("Document Type", "Job No.", "Job Task No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Job No.", JobNo);
        if "Job Task Type" in ["Job Task Type"::Total, "Job Task Type"::"End-Total"] then
            PurchLine.SetFilter("Job Task No.", Totaling)
        else
            PurchLine.SetRange("Job Task No.", JobTaskNo);
        OnAfterApplyPurchaseLineFilters(Rec, PurchLine);
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

    local procedure MessageIfJobPlanningLineExist(ChangedFieldName: Text)
    var
        MessageText: Text;
    begin
        if JobPlanningLineExist() then begin
            MessageText := StrSubstNo(PlanningLinesNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdatePlanningLinesManuallyMsg);
            Message(MessageText);
        end;
    end;

    procedure JobPlanningLineExist() Result: Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        Result := not JobPlanningLine.IsEmpty();
    end;

    procedure SalesJobLedgEntryExist() Result: Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", "Job No.");
        JobLedgerEntry.SetRange("Job Task No.", "Job Task No.");
        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);
        Result := not JobLedgerEntry.IsEmpty();
    end;

    procedure SalesLineExist() Result: Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if "Job No." = '' then
            exit(false);

        SalesLine.SetRange("Job No.", "Job No.");
        SalesLine.SetRange("Job Task No.", "Job Task No.");
        Result := not SalesLine.IsEmpty();
    end;

    local procedure InitLocation(Job: Record Job)
    begin
        "Location Code" := Job."Location Code";
        "Bin Code" := Job."Bin Code";
    end;

    local procedure InitCustomer()
    begin
        if not Job.Get("Job No.") then
            exit;

        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit;

        if "Job Task Type" <> "Job Task Type"::Posting then
            exit;

        SetHideValidationDialog(true);
        if Job."Sell-to Customer No." <> '' then
            Validate("Sell-to Customer No.", Job."Sell-to Customer No.");

        if (Job."Sell-to Customer No." <> Job."Bill-to Customer No.") and (Job."Bill-to Customer No." <> '') then
            Validate("Bill-to Customer No.", Job."Bill-to Customer No.");
    end;

    local procedure ClearCustomerData()
    begin
        if not Job.Get("Job No.") then
            exit;
        if Job."Task Billing Method" = Job."Task Billing Method"::"One customer" then
            exit;

        SetHideValidationDialog(true);
        if "Sell-to Customer No." <> '' then
            Validate("Sell-to Customer No.", '');

        if ("Sell-to Customer No." <> "Bill-to Customer No.") and ("Bill-to Customer No." <> '') then
            Validate("Bill-to Customer No.", '');
    end;

    local procedure BillToCustomerNoUpdated(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    var
        BillToCustomer: Record Customer;
    begin
        OnBeforeBillToCustomerNoUpdated(JobTask, xJobTask, CurrFieldNo);

        CheckBillToCustomerAssosEntriesExist(JobTask, xJobTask);

        if (xJobTask."Bill-to Customer No." <> '') and (not GetHideValidationDialog()) and GuiAllowed() then
            if not Confirm(ConfirmChangeQst, false, BillToCustomerTxt) then begin
                JobTask."Bill-to Customer No." := xJobTask."Bill-to Customer No.";
                JobTask."Bill-to Name" := xJobTask."Bill-to Name";
                exit;
            end;

        // Set sell-to first if it hasn't been set yet.
        if (JobTask."Sell-to Customer No." = '') and (JobTask."Bill-to Customer No." <> '') then
            Validate("Sell-to Customer No.", JobTask."Bill-to Customer No.");

        if JobTask."Bill-to Customer No." <> '' then begin
            BillToCustomer.Get(JobTask."Bill-to Customer No.");
            JobTask."Bill-to Name" := BillToCustomer.Name;
            JobTask."Bill-to Name 2" := BillToCustomer."Name 2";
            JobTask."Bill-to Address" := BillToCustomer.Address;
            JobTask."Bill-to Address 2" := BillToCustomer."Address 2";
            JobTask."Bill-to City" := BillToCustomer.City;
            JobTask."Bill-to Post Code" := BillToCustomer."Post Code";
            JobTask."Bill-to County" := BillToCustomer.County;
            JobTask."Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
            JobTask."Payment Method Code" := BillToCustomer."Payment Method Code";
            JobTask."Payment Terms Code" := BillToCustomer."Payment Terms Code";

            Job.Get("Job No.");
            if Job."Bill-to Customer No." = BillToCustomer."No." then
                "Invoice Currency Code" := Job."Invoice Currency Code"
            else
                "Invoice Currency Code" := BillToCustomer."Currency Code";

            JobTask."Language Code" := BillToCustomer."Language Code";

            OnBillToCustomerNoUpdatedOnAfterCopyFieldsFromBillToCustomer(JobTask, xJobTask, Job, BillToCustomer);

            GetCustomerContact(JobTask."Bill-to Customer No.", JobTask."Bill-to Contact No.", JobTask."Bill-to Contact");
            CreateDefaultJobTaskDimensionsFromCustomer(JobTask."Bill-to Customer No.");
        end else begin
            JobTask."Bill-to Name" := '';
            JobTask."Bill-to Name 2" := '';
            JobTask."Bill-to Address" := '';
            JobTask."Bill-to Address 2" := '';
            JobTask."Bill-to City" := '';
            JobTask."Bill-to Post Code" := '';
            JobTask."Bill-to County" := '';
            JobTask."Bill-to Country/Region Code" := '';
            JobTask."Language Code" := '';
            JobTask."Bill-to Contact" := '';
            JobTask."Bill-to Contact No." := '';
            JobTask."Payment Method Code" := '';
            JobTask."Payment Terms Code" := '';
        end;

        if (xJobTask."Bill-to Customer No." <> '') and (JobTask."Bill-to Customer No." <> xJobTask."Bill-to Customer No.") then
            UpdateCostPricesOnRelatedJobPlanningLines(JobTask);

        OnAfterBillToCustomerNoUpdated(JobTask, xJobTask, BillToCustomer, CurrFieldNo);
    end;

    local procedure UpdateCostPricesOnRelatedJobPlanningLines(var JobTask: Record "Job Task")
    var
        JobPlanningLine: Record "Job Planning Line";
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmResult: Boolean;
        IsHandled: Boolean;
    begin
        JobPlanningLine.SetRange("Job No.", JobTask."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobTask."Job Task No.");
        JobPlanningLine.SetFilter(Type, '<>%1', JobPlanningLine.Type::Text);
        JobPlanningLine.SetFilter("No.", '<>%1', '');
        if JobPlanningLine.IsEmpty() then
            exit;

        IsHandled := false;
        OnUpdateCostPricesOnRelatedJobPlanningLinesOnBeforeConfirmUpdate(JobTask, ConfirmResult, IsHandled);
        if not IsHandled then
            ConfirmResult := ConfirmManagement.GetResponseOrDefault(UpdateCostPricesOnRelatedLinesQst, true);
        if not ConfirmResult then
            exit;

        JobTask.Modify(true);
        JobPlanningLine.FindSet(true);
        repeat
            JobPlanningLine."Line Amount" := 0;
            JobPlanningLine.UpdateAllAmounts();
            JobPlanningLine.Modify(true);
        until JobPlanningLine.Next() = 0;
    end;

    local procedure CreateDefaultJobTaskDimensionsFromCustomer(BillToCustomerNo: Code[20])
    var
        JobTaskDim: Record "Job Task Dimension";
        CustDefaultDimension: Record "Default Dimension";
        TempJobDefaultDimension: Record "Default Dimension" temporary;
    begin
        JobTaskDim.SetRange("Job No.", Rec."Job No.");
        JobTaskDim.SetRange("Job Task No.", Rec."Job Task No.");
        if JobTaskDim.FindSet() then
            repeat
                TempJobDefaultDimension.Init();
                TempJobDefaultDimension."Table ID" := Database::"Job Task";
                TempJobDefaultDimension."No." := Rec."Job Task No.";
                TempJobDefaultDimension."Dimension Code" := JobTaskDim."Dimension Code";
                TempJobDefaultDimension."Dimension Value Code" := JobTaskDim."Dimension Value Code";
                TempJobDefaultDimension.Insert();
            until JobTaskDim.Next() = 0;

        CustDefaultDimension.SetRange("Table ID", Database::Customer);
        CustDefaultDimension.SetRange("No.", BillToCustomerNo);
        if CustDefaultDimension.FindSet() then
            repeat
                if TempJobDefaultDimension.Get(Database::"Job Task", Rec."Job Task No.", CustDefaultDimension."Dimension Code") then begin
                    // Override existing dimension with customer dimension
                    TempJobDefaultDimension."Dimension Value Code" := CustDefaultDimension."Dimension Value Code";
                    TempJobDefaultDimension.Modify();
                end else begin
                    TempJobDefaultDimension.Init();
                    TempJobDefaultDimension.TransferFields(CustDefaultDimension);
                    TempJobDefaultDimension."Table ID" := Database::"Job Task";
                    TempJobDefaultDimension."No." := Rec."Job Task No.";
                    TempJobDefaultDimension.Insert();
                end;
            until CustDefaultDimension.Next() = 0;

        if not JobTaskDim.IsEmpty() then
            JobTaskDim.DeleteAll();

        DimMgt.InsertJobTaskDim(TempJobDefaultDimension, Rec."Job No.", Rec."Job Task No.", Rec."Global Dimension 1 Code", Rec."Global Dimension 2 Code");
    end;

    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo = '' then
            exit(true);

        if not Customer.Get(CustomerNo) then
            exit(true);

        exit(not Customer."Disable Search by Name");
    end;

    local procedure SellToCustomerNoUpdated(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    var
        SellToCustomer: Record Customer;
    begin
        OnBeforeSellToCustomerNoUpdated(JobTask, xJobTask, CurrFieldNo);

        if JobTask."Sell-to Customer No." <> '' then begin
            SellToCustomer.Get(JobTask."Sell-to Customer No.");
            SellToCustomer.CheckBlockedCustOnDocs(SellToCustomer, Enum::"Sales Document Type"::Order, false, false);
        end;

        CheckSellToCustomerAssosEntriesExist(JobTask, xJobTask);

        if (xJobTask."Sell-to Customer No." <> '') and (not GetHideValidationDialog()) and GuiAllowed() then
            if not Confirm(ConfirmChangeQst, false, SellToCustomerTxt) then begin
                JobTask."Sell-to Customer No." := xJobTask."Sell-to Customer No.";
                JobTask."Sell-to Customer Name" := xJobTask."Sell-to Customer Name";
                exit;
            end;

        if JobTask."Sell-to Customer No." <> '' then begin
            SellToCustomer.Get(JobTask."Sell-to Customer No.");
            JobTask."Sell-to Customer Name" := SellToCustomer.Name;
            JobTask."Sell-to Customer Name 2" := SellToCustomer."Name 2";
            JobTask."Sell-to Address" := SellToCustomer.Address;
            JobTask."Sell-to Address 2" := SellToCustomer."Address 2";
            JobTask."Sell-to City" := SellToCustomer.City;
            JobTask."Sell-to Post Code" := SellToCustomer."Post Code";
            JobTask."Sell-to County" := SellToCustomer.County;
            JobTask."Sell-to Country/Region Code" := SellToCustomer."Country/Region Code";
            UpdateSellToContact(JobTask."Sell-to Customer No.");
        end else begin
            JobTask."Sell-to Customer Name" := '';
            JobTask."Sell-to Customer Name 2" := '';
            JobTask."Sell-to Address" := '';
            JobTask."Sell-to Address 2" := '';
            JobTask."Sell-to City" := '';
            JobTask."Sell-to Post Code" := '';
            JobTask."Sell-to County" := '';
            JobTask."Sell-to Country/Region Code" := '';
            JobTask."Sell-to Contact" := '';
            JobTask."Sell-to Contact No." := '';
        end;

        if SellToCustomer."Bill-to Customer No." <> '' then
            JobTask.Validate("Bill-to Customer No.", SellToCustomer."Bill-to Customer No.")
        else
            JobTask.Validate("Bill-to Customer No.", Rec."Sell-to Customer No.");

        if
            (xJobTask.ShipToNameEqualsSellToName() and xJobTask.ShipToAddressEqualsSellToAddress()) or
            ((xJobTask."Ship-to Code" <> '') and (xJobTask."Sell-to Customer No." <> JobTask."Sell-to Customer No."))
        then
            JobTask.SyncShipToWithSellTo();

        OnAfterSellToCustomerNoUpdated(JobTask, xJobTask, SellToCustomer);
    end;

    protected procedure UpdateSellToContact(CustomerNo: Code[20])
    begin
        GetCustomerContact(CustomerNo, Rec."Sell-to Contact No.", Rec."Sell-to Contact");
    end;

    local procedure GetCustomerContact(CustomerNo: Code[20]; var ContactNo: Code[20]; var Contact: Text[100])
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        if Cust.Get(CustomerNo) then begin
            if Cust."Primary Contact No." <> '' then
                ContactNo := Cust."Primary Contact No."
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("No.", CustomerNo);
                if ContBusRel.FindFirst() then
                    ContactNo := ContBusRel."Contact No.";
            end;
            Contact := Cust.Contact;
        end;
    end;

    local procedure CheckBillToCustomerAssosEntriesExist(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBillToCustomerAssosEntriesExist(JobTask, xJobTask, IsHandled);
        if IsHandled then
            exit;

        if (JobTask."Bill-to Customer No." = '') or (JobTask."Bill-to Customer No." <> xJobTask."Bill-to Customer No.") then begin
            if JobTask.SalesJobLedgEntryExist() then
                Error(AssociatedEntriesExistErr, JobTask.FieldCaption("Bill-to Customer No."), JobTask.TableCaption);
            if JobTask.SalesLineExist() then
                Error(AssociatedEntriesExistErr, JobTask.FieldCaption("Bill-to Customer No."), JobTask.TableCaption);
        end;
    end;

    local procedure CheckSellToCustomerAssosEntriesExist(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSellToCustomerAssosEntriesExist(JobTask, xJobTask, IsHandled);
        if IsHandled then
            exit;

        if (JobTask."Sell-to Customer No." = '') or (JobTask."Sell-to Customer No." <> xJobTask."Sell-to Customer No.") then
            if JobTask.SalesJobLedgEntryExist() then
                Error(AssociatedEntriesExistErr, JobTask.FieldCaption("Sell-to Customer No."), JobTask.TableCaption);
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

    local procedure ContactLookup(CustomerNo: Code[20]; ContactNo: Code[20]): Code[20]
    begin
        if (CustomerNo <> '') and Cont.Get(ContactNo) then
            Cont.SetRange("Company No.", Cont."Company No.")
        else
            if Cust.Get(CustomerNo) then begin
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

    procedure SelltoCustomerNoOnAfterValidate(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    begin
        if JobTask.GetFilter("Sell-to Customer No.") = xJobTask."Sell-to Customer No." then
            if JobTask."Sell-to Customer No." <> xJobTask."Sell-to Customer No." then
                JobTask.SetRange("Sell-to Customer No.");
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    begin
        if Cont.Get(ContactNo) then begin
            "Bill-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Bill-to Contact" := Cont.Name
            else
                if Cust.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Cust.Contact
                else
                    "Bill-to Contact" := '';
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if "Bill-to Customer No." = '' then
                Validate("Bill-to Customer No.", ContBusinessRelation."No.")
            else
                if "Bill-to Customer No." <> ContBusinessRelation."No." then
                    Error(ContactBusRelErr, Cont."No.", Cont.Name, "Bill-to Customer No.");
        end else
            Error(ContactBusRelMissingErr, Cont."No.", Cont.Name);
    end;

    local procedure ShipToCodeValidate()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if not ((xRec."Ship-to Code" <> Rec."Ship-to Code") and (Rec."Ship-to Code" <> '')) then
            exit;

        if not ShipToAddress.Get(Rec."Sell-to Customer No.", Rec."Ship-to Code") then
            exit;

        Rec."Ship-to Name" := ShipToAddress.Name;
        Rec."Ship-to Name 2" := ShipToAddress."Name 2";
        Rec."Ship-to Address" := ShipToAddress.Address;
        Rec."Ship-to Address 2" := ShipToAddress."Address 2";
        Rec."Ship-to City" := ShipToAddress.City;
        Rec."Ship-to County" := ShipToAddress.County;
        Rec."Ship-to Post Code" := ShipToAddress."Post Code";
        Rec."Ship-to Country/Region Code" := ShipToAddress."Country/Region Code";
        Rec."Ship-to Contact" := ShipToAddress.Contact;

        OnAfterShipToCodeValidate(Rec, ShipToAddress);
    end;

    local procedure UpdateSellToCust(ContactNo: Code[20])
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactBusinessRelationFound: Boolean;
    begin
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
            Error(ContactBusRelMissingErr, Contact."No.", Contact.Name);

        CheckCustomerContactRelation(Contact, "Sell-to Customer No.", ContactBusinessRelation."No.");

        if "Sell-to Customer No." = '' then
            Validate("Sell-to Customer No.", ContactBusinessRelation."No.");

        UpdateSellToCustomerContact(Customer, Contact);

        if ("Sell-to Customer No." = "Bill-to Customer No.") or ("Bill-to Customer No." = '') then
            Validate("Bill-to Contact No.", "Sell-to Contact No.");
    end;

    local procedure CheckCustomerContactRelation(Contact: Record Contact; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    begin
        if (CustomerNo <> '') and (CustomerNo <> ContBusinessRelationNo) then
            Error(ContactBusRelErr, Contact."No.", Contact.Name, CustomerNo);
    end;

    local procedure UpdateSellToCustomerContact(Customer: Record Customer; Contact: Record Contact)
    begin
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

    procedure SelltoContactLookup(): Boolean
    var
        ContactNo: Code[20];
    begin
        ContactNo := ContactLookup("Sell-to Customer No.", "Sell-to Contact No.");
        if ContactNo <> '' then
            Validate("Sell-to Contact No.", ContactNo);
        exit(ContactNo <> '');
    end;

    procedure ShipToNameEqualsSellToName(): Boolean
    begin
        exit(
            (Rec."Ship-to Name" = Rec."Sell-to Customer Name") and
            (Rec."Ship-to Name 2" = Rec."Sell-to Customer Name 2")
        );
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

    procedure ShipToAddressEqualsSellToAddress() Result: Boolean
    begin
        Result :=
          ("Sell-to Address" = "Ship-to Address") and
          ("Sell-to Address 2" = "Ship-to Address 2") and
          ("Sell-to City" = "Ship-to City") and
          ("Sell-to County" = "Ship-to County") and
          ("Sell-to Post Code" = "Ship-to Post Code") and
          ("Sell-to Country/Region Code" = "Ship-to Country/Region Code") and
          ("Sell-to Contact" = "Ship-to Contact");

        OnAfterShipToAddressEqualsSellToAddress(Rec, Result);
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
        Rec."Ship-to Contact" := Rec."Sell-to Contact";
        Rec."Ship-to Code" := '';

        OnAfterSyncShipToWithSellTo(Rec);
    end;

    procedure JobLedgEntryExist() Result: Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", "Job No.");
        JobLedgerEntry.SetRange("Job Task No.", "Job Task No.");
        Result := not JobLedgerEntry.IsEmpty();
    end;

    procedure JobPlanLineExist() Result: Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.Init();
        JobPlanningLine.SetRange("Job No.", "Job No.");
        JobPlanningLine.SetRange("Job Task No.", "Job Task No.");
        Result := not JobPlanningLine.IsEmpty();
    end;

    procedure SendProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportSelections: Record "Report Selections";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        DocumentSendingProfile.Send(
          ReportSelections.Usage::"Job Task Quote".AsInteger(), Rec, "Job Task No.", "Bill-to Customer No.",
          ReportDistributionMgt.GetFullDocumentTypeText(Rec), FieldNo("Bill-to Customer No."), FieldNo("Job Task No."));
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure SuspendDeletionCheck(Suspend: Boolean)
    begin
        CalledFromHeader := Suspend;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPurchaseLineFilters(var JobTask: Record "Job Task"; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobTaskNo(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateJobPostingGroup(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; JobTask2: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWIPFieldsOnBeforeModify(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobLedgEntriesExistOnAfterSetFilter(var JobTask: Record "Job Task"; var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(JobTask: Record "Job Task"; var IsHandled: Boolean; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipToAddressEqualsSellToAddress(var JobTask: Record "Job Task"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSyncShipToWithSellTo(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCostPricesOnRelatedJobPlanningLinesOnBeforeConfirmUpdate(var JobTask: Record "Job Task"; var ConfirmResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSellToCustomerAssosEntriesExist(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBillToCustomerAssosEntriesExist(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSellToCustomerNoUpdated(var JobTask: Record "Job Task"; var xJobTask: Record "Job Task"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSellToCustomerNoUpdated(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShipToCodeValidate(var JobTask: Record "Job Task"; var ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBillToCustomerNoUpdated(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBillToCustomerNoUpdatedOnAfterCopyFieldsFromBillToCustomer(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var Job: Record Job; var BillToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBillToCustomerNoUpdated(var JobTask: Record "Job Task"; xJobTask: Record "Job Task"; var BillToCustomer: Record Customer; CallingFieldNo: Integer)
    begin
    end;
}

