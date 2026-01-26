// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Address;

page 425 "Vendor Bank Account Card"
{
    Caption = 'Vendor Bank Account Card';
    PageType = Card;
    SourceTable = "Vendor Bank Account";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this vendor bank account.';
                }
                field("Payment Form"; Rec."Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';

                    trigger OnValidate()
                    begin
                        Rec.TestField(Code);
                        CurrPage.SaveRecord();
                        UpdateView();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NameEnable;
                    ToolTip = 'Specifies the name of the bank where the vendor has this bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AddressEnable;
                    ToolTip = 'Specifies the address of the bank where the vendor has the bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Address2Enable;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = PostCodeEnable;
                    ToolTip = 'Specifies the postal code.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = CountryRegionCodeEnable;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
			UpdateSuggestedSwissPaymentType();
                    end;
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = PhoneNoEnable;
                    ToolTip = 'Specifies the telephone number of the bank where the vendor has the bank account.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ContactEnable;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = CityEnable;
                    ToolTip = 'Specifies the city of the bank where the vendor has the bank account.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank branch.';
                    MaskType = Concealed;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = BankAccountNoEnable;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    MaskType = Concealed;

                    trigger OnValidate()
                    begin
                        UpdateView();
                    end;
                }
                field("Transit No."; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    MaskType = Concealed;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = FaxNoEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where the vendor has the bank account.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = EMailEnable;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = HomePageEnable;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field(PaymentForm2; Rec."Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';

                    trigger OnValidate()
                    begin
                        Rec.TestField(Code);
                        CurrPage.SaveRecord();
                        UpdateView();
                    end;
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = SWIFTCodeEnable;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the vendor has the account.';
                    MaskType = Concealed;

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("Clearing No."; Rec."Clearing No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ClearingNoEnable;
                    ToolTip = 'Specifies the clearing number for the supplier''s bank.';

                    trigger OnValidate()
                    begin
                        UpdateView();
                    end;
                }
                field("Giro Account No."; Rec."Giro Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = GiroAccountNoEnable;
                    ToolTip = 'Specifies the vendor''s giro account no.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("ESR Type"; Rec."ESR Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ESRTypeEnable;
                    ToolTip = 'Specifies, for ESR and ESR+, you can define the format of account numbers and reference numbers for this vendor.';
                }
                field("ESR Account No."; Rec."ESR Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ESRAccountNoEnable;
                    ToolTip = 'Specifies the vendor''s ESR account number.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("Invoice No. Startposition"; Rec."Invoice No. Startposition")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = InvoiceNoStartpositionEnable;
                    ToolTip = 'Specifies the position of the invoice number within the reference number.';
                }
                field("Invoice No. Length"; Rec."Invoice No. Length")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = InvoiceNoLengthEnable;
                    ToolTip = 'Specifies the length of the invoice number in the reference number.';
                }
                field("Balance Account No."; Rec."Balance Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that when processing an invoice, for this bank account, the balance account you enter here will be suggested.';
                }
                field("Debit Bank"; Rec."Debit Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a debit bank can be predefined, which should be used for this vendor bank.';
                }
                field("Bank Identifier Code"; Rec."Bank Identifier Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this is used if a payment is made to a foreign bank.';
                    Visible = false;
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IBANEnable;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    MaskType = Concealed;

                    trigger OnValidate()
                    begin
                        UpdateView();
                    end;
                }
                field("Payment Fee Code"; Rec."Payment Fee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment fee code to be used for this vendor bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType();
                    end;
                }
                field("Bank Clearing Standard"; Rec."Bank Clearing Standard")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
                }
                field("Bank Clearing Code"; Rec."Bank Clearing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
                }
                field(SuggestedSwissPaymentType; SuggestedSwissPaymentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggested Swiss SEPA CT Export Payment Type';
                    Editable = false;
                    ToolTip = 'Specifies the suggested payment type for swiss SEPA CT exports.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateView();
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    trigger OnInit()
    begin
        TransitNoEnable := true;
        SWIFTCodeEnable := true;
        HomePageEnable := true;
        EMailEnable := true;
        FaxNoEnable := true;
        ContactEnable := true;
        PhoneNoEnable := true;
        CountryRegionCodeEnable := true;
        IBANEnable := true;
        CityEnable := true;
        PostCodeEnable := true;
        Address2Enable := true;
        AddressEnable := true;
        NameEnable := true;
        InvoiceNoLengthEnable := true;
        InvoiceNoStartpositionEnable := true;
        ESRAccountNoEnable := true;
        GiroAccountNoEnable := true;
        ESRTypeEnable := true;
        BankAccountNoEnable := true;
        ClearingNoEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateView();
    end;

    trigger OnOpenPage()
    begin
        UpdateView();
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
        ClearingNoEnable: Boolean;
        BankAccountNoEnable: Boolean;
        ESRTypeEnable: Boolean;
        GiroAccountNoEnable: Boolean;
        ESRAccountNoEnable: Boolean;
        InvoiceNoStartpositionEnable: Boolean;
        InvoiceNoLengthEnable: Boolean;
        NameEnable: Boolean;
        AddressEnable: Boolean;
        Address2Enable: Boolean;
        PostCodeEnable: Boolean;
        CityEnable: Boolean;
        IBANEnable: Boolean;
        CountryRegionCodeEnable: Boolean;
        PhoneNoEnable: Boolean;
        ContactEnable: Boolean;
        FaxNoEnable: Boolean;
        EMailEnable: Boolean;
        HomePageEnable: Boolean;
        SWIFTCodeEnable: Boolean;
        TransitNoEnable: Boolean;
        SuggestedSwissPaymentType: Option " ","1","2.1","2.2","3","4","5","6";

    [Scope('OnPrem')]
    procedure UpdateView()
    begin
        ClearingNoEnable := false;
        BankAccountNoEnable := false;
        ESRTypeEnable := false;
        GiroAccountNoEnable := false;
        ESRAccountNoEnable := false;
        InvoiceNoStartpositionEnable := false;
        InvoiceNoLengthEnable := false;
        NameEnable := false;
        AddressEnable := false;
        Address2Enable := false;
        PostCodeEnable := false;
        CityEnable := false;
        IBANEnable := false;
        CountryRegionCodeEnable := false;
        PhoneNoEnable := false;
        ContactEnable := false;
        FaxNoEnable := false;
        EMailEnable := false;
        HomePageEnable := false;
        SWIFTCodeEnable := false;
        TransitNoEnable := false;

        case Rec."Payment Form" of
            Rec."Payment Form"::ESR,
            Rec."Payment Form"::"ESR+":
                begin
                    ESRTypeEnable := true;
                    ESRAccountNoEnable := true;
                    InvoiceNoStartpositionEnable := true;
                    InvoiceNoLengthEnable := true;
                    IBANEnable := true;
                end;
            Rec."Payment Form"::"Post Payment Domestic":
                begin
                    GiroAccountNoEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;
                    NameEnable := false;
                    AddressEnable := false;
                    Address2Enable := false;
                    PostCodeEnable := false;
                    CityEnable := false;

                    IBANCheck();

                    CountryRegionCodeEnable := false;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;
                end;
            Rec."Payment Form"::"Bank Payment Domestic":
                begin
                    ClearingNoEnable := true;
                    NameEnable := true;
                    AddressEnable := true;
                    Address2Enable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;

                    IBANCheck();

                    CountryRegionCodeEnable := true;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;
                end;
            Rec."Payment Form"::"Cash Outpayment Order Domestic":
                ;
            Rec."Payment Form"::"Bank Payment Abroad", Rec."Payment Form"::"Post Payment Abroad":
                begin
                    NameEnable := true;
                    AddressEnable := true;
                    Address2Enable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;

                    IBANCheck();

                    CountryRegionCodeEnable := true;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;

                    ClearingNoEnable := true;
                end;
            Rec."Payment Form"::"SWIFT Payment Abroad":
                begin
                    SWIFTCodeEnable := true;
                    NameEnable := true;
                    AddressEnable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    CountryRegionCodeEnable := true;
                    BankAccountNoEnable := true;

                    IBANCheck();
                end;
            Rec."Payment Form"::"Cash Outpayment Order Abroad":
                ;
        end;
        UpdateSuggestedSwissPaymentType();
    end;

    local procedure IBANCheck()
    begin
        IBANEnable := true;
        if Rec.IBAN <> '' then
            BankAccountNoEnable := false;
        if Rec."Bank Account No." <> '' then
            IBANEnable := false;
    end;

    local procedure UpdateSuggestedSwissPaymentType()
    begin
        if not Rec.GetPaymentType(SuggestedSwissPaymentType, Rec."Currency Code") then
            SuggestedSwissPaymentType := SuggestedSwissPaymentType::" ";
    end;
}

