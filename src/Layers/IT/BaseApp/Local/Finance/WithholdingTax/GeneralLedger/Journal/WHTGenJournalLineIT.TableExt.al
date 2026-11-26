// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.CRM.Contact;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

tableextension 12200 "WHT Gen. Journal Line IT" extends "Gen. Journal Line"
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
            begin
                TestField(Resident, Resident::Resident);
                if "Fiscal Code" <> '' then
                    LocalAppMgt.CheckDigit("Fiscal Code");
            end;
        }
        field(12130; Resident; Option)
        {
            Caption = 'Resident';
            DataClassification = CustomerContent;
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";

            trigger OnValidate()
            begin
                TestField("Tax Representative Type", "Tax Representative Type"::" ");
                if Resident = Resident::Resident then
                    InitFields()
                else
                    "Fiscal Code" := '';
            end;
        }
        field(12131; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Tax Representative Type" := "Tax Representative Type"::" ";
                "Tax Representative No." := '';
                if not "Individual Person" then begin
                    Resident := Resident::Resident;
                    InitFields();
                    "Fiscal Code" := '';
                end;
            end;
        }
        field(12133; "First Name"; Text[30])
        {
            Caption = 'First Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12134; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12135; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12136; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Contact,Vendor';
            OptionMembers = " ",Customer,Contact,Vendor;

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
        field(12137; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Customer)) Customer
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;

            trigger OnValidate()
            begin
                if "Tax Representative No." <> '' then
                    TestField("Tax Representative Type");
            end;
        }
        field(12138; "Place of Birth"; Text[30])
        {
            Caption = 'Place of Birth';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    var
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        ChangeLineErr: Label 'It is not possible to change %1 when there are withholding lines associated. Delete this line or the associated withholding line.', Comment = '%1 = Field caption';

    procedure UpdateTmpWithholdingContribution()
    begin
        if TmpWithholdingContribution.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then begin
            TmpWithholdingContribution."Payment Date" := Rec."Document Date";
            TmpWithholdingContribution.Modify();
        end;
    end;

    procedure DeleteTmpWithhSocSec()
    begin
        TmpWithholdingContribution.ClearDeletedLineNos(Rec);
        if TmpWithholdingContribution.Get("Journal Template Name", "Journal Batch Name", "Line No.") then
            TmpWithholdingContribution.Delete();
    end;

    procedure CheckWithholdingContributionChange()
    begin
        if TmpWithholdingContribution.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Line No.") then
            Error(ChangeLineErr, Rec.FieldCaption("Applies-to Doc. No."));
    end;

    [Scope('OnPrem')]
    procedure InitFields()
    begin
        "First Name" := '';
        "Last Name" := '';
        "Date of Birth" := 0D;
        "Place of Birth" := '';
    end;

    [Scope('OnPrem')]
    procedure ConvertPurchTaxRepresentativeTypeToGenJnlLine(TaxRepresentativeType: Option " ",Vendor,Contact): Integer
    begin
        case TaxRepresentativeType of
            TaxRepresentativeType::" ":
                exit("Tax Representative Type"::" ");
            TaxRepresentativeType::Vendor:
                exit("Tax Representative Type"::Vendor);
            TaxRepresentativeType::Contact:
                exit("Tax Representative Type"::Contact);
        end;
    end;

    [Scope('OnPrem')]
    procedure ConvertSalesTaxRepresentativeTypeToGenJnlLine(TaxRepresentativeType: Option " ",Customer,Contact): Integer
    begin
        case TaxRepresentativeType of
            TaxRepresentativeType::" ":
                exit("Tax Representative Type"::" ");
            TaxRepresentativeType::Customer:
                exit("Tax Representative Type"::Customer);
            TaxRepresentativeType::Contact:
                exit("Tax Representative Type"::Contact);
        end;
    end;

}