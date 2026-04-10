// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

table 5507 "Sales Cr. Memo Entity Buffer"
{
    Caption = 'Sales Cr. Memo Entity Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Customer;

            trigger OnValidate()
            begin
                UpdateSellToCustomerId();
            end;
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Customer;
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            DataClassification = CustomerContent;
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            DataClassification = CustomerContent;
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            DataClassification = CustomerContent;
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            DataClassification = CustomerContent;
            TableRelation = if ("Bill-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Bill-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Bill-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(10; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
            DataClassification = CustomerContent;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Terms";

            trigger OnValidate()
            begin
                UpdatePaymentTermsId();
            end;
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = CustomerContent;
        }
        field(27; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipment Method";

            trigger OnValidate()
            begin
                UpdateShipmentMethodId();
            end;
        }
        field(29; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(31; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Customer Posting Group";
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;

            trigger OnValidate()
            begin
                UpdateCurrencyId();
            end;
        }
        field(35; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            DataClassification = CustomerContent;
        }
        field(43; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = CustomerContent;
            TableRelation = "Salesperson/Purchaser";
        }
        field(52; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            DataClassification = CustomerContent;
        }
        field(53; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            DataClassification = CustomerContent;
        }
        field(56; "Recalculate Invoice Disc."; Boolean)
        {
            CalcFormula = exist("Sales Line" where("Document Type" = const(Invoice),
                                                    "Document No." = field("No."),
                                                    "Recalculate Invoice Disc." = const(true)));
            Caption = 'Recalculate Invoice Disc.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount Including VAT';
            DataClassification = CustomerContent;
        }
        field(73; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";

            trigger OnValidate()
            begin
                UpdateReasonCodeId();
            end;
        }
        field(79; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            DataClassification = CustomerContent;
            TableRelation = Customer.Name;
            ValidateTableRelation = false;
        }
        field(81; "Sell-to Address"; Text[100])
        {
            Caption = 'Sell-to Address';
            DataClassification = CustomerContent;
        }
        field(82; "Sell-to Address 2"; Text[50])
        {
            Caption = 'Sell-to Address 2';
            DataClassification = CustomerContent;
        }
        field(83; "Sell-to City"; Text[30])
        {
            Caption = 'Sell-to City';
            DataClassification = CustomerContent;
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(84; "Sell-to Contact"; Text[100])
        {
            Caption = 'Sell-to Contact';
            DataClassification = CustomerContent;
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(86; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
            DataClassification = CustomerContent;
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(88; "Sell-to Post Code"; Code[20])
        {
            Caption = 'Sell-to Post Code';
            DataClassification = CustomerContent;
            TableRelation = if ("Sell-to Country/Region Code" = const('')) "Post Code"
            else
            if ("Sell-to Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Sell-to Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(89; "Sell-to County"; Text[30])
        {
            CaptionClass = '5,2,' + "Sell-to Country/Region Code";
            Caption = 'Sell-to County';
            DataClassification = CustomerContent;
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
        }
        field(99; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(100; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
        field(171; "Sell-to Phone No."; Text[30])
        {
            Caption = 'Sell-to Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;
        }
        field(172; "Sell-to E-Mail"; Text[80])
        {
            Caption = 'Email';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
        field(1304; "Cust. Ledger Entry No."; Integer)
        {
            Caption = 'Cust. Ledger Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "Cust. Ledger Entry"."Entry No.";
        }
        field(1305; "Invoice Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Invoice Discount Amount';
            DataClassification = CustomerContent;
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
            DataClassification = CustomerContent;
            TableRelation = Contact;
        }
        field(5750; "Shipping Advice"; Option)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
            DataClassification = CustomerContent;
            OptionCaption = 'Partial,Complete';
            OptionMembers = Partial,Complete;
        }
        field(5752; "Completely Shipped"; Boolean)
        {
            Caption = 'Completely Shipped';
            DataClassification = CustomerContent;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            DataClassification = CustomerContent;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(9600; "Total Tax Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Tax Amount';
            DataClassification = CustomerContent;
        }
        field(9601; Status; Enum "Sales Cr. Memo Entity Buffer Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        field(9602; Posted; Boolean)
        {
            Caption = 'Posted';
            DataClassification = CustomerContent;
        }
        field(9624; "Discount Applied Before Tax"; Boolean)
        {
            Caption = 'Discount Applied Before Tax';
            DataClassification = CustomerContent;
        }
        field(9630; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9631; "Customer Id"; Guid)
        {
            Caption = 'Customer Id';
            DataClassification = SystemMetadata;
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateSellToCustomerNo();
            end;
        }
        field(9633; "Contact Graph Id"; Text[250])
        {
            Caption = 'Contact Graph Id';
            DataClassification = SystemMetadata;
        }
        field(9634; "Currency Id"; Guid)
        {
            Caption = 'Currency Id';
            DataClassification = SystemMetadata;
            TableRelation = Currency.SystemId;

            trigger OnValidate()
            begin
                UpdateCurrencyCode();
            end;
        }
        field(9635; "Payment Terms Id"; Guid)
        {
            Caption = 'Payment Terms Id';
            DataClassification = SystemMetadata;
            TableRelation = "Payment Terms".SystemId;

            trigger OnValidate()
            begin
                UpdatePaymentTermsCode();
            end;
        }
        field(9636; "Shipment Method Id"; Guid)
        {
            Caption = 'Shipment Method Id';
            DataClassification = SystemMetadata;
            TableRelation = "Shipment Method".SystemId;

            trigger OnValidate()
            begin
                UpdateShipmentMethodCode();
            end;
        }
        field(9638; "Bill-to Customer Id"; Guid)
        {
            Caption = 'Bill-to Customer Id';
            DataClassification = SystemMetadata;
            TableRelation = Customer.SystemId;

            trigger OnValidate()
            begin
                UpdateBillToCustomerNo();
            end;
        }
        field(9639; "Reason Code Id"; Guid)
        {
            Caption = 'Reason Code Id';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code".SystemId;

            trigger OnValidate()
            begin
                UpdateReasonCode();
            end;
        }
    }

    keys
    {
        key(Key1; "No.", Posted)
        {
        }
        key(Key2; Id)
        {
            Clustered = true;
        }
        key(Key3; "Cust. Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds();
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds();
    end;

    trigger OnRename()
    begin
        if Posted and (not IsRenameAllowed) then
            Error(CannotModifyPostedInvioceErr);

        "Last Modified Date Time" := CurrentDateTime;
        UpdateReferencedRecordIds();
    end;

    var
        CannotModifyPostedInvioceErr: Label 'The credit memo has been posted and can no longer be modified.', Locked = true;
        IsRenameAllowed: Boolean;

    local procedure UpdateSellToCustomerId()
    var
        Customer: Record Customer;
    begin
        if "Sell-to Customer No." = '' then begin
            Clear("Customer Id");
            exit;
        end;

        if not Customer.Get("Sell-to Customer No.") then
            exit;

        "Customer Id" := Customer.SystemId;
    end;

    local procedure UpdateBillToCustomerId()
    var
        Customer: Record Customer;
    begin
        if "Bill-to Customer No." = '' then begin
            Clear("Bill-to Customer Id");
            exit;
        end;

        if not Customer.Get("Bill-to Customer No.") then
            exit;

        "Bill-to Customer Id" := Customer.SystemId;
    end;

    procedure UpdateCurrencyId()
    var
        Currency: Record Currency;
    begin
        if "Currency Code" = '' then begin
            Clear("Currency Id");
            exit;
        end;

        if not Currency.Get("Currency Code") then
            exit;

        "Currency Id" := Currency.SystemId;
    end;

    procedure UpdatePaymentTermsId()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if "Payment Terms Code" = '' then begin
            Clear("Payment Terms Id");
            exit;
        end;

        if not PaymentTerms.Get("Payment Terms Code") then
            exit;

        "Payment Terms Id" := PaymentTerms.SystemId;
    end;

    procedure UpdateReasonCodeId()
    var
        ReasonCode: Record "Reason Code";
    begin
        if "Reason Code" = '' then begin
            Clear("Reason Code Id");
            exit;
        end;

        if not ReasonCode.Get("Reason Code") then
            exit;

        "Reason Code Id" := ReasonCode.SystemId;
    end;

    procedure UpdateShipmentMethodId()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        if "Shipment Method Code" = '' then begin
            Clear("Shipment Method Id");
            exit;
        end;

        if not ShipmentMethod.Get("Shipment Method Code") then
            exit;

        "Shipment Method Id" := ShipmentMethod.SystemId;
    end;

    local procedure UpdateSellToCustomerNo()
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid("Customer Id") then
            Customer.GetBySystemId("Customer Id");

        Validate("Sell-to Customer No.", Customer."No.");
    end;

    local procedure UpdateBillToCustomerNo()
    var
        Customer: Record Customer;
    begin
        if not IsNullGuid("Bill-to Customer Id") then
            Customer.GetBySystemId("Bill-to Customer Id");

        Validate("Bill-to Customer No.", Customer."No.");
    end;

    local procedure UpdateCurrencyCode()
    var
        Currency: Record Currency;
    begin
        if not IsNullGuid("Currency Id") then
            Currency.GetBySystemId("Currency Id");

        Validate("Currency Code", Currency.Code);
    end;

    local procedure UpdatePaymentTermsCode()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if not IsNullGuid("Payment Terms Id") then
            PaymentTerms.GetBySystemId("Payment Terms Id");

        Validate("Payment Terms Code", PaymentTerms.Code);
    end;

    local procedure UpdateReasonCode()
    var
        ReasonCode: Record "Reason Code";
    begin
        if not IsNullGuid("Reason Code Id") then
            ReasonCode.GetBySystemId("Reason Code Id");

        Validate("Reason Code", ReasonCode.Code);
    end;

    local procedure UpdateShipmentMethodCode()
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        if not IsNullGuid("Shipment Method Id") then
            ShipmentMethod.GetBySystemId("Shipment Method Id");

        Validate("Shipment Method Code", ShipmentMethod.Code);
    end;

    procedure UpdateReferencedRecordIds()
    begin
        UpdateSellToCustomerId();
        UpdateBillToCustomerId();
        UpdateCurrencyId();
        UpdatePaymentTermsId();
        UpdateShipmentMethodId();
        UpdateReasonCodeId();
    end;

    procedure GetIsRenameAllowed(): Boolean
    begin
        exit(IsRenameAllowed);
    end;

    procedure SetIsRenameAllowed(RenameAllowed: Boolean)
    begin
        IsRenameAllowed := RenameAllowed;
    end;
}

