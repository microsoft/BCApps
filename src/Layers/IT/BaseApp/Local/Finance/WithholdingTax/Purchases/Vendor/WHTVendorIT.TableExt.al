// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.Payment;
using Microsoft.CRM.Contact;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Address;
using Microsoft.Utilities;

tableextension 12201 "WHT VEndor IT" extends Vendor
{
    fields
    {
        field(12101; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            var
                LocalAppMgt: Codeunit LocalApplicationManagement;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateFiscalCode(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                TestField(Resident, Resident::Resident);
                if "Fiscal Code" <> '' then
                    LocalAppMgt.CheckDigit("Fiscal Code");
            end;
        }
        field(12102; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Withhold Code";
        }
        field(12103; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));
        }
        field(12104; "Soc. Sec. Company Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum(Contributions."Gross Amount" where("Vendor No." = field("No."),
                                                                  "Related Date" = field("Date Filter")));
            Caption = 'Soc. Sec. Company Base';
            FieldClass = FlowField;
        }
        field(12105; "Soc. Sec. 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = CustomerContent;
            Caption = 'Soc. Sec. 3 Parties Base';
        }
        field(12106; Resident; Option)
        {
            Caption = 'Resident';
            DataClassification = CustomerContent;
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";

            trigger OnValidate()
            begin
                if Resident <> xRec.Resident then begin
                    TestField("Tax Representative Type", "Tax Representative Type"::" ");
                    if Resident = Resident::Resident then
                        InitFields()
                    else
                        "Fiscal Code" := '';
                end;
            end;
        }
        field(12108; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not "Individual Person" then begin
                    Resident := Resident::Resident;
                    InitFields();
                    "Fiscal Code" := '';
                end else
                    TestField("Tax Representative Type", "Tax Representative Type"::" ");
            end;
        }
        field(12109; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
        field(12110; "Birth City"; Text[30])
        {
            Caption = 'Birth City';
            DataClassification = EndUserIdentifiableInformation;
            OptimizeForTextSearch = true;
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code".City
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
                PostCode.ValidateCity(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12111; "Birth Post Code"; Code[20])
        {
            Caption = 'Birth Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code"
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12112; "Birth County"; Text[30])
        {
            Caption = 'Birth County';
            DataClassification = EndUserIdentifiableInformation;
            OptimizeForTextSearch = true;
        }
        field(12113; Gender; Option)
        {
            Caption = 'Gender';
            DataClassification = EndUserIdentifiableInformation;
            OptionCaption = ' ,Male,Female';
            OptionMembers = " ",Male,Female;
        }
        field(12114; "Residence Address"; Text[50])
        {
            Caption = 'Residence Address';
            DataClassification = EndUserIdentifiableInformation;
            OptimizeForTextSearch = true;
        }
        field(12115; "Residence Post Code"; Code[20])
        {
            Caption = 'Residence Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code"
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Residence City", "Residence Post Code", "Residence County", "Residence Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12116; "Residence City"; Text[30])
        {
            Caption = 'Residence City';
            DataClassification = EndUserIdentifiableInformation;
            OptimizeForTextSearch = true;
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code".City
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Residence City", "Residence Post Code", "Residence County", "Residence Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12117; "Country of Fiscal Domicile"; Code[10])
        {
            Caption = 'Country/Region of Fiscal Domicile';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region";
        }
        field(12118; "Contribution Fiscal Code"; Code[20])
        {
            Caption = 'Contribution Fiscal Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12119; "Tax Exempt Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tax Exempt Amount (LCY)';
            DataClassification = CustomerContent;
        }
        field(12120; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                ContributionCode: Record "Contribution Code";
            begin
                ContributionCode.LookupINAIL("INAIL Code");
            end;
        }
        field(12121; "INAIL Company Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum(Contributions."INAIL Company Amount" where("Vendor No." = field("No."),
                                                                          "Payment Date" = field("Date Filter"),
                                                                          "INAIL Code" = filter(<> '')));
            Caption = 'INAIL Company Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12122; "INAIL 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL 3 Parties Base';
            DataClassification = CustomerContent;
        }
        field(12126; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "Tax Representative Type" <> "Tax Representative Type"::" " then begin
                    TestField("Individual Person", false);
                    TestField(Resident, Resident::"Non-Resident");
                end;
                if "Tax Representative Type" <> xRec."Tax Representative Type" then
                    "Tax Representative No." := '';
            end;
        }
        field(12127; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;

            trigger OnValidate()
            begin
                if "Tax Representative No." <> '' then
                    TestField("Tax Representative Type");
            end;
        }
        field(12129; "Birth Country/Region Code"; Code[10])
        {
            Caption = 'Birth Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12130; "Residence County"; Text[30])
        {
            Caption = 'Residence County';
            OptimizeForTextSearch = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12131; "Residence Country/Region Code"; Code[10])
        {
            Caption = 'Residence Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12184; "First Name"; Text[30])
        {
            Caption = 'First Name';
            OptimizeForTextSearch = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
        field(12185; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
            OptimizeForTextSearch = true;
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateIndividualPerson();
            end;
        }
    }

    var
        PostCode: Record "Post Code";

    [Scope('OnPrem')]
    procedure InitFields()
    begin
        "First Name" := '';
        "Last Name" := '';
        "Date of Birth" := 0D;
        "Birth City" := '';
    end;

    [Scope('OnPrem')]
    procedure ValidateIndividualPerson()
    begin
        TestField("Individual Person");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateFiscalCode(var Vendor: Record Vendor; xVendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;
}