// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
#if not CLEAN27
using Microsoft.Sales.Setup;
#endif
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Posting;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System.Email;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Threading;
using System.Utilities;

table 5900 "Service Header"
{
    Caption = 'Service Header';
    DataCaptionFields = "No.", Name, Description;
    DrillDownPageID = "Service List";
    LookupPageID = "Service List";
    Permissions = TableData "Loaner Entry" = d,
                  TableData "Service Order Allocation" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCustomerNo(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    if ("Customer No." <> xRec."Customer No.") and (xRec."Customer No." <> '') then begin
                        if "Contract No." <> '' then
                            Error(
                              Text003,
                              FieldCaption("Customer No."),
                              "Document Type", FieldCaption("No."), "No.",
                              FieldCaption("Contract No."), "Contract No.");
                        if HideValidationDialog or not GuiAllowed then
                            Confirmed := true
                        else
                            if ServItemLineExists() then
                                Confirmed :=
                                  ConfirmManagement.GetResponseOrDefault(
                                    StrSubstNo(Text004, FieldCaption("Customer No.")), true)
                            else
                                if ServLineExists() then
                                    Confirmed :=
                                      ConfirmManagement.GetResponseOrDefault(
                                        StrSubstNo(Text057, FieldCaption("Customer No.")), true)
                                else
                                    Confirmed :=
                                      ConfirmManagement.GetResponseOrDefault(
                                        StrSubstNo(Text005, FieldCaption("Customer No.")), true);
                        if Confirmed then begin
                            ServLine.SetRange("Document Type", "Document Type");
                            ServLine.SetRange("Document No.", "No.");
                            if "Document Type" = "Document Type"::Order then
                                ServLine.SetFilter("Quantity Shipped", '<>0')
                            else
                                if "Document Type" = "Document Type"::Invoice then begin
                                    ServLine.SetRange("Customer No.", xRec."Customer No.");
                                    ServLine.SetFilter("Shipment No.", '<>%1', '');
                                end;

                            if ServLine.FindFirst() then
                                if "Document Type" = "Document Type"::Order then
                                    ServLine.TestField("Quantity Shipped", 0)
                                else
                                    ServLine.TestField("Shipment No.", '');
                            OnValidateCustomerNoOnBeforeModify(Rec, CurrFieldNo);
                            Modify(true);

                            IsHandled := false;
                            OnValidateCustomerNoOnBeforeDeleteLines(Rec, IsHandled);
                            if not IsHandled then begin
                                ServLine.LockTable();
                                ServLine.Reset();
                                ServLine.SetRange("Document Type", "Document Type");
                                ServLine.SetRange("Document No.", "No.");
                                ServLine.DeleteAll(true);

                                ServItemLine.LockTable();
                                ServItemLine.Reset();
                                ServItemLine.SetRange("Document Type", "Document Type");
                                ServItemLine.SetRange("Document No.", "No.");
                                ServItemLine.DeleteAll(true);
                            end;

                            Get("Document Type", "No.");
                            if "Customer No." = '' then begin
                                Init();
                                OnValidateCustomerNoAfterInit(Rec, xRec);
                                GetServiceMgtSetup();
                                "No. Series" := xRec."No. Series";
                                InitRecord();
                                if xRec."Shipping No." <> '' then begin
                                    "Shipping No. Series" := xRec."Shipping No. Series";
                                    "Shipping No." := xRec."Shipping No.";
                                end;
                                if xRec."Posting No." <> '' then begin
                                    "Posting No. Series" := xRec."Posting No. Series";
                                    "Posting No." := xRec."Posting No.";
                                end;
                                exit;
                            end;
                        end else begin
                            Rec := xRec;
                            exit;
                        end;
                    end;

                if "No." = '' then
                    InitRecord();

                GetCust("Customer No.");
                if "Customer No." <> '' then begin
                    IsHandled := false;
                    OnBeforeCheckBlockedCustomer(Cust, IsHandled);
                    if not IsHandled then
                        Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);
                    if CheckBusPostingGroups() then
                        Cust.TestField("Gen. Bus. Posting Group");
                    CopyCustomerFields(Cust);
                end;

                IsHandled := false;
                OnValidateCustomerNoOnBeforeShippedServLinesExist(Rec, xRec, IsHandled);
                if not IsHandled then
                    if "Customer No." = xRec."Customer No." then
                        if ShippedServLinesExist() then
                            if CheckBusPostingGroups() then begin
                                TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                                TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                            end;

                IsHandled := false;
                OnValidateCustomerNoOnBeforeVerifyShipToCode(Rec, SkipBillToContact, IsHandled);
                if not IsHandled then begin
                    Validate("Ship-to Code", Cust."Ship-to Code");
                    IsHandled := false;
                    OnValidateCustomerNoOnBeforeValidateBillToCustomerNo(Rec, Cust, IsHandled);
                    if not IsHandled then
                        if Cust."Bill-to Customer No." <> '' then
                            Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
                        else begin
                            if "Bill-to Customer No." = "Customer No." then
                                SkipBillToContact := true;
                            Validate("Bill-to Customer No.", "Customer No.");
                            SkipBillToContact := false;
                        end;
                end;

                IsHandled := false;
                OnValidateCustomerNoOnBeforeValidateServiceZoneCode(Rec, IsHandled);
                if not IsHandled then
                    Validate("Service Zone Code");

                if not SkipContact then
                    UpdateCont("Customer No.");
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    GetServiceMgtSetup();
                    TestNoSeriesManual();
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
                ConfirmManagement: Codeunit "Confirm Management";
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeConfirmChange(Rec, xRec, IsHandled);
                if not IsHandled then
                    if (xRec."Bill-to Customer No." <> "Bill-to Customer No.") and
                       (xRec."Bill-to Customer No." <> '')
                    then begin
                        if HideValidationDialog then
                            Confirmed := true
                        else
                            Confirmed :=
                              ConfirmManagement.GetResponseOrDefault(
                                StrSubstNo(Text005, FieldCaption("Bill-to Customer No.")), true);
                        if Confirmed then begin
                            ServLine.SetRange("Document Type", "Document Type");
                            ServLine.SetRange("Document No.", "No.");
                            if "Document Type" = "Document Type"::Order then
                                ServLine.SetFilter("Quantity Shipped", '<>0')
                            else
                                if "Document Type" = "Document Type"::Invoice then
                                    ServLine.SetFilter("Shipment No.", '<>%1', '');

                            OnValidateBillToCustomerNoOnAfterSetFilters(ServLine, Rec, xRec);

                            if ServLine.FindFirst() then
                                if "Document Type" = "Document Type"::Order then
                                    ServLine.TestField("Quantity Shipped", 0)
                                else
                                    ServLine.TestField("Shipment No.", '');
                            ServLine.Reset();
                        end else
                            "Bill-to Customer No." := xRec."Bill-to Customer No.";
                    end;

                GetCust("Bill-to Customer No.");

                IsHandled := false;
                OnBeforeCheckBlockedCustomer(Cust, IsHandled);
                if not IsHandled then
                    Cust.CheckBlockedCustOnDocs(Cust, "Document Type", false, false);

                Cust.TestField("Customer Posting Group");

                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeCopyBillToCustomerFields(Rec, IsHandled);
                if not IsHandled then
                    if GuiAllowed and not HideValidationDialog and
                       ("Document Type" in ["Document Type"::Quote, "Document Type"::Order, "Document Type"::Invoice])
                    then
                        ServCheckCreditLimit.ServiceHeaderCheck(Rec);

                CopyBillToCustomerFields(Cust);

                ValidateServPriceGrOnServItem();

                if "Bill-to Customer No." = xRec."Bill-to Customer No." then
                    if ShippedServLinesExist() then begin
                        TestField("Customer Disc. Group", xRec."Customer Disc. Group");
                        TestField("Currency Code", xRec."Currency Code");
                    end;

                CreateDimFromDefaultDim(Rec.FieldNo("Bill-to Customer No."));

                Validate("Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");

                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeRecreateServLines(Rec, xRec, IsHandled);
                if not IsHandled then
                    if (xRec."Customer No." = "Customer No.") and
                       (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                    then
                        RecreateServLines(FieldCaption("Bill-to Customer No."));

                if not SkipBillToContact then
                    UpdateBillToCont("Bill-to Customer No.");

                if Rec."Customer No." <> Rec."Bill-to Customer No." then
                    UpdateShipToSalespersonCode();

                OnAfterValidateBillToCustomerNo(Rec, xRec, Cust);
            end;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
                ShouldUpdateShipToAddressFields: Boolean;
            begin
                IsHandled := false;
                OnValidateShiptoCodeBeforeConfirmDialog(Rec, xRec, IsHandled);
                if not IsHandled then
                    if ("Ship-to Code" <> xRec."Ship-to Code") and ("Customer No." = xRec."Customer No.") then begin
                        if ("Contract No." <> '') and not HideValidationDialog then
                            Error(
                                Text003,
                                FieldCaption("Ship-to Code"), "Document Type", FieldCaption("No."), "No.", FieldCaption("Contract No."), "Contract No.");
                        if ServItemLineExists() then begin
                            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text004, FieldCaption("Ship-to Code")), true) then begin
                                "Ship-to Code" := xRec."Ship-to Code";
                                exit;
                            end;
                        end else
                            if ServLineExists() then begin
                                IsHandled := false;
                                OnValidateShipToCodeOnBeforeConfirmDeleteLines(Rec, IsHandled);
                                if not IsHandled then
                                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text057, FieldCaption("Ship-to Code")), true) then begin
                                        "Ship-to Code" := xRec."Ship-to Code";
                                        exit;
                                    end;
                            end;
                    end;

                ShouldUpdateShipToAddressFields := "Document Type" <> "Document Type"::"Credit Memo";
                OnValidateShipToCodeOnAfterCalcShouldUpdateShipToAddressFields(Rec, ShouldUpdateShipToAddressFields);
                if ShouldUpdateShipToAddressFields then
                    if "Ship-to Code" <> '' then begin
                        if xRec."Ship-to Code" <> '' then begin
                            GetCust("Customer No.");
                            if Cust."Location Code" <> '' then
                                "Location Code" := Cust."Location Code";
                            "Tax Area Code" := Cust."Tax Area Code";
                        end;
                        ShipToAddr.Get("Customer No.", "Ship-to Code");
                        SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr);
                    end else
                        if "Customer No." <> '' then begin
                            GetCust("Customer No.");
                            CopyShipToCustomerAddressFieldsFromCust(Cust);
                        end;

                UpdateShipToSalespersonCode();
                GetShipmentMethodCode();
                GetShippingTime(FieldNo("Ship-to Code"));

                if (xRec."Customer No." = "Customer No.") and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then
                    if (xRec."VAT Country/Region Code" <> "VAT Country/Region Code") or
                       (xRec."Tax Area Code" <> "Tax Area Code")
                    then
                        RecreateServLines(FieldCaption("Ship-to Code"))
                    else
                        if xRec."Tax Liable" <> "Tax Liable" then
                            Validate("Tax Liable");

                IsHandled := false;
                OnValidateShipToCodeOnBeforeValidateServiceZoneCode(Rec, IsHandled);
                if not IsHandled then
                    Validate("Service Zone Code");

                IsHandled := false;
                OnValidateShipToCodeOnBeforeDeleteLines(Rec, IsHandled);
                if not IsHandled then
                    if ("Ship-to Code" <> xRec."Ship-to Code") and
                       ("Customer No." = xRec."Customer No.") and
                       ServItemLineExists()
                    then begin
                        Modify(true);
                        ServLine.LockTable();
                        ServItemLine.LockTable();
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        ServLine.DeleteAll(true);
                        ServItemLine.Reset();
                        ServItemLine.SetRange("Document Type", "Document Type");
                        ServItemLine.SetRange("Document No.", "No.");
                        ServItemLine.DeleteAll(true);
                    end;
            end;
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(14; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(18; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(19; "Order Date"; Date)
        {
            Caption = 'Order Date';
            NotBlank = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateOrderDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Order Date" <> xRec."Order Date" then begin
                    if ("Order Date" > "Starting Date") and
                       ("Starting Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Order Date"), FieldCaption("Starting Date"));

                    if ("Order Date" > "Finishing Date") and
                       ("Finishing Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Order Date"), FieldCaption("Finishing Date"));

                    if "Starting Time" <> 0T then
                        Validate("Starting Time");
                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Starting Date" < "Order Date" then
                                Error(
                                  Text027, FieldCaption("Order Date"),
                                  ServItemLine.FieldCaption("Starting Date"));
                        until ServItemLine.Next() = 0;

                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        repeat
                            ServItemLine.CheckWarranty("Order Date");
                            ServItemLine.CalculateResponseDateTime("Order Date", "Order Time");
                            ServItemLine.Modify();
                        until ServItemLine.Next() = 0;
                    UpdateServLinesByFieldNo(FieldNo("Order Date"), false);
                end;
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if ("Posting No." <> '') and ("Posting No. Series" <> '') then begin
                    GlobalNoSeries.Get("Posting No. Series");
                    if GlobalNoSeries."Date Order" then
                        Error(
                          Text045,
                          FieldCaption("Posting Date"), FieldCaption("Posting No. Series"), "Posting No. Series",
                          GlobalNoSeries.FieldCaption("Date Order"), GlobalNoSeries."Date Order", "Document Type",
                          FieldCaption("Posting No."), "Posting No.");
                end;

                TestField("Posting Date");
                OnValidatePostingDateOnAfterCheckPostingDate(Rec);

                GeneralLedgerSetup.GetRecordOnce();
                GeneralLedgerSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");
                IsHandled := false;
                OnValidatePostingDateOnAfterValidateVATReportingDate(Rec, xRec, IsHandled);
                if not IsHandled then
                    Validate("Document Date", "Posting Date");

                ServLine.SetRange("Document Type", "Document Type");
                ServLine.SetRange("Document No.", "No.");
                if ServLine.FindSet() then
                    repeat
                        if "Posting Date" <> ServLine."Posting Date" then begin
                            ServLine."Posting Date" := "Posting Date";
                            ServLine.Modify();
                        end;
                    until ServLine.Next() = 0;

                OnValidatePostingDateOnAfterUpdatePostingDateOnLines(Rec, HideValidationDialog);

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then
                    if ServLineExists() then
                        ServLine.ModifyAll("Posting Date", "Posting Date");

                if "Currency Code" <> '' then begin
                    UpdateCurrencyFactor();
                    if "Currency Factor" <> xRec."Currency Factor" then
                        ConfirmCurrencyFactorUpdate();
                end;
            end;
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                ValidatePaymentTerms(Rec);
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                GeneralLedgerSetup.GetRecordOnce();
                if "Payment Discount %" < GeneralLedgerSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GeneralLedgerSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(26; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                if ("Location Code" <> xRec."Location Code") and
                   ("Customer No." = xRec."Customer No.")
                then
                    MessageIfServLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress();
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                CheckHeaderDimension();
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                CheckHeaderDimension();
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";

            trigger OnValidate()
            begin
                CheckCustomerPostingGroupChange();
            end;
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if CurrFieldNo <> FieldNo("Currency Code") then
                    UpdateCurrencyFactor()
                else
                    if "Currency Code" <> xRec."Currency Code" then begin
                        if ServLineExists() and ("Contract No." <> '') and
                           ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"])
                        then
                            Error(Text058, FieldCaption("Currency Code"), "Document Type", "No.", "Contract No.");

                        UpdateCurrencyFactor();
                        ValidateServPriceGrOnServItem();
                    end else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor();
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmCurrencyFactorUpdate();
                        end;
                SetCompanyBankAccount();
            end;
        }
        field(33; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdateServLinesByFieldNo(FieldNo("Currency Factor"), false);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                PriceMsgIfServLinesExist(FieldCaption("Customer Price Group"));
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                ServLine: Record "Service Line";
                Currency: Record Currency;
                RecalculatePrice: Boolean;
            begin
                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    TestField("Max. Labor Unit Price", 0);
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '>0');
                    ServLine.SetFilter(Quantity, '<>0');
                    if ServLine.Find('-') then
                        repeat
                            ServLine.Amount := 0;
                            ServLine."Amount Including VAT" := 0;
                            ServLine."VAT Base Amount" := 0;
                            ServLine.InitOutstandingAmount();
                            ServLine.Modify();
                        until ServLine.Next() = 0;
                    ServLine.SetRange(Type);
                    ServLine.SetRange(Quantity);

                    ServLine.SetFilter("Unit Price", '<>%1', 0);
                    ServLine.SetFilter("VAT %", '<>%1', 0);
                    if ServLine.Find('-') then begin
                        RecalculatePrice := ConfirmRecalculatePrice();
                        OnValidatePricesIncludingVATOnAfterCalcRecalculatePrice(Rec, ServLine, RecalculatePrice);
                        ServLine.SetServHeader(Rec);

                        if "Currency Code" = '' then
                            Currency.InitRoundingPrecision()
                        else
                            Currency.Get("Currency Code");

                        repeat
                            ServLine.TestField("Quantity Invoiced", 0);
                            if not RecalculatePrice then begin
                                ServLine."VAT Difference" := 0;
                                ServLine.InitOutstandingAmount();
                            end else
                                if "Prices Including VAT" then begin
                                    ServLine."Unit Price" :=
                                      Round(
                                        ServLine."Unit Price" * (1 + (ServLine."VAT %" / 100)),
                                        Currency."Unit-Amount Rounding Precision");
                                    if ServLine.Quantity <> 0 then begin
                                        ServLine."Line Discount Amount" :=
                                          Round(
                                            ServLine.CalcChargeableQty() * ServLine."Unit Price" * ServLine."Line Discount %" / 100,
                                            Currency."Amount Rounding Precision");
                                        ServLine.Validate("Inv. Discount Amount",
                                          Round(
                                            ServLine."Inv. Discount Amount" * (1 + (ServLine."VAT %" / 100)),
                                            Currency."Amount Rounding Precision"));
                                    end;
                                end else begin
                                    ServLine."Unit Price" :=
                                      Round(
                                        ServLine."Unit Price" / (1 + (ServLine."VAT %" / 100)),
                                        Currency."Unit-Amount Rounding Precision");
                                    if ServLine.Quantity <> 0 then begin
                                        ServLine."Line Discount Amount" :=
                                          Round(
                                            ServLine.CalcChargeableQty() * ServLine."Unit Price" * ServLine."Line Discount %" / 100,
                                            Currency."Amount Rounding Precision");
                                        ServLine.Validate("Inv. Discount Amount",
                                          Round(
                                            ServLine."Inv. Discount Amount" / (1 + (ServLine."VAT %" / 100)),
                                            Currency."Amount Rounding Precision"));
                                    end;
                                end;
                            ServLine.Modify();
                        until ServLine.Next() = 0;
                    end;
                end;
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';

            trigger OnValidate()
            begin
                Rec.TestField("Release Status", "Release Status"::Open);
                MessageIfServLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Customer Disc. Group"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Language Code"));
            end;
        }
        field(42; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateSalesPersonOnServiceHeader(Rec, false, false);

                CreateDimFromDefaultDim(Rec.FieldNo("Salesperson Code"));
            end;
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Service Comment Line" where("Table Name" = const("Service Header"),
                                                              "Table Subtype" = field("Document Type"),
                                                              "No." = field("No."),
                                                              Type = const(General)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                GenJnlLine: Record "Gen. Journal Line";
                GenJnlApply: Codeunit "Gen. Jnl.-Apply";
                ServApplyCustEntries: Page "Serv. Apply Customer Entries";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, CustLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                TestField("Bal. Account No.", '');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.", "Applies-to Doc. Type".AsInteger(), "Applies-to Doc. No.", 0);
                OnValidateAppliestoDocNoOnAfterSetFilters(CustLedgEntry, Rec);

                ServApplyCustEntries.SetService(Rec, CustLedgEntry, ServHeader.FieldNo("Applies-to Doc. No."));
                ServApplyCustEntries.SetTableView(CustLedgEntry);
                ServApplyCustEntries.SetRecord(CustLedgEntry);
                ServApplyCustEntries.LookupMode(true);
                if ServApplyCustEntries.RunModal() = ACTION::LookupOK then begin
                    ServApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                    CopyAppliestoFieldsFromCustLedgerEntry(CustLedgEntry);
                end;
                Clear(ServApplyCustEntries);

                OnAfterLookupAppliesToDocNo(Rec, CustLedgEntry);
            end;

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAppliesToDocNo(Rec, CustLedgEntry, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to Doc. No." <> '' then
                    TestField("Bal. Account No.", '');

                if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." <> '') and
                   ("Applies-to Doc. No." <> '')
                then begin
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Customer No.");
                    CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Customer No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Customer No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Customer No.");

                OnAfterValidateAppliesToDocNo(Rec, xRec, CustLedgEntry);
            end;
        }
        field(55; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";

            trigger OnValidate()
            var
                GLAcc: Record "G/L Account";
                BankAcc: Record "Bank Account";
            begin
                if "Bal. Account No." <> '' then
                    case "Bal. Account Type" of
                        "Bal. Account Type"::"G/L Account":
                            begin
                                GLAcc.Get("Bal. Account No.");
                                GLAcc.CheckGLAcc();
                                GLAcc.TestField("Direct Posting", true);
                            end;
                        "Bal. Account Type"::"Bank Account":
                            begin
                                BankAcc.Get("Bal. Account No.");
                                BankAcc.TestField(Blocked, false);
                                BankAcc.TestField("Currency Code", "Currency Code");
                            end;
                    end;
            end;
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Service Line".Amount where("Document Type" = field("Document Type"), "Document No." = field("No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the sum of amounts on all the lines in the document.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Service Line"."Amount Including VAT" where("Document Type" = field("Document Type"), "Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the sum of amounts, including VAT, on all the lines in the document.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Shipping No."; Code[20])
        {
            Caption = 'Shipping No.';
        }
        field(63; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
        }
        field(64; "Last Shipping No."; Code[20])
        {
            Caption = 'Last Shipping No.';
            Editable = false;
            TableRelation = "Service Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Service Invoice Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(74; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            var
                GenBusPostingGroup: Record "Gen. Business Posting Group";
            begin
                if "Gen. Bus. Posting Group" <> xRec."Gen. Bus. Posting Group" then begin
                    if GenBusPostingGroup.ValidateVatBusPostingGroup(GenBusPostingGroup, "Gen. Bus. Posting Group") then
                        "VAT Bus. Posting Group" := GenBusPostingGroup."Def. VAT Bus. Posting Group";
                    RecreateServLines(FieldCaption("Gen. Bus. Posting Group"));
                end;
            end;
        }
        field(75; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
        }
        field(76; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            TableRelation = "Transaction Type";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Transaction Type"), false);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Transport Method"), false);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(79; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(80; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer to whom the items on the document will be shipped.';
        }
        field(81; Address; Text[100])
        {
            Caption = 'Address';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Address"));
            end;
        }
        field(82; "Address 2"; Text[50])
        {
            Caption = 'Address 2';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Address 2"));
            end;
        }
        field(83; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to City"));
            end;
        }
        field(84; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBillToPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                FormatAddress: Codeunit "Format Address";
            begin
                if not FormatAddress.UseCounty(Rec."Bill-to Country/Region Code") then
                    "Bill-to County" := '';
            end;
        }
        field(88; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Post Code"));
            end;
        }
        field(89; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to County"));
            end;
        }
        field(90; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                FormatAddress: Codeunit "Format Address";
            begin
                if not FormatAddress.UseCounty("Country/Region Code") then
                    County := '';
                UpdateShipToAddressFromGeneralAddress(FieldNo("Ship-to Country/Region Code"));

                Validate("Ship-to Country/Region Code");
            end;
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToPostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Bal. Account Type"; Enum "Payment Balance Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(97; "Exit Point"; Code[10])
        {
            Caption = 'Exit Point';
            TableRelation = "Entry/Exit Point";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Exit Point"), false);
            end;
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';

            trigger OnValidate()
            begin
                GeneralLedgerSetup.GetRecordOnce();
                GeneralLedgerSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
                Validate("VAT Reporting Date");
                OnValidateDocumentDateOnAfterValidateVATReportingDate(Rec, xRec);
                Validate("Payment Terms Code");
            end;
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';

            trigger OnValidate()
            var
                WhseServiceRelease: Codeunit "Whse.-Service Release";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateExternalDocumentNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if (xRec."External Document No." <> Rec."External Document No.")
                    and (Rec."Release Status" = Rec."Release Status"::"Released to Ship")
                    and ("Document Type" = "Document Type"::Order)
                then
                    WhseServiceRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo(Area), false);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateServLinesByFieldNo(FieldNo("Transaction Specification"), false);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                PaymentMethod: Record "Payment Method";
                SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
            begin
                PaymentMethod.Init();
                if "Payment Method Code" <> '' then
                    PaymentMethod.Get("Payment Method Code");
                if PaymentMethod."Direct Debit" then begin
                    "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Due Date");
                    if "Payment Terms Code" = '' then
                        "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
                end else
                    "Direct Debit Mandate ID" := '';
                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                end;
            end;
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FieldNo("Shipping Agent Code"));
                UpdateServLinesByFieldNo(FieldNo("Shipping Agent Code"), CurrFieldNo <> 0);
            end;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(108; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            begin
                ServHeader := Rec;
                ServHeader.GetServiceMgtSetup();
                ServHeader.TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetPostingNoSeriesCode(), ServHeader."Posting No. Series") then
                    ServHeader.Validate(ServHeader."Posting No. Series");
                Rec := ServHeader;
            end;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    GetServiceMgtSetup();
                    TestNoSeries();
                    NoSeries.TestAreRelated(GetPostingNoSeriesCode(), "Posting No. Series");
                end;
                TestField("Posting No.", '');
            end;
        }
        field(109; "Shipping No. Series"; Code[20])
        {
            Caption = 'Shipping No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "Shipping No. Series" <> '' then begin
                    GetServiceMgtSetup();
                    ServiceMgtSetup.TestField("Posted Service Shipment Nos.");
                    NoSeries.TestAreRelated(ServiceMgtSetup."Posted Service Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Tax Liable"));
                UpdateServLinesByFieldNo(FieldNo("Tax Liable"), false);
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "VAT Bus. Posting Group" <> xRec."VAT Bus. Posting Group" then
                    RecreateServLines(FieldCaption("VAT Bus. Posting Group"));
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            Caption = 'Reserve';
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
                CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
            begin
                if "Applies-to ID" <> '' then
                    TestField("Bal. Account No.", '');
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", Open);
                    CustLedgEntry.SetRange("Customer No.", "Bill-to Customer No.");
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("Applies-to ID", xRec."Applies-to ID");
                    if CustLedgEntry.FindFirst() then
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    CustLedgEntry.Reset();
                end;
            end;
        }
        field(119; "VAT Base Discount %"; Decimal)
        {
            Caption = 'VAT Base Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GeneralLedgerSetup.GetRecordOnce();
                if "VAT Base Discount %" > GeneralLedgerSetup."VAT Tolerance %" then
                    Error(
                      Text011,
                      FieldCaption("VAT Base Discount %"),
                      GeneralLedgerSetup.FieldCaption("VAT Tolerance %"),
                      GeneralLedgerSetup.TableCaption());

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and
                   (CurrFieldNo <> 0)
                then
                    exit;

                IsHandled := false;
                OnValidateVATBaseDiscountPctOnBeforeUpdateLineAmounts(Rec, IsHandled);
                if not IsHandled then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '<>%1', ServLine.Type::" ");
                    ServLine.SetFilter(Quantity, '<>0');
                    ServLine.LockTable();
                    LockTable();
                    if ServLine.FindSet() then begin
                        Modify();
                        repeat
                            if (ServLine."Quantity Invoiced" <> ServLine.Quantity) or
                            ("Shipping Advice" = "Shipping Advice"::Complete) or
                            (CurrFieldNo <> 0)
                            then begin
                                ServLine.UpdateAmounts();
                                ServLine.Modify();
                            end;
                        until ServLine.Next() = 0;
                    end;
                end;
            end;
        }
        field(120; Status; Enum "Service Document Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
                RepairStatus: Record "Repair Status";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStatus(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                LinesExist := true;
                OnValidateServiceDocumentStatusOnAfterServItemLineSetFilters(Rec, ServItemLine);
                if ServItemLine.Find('-') then
                    repeat
                        if ServItemLine."Repair Status Code" <> '' then begin
                            RepairStatus.Get(ServItemLine."Repair Status Code");
                            if ((Status = Status::Pending) and not RepairStatus."Pending Status Allowed") or
                               ((Status = Status::"In Process") and not RepairStatus."In Process Status Allowed") or
                               ((Status = Status::Finished) and not RepairStatus."Finished Status Allowed") or
                               ((Status = Status::"On Hold") and not RepairStatus."On Hold Status Allowed")
                            then
                                Error(
                                  Text031,
                                  FieldCaption(Status), Format(Status), TableCaption(), "No.", ServItemLine.FieldCaption("Repair Status Code"),
                                  ServItemLine."Repair Status Code", ServItemLine.TableCaption(), ServItemLine."Line No.")
                        end;
                    until ServItemLine.Next() = 0
                else
                    LinesExist := false;

                case Status of
                    Status::"In Process":
                        if not LinesExist then begin
                            "Starting Date" := WorkDate();
                            Validate("Starting Time", Time);
                        end else
                            UpdateStartingDateTime();
                    Status::Finished:
                        begin
                            TestMandatoryFields(ServLine);
                            if Status <> xRec.Status then
                                if "Notify Customer" = "Notify Customer"::"By Email" then begin
                                    TestField("Customer No.");
                                    Clear(NotifyCust);
                                    NotifyCust.Run(Rec);
                                end;
                            if not LinesExist then begin
                                if ("Finishing Date" = 0D) and ("Finishing Time" = 0T) then begin
                                    "Finishing Date" := WorkDate();
                                    "Finishing Time" := Time;
                                end;
                            end else
                                UpdateFinishingDateTime();

                            OnValidateStatusFinishedOnAferUpdateFinishingDateTime(Rec, xRec);
                        end;
                end;

                if Status <> Status::Finished then begin
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;

                if ("Starting Date" <> 0D) and
                   ("Finishing Date" <> 0D) and
                   not LinesExist
                then begin
                    CalcFields("Contract Serv. Hours Exist");
                    "Service Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Starting Date", "Starting Time", "Finishing Date", "Finishing Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end;

                if Status = Status::Pending then begin
                    GetServiceMgtSetup();
                    if ServiceMgtSetup."First Warning Within (Hours)" <> 0 then
                        if JobQueueEntry.WritePermission then begin
                            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                            JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ServOrder-Check Response Time");
                            JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold");
                            if JobQueueEntry.FindFirst() then
                                JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
                        end;
                end;
            end;
        }
        field(121; "Invoice Discount Calculation"; Option)
        {
            Caption = 'Invoice Discount Calculation';
            Editable = false;
            OptionCaption = 'None,%,Amount';
            OptionMembers = "None","%",Amount;
        }
        field(122; "Invoice Discount Value"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Invoice Discount Value';
            Editable = false;
        }
        field(129; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
        }
        field(130; "Release Status"; Enum "Service Doc. Release Status")
        {
            Caption = 'Release Status';
            Editable = false;
        }
        field(131; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;

            trigger OnValidate()
            begin
                if "VAT Reporting Date" = 0D then
                    InitVATDate();
            end;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
                ServDocExchangeMgt: Codeunit "Serv. Doc. Exchange Mgt.";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    ServDocExchangeMgt.SetServiceDoc(Rec, IncomingDocument);
            end;
        }
        field(178; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));

            trigger OnValidate()
            begin
                GetServiceMgtSetup();
                TestNoSeries();
                Validate("Posting No. Series", GenJournalTemplate."Posting No. Series");
            end;
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
            DataClassification = CustomerContent;
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
        field(5043; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Service Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                          "No." = field("No."),
                                                                          "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
            Editable = false;
        }
        field(5052; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                OnBeforeLookupContactNo(Rec);

                Cont.FilterGroup(2);
                if "Customer No." <> '' then
                    if Cont.Get("Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Contact No." <> '' then
                    if Cont.Get("Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Contact No.", Cont."No.");
                end;
                Cont.FilterGroup(0);
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
                Confirmed: Boolean;
            begin
                if ("Contact No." <> xRec."Contact No.") and
                   (xRec."Contact No." <> '')
                then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(Text005, FieldCaption("Contact No.")), true);
                    if Confirmed then begin
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if ("Contact No." = '') and ("Customer No." = '') then begin
                            if not ServLine.IsEmpty() then
                                Error(Text050, FieldCaption("Contact No."));
                            InitRecordFromContact();
                            exit;
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Customer No." <> '') and ("Contact No." <> '') then begin
                    Cont.Get("Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Customer No.") and
                       (ContBusinessRelation."Contact No." <> Cont."Company No.")
                    then
                        Error(Text038, Cont."No.", Cont.Name, "Customer No.");
                end;

                UpdateCust("Contact No.");
            end;
        }
        field(5053; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
            begin
                Cont.FilterGroup(2);
                if "Bill-to Customer No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.SetRange("Company No.", Cont."Company No.")
                    else
                        if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") then
                            Cont.SetRange("Company No.", ContBusinessRelation."Contact No.")
                        else
                            Cont.SetRange("No.", '');

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then;
                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                    xRec := Rec;
                    Validate("Bill-to Contact No.", Cont."No.");
                end;
                Cont.FilterGroup(0);
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                ContBusinessRelation: Record "Contact Business Relation";
                ConfirmManagement: Codeunit "Confirm Management";
                Confirmed: Boolean;
            begin
                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then begin
                    if HideValidationDialog then
                        Confirmed := true
                    else
                        Confirmed :=
                          ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(Text005, FieldCaption("Bill-to Contact No.")), true);
                    if Confirmed then begin
                        ServLine.Reset();
                        ServLine.SetRange("Document Type", "Document Type");
                        ServLine.SetRange("Document No.", "No.");
                        if ("Bill-to Contact No." = '') and ("Bill-to Customer No." = '') then begin
                            if not ServLine.IsEmpty() then
                                Error(Text050, FieldCaption("Bill-to Contact No."));
                            InitRecordFromContact();
                            exit;
                        end;
                    end else begin
                        "Bill-to Contact No." := xRec."Bill-to Contact No.";
                        exit;
                    end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then begin
                    Cont.Get("Bill-to Contact No.");
                    if ContBusinessRelation.FindByRelation(ContBusinessRelation."Link to Table"::Customer, "Bill-to Customer No.") and
                       (ContBusinessRelation."Contact No." <> Cont."Company No.")
                    then
                        Error(Text038, Cont."No.", Cont.Name, "Bill-to Customer No.");
                end;

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            var
                RespCenter: Record "Responsibility Center";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateResponsibilityCenter(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center") then
                    Error(
                      Text010,
                      RespCenter.TableCaption(), UserSetupMgt.GetServiceFilter());

                UpdateShipToAddress();

                CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));

                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                if ServItemLine.Find('-') then
                    repeat
                        ServItemLine.Validate("Responsibility Center", "Responsibility Center");
                        ServItemLine.Modify(true);
                    until ServItemLine.Next() = 0;

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreateServLines(FieldCaption("Responsibility Center"));
                    Validate("Location Code", UserSetupMgt.GetLocation(2, '', "Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';

            trigger OnValidate()
            var
                ServiceWarehouseMgt: Codeunit "Service Warehouse Mgt.";
            begin
                TestField("Release Status", "Release Status"::Open);
                if WhsePickConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text064, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                if WhseShipmentConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text065, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                ServiceWarehouseMgt.ServiceHeaderVerifyChange(Rec, xRec);
            end;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("Service Line"."Completely Shipped" where("Document Type" = field("Document Type"),
                                                                         "Document No." = field("No."),
                                                                         Type = filter(<> " "),
                                                                         "Location Code" = field("Location Filter")));
            Caption = 'Completely Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location.Code;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                if "Shipping Time" <> xRec."Shipping Time" then
                    UpdateServLinesByFieldNo(FieldNo("Shipping Time"), CurrFieldNo <> 0);
            end;
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            begin
                TestField("Release Status", "Release Status"::Open);
                GetShippingTime(FieldNo("Shipping Agent Service Code"));
                UpdateServLinesByFieldNo(FieldNo("Shipping Agent Service Code"), CurrFieldNo <> 0);
            end;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5902; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5904; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateServiceOrderTypeOnBeforeCreateDim(Rec, xRec, IsHandled);
                if not IsHandled then
                    CreateDimFromDefaultDim(Rec.FieldNo("Service Order Type"));
            end;
        }
        field(5905; "Link Service to Service Item"; Boolean)
        {
            Caption = 'Link Service to Service Item';

            trigger OnValidate()
            begin
                if "Link Service to Service Item" <> xRec."Link Service to Service Item" then begin
                    ServLine.Reset();
                    ServLine.SetRange("Document Type", "Document Type");
                    ServLine.SetRange("Document No.", "No.");
                    ServLine.SetFilter(Type, '<>%1', ServLine.Type::Cost);
                    if ServLine.Find('-') then
                        Message(
                          Text001,
                          FieldCaption("Link Service to Service Item"),
                          "No.");
                end;
            end;
        }
        field(5907; Priority; Enum "Service Priority")
        {
            Caption = 'Priority';
            Editable = false;
        }
        field(5911; "Allocated Hours"; Decimal)
        {
            CalcFormula = sum("Service Order Allocation"."Allocated Hours" where("Document Type" = field("Document Type"),
                                                                                  "Document No." = field("No."),
                                                                                  "Allocation Date" = field("Date Filter"),
                                                                                  "Resource No." = field("Resource Filter"),
                                                                                  Status = filter(Active | Finished),
                                                                                  "Resource Group No." = field("Resource Group Filter")));
            Caption = 'Allocated Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5915; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(Rec.FieldNo("Ship-to Phone"));
            end;
        }
        field(5916; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
                UpdateShipToAddressFromGeneralAddress(Rec.FieldNo("Ship-to E-Mail"));
            end;
        }
        field(5917; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            begin
                UpdateShipToAddressFromGeneralAddress(Rec.FieldNo("Ship-to Phone 2"));
            end;
        }
        field(5918; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(5921; "No. of Unallocated Items"; Integer)
        {
            CalcFormula = count("Service Item Line" where("Document Type" = field("Document Type"),
                                                           "Document No." = field("No."),
                                                           "No. of Active/Finished Allocs" = const(0)));
            Caption = 'No. of Unallocated Items';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5923; "Order Time"; Time)
        {
            Caption = 'Order Time';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Order Time" <> xRec."Order Time" then begin
                    if ("Order Time" > "Starting Time") and
                       ("Starting Time" <> 0T) and
                       ("Order Date" = "Starting Date")
                    then
                        Error(Text007, FieldCaption("Order Time"), FieldCaption("Starting Time"));
                    if "Starting Time" <> 0T then
                        Validate("Starting Time");
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        repeat
                            ServItemLine.CalculateResponseDateTime("Order Date", "Order Time");
                            ServItemLine.Modify();
                        until ServItemLine.Next() = 0;
                end;
            end;
        }
        field(5924; "Default Response Time (Hours)"; Decimal)
        {
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(5925; "Actual Response Time (Hours)"; Decimal)
        {
            Caption = 'Actual Response Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(5926; "Service Time (Hours)"; Decimal)
        {
            Caption = 'Service Time (Hours)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5927; "Response Date"; Date)
        {
            Caption = 'Response Date';
            Editable = false;
        }
        field(5928; "Response Time"; Time)
        {
            Caption = 'Response Time';
            Editable = false;
        }
        field(5929; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStartingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Starting Date" <> 0D then begin
                    if "Starting Date" < "Order Date" then
                        Error(Text026, FieldCaption("Starting Date"), FieldCaption("Order Date"));

                    if ("Starting Date" > "Finishing Date") and
                       ("Finishing Date" <> 0D)
                    then
                        Error(Text007, FieldCaption("Starting Date"), FieldCaption("Finishing Time"));

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Starting Date" < "Starting Date" then
                                Error(Text024, FieldCaption("Starting Date"));
                        until ServItemLine.Next() = 0;

                    if Time < "Order Time" then
                        Validate("Starting Time", "Order Time")
                    else
                        Validate("Starting Time", Time);
                end else begin
                    "Starting Time" := 0T;
                    "Actual Response Time (Hours)" := 0;
                    "Finishing Date" := 0D;
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;
            end;
        }
        field(5930; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateStartingTime(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Starting Date");

                if ("Starting Date" = "Finishing Date") and
                   ("Starting Time" > "Finishing Time")
                then
                    Error(Text007, FieldCaption("Starting Time"), FieldCaption("Finishing Time"));

                if ("Starting Date" = "Order Date") and
                   ("Starting Time" < "Order Time")
                then
                    Error(Text026, FieldCaption("Starting Time"), FieldCaption("Order Time"));

                if ("Starting Time" = 0T) and (xRec."Starting Time" <> 0T) then begin
                    "Finishing Time" := 0T;
                    "Finishing Date" := 0D;
                    "Service Time (Hours)" := 0;
                end;

                if ("Starting Time" <> 0T) and
                   ("Starting Date" <> 0D)
                then begin
                    CalcFields("Contract Serv. Hours Exist");
                    "Actual Response Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Order Date", "Order Time", "Starting Date", "Starting Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end else
                    "Actual Response Time (Hours)" := 0;
                if "Finishing Time" <> 0T then
                    Validate("Finishing Time");
            end;
        }
        field(5931; "Finishing Date"; Date)
        {
            Caption = 'Finishing Date';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFinishingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "Finishing Date" <> 0D then begin
                    if "Finishing Date" < "Starting Date" then
                        Error(Text026, FieldCaption("Finishing Date"), FieldCaption("Starting Date"));

                    if "Finishing Date" < "Order Date" then
                        Error(
                          Text026,
                          FieldCaption("Finishing Date"),
                          FieldCaption("Order Date"));

                    if "Starting Date" = 0D then begin
                        "Starting Date" := "Finishing Date";
                        "Starting Time" := Time;
                        CalcFields("Contract Serv. Hours Exist");
                        "Actual Response Time (Hours)" :=
                          ServOrderMgt.CalcServTime(
                            "Order Date", "Order Time", "Starting Date", "Starting Time",
                            "Contract No.", "Contract Serv. Hours Exist");
                    end;

                    if "Finishing Date" <> xRec."Finishing Date" then begin
                        if Time < "Starting Time" then
                            "Finishing Time" := "Starting Time"
                        else
                            "Finishing Time" := Time;
                        Validate("Finishing Time");
                    end;

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
                    if ServItemLine.Find('-') then
                        repeat
                            if ServItemLine."Finishing Date" > "Finishing Date" then
                                Error(Text025, FieldCaption("Finishing Date"));
                        until ServItemLine.Next() = 0;
                end else begin
                    "Finishing Time" := 0T;
                    "Service Time (Hours)" := 0;
                end;
            end;
        }
        field(5932; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFinishingTime(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Finishing Date");
                if "Finishing Time" <> 0T then begin
                    if ("Starting Date" = "Finishing Date") and
                       ("Finishing Time" < "Starting Time")
                    then
                        Error(
                          Text026, FieldCaption("Finishing Time"),
                          FieldCaption("Starting Time"));

                    if ("Finishing Date" = "Order Date") and
                       ("Finishing Time" < "Order Time")
                    then
                        Error(
                          Text026, FieldCaption("Finishing Time"),
                          FieldCaption("Order Time"));

                    ServItemLine.Reset();
                    ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
                    IsHandled := false;
                    OnValidateFinishingTimeOnBeforeCheckServItemLines(Rec, xRec, ServItemLine, IsHandled);
                    if not IsHandled then
                        if ServItemLine.Find('-') then
                            repeat
                                if (ServItemLine."Finishing Date" = "Finishing Date") and
                                   (ServItemLine."Finishing Time" > "Finishing Time")
                                then
                                    Error(Text025, FieldCaption("Finishing Time"));
                            until ServItemLine.Next() = 0;

                    CalcFields("Contract Serv. Hours Exist");
                    "Service Time (Hours)" :=
                      ServOrderMgt.CalcServTime(
                        "Starting Date", "Starting Time", "Finishing Date", "Finishing Time",
                        "Contract No.", "Contract Serv. Hours Exist");
                end else
                    "Service Time (Hours)" := 0;
            end;
        }
        field(5933; "Contract Serv. Hours Exist"; Boolean)
        {
            CalcFormula = exist("Service Hour" where("Service Contract No." = field("Contract No.")));
            Caption = 'Contract Serv. Hours Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5934; "Reallocation Needed"; Boolean)
        {
            CalcFormula = exist("Service Order Allocation" where(Status = const("Reallocation Needed"),
                                                                  "Resource No." = field("Resource Filter"),
                                                                  "Document Type" = field("Document Type"),
                                                                  "Document No." = field("No."),
                                                                  "Resource Group No." = field("Resource Group Filter")));
            Caption = 'Reallocation Needed';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5936; "Notify Customer"; Option)
        {
            Caption = 'Notify Customer';
            OptionCaption = 'No,By Phone 1,By Phone 2,By Fax,By Email';
            OptionMembers = No,"By Phone 1","By Phone 2","By Fax","By Email";
        }
        field(5937; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';

            trigger OnValidate()
            begin
                if ServLineExists() then
                    Message(
                      Text001,
                      FieldCaption("Max. Labor Unit Price"),
                      "No.");
            end;
        }
        field(5938; "Warning Status"; Option)
        {
            Caption = 'Warning Status';
            OptionCaption = ' ,First Warning,Second Warning,Third Warning';
            OptionMembers = " ","First Warning","Second Warning","Third Warning";
        }
        field(5939; "No. of Allocations"; Integer)
        {
            CalcFormula = count("Service Order Allocation" where("Document Type" = field("Document Type"),
                                                                  "Document No." = field("No."),
                                                                  "Resource No." = field("Resource Filter"),
                                                                  "Resource Group No." = field("Resource Group Filter"),
                                                                  "Allocation Date" = field("Date Filter"),
                                                                  Status = filter(Active | Finished)));
            Caption = 'No. of Allocations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5940; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract),
                                                                            "Customer No." = field("Customer No."),
                                                                            "Ship-to Code" = field("Ship-to Code"),
                                                                            "Bill-to Customer No." = field("Bill-to Customer No."));

            trigger OnLookup()
            var
                ServContractHeader: Record "Service Contract Header";
                ServContractList: Page "Service Contract List";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateContractNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Contract No." <> '' then
                    if ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.") then
                        ServContractList.SetRecord(ServContractHeader);

                ServContractHeader.Reset();
                ServContractHeader.FilterGroup(2);
                ServContractHeader.SetCurrentKey("Customer No.", "Ship-to Code");
                ServContractHeader.SetRange("Customer No.", "Customer No.");
                ServContractHeader.SetRange("Ship-to Code", "Ship-to Code");
                ServContractHeader.SetRange("Contract Type", ServContractHeader."Contract Type"::Contract);
                ServContractHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
                ServContractHeader.SetRange(Status, ServContractHeader.Status::Signed);
                ServContractHeader.SetFilter("Starting Date", '<=%1', "Order Date");
                ServContractHeader.SetFilter("Expiration Date", '>=%1 | =%2', "Order Date", 0D);
                ServContractHeader.FilterGroup(0);
                OnLookupContractNoOnAfterServContractHeaderSetFilters(Rec, ServContractHeader);
                Clear(ServContractList);
                ServContractList.SetTableView(ServContractHeader);
                ServContractList.LookupMode(true);
                if ServContractList.RunModal() = ACTION::LookupOK then begin
                    ServContractList.GetRecord(ServContractHeader);
                    Validate("Contract No.", ServContractHeader."Contract No.");
                end;
            end;

            trigger OnValidate()
            var
                ServContractHeader: Record "Service Contract Header";
            begin
                if "Contract No." <> xRec."Contract No." then begin
                    if "Contract No." <> '' then begin
                        TestField("Order Date");
                        ServContractHeader.Get(ServContractHeader."Contract Type"::Contract, "Contract No.");
                        if ServContractHeader.Status <> ServContractHeader.Status::Signed then
                            Error(Text041, "Contract No.");
                        if ServContractHeader."Starting Date" > "Order Date" then
                            Error(Text042, "Contract No.");
                        if (ServContractHeader."Expiration Date" <> 0D) and
                           (ServContractHeader."Expiration Date" < "Order Date")
                        then
                            Error(Text043, "Contract No.");
                    end;
                    ServItemLine.Reset();
                    ServItemLine.SetRange("Document Type", "Document Type");
                    ServItemLine.SetRange("Document No.", "No.");
                    if ServItemLine.Find('-') then
                        Error(Text028,
                          FieldCaption("Contract No."), ServItemLine.TableCaption());

                    if not ConfirmChangeContractNo() then begin
                        "Contract No." := xRec."Contract No.";
                        exit;
                    end;

                    if "Contract No." <> '' then begin
                        TestField("Customer No.");
                        TestField("Bill-to Customer No.");
                        "Default Response Time (Hours)" := ServContractHeader."Response Time (Hours)";
                        TestField("Ship-to Code", ServContractHeader."Ship-to Code");
                        "Service Order Type" := ServContractHeader."Service Order Type";
                        Validate("Currency Code", ServContractHeader."Currency Code");
                        "Max. Labor Unit Price" := ServContractHeader."Max. Labor Unit Price";
                        "Your Reference" := ServContractHeader."Your Reference";
                        "Service Zone Code" := ServContractHeader."Service Zone Code";
                    end;
                end;

                if "Contract No." <> '' then
                    CreateDimFromDefaultDim(Rec.FieldNo("Contract No."));
            end;
        }
        field(5951; "Type Filter"; Option)
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Resource,Item,Service Cost,Service Contract';
            OptionMembers = " ",Resource,Item,"Service Cost","Service Contract";
        }
        field(5952; "Customer Filter"; Code[20])
        {
            Caption = 'Customer Filter';
            FieldClass = FlowFilter;
            TableRelation = Customer."No.";
        }
        field(5953; "Resource Filter"; Code[20])
        {
            Caption = 'Resource Filter';
            FieldClass = FlowFilter;
            TableRelation = Resource;
        }
        field(5954; "Contract Filter"; Code[20])
        {
            Caption = 'Contract Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(5955; "Ship-to Fax No."; Text[30])
        {
            Caption = 'Ship-to Fax No.';
        }
        field(5956; "Ship-to E-Mail"; Text[80])
        {
            Caption = 'Ship-to Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("Ship-to E-Mail");
            end;
        }
        field(5957; "Resource Group Filter"; Code[20])
        {
            Caption = 'Resource Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Resource Group";
        }
        field(5958; "Ship-to Phone"; Text[30])
        {
            Caption = 'Ship-to Phone';
            ExtendedDatatype = PhoneNo;
        }
        field(5959; "Ship-to Phone 2"; Text[30])
        {
            Caption = 'Ship-to Phone 2';
            ExtendedDatatype = PhoneNo;
        }
        field(5966; "Service Zone Filter"; Code[10])
        {
            Caption = 'Service Zone Filter';
            FieldClass = FlowFilter;
            TableRelation = "Service Zone".Code;
        }
        field(5968; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            Editable = false;
            TableRelation = "Service Zone".Code;

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateServiceZoneCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if ShipToAddr.Get("Customer No.", "Ship-to Code") then
                    "Service Zone Code" := ShipToAddr."Service Zone Code"
                else
                    if Cust.Get("Customer No.") then
                        "Service Zone Code" := Cust."Service Zone Code"
                    else
                        "Service Zone Code" := '';
            end;
        }
        field(5981; "Expected Finishing Date"; Date)
        {
            Caption = 'Expected Finishing Date';
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
        }
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';

            trigger OnValidate()
            begin
                MessageIfServLinesExist(FieldCaption("Allow Line Disc."));
            end;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateAssignedUserIdOnBeforeCheckRespCenter(Rec, xRec, IsHandled);
                if not IsHandled then
                    if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center", "Assigned User ID") then
                        Error(Text060, "Assigned User ID", UserSetupMgt.GetServiceFilter("Assigned User ID"));
            end;
        }
        field(9001; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Document Type")
        {
        }
        key(Key3; "Customer No.", "Order Date")
        {
        }
        key(Key4; "Contract No.", Status, "Posting Date")
        {
        }
        key(Key5; Status, "Response Date", "Response Time", Priority, "Responsibility Center")
        {
        }
        key(Key6; Status, Priority, "Response Date", "Response Time")
        {
        }
        key(Key7; "Document Type", "Customer No.", "Order Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Incoming Document Entry No.")
        {
        }
        key(Key10; "Document Type", "Combine Shipments", "Customer No.", "Bill-to Customer No.", "Currency Code", "EU 3-Party Trade", "Dimension Set ID", "Journal Templ. Name")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document Type", "No.", "Customer No.", "Posting Date", Status)
        {
        }
        fieldgroup(Brick; "Document Type", "No.", "Customer No.", "Posting Date", Status)
        {
        }
    }

    trigger OnDelete()
    var
        ServDocRegister: Record "Service Document Register";
        ServDocLog: Record "Service Document Log";
        ServOrderAlloc: Record "Service Order Allocation";
        ServCommentLine: Record "Service Comment Line";
        WhseRequest: Record "Warehouse Request";
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        ServAllocMgt: Codeunit ServAllocationManagement;
        ReservMgt: Codeunit "Reservation Management";
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
        ShowPostedDocsToPrint, IsHandled : Boolean;
    begin
        OnBeforeOnDelete(Rec);

        if not UserSetupMgt.CheckRespCenter(2, "Responsibility Center") then
            Error(Text000, UserSetupMgt.GetServiceFilter());

        if "Document Type" = "Document Type"::Invoice then
            PrepareDeleteServiceInvoice();

        OnDeleteOnBeforeArchiveServiceDocument(Rec, xRec);
        ServiceDocumentArchiveMgmt.AutoArchiveServiceDocument(Rec);

        IsHandled := false;
        OnDeleteHeaderOnBeforeDeleteRelatedRecords(Rec, ServShptHeader, ServInvHeader, ServCrMemoHeader, IsHandled);
        if not IsHandled then
            ServPost.DeleteHeader(Rec, ServShptHeader, ServInvHeader, ServCrMemoHeader);
        Validate("Applies-to ID", '');
        Rec.Validate("Incoming Document Entry No.", 0);

        ServLine.Reset();
        ServLine.LockTable();

        ReservMgt.DeleteDocumentReservation(DATABASE::"Service Line", "Document Type".AsInteger(), "No.", HideValidationDialog);

        WhseRequest.DeleteRequest(DATABASE::"Service Line", Rec."Document Type".AsInteger(), Rec."No.");

        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.SuspendStatusCheck(true);
        ServLine.DeleteAll(true);

        ServCommentLine.Reset();
        ServCommentLine.SetRange("Table Name", ServCommentLine."Table Name"::"Service Header");
        ServCommentLine.SetRange("Table Subtype", "Document Type");
        ServCommentLine.SetRange("No.", "No.");
        ServCommentLine.DeleteAll();

        ServDocRegister.SetCurrentKey("Destination Document Type", "Destination Document No.");
        case "Document Type" of
            "Document Type"::Invoice:
                begin
                    ServDocRegister.SetRange("Destination Document Type", ServDocRegister."Destination Document Type"::Invoice);
                    ServDocRegister.SetRange("Destination Document No.", "No.");
                    ServDocRegister.DeleteAll();
                end;
            "Document Type"::"Credit Memo":
                begin
                    ServDocRegister.SetRange("Destination Document Type", ServDocRegister."Destination Document Type"::"Credit Memo");
                    ServDocRegister.SetRange("Destination Document No.", "No.");
                    ServDocRegister.DeleteAll();
                end;
        end;

        ServOrderAlloc.Reset();
        ServOrderAlloc.SetCurrentKey("Document Type");
        ServOrderAlloc.SetRange("Document Type", "Document Type");
        ServOrderAlloc.SetRange("Document No.", "No.");
        ServOrderAlloc.SetRange(Posted, false);
        ServOrderAlloc.DeleteAll();
        ServAllocMgt.SetServOrderAllocStatus(Rec);

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        if ServItemLine.Find('-') then
            repeat
                if ServItemLine."Loaner No." <> '' then begin
                    Loaner.Get(ServItemLine."Loaner No.");
                    LoanerEntry.SetRange("Document Type", LoanerEntry.GetDocTypeFromServDocType("Document Type"));
                    LoanerEntry.SetRange("Document No.", "No.");
                    LoanerEntry.SetRange("Loaner No.", ServItemLine."Loaner No.");
                    LoanerEntry.SetRange(Lent, true);
                    if not LoanerEntry.IsEmpty() then
                        Error(
                          Text040,
                          TableCaption,
                          ServItemLine."Document No.",
                          ServItemLine."Line No.",
                          ServItemLine.FieldCaption("Loaner No."),
                          ServItemLine."Loaner No.");

                    LoanerEntry.SetRange(Lent, true);
                    LoanerEntry.DeleteAll();
                end;

                Clear(ServLogMgt);
                ServLogMgt.ServItemOffServOrder(ServItemLine);
                OnDeleteOnBeforeServItemLineDelete(ServItemLine, Rec);
                ServItemLine.Delete();
            until ServItemLine.Next() = 0;

        ServDocLog.Reset();
        ServDocLog.SetRange("Document Type", "Document Type");
        ServDocLog.SetRange("Document No.", "No.");
        ServDocLog.DeleteAll();

        ServDocLog.Reset();
        ServDocLog.SetRange(Before, "No.");
        ServDocLog.SetFilter("Document Type", '%1|%2|%3',
          ServDocLog."Document Type"::Shipment, ServDocLog."Document Type"::"Posted Invoice",
          ServDocLog."Document Type"::"Posted Credit Memo");
        ServDocLog.DeleteAll();

        OnDeleteOnBeforeShowPostedDocsToPrint(Rec);

        ShowPostedDocsToPrint := (ServShptHeader."No." <> '') or
           (ServInvHeader."No." <> '') or
           (ServCrMemoHeader."No." <> '');
        OnBeforeShowPostedDocsToPrintCreatedMsg(ShowPostedDocsToPrint);
        if ShowPostedDocsToPrint then
            Message(PostedDocsToPrintCreatedMsg);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        InitInsert();

        Clear(ServLogMgt);
        ServLogMgt.ServHeaderCreate(Rec);

        if "Salesperson Code" = '' then
            SetDefaultSalesperson();

        if GetFilter("Customer No.") <> '' then begin
            Clear(xRec."Ship-to Code");
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                Validate("Customer No.", GetRangeMin("Customer No."));
        end;

        if GetFilter("Contact No.") <> '' then
            if GetRangeMin("Contact No.") = GetRangeMax("Contact No.") then
                Validate("Contact No.", GetRangeMin("Contact No."));

        OnAfterOnInsert(Rec);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UpdateServiceOrderChangeLog(xRec);
    end;

    trigger OnRename()
    begin
        Error(Text044, TableCaption);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot delete this document. Your identification is set up to process from Responsibility Center %1 only.', Comment = '%1=User management service filter;';
#pragma warning disable AA0470
        Text001: Label 'Changing %1 in service header %2 will not update the existing service lines.\You must update the existing service lines manually.';
#pragma warning restore AA0470
        Text003: Label 'You cannot change the %1 because the %2 %3 %4 is associated with a %5 %6.', Comment = '%1=Customer number field caption;%2=Document type;%3=Number field caption;%4=Number;%5=Contract number field caption;%6=Contract number; ';
#pragma warning disable AA0470
        Text004: Label 'When you change the %1 the existing Service item line and service line will be deleted.\Do you want to change the %1?';
        Text005: Label 'Do you want to change the %1?';
        Text007: Label '%1 cannot be greater than %2.';
#pragma warning restore AA0470
        Text008: Label 'You cannot create Service %1 with %2=%3 because this number has already been used in the system.', Comment = '%1=Document type format;%2=Number field caption;%3=Number;';
        Text010: Label 'Your identification is set up to process from %1 %2 only.', Comment = '%1=Resposibility center table caption;%2=User management service filter;';
#pragma warning disable AA0470
        Text011: Label '%1 cannot be greater than %2 in the %3 table.';
        Text012: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?';
        Text013: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
#pragma warning restore AA0470
        Text015: Label 'Do you want to update the exchange rate?';
#pragma warning disable AA0470
        Text016: Label 'You have modified %1.\Do you want to update the service lines?';
#pragma warning restore AA0470
        Text018: Label 'You have not specified the %1 for %2 %3=%4, %5=%6.', Comment = '%1=Service order type field caption;%2=table caption;%3=Document type field caption;%4=Document type format;%5=Number field caption;%6=Number format;';
#pragma warning disable AA0470
        Text019: Label 'You have changed %1 on the service header, but it has not been changed on the existing service lines.\The change may affect the exchange rate used in the price calculation of the service lines.';
        Text021: Label 'You have changed %1 on the %2, but it has not been changed on the existing service lines.\You must update the existing service lines manually.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Cust: Record Customer;
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        ServItemLine: Record "Service Item Line";
        PostCode: Record "Post Code";
        CurrExchRate: Record "Currency Exchange Rate";
        GeneralLedgerSetup: Record "General Ledger Setup";
#if not CLEAN27
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
#endif
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        Salesperson: Record "Salesperson/Purchaser";
        ServOrderMgt: Codeunit ServOrderManagement;
        DimMgt: Codeunit DimensionManagement;
        NoSeries: Codeunit "No. Series";
        ServLogMgt: Codeunit ServLogManagement;
        UserSetupMgt: Codeunit "User Setup Management";
        NotifyCust: Codeunit "Customer-Notify by Email";
        ServPost: Codeunit "Service-Post";
        CurrencyDate: Date;
        TempLinkToServItem: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text024: Label 'The %1 cannot be greater than the minimum %1 of the\ Service Item Lines.';
        Text025: Label 'The %1 cannot be less than the maximum %1 of the related\ Service Item Lines.';
        Text026: Label '%1 cannot be earlier than the %2.';
        Text027: Label 'The %1 cannot be greater than the minimum %2 of the related\ Service Item Lines.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ValidatingFromLines: Boolean;
        LinesExist: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text028: Label 'You cannot change the %1 because %2 exists.';
        Text029: Label 'The %1 field on the %2 will be updated if you change %3 manually.\Do you want to continue?';
#pragma warning restore AA0470
        Text031: Label 'You cannot change %1 to %2 in %3 %4.\\%5 %6 in %7 %8 line is preventing it.', Comment = '%1=Status field caption;%2=Status format;%3=table caption;%4=Number;%5=ServItemLine repair status code field caption;%6=ServItemLine repair status code;%7=ServItemLine table caption;%8=ServItemLine line number;';
        Text037: Label 'Contact %1 %2 is not related to customer %3.', Comment = '%1=Contact number;%2=Contact name;%3=Customer number;';
        Text038: Label 'Contact %1 %2 is related to a different company than customer %3.', Comment = '%1=Contact number;%2=Contact name;%3=Customer number;';
        Text039: Label 'Contact %1 %2 is not related to a customer.', Comment = '%1=Contact number;%2=Contact name;';
#pragma warning restore AA0074
        ContactNo: Code[20];
#pragma warning disable AA0074
        Text040: Label 'You cannot delete %1 %2 because the %4 %5 for Service Item Line %3 has not been received.', Comment = '%1=table caption;%2=ServItemLine document number;%3=ServItemLine line number;%4=ServItemLine loaner number field caption;%5=ServItemLine loaner number;';
#pragma warning restore AA0074
        SkipContact: Boolean;
        SkipBillToContact: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text041: Label 'Contract %1 is not signed.';
        Text042: Label 'The service period for contract %1 has not yet started.';
        Text043: Label 'The service period for contract %1 has expired.';
        Text044: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text045: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.', Comment = '%1=Posting date field caption;%2=Posting number series field caption;%3=Posting number series;%4=NoSeries date order field caption;%5=NoSeries date order;%6=Document type;%7=posting number field caption;%8=Posting number;';
#pragma warning disable AA0470
        Text047: Label 'You cannot change %1 because reservation, item tracking, or order tracking exists on the sales order.';
        Text050: Label 'You cannot reset %1 because the document still has one or more lines.';
#pragma warning restore AA0470
        Text051: Label 'The service %1 %2 already exists.', Comment = '%1=Document type format;%2=Number;';
#pragma warning disable AA0470
        Text053: Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text054: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text055: Label 'You have modified the %1 field. Note that the recalculation of VAT may cause penny differences, so you must check the amounts afterwards. Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text057: Label 'When you change the %1 the existing service line will be deleted.\Do you want to change the %1?';
#pragma warning restore AA0470
        Text058: Label 'You cannot change %1 because %2 %3 is linked to Contract %4.', Comment = '%1=Currency code field caption;%2=Document type;%3=Number;%4=Contract number;';
        Text060: Label 'Responsibility Center is set up to process from %1 %2 only.', Comment = '%1=Assigned user ID;%2=User management service filter assigned user id;';
        Text061: Label 'You may have changed a dimension.\\Do you want to update the lines?';
#pragma warning disable AA0470
        Text062: Label 'An open inventory pick exists for the %1 and because %2 is %3.\\You must first post or delete the inventory pick or change %2 to Partial.';
        Text063: Label 'An open warehouse shipment exists for the %1 and %2 is %3.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change %2 to Partial.';
        Text064: Label 'You cannot change %1 to %2 because an open inventory pick on the %3.';
        Text065: Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.';
#pragma warning restore AA0470
        Text066: Label 'You cannot change the dimension because there are service entries connected to this line.';
#pragma warning restore AA0074
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        MissingExchangeRatesQst: Label 'There are no exchange rates for currency %1 and date %2. Do you want to add them now? Otherwise, the last change you made will be reverted.', Comment = '%1 - currency code, %2 - posting date';
        FullServiceTypesTxt: Label 'Service Quote,Service Order,Service Invoice,Service Credit Memo';
        RestoreInvoiceDatesOnDeleteInvQst: Label 'Deleting the service invoice will restore the previous invoice dates in the service contract. Do you want to continue?';
        CannotDeletePostedInvoiceErr: Label 'The service invoice cannot be deleted because it has been posted.';
        CannotDeleteWhenNextInvPostedErr: Label 'The service invoice cannot be deleted because there are posted service ledger entries with a later posting date.';
        CannotDeleteWhenNextInvExistsErr: Label 'The service invoice cannot be deleted because there are service invoices with a later posting date.';
        CannotRestoreInvoiceDatesErr: Label 'The service invoice cannot be deleted because the previous invoice dates cannot be restored in the service contract.';
        InvoicePeriodChangedErr: Label 'The invoice period in the service contract has been changed and cannot be updated.';
#if not CLEAN27
        SkipStatsPrep: Boolean;
#endif

    protected var
        GlobalNoSeries: Record "No. Series";
        HideValidationDialog: Boolean;

    /// <summary>
    /// Lists all related number series for service header when creating new record.
    /// </summary>
    /// <param name="OldServHeader">Service header record that is created. </param>
    /// <returns>Returns true if number series is assigned successfully, otherwise 'false'. </returns>
    procedure AssistEdit(OldServHeader: Record "Service Header"): Boolean
    var
        ServHeader2: Record "Service Header";
    begin
        ServHeader.Copy(Rec);
        ServHeader.GetServiceMgtSetup();
        ServHeader.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(ServHeader.GetNoSeriesCode(), OldServHeader."No. Series", ServHeader."No. Series") then begin
            if (ServHeader."Customer No." = '') and (ServHeader."Contact No." = '') then
                ServHeader.CheckCreditMaxBeforeInsert(false);

            ServHeader."No." := NoSeries.GetNextNo(ServHeader."No. Series");
            if ServHeader2.Get(ServHeader."Document Type", ServHeader."No.") then
                Error(Text051, LowerCase(Format(ServHeader."Document Type")), ServHeader."No.");
            Rec := ServHeader;
            exit(true);
        end;
    end;

    /// <summary>
    /// Generates new dimension set id from provided default dimensions for the current service header.
    /// </summary>
    /// <param name="DefaultDimSource">Provided list of default dimensions. </param>
    /// <remarks>If selected service header is assigned to a contract, it's dimension will be added.
    /// Additional dimensions will be propagated to service item lines or service lines if they exist. </remarks>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        ServiceContractHeader: Record "Service Contract Header";
        ContractDimensionSetID: Integer;
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";

        if "Contract No." <> '' then begin
            ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, "Contract No.");
            ContractDimensionSetID := ServiceContractHeader."Dimension Set ID";
        end;

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Service Management",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ContractDimensionSetID, DATABASE::"Service Contract Header");

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource);

        if "Dimension Set ID" <> OldDimSetID then begin
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            if ServItemLineExists() or ServLineExists() then begin
                Modify();
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
            end;
        end;

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        xServiceLine: Record "Service Line";
        ConfirmManagement: Codeunit "Confirm Management";
        NewDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;

        IsHandled := false;
        OnUpdateAllLineDimOnBeforeGetResponse(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled);
        if not IsHandled then
            if not HideValidationDialog and GuiAllowed then
                if not ConfirmManagement.GetResponseOrDefault(Text061, true) then
                    exit;

        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.LockTable();
        if ServLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetServLineNewDimSetID(ServLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServLine."Dimension Set ID" <> NewDimSetID then begin
                    xServiceLine := ServLine;
                    ServLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServLine."Dimension Set ID", ServLine."Shortcut Dimension 1 Code", ServLine."Shortcut Dimension 2 Code");

                    OnUpdateAllLineDimOnBeforeServiceLineModify(ServLine, xServiceLine);
                    ServLine.Modify();
                    OnUpdateAllLineDimOnAfterServiceLineModify(ServLine);
                end;
            until ServLine.Next() = 0;

        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.LockTable();
        if ServItemLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetServItemLineNewDimSetID(ServItemLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(ServItemLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if ServItemLine."Dimension Set ID" <> NewDimSetID then begin
                    ServItemLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ServItemLine."Dimension Set ID", ServItemLine."Shortcut Dimension 1 Code", ServItemLine."Shortcut Dimension 2 Code");
                    ServItemLine.Modify();
                end;
            until ServItemLine.Next() = 0;
    end;

    local procedure ValidatePaymentTerms(var ServiceHeader: Record "Service Header")
    var
        PaymentTerms: Record "Payment Terms";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidatePaymentTerms(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        if (ServiceHeader."Payment Terms Code" <> '') and (ServiceHeader."Document Date" <> 0D) then begin
            PaymentTerms.Get("Payment Terms Code");
            if (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::"Credit Memo"]) and
               not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos"
            then begin
                ServiceHeader.Validate("Due Date", ServiceHeader."Document Date");
                ServiceHeader.Validate("Pmt. Discount Date", 0D);
                ServiceHeader.Validate("Payment Discount %", 0);
            end else begin
                ServiceHeader."Due Date" := CalcDate(PaymentTerms."Due Date Calculation", ServiceHeader."Document Date");
                ServiceHeader."Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", ServiceHeader."Document Date");
                ServiceHeader.Validate("Payment Discount %", PaymentTerms."Discount %")
            end;
        end else begin
            IsHandled := false;
            OnValidatePaymentTermsCodeOnBeforeValidateDueDate(ServiceHeader, IsHandled);
            if not IsHandled then
                ServiceHeader.Validate("Due Date", ServiceHeader."Document Date");
            ServiceHeader.Validate("Pmt. Discount Date", 0D);
            ServiceHeader.Validate("Payment Discount %", 0);
        end;
    end;

    /// <summary>
    /// Triggers validation of shortcut dimension values.
    /// </summary>
    /// <param name="FieldNumber">Indicates the number of a field which invoked the method. </param>
    /// <param name="ShortcutDimCode">Specified value of the shortcut dimension. </param>
    /// <remarks>Additional changes will be propagated to service item lines or service lines if they exist. </remarks>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnValidateShortcutDimCodeOnBeforeUpdateUpdateAllLineDim(Rec, xRec, FieldNumber);
        if ServItemLineExists() or ServLineExists() then
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Updates value of the field 'Currency Factor' for the current service header.
    /// </summary>
    /// <remarks>If no exchange rate for selected currency code exists, the system will offer to a user option to manually add missing exchange rate.
    /// Changes will be propagated to all existing service lines related to current service header. </remarks>
    procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCurrencyFactor(Rec, CurrExchRate, IsHandled);
        if IsHandled then
            exit;

        if "Currency Code" <> '' then begin
            GeneralLedgerSetup.GetRecordOnce();
            CurrencyDate := "Posting Date";
            OnUpdateCurrencyFactorOnAfterSetCurrencyDate(Rec, GeneralLedgerSetup, CurrencyDate);
            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, "Currency Code") then begin
                "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                if "Currency Code" <> xRec."Currency Code" then
                    RecreateServLines(FieldCaption("Currency Code"));
            end else
                if ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(MissingExchangeRatesQst, "Currency Code", CurrencyDate), true)
                then begin
                    UpdateCurrencyExchangeRates.OpenExchangeRatesPage("Currency Code");
                    UpdateCurrencyFactor();
                end else
                    RevertCurrencyCodeAndPostingDate();
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreateServLines(FieldCaption("Currency Code"));
        end;
    end;

    /// <summary>
    /// Recalculates existing service lines related to current service header based on new values from hader.
    /// </summary>
    /// <param name="ChangedFieldName">Indicates the name of a field which invoked the method. </param>
    /// <remarks>Changing 'Location Code' value won't be possible if reservation entry, item tracking code or order tracking exist.
    /// Additional service lines must not be shipped or invoiced. </remarks>
    procedure RecreateServLines(ChangedFieldName: Text[100])
    var
        TempServLine: Record "Service Line" temporary;
        ServDocReg: Record "Service Document Register";
        TempServDocReg: Record "Service Document Register" temporary;
        ServiceCommentLine: Record "Service Comment Line";
        TempServiceCommentLine: Record "Service Comment Line" temporary;
        Confirmed: Boolean;
        ExtendedTextAdded: Boolean;
        IsHandled: Boolean;
    begin
        if not ServLineExists() then
            exit;

        IsHandled := false;
        OnBeforeRecreateServLines(Rec, xRec, ChangedFieldName, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        Confirmed := ConfirmRecreateServLines(ChangedFieldName);

        if Confirmed then begin
            ServLine.LockTable();
            ReservEntry.LockTable();
            Modify();

            IsHandled := false;
            OnRecreateServLinesOnBeforeUpdateLines(Rec, IsHandled);
            if IsHandled then
                exit;

            ServLine.Reset();
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "No.");
            OnRecreateServLinesOnAfterServLineSetFilters(ServLine);
            if ServLine.Find('-') then begin
                repeat
                    ServLine.TestField("Quantity Shipped", 0);
                    ServLine.TestField("Quantity Invoiced", 0);
                    ServLine.TestField("Shipment No.", '');
                    TempServLine := ServLine;
                    if ServLine.Nonstock then begin
                        ServLine.Nonstock := false;
                        ServLine.Modify();
                    end;
                    TempServLine.Insert();
                    CopyReservEntryToTemp(ServLine);
                until ServLine.Next() = 0;

                if "Location Code" <> xRec."Location Code" then
                    if not TempReservEntry.IsEmpty() then
                        Error(Text047, FieldCaption("Location Code"));

                if "Document Type" = "Document Type"::Invoice then begin
                    ServDocReg.SetCurrentKey("Destination Document Type", "Destination Document No.");
                    ServDocReg.SetRange("Destination Document Type", ServDocReg."Destination Document Type"::Invoice);
                    ServDocReg.SetRange("Destination Document No.", TempServLine."Document No.");
                    if ServDocReg.Find('-') then
                        repeat
                            TempServDocReg := ServDocReg;
                            TempServDocReg.Insert();
                        until ServDocReg.Next() = 0;
                end;
                StoreServiceCommentLineToTemp(TempServiceCommentLine);
                ServiceCommentLine.DeleteServiceInvoiceLinesRelatedComments(Rec);
                IsHandled := false;
                OnRecreateServLinesOnBeforeServLineDeleteAll(Rec, ServLine, CurrFieldNo, IsHandled);
                if not IsHandled then
                    ServLine.DeleteAll(true);

                if "Document Type" = "Document Type"::Invoice then
                    if TempServDocReg.Find('-') then
                        repeat
                            ServDocReg := TempServDocReg;
                            ServDocReg.Insert();
                        until TempServDocReg.Next() = 0;

                CreateServiceLines(TempServLine, ExtendedTextAdded, TempServiceCommentLine);
                TempServLine.SetRange(Type);
                TempServLine.DeleteAll();
                OnRecreateServLinesOnAfterTempServLineDeleteAll(Rec);
            end;
        end else
            Error('');
    end;

    local procedure StoreServiceCommentLineToTemp(var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", "Document Type");
        ServiceCommentLine.SetRange("No.", "No.");
        ServiceCommentLine.SetRange(Type, ServiceCommentLine.Type::General);
        if ServiceCommentLine.FindSet() then
            repeat
                TempServiceCommentLine := ServiceCommentLine;
                TempServiceCommentLine.Insert();
            until ServiceCommentLine.Next() = 0;
    end;

    local procedure RestoreServiceCommentLine(var TempServiceCommentLine: Record "Service Comment Line" temporary; OldDocumentLineNo: Integer; NewDocumentLineNo: Integer)
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        TempServiceCommentLine.SetRange("Table Name", TempServiceCommentLine."Table Name"::"Service Header");
        TempServiceCommentLine.SetRange("Table Subtype", "Document Type");
        TempServiceCommentLine.SetRange("No.", "No.");
        TempServiceCommentLine.SetRange("Table Line No.", OldDocumentLineNo);
        if TempServiceCommentLine.FindSet() then
            repeat
                ServiceCommentLine := TempServiceCommentLine;
                ServiceCommentLine."Table Line No." := NewDocumentLineNo;
                ServiceCommentLine.Insert();
            until TempServiceCommentLine.Next() = 0;
    end;

    procedure ConfirmCurrencyFactorUpdate()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Confirmed: Boolean;
    begin
        if HideValidationDialog then
            Confirmed := true
        else
            Confirmed := ConfirmManagement.GetResponseOrDefault(Text015, true);

        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";
    end;

    /// <summary>
    /// Propagates changes for specific fields provided by 'ChangedFieldNo' to service lines related to current service header.
    /// </summary>
    /// <param name="ChangedFieldNo">Indicates the number of fields which invoked the validation. </param>
    /// <param name="AskQuestion">Indicates if confirmation dialog should appear. </param>
    procedure UpdateServLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        ConfirmManagement: Codeunit "Confirm Management";
        Question: Text[250];
        IsHandled: Boolean;
    begin
        Field.Get(DATABASE::"Service Header", ChangedFieldNo);

        IsHandled := false;
        OnBeforeUpdateServLinesByFieldNoOnBeforeAskQst(Rec, AskQuestion, ChangedFieldNo, IsHandled);
        if not IsHandled then
            if ServLineExists() and AskQuestion then begin
                Question := StrSubstNo(
                    Text016,
                    Field."Field Caption");
                if not ConfirmManagement.GetResponseOrDefault(Question, true) then
                    exit
            end;

        if ServLineExists() then begin
            ServLine.LockTable();
            ServLine.Reset();
            ServLine.SetRange("Document Type", "Document Type");
            ServLine.SetRange("Document No.", "No.");

            ServLine.SetRange("Quantity Shipped", 0);
            ServLine.SetRange("Quantity Invoiced", 0);
            ServLine.SetRange("Quantity Consumed", 0);
            ServLine.SetRange("Shipment No.", '');
            OnUpdateServLinesByFieldNoOnAfterServLineSetFilters(ServLine, Rec, xRec, ChangedFieldNo);

            if ServLine.Find('-') then
                repeat
                    case ChangedFieldNo of
                        FieldNo("Currency Factor"):
                            if (ServLine."Posting Date" = "Posting Date") and (ServLine.Type <> ServLine.Type::" ") then begin
                                ServLine.Validate("Unit Price");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Posting Date"):
                            begin
                                ServLine.Validate("Posting Date", "Posting Date");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Responsibility Center"):
                            begin
                                ServLine.Validate("Responsibility Center", "Responsibility Center");
                                ServLine.Modify(true);
                                ServItemLine.Reset();
                                ServItemLine.SetRange("Document Type", "Document Type");
                                ServItemLine.SetRange("Document No.", "No.");
                                if ServItemLine.Find('-') then
                                    repeat
                                        ServItemLine.Validate("Responsibility Center", "Responsibility Center");
                                        ServItemLine.Modify(true);
                                    until ServItemLine.Next() = 0;
                            end;
                        FieldNo("Order Date"):
                            begin
                                ServLine."Order Date" := "Order Date";
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transaction Type"):
                            begin
                                ServLine.Validate("Transaction Type", "Transaction Type");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transport Method"):
                            begin
                                ServLine.Validate("Transport Method", "Transport Method");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Exit Point"):
                            begin
                                ServLine.Validate("Exit Point", "Exit Point");
                                ServLine.Modify(true);
                            end;
                        FieldNo(Area):
                            begin
                                ServLine.Validate(Area, Area);
                                ServLine.Modify(true);
                            end;
                        FieldNo("Transaction Specification"):
                            begin
                                ServLine.Validate("Transaction Specification", "Transaction Specification");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Agent Code"):
                            begin
                                ServLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Time"):
                            begin
                                ServLine.Validate("Shipping Time", "Shipping Time");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Shipping Agent Service Code"):
                            begin
                                if ServLine."Shipping Agent Code" <> "Shipping Agent Code" then
                                    ServLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                                ServLine.Validate("Shipping Agent Service Code", "Shipping Agent Service Code");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Customer No."):
                            begin
                                ServLine.Validate("Customer No.");
                                ServLine.Modify(true);
                            end;
                        FieldNo("Tax Liable"):
                            if ServLine."No." <> '' then
                                ServLine.Validate("Tax Liable", "Tax Liable");
                        else
                            OnUpdateServLineByChangedFieldName(Rec, ServLine, Field."Field Caption", ChangedFieldNo);
                    end;
                until ServLine.Next() = 0;
        end;

        OnAfterUpdateServLinesByFieldNo(Rec, ServLine, ChangedFieldNo);
    end;

    /// <summary>
    /// Verify if all necessary fields are populated for provided service lines based on service management setup.
    /// </summary>
    /// <param name="PassedServLine">Provided service lines. </param>
    ///<remarks>If 'PassedServLine' is empty, service lines will be filter to the current service header. </remarks>
    procedure TestMandatoryFields(var PassedServLine: Record "Service Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeTestMandatoryFields(Rec, PassedServLine);

        GetServiceMgtSetup();
        CheckMandSalesPersonOrderData(ServiceMgtSetup);
        PassedServLine.Reset();
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");

        IsHandled := false;
        OnTestMandatoryFieldsOnBeforePassedServLineFind(Rec, ServLine, PassedServLine, IsHandled);
        if IsHandled then
            exit;

        if PassedServLine.Find('-') then
            repeat
                if (PassedServLine."Qty. to Ship" <> 0) or
                   (PassedServLine."Qty. to Invoice" <> 0) or
                   (PassedServLine."Qty. to Consume" <> 0)
                then begin
                    if ("Document Type" = "Document Type"::Order) and
                       "Link Service to Service Item" and
                       (PassedServLine.Type in [PassedServLine.Type::Item, PassedServLine.Type::Resource])
                    then
                        PassedServLine.TestField("Service Item Line No.", ErrorInfo.Create());

                    case PassedServLine.Type of
                        PassedServLine.Type::Item:
                            if ServiceMgtSetup."Unit of Measure Mandatory" then
                                PassedServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                        PassedServLine.Type::Resource:
                            begin
                                if ServiceMgtSetup."Work Type Code Mandatory" then
                                    PassedServLine.TestField("Work Type Code", ErrorInfo.Create());
                                if ServiceMgtSetup."Unit of Measure Mandatory" then
                                    PassedServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                            end;
                        PassedServLine.Type::Cost:
                            if ServiceMgtSetup."Unit of Measure Mandatory" then
                                PassedServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                    end;

                    if PassedServLine."Job No." <> '' then
                        PassedServLine.TestField("Qty. to Consume", PassedServLine."Qty. to Ship", ErrorInfo.Create());
                end;
            until PassedServLine.Next() = 0
        else
            if ServLine.Find('-') then
                repeat
                    if (ServLine."Qty. to Ship" <> 0) or
                       (ServLine."Qty. to Invoice" <> 0) or
                       (ServLine."Qty. to Consume" <> 0)
                    then begin
                        if ("Document Type" = "Document Type"::Order) and
                           "Link Service to Service Item" and
                           (ServLine.Type in [ServLine.Type::Item, ServLine.Type::Resource])
                        then
                            ServLine.TestField("Service Item Line No.", ErrorInfo.Create());

                        case ServLine.Type of
                            ServLine.Type::Item:
                                if ServiceMgtSetup."Unit of Measure Mandatory" then
                                    ServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                            ServLine.Type::Resource:
                                begin
                                    if ServiceMgtSetup."Work Type Code Mandatory" then
                                        ServLine.TestField("Work Type Code", ErrorInfo.Create());
                                    if ServiceMgtSetup."Unit of Measure Mandatory" then
                                        ServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                                end;
                            ServLine.Type::Cost:
                                if ServiceMgtSetup."Unit of Measure Mandatory" then
                                    ServLine.TestField("Unit of Measure Code", ErrorInfo.Create());
                        end;

                        if ServLine."Job No." <> '' then
                            ServLine.TestField("Qty. to Consume", ServLine."Qty. to Ship", ErrorInfo.Create());
                    end;
                until ServLine.Next() = 0;
    end;

    /// <summary>
    /// Updates values of 'Response Date' and 'Response Time' based on related service item line.
    /// </summary>
    procedure UpdateResponseDateTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateResponseDateTime(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Response Date");
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        if ServItemLine.Find('-') then begin
            "Response Date" := ServItemLine."Response Date";
            "Response Time" := ServItemLine."Response Time";
            Modify(true);
        end;
    end;

    local procedure UpdateStartingDateTime()
    begin
        OnBeforeUpdateStartingDateTime(Rec, ValidatingFromLines, ServiceMgtSetup);
        if ValidatingFromLines then
            exit;
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Starting Date");
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.SetFilter("Starting Date", '<>%1', 0D);
        if ServItemLine.Find('-') then begin
            "Starting Date" := ServItemLine."Starting Date";
            "Starting Time" := ServItemLine."Starting Time";
            Modify(true);
        end else begin
            "Starting Date" := 0D;
            "Starting Time" := 0T;
        end;
    end;

    local procedure UpdateFinishingDateTime()
    begin
        OnBeforeUpdateFinishingDateTime(Rec, ValidatingFromLines, ServiceMgtSetup);
        if ValidatingFromLines then
            exit;
        ServItemLine.Reset();
        ServItemLine.SetCurrentKey("Document Type", "Document No.", "Finishing Date");
        ServItemLine.Ascending := false;
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        ServItemLine.SetFilter("Finishing Date", '<>%1', 0D);
        if ServItemLine.Find('-') then begin
            "Finishing Date" := ServItemLine."Finishing Date";
            "Finishing Time" := ServItemLine."Finishing Time";
            Modify(true);
        end else begin
            "Finishing Date" := 0D;
            "Finishing Time" := 0T;
        end;
    end;

    local procedure PriceMsgIfServLinesExist(ChangedFieldName: Text[100])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePriceMsgIfServLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if ServLineExists() then
            Message(
              Text019,
              ChangedFieldName);
    end;

    /// <summary>
    /// Checks if service item line exists for current service header record.
    /// </summary>
    /// <returns>Returns 'true' if service item line exists, otherwise 'false'. </returns>
    procedure ServItemLineExists(): Boolean
    var
        ServItemLine: Record "Service Item Line";
    begin
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        exit(not ServItemLine.IsEmpty);
    end;

    /// <summary>
    /// Checks if service line exists for current service header record.
    /// </summary>
    /// <returns>Returns 'true' if service line exists, otherwise 'false'. </returns>
    procedure ServLineExists(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        exit(not ServLine.IsEmpty);
    end;

    procedure MessageIfServLinesExist(ChangedFieldName: Text[100])
    begin
        if ServLineExists() and not HideValidationDialog then
            Message(
              Text021,
              ChangedFieldName, TableCaption);
    end;

    local procedure ValidateServPriceGrOnServItem()
    begin
        ServItemLine.Reset();
        ServItemLine.SetRange("Document Type", "Document Type");
        ServItemLine.SetRange("Document No.", "No.");
        OnValidateServPriceGrOnServItemOnAfterServItemLineSetFilters(Rec, ServItemLine);
        if ServItemLine.Find('-') then begin
            ServItemLine.SetServHeader(Rec);
            repeat
                if ServItemLine."Service Price Group Code" <> '' then begin
                    ServItemLine.Validate("Service Price Group Code");
                    ServItemLine.Modify();
                end;
            until ServItemLine.Next() = 0
        end;
    end;

    /// <summary>
    /// Sets value to the global 'HideValidationDialog' which indicates if messages or confirmation dialogs should be shown.
    /// </summary>
    /// <param name="NewHideValidationDialog">New boolean value for 'HideValidationDialog'. </param>
    /// <remarks>If set to 'true' no message or confirmation dialog will be shown. </remarks>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetHideValidationDialog(Rec, HideValidationDialog, NewHideValidationDialog, IsHandled);
        if not IsHandled then
            HideValidationDialog := NewHideValidationDialog;
    end;

    /// <summary>
    /// Indicates if of values 'Sarting Date', 'Starting Time', 'Finishing Date' and 'Finishing Time' will be taken from related service item line for current service header.
    /// Also it controls if field 'Fault Reason Code' should be populated on related service item lines.
    /// </summary>
    /// <param name="NewValidatingFromLines">New value for 'ValidatingFromLines'. </param>
    ///<remarks>If 'true' transfer won't be done. </remarks>
    procedure SetValidatingFromLines(NewValidatingFromLines: Boolean)
    begin
        ValidatingFromLines := NewValidatingFromLines;
        OnAfterSetValidatingFromLines(Rec, ValidatingFromLines);
    end;

    /// <summary>
    /// Test if a setup for services number series is defined in the service management setup record, also if a corresponding general journal template setup exist.
    /// </summary>
    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.GetRecordOnce();
        if not GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            case "Document Type" of
                "Document Type"::Quote:
                    ServiceMgtSetup.TestField("Service Quote Nos.");
                "Document Type"::Order:
                    ServiceMgtSetup.TestField("Service Order Nos.");
            end
        else begin
            case "Document Type" of
                "Document Type"::Quote:
                    ServiceMgtSetup.TestField("Service Quote Nos.");
                "Document Type"::Order:
                    ServiceMgtSetup.TestField("Service Order Nos.");
            end;
            if "Document Type" <> "Document Type"::"Credit Memo" then begin
                ServiceMgtSetup.TestField("Serv. Inv. Template Name");
                if "Journal Templ. Name" = '' then
                    GenJournalTemplate.Get(ServiceMgtSetup."Serv. Inv. Template Name")
                else
                    GenJournalTemplate.Get("Journal Templ. Name");
            end else begin
                ServiceMgtSetup.TestField("Serv. Cr. Memo Templ. Name");
                if "Journal Templ. Name" = '' then
                    GenJournalTemplate.Get(ServiceMgtSetup."Serv. Cr. Memo Templ. Name")
                else
                    GenJournalTemplate.Get("Journal Templ. Name");
            end;
            GenJournalTemplate.TestField("Posting No. Series");
            GlobalNoSeries.Get(GenJournalTemplate."Posting No. Series");
            GlobalNoSeries.TestField("Default Nos.", true);
        end;
    end;

    /// <summary>
    /// Gets a number series code for the current service header record based on 'Document Type'.
    /// </summary>
    /// <returns>Returns found number series code. </returns>
    procedure GetNoSeriesCode() NoSeriesCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNoSeries(Rec, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                exit(ServiceMgtSetup."Service Quote Nos.");
            "Document Type"::Order:
                exit(ServiceMgtSetup."Service Order Nos.");
            "Document Type"::Invoice:
                exit(ServiceMgtSetup."Service Invoice Nos.");
            "Document Type"::"Credit Memo":
                exit(ServiceMgtSetup."Service Credit Memo Nos.");
        end;

        OnAfterGetNoSeriesCode(Rec, ServiceMgtSetup, NoSeriesCode);
    end;

    local procedure TestNoSeriesManual()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestNoSeriesManual(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Document Type" of
            "Document Type"::Quote:
                NoSeries.TestManual(ServiceMgtSetup."Service Quote Nos.");
            "Document Type"::Order:
                NoSeries.TestManual(ServiceMgtSetup."Service Order Nos.");
            "Document Type"::Invoice:
                NoSeries.TestManual(ServiceMgtSetup."Service Invoice Nos.");
            "Document Type"::"Credit Memo":
                NoSeries.TestManual(ServiceMgtSetup."Service Credit Memo Nos.");
        end;
    end;

    local procedure UpdateCont(CustomerNo: Code[20])
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
                "Fax No." := Cont."Fax No.";
                "E-Mail" := Cont."E-Mail";
            end else begin
                if Cust."Primary Contact No." <> '' then
                    "Contact No." := Cust."Primary Contact No."
                else
                    if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, "Customer No.") then
                        "Contact No." := ContBusRel."Contact No."
                    else
                        "Contact No." := '';
                "Contact Name" := Cust.Contact;
            end;
        end;
        OnAfterUpdateCont(Rec, Cust, Cont);
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
                        "Bill-to Contact No." := ContBusRel."Contact No."
                    else
                        "Bill-to Contact No." := '';
                "Bill-to Contact" := Cust.Contact;
            end;
        end;

        OnAfterUpdateBillToCont(Rec, Cust, Cont);
    end;

    local procedure UpdateCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCust(ContactNo, IsHandled);
        if IsHandled then
            exit;

        if Cont.Get(ContactNo) then begin
            "Contact No." := Cont."No.";
            "Phone No." := Cont."Phone No.";
            "E-Mail" := Cont."E-Mail";
        end else begin
            "Phone No." := '';
            "Fax No." := '';
            "E-Mail" := '';
            "Contact Name" := '';
            exit;
        end;

        if Cont.Type = Cont.Type::Person then
            "Contact Name" := Cont.Name
        else
            if Cust.Get("Customer No.") then
                "Contact Name" := Cust.Contact
            else
                "Contact Name" := '';

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if ("Customer No." <> '') and
               ("Customer No." <> ContBusinessRelation."No.")
            then
                Error(Text037, Cont."No.", Cont.Name, "Customer No.");

            if "Customer No." = '' then begin
                SkipContact := true;
                Validate("Customer No.", ContBusinessRelation."No.");
                SkipContact := false;
            end;
        end else
            Error(Text039, Cont."No.", Cont.Name);

        if ("Customer No." = "Bill-to Customer No.") or
           ("Bill-to Customer No." = '')
        then
            Validate("Bill-to Contact No.", "Contact No.");

        OnAfterUpdateCust(Rec);
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cust: Record Customer;
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if Cont.Get(ContactNo) then begin
            "Bill-to Contact No." := Cont."No.";
            if Cont.Type = Cont.Type::Person then
                "Bill-to Contact" := Cont.Name
            else
                if Cust.Get("Bill-to Customer No.") then
                    "Bill-to Contact" := Cust.Contact
                else
                    "Bill-to Contact" := '';
            OnUpdateBillToCustOnAfterUpdateBillToContact(Rec, Cust, Cont);
        end else begin
            "Bill-to Contact" := '';
            exit;
        end;

        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
            end else
                if "Bill-to Customer No." <> ContBusinessRelation."No." then
                    Error(Text037, Cont."No.", Cont.Name, "Bill-to Customer No.");
        end else
            Error(Text039, Cont."No.", Cont.Name);
    end;

    procedure CheckCreditMaxBeforeInsert(HideCreditCheckDialogue: Boolean)
    var
        ServHeader: Record "Service Header";
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
        IsHandled: Boolean;
    begin
        if HideCreditCheckDialogue then
            exit;

        IsHandled := false;
        OnBeforeCheckCreditMaxBeforeInsert(Rec, IsHandled);
        if not IsHandled then
            if GetFilter("Customer No.") <> '' then begin
                if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then begin
                    ServHeader."Bill-to Customer No." := GetRangeMin("Customer No.");
                    ServCheckCreditLimit.ServiceHeaderCheck(ServHeader);
                end
            end else
                if GetFilter("Contact No.") <> '' then
                    if GetRangeMin("Contact No.") = GetRangeMax("Contact No.") then begin
                        Cont.Get(GetRangeMin("Contact No."));
                        if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
                            ServHeader."Bill-to Customer No." := ContBusinessRelation."No.";
                            ServCheckCreditLimit.ServiceHeaderCheck(ServHeader);
                        end;
                    end;
    end;

    /// <summary>
    /// Updates service order change log based on changes done to the current service header record.
    /// </summary>
    /// <param name="OldServHeader">Source service header record. </param>
    procedure UpdateServiceOrderChangeLog(var OldServHeader: Record "Service Header")
    begin
        if Status <> OldServHeader.Status then
            ServLogMgt.ServHeaderStatusChange(Rec, OldServHeader);

        if "Customer No." <> OldServHeader."Customer No." then
            ServLogMgt.ServHeaderCustomerChange(Rec, OldServHeader);

        if "Ship-to Code" <> OldServHeader."Ship-to Code" then
            ServLogMgt.ServHeaderShiptoChange(Rec, OldServHeader);

        if "Contract No." <> OldServHeader."Contract No." then
            ServLogMgt.ServHeaderContractNoChanged(Rec, OldServHeader);

        OnAfterUpdateServiceOrderChangeLog(Rec, OldServHeader);
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        GetServiceMgtSetup();
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, ServiceMgtSetup, PostingNos, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            GenJournalTemplate.Get("Journal Templ. Name");
            PostingNos := GenJournalTemplate."Posting No. Series";
        end else
            if "Document Type" in ["Document Type"::"Credit Memo"] then
                PostingNos := ServiceMgtSetup."Posted Serv. Credit Memo Nos."
            else
                PostingNos := ServiceMgtSetup."Posted Service Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure CheckDocumentTypeAlreadyUsed()
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentTypeAlreadyUsed(Rec, ServiceShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            ServiceShipmentHeader.SetRange("Order No.", "No.");
            if not ServiceShipmentHeader.IsEmpty() then
                Error(Text008, Format("Document Type"), FieldCaption("No."), "No.");
        end;
    end;

    /// <summary>
    /// Initialize values for the new service header record.
    /// </summary>
    procedure InitInsert()
    var
        IsHandled: Boolean;
    begin
        GetServiceMgtSetup();

        IsHandled := false;
        OnInitInsertOnBeforeInitSeries(Rec, xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                "No. Series" := GetNoSeriesCode();
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
            end;

        CheckDocumentTypeAlreadyUsed();
        OnInsertOnBeforeInitRecord(Rec, xRec);
        InitRecord();
    end;

    /// <summary>
    /// Initialize values for the new service header record.
    /// </summary>
    procedure InitRecord()
    var
        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
    begin
        GetServiceMgtSetup();
        GeneralLedgerSetup.GetRecordOnce();
        SetDefaultNoSeries();

        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote] then begin
            "Order Date" := WorkDate();
            "Order Time" := Time;
        end;

        InitPostingDate();

        "Default Response Time (Hours)" := ServiceMgtSetup."Default Response Time (Hours)";
        "Link Service to Service Item" := ServiceMgtSetup."Link Service to Service Item";

        InitVATDate();

        if Cust.Get("Customer No.") then
            Validate("Location Code", UserSetupMgt.GetLocation(2, Cust."Location Code", "Responsibility Center"));
        OnInitRecordOnAfterValidateLocationCode(Rec, xRec);

        if "Document Type" in ["Document Type"::"Credit Memo"] then begin
            GeneralLedgerSetup.GetRecordOnce();
            Correction := GeneralLedgerSetup."Mark Cr. Memos as Corrections";
        end;

        "Posting Description" := Format("Document Type") + ' ' + "No.";

        Reserve := Reserve::Optional;

        SetResponsibilityCenter();

        "Doc. No. Occurrence" := ServiceDocumentArchiveMgmt.GetNextOccurrenceNo(DATABASE::"Service Header", Rec."Document Type", Rec."No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure SetResponsibilityCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetResponsibilityCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if Cust.Get("Customer No.") then
            if Cust."Responsibility Center" <> '' then
                "Responsibility Center" := UserSetupMgt.GetRespCenter(2, Cust."Responsibility Center")
            else
                "Responsibility Center" := UserSetupMgt.GetRespCenter(2, "Responsibility Center")
        else
            "Responsibility Center" := UserSetupMgt.GetServiceFilter();
    end;

    local procedure InitPostingDate()
    begin
        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();

        if "Document Date" = 0D then
            "Document Date" := WorkDate();

        OnAfterInitPostingDate(Rec);
    end;

    local procedure InitVATDate()
    begin
        "VAT Reporting Date" := GeneralLedgerSetup.GetVATDate("Posting Date", "Document Date");
    end;

    local procedure SetDefaultNoSeries()
    var
        PostingNoSeries: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultNoSeries(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Journal templ. Name Mandatory" then begin
            if "Journal Templ. Name" = '' then begin
                if not IsCreditDocType() then
                    GenJournalTemplate.Get(ServiceMgtSetup."Serv. Inv. Template Name")
                else
                    GenJournalTemplate.Get(ServiceMgtSetup."Serv. Cr. Memo Templ. Name");
                "Journal Templ. Name" := GenJournalTemplate.Name;
            end else
                GenJournalTemplate.Get("Journal Templ. Name");
            PostingNoSeries := GenJournalTemplate."Posting No. Series";
        end else
            if IsCreditDocType() then
                PostingNoSeries := ServiceMgtSetup."Posted Serv. Credit Memo Nos."
            else
                PostingNoSeries := ServiceMgtSetup."Posted Service Invoice Nos.";

        case "Document Type" of
            "Document Type"::Quote, "Document Type"::Order:
                begin
                    if NoSeries.IsAutomatic(PostingNoSeries) then
                        "Posting No. Series" := PostingNoSeries;
                    if NoSeries.IsAutomatic(ServiceMgtSetup."Posted Service Shipment Nos.") then
                        "Shipping No. Series" := ServiceMgtSetup."Posted Service Shipment Nos.";
                end;
            "Document Type"::Invoice:
                begin
                    if ("No. Series" <> '') and (ServiceMgtSetup."Service Invoice Nos." = PostingNoSeries) then
                        "Posting No. Series" := "No. Series"
                    else
                        if NoSeries.IsAutomatic(PostingNoSeries) then
                            "Posting No. Series" := PostingNoSeries;
                    if ServiceMgtSetup."Shipment on Invoice" then
                        if NoSeries.IsAutomatic(ServiceMgtSetup."Posted Service Shipment Nos.") then
                            "Shipping No. Series" := ServiceMgtSetup."Posted Service Shipment Nos.";
                end;
            "Document Type"::"Credit Memo":
                if ("No. Series" <> '') and (ServiceMgtSetup."Service Credit Memo Nos." = PostingNoSeries) then
                    "Posting No. Series" := "No. Series"
                else
                    if NoSeries.IsAutomatic(PostingNoSeries) then
                        "Posting No. Series" := PostingNoSeries;
        end;
    end;

    local procedure InitRecordFromContact()
    begin
        Init();
        GetServiceMgtSetup();
        InitRecord();
        "No. Series" := xRec."No. Series";
        if xRec."Shipping No." <> '' then begin
            "Shipping No. Series" := xRec."Shipping No. Series";
            "Shipping No." := xRec."Shipping No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;
    end;

    local procedure GetCust(CustNo: Code[20])
    begin
        if not (("Document Type" = "Document Type"::Quote) and (CustNo = '')) then begin
            if CustNo <> Cust."No." then
                Cust.Get(CustNo);
        end else
            Clear(Cust);
    end;

    procedure SendToPost(CodeunitId: Integer) IsSuccess: Boolean
    var
        TempServLine: Record "Service Line" temporary;
    begin
        exit(SendToPostWithLines(CodeunitId, TempServLine));
    end;

    procedure SendToPostWithLines(CodeunitId: Integer; var TempServLine: Record "Service Line" temporary) IsSuccess: Boolean
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendToPostWithLines(Rec, TempServLine, CodeunitId, IsHandled, IsSuccess);
        if IsHandled then
            exit(IsSuccess);

        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, '');
        if CodeunitId = Codeunit::"Service-Post (Yes/No)" then begin
            ServPostYesNo.SetGlobalServiceHeader(Rec);
            IsSuccess := ServPostYesNo.Run(TempServLine);
            ServPostYesNo.GetGlobalServiceHeader(Rec);
        end else
            IsSuccess := Codeunit.Run(CodeunitId, Rec);

        if not IsSuccess then
            ErrorMessageHandler.ShowErrors();
    end;

    local procedure ShippedServLinesExist(): Boolean
    begin
        ServLine.Reset();
        ServLine.SetRange("Document Type", "Document Type");
        ServLine.SetRange("Document No.", "No.");
        ServLine.SetFilter("Quantity Shipped", '<>0');
        exit(ServLine.Find('-'));
    end;

    local procedure UpdateShipToAddress()
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToAddress(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Credit Memo" then begin
            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                SetShipToAddress(
                  Location.Name, Location."Name 2", Location.Address, Location."Address 2",
                  Location.City, Location."Post Code", Location.County, Location."Country/Region Code");
                "Ship-to Phone" := Location."Phone No.";
                "Ship-to Contact" := Location.Contact;
            end else begin
                CompanyInfo.Get();
                "Ship-to Code" := '';
                SetShipToAddress(
                  CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
                  CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
                  CompanyInfo."Ship-to Country/Region Code");
                "Ship-to Phone" := CompanyInfo."Ship-to Phone No.";
                "Ship-to Contact" := CompanyInfo."Ship-to Contact";
            end;
            "VAT Country/Region Code" := "Country/Region Code";
        end;

        OnAfterUpdateShipToAddress(Rec);
    end;

    /// <summary>
    /// Sets shipment information from provided parameters for the current service header record.
    /// </summary>
    /// <param name="ShipToName">Provided name information. </param>
    /// <param name="ShipToName2">Provided name 2 information. </param>
    /// <param name="ShipToAddress">Provided address information. </param>
    /// <param name="ShipToAddress2">Provided address 2 information. </param>
    /// <param name="ShipToCity">Provided city information. </param>
    /// <param name="ShipToPostCode">Provided post code information. </param>
    /// <param name="ShipToCounty">Provided county information. </param>
    /// <param name="ShipToCountryRegionCode">Provided country/region code information. </param>
    procedure SetShipToAddress(ShipToName: Text[100]; ShipToName2: Text[50]; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        Validate("Ship-to Country/Region Code", ShipToCountryRegionCode);
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
    end;

    /// <summary>
    /// Runs confirmation dialog to confirm deletion of related service document record.
    /// </summary>
    /// <returns>Returns 'true' if delete is confirmed, otherwise 'false'. </returns>
    procedure ConfirmDeletion(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServPost.TestDeleteHeader(Rec, ServShptHeader, ServInvHeader, ServCrMemoHeader);
        if ServShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text053, ServShptHeader."No."), true)
            then
                exit;
        if ServInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text054, ServInvHeader."No."), true)
            then
                exit;
        if ServCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text013, ServCrMemoHeader."No."), true)
            then
                exit;
        exit(true);
    end;

    local procedure CopyReservEntryToTemp(OldServLine: Record "Service Line")
    begin
        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(
          DATABASE::"Service Line", OldServLine."Document Type".AsInteger(), OldServLine."Document No.", OldServLine."Line No.", false);
        if ReservEntry.FindSet() then
            repeat
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until ReservEntry.Next() = 0;
        ReservEntry.DeleteAll();
    end;

    local procedure CopyReservEntryFromTemp(OldServLine: Record "Service Line"; NewSourceRefNo: Integer)
    begin
        TempReservEntry.Reset();
        TempReservEntry.SetSourceFilter(
          DATABASE::"Service Line", OldServLine."Document Type".AsInteger(), OldServLine."Document No.", OldServLine."Line No.", false);
        if TempReservEntry.FindSet() then
            repeat
                ReservEntry := TempReservEntry;
                ReservEntry."Source Ref. No." := NewSourceRefNo;
                if not ReservEntry.Insert() then;
            until TempReservEntry.Next() = 0;
        TempReservEntry.DeleteAll();
    end;

    /// <summary>
    /// Depicts document dimensions for overview. If changes are made, they will be saved to the current record.
    /// </summary>
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDocDimOnBeforeUpdateAllLineDim(Rec, OldDimSetID, CurrFieldNo);
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if ServItemLineExists() or ServLineExists() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ServiceLine: Record "Service Line";
        ServiceShptLine: Record "Service Shipment Line";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "No.");
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();

        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice:
                if ServiceLine.FindSet() then
                    repeat
                        if (ServiceLine.Type = ServiceLine.Type::Item) and (ServiceLine.Quantity <> 0) then
                            if ServiceLine."Shipment No." <> '' then begin
                                ServiceShptLine.SetRange("Document No.", ServiceLine."Shipment No.");
                                ServiceShptLine.SetRange("Line No.", ServiceLine."Shipment Line No.");
                            end else begin
                                ServiceShptLine.SetCurrentKey("Order No.", "Order Line No.");
                                ServiceShptLine.SetRange("Order No.", ServiceLine."Document No.");
                                ServiceShptLine.SetRange("Order Line No.", ServiceLine."Line No.");
                            end;
                        ServiceShptLine.SetRange(Correction, false);
                        if QtyType = QtyType::Invoicing then
                            ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

                        if ServiceShptLine.FindSet() then
                            repeat
                                ServiceShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                if ItemLedgEntry.FindSet() then
                                    repeat
                                        CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                    until ItemLedgEntry.Next() = 0;
                            until ServiceShptLine.Next() = 0;
                    until ServiceLine.Next() = 0;
        end;
        PAGE.RunModal(0, TempValueEntry);
    end;

    local procedure CreateTempAdjmtValueEntries(var TempValueEntry: Record "Value Entry" temporary; ItemLedgEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if ValueEntry.FindSet() then
            repeat
                if ValueEntry.Adjustment then begin
                    TempValueEntry := ValueEntry;
                    if TempValueEntry.Insert() then;
                end;
            until ValueEntry.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('Call CalculateIncDiscForHeader on codeunit "Service-Calc. Discount" directly instead', '27.0')]
    procedure CalcInvDiscForHeader()
    var
        ServiceInvDisc: Codeunit "Service-Calc. Discount";
    begin
        ServiceInvDisc.CalculateIncDiscForHeader(Rec);
    end;
#endif
    procedure SetSecurityFilterOnRespCenter()
    var
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
    end;

#if not CLEAN27
    /// <summary>
    /// Runs page service statistic for current service header record.
    /// </summary>
    /// <remarks>Commit will be triggered. </remarks>
    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    procedure OpenStatistics()
    var
        StatPageID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        CalcInvDiscForHeader();
        Commit();
        StatPageID := Page::"Service Statistics";
        OnOpenStatisticsOnAfterSetStatPageID(Rec, StatPageID);
        SkipStatsPrep := true;
        Page.RunModal(StatPageID, Rec);
        ResetSkipStatisticsPreparationFlag();
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    procedure OpenOrderStatistics()
    var
        ServiceLine: Record "Service Line";
        ServiceLines: Page "Service Lines";
        StatPageID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenOrderStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesReceivablesSetup.GetRecordOnce();
        if SalesReceivablesSetup."Calc. Inv. Discount" then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", "Document Type");
            ServiceLine.SetRange("Document No.", "No.");
            if ServiceLine.FindFirst() then begin
                ServiceLines.SetTableView(ServiceLine);
                ServiceLines.CalcInvDisc(ServiceLine);
                Commit();
            end;
        end;

        StatPageID := Page::"Service Order Statistics";
        OnOpenOrderStatisticsOnAfterSetStatPageID(Rec, StatPageID);
        SkipStatsPrep := true;
        Page.RunModal(StatPageID, Rec);
        ResetSkipStatisticsPreparationFlag();
    end;

    [Obsolete('The statistics action will be replaced with the SOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    procedure SkipStatisticsPreparation(): Boolean
    begin
        exit(SkipStatsPrep)
    end;

    [Obsolete('The statistics action will be replaced with the ServiceOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    procedure ResetSkipStatisticsPreparationFlag()
    begin
        SkipStatsPrep := false;
    end;
#endif
    local procedure CheckMandSalesPersonOrderData(ServiceMgtSetup: Record "Service Mgt. Setup")
    begin
        if ServiceMgtSetup."Salesperson Mandatory" then
            TestField("Salesperson Code", ErrorInfo.Create());

        if "Document Type" = "Document Type"::Order then begin
            if ServiceMgtSetup."Service Order Type Mandatory" and ("Service Order Type" = '') then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            Text018,
                            FieldCaption("Service Order Type"), TableCaption(),
                            FieldCaption("Document Type"), Format("Document Type"),
                            FieldCaption("No."), Format("No.")),
                        true,
                        Rec));
            if ServiceMgtSetup."Service Order Start Mandatory" then begin
                TestField("Starting Date", ErrorInfo.Create());
                TestField("Starting Time", ErrorInfo.Create());
            end;
            if ServiceMgtSetup."Service Order Finish Mandatory" then begin
                TestField("Finishing Date", ErrorInfo.Create());
                TestField("Finishing Time", ErrorInfo.Create());
            end;
            if ServiceMgtSetup."Fault Reason Code Mandatory" and not ValidatingFromLines then begin
                ServItemLine.Reset();
                ServItemLine.SetRange("Document Type", "Document Type");
                ServItemLine.SetRange("Document No.", "No.");
                if ServItemLine.Find('-') then
                    repeat
                        ServItemLine.TestField("Fault Reason Code", ErrorInfo.Create());
                    until ServItemLine.Next() = 0;
            end;
        end;
    end;

    /// <summary>
    /// Sets 'Ship-to' address information from 'ShipToAddr'.
    /// </summary>
    /// <param name="ShipToAddr">Source ship-to address record. </param>
    procedure SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr: Record "Ship-to Address")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr, IsHandled);
        if IsHandled then
            exit;

        SetShipToAddress(
            ShipToAddr.Name, ShipToAddr."Name 2", ShipToAddr.Address, ShipToAddr."Address 2",
            ShipToAddr.City, ShipToAddr."Post Code", ShipToAddr.County, ShipToAddr."Country/Region Code");
        "Ship-to Contact" := ShipToAddr.Contact;
        "Ship-to Phone" := ShipToAddr."Phone No.";
        if ShipToAddr."Location Code" <> '' then
            "Location Code" := ShipToAddr."Location Code";
        "Ship-to Fax No." := ShipToAddr."Fax No.";
        "Ship-to E-Mail" := ShipToAddr."E-Mail";

        Validate("Shipping Agent Code", ShipToAddr."Shipping Agent Code");
        Validate("Shipping Agent Service Code", ShipToAddr."Shipping Agent Service Code");

        if ShipToAddr."Tax Area Code" <> '' then
            "Tax Area Code" := ShipToAddr."Tax Area Code";
        "Tax Liable" := ShipToAddr."Tax Liable";

        OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr);
    end;


    local procedure CopyShipToCustomerAddressFieldsFromCust(var SellToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, IsHandled);
        if IsHandled then
            exit;

        SetShipToAddress(
          SellToCustomer.Name, SellToCustomer."Name 2", SellToCustomer.Address, SellToCustomer."Address 2",
          SellToCustomer.City, SellToCustomer."Post Code", SellToCustomer.County, SellToCustomer."Country/Region Code");
        "Ship-to Contact" := SellToCustomer.Contact;
        "Ship-to Phone" := SellToCustomer."Phone No.";
        "Tax Area Code" := SellToCustomer."Tax Area Code";
        "Tax Liable" := SellToCustomer."Tax Liable";
        if SellToCustomer."Location Code" <> '' then
            "Location Code" := SellToCustomer."Location Code";
        "Ship-to Fax No." := SellToCustomer."Fax No.";
        "Ship-to E-Mail" := SellToCustomer."E-Mail";

        Validate("Shipping Agent Code", SellToCustomer."Shipping Agent Code");
        Validate("Shipping Agent Service Code", SellToCustomer."Shipping Agent Service Code");

        OnAfterCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer);
    end;

    local procedure CopyAppliestoFieldsFromCustLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        "Applies-to Doc. Type" := CustLedgerEntry."Document Type";
        "Applies-to Doc. No." := CustLedgerEntry."Document No.";

        OnAfterCopyAppliestoFieldsFromCustLedgerEntry(Rec, CustLedgerEntry);
    end;

    procedure WhsePickConflict(DocType: Enum "Service Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ServiceLine: Record "Service Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocType);
        WarehouseActivityLine.SetRange("Source No.", DocNo);
        if WarehouseActivityLine.IsEmpty() then
            exit(false);
        ServiceLine.SetRange("Document Type", DocType);
        ServiceLine.SetRange("Document No.", DocNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        if ServiceLine.IsEmpty() then
            exit(false);
        exit(true);
    end;

    procedure InvPickConflictResolutionTxt(): Text[500]
    begin
        exit(StrSubstNo(Text062, TableCaption(), FieldCaption("Shipping Advice"), Format("Shipping Advice")));
    end;

    procedure WhseShipmentConflict(DocType: Enum "Service Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", DocType);
        WarehouseShipmentLine.SetRange("Source No.", DocNo);
        if WarehouseShipmentLine.IsEmpty() then
            exit(false);
        exit(true);
    end;

    procedure WhseShpmtConflictResolutionTxt(): Text[500]
    begin
        exit(StrSubstNo(Text063, TableCaption(), FieldCaption("Shipping Advice"), Format("Shipping Advice")));
    end;

    local procedure GetShippingTime(CalledByFieldNo: Integer)
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        if (CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0) then
            exit;

        ShippingAgentServices.SetLoadFields("Shipping Time");
        if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
            "Shipping Time" := ShippingAgentServices."Shipping Time"
        else begin
            GetCust("Customer No.");
            "Shipping Time" := Cust."Shipping Time"
        end;
        if not (CalledByFieldNo in [FieldNo("Shipping Agent Code"), FieldNo("Shipping Agent Service Code")]) then
            Validate("Shipping Time");
    end;

    local procedure CheckHeaderDimension()
    begin
        if ("Contract No." <> '') and ("Document Type" = "Document Type"::Invoice) then
            Error(Text066);
    end;

    local procedure CreateServiceLines(var TempServLine: Record "Service Line" temporary; var ExtendedTextAdded: Boolean; var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        ServLine.Init();
        ServLine."Line No." := 0;
        TempServLine.Find('-');
        ExtendedTextAdded := false;

        repeat
            if TempServLine."Attached to Line No." = 0 then begin
                ServLine.Init();
                ServLine.SetHideReplacementDialog(true);
                ServLine.SetHideCostWarning(true);
                ServLine."Line No." := ServLine."Line No." + 10000;
                ServLine."Price Calculation Method" := "Price Calculation Method";
                ServLine.Validate(Type, TempServLine.Type);
                if TempServLine."No." <> '' then begin
                    ServLine.Validate("No.", TempServLine."No.");
                    if ServLine.Type <> ServLine.Type::" " then begin
                        ServLine.Validate("Unit of Measure Code", TempServLine."Unit of Measure Code");
                        ServLine.Validate("Variant Code", TempServLine."Variant Code");
                        if TempServLine.Quantity <> 0 then
                            ServLine.Validate(Quantity, TempServLine.Quantity);
                    end;
                end;

                ServLine."Serv. Price Adjmt. Gr. Code" := TempServLine."Serv. Price Adjmt. Gr. Code";
                ServLine."Document No." := TempServLine."Document No.";
                ServLine."Service Item No." := TempServLine."Service Item No.";
                ServLine."Appl.-to Service Entry" := TempServLine."Appl.-to Service Entry";
                ServLine."Service Item Line No." := TempServLine."Service Item Line No.";
                ServLine.Validate(Description, TempServLine.Description);
                ServLine.Validate("Description 2", TempServLine."Description 2");

                if TempServLine."No." <> '' then begin
                    TempLinkToServItem := "Link Service to Service Item";
                    if "Link Service to Service Item" then begin
                        "Link Service to Service Item" := false;
                        Modify(true);
                    end;
                    ServLine."Spare Part Action" := TempServLine."Spare Part Action";
                    ServLine."Component Line No." := TempServLine."Component Line No.";
                    ServLine."Replaced Item No." := TempServLine."Replaced Item No.";
                    ServLine.Validate("Work Type Code", TempServLine."Work Type Code");

                    ServLine."Location Code" := TempServLine."Location Code";
                    if ServLine.Type <> ServLine.Type::" " then begin
                        if ServLine.Type = ServLine.Type::Item then begin
                            ServLine.Validate("Variant Code", TempServLine."Variant Code");
                            if ServLine."Location Code" <> '' then
                                ServLine."Bin Code" := TempServLine."Bin Code";
                        end;
                        ServLine."Fault Reason Code" := TempServLine."Fault Reason Code";
                        ServLine."Exclude Warranty" := TempServLine."Exclude Warranty";
                        ServLine."Exclude Contract Discount" := TempServLine."Exclude Contract Discount";
                        ServLine.Validate("Contract No.", TempServLine."Contract No.");
                        ServLine.Validate(Warranty, TempServLine.Warranty);
                    end;
                    ServLine."Fault Area Code" := TempServLine."Fault Area Code";
                    ServLine."Symptom Code" := TempServLine."Symptom Code";
                    ServLine."Resolution Code" := TempServLine."Resolution Code";
                    ServLine."Fault Code" := TempServLine."Fault Code";
                    ServLine.Validate("Dimension Set ID", TempServLine."Dimension Set ID");
                end;
                "Link Service to Service Item" := TempLinkToServItem;

                OnBeforeInsertServLineOnServLineRecreation(ServLine, TempServLine);
                ServLine.Insert();
                ExtendedTextAdded := false;
            end else
                if not ExtendedTextAdded then begin
                    ServiceTransferExtText.ServCheckIfAnyExtText(ServLine, true);
                    ServiceTransferExtText.InsertServExtText(ServLine);
                    OnAfterTransferExtendedTextForServLineRecreation(ServLine);
                    ServLine.Find('+');
                    ExtendedTextAdded := true;
                end;
            RestoreServiceCommentLine(TempServiceCommentLine, TempServLine."Line No.", ServLine."Line No.");
            OnCreateServiceLinesOnBeforeCopyReservEntryFromTemp(ServLine, TempServLine, Rec, xRec);
            CopyReservEntryFromTemp(TempServLine, ServLine."Line No.");
        until TempServLine.Next() = 0;
        RestoreServiceCommentLine(TempServiceCommentLine, 0, 0);
    end;

    procedure SetCustomerFromFilter()
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := GetFilterCustNo();
        if CustomerNo = '' then begin
            FilterGroup(2);
            CustomerNo := GetFilterCustNo();
            FilterGroup(0);
        end;
        if CustomerNo <> '' then
            Validate("Customer No.", CustomerNo);

        OnAfterSetCustomerFromFilter(Rec);
    end;

    local procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;

    local procedure UpdateShipToAddressFromGeneralAddress(FieldNumber: Integer)
    begin
        if ("Ship-to Code" <> '') or ShipToAddressModified() then
            exit;

        case FieldNumber of
            FieldNo("Ship-to Address"):
                if xRec.Address = "Ship-to Address" then
                    "Ship-to Address" := Address;
            FieldNo("Ship-to Address 2"):
                if xRec."Address 2" = "Ship-to Address 2" then
                    "Ship-to Address 2" := "Address 2";
            FieldNo("Ship-to City"), FieldNo("Ship-to Post Code"):
                begin
                    if xRec.City = "Ship-to City" then
                        "Ship-to City" := City;
                    if xRec."Post Code" = "Ship-to Post Code" then
                        "Ship-to Post Code" := "Post Code";
                    if xRec.County = "Ship-to County" then
                        "Ship-to County" := County;
                    if xRec."Country/Region Code" = "Ship-to Country/Region Code" then
                        "Ship-to Country/Region Code" := "Country/Region Code";
                end;
            FieldNo("Ship-to County"):
                if xRec.County = "Ship-to County" then
                    "Ship-to County" := County;
            FieldNo("Ship-to Country/Region Code"):
                if xRec."Country/Region Code" = "Ship-to Country/Region Code" then
                    "Ship-to Country/Region Code" := "Country/Region Code";
            Rec.FieldNo("Ship-to Phone"):
                if xRec."Phone No." = "Ship-to Phone" then
                    "Ship-to Phone" := "Phone No.";
            Rec.FieldNo("Ship-to Phone 2"):
                if xRec."Phone No. 2" = "Ship-to Phone 2" then
                    "Ship-to Phone 2" := "Phone No. 2";
        end;
        OnAfterUpdateShipToAddressFromGeneralAddress(Rec, xRec, FieldNumber);
    end;

    procedure CopyCustomerFilter()
    var
        CustomerFilter: Text;
    begin
        CustomerFilter := GetFilter("Customer No.");
        if CustomerFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Customer No.", CustomerFilter);
            FilterGroup(0)
        end;
    end;

    /// <summary>
    /// Transfers relevant field values from provided customer to the current service header record.
    /// </summary>
    /// <param name="Cust">Source customer record. </param>
    local procedure CopyCustomerFields(Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyCustomerFields(Rec, Cust, SkipContact, SkipBillToContact, IsHandled);
        if IsHandled then
            exit;

        Name := Cust.Name;
        "Name 2" := Cust."Name 2";
        Address := Cust.Address;
        "Address 2" := Cust."Address 2";
        City := Cust.City;
        "Post Code" := Cust."Post Code";
        County := Cust.County;
        "Country/Region Code" := Cust."Country/Region Code";
        "VAT Country/Region Code" := "Country/Region Code";
        if not SkipContact then begin
            "Contact Name" := Cust.Contact;
            "Phone No." := Cust."Phone No.";
            "E-Mail" := Cust."E-Mail";
        end;
        "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
        "Tax Area Code" := Cust."Tax Area Code";
        "Tax Liable" := Cust."Tax Liable";
        "VAT Registration No." := Cust.GetVATRegistrationNo();
        "Shipping Advice" := Cust."Shipping Advice";
        "Responsibility Center" := UserSetupMgt.GetRespCenter(2, Cust."Responsibility Center");
        Validate("Location Code", UserSetupMgt.GetLocation(2, Cust."Location Code", "Responsibility Center"));

        OnAfterCopyCustomerFields(Rec, Cust);
    end;

    local procedure CopyBillToCustomerFields(Cust: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyBillToCustFields(Rec, Cust, SkipBillToContact, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        "Bill-to Name" := Cust.Name;
        "Bill-to Name 2" := Cust."Name 2";
        "Bill-to Address" := Cust.Address;
        "Bill-to Address 2" := Cust."Address 2";
        "Bill-to City" := Cust.City;
        "Bill-to Post Code" := Cust."Post Code";
        "Bill-to County" := Cust.County;
        "Bill-to Country/Region Code" := Cust."Country/Region Code";
        if not SkipBillToContact then
            "Bill-to Contact" := Cust.Contact;
        "Payment Terms Code" := Cust."Payment Terms Code";
        if "Document Type" = "Document Type"::"Credit Memo" then begin
            "Payment Method Code" := '';
            if PaymentTerms.Get("Payment Terms Code") then
                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                    "Payment Method Code" := Cust."Payment Method Code"
        end else
            "Payment Method Code" := Cust."Payment Method Code";
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Bill-to/Sell-to VAT Calc." = GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No." then begin
            "VAT Bus. Posting Group" := Cust."VAT Bus. Posting Group";
            "VAT Registration No." := Cust.GetVATRegistrationNo();
            "VAT Country/Region Code" := Cust."Country/Region Code";
            "Gen. Bus. Posting Group" := Cust."Gen. Bus. Posting Group";
        end;
        "Customer Posting Group" := Cust."Customer Posting Group";
        "Currency Code" := Cust."Currency Code";
        "Customer Price Group" := Cust."Customer Price Group";
        "Prices Including VAT" := Cust."Prices Including VAT";
        "Price Calculation Method" := Cust.GetPriceCalculationMethod();
        "Allow Line Disc." := Cust."Allow Line Disc.";
        "Invoice Disc. Code" := Cust."Invoice Disc. Code";
        "Customer Disc. Group" := Cust."Customer Disc. Group";
        "Language Code" := Cust."Language Code";
        "Format Region" := Cust."Format Region";
        SetSalespersonCode(Cust."Salesperson Code", "Salesperson Code");
        Reserve := Cust.Reserve;
        "Combine Shipments" := Cust."Combine Service Shipments";

        OnAfterCopyBillToCustomerFields(Rec, Cust, SkipBillToContact);
    end;

    local procedure ShipToAddressModified(): Boolean
    begin
        if (xRec.Address <> "Ship-to Address") or
           (xRec."Address 2" <> "Ship-to Address 2") or
           (xRec.City <> "Ship-to City") or
           (xRec.County <> "Ship-to County") or
           (xRec."Post Code" <> "Ship-to Post Code") or
           (xRec."Country/Region Code" <> "Ship-to Country/Region Code")
        then
            exit(true);
        exit(false);
    end;

    local procedure GetShipmentMethodCode()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        if "Ship-to Code" <> '' then begin
            ShipToAddress.SetLoadFields("Shipment Method Code");
            ShipToAddress.Get("Customer No.", "Ship-to Code");
            if ShipToAddress."Shipment Method Code" <> '' then begin
                Validate("Shipment Method Code", ShipToAddress."Shipment Method Code");
                exit;
            end;
        end;

        if "Customer No." <> '' then begin
            GetCust("Customer No.");
            Validate("Shipment Method Code", Cust."Shipment Method Code");
        end;
    end;

    procedure ConfirmCloseUnposted(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if ServLineExists() or ServItemLineExists() then
            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode()));
        exit(true)
    end;

    local procedure ConfirmChangeContractNo(): Boolean
    var
        ServContractLine: Record "Service Contract Line";
        ConfirmManagement: Codeunit "Confirm Management";
        Confirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateContractNo(Rec, Confirmed, HideValidationDialog, IsHandled);
        if IsHandled then
            exit(Confirmed);

        Confirmed :=
          ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(
              Text029, ServContractLine.FieldCaption("Next Planned Service Date"),
              ServContractLine.TableCaption(), FieldCaption("Contract No.")), true);

        exit(Confirmed);
    end;

    local procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSalesperson(Rec, IsHandled);
        if IsHandled then
            exit;

        if not UserSetup.Get(UserId) then
            exit;

        if UserSetup."Salespers./Purch. Code" <> '' then
            Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    local procedure SetCompanyBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        Validate("Company Bank Account Code", BankAccount.GetDefaultBankAccountNoForCurrency("Currency Code"));
        OnAfterSetCompanyBankAccount(Rec, xRec);
    end;

    procedure ValidateSalesPersonOnServiceHeader(ServiceHeader2: Record "Service Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if ServiceHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(ServiceHeader2."Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then begin
                    if IsTransaction then
                        Error(
                            ErrorInfo.Create(
                                Salesperson.GetPrivacyBlockedTransactionText(Salesperson, IsPostAction, true),
                                true,
                                Salesperson));
                    if not IsTransaction then
                        Error(
                            ErrorInfo.Create(
                                Salesperson.GetPrivacyBlockedGenericText(Salesperson, true),
                                true,
                                Salesperson));
                end;
    end;

    procedure UpdateShipToSalespersonCode()
    var
        ShipToAddress: Record "Ship-to Address";
        SalespersonCode: Code[20];
        IsHandled: Boolean;
        IsSalesPersonCodeAssigned: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToSalespersonCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Ship-to Code" <> '' then begin
            ShipToAddress.SetLoadFields("Salesperson Code");
            ShipToAddress.Get("Customer No.", "Ship-to Code");
            if ShipToAddress."Salesperson Code" <> '' then begin
                SetSalespersonCode(ShipToAddress."Salesperson Code", SalespersonCode);
                Validate("Salesperson Code", SalespersonCode);
                IsSalesPersonCodeAssigned := true;
            end;
        end;

        if not IsSalesPersonCodeAssigned then begin
            IsHandled := false;
            OnUpdateShiptoSalespersonCodeNotAssigned(Rec, IsHandled);
            if not IsHandled then
                if ("Bill-to Customer No." <> '') then begin
                    GetCust("Bill-to Customer No.");
                    SetSalespersonCode(Cust."Salesperson Code", SalespersonCode);
                    Validate("Salesperson Code", SalespersonCode);
                    if Rec."Customer No." <> '' then
                        GetCust(Rec."Customer No.");
                end else
                    SetDefaultSalesperson();
        end;
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

    local procedure RevertCurrencyCodeAndPostingDate()
    begin
        "Currency Code" := xRec."Currency Code";
        "Posting Date" := xRec."Posting Date";
        Modify();
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    /// <summary>
    /// Gets document type for current service header record.
    /// </summary>
    /// <returns>Returns one of full names of document types 'Service Quote', 'Service Order', 'Service Invoice', 'Service Credit Memo'. </returns>
    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type".AsInteger() + 1, FullServiceTypesTxt);
    end;

    local procedure ConfirmRecalculatePrice() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRecalculatePrice(Rec, HideValidationDialog, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text055, FieldCaption("Prices Including VAT"), ServLine.FieldCaption("Unit Price")), true);
    end;

    local procedure ConfirmRecreateServLines(ChangedFieldName: Text[100]) Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRecreateServLines(Rec, xRec, ChangedFieldName, HideValidationDialog, Result, IsHandled);
        if IsHandled then
            exit;

        if HideValidationDialog or not GuiAllowed() then
            Result := true
        else
            Result := ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012, ChangedFieldName), true);
    end;

    /// <summary>
    /// Gets the value for the global variable 'ServiceMgtSetup'.
    /// </summary>
    procedure GetServiceMgtSetup()
    begin
        ServiceMgtSetup.GetRecordOnce();

        OnAfterGetServiceMgtSetup(ServiceMgtSetup, Rec, CurrFieldNo);
    end;

    local procedure CheckCustomerPostingGroupChange()
    var
        BilltoCustomer: Record Customer;
        PostingGroupChangeInterface: Interface "Posting Group Change Method";
        IsHandled: Boolean;
    begin
        OnBeforeCheckCustomerPostingGroupChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;
        if ("Customer Posting Group" <> xRec."Customer Posting Group") and (xRec."Customer Posting Group" <> '') then begin
            TestField("Bill-to Customer No.");
            BillToCustomer.Get("Bill-to Customer No.");
            GetServiceMgtSetup();
            if ServiceMgtSetup."Allow Multiple Posting Groups" then begin
                BillToCustomer.TestField("Allow Multiple Posting Groups");
                PostingGroupChangeInterface := ServiceMgtSetup."Check Multiple Posting Groups";
                PostingGroupChangeInterface.ChangePostingGroup("Customer Posting Group", xRec."Customer Posting Group", Rec);
            end;
        end;
    end;

    procedure CheckBusPostingGroups(): Boolean
    var
        ApplicationAreaMgmt: Codeunit System.Environment.Configuration."Application Area Mgmt.";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBusPostingGroups(Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(not ApplicationAreaMgmt.IsSalesTaxEnabled());
    end;

    /// <summary>
    /// Checks if the current service header field 'Type' value is 'Credit Memo'.
    /// </summary>
    /// <returns>Returns 'true' if value of field 'Type' from current service header is 'Credit Memo', otherwise 'false'. </returns>
    procedure IsCreditDocType(): Boolean
    begin
        exit("Document Type" = "Document Type"::"Credit Memo");
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
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Contract Header", Rec."Contract No.", FieldNo = Rec.FieldNo("Contract No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Service Order Type", Rec."Service Order Type", FieldNo = Rec.FieldNo("Service Order Type"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    procedure ServiceLinesEditable() IsEditable: Boolean;
    begin
        IsEditable := Rec."Customer No." <> '';

        OnAfterServiceLinesEditable(Rec, IsEditable);
    end;

    internal procedure PerformManualRelease()
    var
        ReleaseServiceDoc: Codeunit "Release Service Document";
    begin
        if Rec."Release Status" <> Rec."Release Status"::"Released to Ship" then begin
            ReleaseServiceDoc.PerformManualRelease(Rec);
            Commit();
        end;
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := ServiceLineReserve.GetReservedQtyFromInventory(Rec);
        if QtyReservedFromStock = 0 then
            exit(Result::None);

        if QtyReservedFromStock = CalculateReservableOutstandingQuantityBase() then
            exit(Result::Full);

        exit(Result::Partial);
    end;

    local procedure CalculateReservableOutstandingQuantityBase() OutstandingQtyBase: Decimal
    var
        RemQtyBaseInvtItemServiceLine: Query RemQtyBaseInvtItemServiceLine;
    begin
        RemQtyBaseInvtItemServiceLine.SetServiceLineFilter(Rec);
        if RemQtyBaseInvtItemServiceLine.Open() then
            if RemQtyBaseInvtItemServiceLine.Read() then
                OutstandingQtyBase := RemQtyBaseInvtItemServiceLine.Outstanding_Qty___Base_;
        RemQtyBaseInvtItemServiceLine.Close();
    end;

    local procedure PrepareDeleteServiceInvoice()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLine: Record "Service Line";
        ServLedgEntriesPost: Codeunit "ServLedgEntries-Post";
        ServContractMgt: Codeunit ServContractManagement;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Invoice);
        ServiceLine.SetRange("Document No.", Rec."No.");
        ServiceLine.SetFilter("Appl.-to Service Entry", '>%1', 0);
        if ServiceLine.IsEmpty() then
            exit;

        if not ConfirmManagement.GetResponseOrDefault(RestoreInvoiceDatesOnDeleteInvQst, false) then
            exit;

        if not ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, Rec."Contract No.") then
            exit;

        CheckServiceLedgerEntriesCanBeReversed(Rec."Contract No.", Rec."No.");

        ServLedgEntriesPost.UnapplyOpenServiceLines(ServiceLine);

        ServiceContractHeader.SuspendStatusCheck(true);
        if not RestoreServiceContractDates(ServiceContractHeader) then
            Error(CannotRestoreInvoiceDatesErr);
        ServiceContractHeader.Modify(true);

        ServContractMgt.FilterServiceContractLine(ServiceContractLine, ServiceContractHeader."Contract No.", ServiceContractHeader."Contract Type", 0);
        ServiceContractLine.SetFilter(
          "Starting Date", '<=%1|%2..%3', ServiceContractHeader."Next Invoice Date",
          ServiceContractHeader."Next Invoice Period Start", ServiceContractHeader."Next Invoice Period End");
        if ServiceContractLine.FindSet() then
            repeat
                if ServiceContractHeader."Last Invoice Date" = 0D then
                    ServiceContractLine."Invoiced to Date" := 0D
                else
                    ServContractMgt.CalcInvoicedToDate(ServiceContractLine, ServiceContractLine."Starting Date", ServiceContractHeader."Next Invoice Period Start" - 1);
                ServiceContractLine.Modify(true);
            until ServiceContractLine.Next() = 0;
    end;

    local procedure CheckServiceLedgerEntriesCanBeReversed(ContractNo: Code[20]; ServiceInvoiceNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        LastPostingDate: Date;
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetLoadFields("Posting Date");
        ServiceLedgerEntry.SetCurrentKey("Service Contract No.", "Posting Date");
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::" ");
        ServiceLedgerEntry.SetRange("Document No.", ServiceInvoiceNo);
        ServiceLedgerEntry.SetRange(Open, false);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeletePostedInvoiceErr);

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.FindLast();
        LastPostingDate := ServiceLedgerEntry."Posting Date";

        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetCurrentKey("Service Contract No.", "Posting Date");
        ServiceLedgerEntry.SetRange("Service Contract No.", ContractNo);
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Invoice);
        ServiceLedgerEntry.SetFilter("Posting Date", '>%1', LastPostingDate);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteWhenNextInvPostedErr);

        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::" ");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteWhenNextInvExistsErr);
    end;

    local procedure RestoreServiceContractDates(var ServiceContractHeader: Record "Service Contract Header"): Boolean
    var
        ServDocReg: Record "Service Document Register";
    begin
        if not ServDocReg.Get(
              ServDocReg."Source Document Type"::Contract, ServiceContractHeader."Contract No.",
              ServDocReg."Destination Document Type"::Invoice, Rec."No.")
        then
            exit(false);

        if (ServDocReg."Next Invoice Date" = 0D) and (ServDocReg."Last Invoice Date" = 0D) then
            exit(false);

        if ServDocReg."Invoice Period" <> ServiceContractHeader."Invoice Period" then
            Error(InvoicePeriodChangedErr);

        ServiceContractHeader."Last Invoice Date" := ServDocReg."Last Invoice Date";
        ServiceContractHeader."Next Invoice Date" := ServDocReg."Next Invoice Date";
        ServiceContractHeader."Next Invoice Period Start" := ServDocReg."Next Invoice Period Start";
        ServiceContractHeader."Next Invoice Period End" := ServDocReg."Next Invoice Period End";
        if ServiceContractHeader.Prepaid then
            ServiceContractHeader."Last Invoice Period End" := ServiceContractHeader."Next Invoice Date" - 1;

        ServiceContractHeader.CalcFields("No. of Posted Invoices", "No. of Unposted Invoices");
        if (ServiceContractHeader."No. of Posted Invoices" = 0) and (ServiceContractHeader."No. of Unposted Invoices" = 1) then
            ServiceContractHeader."Last Invoice Date" := 0D;

        if ServiceContractHeader."Last Invoice Date" = 0D then
            ServiceContractHeader."Last Invoice Period End" := 0D;

        exit(true);
    end;

    /// <summary>
    /// Transfers relevant field values from current service header to the provided general journal line.
    /// </summary>
    /// <param name="GenJournalLine">Destination general journal line. </param>
    procedure CopyToGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Source Currency Code" := "Currency Code";
        GenJournalLine.Correction := Correction;
        GenJournalLine."VAT Base Discount %" := "VAT Base Discount %";
        GenJournalLine."Sell-to/Buy-from No." := "Customer No.";
        GenJournalLine."Bill-to/Pay-to No." := "Bill-to Customer No.";
        GenJournalLine."Country/Region Code" := "VAT Country/Region Code";
        GenJournalLine."VAT Registration No." := "VAT Registration No.";
        GenJournalLine."Source Type" := GenJournalLine."Source Type"::Customer;
        GenJournalLine."Source No." := "Bill-to Customer No.";
        GenJournalLine."Posting No. Series" := "Posting No. Series";
        GenJournalLine."Ship-to/Order Address Code" := "Ship-to Code";
        GenJournalLine."EU 3-Party Trade" := "EU 3-Party Trade";
        GenJournalLine."Salespers./Purch. Code" := "Salesperson Code";
        GenJournalLine."Your Reference" := "Your Reference";
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then
            GenJournalLine."Posting Group" := "Customer Posting Group";
        GeneralLedgerSetup.GetRecordOnce();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then
            GenJournalLine."Journal Template Name" := "Journal Templ. Name";

        OnAfterCopyToGenJnlLine(GenJournalLine, Rec);
#if not CLEAN25
        GenJournalLine.RunOnAfterCopyGenJnlLineFromServHeader(Rec, GenJournalLine);
#endif
    end;

    /// <summary>
    /// Transfers apply-to document information from current service header to the provided general journal line.
    /// </summary>
    /// <param name="GenJournalLine">Destination general journal line. </param>
    procedure CopyToGenJournalLineApplyTo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Applies-to Doc. Type" := "Applies-to Doc. Type";
        GenJournalLine."Applies-to Doc. No." := "Applies-to Doc. No.";
        GenJournalLine."Applies-to ID" := "Applies-to ID";
        GenJournalLine."Allow Application" := "Bal. Account No." = '';

        OnAfterCopyToGenJnlLineApplyTo(GenJournalLine, Rec);
#if not CLEAN25
        GenJournalLine.RunOnAfterCopyGenJnlLineFromServHeaderApplyTo(Rec, GenJournalLine);
#endif
    end;

    /// <summary>
    /// Transfers payment information from current service header to the provided general journal line.
    /// </summary>
    /// <param name="GenJournalLine">Destination general journal line. </param>
    procedure CopyToGenJournalLinePayment(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."Due Date" := "Due Date";
        GenJournalLine."Payment Terms Code" := "Payment Terms Code";
        GenJournalLine."Payment Method Code" := "Payment Method Code";
        GenJournalLine."Pmt. Discount Date" := "Pmt. Discount Date";
        GenJournalLine."Payment Discount %" := "Payment Discount %";
        GenJournalLine."Direct Debit Mandate ID" := "Direct Debit Mandate ID";

        OnAfterCopyToGenJnlLinePayment(GenJournalLine, Rec);
#if not CLEAN25
        GenJournalLine.RunOnAfterCopyGenJnlLineFromServHeaderPayment(Rec, GenJournalLine);
#endif
    end;

    /// <summary>
    /// Transfers relevant field values from current service header to the provided item journal line.
    /// </summary>
    /// <param name="ItemJournalLine">Destination general journal line. </param>
    procedure CopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."Document Date" := Rec."Document Date";
        ItemJournalLine."Order Date" := Rec."Order Date";
        ItemJournalLine."Source Posting Group" := Rec."Customer Posting Group";
        ItemJournalLine."Salespers./Purch. Code" := Rec."Salesperson Code";
        ItemJournalLine."Reason Code" := Rec."Reason Code";
        ItemJournalLine."Source Type" := ItemJournalLine."Source Type"::Customer;
        ItemJournalLine."Source No." := Rec."Customer No.";
        ItemJournalLine."Shpt. Method Code" := Rec."Shipment Method Code";
        ItemJournalLine."Price Calculation Method" := Rec."Price Calculation Method";

        if Rec.IsCreditDocType() then
            ItemJournalLine."Country/Region Code" := Rec."Country/Region Code"
        else
            if Rec."Ship-to Country/Region Code" <> '' then
                ItemJournalLine."Country/Region Code" := Rec."Ship-to Country/Region Code"
            else
                ItemJournalLine."Country/Region Code" := Rec."Country/Region Code";

        OnAfterCopyToItemJnlLine(ItemJournalLine, Rec);
#if not CLEAN25
        ItemJournalLine.RunOnAfterCopyItemJnlLineFromServHeader(ItemJournalLine, Rec);
#endif
    end;

    procedure CopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line")
    begin
        ResJournalLine."Document Date" := Rec."Document Date";
        ResJournalLine."Reason Code" := Rec."Reason Code";
        ResJournalLine."Order No." := Rec."No.";

        OnAfterCopyToResJournalLine(ResJournalLine, Rec);
#if not CLEAN25
        ResJournalLine.RunOnAfterCopyResJnlLineFromServHeader(Rec, ResJournalLine);
#endif
    end;

    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Work Description");
        Rec."Work Description".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Work Description");
        Rec."Work Description".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Work Description")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ServiceHeader: Record "Service Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLinesEditable(ServiceHeader: Record "Service Header"; var IsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var ServiceHeader: Record "Service Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyFactor(var ServiceHeader: Record "Service Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddress(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStartingDateTime(var ServiceHeader: Record "Service Header"; ValidatingFromLines: Boolean; var ServiceMgtSetup: Record "Service Mgt. Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFinishingDateTime(var ServiceHeader: Record "Service Header"; ValidatingFromLines: Boolean; var ServiceMgtSetup: Record "Service Mgt. Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePriceMsgIfServLinesExist(ServiceHeader: Record "Service Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer; SkipBillToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromCustomer(var ServiceHeader: Record "Service Header"; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var ServiceHeader: Record "Service Header"; ShipToAddress: Record "Ship-to Address")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var ServiceHeader: Record "Service Header"; ServiceMgtSetup: Record "Service Mgt. Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(var ServiceHeader: Record "Service Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompanyBankAccount(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValidatingFromLines(var ServiceHeader: Record "Service Header"; var ValidatingFromLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCont(var ServiceHeader: Record "Service Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServLinesByFieldNo(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddressFromGeneralAddress(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLineByChangedFieldName(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ChangedFieldName: Text[100]; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateServLinesByFieldNoOnAfterServLineSetFilters(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ServiceHeader: Record "Service Header"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCont(var ServiceHeader: Record "Service Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCust(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForServLineRecreation(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBlockedCustomer(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentTypeAlreadyUsed(var ServiceHeader: Record "Service Header"; var ServShptHeader: Record "Service Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateContractNo(var ServiceHeader: Record "Service Header"; var Confirmed: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(var ServiceHeader: Record "Service Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(var ServiceHeader: Record "Service Header"; ShipToAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeries(var ServiceHeader: Record "Service Header"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var ServiceHeader: Record "Service Header"; ServiceMgtSetup: Record "Service Mgt. Setup"; var PostingNos: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var ServiceHeader: Record "Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLineOnServLineRecreation(var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var ServiceHeader: Record "Service Header")
    begin
    end;
#if not CLEAN27
    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenOrderStatistics(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenStatistics(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestMandatoryFields(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeriesManual(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCust(var ServiceHeader: Record "Service Header"; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocNo(var ServiceHeader: Record "Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateServiceZoneCode(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var ServiceHeader: Record "Service Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateCust(ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupContractNoOnAfterServContractHeaderSetFilters(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLinesOnBeforeUpdateLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAppliestoDocNoOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeDeleteLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeModify(var ServiceHeader: Record "Service Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATBaseDiscountPctOnBeforeUpdateLineAmounts(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnAfterCalcRecalculatePrice(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var RecalculatePrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeDeleteLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnAfterCalcShouldUpdateShipToAddressFields(var ServiceHeader: Record "Service Header"; var ShouldUpdateShipToAddressFields: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceDocumentStatusOnAfterServItemLineSetFilters(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServPriceGrOnServItemOnAfterServItemLineSetFilters(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRecalculatePrice(ServiceHeader: Record "Service Header"; var HideValidationDialog: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(var ServiceHeader: Record "Service Header"; SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToSalespersonCode(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShiptoSalespersonCodeNotAssigned(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetResponsibilityCenter(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var ShowPostedDocsToPrint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateServLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRecreateServLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; ChangedFieldName: Text[100]; var HideValidationDialog: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultNoSeries(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOnBeforeInitRecord(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitInsertOnBeforeInitSeries(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnAfterValidateLocationCode(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetServLineNewDimSetID(var ServLine: Record "Service Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetServItemLineNewDimSetID(var ServItemLine: Record "Service Item Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterUpdateBillToContact(var ServiceHeader: Record "Service Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLinesOnAfterServLineSetFilters(var ServLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLinesOnBeforeServLineDeleteAll(var ServiceHeader: Record "Service Header"; var ServLine: Record "Service Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateServLinesOnAfterTempServLineDeleteAll(ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestMandatoryFieldsOnBeforePassedServLineFind(ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; var PassedServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetServiceMgtSetup(var ServSetup: Record "Service Mgt. Setup"; ServiceHeader: Record "Service Header"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeUpdateAllLineDim(var Rec: Record "Service Header"; OldDimSetID: Integer; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoAfterInit(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCity(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToPostCode(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCity(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var ServiceHeader: Record "Service Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeConfirmDeleteLines(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerPostingGroupChange(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeConfirmChange(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateCustomerNoOnBeforeShippedServLinesExist(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateFinishingTimeOnBeforeCheckServItemLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusFinishedOnAferUpdateFinishingDateTime(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateServiceOrderTypeOnBeforeCreateDim(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetResponse(var ServiceHeader: Record "Service Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateAssignedUserIdOnBeforeCheckRespCenter(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeValidateServiceZoneCode(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShiptoCodeBeforeConfirmDialog(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeValidateServiceZoneCode(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateContractNo(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeServItemLineDelete(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHeaderOnBeforeDeleteRelatedRecords(var ServiceHeader: Record "Service Header"; var ServShptHeader: Record "Service Shipment Header"; var ServInvHeader: Record "Service Invoice Header"; var ServCrMemoHeader: Record "Service Cr.Memo Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerNo(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCustomerNoOnBeforeVerifyShipToCode(var ServiceHeader: Record "Service Header"; var SkipBillToContact: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeRecreateServLines(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShortcutDimCodeOnBeforeUpdateUpdateAllLineDim(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; FieldNumber: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupContactNo(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateResponsibilityCenter(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServLinesByFieldNoOnBeforeAskQst(var ServiceHeader: Record "Service Header"; AskQuestion: Boolean; ChangedFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditMaxBeforeInsert(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServiceOrderChangeLog(var ServiceHeader: Record "Service Header"; var OldServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer; var SkipContact: Boolean; var SkipBillToContact: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBillToCustFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer; var SkipBillToContact: Boolean; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetHideValidationDialog(var ServiceHeader: Record "Service Header"; var HideValidationDialog: Boolean; NewHideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExternalDocumentNo(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateServiceLinesOnBeforeCopyReservEntryFromTemp(var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line" temporary; var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesperson(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCustomerFromFilter(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLineApplyTo(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToGenJnlLinePayment(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToResJournalLine(var ResJournalLine: Record "Res. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

#if not CLEAN27
    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnOpenStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
    end;

    [Obsolete('The new statistics actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnOpenOrderStatisticsOnAfterSetStatPageID(var ServiceHeader: Record "Service Header"; var StatPageID: Integer)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeArchiveServiceDocument(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBusPostingGroups(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyAppliestoFieldsFromCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePaymentTerms(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostingDate(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCurrencyFactorOnAfterSetCurrencyDate(var ServiceHeader: Record "Service Header"; var GeneralLedgerSetup: Record "General Ledger Setup"; var CurrencyDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterCheckPostingDate(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterUpdatePostingDateOnLines(var ServiceHeader: Record "Service Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterValidateVATReportingDate(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateDocumentDateOnAfterValidateVATReportingDate(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeShowPostedDocsToPrint(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendToPostWithLines(var ServiceHeader: Record "Service Header"; var TempServiceLine: Record "Service Line" temporary; PostingCodeunitID: Integer; var IsHandled: Boolean; var IsSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingDate(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStartingTime(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFinishingDate(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFinishingTime(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateOrderDate(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateStatus(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateResponseDateTime(var ServiceHeader: Record "Service Header"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterSetFilters(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAppliesToDocNo(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeServiceLineModify(var ServiceLine: Record "Service Line"; var xServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterServiceLineModify(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupAppliesToDocNo(var ServiceHeader: Record "Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;
}