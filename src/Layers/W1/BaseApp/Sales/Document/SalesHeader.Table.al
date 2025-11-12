// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Intercompany;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System;
using System.Automation;
using System.Globalization;
using System.Reflection;
using System.Utilities;
using Microsoft.Foundation.NoSeries;
using System.Threading;
using System.Email;
using System.Security.User;
using System.Environment.Configuration;

table 36 "Sales Header"
{
    Caption = 'Sales Header';
    DataCaptionFields = "No.", "Sell-to Customer Name";
    LookupPageID = "Sales List";
    Permissions = tabledata "Assemble-to-Order Link" = rmid,
                  tabledata "Assembly Header" = m;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you''re selling to. By default, the same customer is suggested as the ship-to customer. If needed, you can specify a different ship-to customer on the document.';
            TableRelation = Customer;

            trigger OnValidate()
            var
                LocationCode: Code[10];
                ShouldSkipConfirmSellToCustomerDialog: Boolean;
                IsHandled: Boolean;
                ConfirmedShouldBeFalse: Boolean;
            begin
                CheckCreditLimitIfLineNotInsertedYet();
                if "No." = '' then
                    InitRecord();
                TestStatusOpen();

                IsHandled := false;
                OnValidateSellToCustomerNoOnAfterTestStatusOpen(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Sell-to Customer No." <> xRec."Sell-to Customer No.") and
                   (xRec."Sell-to Customer No." <> '')
                then begin
                    if ("Opportunity No." <> '') and ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) then
                        Error(
                          Text062,
                          FieldCaption("Sell-to Customer No."),
                          FieldCaption("Opportunity No."),
                          "Opportunity No.",
                          "Document Type");

                    ShouldSkipConfirmSellToCustomerDialog := GetHideValidationDialog() or not GuiAllowed();
                    ConfirmedShouldBeFalse := false;
                    OnValidateSellToCustomerNoOnAfterCalcShouldSkipConfirmSellToCustomerDialog(Rec, ShouldSkipConfirmSellToCustomerDialog, ConfirmedShouldBeFalse);
                    if ShouldSkipConfirmSellToCustomerDialog then
                        Confirmed := true and not ConfirmedShouldBeFalse
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, SellToCustomerTxt);
                    if Confirmed then begin
                        SalesLine.SetRange("Document Type", "Document Type");
                        SalesLine.SetRange("Document No.", "No.");
                        if "Sell-to Customer No." = '' then begin
                            if SalesLine.FindFirst() then
                                Error(
                                  Text005,
                                  FieldCaption("Sell-to Customer No."));
                            Init();
                            OnValidateSellToCustomerNoAfterInit(Rec, xRec);
                            GetSalesSetup();
                            "No. Series" := xRec."No. Series";
                            InitRecord();
                            InitNoSeries();
                            exit;
                        end;

                        CheckShipmentInfo(SalesLine, false);
                        CheckPrepmtInfo(SalesLine);
                        CheckReturnInfo(SalesLine, false);

                        SalesLine.Reset();
                        AltCustVATRegFacade.Init(Rec, xRec);
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Document Type" = "Document Type"::Order) and
                   (xRec."Sell-to Customer No." <> "Sell-to Customer No.")
                then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not SalesLine.IsEmpty() then
                        Error(
                          Text006,
                          FieldCaption("Sell-to Customer No."));
                    SalesLine.Reset();
                end;

                OnValidateSellToCustomerNoOnBeforeGetCust(Rec, xRec);
                GetCust("Sell-to Customer No.");
                IsHandled := false;
                OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Customer, IsHandled);
                if not IsHandled then
                    Customer.CheckBlockedCustOnDocs(Customer, "Document Type", false, false);
                if (not ApplicationAreaMgmt.IsSalesTaxEnabled()) and (Customer."No." <> '') then
                    Customer.TestField("Gen. Bus. Posting Group");
                OnAfterCheckSellToCust(Rec, xRec, Customer, CurrFieldNo);

                CopySellToCustomerAddressFieldsFromCustomer(Customer);

                if "Sell-to Customer No." = xRec."Sell-to Customer No." then
                    if ShippedSalesLinesExist() or ReturnReceiptExist() then begin
                        TestField("VAT Bus. Posting Group", xRec."VAT Bus. Posting Group");
                        TestField("Gen. Bus. Posting Group", xRec."Gen. Bus. Posting Group");
                    end;

                "Sell-to IC Partner Code" := Customer."IC Partner Code";
                "Send IC Document" := ("Sell-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                UpdateShipToCodeFromCust();
                IsHandled := false;
                OnValidateSellToCustomerNoOnBeforeValidateLocationCode(Rec, Customer, IsHandled, xRec, LocationCode);
                if not IsHandled then
                    LocationCode := "Location Code";

                SetBillToCustomerNo(Customer);

                Validate("Location Code", LocationCode);
                GetShippingTime(FieldNo("Sell-to Customer No."));

                SetRcvdFromCountry(Customer."Country/Region Code");

                if (xRec."Sell-to Customer No." <> "Sell-to Customer No.") or
                   (xRec."Currency Code" <> "Currency Code") or
                   (xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") or
                   (xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group")
                then
                    RecreateSalesLines(SellToCustomerTxt);

                if not InsertMode and ("Sell-to Customer No." <> '') then
                    StandardCodesMgtGlobal.CheckCreateSalesRecurringLines(Rec);

                OnValidateSellToCustomerNoOnBeforeUpdateSellToCont(Rec, xRec, Customer, SkipSellToContact);
                if not SkipSellToContact then
                    UpdateSellToCont("Sell-to Customer No.");

                OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(Rec, xRec);
                if (xRec."Sell-to Customer No." <> '') and (xRec."Sell-to Customer No." <> "Sell-to Customer No.") then
                    Rec.RecallModifyAddressNotification(GetModifyCustomerAddressNotificationId());

                if xRec."Sell-to Customer No." <> "Sell-to Customer No." then
                    SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, Rec, true);
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies a unique number that identifies the sales document. The number can be generated automatically from a number series, or you can number each of them manually.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GetSalesSetup();
                    NoSeries.TestManual(GetNoSeriesCode());
                    "No. Series" := '';
                end;
            end;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            var
                IsHandled: Boolean;
                IsHandledDoExist: Boolean;
            begin
                TestStatusOpen();
                BilltoCustomerNoChanged := xRec."Bill-to Customer No." <> "Bill-to Customer No.";

                IsHandled := false;
                OnValidateBillToCustomerNoOnAfterCheckBilltoCustomerNoChanged(Rec, xRec, CurrFieldNo, IsHandled, IsHandledDoExist);
                if IsHandledDoExist then
                    exit;

                if BilltoCustomerNoChanged and not IsHandled then
                    if xRec."Bill-to Customer No." = '' then
                        InitRecord()
                    else
                        if ConfirmBillToCustomerChange() then begin
                            OnValidateBillToCustomerNoOnAfterConfirmed(Rec);

                            SalesLine.SetRange("Document Type", "Document Type");
                            SalesLine.SetRange("Document No.", "No.");

                            CheckShipmentInfo(SalesLine, true);
                            CheckPrepmtInfo(SalesLine);
                            CheckReturnInfo(SalesLine, true);

                            SalesLine.Reset();
                        end else
                            "Bill-to Customer No." := xRec."Bill-to Customer No.";

                GetCust("Bill-to Customer No.");
                IsHandled := false;
                OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(Rec, Customer, IsHandled);
                if not IsHandled then
                    Customer.CheckBlockedCustOnDocs(Customer, "Document Type", false, false);
                if Customer."No." <> '' then
                    Customer.TestField("Customer Posting Group");
                PostingSetupMgt.CheckCustPostingGroupReceivablesAccount("Customer Posting Group");
                CheckCreditLimit();
                OnAfterCheckBillToCust(Rec, xRec, Customer);

                SetBillToCustomerAddressFieldsFromCustomer(Customer);

                if not BilltoCustomerNoChanged then
                    if ShippedSalesLinesExist() then begin
                        TestField("Customer Disc. Group", xRec."Customer Disc. Group");
                        TestField("Currency Code", xRec."Currency Code");
                    end;

                CreateDimensionsFromValidateBillToCustomerNo();

                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");
                Validate("Payment Method Code");
                Validate("Currency Code");
                Validate("Prepayment %");

                if (xRec."Sell-to Customer No." = "Sell-to Customer No.") and
                   (xRec."Bill-to Customer No." <> "Bill-to Customer No.")
                then begin
                    RecreateSalesLines(BillToCustomerTxt);
                    BilltoCustomerNoChanged := false;
                end;
                if not SkipBillToContact then
                    UpdateBillToCont("Bill-to Customer No.");

                "Bill-to IC Partner Code" := Customer."IC Partner Code";
                "Send IC Document" := ("Bill-to IC Partner Code" <> '') and ("IC Direction" = "IC Direction"::Outgoing);

                OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(Rec, xRec);
                if (xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No.") then
                    Rec.RecallModifyAddressNotification(Rec.GetModifyBillToCustomerAddressNotificationId());

                if xRec."Bill-to Customer No." <> "Bill-to Customer No." then
                    SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, Rec, true);
            end;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                OnBeforeValidateBillToCustomerName(Rec, Customer);
                if Rec."Bill-to Name" <> xRec."Bill-to Name" then
                    if ShouldSearchForCustomerByName("Bill-to Customer No.") then
                        Validate("Bill-to Customer No.", Customer.GetCustNo("Bill-to Name"));
            end;
        }
        field(6; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer that you send or sent the invoice or credit memo to.';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
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
                OnBeforeLookupBillToCity(Rec, PostCode);

                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");

                OnAfterLookupBillToCity(Rec, PostCode, xRec);
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
                ModifyBillToCustomerAddress();
            end;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';

            trigger OnLookup()
            var
                Contact: Record Contact;
            begin
                Contact.FilterGroup(2);
                LookupContact("Bill-to Customer No.", "Bill-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Bill-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
        }
        field(12; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Sell-to Customer No."));

            trigger OnValidate()
            var
                ShipToAddr: Record "Ship-to Address";
                IsHandled: Boolean;
                CopyShipToAddress: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipToCode(Rec, xRec, Customer, ShipToAddr, IsHandled);
                if IsHandled then
                    exit;

                if ("Document Type" = "Document Type"::Order) and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Purch. Order Line No.", '<>0');
                    if not SalesLine.IsEmpty() then
                        Error(
                          Text006,
                          FieldCaption("Ship-to Code"));
                    SalesLine.Reset();
                end;

                CopyShipToAddress := not IsCreditDocType();
                OnValidateShipToCodeOnBeforeCopyShipToAddress(Rec, xRec, CopyShipToAddress);
                if CopyShipToAddress then
                    if "Ship-to Code" <> '' then begin
                        if xRec."Ship-to Code" <> '' then begin
                            GetCust("Sell-to Customer No.");
                            SetCustomerLocationCode(Customer);
                            "Tax Area Code" := Customer."Tax Area Code";
                        end;
                        ShipToAddr.Get("Sell-to Customer No.", "Ship-to Code");
                        SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr);
                    end else
                        if "Sell-to Customer No." <> '' then begin
                            GetCust("Sell-to Customer No.");
                            CopyShipToCustomerAddressFieldsFromCust(Customer);
                            AltCustVATRegFacade.CopyFromCustomer(Rec, xRec);
                        end;

                UpdateShipToSalespersonCode(FieldNo("Ship-to Code"));
                GetShipmentMethodCode();
                GetShippingTime(FieldNo("Ship-to Code"));

                if (xRec."Sell-to Customer No." = "Sell-to Customer No.") and
                   (xRec."Ship-to Code" <> "Ship-to Code")
                then
                    if AltCustVATRegFacade.VATDataIsChangedOnShipToCodeValidation(Rec, xRec) or
                       (xRec."Tax Area Code" <> "Tax Area Code")
                    then
                        RecreateSalesLines(FieldCaption("Ship-to Code"))
                    else begin
                        if xRec."Shipping Agent Code" <> "Shipping Agent Code" then
                            MessageIfSalesLinesExist(FieldCaption("Shipping Agent Code"));
                        if xRec."Shipping Agent Service Code" <> "Shipping Agent Service Code" then
                            MessageIfSalesLinesExist(FieldCaption("Shipping Agent Service Code"));
                        OnValidateShipToCodeOnBeforeValidateTaxLiable(Rec, xRec);
                        if xRec."Tax Liable" <> "Tax Liable" then
                            Validate("Tax Liable");
                    end;
            end;
        }
        field(13; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
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
                OnBeforeLookupShipToCity(Rec, PostCode);

                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");

                OnAfterLookupShipToCity(Rec, PostCode, xRec);
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
            ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
        }
        field(19; "Order Date"; Date)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Order Date';

            trigger OnValidate()
            begin
                if ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) and
                   not ("Order Date" = xRec."Order Date")
                then
                    PriceMessageIfSalesLinesExist(FieldCaption("Order Date"));
            end;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when the posting of the sales document will be recorded.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
                NeedUpdateCurrencyFactor: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostingDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Posting Date");
                TestNoSeriesDate(
                  "Posting No.", "Posting No. Series",
                  FieldCaption("Posting No."), FieldCaption("Posting No. Series"));
                TestNoSeriesDate(
                  "Prepayment No.", "Prepayment No. Series",
                  FieldCaption("Prepayment No."), FieldCaption("Prepayment No. Series"));
                TestNoSeriesDate(
                  "Prepmt. Cr. Memo No.", "Prepmt. Cr. Memo No. Series",
                  FieldCaption("Prepmt. Cr. Memo No."), FieldCaption("Prepmt. Cr. Memo No. Series"));

                UpdateVATReportingDate(FieldNo("Posting Date"));
                UpdateDocumentDateFromLinkedPostingDate(true);

                if ("Document Type" in ["Document Type"::Invoice, "Document Type"::"Credit Memo"]) and
                   not ("Posting Date" = xRec."Posting Date")
                then
                    PriceMessageIfSalesLinesExist(FieldCaption("Posting Date"));

                OnValidatePostingDateOnBeforeResetInvoiceDiscountValue(Rec, xRec);
                ResetInvoiceDiscountValue();

                NeedUpdateCurrencyFactor := "Currency Code" <> '';
                OnValidatePostingDateOnBeforeCheckNeedUpdateCurrencyFactor(Rec, Confirmed, NeedUpdateCurrencyFactor, xRec);
                if NeedUpdateCurrencyFactor then begin
                    UpdateCurrencyFactor();
                    if ("Currency Factor" <> xRec."Currency Factor") and not GetCalledFromWhseDoc() then
                        ConfirmCurrencyFactorUpdate();
                end;
                OnValidatePostingDateOnAfterCheckNeedUpdateCurrencyFactor(Rec, xRec, NeedUpdateCurrencyFactor);

                if "Posting Date" <> xRec."Posting Date" then
                    if DeferralHeadersExist() then
                        ConfirmUpdateDeferralDate();
                SynchronizeAsmHeader();
            end;
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentDate(Rec, CurrFieldNo, IsHandled);
                if not IsHandled then
                    UpdateSalesLinesByFieldNo(FieldNo("Shipment Date"), CurrFieldNo <> 0);
            end;
        }
        field(22; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            ToolTip = 'Specifies additional posting information for the document. After you post the document, the description can add detail to vendor and customer ledger entries.';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePaymentTermsCode(Rec, xRec, CurrFieldNo, UpdateDocumentDate, IsHandled);
                if IsHandled then
                    exit;

                if ("Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Payment Terms Code");
                    if IsCreditDocType() and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeValidateDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            Validate("Due Date", "Document Date");
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate and (xRec."Payment Terms Code" <> Rec."Payment Terms Code") then
                            Validate("Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Pmt. Discount Date", 0D);
                        Validate("Payment Discount %", 0);
                    end;
                    OnValidatePaymentTermsCodeOnAfterValidatePaymentDiscountWhenBlank(Rec, xRec, CurrFieldNo);
                end;
                if xRec."Payment Terms Code" = "Prepmt. Payment Terms Code" then begin
                    if xRec."Prepayment Due Date" = 0D then begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then begin
                            TestField("Document Date");
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        end;
                    end;
                    Validate("Prepmt. Payment Terms Code", "Payment Terms Code");
                end;
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies when the sales invoice must be paid.';
        }
        field(25; "Payment Discount %"; Decimal)
        {
            Caption = 'Payment Discount %';
            ToolTip = 'Specifies the payment discount percentage that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePaymentDiscount(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen();
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
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
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            TableRelation = "Shipment Method";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShipmentMethodCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
            end;
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location from where items are to be shipped. This field acts as the default location for new lines. You can update the location code for individual lines as needed.';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLocationCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if ("Location Code" <> xRec."Location Code") and
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                then
                    MessageIfSalesLinesExist(FieldCaption("Location Code"));

                UpdateShipToAddress();
                UpdateOutboundWhseHandlingTime();
                if "Location Code" <> xRec."Location Code" then
                    CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
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
        field(30; "Shortcut Dimension 2 Code"; Code[20])
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
            ToolTip = 'Specifies the currency of amounts on the sales document.';
            TableRelation = Currency;

            trigger OnValidate()
            var
                StandardCodesMgt: Codeunit "Standard Codes Mgt.";
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date")]) or ("Currency Code" <> xRec."Currency Code") then
                    TestStatusOpen();

                ResetInvoiceDiscountValue();

                if (CurrFieldNo <> FieldNo("Currency Code")) and ("Currency Code" = xRec."Currency Code") then
                    UpdateCurrencyFactor()
                else
                    if "Currency Code" <> xRec."Currency Code" then
                        UpdateCurrencyFactor()
                    else
                        if "Currency Code" <> '' then begin
                            UpdateCurrencyFactor();
                            if "Currency Factor" <> xRec."Currency Factor" then
                                ConfirmCurrencyFactorUpdate();
                        end;

                if ShouldCheckShowRecurringSalesLines(xRec, Rec) then
                    StandardCodesMgt.CheckShowSalesRecurringLinesNotification(Rec);

                if "Currency Code" <> xRec."Currency Code" then
                    SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, Rec, true);

                if Status = Status::Open then
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
                ResetInvoiceDiscountValue();

                if "Currency Factor" <> xRec."Currency Factor" then
                    UpdateSalesLinesByFieldNo(FieldNo("Currency Factor"), false);
            end;
        }
        field(34; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FieldCaption("Customer Price Group"));
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
                Currency: Record Currency;
                RecalculatePrice: Boolean;
                VatFactor: Decimal;
                LineInvDiscAmt: Decimal;
                InvDiscRounding: Decimal;
            begin
                TestStatusOpen();

                if "Prices Including VAT" <> xRec."Prices Including VAT" then begin
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Job Contract Entry No.", '<>%1', 0);
                    if SalesLine.Find('-') then begin
                        SalesLine.TestField("Job No.", '');
                        SalesLine.TestField("Job Contract Entry No.", 0);
                    end;

                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", "Document Type");
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.SetFilter("Unit Price", '<>%1', 0);
                    SalesLine.SetFilter("VAT %", '<>%1', 0);
                    OnValidatePricesIncludingVATOnBeforeSalesLineFindFirst(SalesLine);
                    if SalesLine.FindFirst() then begin
                        RecalculatePrice := ConfirmRecalculatePrice(SalesLine);
                        OnAfterConfirmSalesPrice(Rec, SalesLine, RecalculatePrice);
                        SalesLine.SetSalesHeader(Rec);

                        InitializeRoundingPrecision(Currency);

                        SalesLine.LockTable();
                        LockTable();
                        SalesLine.FindSet();
                        repeat
                            SalesLine.TestField("Quantity Invoiced", 0);
                            SalesLine.TestField("Prepmt. Amt. Inv.", 0);
                            if not RecalculatePrice then begin
                                SalesLine."VAT Difference" := 0;
                                SalesLine.UpdateAmounts();
                            end else begin
                                VatFactor := 1 + SalesLine."VAT %" / 100;
                                if VatFactor = 0 then
                                    VatFactor := 1;
                                if not "Prices Including VAT" then
                                    VatFactor := 1 / VatFactor;
                                if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then
                                    VatFactor := 1;
                                SalesLine."Unit Price" :=
                                  Round(SalesLine."Unit Price" * VatFactor, Currency."Unit-Amount Rounding Precision");
                                SalesLine."Line Discount Amount" :=
                                  Round(
                                    SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100,
                                    Currency."Amount Rounding Precision");
                                LineInvDiscAmt := InvDiscRounding + SalesLine."Inv. Discount Amount" * VatFactor;
                                SalesLine."Inv. Discount Amount" := Round(LineInvDiscAmt, Currency."Amount Rounding Precision");
                                InvDiscRounding := LineInvDiscAmt - SalesLine."Inv. Discount Amount";
                                if SalesLine."VAT Calculation Type" = SalesLine."VAT Calculation Type"::"Full VAT" then
                                    SalesLine."Line Amount" := SalesLine."Amount Including VAT"
                                else
                                    if "Prices Including VAT" then
                                        SalesLine."Line Amount" := SalesLine."Amount Including VAT" + SalesLine."Inv. Discount Amount"
                                    else
                                        SalesLine."Line Amount" := SalesLine.Amount + SalesLine."Inv. Discount Amount";
                                UpdatePrepmtAmounts(SalesLine);
                            end;
                            OnValidatePricesIncludingVATOnBeforeSalesLineModify(Rec, SalesLine, Currency, RecalculatePrice);
                            SalesLine.Modify();
                        until SalesLine.Next() = 0;
                    end;
                    OnAfterChangePricesIncludingVAT(Rec);
                end;
            end;
        }
        field(37; "Invoice Disc. Code"; Code[20])
        {
            AccessByPermission = TableData "Cust. Invoice Disc." = R;
            Caption = 'Invoice Disc. Code';

            trigger OnValidate()
            begin
                TestStatusOpen();
                MessageIfSalesLinesExist(FieldCaption("Invoice Disc. Code"));
            end;
        }
        field(40; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCustomerDiscGroup(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                MessageIfSalesLinesExist(FieldCaption("Customer Disc. Group"));
            end;
        }
        field(41; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                MessageIfSalesLinesExist(FieldCaption("Language Code"));
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
            ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            var
                ApprovalEntry: Record "Approval Entry";
                EnumAssignmentMgt: Codeunit "Enum Assignment Management";
            begin
                ValidateSalesPersonOnSalesHeader(Rec, false, false);

                ApprovalEntry.SetRange("Table ID", DATABASE::"Sales Header");
                ApprovalEntry.SetRange("Document Type", EnumAssignmentMgt.GetSalesApprovalDocumentType("Document Type"));
                ApprovalEntry.SetRange("Document No.", "No.");
                ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
                if not ApprovalEntry.IsEmpty() then
                    Error(Text053, FieldCaption("Salesperson Code"));

                CreateDimensionsFromValidateSalesPersonCode();
            end;
        }
        field(45; "Order Class"; Code[10])
        {
            Caption = 'Order Class';
        }
        field(46; Comment; Boolean)
        {
            CalcFormula = exist("Sales Comment Line" where("Document Type" = field("Document Type"),
                                                            "No." = field("No."),
                                                            "Document Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
            Editable = false;
        }
        field(51; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
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
                GenJnlLine: Record "Gen. Journal Line";
                GenJnlApply: Codeunit "Gen. Jnl.-Apply";
                ApplyCustEntries: Page "Apply Customer Entries";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupAppliesToDocNo(Rec, CustLedgEntry, IsHandled);
                if IsHandled then
                    exit;

                TestField("Bal. Account No.", '');
                CustLedgEntry.SetApplyToFilters("Bill-to Customer No.", "Applies-to Doc. Type".AsInteger(), "Applies-to Doc. No.", Amount);
                OnAfterSetApplyToFilters(CustLedgEntry, Rec);

                ApplyCustEntries.SetSales(Rec, CustLedgEntry, SalesHeader.FieldNo("Applies-to Doc. No."));
                ApplyCustEntries.SetTableView(CustLedgEntry);
                ApplyCustEntries.SetRecord(CustLedgEntry);
                ApplyCustEntries.LookupMode(true);
                if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
                    ApplyCustEntries.GetCustLedgEntry(CustLedgEntry);
                    GenJnlApply.CheckAgainstApplnCurrency(
                      "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                    "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                    "Applies-to Doc. No." := CustLedgEntry."Document No.";
                    OnAfterAppliesToDocNoOnLookup(Rec, CustLedgEntry);
                end;
                Clear(ApplyCustEntries);
            end;

            trigger OnValidate()
            var
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
                    CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.");
                    CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");
                end else
                    if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and (xRec."Applies-to Doc. No." = '') then
                        CustLedgEntry.SetAmountToApply("Applies-to Doc. No.", "Bill-to Customer No.")
                    else
                        if ("Applies-to Doc. No." <> xRec."Applies-to Doc. No.") and ("Applies-to Doc. No." = '') then
                            CustLedgEntry.SetAmountToApply(xRec."Applies-to Doc. No.", "Bill-to Customer No.");

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
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            CalcFormula = exist("Sales Line" where("Document Type" = field("Document Type"),
                                                    "Document No." = field("No."),
                                                    "Recalculate Invoice Disc." = const(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(57; Ship; Boolean)
        {
            Caption = 'Ship';
            Editable = false;
        }
        field(58; Invoice; Boolean)
        {
            Caption = 'Invoice';
        }
        field(59; "Print Posted Documents"; Boolean)
        {
            Caption = 'Print Posted Documents';
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line".Amount where("Document Type" = field("Document Type"),
                                                         "Document No." = field("No.")));
            Caption = 'Amount';
            ToolTip = 'Specifies the sum of amounts on all the lines in the document. This will include invoice discounts.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Amount Including VAT" where("Document Type" = field("Document Type"),
                                                                         "Document No." = field("No.")));
            Caption = 'Amount Including VAT';
            ToolTip = 'Specifies the sum of amounts, including VAT, on all the lines in the document. This will include invoice discounts.';
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
            TableRelation = "Sales Shipment Header";
        }
        field(65; "Last Posting No."; Code[20])
        {
            Caption = 'Last Posting No.';
            Editable = false;
            TableRelation = "Sales Invoice Header";
        }
        field(66; "Prepayment No."; Code[20])
        {
            Caption = 'Prepayment No.';
        }
        field(67; "Last Prepayment No."; Code[20])
        {
            Caption = 'Last Prepayment No.';
            TableRelation = "Sales Invoice Header";
        }
        field(68; "Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No.';
        }
        field(69; "Last Prepmt. Cr. Memo No."; Code[20])
        {
            Caption = 'Last Prepmt. Cr. Memo No.';
            TableRelation = "Sales Cr.Memo Header";
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                Customer: Record Customer;
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegistrationNoFormat: Record "VAT Registration No. Format";
                VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecRef: RecordRef;
                ApplicableCountryCode: Code[10];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATRegistrationNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;

                GLSetup.GetRecordOnce();
                case GLSetup."Bill-to/Sell-to VAT Calc." of
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.":
                        if not Customer.Get("Bill-to Customer No.") then
                            exit;
                    GLSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.":
                        if not Customer.Get("Sell-to Customer No.") then
                            exit;
                end;

                if "VAT Registration No." = Customer."VAT Registration No." then
                    exit;

                ApplicableCountryCode := Rec."VAT Country/Region Code";
                if ApplicableCountryCode = '' then
                    ApplicableCountryCode := Customer."Country/Region Code";
                if not VATRegistrationNoFormat.Test("VAT Registration No.", ApplicableCountryCode, Customer."No.", DATABASE::Customer) then
                    exit;

                ApplicableCountryCode := Customer."Country/Region Code";
                if ApplicableCountryCode = '' then
                    ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";

                if not VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                    if AltCustVATRegFacade.UpdateVATRegNoInCustFromSalesHeader(Rec, Customer) then begin
                        Customer."VAT Registration No." := "VAT Registration No.";
                        Customer.Modify(true);
                    end;
                    exit;
                end;

                VATRegistrationLogMgt.CheckVIESForVATNo(
                    ResultRecRef, VATRegistrationLog, Customer, Customer."No.",
                    ApplicableCountryCode, VATRegistrationLog."Account Type"::Customer.AsInteger());

                if VATRegistrationLog.Status = VATRegistrationLog.Status::Valid then begin
                    Message(ValidVATNoMsg);
                    if AltCustVATRegFacade.UpdateVATRegNoInCustFromSalesHeader(Rec, Customer) then begin
                        Customer."VAT Registration No." := "VAT Registration No.";
                        Customer.Modify(true);
                    end;
                end else
                    Message(InvalidVatRegNoMsg);
            end;
        }
        field(71; "Combine Shipments"; Boolean)
        {
            Caption = 'Combine Shipments';
        }
        field(72; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
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
            begin
                TestStatusOpen();
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then begin
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then begin
                        "VAT Bus. Posting Group" := GenBusPostingGrp."Def. VAT Bus. Posting Group";
                        OnAfterAssignDefaultVATBusPostingGroup(Rec, xRec, GenBusPostingGrp);
                    end;
                    RecreateSalesLines(FieldCaption("Gen. Bus. Posting Group"));
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
                UpdateSalesLinesByFieldNo(FieldNo("Transaction Type"), false);
            end;
        }
        field(77; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            TableRelation = "Transport Method";

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Transport Method"), false);
            end;
        }
        field(78; "VAT Country/Region Code"; Code[10])
        {
            Caption = 'VAT Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                AltCustVATRegFacade.UpdateSetupOnVATCountryChangeInSalesHeader(Rec, xRec);
            end;
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer that you''re selling to. By default, the same customer is suggested as the ship-to customer. If needed, you can specify a different ship-to customer on the document.';
            TableRelation = Customer.Name;
            ValidateTableRelation = false;

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
                    end
                end else
                    if Rec."Sell-to Customer Name" <> xRec."Sell-to Customer Name" then
                        if ShouldSearchForCustomerByName("Sell-to Customer No.") then
                            Validate("Sell-to Customer No.", Customer.GetCustNo("Sell-to Customer Name"));

                GetShippingTime(FieldNo("Sell-to Customer Name"));
            end;
        }
        field(80; "Sell-to Customer Name 2"; Text[50])
        {
            Caption = 'Sell-to Customer Name 2';
            ToolTip = 'Specifies an additional part of the name of the customer who will receive the products and be billed by default.';
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address"));
                ModifyCustomerAddress();
            end;
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Address 2"));
                ModifyCustomerAddress();
            end;
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupSellToCity(Rec, PostCode);

                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");

                OnAfterLookupSellToCity(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(
                        "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to City"));
                ModifyCustomerAddress();
            end;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            ToolTip = 'Specifies the name of the contact person at the customer''s main address.';

            trigger OnLookup()
            var
                Contact: Record Contact;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupSelltoContact(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Document Type" <> "Document Type"::Quote then
                    if "Sell-to Customer No." = '' then
                        exit;

                Contact.FilterGroup(2);
                LookupContact("Sell-to Customer No.", "Sell-to Contact No.", Contact);
                if PAGE.RunModal(0, Contact) = ACTION::LookupOK then
                    Validate("Sell-to Contact No.", Contact."No.");
                Contact.FilterGroup(0);
            end;

            trigger OnValidate()
            begin
                if "Sell-to Contact" = '' then
                    Validate("Sell-to Contact No.", '');
                ModifyCustomerAddress();
            end;
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s billing address.';
            TableRelation = "Post Code";
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupBillToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Bill-to City", "Bill-to Post Code", "Bill-to County", "Bill-to Country/Region Code");

                OnAfterLookupBillToPostCode(Rec, PostCode, xRec);
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
                ModifyBillToCustomerAddress();
            end;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';

            trigger OnValidate()
            begin
                ModifyBillToCustomerAddress();
            end;
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s billing address.';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                FormatAddress: Codeunit "Format Address";
            begin
                if not FormatAddress.UseCounty(Rec."Bill-to Country/Region Code") then
                    "Bill-to County" := '';
                ModifyBillToCustomerAddress();
            end;
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            ToolTip = 'Specifies the postal code of the customer''s main address.';
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupSellToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code");

                OnAfterLookupSellToPostCode(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
                DoExit: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSellToPostCode(Rec, PostCode, CurrFieldNo, IsHandled, DoExit);
                if DoExit then
                    exit;

                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Sell-to City", "Sell-to Post Code", "Sell-to County", "Sell-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Post Code"));
                ModifyCustomerAddress();
            end;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';

            trigger OnValidate()
            begin
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to County"));
                ModifyCustomerAddress();
            end;
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            ToolTip = 'Specifies the country/region code of the customer''s main address.';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                FormatAddress: Codeunit "Format Address";
            begin
                if not FormatAddress.UseCounty(Rec."Sell-to Country/Region Code") then
                    "Sell-to County" := '';
                UpdateShipToAddressFromSellToAddress(FieldNo("Ship-to Country/Region Code"));
                ModifyCustomerAddress();
                Validate("Ship-to Country/Region Code");
            end;
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupShipToPostCode(Rec, PostCode);

                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");

                OnAfterLookupShipToPostCode(Rec, PostCode, xRec);
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
            ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                AltCustVATRegFacade.UpdateSetupOnShipToCountryChangeInSalesHeader(Rec, xRec);
            end;
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
                UpdateSalesLinesByFieldNo(FieldNo("Exit Point"), false);
            end;
        }
        field(98; Correction; Boolean)
        {
            Caption = 'Correction';
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ToolTip = 'Specifies the date when the related document was created.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateDocumentDate(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                UpdateVATReportingDate(FieldNo("Document Date"));

                if xRec."Document Date" <> "Document Date" then
                    UpdateDocumentDate := true;
                Validate("Payment Terms Code");
                Validate("Prepmt. Payment Terms Code");

                if UpdateDocumentDate and ("Document Type" = "Document Type"::Quote) and ("Document Date" <> 0D) then
                    CalcQuoteValidUntilDate();
                UpdateDocumentDate := false;
            end;
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';

            trigger OnValidate()
            var
                WhseSalesRelease: Codeunit "Whse.-Sales Release";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateExternalDocumentNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "External Document No." <> '' then
                    if FindDocumentWithSameExternalDocNo() then
                        ShowExternalDocAlreadyExistNotification()
                    else
                        RecallExternalDocAlreadyExistsNotification();

                if (xRec."External Document No." <> "External Document No.") and (Status = Status::Released) and
                   ("Document Type" in ["Document Type"::Order, "Document Type"::"Return Order"])
                then
                    WhseSalesRelease.UpdateExternalDocNoForReleasedOrder(Rec);
            end;
        }
        field(101; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo(Area), false);
            end;
        }
        field(102; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            TableRelation = "Transaction Specification";

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Transaction Specification"), false);
            end;
        }
        field(104; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePaymentMethodCode(Rec, PaymentMethod, IsHandled);
                if IsHandled then
                    exit;

                UpdateDirectDebitPmtTermsCode();

                "Bal. Account Type" := PaymentMethod."Bal. Account Type";
                "Bal. Account No." := PaymentMethod."Bal. Account No.";
                if "Bal. Account No." <> '' then begin
                    TestField("Applies-to Doc. No.", '');
                    TestField("Applies-to ID", '');
                    Clear("Payment Service Set ID");
                end;
            end;
        }
        field(105; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentCode(Rec, IsHandled, xRec, CurrFieldNo);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if xRec."Shipping Agent Code" = "Shipping Agent Code" then
                    exit;

                "Shipping Agent Service Code" := '';
                GetShippingTime(FieldNo("Shipping Agent Code"));

                OnValidateShippingAgentCodeOnBeforeUpdateLines(Rec, CurrFieldNo, HideValidationDialog);
                UpdateSalesLinesByFieldNo(FieldNo("Shipping Agent Code"), CurrFieldNo <> 0);
            end;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(106; "Package Tracking No."; Text[50])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Package Tracking No.';
            ToolTip = 'Specifies the shipping agent''s package number.';
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
            var
                NoSeries: Codeunit "No. Series";
            begin
                SalesHeader := Rec;
                GetSalesSetup();
                SalesHeader.TestNoSeries();
                if NoSeries.LookupRelatedNoSeries(GetPostingNoSeriesCode(), SalesHeader."Posting No. Series") then
                    SalesHeader.Validate("Posting No. Series");
                Rec := SalesHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "Posting No. Series" <> '' then begin
                    GetSalesSetup();
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

            trigger OnLookup()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                SalesHeader := Rec;
                GetSalesSetup();
                SalesSetup.TestField("Posted Shipment Nos.");
                if NoSeries.LookupRelatedNoSeries(SalesSetup."Posted Shipment Nos.", SalesHeader."Shipping No. Series") then
                    SalesHeader.Validate("Shipping No. Series");
                Rec := SalesHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Shipping No. Series" <> '' then begin
                    GetSalesSetup();
                    SalesSetup.TestField("Posted Shipment Nos.");
                    NoSeries.TestAreRelated(SalesSetup."Posted Shipment Nos.", "Shipping No. Series");
                end;
                TestField("Shipping No.", '');
            end;
        }
        field(114; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Tax Area Code" = xRec."Tax Area Code" then
                    exit;
                TestStatusOpen();
                ValidateTaxAreaCode();
                MessageIfSalesLinesExist(FieldCaption("Tax Area Code"));
            end;
        }
        field(115; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                if "Tax Liable" = xRec."Tax Liable" then
                    exit;
                TestStatusOpen();
                MessageIfSalesLinesExist(FieldCaption("Tax Liable"));
            end;
        }
        field(116; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if xRec."VAT Bus. Posting Group" <> "VAT Bus. Posting Group" then begin
                    RecreateSalesLines(FieldCaption("VAT Bus. Posting Group"));
                    SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, Rec, true);
                end;
            end;
        }
        field(117; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
            InitValue = Optional;
        }
        field(118; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
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
                IsHandled := false;
                OnBeforeValidateVATBaseDiscountPct(Rec, IsHandled);
                if IsHandled then
                    exit;

                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen();
                GLSetup.Get();
                if "VAT Base Discount %" > GLSetup."VAT Tolerance %" then
                    Error(
                      Text007,
                      FieldCaption("VAT Base Discount %"),
                      GLSetup.FieldCaption("VAT Tolerance %"),
                      GLSetup.TableCaption());

                if ("VAT Base Discount %" = xRec."VAT Base Discount %") and (CurrFieldNo <> 0) then
                    exit;

                UpdateSalesLineAmounts();
            end;
        }
        field(120; Status; Enum "Sales Document Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
            Editable = false;
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
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "Send IC Document" then begin
                    if "Bill-to IC Partner Code" = '' then
                        TestField("Sell-to IC Partner Code");
                    IsHandled := false;
                    OnValidateSendICDocumentOnBeforeCheckICDirection(Rec, IsHandled);
                    if not IsHandled then
                        TestField("IC Direction", "IC Direction"::Outgoing);
                end;
            end;
        }
        field(124; "IC Status"; Enum "Sales Document IC Status")
        {
            Caption = 'IC Status';
        }
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            Editable = false;
        }
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';

            trigger OnValidate()
            begin
                if "IC Direction" = "IC Direction"::Incoming then
                    "Send IC Document" := false;
            end;
        }
        field(130; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Prepayment %" > 100 then
                    error(MaxAllowedValueIs100Err);
                if xRec."Prepayment %" <> "Prepayment %" then
                    UpdateSalesLinesByFieldNo(FieldNo("Prepayment %"), CurrFieldNo <> 0);
            end;
        }
        field(131; "Prepayment No. Series"; Code[20])
        {
            Caption = 'Prepayment No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupPrepmtNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                SalesHeader := Rec;
                GetSalesSetup();
                SalesSetup.TestField("Posted Prepmt. Inv. Nos.");
                if NoSeries.LookupRelatedNoSeries(GetPostingPrepaymentNoSeriesCode(), SalesHeader."Prepayment No. Series") then
                    SalesHeader.Validate("Prepayment No. Series");
                Rec := SalesHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Prepayment No. Series" <> '' then begin
                    GetSalesSetup();
                    SalesSetup.TestField("Posted Prepmt. Inv. Nos.");
                    NoSeries.TestAreRelated(GetPostingPrepaymentNoSeriesCode(), "Prepayment No. Series");
                end;
                TestField("Prepayment No.", '');
            end;
        }
        field(132; "Compress Prepayment"; Boolean)
        {
            Caption = 'Compress Prepayment';
            InitValue = true;
        }
        field(133; "Prepayment Due Date"; Date)
        {
            Caption = 'Prepayment Due Date';
        }
        field(134; "Prepmt. Cr. Memo No. Series"; Code[20])
        {
            Caption = 'Prepmt. Cr. Memo No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupPrepmtCrMemoNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                SalesHeader := Rec;
                GetSalesSetup();
                SalesSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                if NoSeries.LookupRelatedNoSeries(GetPostingPrepaymentNoSeriesCode(), SalesHeader."Prepmt. Cr. Memo No. Series") then
                    SalesHeader.Validate("Prepmt. Cr. Memo No. Series");
                Rec := SalesHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtCrMemoNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Prepmt. Cr. Memo No." <> '' then begin
                    GetSalesSetup();
                    SalesSetup.TestField("Posted Prepmt. Cr. Memo Nos.");
                    NoSeries.TestAreRelated(GetPostingPrepaymentNoSeriesCode(), "Prepmt. Cr. Memo No. Series");
                end;
                TestField("Prepmt. Cr. Memo No.", '');
            end;
        }
        field(135; "Prepmt. Posting Description"; Text[100])
        {
            Caption = 'Prepmt. Posting Description';
        }
        field(138; "Prepmt. Pmt. Discount Date"; Date)
        {
            Caption = 'Prepmt. Pmt. Discount Date';
        }
        field(139; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms";

            trigger OnValidate()
            var
                PaymentTerms: Record "Payment Terms";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePrepmtPaymentTermsCode(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, UpdateDocumentDate, IsHandled);
                if IsHandled then
                    exit;

                if ("Prepmt. Payment Terms Code" <> '') and ("Document Date" <> 0D) then begin
                    PaymentTerms.Get("Prepmt. Payment Terms Code");
                    if IsCreditDocType() and not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
                        IsHandled := false;
                        OnValidatePrepmtPaymentTermsCodeOnCaseIfOnBeforeValidatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                        if not IsHandled then
                            Validate("Prepayment Due Date", "Document Date");
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end else begin
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcDueDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepayment Due Date" := CalcDate(PaymentTerms."Due Date Calculation", "Document Date");
                        IsHandled := false;
                        OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(Rec, xRec, FieldNo("Prepmt. Payment Terms Code"), CurrFieldNo, IsHandled);
                        if not IsHandled then
                            "Prepmt. Pmt. Discount Date" := CalcDate(PaymentTerms."Discount Date Calculation", "Document Date");
                        if not UpdateDocumentDate then
                            Validate("Prepmt. Payment Discount %", PaymentTerms."Discount %")
                    end;
                end else begin
                    IsHandled := false;
                    OnPrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(Rec, xRec, CurrFieldNo, IsHandled);
                    if not IsHandled then
                        Validate("Prepayment Due Date", "Document Date");
                    if not UpdateDocumentDate then begin
                        Validate("Prepmt. Pmt. Discount Date", 0D);
                        Validate("Prepmt. Payment Discount %", 0);
                    end;
                end;
            end;
        }
        field(140; "Prepmt. Payment Discount %"; Decimal)
        {
            Caption = 'Prepmt. Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date"), FieldNo("Document Date")]) then
                    TestStatusOpen();
                GLSetup.Get();
                if "Payment Discount %" < GLSetup."VAT Tolerance %" then
                    "VAT Base Discount %" := "Payment Discount %"
                else
                    "VAT Base Discount %" := GLSetup."VAT Tolerance %";
                Validate("VAT Base Discount %");
            end;
        }
        field(151; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
            ToolTip = 'Specifies the number of the sales quote that the sales order was created from. You can track the number to sales quote documents that you have printed, saved, or emailed.';
            Editable = false;
        }
        field(152; "Quote Valid Until Date"; Date)
        {
            Caption = 'Quote Valid To Date';
        }
        field(153; "Quote Sent to Customer"; DateTime)
        {
            Caption = 'Quote Sent to Customer';
            Editable = false;
        }
        field(154; "Quote Accepted"; Boolean)
        {
            Caption = 'Quote Accepted';

            trigger OnValidate()
            begin
                if "Quote Accepted" then begin
                    "Quote Accepted Date" := WorkDate();
                    OnAfterSalesQuoteAccepted(Rec);
                end else
                    "Quote Accepted Date" := 0D;
            end;
        }
        field(155; "Quote Accepted Date"; Date)
        {
            Caption = 'Quote Accepted Date';
            Editable = false;
        }
        field(160; "Job Queue Status"; Enum "Document Job Queue Status")
        {
            Caption = 'Job Queue Status';
            ToolTip = 'Specifies the status of a job queue entry or task that handles the posting of sales orders.';
            Editable = false;

            trigger OnLookup()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                if Rec."Job Queue Status" = Rec."Job Queue Status"::" " then
                    exit;
                JobQueueEntry.ShowStatusMsg(Rec."Job Queue Entry ID");
            end;
        }
        field(161; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(163; "Company Bank Account Code"; Code[20])
        {
            Caption = 'Company Bank Account Code';
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));

            trigger OnValidate()
            begin
                if not (CurrFieldNo in [0, FieldNo("Posting Date")]) or ("Company Bank Account Code" <> xRec."Company Bank Account Code") then
                    TestStatusOpen();
            end;
        }
        field(165; "Incoming Document Entry No."; Integer)
        {
            Caption = 'Incoming Document Entry No.';
            TableRelation = "Incoming Document";

            trigger OnValidate()
            var
                IncomingDocument: Record "Incoming Document";
            begin
                if "Incoming Document Entry No." = xRec."Incoming Document Entry No." then
                    exit;
                if "Incoming Document Entry No." = 0 then
                    IncomingDocument.RemoveReferenceToWorkingDocument(xRec."Incoming Document Entry No.")
                else
                    IncomingDocument.SetSalesDoc(Rec);
            end;
        }
        field(166; "Alt. VAT Registration No."; Boolean)
        {
            Caption = 'Alternative VAT Registration No.';
            Editable = false;
        }
        field(167; "Alt. Gen. Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative Gen. Bus. Posting Group';
            Editable = false;
        }
        field(168; "Alt. VAT Bus Posting Group"; Boolean)
        {
            Caption = 'Alternative VAT Bus. Posting Group';
            Editable = false;
        }
        field(170; IsTest; Boolean)
        {
            Caption = 'IsTest';
            Editable = false;
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Sell-to Phone No.") do
                    if Char.IsLetter("Sell-to Phone No."[i]) then
                        Error(PhoneNoCannotContainLettersErr);

                UpdateShipToAddressFromSellToAddress(Rec.FieldNo("Ship-to Phone No."));
            end;
        }
        field(172; "Sell-to E-Mail"; Text[80])
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
        field(178; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template" where(Type = filter(Sales));

            trigger OnValidate()
            begin
                SalesSetup.Get();
                TestNoSeries();
                Validate("Posting No. Series", GenJournalTemplate."Posting No. Series");
            end;
        }
        field(179; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if "VAT Reporting Date" = 0D then begin
                    IsHandled := false;
                    OnValidateVATReportingDateOnBeforeInitVATDate(Rec, xRec, IsHandled);
                    if not IsHandled then
                        InitVATDate();
                end;
            end;
        }
        field(181; "Rcvd.-from Count./Region Code"; Code[10])
        {
            Caption = 'Received-from Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(185; "Last Email Sent Time"; DateTime)
        {
            Caption = 'Last Email Sent Time';
            FieldClass = FlowField;
            CalcFormula = max("Email Related Record".SystemCreatedAt where("Table Id" = const(Database::"Sales Header"),
                                                                           "System Id" = field(SystemId)));
        }
        field(186; "Last Email Sent Message Id"; Guid)
        {
            Caption = 'Last Email Sent Message Id';
            FieldClass = FlowField;
            CalcFormula = lookup("Email Related Record"."Email Message Id" where(SystemCreatedAt = field("Last Email Sent Time")));
        }
        field(200; "Work Description"; BLOB)
        {
            Caption = 'Work Description';
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(300; "Amt. Ship. Not Inv. (LCY)"; Decimal)
        {
            CalcFormula = sum("Sales Line"."Shipped Not Invoiced (LCY)" where("Document Type" = field("Document Type"),
                                                                               "Document No." = field("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT';
            ToolTip = 'Specifies the sum, in LCY, for items that have been shipped but not yet been invoiced. The amount is calculated as Amount Including VAT x Qty. Shipped Not Invoiced / Quantity.';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatType = 1;
        }
        field(301; "Amt. Ship. Not Inv. (LCY) Base"; Decimal)
        {
            CalcFormula = sum("Sales Line"."Shipped Not Inv. (LCY) No VAT" where("Document Type" = field("Document Type"),
                                                                                  "Document No." = field("No.")));
            Caption = 'Amount Shipped Not Invoiced (LCY)';
            ToolTip = 'Specifies the sum, in LCY, for items that have been shipped but not yet been invoiced. The amount is calculated as Amount Including VAT x Qty. Shipped Not Invoiced / Quantity.';
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
        field(600; "Payment Service Set ID"; Integer)
        {
            Caption = 'Payment Service Set ID';
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            ToolTip = 'Specifies that the sales order is coupled to an order in Dynamics 365 Sales.';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Sales Header")));
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."),
                                                               Closed = const(false),
                                                               Blocked = const(false));
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Sales Line"."Inv. Discount Amount" where("Document No." = field("No."),
                                                                         "Document Type" = field("Document Type")));
            Caption = 'Invoice Discount Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5043; "No. of Archived Versions"; Integer)
        {
            CalcFormula = max("Sales Header Archive"."Version No." where("Document Type" = field("Document Type"),
                                                                          "No." = field("No."),
                                                                          "Doc. No. Occurrence" = field("Doc. No. Occurrence")));
            Caption = 'No. of Archived Versions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            ToolTip = 'Specifies the campaign number the document is linked to.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                UpdateSalesLinesByFieldNo(FieldNo("Campaign No."), CurrFieldNo <> 0);
                CreateDimFromDefaultDim(Rec.FieldNo("Campaign No."));
            end;
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            TableRelation = Contact;

            trigger OnLookup()
            begin
                SelltoContactLookup();
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                Opportunity: Record Opportunity;
                IsHandled: Boolean;
                ShouldUpdateOpportunity: Boolean;
            begin
                TestStatusOpen();

                if "Sell-to Contact No." <> '' then
                    if Cont.Get("Sell-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric();

                IsHandled := false;
                OnValidateSellToContactNoOnAfterContCheckIfPrivacyBlockedGeneric(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if ("Sell-to Contact No." <> xRec."Sell-to Contact No.") and
                   (xRec."Sell-to Contact No." <> '')
                then begin
                    if ("Sell-to Contact No." = '') and ("Opportunity No." <> '') then
                        Error(Text049, FieldCaption("Sell-to Contact No."));
                    IsHandled := false;
                    OnBeforeConfirmSellToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog() or not GuiAllowed then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Sell-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Sell-to Contact No.", "Sell-to Customer No.", FieldCaption("Sell-to Contact No.")) then
                            exit;
                        ShouldUpdateOpportunity := "Opportunity No." <> '';
                        OnValidateSelltoContactNoOnAfterCalcShouldUpdateOpportunity(Rec, ShouldUpdateOpportunity);
                        if ShouldUpdateOpportunity then begin
                            Opportunity.Get("Opportunity No.");
                            if Opportunity."Contact No." <> "Sell-to Contact No." then begin
                                Modify();
                                Opportunity.Validate("Contact No.", "Sell-to Contact No.");
                                Opportunity.Modify();
                            end
                        end;
                    end else begin
                        Rec := xRec;
                        exit;
                    end;
                end;

                if ("Sell-to Customer No." <> '') and ("Sell-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Sell-to Contact No.", "Sell-to Customer No.", CurrFieldNo);

                IsHandled := false;
                OnValidateSelltoContactNoOnBeforeValidateSalespersonCode(Rec, Cont, IsHandled);
                if not IsHandled then
                    if "Sell-to Contact No." <> '' then
                        if Cont.Get("Sell-to Contact No.") then
                            if ("Salesperson Code" = '') and (Cont."Salesperson Code" <> '') then
                                Validate("Salesperson Code", Cont."Salesperson Code");

                if ("Sell-to Contact No." <> xRec."Sell-to Contact No.") then
                    UpdateSellToCust("Sell-to Contact No.");
                UpdateSellToCustTemplateCode();
                UpdateShipToContact();
                GetShippingTime(FieldNo("Sell-to Contact No."));
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
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupBillToContactNo(IsHandled, Rec, xRec);
                if IsHandled then
                    exit;

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
            end;

            trigger OnValidate()
            var
                Cont: Record Contact;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                if "Bill-to Contact No." <> '' then
                    if Cont.Get("Bill-to Contact No.") then
                        Cont.CheckIfPrivacyBlockedGeneric();

                if ("Bill-to Contact No." <> xRec."Bill-to Contact No.") and
                   (xRec."Bill-to Contact No." <> '')
                then begin
                    IsHandled := false;
                    OnBeforeConfirmBillToContactNoChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
                    if not IsHandled then
                        if GetHideValidationDialog() or (not GuiAllowed) then
                            Confirmed := true
                        else
                            Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Contact No."));
                    if Confirmed then begin
                        if InitFromContact("Bill-to Contact No.", "Bill-to Customer No.", FieldCaption("Bill-to Contact No.")) then
                            exit;
                    end else begin
                        "Bill-to Contact No." := xRec."Bill-to Contact No.";
                        exit;
                    end;
                end;

                if ("Bill-to Customer No." <> '') and ("Bill-to Contact No." <> '') then
                    CheckContactRelatedToCustomerCompany("Bill-to Contact No.", "Bill-to Customer No.", CurrFieldNo);

                UpdateBillToCust("Bill-to Contact No.");
            end;
        }
        field(5055; "Opportunity No."; Code[20])
        {
            Caption = 'Opportunity No.';
            TableRelation = if ("Document Type" = filter(<> Order)) Opportunity."No." where("Contact No." = field("Sell-to Contact No."),
                                                                                          Closed = const(false))
            else
            if ("Document Type" = const(Order)) Opportunity."No." where("Contact No." = field("Sell-to Contact No."),
                                                                                                                                                          "Sales Document No." = field("No."),
                                                                                                                                                          "Sales Document Type" = const(Order));

            trigger OnValidate()
            begin
                LinkSalesDocWithOpportunity(xRec."Opportunity No.");
            end;
        }
        field(5056; "Sell-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Sell-to Customer Template Code';
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                SellToCustTemplate: Record "Customer Templ.";
            begin
                EnsureDocumentTypeIsQuote();
                TestStatusOpen();

                if not InsertMode and
                   ("Sell-to Customer Templ. Code" <> xRec."Sell-to Customer Templ. Code") and
                   (xRec."Sell-to Customer Templ. Code" <> '')
                then begin
                    if GetHideValidationDialog() or not GuiAllowed() then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Sell-to Customer Templ. Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Sell-to Customer Templ. Code", FieldCaption("Sell-to Customer Templ. Code")) then
                            exit
                    end else begin
                        "Sell-to Customer Templ. Code" := xRec."Sell-to Customer Templ. Code";
                        exit;
                    end;
                end;

                if SellToCustTemplate.Get("Sell-to Customer Templ. Code") then
                    CopyFromNewSellToCustTemplate(SellToCustTemplate);

                if not InsertMode and
                   ((xRec."Sell-to Customer Templ. Code" <> "Sell-to Customer Templ. Code") or
                    (xRec."Currency Code" <> "Currency Code"))
                then
                    RecreateSalesLines(CopyStr(FieldCaption("Sell-to Customer Templ. Code"), 1, 100));
            end;
        }
        field(5057; "Bill-to Customer Templ. Code"; Code[20])
        {
            Caption = 'Bill-to Customer Template Code';
            TableRelation = "Customer Templ.";

            trigger OnValidate()
            var
                BillToCustTemplate: Record "Customer Templ.";
            begin
                TestField("Document Type", "Document Type"::Quote);
                TestStatusOpen();

                if not InsertMode and
                   ("Bill-to Customer Templ. Code" <> xRec."Bill-to Customer Templ. Code") and
                   (xRec."Bill-to Customer Templ. Code" <> '')
                then begin
                    if GetHideValidationDialog() or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(ConfirmChangeQst, false, FieldCaption("Bill-to Customer Templ. Code"));
                    if Confirmed then begin
                        if InitFromTemplate("Bill-to Customer Templ. Code", FieldCaption("Bill-to Customer Templ. Code")) then
                            exit
                    end else begin
                        "Bill-to Customer Templ. Code" := xRec."Bill-to Customer Templ. Code";
                        exit;
                    end;
                end;

                Rec.Validate("Ship-to Code", '');
                if BillToCustTemplate.Get("Bill-to Customer Templ. Code") then
                    InitFromBillToCustTemplate(BillToCustTemplate);

                CreateDimFromDefaultDim(Rec.FieldNo("Bill-to Customer Templ. Code"));

                OnValidateBilltoCustomerTemplCodeOnBeforeRecreateSalesLines(Rec, CurrFieldNo);

                if not InsertMode and
                   (xRec."Sell-to Customer Templ. Code" = "Sell-to Customer Templ. Code") and
                   (xRec."Bill-to Customer Templ. Code" <> "Bill-to Customer Templ. Code")
                then
                    RecreateSalesLines(CopyStr(FieldCaption("Bill-to Customer Templ. Code"), 1, 100));
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";

            trigger OnValidate()
            begin
                TestStatusOpen();
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
                    Error(
                      Text027,
                      RespCenter.TableCaption(), UserSetupMgt.GetSalesFilter());

                UpdateLocationCode('');
                UpdateOutboundWhseHandlingTime();
                UpdateShipToAddress();

                CreateDimFromDefaultDim(Rec.FieldNo("Responsibility Center"));

                if xRec."Responsibility Center" <> "Responsibility Center" then begin
                    RecreateSalesLines(FieldCaption("Responsibility Center"));
                    "Assigned User ID" := '';
                end;
            end;
        }
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies if the customer accepts partial shipment of orders.';

            trigger OnValidate()
            var
                SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
            begin
                TestStatusOpen();
                if InventoryPickConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text066, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                if WhseShipmentConflict("Document Type", "No.", "Shipping Advice") then
                    Error(Text070, FieldCaption("Shipping Advice"), Format("Shipping Advice"), TableCaption);
                SalesWarehouseMgt.SalesHeaderVerifyChange(Rec, xRec);
            end;
        }
        field(5751; "Shipped Not Invoiced"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = exist("Sales Line" where("Document Type" = field("Document Type"),
                                                    "Document No." = field("No."),
                                                    "Qty. Shipped Not Invoiced" = filter(<> 0)));
            Caption = 'Shipped Not Invoiced';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            CalcFormula = min("Sales Line"."Completely Shipped" where("Document Type" = field("Document Type"),
                                                                       "Document No." = field("No."),
                                                                       Type = filter(<> " "),
                                                                       "Location Code" = field("Location Filter")));
            Caption = 'Completely Shipped';
            ToolTip = 'Specifies whether all the items on the order have been shipped or, in the case of inbound items, completely received.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5753; "Posting from Whse. Ref."; Integer)
        {
            AccessByPermission = TableData Location = R;
            Caption = 'Posting from Whse. Ref.';
        }
        field(5754; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5755; Shipped; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = exist("Sales Line" where("Document Type" = field("Document Type"),
                                                    "Document No." = field("No."),
                                                    "Qty. Shipped (Base)" = filter(<> 0)));
            Caption = 'Shipped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5756; "Last Shipment Date"; Date)
        {
            CalcFormula = lookup("Sales Shipment Header"."Shipment Date" where("No." = field("Last Shipping No.")));
            Caption = 'Last Shipment Date';
            FieldClass = FlowField;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            ToolTip = 'Specifies the date that the customer has asked for the order to be delivered.';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateRequestedDeliveryDate(Rec, IsHandled, xRec, CurrFieldNo);
                if IsHandled then
                    exit;

                TestStatusOpen();
                CheckPromisedDeliveryDate();

                if "Requested Delivery Date" <> xRec."Requested Delivery Date" then
                    UpdateSalesLinesByFieldNo(FieldNo("Requested Delivery Date"), CurrFieldNo <> 0);
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
                IsHandled := false;
                OnBeforeValidatePromisedDeliveryDate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if "Promised Delivery Date" <> xRec."Promised Delivery Date" then
                    UpdateSalesLinesByFieldNo(FieldNo("Promised Delivery Date"), CurrFieldNo <> 0);
            end;
        }
        field(5792; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if "Shipping Time" <> xRec."Shipping Time" then
                    UpdateSalesLinesByFieldNo(FieldNo("Shipping Time"), CurrFieldNo <> 0);
            end;
        }
        field(5793; "Outbound Whse. Handling Time"; DateFormula)
        {
            AccessByPermission = TableData "Warehouse Shipment Header" = R;
            Caption = 'Outbound Whse. Handling Time';

            trigger OnValidate()
            begin
                TestStatusOpen();
                if ("Outbound Whse. Handling Time" <> xRec."Outbound Whse. Handling Time") and
                   (xRec."Sell-to Customer No." = "Sell-to Customer No.")
                then
                    UpdateSalesLinesByFieldNo(FieldNo("Outbound Whse. Handling Time"), CurrFieldNo <> 0);
            end;
        }
        field(5794; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateShippingAgentServiceCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                if xRec."Shipping Agent Service Code" = "Shipping Agent Service Code" then
                    exit;

                GetShippingTime(FieldNo("Shipping Agent Service Code"));
                UpdateSalesLinesByFieldNo(FieldNo("Shipping Agent Service Code"), CurrFieldNo <> 0);
            end;
        }
        field(5795; "Late Order Shipping"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = exist("Sales Line" where("Document Type" = field("Document Type"),
                                                    "Sell-to Customer No." = field("Sell-to Customer No."),
                                                    "Document No." = field("No."),
                                                    "Shipment Date" = field("Date Filter"),
                                                    "Outstanding Quantity" = filter(<> 0)));
            Caption = 'Late Order Shipping';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5796; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5800; Receive; Boolean)
        {
            Caption = 'Receive';
        }
        field(5801; "Return Receipt No."; Code[20])
        {
            Caption = 'Return Receipt No.';
        }
        field(5802; "Return Receipt No. Series"; Code[20])
        {
            Caption = 'Return Receipt No. Series';
            TableRelation = "No. Series";

            trigger OnLookup()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeLookupReturnReceiptNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                SalesHeader := Rec;
                GetSalesSetup();
                SalesSetup.TestField("Posted Return Receipt Nos.");
                if NoSeries.LookupRelatedNoSeries(SalesSetup."Posted Return Receipt Nos.", SalesHeader."Return Receipt No. Series") then
                    SalesHeader.Validate("Return Receipt No. Series");
                Rec := SalesHeader;
            end;

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateReturnReceiptNoSeries(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Return Receipt No. Series" <> '' then begin
                    GetSalesSetup();
                    SalesSetup.TestField("Posted Return Receipt Nos.");
                    NoSeries.TestAreRelated(SalesSetup."Posted Return Receipt Nos.", "Return Receipt No. Series");
                end;
                TestField("Return Receipt No.", '');
            end;
        }
        field(5803; "Last Return Receipt No."; Code[20])
        {
            Caption = 'Last Return Receipt No.';
            Editable = false;
            TableRelation = "Return Receipt Header";
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
                TestStatusOpen();
                MessageIfSalesLinesExist(FieldCaption("Allow Line Disc."));
            end;
        }
        field(7200; "Get Shipment Used"; Boolean)
        {
            Caption = 'Get Shipment Used';
            Editable = false;
        }
        field(9000; "Assigned User ID"; Code[50])
        {
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the ID of the user who is responsible for the document.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";

            trigger OnValidate()
            begin
                if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center", "Assigned User ID") then
                    Error(
                      Text061, "Assigned User ID",
                      RespCenter.TableCaption(), UserSetupMgt.GetSalesFilter("Assigned User ID"));
            end;
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
        key(Key3; "Document Type", "Sell-to Customer No.")
        {
        }
        key(Key4; "Document Type", "Bill-to Customer No.")
        {
        }
        key(Key5; "Document Type", "Combine Shipments", "Sell-to Customer No.", "Bill-to Customer No.", "Currency Code", "EU 3-Party Trade", "Dimension Set ID", "Journal Templ. Name")
        {
        }
        key(Key6; "Sell-to Customer No.", "External Document No.")
        {
        }
        key(Key7; "Document Type", "Sell-to Contact No.")
        {
        }
        key(Key8; "Bill-to Contact No.")
        {
        }
        key(Key9; "Incoming Document Entry No.")
        {
        }
        key(Key10; "Document Date")
        {
        }
        key(Key11; "Shipment Date", Status, "Location Code", "Responsibility Center")
        {
        }
        key(Key12; "Salesperson Code")
        {
        }
        key(Key13; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Sell-to Customer Name", Amount, "Sell-to Contact", "Amount Including VAT")
        {
        }
        fieldgroup(Brick; "No.", "Sell-to Customer Name", Amount, "Sell-to Contact", "Amount Including VAT")
        {
        }
    }

    trigger OnDelete()
    var
        PostSalesDelete: Codeunit "PostSales-Delete";
        ArchiveManagement: Codeunit ArchiveManagement;
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        ShowPostedDocsToPrint: Boolean;
    begin
        if not UserSetupMgt.CheckRespCenter(0, "Responsibility Center") then
            Error(
              Text022,
              RespCenter.TableCaption(), UserSetupMgt.GetSalesFilter());

        OnDeleteOnBeforeArchiveSalesDocument(Rec, xRec);
        ArchiveManagement.AutoArchiveSalesDocument(Rec);
        PostSalesDelete.DeleteHeader(
          Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
          SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt);
        UpdateOpportunity();
        OnDeleteOnAfterPostSalesDeleteDeleteHeader(Rec);

        Validate("Applies-to ID", '');
        Rec.Validate("Incoming Document Entry No.", 0);

        DeleteRecordInApprovalRequest();
        SalesLine.Reset();
        SalesLine.LockTable();

        DeleteWarehouseRequest();

        DeleteAllSalesLines();

        ShowPostedDocsToPrint := (SalesShptHeader."No." <> '') or
           (SalesInvHeader."No." <> '') or
           (SalesCrMemoHeader."No." <> '') or
           (ReturnRcptHeader."No." <> '') or
           (SalesInvHeaderPrepmt."No." <> '') or
           (SalesCrMemoHeaderPrepmt."No." <> '');
        OnBeforeShowPostedDocsToPrintCreatedMsg(ShowPostedDocsToPrint);
        if ShowPostedDocsToPrint then
            Message(PostedDocsToPrintCreatedMsg);

        CRMIntTableSubscriber.MarkArchivedSalesOrder(Rec);
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled, InsertMode);
        if IsHandled then
            exit;

        InitInsert();
        InsertMode := true;

        Rec.SetSellToCustomerFromFilter();

        if GetFilterContNo() <> '' then
            Validate("Sell-to Contact No.", GetFilterContNo());

        if "Sell-to Customer No." <> '' then
            StandardCodesMgtGlobal.CheckCreateSalesRecurringLines(Rec);

        // Remove view filters so that the cards does not show filtered view notification
        SetView('');

        OnAfterOnInsert(Rec);
    end;

    trigger OnRename()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRename(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        Error(Text003, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'You cannot reset %1 because the document still has one or more lines.';
        Text006: Label 'You cannot change %1 because the order is associated with one or more purchase orders.';
        Text007: Label '%1 cannot be greater than %2 in the %3 table.';
        Text009: Label 'Deleting this document will cause a gap in the number series for shipments. An empty shipment %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text012: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text014: Label 'Deleting this document will cause a gap in the number series for posted credit memos. An empty posted credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RecreateSalesLinesMsg: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\\Do you want to continue?', Comment = '%1: FieldCaption';
        ResetItemChargeAssignMsg: Label 'If you change %1, the existing sales lines will be deleted and new sales lines based on the new information on the header will be created.\The amount of the item charge assignment will be reset to 0.\\Do you want to continue?', Comment = '%1: FieldCaption';
#pragma warning disable AA0470
        LinesNotUpdatedMsg: Label 'You have changed %1 on the sales header, but it has not been changed on the existing sales lines.', Comment = 'You have changed Order Date on the sales header, but it has not been changed on the existing sales lines.';
#pragma warning restore AA0470
        LinesNotUpdatedDateMsg: Label 'You have changed the %1 on the sales header, which might affect the prices and discounts on the sales lines. You should review the lines and manually update prices and discounts if needed.', Comment = '%1: OrderDate';
#pragma warning disable AA0074
        Text019: Label 'You must update the existing sales lines manually.';
#pragma warning restore AA0074
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the sales lines.';
#pragma warning disable AA0074
        Text021: Label 'Do you want to update the exchange rate?';
#pragma warning disable AA0470
        Text022: Label 'You cannot delete this document. Your identification is set up to process from %1 %2 only.';
        Text024: Label 'You have modified the %1 field. The recalculation of VAT may cause penny differences, so you must check the amounts afterward. Do you want to update the %2 field on the lines to reflect the new value of %1?';
        Text027: Label 'Your identification is set up to process from %1 %2 only.';
        Text028: Label 'You cannot change the %1 when the %2 has been filled in.';
        Text030: Label 'Deleting this document will cause a gap in the number series for return receipts. An empty return receipt %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text031: Label 'You have modified %1.\\Do you want to update the lines?', Comment = 'You have modified Shipment Date.\\Do you want to update the lines?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MaxAllowedValueIs100Err: Label 'The values must be less than or equal 100.';
        DoYouWantToKeepExistingDimensionsQst: Label 'This will change the dimension specified on the document. Do you want to recalculate/update dimensions?';
        SalesAlreadyExistsTxt: Label 'Sales %1 %2 already exists for this customer.', Comment = '%1 = Document Type; %2 = External Document No.';
        ShowDocAlreadyExistNotificationNameTxt: Label 'Sales document with same external document number already exists.';
        ShowDocAlreadyExistNotificationDescriptionTxt: Label 'Warn if sales document with same external document number already exists.';
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CurrExchRate: Record "Currency Exchange Rate";
        PostCode: Record "Post Code";
        BankAcc: Record "Bank Account";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        SalesInvHeaderPrepmt: Record "Sales Invoice Header";
        SalesCrMemoHeaderPrepmt: Record "Sales Cr.Memo Header";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        RespCenter: Record "Responsibility Center";
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        GenJournalTemplate: Record "Gen. Journal Template";
        GlobalNoSeries: Record "No. Series";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        CompanyInfo: Record "Company Information";
        Salesperson: Record "Salesperson/Purchaser";
        UserSetupMgt: Codeunit "User Setup Management";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        DimMgt: Codeunit DimensionManagement;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        StandardCodesMgtGlobal: Codeunit "Standard Codes Mgt.";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        AltCustVATRegFacade: Codeunit "Alt. Cust. VAT. Reg. Facade";
        CurrencyDate: Date;
        Confirmed: Boolean;
#pragma warning disable AA0074
        Text035: Label 'You cannot Release Quote or Make Order unless you specify a customer on the quote.\\Do you want to create customer(s) now?';
#pragma warning disable AA0470
        Text037: Label 'Contact %1 %2 is not related to customer %3.';
        Text038: Label 'Contact %1 %2 is related to a different company than customer %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        ContactIsNotRelatedToAnyCostomerErr: Label 'Contact %1 %2 is not related to a customer.';
#pragma warning restore AA0470
#pragma warning disable AA0074
        Text040: Label 'A won opportunity is linked to this order.\It has to be changed to status Lost before the Order can be deleted.\Do you want to change the status for this opportunity now?';
        Text044: Label 'The status of the opportunity has not been changed. The program has aborted deleting the order.';
#pragma warning disable AA0470
        Text045: Label 'You can not change the %1 field because %2 %3 has %4 = %5 and the %6 has already been assigned %7 %8.';
        Text048: Label 'Sales quote %1 has already been assigned to opportunity %2. Would you like to reassign this quote?';
        Text049: Label 'The %1 field cannot be blank because this quote is linked to an opportunity.';
        Text051: Label 'The sales %1 %2 already exists.';
        Text053: Label 'You must cancel the approval process if you wish to change the %1.';
        Text056: Label 'Deleting this document will cause a gap in the number series for prepayment invoices. An empty prepayment invoice %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text057: Label 'Deleting this document will cause a gap in the number series for prepayment credit memos. An empty prepayment credit memo %1 will be created to fill this gap in the number series.\\Do you want to continue?';
        Text061: Label '%1 is set up to process from %2 %3 only.';
        Text062: Label 'You cannot change %1 because the corresponding %2 %3 has been assigned to this %4.';
#pragma warning restore AA0470
        Text063: Label 'Reservations exist for this order. These reservations will be canceled if a date conflict is caused by this change.\\Do you want to continue?';
        Text064: Label 'You may have changed a dimension.\\Do you want to update the lines?';
#pragma warning disable AA0470
        Text066: Label 'You cannot change %1 to %2 because an open inventory pick on the %3.';
        Text070: Label 'You cannot change %1  to %2 because an open warehouse shipment exists for the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        BilltoCustomerNoChanged: Boolean;
        SelectNoSeriesAllowed: Boolean;
#pragma warning disable AA0470
        PrepaymentInvoicesNotPaidErr: Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are posted.', Comment = 'You cannot post the document of type Order with the number 1001 before all related prepayment invoices are posted.';
#pragma warning restore AA0470
        StatisticsInsuffucientPermissionsErr: Label 'You don''t have permission to view statistics.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text072: Label 'There are unpaid prepayment invoices related to the document of type %1 with the number %2.';
        DifferentDatesQst: Label 'Posting Date %1 is different from Work Date %2.\\Do you want to continue?', Comment = '%1 - Posting Date, %2 - work date';
        DifferentDatesErr: Label 'Posting Date %1 is different from Work Date %2.\\Batch posting cannot be used.', Comment = '%1 - Posting Date, %2 - work date';
#pragma warning restore AA0470
#pragma warning restore AA0074
        DeferralLineQst: Label 'Do you want to update the deferral schedules for the lines?';
#pragma warning disable AA0470
        SynchronizingMsg: Label 'Synchronizing ...\ from: Sales Header with %1\ to: Assembly Header with %2.';
#pragma warning restore AA0470
        ShippingAdviceErr: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        DocumentNotPostedClosePageQst: Label 'The document has been saved but is not yet posted.\\Are you sure you want to exit?';
        SelectCustomerTemplateQst: Label 'Do you want to select the customer template?';
        ModifyCustomerAddressNotificationLbl: Label 'Update the address';
        DontShowAgainActionLbl: Label 'Don''t show again';
        ModifyCustomerAddressNotificationMsg: Label 'The address you entered for %1 is different from the customer''s existing address.', Comment = '%1=customer name';
        ValidVATNoMsg: Label 'The specified VAT registration number is valid.';
        InvalidVatRegNoMsg: Label 'The VAT registration number is not valid. Try entering the number again.';
        SellToCustomerTxt: Label 'Sell-to Customer';
        BillToCustomerTxt: Label 'Bill-to Customer';
        ModifySellToCustomerAddressNotificationNameTxt: Label 'Update Sell-to Customer Address';
        ModifySellToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the sell-to address on sales documents is different from the customer''s existing address.';
        ModifyBillToCustomerAddressNotificationNameTxt: Label 'Update Bill-to Customer Address';
        ModifyBillToCustomerAddressNotificationDescriptionTxt: Label 'Warn if the bill-to address on sales documents is different from the customer''s existing address.';
        DuplicatedCaptionsNotAllowedErr: Label 'Field captions must not be duplicated when using this method. Use UpdateSalesLinesByFieldNo instead.';
        PhoneNoCannotContainLettersErr: Label 'You cannot enter letters in this field.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        ConfirmEmptyEmailQst: Label 'Contact %1 has no email address specified. The value in the Email field on the sales order, %2, will be deleted. Do you want to continue?', Comment = '%1 - Contact No., %2 - Email';
        FullSalesTypesTxt: Label 'Sales Quote,Sales Order,Sales Invoice,Sales Credit Memo,Sales Blanket Order,Sales Return Order';
        RecreateSalesLinesCancelErr: Label 'Change in the existing sales lines for the field %1 is cancelled by user.', Comment = '%1 - Field Name, Sample: You must delete the existing sales lines before you can change Currency Code.';
        SalesLinesCategoryLbl: Label 'Sales Lines', Locked = true;
        SalesHeaderIsTemporaryLbl: Label 'Sales Header must be not temporary.', Locked = true;
        SalesHeaderDoesNotExistLbl: Label 'Sales Header must exist.', Locked = true;
        SalesHeaderCannotModifyLbl: Label 'Cannot modify Sales Header.', Locked = true;
        WarnZeroQuantitySalesPostingTxt: Label 'Warn before posting Sales lines with 0 quantity';
        WarnZeroQuantitySalesPostingDescriptionTxt: Label 'Warn before posting lines on Sales documents where quantity is 0.';
        CalledFromWhseDoc: Boolean;
        DocumentNotOpenErr: Label 'The document''s status must be Open. To change the status, use the Reopen action.';
#if not CLEAN26
        SkipStatsPrep: Boolean;
#endif

    protected var
        Customer: Record Customer;
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        HideCreditCheckDialogue: Boolean;
        HideValidationDialog: Boolean;
        InsertMode: Boolean;
        StatusCheckSuspended: Boolean;
        UpdateDocumentDate: Boolean;
        SkipSellToContact: Boolean;
        SkipBillToContact: Boolean;
        SkipTaxCalculation: Boolean;

    /// <summary>
    /// Initializes a new sales header with a new document number from the number series.
    /// </summary>
    procedure InitInsert()
    var
        SalesHeader2: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitInsert(Rec, xRec, IsHandled);
        if not IsHandled then
            if "No." = '' then begin
                TestNoSeries();
                NoSeriesCode := GetNoSeriesCode();
                "No. Series" := NoSeriesCode;
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
                SalesHeader2.ReadIsolation(IsolationLevel::ReadUncommitted);
                SalesHeader2.SetLoadFields("No.");
                while SalesHeader2.Get("Document Type", "No.") do
                    "No." := NoSeries.GetNextNo("No. Series", "Posting Date");
            end;

        OnInitInsertOnBeforeInitRecord(Rec, xRec);
        InitRecord();
    end;

    /// <summary>
    /// Initializes a new sales header with default values.
    /// </summary>
    procedure InitRecord()
    var
        ShipToAddress: Record "Ship-to Address";
        ArchiveManagement: Codeunit ArchiveManagement;
        LocationCode: Code[10];
        IsHandled: Boolean;
        NewOrderDate: Date;
    begin
        GetSalesSetup();
        IsHandled := false;
        OnBeforeInitRecord(Rec, IsHandled, xRec);
        if not IsHandled then
            InitPostingNoSeries();

        InitShipmentDate();

        InitPostingDate();

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then
            "Posting Date" := 0D;
        NewOrderDate := WorkDate();
        OnInitRecordOnBeforeAssignOrderDate(Rec, NewOrderDate);
        "Order Date" := NewOrderDate;
        UpdateDocumentDateFromLinkedPostingDate(false);
        if Rec."Document Date" = 0D then
            "Document Date" := WorkDate();
        if "Document Type" = "Document Type"::Quote then
            CalcQuoteValidUntilDate();

        if "Sell-to Customer No." <> '' then
            GetCust("Sell-to Customer No.");
        LocationCode := Customer."Location Code";
        AltCustVATRegFacade.Init(Rec, xRec);
        if "Ship-to Code" <> '' then begin
            ShipToAddress.SetLoadFields("Location Code");
            if ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code") then
                if ShipToAddress."Location Code" <> '' then
                    LocationCode := ShipToAddress."Location Code";
        end;
        UpdateLocationCode(LocationCode);

        if IsCreditDocType() then begin
            GLSetup.Get();
            Correction := GLSetup."Mark Cr. Memos as Corrections";
        end;

        InitVATDate();
        InitPostingDescription();

        UpdateOutboundWhseHandlingTime();

        IsHandled := false;
        OnInitRecordOnBeforeAssignResponsibilityCenter(Rec, IsHandled);
        if not IsHandled then
            "Responsibility Center" := UserSetupMgt.GetRespCenter(0, "Responsibility Center");

        IsHandled := false;
        OnInitRecordOnBeforeGetNextArchiveDocOccurrenceNo(Rec, IsHandled);
        if not IsHandled then
            "Doc. No. Occurrence" := ArchiveManagement.GetNextOccurrenceNo(DATABASE::"Sales Header", Rec."Document Type".AsInteger(), Rec."No.");

        OnAfterInitRecord(Rec);
    end;

    local procedure InitShipmentDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitRecordOnBeforeAssignShipmentDate(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" in ["Document Type"::Order, "Document Type"::Invoice, "Document Type"::Quote] then
            "Shipment Date" := WorkDate();
    end;

    local procedure InitVATDate()
    begin
        "VAT Reporting Date" := GLSetup.GetVATDate("Posting Date", "Document Date");
    end;

    local procedure InitPostingDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInitRecordOnBeforeAssignWorkDateToPostingDate(Rec, IsHandled);
        if IsHandled then
            exit;

        if not ("Document Type" in ["Document Type"::"Blanket Order", "Document Type"::Quote]) and
           ("Posting Date" = 0D)
        then
            "Posting Date" := WorkDate();
    end;

    local procedure InitializeRoundingPrecision(var Currency: Record Currency)
    begin
        if "Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get("Currency Code");

        OnAfterInitializeRoundingPrecision(Rec, Currency);
    end;

    local procedure InitNoSeries()
    begin
        if xRec."Shipping No." <> '' then begin
            "Shipping No. Series" := xRec."Shipping No. Series";
            "Shipping No." := xRec."Shipping No.";
        end;
        if xRec."Posting No." <> '' then begin
            "Posting No. Series" := xRec."Posting No. Series";
            "Posting No." := xRec."Posting No.";
        end;
        if xRec."Return Receipt No." <> '' then begin
            "Return Receipt No. Series" := xRec."Return Receipt No. Series";
            "Return Receipt No." := xRec."Return Receipt No.";
        end;
        if xRec."Prepayment No." <> '' then begin
            "Prepayment No. Series" := xRec."Prepayment No. Series";
            "Prepayment No." := xRec."Prepayment No.";
        end;
        if xRec."Prepmt. Cr. Memo No." <> '' then begin
            "Prepmt. Cr. Memo No. Series" := xRec."Prepmt. Cr. Memo No. Series";
            "Prepmt. Cr. Memo No." := xRec."Prepmt. Cr. Memo No.";
        end;

        OnAfterInitNoSeries(Rec, xRec);
    end;

    /// <summary>
    /// Initializes the posting description with formatted document type and number text for the sales header.
    /// </summary>
    procedure InitPostingDescription()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPostingDescription(Rec, IsHandled);
        if IsHandled then
            exit;

        "Posting Description" := Format("Document Type") + ' ' + "No.";
    end;

    /// <summary>
    /// Sets global StandardCodesMgtGlobal codeunit to a new instance.
    /// </summary>
    /// <remarks>
    /// StandardCodesMgtGlobal codeunit is used to check whether sales recurring lines should be applied for sales document,
    /// if necessary, creates a sales line on insert sales header.
    /// </remarks>
    /// <param name="StandardCodesMgtNew">The new codeunit instance to set.</param>
    procedure SetStandardCodesMgt(var StandardCodesMgtNew: Codeunit "Standard Codes Mgt.")
    begin
        StandardCodesMgtGlobal := StandardCodesMgtNew;
    end;

    /// <summary>
    /// Opens a page to select related number series for the sales header and updates the document number with the selected number series.
    /// </summary>
    /// <param name="OldSalesHeader">
    /// Sales header record before the change. The no series code from this record will be highlighted by default on the open page.
    /// </param>
    /// <returns>True if the document number has changed, otherwise false.</returns>
    procedure AssistEdit(OldSalesHeader: Record "Sales Header") Result: Boolean
    var
        SalesHeader2: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldSalesHeader, IsHandled, Result);
        if IsHandled then
            exit;

        SalesHeader.Copy(Rec);
        GetSalesSetup();
        SalesHeader.TestNoSeries();
        if NoSeries.LookupRelatedNoSeries(SalesHeader.GetNoSeriesCode(), OldSalesHeader."No. Series", SalesHeader."No. Series") then begin
            if (SalesHeader."Sell-to Customer No." = '') and (SalesHeader."Sell-to Contact No." = '') then begin
                HideCreditCheckDialogue := false;
                Rec.CheckCreditMaxBeforeInsert();
                HideCreditCheckDialogue := true;
            end;
            SalesHeader."No." := NoSeries.GetNextNo(SalesHeader."No. Series");
            if SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.") then
                Error(Text051, LowerCase(Format(SalesHeader."Document Type")), SalesHeader."No.");
            Rec := SalesHeader;
            exit(true);
        end;
    end;

    /// <summary>
    /// Checks if the number series for different types of sales documents are filled in the sales setup.
    /// </summary>
    procedure TestNoSeries()
    var
        IsHandled: Boolean;
    begin
        GetSalesSetup();
        IsHandled := false;
        OnBeforeTestNoSeries(Rec, IsHandled);
        if not IsHandled then begin
            case "Document Type" of
                "Document Type"::Quote:
                    SalesSetup.TestField("Quote Nos.");
                "Document Type"::Order:
                    SalesSetup.TestField("Order Nos.");
                "Document Type"::Invoice:
                    SalesSetup.TestField("Invoice Nos.");
                "Document Type"::"Return Order":
                    SalesSetup.TestField("Return Order Nos.");
                "Document Type"::"Credit Memo":
                    SalesSetup.TestField("Credit Memo Nos.");
                "Document Type"::"Blanket Order":
                    SalesSetup.TestField("Blanket Order Nos.");
            end;
            GLSetup.GetRecordOnce();
            if not GLSetup."Journal Templ. Name Mandatory" then
                case "Document Type" of
                    "Document Type"::Invoice:
                        SalesSetup.TestField("Posted Invoice Nos.");
                    "Document Type"::"Credit Memo":
                        SalesSetup.TestField("Posted Credit Memo Nos.");
                end
            else begin
                SalesSetup.GetRecordOnce();
                if not IsCreditDocType() then begin
                    SalesSetup.TestField("S. Invoice Template Name");
                    if "Journal Templ. Name" = '' then
                        GenJournalTemplate.Get(SalesSetup."S. Invoice Template Name")
                    else
                        GenJournalTemplate.Get("Journal Templ. Name");
                end else begin
                    SalesSetup.TestField("S. Cr. Memo Template Name");
                    if "Journal Templ. Name" = '' then
                        GenJournalTemplate.Get(SalesSetup."S. Cr. Memo Template Name")
                    else
                        GenJournalTemplate.Get("Journal Templ. Name");
                end;
                GenJournalTemplate.TestField("Posting No. Series");
                GlobalNoSeries.Get(GenJournalTemplate."Posting No. Series");
                GlobalNoSeries.TestField("Default Nos.", true);
            end;
        end;

        OnAfterTestNoSeries(Rec, SalesSetup);
    end;

    /// <summary>
    /// Returns the number series code from the sales setup based on the document type of the sales header.
    /// </summary>
    /// <returns>Number series code.</returns>
    procedure GetNoSeriesCode(): Code[20]
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        IsHandled: Boolean;
    begin
        GetSalesSetup();
        IsHandled := false;
        OnBeforeGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode, IsHandled);
        if IsHandled then
            exit(NoSeriesCode);

        case "Document Type" of
            "Document Type"::Quote:
                NoSeriesCode := SalesSetup."Quote Nos.";
            "Document Type"::Order:
                NoSeriesCode := SalesSetup."Order Nos.";
            "Document Type"::Invoice:
                NoSeriesCode := SalesSetup."Invoice Nos.";
            "Document Type"::"Return Order":
                NoSeriesCode := SalesSetup."Return Order Nos.";
            "Document Type"::"Credit Memo":
                NoSeriesCode := SalesSetup."Credit Memo Nos.";
            "Document Type"::"Blanket Order":
                NoSeriesCode := SalesSetup."Blanket Order Nos.";
        end;
        OnAfterGetNoSeriesCode(Rec, SalesSetup, NoSeriesCode);
        if not SelectNoSeriesAllowed then
            exit(NoSeriesCode);

        if NoSeries.IsAutomatic(NoSeriesCode) then
            exit(NoSeriesCode);

        if NoSeries.HasRelatedSeries(NoSeriesCode) then
            if NoSeries.LookupRelatedNoSeries(NoSeriesCode, "No. Series") then
                exit("No. Series");

        exit(NoSeriesCode);
    end;

    local procedure GetPostingNoSeriesCode() PostingNos: Code[20]
    var
        IsHandled: Boolean;
    begin
        GetSalesSetup();
        IsHandled := false;
        OnBeforeGetPostingNoSeriesCode(Rec, SalesSetup, PostingNos, IsHandled);
        if IsHandled then
            exit;

        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            GenJournalTemplate.Get("Journal Templ. Name");
            PostingNos := GenJournalTemplate."Posting No. Series";
        end else
            if IsCreditDocType() then
                PostingNos := SalesSetup."Posted Credit Memo Nos."
            else
                PostingNos := SalesSetup."Posted Invoice Nos.";

        OnAfterGetPostingNoSeriesCode(Rec, PostingNos);
    end;

    local procedure GetPostingPrepaymentNoSeriesCode() PostingNos: Code[20]
    begin
        if IsCreditDocType() then
            PostingNos := SalesSetup."Posted Prepmt. Cr. Memo Nos."
        else
            PostingNos := SalesSetup."Posted Prepmt. Inv. Nos.";

        OnAfterGetPrepaymentPostingNoSeriesCode(Rec, PostingNos);
    end;

    /// <summary>
    /// Checks if the number series has to be assigned chronologically after various documents are already posted.
    /// </summary>
    /// <param name="No">Posted document number.</param>
    /// <param name="NoSeriesCode">Number series code to check.</param>
    /// <param name="NoCapt">Posted document number field caption.</param>
    /// <param name="NoSeriesCapt">Number series field caption.</param>
    procedure TestNoSeriesDate(No: Code[20]; NoSeriesCode: Code[20]; NoCapt: Text[1024]; NoSeriesCapt: Text[1024])
    begin
        if (No <> '') and (NoSeriesCode <> '') then begin
            GlobalNoSeries.Get(NoSeriesCode);
            if GlobalNoSeries."Date Order" then
                Error(
                  Text045,
                  FieldCaption("Posting Date"), NoSeriesCapt, NoSeriesCode,
                  GlobalNoSeries.FieldCaption("Date Order"), GlobalNoSeries."Date Order", "Document Type",
                  NoCapt, No);
        end;
    end;

    /// <summary>
    /// Opens a confirmation dialog to confirm the deletion of the sales header.
    /// This check is to confirm with the user that gaps will happen in the posted documents if the document is deleted.
    /// </summary>
    /// <returns>True if sales header should be deleted, otherwise false.</returns>
    procedure ConfirmDeletion() Result: Boolean
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        PostSalesDelete: Codeunit "PostSales-Delete";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmDeletion(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Deleted Document");
        SourceCode.Get(SourceCodeSetup."Deleted Document");

        PostSalesDelete.InitDeleteHeader(
          Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader,
          SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt, SourceCode.Code);

        exit(CheckNoAndShowConfirm(SourceCode));
    end;

    local procedure EnsureDocumentTypeIsQuote()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureDocumentTypeIsQuote(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        TestField("Document Type", "Document Type"::Quote);
    end;

    local procedure CheckNoAndShowConfirm(SourceCode: Record "Source Code") Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoAndShowConfirm(Rec, SalesShptHeader, SalesInvHeader, SalesCrMemoHeader, ReturnRcptHeader, SalesInvHeaderPrepmt, SalesCrMemoHeaderPrepmt, SourceCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesShptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text009, SalesShptHeader."No."), true) then
                exit;
        if SalesInvHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text012, SalesInvHeader."No."), true) then
                exit;
        if SalesCrMemoHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text014, SalesCrMemoHeader."No."), true) then
                exit;
        if ReturnRcptHeader."No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text030, ReturnRcptHeader."No."), true) then
                exit;
        if "Prepayment No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text056, SalesInvHeaderPrepmt."No."), true) then
                exit;
        if "Prepmt. Cr. Memo No." <> '' then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text057, SalesCrMemoHeaderPrepmt."No."), true) then
                exit;
        exit(true);
    end;

    /// <summary>
    /// Updates the global Customer record. Record will not be retrieved if document type is quote and provided customer no is blank.
    /// </summary>
    /// <param name="CustNo">Customer number to retrieve the record for.</param>
    /// <returns>Retrieved customer record.</returns>
    procedure GetCust(CustNo: Code[20]): Record Customer
    begin
        OnBeforeGetCust(Rec, Customer, CustNo);

        if not (("Document Type" = "Document Type"::Quote) and (CustNo = '')) then begin
            if CustNo <> Customer."No." then
                Customer.Get(CustNo);
        end else
            Clear(Customer);

        exit(Customer);
    end;

    local procedure GetSalesSetup()
    begin
        SalesSetup.Get();
        OnAfterGetSalesSetup(Rec, SalesSetup, CurrFieldNo);
    end;

    /// <summary>
    /// Checks if any sales lines exists for sales header.
    /// </summary>
    /// <returns>True if sales lines exists, otherwise false.</returns>
    procedure SalesLinesExist(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLinesExist(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        exit(not SalesLine.IsEmpty());
    end;

    local procedure ResetInvoiceDiscountValue()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeResetInvoiceDiscountValue(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Invoice Discount Value" <> 0 then begin
            CalcFields("Invoice Discount Amount");
            if "Invoice Discount Amount" = 0 then
                "Invoice Discount Value" := 0;
        end;
    end;

    /// <summary>
    /// Recreates sales lines for a sales document when the provided field in the sales header is changed.
    /// </summary>
    /// <remarks>
    /// Opens confirmation dialog to confirm the deletion of existing sales lines
    /// and then recreates the sales lines based on the new information in the sales header.
    /// It also handles item charge assignments and extended text lines.
    /// </remarks>
    /// <param name="ChangedFieldName">
    /// Name of the field that is changed.
    /// This name is used only in error messages and confirmation dialogs.
    /// </param>
    procedure RecreateSalesLines(ChangedFieldName: Text[100])
    var
        TempSalesLine: Record "Sales Line" temporary;
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
        TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary;
        TempInteger: Record "Integer" temporary;
        TempATOLink: Record "Assemble-to-Order Link" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        TempSalesCommentLine: Record "Sales Comment Line" temporary;
        TempReqLine: Record "Requisition Line" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        ExtendedTextAdded: Boolean;
        ConfirmText: Text;
        IsHandled: Boolean;
    begin
        if not SalesLinesExist() then
            exit;

        IsHandled := false;
        OnBeforeRecreateSalesLinesHandler(Rec, xRec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnRecreateSalesLinesOnBeforeConfirm(Rec, xRec, ChangedFieldName, HideValidationDialog, Confirmed, IsHandled);
        if not IsHandled then
            if GetHideValidationDialog() or not GuiAllowed() then
                Confirmed := true
            else begin
                if HasItemChargeAssignment() then
                    ConfirmText := ResetItemChargeAssignMsg
                else
                    ConfirmText := RecreateSalesLinesMsg;
                Confirmed := Confirm(ConfirmText, false, ChangedFieldName);
            end;

        if Confirmed then begin
            SalesLine.LockTable();
            ItemChargeAssgntSales.LockTable();
            ReservEntry.LockTable();
            Modify();
            OnBeforeRecreateSalesLines(Rec);
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", "Document Type");
            SalesLine.SetRange("Document No.", "No.");
            OnRecreateSalesLinesOnAfterSetSalesLineFilters(SalesLine, Rec);
            if SalesLine.FindSet() then begin
                OnRecreateSalesLinesOnAfterFindSalesLine(Rec, SalesLine, ChangedFieldName);
                TempReservEntry.DeleteAll();
                RecreateReservEntryReqLine(TempSalesLine, TempATOLink, ATOLink, TempReqLine);
                StoreSalesCommentLineToTemp(TempSalesCommentLine);
                SalesCommentLine.DeleteComments("Document Type".AsInteger(), "No.");
                TransferItemChargeAssgntSalesToTemp(ItemChargeAssgntSales, TempItemChargeAssgntSales);
                IsHandled := false;
                OnRecreateSalesLinesOnBeforeSalesLineDeleteAll(Rec, SalesLine, CurrFieldNo, IsHandled);
                if not IsHandled then
                    SalesLine.DeleteAll(true);

                SalesLine.Init();
                SalesLine."Line No." := 0;
                OnRecreateSalesLinesOnBeforeTempSalesLineFindSet(TempSalesLine);
                TempSalesLine.FindSet();
                ExtendedTextAdded := false;
                SalesLine.BlockDynamicTracking(true);
                repeat
                    RecreateSalesLinesHandleSupplementTypes(TempSalesLine, ExtendedTextAdded, TempItemChargeAssgntSales, TempInteger);
                    RestoreSalesCommentLine(TempSalesCommentLine, TempSalesLine."Line No.", SalesLine."Line No.");
                    OnRecreateSalesLinesOnBeforeCopyReservEntryFromTemp(SalesLine, TempSalesLine, Rec, xRec, ChangedFieldName);
                    SalesLineReserve.CopyReservEntryFromTemp(TempReservEntry, TempSalesLine, SalesLine."Line No.");
                    RecreateReqLine(TempReqLine, TempSalesLine, SalesLine."Line No.", false);
                    SynchronizeForReservations(SalesLine, TempSalesLine);

                    if TempATOLink.AsmExistsForSalesLine(TempSalesLine) then begin
                        ATOLink := TempATOLink;
                        ATOLink."Document Line No." := SalesLine."Line No.";
                        ATOLink.Insert();
                        ATOLink.UpdateAsmFromSalesLineATOExist(SalesLine);
                        TempATOLink.Delete();
                    end;
                until TempSalesLine.Next() = 0;

                OnRecreateSalesLinesOnAfterProcessTempSalesLines(TempSalesLine, Rec, xRec, ChangedFieldName);

                RestoreSalesCommentLine(TempSalesCommentLine, 0, 0);

                CreateItemChargeAssgntSales(TempItemChargeAssgntSales, TempSalesLine, TempInteger);

                TempSalesLine.SetRange(Type);
                TempSalesLine.DeleteAll();
                OnAfterDeleteAllTempSalesLines(Rec);
                ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
                TempItemChargeAssgntSales.DeleteAll();
            end;
        end else
            Error(RecreateSalesLinesCancelErr, ChangedFieldName);

        SalesLine.BlockDynamicTracking(false);

        OnAfterRecreateSalesLines(Rec, ChangedFieldName);
    end;

    local procedure RecreateSalesLinesHandleSupplementTypes(var TempSalesLine: Record "Sales Line" temporary; var ExtendedTextAdded: Boolean; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempInteger: Record "Integer" temporary)
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        IsHandled: Boolean;
        ShouldCreateSalsesLine: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecreateSalesLinesHandleSupplementTypes(TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        ShouldCreateSalsesLine := not TempSalesLine.IsExtendedText();
        OnRecreateSalesLinesHandleSupplementTypesOnAfterCalcShouldCreateSalsesLine(TempSalesLine, ShouldCreateSalsesLine, SalesLine);
        if ShouldCreateSalsesLine then begin
            CreateSalesLine(TempSalesLine);
            ExtendedTextAdded := false;
            OnAfterRecreateSalesLine(SalesLine, TempSalesLine, Rec);

            if SalesLine.Type = SalesLine.Type::Item then
                RecreateSalesLinesFillItemChargeAssignment(SalesLine, TempSalesLine, TempItemChargeAssgntSales);

            if SalesLine.Type = SalesLine.Type::"Charge (Item)" then begin
                TempInteger.Init();
                TempInteger.Number := SalesLine."Line No.";
                TempInteger.Insert();
            end;

            OnRecreateSalesLinesHandleSupplementTypesOnAfterCreateSalesLine(Rec, SalesLine, TempSalesLine);
        end else
            if not ExtendedTextAdded then begin
                TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
                TransferExtendedText.InsertSalesExtText(SalesLine);
                OnAfterTransferExtendedTextForSalesLineRecreation(SalesLine, TempSalesLine);

                SalesLine.FindLast();
                ExtendedTextAdded := true;
            end;

        OnAfterRecreateSalesLinesHandleSupplementTypes(Rec);
    end;

    /// <summary>
    /// Inserts existing sales comment lines into a temporary record.
    /// </summary>
    /// <param name="TempSalesCommentLine">Return value: Inserted sales comment lines.</param>
    procedure StoreSalesCommentLineToTemp(var TempSalesCommentLine: Record "Sales Comment Line" temporary)
    var
        SalesCommentLine: Record "Sales Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeStoreSalesCommentLineToTemp(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        if SalesCommentLine.FindSet() then
            repeat
                TempSalesCommentLine := SalesCommentLine;
                TempSalesCommentLine.Insert();
            until SalesCommentLine.Next() = 0;
    end;

    /// <summary>
    /// Inserts sales comment lines for the sales line of the document.
    /// Lines are inserted from the provided temporary sales comment line record set.
    /// </summary>
    /// <param name="TempSalesCommentLine">Temporary sales comment line record set to insert.</param>
    /// <param name="OldDocumnetLineNo">Previous sales line number.</param>
    /// <param name="NewDocumentLineNo">New sales line number.</param>
    procedure RestoreSalesCommentLine(var TempSalesCommentLine: Record "Sales Comment Line" temporary; OldDocumnetLineNo: Integer; NewDocumentLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        TempSalesCommentLine.SetRange("Document Type", "Document Type");
        TempSalesCommentLine.SetRange("No.", "No.");
        TempSalesCommentLine.SetRange("Document Line No.", OldDocumnetLineNo);
        if TempSalesCommentLine.FindSet() then
            repeat
                SalesCommentLine := TempSalesCommentLine;
                SalesCommentLine."Document Line No." := NewDocumentLineNo;
                SalesCommentLine.Insert();
            until TempSalesCommentLine.Next() = 0;
    end;

    local procedure RecreateSalesLinesFillItemChargeAssignment(SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type", TempSalesLine."Document Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.", TempSalesLine."Document No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.", TempSalesLine."Line No.");
        if TempItemChargeAssgntSales.FindSet() then
            repeat
                if not TempItemChargeAssgntSales.Mark() then begin
                    TempItemChargeAssgntSales."Applies-to Doc. Line No." := SalesLine."Line No.";
                    TempItemChargeAssgntSales.Description := SalesLine.Description;
                    TempItemChargeAssgntSales.Modify();
                    TempItemChargeAssgntSales.Mark(true);
                end;
            until TempItemChargeAssgntSales.Next() = 0;
    end;

    /// <summary>
    /// Displays a message if sales lines exist for the sales header and the changed field was not updated on the lines.
    /// </summary>
    /// <remarks>
    /// Message states that the user must update the existing sales lines manually.
    /// </remarks>
    /// <param name="ChangedFieldName">Changed sales header field caption.</param>
    procedure MessageIfSalesLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMessageIfSalesLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if SalesLinesExist() and not GetHideValidationDialog() then begin
            MessageText := StrSubstNo(LinesNotUpdatedMsg, ChangedFieldName);
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, Text019);
            Message(MessageText);
        end;
    end;

    /// <summary>
    /// Displays a message to the user if there are existing sales lines and a provided field in the sales header has been changed,
    /// which might affect the prices and discounts on the sales lines.
    /// </summary>
    /// <param name="ChangedFieldName">Changed sales header field caption.</param>
    procedure PriceMessageIfSalesLinesExist(ChangedFieldName: Text[100])
    var
        MessageText: Text;
        IsHandled: Boolean;
    begin
        OnBeforePriceMessageIfSalesLinesExist(Rec, ChangedFieldName, IsHandled);
        if IsHandled then
            exit;

        if SalesLinesExist() and not GetHideValidationDialog() then begin
            MessageText := StrSubstNo(LinesNotUpdatedDateMsg, ChangedFieldName);
            if "Currency Code" <> '' then
                MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
            Message(MessageText);
        end;
    end;

    /// <summary>
    /// Updates currency factor on the sales header and recreates sales lines if the currency code has changed.
    /// </summary>
    procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        Updated: Boolean;
    begin
        OnBeforeUpdateCurrencyFactor(Rec, Updated, CurrExchRate, xRec);
        if Updated then
            exit;

        if "Currency Code" <> '' then begin
            if Rec."Posting Date" <> 0D then
                CurrencyDate := "Posting Date"
            else
                CurrencyDate := WorkDate();

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, "Currency Code") then begin
                "Currency Factor" := CurrExchRate.ExchangeRate(CurrencyDate, "Currency Code");
                if ("Currency Code" <> xRec."Currency Code") and (xRec."No." <> '') then
                    RecreateSalesLines(FieldCaption("Currency Code"));
            end else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Currency Code");
        end else begin
            "Currency Factor" := 0;
            if "Currency Code" <> xRec."Currency Code" then
                RecreateSalesLines(FieldCaption("Currency Code"));
        end;

        OnAfterUpdateCurrencyFactor(Rec, GetHideValidationDialog());
    end;

    /// <summary>
    /// Updates currency factor on the sales header if confirmed by the user.
    /// </summary>
    procedure ConfirmCurrencyFactorUpdate()
    var
        IsHandled: Boolean;
        ForceConfirm: Boolean;
    begin
        IsHandled := false;
        ForceConfirm := false;
        OnBeforeConfirmUpdateCurrencyFactor(Rec, HideValidationDialog, xRec, IsHandled, ForceConfirm);
        if IsHandled then
            exit;

        if GetHideValidationDialog() or not GuiAllowed() or ForceConfirm then
            Confirmed := true
        else
            Confirmed := Confirm(Text021, false);
        if Confirmed then
            Validate("Currency Factor")
        else
            "Currency Factor" := xRec."Currency Factor";

        OnAfterConfirmCurrencyFactorUpdate(Rec, Confirmed);
    end;

    /// <summary>
    /// Sets the value of the global flag HideValidationDialog.
    /// </summary>
    /// <remarks>
    /// Global flag HideValidationDialog is used to hide various confirmation/message/other dialogs.
    /// </remarks>
    /// <param name="NewHideValidationDialog">The new value to set.</param>
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    /// <summary>
    /// Returns the value of the global flag HideValidationDialog.
    /// </summary>
    /// <remarks>
    /// Global flag HideValidationDialog is used to hide various confirmation/message/other dialogs.
    /// </remarks>
    /// <returns>The value of the global flag HideValidationDialog.</returns>
    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    /// <summary>
    /// Sets the value of the global flag HideCreditCheckDialogue.
    /// </summary>
    /// <remarks>
    /// Global flag HideCreditCheckDialogue is used to hide exceeded credit limit notification in sales document.
    /// </remarks>
    /// <param name="NewHideCreditCheckDialogue">The new value to set.</param>
    procedure SetHideCreditCheckDialogue(NewHideCreditCheckDialogue: Boolean)
    begin
        HideCreditCheckDialogue := NewHideCreditCheckDialogue;
    end;

    /// <summary>
    /// Returns the value of the global flag HideCreditCheckDialogue.
    /// </summary>
    /// <remarks>
    /// Global flag HideCreditCheckDialogue is used to hide exceeded credit limit notification in sales document.
    /// </remarks>
    /// <returns>The value of the global flag HideCreditCheckDialogue.</returns>
    procedure GetHideCreditCheckDialogue(): Boolean
    begin
        exit(HideCreditCheckDialogue);
    end;

    local procedure UpdateDirectDebitPmtTermsCode()
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDirectDebitPmtTermsCode(Rec, IsHandled, PaymentMethod);
        if IsHandled then
            exit;

        PaymentMethod.Init();
        if "Payment Method Code" <> '' then
            PaymentMethod.Get("Payment Method Code");
        if PaymentMethod."Direct Debit" then begin
            "Direct Debit Mandate ID" := SEPADirectDebitMandate.GetDefaultMandate("Bill-to Customer No.", "Due Date");
            if "Payment Terms Code" = '' then
                "Payment Terms Code" := PaymentMethod."Direct Debit Pmt. Terms Code";
        end else
            "Direct Debit Mandate ID" := '';
    end;

    /// <summary>
    /// Updates the location code with the specified location code. If it's empty, it takes location code from user setup management.
    /// </summary>
    /// <param name="LocationCode">New location code.</param>
    procedure UpdateLocationCode(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLocationCode(Rec, LocationCode, IsHandled);
        if not IsHandled then
            Validate("Location Code", UserSetupMgt.GetLocation(0, LocationCode, "Responsibility Center"));
    end;

    /// <summary>
    /// Updates sales lines to reflect changes in the sales header field.
    /// Optionally the confirmation is raised, for the user to confirm the update of lines.
    /// </summary>
    /// <remarks>
    /// Field captions must not be duplicated in the sales header, otherwise an error will be raised.
    /// </remarks>
    /// <param name="ChangedFieldName">Changed sales header field caption.</param>
    /// <param name="AskQuestion">
    /// If true, a confirmation message is shown to update the lines, otherwise confirmation is not shown.
    /// </param>
    procedure UpdateSalesLines(ChangedFieldName: Text[100]; AskQuestion: Boolean)
    var
        "Field": Record "Field";
    begin
        OnBeforeUpdateSalesLines(Rec, ChangedFieldName, AskQuestion);

        Field.SetRange(TableNo, DATABASE::"Sales Header");
        Field.SetRange("Field Caption", ChangedFieldName);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.Find('-');
        if Field.Next() <> 0 then
            Error(DuplicatedCaptionsNotAllowedErr);
        UpdateSalesLinesByFieldNo(Field."No.", AskQuestion);

        OnAfterUpdateSalesLines(Rec);
    end;

    local procedure UpdateSalesLineAmounts()
    var
        SalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if Rec.IsTemporary() then begin
            Session.LogMessage('0000G92', SalesHeaderIsTemporaryLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
            exit;
        end;

        if IsNullGuid(Rec.SystemId) then begin
            Session.LogMessage('0000G93', SalesHeaderDoesNotExistLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
            exit;
        end;

        IsHandled := false;
        OnBeforeUpdateSalesLineAmounts(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", "Document Type");
        SalesLine2.SetRange("Document No.", "No.");
        SalesLine2.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine2.SetFilter(Quantity, '<>0');
        OnUpdateSalesLineAmountsOnAfterSalesLineSetFilters(Rec, SalesLine);
        SalesLine2.LockTable();
        LockTable();
        if SalesLine2.FindSet() then begin
            if not Rec.Modify() then begin
                Session.LogMessage('0000G94', SalesHeaderCannotModifyLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
                exit;
            end;
            OnUpdateSalesLineAmountsOnAfterSalesHeaderModify(Rec, SalesLine2);
            repeat
                if (SalesLine2."Quantity Invoiced" <> SalesLine2.Quantity) or
                   ("Shipping Advice" = "Shipping Advice"::Complete) or
                   (SalesLine2.Type <> SalesLine.Type::"Charge (Item)") or
                   (CurrFieldNo <> 0)
                then begin
                    SalesLine2.UpdateAmounts();
                    SalesLine2.Modify();
                end;
            until SalesLine2.Next() = 0;
        end;
    end;

    /// <summary>
    /// Updates sales lines based on the provided field number.
    /// </summary>
    /// <param name="ChangedFieldNo">Changed field number.</param>
    /// <param name="AskQuestion">
    /// If true, confirmation message is shown to update the lines, otherwise confirmation is not shown.
    /// </param>
    procedure UpdateSalesLinesByFieldNo(ChangedFieldNo: Integer; AskQuestion: Boolean)
    var
        "Field": Record "Field";
        JobTransferLine: Codeunit "Job Transfer Line";
        JobPostLine: Codeunit "Job Post-Line";
        Question: Text[250];
        IsHandled: Boolean;
        ShouldConfirmReservationDateConflict: Boolean;
    begin
        if Rec.IsTemporary() then begin
            Session.LogMessage('0000G95', SalesHeaderIsTemporaryLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
            exit;
        end;

        if IsNullGuid(Rec.SystemId) then begin
            Session.LogMessage('0000G96', SalesHeaderDoesNotExistLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
            exit;
        end;

        IsHandled := false;
        OnBeforeUpdateSalesLinesByFieldNo(Rec, ChangedFieldNo, AskQuestion, IsHandled, xRec, CurrFieldNo);
        if IsHandled then
            exit;

        if not SalesLinesExist() then
            exit;

        if not Field.Get(DATABASE::"Sales Header", ChangedFieldNo) then
            Field.Get(DATABASE::"Sales Line", ChangedFieldNo);

        if AskQuestion then begin
            Question := StrSubstNo(Text031, Field."Field Caption");
            if GuiAllowed and not GetHideValidationDialog() then
                if DIALOG.Confirm(Question, true) then begin
                    ShouldConfirmReservationDateConflict := ChangedFieldNo in [
                        FieldNo("Shipment Date"),
                        FieldNo("Shipping Agent Code"),
                        FieldNo("Shipping Agent Service Code"),
                        FieldNo("Shipping Time"),
                        FieldNo("Requested Delivery Date"),
                        FieldNo("Promised Delivery Date"),
                        FieldNo("Outbound Whse. Handling Time")
                    ];
                    OnUpdateSalesLinesByFieldNoOnAfterCalcShouldConfirmReservationDateConflict(Rec, ChangedFieldNo, ShouldConfirmReservationDateConflict);
                    if ShouldConfirmReservationDateConflict then
                        ConfirmReservationDateConflict();
                end else
                    exit
        end;

        SalesLine.LockTable();
        if not Rec.Modify() then begin
            Session.LogMessage('0000G97', SalesHeaderCannotModifyLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SalesLinesCategoryLbl);
            exit;
        end;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        OnUpdateSalesLinesByFieldNoOnAfterSalesLineSetFilters(Rec, xRec, SalesLine, ChangedFieldNo);
        if SalesLine.FindSet() then
            repeat
                IsHandled := false;
                OnBeforeSalesLineByChangedFieldNo(Rec, SalesLine, ChangedFieldNo, IsHandled, xRec, CurrFieldNo);
                if not IsHandled then
                    case ChangedFieldNo of
                        FieldNo("Shipment Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Shipment Date", "Shipment Date");
                        FieldNo("Currency Factor"):
                            if SalesLine.Type <> SalesLine.Type::" " then begin
                                if SalesLine."Line Discount %" <> 0 then
                                    SalesLine.Validate("Unit Price");
                                SalesLine.Validate("Unit Cost (LCY)");
                                if SalesLine."Job No." <> '' then
                                    JobTransferLine.FromSalesHeaderToPlanningLine(SalesLine, "Currency Factor");
                            end;
                        FieldNo("Transaction Type"):
                            SalesLine.Validate("Transaction Type", "Transaction Type");
                        FieldNo("Transport Method"):
                            SalesLine.Validate("Transport Method", "Transport Method");
                        FieldNo("Exit Point"):
                            SalesLine.Validate("Exit Point", "Exit Point");
                        FieldNo(Area):
                            SalesLine.Validate(Area, Area);
                        FieldNo("Transaction Specification"):
                            SalesLine.Validate("Transaction Specification", "Transaction Specification");
                        FieldNo("Shipping Agent Code"):
                            SalesLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                        FieldNo("Shipping Agent Service Code"):
                            if (SalesLine."No." <> '') and (SalesLine."Shipping Agent Code" <> '') then begin
                                if SalesLine."Shipping Agent Code" <> "Shipping Agent Code" then
                                    SalesLine.Validate("Shipping Agent Code", "Shipping Agent Code");
                                SalesLine.Validate("Shipping Agent Service Code", "Shipping Agent Service Code");
                            end;
                        FieldNo("Shipping Time"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Shipping Time", "Shipping Time");
                        FieldNo("Prepayment %"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Prepayment %", "Prepayment %");
                        FieldNo("Requested Delivery Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Requested Delivery Date", "Requested Delivery Date");
                        FieldNo("Promised Delivery Date"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Promised Delivery Date", "Promised Delivery Date");
                        FieldNo("Outbound Whse. Handling Time"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Outbound Whse. Handling Time", "Outbound Whse. Handling Time");
                        SalesLine.FieldNo("Deferral Code"):
                            if SalesLine."No." <> '' then
                                SalesLine.Validate("Deferral Code");
                        FieldNo("Campaign No."):
                            if SalesLine."No." <> '' then begin
                                if SalesLine."Job No." <> '' then
                                    JobPostLine.TestSalesLine(SalesLine);
                                SalesLine.UpdateUnitPrice(0);
                            end;
                        else
                            OnUpdateSalesLineByChangedFieldName(Rec, SalesLine, Field.FieldName, ChangedFieldNo, xRec);
                    end;
                SalesLineReserve.AssignForPlanning(SalesLine);
                OnUpdateSalesLinesByFieldNoOnBeforeSalesLineModify(SalesLine, ChangedFieldNo, CurrFieldNo);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;

        OnAfterUpdateSalesLinesByFieldNo(Rec, xRec, ChangedFieldNo);
    end;

    /// <summary>
    /// Raises a confirmation informing the user that reservations may be canceled if the change in the field causes a date conflict.
    /// Confirmation is only raised if reservations exist. If not confirmed, the execution stops.
    /// </summary>
    procedure ConfirmReservationDateConflict()
    var
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        if ReservationEngineMgt.ResvExistsForSalesHeader(Rec) then
            if not Confirm(Text063, false) then
                Error('');
    end;

    /// <summary>
    /// Creates and assigns dimensions for the sales header based on the provided default dimension sources.
    /// </summary>
    /// <remarks>
    /// If sales lines exist and the dimension set has changed the dimensions are updated on the lines as well.
    /// </remarks>
    /// <param name="DefaultDimSource">The list of default dimension sources.</param>
    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled, DefaultDimSource);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Sales, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnCreateDimOnBeforeUpdateLines(Rec, xRec, CurrFieldNo, OldDimSetID, DefaultDimSource);

        if (OldDimSetID <> "Dimension Set ID") and (OldDimSetID <> 0) and GuiAllowed and not GetHideValidationDialog() then
            if CouldDimensionsBeKept() then
                if not ConfirmKeepExistingDimensions(OldDimSetID) then begin
                    "Dimension Set ID" := OldDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(Rec."Dimension Set ID", Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                    OnCreateDimOnKeepDimensionsOnAfterUpdateGlobalDim(Rec, xRec, CurrFieldNo, OldDimSetID);
                end;

        if (OldDimSetID <> "Dimension Set ID") and SalesLinesExist() then begin
            OnCreateDimOnBeforeModify(Rec, xRec, CurrFieldNo, OldDimSetID);
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure ConfirmKeepExistingDimensions(OldDimSetID: Integer) Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmKeepExistingDimensions(Rec, xRec, CurrFieldNo, OldDimSetID, Confirmed, IsHandled);
        if IsHandled then
            exit(Confirmed);

        Confirmed := Confirm(DoYouWantToKeepExistingDimensionsQst);
    end;

    local procedure CouldDimensionsBeKept() Result: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCouldDimensionsBeKept(Rec, xRec, Result, IsHandled);
        if not IsHandled then begin
            if (xRec."Sell-to Customer No." <> '') and (xRec."Sell-to Customer No." <> Rec."Sell-to Customer No.") then
                exit(false);
            if (xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> Rec."Bill-to Customer No.") then
                exit(false);

            if (xRec."Location Code" <> Rec."Location Code") and (xRec."Bill-to Customer No." <> '') then
                exit(true);
            if (xRec."Salesperson Code" <> '') and (xRec."Salesperson Code" <> Rec."Salesperson Code") then
                exit(true);
            if (xRec."Responsibility Center" <> '') and (xRec."Responsibility Center" <> Rec."Responsibility Center") then
                exit(true);
        end;
        OnAfterCouldDimensionsBeKept(Rec, xRec, Result);
    end;

    /// <summary>
    /// Verifies whether the provided shortcut dimension code and value are valid.
    /// If valid, assigns it to the sales document.
    /// </summary>
    /// <remarks>
    /// If sales lines exist, the dimensions are updated on the lines as well.
    /// </remarks>
    /// <param name="FieldNumber">Number of the shortcut dimension.</param>
    /// <param name="ShortcutDimCode">Value of the shortcut dimension.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "No." <> '' then
            Modify();

        if OldDimSetID <> "Dimension Set ID" then begin
            OnValidateShortcutDimCodeOnBeforeUpdateAllLineDim(Rec, xRec, FieldNumber);
            if not IsNullGuid(Rec.SystemId) then
                Modify();
            if SalesLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Determines if sales lines that are already shipped exist.
    /// </summary>
    /// <returns>True if shipped sales lines exists, otherwise false.</returns>
    procedure ShippedSalesLinesExist(): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Quantity Shipped", '<>0');
        exit(SalesLine.FindFirst());
    end;

    /// <summary>
    /// Determines if sales lines that are already returned exist.
    /// </summary>
    /// <returns>True if return receipt exists, otherwise false.</returns>
    procedure ReturnReceiptExist(): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Return Qty. Received", '<>0');
        exit(SalesLine.FindFirst());
    end;

    /// <summary>
    /// Deletes all sales lines, reservation, and comment lines for the document.
    /// </summary>
    procedure DeleteAllSalesLines()
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");

        DeleteSalesLines();
        SalesLine.SetRange(Type);
        DeleteSalesLines();

        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.DeleteAll();
    end;

    local procedure DeleteSalesLines()
    var
        ReservMgt: Codeunit "Reservation Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteSalesLines(SalesLine, IsHandled, Rec);
        if not IsHandled then
            if SalesLine.FindSet() then begin
                ReservMgt.DeleteDocumentReservation(DATABASE::"Sales Line", "Document Type".AsInteger(), "No.", GetHideValidationDialog());
                repeat
                    SalesLine.SuspendStatusCheck(true);
                    OnDeleteSalesLinesOnBeforeDeleteLine(SalesLine);
                    SalesLine.Delete(true);
                until SalesLine.Next() = 0;
            end;
        OnAfterDeleteSalesLines(SalesLine, Rec);
    end;

    local procedure DeleteRecordInApprovalRequest()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteRecordInApprovalRequest(Rec, IsHandled);
        if IsHandled then
            exit;

        ApprovalsMgmt.OnDeleteRecordInApprovalRequest(RecordId);
    end;

    local procedure ClearItemAssgntSalesFilter(var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    begin
        TempItemChargeAssgntSales.SetRange("Document Line No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Type");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. No.");
        TempItemChargeAssgntSales.SetRange("Applies-to Doc. Line No.");
    end;

    /// <summary>
    /// Checks if sell-to and bill-to customer numbers are filled. If not, it creates customers based on the associated
    /// contact and customer template, and assigns the new customer number to the document.
    /// </summary>
    /// <remarks>
    /// The transaction is committed after each customer record is created.
    /// Procedure are used in release sales quote or make order from quote processes.
    /// </remarks>
    /// <param name="Prompt">If set to true, a confirmation dialog to create a customer will be shown, otherwise not.</param>
    /// <returns>True if sell-to and bill-to customer numbers are filled, otherwise false.</returns>
    procedure CheckCustomerCreated(Prompt: Boolean): Boolean
    var
        Cont: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled, Result : Boolean;
    begin
        if ("Bill-to Customer No." <> '') and ("Sell-to Customer No." <> '') then
            exit(true);

        IsHandled := false;
        OnCheckCustomerCreatedOnBeforeConfirmProcess(Rec, Prompt, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Prompt then
            if not ConfirmManagement.GetResponseOrDefault(Text035, true) then
                exit(false);

        OnCheckCustomerCreatedOnAfterConfirmProcess(Rec);

        if "Sell-to Customer No." = '' then begin
            TestField("Sell-to Contact No.");
            TestField("Sell-to Customer Templ. Code");
            GetContact(Cont, "Sell-to Contact No.");
            CreateCustomerFromSellToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        if "Bill-to Customer No." = '' then begin
            TestField("Bill-to Contact No.");
            TestField("Bill-to Customer Templ. Code");
            GetContact(Cont, "Bill-to Contact No.");
            CreateCustomerFromBillToCustomerTemplate(Cont);
            Commit();
            Get("Document Type"::Quote, "No.");
        end;

        exit(("Bill-to Customer No." <> '') and ("Sell-to Customer No." <> ''));
    end;

    local procedure CreateCustomerFromSellToCustomerTemplate(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromSellToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Cont.CreateCustomerFromTemplate("Sell-to Customer Templ. Code");
    end;

    local procedure CreateCustomerFromBillToCustomerTemplate(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromBillToCustomerTemplate(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        Cont.CreateCustomerFromTemplate("Bill-to Customer Templ. Code");
    end;

    local procedure CreateDimensionsFromValidateBillToCustomerNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimensionsFromValidateBillToCustomerNo(Rec, IsHandled);
        if IsHandled then
            exit;

        CreateDimFromDefaultDim(Rec.FieldNo("Bill-to Customer No."));
    end;

    local procedure CreateDimensionsFromValidateSalesPersonCode()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimensionsFromValidateSalesPersonCode(Rec, IsHandled);
        if IsHandled then
            exit;

        CreateDimFromDefaultDim(Rec.FieldNo("Salesperson Code"));
    end;

    local procedure CheckShipmentInfo(var SalesLine: Record "Sales Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShipmentInfo(Rec, xRec, SalesLine, BillTo, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then
            SalesLine.SetFilter("Quantity Shipped", '<>0')
        else
            if "Document Type" = "Document Type"::Invoice then begin
                if not BillTo then
                    SalesLine.SetRange("Sell-to Customer No.", xRec."Sell-to Customer No.");
                SalesLine.SetFilter("Shipment No.", '<>%1', '');
            end;

        if SalesLine.FindFirst() then
            if "Document Type" = "Document Type"::Order then
                TestQuantityShippedField(SalesLine)
            else
                SalesLine.TestField("Shipment No.", '');
        SalesLine.SetRange("Shipment No.");
        SalesLine.SetRange("Quantity Shipped");
    end;

    local procedure CheckPrepmtInfo(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPrepmtInfo(Rec, xRec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>0');
            if SalesLine.Find('-') then
                SalesLine.TestField("Prepmt. Amt. Inv.", 0);
            SalesLine.SetRange("Prepmt. Amt. Inv.");
        end;
    end;

    local procedure CheckReturnInfo(var SalesLine: Record "Sales Line"; BillTo: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReturnInfo(Rec, IsHandled, xRec, BillTo);
        if IsHandled then
            exit;

        if "Document Type" = "Document Type"::"Return Order" then
            SalesLine.SetFilter("Return Qty. Received", '<>0')
        else
            if "Document Type" = "Document Type"::"Credit Memo" then begin
                if not BillTo then
                    SalesLine.SetRange("Sell-to Customer No.", xRec."Sell-to Customer No.");
                SalesLine.SetFilter("Return Receipt No.", '<>%1', '');
            end;

        if SalesLine.FindFirst() then
            if "Document Type" = "Document Type"::"Return Order" then
                SalesLine.TestField("Return Qty. Received", 0)
            else
                SalesLine.TestField("Return Receipt No.", '');
    end;

    local procedure CopyFromNewSellToCustTemplate(SellToCustTemplate: Record "Customer Templ.")
    begin
        OnBeforeCopyFromNewSellToCustTemplate(Rec, xRec, SellToCustTemplate);

        if not ApplicationAreaMgmt.IsSalesTaxEnabled() then
            SellToCustTemplate.TestField("Gen. Bus. Posting Group");
        "Gen. Bus. Posting Group" := SellToCustTemplate."Gen. Bus. Posting Group";
        "VAT Bus. Posting Group" := SellToCustTemplate."VAT Bus. Posting Group";
        if "Bill-to Customer No." = '' then
            Validate("Bill-to Customer Templ. Code", "Sell-to Customer Templ. Code");

        OnAfterCopyFromNewSellToCustTemplate(Rec, SellToCustTemplate);
    end;

    /// <summary>
    /// Recreates requisition lines linked to a sales line, either shifting them to a temporary table or
    /// back based on the provided ToTemp flag, updating the order promising line ID in the process.
    /// </summary>
    /// <remarks>
    /// Temporary requisition line table is defined as a local variable and the caller has no way to pass in / retrieve lines.
    /// Old requisition lines after recreation are deleted.
    /// </remarks>
    /// <param name="TempReqLine">Return value Temporary Requisition Line that contains the requisition lines that have been recreated.</param>
    /// <param name="OldSalesLine">Sales line that is associated with the requisition lines that need to be recreated.</param>
    /// <param name="NewSourceRefNo">New order promising line ID that should be assigned to the requisition lines when they are moved back from the temporary table to the main table.</param>
    /// <param name="ToTemp">
    /// If true, the procedure moves the requisition lines to a temporary table,
    /// otherwise it moves the requisition lines back from the temporary table to the main table.
    /// </param>
    procedure RecreateReqLine(var TempReqLine: Record "Requisition Line" temporary; OldSalesLine: Record "Sales Line"; NewSourceRefNo: Integer; ToTemp: Boolean)
    var
        ReqLine: Record "Requisition Line";
    begin
        if ("Document Type" = "Document Type"::Order) then
            if ToTemp then begin
                ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                ReqLine.SetRange("Order Promising ID", OldSalesLine."Document No.");
                ReqLine.SetRange("Order Promising Line ID", OldSalesLine."Line No.");
                if ReqLine.FindSet() then begin
                    repeat
                        TempReqLine := ReqLine;
                        TempReqLine.Insert();
                    until ReqLine.Next() = 0;
                    ReqLine.DeleteAll();
                end;
            end else begin
                Clear(TempReqLine);
                TempReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
                TempReqLine.SetRange("Order Promising ID", OldSalesLine."Document No.");
                TempReqLine.SetRange("Order Promising Line ID", OldSalesLine."Line No.");
                if TempReqLine.FindSet() then begin
                    repeat
                        ReqLine := TempReqLine;
                        ReqLine."Order Promising Line ID" := NewSourceRefNo;
                        ReqLine.Insert();
                    until TempReqLine.Next() = 0;
                    TempReqLine.DeleteAll();
                end;
            end;
    end;

#if not CLEAN25
    /// <summary>
    /// Recreates requisition lines linked to a sales line, either shifting them to a temporary table or
    /// back based on the provided ToTemp flag, updating the order promising line ID in the process.
    /// </summary>
    /// <remarks>
    /// Temporary requisition line table is defined as a local variable and the caller has no way to pass in / retrieve lines.
    /// Old requisition lines after recreation are deleted.
    /// </remarks>
    /// <param name="OldSalesLine">Sales line that is associated with the requisition lines that need to be recreated.</param>
    /// <param name="NewSourceRefNo">New order promising line ID that should be assigned to the requisition lines when they are moved back from the temporary table to the main table.</param>
    /// <param name="ToTemp">
    /// If true, the procedure moves the requisition lines to a temporary table,
    /// otherwise it moves the requisition lines back from the temporary table to the main table.
    /// </param>
    [Obsolete('Use RecreateReqLine with TempReqLine parameter instead.', '25.0')]
    procedure RecreateReqLine(OldSalesLine: Record "Sales Line"; NewSourceRefNo: Integer; ToTemp: Boolean)
    var
        TempReqLine: Record "Requisition Line" temporary;
    begin
        RecreateReqLine(TempReqLine, OldSalesLine, NewSourceRefNo, ToTemp);
    end;
#endif

    procedure TestPostingDate(BatchPost: Boolean)
    begin
        SalesSetup.Get();
        if not SalesSetup."Posting Date Check on Posting" then
            exit;
        if not GuiAllowed then
            exit;
        if "Posting Date" <> WorkDate() then begin
            if BatchPost then
                Error(DifferentDatesErr, "Posting Date", WorkDate());
            if not Confirm(DifferentDatesQst, false, "Posting Date", WorkDate()) then
                Error('');
        end;
    end;

    /// <summary>
    /// Updates the sell-to contact details of a sales header based on the provided customer number.
    /// </summary>
    /// <remarks>
    /// If the contact linked to a specific business relation is found, sell-to contact information is updated from the contact.
    /// </remarks>
    /// <param name="CustomerNo">Customer number from which details are taken.</param>
    procedure UpdateSellToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        OfficeContact: Record Contact;
        OfficeMgt: Codeunit "Office Management";
    begin
        if OfficeMgt.GetContact(OfficeContact, CustomerNo) then begin
            HideValidationDialog := true;
            UpdateSellToCust(OfficeContact."No.");
            HideValidationDialog := false;
        end else
            if Cust.Get(CustomerNo) then begin
                if Cust."Primary Contact No." <> '' then
                    "Sell-to Contact No." := Cust."Primary Contact No."
                else begin
                    ContBusRel.Reset();
                    ContBusRel.SetCurrentKey("Link to Table", "No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", "Sell-to Customer No.");
                    if ContBusRel.FindFirst() then
                        "Sell-to Contact No." := ContBusRel."Contact No."
                    else
                        "Sell-to Contact No." := '';
                end;
                "Sell-to Contact" := Cust.Contact;
            end;
        if "Sell-to Contact No." <> '' then
            if OfficeContact.Get("Sell-to Contact No.") then
                OfficeContact.CheckIfPrivacyBlockedGeneric();

        OnAfterUpdateSellToCont(Rec, Cust, OfficeContact, HideValidationDialog);
    end;

    /// <summary>
    /// Updates the bill-to contact details of a sales header based on the provided customer number.
    /// </summary>
    /// <remarks>
    /// If the contact linked to a specific business relation is found, bill-to contact information is updated from the contact.
    /// </remarks>
    /// <param name="CustomerNo">Customer number from which details are taken.</param>
    procedure UpdateBillToCont(CustomerNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
        Cust: Record Customer;
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCont(Rec, CustomerNo, SkipBillToContact, IsHandled);
        if IsHandled then
            exit;

        if Cust.Get(CustomerNo) then begin
            if Cust."Primary Contact No." <> '' then
                "Bill-to Contact No." := Cust."Primary Contact No."
            else begin
                ContBusRel.Reset();
                ContBusRel.SetCurrentKey("Link to Table", "No.");
                ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                ContBusRel.SetRange("No.", "Bill-to Customer No.");
                if ContBusRel.FindFirst() then
                    "Bill-to Contact No." := ContBusRel."Contact No."
                else
                    "Bill-to Contact No." := '';
            end;
            "Bill-to Contact" := Cust.Contact;
        end;
        if "Bill-to Contact No." <> '' then
            if Contact.Get("Bill-to Contact No.") then
                Contact.CheckIfPrivacyBlockedGeneric();

        OnAfterUpdateBillToCont(Rec, Cust, Contact);
    end;

    /// <summary>
    /// Updates the sell-to customer details of a sales header based on the provided contact number.
    /// </summary>
    /// <remarks>
    /// If the contact linked to a specific business relation is found, sell-to customer information is updated from the contact.
    /// </remarks>
    /// <param name="ContactNo">Contact number from which details are taken.</param>
    procedure UpdateSellToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        Cont: Record Contact;
        CustomerTempl: Record "Customer Templ.";
        SearchContact: Record Contact;
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateSellToCust(Rec, Cont, Customer, ContactNo);

        if not Cont.Get(ContactNo) then begin
            "Sell-to Contact" := '';
            exit;
        end;
        "Sell-to Contact No." := Cont."No.";

        IsHandled := false;
        OnUpdateSellToCustOnAfterSetSellToContactNo(Rec, Customer, Cont, IsHandled);
        if IsHandled then
            exit;

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            if not IsHandled then
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;

        OnUpdateSellToCustOnAfterFindContactBusinessRelation(Rec, Cont, ContBusinessRelation, ContactBusinessRelationFound);

        if ContactBusinessRelationFound then begin
            CheckCustomerContactRelation(Cont, "Sell-to Customer No.", ContBusinessRelation."No.");

            if "Sell-to Customer No." = '' then begin
                SkipSellToContact := true;
                Validate("Sell-to Customer No.", ContBusinessRelation."No.");
                SkipSellToContact := false;
            end;

            UpdateSellToEmail(Cont);
            Validate("Sell-to Phone No.", Cont."Phone No.");
        end else begin
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Sell-to Customer Name" := SearchContact."Company Name";
                "Sell-to Customer Name 2" := SearchContact."Name 2";
                "Sell-to Phone No." := SearchContact."Phone No.";
                "Sell-to E-Mail" := SearchContact."E-Mail";
                SetShipToAddress(
                  SearchContact."Company Name", SearchContact."Name 2", SearchContact.Address, SearchContact."Address 2",
                  SearchContact.City, SearchContact."Post Code", SearchContact.County, SearchContact."Country/Region Code");
                "Ship-to Phone No." := SearchContact."Phone No.";
                OnUpdateSellToCustOnAfterSetShipToAddress(Rec, SearchContact);
                if ("Sell-to Customer Templ. Code" = '') and (not CustomerTempl.IsEmpty) then
                    Validate("Sell-to Customer Templ. Code", Cont.FindNewCustomerTemplate());
                OnUpdateSellToCustOnAfterSetFromSearchContact(Rec, SearchContact);
            end else begin
                IsHandled := false;
                OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;

            "Sell-to Contact" := Cont.Name;
        end;

        UpdateSellToCustContact(Customer, Cont);

        if "Document Type" = "Document Type"::Quote then begin
            if Customer.Get("Sell-to Customer No.") or Customer.Get(ContBusinessRelation."No.") then begin
                if Customer."Copy Sell-to Addr. to Qte From" = Customer."Copy Sell-to Addr. to Qte From"::Company then
                    GetContactAsCompany(Cont, Cont);
            end else
                GetContactAsCompany(Cont, Cont);
            "Sell-to Address" := Cont.Address;
            "Sell-to Address 2" := Cont."Address 2";
            "Sell-to City" := Cont.City;
            "Sell-to Post Code" := Cont."Post Code";
            "Sell-to County" := Cont.County;
            "Sell-to Country/Region Code" := Cont."Country/Region Code";
        end;
        Clear(IsHandled);
        OnUpdateSellToCustOnBeforeValidateBillToContactNo(Rec, IsHandled);
        if not IsHandled then
            if ("Sell-to Customer No." = "Bill-to Customer No.") or
               ("Bill-to Customer No." = '')
            then
                Validate("Bill-to Contact No.", "Sell-to Contact No.");

        OnAfterUpdateSellToCust(Rec, Cont);
    end;

    local procedure UpdateSellToEmail(Contact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSellToEmail(Rec, Contact, IsHandled);
        if IsHandled then
            exit;

        if (Contact."E-Mail" = '') and ("Sell-to E-Mail" <> '') and GuiAllowed then begin
            if Confirm(ConfirmEmptyEmailQst, false, Contact."No.", "Sell-to E-Mail") then
                Validate("Sell-to E-Mail", Contact."E-Mail");
        end else
            Validate("Sell-to E-Mail", Contact."E-Mail");
    end;

    local procedure UpdateSellToCustContact(Customer: Record Customer; Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSellToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if (Cont.Type = Cont.Type::Company) and Customer.Get("Sell-to Customer No.") then
            "Sell-to Contact" := Customer.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Sell-to Contact" := ''
            else
                "Sell-to Contact" := Cont.Name;
    end;

    local procedure CheckCustomerContactRelation(Cont: Record Contact; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    var
        ContactBusinessRelationLinkType: Enum "Contact Business Relation Link To Table";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustomerContactRelation(Rec, Cont, IsHandled, CustomerNo, ContBusinessRelationNo);
        if IsHandled then
            exit;

        if (CustomerNo <> '') and (CustomerNo <> ContBusinessRelationNo) then
            if FindContactBusinessRelation(CustomerNo, Cont."Company No.", ContactBusinessRelationLinkType::Customer) then
                Error(Text037, Cont."No.", Cont.Name, CustomerNo);
    end;

    local procedure UpdateBillToCust(ContactNo: Code[20])
    var
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        SearchContact: Record Contact;
        CustomerTempl: Record "Customer Templ.";
        ContactBusinessRelationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCust(Rec, ContactNo, IsHandled);
        if IsHandled then
            exit;

        if not Cont.Get(ContactNo) then begin
            "Bill-to Contact" := '';
            exit;
        end;
        "Bill-to Contact No." := Cont."No.";

        UpdateBillToCustContact(Cont);

        if Cont.Type = Cont.Type::Person then
            ContactBusinessRelationFound := ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."No.");
        if not ContactBusinessRelationFound then begin
            IsHandled := false;
            OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Cont, ContBusinessRelation, ContactBusinessRelationFound, IsHandled);
            if not IsHandled then
                ContactBusinessRelationFound :=
                    ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.");
        end;

        OnUpdateBillToCustOnAfterFindContactBusinessRelation(Rec, Cont, ContBusinessRelation, ContactBusinessRelationFound);

        if ContactBusinessRelationFound then begin
            if "Bill-to Customer No." = '' then begin
                SkipBillToContact := true;
                Validate("Bill-to Customer No.", ContBusinessRelation."No.");
                SkipBillToContact := false;
                "Bill-to Customer Templ. Code" := '';
            end else
                CheckCustomerContactRelation(Cont, "Bill-to Customer No.", ContBusinessRelation."No.");
        end else
            if "Document Type" = "Document Type"::Quote then begin
                if not GetContactAsCompany(Cont, SearchContact) then
                    SearchContact := Cont;
                "Bill-to Name" := SearchContact."Company Name";
                "Bill-to Name 2" := SearchContact."Name 2";
                "Bill-to Address" := SearchContact.Address;
                "Bill-to Address 2" := SearchContact."Address 2";
                "Bill-to City" := SearchContact.City;
                "Bill-to Post Code" := SearchContact."Post Code";
                "Bill-to County" := SearchContact.County;
                "Bill-to Country/Region Code" := SearchContact."Country/Region Code";
                "VAT Registration No." := SearchContact."VAT Registration No.";
                "Registration Number" := SearchContact."Registration Number";
                Validate("Currency Code", SearchContact."Currency Code");
                "Language Code" := SearchContact."Language Code";
                "Format Region" := SearchContact."Format Region";

                OnUpdateBillToCustOnAfterSalesQuote(Rec, SearchContact);

                if ("Bill-to Customer Templ. Code" = '') and (not CustomerTempl.IsEmpty) then
                    Validate("Bill-to Customer Templ. Code", Cont.FindNewCustomerTemplate());
            end else begin
                IsHandled := false;
                OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(Rec, Cont, ContBusinessRelation, IsHandled);
                if not IsHandled then
                    Error(ContactIsNotRelatedToAnyCostomerErr, Cont."No.", Cont.Name);
            end;

        OnAfterUpdateBillToCust(Rec, Cont);
    end;

    local procedure UpdateBillToCustContact(Cont: Record Contact)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBillToCustContact(Rec, Cont, IsHandled);
        if IsHandled then
            exit;

        if Customer.Get("Bill-to Customer No.") and (Cont.Type = Cont.Type::Company) then
            "Bill-to Contact" := Customer.Contact
        else
            if Cont.Type = Cont.Type::Company then
                "Bill-to Contact" := ''
            else
                "Bill-to Contact" := Cont.Name;
    end;

    local procedure UpdateSellToCustTemplateCode()
    begin
        if ("Document Type" = "Document Type"::Quote) and ("Sell-to Customer No." = '') and ("Sell-to Customer Templ. Code" = '') and
           (GetFilterContNo() = '')
        then
            Validate("Sell-to Customer Templ. Code", SelectSalesHeaderNewCustomerTemplate());
    end;

    local procedure GetShipmentMethodCode()
    var
        ShipToAddress: Record "Ship-to Address";
        IsHandled: Boolean;
        IsShipmentMethodCodeAssigned: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShipmentMethodCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Ship-to Code" <> '' then begin
            ShipToAddress.SetLoadFields("Shipment Method Code");
            ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code");
            if ShipToAddress."Shipment Method Code" <> '' then begin
                Validate("Shipment Method Code", ShipToAddress."Shipment Method Code");
                IsShipmentMethodCodeAssigned := true;
            end;
        end;

        if (not IsShipmentMethodCodeAssigned) and ("Sell-to Customer No." <> '') then begin
            GetCust("Sell-to Customer No.");
            Validate("Shipment Method Code", Customer."Shipment Method Code");
        end;
    end;

    /// <summary>
    /// Updates the shipping time on the sales header.
    /// </summary>
    /// <remarks>
    /// Checks if the procedure is called by a field other than the current field. If so, the procedure exits.
    /// If shipping agent is defined in sales header then shipping time is set from the shipping agent services, otherwise from sell-to customer.
    /// If the procedure was not called by the shipping agent code or shipping agent service code fields,
    /// it validates the current shipping time value.
    /// </remarks>
    /// <param name="CalledByFieldNo">Field number of the field that called this procedure.</param>
    procedure GetShippingTime(CalledByFieldNo: Integer)
    var
        ShippingAgentServices: Record "Shipping Agent Services";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShippingTime(Rec, xRec, CalledByFieldNo, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;
        if (CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0) then
            exit;

        ShippingAgentServices.SetLoadFields("Shipping Time");
        if ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code") then
            "Shipping Time" := ShippingAgentServices."Shipping Time"
        else begin
            GetCust("Sell-to Customer No.");
            "Shipping Time" := Customer."Shipping Time"
        end;
        if not (CalledByFieldNo in [FieldNo("Shipping Agent Code"), FieldNo("Shipping Agent Service Code")]) then
            Validate("Shipping Time");
    end;

    local procedure GetContact(var Contact: Record Contact; ContactNo: Code[20])
    begin
        Contact.Get(ContactNo);
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
    end;

    /// <summary>
    /// Gets sell-to customer fax number.
    /// </summary>
    /// <returns>Customer fax number.</returns>
    procedure GetSellToCustomerFaxNo(): Text
    var
        Customer2: Record Customer;
    begin
        if Customer2.Get("Sell-to Customer No.") then
            exit(Customer2."Fax No.");
    end;

    /// <summary>
    /// Checks the bill to customer credit limit and if credit limit is exceeded, creates a notification.
    /// </summary>
    /// <remarks>
    /// Notifiction will be created only if credit warnings is not disabled in sales setup.
    /// </remarks>
    procedure CheckCreditMaxBeforeInsert()
    var
        SalesHeader2: Record "Sales Header";
        ContBusinessRelation: Record "Contact Business Relation";
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditMaxBeforeInsert(Rec, IsHandled, HideCreditCheckDialogue, GetFilterCustNo(), GetFilterContNo());
        if IsHandled then
            exit;

        if HideCreditCheckDialogue then
            exit;

        if (GetFilterCustNo() <> '') or ("Sell-to Customer No." <> '') then begin
            if "Sell-to Customer No." <> '' then
                Customer.Get("Sell-to Customer No.")
            else
                Customer.Get(GetFilterCustNo());
            if Customer."Bill-to Customer No." <> '' then
                SalesHeader2."Bill-to Customer No." := Customer."Bill-to Customer No."
            else
                SalesHeader2."Bill-to Customer No." := Customer."No.";
            OnCheckCreditMaxBeforeInsertOnCaseIfOnBeforeSalesHeaderCheckCase(SalesHeader2, Rec);
            CustCheckCreditLimit.SalesHeaderCheck(SalesHeader2);
        end else
            if GetFilterContNo() <> '' then begin
                Cont.Get(GetFilterContNo());
                if ContBusinessRelation.FindByContact(ContBusinessRelation."Link to Table"::Customer, Cont."Company No.") then begin
                    Customer.Get(ContBusinessRelation."No.");
                    if Customer."Bill-to Customer No." <> '' then
                        SalesHeader2."Bill-to Customer No." := Customer."Bill-to Customer No."
                    else
                        SalesHeader2."Bill-to Customer No." := Customer."No.";
                    CustCheckCreditLimit.SalesHeaderCheck(SalesHeader2);
                end;
            end;

        OnAfterCheckCreditMaxBeforeInsert(Rec);
    end;

    /// <summary>
    /// Creates inventory put-away, pick, or movement documents for a released sales document.
    /// </summary>
    procedure CreateInvtPutAwayPick()
    begin
        OnBeforeCreateInvtPutAwayPick(Rec);

        if "Document Type" = "Document Type"::Order then
            if not IsApprovedForPosting() then
                exit;

        OnCreateInvtPutAwayPickOnBeforeTestingStatus(Rec);
        TestField(Status, Status::Released);

        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        case "Document Type" of
            "Document Type"::Order:
                begin
                    if "Shipping Advice" = "Shipping Advice"::Complete then
                        CheckShippingAdvice();
                    WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Order");
                end;
            "Document Type"::"Return Order":
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Return Order");
        end;
        WhseRequest.SetRange("Source No.", "No.");
        REPORT.RunModal(REPORT::"Create Invt Put-away/Pick/Mvmt", true, false, WhseRequest);
    end;

    /// <summary>
    /// Starts the create task wizard with information from the sales header.
    /// </summary>
    procedure CreateTask()
    var
        TempTask: Record "To-do" temporary;
    begin
        TestField("Sell-to Contact No.");
        TempTask.CreateTaskFromSalesHeader(Rec);
    end;

    /// <summary>
    /// Updates the ship-to address information if the sales header has a credit document type.
    /// </summary>
    procedure UpdateShipToAddress()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateShipToAddress(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if IsCreditDocType() then
            if "Location Code" <> '' then begin
                Location.Get("Location Code");
                SetShipToAddress(
                  Location.Name, Location."Name 2", Location.Address, Location."Address 2", Location.City,
                  Location."Post Code", Location.County, Location."Country/Region Code");
                "Ship-to Phone No." := Location."Phone No.";
                "Ship-to Contact" := Location.Contact;
            end else begin
                CompanyInfo.Get();
                "Ship-to Code" := '';
                SetShipToAddress(
                  CompanyInfo."Ship-to Name", CompanyInfo."Ship-to Name 2", CompanyInfo."Ship-to Address", CompanyInfo."Ship-to Address 2",
                  CompanyInfo."Ship-to City", CompanyInfo."Ship-to Post Code", CompanyInfo."Ship-to County",
                  CompanyInfo."Ship-to Country/Region Code");
                "Ship-to Phone No." := CompanyInfo."Ship-to Phone No.";
                "Ship-to Contact" := CompanyInfo."Ship-to Contact";
            end;

        OnAfterUpdateShipToAddress(Rec, xRec, CurrFieldNo);
    end;

    local procedure SetRcvdFromCountry(RcvdFromCountryRegionCode: Code[10])
    begin
        if not IsCreditDocType() then
            exit;
        Rec."Rcvd.-from Count./Region Code" := RcvdFromCountryRegionCode;
    end;

    local procedure UpdateShipToCodeFromCust()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToCodeFromCust(Rec, Customer, IsHandled);
        if IsHandled then
            exit;

        Rec.Validate("Ship-to Code", Customer."Ship-to Code");
    end;

    /// <summary>
    /// Opens a page for editing dimensions for the sales header.
    /// If dimensions are changed, they're updated on the sales lines as well.
    /// </summary>
    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDocDim(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', "Document Type", "No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnShowDocDimOnBeforeUpdateSalesLines(Rec, xRec);
        if OldDimSetID <> "Dimension Set ID" then begin
            OnShowDocDimOnBeforeSalesHeaderModify(Rec);
            Modify();
            if SalesLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure ConfirmUpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer) Confirmed: Boolean;
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateAllLineDim(Rec, xRec, NewParentDimSetID, OldParentDimSetID, Confirmed, IsHandled);
        if not IsHandled then
            Confirmed := Confirm(Text064);
    end;

    /// <summary>
    /// Updates the dimensions of sales lines in a sales document when the dimensions of the sales header are changed.
    /// </summary>
    /// <param name="NewParentDimSetID">New dimension set ID.</param>
    /// <param name="OldParentDimSetID">Previous dimension set ID.</param>
    procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        ATOLink: Record "Assemble-to-Order Link";
        xSalesLine: Record "Sales Line";
        NewDimSetID: Integer;
        ShippedReceivedItemLineDimChangeConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAllLineDim(Rec, NewParentDimSetID, OldParentDimSetID, IsHandled, xRec);
        if IsHandled then
            exit;

        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not GetHideValidationDialog() and GuiAllowed then
            if not ConfirmUpdateAllLineDim(NewParentDimSetID, OldParentDimSetID) then
                exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.LockTable();
        if SalesLine.Find('-') then
            repeat
                OnUpdateAllLineDimOnBeforeGetSalesLineNewDimsetID(SalesLine, NewParentDimSetID, OldParentDimSetID);
                NewDimSetID := DimMgt.GetDeltaDimSetID(SalesLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                OnUpdateAllLineDimOnAfterGetSalesLineNewDimsetID(Rec, xRec, SalesLine, NewDimSetID, NewParentDimSetID, OldParentDimSetID);
                if SalesLine."Dimension Set ID" <> NewDimSetID then begin
                    xSalesLine := SalesLine;
                    SalesLine."Dimension Set ID" := NewDimSetID;

                    if not GetHideValidationDialog() and GuiAllowed then
                        VerifyShippedReceivedItemLineDimChange(ShippedReceivedItemLineDimChangeConfirmed);

                    DimMgt.UpdateGlobalDimFromDimSetID(
                      SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");

                    OnUpdateAllLineDimOnBeforeSalesLineModify(SalesLine, xSalesLine);
                    SalesLine.Modify();
                    OnUpdateAllLineDimOnAfterSalesLineModify(SalesLine);
                    ATOLink.UpdateAsmDimFromSalesLine(SalesLine, true);
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure VerifyShippedReceivedItemLineDimChange(var ShippedReceivedItemLineDimChangeConfirmed: Boolean)
    begin
        if SalesLine.IsShippedReceivedItemDimChanged() then
            if not ShippedReceivedItemLineDimChangeConfirmed then
                ShippedReceivedItemLineDimChangeConfirmed := SalesLine.ConfirmShippedReceivedItemDimChange();
    end;

    /// <summary>
    /// Opens a page with adjustment value entries related to the sales header.
    /// </summary>
    /// <param name="QtyType">
    /// General - filters all related value entries.
    /// Invoicing - filters only not invoiced value entries.
    /// </param>
    procedure LookupAdjmtValueEntries(QtyType: Option General,Invoicing)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        SalesShptLine: Record "Sales Shipment Line";
        ReturnRcptLine: Record "Return Receipt Line";
        TempValueEntry: Record "Value Entry" temporary;
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        TempValueEntry.Reset();
        TempValueEntry.DeleteAll();

        case "Document Type" of
            "Document Type"::Order, "Document Type"::Invoice:
                if SalesLine.FindSet() then
                    repeat
                        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity <> 0) then begin
                            if SalesLine."Shipment No." <> '' then begin
                                SalesShptLine.SetRange("Document No.", SalesLine."Shipment No.");
                                SalesShptLine.SetRange("Line No.", SalesLine."Shipment Line No.");
                            end else begin
                                SalesShptLine.SetCurrentKey("Order No.", "Order Line No.");
                                SalesShptLine.SetRange("Order No.", SalesLine."Document No.");
                                SalesShptLine.SetRange("Order Line No.", SalesLine."Line No.");
                            end;
                            SalesShptLine.SetRange(Correction, false);
                            if QtyType = QtyType::Invoicing then
                                SalesShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');

                            if SalesShptLine.FindSet() then
                                repeat
                                    SalesShptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                    if ItemLedgEntry.FindSet() then
                                        repeat
                                            CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                        until ItemLedgEntry.Next() = 0;
                                until SalesShptLine.Next() = 0;
                        end;
                    until SalesLine.Next() = 0;
            "Document Type"::"Return Order", "Document Type"::"Credit Memo":
                if SalesLine.FindSet() then
                    repeat
                        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Quantity <> 0) then begin
                            if SalesLine."Return Receipt No." <> '' then begin
                                ReturnRcptLine.SetRange("Document No.", SalesLine."Return Receipt No.");
                                ReturnRcptLine.SetRange("Line No.", SalesLine."Return Receipt Line No.");
                            end else begin
                                ReturnRcptLine.SetCurrentKey("Return Order No.", "Return Order Line No.");
                                ReturnRcptLine.SetRange("Return Order No.", SalesLine."Document No.");
                                ReturnRcptLine.SetRange("Return Order Line No.", SalesLine."Line No.");
                            end;
                            ReturnRcptLine.SetRange(Correction, false);
                            if QtyType = QtyType::Invoicing then
                                ReturnRcptLine.SetFilter("Return Qty. Rcd. Not Invd.", '<>0');

                            if ReturnRcptLine.FindSet() then
                                repeat
                                    ReturnRcptLine.FilterPstdDocLnItemLedgEntries(ItemLedgEntry);
                                    if ItemLedgEntry.FindSet() then
                                        repeat
                                            CreateTempAdjmtValueEntries(TempValueEntry, ItemLedgEntry."Entry No.");
                                        until ItemLedgEntry.Next() = 0;
                                until ReturnRcptLine.Next() = 0;
                        end;
                    until SalesLine.Next() = 0;
            else
                OnLookupAdjmtValueEntriesCaseDocumentTypeElse(Rec, SalesLine, QtyType);
        end;
        PAGE.RunModal(0, TempValueEntry);
    end;

    /// <summary>
    /// Returns the VAT registration number from a sales header.
    /// </summary>
    /// <returns>VAT registration number.</returns>
    procedure GetCustomerVATRegistrationNumber() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumber(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit("VAT Registration No.");
    end;

    /// <summary>
    /// Returns the VAT registration number field caption from a sales header.
    /// </summary>
    /// <returns>Caption of the VAT registration number field in the sales header.</returns>
    procedure GetCustomerVATRegistrationNumberLbl() ReturnValue: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerVATRegistrationNumberLbl(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        exit(FieldCaption("VAT Registration No."));
    end;

    /// <summary>
    /// Returns customer global location number. Currently defined to return an empty value.
    /// </summary>
    /// <returns>Empty text.</returns>
#if not CLEAN25
    [Obsolete('The procedure is not used and will be obsoleted.', '25.0')]
    procedure GetCustomerGlobalLocationNumber(): Text
    begin
        exit('');
    end;

    /// <summary>
    /// Returns customer global location number caption. Currently defined to return an empty value.
    /// </summary>
    /// <returns>Empty text.</returns>
    [Obsolete('The procedure is not used and will be obsoleted.', '25.0')]
    procedure GetCustomerGlobalLocationNumberLbl(): Text
    begin
        exit('');
    end;
#endif

    /// <summary>
    /// Returns document status field style expression based on the status of the sales header.
    /// </summary>
    /// <returns>Status style expression.</returns>
    procedure GetStatusStyleText() StatusStyleText: Text
    begin
        if Status = Status::Open then
            StatusStyleText := 'Favorable'
        else
            StatusStyleText := 'Strong';

        OnAfterGetStatusStyleText(Rec, StatusStyleText);
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

    /// <summary>
    /// Opens a page with posted document lines that can be reversed. After the user selects the lines,
    /// they are copied to the current document.
    /// </summary>
    procedure GetPstdDocLinesToReverse()
    var
        SalesPostedDocLines: Page "Posted Sales Document Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPstdDocLinesToReverse(Rec, IsHandled);
        if IsHandled then
            exit;

        GetCust("Sell-to Customer No.");
        SalesPostedDocLines.SetToSalesHeader(Rec);
        SalesPostedDocLines.SetRecord(Customer);
        SalesPostedDocLines.LookupMode := true;
        if SalesPostedDocLines.RunModal() = ACTION::LookupOK then
            SalesPostedDocLines.CopyLineToDoc();

        Clear(SalesPostedDocLines);

        OnAfterGetPstdDocLinesToReverse(Rec);
    end;

    /// <summary>
    /// Calculates invoice discount for a sales header if calculate invoice discount is enabled in the sales setup.
    /// </summary>
    procedure CalcInvDiscForHeader()
    var
        SalesInvDisc: Codeunit "Sales-Calc. Discount";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvDiscForHeader(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if SalesSetup."Calc. Inv. Discount" then
            SalesInvDisc.CalculateIncDiscForHeader(Rec);
    end;

    /// <summary>
    /// Filters the sales header for responsibility center set in the user setup or company information.
    /// The filter is set in filter group 2 and is hidden from the user.
    /// </summary>
    /// <remarks>
    /// Responsibility filter is set from user setup sales responsibility control filter field if this field is filled,
    /// otherwise it is set from the company information responsibility center field.
    /// </remarks>
    procedure SetSecurityFilterOnRespCenter()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSecurityFilterOnRespCenter(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetupMgt.GetSalesFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupMgt.GetSalesFilter());
            FilterGroup(0);
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate());
    end;

    /// <summary>
    /// Updates reservations data if location or bin have changed on the sales line.
    /// </summary>
    /// <remarks>
    /// Procedure is used on sales lines recreation process.
    /// </remarks>
    /// <param name="NewSalesLine">Return value: Updated sales line record.</param>
    /// <param name="OldSalesLine">The original sales line record before updates.</param>
    procedure SynchronizeForReservations(var NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSynchronizeForReservations(Rec, NewSalesLine, OldSalesLine, IsHandled);
        if IsHandled then
            exit;

        NewSalesLine.CalcFields("Reserved Quantity");
        if NewSalesLine."Reserved Quantity" = 0 then
            exit;
        if NewSalesLine."Location Code" <> OldSalesLine."Location Code" then
            NewSalesLine.Validate("Location Code", OldSalesLine."Location Code");
        if NewSalesLine."Bin Code" <> OldSalesLine."Bin Code" then
            NewSalesLine.Validate("Bin Code", OldSalesLine."Bin Code");
        if NewSalesLine.Modify() then;
    end;

    /// <summary>
    /// Determines if there is a conflict between inventory pick and sales line for a given sales document.
    /// </summary>
    /// <param name="DocType">The type of the sales document.</param>
    /// <param name="DocNo">The number of the sales document.</param>
    /// <param name="ShippingAdvice">The shipping advice for the sales document.</param>
    /// <returns>True if there is a conflict, otherwise false.</returns>
    procedure InventoryPickConflict(DocType: Enum "Sales Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine2: Record "Sales Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseActivityLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseActivityLine.SetRange("Source Subtype", DocType);
        WarehouseActivityLine.SetRange("Source No.", DocNo);
        if WarehouseActivityLine.IsEmpty() then
            exit(false);
        SalesLine2.SetRange("Document Type", DocType);
        SalesLine2.SetRange("Document No.", DocNo);
        SalesLine2.SetRange(Type, SalesLine.Type::Item);
        if SalesLine2.IsEmpty() then
            exit(false);
        exit(true);
    end;

    /// <summary>
    /// Determines if there is a conflict between warehouse shipment and sales line for a given sales document.
    /// </summary>
    /// <param name="DocType">The type of the sales document.</param>
    /// <param name="DocNo">The number of the sales document.</param>
    /// <param name="ShippingAdvice">The shipping advice for the sales document.</param>
    /// <returns>True if there is a conflict, otherwise false.</returns>
    procedure WhseShipmentConflict(DocType: Enum "Sales Document Type"; DocNo: Code[20]; ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if ShippingAdvice <> ShippingAdvice::Complete then
            exit(false);
        WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseShipmentLine.SetRange("Source Subtype", DocType);
        WarehouseShipmentLine.SetRange("Source No.", DocNo);
        if WarehouseShipmentLine.IsEmpty() then
            exit(false);
        exit(true);
    end;

    local procedure CheckCreditLimit()
    var
        SalesHeader2: Record "Sales Header";
        IsHandled: Boolean;
    begin
        SalesHeader2 := Rec;

        if GuiAllowed and
           (CurrFieldNo <> 0) and CheckCreditLimitCondition() and SalesHeader2.Find()
        then begin
            "Amount Including VAT" := 0;
            if "Document Type" = "Document Type"::Order then
                if BilltoCustomerNoChanged then begin
                    SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                    SalesLine.SetRange("Document No.", "No.");
                    SalesLine.CalcSums("Outstanding Amount", "Shipped Not Invoiced");
                    "Amount Including VAT" := SalesLine."Outstanding Amount" + SalesLine."Shipped Not Invoiced";
                end;

            IsHandled := false;
            OnBeforeCheckCreditLimit(Rec, IsHandled);
            if not IsHandled then
                CustCheckCreditLimit.SalesHeaderCheck(Rec);

            CalcFields("Amount Including VAT");
            OnCheckCreditLimitOnAfterCreditLimitCheck(Rec);
        end;
    end;

    local procedure CheckCreditLimitCondition(): Boolean
    var
        RunCheck: Boolean;
    begin
        RunCheck := ("Document Type".AsInteger() <= "Document Type"::Invoice.AsInteger()) or ("Document Type" = "Document Type"::"Blanket Order");
        OnAfterCheckCreditLimitCondition(Rec, RunCheck);
        exit(RunCheck);
    end;

    /// <summary>
    /// Checks if all lines of the document are in stock.
    /// If the quantity in stock is too low, a notification is shown.
    /// </summary>
    /// <remarks>
    /// Notifications will be displayed if stock notifications are not disabled.
    /// </remarks>
    procedure CheckItemAvailabilityInLines()
    var
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailabilityInLines(Rec, SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetFilter("Outstanding Quantity", '<>%1', 0);
        OnCheckItemAvailabilityInLinesOnAfterSetFilters(SalesLine);
        if SalesLine.FindSet() then
            repeat
                if ItemCheckAvail.SalesLineCheck(SalesLine) then
                    ItemCheckAvail.RaiseUpdateInterruptedError();
            until SalesLine.Next() = 0;
    end;

    /// <summary>
    /// Determines if the quantity to ship is zero for all sales document lines.
    /// </summary>
    /// <returns>True if the quantity to ship is zero for all lines, otherwise false.</returns>
    procedure QtyToShipIsZero() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQtyToShipIsZero(Rec, SalesLine, Result, IsHandled);
        if IsHandled then
            exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Qty. to Ship", '<>0');
        Result := SalesLine.IsEmpty();
    end;

    /// <summary>
    /// Checks if the sales document can be posted.
    /// It checks for status, approvals, payments and prepayments, and throws an error if conditions are not met.
    /// </summary>
    /// <returns>True if the sales header is approved for posting, otherwise false.</returns>
    procedure IsApprovedForPosting() Approved: Boolean
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsApprovedForPosting(Rec, Approved, IsHandled);
        if IsHandled then
            exit(Approved);

        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if "Document Type" = "Document Type"::Order then
                if PrepaymentMgt.TestSalesPayment(Rec) then
                    Error(Text072, "Document Type", "No.");
            Approved := true;
            OnAfterIsApprovedForPosting(Rec, Approved);
        end;
    end;

    /// <summary>
    /// Determines if the sales document can be posted. It checks for status, approvals, payments, and prepayments.
    /// </summary>
    /// <remarks>
    /// All the checks are executed in the try function, so no errors will be thrown if they appear.
    /// </remarks>
    /// <returns>True if the sales header is approved for posting, otherwise false.</returns>
    procedure IsApprovedForPostingBatch() Approved: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsApprovedForPostingBatch(Rec, Approved, IsHandled);
        if IsHandled then
            exit(Approved);

        Approved := ApprovedForPostingBatch();
        OnAfterIsApprovedForPostingBatch(Rec, Approved);
    end;

    [TryFunction]
    local procedure ApprovedForPostingBatch()
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                Error(PrepaymentInvoicesNotPaidErr, "Document Type", "No.");
            if PrepaymentMgt.TestSalesPayment(Rec) then
                Error(Text072, "Document Type", "No.");
        end;
    end;

    /// <summary>
    /// Returns legal statement from sales setup. Currently defined to return an empty value.
    /// </summary>
    /// <returns>Empty text.</returns>
    procedure GetLegalStatement(): Text
    begin
        GetSalesSetup();
        exit(SalesSetup.GetLegalStatement());
    end;

    /// <summary>
    /// Posts a sales document by running the provided codeunit if the document is approved for posting.
    /// </summary>
    /// <remarks>
    /// The transaction is committed before the posting codeunit is run.
    /// After the posting codeunit is executed any errors that occur during the posting operation are shown.
    /// </remarks>
    /// <param name="PostingCodeunitID">Posting codeunit id that is executed.</param>
    /// <returns>True if the document was successfully posted, otherwise false.</returns>
    procedure SendToPosting(PostingCodeunitID: Integer) IsSuccess: Boolean
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSendToPosting(Rec, IsSuccess, IsHandled, PostingCodeunitID);
        if IsHandled then
            exit(IsSuccess);

        if not IsApprovedForPosting() then
            exit;

        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecordId, 0, '');
        IsSuccess := CODEUNIT.Run(PostingCodeunitID, Rec);

        OnSendToPostingOnAfterPost(Rec);
        if not IsSuccess then begin
            if Rec.Status <> Rec.Status::Released then
                DeleteWarehouseRequest();
            ErrorMessageHandler.ShowErrors();
        end;
    end;

    local procedure DeleteWarehouseRequest()
    begin
        WhseRequest.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRequest.SetRange("Source Subtype", "Document Type");
        WhseRequest.SetRange("Source No.", "No.");
        if not WhseRequest.IsEmpty() then
            WhseRequest.DeleteAll(true);
    end;

    /// <summary>
    /// Cancels a background posting job for a sales document.
    /// </summary>
    procedure CancelBackgroundPosting()
    var
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        SalesPostViaJobQueue.CancelQueueEntry(Rec);
    end;

    /// <summary>
    /// Sends an email with the sales document attached.
    /// </summary>
    /// <param name="ShowDialog">Determines whether to show the email dialog before sending the email.</param>
    [Scope('Cloud')]
    procedure EmailRecords(ShowDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
    begin
        case "Document Type" of
            "Document Type"::Quote:
                begin
                    DocumentSendingProfile.TrySendToEMail(
                      DummyReportSelections.Usage::"S.Quote".AsInteger(), Rec, FieldNo("No."),
                      GetDocTypeTxt(), FieldNo("Bill-to Customer No."), ShowDialog);
                    Find();
                    "Quote Sent to Customer" := CurrentDateTime;
                    Modify();
                end;
            "Document Type"::Invoice:
                DocumentSendingProfile.TrySendToEMail(
                  DummyReportSelections.Usage::"S.Invoice Draft".AsInteger(), Rec, FieldNo("No."),
                  GetDocTypeTxt(), FieldNo("Bill-to Customer No."), ShowDialog);
        end;

        OnAfterSendSalesHeader(Rec, ShowDialog);
    end;

    /// <summary>
    /// Retrieves the full document type name based on the sales header document type.
    /// </summary>
    /// <returns>Retrieved document type name.</returns>
    procedure GetDocTypeTxt() TypeText: Text[50]
    var
        ReportDistributionMgt: Codeunit "Report Distribution Management";
    begin
        TypeText := ReportDistributionMgt.GetFullDocumentTypeText(Rec);

        OnAfterGetDocTypeText(Rec, TypeText);
    end;

    /// <summary>
    /// Retrieves the full sales document type name based on the sales header document type.
    /// </summary>
    /// <returns>Retrieved document type name.</returns>
    procedure GetFullDocTypeTxt() FullDocTypeTxt: Text
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetFullDocTypeTxt(Rec, FullDocTypeTxt, IsHandled);

        if IsHandled then
            exit;

        FullDocTypeTxt := SelectStr("Document Type".AsInteger() + 1, FullSalesTypesTxt);
    end;

    /// <summary>
    /// Updates the link between the sales document and an opportunity.
    /// </summary>
    /// <param name="OldOpportunityNo">The opportunity number before the update.</param>
    procedure LinkSalesDocWithOpportunity(OldOpportunityNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Opportunity: Record Opportunity;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLinkSalesDocWithOpportunity(Rec, OldOpportunityNo, IsHandled);
        if IsHandled then
            exit;

        if "Opportunity No." <> OldOpportunityNo then begin
            if "Opportunity No." <> '' then
                if Opportunity.Get("Opportunity No.") then begin
                    Opportunity.TestField(Status, Opportunity.Status::"In Progress");
                    if Opportunity."Sales Document No." <> '' then begin
                        if CofirmClearOpportunityNo(Opportunity) then begin
                            if SalesHeader.Get("Document Type"::Quote, Opportunity."Sales Document No.") then begin
                                SalesHeader."Opportunity No." := '';
                                OnLinkSalesDocWithOpportunityOnBeforeSalesHeaderModify(Rec, OldOpportunityNo, Opportunity);
                                SalesHeader.Modify();
                            end;
                            UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                        end else
                            "Opportunity No." := OldOpportunityNo;
                    end else
                        UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::Quote, "No.");
                end;
            if (OldOpportunityNo <> '') and Opportunity.Get(OldOpportunityNo) then
                UpdateOpportunityLink(Opportunity, Opportunity."Sales Document Type"::" ", '');
        end;
    end;

    local procedure CofirmClearOpportunityNo(Opportunity: Record Opportunity) Confirmed: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCofirmClearOpportunityNo(Opportunity, Confirmed, IsHandled);
        if IsHandled then
            exit(Confirmed);

        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text048, Opportunity."Sales Document No.", Opportunity."No."), true))
    end;

    local procedure UpdateOpportunityLink(Opportunity: Record Opportunity; SalesDocumentType: Enum "Opportunity Document Type"; SalesHeaderNo: Code[20])
    begin
        Opportunity."Sales Document Type" := SalesDocumentType;
        Opportunity."Sales Document No." := SalesHeaderNo;
        OnUpdateOpportunityLinkOnBeforeModify(Opportunity, Rec, SalesDocumentType.AsInteger(), SalesHeaderNo);
        Opportunity.Modify();
    end;

    /// <summary>
    /// Updates the posting date of related assembly headers with the sales header.
    /// </summary>
    /// <remarks>
    /// During the update dialog window will be shown for the user.
    /// </remarks>
    procedure SynchronizeAsmHeader()
    var
        AsmHeader: Record "Assembly Header";
        ATOLink: Record "Assemble-to-Order Link";
        Window: Dialog;
    begin
        ATOLink.SetCurrentKey(Type, "Document Type", "Document No.");
        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", "Document Type");
        ATOLink.SetRange("Document No.", "No.");
        if ATOLink.FindSet() then
            repeat
                if AsmHeader.Get(ATOLink."Assembly Document Type", ATOLink."Assembly Document No.") then
                    if "Posting Date" <> AsmHeader."Posting Date" then begin
                        Window.Open(StrSubstNo(SynchronizingMsg, "No.", AsmHeader."No."));
                        AsmHeader.Validate("Posting Date", "Posting Date");
                        AsmHeader.Modify();
                        Window.Close();
                    end;
            until ATOLink.Next() = 0;
    end;

    /// <summary>
    /// Checks if the sales document can be shipped completely and throws an error if it cannot.
    /// </summary>
    procedure CheckShippingAdvice()
    var
        SalesLine2: Record "Sales Line";
        Item: Record Item;
        QtyToShipBaseTotal: Decimal;
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckShippingAdvice(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine2.SetRange("Document Type", "Document Type");
        SalesLine2.SetRange("Document No.", "No.");
        SalesLine2.SetRange("Drop Shipment", false);
        SalesLine2.SetRange(Type, SalesLine.Type::Item);
        Result := true;
        if SalesLine2.FindSet() then
            repeat
                Item.Get(SalesLine2."No.");
                if SalesLine2.IsShipment() and (Item.Type = Item.Type::Inventory) then begin
                    QtyToShipBaseTotal += SalesLine2."Qty. to Ship (Base)";
                    if SalesLine2."Quantity (Base)" <>
                       SalesLine2."Qty. to Ship (Base)" + SalesLine2."Qty. Shipped (Base)"
                    then
                        Result := false;
                end;
            until SalesLine2.Next() = 0;
        if QtyToShipBaseTotal = 0 then
            Result := true;

        OnAfterCheckShippingAdvice(Rec, Result);
        if not Result then
            Error(ErrorInfo.Create(ShippingAdviceErr, true, Rec));
    end;

    /// <summary>
    /// Retrieves the company contact associated with the provided contact.
    /// </summary>
    /// <param name="Contact">The contact record to get the associated company contact for.</param>
    /// <param name="SearchContact">Return value: associated company contact.</param>
    /// <returns>True if company contact was found, otherwise false.</returns>
    protected procedure GetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact): Boolean;
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetContactAsCompany(Contact, SearchContact, IsHandled);
        if not IsHandled then
            if Contact."Company No." <> '' then
                exit(SearchContact.Get(Contact."Company No."));
    end;

    local procedure GetFilterCustNo(): Code[20]
    var
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Sell-to Customer No.") <> '' then
            if TryGetFilterCustNoRange(MinValue, MaxValue) then
                if MinValue = MaxValue then
                    exit(MaxValue);
    end;

    [TryFunction]
    local procedure TryGetFilterCustNoRange(var MinValue: Code[20]; var MaxValue: Code[20])
    begin
        MinValue := GetRangeMin("Sell-to Customer No.");
        MaxValue := GetRangeMax("Sell-to Customer No.");
    end;

    local procedure GetFilterCustNoByApplyingFilter(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        MinValue: Code[20];
        MaxValue: Code[20];
    begin
        if GetFilter("Sell-to Customer No.") <> '' then begin
            SalesHeader.CopyFilters(Rec);
            SalesHeader.SetCurrentKey("Sell-to Customer No.");
            if SalesHeader.FindFirst() then
                MinValue := SalesHeader."Sell-to Customer No.";
            if SalesHeader.FindLast() then
                MaxValue := SalesHeader."Sell-to Customer No.";
            if MinValue = MaxValue then
                exit(MaxValue);
        end;
    end;

    local procedure GetFilterContNo(): Code[20]
    begin
        if GetFilter("Sell-to Contact No.") <> '' then
            if GetRangeMin("Sell-to Contact No.") = GetRangeMax("Sell-to Contact No.") then
                exit(GetRangeMax("Sell-to Contact No."));
    end;

    local procedure CheckCreditLimitIfLineNotInsertedYet()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCreditLimitIfLineNotInsertedYet(Rec, IsHandled);
        if IsHandled then
            exit;

        if "No." = '' then begin
            HideCreditCheckDialogue := false;
            Rec.CheckCreditMaxBeforeInsert();
            HideCreditCheckDialogue := true;
        end;
    end;

    /// <summary>
    /// Determines whether there are invoiced sales lines for the sales header.
    /// </summary>
    /// <returns>True if invoiced sales lines exists, otherwise false.</returns>
    procedure InvoicedLineExists(): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        exit(not SalesLine.IsEmpty);
    end;

    /// <summary>
    /// Updates dimensions on lines with prepayments.
    /// </summary>
    /// <remarks>
    /// Dimensions are updated on temporary sales line table.
    /// Temporary sales line table is defined as a local variable and the caller has no way to retrieve lines.
    /// </remarks>
    procedure CreateDimSetForPrepmtAccDefaultDim()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimSetForPrepmtAccDefaultDim(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        SalesLine.SetFilter("Prepmt. Amt. Inv.", '<>%1', 0);
        if SalesLine.FindSet() then
            repeat
                CollectParamsInBufferForCreateDimSet(TempSalesLine, SalesLine);
            until SalesLine.Next() = 0;
        TempSalesLine.Reset();
        TempSalesLine.MarkedOnly(false);
        if TempSalesLine.FindSet() then
            repeat
                InitSalesLineDefaultDimSource(DefaultDimSource, TempSalesLine);
                OnCreateDimSetForPrepmtAccDefaultDimOnBeforeTempSalesLineCreateDim(DefaultDimSource, TempSalesLine);
                TempSalesLine.CreateDim(DefaultDimSource);
            until TempSalesLine.Next() = 0;
    end;

    local procedure InitSalesLineDefaultDimSource(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; SourceSalesLine: Record "Sales Line")
    begin
        Clear(DefaultDimSource);
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", SourceSalesLine."No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, SourceSalesLine."Job No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", SourceSalesLine."Responsibility Center");
    end;

    local procedure CollectParamsInBufferForCreateDimSet(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        TempSalesLine.SetRange("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
        TempSalesLine.SetRange("Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
        if not TempSalesLine.FindFirst() then begin
            GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            DefaultDimension.SetRange("Table ID", DATABASE::"G/L Account");
            DefaultDimension.SetRange("No.", GenPostingSetup.GetSalesPrepmtAccount());
            OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempSalesLineInBuffer(GenPostingSetup, DefaultDimension);
            InsertTempSalesLineInBuffer(TempSalesLine, SalesLine, GenPostingSetup."Sales Prepayments Account", DefaultDimension.IsEmpty);
        end else
            if not TempSalesLine.Mark() then begin
                TempSalesLine.SetRange("Job No.", SalesLine."Job No.");
                TempSalesLine.SetRange("Responsibility Center", SalesLine."Responsibility Center");
                OnCollectParamsInBufferForCreateDimSetOnAfterSetTempSalesLineFilters(TempSalesLine, SalesLine);
                if TempSalesLine.IsEmpty() then
                    InsertTempSalesLineInBuffer(TempSalesLine, SalesLine, TempSalesLine."No.", false);
            end;
    end;

    local procedure InsertTempSalesLineInBuffer(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line"; AccountNo: Code[20]; DefaultDimensionsNotExist: Boolean)
    begin
        TempSalesLine.Init();
        TempSalesLine."Document Type" := SalesLine."Document Type";
        TempSalesLine."Document No." := SalesLine."Document No.";
        TempSalesLine."Line No." := SalesLine."Line No.";
        TempSalesLine."No." := AccountNo;
        TempSalesLine."Job No." := SalesLine."Job No.";
        TempSalesLine."Responsibility Center" := SalesLine."Responsibility Center";
        TempSalesLine."Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        TempSalesLine."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        TempSalesLine.Mark := DefaultDimensionsNotExist;
        OnInsertTempSalesLineInBufferOnBeforeTempSalesLineInsert(TempSalesLine, SalesLine);
        TempSalesLine.Insert();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    /// <summary>
    /// Open statistics page for sales document.
    /// </summary>
    /// <remarks>
    /// Commit is executed before opening the statistics page.
    /// </remarks>
    procedure OpenSalesOrderStatistics()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenSalesOrderStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        OpenDocumentStatisticsInternal();
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    /// <summary>
    /// Open statistics page for sales documents.
    /// </summary>
    /// <remarks>
    /// Commit is executed before opening the statistics page.
    /// </remarks>
    procedure OpenDocumentStatistics()
    begin
        OpenDocumentStatisticsInternal();
    end;
#endif
    /// <summary>
    /// Runs checks and prepares data needed to open the document statistics page.
    /// </summary>
    /// <remarks>
    /// It checks the user's permissions,
    /// calculates the invoice discount, creates a dimension set for order documents, and commits any changes made.
    /// </remarks>
    procedure PrepareOpeningDocumentStatistics()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        SalesHeader2: Record "Sales Header";
        [SecurityFiltering(SecurityFilter::Ignored)]
        SalesLine2: Record "Sales Line";
    begin
        if not SalesHeader2.WritePermission() or not SalesLine2.WritePermission() then
            Error(StatisticsInsuffucientPermissionsErr);

        CalcInvDiscForHeader();

        if IsOrderDocument() then
            CreateDimSetForPrepmtAccDefaultDim();

        OnAfterPrepareOpeningDocumentStatistics(Rec);

        Commit();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    /// <summary>
    /// Opens a sales document statistics page based on the document type.
    /// After the page is closed, the recalculate invoice discount field is set to false on all sales document lines.
    /// </summary>
    procedure ShowDocumentStatisticsPage() StatisticsPageId: Integer
    begin
        StatisticsPageId := GetStatisticsPageID();

        OnGetStatisticsPageID(StatisticsPageId, Rec);

        SkipStatsPrep := true;
        PAGE.RunModal(StatisticsPageId, Rec);
        ResetSkipStatisticsPreparationFlag();

        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    procedure SkipStatisticsPreparation(): Boolean
    begin
        exit(SkipStatsPrep)
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    procedure ResetSkipStatisticsPreparationFlag()
    begin
        SkipStatsPrep := false;
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenDocumentStatisticsInternal()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenDocumentStatistics(Rec, IsHandled);
        if IsHandled then
            exit;

        PrepareOpeningDocumentStatistics();
        ShowDocumentStatisticsPage();
    end;
#endif
    local procedure IsOrderDocument(): Boolean
    begin
        exit("Document Type" in ["Document Type"::Order, "Document Type"::"Blanket Order", "Document Type"::"Return Order"])
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure GetStatisticsPageID(): Integer
    begin
        if IsOrderDocument() then
            exit(PAGE::"Sales Order Statistics");

        exit(PAGE::"Sales Statistics");
    end;
#endif
    /// <summary>
    /// Determines the available credit limit for the customer associated with the sales header.
    /// </summary>
    /// <returns>Available credit limit.</returns>
    procedure CheckAvailableCreditLimit() ReturnValue: Decimal
    var
        Customer: Record Customer;
        AvailableCreditLimit: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailableCreditLimit(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if ("Bill-to Customer No." = '') and ("Sell-to Customer No." = '') then
            exit(0);

        if not Customer.Get("Bill-to Customer No.") then
            Customer.Get("Sell-to Customer No.");

        AvailableCreditLimit := Customer.CalcAvailableCredit();

        if AvailableCreditLimit < 0 then
            CustomerCreditLimitExceeded()
        else
            CustomerCreditLimitNotExceeded();

        exit(AvailableCreditLimit);
    end;

    /// <summary>
    /// Sets the status of a sales document.
    /// </summary>
    /// <param name="NewStatus">New status to set.</param>
    procedure SetStatus(NewStatus: Option)
    begin
        Status := Enum::"Sales Document Status".FromInteger(NewStatus);
        Modify();
    end;

    local procedure TestSalesLineFieldsBeforeRecreate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesLineFieldsBeforeRecreate(Rec, IsHandled, SalesLine);
        if IsHandled then
            exit;

        SalesLine.TestField("Job No.", '');
        SalesLine.TestField("Job Contract Entry No.", 0);
        SalesLine.TestField("Quantity Invoiced", 0);
        SalesLine.TestField("Return Qty. Received", 0);
        SalesLine.TestField("Shipment No.", '');
        SalesLine.TestField("Return Receipt No.", '');
        SalesLine.TestField("Blanket Order No.", '');
        SalesLine.TestField("Prepmt. Amt. Inv.", 0);
        TestQuantityShippedField(SalesLine);
    end;

    local procedure RecreateReservEntryReqLine(var TempSalesLine: Record "Sales Line" temporary; var TempATOLink: Record "Assemble-to-Order Link" temporary; var ATOLink: Record "Assemble-to-Order Link"; var TempReqLine: Record "Requisition Line" temporary);
    var
        ShouldValidateLocationCode: Boolean;
    begin
        repeat
            TestSalesLineFieldsBeforeRecreate();
            ShouldValidateLocationCode := (SalesLine."Location Code" <> "Location Code") and not SalesLine.IsNonInventoriableItem();
            OnRecreateReservEntryReqLineOnAfterCalcShouldValidateLocationCode(Rec, xRec, SalesLine, ShouldValidateLocationCode);
            if ShouldValidateLocationCode then begin
                SalesLine.Validate("Location Code", "Location Code");
                if Rec."Document Type" in [Rec."Document Type"::Invoice, Rec."Document Type"::"Credit Memo"] then
                    if SalesLine."Location Code" <> '' then
                        SalesLine.CheckLocationOnWMS();
            end;
            TempSalesLine := SalesLine;
            if SalesLine.Nonstock then begin
                SalesLine.Nonstock := false;
                SalesLine.Modify();
            end;

            if ATOLink.AsmExistsForSalesLine(TempSalesLine) then begin
                TempATOLink := ATOLink;
                TempATOLink.Insert();
                ATOLink.Delete();
            end;

            if not IsServiceChargeLine(SalesLine) then
                TempSalesLine.Insert();
            OnAfterInsertTempSalesLine(SalesLine, TempSalesLine);
            SalesLineReserve.CopyReservEntryToTemp(TempReservEntry, SalesLine);
            RecreateReqLine(TempReqLine, SalesLine, 0, true);
            OnRecreateReservEntryReqLineOnAfterLoop(Rec, SalesLine);
        until SalesLine.Next() = 0;
    end;

    local procedure IsServiceChargeLine(SalesLine: Record "Sales Line"): Boolean
    begin
        if SalesLine."System-Created Entry" then
            if SalesLine.Type = SalesLine.Type::"G/L Account" then
                if SalesLine.IsServiceChargeLine() then
                    exit(true);
    end;

    /// <summary>
    /// Transfers item charge assignments to the temporary record set and deletes them from the original record.
    /// </summary>
    /// <param name="ItemChargeAssgntSales">Item charge assignment record set to transfer.</param>
    /// <param name="TempItemChargeAssgntSales">Return value: Temporary item charge assignment record set to transfer to.</param>
    procedure TransferItemChargeAssgntSalesToTemp(var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferItemChargeAssgntSalesToTemp(Rec, ItemChargeAssgntSales, TempItemChargeAssgntSales, IsHandled);
        if IsHandled then
            exit;

        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        if ItemChargeAssgntSales.FindSet() then begin
            repeat
                TempItemChargeAssgntSales.Init();
                TempItemChargeAssgntSales := ItemChargeAssgntSales;
                TempItemChargeAssgntSales.Insert();
            until ItemChargeAssgntSales.Next() = 0;
            ItemChargeAssgntSales.DeleteAll();
        end;
    end;

    local procedure CreateSalesLine(var TempSalesLine: Record "Sales Line" temporary)
    var
        IsHandled: Boolean;
        ShouldValidateQuantity: Boolean;
    begin
        OnBeforeCreateSalesLine(TempSalesLine, IsHandled, Rec, SalesLine);
        if IsHandled then
            exit;

        SalesLine.Init();
        SalesLine."Line No." := SalesLine."Line No." + 10000;
        SalesLine."Price Calculation Method" := "Price Calculation Method";

        OnCreateSalesLineOnBeforeAssignType(SalesLine, TempSalesLine, Rec);
        SalesLine.Validate(Type, TempSalesLine.Type);
        OnCreateSalesLineOnAfterAssignType(SalesLine, TempSalesLine);
        if TempSalesLine."No." = '' then begin
            SalesLine.Description := TempSalesLine.Description;
            SalesLine."Description 2" := TempSalesLine."Description 2";
        end else begin
            SalesLine.Validate("No.", TempSalesLine."No.");
            OnCreateSalesLineOnAfterValidateNo(SalesLine, TempSalesLine);

            if SalesLine.Type <> SalesLine.Type::" " then begin
                OnCreateSalesLineOnBeforeTransferFieldsFromTempSalesLine(SalesLine, TempSalesLine, Rec);
                SalesLine.Validate("Unit of Measure Code", TempSalesLine."Unit of Measure Code");
                SalesLine.Validate("Variant Code", TempSalesLine."Variant Code");
                ShouldValidateQuantity := TempSalesLine.Quantity <> 0;
                OnCreateSalesLineOnBeforeValidateQuantity(SalesLine, TempSalesLine, ShouldValidateQuantity);
                if ShouldValidateQuantity then begin
                    SalesLine.Validate(Quantity, TempSalesLine.Quantity);
                    SalesLine.Validate("Qty. to Assemble to Order", TempSalesLine."Qty. to Assemble to Order");
                end;
                SalesLine."Purchase Order No." := TempSalesLine."Purchase Order No.";
                SalesLine."Purch. Order Line No." := TempSalesLine."Purch. Order Line No.";

                IsHandled := false;
                OnCreateSalesLineOnBeforeSetDropShipment(SalesLine, TempSalesLine, IsHandled);
                if not IsHandled then
                    SalesLine."Drop Shipment" := TempSalesLine."Drop Shipment";
            end;

            IsHandled := false;
            OnCreateSalesLineOnBeforeValidateShipmentDate(SalesLine, TempSalesLine, Rec, IsHandled);
            if not IsHandled then
                SalesLine.Validate("Shipment Date", TempSalesLine."Shipment Date");
        end;
        OnBeforeSalesLineInsert(SalesLine, TempSalesLine, Rec);
        SalesLine.Insert();
        OnAfterCreateSalesLine(SalesLine, TempSalesLine);
    end;

    local procedure CreateItemChargeAssgntSales(var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempSalesLine: Record "Sales Line" temporary; var TempInteger: Record "Integer" temporary)
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempSalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        if TempSalesLine.FindSet() then
            repeat
                TempItemChargeAssgntSales.SetRange("Document Line No.", TempSalesLine."Line No.");
                if TempItemChargeAssgntSales.FindSet() then begin
                    repeat
                        TempInteger.FindFirst();
                        ItemChargeAssgntSales.Init();
                        ItemChargeAssgntSales := TempItemChargeAssgntSales;
                        ItemChargeAssgntSales."Document Line No." := TempInteger.Number;
                        ItemChargeAssgntSales.Validate("Qty. to Assign", 0);
                        ItemChargeAssgntSales.Insert();
                    until TempItemChargeAssgntSales.Next() = 0;
                    TempInteger.Delete();
                end;
            until TempSalesLine.Next() = 0;

        ClearItemAssgntSalesFilter(TempItemChargeAssgntSales);
        TempItemChargeAssgntSales.DeleteAll();
    end;

    local procedure UpdateOutboundWhseHandlingTime()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOutboundWhseHandlingTime(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Location Code" <> '' then begin
            if Location.Get("Location Code") then
                "Outbound Whse. Handling Time" := Location."Outbound Whse. Handling Time";
        end else
            if InvtSetup.Get() then
                "Outbound Whse. Handling Time" := InvtSetup."Outbound Whse. Handling Time";
    end;

    [IntegrationEvent(true, false)]
    procedure OnCheckSalesPostRestrictions()
    begin
    end;

    /// <summary>
    /// Triggers the OnCheckSalesPostRestrictions event that allows customized restrictions to be added to the sales document post process.
    /// </summary>
    procedure CheckSalesPostRestrictions()
    begin
        OnCheckSalesPostRestrictions();
    end;

    [IntegrationEvent(true, false)]
    procedure OnCustomerCreditLimitExceeded(NotificationId: Guid)
    begin
    end;

    /// <summary>
    /// Triggers the OnCustomerCreditLimitExceeded event that allows a custom solution to be
    /// added when the calculated credit limit exceeds the customer's credit limit.
    /// </summary>
    procedure CustomerCreditLimitExceeded()
    var
        NotificationId: Guid;
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    /// <summary>
    /// Triggers the OnCustomerCreditLimitExceeded event that allows a custom solution to be added
    /// when the calculated credit limit exceeds the customer's credit limit.
    /// </summary>
    /// <remarks>
    /// Used on sales lines and sales header check procedures which creates exceeded credit limit notification if needed.
    /// </remarks>
    /// <param name="NotificationID">GUID of the credit limit notification.</param>
    procedure CustomerCreditLimitExceeded(NotificationId: Guid)
    begin
        OnCustomerCreditLimitExceeded(NotificationId);
    end;

    [IntegrationEvent(true, false)]
    procedure OnCustomerCreditLimitNotExceeded()
    begin
    end;

    /// <summary>
    /// Triggers the OnCustomerCreditLimitNotExceeded event that allows a custom solution to be added
    /// when the calculated credit limit not exceeds the customer's credit limit.
    /// </summary>
    procedure CustomerCreditLimitNotExceeded()
    begin
        OnCustomerCreditLimitNotExceeded();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckSalesReleaseRestrictions()
    begin
    end;

    /// <summary>
    /// Checks the sales document approvals if the status is open.
    /// </summary>
    procedure CheckSalesReleaseRestrictions()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OnCheckSalesReleaseRestrictions();
        ApprovalsMgmt.PrePostApprovalCheckSales(Rec);
    end;

    /// <summary>
    /// Determines whether there are related deferrals.
    /// </summary>
    /// <returns>True if any related deferal header exists, otherwise false.</returns>
    procedure DeferralHeadersExist(): Boolean
    var
        DeferralHeader: Record "Deferral Header";
    begin
        DeferralHeader.SetRange("Deferral Doc. Type", Enum::"Deferral Document Type"::Sales);
        DeferralHeader.SetRange("Gen. Jnl. Template Name", '');
        DeferralHeader.SetRange("Gen. Jnl. Batch Name", '');
        DeferralHeader.SetRange("Document Type", "Document Type");
        DeferralHeader.SetRange("Document No.", "No.");
        OnDeferralHeadersExistOnAfterSetFilters(Rec, DeferralHeader);
        exit(not DeferralHeader.IsEmpty);
    end;

    /// <summary>
    /// Sets the sell-to customer number from the filter applied to the sell-to customer field if the filter is not blank.
    /// </summary>
    procedure SetSellToCustomerFromFilter()
    var
        SellToCustomerNo: Code[20];
    begin
        OnBeforeSetSellToCustomerFromFilter(Rec);

        SellToCustomerNo := GetSellToCustomerFromFilter();

        if SellToCustomerNo <> '' then
            Validate("Sell-to Customer No.", SellToCustomerNo);

        OnAfterSetSellToCustomerFromFilter(Rec);
    end;

    /// <summary>
    /// Retrieves the sell-to customer no. of a sales header based on a single-value filter applied to the sell-to customer no. field.
    /// </summary>
    /// <remarks>
    /// Single-value filter is retrieved from the current filter group or filter group 2.
    /// </remarks>
    /// <returns>Sell-to customer number.</returns>
    procedure GetSellToCustomerFromFilter() SellToCustomerNo: Code[20]
    begin
        SellToCustomerNo := GetFilterCustNo();
        if SellToCustomerNo = '' then begin
            FilterGroup(2);
            SellToCustomerNo := GetFilterCustNo();
            if SellToCustomerNo = '' then
                SellToCustomerNo := GetFilterCustNoByApplyingFilter();
            FilterGroup(0);
        end;
    end;

    /// <summary>
    /// Moves the filter on sell-to customer no. from the current filter group to filter group 2.
    /// </summary>
    procedure CopySellToCustomerFilter()
    var
        SellToCustomerFilter: Text;
    begin
        SellToCustomerFilter := GetFilter("Sell-to Customer No.");
        OnCopySellToCustomerFilterOnAfterGetSellToCustomerFilter(Rec, SellToCustomerFilter);
        if SellToCustomerFilter <> '' then begin
            FilterGroup(2);
            SetFilter("Sell-to Customer No.", SellToCustomerFilter);
            FilterGroup(0)
        end;
    end;

    local procedure ConfirmBillToCustomerChange() Confirmed: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmBillToCustomerChange(Rec, xRec, CurrFieldNo, Confirmed, IsHandled);
        if IsHandled then
            exit(Confirmed);

        if GetHideValidationDialog() or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(ConfirmChangeQst, false, BillToCustomerTxt);
    end;

    local procedure ConfirmUpdateDeferralDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmUpdateDeferralDate(Rec, xRec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if GetHideValidationDialog() or not GuiAllowed then
            Confirmed := true
        else
            Confirmed := Confirm(DeferralLineQst, false);
        if Confirmed then
            UpdateSalesLinesByFieldNo(SalesLine.FieldNo("Deferral Code"), false);
    end;

    /// <summary>
    /// Raises a confirmation to update the deferral schedules on the lines to reflect the changed dates.
    /// If user confirms the update, the sales lines are updated.
    /// </summary>
    /// <param name="BatchConfirm"></param>
    /// <param name="ReplacePostingDate">If true, the sales header's posting date will be replaced with the specified PostingDateReq.</param>
    /// <param name="PostingDateReq">Posting date to replace.</param>
    /// <param name="ReplaceVATDate"></param>
    /// <param name="VATDateReq">Vat reporting date to replace.</param>
    procedure BatchConfirmUpdateDeferralDate(var BatchConfirm: Option " ",Skip,Update; ReplacePostingDate: Boolean; PostingDateReq: Date; ReplaceVATDate: Boolean; VATDateReq: Date)
    begin
        if ((not ReplacePostingDate) and (not ReplaceVATDate)) or (BatchConfirm = BatchConfirm::Skip) then
            exit;
        if (PostingDateReq = "Posting Date") and (VATDateReq = "VAT Reporting Date") then
            exit;
        if not DeferralHeadersExist() then
            exit;

        if ReplacePostingDate then
            "Posting Date" := PostingDateReq;
        if ReplaceVATDate then
            "VAT Reporting Date" := VATDateReq;

        case BatchConfirm of
            BatchConfirm::" ":
                begin
                    ConfirmUpdateDeferralDate();
                    if Confirmed then
                        BatchConfirm := BatchConfirm::Update
                    else
                        BatchConfirm := BatchConfirm::Skip;
                end;
            BatchConfirm::Update:
                UpdateSalesLinesByFieldNo(SalesLine.FieldNo("Deferral Code"), false);
        end;
        Commit();
    end;

    procedure BatchConfirmUpdatePostingDate(ReplacePostingDate: Boolean; PostingDateReq: Date; ReplaceVATDate: Boolean; VATDateReq: Date; ReplaceDocDate: Boolean)
    begin
        if not ReplacePostingDate then
            exit;
        if (PostingDateReq = "Posting Date") then
            exit;
        if DeferralHeadersExist() then
            exit;

        "Posting Date" := PostingDateReq;
        if "Currency Code" <> '' then begin
            UpdateCurrencyFactor();
            UpdateSalesLinesByFieldNo(SalesHeader.FieldNo("Currency Factor"), false);
        end;

        if ReplaceVATDate then
            "VAT Reporting Date" := VATDateReq;

        if ReplaceDocDate and ("Document Date" <> PostingDateReq) then begin
            UpdateDocumentDate := true;
            Validate("Document Date", PostingDateReq);
        end;

        Commit();
    end;


    /// <summary>
    /// Retrieves the name of the payment service assigned to the document.
    /// </summary>
    procedure GetSelectedPaymentServicesText(): Text
    var
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        exit(PaymentServiceSetup.GetSelectedPaymentsText("Payment Service Set ID"));
    end;

    /// <summary>
    /// Updates the payment service on the document with the default payment service from the setup.
    /// </summary>
    procedure SetDefaultPaymentServices()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultPaymentServices(Rec, IsHandled);
        if IsHandled then
            exit;

        if not PaymentServiceSetup.CanChangePaymentService(Rec) then
            exit;

        if PaymentServiceSetup.GetDefaultPaymentServices(SetID) then
            Validate("Payment Service Set ID", SetID);
    end;

    /// <summary>
    /// Opens a page to either select an existing payment service or set up a new one if none exists.
    /// The payment service is then assigned to the document.
    /// </summary>
    procedure ChangePaymentServiceSetting()
    var
        PaymentServiceSetup: Record "Payment Service Setup";
        SetID: Integer;
    begin
        SetID := "Payment Service Set ID";
        if PaymentServiceSetup.SelectPaymentService(SetID) then begin
            Validate("Payment Service Set ID", SetID);
            Modify(true);
        end;
    end;

    /// <summary>
    /// Check if sales header is credit document type. Credit documents are return orders and credit memos.
    /// </summary>
    /// <returns>True if the sales header is a credit document, otherwise false.</returns>
    procedure IsCreditDocType() CreditDocType: Boolean
    begin
        CreditDocType := "Document Type" in ["Document Type"::"Return Order", "Document Type"::"Credit Memo"];
        OnBeforeIsCreditDocType(Rec, CreditDocType);
    end;

    /// <summary>
    /// Determines if sales header has sell-to information.
    /// </summary>
    /// <returns>True if sales header has sell-to information, otherwise false.</returns>
    procedure HasSellToAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasSellToAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case true of
            "Sell-to Address" <> '':
                exit(true);
            "Sell-to Address 2" <> '':
                exit(true);
            "Sell-to City" <> '':
                exit(true);
            "Sell-to Country/Region Code" <> '':
                exit(true);
            "Sell-to County" <> '':
                exit(true);
            "Sell-to Post Code" <> '':
                exit(true);
            "Sell-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Determines if sales header has ship-to information.
    /// </summary>
    /// <returns>True if sales header has ship-to information, otherwise false.</returns>
    procedure HasShipToAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasShipToAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case true of
            "Ship-to Address" <> '':
                exit(true);
            "Ship-to Address 2" <> '':
                exit(true);
            "Ship-to City" <> '':
                exit(true);
            "Ship-to Country/Region Code" <> '':
                exit(true);
            "Ship-to County" <> '':
                exit(true);
            "Ship-to Post Code" <> '':
                exit(true);
            "Ship-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Determines if sales header has bill-to information.
    /// </summary>
    /// <returns>True if sales header has bill-to information, otherwise false.</returns>
    procedure HasBillToAddress() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHasBillToAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case true of
            "Bill-to Address" <> '':
                exit(true);
            "Bill-to Address 2" <> '':
                exit(true);
            "Bill-to City" <> '':
                exit(true);
            "Bill-to Country/Region Code" <> '':
                exit(true);
            "Bill-to County" <> '':
                exit(true);
            "Bill-to Post Code" <> '':
                exit(true);
            "Bill-to Contact" <> '':
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Determines if the sales header has any item charge assignments.
    /// </summary>
    /// <returns>True if item charge assignments exists, otherwise false.</returns>
    procedure HasItemChargeAssignment(): Boolean
    var
        ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssgntSales.SetRange("Document Type", "Document Type");
        ItemChargeAssgntSales.SetRange("Document No.", "No.");
        ItemChargeAssgntSales.SetFilter("Amount to Assign", '<>%1', 0);
        exit(not ItemChargeAssgntSales.IsEmpty);
    end;

    local procedure CopySellToCustomerAddressFieldsFromCustomer(var SellToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopySellToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, IsHandled);
        if not IsHandled then begin
            "Sell-to Customer Templ. Code" := '';
            "Sell-to Customer Name" := Customer.Name;
            "Sell-to Customer Name 2" := Customer."Name 2";
            "Sell-to Phone No." := Customer."Phone No.";
            "Sell-to E-Mail" := Customer."E-Mail";
            if SellToCustomerIsReplaced() or
                ShouldCopyAddressFromSellToCustomer(SellToCustomer) or
                (HasDifferentSellToAddress(SellToCustomer) and SellToCustomer.HasAddress())
            then begin
                "Sell-to Address" := SellToCustomer.Address;
                "Sell-to Address 2" := SellToCustomer."Address 2";
                "Sell-to City" := SellToCustomer.City;
                "Sell-to Post Code" := SellToCustomer."Post Code";
                "Sell-to County" := SellToCustomer.County;
                "Sell-to Country/Region Code" := SellToCustomer."Country/Region Code";
                OnCopySellToCustomerAddressFieldsFromCustomerOnAfterAssignSellToCustomerAddress(Rec, SellToCustomer);
            end;
            if not SkipSellToContact then
                "Sell-to Contact" := SellToCustomer.Contact;
            "Gen. Bus. Posting Group" := SellToCustomer."Gen. Bus. Posting Group";
            if "VAT Bus. Posting Group" = '' then
                "VAT Bus. Posting Group" := SellToCustomer."VAT Bus. Posting Group"
            else
                Validate("VAT Bus. Posting Group", SellToCustomer."VAT Bus. Posting Group");
            "Tax Area Code" := SellToCustomer."Tax Area Code";
            "Tax Liable" := SellToCustomer."Tax Liable";
            "Registration Number" := SellToCustomer."Registration Number";
            "VAT Country/Region Code" := SellToCustomer."Country/Region Code";
            "VAT Registration No." := SellToCustomer.GetVATRegistrationNo();
            "Shipping Advice" := SellToCustomer."Shipping Advice";
            "Salesperson Code" := SellToCustomer."Salesperson Code";
            IsHandled := false;
            OnCopySelltoCustomerAddressFieldsFromCustomerOnBeforeAssignRespCenter(Rec, SellToCustomer, IsHandled);
            if not IsHandled then begin
                "Responsibility Center" := UserSetupMgt.GetRespCenter(0, SellToCustomer."Responsibility Center");
                OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(Rec, SellToCustomer, CurrFieldNo);
            end;
            IsHandled := false;
            OnCopySellToCustomerAddressFieldsFromCustomerOnBeforeUpdateLocation(Rec, SellToCustomer, IsHandled);
            if not IsHandled then
                UpdateLocationCode(SellToCustomer."Location Code");
        end;

        OnAfterCopySellToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, CurrFieldNo, SkipBillToContact, SkipSellToContact);
    end;

    /// <summary>
    /// Updates sales header with data from provided sell-to customer record.
    /// </summary>
    /// <param name="SellToCustomer">Sell-to customer record to copy data from.</param>
    procedure CopyShipToCustomerAddressFieldsFromCust(var SellToCustomer: Record Customer)
    var
        CustomerTempl: Record "Customer Templ.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := SellToCustomer.Name;
        "Ship-to Name 2" := SellToCustomer."Name 2";
        if SellToCustomerIsReplaced() or
            ShipToAddressEqualsOldSellToAddress() or
            (HasDifferentShipToAddress(SellToCustomer) and SellToCustomer.HasAddress())
        then begin
            "Ship-to Address" := SellToCustomer.Address;
            "Ship-to Address 2" := SellToCustomer."Address 2";
            "Ship-to City" := SellToCustomer.City;
            "Ship-to Post Code" := SellToCustomer."Post Code";
            "Ship-to County" := SellToCustomer.County;
            "Ship-to Phone No." := SellToCustomer."Phone No.";
            Validate("Ship-to Country/Region Code", SellToCustomer."Country/Region Code");
            OnCopyShipToCustomerAddressFieldsFromCustOnAfterAssignAddressFromSellToCustomer(Rec, SellToCustomer);
        end;
        "Ship-to Phone No." := SellToCustomer."Phone No.";
        "Ship-to Contact" := SellToCustomer.Contact;
        if not CustomerTempl.Get("Sell-to Customer Templ. Code") then begin
            Validate("Tax Area Code", SellToCustomer."Tax Area Code");
            Validate("Tax Liable", SellToCustomer."Tax Liable");
        end;
        SetCustomerLocationCode(SellToCustomer);

        IsHandled := false;
        OnCopyShipToCustomerAddressFieldsFromCustOnBeforeValidateShippingAgentFields(Rec, xRec, SellToCustomer, IsHandled);
        if not IsHandled then begin
            Validate("Shipping Agent Code", SellToCustomer."Shipping Agent Code");
            Validate("Shipping Agent Service Code", SellToCustomer."Shipping Agent Service Code");
        end;

        OnAfterCopyShipToCustomerAddressFieldsFromCustomer(Rec, SellToCustomer, xRec);
    end;

    local procedure SetCustomerLocationCode(SellToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCustomerLocationCode(Rec, IsHandled, SellToCustomer);
        if IsHandled then
            exit;

        if SellToCustomer."Location Code" <> '' then
            Validate("Location Code", SellToCustomer."Location Code");
    end;

    local procedure SetCompanyBankAccount()
    var
        BankAccount: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCompanyBankAccount(Rec, IsHandled);
        if not IsHandled then
            Validate("Company Bank Account Code", BankAccount.GetDefaultBankAccountNoForCurrency("Currency Code"));
        OnAfterSetCompanyBankAccount(Rec, xRec);
    end;

    /// <summary>
    /// Updates the document's shipping address from the provided ship-to address.
    /// </summary>
    /// <param name="ShipToAddr">Ship-to address to update the shipping address with.</param>
    procedure SetShipToCustomerAddressFieldsFromShipToAddr(ShipToAddr: Record "Ship-to Address")
    var
        IsHandled: Boolean;
        ShouldCopyLocationCode: Boolean;
        ShouldCopySalespersonCode: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr, IsHandled);
        if IsHandled then
            exit;

        "Ship-to Name" := ShipToAddr.Name;
        "Ship-to Name 2" := ShipToAddr."Name 2";
        "Ship-to Address" := ShipToAddr.Address;
        "Ship-to Address 2" := ShipToAddr."Address 2";
        "Ship-to City" := ShipToAddr.City;
        "Ship-to Post Code" := ShipToAddr."Post Code";
        "Ship-to County" := ShipToAddr.County;
        Validate("Ship-to Country/Region Code", ShipToAddr."Country/Region Code");
        "Ship-to Phone No." := ShipToAddr."Phone No.";
        "Ship-to Contact" := ShipToAddr.Contact;
        ShouldCopyLocationCode := ShipToAddr."Location Code" <> '';
        ShouldCopySalespersonCode := (ShipToAddr."Salesperson Code" <> '') and (ShipToAddr."Salesperson Code" <> "Salesperson Code");
        OnSetShipToCustomerAddressFieldsFromShipToAddrOnAfterCalcShouldCopyLocationCode(Rec, xRec, ShipToAddr, ShouldCopyLocationCode, ShouldCopySalespersonCode);
        if ShouldCopyLocationCode then
            Validate("Location Code", ShipToAddr."Location Code");
        if ShouldCopySalespersonCode then
            Validate("Salesperson Code", ShipToAddr."Salesperson Code");
        IsHandled := false;
        OnSetShipToCustomerAddressFieldsFromShipToAddrOnBeforeValidateShippingAgentFields(Rec, xRec, ShipToAddr, IsHandled);
        if not IsHandled then begin
            Validate("Shipping Agent Code", ShipToAddr."Shipping Agent Code");
            Validate("Shipping Agent Service Code", ShipToAddr."Shipping Agent Service Code");
        end;
        if ShipToAddr."Tax Area Code" <> '' then
            Validate("Tax Area Code", ShipToAddr."Tax Area Code");
        Validate("Tax Liable", ShipToAddr."Tax Liable");

        OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(Rec, ShipToAddr, xRec);
    end;

    /// <summary>
    /// Updates the billing information on the document from the provided bill-to customer.
    /// </summary>
    /// <param name="BillToCustomer">Bill-to customer to update the billing infromation from.</param>
    procedure SetBillToCustomerAddressFieldsFromCustomer(var BillToCustomer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBillToCustomerAddressFieldsFromCustomer(Rec, BillToCustomer, SkipBillToContact, IsHandled, xRec, GLSetup, CurrFieldNo);
        if IsHandled then
            exit;

        "Bill-to Customer Templ. Code" := '';
        "Bill-to Name" := BillToCustomer.Name;
        "Bill-to Name 2" := BillToCustomer."Name 2";
        if BillToCustomerIsReplaced() or
            ShouldCopyAddressFromBillToCustomer(BillToCustomer) or
            (HasDifferentBillToAddress(BillToCustomer) and BillToCustomer.HasAddress())
        then begin
            "Bill-to Address" := BillToCustomer.Address;
            "Bill-to Address 2" := BillToCustomer."Address 2";
            "Bill-to City" := BillToCustomer.City;
            "Bill-to Post Code" := BillToCustomer."Post Code";
            "Bill-to County" := BillToCustomer.County;
            "Bill-to Country/Region Code" := BillToCustomer."Country/Region Code";
            OnSetBillToCustomerAddressFieldsFromCustomerOnAfterAssignBillToCustomerAddress(Rec, BillToCustomer);
        end;
        if not SkipBillToContact then
            "Bill-to Contact" := BillToCustomer.Contact;
        "Payment Terms Code" := BillToCustomer."Payment Terms Code";
        "Prepmt. Payment Terms Code" := BillToCustomer."Payment Terms Code";

        if "Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"] then begin
            "Payment Method Code" := '';
            if PaymentTerms.Get("Payment Terms Code") then
                if PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then
                    "Payment Method Code" := BillToCustomer."Payment Method Code"
        end else
            "Payment Method Code" := BillToCustomer."Payment Method Code";

        AltCustVATRegFacade.UpdateSetupOnBillToCustomerChangeInSalesHeader(Rec, xRec, BillToCustomer);

        "Customer Posting Group" := BillToCustomer."Customer Posting Group";
        "Currency Code" := BillToCustomer."Currency Code";
        "Customer Price Group" := BillToCustomer."Customer Price Group";
        "Prices Including VAT" := BillToCustomer."Prices Including VAT";
        "Price Calculation Method" := BillToCustomer.GetPriceCalculationMethod();
        "Allow Line Disc." := BillToCustomer."Allow Line Disc.";
        "Invoice Disc. Code" := BillToCustomer."Invoice Disc. Code";
        "Customer Disc. Group" := BillToCustomer."Customer Disc. Group";
        "Language Code" := BillToCustomer."Language Code";
        "Format Region" := BillToCustomer."Format Region";
        if (BilltoCustomer."No." <> "Sell-to Customer No.") or BillToCustomerIsReplaced() then
            UpdateShipToSalespersonCode(FieldNo("Bill-to Customer No."));
        "Combine Shipments" := BillToCustomer."Combine Shipments";
        Reserve := BillToCustomer.Reserve;
        if "Document Type" in ["Document Type"::Order, "Document Type"::Quote] then
            "Prepayment %" := BillToCustomer."Prepayment %";
        "Tax Area Code" := BillToCustomer."Tax Area Code";
        if ("Ship-to Code" = '') or ("Sell-to Customer No." <> BillToCustomer."No.") then
            "Tax Liable" := BillToCustomer."Tax Liable";

        OnAfterSetFieldsBilltoCustomer(Rec, BillToCustomer, xRec, SkipBillToContact, CurrFieldNo);
    end;

    /// <summary>
    /// Sets the shipping address details for a sales header.
    /// </summary>
    /// <param name="ShipToName">New ship-to name value.</param>
    /// <param name="ShipToName2">New ship-to name 2 value.</param>
    /// <param name="ShipToAddress">New ship-to address value.</param>
    /// <param name="ShipToAddress2">New ship-to address 2 value.</param>
    /// <param name="ShipToCity">New ship-to city value.</param>
    /// <param name="ShipToPostCode">New ship-to post code value.</param>
    /// <param name="ShipToCounty">New ship-to county value.</param>
    /// <param name="ShipToCountryRegionCode">New ship-to country/region code value.</param>
    procedure SetShipToAddress(ShipToName: Text[100]; ShipToName2: Text[50]; ShipToAddress: Text[100]; ShipToAddress2: Text[50]; ShipToCity: Text[30]; ShipToPostCode: Code[20]; ShipToCounty: Text[30]; ShipToCountryRegionCode: Code[10])
    begin
        "Ship-to Name" := ShipToName;
        "Ship-to Name 2" := ShipToName2;
        "Ship-to Address" := ShipToAddress;
        "Ship-to Address 2" := ShipToAddress2;
        "Ship-to City" := ShipToCity;
        "Ship-to Post Code" := ShipToPostCode;
        "Ship-to County" := ShipToCounty;
        "Ship-to Country/Region Code" := ShipToCountryRegionCode;

        OnAfterSetShipToAddress(Rec);
    end;

    local procedure ShouldCopyAddressFromSellToCustomer(SellToCustomer: Record Customer): Boolean
    begin
        exit((not HasSellToAddress()) and SellToCustomer.HasAddress());
    end;

    local procedure ShouldCopyAddressFromBillToCustomer(BillToCustomer: Record Customer): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldCopyAddressFromBillToCustomer(BillToCustomer, Rec, xRec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        exit(((not HasBillToAddress()) and BillToCustomer.HasAddress()) or (xRec."Bill-to Contact" <> BillToCustomer.Contact));
    end;

    local procedure SellToCustomerIsReplaced(): Boolean
    begin
        exit((xRec."Sell-to Customer No." <> '') and (xRec."Sell-to Customer No." <> "Sell-to Customer No."));
    end;

    local procedure BillToCustomerIsReplaced(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeBillToCustomerIsReplaced(Rec, xRec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit((xRec."Bill-to Customer No." <> '') and (xRec."Bill-to Customer No." <> "Bill-to Customer No."));
    end;

    local procedure UpdateShipToAddressFromSellToAddress(FieldNumber: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToAddressFromSellToAddress(Rec, FieldNumber, IsHandled);
        if IsHandled then
            exit;

        if ("Ship-to Code" = '') and ShipToAddressEqualsOldSellToAddress() then begin
            case FieldNumber of
                FieldNo("Ship-to Address"):
                    "Ship-to Address" := "Sell-to Address";
                FieldNo("Ship-to Address 2"):
                    "Ship-to Address 2" := "Sell-to Address 2";
                FieldNo("Ship-to City"), FieldNo("Ship-to Post Code"):
                    begin
                        "Ship-to City" := "Sell-to City";
                        "Ship-to Post Code" := "Sell-to Post Code";
                        "Ship-to County" := "Sell-to County";
                        "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
                    end;
                FieldNo("Ship-to County"):
                    "Ship-to County" := "Sell-to County";
                FieldNo("Ship-to Country/Region Code"):
                    "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
                FieldNo("Ship-to Phone No."):
                    "Ship-to Phone No." := "Sell-to Phone No.";
            end;
            OnAfterUpdateShipToAddressFromSellToAddress(Rec, xRec, FieldNumber);
        end;
    end;

    local procedure ShipToAddressEqualsOldSellToAddress(): Boolean
    begin
        exit(IsShipToAddressEqualToSellToAddress(xRec, Rec));
    end;

    /// <summary>
    /// Determines if sell-to address matches the ship-to address.
    /// </summary>
    /// <returns>True if the address match, otherwise false.</returns>
    procedure ShipToAddressEqualsSellToAddress(): Boolean
    begin
        exit(IsShipToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsShipToAddressEqualToSellToAddress(SalesHeaderWithSellTo: Record "Sales Header"; SalesHeaderWithShipTo: Record "Sales Header"): Boolean
    var
        Result: Boolean;
    begin
        Result :=
          (SalesHeaderWithSellTo."Sell-to Address" = SalesHeaderWithShipTo."Ship-to Address") and
          (SalesHeaderWithSellTo."Sell-to Address 2" = SalesHeaderWithShipTo."Ship-to Address 2") and
          (SalesHeaderWithSellTo."Sell-to City" = SalesHeaderWithShipTo."Ship-to City") and
          (SalesHeaderWithSellTo."Sell-to County" = SalesHeaderWithShipTo."Ship-to County") and
          (SalesHeaderWithSellTo."Sell-to Post Code" = SalesHeaderWithShipTo."Ship-to Post Code") and
          (SalesHeaderWithSellTo."Sell-to Country/Region Code" = SalesHeaderWithShipTo."Ship-to Country/Region Code") and
          (SalesHeaderWithSellTo."Sell-to Phone No." = SalesHeaderWithShipTo."Ship-to Phone No.") and
          (SalesHeaderWithSellTo."Sell-to Contact" = SalesHeaderWithShipTo."Ship-to Contact");

        OnAfterIsShipToAddressEqualToSellToAddress(SalesHeaderWithSellTo, SalesHeaderWithShipTo, Result);
        exit(Result);
    end;

    /// <summary>
    /// Determines if sell-to address matches the bill-to address.
    /// </summary>
    /// <returns>True if addresses match, otherwise false.</returns>
    procedure BillToAddressEqualsSellToAddress(): Boolean
    begin
        exit(IsBillToAddressEqualToSellToAddress(Rec, Rec));
    end;

    local procedure IsBillToAddressEqualToSellToAddress(SalesHeaderWithSellTo: Record "Sales Header"; SalesHeaderWithBillTo: Record "Sales Header") Result: Boolean
    begin
        Result := (SalesHeaderWithSellTo."Sell-to Address" = SalesHeaderWithBillTo."Bill-to Address") and
           (SalesHeaderWithSellTo."Sell-to Address 2" = SalesHeaderWithBillTo."Bill-to Address 2") and
           (SalesHeaderWithSellTo."Sell-to City" = SalesHeaderWithBillTo."Bill-to City") and
           (SalesHeaderWithSellTo."Sell-to County" = SalesHeaderWithBillTo."Bill-to County") and
           (SalesHeaderWithSellTo."Sell-to Post Code" = SalesHeaderWithBillTo."Bill-to Post Code") and
           (SalesHeaderWithSellTo."Sell-to Country/Region Code" = SalesHeaderWithBillTo."Bill-to Country/Region Code") and
           (SalesHeaderWithSellTo."Sell-to Contact No." = SalesHeaderWithBillTo."Bill-to Contact No.") and
           (SalesHeaderWithSellTo."Sell-to Contact" = SalesHeaderWithBillTo."Bill-to Contact");
        OnAfterIsBillToAddressEqualToSellToAddress(SalesHeaderWithSellTo, SalesHeaderWithBillTo, Result);
    end;

    /// <summary>
    /// Copies the sell-to address to the ship-to address.
    /// </summary>
    procedure CopySellToAddressToShipToAddress()
    begin
        "Ship-to Address" := "Sell-to Address";
        "Ship-to Address 2" := "Sell-to Address 2";
        "Ship-to City" := "Sell-to City";
        "Ship-to Contact" := "Sell-to Contact";
        "Ship-to Country/Region Code" := "Sell-to Country/Region Code";
        "Ship-to County" := "Sell-to County";
        "Ship-to Post Code" := "Sell-to Post Code";
        "Ship-to Phone No." := "Sell-to Phone No.";

        OnAfterCopySellToAddressToShipToAddress(Rec);
    end;

    /// <summary>
    /// Copies the sell-to address to the bill-to address if bill-to and sell-to customer numbers are the same.
    /// </summary>
    procedure CopySellToAddressToBillToAddress()
    begin
        OnBeforeCopySellToAddressToBillToAddress(Rec);
        if "Bill-to Customer No." = "Sell-to Customer No." then begin
            "Bill-to Address" := "Sell-to Address";
            "Bill-to Address 2" := "Sell-to Address 2";
            "Bill-to Post Code" := "Sell-to Post Code";
            "Bill-to Country/Region Code" := "Sell-to Country/Region Code";
            "Bill-to City" := "Sell-to City";
            "Bill-to County" := "Sell-to County";
            OnAfterCopySellToAddressToBillToAddress(Rec);
        end;
    end;

    local procedure UpdateShipToContact()
    var
        ShipToAddress: Record "Ship-to Address";
        IsHandled: Boolean;
    begin
        if not (CurrFieldNo in [FieldNo("Sell-to Contact"), FieldNo("Sell-to Contact No.")]) then
            exit;

        if IsCreditDocType() then
            exit;

        if "Ship-to Code" <> '' then
            if ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code") then
                if ShipToAddress.Contact <> '' then
                    exit;

        IsHandled := false;
        OnUpdateShipToContactOnBeforeValidateShipToContact(Rec, xRec, CurrFieldNo, IsHandled);
        if not IsHandled then
            Validate("Ship-to Contact", "Sell-to Contact");
    end;

    /// <summary>
    /// Raises a dialog to confirm closing a page if unposted lines exist.
    /// </summary>
    /// <returns>True if page should be closed, otherwise false.</returns>
    procedure ConfirmCloseUnposted() Result: Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        IsHandled: Boolean;
    begin
        if SalesLinesExist() then begin
            IsHandled := false;
            OnConfirmCloseUnpostedOnSalesLinesExist(Rec, Result, IsHandled);
            if IsHandled then
                exit(Result);

            if InstructionMgt.IsUnpostedEnabledForRecord(Rec) then
                exit(InstructionMgt.ShowConfirm(DocumentNotPostedClosePageQst, InstructionMgt.QueryPostOnCloseCode()));
        end;
        exit(true)
    end;

    local procedure UpdateOpportunity()
    var
        Opp: Record Opportunity;
        OpportunityEntry: Record "Opportunity Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOpportunity(IsHandled, Rec);
        if IsHandled then
            exit;

        if not ("Opportunity No." <> '') or not ("Document Type" in ["Document Type"::Quote, "Document Type"::Order]) then
            exit;

        if not Opp.Get("Opportunity No.") then
            exit;

        if "Document Type" = "Document Type"::Order then begin
            if not ConfirmManagement.GetResponseOrDefault(Text040, true) then
                Error(Text044);

            OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
            OpportunityEntry.ModifyAll(Active, false);

            OpportunityEntry.Init();
            OpportunityEntry.Validate("Opportunity No.", Opp."No.");

            OpportunityEntry.LockTable();
            OpportunityEntry."Entry No." := OpportunityEntry.GetLastEntryNo() + 1;
            OpportunityEntry."Sales Cycle Code" := Opp."Sales Cycle Code";
            OpportunityEntry."Contact No." := Opp."Contact No.";
            OpportunityEntry."Contact Company No." := Opp."Contact Company No.";
            OpportunityEntry."Salesperson Code" := Opp."Salesperson Code";
            OpportunityEntry."Campaign No." := Opp."Campaign No.";
            OpportunityEntry."Action Taken" := OpportunityEntry."Action Taken"::Lost;
            OpportunityEntry.Active := true;
            OpportunityEntry."Completed %" := 100;
            OpportunityEntry."Estimated Value (LCY)" := GetOpportunityEntryEstimatedValue();
            OpportunityEntry."Estimated Close Date" := Opp."Date Closed";
            OpportunityEntry.Insert(true);
        end;
        Opp.Find();
        Opp."Sales Document Type" := Opp."Sales Document Type"::" ";
        Opp."Sales Document No." := '';
        OnUpdateOpportunityOnBeforeModify(Opp, Rec);
        Opp.Modify();
        "Opportunity No." := '';
    end;

    local procedure GetOpportunityEntryEstimatedValue(): Decimal
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Opportunity No.", "Opportunity No.");
        if OpportunityEntry.FindLast() then
            exit(OpportunityEntry."Estimated Value (LCY)");
    end;

    /// <summary>
    /// Initializes a sales header from the provided sales header.
    /// </summary>
    /// <param name="SourceSalesHeader">Sales header to copy information from.</param>
    procedure InitFromSalesHeader(SourceSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromSalesHeader(Rec, SourceSalesHeader, IsHandled);
        if not IsHandled then begin
            "Document Date" := SourceSalesHeader."Document Date";
            "Shipment Date" := SourceSalesHeader."Shipment Date";
            "Shortcut Dimension 1 Code" := SourceSalesHeader."Shortcut Dimension 1 Code";
            "Shortcut Dimension 2 Code" := SourceSalesHeader."Shortcut Dimension 2 Code";
            "Dimension Set ID" := SourceSalesHeader."Dimension Set ID";
            "Location Code" := SourceSalesHeader."Location Code";
            SetShipToAddress(
            SourceSalesHeader."Ship-to Name", SourceSalesHeader."Ship-to Name 2", SourceSalesHeader."Ship-to Address",
            SourceSalesHeader."Ship-to Address 2", SourceSalesHeader."Ship-to City", SourceSalesHeader."Ship-to Post Code",
            SourceSalesHeader."Ship-to County", SourceSalesHeader."Ship-to Country/Region Code");
            "Ship-to Phone No." := SourceSalesHeader."Ship-to Phone No.";
            "Ship-to Contact" := SourceSalesHeader."Ship-to Contact";
        end;

        OnAfterInitFromSalesHeader(Rec, SourceSalesHeader);
    end;

    local procedure InitFromContact(ContactNo: Code[20]; CustomerNo: Code[20]; ContactCaption: Text): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if (ContactNo = '') and (CustomerNo = '') then begin
            if not SalesLine.IsEmpty() then
                Error(Text005, ContactCaption);
            Init();
            GetSalesSetup();
            "No. Series" := xRec."No. Series";
            OnInitFromContactOnBeforeInitRecord(Rec, xRec);
            InitRecord();
            InitNoSeries();
            OnInitFromContactOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure InitFromTemplate(TemplateCode: Code[20]; TemplateCaption: Text): Boolean
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", "Document Type");
        SalesLine.SetRange("Document No.", "No.");
        if TemplateCode = '' then begin
            if not SalesLine.IsEmpty() then
                Error(Text005, TemplateCaption);
            Init();
            GetSalesSetup();
            "No. Series" := xRec."No. Series";
            OnInitFromTemplateOnBeforeInitRecord(Rec, xRec);
            InitRecord();
            InitNoSeries();
            OnInitFromTemplateOnAfterInitNoSeries(Rec, xRec);
            exit(true);
        end;
    end;

    local procedure InitFromBillToCustTemplate(BillToCustTemplate: Record "Customer Templ.")
    begin
        OnBeforeInitFromBillToCustTemplate(Rec, xRec, BillToCustTemplate);

        BillToCustTemplate.TestField("Customer Posting Group");
        "Customer Posting Group" := BillToCustTemplate."Customer Posting Group";
        "Invoice Disc. Code" := BillToCustTemplate."Invoice Disc. Code";
        "Customer Price Group" := BillToCustTemplate."Customer Price Group";
        "Customer Disc. Group" := BillToCustTemplate."Customer Disc. Group";
        "Allow Line Disc." := BillToCustTemplate."Allow Line Disc.";
        Validate("Payment Terms Code", BillToCustTemplate."Payment Terms Code");
        Validate("Payment Method Code", BillToCustTemplate."Payment Method Code");
        "Prices Including VAT" := BillToCustTemplate."Prices Including VAT";
        "Shipment Method Code" := BillToCustTemplate."Shipment Method Code";

        OnAfterInitFromBillToCustTemplate(Rec, BillToCustTemplate);
    end;

    local procedure ValidateTaxAreaCode()
    var
        TaxArea: Record "Tax Area";
    begin
        if "Tax Area Code" = '' then
            exit;

        TaxArea.Get("Tax Area Code");
    end;

    /// <summary>
    /// Updates current sales header work description with the provided description.
    /// </summary>
    /// <param name="NewWorkDescription">New work description.</param>
    procedure SetWorkDescription(NewWorkDescription: Text)
    var
        OutStream: OutStream;
    begin
        OnBeforeSetWorkDescription(Rec, NewWorkDescription);
        Clear("Work Description");
        "Work Description".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewWorkDescription);
        Modify();
    end;

    /// <summary>
    /// Retrieves work description from the sales header.
    /// </summary>
    /// <returns>Work description.</returns>
    procedure GetWorkDescription() WorkDescription: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Work Description");
        "Work Description".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Work Description")));
    end;

    /// <summary>
    /// Filters the contact for the company number that is associated with either the customer or contact number.
    /// </summary>
    /// <remarks>
    /// If no business relations exist within provided customer and contacts
    /// and document type is quote, then filters company contact based on provided contact number.
    /// </remarks>
    /// <param name="CustomerNo">The number of the customer to filter the contact for.</param>
    /// <param name="ContactNo">The number of the contact to look up.</param>
    /// <param name="Contact">Return value: Filtered contact record set.</param>
    procedure LookupContact(CustomerNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        FilterByContactCompany: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupContact(CustomerNo, ContactNo, Contact, IsHandled);
        if IsHandled then
            exit;

        if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo) then
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
        else
            if "Document Type" = "Document Type"::Quote then
                FilterByContactCompany := true
            else
                Contact.SetRange("Company No.", '');
        if ContactNo <> '' then
            if Contact.Get(ContactNo) then
                if FilterByContactCompany then
                    Contact.SetRange("Company No.", Contact."Company No.");
    end;

    /// <summary>
    /// Sets the global flag SelectNoSeriesAllowed to true.
    /// </summary>
    /// <remarks>
    /// The global flag is used to determine if the lookup for the number series can been shown.
    /// </remarks>
    procedure SetAllowSelectNoSeries()
    begin
        SelectNoSeriesAllowed := true;
    end;

    /// <summary>
    /// Sets the default salesperson code for the sales header.
    /// </summary>
    /// <remarks>
    /// Retrieves default salesperson code from user setup. If retrieved salesperson code privacy is not blocked,
    /// sets it for the sales header.
    /// </remarks>
    procedure SetDefaultSalesperson()
    var
        UserSetupSalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSalesperson(Rec, IsHandled, InsertMode);
        if IsHandled then
            exit;

        UserSetupSalespersonCode := GetUserSetupSalespersonCode();
        if UserSetupSalespersonCode <> '' then
            if Salesperson.Get(UserSetupSalespersonCode) then
                if not Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    Validate("Salesperson Code", UserSetupSalespersonCode);
    end;

    /// <summary>
    /// Retrieves the salesperson code of the current user from the user setup.
    /// </summary>
    /// <returns>Salesperson code of the current user from the user setup.</returns>
    procedure GetUserSetupSalespersonCode(): Code[20]
    var
        UserSetup: Record "User Setup";
    begin
        if not UserSetup.Get(UserId) then
            exit;

        exit(UserSetup."Salespers./Purch. Code");
    end;

    /// <summary>
    /// Removes the filter on customer number if the customer number has changed.
    /// </summary>
    /// <param name="SalesHeader">The current sales header record.</param>
    /// <param name="xSalesHeader">Sales header record before the changes.</param>
    procedure SelltoCustomerNoOnAfterValidate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
        if SalesHeader.GetFilter("Sell-to Customer No.") = xSalesHeader."Sell-to Customer No." then
            if SalesHeader."Sell-to Customer No." <> xSalesHeader."Sell-to Customer No." then
                SalesHeader.SetRange("Sell-to Customer No.");

        OnAfterSelltoCustomerNoOnAfterValidate(Rec, xRec);
    end;

    /// <summary>
    /// Releases the sales documents that are not yet released.
    /// </summary>
    /// <param name="SalesHeader">Filtered sales headers to release.</param>
    procedure PerformManualRelease(var SalesHeader: Record "Sales Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
        PrevFilterGroup: Integer;
    begin
        NoOfSelected := SalesHeader.Count;
        PrevFilterGroup := SalesHeader.FilterGroup();
        SalesHeader.FilterGroup(10);
        SalesHeader.SetFilter(Status, '<>%1', SalesHeader.Status::Released);
        NoOfSkipped := NoOfSelected - SalesHeader.Count;
        BatchProcessingMgt.BatchProcess(SalesHeader, Codeunit::"Sales Manual Release", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
        SalesHeader.SetRange(Status);
        SalesHeader.FilterGroup(PrevFilterGroup);

    end;

    /// <summary>
    /// Releases the sales document if it's not already released.
    /// </summary>
    /// <remarks>
    /// The transaction is committed after release.
    /// </remarks>
    procedure PerformManualRelease()
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        IsHandled: Boolean;
    begin
        OnBeforePerformManualRelease(Rec, IsHandled);
        if not IsHandled then
            if Rec.Status <> Rec.Status::Released then begin
                ReleaseSalesDoc.PerformManualRelease(Rec);
                Commit();
            end;
    end;

    /// <summary>
    /// Reopens sales documents that are not already open.
    /// </summary>
    /// <param name="SalesHeader">Filtered sales headers to reopen.</param>
    procedure PerformManualReopen(var SalesHeader: Record "Sales Header")
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        NoOfSelected: Integer;
        NoOfSkipped: Integer;
    begin
        NoOfSelected := SalesHeader.Count;
        SalesHeader.SetFilter(Status, '<>%1', SalesHeader.Status::Open);
        NoOfSkipped := NoOfSelected - SalesHeader.Count;
        BatchProcessingMgt.BatchProcess(SalesHeader, Codeunit::"Sales Manual Reopen", Enum::"Error Handling Options"::"Show Error", NoOfSelected, NoOfSkipped);
    end;

    /// <summary>
    /// Opens a page for selecting a customer template to use for creating a new customer.
    /// </summary>
    /// <remarks>
    /// If sell-to contact has no business relations a confirmation for template selection is raised.
    /// If the user confirms, it commits any changes
    /// and returns the code of the new customer template selected by the user.
    /// </remarks>
    /// <returns>Customer template code.</returns>
    procedure SelectSalesHeaderNewCustomerTemplate(): Code[20]
    var
        Contact: Record Contact;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        Contact.Get("Sell-to Contact No.");
        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            Contact.Get(Contact."Company No.");
        if not Contact.ContactToCustBusinessRelationExist() then
            if ConfirmManagement.GetResponse(SelectCustomerTemplateQst, false) then begin
                Commit();
                exit(Contact.LookupNewCustomerTemplate());
            end;
    end;

    local procedure ModifyBillToCustomerAddress()
    var
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyBillToCustomerAddress(Rec, IsHandled);
        if IsHandled then
            exit;

        GetSalesSetup();
        if SalesSetup."Ignore Updated Addresses" then
            exit;

        if IsCreditDocType() then
            exit;

        if ("Bill-to Customer No." = "Sell-to Customer No.") then
            exit;

        if not HasBillToAddress() then
            exit;

        if not Customer.Get("Bill-to Customer No.") then
            exit;

        if not HasDifferentBillToAddress(Customer) then
            exit;

        ShowModifyAddressNotification(GetModifyBillToCustomerAddressNotificationId(),
          ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
          'CopyBillToCustomerAddressFieldsFromSalesDocument', "Bill-to Customer No.",
          "Bill-to Name", FieldName("Bill-to Customer No."));
    end;

    local procedure ModifyCustomerAddress()
    var
        Customer: Record Customer;
    begin
        OnBeforeModifyCustomerAddress(Rec, xRec);

        GetSalesSetup();
        if SalesSetup."Ignore Updated Addresses" then
            exit;
        if IsCreditDocType() then
            exit;
        if Customer.Get("Sell-to Customer No.") and HasSellToAddress() and HasDifferentSellToAddress(Customer) then
            ShowModifyAddressNotification(GetModifyCustomerAddressNotificationId(),
              ModifyCustomerAddressNotificationLbl, ModifyCustomerAddressNotificationMsg,
              'CopySellToCustomerAddressFieldsFromSalesDocument', "Sell-to Customer No.",
              "Sell-to Customer Name", FieldName("Sell-to Customer No."));
    end;

    local procedure ShowModifyAddressNotification(NotificationID: Guid; NotificationLbl: Text; NotificationMsg: Text; NotificationFunctionTok: Text; CustomerNumber: Code[20]; CustomerName: Text[100]; CustomerNumberFieldName: Text)
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PageMyNotifications: Page "My Notifications";
        ModifyCustomerAddressNotification: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowModifyAddressNotification(IsHandled, Rec, CustomerNumber);
        if IsHandled then
            exit;

        if not MyNotifications.Get(UserId, NotificationID) then
            PageMyNotifications.InitializeNotificationsWithDefaultState();

        if not MyNotifications.IsEnabled(NotificationID) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Message := StrSubstNo(NotificationMsg, CustomerName);
        ModifyCustomerAddressNotification.AddAction(NotificationLbl, CODEUNIT::"Document Notifications", NotificationFunctionTok);
        ModifyCustomerAddressNotification.AddAction(
          DontShowAgainActionLbl, CODEUNIT::"Document Notifications", 'HideNotificationForCurrentUser');
        ModifyCustomerAddressNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        ModifyCustomerAddressNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        ModifyCustomerAddressNotification.SetData(FieldName("No."), "No.");
        ModifyCustomerAddressNotification.SetData(CustomerNumberFieldName, CustomerNumber);
        NotificationLifecycleMgt.SendNotification(ModifyCustomerAddressNotification, RecordId);
    end;

    /// <summary>
    /// Recalls a sent notification for the provided notification GUID.
    /// </summary>
    /// <remarks>
    /// If it is a credit document or if notification isn't enabled, it won't recall the notification.
    /// </remarks>
    /// <param name="NotificationID">GUID of the notification to recall.</param>
    procedure RecallModifyAddressNotification(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
        ModifyCustomerAddressNotification: Notification;
    begin
        if IsCreditDocType() or (not MyNotifications.IsEnabled(NotificationID)) then
            exit;

        ModifyCustomerAddressNotification.Id := NotificationID;
        ModifyCustomerAddressNotification.Recall();
    end;

    /// <summary>
    /// Returns a GUID for a notification that warns if the sell-to address on sales documents is different
    /// from the customer's existing address.
    /// </summary>
    /// <returns>Notification GUID.</returns>
    procedure GetModifyCustomerAddressNotificationId(): Guid
    begin
        exit('509FD112-31EC-4CDC-AEBF-19B8FEBA526F');
    end;

    /// <summary>
    /// Returns a GUID for a notification that warns if the bill-to address on sales documents is different
    /// from the customer's existing address.
    /// </summary>
    /// <returns>Notification GUID.</returns>
    procedure GetModifyBillToCustomerAddressNotificationId(): Guid
    begin
        exit('2096CE78-6A74-48DB-BC9A-CD5C21504FC1');
    end;

    /// <summary>
    /// Returns a GUID for a notification that warns if the invoice discount amount for the sales line record has been reset.
    /// </summary>
    /// <returns>Notification GUID.</returns>
    procedure GetLineInvoiceDiscountResetNotificationId(): Guid
    begin
        exit('35AB3090-2E03-4849-BBF9-9664DE464605');
    end;

    /// <summary>
    /// Returns a GUID for a notification that warns before posting lines on sales documents where quantity is 0.
    /// </summary>
    /// <returns>Notification GUID.</returns>
    procedure GetWarnWhenZeroQuantitySalesLinePosting(): Guid
    begin
        exit('ce906407-2f7e-410a-8fb9-4fdc76954876');
    end;

    /// <summary>
    /// Inserts the default notification to warn that sell-to address on sales documents is different
    /// from the customer's existing address.
    /// </summary>
    /// <remarks>
    /// Notification is enabled by default.
    /// </remarks>
    procedure SetModifyCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyCustomerAddressNotificationId(),
          ModifySellToCustomerAddressNotificationNameTxt, ModifySellToCustomerAddressNotificationDescriptionTxt, true);
    end;

    /// <summary>
    /// Inserts the default notification to warn that bill-to address on sales documents is different
    /// from the customer's existing address.
    /// </summary>
    /// <remarks>
    /// Notification is enabled by default.
    /// </remarks>
    procedure SetModifyBillToCustomerAddressNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetModifyBillToCustomerAddressNotificationId(),
          ModifyBillToCustomerAddressNotificationNameTxt, ModifyBillToCustomerAddressNotificationDescriptionTxt, true);
    end;

    procedure SetShowExternalDocAlreadyExistNotificationDefaultState(DefaultState: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetShowExternalDocAlreadyExistNotificationId(),
          ShowDocAlreadyExistNotificationNameTxt, ShowDocAlreadyExistNotificationDescriptionTxt, DefaultState);
    end;

    /// <summary>
    /// Disables a specified notification for the current user.
    /// </summary>
    /// <param name="NotificationID">GUID of the notification that needs to be disabled.</param>
    procedure DontNotifyCurrentUserAgain(NotificationID: Guid)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(NotificationID) then
            case NotificationID of
                GetModifyCustomerAddressNotificationId():
                    MyNotifications.InsertDefault(NotificationID, ModifySellToCustomerAddressNotificationNameTxt,
                      ModifySellToCustomerAddressNotificationDescriptionTxt, false);
                GetModifyBillToCustomerAddressNotificationId():
                    MyNotifications.InsertDefault(NotificationID, ModifyBillToCustomerAddressNotificationNameTxt,
                      ModifyBillToCustomerAddressNotificationDescriptionTxt, false);
            end;
    end;

    /// <summary>
    /// Determines if the sell-to address matches the provided customer's address.
    /// </summary>
    /// <param name="Customer">Customer to compare the sell-to address with.</param>
    /// <returns>True if sell-to address is different from provided customer's address, otherwise false.</returns>
    procedure HasDifferentSellToAddress(Customer: Record Customer) Result: Boolean
    begin
        Result := ("Sell-to Address" <> Customer.Address) or
          ("Sell-to Address 2" <> Customer."Address 2") or
          ("Sell-to City" <> Customer.City) or
          ("Sell-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Sell-to County" <> Customer.County) or
          ("Sell-to Post Code" <> Customer."Post Code") or
          ("Sell-to Contact" <> Customer.Contact);

        OnAfterHasDifferentSellToAddress(Rec, Customer, Result);
    end;

    /// <summary>
    /// Determines if the bill-to address matches the provided customer's address.
    /// </summary>
    /// <param name="Customer">Customer to compare the bill-to address with.</param>
    /// <returns>True if bill-to address is different from provided customer's address, otherwise false.</returns>
    procedure HasDifferentBillToAddress(Customer: Record Customer) Result: Boolean
    begin
        Result := ("Bill-to Address" <> Customer.Address) or
          ("Bill-to Address 2" <> Customer."Address 2") or
          ("Bill-to City" <> Customer.City) or
          ("Bill-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Bill-to County" <> Customer.County) or
          ("Bill-to Post Code" <> Customer."Post Code") or
          ("Bill-to Contact" <> Customer.Contact);

        OnAfterHasDifferentBillToAddress(Rec, Customer, Result);
    end;

    /// <summary>
    /// Determines if the ship-to address matches the provided customer's address.
    /// </summary>
    /// <param name="Customer">Customer to compare the ship-to address with.</param>
    /// <returns>True if ship-to address is different from provided customer's address, otherwise false.</returns>
    procedure HasDifferentShipToAddress(Customer: Record Customer) Result: Boolean
    begin
        Result := ("Ship-to Address" <> Customer.Address) or
          ("Ship-to Address 2" <> Customer."Address 2") or
          ("Ship-to City" <> Customer.City) or
          ("Ship-to Country/Region Code" <> Customer."Country/Region Code") or
          ("Ship-to County" <> Customer.County) or
          ("Ship-to Post Code" <> Customer."Post Code") or
          ("Ship-to Phone No." <> Customer."Phone No.") or
          ("Ship-to Contact" <> Customer.Contact);

        OnAfterHasDifferentShipToAddress(Rec, Customer, Result);
    end;

    /// <summary>
    /// Opens the interaction log entries page where entries related to the sales document are displayed.
    /// </summary>
    procedure ShowInteractionLogEntries()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        OnBeforeShowInteractionLogEntries(InteractionLogEntry);
        if "Bill-to Contact No." <> '' then
            InteractionLogEntry.SetRange("Contact No.", "Bill-to Contact No.");
        case "Document Type" of
            "Document Type"::Order:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
            "Document Type"::Quote:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Qte.");
            "Document Type"::Invoice:
                InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Draft Invoice");
        end;

        InteractionLogEntry.SetRange("Document No.", "No.");
        PAGE.Run(PAGE::"Interaction Log Entries", InteractionLogEntry);
    end;

    /// <summary>
    /// Retrieves the bill-to (customer or contact) number for a sales document.
    /// </summary>
    /// <remarks>
    /// If sales document type is quote where the bill-to customer number is blank, but the bill-to contact number
    /// and bill-to customer template code are specified, it returns the bill-to contact number.
    /// For all other cases, it returns the bill-to customer number.
    /// </remarks>
    /// <returns>Bill-to number.</returns>
    procedure GetBillToNo(): Code[20]
    begin
        if ("Document Type" = "Document Type"::Quote) and
           ("Bill-to Customer No." = '') and ("Bill-to Contact No." <> '') and
           ("Bill-to Customer Templ. Code" <> '')
        then
            exit("Bill-to Contact No.");

        exit("Bill-to Customer No.");
    end;

    /// <summary>
    /// Gets the currency symbol for sales document. If currency symbol is not specified returns the currency code.
    /// </summary>
    /// <returns>Currency symbol.</returns>
    procedure GetCurrencySymbol(): Text[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        if GeneralLedgerSetup.Get() then
            if ("Currency Code" = '') or ("Currency Code" = GeneralLedgerSetup."LCY Code") then
                exit(GeneralLedgerSetup.GetCurrencySymbol());

        if Currency.Get("Currency Code") then
            exit(Currency.GetCurrencySymbol());

        exit("Currency Code");
    end;

#if not CLEAN26
    /// <summary>
    /// Updates the salesperson code from either the ship-to addresses or bill-to customer's salesperson.
    /// </summary>
    /// <remarks>
    /// If neither are set, it uses the default salesperson from the user setup.
    /// If salesperson is blocked, it doesn't get assigned.
    /// </remarks>
    [Obsolete('Use UpdateShipToSalespersonCode(FieldNo: Integer) instead.', '26.0')]
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
            ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code");
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
                    SetSalespersonCode(Customer."Salesperson Code", SalespersonCode);
                    Validate("Salesperson Code", SalespersonCode);
                    if Rec."Sell-to Customer No." <> '' then
                        GetCust(Rec."Sell-to Customer No.");
                end else
                    SetDefaultSalesperson();
        end;
    end;
#endif
    /// <summary>
    /// Updates the salesperson code from either the ship-to addresses or bill-to customer's salesperson.
    /// </summary>
    /// <remarks>
    /// If neither are set, it uses the default salesperson from the user setup.
    /// If salesperson is blocked, it doesn't get assigned.
    /// </remarks>
    procedure UpdateShipToSalespersonCode(FieldNo: Integer)
    var
        ShipToAddress: Record "Ship-to Address";
        SalespersonCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToSalespersonCode(Rec, IsHandled);
        if IsHandled then
            exit;

        SalespersonCode := "Salesperson Code";

        // three-step logic - Bill-to, Ship-to, Default
        if FieldNo = FieldNo("Bill-to Customer No.") then
            if ("Bill-to Customer No." <> '') then begin
                GetCust("Bill-to Customer No.");
                if Customer."Salesperson Code" = '' then
                    SalespersonCode := ''
                else
                    SetSalespersonCode(Customer."Salesperson Code", SalespersonCode);
            end;

        // two-step logic - Ship-to, Default
        if FieldNo in [FieldNo("Bill-to Customer No."), FieldNo("Ship-to Code")] then
            if "Ship-to Code" <> '' then begin
                ShipToAddress.SetLoadFields("Salesperson Code");
                ShipToAddress.Get("Sell-to Customer No.", "Ship-to Code");
                if ShipToAddress."Salesperson Code" <> '' then
                    SetSalespersonCode(ShipToAddress."Salesperson Code", SalespersonCode);
            end;

        // one-step logic - Default
        if SalespersonCode = '' then
            SetSalespersonCode('', SalespersonCode);

        if SalespersonCode <> "Salesperson Code" then
            Validate("Salesperson Code", SalespersonCode);
    end;

    /// <summary>
    /// Updates salesperson code. If the provided salesperson code privacy is not blocked, returns provided salesperson code,
    /// otherwise returns empty value to assign.
    /// </summary>
    /// <remarks>
    /// If the provided salesperson code is empty, it uses the default one from the user setup.
    /// </remarks>
    /// <param name="SalesPersonCodeToCheck">Salesperson code to set.</param>
    /// <param name="SalesPersonCodeToAssign">Return value: Salesperson code to assign.</param>
    procedure SetSalespersonCode(SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetSalespersonCode(Rec, SalesPersonCodeToCheck, SalesPersonCodeToAssign, IsHandled);
        if IsHandled then
            exit;

        if SalesPersonCodeToCheck = '' then
            SalesPersonCodeToCheck := GetUserSetupSalespersonCode();
        if Salesperson.Get(SalesPersonCodeToCheck) then begin
            if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                SalesPersonCodeToAssign := ''
            else
                SalesPersonCodeToAssign := SalesPersonCodeToCheck;
        end else
            SalesPersonCodeToAssign := '';
    end;

    /// <summary>
    /// Checks if the document can be created/posted depending on the privacy blocked of the salesperson.
    /// </summary>
    /// <param name="SalesHeader2">Sales header on which salesperson code has been changed.</param>
    /// <param name="IsTransaction">Determines if the check is completed during a write transaction.</param>
    /// <param name="IsPostAction">Determines if the check is completed during the posting.</param>
    procedure ValidateSalesPersonOnSalesHeader(SalesHeader2: Record "Sales Header"; IsTransaction: Boolean; IsPostAction: Boolean)
    begin
        if SalesHeader2."Salesperson Code" <> '' then
            if Salesperson.Get(SalesHeader2."Salesperson Code") then
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

    /// <summary>
    /// Determines whether a search for a customer should be performed by name for the provided customer number.
    /// </summary>
    /// <param name="CustomerNo">Customer number to check.</param>
    /// <returns>True if customer should be searched by name, otherwise false.</returns>
    procedure ShouldSearchForCustomerByName(CustomerNo: Code[20]) Result: Boolean
    var
        Customer2: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShouldSearchForCustomerByName(CustomerNo, Result, IsHandled, CurrFieldNo, Rec, xRec);
        if IsHandled then
            exit(Result);

        if CustomerNo = '' then
            exit(true);

        if not Customer2.Get(CustomerNo) then
            exit(true);

        GetSalesSetup();
        if SalesSetup."Disable Search by Name" then
            exit(false);

        exit(not Customer2."Disable Search by Name");
    end;

    local procedure CalcQuoteValidUntilDate()
    var
        BlankDateFormula: DateFormula;
    begin
        GetSalesSetup();
        if SalesSetup."Quote Validity Calculation" <> BlankDateFormula then
            "Quote Valid Until Date" := CalcDate(SalesSetup."Quote Validity Calculation", "Document Date");
    end;

    /// <summary>
    /// Returns the value of the global variable SkipTaxCalculation.
    /// </summary>
    /// <remarks>
    /// Currently SkipTaxCalculation in sales header is used only in variable set and get procedures.
    /// </remarks>
    /// <returns>The value of the global variable SkipTaxCalculation.</returns>
    procedure CanCalculateTax(): Boolean
    begin
        exit(SkipTaxCalculation);
    end;

    /// <summary>
    /// Sets the value of the global variable SkipTaxCalculation.
    /// </summary>
    /// <remarks>
    /// Currently SkipTaxCalculation in sales header is used only in variable set and get procedures.
    /// </remarks>
    /// <param name="Skip">The new value to set.</param>
    procedure SetSkipTaxCalulation(Skip: Boolean)
    begin
        SkipTaxCalculation := Skip;
    end;

    /// <summary>
    /// Checks if the sales line quantity shipped is zero. If it is not, an error is raised.
    /// </summary>
    /// <param name="SalesLine">Sales line which shipped quantity has to be checked.</param>
    procedure TestQuantityShippedField(SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestQuantityShippedField(SalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField("Quantity Shipped", 0);
        OnAfterTestQuantityShippedField(SalesLine);
    end;

    /// <summary>
    /// Determines if sales document status is not pending approval.
    /// </summary>
    /// <returns>True if status is not pending approval, otherwise false.</returns>
    procedure TestStatusIsNotPendingApproval() NotPending: Boolean;
    begin
        NotPending := Status <> Status::"Pending Approval";

        OnTestStatusIsNotPendingApproval(Rec, NotPending);
    end;

    /// <summary>
    /// Determines if sales document status is not pending prepayment.
    /// </summary>
    /// <returns>True if status is not pending prepayment, otherwise false.</returns>
    procedure TestStatusIsNotPendingPrepayment() NotPending: Boolean;
    begin
        NotPending := Status <> Status::"Pending Prepayment";

        OnTestStatusIsNotPendingPrepayment(Rec, NotPending);
    end;

    /// <summary>
    /// Determines if sales document status is not released.
    /// </summary>
    /// <returns>True if status is not released, otherwise false.</returns>
    procedure TestStatusIsNotReleased() NotReleased: Boolean;
    begin
        NotReleased := Status <> Status::Released;

        OnTestStatusIsNotReleased(Rec, NotReleased);
    end;

    /// <summary>
    /// Checks if sales document status is open. If it is not, an error is raised.
    /// </summary>
    /// <remakrs>
    /// If global flag StatusCheckSuspended is set to true, the procedure is not executed.
    /// </remakrs>
    procedure TestStatusOpen()
    begin
        OnBeforeTestStatusOpen(Rec, xRec, CurrFieldNo);

        if StatusCheckSuspended then
            exit;

        TestField(Status, Status::Open);

        OnAfterTestStatusOpen(Rec);
    end;

    /// <summary>
    /// Checks if sales document status is open. If it is not, an error is raised.
    /// </summary>
    /// <param name="ThrowErrorIfNot">Determines if an error should be raised if status is not open.</param>
    /// <returns>True if status is open, otherwise false.</returns>
    /// <remakrs>
    /// If global flag StatusCheckSuspended is set to true, the procedure is not executed.
    /// </remakrs>
    procedure TestStatusOpen(ThrowErrorIfNot: Boolean): Boolean
    begin
        OnBeforeTestStatusOpen(Rec, xRec, CurrFieldNo);

        if StatusCheckSuspended then
            exit(true);

        if Rec.Status <> Rec.Status::Open then begin
            if ThrowErrorIfNot then
                Error(DocumentNotOpenErr);
            exit(false)
        end;
        OnAfterTestStatusOpen(Rec);
        exit(true)
    end;

    /// <summary>
    /// Sets the value of the global flag StatusCheckSuspended.
    /// </summary>
    /// <remarks>
    /// The global flag is used to suspend the check if the document status is open.
    /// </remarks>
    /// <param name="Suspend">The new value to set.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    /// <summary>
    /// Checks if there are any blocked items or resources in the sales lines of the sales header.
    /// </summary>
    procedure CheckForBlockedLines()
    var
        CurrentSalesLine: Record "Sales Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Resource: Record Resource;
    begin
        CurrentSalesLine.SetCurrentKey("Document Type", "Document No.", Type);
        CurrentSalesLine.SetRange("Document Type", "Document Type");
        CurrentSalesLine.SetRange("Document No.", "No.");
        CurrentSalesLine.SetFilter(Type, '%1|%2', CurrentSalesLine.Type::Item, CurrentSalesLine.Type::Resource);
        CurrentSalesLine.SetFilter("No.", '<>''''');
        if "Document Type" = "Document Type"::"Blanket Order" then
            CurrentSalesLine.SetFilter("Qty. to Ship", '<>0');

        if CurrentSalesLine.FindSet() then
            repeat
                case CurrentSalesLine.Type of
                    CurrentSalesLine.Type::Item:
                        begin
                            Item.Get(CurrentSalesLine."No.");
                            Item.TestField(Blocked, false);

                            if CurrentSalesLine."Variant Code" <> '' then begin
                                ItemVariant.SetLoadFields(Blocked);
                                ItemVariant.Get(CurrentSalesLine."No.", CurrentSalesLine."Variant Code");
                                ItemVariant.TestField(Blocked, false);
                            end
                        end;
                    CurrentSalesLine.Type::Resource:
                        begin
                            Resource.Get(CurrentSalesLine."No.");
                            Resource.CheckResourcePrivacyBlocked(false);
                            Resource.TestField(Blocked, false);
                        end;
                end;
            until CurrentSalesLine.Next() = 0;
    end;

    /// <summary>
    /// Runs the copy sales document report for the sales header.
    /// </summary>
    /// <remarks>
    /// The report creates new sales documents based on the existing one.
    /// </remarks>
    procedure CopyDocument()
    var
        CopySalesDocument: Report "Copy Sales Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDocument(Rec, IsHandled);
        if IsHandled then
            exit;

        CopySalesDocument.SetSalesHeader(Rec);
        CopySalesDocument.RunModal();
    end;

    local procedure CheckContactRelatedToCustomerCompany(ContactNo: Code[20]; CustomerNo: Code[20]; CurrFieldNo: Integer);
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactRelatedToCustomerCompany(Rec, CurrFieldNo, IsHandled, ContactNo, CustomerNo);
        if IsHandled then
            exit;

        Contact.Get(ContactNo);
        if ContBusRel.FindByRelation(ContBusRel."Link to Table"::Customer, CustomerNo) then
            if (ContBusRel."Contact No." <> Contact."Company No.") and (ContBusRel."Contact No." <> Contact."No.") then
                Error(Text038, Contact."No.", Contact.Name, CustomerNo);
    end;

    local procedure ConfirmRecalculatePrice(var SalesLine: Record "Sales Line") Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRecalculatePrice(Rec, xRec, CurrFieldNo, Result, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        if GetHideValidationDialog() or not GuiAllowed then
            Result := true
        else
            Result :=
              ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(Text024, FieldCaption("Prices Including VAT"), SalesLine.FieldCaption("Unit Price")), true);
    end;

    /// <summary>
    /// Opens customer lookup page to select a customer.
    /// </summary>
    /// <param name="CustomerName">Return value: Selected customer name.</param>
    /// <returns>True if customer is selected, otherwise false.</returns>
    procedure LookupSellToCustomerName(var CustomerName: Text): Boolean
    var
        Customer: Record Customer;
        LookupStateManager: Codeunit "Lookup State Manager";
        RecVariant: Variant;
        SearchCustomerName: Text;
    begin
        SearchCustomerName := CustomerName;
        Customer.SetFilter("Date Filter", GetFilter("Date Filter"));
        if "Sell-to Customer No." <> '' then
            Customer.Get("Sell-to Customer No.");

        OnLookupSellToCustomerNameOnBeforeSelectCustomer(Rec, Customer, CustomerName);

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

    local procedure CheckPromisedDeliveryDate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPromisedDeliveryDate(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Promised Delivery Date" <> 0D then
            Error(Text028, FieldCaption("Requested Delivery Date"), FieldCaption("Promised Delivery Date"));
    end;

    procedure SetBillToCustomerNo(var Cust: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetBillToCustomerNo(Rec, Cust, IsHandled, xRec, CurrFieldNo);
        if IsHandled then
            exit;

        if Cust."Bill-to Customer No." <> '' then
            Validate("Bill-to Customer No.", Cust."Bill-to Customer No.")
        else begin
            if "Bill-to Customer No." = "Sell-to Customer No." then
                SkipBillToContact := true;
            Rec.Validate("Bill-to Customer No.", Rec."Sell-to Customer No.");
            SkipBillToContact := false;
        end;
    end;

    /// <summary>
    /// Returns the value of the global flag StatusCheckSuspended.
    /// </summary>
    /// <remarks>
    /// The global flag is used to suspend the check if the document status is open.
    /// </remarks>
    /// <returns>The value of the global flag StatusCheckSuspended.</returns>
    procedure GetStatusCheckSuspended(): Boolean
    begin
        exit(StatusCheckSuspended);
    end;

    /// <summary>
    /// Returns the value of the global flag CalledFromWhseDoc.
    /// </summary>
    /// <remarks>
    /// Global flag CalledFromWhseDoc is used on posting date validation to check if currency factor can be updated.
    /// </remarks>
    /// <returns>The value of the global flag CalledFromWhseDoc.</returns>
    procedure GetCalledFromWhseDoc(): Boolean
    begin
        exit(CalledFromWhseDoc);
    end;

    /// <summary>
    /// Sets the value of the global flag CalledFromWhseDoc.
    /// </summary>
    /// <remarks>
    /// Global flag CalledFromWhseDoc is set to true on init source header in warahoure shipment and receipt posting.
    /// </remarks>
    /// <param name="NewCalledFromWhseDoc">The new value to set.</param>
    procedure SetCalledFromWhseDoc(NewCalledFromWhseDoc: Boolean)
    begin
        CalledFromWhseDoc := NewCalledFromWhseDoc;
    end;

    local procedure CheckCustomerPostingGroupChange()
    var
        BillToCustomer: Record Customer;
        PostingGroupChangeInterface: Interface "Posting Group Change Method";
        IsHandled: Boolean;
    begin
        OnBeforeCheckCustomerPostingGroupChange(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ("Customer Posting Group" <> xRec."Customer Posting Group") and (xRec."Customer Posting Group" <> '') then begin
            TestField("Bill-to Customer No.");
            BillToCustomer.Get("Bill-to Customer No.");
            GetSalesSetup();
            if SalesSetup."Allow Multiple Posting Groups" then begin
                BillToCustomer.TestField("Allow Multiple Posting Groups");
                PostingGroupChangeInterface := SalesSetup."Check Multiple Posting Groups";
                PostingGroupChangeInterface.ChangePostingGroup("Customer Posting Group", xRec."Customer Posting Group", Rec);
            end;
        end;
    end;

    local procedure UpdatePrepmtAmounts(var SalesLine: Record "Sales Line")
    var
        Currency: Record Currency;
    begin
        Currency.Initialize("Currency Code");
        if "Document Type" = "Document Type"::Order then begin
            SalesLine."Prepmt. Line Amount" := Round(
                SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, Currency."Amount Rounding Precision");
            if Abs(SalesLine."Inv. Discount Amount" + SalesLine."Prepmt. Line Amount") > Abs(SalesLine."Line Amount") then
                SalesLine."Prepmt. Line Amount" := SalesLine."Line Amount" - SalesLine."Inv. Discount Amount";
        end;
    end;

    /// <summary>
    /// Returns the date to use for the sales document.
    /// </summary>
    /// <returns>Posting date if posting date is set in sales header, otherwise work date.</returns>
    procedure GetUseDate(): Date
    begin
        if "Posting Date" = 0D then
            exit(WorkDate());

        exit("Posting Date");
    end;

    /// <summary>
    /// Initializes the number series for sales document posting based on the document type.
    /// </summary>
    procedure InitPostingNoSeries()
    var
        NoSeries: Codeunit "No. Series";
        PostingNoSeries: Code[20];
    begin
        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if "Journal Templ. Name" = '' then begin
                if not IsCreditDocType() then
                    GenJournalTemplate.Get(SalesSetup."S. Invoice Template Name")
                else
                    GenJournalTemplate.Get(SalesSetup."S. Cr. Memo Template Name");
                "Journal Templ. Name" := GenJournalTemplate.Name;
            end else
                GenJournalTemplate.Get("Journal Templ. Name");
            PostingNoSeries := GenJournalTemplate."Posting No. Series";
        end else
            if IsCreditDocType() then
                PostingNoSeries := SalesSetup."Posted Credit Memo Nos."
            else
                PostingNoSeries := SalesSetup."Posted Invoice Nos.";

        case "Document Type" of
            "Document Type"::Quote, "Document Type"::Order:
                begin
                    if NoSeries.IsAutomatic(PostingNoSeries) then
                        "Posting No. Series" := PostingNoSeries;
                    if NoSeries.IsAutomatic(SalesSetup."Posted Shipment Nos.") then
                        "Shipping No. Series" := SalesSetup."Posted Shipment Nos.";
                    if NoSeries.IsAutomatic(SalesSetup."Posted Prepmt. Inv. Nos.") then
                        "Prepayment No. Series" := SalesSetup."Posted Prepmt. Inv. Nos.";
                    if NoSeries.IsAutomatic(SalesSetup."Posted Prepmt. Cr. Memo Nos.") then
                        "Prepmt. Cr. Memo No. Series" := SalesSetup."Posted Prepmt. Cr. Memo Nos.";
                end;
            "Document Type"::Invoice:
                begin
                    if ("No. Series" <> '') and (SalesSetup."Invoice Nos." = PostingNoSeries) then
                        "Posting No. Series" := "No. Series"
                    else
                        if NoSeries.IsAutomatic(PostingNoSeries) then
                            "Posting No. Series" := PostingNoSeries;

                    if SalesSetup."Shipment on Invoice" then
                        if NoSeries.IsAutomatic(SalesSetup."Posted Shipment Nos.") then
                            "Shipping No. Series" := SalesSetup."Posted Shipment Nos.";
                end;
            "Document Type"::"Return Order":
                begin
                    if NoSeries.IsAutomatic(PostingNoSeries) then
                        "Posting No. Series" := PostingNoSeries;
                    if NoSeries.IsAutomatic(SalesSetup."Posted Return Receipt Nos.") then
                        "Return Receipt No. Series" := SalesSetup."Posted Return Receipt Nos.";
                end;
            "Document Type"::"Credit Memo":
                begin
                    if ("No. Series" <> '') and (SalesSetup."Credit Memo Nos." = PostingNoSeries) then
                        "Posting No. Series" := "No. Series"
                    else
                        if NoSeries.IsAutomatic(PostingNoSeries) then
                            "Posting No. Series" := PostingNoSeries;
                    if SalesSetup."Return Receipt on Credit Memo" then
                        if NoSeries.IsAutomatic(SalesSetup."Posted Return Receipt Nos.") then
                            "Return Receipt No. Series" := SalesSetup."Posted Return Receipt Nos."
                end;
        end;

        OnAfterInitPostingNoSeries(Rec, xRec);
    end;

    /// <summary>
    /// Initializes the dimensions for the document from default dimensions for the related entry specified in the field.
    /// </summary>
    /// <param name="FieldNo">The field number for which to initialize the dimensions.</param>
    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDimFromDefaultDim(Rec, FieldNo, IsHandled);
        if IsHandled then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        OnBeforeInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);

        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Bill-to Customer No.", FieldNo = Rec.FieldNo("Bill-to Customer No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", Rec."Salesperson Code", FieldNo = Rec.FieldNo("Salesperson Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Campaign, Rec."Campaign No.", FieldNo = Rec.FieldNo("Campaign No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Responsibility Center", Rec."Responsibility Center", FieldNo = Rec.FieldNo("Responsibility Center"));
        DimMgt.AddDimSource(DefaultDimSource, Database::"Customer Templ.", Rec."Bill-to Customer Templ. Code", FieldNo = Rec.FieldNo("Bill-to Customer Templ. Code"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, FieldNo);
    end;

    /// <summary>
    /// Opens a contact lookup page and validates the sell-to contact number with the selected contact.
    /// </summary>
    /// <returns>True if the contact was validated, otherwise false.</returns>
    procedure SelltoContactLookup(): Boolean
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupSellToContactNo(Rec, xRec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Contact.FilterGroup(2);
        if "Sell-to Customer No." <> '' then
            if Contact.Get("Sell-to Contact No.") then
                Contact.SetRange("Company No.", Contact."Company No.")
            else
                if ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, "Sell-to Customer No.") then
                    Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.")
                else
                    Contact.SetRange("No.", '');

        if "Sell-to Contact No." <> '' then
            if Contact.Get("Sell-to Contact No.") then;
        if Page.RunModal(0, Contact) = Action::LookupOK then begin
            xRec := Rec;
            CurrFieldNo := FieldNo("Sell-to Contact No.");
            Validate("Sell-to Contact No.", Contact."No.");
            exit(true);
        end;
        Contact.FilterGroup(0);
        exit(false);
    end;

    local procedure ShouldCheckShowRecurringSalesLines(var xHeader: Record "Sales Header"; var Header: Record "Sales Header"): Boolean
    begin
        exit(
            (xHeader."Bill-to Customer No." <> '') and
            (Header."No." <> '') and
            (Header."Currency Code" <> xHeader."Currency Code")
        );
    end;

    /// <summary>
    /// Inserts the default notification to warn before posting lines on sales documents where quantity is 0.
    /// </summary>
    /// <remarks>
    /// Notification is enabled by default.
    /// </remarks>
    procedure SetWarnZeroQuantitySalesPosting()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetWarnWhenZeroQuantitySalesLinePosting(),
         WarnZeroQuantitySalesPostingTxt, WarnZeroQuantitySalesPostingDescriptionTxt, true);
    end;

    /// <summary>
    /// Determines if the sales lines are editable based on whether sell-to information is in the sales header.
    /// </summary>
    /// <returns>True if sales lines are editable, otherwise false.</returns>
    procedure SalesLinesEditable() IsEditable: Boolean;
    begin
        if "Document Type" = "Document Type"::Quote then
            IsEditable := (Rec."Sell-to Customer No." <> '') or (Rec."Sell-to Customer Templ. Code" <> '') or (Rec."Sell-to Contact No." <> '') or (Rec.GetFilter("Sell-to Contact No.") <> '')
        else
            IsEditable := Rec."Sell-to Customer No." <> '';

        OnAfterSalesLinesEditable(Rec, IsEditable);
    end;


    local procedure FindDocumentWithSameExternalDocNo(): Boolean
    var
        CustomerMgt: Codeunit "Customer Mgt.";
    begin
        exit(CustomerMgt.SearchForExternalDocNo(Rec));
    end;

    local procedure ShowExternalDocAlreadyExistNotification()
    var
        MyNotifications: Record "My Notifications";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        InstructionMgt: Codeunit "Instruction Mgt.";
        DocAlreadyExistNotification: Notification;
    begin
        if not MyNotifications.IsEnabled(GetShowExternalDocAlreadyExistNotificationId()) then
            exit;
        InstructionMgt.CreateMissingMyNotificationsWithDefaultState(GetShowExternalDocAlreadyExistNotificationId());

        if not IsDocAlreadyExistNotificationEnabled() then
            exit;

        DocAlreadyExistNotification.Id := GetShowExternalDocAlreadyExistNotificationId();
        DocAlreadyExistNotification.Message :=
          StrSubstNo(SalesAlreadyExistsTxt, "Document Type", "External Document No.");
        DocAlreadyExistNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        DocAlreadyExistNotification.SetData(FieldName("Document Type"), Format("Document Type"));
        DocAlreadyExistNotification.SetData(FieldName("No."), "No.");
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          DocAlreadyExistNotification, RecordId, GetShowExternalDocAlreadyExistNotificationId());
    end;

    procedure GetShowExternalDocAlreadyExistNotificationId(): Guid
    begin
        exit('0677e7f8-cc39-442e-b9c2-65aadaa85ae9');
    end;

    local procedure RecallExternalDocAlreadyExistsNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        if not IsDocAlreadyExistNotificationEnabled() then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          RecordId, GetShowExternalDocAlreadyExistNotificationId(), true);
    end;

    local procedure IsDocAlreadyExistNotificationEnabled(): Boolean
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        exit(InstructionMgt.IsMyNotificationEnabled(GetShowExternalDocAlreadyExistNotificationId()));
    end;

    procedure UpdateSalesOrderLineIfExist()
    var
        SalesCreditMemoHeader: Record "Sales Cr.Memo Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        IsHandled: Boolean;
    begin
        SalesCreditMemoHeader.SetLoadFields("Pre-Assigned No.", "Cust. Ledger Entry No.");
        SalesCreditMemoHeader.SetRange("Pre-Assigned No.", Rec."No.");
        if not SalesCreditMemoHeader.FindFirst() then
            exit;

        IsHandled := false;
        OnBeforeUpdateSalesOrderLineIfExist(Rec, IsHandled);
        if IsHandled then
            exit;

        CorrectPostedSalesInvoice.UpdateSalesOrderLineIfExist(SalesCreditMemoHeader."No.");
    end;

    internal procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        QtyReservedFromStock: Decimal;
    begin
        QtyReservedFromStock := SalesLineReserve.GetReservedQtyFromInventory(Rec);
        if QtyReservedFromStock = 0 then
            exit(Result::None);

        if QtyReservedFromStock = CalculateReservableOutstandingQuantityBase() then
            exit(Result::Full);

        exit(Result::Partial);
    end;

    internal procedure CalculateReservableOutstandingQuantityBase() OutstandingQtyBase: Decimal
    var
        RemQtyBaseInvtItemSalesLine: Query RemQtyBaseInvtItemSalesLine;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateReservableOutstandingQuantityBase(Rec, IsHandled, OutstandingQtyBase);
        if IsHandled then
            exit(OutstandingQtyBase);

        OutstandingQtyBase := 0;
        RemQtyBaseInvtItemSalesLine.SetSalesLineFilter(Rec);
        if RemQtyBaseInvtItemSalesLine.Open() then
            if RemQtyBaseInvtItemSalesLine.Read() then
                OutstandingQtyBase := RemQtyBaseInvtItemSalesLine.Outstanding_Qty___Base_;
        RemQtyBaseInvtItemSalesLine.Close();
    end;

    local procedure UpdateVATReportingDate(CalledByFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVATReportingDate(Rec, CalledByFieldNo, IsHandled);
        if IsHandled then
            exit;

        if not (CalledByFieldNo in [FieldNo("Posting Date"), FieldNo("Document Date")]) then
            exit;

        GLSetup.GetRecordOnce();
        case CalledByFieldNo of
            FieldNo("Posting Date"):
                GLSetup.UpdateVATDate("Posting Date", Enum::"VAT Reporting Date"::"Posting Date", "VAT Reporting Date");
            FieldNo("Document Date"):
                GLSetup.UpdateVATDate("Document Date", Enum::"VAT Reporting Date"::"Document Date", "VAT Reporting Date");
        end;
        Validate("VAT Reporting Date");
    end;

    local procedure FindContactBusinessRelation(CustomerNo: Code[20]; ContactNo: Code[20]; ContactBusinessRelationLinkType: Enum "Contact Business Relation Link To Table"): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange(ContactBusinessRelation."Link to Table", ContactBusinessRelationLinkType);
        exit(ContactBusinessRelation.IsEmpty());
    end;

    local procedure UpdateDocumentDateFromLinkedPostingDate(WithValidate: Boolean)
    var
        IsHandled: Boolean;
    begin
        OnValidatePostingDateOnBeforeAssignDocumentDate(Rec, IsHandled);
        if IsHandled then
            exit;
        if Rec."Incoming Document Entry No." <> 0 then
            exit;
        GetSalesSetup();
        if SalesSetup."Link Doc. Date To Posting Date" then
            if WithValidate then
                Rec.Validate("Document Date", Rec."Posting Date")
            else
                Rec."Document Date" := Rec."Posting Date";
    end;

    procedure SendICSalesDoc(var SalesHeader: Record "Sales Header")
    var
        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if SalesHeader.FindSet() then
            repeat
                if ApprovalsMgmt.PrePostApprovalCheckSales(SalesHeader) then
                    ICInOutboxMgt.SendSalesDoc(SalesHeader, false);
            until SalesHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignDefaultVATBusPostingGroup(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; GenBusinessPostingGroup: Record "Gen. Business Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var SalesHeader: Record "Sales Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitRecord(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeRoundingPrecision(var SalesHeader: Record "Sales Header"; var Currency: Record Currency)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsBillToAddressEqualToSellToAddress(SellToSalesHeader: Record "Sales Header"; BillToSalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditLimitCondition(var SalesHeader: Record "Sales Header"; var RunCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCreditMaxBeforeInsert(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBillToCust(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSellToCust(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Customer: Record Customer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckShippingAdvice(var SalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmSalesPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var RecalculateLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmCurrencyFactorUpdate(var SalesHeader: Record "Sales Header"; var Confirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCouldDimensionsBeKept(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteAllTempSalesLines(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDeleteSalesLines(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromSalesHeader(var SalesHeader: Record "Sales Header"; SourceSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromBillToCustTemplate(var SalesHeader: Record "Sales Header"; BillToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempSalesLine(SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPosting(SalesHeader: Record "Sales Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsApprovedForPostingBatch(SalesHeader: Record "Sales Header"; var Approved: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesReceivablesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingNoSeriesCode(SalesHeader: Record "Sales Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPrepaymentPostingNoSeriesCode(SalesHeader: Record "Sales Header"; var PostingNos: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesSetup(SalesHeader: Record "Sales Header"; var SalesReceivablesSetup: Record "Sales & Receivables Setup"; CalledByFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocTypeText(var SalesHeader: Record "Sales Header"; var TypeText: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetStatusStyleText(SalesHeader: Record "Sales Header"; var StatusStyleText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasDifferentSellToAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasDifferentBillToAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasDifferentShipToAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLinesEditable(SalesHeader: Record "Sales Header"; var IsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestNoSeries(var SalesHeader: Record "Sales Header"; var SalesReceivablesSetup: Record "Sales & Receivables Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddress(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var SalesHeader: Record "Sales Header"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineByChangedFieldName(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldName: Text[100]; ChangedFieldNo: Integer; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLinesByFieldNoOnAfterSalesLineSetFilters(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineAmountsOnAfterSalesHeaderModify(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateShipToContactOnBeforeValidateShipToContact(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOpportunityOnBeforeModify(var Opportunity: Record Opportunity; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOpportunityLinkOnBeforeModify(var Opportunity: Record Opportunity; var SalesHeader: Record "Sales Header"; SalesDocumentType: Option; SalesHeaderNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShortcutDimCodeOnBeforeUpdateAllLineDim(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShipToAddressEqualToSellToAddress(SellToSalesHeader: Record "Sales Header"; ShipToSalesHeader: Record "Sales Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteAccepted(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterChangePricesIncludingVAT(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSelltoCustomerNoOnAfterValidate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendSalesHeader(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; xSalesHeader: Record "Sales Header"; SkipBillToContact: Boolean; CUrrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferExtendedTextForSalesLineRecreation(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromNewSellToCustTemplate(var SalesHeader: Record "Sales Header"; SellToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToShipToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToAddressToBillToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopySellToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; CurrentFieldNo: Integer; var SkipBillToContact: Boolean; var SkipSellToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr(var SalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLinesByFieldNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var SalesHeader: Record "Sales Header"; OldSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailableCreditLimit(var SalesHeader: Record "Sales Header"; var ReturnValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimit(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditMaxBeforeInsert(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; HideCreditCheckDialogue: Boolean; FilterCustNo: Code[20]; FilterContNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCreditLimitIfLineNotInsertedYet(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerContactRelation(var SalesHeader: Record "Sales Header"; Cont: Record Contact; var IsHandled: Boolean; CustomerNo: Code[20]; ContBusinessRelationNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoAndShowConfirm(SalesHeader: Record "Sales Header"; var SalesShptHeader: Record "Sales Shipment Header"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnRcptHeader: Record "Return Receipt Header"; var SalesInvHeaderPrePmt: Record "Sales Invoice Header"; var SalesCrMemoHeaderPrePmt: Record "Sales Cr.Memo Header"; SourceCode: Record "Source Code"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPrepmtInfo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReturnInfo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; BillTo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShipmentInfo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; BillTo: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckShippingAdvice(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimensionsFromValidateBillToCustomerNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimensionsFromValidateSalesPersonCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCofirmClearOpportunityNo(Opportunity: Record Opportunity; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmKeepExistingDimensions(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNo: Integer; OldDimSetID: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateAllLineDim(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmBillToContactNoChange(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmSellToContactNoChange(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var HideValidationDialog: Boolean; var xSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var ForceConfirm: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetContactAsCompany(Contact: Record Contact; var SearchContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDeletion(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySellToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySellToAddressToBillToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr(var SalesHeader: Record "Sales Header"; var ShipToAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromSellToCustomerTemplate(var SalesHeader: Record "Sales Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromBillToCustomerTemplate(var SalesHeader: Record "Sales Header"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreateSalesLine(var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean; var SalesHeader: record "Sales Header"; var SalesLine: record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInvtPutAwayPick(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteSalesLines(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteRecordInApprovalRequest(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureDocumentTypeIsQuote(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCust(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; CustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumber(var SalesHeader: Record "Sales Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerVATRegistrationNumberLbl(var SalesHeader: Record "Sales Header"; var ReturnValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPstdDocLinesToReverse(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingNoSeriesCode(var SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup"; var NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShippingTime(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var CalledByFieldNo: Integer; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShipmentMethodCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromSalesHeader(var SalesHeader: Record "Sales Header"; SourceSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitInsert(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPostingDescription(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsCreditDocType(SalesHeader: Record "Sales Header"; var CreditDocType: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsApprovedForPosting(var SalesHeader: Record "Sales Header"; var Approved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsApprovedForPostingBatch(var SalesHeader: Record "Sales Header"; var Approved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupAppliesToDocNo(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBillToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBillToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupContact(CustomerNo: Code[20]; ContactNo: Code[20]; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSelltoContact(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToContactNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSellToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShipToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShipToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupBillToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupBillToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupSellToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupSellToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupShippingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupReturnReceiptNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenSalesOrderStatistics(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyToShipIsZero(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocDim(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowInteractionLogEntries(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldSearchForCustomerByName(CustomerNo: Code[20]; var Result: Boolean; var IsHandled: Boolean; var CallingFieldNo: Integer; var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferItemChargeAssgntSalesToTemp(var SalesHeader: Record "Sales Header"; var ItemChargeAssgntSales: Record "Item Charge Assignment (Sales)"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var Updated: Boolean; var CurrencyExchangeRate: Record "Currency Exchange Rate"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCont(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; var SkipBillToContact: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToEmail(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDocumentDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePromisedDeliveryDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLocationCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePaymentTermsCode(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CallingFieldNo: Integer; UpdateDocumentDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateReturnReceiptNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean; var DoExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCity(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var SalesHeader: Record "Sales Header"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATRegistrationNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRequestedDeliveryDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMessageIfSalesLinesExist(var SalesHeader: Record "Sales Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePriceMessageIfSalesLinesExist(SalesHeader: Record "Sales Header"; ChangedFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimSetForPrepmtAccDefaultDim(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLinesHandler(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecreateSalesLinesHandleSupplementTypes(var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineByChangedFieldNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustomerLocationCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultPaymentServices(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesperson(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; InsertMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStoreSalesCommentLineToTemp(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSecurityFilterOnRespCenter(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeShowPostedDocsToPrintCreatedMsg(var ShowPostedDocsToPrint: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSynchronizeForReservations(var SalesHeader: Record "Sales Header"; var NewSalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCustContact(var SalesHeader: Record "Sales Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDirectDebitPmtTermsCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var PaymentMethod: Record "Payment Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCust(var SalesHeader: Record "Sales Header"; var Contact: Record Contact; var Customer: Record Customer; ContactNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAllLineDim(var SalesHeader: Record "Sales Header"; NewParentDimSetID: Integer; OldParentDimSetID: Integer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLocationCode(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOutboundWhseHandlingTime(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLineAmounts(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLinesByFieldNo(var SalesHeader: Record "Sales Header"; ChangedFieldNo: Integer; var AskQuestion: Boolean; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLines(var SalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; var AskQuestion: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSellToCustContact(var SalesHeader: Record "Sales Header"; Conact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddress(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToCodeFromCust(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostingDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemAvailabilityInLinesOnAfterSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnAfterSetTempSalesLineFilters(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySelltoCustomerAddressFieldsFromCustomerOnAfterAssignRespCenter(var SalesHeader: Record "Sales Header"; Customer: Record Customer; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCopySellToCustomerAddressFieldsFromCustomerOnAfterAssignSellToCustomerAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeUpdateLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnBeforeModify(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNo: Integer; OldDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnKeepDimensionsOnAfterUpdateGlobalDim(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNo: Integer; OldDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnAfterAssignType(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeValidateQuantity(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var ShouldValidateQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeTransferFieldsFromTempSalesLine(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteSalesLinesOnBeforeDeleteLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterPostSalesDeleteDeleteHeader(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeArchiveSalesDocument(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromContactOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnAfterInitNoSeries(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromTemplateOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitInsertOnBeforeInitRecord(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignShipmentDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignOrderDate(var SalesHeader: Record "Sales Header"; var NewOrderDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempSalesLineInBufferOnBeforeTempSalesLineInsert(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterSalesQuote(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBilltoCustomerTemplCodeOnBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoAfterInit(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnAfterCalcShouldSkipConfirmSellToCustomerDialog(var SalesHeader: Record "Sales Header"; var ShouldSkipConfirmSellToCustomerDialog: Boolean; var ConfirmedShouldBeFalse: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSelltoContactNoOnAfterCalcShouldUpdateOpportunity(var SalesHeader: Record "Sales Header"; var ShouldUpdateOpportunity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestQuantityShippedField(SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesLineFieldsBeforeRecreate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestQuantityShippedField(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenDocumentStatistics(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareOpeningDocumentStatistics(var SalesHeader: Record "Sales Header")
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetStatisticsPageID(var PageID: Integer; SalesHeader: Record "Sales Header")
    begin
    end;
#endif
    [IntegrationEvent(true, false)]
    local procedure OnBeforeTestStatusOpen(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterTestStatusOpen(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCont(var SalesHeader: Record "Sales Header"; Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBillToCust(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCont(var SalesHeader: Record "Sales Header"; Customer: Record Customer; Contact: Record Contact; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSellToCust(var SalesHeader: Record "Sales Header"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLines(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCompanyBankAccount(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAppliesToDocNo(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToCustomerName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSellToCustomerName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLinkSalesDocWithOpportunityOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header"; OldOpportunityNo: Code[20]; Opportunity: Record Opportunity)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeConfirm(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100]; HideValidationDialog: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeSalesLineDeleteAll(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnAfterProcessTempSalesLines(var TempSalesLine: Record "Sales Line" temporary; var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateReservEntryReqLineOnAfterLoop(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateReservEntryReqLineOnAfterCalcShouldValidateLocationCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ShouldValidateLocationCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesHandleSupplementTypesOnAfterCalcShouldCreateSalsesLine(var TempSalesLine: Record "Sales Line"; var ShouldCreateSalsesLine: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnSetBillToCustomerAddressFieldsFromCustomerOnAfterAssignBillToCustomerAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetShipToCustomerAddressFieldsFromShipToAddrOnAfterCalcShouldCopyLocationCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ShipToAddress: Record "Ship-to Address"; var ShouldCopyLocationCode: Boolean; var ShouldCopySalespersonCode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingApproval(SalesHeader: Record "Sales Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotPendingPrepayment(SalesHeader: Record "Sales Header"; var NotPending: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestStatusIsNotReleased(SalesHeader: Record "Sales Header"; var NotReleased: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLinesByFieldNoOnBeforeSalesLineModify(var SalesLine: Record "Sales Line"; ChangedFieldNo: Integer; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLinesByFieldNoOnAfterCalcShouldConfirmReservationDateConflict(var SalesHeader: Record "Sales Header"; ChangedFieldNo: Integer; var ShouldConfirmReservationDateConflict: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnBeforeFindContactBusinessRelation(Contact: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetFromSearchContact(var SalesHeader: Record "Sales Header"; var SearchContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetShipToAddress(var SalesHeader: Record "Sales Header"; var SearchContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterSetSellToContactNo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCostomerErr(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeFindContactBusinessRelation(Cont: Record Contact; var ContBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterConfirmed(var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcDueDate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalcPmtDiscDate(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeValidateDueDateWhenBlank(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeAssignDocumentDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeResetInvoiceDiscountValue(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnBeforeCheckNeedUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; var IsConfirmed: Boolean; var NeedUpdateCurrencyFactor: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnBeforeSalesLineModify(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Currency: Record Currency; RecalculatePrice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShippingAgentCodeOnBeforeUpdateLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFullDocTypeTxt(var SalesHeader: Record "Sales Header"; var FullDocTypeTxt: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnBeforeInsertTempSalesLineInBuffer(var GenPostingSetup: Record "General Posting Setup"; var DefaultDimension: Record "Default Dimension")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDocument(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBillToCust(var SalesHeader: Record "Sales Header"; ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeTempSalesLineFindSet(var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactRelatedToCustomerCompany(SalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean; ContactNo: Code[20]; CustomerNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowModifyAddressNotification(var IsHandled: Boolean; SalesHeader: Record "Sales Header"; CustomerNumber: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeUpdateSalesLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRecalculatePrice(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var Result: Boolean; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnBeforeGetSalesLineNewDimSetID(var SalesLine: Record "Sales Line"; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterGetSalesLineNewDimsetID(SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var NewDimSetID: Integer; NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRename(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupBillToContactNo(var IsHandled: Boolean; var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateOpportunity(var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPromisedDeliveryDate(var IsHandled: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToAddressFromSellToAddress(var SalesHeader: Record "Sales Header"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToSalespersonCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSalespersonCode(var SalesHeader: Record "Sales Header"; SalesPersonCodeToCheck: Code[20]; var SalesPersonCodeToAssign: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    [IntegrationEvent(false, false)]
    [Obsolete('This event is obsolete. Use OnBeforeUpdateShipToSalespersonCode instead.', '26.0')]
    local procedure OnUpdateShiptoSalespersonCodeNotAssigned(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateShipToAddressFromSellToAddress(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCode(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; Cust: Record Customer; ShipToAddr: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeCheckBlockedCustOnDocs(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeCheckBlockedCustOnDocs(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerAddressFieldsFromCustomer(var SalesHeader: Record "Sales Header"; var BillToCustomer: Record Customer; var SkipBillToContact: Boolean; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; var GLSetup: Record "General Ledger Setup"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeRecallModifyAddressNotification(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBillToName(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeValidateTaxLiable(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateShipToCodeOnBeforeCopyShipToAddress(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var CopyShipToAddress: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentMethodCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignWorkDateToPostingDate(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetBillToCustomerNo(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; var CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShippingAgentServiceCode(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtPaymentTermsCode(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; CallingFieldNo: Integer; UpdateDocumentDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLines(var SalesHeader: Record "Sales Header"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSellToCustomerFromFilter(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvDiscForHeader(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCouldDimensionsBeKept(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmBillToCustomerChange(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeRecallModifyAddressNotification(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCreditMaxBeforeInsertOnCaseIfOnBeforeSalesHeaderCheckCase(var SalesHeader: Record "Sales Header"; Rec: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustomerCreatedOnAfterConfirmProcess(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepmtPaymentTermsCodeOnCaseElseOnBeforeValidatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePrepmtPaymentTermsCodeOnCaseIfOnBeforeValidatePrepaymentDueDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecreateSalesLinesHandleSupplementTypes(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPostingNoSeries(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromBillToCustTemplate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var BillToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromNewSellToCustTemplate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var SellToCustTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyCustomerAddress(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShouldCopyAddressFromBillToCustomer(BillToCustomer: Record Customer; Rec: Record "Sales Header"; xRec: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBillToCustomerIsReplaced(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnAfterFindSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySelltoCustomerAddressFieldsFromCustomerOnBeforeAssignRespCenter(var SalesHeader: Record "Sales Header"; var SellToCustomer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExternalDocumentNo(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePostingDateOnAfterCheckNeedUpdateCurrencyFactor(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var NeedUpdateCurrencyFactor: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeGetCust(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeAssignResponsibilityCenter(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeValidateLocationCode(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; var LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSendICDocumentOnBeforeCheckICDirection(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPstdDocLinesToReverse(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyShipToCustomerAddressFieldsFromCustOnBeforeValidateShippingAgentFields(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetShipToCustomerAddressFieldsFromShipToAddrOnBeforeValidateShippingAgentFields(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ShipToAddr: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitRecordOnBeforeGetNextArchiveDocOccurrenceNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesOnBeforeCopyReservEntryFromTemp(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; ChangedFieldName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerPostingGroupChange(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePaymentTermsCodeOnAfterValidatePaymentDiscountWhenBlank(var SalesHeader: Record "Sales Header"; var xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineAmountsOnAfterSalesLineSetFilters(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupAdjmtValueEntriesCaseDocumentTypeElse(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; QtyType: Option General,Invoicing);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLinesExist(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATBaseDiscountPct(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePricesIncludingVATOnBeforeSalesLineFindFirst(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePaymentMethodCode(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var InsertMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeUpdateSellToCont(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; var SkipSellToContact: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeferralHeadersExistOnAfterSetFilters(var SalesHeader: Record "Sales Header"; var DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySellToCustomerAddressFieldsFromCustomerOnBeforeUpdateLocation(var SalesHeader: Record "Sales Header"; var SellToCustomer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATReportingDateOnBeforeInitVATDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDocDimOnBeforeSalesHeaderModify(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimSetForPrepmtAccDefaultDimOnBeforeTempSalesLineCreateDim(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitDefaultDimensionSources(var SalesHeader: Record "Sales Header"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnValidateSelltoContactNoOnBeforeValidateSalespersonCode(var SalesHeader: Record "Sales Header"; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvtPutAwayPickOnBeforeTestingStatus(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToPostingOnAfterPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailabilityInLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToCustomerNoOnAfterTestStatusOpen(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBillToCustomerNoOnAfterCheckBilltoCustomerNoChanged(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean; var IsHandledDoExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSellToContactNoOnAfterContCheckIfPrivacyBlockedGeneric(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecreateSalesLinesHandleSupplementTypesOnAfterCreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmCloseUnpostedOnSalesLinesExist(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetInvoiceDiscountValue(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeAssignType(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeValidateShipmentDate(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnBeforeSetDropShipment(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesLineOnAfterValidateNo(var SalesLine: Record "Sales Line"; TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustomerCreatedOnBeforeConfirmProcess(SalesHeader: Record "Sales Header"; var Prompt: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmUpdateDeferralDate(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCompanyBankAccount(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnAfterFindContactBusinessRelation(SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBillToCustOnAfterFindContactBusinessRelation(SalesHeader: Record "Sales Header"; Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; var ContactBusinessRelationFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCopyShipToCustomerAddressFieldsFromCustOnAfterAssignAddressFromSellToCustomer(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasSellToAddress(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasShipToAddress(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHasBillToAddress(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetShipToAddress(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipmentDate(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePaymentDiscount(var SalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesOrderLineIfExist(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLinkSalesDocWithOpportunity(var SalesHeader: Record "Sales Header"; OldOpportunityNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVATReportingDate(var SalesHeader: Record "Sales Header"; CalledByFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendToPosting(var SalesHeader: Record "Sales Header"; var IsSuccess: Boolean; var IsHandled: Boolean; PostingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSellToCustOnBeforeValidateBillToContactNo(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePerformManualRelease(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Removed Not used anymore.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNotFullyCancelled(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckCreditLimitOnAfterCreditLimitCheck(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDimFromDefaultDim(var Rec: Record "Sales Header"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerDiscGroup(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetWorkDescription(var SalesHeader: Record "Sales Header"; var NewWorkDescription: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPrepmtCrMemoNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtCrMemoNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;


#if not CLEAN27
    [Obsolete('Not used anymore due to new implementation that uses Query. Replaced by OnBeforeCalculateReservableOutstandingQuantityBase.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalcOutstandingQuantityBaseOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateReservableOutstandingQuantityBase(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var OutstandingQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyBillToCustomerAddress(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAppliesToDocNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPrepmtNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtNoSeries(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySellToCustomerFilterOnAfterGetSellToCustomerFilter(var SalesHeader: Record "Sales Header"; var SellToCustomerFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSellToCustomerFromFilter(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupSellToCustomerNameOnBeforeSelectCustomer(SalesHeader: Record "Sales Header"; var Customer: Record Customer; var CustomerName: Text)
    begin
    end;
}
