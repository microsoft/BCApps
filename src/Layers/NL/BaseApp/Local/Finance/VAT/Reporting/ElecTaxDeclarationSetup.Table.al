// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Environment;
using System.Security.Encryption;

table 11408 "Elec. Tax Declaration Setup"
{
    Caption = 'Elec. Tax Declaration Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "VAT Declaration Nos."; Code[20])
        {
            Caption = 'VAT Declaration Nos.';
            TableRelation = "No. Series";
        }
        field(3; "ICP Declaration Nos."; Code[20])
        {
            Caption = 'ICP Declaration Nos.';
            TableRelation = "No. Series";
        }
        field(10; "VAT Contact Type"; Option)
        {
            Caption = 'VAT Contact Type';
            OptionCaption = 'Tax Payer,,,Agent';
            OptionMembers = "Tax Payer",,,Agent;
        }
        field(11; "Agent Contact ID"; Code[17])
        {
            Caption = 'Agent Contact ID';

            trigger OnValidate()
            begin
                if "Agent Contact ID" <> '' then begin
                    if ("VAT Contact Type" = "VAT Contact Type"::"Tax Payer") and
                       ("ICP Contact Type" = "ICP Contact Type"::"Tax Payer")
                    then
                        Error(Text000, FieldCaption("Agent Contact ID"), FieldCaption("VAT Contact Type"),
                          FieldCaption("ICP Contact Type"), "VAT Contact Type");
                    if ("VAT Contact Type" = "VAT Contact Type"::Agent) or
                       ("ICP Contact Type" = "ICP Contact Type"::Agent)
                    then
                        case true of
                            StrLen("Agent Contact ID") <> 6:
                                Error(Text001, FieldCaption("Agent Contact ID"), 6, FieldCaption("VAT Contact Type"),
                                  FieldCaption("ICP Contact Type"), "VAT Contact Type");
                            not CheckBECONID("Agent Contact ID"):
                                Error(Text002, "Agent Contact ID");
                        end;
                end;
            end;
        }
        field(12; "Agent Contact Name"; Text[35])
        {
            Caption = 'Agent Contact Name';
        }
        field(13; "Agent Contact Phone No."; Text[25])
        {
            Caption = 'Agent Contact Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(15; "Agent Contact Address"; Text[30])
        {
            Caption = 'Agent Contact Address';
        }
        field(16; "Agent Contact Post Code"; Code[20])
        {
            Caption = 'Agent Contact Post Code';
        }
        field(17; "Agent Contact City"; Text[30])
        {
            Caption = 'Agent Contact City';
        }
        field(19; "ICP Contact Type"; Option)
        {
            Caption = 'ICP Contact Type';
            OptionCaption = 'Tax Payer,,,Agent';
            OptionMembers = "Tax Payer",,,Agent;
        }
        field(20; "Service Agency Contact ID"; Code[17])
        {
            Caption = 'Service Agency Contact ID';
        }
        field(21; "Service Agency Contact Name"; Text[35])
        {
            Caption = 'Service Agency Contact Name';
        }
        field(22; "Svc. Agency Contact Phone No."; Text[25])
        {
            Caption = 'Svc. Agency Contact Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(23; "Tax Payer Contact Name"; Text[35])
        {
            Caption = 'Tax Payer Contact Name';
        }
        field(24; "Tax Payer Contact Phone No."; Text[25])
        {
            Caption = 'Tax Payer Contact Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(230; "Part of Fiscal Entity"; Boolean)
        {
            Caption = 'Part of Fiscal Entity';

            trigger OnValidate()
            begin
                if "Part of Fiscal Entity" <> xRec."Part of Fiscal Entity" then begin
                    ElecTaxDeclarationHeader.Reset();
                    ElecTaxDeclarationHeader.SetFilter(Status, '%1|%2', ElecTaxDeclarationHeader.Status::Created,
                      ElecTaxDeclarationHeader.Status::Submitted);
                    if ElecTaxDeclarationHeader.FindFirst() then
                        Error(Text003,
                          FieldCaption("Part of Fiscal Entity"),
                          ElecTaxDeclarationHeader.TableCaption(),
                          ElecTaxDeclarationHeader.FieldCaption(Status),
                          ElecTaxDeclarationHeader.Status);
                end;
            end;
        }
        field(250; "Digipoort Client Cert. Name"; Text[250])
        {
            Caption = 'Digipoort Client Cert. Name';
        }
        field(251; "Digipoort Service Cert. Name"; Text[250])
        {
            Caption = 'Digipoort Service Cert. Name';
        }
        field(252; "Digipoort Delivery URL"; Text[250])
        {
            Caption = 'Digipoort Delivery URL';
        }
        field(253; "Digipoort Status URL"; Text[250])
        {
            Caption = 'Digipoort Status URL';
        }
        field(300; "Use Certificate Setup"; Boolean)
        {
            Caption = 'Use Certificate Setup';
        }
        field(301; "Client Certificate Code"; Code[20])
        {
            TableRelation = "Isolated Certificate";
            Caption = 'Client Certificate Code';
        }
        field(302; "Service Certificate Code"; Code[20])
        {
            TableRelation = "Isolated Certificate";
            Caption = 'Service Certificate Code';
        }
        field(350; "Tax Decl. Schema Version"; Text[10])
        {
            Caption = 'Tax Decl. Schema Version';
        }
        field(351; "Tax Decl. BD Data Endpoint"; Text[250])
        {
            Caption = 'Tax Decl. BD Data Endpoint';
        }
        field(352; "Tax Decl. BD Tuples Endpoint"; Text[250])
        {
            Caption = 'Tax Decl. BD Tuples Endpoint';
        }
        field(353; "Tax Decl. Schema Endpoint"; Text[250])
        {
            Caption = 'Tax Decl. Schema Endpoint';
        }
        field(354; "ICP Decl. Schema Endpoint"; Text[250])
        {
            Caption = 'ICP Decl. Schema Endpoint';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1 must be blank if %2 and %3 are %4.';
        Text001: Label 'Length of %1 must be exactly %2 characters if %3 or %4 is %5.';
        Text002: Label '%1 is not a valid BECON ID.';
        ElecTaxDeclarationHeader: Record "Elec. Tax Declaration Header";
        Text003: Label 'You cannot change %1 when you have %2 with %3 %4.';

    local procedure CheckBECONID(BECONID: Code[6]): Boolean
    var
        i: Integer;
        Digit: Integer;
        Weight: Integer;
        Total: Integer;
    begin
        for i := 1 to 5 do begin
            Evaluate(Digit, Format(BECONID[i]));
            Weight := 7 - i;
            Total := Total + Digit * Weight;
        end;

        Evaluate(Digit, Format(BECONID[6]));
        Total := Total mod 11;
        exit(Digit = Total);
    end;

    [Scope('OnPrem')]
    procedure CheckDigipoortSetup()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if "Use Certificate Setup" then begin
            TestField("Client Certificate Code");
            TestField("Service Certificate Code");
        end else
            if not EnvironmentInfo.IsSaaS() then begin
                TestField("Digipoort Client Cert. Name");
                TestField("Digipoort Service Cert. Name");
            end;
        TestField("Digipoort Delivery URL");
        TestField("Digipoort Status URL");
    end;
}

