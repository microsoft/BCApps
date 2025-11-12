// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Security.User;
using System.Utilities;

table 5965 "Service Contract Header"
{
    Caption = 'Service Contract Header';
    DataCaptionFields = "Contract No.", Description;
    DrillDownPageID = "Service Contract List";
    LookupPageID = "Service Contract List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';

            trigger OnValidate()
            begin
                if "Contract No." <> xRec."Contract No." then begin
                    ServMgtSetup.Get();
                    NoSeries.TestManual(GetServiceContractNos());
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
#pragma warning disable AS0070
        field(5; Status; Enum "Service Contract Status")
        {
            Caption = 'Status';
            Editable = true;

            trigger OnValidate()
            begin
                if Status <> xRec.Status then begin
                    CheckChangeStatus();
                    ChangeContractStatus();
                end;
            end;
        }
#pragma warning restore AS0070
        field(6; "Change Status"; Enum "Service Contract Change Status")
        {
            Caption = 'Change Status';
            Editable = false;
        }
        field(7; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCustomerNo(Rec, xRec, SkipBillToContact, SkipContact, IsHandled);
                if IsHandled then
                    exit;

                ChangeCustomerNo();
            end;
        }
        field(8; Name; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; Address; Text[100])
        {
            CalcFormula = lookup(Customer.Address where("No." = field("Customer No.")));
            Caption = 'Address';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Address 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Address 2" where("No." = field("Customer No.")));
            Caption = 'Address 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Post Code"; Code[20])
        {
            CalcFormula = lookup(Customer."Post Code" where("No." = field("Customer No.")));
            Caption = 'Post Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; City; Text[30])
        {
            CalcFormula = lookup(Customer.City where("No." = field("Customer No.")));
            Caption = 'City';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateSalesPersonOnServiceContractHeader(Rec, false, false);

                CheckChangeStatus();
                Modify();

                CreateDimFromDefaultDim(Rec.FieldNo("Salesperson Code"));
            end;
        }
        field(16; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToCustomerNo(Rec, xRec, HideValidationDialog, Confirmed, SkipBillToContact, IsHandled);
                if IsHandled then
                    exit;

                CheckChangeStatus();
                if xRec."Bill-to Customer No." <> "Bill-to Customer No." then
                    if xRec."Bill-to Customer No." <> '' then begin
                        if HideValidationDialog then
                            Confirmed := true
                        else
                            Confirmed :=
                              ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(Text014, FieldCaption("Bill-to Customer No.")), true);
                    end else
                        Confirmed := true;

                if Confirmed then begin
                    if Rec."Bill-to Customer No." <> xRec."Bill-to Customer No." then
                        if "Bill-to Customer No." <> '' then begin
                            Cust.Get("Bill-to Customer No.");
                            IsHandled := false;
                            OnValidateBillToCustomerNoOnBeforePrivacyBlockedCheck(Rec, Cust, IsHandled);
                            if not IsHandled then
                                if Cust."Privacy Blocked" then
                                    Cust.CustPrivacyBlockedErrorMessage(Cust, false);
                            IsHandled := false;
                            OnValidateBillToCustomerNoOnBeforeBlockedCheck(Rec, Cust, IsHandled);
                            if not IsHandled then
                                if Cust.Blocked = Cust.Blocked::All then
                                    Cust.CustBlockedErrorMessage(Cust, false);
                        end;

                    if "Customer No." <> '' then begin
                        Cust.Get("Customer No.");
                        if Cust."Bill-to Customer No." <> '' then
                            if "Bill-to Customer No." = '' then
                                "Bill-to Customer No." := Cust."Bill-to Customer No.";
                    end;
                    if "Bill-to Customer No." = '' then
                        "Bill-to Customer No." := "Customer No.";
                    if Cust.Get("Bill-to Customer No.") then begin
                        "Currency Code" := Cust."Currency Code";
                        "Payment Terms Code" := Cust."Payment Terms Code";
                        Validate("Payment Method Code", Cust."Payment Method Code");
                        "Language Code" := Cust."Language Code";
                        "Format Region" := Cust."Format Region";
                        SetSalespersonCode(Cust."Salesperson Code", "Salesperson Code");
                        if not SkipBillToContact then
                            "Bill-to Contact" := Cust.Contact;
                        OnValidateBillToCustomerNoOnAfterCopyFieldsFromCust(Rec, Cust, SkipBillToContact);
                    end;

                    if not HideValidationDialog then
                        ServCheckCreditLimit.ServiceContractHeaderCheck(Rec);

                    CalcFields(
                      "Bill-to Name", "Bill-to Name 2", "Bill-to Address", "Bill-to Address 2",
                      "Bill-to Post Code", "Bill-to City", "Bill-to County", "Bill-to Country/Region Code");

                    if not SkipBillToContact then
                        UpdateBillToCont("Bill-to Customer No.");
                end else
                    "Bill-to Customer No." := xRec."Bill-to Customer No.";

                CreateDimFromDefaultDim(Rec.FieldNo("Bill-to Customer No."));
            end;
        }
        field(17; "Bill-to Name"; Text[100])
        {
            CalcFormula = lookup(Customer.Name where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Bill-to Address"; Text[100])
        {
            CalcFormula = lookup(Customer.Address where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Address';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Bill-to Address 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Address 2" where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Address 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Bill-to Post Code"; Code[20])
        {
            CalcFormula = lookup(Customer."Post Code" where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Post Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Bill-to City"; Text[30])
        {
            CalcFormula = lookup(Customer.City where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to City';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Customer No." <> xRec."Customer No.") or ("Ship-to Code" <> xRec."Ship-to Code") then begin
                    IsHandled := false;
                    OnValidateShipToCodeOnBeforeContractLinesExist(Rec, IsHandled);
                    if not IsHandled then
                        if ContractLinesExist() then
                            Error(Text011, FieldCaption("Ship-to Code"));
                    UpdateServZone();
                end;
            end;
        }
        field(23; "Ship-to Name"; Text[100])
        {
            CalcFormula = lookup("Ship-to Address".Name where("Customer No." = field("Customer No."),
                                                               Code = field("Ship-to Code")));
            Caption = 'Ship-to Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Ship-to Address"; Text[100])
        {
            CalcFormula = lookup("Ship-to Address".Address where("Customer No." = field("Customer No."),
                                                                  Code = field("Ship-to Code")));
            Caption = 'Ship-to Address';
            Editable = false;
            FieldClass = FlowField;
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            CalcFormula = lookup("Ship-to Address"."Address 2" where("Customer No." = field("Customer No."),
                                                                      Code = field("Ship-to Code")));
            Caption = 'Ship-to Address 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Ship-to Post Code"; Code[20])
        {
            CalcFormula = lookup("Ship-to Address"."Post Code" where("Customer No." = field("Customer No."),
                                                                      Code = field("Ship-to Code")));
            Caption = 'Ship-to Post Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; "Ship-to City"; Text[30])
        {
            CalcFormula = lookup("Ship-to Address".City where("Customer No." = field("Customer No."),
                                                               Code = field("Ship-to Code")));
            Caption = 'Ship-to City';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Serv. Contract Acc. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Contract Acc. Gr. Code';
            TableRelation = "Service Contract Account Group";
        }
        field(32; "Invoice Period"; Enum "Service Contract Header Invoice Period")
        {
            Caption = 'Invoice Period';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateInvoicePeriod(Rec, IsHandled);
                if IsHandled then
                    exit;

                CalcInvPeriodDuration();
                if (Format("Price Update Period") <> '') and
                   (CalcDate("Price Update Period", "Starting Date") < CalcDate(InvPeriodDuration, "Starting Date"))
                then
                    Error(Text065, FieldCaption("Invoice Period"), FieldCaption("Price Update Period"));

                CheckChangeStatus();
                if ("Invoice Period" = "Invoice Period"::None) and
                   ("Last Invoice Date" <> 0D)
                then
                    Error(Text041,
                      FieldCaption("Invoice Period"),
                      Format("Invoice Period"),
                      TableCaption);

                if "Invoice Period" = "Invoice Period"::None then begin
                    "Amount per Period" := 0;
                    "Next Invoice Date" := 0D;
                    "Next Invoice Period Start" := 0D;
                    "Next Invoice Period End" := 0D;
                end else
                    if IsInvoicePeriodInTimeSegment() then
                        if Prepaid then begin
                            if "Next Invoice Date" = 0D then begin
                                if "Last Invoice Date" = 0D then begin
                                    TestField("Starting Date");
                                    if "Starting Date" = CalcDate('<-CM>', "Starting Date") then
                                        Validate("Next Invoice Date", "Starting Date")
                                    else
                                        Validate("Next Invoice Date", CalcDate('<-CM+1M>', "Starting Date"));
                                end else
                                    if "Last Invoice Date" = CalcDate('<-CM>', "Last Invoice Date") then
                                        Validate("Next Invoice Date", CalcDate('<CM+1D>', "Last Invoice Period End"))
                                    else
                                        Validate("Next Invoice Date", CalcDate('<-CM+1M>', "Last Invoice Date"));
                            end else
                                Validate("Next Invoice Date");
                        end else
                            Validate("Last Invoice Date");
            end;
        }
        field(33; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLastInvoiceDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField("Starting Date");
                if "Last Invoice Date" = 0D then
                    if Prepaid then
                        TempDate := CalcDate('<-1D-CM>', "Starting Date")
                    else
                        TempDate := CalcDate('<-1D+CM>', "Starting Date")
                else
                    TempDate := "Last Invoice Date";
                case "Invoice Period" of
                    "Invoice Period"::Month:
                        "Next Invoice Date" := CalcDate('<1M>', TempDate);
                    "Invoice Period"::"Two Months":
                        "Next Invoice Date" := CalcDate('<2M>', TempDate);
                    "Invoice Period"::Quarter:
                        "Next Invoice Date" := CalcDate('<3M>', TempDate);
                    "Invoice Period"::"Half Year":
                        "Next Invoice Date" := CalcDate('<6M>', TempDate);
                    "Invoice Period"::Year:
                        "Next Invoice Date" := CalcDate('<12M>', TempDate);
                    "Invoice Period"::None:
                        if Prepaid then
                            "Next Invoice Date" := 0D;
                end;
                if not Prepaid and ("Next Invoice Date" <> 0D) then
                    "Next Invoice Date" := CalcDate('<CM>', "Next Invoice Date");

                if ("Last Invoice Date" <> 0D) and ("Last Invoice Date" <> xRec."Last Invoice Date") then
                    if Prepaid then
                        Validate("Last Invoice Period End", "Next Invoice Period End")
                    else
                        Validate("Last Invoice Period End", "Last Invoice Date");

                Validate("Next Invoice Date");
            end;
        }
        field(34; "Next Invoice Date"; Date)
        {
            Caption = 'Next Invoice Date';
            Editable = false;

            trigger OnValidate()
            var
                ServLedgEntry: Record "Service Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNextInvoiceDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Next Invoice Date" = 0D then begin
                    "Next Invoice Period Start" := 0D;
                    "Next Invoice Period End" := 0D;
                    exit;
                end;
                if "Last Invoice Date" <> 0D then
                    if "Last Invoice Date" > "Next Invoice Date" then begin
                        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
                        ServLedgEntry.SetRange("No.", "Contract No.");
                        if not ServLedgEntry.IsEmpty() then
                            Error(Text023, FieldCaption("Next Invoice Date"), FieldCaption("Last Invoice Date"));
                        "Last Invoice Date" := 0D;
                    end;

                if "Next Invoice Date" < "Starting Date" then
                    Error(Text024, FieldCaption("Next Invoice Date"), FieldCaption("Starting Date"));

                if Prepaid then begin
                    if "Next Invoice Date" <> CalcDate('<-CM>', "Next Invoice Date") then begin
                        IsHandled := false;
                        OnValidateNextInvoiceDateOnBeforeCheck(Rec, IsHandled);
                        if not IsHandled then
                            Error(Text026, FieldCaption("Next Invoice Date"));
                    end;
                    TempDate := CalculateEndPeriodDate(true, "Next Invoice Date");
                    if "Expiration Date" <> 0D then
                        if "Next Invoice Date" > "Expiration Date" then
                            "Next Invoice Date" := 0D
                        else
                            if TempDate > "Expiration Date" then
                                TempDate := "Expiration Date";
                    if ("Next Invoice Date" <> 0D) and (TempDate <> 0D) then begin
                        "Next Invoice Period Start" := "Next Invoice Date";
                        "Next Invoice Period End" := TempDate;
                    end else begin
                        "Next Invoice Period Start" := 0D;
                        "Next Invoice Period End" := 0D;
                    end;
                end else begin
                    if "Next Invoice Date" <> CalcDate('<CM>', "Next Invoice Date") then begin
                        IsHandled := false;
                        OnValidateNextInvoiceDateOnBeforeCheck(Rec, IsHandled);
                        if not IsHandled then
                            Error(Text028, FieldCaption("Next Invoice Date"));
                    end;
                    TempDate := CalculateEndPeriodDate(false, "Next Invoice Date");
                    if TempDate < "Starting Date" then
                        TempDate := "Starting Date";

                    if "Expiration Date" <> 0D then
                        if "Expiration Date" < TempDate then
                            "Next Invoice Date" := 0D
                        else
                            if "Expiration Date" < "Next Invoice Date" then
                                "Next Invoice Date" := "Expiration Date";

                    if ("Next Invoice Date" <> 0D) and (TempDate <> 0D) then begin
                        "Next Invoice Period Start" := TempDate;
                        "Next Invoice Period End" := "Next Invoice Date";
                    end else begin
                        "Next Invoice Period Start" := 0D;
                        "Next Invoice Period End" := 0D;
                    end;
                end;

                OnValidateNextInvoiceDateOnBeforeValidateNextInvoicePeriod(Rec);
                ValidateNextInvoicePeriod();
            end;
        }
        field(35; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStartingDate(Rec, ServContractLine, IsHandled);
                if IsHandled then
                    exit;

                CheckChangeStatus();

                if "Last Invoice Date" <> 0D then
                    Error(
                      Text029,
                      FieldCaption("Starting Date"), Format("Contract Type"));
                if "Starting Date" = 0D then begin
                    Validate("Next Invoice Date", 0D);
                    "First Service Date" := 0D;
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", "Contract Type");
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("New Line", true);
                    OnValidateStartingDateOnAfterServContractLineSetFilters(Rec, ServContractLine);
                    if ServContractLine.Find('-') then begin
                        repeat
                            ServContractLine."Starting Date" := 0D;
                            ServContractLine."Next Planned Service Date" := 0D;
                            ServContractLine.Modify();
                        until ServContractLine.Next() = 0;
                        Modify(true);
                    end;
                end else begin
                    if "Starting Date" > "First Service Date" then
                        "First Service Date" := "Starting Date";
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", "Contract Type");
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetRange("New Line", true);
                    OnValidateStartingDateOnAfterServContractLineSetFilters(Rec, ServContractLine);
                    if ServContractLine.Find('-') then begin
                        repeat
                            ServContractLine.SuspendStatusCheck(true);
                            ServContractLine."Starting Date" := "Starting Date";
                            ServContractLine."Next Planned Service Date" := "First Service Date";
                            ServContractLine.Modify();
                        until ServContractLine.Next() = 0;
                        Modify(true);
                    end;
                    if "Next Price Update Date" = 0D then
                        "Next Price Update Date" := CalcDate("Price Update Period", "Starting Date");
                    if IsInvoicePeriodInTimeSegment() then
                        if Prepaid then begin
                            if "Starting Date" = CalcDate('<-CM>', "Starting Date") then
                                Validate("Next Invoice Date", "Starting Date")
                            else
                                Validate("Next Invoice Date", CalcDate('<-CM+1M>', "Starting Date"))
                        end else
                            Validate("Last Invoice Date");
                    Validate("Service Period");
                end;
            end;
        }
        field(36; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                if "Expiration Date" <> xRec."Expiration Date" then begin
                    CheckExpirationDate();
                    ChangeExpirationDate();
                end;
            end;
        }
        field(38; "First Service Date"; Date)
        {
            Caption = 'First Service Date';

            trigger OnValidate()
            begin
                if "First Service Date" <> xRec."First Service Date" then begin
                    if ("Contract Type" = "Contract Type"::Contract) and
                       (Status = Status::Signed)
                    then
                        Error(
                          Text030,
                          FieldCaption("First Service Date"));

                    if "First Service Date" < "Starting Date" then
                        Error(
                          Text023,
                          FieldCaption("First Service Date"),
                          FieldCaption("Starting Date"));

                    if "Contract Type" = "Contract Type"::Quote then
                        if ContractLinesExist() then
                            Message(
                              Text031, FieldCaption("First Service Date"));
                end;
            end;
        }
        field(39; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';
        }
        field(40; "Calcd. Annual Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Service Contract Line"."Line Amount" where("Contract Type" = field("Contract Type"),
                                                                           "Contract No." = field("Contract No.")));
            Caption = 'Calcd. Annual Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Annual Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Annual Amount';
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckChangeStatus();
                ServMgtSetup.Get();
                DistributeAmounts();
                Validate("Invoice Period");
            end;
        }
        field(43; "Amount per Period"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount per Period';
            Editable = false;
        }
        field(44; "Combine Invoices"; Boolean)
        {
            Caption = 'Combine Invoices';
        }
        field(45; Prepaid; Boolean)
        {
            Caption = 'Prepaid';

            trigger OnValidate()
            var
                ServLedgEntry: Record "Service Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepaid(Rec, xRec, ServLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                if Prepaid <> xRec.Prepaid then begin
                    if "Contract Type" = "Contract Type"::Contract then begin
                        ServLedgEntry.SetCurrentKey("Service Contract No.");
                        ServLedgEntry.SetRange("Service Contract No.", "Contract No.");
                        if not ServLedgEntry.IsEmpty() then
                            Error(
                              Text032,
                              FieldCaption(Prepaid), TableCaption(), "Contract No.");
                    end;
                    TestField("Starting Date");
                    if Prepaid then begin
                        if "Invoice after Service" then
                            Error(
                              Text057,
                              FieldCaption("Invoice after Service"),
                              FieldCaption(Prepaid));
                        if "Invoice Period" = "Invoice Period"::None then
                            Validate("Next Invoice Date", 0D)
                        else
                            if IsInvoicePeriodInTimeSegment() then
                                if "Starting Date" = CalcDate('<-CM>', "Starting Date") then
                                    Validate("Next Invoice Date", "Starting Date")
                                else
                                    Validate("Next Invoice Date", CalcDate('<-CM+1M>', "Starting Date"));
                    end else
                        Validate("Last Invoice Date");
                end;
            end;
        }
        field(46; "Next Invoice Period"; Text[30])
        {
            Caption = 'Next Invoice Period';
            Editable = false;
        }
        field(47; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";
        }
        field(48; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(49; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(50; "Cancel Reason Code"; Code[10])
        {
            Caption = 'Cancel Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Last Price Update Date"; Date)
        {
            Caption = 'Last Price Update Date';
            Editable = false;
        }
        field(52; "Next Price Update Date"; Date)
        {
            Caption = 'Next Price Update Date';

            trigger OnValidate()
            begin
                if "Next Price Update Date" < "Next Invoice Date" then
                    Error(Text064, FieldCaption("Next Price Update Date"), FieldCaption("Next Invoice Date"));
            end;
        }
        field(53; "Last Price Update %"; Decimal)
        {
            Caption = 'Last Price Update %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(55; "Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                CheckChangeStatus();

                if "Response Time (Hours)" <> xRec."Response Time (Hours)" then begin
                    ServContractLine.Reset();
                    ServContractLine.SetRange("Contract Type", "Contract Type");
                    ServContractLine.SetRange("Contract No.", "Contract No.");
                    ServContractLine.SetFilter("Response Time (Hours)", '>%1', "Response Time (Hours)");
                    if ServContractLine.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text034, FieldCaption("Response Time (Hours)")), true)
                        then
                            ServContractLine.ModifyAll("Response Time (Hours)", "Response Time (Hours)", true);
                end;
            end;
        }
        field(56; "Contract Lines on Invoice"; Boolean)
        {
            Caption = 'Contract Lines on Invoice';
        }
        field(57; "No. of Posted Invoices"; Integer)
        {
            CalcFormula = count("Service Document Register" where("Source Document Type" = const(Contract),
                                                                   "Source Document No." = field("Contract No."),
                                                                   "Destination Document Type" = const("Posted Invoice")));
            Caption = 'No. of Posted Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "No. of Unposted Invoices"; Integer)
        {
            CalcFormula = count("Service Document Register" where("Source Document Type" = const(Contract),
                                                                   "Source Document No." = field("Contract No."),
                                                                   "Destination Document Type" = const(Invoice)));
            Caption = 'No. of Unposted Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';

            trigger OnValidate()
            begin
                if "Service Period" <> xRec."Service Period" then begin
                    if ("Contract Type" = "Contract Type"::Contract) and
                       (Status = Status::Signed)
                    then
                        Error(
                          Text030,
                          FieldCaption("Service Period"));
                    if "Contract Type" = "Contract Type"::Quote then
                        if ContractLinesExist() then
                            Message(Text031, FieldCaption("Service Period"));
                    if ContractLinesExist() and (Format("Service Period") <> '') then begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", "Contract Type");
                        ServContractLine.SetRange("Contract No.", "Contract No.");
                        if ServContractLine.Find('-') then
                            repeat
                                if (Format(ServContractLine."Service Period") = '') or
                                   (ServContractLine."Service Period" = xRec."Service Period")
                                then begin
                                    ServContractLine."Service Period" := "Service Period";
                                    ServContractLine.Modify();
                                end;
                            until ServContractLine.Next() = 0;
                    end;
                end;
            end;
        }
        field(60; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(62; "Invoice after Service"; Boolean)
        {
            Caption = 'Invoice after Service';

            trigger OnValidate()
            begin
                if not ServHeader.ReadPermission and
                   "Invoice after Service" = true
                then
                    Error(Text054);
                if "Invoice after Service" and
                   Prepaid
                then
                    Error(
                      Text057,
                      FieldCaption("Invoice after Service"),
                      FieldCaption(Prepaid));
            end;
        }
        field(63; "Quote Type"; Enum "Service Contract Quote Type")
        {
            Caption = 'Quote Type';
        }
        field(64; "Allow Unbalanced Amounts"; Boolean)
        {
            Caption = 'Allow Unbalanced Amounts';

            trigger OnValidate()
            begin
                CheckChangeStatus();
                ServMgtSetup.Get();
                if "Allow Unbalanced Amounts" <> xRec."Allow Unbalanced Amounts" then
                    DistributeAmounts();
            end;
        }
        field(65; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            TableRelation = "Contract Group";
        }
        field(66; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Service Order Type"));
            end;
        }
        field(67; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                CheckChangeStatus();
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(68; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                CheckChangeStatus();
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(69; "Accept Before"; Date)
        {
            Caption = 'Accept Before';
        }
        field(71; "Automatic Credit Memos"; Boolean)
        {
            Caption = 'Automatic Credit Memos';
        }
        field(74; "Template No."; Code[20])
        {
            Caption = 'Template No.';

            trigger OnValidate()
            begin
                CreateDimFromDefaultDim(Rec.FieldNo("Template No."));
            end;
        }
        field(75; "Price Update Period"; DateFormula)
        {
            Caption = 'Price Update Period';
            InitValue = '1Y';

            trigger OnValidate()
            begin
                CalcInvPeriodDuration();
                if (Format("Price Update Period") <> '') and
                   (CalcDate("Price Update Period", "Starting Date") < CalcDate(InvPeriodDuration, "Starting Date"))
                then
                    Error(Text064, FieldCaption("Price Update Period"), FieldCaption("Invoice Period"));

                if Format("Price Update Period") <> '' then
                    if "Last Price Update Date" <> 0D then
                        "Next Price Update Date" := CalcDate("Price Update Period", "Last Price Update Date")
                    else
                        "Next Price Update Date" := CalcDate("Price Update Period", "Starting Date")
                else
                    "Next Price Update Date" := 0D;
            end;
        }
        field(79; "Price Inv. Increase Code"; Code[20])
        {
            Caption = 'Price Inv. Increase Code';
            TableRelation = "Standard Text";
        }
        field(80; "Print Increase Text"; Boolean)
        {
            Caption = 'Print Increase Text';
        }
        field(81; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCurrencyCode(Rec, xRec, IsHandled);
                if not IsHandled then
                    Message(Text042, FieldCaption("Currency Code"));
            end;
        }
        field(82; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(83; Probability; Decimal)
        {
            Caption = 'Probability';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
        }
        field(84; Comment; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Contract"),
                                                              "Table Subtype" = field("Contract Type"),
                                                              "No." = field("Contract No."),
                                                              "Table Line No." = filter(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                if not UserMgt.CheckRespCenter(2, "Responsibility Center") then
                    Error(
                      Text040,
                      RespCenter.TableCaption(), UserMgt.GetSalesFilter());

                CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));
            end;
        }
        field(86; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(87; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(88; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(89; "Bill-to County"; Text[30])
        {
            CalcFormula = lookup(Customer.County where("No." = field("Bill-to Customer No.")));
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            Editable = false;
            FieldClass = FlowField;
        }
        field(90; County; Text[30])
        {
            CalcFormula = lookup(Customer.County where("No." = field("Customer No.")));
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Ship-to County"; Text[30])
        {
            CalcFormula = lookup("Ship-to Address".County where("Customer No." = field("Customer No."),
                                                                 Code = field("Ship-to Code")));
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
            Editable = false;
            FieldClass = FlowField;
        }
        field(92; "Country/Region Code"; Code[10])
        {
            CalcFormula = lookup(Customer."Country/Region Code" where("No." = field("Customer No.")));
            Caption = 'Country/Region Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(93; "Bill-to Country/Region Code"; Code[10])
        {
            CalcFormula = lookup(Customer."Country/Region Code" where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Country/Region Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Ship-to Country/Region Code"; Code[10])
        {
            CalcFormula = lookup("Ship-to Address"."Country/Region Code" where("Customer No." = field("Customer No."),
                                                                                Code = field("Ship-to Code")));
            Caption = 'Ship-to Country/Region Code';
            Editable = false;
            FieldClass = FlowField;
        }
        field(95; "Name 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Name 2" where("No." = field("Customer No.")));
            Caption = 'Name 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(96; "Bill-to Name 2"; Text[50])
        {
            CalcFormula = lookup(Customer."Name 2" where("No." = field("Bill-to Customer No.")));
            Caption = 'Bill-to Name 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(97; "Ship-to Name 2"; Text[50])
        {
            CalcFormula = lookup("Ship-to Address"."Name 2" where("Customer No." = field("Customer No."),
                                                                   Code = field("Ship-to Code")));
            Caption = 'Ship-to Name 2';
            Editable = false;
            FieldClass = FlowField;
        }
        field(98; "Next Invoice Period Start"; Date)
        {
            Caption = 'Next Invoice Period Start';
            Editable = false;
        }
        field(99; "Next Invoice Period End"; Date)
        {
            Caption = 'Next Invoice Period End';
            Editable = false;
        }
        field(100; "Contract Invoice Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Amount (LCY)" where("Service Contract No." = field("Contract No."),
                                                                            "Entry Type" = const(Sale),
                                                                            "Moved from Prepaid Acc." = const(true),
                                                                            Type = field("Type Filter"),
                                                                            "Posting Date" = field("Date Filter"),
                                                                            Open = const(false)));
            Caption = 'Contract Invoice Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(101; "Contract Prepaid Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = - sum("Service Ledger Entry"."Amount (LCY)" where("Service Contract No." = field("Contract No."),
                                                                            "Entry Type" = const(Sale),
                                                                            "Moved from Prepaid Acc." = const(false),
                                                                            Type = const("Service Contract"),
                                                                            "Posting Date" = field("Date Filter"),
                                                                            Open = const(false),
                                                                            Prepaid = const(true)));
            Caption = 'Contract Prepaid Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(102; "Contract Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Service Ledger Entry"."Contract Disc. Amount" where("Service Contract No." = field("Contract No."),
                                                                                    "Entry Type" = const(Sale),
                                                                                    "Moved from Prepaid Acc." = const(true),
                                                                                    Type = field("Type Filter"),
                                                                                    "Posting Date" = field("Date Filter"),
                                                                                    Open = const(false)));
            Caption = 'Contract Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(103; "Contract Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Service Ledger Entry"."Cost Amount" where("Service Contract No." = field("Contract No."),
                                                                          "Entry Type" = const(Usage),
                                                                          "Moved from Prepaid Acc." = const(true),
                                                                          Type = field("Type Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                          Open = const(false)));
            Caption = 'Contract Cost Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(104; "Contract Gain/Loss Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Contract Gain/Loss Entry".Amount where("Contract No." = field("Contract No."),
                                                                       "Reason Code" = field("Reason Code Filter"),
                                                                       "Change Date" = field("Date Filter")));
            Caption = 'Contract Gain/Loss Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(106; "No. of Posted Credit Memos"; Integer)
        {
            CalcFormula = count("Service Document Register" where("Source Document Type" = const(Contract),
                                                                   "Source Document No." = field("Contract No."),
                                                                   "Destination Document Type" = const("Posted Credit Memo")));
            Caption = 'No. of Posted Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(107; "No. of Unposted Credit Memos"; Integer)
        {
            CalcFormula = count("Service Document Register" where("Source Document Type" = const(Contract),
                                                                   "Source Document No." = field("Contract No."),
                                                                   "Destination Document Type" = const("Credit Memo")));
            Caption = 'No. of Unposted Credit Memos';
            Editable = false;
            FieldClass = FlowField;
        }
        field(140; "Type Filter"; Enum "Service Ledger Entry Type")
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
        }
        field(141; "Reason Code Filter"; Code[10])
        {
            Caption = 'Reason Code Filter';
            FieldClass = FlowFilter;
            TableRelation = "Reason Code";
        }
        field(142; "Posted Service Order Filter"; Code[20])
        {
            Caption = 'Posted Service Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Shipment Header";
        }
        field(143; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(144; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
            TableRelation = Item;
        }
        field(204; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                if PaymentMethod.Get("Payment Method Code") then
                    if PaymentMethod."Direct Debit" then begin
                        "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Expiration Date");
                        if "Payment Terms Code" = '' then
                            "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                    end else
                        "Direct Debit Mandate ID" := '';
            end;
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            CalcFormula = lookup("Ship-to Address"."Phone No." where("Customer No." = field("Customer No."), Code = field("Ship-to Code")));
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
            Editable = false;
            FieldClass = FlowField;
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
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."),
                                                               Closed = const(false),
                                                               Blocked = const(false));
            DataClassification = SystemMetadata;
        }
        field(5050; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                if ("Customer No." <> '') and Cont.Get("Contact No.") then
                    Cont.SetRange("Company No.", Cont."Company No.")
                else
                    if "Customer No." <> '' then begin
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.");
                    end else
                        Cont.SetFilter("Company No.", '<>%1', '''');

                if "Contact No." <> '' then
                    if Cont.Get("Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                if ("Contact No." <> xRec."Contact No.") and (xRec."Contact No." <> '') then begin
                    IsHandled := false;
                    OnBeforeConfirmChangeContactNo(Rec, IsHandled);
                    if not IsHandled then
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014, FieldCaption("Contact No.")), true) then begin
                            "Contact No." := xRec."Contact No.";
                            exit;
                        end;
                end;

                if ("Customer No." <> '') and ("Contact No." <> '') then begin
                    Cont.Get("Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") then
                        if ContBusinessRelation."Contact No." <> Cont."Company No." then
                            Error(Text045, Cont."No.", Cont.Name, "Customer No.");
                end;

                UpdateCust("Contact No.");
            end;
        }
        field(5051; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                if ("Bill-to Customer No." <> '') and Cont.Get("Bill-to Contact No.") then
                    Cont.SetRange("Company No.", Cont."Company No.")
                else
                    if Cust.Get("Bill-to Customer No.") then begin
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.");
                    end else
                        Cont.SetFilter("Company No.", '<>%1', '''');

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Bill-to Contact No.", Cont."No.");
                end;
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and (xRec."Bill-to Contact No." <> '') then begin
                    IsHandled := false;
                    OnBeforeConfirmChangeBillToContactNo(Rec, IsHandled);
                    if not IsHandled then
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014, FieldCaption("Bill-to Contact No.")), true) then begin
                            "Bill-to Contact No." := xRec."Bill-to Contact No.";
                            exit;
                        end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then begin
                    Cont.Get("Bill-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                        if (ContBusinessRelation."Contact No." <> Cont."Company No.") and (Cont.Type = Cont.Type::Company) then
                            Error(Text045, Cont."No.", Cont.Name, "Bill-to Customer No.");
                end;

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5052; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(5053; "Last Invoice Period End"; Date)
        {
            Caption = 'Last Invoice Period End';
        }
    }

    keys
    {
        key(Key1; "Contract Type", "Contract No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract No.", "Contract Type")
        {
        }
        key(Key3; "Customer No.", "Ship-to Code")
        {
        }
        key(Key4; "Bill-to Customer No.", "Contract Type", "Combine Invoices", "Next Invoice Date")
        {
        }
        key(Key5; "Next Price Update Date")
        {
        }
        key(Key6; "Responsibility Center", "Service Zone Code", Status, "Contract Group Code")
        {
        }
        key(Key7; "Salesperson Code", Status)
        {
        }
        key(Key8; "Template No.")
        {
        }
        key(Key9; "Customer No.", "Bill-to Customer No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Customer No.", "Currency Code", "Ship-to Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Expiration Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Contract No.", Description, "Customer No.", Status, "Change Status", "Starting Date")
        {
        }
        fieldgroup(Brick; "Contract No.", Description, "Customer No.", Status, "Change Status", "Starting Date")
        {
        }
    }

    trigger OnDelete()
    var
        ServLedgEntry: Record "Service Ledger Entry";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not UserMgt.CheckRespCenter(2, "Responsibility Center") then
            Error(
              Text002,
              RespCenter.TableCaption(), UserMgt.GetSalesFilter());

        if "Contract Type" = "Contract Type"::Contract then begin
            ServMoveEntries.MoveServContractLedgerEntries(Rec);

            if Status = Status::Signed then
                Error(Text003, Format(Status), TableCaption);

            ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
            ServLedgEntry.SetRange("No.", "Contract No.");
            ServLedgEntry.SetRange(Prepaid, false);
            ServLedgEntry.SetRange(Open, true);
            if not ServLedgEntry.IsEmpty() then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(Text052, ServLedgEntry.FieldCaption(Open)), true)
                then
                    Error(Text053);
        end;
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", "Contract Type");
        ServContractLine.SetRange("Contract No.", "Contract No.");
        ServContractLine.DeleteAll();

        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Contract");
        ServCommentLine.SetRange("Table Subtype", "Contract Type");
        ServCommentLine.SetRange("No.", "Contract No.");
        ServCommentLine.DeleteAll();

        ServHour.Reset();
        case "Contract Type" of
            "Contract Type"::Quote:
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::Quote);
            "Contract Type"::Contract:
                ServHour.SetRange("Service Contract Type", ServHour."Service Contract Type"::Contract);
        end;
        ServHour.SetRange("Service Contract No.", "Contract No.");
        ServHour.DeleteAll();

        ServMgtSetup.SetLoadFields("Del. Filed Cont. w. main Cont.");
        ServMgtSetup.Get();
        if ServMgtSetup."Del. Filed Cont. w. main Cont." then begin
            FiledServiceContractHeader.SetCurrentKey("Contract Type Relation", "Contract No. Relation");
            FiledServiceContractHeader.SetRange("Contract Type Relation", "Contract Type");
            FiledServiceContractHeader.SetRange("Contract No. Relation", "Contract No.");
            FiledServiceContractHeader.DeleteAll(true);
        end;
    end;

    trigger OnInsert()
    var
        ServiceContractTemplate: Record "Service Contract Template";
        ServContractQuoteTmplUpd: Codeunit "ServContractQuote-Tmpl. Upd.";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        ServMgtSetup.Get();
        InitNoSeries();
        "Starting Date" := WorkDate();
        "First Service Date" := WorkDate();

        IsHandled := false;
        OnBeforeApplyServiceContractQuoteTemplate(Rec, IsHandled);
        if not IsHandled then begin
            ServiceContractTemplate.Reset();
            if ServiceContractTemplate.FindFirst() then
                if ConfirmManagement.GetResponseOrDefault(Text000, false) then begin
                    Commit();
                    Clear(ServContractQuoteTmplUpd);
                    ServContractQuoteTmplUpd.Run(Rec);
                end;
        end;

        Validate("Starting Date");
    end;

    trigger OnModify()
    begin
        CheckChangeStatus();
        if ("Contract Type" = "Contract Type"::Contract) and ("Contract No." <> '') then begin
            ServMgtSetup.Get();
            if ServMgtSetup."Register Contract Changes" then
                UpdContractChangeLog(xRec);

            if (Status <> xRec.Status) and
               (Status = Status::Cancelled)
            then
                ContractGainLossEntry.CreateEntry(
                    "Service Contract Change Type"::"Contract Canceled", "Contract Type", "Contract No.",
                     -"Annual Amount", "Cancel Reason Code");
        end;

        if (Status = Status::Signed) and
           ("Annual Amount" <> xRec."Annual Amount")
        then
            ContractGainLossEntry.CreateEntry(
                "Service Contract Change Type"::"Manual Update", "Contract Type", "Contract No.",
                "Annual Amount" - xRec."Annual Amount", '');
    end;

    trigger OnRename()
    begin
        Error(Text063, TableCaption);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Do you want to create the contract using a contract template?';
#pragma warning disable AA0470
        Text002: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text003: Label 'You cannot delete %1 %2.';
        Text006: Label 'The %1 field can only be changed to Canceled.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CancelTheContractQst: Label '%1 It is not possible to change a service contract to its previous status.\\Do you want to cancel the contract?', Comment = '%1: Text008';
        OpenPrepaymentEntriesExistTxt: Label 'Open prepayment entries exist for the contract.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label 'You cannot change the %1 field to %2 when the %3 field is %4.';
        Text010: Label 'Do you want to cancel %1?';
        Text011: Label 'You cannot change the %1 field manually because there are contract lines for this customer.\\';
#pragma warning restore AA0470
        Text012: Label 'To change the customer, use the Change Customer function.';
#pragma warning disable AA0470
        Text014: Label 'Do you want to change %1?';
        Text023: Label '%1 cannot be less than %2.';
        Text024: Label 'The %1 cannot be before the %2.';
        Text026: Label '%1 must be the first day in the month.';
        Text027: Label '%1 to %2';
        Text028: Label '%1 must be the last day in the month.';
        Text029: Label 'You are not allowed to change %1 because the %2 has been invoiced.';
        Text030: Label 'You cannot change the %1 field on signed service contracts.';
        Text031: Label 'You have changed the %1 field.\\The contract lines will not be updated.';
        Text032: Label 'You cannot change %1 because %2 %3 has been invoiced.';
        Text034: Label 'Some of the contract lines have a longer response time than the %1 field on the service contract header. Do you want to update them?';
        Text040: Label 'Your identification is set up to process from %1 %2 only.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServHeader: Record "Service Header";
        ServContractHeader: Record "Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        ServMgtSetup: Record "Service Mgt. Setup";
        ServCommentLine: Record "Service Comment Line";
        Cust: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        ContractChangeLog: Record "Contract Change Log";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        RespCenter: Record "Responsibility Center";
        ServHour: Record "Service Hour";
        ServContractLine2: Record "Service Contract Line";
        Currency: Record Currency;
        Salesperson: Record "Salesperson/Purchaser";
        NoSeries: Codeunit "No. Series";
        UserMgt: Codeunit "User Setup Management";
        ServContractMgt: Codeunit ServContractManagement;
        ServOrderMgt: Codeunit ServOrderManagement;
        DimMgt: Codeunit DimensionManagement;
        ServMoveEntries: Codeunit "Serv. Move Entries";
        DaysInThisInvPeriod: Integer;
        DaysInFullInvPeriod: Integer;
        TempDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text041: Label '%1 cannot be changed to %2 because this %3 has been invoiced';
        Text042: Label 'The amounts on the service contract header and service contract lines have not been updated. The value of the %1 field indicates the currency in which the amounts in the sales documents belonging to this contract are calculated. The amounts on the service contract are presented in LCY only.';
        Text044: Label 'Contact %1 %2 is not related to customer %3.';
        Text045: Label 'Contact %1 %2 is related to a different company than customer %3.';
#pragma warning restore AA0470
        Text048: Label 'There are unposted invoices linked to this contract.\\Do you want to cancel the contract?';
        Text049: Label 'There are unposted credit memos linked to this contract.\\Do you want to cancel the contract?';
#pragma warning disable AA0470
        Text051: Label 'Contact %1 %2 is not related to a customer.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ContactNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text052: Label '%1 service ledger entries exist for this service contract\Would you like to continue?';
#pragma warning restore AA0470
        Text053: Label 'The deletion process has been interrupted.';
#pragma warning restore AA0074
        SkipContact: Boolean;
        SkipBillToContact: Boolean;
#pragma warning disable AA0074
        Text054: Label 'You cannot checkmark this field because you do not have permissions for the Service Order Management Area.';
        Text055: Label 'There are unposted invoices and credit memos linked to this contract.\\Do you want to cancel the contract?';
#pragma warning restore AA0074
        StrToInsert: Text[250];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text056: Label 'The contract expiration dates on the service contract lines that are later than %1 on the %2 will be replaced with %3.\Do you want to continue?';
        Text057: Label 'You cannot select both the %1 and the %2 check boxes.';
#pragma warning restore AA0470
        Text058: Label 'You cannot use the Distribution functionality if there are no contract lines in the service contract.';
        Text059: Label 'You cannot use the Distribution Based on Profit option if the sum of values in the Profit field on the contract lines equals to zero.';
        Text060: Label 'You cannot use the Distribution Based on Line Amount option if the sum of values in the Line Amount field on the contract lines equals to zero.';
#pragma warning disable AA0470
        Text061: Label 'The annual amount difference has been distributed and one or more contract lines have zero or less in the %1 fields.\You can enter an amount in the %1 field.';
        Text062: Label 'Some lines containing service items have been added to one or more contracts\while the quote had the %1 %2.\Do you want to see these lines?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Confirmed: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text063: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InvPeriodDuration: DateFormula;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text064: Label '%1 cannot be less than %2.';
        Text065: Label '%1 cannot be more than %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;
        SuspendChangeStatus: Boolean;

    procedure UpdContractChangeLog(OldServContractHeader: Record "Service Contract Header")
    begin
        if "Contract Type" <> OldServContractHeader."Contract Type" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Contract Type"), 0,
              Format(OldServContractHeader."Contract Type"), Format("Contract Type"),
              '', 0);
        if "Contract No." <> OldServContractHeader."Contract No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Contract No."), 0,
              Format(OldServContractHeader."Contract No."), Format("Contract No."),
              '', 0);
        if Description <> OldServContractHeader.Description then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption(Description), 0,
              OldServContractHeader.Description, Description,
              '', 0);
        if "Description 2" <> OldServContractHeader."Description 2" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Description 2"), 0,
              OldServContractHeader."Description 2", "Description 2",
              '', 0);
        if Status <> OldServContractHeader.Status then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption(Status), 0,
              Format(OldServContractHeader.Status), Format(Status),
              '', 0);
        if "Customer No." <> OldServContractHeader."Customer No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Customer No."), 0,
              OldServContractHeader."Customer No.", "Customer No.",
              '', 0);
        if "Contact Name" <> OldServContractHeader."Contact Name" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Contact Name"), 0,
              OldServContractHeader."Contact Name", "Contact Name",
              '', 0);
        if "Your Reference" <> OldServContractHeader."Your Reference" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Your Reference"), 0,
              OldServContractHeader."Your Reference", "Your Reference",
              '', 0);
        if "Salesperson Code" <> OldServContractHeader."Salesperson Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Salesperson Code"), 0,
              OldServContractHeader."Salesperson Code", "Salesperson Code",
              '', 0);
        if "Bill-to Customer No." <> OldServContractHeader."Bill-to Customer No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Bill-to Customer No."), 0,
              OldServContractHeader."Bill-to Customer No.", "Bill-to Customer No.",
              '', 0);
        if "Ship-to Code" <> OldServContractHeader."Ship-to Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Ship-to Code"), 0,
              OldServContractHeader."Ship-to Code", "Ship-to Code",
              '', 0);
        if Prepaid <> OldServContractHeader.Prepaid then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption(Prepaid), 0,
              Format(OldServContractHeader.Prepaid), Format(Prepaid),
              '', 0);
        if "Invoice Period" <> OldServContractHeader."Invoice Period" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Invoice Period"), 0,
              Format(OldServContractHeader."Invoice Period"), Format("Invoice Period"),
              '', 0);
        if "Next Invoice Date" <> OldServContractHeader."Next Invoice Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Next Invoice Date"), 0,
              Format(OldServContractHeader."Next Invoice Date"), Format("Next Invoice Date"),
              '', 0);
        if "Starting Date" <> OldServContractHeader."Starting Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Starting Date"), 0,
              Format(OldServContractHeader."Starting Date"), Format("Starting Date"),
              '', 0);
        if "Expiration Date" <> OldServContractHeader."Expiration Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Expiration Date"), 0,
              Format(OldServContractHeader."Expiration Date"), Format("Expiration Date"),
              '', 0);
        if "First Service Date" <> OldServContractHeader."First Service Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("First Service Date"), 0,
              Format(OldServContractHeader."First Service Date"), Format("First Service Date"),
              '', 0);
        if "Max. Labor Unit Price" <> OldServContractHeader."Max. Labor Unit Price" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Max. Labor Unit Price"), 0,
              Format(OldServContractHeader."Max. Labor Unit Price"), Format("Max. Labor Unit Price"),
              '', 0);
        if "Annual Amount" <> OldServContractHeader."Annual Amount" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Annual Amount"), 0,
              Format(OldServContractHeader."Annual Amount"), Format("Annual Amount"),
              '', 0);
        if "Amount per Period" <> OldServContractHeader."Amount per Period" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Amount per Period"), 0,
              Format(OldServContractHeader."Amount per Period"), Format("Amount per Period"),
              '', 0);
        if "Combine Invoices" <> OldServContractHeader."Combine Invoices" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Combine Invoices"), 0,
              Format(OldServContractHeader."Combine Invoices"), Format("Combine Invoices"),
              '', 0);
        if "Next Invoice Period Start" <> OldServContractHeader."Next Invoice Period Start" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Next Invoice Period Start"), 0,
              Format(OldServContractHeader."Next Invoice Period Start"), Format("Next Invoice Period Start"),
              '', 0);
        if "Next Invoice Period End" <> OldServContractHeader."Next Invoice Period End" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Next Invoice Period End"), 0,
              Format(OldServContractHeader."Next Invoice Period End"), Format("Next Invoice Period End"),
              '', 0);
        if "Service Zone Code" <> OldServContractHeader."Service Zone Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Service Zone Code"), 0,
              Format(OldServContractHeader."Service Zone Code"), Format("Service Zone Code"),
              '', 0);
        if "Cancel Reason Code" <> OldServContractHeader."Cancel Reason Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Cancel Reason Code"), 0,
              Format(OldServContractHeader."Cancel Reason Code"), Format("Cancel Reason Code"),
              '', 0);
        if "Next Price Update Date" <> OldServContractHeader."Next Price Update Date" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Next Price Update Date"), 0,
              Format(OldServContractHeader."Next Price Update Date"), Format("Next Price Update Date"),
              '', 0);
        if "Response Time (Hours)" <> OldServContractHeader."Response Time (Hours)" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Response Time (Hours)"), 0,
              Format(OldServContractHeader."Response Time (Hours)"), Format("Response Time (Hours)"),
              '', 0);
        if "Contract Lines on Invoice" <> OldServContractHeader."Contract Lines on Invoice" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Contract Lines on Invoice"), 0,
              Format(OldServContractHeader."Contract Lines on Invoice"), Format("Contract Lines on Invoice"),
              '', 0);
        if "Service Period" <> OldServContractHeader."Service Period" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Service Period"), 0,
              Format(OldServContractHeader."Service Period"), Format("Service Period"),
              '', 0);
        if "Payment Terms Code" <> OldServContractHeader."Payment Terms Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Payment Terms Code"), 0,
              Format(OldServContractHeader."Payment Terms Code"), Format("Payment Terms Code"),
              '', 0);
        if "Payment Method Code" <> OldServContractHeader."Payment Method Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Payment Method Code"), 0,
              Format(OldServContractHeader."Payment Method Code"), Format("Payment Method Code"),
              '', 0);
        if "Direct Debit Mandate ID" <> OldServContractHeader."Direct Debit Mandate ID" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Direct Debit Mandate ID"), 0,
              Format(OldServContractHeader."Direct Debit Mandate ID"), Format("Direct Debit Mandate ID"),
              '', 0);
        if "Contract Group Code" <> OldServContractHeader."Contract Group Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Contract Group Code"), 0,
              OldServContractHeader."Contract Group Code", "Contract Group Code",
              '', 0);
        if "Service Order Type" <> OldServContractHeader."Service Order Type" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Service Order Type"), 0,
              Format(OldServContractHeader."Service Order Type"), Format("Service Order Type"),
              '', 0);
        if "Accept Before" <> OldServContractHeader."Accept Before" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Accept Before"), 0,
              Format(OldServContractHeader."Accept Before"), Format("Accept Before"),
              '', 0);
        if "Automatic Credit Memos" <> OldServContractHeader."Automatic Credit Memos" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Automatic Credit Memos"), 0,
              Format(OldServContractHeader."Automatic Credit Memos"), Format("Automatic Credit Memos"),
              '', 0);
        if "Price Update Period" <> OldServContractHeader."Price Update Period" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Price Update Period"), 0,
              Format(OldServContractHeader."Price Update Period"), Format("Price Update Period"),
              '', 0);
        if "Price Inv. Increase Code" <> OldServContractHeader."Price Inv. Increase Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Price Inv. Increase Code"), 0,
              Format(OldServContractHeader."Price Inv. Increase Code"), Format("Price Inv. Increase Code"),
              '', 0);
        if "Currency Code" <> OldServContractHeader."Currency Code" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Currency Code"), 0,
              Format(OldServContractHeader."Currency Code"), Format("Currency Code"),
              '', 0);
        if "Responsibility Center" <> OldServContractHeader."Responsibility Center" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Responsibility Center"), 0,
              Format(OldServContractHeader."Responsibility Center"), Format("Responsibility Center"),
              '', 0);
        if "Phone No." <> OldServContractHeader."Phone No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Phone No."), 0,
              Format(OldServContractHeader."Phone No."), Format("Phone No."),
              '', 0);
        if "Fax No." <> OldServContractHeader."Fax No." then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Fax No."), 0,
              Format(OldServContractHeader."Fax No."), Format("Fax No."),
              '', 0);
        if "E-Mail" <> OldServContractHeader."E-Mail" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("E-Mail"), 0,
              Format(OldServContractHeader."E-Mail"), Format("E-Mail"),
              '', 0);
        if "Allow Unbalanced Amounts" <> OldServContractHeader."Allow Unbalanced Amounts" then
            ContractChangeLog.LogContractChange(
              "Contract No.", 0, FieldCaption("Allow Unbalanced Amounts"), 0,
              Format(OldServContractHeader."Allow Unbalanced Amounts"), Format("Allow Unbalanced Amounts"),
              '', 0);

        OnAfterUpdContractChangeLog(Rec, OldServContractHeader);
    end;

    procedure AssistEdit(OldServContract: Record "Service Contract Header"): Boolean
    begin
        ServContractHeader := Rec;

        if NoSeries.LookupRelatedNoSeries(GetServiceContractNos(), OldServContract."No. Series", ServContractHeader."No. Series") then begin
            ServContractHeader."Contract No." := NoSeries.GetNextNo(ServContractHeader."No. Series");
            Rec := ServContractHeader;
            exit(true);
        end;

        OnAfterAssistEdit(OldServContract);
    end;

    local procedure InitNoSeries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitNoSeries(Rec, xRec, ServMgtSetup, IsHandled);
        if IsHandled then
            exit;

        if "Contract No." = '' then begin
            ServMgtSetup.TestField("Service Contract Nos.");
            "No. Series" := GetServiceContractNos();
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "Contract No." := NoSeries.GetNextNo("No. Series");

        end;
    end;

    local procedure GetServiceContractNos() NoSeriesCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetServiceContractNos(Rec, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        ServMgtSetup.Get();
        ServMgtSetup.TestField("Service Contract Nos.");
        exit(ServMgtSetup."Service Contract Nos.");
    end;

    procedure ReturnNoOfPer(InvoicePeriod: Enum "Service Contract Header Invoice Period") RetPer: Integer
    begin
        case InvoicePeriod of
            InvoicePeriod::Month:
                RetPer := 12;
            InvoicePeriod::"Two Months":
                RetPer := 6;
            InvoicePeriod::Quarter:
                RetPer := 4;
            InvoicePeriod::"Half Year":
                RetPer := 2;
            InvoicePeriod::Year:
                RetPer := 1;
            else
                RetPer := 0;
        end;

        OnAfterReturnNoOfPer(InvoicePeriod, RetPer);
    end;

    procedure CalculateEndPeriodDate(Prepaid: Boolean; NextInvDate: Date): Date
    var
        TempDate2: Date;
        IsHandled: Boolean;
        Result: Date;
    begin
        if NextInvDate = 0D then
            exit(0D);

        IsHandled := false;
        OnBeforeCalculateEndPeriodDate(Rec, Prepaid, NextInvDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Prepaid then begin
            case "Invoice Period" of
                "Invoice Period"::Month:
                    TempDate2 := CalcDate('<1M-1D>', NextInvDate);
                "Invoice Period"::"Two Months":
                    TempDate2 := CalcDate('<2M-1D>', NextInvDate);
                "Invoice Period"::Quarter:
                    TempDate2 := CalcDate('<3M-1D>', NextInvDate);
                "Invoice Period"::"Half Year":
                    TempDate2 := CalcDate('<6M-1D>', NextInvDate);
                "Invoice Period"::Year:
                    TempDate2 := CalcDate('<12M-1D>', NextInvDate);
                "Invoice Period"::None:
                    TempDate2 := 0D;
                else
                    OnCalculateEndPeriodDateOnPrepaidCaseElse(Rec, TempDate2);
            end;
            exit(TempDate2);
        end;
        case "Invoice Period" of
            "Invoice Period"::Month:
                TempDate2 := CalcDate('<-CM>', NextInvDate);
            "Invoice Period"::"Two Months":
                TempDate2 := CalcDate('<-CM-1M>', NextInvDate);
            "Invoice Period"::Quarter:
                TempDate2 := CalcDate('<-CM-2M>', NextInvDate);
            "Invoice Period"::"Half Year":
                TempDate2 := CalcDate('<-CM-5M>', NextInvDate);
            "Invoice Period"::Year:
                TempDate2 := CalcDate('<-CM-11M>', NextInvDate);
            "Invoice Period"::None:
                TempDate2 := 0D;
            else
                OnCalculateEndPeriodDateCaseElse(Rec, TempDate2);
        end;
        exit(TempDate2);
    end;

    local procedure CheckExpirationDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExpirationDate(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Expiration Date" <> 0D then begin
            if "Expiration Date" < "Starting Date" then
                Error(Text023, FieldCaption("Expiration Date"), FieldCaption("Starting Date"));
            if "Last Invoice Date" <> 0D then
                if "Expiration Date" < "Last Invoice Date" then
                    Error(
                        Text023, FieldCaption("Expiration Date"), FieldCaption("Last Invoice Date"));
        end;
    end;

    procedure UpdateServZone()
    begin
        if "Ship-to Code" <> '' then begin
            ShipToAddr.Get("Customer No.", "Ship-to Code");
            "Service Zone Code" := ShipToAddr."Service Zone Code";
        end else
            if "Customer No." <> '' then begin
                Cust.Get("Customer No.");
                "Service Zone Code" := Cust."Service Zone Code";
            end else
                "Service Zone Code" := '';

        OnAfterUpdateZone(Rec);
    end;

    local procedure ContractLinesExist() Result: Boolean
    begin
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", "Contract Type");
        ServContractLine.SetRange("Contract No.", "Contract No.");
        Result := ServContractLine.Find('-');

        OnAfterContractLinesExist(ServContractLine, Result);
    end;

    procedure UpdateShiptoCode()
    begin
        if "Ship-to Code" = '' then begin
            "Ship-to Name" := Name;
            "Ship-to Name 2" := "Name 2";
            "Ship-to Address" := Address;
            "Ship-to Address 2" := "Address 2";
            "Ship-to Post Code" := "Post Code";
            "Ship-to City" := City;
            "Ship-to County" := County;
            "Ship-to Phone No." := "Phone No.";
            "Ship-to Country/Region Code" := "Country/Region Code";
        end;
        OnAfterUpdateShipToCode(Rec);
    end;

    procedure NextInvoicePeriod(): Text[250]
    begin
        if ("Next Invoice Period Start" <> 0D) and ("Next Invoice Period End" <> 0D) then
            exit(StrSubstNo(Text027, "Next Invoice Period Start", "Next Invoice Period End"));
    end;

    procedure ValidateNextInvoicePeriod()
    var
        InvFrom: Date;
        InvTo: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateNextInvoicePeriod(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        if NextInvoicePeriod() = '' then begin
            "Amount per Period" := 0;
            exit;
        end;
        Currency.InitRoundingPrecision();
        InvFrom := "Next Invoice Period Start";
        InvTo := "Next Invoice Period End";

        DaysInThisInvPeriod := InvTo - InvFrom + 1;

        if Prepaid then begin
            TempDate := CalculateEndPeriodDate(true, "Next Invoice Date");
            DaysInFullInvPeriod := TempDate - "Next Invoice Date" + 1;
        end else begin
            TempDate := CalculateEndPeriodDate(false, "Next Invoice Date");
            DaysInFullInvPeriod := "Next Invoice Date" - TempDate + 1;
            if (DaysInFullInvPeriod = DaysInThisInvPeriod) and ("Next Invoice Date" = "Expiration Date") then
                DaysInFullInvPeriod := CalculateEndPeriodDate(true, TempDate) - TempDate + 1;
        end;

        SetAmountPerPeriod(InvFrom, InvTo);
    end;

    local procedure SetAmountPerPeriod(InvFrom: Date; InvTo: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetAmountPerPeriod(Rec, InvFrom, InvTo, DaysInFullInvPeriod, DaysInThisInvPeriod, IsHandled);
        if IsHandled then
            exit;

        if DaysInFullInvPeriod = DaysInThisInvPeriod then
            "Amount per Period" :=
              Round("Annual Amount" / ReturnNoOfPer("Invoice Period"), Currency."Amount Rounding Precision")
        else
            "Amount per Period" := Round(
                ServContractMgt.CalcContractAmount(Rec, InvFrom, InvTo), Currency."Amount Rounding Precision");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        if "Change Status" <> "Change Status"::Open then
            exit;

        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, CurrFieldNo, DefaultDimSource);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, CurrFieldNo);
    end;

    procedure SuspendStatusCheck(StatCheckParameter: Boolean)
    begin
        SuspendChangeStatus := StatCheckParameter;
    end;

    procedure UpdateCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
    begin
        if Cust.Get(CustomerNo) then begin
            Clear(ServOrderMgt);
            ContactNo := ServOrderMgt.FindContactInformation(Cust."No.");
            if Cont.Get(ContactNo) then begin
                "Contact No." := Cont."No.";
                "Contact Name" := Cont.Name;
                "Phone No." := Cont."Phone No.";
                "E-Mail" := Cont."E-Mail";
            end else begin
                if Cust."Primary Contact No." <> '' then
                    "Contact No." := Cust."Primary Contact No."
                else
                    if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, "Customer No.") then
                        "Contact No." := ContBusRel."Contact No.";
                "Contact Name" := Cust.Contact;
                OnUpdateContOnAfterUpdateContFromCust(Rec);
            end;
        end;

        OnAfterUpdateCont(Rec, CustomerNo);
    end;

    local procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
        Cust: Record Customer;
    begin
        if Cust.Get(CustomerNo) then begin
            Clear(ServOrderMgt);
            ContactNo := ServOrderMgt.FindContactInformation("Bill-to Customer No.");
            if Cont.Get(ContactNo) then begin
                "Bill-to Contact No." := Cont."No.";
                "Bill-to Contact" := Cont.Name;
            end else begin
                if Cust."Primary Contact No." <> '' then
                    "Bill-to Contact No." := Cust."Primary Contact No."
                else
                    if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, "Bill-to Customer No.") then
                        "Bill-to Contact No." := ContBusRel."Contact No.";
                "Bill-to Contact" := Cust.Contact;
            end;
        end;

        OnAfterUpdateBillToCont(Rec, Cust, Cont);
    end;

    procedure UpdateCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if Cont.Get(ContactNo) then begin
            "Contact No." := Cont."No.";
            "Phone No." := Cont."Phone No.";
            "E-Mail" := Cont."E-Mail";
            if Cont.Type = Cont.Type::Person then begin
                "Contact Name" := Cont.Name;
                ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
                if not ContactBusinessRelationFound then
                    ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
            end else begin
                if not ContactBusinessRelationFound then
                    ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");

                if Cust.Get("Customer No.") then
                    "Contact Name" := Cust.Contact
                else
                    "Contact Name" := ''
            end;
        end else begin
            "Contact Name" := '';
            "Phone No." := '';
            "E-Mail" := '';
            exit;
        end;

        if ContactBusinessRelationFound then begin
            if ("Customer No." <> '') and
               ("Customer No." <> ContBusinessRelation."No.")
            then
                Error(Text044, Cont."No.", Cont.Name, "Customer No.");
            if "Customer No." = '' then begin
                SkipContact := true;
                Validate("Customer No.", ContBusinessRelation."No.");
                SkipContact := false;
            end;
        end else
            Error(Text051, Cont."No.", Cont.Name);

        if ("Customer No." = "Bill-to Customer No.") or
           ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Contact No.");
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
        ContactBusinessRelationFound: Boolean;
    begin
        if Cont.Get(ContactNo) then begin
            "Bill-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then begin
                "Bill-to Contact" := Cont.Name;
                ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
                if not ContactBusinessRelationFound then
                    ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
            end else begin
                if not ContactBusinessRelationFound then
                    ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");

                if Cust.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Cust.Contact
                else
                    "Bill-to Contact" := '';
            end;
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        OnUpdateBillToCustOnBeforeContBusinessRelationFindByContact(Rec, Cust, Cont);
        if ContactBusinessRelationFound then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
            end else
                if "Bill-to Customer No." <> ContBusinessRelation."No." then
                    Error(Text044, Cont."No.", Cont.Name, "Bill-to Customer No.");
        end else
            Error(Text051, Cont."No.", Cont.Name);
    end;

    local procedure EvenDistribution(var ServContractLine2: Record "Service Contract Line")
    var
        OldServContractLine: Record "Service Contract Line";
        AmountToAdjust: Decimal;
    begin
        ServContractLine2.LockTable();
        CalcFields("Calcd. Annual Amount");
        AmountToAdjust := ("Annual Amount" - "Calcd. Annual Amount") / ServContractLine2.Count();
        if ServContractLine2.Find('-') then
            repeat
                OldServContractLine := ServContractLine2;
                ServContractLine2.Validate(
                  "Line Amount",
                  Round(ServContractLine2."Line Amount" + AmountToAdjust, Currency."Amount Rounding Precision"));
                ServContractLine2.Modify();
                if ServMgtSetup."Register Contract Changes" then
                    ServContractLine2.LogContractLineChanges(OldServContractLine);
            until ServContractLine2.Next() = 0;
    end;

    local procedure ProfitBasedDistribution(var ServContractLine2: Record "Service Contract Line")
    var
        OldServContractLine: Record "Service Contract Line";
        TotalProfit: Decimal;
    begin
        ServContractLine2.LockTable();
        ServContractLine2.CalcSums(Profit);
        TotalProfit := ServContractLine2.Profit;
        if TotalProfit = 0 then
            Error(Text059);
        CalcFields("Calcd. Annual Amount");
        if ServContractLine2.Find('-') then
            repeat
                OldServContractLine := ServContractLine2;
                ServContractLine2.Validate(
                  "Line Amount",
                  Round(
                    ServContractLine."Line Amount" +
                    ("Annual Amount" - "Calcd. Annual Amount") *
                    (ServContractLine2.Profit / TotalProfit), Currency."Amount Rounding Precision"));
                ServContractLine2.Modify();
                if ServMgtSetup."Register Contract Changes" then
                    ServContractLine2.LogContractLineChanges(OldServContractLine);
            until ServContractLine2.Next() = 0;
    end;

    local procedure AmountBasedDistribution(var ServContractLine2: Record "Service Contract Line")
    var
        OldServContractLine: Record "Service Contract Line";
    begin
        ServContractLine2.LockTable();
        CalcFields("Calcd. Annual Amount");
        if "Calcd. Annual Amount" = 0 then
            Error(Text060);
        if ServContractLine2.Find('-') then
            repeat
                OldServContractLine := ServContractLine2;
                ServContractLine2.Validate(
                  "Line Amount",
                  Round(
                    ServContractLine2."Line Amount" +
                    ("Annual Amount" - "Calcd. Annual Amount") *
                    (ServContractLine2."Line Amount" / "Calcd. Annual Amount"),
                    Currency."Amount Rounding Precision"));
                ServContractLine2.Modify();
                if ServMgtSetup."Register Contract Changes" then
                    ServContractLine2.LogContractLineChanges(OldServContractLine);
            until ServContractLine2.Next() = 0;
    end;

    local procedure DistributeAmounts()
    var
        OldServContractLine: Record "Service Contract Line";
        Result: Integer;
    begin
        if not "Allow Unbalanced Amounts" then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", "Contract Type");
            ServContractLine.SetRange("Contract No.", "Contract No.");
            if not ServContractLine.Find('-') and ("Annual Amount" <> 0) then
                Error(Text058);
            CalcFields("Calcd. Annual Amount");
            if "Annual Amount" <> "Calcd. Annual Amount" then begin
                ServContractLine.SetRange("Line Value", 0);
                if ServContractLine.Find('-') then
                    ServContractLine.TestField("Line Value");
                ServContractLine.SetRange("Line Value");
                if ServContractLine.Next() <> 0 then begin
                    if AskContractAmountDistribution(Result) then begin
                        Currency.InitRoundingPrecision();
                        case Result of
                            0:
                                EvenDistribution(ServContractLine);
                            1:
                                ProfitBasedDistribution(ServContractLine);
                            2:
                                AmountBasedDistribution(ServContractLine);
                        end;
                        CalcFields("Calcd. Annual Amount");
                        if "Annual Amount" <> "Calcd. Annual Amount" then begin
                            ServContractLine.Validate(
                              "Line Amount",
                              ServContractLine."Line Amount" + "Annual Amount" - "Calcd. Annual Amount");
                            ServContractLine.Modify();
                        end;
                        ServContractLine.SetFilter("Line Amount", '<=0');
                        if ServContractLine.Find('-') then
                            Message(Text061, ServContractLine.FieldCaption("Line Amount"));
                    end else
                        Error('');
                end else begin
                    OldServContractLine := ServContractLine;
                    ServContractLine.Validate("Line Amount", "Annual Amount");
                    ServContractLine.Modify();
                    if ServMgtSetup."Register Contract Changes" then
                        ServContractLine.LogContractLineChanges(OldServContractLine);
                end;
            end;
        end;
    end;

    procedure SetHideValidationDialog(Hide: Boolean)
    begin
        HideValidationDialog := Hide;
    end;

    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserMgt.GetServiceFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetServiceFilter());
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate() - 1);
    end;

    procedure ShowDocDim()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Contract Type", "Contract No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDocDim(Rec);
    end;

    local procedure CalcInvPeriodDuration()
    begin
        if "Invoice Period" <> "Invoice Period"::None then
            case "Invoice Period" of
                "Invoice Period"::Month:
                    Evaluate(InvPeriodDuration, '<1M>');
                "Invoice Period"::"Two Months":
                    Evaluate(InvPeriodDuration, '<2M>');
                "Invoice Period"::Quarter:
                    Evaluate(InvPeriodDuration, '<3M>');
                "Invoice Period"::"Half Year":
                    Evaluate(InvPeriodDuration, '<6M>');
                "Invoice Period"::Year:
                    Evaluate(InvPeriodDuration, '<1Y>');
                else
                    OnCalcInvPeriodDurationCaseElse(Rec, InvPeriodDuration);
            end;
    end;

    local procedure ChangeContractStatus()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ConfirmManagement: Codeunit "Confirm Management";
        AnyServItemInOtherContract: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeContractStatus(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        case "Contract Type" of
            "Contract Type"::Contract:
                begin
                    if Status <> Status::Cancelled then
                        Error(Text006, FieldCaption(Status));

                    CalcFields("No. of Unposted Invoices", "No. of Unposted Credit Memos");
                    case true of
                        ("No. of Unposted Invoices" <> 0) and ("No. of Unposted Credit Memos" = 0):
                            if not ConfirmManagement.GetResponseOrDefault(Text048, true) then begin
                                Status := xRec.Status;
                                exit;
                            end;
                        ("No. of Unposted Invoices" = 0) and ("No. of Unposted Credit Memos" <> 0):
                            if not ConfirmManagement.GetResponseOrDefault(Text049, true) then begin
                                Status := xRec.Status;
                                exit;
                            end;
                        ("No. of Unposted Invoices" <> 0) and ("No. of Unposted Credit Memos" <> 0):
                            if not ConfirmManagement.GetResponseOrDefault(Text055, true) then begin
                                Status := xRec.Status;
                                exit;
                            end;
                    end;

                    ServMgtSetup.Get();
                    if ServMgtSetup."Use Contract Cancel Reason" then
                        TestField("Cancel Reason Code");

                    ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Contract");
                    ServiceLedgerEntry.SetRange("No.", "Contract No.");
                    ServiceLedgerEntry.SetRange("Moved from Prepaid Acc.", false);
                    ServiceLedgerEntry.SetRange(Open, false);
                    ServiceLedgerEntry.CalcSums("Amount (LCY)");
                    if ServiceLedgerEntry."Amount (LCY)" <> 0 then
                        StrToInsert := OpenPrepaymentEntriesExistTxt;

                    IsHandled := false;
                    OnChangeContractStatusOnBeforeConfirmCancelTheContractQst(Rec, IsHandled);
                    if not IsHandled then
                        if not ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(CancelTheContractQst, StrToInsert), true)
                        then begin
                            Status := xRec.Status;
                            exit;
                        end;
                    FiledServiceContractHeader.FileContractBeforeCancellation(xRec);
                end;
            "Contract Type"::Quote:
                case Status of
                    Status::" ":
                        if xRec.Status = xRec.Status::Cancelled then begin
                            ServContractLine.Reset();
                            ServContractLine.SetRange("Contract Type", "Contract Type");
                            ServContractLine.SetRange("Contract No.", "Contract No.");
                            if ServContractLine.Find('-') then
                                repeat
                                    ServContractLine2.Reset();
                                    ServContractLine2.SetCurrentKey("Service Item No.");
                                    ServContractLine2.SetRange("Service Item No.", ServContractLine."Service Item No.");
                                    ServContractLine2.SetRange("Contract Type", "Contract Type"::Contract);
                                    if ServContractLine2.FindFirst() then begin
                                        AnyServItemInOtherContract := true;
                                        ServContractLine.Mark(true);
                                    end;
                                until ServContractLine.Next() = 0;

                            "Change Status" := "Change Status"::Open;

                            if AnyServItemInOtherContract then
                                if ConfirmManagement.GetResponse(
                                        StrSubstNo(Text062, Format(xRec.Status), FieldCaption(Status)), true)
                                then begin
                                    ServContractLine.MarkedOnly(true);
                                    PAGE.RunModal(PAGE::"Service Contract Line List", ServContractLine);
                                end;
                        end;
                    Status::Signed:
                        Error(
                            Text009,
                            FieldCaption(Status), Status, FieldCaption("Contract Type"), "Contract Type");
                    Status::Cancelled:
                        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text010, "Contract No."), true) then begin
                            Status := xRec.Status;
                            exit;
                        end;
                end;
        end;

        if Status = Status::Cancelled then
            "Change Status" := "Change Status"::Locked;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", "Contract Type");
        ServContractLine.SetRange("Contract No.", "Contract No.");
        OnChangeContractStatusOnBeforeModifyServContractLines(ServContractLine, Rec, xRec);
        ServContractLine.ModifyAll("Contract Status", Status);
    end;

    local procedure CheckChangeStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckChangeStatus(Rec, IsHandled);
        if not IsHandled then
            if (Status <> Status::Cancelled) and not SuspendChangeStatus then
                TestField("Change Status", "Change Status"::Open);
    end;

    local procedure ChangeCustomerNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeCustomerNo(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Cust.Get("Customer No.");
        if "Customer No." <> xRec."Customer No." then begin
            IsHandled := false;
            OnCheckChangeStatusOnBeforeCheckContractLinesExist(Rec, IsHandled);
            if not IsHandled then
                if ContractLinesExist() then
                    case "Contract Type" of
                        "Contract Type"::Contract:
                            Error(Text011 + Text012, FieldCaption("Customer No."));
                        "Contract Type"::Quote:
                            Error(Text011, FieldCaption("Customer No."));
                    end;
            Rec.Validate("Ship-to Code", '');
        end;

        Rec."Responsibility Center" := UserMgt.GetRespCenter(2, Cust."Responsibility Center");

        IsHandled := false;
        OnCheckChangeStatusOnBeforeSetBillToCustomerNo(Rec, IsHandled);
        if not IsHandled then
            if "Customer No." <> '' then begin
                if Cust."Bill-to Customer No." = '' then begin
                    if "Bill-to Customer No." = "Customer No." then
                        SkipBillToContact := true;
                    Validate("Bill-to Customer No.", "Customer No.");
                    SkipBillToContact := false;
                end else
                    Validate("Bill-to Customer No.", Cust."Bill-to Customer No.");
                if not SkipContact then begin
                    "Contact Name" := Cust.Contact;
                    "Phone No." := Cust."Phone No.";
                    "E-Mail" := Cust."E-Mail";
                end;
                "Fax No." := Cust."Fax No.";
            end else begin
                "Contact Name" := '';
                "Phone No." := '';
                "Fax No." := '';
                "E-Mail" := '';
                "Service Zone Code" := '';
            end;

        if "Customer No." <> xRec."Customer No." then begin
            CalcFields(
                Name, "Name 2", Address, "Address 2",
                "Post Code", City, County, "Country/Region Code");
            CalcFields(
                "Bill-to Name", "Bill-to Name 2", "Bill-to Address", "Bill-to Address 2",
                "Bill-to Post Code", "Bill-to City", "Bill-to County", "Bill-to Country/Region Code");
            UpdateShiptoCode();
        end;

        if not SkipContact then
            UpdateCont("Customer No.");
    end;

    local procedure ChangeExpirationDate()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeExpirationDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", "Contract Type");
        ServContractLine.SetRange("Contract No.", "Contract No.");
        ServContractLine.SetRange(Credited, false);

        if ("Expiration Date" <> 0D) or
            ("Contract Type" = "Contract Type"::Quote)
        then begin
            if "Contract Type" = "Contract Type"::Contract then begin
                ServContractLine.SetFilter("Contract Expiration Date", '>%1', "Expiration Date");
                if ServContractLine.Find('-') then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                            ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(Text056, FieldCaption("Expiration Date"), TableCaption(), "Expiration Date"), true);
                    if not Confirmed then
                        Error('');
                end;
                ServContractLine.SetFilter("Contract Expiration Date", '>%1 | %2', "Expiration Date", 0D);
            end;

            if ServContractLine.Find('-') then begin
                repeat
                    ServContractLine."Contract Expiration Date" := "Expiration Date";
                    ServContractLine."Credit Memo Date" := "Expiration Date";
                    ServContractLine.Modify();
                until ServContractLine.Next() = 0;
                Modify(true);
            end;
        end;

        IsHandled := false;
        OnChangeExpirationDateOnBeforeValidateInvoicePeriod(Rec, IsHandled);
        if not IsHandled then
            Validate("Invoice Period");
    end;

    procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(Rec, SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck <> '' then
            if Salesperson.Get(SalesPersonCodeToCheck) then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    SalesPersonCodeToAssign := ''
                else
                    SalesPersonCodeToAssign := SalesPersonCodeToCheck;
    end;

    procedure ValidateSalesPersonOnServiceContractHeader(ServiceContractHeader2: Record "Service Contract Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateSalesPersonOnServiceContractHeader(ServiceContractHeader2, IsTransaction, IsPostAction, IsHandled);
        if IsHandled then
            exit;

        if ServiceContractHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(ServiceContractHeader2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true));
                    if not IsTransaction then
                        Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true));
                end;
    end;

    procedure IsInvoicePeriodInTimeSegment() InvoicePeriodInTimeSegment: Boolean
    begin
        InvoicePeriodInTimeSegment :=
            "Invoice Period" in ["Invoice Period"::Month, "Invoice Period"::"Two Months", "Invoice Period"::Quarter, "Invoice Period"::"Half Year", "Invoice Period"::Year];
        OnIsInvoicePeriodInTimeSegment(Rec, InvoicePeriodInTimeSegment);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Bill-to Customer No.", FieldNo = Rec.FieldNo("Bill-to Customer No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salesperson Code", FieldNo = Rec.FieldNo("Salesperson Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Contract Template", Rec."Template No.", FieldNo = Rec.FieldNo("Template No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Order Type", Rec."Service Order Type", FieldNo = Rec.FieldNo("Service Order Type"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    local procedure AskContractAmountDistribution(var Result: Integer) OK: Boolean
    var
        ContractAmountDistribution: Page "Contract Amount Distribution";
        IsHandled: Boolean;
    begin
        Result := 0;
        OK := false;
        IsHandled := false;
        OnBeforeAskContractAmountDistribution(Rec, OK, Result, IsHandled);
        if not IsHandled then begin
            Clear(ContractAmountDistribution);
            ContractAmountDistribution.SetValues("Annual Amount", "Calcd. Annual Amount");
            if ContractAmountDistribution.RunModal() = ACTION::Yes then begin
                Result := ContractAmountDistribution.GetResult();
                OK := true;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ServiceContractHeader: Record "Service Contract Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistEdit(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReturnNoOfPer(InvoicePeriod: Enum "Service Contract Header Invoice Period"; var RetPer: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCont(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShiptoCode(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdContractChangeLog(var ServiceContractHeader: Record "Service Contract Header"; OldServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyServiceContractQuoteTemplate(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetServiceContractNos(ServiceContractHeader: Record "Service Contract Header"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateEndPeriodDate(var ServiceContractHeader: Record "Service Contract Header"; PrepaidContract: Boolean; NextInvDate: Date; var Result: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitNoSeries(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; ServMgtSetup: Record "Service Mgt. Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNextInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean; xServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNextInvoiceDate(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepaid(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var ServiceLedgerEntry: Record "Service Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLastInvoiceDate(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNextInvoiceDateOnBeforeCheck(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNextInvoiceDateOnBeforeValidateNextInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStartingDateOnAfterServContractLineSetFilters(var ServiceContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateEndPeriodDateOnPrepaidCaseElse(var ServiceContractHeader: Record "Service Contract Header"; var EndPeriodDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateEndPeriodDateCaseElse(var ServiceContractHeader: Record "Service Contract Header"; var EndPeriodDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvPeriodDurationCaseElse(var ServiceContractHeader: Record "Service Contract Header"; var InvPeriodDuration: DateFormula)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeContBusinessRelationFindByContact(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterCopyFieldsFromCust(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer; SkipBillToContact: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckExpirationDate(var IsHandled: Boolean; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateCust(var ServiceContractHeader: Record "Service Contract Header"; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsInvoicePeriodInTimeSegment(ServiceContractHeader: Record "Service Contract Header"; var InvoicePeriodInTimeSegment: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterContractLinesExist(var ServContractLine: Record "Service Contract Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(var ServiceContractHeader: Record "Service Contract Header"; SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountPerPeriod(var ServiceContractHeader: Record "Service Contract Header"; InvFrom: Date; InvTo: Date; DaysInFullInvPeriod: Integer; DaysInThisInvPeriod: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ServiceContractHeader: Record "Service Contract Header"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCont(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeContractStatus(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCurrencyCode(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeCustomerNo(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeExpirationDate(var ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeContractLinesExist(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateZone(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean; CurrFieldNo: Integer; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmChangeContactNo(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmChangeBillToContactNo(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDocDim(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckChangeStatus(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAskContractAmountDistribution(var ServiceContractHeader: Record "Service Contract Header"; var OK: Boolean; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforePrivacyBlockedCheck(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeBlockedCheck(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSalesPersonOnServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; IsTransaction: Boolean; IsPostAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerNo(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; HideValidationDialog: Boolean; var Confirmed: Boolean; SkipBillToContact: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNo(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; var SkipBillToContact: Boolean; var SkipContact: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCode(var ServiceContractHeader: Record "Service Contract Header"; var xServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingDate(var ServiceContractHeader: Record "Service Contract Header"; var ServContractLine: Record "Service Contract Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateContOnAfterUpdateContFromCust(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeContractStatusOnBeforeConfirmCancelTheContractQst(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeContractStatusOnBeforeModifyServContractLines(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; xServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckChangeStatusOnBeforeSetBillToCustomerNo(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckChangeStatusOnBeforeCheckContractLinesExist(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeExpirationDateOnBeforeValidateInvoicePeriod(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;
}
