// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Receivables;
using System.Email;
using System.Globalization;

/// <summary>
/// Stores customer bank account information including IBAN, SWIFT code, and bank details.
/// </summary>
table 287 "Customer Bank Account"
{
    Caption = 'Customer Bank Account';
    DataCaptionFields = "Customer No.", "Code", Name;
    DrillDownPageID = "Customer Bank Account List";
    LookupPageID = "Customer Bank Account List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer that owns this bank account.
        /// </summary>
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        /// <summary>
        /// Specifies a unique code to identify this bank account among the customer's bank accounts.
        /// </summary>
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies a code to identify this customer bank account.';
        }
        /// <summary>
        /// Specifies the name of the bank where the customer holds this account.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the bank where the customer has the bank account.';
        }
        /// <summary>
        /// Specifies additional name information for the bank.
        /// </summary>
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        /// <summary>
        /// Specifies the street address of the bank.
        /// </summary>
        field(6; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the address of the bank where the customer has the bank account.';
        }
        /// <summary>
        /// Specifies additional address details for the bank location.
        /// </summary>
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city where the bank is located.
        /// </summary>
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the city of the bank where the customer has the bank account.';

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
            end;
        }
        /// <summary>
        /// Specifies the postal code for the bank's address.
        /// </summary>
        field(9; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the postal code.';

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
            end;
        }
        /// <summary>
        /// Specifies the name of the bank contact person for this account.
        /// </summary>
        field(10; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
        }
        /// <summary>
        /// Specifies the telephone number of the bank.
        /// </summary>
        field(11; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            ToolTip = 'Specifies the telephone number of the bank where the customer has the bank account.';
        }
        /// <summary>
        /// Specifies the telex number for the bank.
        /// </summary>
        field(12; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        /// <summary>
        /// Specifies the bank's branch number for routing purposes.
        /// </summary>
        field(13; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
            ToolTip = 'Specifies the number of the bank branch.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Branch No.');
            end;
        }
        /// <summary>
        /// Specifies the customer's account number at the bank.
        /// </summary>
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
            ToolTip = 'Specifies the number used by the bank for the bank account.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Account No.');
            end;
        }
        /// <summary>
        /// Specifies the transit routing number for the bank.
        /// </summary>
        field(15; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
            ToolTip = 'Specifies a bank identification number of your own choice.';
        }
        /// <summary>
        /// Specifies the currency used for transactions in this bank account.
        /// </summary>
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the relevant currency code for the bank account.';
        }
        /// <summary>
        /// Specifies the country or region where the bank is located.
        /// </summary>
        field(17; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        /// <summary>
        /// Specifies the state, province, or county where the bank is located.
        /// </summary>
        field(18; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the fax number of the bank.
        /// </summary>
        field(19; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the fax number of the bank where the customer has the bank account.';
        }
        /// <summary>
        /// Specifies the telex answer back code for the bank.
        /// </summary>
        field(20; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        /// <summary>
        /// Specifies the language code for communication with the bank.
        /// </summary>
        field(21; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
        }
        /// <summary>
        /// Specifies the email address associated with the bank account.
        /// </summary>
        field(22; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            ToolTip = 'Specifies the email address associated with the bank account.';

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        /// <summary>
        /// Specifies the bank's website URL.
        /// </summary>
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(23; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
            ToolTip = 'Specifies the bank web site.';
        }
        /// <summary>
        /// Specifies the International Bank Account Number for this account.
        /// </summary>
        field(24; IBAN; Code[50])
        {
            Caption = 'IBAN';
            ToolTip = 'Specifies the bank account''s international bank account number.';

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CompanyInfo.CheckIBAN(IBAN);
            end;
        }
        /// <summary>
        /// Specifies the SWIFT code for international bank transfers.
        /// </summary>
        field(25; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
            ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the customer has the account.';
        }
        /// <summary>
        /// Specifies the bank clearing code required for payment processing.
        /// </summary>
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
            ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
        }
        /// <summary>
        /// Specifies the format standard used for bank clearing codes.
        /// </summary>
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
            ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
        fieldgroup(Brick; "Code", Name, "Phone No.", Contact)
        {
        }
    }

    trigger OnDelete()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", "Customer No.");
        CustLedgerEntry.SetRange("Recipient Bank Account", Code);
        CustLedgerEntry.SetRange(Open, true);
        if not CustLedgerEntry.IsEmpty() then
            Error(BankAccDeleteErr);
        UpdateCustPreferredBankAccountCode();
    end;

    trigger OnRename()
    begin
    end;

    var
        PostCode: Record "Post Code";
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

    /// <summary>
    /// Gets the bank account number or IBAN, raising an error if both are empty.
    /// </summary>
    /// <returns>The bank account number or IBAN.</returns>
    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo();
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr);
    end;

    /// <summary>
    /// Gets the bank account number, preferring IBAN if available.
    /// </summary>
    /// <returns>The IBAN (without spaces) or bank account number, or empty if neither is specified.</returns>
    procedure GetBankAccountNo(): Text
    var
        Handled: Boolean;
        ResultBankAccountNo: Text;
    begin
        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    local procedure UpdateCustPreferredBankAccountCode()
    var
        CustomerLocal: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustPreferredBankAccountCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if CustomerLocal.Get("Customer No.") and (CustomerLocal."Preferred Bank Account Code" = Code) then begin
            CustomerLocal."Preferred Bank Account Code" := '';
            CustomerLocal.Modify();
        end;
    end;

    /// <summary>
    /// Raised when validating the bank branch number or bank account number fields.
    /// </summary>
    /// <param name="CustomerBankAccount">The customer bank account record being validated.</param>
    /// <param name="FieldToValidate">The name of the field being validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; FieldToValidate: Text)
    begin
    end;

    /// <summary>
    /// Raised before validating the IBAN field.
    /// </summary>
    /// <param name="CustomerBankAccount">The customer bank account record.</param>
    /// <param name="xCustomerBankAccount">The previous customer bank account record.</param>
    /// <param name="IsHandled">Set to true to skip the default IBAN validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIBAN(var CustomerBankAccount: Record "Customer Bank Account"; var xCustomerBankAccount: Record "Customer Bank Account"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised when getting the bank account number to allow custom retrieval logic.
    /// </summary>
    /// <param name="Handled">Set to true to indicate custom handling was performed.</param>
    /// <param name="CustomerBankAccount">The customer bank account record.</param>
    /// <param name="ResultBankAccountNo">Set to the bank account number to return.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetBankAccount(var Handled: Boolean; CustomerBankAccount: Record "Customer Bank Account"; var ResultBankAccountNo: Text)
    begin
    end;

    /// <summary>
    /// Raised before validating the city field.
    /// </summary>
    /// <param name="CustomerBankAccount">The customer bank account record.</param>
    /// <param name="PostCodeRec">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var CustomerBankAccount: Record "Customer Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before updating the customer's preferred bank account code when deleting a bank account.
    /// </summary>
    /// <param name="CustomerBankAccount">The customer bank account record being deleted.</param>
    /// <param name="IsHandled">Set to true to skip the default update.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustPreferredBankAccountCode(var CustomerBankAccount: Record "Customer Bank Account"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before validating the post code field.
    /// </summary>
    /// <param name="CustomerBankAccount">The customer bank account record.</param>
    /// <param name="PostCodeRec">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var CustomerBankAccount: Record "Customer Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}
