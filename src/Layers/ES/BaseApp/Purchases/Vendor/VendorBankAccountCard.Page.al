// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Address;
using System.Telemetry;

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
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where the vendor has this bank account.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the bank where the vendor has the bank account.';
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the bank where the vendor has the bank account.';
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
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where the vendor has the bank account.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("Bank Branch No."; Rec."Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Branch No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies a number of the bank branch.';
                    Visible = false;
                    MaskType = Concealed;
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account No.';
                    Importance = Promoted;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                    Visible = false;
                    MaskType = Concealed;
                }
                field("Transit No."; Rec."Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                    MaskType = Concealed;
                }
                field("Use For Electronic Payments"; Rec."Use For Electronic Payments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this vendor bank account to be used for electronic payments.';

                    trigger OnValidate()
                    begin
                        FeatureTelemetry.LogUptake('1000HW6', ESElecPaymentsTok, Enum::"Feature Uptake Status"::Discovered);
                        UseForElectronicPaymentsOnPush();
                    end;
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where the vendor has the bank account.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field("CCC Bank No."; Rec."CCC Bank No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account code. This code is the first part of the Codigo Cuenta Cliente (CCC) number.';
                }
                field("CCC Bank Branch No."; Rec."CCC Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the four-digit bank office number. This number is the second part of the Codigo Cuenta Cliente (CCC) number.';
                }
                field("CCC Control Digits"; Rec."CCC Control Digits")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the two-digit account control code. This number is the third part of the Codigo Cuenta Cliente (CCC) number.';
                }
                field("CCC Bank Account No."; Rec."CCC Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company''s bank account code.';
                }
                field("CCC No."; Rec."CCC No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Codigo Cuenta Cliente (CCC) number.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the vendor has the account.';
                    MaskType = Concealed;
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                    MaskType = Concealed;
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

    local procedure UseForElectronicPaymentsOnPush()
    begin
        CurrPage.Update();
    end;

    trigger OnAfterGetRecord()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsCountyVisible: Boolean;
        ESElecPaymentsTok: Label 'ES Electronic Payments', Locked = true;

}

