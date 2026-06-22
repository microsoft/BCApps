// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Environment;
using System.Security.Encryption;
using System.Telemetry;
using System.Utilities;

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

            trigger OnValidate()
            var
                AuditLog: Codeunit "Audit Log";
            begin
                if "Digipoort Delivery URL" <> xRec."Digipoort Delivery URL" then
                    Session.LogSecurityAudit(
                        DigipoortServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditDeliveryUrlChangedTxt, GetDigipoortUrlHost(xRec."Digipoort Delivery URL"), GetDigipoortUrlHost("Digipoort Delivery URL")),
                        AuditCategory::ApplicationManagement);
                if (xRec."Digipoort Delivery URL" = '') and ("Digipoort Delivery URL" <> '') then
                    AuditLog.LogAuditMessage(
                        StrSubstNo(DigipoortConfiguredLbl, UserSecurityId()),
                        SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);
                if not IsValidDigipoortHost("Digipoort Delivery URL") then
                    Error(InvalidDigipoortHostErr, FieldCaption("Digipoort Delivery URL"), DigipoortHostSuffixTok);
            end;
        }
        field(253; "Digipoort Status URL"; Text[250])
        {
            Caption = 'Digipoort Status URL';

            trigger OnValidate()
            begin
                if "Digipoort Status URL" <> xRec."Digipoort Status URL" then
                    Session.LogSecurityAudit(
                        DigipoortServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditStatusUrlChangedTxt, GetDigipoortUrlHost(xRec."Digipoort Status URL"), GetDigipoortUrlHost("Digipoort Status URL")),
                        AuditCategory::ApplicationManagement);
                if not IsValidDigipoortHost("Digipoort Status URL") then
                    Error(InvalidDigipoortHostErr, FieldCaption("Digipoort Status URL"), DigipoortHostSuffixTok);
            end;
        }
        field(300; "Use Certificate Setup"; Boolean)
        {
            Caption = 'Use Certificate Setup';

            trigger OnValidate()
            begin
                if "Use Certificate Setup" <> xRec."Use Certificate Setup" then
                    Session.LogSecurityAudit(
                        DigipoortServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditUseCertSetupChangedTxt, xRec."Use Certificate Setup", "Use Certificate Setup"),
                        AuditCategory::ApplicationManagement);
            end;
        }
        field(301; "Client Certificate Code"; Code[20])
        {
            TableRelation = "Isolated Certificate";
            Caption = 'Client Certificate Code';

            trigger OnValidate()
            begin
                if "Client Certificate Code" <> xRec."Client Certificate Code" then
                    Session.LogSecurityAudit(
                        DigipoortServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditClientCertChangedTxt, xRec."Client Certificate Code", "Client Certificate Code"),
                        AuditCategory::UserManagement);
            end;
        }
        field(302; "Service Certificate Code"; Code[20])
        {
            TableRelation = "Isolated Certificate";
            Caption = 'Service Certificate Code';

            trigger OnValidate()
            begin
                if "Service Certificate Code" <> xRec."Service Certificate Code" then
                    Session.LogSecurityAudit(
                        DigipoortServiceNameTxt, SecurityOperationResult::Success,
                        StrSubstNo(SecurityAuditServiceCertChangedTxt, xRec."Service Certificate Code", "Service Certificate Code"),
                        AuditCategory::UserManagement);
            end;
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
        DigipoortServiceNameTxt: Label 'Digipoort', Locked = true;
        SecurityAuditDeliveryUrlChangedTxt: Label 'Digipoort Delivery URL host was changed from %1 to %2.', Locked = true, Comment = '%1 - old host, %2 - new host';
        SecurityAuditStatusUrlChangedTxt: Label 'Digipoort Status URL host was changed from %1 to %2.', Locked = true, Comment = '%1 - old host, %2 - new host';
        SecurityAuditUseCertSetupChangedTxt: Label 'Use Certificate Setup was changed from %1 to %2.', Locked = true, Comment = '%1 - old value, %2 - new value';
        SecurityAuditClientCertChangedTxt: Label 'Digipoort Client Certificate Code was changed from %1 to %2.', Locked = true, Comment = '%1 - old certificate code, %2 - new certificate code';
        SecurityAuditServiceCertChangedTxt: Label 'Digipoort Service Certificate Code was changed from %1 to %2.', Locked = true, Comment = '%1 - old certificate code, %2 - new certificate code';
        DigipoortConfiguredLbl: Label 'Digipoort connection has been set up by UserSecurityId %1.', Locked = true;
        DigipoortHostSuffixTok: Label '.digipoort.logius.nl', Locked = true;
        InvalidDigipoortHostErr: Label 'The host of %1 must end with %2.', Comment = '%1 - field caption, %2 - required host suffix';

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

    internal procedure IsValidDigipoortHost(Url: Text): Boolean
    var
        Uri: Codeunit Uri;
    begin
        if Url = '' then
            exit(true);
        if not Uri.IsValidUri(Url) then
            exit(false);
        Uri.Init(Url);
        if Uri.GetScheme().ToLower() <> 'https' then
            exit(false);
        exit(Uri.GetHost().ToLower().EndsWith(DigipoortHostSuffixTok));
    end;

    internal procedure GetDigipoortHostSuffix(): Text
    begin
        exit(DigipoortHostSuffixTok);
    end;

    internal procedure GetDigipoortUrlHost(Url: Text): Text
    var
        Uri: Codeunit Uri;
    begin
        if (Url <> '') and Uri.IsValidUri(Url) then begin
            Uri.Init(Url);
            exit(Uri.GetHost());
        end;
        exit(Url);
    end;
}

